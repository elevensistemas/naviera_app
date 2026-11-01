import Foundation

/// Protocolo central del servicio de cámaras para la flota de Naviera Cruz del Sur
protocol CameraServiceProtocol {
    /// Obtiene el catálogo de cámaras autorizadas para la flota (ALFA C, NANY, GUSTAVO U)
    func getAuthorizedFleetCameras() async throws -> [Camera]
    
    /// Obtiene la URL temporal HLS para una cámara por su número de serie
    func fetchLiveStream(for serial: String, forceRefresh: Bool) async throws -> CameraLiveResponse
    
    /// Obtiene una fotografía JPEG reciente para una cámara
    func fetchSnapshot(for serial: String) async throws -> Data?
    
    /// Revoca la sesión de streaming activa (sid) en Centinela Gateway
    func revokeSession(for serial: String, sid: String) async
    
    /// Comprueba si una cámara está confirmada como fuera de línea
    func isCameraOffline(serial: String) -> Bool
    
    /// Comprueba si el usuario tiene permisos vigentes para ver esta cámara
    func isCameraAllowed(serial: String) -> Bool
    
    /// Limpia la memoria caché de una cámara o de todas
    func clearCache(for serial: String?)
}

/// Implementación de producción que se comunica directamente con Centinela Gateway
class CentinelaCameraService: CameraServiceProtocol {
    static let shared = CentinelaCameraService()
    
    private let baseURL: String
    private let authProvider: CameraAuthenticationProviderProtocol
    private let urlSession: URLSession
    
    // Caché en memoria de URLs HLS con tiempo de expiración
    private var streamCache: [String: (response: CameraLiveResponse, expiry: Date)] = [:]
    
    // Caché en memoria de capturas JPEG recientes
    private var snapshotCache: [String: (data: Data, timestamp: Date)] = [:]
    
    // Dispositivos confirmados fuera de línea (ej: GUSTAVO U en dique seco)
    private var offlineSerials: Set<String> = []
    
    // Control de concurrencia: tareas en vuelo para evitar llamadas duplicadas simultáneas
    private var inFlightStreamTasks: [String: Task<CameraLiveResponse, Error>] = [:]
    private var inFlightSnapshotTasks: [String: Task<Data?, Error>] = [:]
    
    // Cola serial para sincronización de caché en memoria
    private let cacheQueue = DispatchQueue(label: "com.navieracruz.cameraservice.cache")
    
    init(
        baseURL: String = AppConfig.centinelaGatewayURL,
        authProvider: CameraAuthenticationProviderProtocol = CentinelaUserAuthenticationProvider.shared,
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.authProvider = authProvider
        self.urlSession = urlSession
    }
    
    // MARK: - Catálogo de Cámaras
    func getAuthorizedFleetCameras() async throws -> [Camera] {
        // En primer lugar, filtramos el catálogo canónico oficial garantizando que
        // MONARCA I (o cualquier buque ajeno) NUNCA se procese ni se visualice.
        var fleet = Camera.officialFleetCameras
        
        // Actualizamos los estados en base a la telemetría en memoria
        cacheQueue.sync {
            for i in 0..<fleet.count {
                if offlineSerials.contains(fleet[i].serialNumber) {
                    fleet[i].status = .offline
                }
            }
        }
        return fleet
    }
    
    func isCameraAllowed(serial: String) -> Bool {
        return authProvider.isCameraAllowed(serial: serial)
    }
    
