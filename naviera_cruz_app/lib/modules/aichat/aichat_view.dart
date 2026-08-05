import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../app/theme.dart';

class AIResponse {
  final String id;
  final String text;
  final bool isUser;

  AIResponse({
    required this.id,
    required this.text,
    required this.isUser,
  });
}

class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> {
  final List<AIResponse> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _speechText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    
    _initSpeech();
    _initTts();
    
    // Welcome message
    _messages.add(AIResponse(
      id: "w1",
      text: "Hola. Soy el asistente operativo de Naviera Cruz del Sur. Puedes preguntarme el estado de nuestra flota, tripulación o cargas por voz o texto.",
      isUser: false,
    ));
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_speechText.isNotEmpty) {
              _sendMessage(_speechText);
              _speechText = '';
            }
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      setState(() {
        _isSpeechAvailable = available;
      });
    } catch (_) {}
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("es-ES");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  void _toggleListening() async {
    if (!_isSpeechAvailable) return;

    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _speechText = '';
      });
      _speech.listen(
        onResult: (val) => setState(() {
          _speechText = val.recognizedWords;
        }),
      );
    }
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(AIResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
      ));
      _isProcessing = true;
    });
    
    _scrollToBottom();
    _processWithAI(text);
  }

  Future<void> _processWithAI(String query) async {
    final lowerQuery = query.toLowerCase();
    await Future.delayed(const Duration(milliseconds: 1500));
    
    String responseText = "No tengo información específica sobre eso. Intenta preguntar sobre el estado de barcos, cargas o tripulación.";

    if (lowerQuery.contains("estado") || lowerQuery.contains("barco") || lowerQuery.contains("naviera i")) {
      responseText = "El Naviera I se encuentra Activo en alta mar. El Naviera II está en puerto por mantenimiento programado.";
    } else if (lowerQuery.contains("carga") || lowerQuery.contains("toneladas")) {
      responseText = "Actualmente la flota cuenta con 3,700 toneladas métricas de carga en transporte, distribuidas en dos buques operativos.";
    } else if (lowerQuery.contains("tripula") || lowerQuery.contains("quien esta") || lowerQuery.contains("capitán")) {
      responseText = "El Capitán actual del Naviera I es Juan Pérez. El equipo completo se encuentra operativo y sin incidentes de seguridad reportados.";
    }

    if (mounted) {
      setState(() {
        _messages.add(AIResponse(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: responseText,
          isUser: false,
        ));
        _isProcessing = false;
      });
      _scrollToBottom();
      _speak(responseText);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Asistente NCS"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text("Procesando...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          const Divider(height: 1),
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.red.withOpacity(0.05),
              child: Center(
                child: Text(
                  _speechText.isEmpty ? "Escuchando..." : _speechText,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.red),
                ),
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIResponse message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ColorTheme.accent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.online_prediction,
                size: 18,
                color: ColorTheme.accent,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser 
                    ? ColorTheme.primary 
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18).copyWith(
                  topLeft: isUser ? null : const Radius.circular(0),
                  topRight: isUser ? const Radius.circular(0) : null,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser 
                      ? Colors.white 
                      : theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: _isListening ? "Escuchando por voz..." : "Escribe o usa el micrófono",
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              enabled: !_isListening,
              onSubmitted: (val) {
                _sendMessage(val.trim());
                _textController.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _textController,
            builder: (context, child) {
              final text = _textController.text.trim();
              if (text.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.send),
                  color: ColorTheme.accent,
                  onPressed: () {
                    _sendMessage(text);
                    _textController.clear();
                  },
                );
              } else {
                return IconButton(
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  color: _isListening ? Colors.red : ColorTheme.primary,
                  iconSize: 28,
                  onPressed: _toggleListening,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
