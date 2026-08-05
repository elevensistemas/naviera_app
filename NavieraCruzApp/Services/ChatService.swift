import Foundation

protocol ChatServiceProtocol {
    func fetchChannels() async throws -> [ChatChannel]
    func fetchMessages(forChannel id: String) async throws -> [ChatMessage]
    func sendMessage(text: String, channelId: String, attachment: Data?) async throws -> ChatMessage
    func report(reportedUserId: String?, messageId: String?, reason: String) async throws
    func block(blockedUserId: String, block: Bool) async throws
}

class MockChatService: ChatServiceProtocol {
    func fetchChannels() async throws -> [ChatChannel] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            ChatChannel(id: "ch1", name: "Operaciones Central", isGroup: true, lastMessage: "¿Cómo viene la carga del Naviera I?", lastMessageTimestamp: Date()),
            ChatChannel(id: "ch2", name: "Capitán Pérez", isGroup: false, lastMessage: "Recibido.", lastMessageTimestamp: Date().addingTimeInterval(-3600))
        ]
    }
    
    func fetchMessages(forChannel id: String) async throws -> [ChatMessage] {
        try await Task.sleep(nanoseconds: 400_000_000)
        return [
            ChatMessage(id: "m1", senderId: "other", text: "Reporte de situación enviado", timestamp: Date().addingTimeInterval(-7200)),
            ChatMessage(id: "m2", senderId: "1", text: "Excelente, gracias.", timestamp: Date().addingTimeInterval(-7000)) // "1" is our mock user ID
        ]
    }
    
    func sendMessage(text: String, channelId: String, attachment: Data?) async throws -> ChatMessage {
        try await Task.sleep(nanoseconds: 300_000_000)
        return ChatMessage(id: UUID().uuidString, senderId: "1", text: text, attachmentURL: attachment != nil ? "mock_url" : nil, timestamp: Date())
    }
    
    func report(reportedUserId: String?, messageId: String?, reason: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
    
    func block(blockedUserId: String, block: Bool) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}

class ProductionChatService: ChatServiceProtocol {
    func fetchChannels() async throws -> [ChatChannel] {
        return try await APIClient.shared.request(endpoint: "/api/v1/chat/channels/", method: "GET")
    }
    
    func fetchMessages(forChannel id: String) async throws -> [ChatMessage] {
        guard let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw NetworkError.invalidURL
        }
        return try await APIClient.shared.request(endpoint: "/api/v1/chat/channels/\(encodedId)/messages/", method: "GET")
    }
    
    func sendMessage(text: String, channelId: String, attachment: Data?) async throws -> ChatMessage {
        var base64Attachment: String? = nil
        if let attachment = attachment {
            base64Attachment = attachment.base64EncodedString()
        }
        
        let body: [String: Any] = [
            "text": text,
            "channel": channelId,
            "attachment": base64Attachment as Any
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            throw NetworkError.decodingError
        }
        
        guard let encodedId = channelId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw NetworkError.invalidURL
        }
        
        return try await APIClient.shared.request(endpoint: "/api/v1/chat/channels/\(encodedId)/messages/", method: "POST", body: httpBody)
    }
    
    func report(reportedUserId: String?, messageId: String?, reason: String) async throws {
        var body: [String: Any] = [
            "reason": reason
        ]
        if let userId = reportedUserId, let userInt = Int(userId) {
            body["reported_user_id"] = userInt
        }
        if let msgId = messageId, let msgInt = Int(msgId) {
            body["message_id"] = msgInt
        }
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            throw NetworkError.decodingError
        }
        
        _ = try await APIClient.shared.request(
            endpoint: "/api/v1/chat/report/",
            method: "POST",
            body: httpBody
        ) as [String: String]
    }
    
    func block(blockedUserId: String, block: Bool) async throws {
        guard let userInt = Int(blockedUserId) else {
            throw NetworkError.invalidURL
        }
        
        let body: [String: Any] = [
            "blocked_user_id": userInt,
            "block": block
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            throw NetworkError.decodingError
        }
        
        _ = try await APIClient.shared.request(
            endpoint: "/api/v1/chat/block/",
            method: "POST",
            body: httpBody
        ) as [String: String]
    }
}

