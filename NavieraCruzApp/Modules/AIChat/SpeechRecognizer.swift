import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognizerManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var isAuthorized = false
    @Published var isPlayingAudio = false
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var player: AVPlayer?
    private var playerItemObserver: AnyCancellable?
    private var localSynthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-CL")) ?? SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
        self.speechRecognizer?.delegate = self
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.isAuthorized = (authStatus == .authorized)
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }
    
    func startRecording() throws {
        // Stop any ongoing audio playback
        stopAudioPlayback()
        
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        
        request.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
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
        
        self.transcript = ""
        self.isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        request?.endAudio()
        isRecording = false
    }
    
    // MARK: - Audio TTS Streaming & Playback
    
    /// Stream TTS audio from endpoint or fallback to local synthesis
    func playTTS(text: String, audioURL: URL? = nil) {
        stopAudioPlayback()
        
        guard let url = audioURL ?? NCSChatService.shared.getTTSAudioURL(for: text) else {
            speakFallback(text: text)
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        isPlayingAudio = true
        
        // Listen for playback completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        player?.play()
    }
    
    @objc private func playerItemDidReachEnd(notification: Notification) {
        DispatchQueue.main.async {
            self.isPlayingAudio = false
        }
    }
    
    func stopAudioPlayback() {
        if player != nil {
            player?.pause()
            player = nil
        }
        if localSynthesizer.isSpeaking {
            localSynthesizer.stopSpeaking(at: .immediate)
        }
        isPlayingAudio = false
    }
    
    private func speakFallback(text: String) {
        let cleanText = text
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "`", with: "")
        
        let utterance = AVSpeechUtterance(string: cleanText)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-CL") ?? AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.5
        
        isPlayingAudio = true
        localSynthesizer.speak(utterance)
    }
}
