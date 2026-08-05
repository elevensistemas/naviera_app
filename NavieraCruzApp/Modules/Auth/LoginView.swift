import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            VStack(spacing: 8) {
                if UIImage(named: "Logo sugerido") != nil {
                    Image("Logo sugerido")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 15)) // Un pequeño clipping por si el PNG tiene bordes
                        .shadow(radius: 5)
                } else {
                    // Fallback para revisores de Apple o entornos sin assets cargados
                    Image(systemName: "ferry.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .padding(20)
                        .background(ColorTheme.primary.opacity(0.1))
                        .foregroundColor(ColorTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 5)
                }
                
                Text(String(String("NAVIERA CRUZ DEL SUR")))
                    .font(Typography.title2())
                    .bold()
                    .tracking(2)
                    .foregroundColor(ColorTheme.fallbackPrimary)
            }
            
            VStack(spacing: 16) {
                CustomTextField(placeholder: "Usuario (Ej. admin)", text: $viewModel.username)
                    .autocapitalization(.none)
                
                CustomTextField(placeholder: "Contraseña", text: $viewModel.passcode, isSecure: true)
            }
            .padding(.horizontal)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(ColorTheme.danger)
                    .font(Typography.caption())
            }
            
            PrimaryButton(title: "Ingresar", isLoading: viewModel.isLoading) {
                viewModel.login()
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Al ingresar aceptas nuestros")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.textSecondary)
                
                HStack(spacing: 12) {
                    if let privacyURL = URL(string: "https://www.navieracruz.cl/privacy-policy/"),
                       let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        Link("Términos de Uso", destination: eulaURL)
                            .font(.caption2)
                            .foregroundColor(ColorTheme.fallbackAccent)
                            .underline()
                        
                        Text("|")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.textSecondary)
                        
                        Link("Política de Privacidad", destination: privacyURL)
                            .font(.caption2)
                            .foregroundColor(ColorTheme.fallbackAccent)
                            .underline()
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .background(ColorTheme.background.ignoresSafeArea())
    }
}
