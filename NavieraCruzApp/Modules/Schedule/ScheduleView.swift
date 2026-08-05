import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel = ScheduleViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.secondaryBackground.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.schedules.isEmpty {
                    ProgressView()
                } else if viewModel.schedules.isEmpty {
                    Text("No hay programación disponible.")
                } else {
                    List(viewModel.schedules) { schedule in
                        ScheduleRow(schedule: schedule)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .refreshable {
                        viewModel.loadSchedules()
                    }
                }
            }
            .navigationTitle("Programación Mensual")
            .onAppear {
                viewModel.loadSchedules()
            }
        }
    }
}

struct ScheduleRow: View {
    let schedule: Schedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(ColorTheme.fallbackAccent)
                Text(schedule.date, style: .date)
                    .font(Typography.headline())
                
                Spacer()
                
                Text(schedule.shipId) // En una app real, cruzar con Ships list
                    .font(.caption)
                    .padding(6)
                    .background(ColorTheme.fallbackPrimary.opacity(0.1))
                    .foregroundColor(ColorTheme.fallbackPrimary)
                    .cornerRadius(8)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Tipo de Carga")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(schedule.cargoType)
                        .font(Typography.body())
                }
                Spacer()
            }
            
            Text(schedule.details)
                .font(.caption)
                .foregroundColor(ColorTheme.textSecondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}
