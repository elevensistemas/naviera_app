import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    
    private let homeService: HomeServiceProtocol
    
    init(homeService: HomeServiceProtocol = AppConfig.isMockActive ? MockHomeService() : ProductionHomeService()) {
        self.homeService = homeService
    }
    
    func loadPosts() {
        isLoading = true
        Task {
            do {
                self.posts = try await homeService.fetchPosts()
            } catch {
                print("Error loading posts: \(error)")
            }
            self.isLoading = false
        }
    }
}
