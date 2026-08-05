import Foundation

struct Post: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorName: String
    let content: String
    let timestamp: Date
    let type: PostType
}

enum PostType: String, Codable {
    case news = "Novedad"
    case alert = "Aviso Importante"
    case event = "Evento"
    case birthday = "Cumpleaños"
}
