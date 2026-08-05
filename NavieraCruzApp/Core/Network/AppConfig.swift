import Foundation

struct AppConfig {
    /// Base URL for the production API
    static let apiBaseURL = "https://navieracruzdelsur.dyndns.org:6570"
    
    // ATENCIÓN: Para la revisión de Apple, los evaluadores deben usar datos locales (Mock)
    // ya que el servidor de producción requiere VPN/Intranet. 
    // Asegúrese de compilar con el flag -D APPSTORE_REVIEW o cambiar 'useMockData' a 'true' manualmente antes de subir.
    #if APPSTORE_REVIEW
    static let useMockData = true
    #else
    static let useMockData = false // Cambiar a 'true' manualmente aquí si no se configuran custom flags en Xcode
    #endif
    
    /// Dynamic flag that can enable mock services at runtime if production is offline/VPN restricted.
    static var isMockActive: Bool = useMockData
}
