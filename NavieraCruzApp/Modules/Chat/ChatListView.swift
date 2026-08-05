import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Asistente IA (Contacto VIP)
                Section {
                    NavigationLink(destination: AIChatView()) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(ColorTheme.fallbackAccent.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "aqi.medium")
                                        .foregroundColor(ColorTheme.fallbackAccent)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NCS-Bot Operativo")
                                    .font(Typography.headline())
                                    .foregroundColor(ColorTheme.textPrimary)
                                
                                Text("Asistente IA (Voice & Text)")
                                    .font(Typography.caption())
                                    .foregroundColor(ColorTheme.fallbackAccent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Canales Normales
                Section {
                    ForEach(viewModel.channels) { channel in
                        NavigationLink(destination: ChatDetailView(viewModel: viewModel, channel: channel)) {
                            ChatChannelRow(channel: channel)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Comunicaciones")
            .onAppear {
                viewModel.loadChannels()
            }
        }
    }
}

struct ChatChannelRow: View {
    let channel: ChatChannel
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(channel.isGroup ? ColorTheme.info.opacity(0.3) : ColorTheme.fallbackPrimary.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: channel.isGroup ? "person.3.fill" : "person.fill")
                        .foregroundColor(channel.isGroup ? ColorTheme.info : ColorTheme.fallbackPrimary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(Typography.headline())
                    .foregroundColor(ColorTheme.textPrimary)
                
                Text(channel.lastMessage ?? "Sin mensajes")
                    .font(Typography.caption())
                    .foregroundColor(ColorTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let date = channel.lastMessageTimestamp {
                Text(date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
