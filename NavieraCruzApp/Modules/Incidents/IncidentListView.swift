import SwiftUI

struct IncidentListView: View {
    @StateObject private var viewModel = IncidentViewModel()
    @State private var showingReportSheet = false
    
    var body: some View {
        ZStack {
            ColorTheme.secondaryBackground.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.incidents.isEmpty {
                ProgressView()
            } else if viewModel.incidents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.success)
                    Text("No hay incidentes de seguridad o HSE reportados.")
                        .foregroundColor(.gray)
                }
            } else {
                List(viewModel.incidents) { incident in
                    IncidentRow(incident: incident)
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    viewModel.loadIncidents()
                }
            }
        }
        .navigationTitle("Incidentes de Seguridad")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingReportSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(ColorTheme.danger)
                }
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportIncidentView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadIncidents()
        }
    }
}

struct IncidentRow: View {
    let incident: Incident
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(statusColor(incident.status))
                    .frame(width: 12, height: 12)
                
                Text(incident.status.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor(incident.status))
                
                Spacer()
                
                Text(incident.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Text(incident.description)
                .font(Typography.body())
                .lineLimit(2)
            
            HStack {
                Image(systemName: "ferry.fill")
                    .foregroundColor(.gray)
                Text("Barco ID: \(incident.shipId)") // Mock, en real cruzar con nombre
                    .font(.caption)
                    .foregroundColor(ColorTheme.textSecondary)
                
                Spacer()
                
                if !incident.photoURLs.isEmpty {
                    Image(systemName: "paperclip")
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
    
    func statusColor(_ status: IncidentStatus) -> Color {
        switch status {
        case .open: return ColorTheme.danger
        case .inReview: return ColorTheme.warning
        case .resolved: return ColorTheme.success
        }
    }
}
