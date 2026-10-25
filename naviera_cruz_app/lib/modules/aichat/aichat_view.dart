import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../app/theme.dart';
import '../../models/ncs_chat_models.dart';
import '../../services/ncs_chat_service.dart';

class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> {
  final List<NCSAIMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  bool _isSpeechAvailable = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _speechText = '';
  StreamSubscription<NCSStreamEvent>? _currentStreamSubscription;


  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    _initSpeech();
    _initTts();
    _setupWelcomeMessage();
  }

  void _setupWelcomeMessage() {
    const welcomeText = "¡Hola! Soy el **Asistente de NCS**.";

    _messages.add(NCSAIMessage(
      id: "w1",
      sender: NCSMessageSender.assistant,
      text: welcomeText,
      logs: [
        NCSLogItem(
          id: "l1",
          category: "info",
          message: "Conectado a NCS Control Center v4.4",
          timestamp: DateTime.now(),
        )
      ],
    ));
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            if (_speechText.trim().isNotEmpty) {
              _sendMessage(_speechText.trim(), isVoice: true);
              _speechText = '';
            }
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) {
        setState(() => _isSpeechAvailable = available);
      }
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
      final cleanText = text
          .replaceAll('#', '')
          .replaceAll('*', '')
          .replaceAll('`', '');
      await _tts.speak(cleanText);
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

  void _sendMessage(String text, {bool isVoice = false}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Add User Message
    setState(() {
      _messages.add(NCSAIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: NCSMessageSender.user,
        text: trimmed,
      ));
      _isProcessing = true;
    });

    _scrollToBottom();

    // Add empty Assistant Message placeholder
    final assistantMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final assistantMsg = NCSAIMessage(
      id: assistantMsgId,
      sender: NCSMessageSender.assistant,
      text: "",
      isStreaming: true,
    );

    setState(() {
      _messages.add(assistantMsg);
    });

    _currentStreamSubscription?.cancel();

    final history = _messages
        .where((m) => m.text.isNotEmpty && m.id != "w1" && m.id != assistantMsgId)
        .map((m) => {
              "role": m.sender == NCSMessageSender.user ? "user" : "assistant",
              "content": m.text,
            })
        .toList();

    final stream = NCSChatService.shared.streamChatResponse(trimmed, history: history);
    _currentStreamSubscription = stream.listen((event) {
      if (!mounted) return;

      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (index != -1) {
          if (event.type == "log") {
            _messages[index].logs.add(NCSLogItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              category: event.logClass ?? "info",
              message: event.content ?? "Procesando...",
              timestamp: DateTime.now(),
            ));
          } else if (event.type == "result") {
            if (event.content != null) {
              _messages[index].text = event.content!;
            }
            if (event.structured != null) {
              _messages[index].structuredData = event.structured;
            }
            _messages[index].isStreaming = false;
          }
        }
      });
      _scrollToBottom();
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (index != -1) {
          _messages[index].text = "⚠️ No se pudo conectar con NCS Control Center.";
          _messages[index].isStreaming = false;
        }
        _isProcessing = false;
      });
    }, onDone: () {
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (index != -1) {
          _messages[index].isStreaming = false;
          if (isVoice && _messages[index].text.isNotEmpty) {
            _speak(_messages[index].text);
          }
        }
        _isProcessing = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
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
        title: const Text("NCS Control Center"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Executive Header Badge
          _buildExecutiveHeader(),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),


          // Speech Listening Banner
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _speechText.isEmpty ? "Escuchando consulta por voz..." : _speechText,
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.red, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleListening,
                    child: const Text("Enviar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

          const Divider(height: 1),

          // Input Bar
          _buildInputBar(theme),

          // Apple App Store Mandatory AI Disclaimer
          _buildAIDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Container(
      width: double.infinity,
      color: Colors.black.withOpacity(0.03),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ColorTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorTheme.accent.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.green, size: 8),
                SizedBox(width: 6),
                Text(
                  "NCS AI Control Center • En Línea",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ColorTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_isProcessing)
            InkWell(
              onTap: () {
                _currentStreamSubscription?.cancel();
                setState(() => _isProcessing = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text("Detener", style: TextStyle(color: Colors.red, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildMessageBubble(NCSAIMessage message) {
    final isUser = message.sender == NCSMessageSender.user;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: ColorTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.online_prediction, size: 18, color: ColorTheme.accent),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Header (Name & Audio Button)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isUser ? "Usuario" : "NCS AI",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    if (!isUser && message.text.isNotEmpty)
                      InkWell(
                        onTap: () => _speak(message.text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volume_up, size: 12, color: ColorTheme.accent),
                              SizedBox(width: 4),
                              Text("Escuchar", style: TextStyle(fontSize: 10, color: ColorTheme.accent)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Processing Logs Accordion
                if (!isUser && message.logs.isNotEmpty)
                  _LogTraceAccordion(logs: message.logs, isStreaming: message.isStreaming),

                // Main Text Content
                if (message.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? ColorTheme.primary : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: SelectableText(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : theme.colorScheme.onSurface,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  )
                else if (message.isStreaming)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: ColorTheme.accent),
                        ),
                        SizedBox(width: 10),
                        Text("Analizando telemetría y generando respuesta...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),


              ],
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorTheme.accent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 18, color: ColorTheme.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: _isListening ? "Escuchando por voz..." : "",
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              enabled: !_isListening && !_isProcessing,
              onSubmitted: (val) {
                _sendMessage(val);
                _textController.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textController,
            builder: (context, value, child) {
              final isNotEmpty = value.text.trim().isNotEmpty;
              if (isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: ColorTheme.accent,
                  onPressed: () {
                    _sendMessage(value.text);
                    _textController.clear();
                  },
                );
              } else {
                return IconButton(
                  icon: Icon(_isListening ? Icons.stop_circle : Icons.mic_rounded),
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

  Widget _buildAIDisclaimer() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            "NCS AI puede cometer errores. Verifique la información operativa.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentStreamSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}

class _LogTraceAccordion extends StatefulWidget {
  final List<NCSLogItem> logs;
  final bool isStreaming;

  const _LogTraceAccordion({required this.logs, required this.isStreaming});

  @override
  State<_LogTraceAccordion> createState() => _LogTraceAccordionState();
}

class _LogTraceAccordionState extends State<_LogTraceAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ColorTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isStreaming)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                else
                  const Icon(Icons.check_circle, size: 12, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  "Procesamiento NDJSON (${widget.logs.length} eventos)",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ColorTheme.primary),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.logs.map((log) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ", style: TextStyle(color: ColorTheme.accent, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          log.message,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _StructuredTelemetryCard extends StatelessWidget {
  final NCSStructuredVesselData data;

  const _StructuredTelemetryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorTheme.primary, Color(0xFF0E345A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorTheme.accent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_boat, color: ColorTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                data.vesselName ?? "Buque NCS",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              if (data.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.status!,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (data.speed != null) _metricItem(Icons.speed, "Velocidad", data.speed!),
              if (data.eta != null) _metricItem(Icons.access_time_filled, "ETA", data.eta!),
              if (data.fuelLevel != null) _metricItem(Icons.local_gas_station, "Combustible", data.fuelLevel!),
              if (data.cargoWeight != null) _metricItem(Icons.inventory_2, "Carga", data.cargoWeight!),
            ],
          ),
          if (data.coordinates != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: ColorTheme.accent),
                const SizedBox(width: 4),
                Text(
                  "Coordenadas: ${data.coordinates}",
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _metricItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ColorTheme.accent),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white60)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        )
      ],
    );
  }
}
