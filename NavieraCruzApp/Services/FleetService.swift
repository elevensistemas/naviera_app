import Foundation

protocol FleetServiceProtocol {
    func fetchShips() async throws -> [Ship]
    func fetchCrew(forShip id: String) async throws -> [CrewMember]
}

class MockFleetService: FleetServiceProtocol {
    func fetchShips() async throws -> [Ship] {
        try await Task.sleep(nanoseconds: 700_000_000)
        return [
            Ship(id: "s1", name: "Naviera I", status: .active, totalCargo: 1500, latitude: -42.76, longitude: -65.03, cameraUrl: nil),
            Ship(id: "s2", name: "Naviera II", status: .docked, totalCargo: 0, latitude: -38.00, longitude: -57.55, cameraUrl: nil),
            Ship(id: "s3", name: "Naviera III", status: .active, totalCargo: 2200, latitude: -54.80, longitude: -68.30, cameraUrl: nil)
        ]
    }
    
    func fetchCrew(forShip id: String) async throws -> [CrewMember] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            CrewMember(id: "c1", shipId: id, name: "Juan Pérez", role: "Capitán"),
            CrewMember(id: "c2", shipId: id, name: "Carlos Goméz", role: "Jefe de Máquinas")
        ]
    }
}

class ProductionFleetService: FleetServiceProtocol {
    func fetchShips() async throws -> [Ship] {
        return try await APIClient.shared.request(endpoint: "/api/v1/ships/", method: "GET")
    }
    
    func fetchCrew(forShip id: String) async throws -> [CrewMember] {
        // Encodear id de barco en la URL de consulta
        guard let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw NetworkError.invalidURL
        }
        return try await APIClient.shared.request(endpoint: "/api/v1/ships/\(encodedId)/crew/", method: "GET")
    }
}

