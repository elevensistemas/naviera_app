import Foundation

protocol HomeServiceProtocol {
    func fetchPosts() async throws -> [Post]
}

class MockHomeService: HomeServiceProtocol {
    func fetchPosts() async throws -> [Post] {
        try await Task.sleep(nanoseconds: 800_000_000)
        return [
            Post(id: "1", authorId: "hr1", authorName: "Recursos Humanos", content: "¡Bienvenidos al nuevo portal móvil de Naviera Cruz del Sur! A partir de hoy centralizaremos comunicados aquí.", timestamp: Date().addingTimeInterval(-86400), type: .news),
            Post(id: "2", authorId: "op1", authorName: "Centro Operativo", content: "Aviso: Zonas de ráfagas fuertes en el sur argentino. Mantener precauciones en flota pesquera.", timestamp: Date().addingTimeInterval(-3600), type: .alert)
        ]
    }
}

class ProductionHomeService: HomeServiceProtocol {
    func fetchPosts() async throws -> [Post] {
        return try await APIClient.shared.request(endpoint: "/api/v1/posts/", method: "GET")
    }
}

