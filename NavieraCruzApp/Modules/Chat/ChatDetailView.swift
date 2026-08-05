import SwiftUI

struct ChatDetailView: View {
    @ObservedObject var viewModel: ChatViewModel
    let channel: ChatChannel
    
    @State private var messageText: String = ""
    @State private var activeAlert: ActiveAlert? = nil
    @State private var showingImagePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage? = nil
    
    enum ActiveAlert: Identifiable {
        case reportConfirmation(ChatMessage)
        case blockConfirmation(String)
        case status(String)
        
        var id: String {
            switch self {
            case .reportConfirmation(let msg): return "report_\(msg.id)"
            case .blockConfirmation(let usr): return "block_\(usr)"
            case .status(let msg): return "status_\(msg)"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.currentMessages.filter { !viewModel.blockedUserIds.contains($0.senderId) }) { message in
                            MessageBubble(message: message, isCurrentUser: message.senderId == SessionManager.shared.currentUser?.id)
                                .id(message.id)
                                .contextMenu {
                                    if message.senderId != SessionManager.shared.currentUser?.id {
                                        Button(action: {
                                            activeAlert = .reportConfirmation(message)
                                        }) {
                                            Label("Reportar Mensaje", systemImage: "exclamationmark.triangle")
                                        }
                                        
                                        Button(action: {
                                            activeAlert = .blockConfirmation(message.senderId)
                                        }) {
                                            Label("Bloquear Usuario", systemImage: "hand.raised.fill")
                                        }
                                    }
                                }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.currentMessages.count) { _ in
                    if let last = viewModel.currentMessages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            if let selectedImage = selectedImage {
                HStack {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            Button(action: {
                                self.selectedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Circle().fill(Color.white))
                            }
                            .offset(x: 5, y: -5),
                            alignment: .topTrailing
                        )
                        .padding(.vertical, 8)
                    Spacer()
                }
                .padding(.horizontal)
                .background(ColorTheme.secondaryBackground.opacity(0.5))
            }
            
            Divider()
            
            HStack {
                Button(action: {
                    pickerSourceType = .photoLibrary
                    showingImagePicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(ColorTheme.fallbackAccent)
                }
                
                Button(action: {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        pickerSourceType = .camera
                        showingImagePicker = true
                    } else {
                        activeAlert = .status("La cámara no está disponible en este dispositivo.")
                    }
                }) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(ColorTheme.fallbackAccent)
                }
                
                TextField("Escribir mensaje...", text: $messageText)
                    .padding(10)
                    .background(ColorTheme.secondaryBackground)
                    .cornerRadius(20)
                
                Button(action: {
                    guard !messageText.isEmpty || selectedImage != nil else { return }
                    
                    var attachmentData: Data? = nil
                    if let image = selectedImage {
                        attachmentData = image.jpegData(compressionQuality: 0.8)
                    }
                    
                    viewModel.sendMessage(text: messageText, channelId: channel.id, attachment: attachmentData)
                    messageText = ""
                    selectedImage = nil
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(ColorTheme.fallbackAccent)
                }
            }
            .padding()
            .background(ColorTheme.background)
        }
        .navigationTitle(channel.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadMessages(for: channel.id)
        }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .reportConfirmation(let message):
                return Alert(
                    title: Text("Denunciar Mensaje"),
                    message: Text("¿Estás seguro de que deseas denunciar este mensaje por spam, acoso o contenido ofensivo?"),
                    primaryButton: .destructive(Text("Denunciar")) {
                        reportMessage(message)
                    },
                    secondaryButton: .cancel(Text("Cancelar"))
                )
            case .blockConfirmation(let userId):
                return Alert(
                    title: Text("Bloquear Usuario"),
                    message: Text("¿Deseas bloquear a este usuario? No volverás a ver sus mensajes en tus chats."),
                    primaryButton: .destructive(Text("Bloquear")) {
                        blockUser(userId)
                    },
                    secondaryButton: .cancel(Text("Cancelar"))
                )
            case .status(let msgText):
                return Alert(
                    title: Text("Comunicaciones"),
                    message: Text(msgText),
                    dismissButton: .default(Text("Aceptar"))
                )
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: pickerSourceType, selectedImage: $selectedImage)
        }
    }
    
    private func reportMessage(_ message: ChatMessage) {
        Task {
            do {
                try await viewModel.reportMessage(messageId: message.id, senderId: message.senderId, reason: "Spam / Contenido Ofensivo")
                activeAlert = .status("El mensaje ha sido denunciado a los moderadores para su revisión inmediata.")
            } catch {
                activeAlert = .status("No se pudo enviar la denuncia: \(error.localizedDescription)")
            }
        }
    }
    
    private func blockUser(_ userId: String) {
        Task {
            do {
                try await viewModel.blockUser(userId: userId)
                activeAlert = .status("Usuario bloqueado de forma exitosa.")
            } catch {
                activeAlert = .status("No se pudo completar el bloqueo: \(error.localizedDescription)")
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if let attachmentURL = message.attachmentURL, !attachmentURL.isEmpty {
                    AsyncImage(url: URL(string: attachmentURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 220, maxHeight: 220)
                                .cornerRadius(12)
                        case .failure(_):
                            if attachmentURL == "mock_url" {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                        case .empty:
                            ProgressView()
                                .frame(width: 80, height: 80)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.bottom, 4)
                }
                
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(12)
                        .background(isCurrentUser ? ColorTheme.fallbackPrimary : ColorTheme.secondaryBackground)
                        .foregroundColor(isCurrentUser ? .white : ColorTheme.textPrimary)
                        .cornerRadius(16)
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}
