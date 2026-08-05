import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionManager
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingDeleteAccountAlert = false
    @State private var showingLogoutAlert = false
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            List {
                if let user = session.currentUser {
                    Section {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(ColorTheme.fallbackPrimary)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(user.name.prefix(1).uppercased())
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                  )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(Typography.title2())
                                Text(user.role)
                                    .font(Typography.body())
                                    .foregroundColor(ColorTheme.textSecondary)
                                Text("Sector: \(user.sector)")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.fallbackAccent)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Configuración General")) {
                    Toggle(isOn: Binding(
                        get: { themeManager.colorScheme == .dark },
                        set: { _ in themeManager.toggleTheme() }
                    )) {
                        Label("Modo Oscuro", systemImage: "moon.fill")
                    }
                    
                    NavigationLink(destination: FinanceView()) {
                        Label("Módulo Contable (Gerencial)", systemImage: "chart.pie.fill")
                            .foregroundColor(ColorTheme.textPrimary)
                    }
                    
                    NavigationLink(destination: StatsView()) {
                        Label("Estadísticas Operativas", systemImage: "chart.bar.xaxis")
                            .foregroundColor(ColorTheme.textPrimary)
                    }
                    
                    NavigationLink(destination: CrewListView(shipId: nil)) {
                        Label("Tripulación Actual", systemImage: "person.3.sequence.fill")
                            .foregroundColor(ColorTheme.textPrimary)
                    }
                    
                    NavigationLink(destination: IncidentListView()) {
                        Label("Incidentes HSE", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(ColorTheme.danger)
                    }
                }
                
                Section(header: Text("Privacidad")) {
                    if let privacyURL = URL(string: "https://www.navieracruz.cl/privacy-policy/"),
                       let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        Link(destination: privacyURL) {
                            Label("Política de Privacidad", systemImage: "doc.text.fill")
                                .foregroundColor(ColorTheme.textPrimary)
                        }
                        
                        Link(destination: eulaURL) {
                            Label("Términos de Uso (EULA)", systemImage: "scroll.fill")
                                .foregroundColor(ColorTheme.textPrimary)
                        }
                    }
                    
                    Button(action: {
                        showingDeleteAccountAlert = true
                    }) {
                        HStack {
                            Label("Eliminar mi Cuenta", systemImage: "trash.fill")
                                .foregroundColor(ColorTheme.danger)
                            if isDeletingAccount {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isDeletingAccount)
                    .alert(isPresented: $showingDeleteAccountAlert) {
                        Alert(
                            title: Text("Eliminar Cuenta"),
                            message: Text("¿Estás completamente seguro de que deseas eliminar tu cuenta? Esta acción borrará de forma permanente todos tus datos personales y es irreversible."),
                            primaryButton: .destructive(Text("Eliminar")) {
                                deleteUserAccount()
                            },
                            secondaryButton: .cancel(Text("Cancelar"))
                        )
                    }
                    
                    if let errorMessage = deleteErrorMessage {
                        Text(errorMessage)
                            .foregroundColor(ColorTheme.danger)
                            .font(.caption)
                            .padding(.top, 4)
                    }
                }
                
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Label("Cerrar Sesión", systemImage: "arrow.right.circle.fill")
                            .foregroundColor(ColorTheme.danger)
                    }
                    .alert(isPresented: $showingLogoutAlert) {
                        Alert(
                            title: Text("Cerrar Sesión"),
                            message: Text("¿Estás seguro que deseas desconectarte?"),
                            primaryButton: .destructive(Text("Salir")) {
                                session.logout()
                            },
                            secondaryButton: .cancel(Text("Cancelar"))
                        )
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Mi Perfil")
        }
    }
    
    private func deleteUserAccount() {
        isDeletingAccount = true
        deleteErrorMessage = nil
        Task {
            do {
                let authService: AuthServiceProtocol = AppConfig.isMockActive ? MockAuthService() : ProductionAuthService()
                try await authService.deleteAccount()
                isDeletingAccount = false
                session.logout()
            } catch {
                isDeletingAccount = false
                deleteErrorMessage = "No se pudo eliminar la cuenta: \(error.localizedDescription)"
                // No forzar logout para que el usuario sepa que no se pudo borrar y pueda reintentar
            }
        }
    }
}

// TripulacionPlaceholderView removed to comply with Guideline 2.1 (No Placeholders)
