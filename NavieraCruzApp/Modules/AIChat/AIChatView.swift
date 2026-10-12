import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar - Executive Maritime Badge
            executiveHeader
            
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { msg in
                            AIBubble(message: msg, viewModel: viewModel)
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.messages.last?.logs.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.messages.last?.text) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Quick Prompt Chips
            if viewModel.messages.count <= 2 {
                quickPromptsView
            }
            
            // Dictation / Speech Recognition Status
            if viewModel.speechManager.isRecording {
                speechRecordingBanner
            }
            
            Divider()
                .background(Color.gray.opacity(0.2))
            
            // Bottom Input Bar
            inputBarView
            
            // Apple App Store Compliance AI Disclaimer (MANDATORY)
            aiDisclaimerFooter
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .navigationTitle("NCS Control Center")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Executive Header Badge
    private var executiveHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(ColorTheme.success)
                    .frame(width: 8, height: 8)
                
                Text("NCS AI Control Center • En Línea")
                    .font(Typography.caption())
                    .foregroundColor(ColorTheme.fallbackPrimary)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ColorTheme.fallbackAccent.opacity(0.15))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorTheme.fallbackAccent.opacity(0.4), lineWidth: 1)
            )
            
            Spacer()
            
            if viewModel.isProcessing {
                Button(action: {
                    viewModel.cancelCurrentStream()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Detener")
                            .font(.caption2)
                    }
                    .foregroundColor(ColorTheme.danger)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ColorTheme.danger.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(ColorTheme.secondaryBackground.opacity(0.7))
    }
    
    // MARK: - Quick Prompt Suggestions
    private var quickPromptsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.quickPrompts, id: \.self) { prompt in
                    Button(action: {
                        viewModel.sendMessage(prompt)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(ColorTheme.fallbackAccent)
                            Text(prompt)
                                .font(Typography.caption())
                                .foregroundColor(ColorTheme.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ColorTheme.secondaryBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ColorTheme.fallbackAccent.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Speech Recording Live Transcript
    private var speechRecordingBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .foregroundColor(ColorTheme.danger)
                .symbolEffect(.bounce, options: .repeating)
            
            Text(viewModel.speechManager.transcript.isEmpty ? "Escuchando consulta por voz..." : viewModel.speechManager.transcript)
                .font(Typography.caption())
                .foregroundColor(ColorTheme.textPrimary)
                .italic()
                .lineLimit(2)
            
            Spacer()
            
            Button(action: {
                viewModel.toggleRecording()
            }) {
                Text("Listo")
                    .font(Typography.caption())
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ColorTheme.danger)
                    .cornerRadius(12)
            }
        }
        .padding(12)
        .background(ColorTheme.danger.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
    
    // MARK: - Bottom Input Bar
    private var inputBarView: some View {
        HStack(spacing: 10) {
            TextField("Consulte por flota, ETA, cargas o combustible...", text: $inputText)
                .focused($isInputFocused)
                .padding(12)
                .background(ColorTheme.secondaryBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .disabled(viewModel.speechManager.isRecording || viewModel.isProcessing)
                .onSubmit {
                    sendCurrentInput()
                }
            
            if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: sendCurrentInput) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 38, height: 38)
                        .foregroundColor(ColorTheme.fallbackAccent)
                }
                .disabled(viewModel.isProcessing)
            } else {
                Button(action: {
                    viewModel.toggleRecording()
                }) {
                    Image(systemName: viewModel.speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .resizable()
                        .frame(width: 38, height: 38)
                        .foregroundColor(viewModel.speechManager.isRecording ? ColorTheme.danger : ColorTheme.fallbackPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ColorTheme.background)
    }
    
    // MARK: - App Store Compliance AI Disclaimer
    private var aiDisclaimerFooter: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(ColorTheme.warning)
            
            Text("NCS AI puede cometer errores. Verifique la información operativa.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 6)
        .padding(.top, 2)
        .frame(maxWidth: .infinity)
        .background(ColorTheme.background)
    }
    
    private func sendCurrentInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.sendMessage(text)
        inputText = ""
        isInputFocused = false
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

// MARK: - AI Message Bubble
struct AIBubble: View {
    let message: NCSAIMessage
    @ObservedObject var viewModel: AIChatViewModel
    @State private var isLogsExpanded: Bool = false
    
    var isUser: Bool { message.sender == .user }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isUser { Spacer(minLength: 40) }
            
            if !isUser {
                // AI Icon Avatar
                ZStack {
                    Circle()
                        .fill(ColorTheme.fallbackPrimary)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "aqi.medium")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ColorTheme.fallbackAccent)
                }
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 10) {
                // Sender Name & Time Header
                HStack {
                    Text(isUser ? "Usuario" : "NCS AI")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(ColorTheme.textSecondary)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(Color.gray)
                    
                    Spacer()
                    
                    if !isUser && !message.text.isEmpty {
                        Button(action: {
                            viewModel.playTTS(for: message)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.speechManager.isPlayingAudio ? "speaker.wave.3.fill" : "speaker.wave.2")
                                    .font(.caption2)
                                Text(viewModel.speechManager.isPlayingAudio ? "Detener" : "Escuchar")
                                    .font(.caption2)
                            }
                            .foregroundColor(ColorTheme.fallbackAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ColorTheme.fallbackAccent.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                
                // Processing Log Trace Accordion (if events exist)
                if !isUser && !message.logs.isEmpty {
                    NCSLogTraceAccordion(logs: message.logs, isStreaming: message.isStreaming, isExpanded: $isLogsExpanded)
                }
                
                // Markdown Content Text
                if !message.text.isEmpty {
                    NCSMarkdownText(text: message.text)
                        .padding(14)
                        .background(
                            isUser ?
                            ColorTheme.fallbackPrimary :
                            ColorTheme.secondaryBackground
                        )
                        .foregroundColor(isUser ? .white : ColorTheme.textPrimary)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                } else if message.isStreaming {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.fallbackAccent))
                        Text("Analizando telemetría y generando respuesta...")
                            .font(Typography.caption())
                            .foregroundColor(ColorTheme.textSecondary)
                    }
                    .padding(12)
                    .background(ColorTheme.secondaryBackground)
                    .cornerRadius(16)
                }
                

            }
            
            if isUser {
                // User Avatar
                ZStack {
                    Circle()
                        .fill(ColorTheme.fallbackAccent.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ColorTheme.fallbackPrimary)
                }
            } else {
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Log Trace Accordion Component
struct NCSLogTraceAccordion: View {
    let logs: [NCSLogItem]
    let isStreaming: Bool
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    if isStreaming {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ColorTheme.success)
                            .font(.caption)
                    }
                    
                    Text("Procesamiento NDJSON (\(logs.count) eventos)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.fallbackPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(ColorTheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ColorTheme.fallbackAccent.opacity(0.12))
                .cornerRadius(10)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logs) { log in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .bold()
                                .foregroundColor(ColorTheme.fallbackAccent)
                            Text(log.message)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                    }
                }
                .padding(10)
                .background(ColorTheme.secondaryBackground.opacity(0.8))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Structured Telemetry Card Component
struct NCSStructuredTelemetryCard: View {
    let data: NCSStructuredVesselData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "ferry.fill")
                    .foregroundColor(ColorTheme.fallbackAccent)
                
                Text(data.vesselName ?? "Buque NCS")
                    .font(Typography.headline())
                    .foregroundColor(.white)
                
                Spacer()
                
                if let status = data.status {
                    Text(status)
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTheme.success.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                if let speed = data.speed {
                    telemetryMetricRow(icon: "speedometer", label: "Velocidad", value: speed)
                }
                if let eta = data.eta {
                    telemetryMetricRow(icon: "clock.fill", label: "ETA", value: eta)
                }
                if let fuel = data.fuelLevel {
                    telemetryMetricRow(icon: "fuelpump.fill", label: "Combustible", value: fuel)
                }
                if let cargo = data.cargoWeight {
                    telemetryMetricRow(icon: "shippingbox.fill", label: "Carga", value: cargo)
                }
            }
            
            if let coords = data.coordinates {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(ColorTheme.fallbackAccent)
                    Text("Coordenadas: \(coords)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [ColorTheme.fallbackPrimary, Color(hex: "#0E345A")],
                startPoint: .topLeft,
                endPoint: .bottomRight
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.fallbackAccent.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
    
    private func telemetryMetricRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(ColorTheme.fallbackAccent)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.7))
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Markdown Text Renderer
struct NCSMarkdownText: View {
    let text: String
    
    var body: some View {
        Text(LocalizedStringKey(text))
            .font(Typography.body())
            .lineSpacing(4)
    }
}
