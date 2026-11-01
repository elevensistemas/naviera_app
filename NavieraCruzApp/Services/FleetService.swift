import Foundation

protocol FleetServiceProtocol {
    func fetchShips() async throws -> [Ship]
    func fetchCrew(forShip id: String) async throws -> [CrewMember]
}

class MockFleetService: FleetServiceProtocol {
    func fetchShips() async throws -> [Ship] {
        try await Task.sleep(nanoseconds: 400_000_000)
        return [
            Ship(
                id: "1",
                name: "ALFA C",
                status: .active,
                totalCargo: 1500,
                latitude: -42.76,
                longitude: -65.03,
                cameraUrl: nil,
                code: "alfa"
            ),
            Ship(
                id: "5",
                name: "NANY",
                status: .active,
                totalCargo: 1150,
                latitude: -38.00,
                longitude: -57.55,
                cameraUrl: nil,
                code: "nany"
            ),
            Ship(
                id: "6",
                name: "GUSTAVO U",
                status: .maintenance,
                totalCargo: 0,
                latitude: -54.80,
                longitude: -68.30,
                cameraUrl: nil,
                code: "gustavo"
            )
        ]
    }
    
    func fetchCrew(forShip id: String) async throws -> [CrewMember] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return [
            CrewMember(id: "c1", shipId: id, name: "Marenco Rubén Darío", role: "Capitán"),
            CrewMember(id: "c2", shipId: id, name: "Sosa Armando", role: "Jefe de Máquinas")
        ]
    }
}

class ProductionFleetService: FleetServiceProtocol {
    func fetchShips() async throws -> [Ship] {
        return try await APIClient.shared.request(endpoint: "/api/v1/ships/", method: "GET")
    }
    
    func fetchCrew(forShip id: String) async throws -> [CrewMember] {
        guard let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw NetworkError.invalidURL
        }
        return try await APIClient.shared.request(endpoint: "/api/v1/ships/\(encodedId)/crew/", method: "GET")
    }
}
