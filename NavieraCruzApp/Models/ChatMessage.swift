import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: String
    let senderId: String
    let text: String
    var attachmentURL: String? = nil
    let timestamp: Date
}

struct ChatChannel: Identifiable, Codable {
    let id: String
    let name: String
    let isGroup: Bool
    let lastMessage: String?
    let lastMessageTimestamp: Date?
}
