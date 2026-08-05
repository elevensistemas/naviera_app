import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognizerManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var isAuthorized = false
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        // Inicializar con español
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
        self.speechRecognizer?.delegate = self
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.isAuthorized = (authStatus == .authorized)
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            // Handle audio permission if needed
        }
    }
    
    func startRecording() throws {
        // Cancel previous task if running
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { fatalError("No se pudo crear SFSpeechAudioBufferRecognitionRequest") }
        
        request.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.request = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        DispatchQueue.main.async {
            self.transcript = ""
            self.isRecording = true
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        request?.endAudio()
        isRecording = false
    }
    
    // Función para que la IA responda por voz
    func speak(text: String) {
        // Detener si hay un audio en curso
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Ajustar sesión a reproducción
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio)
        try? audioSession.setActive(true)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.5 // Velocidad normal a placentera
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
}
