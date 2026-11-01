import SwiftUI
import AVKit
import AVFoundation
import Combine

/// Estados del reproductor de cámaras de la flota
enum CameraPlayerState: Equatable {
    case idle
    case loading
    case playing
    case offline(message: String)
    case error(message: String)
    case unauthorized
}

/// ViewModel que administra el ciclo de vida del AVPlayer, la coordinación de streaming
/// y la liberación estricta de sesiones y buffers HLS al pasar a segundo plano.
@MainActor
class CameraPlayerViewModel: ObservableObject {
    @Published var state: CameraPlayerState = .idle
    @Published var snapshotData: Data? = nil
    
    // Instancia estable de AVPlayer
    let player: AVPlayer = AVPlayer()
    
    private let ship: Ship
    private let cameraService: CameraServiceProtocol
    private let coordinator = CameraStreamCoordinator.shared
    
    private var recoveryTask: Task<Void, Never>? = nil
    private var cancellables = Set<AnyCancellable>()
    private var isViewActive: Bool = false
    
    // Sesión activa en Centinela
    private var currentSid: String? = nil
    private var currentSerial: String? = nil
    
    // Bandera para recordar si esta cámara estaba reproduciendo antes de entrar a background
    private var wasPlayingBeforeBackground: Bool = false
    
    // Control para evitar revocaciones duplicadas
    private var isRevokingSession: Bool = false
    
    // Control para evitar bucles de reintentos infinitos ante expiración de sid
    private var hasAttemptedSessionRecovery: Bool = false
    
    init(ship: Ship, cameraService: CameraServiceProtocol) {
        self.ship = ship
        self.cameraService = cameraService
        setupNotificationObservers()
        setupCoordinatorObserver()
    }
    
    deinit {
        player.pause()
        player.replaceCurrentItem(with: nil)
        recoveryTask?.cancel()
        
        // Revocación de sesión de seguridad en Centinela al destruir el ViewModel
        if let sid = currentSid, let serial = currentSerial {
            let svc = cameraService
            Task.detached {
                await svc.revokeSession(for: serial, sid: sid)
            }
        }
    }
    
    // MARK: - Ciclo de Vida de la Vista
    func onAppear() {
        isViewActive = true
        hasAttemptedSessionRecovery = false
        
        // Cargar snapshot inicial y telemetría sin iniciar streaming HLS automático innecesario
        loadInitialPreviewOrResume()
    }
    
    func onDisappear() {
        isViewActive = false
        recoveryTask?.cancel()
        recoveryTask = nil
        
        // Si esta cámara estaba reproduciendo, detener y revocar sesión
        if state == .playing || currentSid != nil {
            stopStreaming()
        }
        
        coordinator.releaseStreamingAccess(for: ship.assignedCameraSerial ?? "")
        state = .idle
    }
    
    // MARK: - Carga Inicial y Previsualización
    private func loadInitialPreviewOrResume() {
        guard let serial = ship.assignedCameraSerial else {
            state = .error(message: "Cámara no vinculada")
            return
        }
        
        // Comprobar autorización de cámara para el usuario actual
        guard cameraService.isCameraAllowed(serial: serial) else {
            state = .unauthorized
            snapshotData = nil
            return
        }
        
        // Si Centinela la reportó offline previamente
        if cameraService.isCameraOffline(serial: serial) {
            state = .offline(message: "Cámara sin conexión")
            startPassiveRecoveryPolling(for: serial)
            return
        }
        
        // Si el coordinador indica que esta cámara debe reanudar streaming
        if coordinator.shouldResumeOnForeground(for: serial) {
            startStreaming(forceRefresh: true)
            return
        }
        
        // Modo dashboard estándar: cargar snapshot ligero sin abrir sesión HLS
        Task {
            if self.snapshotData == nil {
                if let snap = try? await self.cameraService.fetchSnapshot(for: serial) {
                    guard self.isViewActive else { return }
                    self.snapshotData = snap
                }
            }
            if self.state == .idle {
                // Se mantiene en idle (listo para reproducir cuando el usuario lo solicite)
            }
        }
    }
    
