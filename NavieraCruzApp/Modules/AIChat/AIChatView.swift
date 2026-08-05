import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Contenedor de mensajes
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages, id: \.id) { msg in
                            AIBubble(message: msg)
                                .id(msg.id)
                        }
                        if viewModel.isProcessing {
                            HStack {
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Visualizador de texto temporario de Voz
            if viewModel.speechManager.isRecording {
                Text(viewModel.speechManager.transcript.isEmpty ? "Escuchando..." : viewModel.speechManager.transcript)
                    .italic()
                    .foregroundColor(.gray)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // Barra inferior híbrida
            HStack(spacing: 12) {
                // Entrada de texto
                TextField("Escribe o usa el micrófono", text: $inputText)
                    .padding(12)
                    .background(ColorTheme.secondaryBackground)
                    .cornerRadius(20)
                    .disabled(viewModel.speechManager.isRecording)
                
                // Botón Enviar (si hay texto) o Botón Microfono
                if !inputText.isEmpty {
                    Button(action: {
                        viewModel.sendMessage(inputText)
                        inputText = ""
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(ColorTheme.fallbackAccent)
                            .frame(width: 44, height: 44)
                    }
                } else {
                    Button(action: {
                        viewModel.toggleRecording()
                    }) {
                        Image(systemName: viewModel.speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(viewModel.speechManager.isRecording ? ColorTheme.danger : ColorTheme.fallbackPrimary)
                    }
                }
            }
            .padding()
            .background(ColorTheme.background)
        }
        .navigationTitle("Asistente NCS")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AIBubble: View {
    let message: AIResponse
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            if !message.isUser {
                Image(systemName: "aqi.medium") // AI Icon
                    .foregroundColor(ColorTheme.fallbackAccent)
                    .padding(.trailing, 4)
            }
            
            Text(message.text)
                .padding(14)
                .background(message.isUser ? ColorTheme.fallbackPrimary : ColorTheme.secondaryBackground)
                .foregroundColor(message.isUser ? .white : ColorTheme.textPrimary)
                .cornerRadius(18)
                .font(Typography.body())
            
            if message.isUser { Spacer() }
        }
    }
}
