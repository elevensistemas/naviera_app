import SwiftUI

struct CrewListView: View {
    @State private var crewMembers: [CrewMember] = []
    @State private var isLoading = false
    let shipId: String? // Optional to allow general view or filtered view
    
    private let fleetService: FleetServiceProtocol = AppConfig.isMockActive ? MockFleetService() : ProductionFleetService()
    
    var body: some View {
        ZStack {
            ColorTheme.secondaryBackground.ignoresSafeArea()
            
            if isLoading && crewMembers.isEmpty {
                ProgressView()
            } else if crewMembers.isEmpty {
                Text("No hay tripulación registrada para \(shipId ?? "la flota").")
                    .foregroundColor(.gray)
            } else {
                List(crewMembers) { member in
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ColorTheme.fallbackPrimary.opacity(0.7))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name)
                                .font(Typography.headline())
                            Text(member.role)
                                .font(.caption)
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(member.shipId)
                            .font(.caption2)
                            .padding(4)
                            .background(ColorTheme.info.opacity(0.1))
                            .foregroundColor(ColorTheme.info)
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Tripulación")
        .onAppear {
            loadCrew()
        }
    }
    
    func loadCrew() {
        isLoading = true
        Task {
            do {
                self.crewMembers = try await fleetService.fetchCrew(forShip: shipId ?? "Generico")
            } catch {
                print("Error loading crew: \(error)")
            }
            isLoading = false
        }
    }
}
