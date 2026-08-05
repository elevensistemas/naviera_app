import Foundation

struct CrewMember: Identifiable, Codable {
    let id: String
    let shipId: String
    let name: String
    let role: String
}

struct Schedule: Identifiable, Codable {
    let id: String
    let shipId: String
    let date: Date
    let cargoType: String
    let details: String
}
