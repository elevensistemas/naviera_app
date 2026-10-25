import 'package:flutter/material.dart';
import '../../services/crew_faq_service.dart';
import '../../services/crew_profile_service.dart';
import '../../services/ncs_chat_service.dart';
import '../../models/crew_profile.dart';
import '../../core/storage.dart';

class CrewAssistantView extends StatefulWidget {
  final String? initialQuery;

  const CrewAssistantView({super.key, this.initialQuery});

  @override
  State<CrewAssistantView> createState() => _CrewAssistantViewState();
}

class _ChatMessageItem {
  final bool isUser;
  final String text;
  final String? source;
  final bool isVerified;
  final List<CrewFAQItem> relatedItems;

  const _ChatMessageItem({
    required this.isUser,
    required this.text,
    this.source,
    this.isVerified = true,
    this.relatedItems = const [],
  });
}

class _CrewAssistantViewState extends State<CrewAssistantView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessageItem> _messages = [];
  CrewProfile? _profile;
  bool _loadingProfile = true;
  FAQCategory? _selectedCategory;
  bool _isQueryingAi = false;

  @override
  void initState() {
    super.initState();
    _loadProfileAndInit();
  }

  Future<void> _loadProfileAndInit() async {
    try {
      final user = SessionManager.shared.currentUser;
      final profile = await ProductionCrewProfileService().fetchCurrentCrewProfile(currentUser: user);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }

    _addWelcomeMessage();

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _handleSubmitted(widget.initialQuery!.trim());
    }
  }

  void _addWelcomeMessage() {
    final name = _profile?.name ?? SessionManager.shared.currentUser?.name ?? "Tripulante";
    _messages.add(
      _ChatMessageItem(
        isUser: false,
        text: "¡Hola $name! Soy tu asistente de a bordo en Naviera Cruz del Sur.\n\nPuedo responder tus consultas sobre días embarcado, buque asignado, cursos, capacitaciones, reporte de incidentes y procedimientos del Manual de Gestión.",
        isVerified: true,
        source: "Documentación Oficial NCS",
      ),
    );
  }

  void _handleSubmitted(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(_ChatMessageItem(isUser: true, text: query));
      _isQueryingAi = true;
    });

    _scrollToBottom();

    // 1. Evaluar si es dato personal directo de perfil con alta confianza
    final faqResult = CrewFAQService.shared.answerQuery(query: query, profile: _profile);
    if (faqResult.item != null && faqResult.item!.isPersonalData && faqResult.isVerified) {
      if (!mounted) return;
      setState(() {
        _isQueryingAi = false;
        _messages.add(
          _ChatMessageItem(
            isUser: false,
            text: faqResult.message,
            source: faqResult.source,
            isVerified: faqResult.isVerified,
            relatedItems: faqResult.relatedItems,
          ),
        );
      });
      _scrollToBottom();
      return;
    }

    // 2. Consultar al LLM corporativo (Centinela IA / Manuales SGS)
    String? aiReply;
    try {
      aiReply = await NCSChatService.shared.queryCentinela(query);
    } catch (_) {
      aiReply = null;
    }

    if (!mounted) return;

    if (aiReply != null && aiReply.trim().isNotEmpty) {
      setState(() {
        _isQueryingAi = false;
        _messages.add(
          _ChatMessageItem(
            isUser: false,
            text: aiReply!.trim(),
            source: "Manual de Gestión SGS / Centinela IA",
            isVerified: true,
            relatedItems: faqResult.relatedItems,
          ),
        );
      });
    } else {
      // 3. Fallback al catálogo de preguntas frecuentes verificadas
      setState(() {
        _isQueryingAi = false;
        _messages.add(
          _ChatMessageItem(
            isUser: false,
            text: faqResult.message,
            source: faqResult.source,
            isVerified: faqResult.isVerified,
            relatedItems: faqResult.relatedItems,
          ),
        );
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00224A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Tu asistente a bordo",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            Text(
              "Preguntas frecuentes verificadas",
              style: TextStyle(fontSize: 11, color: Color(0xFF93C5FD)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Reiniciar conversación",
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector horizontal de categorías
          _buildCategorySelector(isDark),

          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: (_messages.length == 1 ? 2 : _messages.length) + (_isQueryingAi ? 1 : 0),
              itemBuilder: (context, index) {
                if (_messages.length == 1) {
                  if (index == 0) return _buildMessageBubble(_messages[0], isDark);
                  if (index == 1) return _buildSuggestedQuestionsSection(isDark);
                  if (_isQueryingAi && index == 2) return _buildThinkingBubble(isDark);
                } else {
                  if (index < _messages.length) {
                    return _buildMessageBubble(_messages[index], isDark);
                  }
                  if (_isQueryingAi && index == _messages.length) {
                    return _buildThinkingBubble(isDark);
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Barra inferior de entrada de texto
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _buildCategoryChip(
            label: "Todas las preguntas",
            isSelected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
            isDark: isDark,
          ),
          ...FAQCategory.values.map((cat) {
            return _buildCategoryChip(
              label: cat.displayName,
              isSelected: _selectedCategory == cat,
              onTap: () {
                setState(() => _selectedCategory = cat);
                _showCategoryBottomSheet(cat);
              },
              isDark: isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF334155)),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        selectedColor: const Color(0xFF0057B8),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildSuggestedQuestionsSection(bool isDark) {
    final questions = CrewFAQService.shared.suggestedQuestions;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF007AFF), size: 18),
              SizedBox(width: 8),
              Text(
                "Consultas sugeridas para tu día a bordo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions.map((q) {
              return ActionChip(
                label: Text(q.mainQuestion),
                avatar: const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFF0057B8)),
                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF0057B8), fontWeight: FontWeight.w600),
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEBF5FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onPressed: () => _handleSubmitted(q.mainQuestion),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessageItem msg, bool isDark) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0057B8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
          ),
        ),
      );
    }

    // Mensaje del Asistente
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con insignia de verificación
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0057B8).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Color(0xFF0057B8),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Asistente NCS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                if (msg.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, size: 10, color: Color(0xFF10B981)),
                        SizedBox(width: 3),
                        Text(
                          "Verificado",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Texto de respuesta
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),

            // Fuente documental si está disponible
            if (msg.source != null && msg.source!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.source_outlined, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "Fuente: ${msg.source}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Preguntas relacionadas si la consulta fue ambigua
            if (msg.relatedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text(
                "Preguntas sugeridas relacionadas:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              ...msg.relatedItems.map((item) {
                return InkWell(
                  onTap: () => _handleSubmitted(item.mainQuestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF007AFF)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.mainQuestion,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF007AFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0057B8),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Consultando Manual de Gestión / Centinela IA...",
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                ),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: _handleSubmitted,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: const InputDecoration(
                  hintText: "¿En qué te puedo ayudar?",
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleSubmitted(_textController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF0057B8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryBottomSheet(FAQCategory category) {
    final items = CrewFAQService.shared.getByCategory(category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      title: Text(
                        item.mainQuestion,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Fuente: ${item.source}",
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF0057B8)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleSubmitted(item.mainQuestion);
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
  }
}
