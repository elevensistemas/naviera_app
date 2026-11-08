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
        ChatChannel(id: "c1", name: "Marenco Rubén Darío", isGroup: false, type: "direct", lastMessage: "Capitán - ALFA C"),
        ChatChannel(id: "c2", name: "Ramirez Pedro", isGroup: false, type: "direct", lastMessage: "Capitán - GUSTAVO U"),
        ChatChannel(id: "c3", name: "Maciel Jonathan", isGroup: false, type: "direct", lastMessage: "Capitán - NANY"),
        ChatChannel(id: "c4", name: "Sosa Armando", isGroup: false, type: "direct", lastMessage: "Jefe de Máquinas - ALFA C"),
        ChatChannel(id: "c5", name: "Agüero Leandro", isGroup: false, type: "direct", lastMessage: "Jefe de Máquinas - GUSTAVO U"),
        ChatChannel(id: "c6", name: "Porto Guillermo", isGroup: false, type: "direct", lastMessage: "Jefe de Máquinas - NANY"),
        ChatChannel(id: "c7", name: "Maldonado Juan", isGroup: false, type: "direct", lastMessage: "1er Oficial Cubierta - ALFA C"),
        ChatChannel(id: "c8", name: "Carattoli Pablo", isGroup: false, type: "direct", lastMessage: "2do Oficial Cubierta - ALFA C"),
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
        ChatChannel(id: "c1", name: "Marenco Rubén Darío", isGroup: false, type: "direct", lastMessage: "Capitán - ALFA C"),
        ChatChannel(id: "c2", name: "Ramirez Pedro", isGroup: false, type: "direct", lastMessage: "Capitán - GUSTAVO U"),
        ChatChannel(id: "c3", name: "Maciel Jonathan", isGroup: false, type: "direct", lastMessage: "Capitán - NANY"),
        ChatChannel(id: "c4", name: "Sosa Armando", isGroup: false, type: "direct", lastMessage: "Jefe de Máquinas - ALFA C"),
        ChatChannel(id: "c5", name: "Agüero Leandro", isGroup: false, type: "direct", lastMessage: "Jefe de Máquinas - GUSTAVO U"),
        ChatChannel(id: "c6", name: "Porto Guillermo", isGroup: false, type: "direct", lastMessage: "Jefe de Máquinas - NANY"),
        ChatChannel(id: "c7", name: "Maldonado Juan", isGroup: false, type: "direct", lastMessage: "1er Oficial Cubierta - ALFA C"),
        ChatChannel(id: "c8", name: "Carattoli Pablo", isGroup: false, type: "direct", lastMessage: "2do Oficial Cubierta - ALFA C"),
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
    final bgGradientColors = isDark
        ? [const Color(0xFF0F172A), const Color(0xFF0A0F1D)]
        : [const Color(0xFFE2EDFB), const Color(0xFFF1F6FC), const Color(0xFFF8FAFC)];

    return Container(
      color: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F6FC),
      child: Column(
        children: [
          // Standard NcsHeroHeader con funciones interactivas completas
          const NcsHeroHeader(
            title: "Comunicaciones",
            subtitle: "Mensajería, contactos y asistente IA.",
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bgGradientColors,
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Sutil resplandor luminoso superior simulando el efecto frosted/vidrio
                  Positioned(
                    top: -50,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.3,
                          colors: [
                            Colors.white.withValues(alpha: isDark ? 0.05 : 0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Lista scrolleable con diseño flotante iOS Liquid Glass
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 36.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Buscador con diseño pill frosted translúcido
                        _buildSearchBar(isDark, textColor, captionColor),
                        const SizedBox(height: 14),

                        // 2. Banner Asistente NCS con gradiente deep sapphire e icono estelar IA
                        _buildAssistantBanner(context, isDark),
                        const SizedBox(height: 14),

                        // 3. Tarjetas de Acción directas (Nuevo Chat y Contactos - sin llamada ni archivos compartidos)
                        _buildActionCards(context, isDark, textColor),
                        const SizedBox(height: 16),

                        // 4. Selector de Segmento (Chats recientes / Todos los contactos)
                        _buildSegmentSwitcher(isDark),
                        const SizedBox(height: 20),

                        // 5. Contenido principal (Empty state o lista de chats / contactos)
                        _buildContent(context, isDark, textColor, captionColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color textColor, Color captionColor) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0057B8).withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white60 : const Color(0xFF334155),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          hintText: "Buscar conversaciones, contactos o mensajes",
          hintStyle: TextStyle(
            fontSize: 13.5,
            color: isDark ? Colors.white38 : const Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAssistantBanner(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIChatView()),
        );
      },
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E293B), // Midnight slate
              Color(0xFF1E3A8A), // Royal Navy
              Color(0xFF2563EB), // Electric Cobalt Blue
              Color(0xFF3B82F6), // Bright Azure
            ],
            stops: [0.0, 0.35, 0.72, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Reflejo ondulado luminoso inferior
              Positioned(
                right: -25,
                bottom: -35,
                child: Container(
                  width: 150,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF93C5FD).withValues(alpha: 0.4),
                        const Color(0xFF60A5FA).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Icono de estrella IA con resplandor radial
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF818CF8).withValues(alpha: 0.45),
                            const Color(0xFF3B82F6).withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFBAE6FD),
                              Color(0xFFDDD6FE),
                              Color(0xFFF472B6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Títulos del asistente
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Asistente NCS",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Tu aliado operativo con IA",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón circular chevron
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCards(BuildContext context, bool isDark, Color textColor) {
    final cardBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.88);
    final cardBorder = isDark ? Colors.white12 : Colors.white;
    final cardShadow = [
      BoxShadow(
        color: const Color(0xFF0057B8).withValues(alpha: isDark ? 0.2 : 0.05),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

    return Row(
      children: [
        // Tarjeta 1: Nuevo Chat
        Expanded(
          child: GestureDetector(
            onTap: () => _showNewChatModal(context),
            child: Container(
              height: 86,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder, width: 1.5),
                boxShadow: cardShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Nuevo Chat",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Tarjeta 2: Contactos
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _activeSegment = 1);
              _loadChannels();
            },
            child: Container(
              height: 86,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder, width: 1.5),
                boxShadow: cardShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      Icons.people_outline_rounded,
                      size: 28,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Contactos",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentSwitcher(bool isDark) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.white.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tab 1: Chats recientes
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeSegment != 0) {
                  setState(() => _activeSegment = 0);
                  _loadChannels();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _activeSegment == 0 ? const Color(0xFF007AFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _activeSegment == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  "Chats recientes",
                  style: TextStyle(
                    color: _activeSegment == 0
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ),
          // Tab 2: Todos los contactos
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeSegment != 1) {
                  setState(() => _activeSegment = 1);
                  _loadChannels();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _activeSegment == 1 ? const Color(0xFF007AFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _activeSegment == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  "Todos los contactos",
                  style: TextStyle(
                    color: _activeSegment == 1
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, Color textColor, Color captionColor) {
    if (_isLoading && _filteredChannels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_filteredChannels.isEmpty) {
      return _buildEmptyState(context, isDark, textColor, captionColor);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredChannels.length,
      itemBuilder: (context, index) {
        final channel = _filteredChannels[index];
        return _buildChannelTile(channel, isDark, textColor, captionColor);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, Color textColor, Color captionColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Halo con ilustración 3D de burbujas de diálogo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF60A5FA).withValues(alpha: isDark ? 0.22 : 0.18),
                  const Color(0xFF93C5FD).withValues(alpha: isDark ? 0.08 : 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Burbuja azul de fondo
                Positioned(
                  left: 30,
                  top: 30,
                  child: Container(
                    width: 46,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                // Burbuja blanca en primer plano con tres puntos
                Positioned(
                  right: 28,
                  bottom: 30,
                  child: Container(
                    width: 48,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF94A3B8))),
                        const SizedBox(width: 3.5),
                        Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF94A3B8))),
                        const SizedBox(width: 3.5),
                        Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Título
          Text(
            _activeSegment == 0 ? "No hay chats recientes" : "No hay contactos disponibles",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              _activeSegment == 0
                  ? "Inicia una conversación, contacta a un miembro de la flota o consulta al Asistente NCS."
                  : "No se encontraron contactos en la agenda corporativa.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: captionColor,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Botón azul redondeado "+ Nuevo Chat"
          GestureDetector(
            onTap: () => _showNewChatModal(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Nuevo Chat",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(ChatChannel channel, bool isDark, Color textColor, Color captionColor) {
    final itemBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9);
    final itemBorder = isDark ? Colors.white12 : Colors.white;

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: itemBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0057B8).withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
              Icons.chevron_right_rounded,
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
