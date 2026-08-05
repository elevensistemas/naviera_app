import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case unauthorized // 401
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "La URL proporcionada es inválida."
        case .noData: return "No se recibieron datos del servidor."
        case .decodingError: return "Error al procesar la respuesta."
        case .serverError(let code): return "Error en el servidor. Código: \(code)"
        case .unauthorized: return "Sesión expirada. Por favor inicie sesión nuevamente."
        case .unknown: return "Ocurrió un error desconocido."
        }
    }
}

class APIClient {
    static let shared = APIClient()
    private let baseURL = AppConfig.apiBaseURL
    
    /// Generic request handler that calls Django REST APIs.
    /// Will automatically inject the Bearer Token from Keychain if available.
    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Load the session token from keychain if user is logged in
        if let tokenData = KeychainManager.shared.load(key: "com.navieracruz.authToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                // Configure standard date decoding if needed
                decoder.dateDecodingStrategy = .iso8601
                let decodingData = data.isEmpty ? "{}".data(using: .utf8)! : data
                return try decoder.decode(T.self, from: decodingData)
            } catch {
                print("Error decodificando respuesta: \(error)")
                throw NetworkError.decodingError
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
}
