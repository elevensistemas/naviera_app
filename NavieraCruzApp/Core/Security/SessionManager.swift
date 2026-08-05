import Foundation
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    
    private let tokenKey = "com.navieracruz.authToken"
    
    init() {
        checkSession()
    }
    
    func checkSession() {
        // Intenta recuperar el token del keychain
        if let tokenData = KeychainManager.shared.load(key: tokenKey),
           let _ = String(data: tokenData, encoding: .utf8) {
            
            // Intentar cargar el usuario de UserDefaults
            if let userData = UserDefaults.standard.data(forKey: "com.navieracruz.currentUser"),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                self.currentUser = user
            } else {
                // Fallback si no existe o hay error de decodificación
                self.currentUser = User(id: "1", name: "Usuario Autenticado", role: "Personal Naviera", avatarURL: nil)
            }
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    func login(token: String, user: User) {
        if let data = token.data(using: .utf8) {
            _ = KeychainManager.shared.save(key: tokenKey, data: data)
            self.currentUser = user
            self.isAuthenticated = true
            
            // Guardar usuario en UserDefaults
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "com.navieracruz.currentUser")
            }
        }
    }
    
    func logout() {
        KeychainManager.shared.delete(key: tokenKey)
        UserDefaults.standard.removeObject(forKey: "com.navieracruz.currentUser")
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
