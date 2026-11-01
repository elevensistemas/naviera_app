import Foundation

/// Estado operativo de una cámara de la flota reportado por Centinela Gateway
enum CameraStatus: String, Codable {
    case online = "online"
    case offline = "offline"
    case error = "error"
    case unknown = "unknown"
}

/// Modelo de Cámara de la Flota para la aplicación iOS de Naviera Cruz del Sur
struct Camera: Identifiable, Codable, Equatable {
    let id: String
    let serialNumber: String
    let name: String
    let shipCode: String
    let shipName: String
    var status: CameraStatus
    var isActive: Bool
    
    // Identificador único para SwiftUI
    var uniqueId: String {
        return "\(serialNumber)-\(shipCode)"
    }
    
    // MARK: - Catálogo oficial estricto de cámaras autorizadas para NavieraCruzApp
    // La app iOS accede EXCLUSIVAMENTE a estos 3 buques.
    // MONARCA I está estrictamente excluido por diseño y arquitectura.
    static let authorizedSerials: Set<String> = [
        "BF1765385", // ALFA C
        "BF1765344", // NANY
        "BF1767228"  // GUSTAVO U
    ]
    
    static let officialFleetCameras: [Camera] = [
        Camera(
            id: "10012",
            serialNumber: "BF1765385",
            name: "Cámara Proa - BT ALFA C",
            shipCode: "alfa",
            shipName: "ALFA C",
            status: .online,
            isActive: true
        ),
        Camera(
            id: "9",
            serialNumber: "BF1765344",
            name: "Cámara Puente - BT NANY",
            shipCode: "nany",
            shipName: "NANY",
            status: .online,
            isActive: true
        ),
        Camera(
            id: "12",
            serialNumber: "BF1767228",
            name: "Cámara Cubierta - BT GUSTAVO U",
            shipCode: "gustavo",
            shipName: "GUSTAVO U",
            status: .online,
            isActive: true
        )
    ]
    
    /// Verifica si un número de serie pertenece a las 3 cámaras autorizadas de la flota
    static func isAuthorized(serial: String) -> Bool {
        return authorizedSerials.contains(serial.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Obtiene la cámara predeterminada para un código de buque ("alfa", "nany", "gustavo")
    static func camera(forShipCode shipCode: String) -> Camera? {
        let normalized = shipCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return officialFleetCameras.first { $0.shipCode.lowercased() == normalized }
    }
    
    /// Obtiene la cámara predeterminada para un número de serie
    static func camera(forSerial serial: String) -> Camera? {
        let normalized = serial.trimmingCharacters(in: .whitespacesAndNewlines)
        return officialFleetCameras.first { $0.serialNumber == normalized }
    }
}
