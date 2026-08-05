import SwiftUI
import AVKit
import AVFoundation

struct FleetView: View {
    @StateObject private var viewModel = FleetViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.secondaryBackground.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.ships.isEmpty {
                    ProgressView()
                } else if viewModel.ships.isEmpty {
                    Text("No hay barcos disponibles.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.ships) { ship in
                                ShipCardView(ship: ship)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        viewModel.loadShips()
                    }
                }
            }
            .navigationTitle("Dashboard de Flota")
            .onAppear {
                viewModel.loadShips()
            }
        }
    }
}

struct ShipCardView: View {
    let ship: Ship
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ship.name)
                    .font(Typography.headline())
                    .foregroundColor(ColorTheme.textPrimary)
                
                Spacer()
                
                Text(ship.status.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(ship.status).opacity(0.2))
                    .foregroundColor(statusColor(ship.status))
                    .cornerRadius(8)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Carga Total")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textSecondary)
                    Text("\(Int(ship.totalCargo)) tons")
                        .font(Typography.body())
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Ubicación")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textSecondary)
                    Text("Lat: \(String(format: "%.2f", ship.latitude)), Lon: \(String(format: "%.2f", ship.longitude))")
                        .font(.caption)
                }
            }
            
            // Functional Video Player for SBS Camera (AVKit HLS Player)
            if let cameraUrlStr = ship.cameraUrl, let url = URL(string: cameraUrlStr) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 150)
                    .cornerRadius(8)
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 150)
                        .cornerRadius(8)
                    
                    VStack {
                        Image(systemName: "video.slash.fill")
                            .foregroundColor(.gray)
                        Text("Cámara SBS no disponible")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(ColorTheme.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func statusColor(_ status: ShipStatus) -> Color {
        switch status {
        case .active: return .green
        case .maintenance: return .orange
        case .docked: return .blue
        }
    }
}
