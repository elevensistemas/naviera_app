import Foundation

/// Respuesta estructurada para la URL de video en vivo HLS desde Centinela Gateway
struct CameraLiveResponse: Codable {
    let success: Bool?
    let status: String?
    let streamUrl: String?
    let cameraId: String?
    let vessel: String?
    let expiresAt: String?
    let protocolName: String?
    let error: String?
    let code: String?
    let playbackNotes: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case status
        case streamUrl = "stream_url"
        case cameraId = "camera_id"
        case vessel
        case expiresAt = "expires_at"
        case protocolName = "protocol"
        case error
        case code
        case playbackNotes = "playback_notes"
    }
    
    /// Identificador de sesión temporal (sid) embebido en la URL de streaming
    var sid: String? {
        guard let urlStr = streamUrl, let components = URLComponents(string: urlStr) else { return nil }
        return components.queryItems?.first(where: { $0.name == "sid" })?.value
    }
    
    /// Comprueba si la URL apunta exclusivamente al host y puerto autorizados de Centinela
    var isValidCentinelaStream: Bool {
        guard let urlStr = streamUrl, let url = URL(string: urlStr) else { return false }
        return AppConfig.isValidCentinelaStreamURL(url)
    }
    
    /// Indica si el enlace de video se encuentra disponible y en línea a través de Centinela
    var isOnline: Bool {
        let isOnlineStatus = (status?.lowercased() == "online") || (success == true)
        return isOnlineStatus && streamUrl != nil && isValidCentinelaStream
    }
    
    /// Indica si la cámara está fuera de línea (ej. GUSTAVO U en dique seco)
    var isOffline: Bool {
        return status?.lowercased() == "offline" || code == "CAMERA_OFFLINE" || code == "20007"
    }
    
    /// Mensaje descriptivo del estado o error
    var displayDetail: String {
        if let err = error, !err.isEmpty {
            return err
        }
        if let notes = playbackNotes, !notes.isEmpty {
            return notes
        }
        if isOffline {
            return "Cámara sin conexión"
        }
        return ""
    }
    
    /// Parsea la fecha de expiración informada por Centinela Gateway
    var expirationDate: Date? {
        guard let expiresAt = expiresAt, !expiresAt.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: expiresAt) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: expiresAt)
    }
    
    /// Comprueba si la URL ha vencido o está próxima a vencer dentro del margen de seguridad (ej: 60 s)
    func isExpired(safetyMarginSeconds: TimeInterval = 60) -> Bool {
        guard let exp = expirationDate else {
            return false
        }
        return exp.timeIntervalSince(Date()) <= safetyMarginSeconds
    }
}
