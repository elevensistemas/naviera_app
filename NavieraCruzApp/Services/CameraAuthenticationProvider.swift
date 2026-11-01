import Foundation

/// Respuesta del endpoint de la Intranet para la emisión de CAT
struct CameraTokenResponse: Codable {
    let cameraAccessToken: String
    let tokenType: String
    let expiresIn: Int
    let expiresAt: String?
    let allowedCameras: [String]
    
    enum CodingKeys: String, CodingKey {
        case cameraAccessToken = "camera_access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case allowedCameras = "allowed_cameras"
    }
}

/// Protocolo que abstrae el manejo seguro del Camera Access Token (CAT)
protocol CameraAuthenticationProviderProtocol {
    /// Inyecta la cabecera 'Authorization: Bearer <CAT>' en la solicitud saliente
    func applyAuthentication(to request: inout URLRequest) async throws
    
    /// Obtiene un Camera Access Token vigente (renovándolo automáticamente si ha vencido)
    func getValidCameraAccessToken() async throws -> String
    
    /// Comprueba si una cámara está autorizada en el conjunto 'allowed_cameras' del usuario
    func isCameraAllowed(serial: String) -> Bool
    
    /// Invalida y purga el CAT almacenado en memoria local (ej. al cerrar sesión)
    func invalidateCAT()
    
    /// Indica si el usuario actual cuenta con una sesión válida activa en la Intranet
    var hasValidCredentials: Bool { get }
}

/// Proveedor de autenticación que gestiona el ciclo de vida del Camera Access Token (CAT)
class CentinelaUserAuthenticationProvider: CameraAuthenticationProviderProtocol {
    static let shared = CentinelaUserAuthenticationProvider()
    
    private let tokenKey = "com.navieracruz.authToken"
    private let urlSession: URLSession
    
    // Almacenamiento en memoria del CAT y su fecha de expiración
    private var cachedCAT: String? = nil
    private var catExpirationDate: Date? = nil
    private var currentAllowedCameras: Set<String> = []
    
    // Tarea asíncrona en vuelo para evitar peticiones duplicadas de renovación de CAT
    private var inFlightTokenTask: Task<CameraTokenResponse, Error>? = nil
    private let lockQueue = DispatchQueue(label: "com.navieracruz.cat.auth.lock")
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    var hasValidCredentials: Bool {
        return SessionManager.shared.isAuthenticated
    }
    
    /// Comprueba si el serial está dentro del listado 'allowed_cameras' otorgado por la Intranet
    func isCameraAllowed(serial: String) -> Bool {
        let clean = serial.trimmingCharacters(in: .whitespacesAndNewlines)
        return lockQueue.sync {
            // Si aún no se solicitó el CAT, permitimos la comprobación inicial del catálogo
            if currentAllowedCameras.isEmpty {
                return Camera.isAuthorized(serial: clean)
            }
            return currentAllowedCameras.contains(clean) && Camera.isAuthorized(serial: clean)
        }
    }
    
    /// Obtiene un CAT válido, renovándolo automáticamente contra la Intranet si expiró
    func getValidCameraAccessToken() async throws -> String {
        // 1. Verificar si el token en caché está vigente (con margen de seguridad de 60 segundos)
        var validToken: String? = nil
        lockQueue.sync {
            if let token = cachedCAT, let exp = catExpirationDate {
                if exp.timeIntervalSince(Date()) > 60 {
                    validToken = token
                }
            }
        }
        if let token = validToken {
            return token
        }
        
        // 2. Si ya hay una solicitud de renovación en vuelo, reutilizarla
        let existingTask: Task<CameraTokenResponse, Error>? = lockQueue.sync {
            return inFlightTokenTask
        }
        if let task = existingTask {
            let res = try await task.value
            return res.cameraAccessToken
        }
        
        // 3. Crear nueva tarea para solicitar el CAT a la Intranet
        let newTask = Task<CameraTokenResponse, Error> {
            defer {
                self.lockQueue.sync {
                    self.inFlightTokenTask = nil
                }
            }
            
            // Cargar el token de sesión de la intranet desde Keychain
            guard let tokenData = KeychainManager.shared.load(key: self.tokenKey),
                  let intranetToken = String(data: tokenData, encoding: .utf8),
                  !intranetToken.isEmpty else {
                throw NetworkError.unauthorized
            }
            
            guard let url = URL(string: "\(AppConfig.apiBaseURL)\(AppConfig.cameraTokenEndpoint)") else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Token \(intranetToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = "{}".data(using: .utf8)
            request.timeoutInterval = 10
            
            let (data, response) = try await self.urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw NetworkError.unauthorized
            } else if httpResponse.statusCode != 200 {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let tokenResponse = try decoder.decode(CameraTokenResponse.self, from: data)
            
            // Guardar en memoria el CAT, allowed_cameras y la fecha de expiración
            self.lockQueue.sync {
                self.cachedCAT = tokenResponse.cameraAccessToken
                self.currentAllowedCameras = Set(tokenResponse.allowedCameras)
                
                // Calcular fecha de expiración (preferir 'expires_in' en segundos)
                let ttl = TimeInterval(tokenResponse.expiresIn)
                self.catExpirationDate = Date().addingTimeInterval(ttl)
            }
            
            // Pausa preventiva de 2 segundos para absorber la diferencia de reloj NTP entre Intranet y Centinela Gateway
            // Esto garantiza que el claim 'nbf' (not before) ya sea válido en Centinela desde la primera petición
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            return tokenResponse
        }
        
        lockQueue.sync {
            inFlightTokenTask = newTask
        }
        
        let tokenResponse = try await newTask.value
        return tokenResponse.cameraAccessToken
    }
    
    /// Inyecta la cabecera 'Authorization: Bearer <CAT>' en la petición
    func applyAuthentication(to request: inout URLRequest) async throws {
        let cat = try await getValidCameraAccessToken()
        request.setValue("Bearer \(cat)", forHTTPHeaderField: "Authorization")
    }
    
    /// Invalida y elimina el CAT de la memoria
    func invalidateCAT() {
        lockQueue.sync {
            cachedCAT = nil
            catExpirationDate = nil
            currentAllowedCameras.removeAll()
            inFlightTokenTask?.cancel()
            inFlightTokenTask = nil
        }
    }
}