    // MARK: - Inicio de Transmisión HLS (Bajo demanda o reanudación autorizada)
    func startStreaming(forceRefresh: Bool = false) {
        guard let serial = ship.assignedCameraSerial else {
            state = .error(message: "Cámara no vinculada")
            return
        }
        
        guard cameraService.isCameraAllowed(serial: serial) else {
            state = .unauthorized
            snapshotData = nil
            return
        }
        
        // Notificar al coordinador para acceso exclusivo
        coordinator.requestStreamingAccess(for: serial)
        wasPlayingBeforeBackground = true
        state = .loading
        
        Task {
            do {
                let liveResponse = try await self.cameraService.fetchLiveStream(for: serial, forceRefresh: forceRefresh)
                
                guard self.isViewActive else { return }
                
                if liveResponse.isOffline {
                    self.snapshotData = nil
                    let msg = liveResponse.displayDetail.isEmpty ? "Cámara sin conexión" : liveResponse.displayDetail
                    self.state = .offline(message: msg)
                    self.player.pause()
                    self.player.replaceCurrentItem(with: nil)
                    self.startPassiveRecoveryPolling(for: serial)
                    return
                }
                
                if let urlString = liveResponse.streamUrl, let url = URL(string: urlString) {
                    guard AppConfig.isValidCentinelaStreamURL(url) else {
                        self.state = .error(message: "Dominio de video no autorizado")
                        return
                    }
                    
                    self.currentSid = liveResponse.sid
                    self.currentSerial = serial
                    self.setupPlayerWithURL(url)
                    self.state = .playing
                } else {
                    self.state = .error(message: "Transmisión no disponible")
                }
            } catch NetworkError.unauthorized {
                self.snapshotData = nil
                self.state = .unauthorized
            } catch {
                self.state = .error(message: "Error al conectar con Centinela")
            }
        }
    }
    
    // MARK: - Detención Limpia de Streaming
    func stopStreaming() {
        wasPlayingBeforeBackground = false
        
        // 1. Pausar y desconectar completamente el AVPlayerItem para cancelar descargas HLS
        player.pause()
        player.replaceCurrentItem(with: nil)
        
        // 2. Revocar sesión activa en Centinela Gateway
        revokeCurrentSessionSafely()
        
        if let serial = ship.assignedCameraSerial {
            coordinator.releaseStreamingAccess(for: serial)
        }
        
        state = .idle
    }
    
    private func setupPlayerWithURL(_ url: URL) {
        let playerItem = AVPlayerItem(url: url)
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackFailure()
        }
        
