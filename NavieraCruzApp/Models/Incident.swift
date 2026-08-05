import Foundation

struct Incident: Identifiable, Codable {
    let id: String
    let description: String
    let shipId: String
    let reporterId: String
    let date: Date
    let status: IncidentStatus
    var photoURLs: [String] = []
}

enum IncidentStatus: String, Codable {
    case open = "Abierto"
    case inReview = "En Revisión"
    case resolved = "Resuelto"
}
