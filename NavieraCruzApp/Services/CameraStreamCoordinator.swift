import Foundation
import Combine

/// Coordinador centralizado de transmisiones HLS para la flota de Naviera Cruz del Sur.
/// Controla que en el dashboard solo una cámara mantenga streaming activo a la vez,
/// evitando sobrecargar los servicios de IA, Radar y Caja Negra de Centinela Gateway,
/// y garantizando la revocación inmediata de sesiones al pasar a segundo plano.
@MainActor
class CameraStreamCoordinator: ObservableObject {
    static let shared = CameraStreamCoordinator()
    
    /// Serial de la cámara actualmente autorizada para streaming HLS
    @Published private(set) var activeStreamingSerial: String? = nil
    
    /// Serial de la cámara cuya reproducción estaba abierta antes de entrar a background
    private(set) var resumedSerialOnForeground: String? = nil
    
    private init() {}
    
    /// Solicita acceso exclusivo para reproducir video HLS en una cámara
    func requestStreamingAccess(for serial: String) {
        activeStreamingSerial = serial
        resumedSerialOnForeground = serial
    }
    
    /// Detiene y libera la autorización de streaming para una cámara
    func releaseStreamingAccess(for serial: String) {
        if activeStreamingSerial == serial {
            activeStreamingSerial = nil
        }
        if resumedSerialOnForeground == serial {
            resumedSerialOnForeground = nil
        }
    }
    
    /// Gestiona la transición a segundo plano (bloqueo, cambio de app o home)
    func handleAppEnteredBackground() {
        // Se preserva resumedSerialOnForeground para reactivar ÚNICAMENTE
        // la cámara que estaba abierta al volver a primer plano
        activeStreamingSerial = nil
    }
    
    /// Gestiona el regreso de la app a primer plano
    func handleAppBecameActive() {
        // Restaura únicamente la cámara que estaba reproduciendo previamente
        activeStreamingSerial = resumedSerialOnForeground
    }
    
    /// Indica si esta cámara tiene autorización de streaming activo
    func isStreamingActive(for serial: String) -> Bool {
        return activeStreamingSerial == serial
    }
    
    /// Comprueba si esta cámara debe reanudar su transmisión al volver a primer plano
    func shouldResumeOnForeground(for serial: String) -> Bool {
        return resumedSerialOnForeground == serial
    }
    
    /// Limpia todas las autorizaciones (por ejemplo al cerrar sesión o cambiar de pantalla)
    func resetAll() {
        activeStreamingSerial = nil
        resumedSerialOnForeground = nil
    }
}