    // MARK: - Obtención de Stream HLS (.m3u8)
    func fetchLiveStream(for serial: String, forceRefresh: Bool = false) async throws -> CameraLiveResponse {
        let cleanSerial = serial.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Verificación estricta de autorización de catálogo oficial
        guard Camera.isAuthorized(serial: cleanSerial) else {
            throw NetworkError.unauthorized
        }
        
        // 2. Verificación de permisos por usuario (allowed_cameras)
        guard authProvider.isCameraAllowed(serial: cleanSerial) else {
            throw NetworkError.unauthorized
        }
        
        // 3. Comprobación de caché en memoria
        if !forceRefresh {
            var cached: CameraLiveResponse? = nil
            cacheQueue.sync {
                if let entry = streamCache[cleanSerial] {
                    // Margen de seguridad de 60 segundos
                    if entry.expiry.timeIntervalSince(Date()) > 60 {
                        cached = entry.response
                    } else {
                        streamCache.removeValue(forKey: cleanSerial)
                    }
                }
            }
            if let valid = cached {
                return valid
            }
        }
        
        // 4. Deduplicación de peticiones en vuelo (evita sobrecargar Centinela)
        let existingTask: Task<CameraLiveResponse, Error>? = cacheQueue.sync {
            return inFlightStreamTasks[cleanSerial]
        }
        if let task = existingTask {
            return try await task.value
        }
        
        // 5. Crear nueva tarea de red
        let newTask = Task<CameraLiveResponse, Error> {
            defer {
                self.cacheQueue.sync {
                    self.inFlightStreamTasks.removeValue(forKey: cleanSerial)
                }
            }
            
            // Construcción del endpoint de Centinela Gateway
            // Ruta estándar: /api/v1/external/cameras/{serial}/stream
            guard let url = URL(string: "\(self.baseURL)/cameras/\(cleanSerial)/stream") else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 12
            
            // Aplicar cabecera 'Authorization: Bearer <CAT>' mediante el provider
            try await self.authProvider.applyAuthentication(to: &request)
            
            do {
                var (data, response) = try await self.urlSession.data(for: request)
                
                guard var httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.unknown
                }
                
                // Manejo de 401 con reintento único seguro (absorbe desfasaje horario inicial de reloj o token vencido)
                if httpResponse.statusCode == 401 {
                    self.authProvider.invalidateCAT()
                    try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 segundos
                    try await self.authProvider.applyAuthentication(to: &request)
                    let retryResult = try await self.urlSession.data(for: request)
                    data = retryResult.0
                    if let retryHttp = retryResult.1 as? HTTPURLResponse {
                        httpResponse = retryHttp
                    }
                }
                
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw NetworkError.unauthorized
                }
                
                // Manejo de cámara offline (503 reportado por Centinela)
                if httpResponse.statusCode == 503 {
                    self.cacheQueue.sync {
                        self.offlineSerials.insert(cleanSerial)
                        self.streamCache.removeValue(forKey: cleanSerial)
                    }
                    
                    if let offlineResponse = try? JSONDecoder().decode(CameraLiveResponse.self, from: data) {
                        return offlineResponse
                    }
                    return CameraLiveResponse(
                        success: false,
                        status: "offline",
                        streamUrl: nil,
                        cameraId: cleanSerial,
                        vessel: nil,
                        expiresAt: nil,
                        protocolName: nil,
                        error: "Cámara sin conexión",
                        code: "CAMERA_OFFLINE",
                        playbackNotes: "Dispositivo temporalmente fuera de línea"
                    )
                }
                
                if httpResponse.statusCode != 200 {
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
                
                let decoder = JSONDecoder()
                let liveResponse = try decoder.decode(CameraLiveResponse.self, from: data)
                
                // Validar estrictamente la URL devuelta por Centinela antes de aceptarla
                if let streamUrlStr = liveResponse.streamUrl, let streamUrl = URL(string: streamUrlStr) {
                    guard AppConfig.isValidCentinelaStreamURL(streamUrl) else {
                        throw NetworkError.unauthorized
                    }
                }
                
                // Actualizar estado offline/online según respuesta de Centinela
                self.cacheQueue.sync {
                    if liveResponse.isOffline {
                        self.offlineSerials.insert(cleanSerial)
                        self.streamCache.removeValue(forKey: cleanSerial)
                    } else {
                        self.offlineSerials.remove(cleanSerial)
                        // Calcular fecha de expiración para la caché
                        let expDate = liveResponse.expirationDate ?? Date().addingTimeInterval(300)
                        self.streamCache[cleanSerial] = (liveResponse, expDate)
                    }
                }
                
                return liveResponse
            } catch {
                throw error
            }
        }
        
        cacheQueue.sync {
            inFlightStreamTasks[cleanSerial] = newTask
        }
        
