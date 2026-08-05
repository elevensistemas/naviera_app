import SwiftUI

struct StatsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Rendimiento de Flota")
                        .font(Typography.title2())
                    Spacer()
                }
                .padding(.horizontal)
                
                // KPIs
                HStack(spacing: 15) {
                    StatCard(title: "Viajes Activos", value: "12", icon: "arrow.triangle.swap", color: ColorTheme.info)
                    StatCard(title: "Eficiencia", value: "94%", icon: "chart.line.uptrend.xyaxis", color: ColorTheme.success)
                }
                .padding(.horizontal)
                
                HStack(spacing: 15) {
                    StatCard(title: "Carga Total Mensual", value: "45k t", icon: "shippingbox.fill", color: ColorTheme.warning)
                    StatCard(title: "Incidentes HSE", value: "3", icon: "exclamationmark.shield.fill", color: ColorTheme.danger)
                }
                .padding(.horizontal)
                
                // Histograma de Eficiencia de Viajes
                VStack(alignment: .leading, spacing: 15) {
                    Text("Eficiencia de Viaje Semanal")
                        .font(Typography.headline())
                        .foregroundColor(ColorTheme.textPrimary)
                    
                    HStack(alignment: .bottom, spacing: 16) {
                        BarChartElement(label: "Sem 1", value: 0.85, efficiency: "85%", color: ColorTheme.info)
                        BarChartElement(label: "Sem 2", value: 0.90, efficiency: "90%", color: ColorTheme.info)
                        BarChartElement(label: "Sem 3", value: 0.94, efficiency: "94%", color: ColorTheme.success)
                        BarChartElement(label: "Sem 4", value: 0.88, efficiency: "88%", color: ColorTheme.info)
                        BarChartElement(label: "Sem 5", value: 0.92, efficiency: "92%", color: ColorTheme.info)
                    }
                    .frame(height: 180)
                    .padding(.top, 10)
                }
                .padding()
                .background(ColorTheme.background)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Estadísticas")
        .background(ColorTheme.background.ignoresSafeArea())
    }
}

struct BarChartElement: View {
    let label: String
    let value: Double
    let efficiency: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            Text(efficiency)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.85))
                .frame(height: CGFloat(value * 120))
            
            Text(label)
                .font(.caption2)
                .foregroundColor(ColorTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}


struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ColorTheme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(ColorTheme.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.background)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
