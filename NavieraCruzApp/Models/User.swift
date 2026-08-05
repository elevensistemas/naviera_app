import Foundation

struct User: Identifiable, Codable {
    let id: String
    let name: String
    let role: String
    let avatarURL: String?
    var sector: String = "Operaciones"
    var birthDate: Date? = nil
}
