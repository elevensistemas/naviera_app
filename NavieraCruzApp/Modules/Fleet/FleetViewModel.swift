import Foundation

@MainActor
class FleetViewModel: ObservableObject {
    @Published var ships: [Ship] = []
    @Published var isLoading: Bool = false
    
    private let fleetService: FleetServiceProtocol
    
    init(fleetService: FleetServiceProtocol = AppConfig.isMockActive ? MockFleetService() : ProductionFleetService()) {
        self.fleetService = fleetService
    }
    
    func loadShips() {
        isLoading = true
        Task {
            do {
                self.ships = try await fleetService.fetchShips()
            } catch {
                print("Error loading ships: \(error)")
            }
            self.isLoading = false
        }
    }
}
