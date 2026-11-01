import Foundation

/// Modelo en memoria de una fotografía / captura de cámara
struct CameraSnapshot: Identifiable {
    let id: String
    let serialNumber: String
    let imageData: Data
    let timestamp: Date
    
    /// Indica si la fotografía es reciente (menos de 60 segundos)
    var isFresh: Bool {
        return Date().timeIntervalSince(timestamp) < 60
    }
}
