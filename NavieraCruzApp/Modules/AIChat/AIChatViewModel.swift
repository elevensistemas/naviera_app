import Foundation
import Combine

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [NCSAIMessage] = []
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil
    
    let speechManager = SpeechRecognizerManager()
    private var activeStreamTask: Task<Void, Never>? = nil
    
    let quickPrompts = [
        "Estado Naviera I",
        "ETA Puerto Montt",
        "Reporte de Combustible",
        "Tripulación Activa"
    ]
    
    init() {
        speechManager.requestPermissions()
        setupWelcomeMessage()
    }
    
    private func setupWelcomeMessage() {
        let welcomeText = """
        ¡Hola! Soy el **Asistente IA de NCS Control Center**.
        
        Puedo ayudarte a verificar la telemetría satelital, velocidad de buques, consumo de combustible, horas de arribo (ETA) y dotación de personal en tiempo real.
        """
        
        let initialStructured = NCSStructuredVesselData(
            vesselName: "Naviera I",
            status: "En Operación",
            speed: "12.4 nudos",
            coordinates: "41°48'S 73°45'W",
            eta: "Hoy 18:30",
            fuelLevel: "85%",
            cargoWeight: "1,850 Ton"
        )
        
        let welcomeMessage = NCSAIMessage(
            sender: .assistant,
            text: welcomeText,
            logs: [
                NCSLogItem(category: "info", message: "Conectado a NCS Control Center v4.4")
            ],
            structuredData: initialStructured
        )
        
        messages.append(welcomeMessage)
    }
    
    func toggleRecording() {
        if speechManager.isRecording {
            speechManager.stopRecording()
            let recordedText = speechManager.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !recordedText.isEmpty {
                sendMessage(recordedText, isVoice: true)
            }
        } else {
            do {
                try speechManager.startRecording()
            } catch {
                errorMessage = "Error al iniciar el micrófono: \(error.localizedDescription)"
            }
        }
    }
    
    func sendMessage(_ text: String, isVoice: Bool = false) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        errorMessage = nil
        
        // Add User Message
        let userMsg = NCSAIMessage(sender: .user, text: trimmed)
        messages.append(userMsg)
        
        // Add empty assistant placeholder message with streaming flag
        let assistantMsgId = UUID()
        var assistantMsg = NCSAIMessage(
            id: assistantMsgId,
            sender: .assistant,
            text: "",
            logs: [],
            structuredData: nil,
            isStreaming: true
        )
        messages.append(assistantMsg)
        
        isProcessing = true
        
        // Cancel any previous stream task
        activeStreamTask?.cancel()
        
        activeStreamTask = Task {
            do {
                let stream = NCSChatService.shared.streamChatResponse(prompt: trimmed)
                
                for try await event in stream {
                    guard !Task.isCancelled else { break }
                    
                    if let index = self.messages.firstIndex(where: { $0.id == assistantMsgId }) {
                        if event.type == "log" {
                            let logText = event.content ?? "Procesando solicitud..."
                            let logClass = event.logClass ?? "info"
                            self.messages[index].logs.append(
                                NCSLogItem(category: logClass, message: logText)
                            )
                        } else if event.type == "result" {
                            if let resultText = event.content {
                                self.messages[index].text = resultText
                            }
                            if let structured = event.structured {
                                self.messages[index].structuredData = structured
                            }
                        }
                    }
                }
                
                if let index = self.messages.firstIndex(where: { $0.id == assistantMsgId }) {
                    self.messages[index].isStreaming = false
                    
                    // If sent via voice or user preference, auto-read answer via TTS
                    if isVoice && !self.messages[index].text.isEmpty {
                        let textToSpeak = self.messages[index].text
                        self.speechManager.playTTS(text: textToSpeak)
                    }
                }
            } catch {
                if let index = self.messages.firstIndex(where: { $0.id == assistantMsgId }) {
                    self.messages[index].text = "⚠️ No se pudo completar la consulta con NCS Control Center. Por favor verifique la conexión."
                    self.messages[index].isStreaming = false
                }
                self.errorMessage = error.localizedDescription
            }
            
            self.isProcessing = false
        }
    }
    
    func playTTS(for message: NCSAIMessage) {
        if speechManager.isPlayingAudio {
            speechManager.stopAudioPlayback()
        } else {
            speechManager.playTTS(text: message.text)
        }
    }
    
    func cancelCurrentStream() {
        activeStreamTask?.cancel()
        isProcessing = false
    }
}
