import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/ncs_hero_header.dart';
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
  int _activeSegment = 0; // 0 = Chats recientes, 1 = Todos los contactos

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
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredChannels = List.from(_channels);
      } else {
        _filteredChannels = _channels.where((channel) {
          final nameMatch = channel.name.toLowerCase().contains(query);
          final msgMatch = channel.lastMessage != null && channel.lastMessage!.toLowerCase().contains(query);
          return nameMatch || msgMatch;
        }).toList();
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
      final rawChannels = _activeSegment == 0 
          ? await chatService.fetchChannels() 
          : await chatService.fetchContacts();
      
      final channels = rawChannels.where((c) {
        final n = c.name.toLowerCase();
        return !n.contains('admin') && !n.contains('test admin') && !n.contains('test_admin');
      }).toList();

      setState(() {
        _channels.clear();
        _channels.addAll(channels);
        _filteredChannels = List.from(_channels);
      });
    } catch (e) {
      if (_activeSegment == 1) {
        _loadFallbackContacts();
      } else {
        setState(() {
          _channels.clear();
          _filteredChannels.clear();
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadFallbackContacts() {
    setState(() {
      _channels.clear();
      _channels.addAll([
        ChatChannel(id: "c1", name: "Carrá Leonel", isGroup: false, type: "direct", lastMessage: "Capitán - ALFA C"),
        ChatChannel(id: "c2", name: "Caballero Diego", isGroup: false, type: "direct", lastMessage: "1er Oficial Cubierta"),
        ChatChannel(id: "c3", name: "Caratolli Pablo", isGroup: false, type: "direct", lastMessage: "2do Oficial Cubierta"),
        ChatChannel(id: "c4", name: "Escalante Jorge", isGroup: false, type: "direct", lastMessage: "3er Oficial Cubierta"),
        ChatChannel(id: "c5", name: "Sosa Armando", isGroup: false, type: "direct", lastMessage: "Jefe de Máquinas"),
        ChatChannel(id: "c6", name: "Medina Cesar", isGroup: false, type: "direct", lastMessage: "1er Conductor"),
        ChatChannel(id: "c7", name: "Ledesma Gabriel", isGroup: false, type: "direct", lastMessage: "2do Oficial Máquinas"),
        ChatChannel(id: "c8", name: "Pereyra Matías", isGroup: false, type: "direct", lastMessage: "3er Oficial Máquinas"),
      ]);
      _filteredChannels = List.from(_channels);
    });
  }

  void _showNewChatModal(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<ChatChannel> contacts = [];
    try {
      final rawContacts = await ChatService().fetchContacts();
      contacts = rawContacts.where((c) {
        final n = c.name.toLowerCase();
        return !n.contains('admin') && !n.contains('test admin') && !n.contains('test_admin');
      }).toList();
    } catch (_) {}

    if (contacts.isEmpty) {
      contacts = [
        ChatChannel(id: "c1", name: "Carrá Leonel", isGroup: false, type: "direct", lastMessage: "Capitán - ALFA C"),
        ChatChannel(id: "c2", name: "Caballero Diego", isGroup: false, type: "direct", lastMessage: "1er Oficial Cubierta"),
        ChatChannel(id: "c3", name: "Caratolli Pablo", isGroup: false, type: "direct", lastMessage: "2do Oficial Cubierta"),
        ChatChannel(id: "c4", name: "Escalante Jorge", isGroup: false, type: "direct", lastMessage: "3er Oficial Cubierta"),
        ChatChannel(id: "c5", name: "Sosa Armando", isGroup: false, type: "direct", lastMessage: "Jefe de Máquinas"),
        ChatChannel(id: "c6", name: "Medina Cesar", isGroup: false, type: "direct", lastMessage: "1er Conductor"),
        ChatChannel(id: "c7", name: "Ledesma Gabriel", isGroup: false, type: "direct", lastMessage: "2do Oficial Máquinas"),
        ChatChannel(id: "c8", name: "Pereyra Matías", isGroup: false, type: "direct", lastMessage: "3er Oficial Máquinas"),
      ];
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        String modalSearch = '';

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filteredContacts = contacts.where((c) {
              if (modalSearch.isEmpty) return true;
              return c.name.toLowerCase().contains(modalSearch.toLowerCase()) ||
                  (c.lastMessage != null && c.lastMessage!.toLowerCase().contains(modalSearch.toLowerCase()));
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Top Bar Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Modal Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Nuevo Chat",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  Text(
                    "Selecciona un usuario para iniciar una conversación.",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Modal Search Input
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      onChanged: (val) {
                        setModalState(() {
                          modalSearch = val.trim();
                        });
                      },
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        hintText: "Buscar contacto por nombre o cargo...",
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contacts List
                  Expanded(
                    child: filteredContacts.isEmpty
                        ? Center(
                            child: Text(
                              "No se encontraron contactos.",
                              style: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredContacts.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final contact = filteredContacts[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    color: ColorTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                                ),
                                title: Text(
                                  contact.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Text(
                                  contact.lastMessage ?? "Personal Naviera",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: ColorTheme.primary,
                                  size: 20,
                                ),
                                onTap: () {
                                  Navigator.pop(modalContext);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatDetailView(channel: contact),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final captionColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final bodyBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? Colors.white24 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bodyBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Standard NcsHeroHeader with ship ALFA C
            const NcsHeroHeader(
              title: "Comunicaciones",
              subtitle: "Mensajería, contactos y asistente IA.",
            ),

            // Main White / Card Container with rounded top corners
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Search Input Bar
                  _buildSearchBar(inputBg, inputBorder, isDark, captionColor, textColor),
                  const SizedBox(height: 16),

                  // Row 2: Top 2 Action Cards (Asistente IA NCS + Nuevo chat)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card 1: Asistente IA NCS
                        Expanded(
                          child: _buildActionCard(
                            context: context,
                            title: "Asistente IA",
                            subtitle: "Asistente de Voz y Texto",
                            icon: Icons.auto_awesome_rounded,
                            iconBgColor: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
                            iconColor: isDark ? const Color(0xFFF97316) : const Color(0xFFEA580C),
                            cardBgColor: isDark ? const Color(0xFF451A03).withOpacity(0.4) : const Color(0xFFFFF7ED),
                            borderColor: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
                            arrowColor: isDark ? const Color(0xFFF97316) : const Color(0xFFEA580C),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AIChatView()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Card 2: Nuevo chat
                        Expanded(
                          child: _buildActionCard(
                            context: context,
                            title: "Nuevo chat",
                            subtitle: "Conversar con usuarios",
                            icon: Icons.chat_bubble_rounded,
                            iconBgColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                            iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0284C7),
                            cardBgColor: isDark ? const Color(0xFF172554).withOpacity(0.4) : const Color(0xFFEFF6FF),
                            borderColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                            arrowColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0284C7),
                            onTap: () {
                              _showNewChatModal(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Row 3: Segmented Switcher (Chats recientes / Todos los contactos)
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _activeSegment == 0 ? ColorTheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                "Chats recientes",
                                style: TextStyle(
                                  color: _activeSegment == 0 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _activeSegment == 1 ? ColorTheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                "Todos los contactos",
                                style: TextStyle(
                                  color: _activeSegment == 1 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Row 4: Channels & Contacts List / Empty State
                  if (_isLoading && _filteredChannels.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_filteredChannels.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.forum_outlined,
                              size: 42,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _activeSegment == 0 ? "No hay chats recientes" : "No hay contactos disponibles",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _activeSegment == 0
                                ? "Contacta con el chat haciendo clic en 'Nuevo chat' o buscando en la pestaña 'Todos los contactos'."
                                : "No se encontraron contactos en la agenda.",
                            style: TextStyle(
                              fontSize: 12,
                              color: captionColor,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () => _showNewChatModal(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_comment_rounded, size: 18),
                            label: const Text(
                              "Nuevo Chat",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredChannels.length,
                      itemBuilder: (context, index) {
                        final channel = _filteredChannels[index];
                        return _buildChannelTile(channel, isDark, textColor, captionColor);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color inputBg, Color inputBorder, bool isDark, Color captionColor, Color textColor) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: inputBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          hintText: "Buscar conversaciones, contactos o mensajes...",
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color cardBgColor,
    required Color borderColor,
    required Color arrowColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80, // Dimensiones de borde e iconos idénticas para ambas tarjetas
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: arrowColor),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelTile(ChatChannel channel, bool isDark, Color textColor, Color captionColor) {
    final itemBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final itemBorder = isDark ? Colors.white10 : const Color(0xFFF1F5F9);

    final timeStr = channel.timeDisplay ?? _formatTime(channel.lastMessageTimestamp);

    Widget avatarWidget;
    if (channel.type == 'group' || channel.name.contains('Tripulación')) {
      avatarWidget = Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.people_alt_rounded,
          color: isDark ? Colors.white70 : const Color(0xFF64748B),
          size: 24,
        ),
      );
    } else if (channel.type == 'announcement' || channel.name.contains('Comunicaciones')) {
      avatarWidget = Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.campaign_rounded,
          color: isDark ? Colors.white70 : const Color(0xFF64748B),
          size: 24,
        ),
      );
    } else {
      avatarWidget = Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: ColorTheme.primary,
          shape: BoxShape.circle,
        ),
        child: (channel.avatarUrl != null && channel.avatarUrl!.isNotEmpty)
            ? ClipOval(
                child: Image.network(
                  channel.avatarUrl!,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              )
            : const Icon(
                Icons.person,
                color: Colors.white,
                size: 26,
              ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: itemBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        leading: avatarWidget,
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
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: captionColor,
                    ),
                  ),
                const SizedBox(height: 4),
                if (channel.unreadCount > 0)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: ColorTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${channel.unreadCount}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
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
  }
}
