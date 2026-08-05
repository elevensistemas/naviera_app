import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../aichat/aichat_view.dart';
import 'chat_detail_view.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final List<ChatChannel> _channels = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chatService = ChatService();
      final channels = await chatService.fetchChannels();
      setState(() {
        _channels.clear();
        _channels.addAll(channels);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Comunicaciones",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChannels,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChannels,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // AI Assistant Card
            Card(
              elevation: 0,
              color: ColorTheme.accent.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: ColorTheme.accent.withOpacity(0.2)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: ColorTheme.accent.withOpacity(0.2),
                  child: const Icon(
                    Icons.online_prediction,
                    color: ColorTheme.accent,
                    size: 28,
                  ),
                ),
                title: Text(
                  "NCS-Bot Operativo",
                  style: TypographyTheme.headline(context).copyWith(
                    color: theme.colorScheme.brightness == Brightness.light
                        ? ColorTheme.primary
                        : Colors.white,
                  ),
                ),
                subtitle: const Text(
                  "Asistente IA (Voz y Texto)",
                  style: TextStyle(color: ColorTheme.accent, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.chevron_right, color: ColorTheme.accent),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AIChatView()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Channels Header
            Text(
              "Canales de Comunicación",
              style: TypographyTheme.caption(context).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Channel List
            if (_isLoading && _channels.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
            else if (_channels.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(
                    _errorMessage ?? "Sin canales de chat disponibles.",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._channels.map((channel) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: channel.isGroup 
                          ? ColorTheme.info.withOpacity(0.15) 
                          : ColorTheme.primary.withOpacity(0.15),
                      child: Icon(
                        channel.isGroup ? Icons.groups : Icons.person,
                        color: channel.isGroup ? ColorTheme.info : ColorTheme.primary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      channel.name,
                      style: TypographyTheme.headline(context).copyWith(fontSize: 15),
                    ),
                    subtitle: Text(
                      channel.lastMessage ?? "Sin mensajes",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TypographyTheme.caption(context),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (channel.lastMessageTimestamp != null)
                          Text(
                            _formatTime(channel.lastMessageTimestamp),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailView(channel: channel),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
