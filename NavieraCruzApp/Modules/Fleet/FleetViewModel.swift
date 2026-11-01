import Foundation

@MainActor
class FleetViewModel: ObservableObject {
    @Published var ships: [Ship] = []
    @Published var isLoading: Bool = false
    
    let fleetService: FleetServiceProtocol
    let cameraService: CameraServiceProtocol
    
    init(
        fleetService: FleetServiceProtocol = AppConfig.isMockActive ? MockFleetService() : ProductionFleetService(),
        cameraService: CameraServiceProtocol = AppConfig.isMockActive ? MockCameraService() : CentinelaCameraService.shared
    ) {
        self.fleetService = fleetService
        self.cameraService = cameraService
    }
    
    func loadShips() {
        isLoading = true
        Task {
            // Sincronizar CAT para conocer allowed_cameras del usuario actual de inmediato
            _ = try? await CentinelaUserAuthenticationProvider.shared.getValidCameraAccessToken()
            
            do {
                let fetchedShips = try await fleetService.fetchShips()
                
                // Filtro estricto de seguridad:
                // 1. Descartar completamente MONARCA I (o cualquier buque ajeno)
                // 2. Mantener únicamente los buques autorizados de la flota (ALFA C, NANY, GUSTAVO U)
                let validFleet = fetchedShips.filter { ship in
                    guard !ship.isMonarcaExcluded else { return false }
                    let code = ship.resolvedShipCode
                    return code == "alfa" || code == "nany" || code == "gustavo"
                }
                
                // Ordenamiento canónico de la flota
                self.ships = validFleet.sorted { s1, s2 in
                    let order = ["alfa": 1, "nany": 2, "gustavo": 3]
                    let o1 = order[s1.resolvedShipCode] ?? 99
                    let o2 = order[s2.resolvedShipCode] ?? 99
                    return o1 < o2
                }
            } catch {
                // Registro seguro de error sin exponer rutas ni credenciales
                print("Error cargando buques de flota: \(error.localizedDescription)")
            }
            self.isLoading = false
        }
    }
}
