import Foundation

struct AppConfig {
    /// Base URL for the production Intranet API
    static let apiBaseURL = "https://navieracruzdelsur.dyndns.org:6570"
    
    /// Endpoint de la Intranet para solicitar el Camera Access Token (CAT)
    static let cameraTokenEndpoint = "/api/v1/centinela/camera-token/"
    
    /// Gateway URL oficial de Centinela para cámaras (HTTPS exclusivo)
    static let centinelaGatewayURL = "https://centinela.dyndns.org:5073/api/v1/external"
    static let centinelaHostURL = "https://centinela.dyndns.org:5073"
    
    /// Host y puerto únicos autorizados para streaming y fotografías de cámaras
    static let authorizedStreamHost = "centinela.dyndns.org"
    static let authorizedStreamPort = 5073
    
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
    
    /// Validación estricta de seguridad: garantiza que la URL de reproducción
    /// pertenezca única y exclusivamente al host HTTPS oficial de Centinela Gateway
    /// y rechaza terminantemente cualquier dominio de EZVIZ u otros hosts externos.
    static func isValidCentinelaStreamURL(_ url: URL) -> Bool {
        // 1. Debe ser obligatoriamente protocolo seguro HTTPS
        guard let scheme = url.scheme?.lowercased(), scheme == "https" else {
            return false
        }
        
        // 2. Comprobar host
        guard let host = url.host?.lowercased() else {
            return false
        }
        
        // 3. Rechazo absoluto de EZVIZ
        if host.contains("ezvizlife.com") || host.contains("ezviz") {
            return false
        }
        
        // 4. Host autorizado estricto
        guard host == authorizedStreamHost else {
            return false
        }
        
        // 5. Puerto autorizado estricto (5073)
        if let port = url.port {
            guard port == authorizedStreamPort else {
                return false
            }
        }
        
        return true
    }
}
