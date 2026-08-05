import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var channels: [ChatChannel] = []
    @Published var currentMessages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var blockedUserIds: Set<String> = []
    
    private let chatService: ChatServiceProtocol
    
    init(chatService: ChatServiceProtocol = AppConfig.isMockActive ? MockChatService() : ProductionChatService()) {
        self.chatService = chatService
    }
    
    func loadChannels() {
        isLoading = true
        Task {
            do {
                self.channels = try await chatService.fetchChannels()
            } catch {
                print("Error loading channels: \(error)")
            }
            self.isLoading = false
        }
    }
    
    func loadMessages(for channelId: String) {
        isLoading = true
        Task {
            do {
                self.currentMessages = try await chatService.fetchMessages(forChannel: channelId)
            } catch {
                print("Error loading messages: \(error)")
            }
            self.isLoading = false
        }
    }
    
    func sendMessage(text: String, channelId: String, attachment: Data? = nil) {
        Task {
            do {
                let newMessage = try await chatService.sendMessage(text: text, channelId: channelId, attachment: attachment)
                self.currentMessages.append(newMessage)
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
    
    func reportMessage(messageId: String, senderId: String, reason: String) async throws {
        try await chatService.report(reportedUserId: senderId, messageId: messageId, reason: reason)
    }
    
    func blockUser(userId: String) async throws {
        try await chatService.block(blockedUserId: userId, block: true)
        self.blockedUserIds.insert(userId)
    }
    
    func unblockUser(userId: String) async throws {
        try await chatService.block(blockedUserId: userId, block: false)
        self.blockedUserIds.remove(userId)
    }
}
