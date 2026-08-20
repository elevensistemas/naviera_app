import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../core/storage.dart';
import '../../app/theme.dart';

class ChatDetailView extends StatefulWidget {
  final ChatChannel channel;
  const ChatDetailView({super.key, required this.channel});

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  XFile? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final chatService = ChatService();
      final messages = await chatService.fetchMessages(widget.channel.id);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
      _scrollToBottom(immediate: true);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _selectedImageBytes = bytes;
        });
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;

    final chatService = ChatService();
    _textController.clear();
    
    final imageBytes = _selectedImageBytes;
    setState(() {
      _selectedImageBytes = null;
      _selectedImageFile = null;
    });

    try {
      final newMsg = await chatService.sendMessage(text, widget.channel.id, imageBytes);
      setState(() {
        _messages.add(newMsg);
      });
      _scrollToBottom();
    } catch (_) {}
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _showReportDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Denunciar Mensaje"),
          content: const Text("¿Estás seguro de que deseas denunciar este mensaje por spam, acoso o contenido ofensivo?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ChatService().report(message.senderId, message.id, "Spam / Contenido Ofensivo");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("El mensaje ha sido denunciado para su revisión.")),
                    );
                  }
                } catch (_) {}
              },
              child: const Text("Denunciar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showBlockDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Bloquear Usuario"),
          content: const Text("¿Deseas bloquear a este usuario? No volverás a ver sus mensajes en tus chats."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ChatService().block(userId, true);
                  await SessionManager.shared.blockUser(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Usuario bloqueado de forma exitosa.")),
                    );
                  }
                } catch (_) {}
              },
              child: const Text("Bloquear", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = Provider.of<SessionManager>(context);
    final myId = session.currentUser?.id ?? '';
    
    // Filter messages from blocked users
    final visibleMessages = _messages.where((msg) => !session.blockedUserIds.contains(msg.senderId)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && visibleMessages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: visibleMessages.length,
                    itemBuilder: (context, index) {
                      final message = visibleMessages[index];
                      final isMe = message.senderId == myId;
                      return _buildMessageRow(message, isMe);
                    },
                  ),
          ),
          if (_selectedImageBytes != null) _buildImagePreviewWidget(),
          const Divider(height: 1),
          _buildInputWidget(),
        ],
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage message, bool isMe) {
    final theme = Theme.of(context);
    final timeStr = "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onLongPress: isMe ? null : () {
          // Show block/report options
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.warning, color: Colors.orange),
                      title: const Text("Reportar Mensaje"),
                      onTap: () {
                        Navigator.pop(context);
                        _showReportDialog(message);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: const Text("Bloquear Usuario"),
                      onTap: () {
                        Navigator.pop(context);
                        _showBlockDialog(message.senderId);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.attachmentURL != null) ...[
                    _buildAttachmentWidget(message.attachmentURL!),
                    const SizedBox(height: 4),
                  ],
                  if (message.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe 
                            ? ColorTheme.primary 
                            : (theme.brightness == Brightness.dark 
                                ? Colors.white.withOpacity(0.12) 
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isMe ? const Radius.circular(0) : null,
                          bottomLeft: isMe ? null : const Radius.circular(0),
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: isMe 
                              ? Colors.white 
                              : (theme.brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Colors.black87),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentWidget(String url) {
    if (url == "mock_url") {
      return Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.photo, size: 40, color: Colors.grey),
      );
    }
    
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image, color: Colors.red));
        },
      ),
    );
  }

  Widget _buildImagePreviewWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: MemoryImage(_selectedImageBytes!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageBytes = null;
                      _selectedImageFile = null;
                    });
                  },
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Text("Fotografía adjunta lista para enviar", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInputWidget() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate, color: ColorTheme.accent),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt, color: ColorTheme.accent),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "Escribir mensaje...",
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: ColorTheme.accent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
