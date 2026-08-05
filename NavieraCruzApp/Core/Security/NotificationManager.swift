import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    // Registration for remote push notifications (APNs)
                    UIApplication.shared.registerForRemoteNotifications()
                } else if let error = error {
                    print("Error solicitando permisos de notificaciones: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Función utilitaria para programar notificaciones locales (Mock de comportamiento)
    func scheduleLocalNotification(title: String, body: String, delay: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error programando notificación: \(error.localizedDescription)")
            }
        }
    }
}

// Extensión para manejar notificaciones mientras la app está en primer plano (Foreground)
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Muestra la alerta tipo banner y sonido incluso con la app abierta
        completionHandler([.banner, .sound, .badge])
    }
}
