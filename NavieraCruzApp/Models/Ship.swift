import Foundation

/// Referencia anidada de cámara opcional que puede entregar el backend
struct ShipCameraReference: Identifiable, Codable, Equatable {
    let id: Int?
    let serialNumber: String?
    let name: String?
    let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case serialNumber = "serial_number"
        case name
        case isActive = "is_active"
    }
}

/// Modelo de Buque en Naviera Cruz del Sur
struct Ship: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let status: ShipStatus
    let totalCargo: Double // in tons
    let latitude: Double
    let longitude: Double
    var cameraUrl: String? // HLS or image URL (conservado para retrocompatibilidad)
    var code: String? = nil
    var cameras: [ShipCameraReference]? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case status
        case totalCargo
        case latitude
        case longitude
        case cameraUrl
        case code
        case cameras
    }
    
    init(
        id: String,
        name: String,
        status: ShipStatus,
        totalCargo: Double,
        latitude: Double,
        longitude: Double,
        cameraUrl: String? = nil,
        code: String? = nil,
        cameras: [ShipCameraReference]? = nil
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.totalCargo = totalCargo
        self.latitude = latitude
        self.longitude = longitude
        self.cameraUrl = cameraUrl
        self.code = code
        self.cameras = cameras
    }
    
    /// Código canónico del buque ("alfa", "nany", "gustavo")
    var resolvedShipCode: String {
        if let c = code, !c.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return c.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        let upper = name.uppercased()
        if upper.contains("ALFA") { return "alfa" }
        if upper.contains("NANY") { return "nany" }
        if upper.contains("GUSTAVO") { return "gustavo" }
        return name.lowercased()
    }
    
    /// Número de serie EZVIZ oficial vinculado en Centinela Gateway
    var assignedCameraSerial: String? {
        // 1. Si el buque tiene cámaras anidadas informadas por el backend
        if let cams = cameras, let firstActive = cams.first(where: { $0.isActive ?? true && $0.serialNumber != nil }) {
            if let serial = firstActive.serialNumber, Camera.isAuthorized(serial: serial) {
                return serial
            }
        }
        
        // 2. Mapeo estricto por código oficial de los 3 buques de Naviera Cruz del Sur
        switch resolvedShipCode {
        case "alfa":
            return "BF1765385"
        case "nany":
            return "BF1765344"
        case "gustavo":
            return "BF1767228"
        default:
            return nil
        }
    }
    
    /// Verifica si este buque corresponde al programa independiente MONARCA I (estrictamente excluido)
    var isMonarcaExcluded: Bool {
        let upper = name.uppercased()
        return upper.contains("MONARCA") || (code?.uppercased().contains("MONARCA") ?? false)
    }
}

enum ShipStatus: String, Codable {
    case active = "Activo"
    case maintenance = "Mantenimiento"
    case docked = "En Puerto"
}
