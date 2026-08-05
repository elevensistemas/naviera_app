import SwiftUI

struct FinanceView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Dashboard Contable")
                        .font(Typography.title2())
                    Spacer()
                }
                .padding(.horizontal)
                
                // Resumen Ejecutivo
                VStack(spacing: 15) {
                    FinanceRow(title: "Facturación Mensual", amount: "$1.2M", isPositive: true)
                    FinanceRow(title: "Presupuesto Ejecutado", amount: "$850k", isPositive: nil)
                    FinanceRow(title: "Desviación Operativa", amount: "-$45k", isPositive: false)
                }
                .padding()
                .background(ColorTheme.background)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Desglose de Gastos Operativos por Buque
                VStack(alignment: .leading, spacing: 15) {
                    Text("Distribución de Gastos (Flota)")
                        .font(Typography.headline())
                        .foregroundColor(ColorTheme.textPrimary)
                        .padding(.bottom, 5)
                    
                    ExpenseItemRow(label: "Combustible y Lubricantes", amount: "$420,000", percentage: 0.50, color: .orange)
                    ExpenseItemRow(label: "Mantenimiento Técnico", amount: "$250,000", percentage: 0.30, color: .blue)
                    ExpenseItemRow(label: "Sueldos y Personal", amount: "$130,000", percentage: 0.15, color: .green)
                    ExpenseItemRow(label: "Tasas Portuarias y Seguros", amount: "$50,000", percentage: 0.05, color: .purple)
                }
                .padding()
                .background(ColorTheme.background)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Contable")
        .background(ColorTheme.background.ignoresSafeArea())
    }
}

struct FinanceRow: View {
    let title: String
    let amount: String
    let isPositive: Bool?
    
    var body: some View {
        HStack {
            Text(title)
                .font(Typography.body())
                .foregroundColor(ColorTheme.textSecondary)
            
            Spacer()
            
            Text(amount)
                .font(Typography.headline())
                .foregroundColor(
                    isPositive == nil ? ColorTheme.textPrimary :
                        (isPositive! ? ColorTheme.success : ColorTheme.danger)
                )
        }
        .padding(.vertical, 4)
    }
}

struct ExpenseItemRow: View {
    let label: String
    let amount: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(ColorTheme.textSecondary)
                Spacer()
                Text(amount)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.textPrimary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorTheme.secondaryBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 2)
    }
}

