import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/config.dart';
import '../../core/storage.dart';
import '../../core/video_helper.dart';

class TrainingView extends StatefulWidget {
  const TrainingView({super.key});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  final TrainingService _trainingService = ProductionTrainingService();
  bool _isLoading = true;
  TrainingConsumption? _consumption;
  List<Training> _trainings = [];
  String? _selectedShip;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final consumption = await _trainingService.fetchTrainingConsumption(ship: _selectedShip);
      final trainings = await _trainingService.fetchTrainings();
      setState(() {
        _consumption = consumption;
        _trainings = trainings;
      });
    } catch (e) {
      debugPrint('Error loading training data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openTrainingDetailModal(Training training) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TrainingDetailSheet(
        training: training,
        onAdvanceProgress: (updatedTraining) {
          setState(() {
            final idx = _trainings.indexWhere((t) => t.id == updatedTraining.id);
            if (idx != -1) {
              _trainings[idx] = updatedTraining;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Capacitaciones", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cursos y Capacitaciones Activas Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Programa de Cursos y Normas",
                          style: TypographyTheme.title2(context),
                        ),
                        Text(
                          "Toca para abrir y continuar",
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_trainings.isEmpty)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.school_outlined, size: 44, color: Colors.grey),
                                const SizedBox(height: 10),
                                Text(
                                  "No hay capacitaciones asignadas o registradas en el servidor para este usuario.",
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._trainings.map((t) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openTrainingDetailModal(t),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: ColorTheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.play_circle_fill, color: ColorTheme.primary, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              t.code,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text("${t.hours} hrs • ${t.sector}", style: const TextStyle(fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: t.userProgressPercentage / 100.0,
                                              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                                              color: ColorTheme.success,
                                              minHeight: 5,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${t.completedModules}/${t.totalModules} mód",
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: ColorTheme.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${t.userProgressPercentage.toStringAsFixed(0)}%",
                                    style: const TextStyle(
                                      color: ColorTheme.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Modal Detail View for interactive training viewer and advancing progress
class _TrainingDetailSheet extends StatefulWidget {
  final Training training;
  final ValueChanged<Training> onAdvanceProgress;

  const _TrainingDetailSheet({
    required this.training,
    required this.onAdvanceProgress,
  });

  @override
  State<_TrainingDetailSheet> createState() => _TrainingDetailSheetState();
}

class _TrainingDetailSheetState extends State<_TrainingDetailSheet> {
  late Training _current;
  bool _isUpdating = false;
  bool _isPlayingVideo = false;

  @override
  void initState() {
    super.initState();
    _current = widget.training;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final service = ProductionTrainingService();
      final identifier = _current.slug.isNotEmpty ? _current.slug : _current.id;
      final detail = await service.fetchTrainingDetail(identifier);
      if (detail != null && mounted) {
        setState(() {
          _current = detail;
        });
      }
    } catch (e) {
      debugPrint('Notice loading training detail: $e');
    }
  }

  Future<void> _advanceCourse() async {
    if (_current.completedModules >= _current.totalModules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Capacitación completada al 100%!"), backgroundColor: Colors.green),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final service = ProductionTrainingService();
      final updated = await service.updateTrainingProgress(
        trainingId: _current.id,
        completedModules: _current.completedModules + 1,
      );
      setState(() {
        _current = updated;
      });
      widget.onAdvanceProgress(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Módulo avanzado! Progreso actual: ${updated.userProgressPercentage.toStringAsFixed(0)}%"),
            backgroundColor: ColorTheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error advancing progress: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasVideo = _current.videoUrl != null && _current.videoUrl!.trim().isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _current.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Video Player Simulated Frame
                if (_isPlayingVideo && hasVideo && _current.videoUrl != null) ...[
                  InlineTrainingVideoPlayer(videoUrl: _current.videoUrl!),
                ] else ...[
                  InkWell(
                    onTap: () {
                      if (hasVideo) {
                        setState(() {
                          _isPlayingVideo = true;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0B192C), Color(0xFF1E3E62)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 70),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: hasVideo ? ColorTheme.primary : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  hasVideo ? Icons.play_arrow : Icons.videocam_off,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasVideo ? "Ver Clase en Video" : "Video no disponible",
                                style: TextStyle(
                                  color: hasVideo ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Sector & Instructor info
                Row(
                  children: [
                    if (_current.code.isNotEmpty) ...[
                      Chip(
                        label: Text(_current.code, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        backgroundColor: ColorTheme.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_current.hours > 0) ...[
                      Chip(
                        label: Text("${_current.hours} Horas", style: const TextStyle(fontSize: 11)),
                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Chip(
                      label: Text(_current.sector, style: const TextStyle(fontSize: 11)),
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (_current.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _current.description,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  _current.instructor.isNotEmpty
                      ? "Instructor: ${_current.instructor}"
                      : "Instructor: No asignado",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _current.instructor.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                    fontStyle: _current.instructor.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                    color: _current.instructor.isNotEmpty ? ColorTheme.primary : (isDark ? Colors.white38 : Colors.grey.shade600),
                  ),
                ),

                if (_current.totalModules > 0 && _current.modules.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Progreso personal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Progreso del Marino", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        "${_current.completedModules} de ${_current.totalModules} Módulos (${_current.userProgressPercentage.toStringAsFixed(0)}%)",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorTheme.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _current.userProgressPercentage / 100.0,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                    color: ColorTheme.success,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),

                  const SizedBox(height: 20),
                  const Text("Módulos del Curso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),

                  // Lista de módulos
                  ..._current.modules.map((m) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: m.isCompleted ? ColorTheme.success.withOpacity(0.4) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            m.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: m.isCompleted ? ColorTheme.success : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: m.isCompleted ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            "${m.durationMinutes} min",
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Estado de la Capacitación", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _current.status.toLowerCase().contains("vigente")
                              ? Colors.green.withOpacity(0.15)
                              : Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _current.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _current.status.toLowerCase().contains("vigente") ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action Button Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (_current.totalModules > 0 && _current.modules.isNotEmpty)
                    ? (_isUpdating ? null : _advanceCourse)
                    : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isUpdating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon((_current.totalModules == 0 || _current.modules.isEmpty || _current.completedModules >= _current.totalModules)
                        ? Icons.check_circle_outline
                        : Icons.play_arrow),
                label: Text(
                  (_current.totalModules == 0 || _current.modules.isEmpty)
                      ? "Entendido / Cerrar"
                      : (_current.completedModules >= _current.totalModules
                          ? "Capacitación Completada"
                          : "Continuar Capacitación (Avanzar Módulo)"),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compatibility Alias
typedef StatsView = TrainingView;

class InlineTrainingVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const InlineTrainingVideoPlayer({super.key, required this.videoUrl});

  @override
  State<InlineTrainingVideoPlayer> createState() => _InlineTrainingVideoPlayerState();
}

class _InlineTrainingVideoPlayerState extends State<InlineTrainingVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  List<Uri> _generateCandidateUris(String rawVideoUrl) {
    String cleaned = rawVideoUrl.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }

    final List<String> rawPaths = [];

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      final parsed = Uri.tryParse(cleaned);
      if (parsed != null) {
        rawPaths.add(parsed.path);
      } else {
        rawPaths.add(cleaned);
      }
    } else {
      rawPaths.add(cleaned.startsWith('/') ? cleaned : '/$cleaned');
    }

    final String base = AppConfig.apiBaseURL.endsWith('/')
        ? AppConfig.apiBaseURL.substring(0, AppConfig.apiBaseURL.length - 1)
        : AppConfig.apiBaseURL;

    final List<String> fullUrls = [];

    for (final p in rawPaths) {
      final String decodedPath = Uri.decodeFull(p);
      
      // Candidate A: Normal path
      fullUrls.add('$base$decodedPath');

      // Candidate B: Spaces replaced by underscores (Django get_valid_filename convention)
      final String pathUnderscore = decodedPath.replaceAll(' ', '_').replaceAll('%20', '_');
      fullUrls.add('$base$pathUnderscore');

      // Candidate C: If path doesn't start with /media/, add /media prefix
      if (!decodedPath.startsWith('/media/')) {
        fullUrls.add('$base/media$decodedPath');
        fullUrls.add('$base/media$pathUnderscore');
      }

      // Candidate D: If path starts with /capacitaciones/, replace with /media/capacitaciones/
      if (decodedPath.startsWith('/capacitaciones/')) {
        final mediaPath = decodedPath.replaceFirst('/capacitaciones/', '/media/capacitaciones/');
        fullUrls.add('$base$mediaPath');
        fullUrls.add('$base${mediaPath.replaceAll(' ', '_').replaceAll('%20', '_')}');
      }

      // Candidate E: If path contains /files/, try without /files/ or /media/files/
      if (decodedPath.contains('/files/')) {
        final mediaFiles = decodedPath.replaceFirst('/files/', '/media/files/');
        fullUrls.add('$base$mediaFiles');
        fullUrls.add('$base${mediaFiles.replaceAll(' ', '_').replaceAll('%20', '_')}');
      }
    }

    final List<Uri> uris = [];
    final Set<String> seen = {};
    for (final urlStr in fullUrls) {
      try {
        final decoded = Uri.decodeFull(urlStr);
        final encoded = Uri.encodeFull(decoded);
        if (seen.add(encoded)) {
          uris.add(Uri.parse(encoded));
        }
      } catch (_) {}
    }

    return uris;
  }

  Future<void> _initVideo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.shared.getToken();
      final Map<String, String> headers = {
        'Accept': '*/*',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }

      String rawUrl = widget.videoUrl.trim();
      Uri? primaryUri;
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        primaryUri = Uri.tryParse(rawUrl);
      }

      // Approach 1: Try direct VideoPlayerController.networkUrl with pre-injected ?token= and Authorization header
      if (primaryUri != null) {
        try {
          _videoPlayerController = VideoPlayerController.networkUrl(
            primaryUri,
            httpHeaders: headers,
          );

          await _videoPlayerController!.initialize();

          final double aspect = _videoPlayerController!.value.aspectRatio > 0
              ? _videoPlayerController!.value.aspectRatio
              : (16 / 9);

          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            aspectRatio: aspect,
            autoPlay: true,
            looping: false,
            allowFullScreen: true,
            allowMuting: true,
            showControls: true,
          );

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        } catch (directError) {
          debugPrint('Notice direct networkUrl attempt: $directError');
        }
      }

      // Approach 2: Candidate URI resolution & HTTP fetch to local Blob/File URL (for Web CORS)
      final candidateUris = _generateCandidateUris(widget.videoUrl);
      for (final uri in candidateUris) {
        try {
          final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            final bytes = response.bodyBytes;
            final sample = String.fromCharCodes(bytes.take(100)).toLowerCase();
            if (!sample.contains('<html') && !sample.contains('<!doctype')) {
              final String sourceUrl = await createBlobOrFileUrl(bytes);
              if (sourceUrl.startsWith('blob:') || sourceUrl.startsWith('http')) {
                _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(sourceUrl));
              } else {
                _videoPlayerController = VideoPlayerController.file(File(sourceUrl));
              }

              await _videoPlayerController!.initialize();

              final double aspect = _videoPlayerController!.value.aspectRatio > 0
                  ? _videoPlayerController!.value.aspectRatio
                  : (16 / 9);

              _chewieController = ChewieController(
                videoPlayerController: _videoPlayerController!,
                aspectRatio: aspect,
                autoPlay: true,
                looping: false,
                allowFullScreen: true,
                allowMuting: true,
                showControls: true,
              );

              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              return;
            }
          }
        } catch (httpErr) {
          debugPrint('Candidate fetch notice for $uri: $httpErr');
        }
      }

      throw Exception("No se pudo cargar el video desde las fuentes de servidor.");
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No se pudo reproducir el video. Verifique que el archivo exista en el servidor y su formato sea compatible.";
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: ColorTheme.primary),
              SizedBox(height: 12),
              Text(
                "Cargando clase en video...",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 32),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _initVideo,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Reintentar", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTheme.primary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null) {
      return Container(
        height: 210,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

