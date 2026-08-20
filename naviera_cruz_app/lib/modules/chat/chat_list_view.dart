import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/bar_widget.dart';
import '../aichat/aichat_view.dart';
import 'chat_detail_view.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final List<ChatChannel> _channels = [];
  List<ChatChannel> _filteredChannels = [];
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _activeSegment = 0; // 0 = Chat recientes, 1 = Todos los contactos

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChannels = List.from(_channels);
      } else {
        _filteredChannels = _channels
            .where((channel) => channel.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadChannels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chatService = ChatService();
      final channels = _activeSegment == 0 
          ? await chatService.fetchChannels() 
          : await chatService.fetchContacts();
      setState(() {
        _channels.clear();
        _channels.addAll(channels);
        _filteredChannels = List.from(_channels);
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
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'p.m.' : 'a.m.';
    // Display in standard 12-hour format for mockup parity
    final displayHour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    return "$displayHour:${minute} $ampm";
  }

  Color _avatarBgColor(String name) {
    if (name.contains("Admin")) return const Color(0xFFF28000); // Orange
    if (name.contains("Mónica") || name.contains("Monica")) return const Color(0xFFFFD180); // Peach
    if (name.contains("Capitán")) return const Color(0xFF29B6F6); // Cyan
    return ColorTheme.primary;
  }

  String _avatarInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final captionColor = isDark ? Colors.white38 : Colors.black38;
    final text45Color = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      appBar: const NavieraAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title "Comunicaciones"
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
            child: Text(
              "Comunicaciones",
              style: TextStyle(
                color: ColorTheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Main content list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadChannels,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                children: [
                  // Buscar conversación Input (App NCS - Pantalla 6 style)
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Buscar conversación",
                      hintStyle: TextStyle(color: captionColor),
                      prefixIcon: Icon(Icons.search, color: captionColor),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: ColorTheme.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Segmented control: Chat recientes / Todos los contactos
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _activeSegment = 0);
                              _loadChannels();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _activeSegment == 0 ? ColorTheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                "Chat recientes",
                                style: TextStyle(
                                  color: _activeSegment == 0 ? Colors.white : (isDark ? Colors.white70 : ColorTheme.primary),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _activeSegment = 1);
                              _loadChannels();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _activeSegment == 1 ? ColorTheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                "Todos los contactos",
                                style: TextStyle(
                                  color: _activeSegment == 1 ? Colors.white : (isDark ? Colors.white70 : ColorTheme.primary),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // NCS-Bot AI Card
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.orange.withOpacity(0.15) : const Color(0xFFFFF3E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.online_prediction,
                          color: ColorTheme.accent,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        "NCS-Bot Operativo",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        "Asistente IA (Voz y Texto)",
                        style: TextStyle(
                          color: ColorTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

                  // Chat Channels List
                  if (_isLoading && _filteredChannels.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
                  else if (_filteredChannels.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          _errorMessage ?? "No hay conversaciones.",
                          style: TextStyle(color: captionColor),
                        ),
                      ),
                    )
                  else if (_activeSegment == 0) ...[
                    // Only show channels that have a last message (recent chats)
                    ..._filteredChannels.map((channel) {
                      final avBg = _avatarBgColor(channel.name);
                      final avInit = _avatarInitials(channel.name);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: avBg,
                                child: Text(
                                  avInit,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              // Online green dot
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50), // Green dot
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            channel.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              channel.lastMessage ?? "Sin mensajes recientes",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: text45Color, fontSize: 13),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (channel.lastMessageTimestamp != null)
                                Text(
                                  _formatTime(channel.lastMessageTimestamp),
                                  style: TextStyle(fontSize: 11, color: captionColor),
                                ),
                              const SizedBox(height: 4),
                              Icon(Icons.chevron_right, size: 16, color: captionColor),
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
                  ] else ...[
                    // Mock contacts list (all contacts)
                    ..._filteredChannels.map((channel) {
                      final avBg = _avatarBgColor(channel.name);
                      final avInit = _avatarInitials(channel.name);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: avBg,
                            child: Text(
                              avInit,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            channel.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Personal de Naviera",
                              style: TextStyle(color: text45Color, fontSize: 12),
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right, size: 16, color: captionColor),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