        return try await newTask.value
    }
    
    // MARK: - Obtención de Fotografía JPEG
    func fetchSnapshot(for serial: String) async throws -> Data? {
        let cleanSerial = serial.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard Camera.isAuthorized(serial: cleanSerial), authProvider.isCameraAllowed(serial: cleanSerial) else {
            return nil
        }
        
        // Si el dispositivo está confirmado como offline (GUSTAVO U), no solicitar fotografía
        // para garantizar que no se muestren imágenes antiguas como actuales.
        if isCameraOffline(serial: cleanSerial) {
            return nil
        }
        
        // Comprobar caché reciente de 30 segundos
        var cachedData: Data? = nil
        cacheQueue.sync {
            if let entry = snapshotCache[cleanSerial], Date().timeIntervalSince(entry.timestamp) < 30 {
                cachedData = entry.data
            }
        }
        if let data = cachedData {
            return data
        }
        
        // Deduplicación en vuelo
        let existingTask: Task<Data?, Error>? = cacheQueue.sync {
            return inFlightSnapshotTasks[cleanSerial]
        }
        if let task = existingTask {
            return try await task.value
        }
        
        let newTask = Task<Data?, Error> {
            defer {
                self.cacheQueue.sync {
                    self.inFlightSnapshotTasks.removeValue(forKey: cleanSerial)
                }
            }
            
            guard let url = URL(string: "\(self.baseURL)/cameras/\(cleanSerial)/snapshot") else {
                return nil
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 8
            try await self.authProvider.applyAuthentication(to: &request)
            
            do {
                var (data, response) = try await self.urlSession.data(for: request)
                guard var httpResponse = response as? HTTPURLResponse else {
                    return nil
                }
                
                // Si Centinela indica 503 (SNAPSHOT_STALE o offline), no usar la imagen
                if httpResponse.statusCode == 503 {
                    self.cacheQueue.sync {
                        self.offlineSerials.insert(cleanSerial)
                        self.snapshotCache.removeValue(forKey: cleanSerial)
                    }
                    return nil
                }
                
                // Manejo de 401 con reintento único
                if httpResponse.statusCode == 401 {
                    self.authProvider.invalidateCAT()
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    try await self.authProvider.applyAuthentication(to: &request)
                    let retryResult = try await self.urlSession.data(for: request)
                    data = retryResult.0
                    if let retryHttp = retryResult.1 as? HTTPURLResponse {
                        httpResponse = retryHttp
                    }
                }
                
                guard httpResponse.statusCode == 200 else {
                    return nil
                }
                
                self.cacheQueue.sync {
                    self.snapshotCache[cleanSerial] = (data, Date())
                }
                return data
            } catch {
                return nil
            }
        }
        
        cacheQueue.sync {
            inFlightSnapshotTasks[cleanSerial] = newTask
        }
        
        return try await newTask.value
    }
    
    // MARK: - Revocación de Sesión HLS en Centinela
    func revokeSession(for serial: String, sid: String) async {
        let cleanSerial = serial.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSid = sid.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard Camera.isAuthorized(serial: cleanSerial), !cleanSid.isEmpty else {
            return
        }
        
        guard let url = URL(string: "\(self.baseURL)/cameras/\(cleanSerial)/session/revoke") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 6
        
        do {
            try await self.authProvider.applyAuthentication(to: &request)
            let bodyDict = ["sid": cleanSid]
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
            
            let (_, response) = try await self.urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Sesión revocada exitosamente en Centinela
            }
            
            // Invalida inmediatamente la entrada en caché para no reutilizar el sid revocado
            self.cacheQueue.sync {
                self.streamCache.removeValue(forKey: cleanSerial)
            }
        } catch {
            // Asegurar que la caché quede limpia incluso si falla la petición de red
            self.cacheQueue.sync {
                self.streamCache.removeValue(forKey: cleanSerial)
            }
        }
    }
    
    func isCameraOffline(serial: String) -> Bool {
        let cleanSerial = serial.trimmingCharacters(in: .whitespacesAndNewlines)
        return cacheQueue.sync {
            offlineSerials.contains(cleanSerial)
        }
    }
    
    func clearCache(for serial: String? = nil) {
        cacheQueue.sync {
            if let s = serial {
                streamCache.removeValue(forKey: s)
                snapshotCache.removeValue(forKey: s)
                offlineSerials.remove(s)
            } else {
                streamCache.removeAll()
                snapshotCache.removeAll()
                offlineSerials.removeAll()
            }
        }
    }
}

// MARK: - Servicio Mock para Pruebas y Revisión de Apple (App Store Review)
class MockCameraService: CameraServiceProtocol {
    func getAuthorizedFleetCameras() async throws -> [Camera] {
        return Camera.officialFleetCameras
    }
    
    func isCameraAllowed(serial: String) -> Bool {
        return Camera.isAuthorized(serial: serial)
    }
    
    func fetchLiveStream(for serial: String, forceRefresh: Bool) async throws -> CameraLiveResponse {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        switch serial {
        case "BF1765385": // ALFA C
            return CameraLiveResponse(
                success: true,
                status: "online",
                streamUrl: "https://centinela.dyndns.org:5073/api/v1/external/cameras/BF1765385/live.m3u8?sid=mock_alfa",
                cameraId: "BF1765385",
                vessel: "BT.ALFAC",
                expiresAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400)),
                protocolName: "HLS",
                error: nil,
                code: "200",
                playbackNotes: "Mock stream para App Review"
            )
        case "BF1765344": // NANY
            return CameraLiveResponse(
                success: true,
                status: "online",
                streamUrl: "https://centinela.dyndns.org:5073/api/v1/external/cameras/BF1765344/live.m3u8?sid=mock_nany",
                cameraId: "BF1765344",
                vessel: "BT.NANY1",
                expiresAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400)),
                protocolName: "HLS",
                error: nil,
                code: "200",
                playbackNotes: "Mock stream para App Review"
            )
        case "BF1767228": // GUSTAVO U
            return CameraLiveResponse(
                success: true,
                status: "online",
                streamUrl: "https://centinela.dyndns.org:5073/api/v1/external/cameras/BF1767228/live.m3u8?sid=mock_gustavo",
                cameraId: "BF1767228",
                vessel: "BT.GUSTAVO.U",
                expiresAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400)),
                protocolName: "HLS",
                error: nil,
                code: "200",
                playbackNotes: "Mock stream para App Review"
            )
        default:
            throw NetworkError.serverError(404)
        }
    }
    
    func fetchSnapshot(for serial: String) async throws -> Data? {
        return nil
    }
    
    func revokeSession(for serial: String, sid: String) async {}
    
    func isCameraOffline(serial: String) -> Bool {
        return false
    }
    
    func clearCache(for serial: String?) {}
}
