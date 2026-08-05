import Foundation

protocol IncidentServiceProtocol {
    func fetchIncidents() async throws -> [Incident]
    func reportIncident(description: String, shipId: String, photos: [Data]) async throws -> Incident
}

class MockIncidentService: IncidentServiceProtocol {
    func fetchIncidents() async throws -> [Incident] {
        try await Task.sleep(nanoseconds: 600_000_000)
        return [
            Incident(id: "inc1", description: "Falla en generador auxiliar", shipId: "s1", reporterId: "1", date: Date().addingTimeInterval(-86400), status: .inReview, photoURLs: [])
        ]
    }
    
    func reportIncident(description: String, shipId: String, photos: [Data]) async throws -> Incident {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        return Incident(id: UUID().uuidString, description: description, shipId: shipId, reporterId: "1", date: Date(), status: .open, photoURLs: photos.isEmpty ? [] : ["mock_photo_url"])
    }
}

class ProductionIncidentService: IncidentServiceProtocol {
    func fetchIncidents() async throws -> [Incident] {
        return try await APIClient.shared.request(endpoint: "/api/v1/incidents/", method: "GET")
    }
    
    func reportIncident(description: String, shipId: String, photos: [Data]) async throws -> Incident {
        var base64Photos: [String] = []
        for photoData in photos {
            base64Photos.append(photoData.base64EncodedString())
        }
        
        let body: [String: Any] = [
            "description": description,
            "ship": shipId,
            "photos": base64Photos
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            throw NetworkError.decodingError
        }
        
        return try await APIClient.shared.request(endpoint: "/api/v1/incidents/", method: "POST", body: httpBody)
    }
}

