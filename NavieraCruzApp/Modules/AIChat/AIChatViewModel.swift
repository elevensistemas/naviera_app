import Foundation

struct AIResponse {
    let id = UUID()
    let text: String
    let isUser: Bool
}

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [AIResponse] = []
    @Published var isProcessing: Bool = false
    
    let speechManager = SpeechRecognizerManager()
    
    init() {
        speechManager.requestPermissions()
        // Bienvenida inicial
        let welcome = "Hola. Soy el asistente operativo de Naviera Cruz del Sur. Puedes preguntarme el estado de nuestra flota, tripulación o cargas por voz o texto."
        messages.append(AIResponse(text: welcome, isUser: false))
    }
    
    func toggleRecording() {
        if speechManager.isRecording {
            speechManager.stopRecording()
            if !speechManager.transcript.isEmpty {
                sendMessage(speechManager.transcript)
            }
        } else {
            try? speechManager.startRecording()
        }
    }
    
    func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Agregar pregunta del usuario
        let userMsg = AIResponse(text: text, isUser: true)
        messages.append(userMsg)
        
        // Procesar respuesta
        processWithAI(query: text)
    }
    
    private func processWithAI(query: String) {
        isProcessing = true
        let lowerQuery = query.lowercased()
        
        // Mock de delay de API LLM
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            var responseText = "No tengo información específica sobre eso. Intenta preguntar sobre estado de barcos, cargas o tripulación."
            
            // Matchers lógicos tipo IA
            if lowerQuery.contains("estado") || lowerQuery.contains("barco") || lowerQuery.contains("naviera i") {
                responseText = "El Naviera I se encuentra Activo en alta mar. El Naviera II está en puerto por mantenimiento programado."
            } else if lowerQuery.contains("carga") || lowerQuery.contains("toneladas") {
                responseText = "Actualmente la flota cuenta con 3,700 toneladas métricas de carga en transporte, distribuidas en dos buques operativos."
            } else if lowerQuery.contains("tripula") || lowerQuery.contains("quien esta") || lowerQuery.contains("capitán") {
                responseText = "El Capitán actual del Naviera I es Juan Pérez. El equipo completo se encuentra operativo y sin incidentes de seguridad reportados."
            }
            
            let assistantMsg = AIResponse(text: responseText, isUser: false)
            self.messages.append(assistantMsg)
            self.isProcessing = false
            
            // Hablar la respuesta!
            self.speechManager.speak(text: responseText)
        }
    }
}
