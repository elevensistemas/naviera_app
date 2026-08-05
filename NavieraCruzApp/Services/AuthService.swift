import Foundation
import Combine

protocol AuthServiceProtocol {
    func login(username: String, passcode: String) async throws -> (User, String)
    func logout() async throws
    func deleteAccount() async throws
}

class MockAuthService: AuthServiceProtocol {
    func login(username: String, passcode: String) async throws -> (User, String) {
        // Simular latencia de red
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if username.lowercased() == "admin" && passcode == "123456" {
            let user = User(id: "1", name: "Administrador", role: "Gerencia", avatarURL: nil)
            let fakeToken = "eyJhbGciOiJIUzI1NiIsInR..."
            return (user, fakeToken)
        } else {
            throw NetworkError.unauthorized
        }
    }
    
    func logout() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func deleteAccount() async throws {
        try await Task.sleep(nanoseconds: 600_000_000)
        // Simular borrado de cuenta local
    }
}

class ProductionAuthService: AuthServiceProtocol {
    struct LoginResponse: Decodable {
        let token: String
        let id: Int?
        let name: String?
        let role: String?
        let username: String?
    }
    
    func login(username: String, passcode: String) async throws -> (User, String) {
        let requestBody: [String: String] = [
            "username": username,
            "password": passcode
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NetworkError.decodingError
        }
        
        let response: LoginResponse = try await APIClient.shared.request(
            endpoint: "/api/v1/login/",
            method: "POST",
            body: httpBody
        )
        
        let userId = response.id != nil ? String(response.id!) : username.lowercased()
        let displayName = response.name ?? response.username ?? username
        let userRole = response.role ?? "Personal Naviera"
        
        let user = User(
            id: userId,
            name: displayName,
            role: userRole,
            avatarURL: nil
        )
        
        return (user, response.token)
    }
    
    func logout() async throws {
        // Enviar petición opcional de logout o revocación de token al servidor
        // En la mayoría de implementaciones Django TokenAuth es suficiente borrar localmente,
        // pero podemos mandar una petición POST vacía a logout si existe en el backend.
        _ = try? await APIClient.shared.request(
            endpoint: "/api/v1/logout/",
            method: "POST"
        ) as [String: String]
    }
    
    func deleteAccount() async throws {
        // Enviar petición DELETE a profile para eliminar la cuenta y sus datos asociados.
        // Cumple con el Guideline de Privacidad de Apple.
        do {
            _ = try await APIClient.shared.request(
                endpoint: "/api/v1/profile/",
                method: "DELETE"
            ) as [String: String]
        } catch {
            print("Notificación de eliminación de cuenta fallida en servidor: \(error.localizedDescription)")
            throw error
        }
    }
}
