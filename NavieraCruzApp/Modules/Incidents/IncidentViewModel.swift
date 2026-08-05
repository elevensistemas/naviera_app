import Foundation

@MainActor
class IncidentViewModel: ObservableObject {
    @Published var incidents: [Incident] = []
    @Published var isLoading: Bool = false
    
    private let incidentService: IncidentServiceProtocol
    
    init(incidentService: IncidentServiceProtocol = AppConfig.isMockActive ? MockIncidentService() : ProductionIncidentService()) {
        self.incidentService = incidentService
    }
    
    func loadIncidents() {
        isLoading = true
        Task {
            do {
                self.incidents = try await incidentService.fetchIncidents()
            } catch {
                print("Error loading incidents: \(error)")
            }
            self.isLoading = false
        }
    }
    
    func reportIncident(description: String, shipId: String, photos: [Data]) {
        isLoading = true
        Task {
            do {
                let newIncident = try await incidentService.reportIncident(description: description, shipId: shipId, photos: photos)
                self.incidents.insert(newIncident, at: 0)
            } catch {
                print("Error reporting incident: \(error)")
            }
            self.isLoading = false
        }
    }
}
