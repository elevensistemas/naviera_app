import Foundation

struct Ship: Identifiable, Codable {
    let id: String
    let name: String
    let status: ShipStatus
    let totalCargo: Double // in tons
    let latitude: Double
    let longitude: Double
    let cameraUrl: String? // HLS or image URL for SBS integration
}

enum ShipStatus: String, Codable {
    case active = "Activo"
    case maintenance = "Mantenimiento"
    case docked = "En Puerto"
}