        player.replaceCurrentItem(with: playerItem)
        player.actionAtItemEnd = .none
        player.play()
    }
    
    // MARK: - Recuperación ante fallo de reproducción (expiración de sid)
    private func handlePlaybackFailure() {
        guard isViewActive, !hasAttemptedSessionRecovery, let serial = ship.assignedCameraSerial else {
            return
        }
        hasAttemptedSessionRecovery = true
        
        revokeCurrentSessionSafely()
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard self.isViewActive, self.state == .playing else { return }
            self.startStreaming(forceRefresh: true)
        }
    }
    
    // MARK: - Revocación Segura de Sesión en Centinela con Background Task
    private func revokeCurrentSessionSafely() {
        guard !isRevokingSession, let sid = currentSid, let serial = currentSerial else {
            return
        }
        
        isRevokingSession = true
        let sidToRevoke = sid
        let serialToRevoke = serial
        self.currentSid = nil
        self.currentSerial = nil
        
        let svc = cameraService
        
        // Solicitar tiempo de finalización seguro a iOS para que la revocación HTTP POST
        // complete con éxito incluso si el usuario bloquea el teléfono inmediatamente
        var bgTaskId = UIBackgroundTaskIdentifier.invalid
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "CentinelaRevoke-\(serialToRevoke)") {
            if bgTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskId)
                bgTaskId = .invalid
            }
        }
        
        Task.detached {
            await svc.revokeSession(for: serialToRevoke, sid: sidToRevoke)
            if bgTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskId)
                bgTaskId = .invalid
            }
        }
        
        // Permitir nuevas revocaciones futuras
        self.isRevokingSession = false
    }
    
    // MARK: - Gestión de Background y Foreground (scenePhase y Notificaciones)
    func handleDidEnterBackground() {
        // Recordar si la cámara estaba transmitiendo activamente
        if state == .playing {
            wasPlayingBeforeBackground = true
        }
        
        // 1. Detener reproducción y liberar inmediatamente AVPlayerItem (cancela descargas de segmentos .ts)
        player.pause()
        player.replaceCurrentItem(with: nil)
        
        // 2. Suspender sondeo pasivo y solicitudes de snapshots
        recoveryTask?.cancel()
        recoveryTask = nil
        
        // 3. Revocar sesión activa en Centinela mediante background task protegido
        revokeCurrentSessionSafely()
        
        // 4. Notificar al coordinador para limpiar sesión activa en background
        coordinator.handleAppEnteredBackground()
        
        // 5. Dejar estado en reposo para no mantener buffers de video
        if state == .playing || state == .loading {
            state = .idle
        }
    }
    
    func handleDidBecomeActive() {
        guard isViewActive, let serial = ship.assignedCameraSerial else { return }
        
        coordinator.handleAppBecameActive()
        
        // REGLA FUNDAMENTAL:
        // No iniciar automáticamente las 3 cámaras en el dashboard.
        // Recuperar ÚNICAMENTE la cámara cuya vista de reproducción estaba abierta/activa
        if wasPlayingBeforeBackground && coordinator.shouldResumeOnForeground(for: serial) {
            wasPlayingBeforeBackground = false
            startStreaming(forceRefresh: true)
        } else {
            // Si el usuario estaba en el dashboard general sin video activo,
            // mantener únicamente previsualización sin abrir streams HLS
            if state == .idle && snapshotData == nil {
                Task {
                    if let snap = try? await self.cameraService.fetchSnapshot(for: serial) {
                        guard self.isViewActive else { return }
                        self.snapshotData = snap
                    }
                }
            }
        }
    }
    
    // MARK: - Observadores de Ciclo de Vida y Notificaciones
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleDidEnterBackground()
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleDidBecomeActive()
            }
            .store(in: &cancellables)
    }
    
    private func setupCoordinatorObserver() {
        // Si otra cámara solicita streaming en el dashboard, detener esta para evitar sobrecargar Centinela
        coordinator.$activeStreamingSerial
            .sink { [weak self] activeSerial in
                guard let self = self, let mySerial = self.ship.assignedCameraSerial else { return }
                if let active = activeSerial, active != mySerial && (self.state == .playing || self.state == .loading) {
                    self.stopStreaming()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Recuperación Automática Pasiva (solo mientras la vista esté activa)
    private func startPassiveRecoveryPolling(for serial: String) {
        recoveryTask?.cancel()
        
        recoveryTask = Task { [weak self] in
            while let self = self, self.isViewActive {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard self.isViewActive else { break }
                
                if let response = try? await self.cameraService.fetchLiveStream(for: serial, forceRefresh: true) {
                    if response.isOnline {
                        if self.wasPlayingBeforeBackground || self.coordinator.isStreamingActive(for: serial) {
                            self.startStreaming(forceRefresh: true)
                        } else {
                            self.state = .idle
                            if let snap = try? await self.cameraService.fetchSnapshot(for: serial) {
                                self.snapshotData = snap
                            }
                        }
                        break
                    }
                }
            }
        }
    }
}

/// Vista SwiftUI nativa para reproducir la cámara de un buque
struct CameraPlayerView: View {
    let ship: Ship
    @StateObject private var viewModel: CameraPlayerViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    init(ship: Ship, cameraService: CameraServiceProtocol) {
        self.ship = ship
        _viewModel = StateObject(wrappedValue: CameraPlayerViewModel(ship: ship, cameraService: cameraService))
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.85))
                .cornerRadius(8)
            
            // Fondo con fotografía estática si está disponible
            if let snapData = viewModel.snapshotData, let uiImage = UIImage(data: snapData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(viewModel.state == .playing ? 0.2 : 0.45)
                    .clipped()
                    .cornerRadius(8)
            }
            
            switch viewModel.state {
            case .idle:
                // Previsualización optimizada para dashboard: muestra snapshot con botón de inicio bajo demanda
                Button(action: {
                    viewModel.startStreaming(forceRefresh: true)
                }) {
                    ZStack {
                        Color.clear
                        
                        VStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 2)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("EN LÍNEA • TOCAR PARA VER EN VIVO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(12)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
            case .loading:
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Conectando con Centinela...")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                
            case .playing:
                ZStack(alignment: .topLeading) {
                    VideoPlayer(player: viewModel.player)
                        .cornerRadius(8)
                    
                    HStack {
                        // Badge EN VIVO
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("EN VIVO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(4)
                        
                        Spacer()
                        
                        // Botón Detener reproducción para regresar a modo preview y liberar recursos
                        Button(action: {
                            viewModel.stopStreaming()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 8))
                                Text("Detener")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        }
                    }
                    .padding(8)
                }
                
            case .offline(let message):
                VStack(spacing: 6) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.orange.opacity(0.9))
                    Text(message)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Button(action: {
                        viewModel.startStreaming(forceRefresh: true)
                    }) {
                        Text("Reintentar")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    Text("Revisión automática cada 60s")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                
            case .error(let message):
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.yellow)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white)
                    Button(action: {
                        viewModel.startStreaming(forceRefresh: true)
                    }) {
                        Text("Reintentar")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                .padding()
                
            case .unauthorized:
                VStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                    Text("Acceso a cámara restringido")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                viewModel.handleDidEnterBackground()
            case .active:
                viewModel.handleDidBecomeActive()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
