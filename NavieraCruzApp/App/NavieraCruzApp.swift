import SwiftUI

// Adaptador necesario para delegados del ciclo de vida (Notificaciones remotas)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token de Apple recibido: \(token)")
        // En un futuro este token se envía al Backend vía APIClient para Firebase/APNs
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Fallo el registro en APNs: \(error.localizedDescription)")
    }
}

@main
struct NavieraCruzApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if sessionManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(sessionManager)
                        .transition(.opacity)
                        .onAppear {
                            // Solicitar permisos de notificación al entrar a la app por primera vez
                            notificationManager.requestAuthorization()
                        }
                } else {
                    LoginView()
                        .environmentObject(sessionManager)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: sessionManager.isAuthenticated)
            .preferredColorScheme(themeManager.colorScheme)
            .accentColor(ColorTheme.primary)
        }
    }
}
