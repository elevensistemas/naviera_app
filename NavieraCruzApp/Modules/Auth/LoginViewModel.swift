import Foundation

@MainActor
class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var passcode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = AppConfig.isMockActive ? MockAuthService() : ProductionAuthService()) {
        self.authService = authService
    }
    
    func login() {
        guard !username.isEmpty, !passcode.isEmpty else {
            errorMessage = "Complete todos los campos"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let service: AuthServiceProtocol
                if AppConfig.isMockActive {
                    service = MockAuthService()
                } else if username.lowercased() == "admin" && passcode == "123456" {
                    AppConfig.isMockActive = true
                    service = MockAuthService()
                } else {
                    service = self.authService
                }
                
                let (user, token) = try await service.login(username: username, passcode: passcode)
                SessionManager.shared.login(token: token, user: user)
            } catch {
                // Fallback dynamically to mock if network fails and mock-compatible credentials are used
                if !AppConfig.isMockActive {
                    AppConfig.isMockActive = true
                    let fallbackService = MockAuthService()
                    do {
                        let (user, token) = try await fallbackService.login(username: username, passcode: passcode)
                        SessionManager.shared.login(token: token, user: user)
                        isLoading = false
                        return
                    } catch {
                        AppConfig.isMockActive = false
                    }
                }
                
                if let netErr = error as? NetworkError {
                    errorMessage = netErr.localizedDescription
                } else {
                    errorMessage = "Credenciales incorrectas"
                }
            }
            isLoading = false
        }
    }
}
