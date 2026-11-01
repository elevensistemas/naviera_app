import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'sbs_camera_player.dart';

Widget buildPlatformPlayer(
  BuildContext context,
  String url, {
  VoidCallback? onRetry,
  ValueChanged<CameraPlayerStatus>? onStatusChanged,
  String? vesselName,
}) {
  return SBSMobileCameraPlayer(
    url: url,
    onRetry: onRetry,
    onStatusChanged: onStatusChanged,
    vesselName: vesselName,
  );
}

class SBSMobileCameraPlayer extends StatefulWidget {
  final String url;
  final VoidCallback? onRetry;
  final ValueChanged<CameraPlayerStatus>? onStatusChanged;
  final String? vesselName;

  const SBSMobileCameraPlayer({
    super.key,
    required this.url,
    this.onRetry,
    this.onStatusChanged,
    this.vesselName,
  });

  @override
  State<SBSMobileCameraPlayer> createState() => _SBSMobileCameraPlayerState();
}

class _SBSMobileCameraPlayerState extends State<SBSMobileCameraPlayer> with WidgetsBindingObserver {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isDisposed = false;
  bool _hasAttemptedAutoRetry = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pausar reproducción para no dejar sockets ni buffers consumiendo en segundo plano en iOS
      try {
        _videoPlayerController?.pause();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      // Al volver a primer plano, si hubo error o el reproductor se desenganchó, reconectar
      if (_hasError || _videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
        _handleManualRetry();
      } else {
        _videoPlayerController?.play().catchError((_) {
          _handleManualRetry();
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant SBSMobileCameraPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _hasAttemptedAutoRetry = false;
      _cleanupControllers().then((_) {
        if (!_isDisposed && mounted) {
          _initializePlayer();
        }
      });
    }
  }

  Future<void> _cleanupControllers() async {
    final oldChewie = _chewieController;
    final oldVideo = _videoPlayerController;
    _chewieController = null;
    _videoPlayerController = null;

    if (oldVideo != null) {
      oldVideo.removeListener(_playerListener);
      try {
        await oldVideo.pause();
      } catch (_) {}
      // Nota técnica: dispose() libera la instancia del controlador Flutter y solicita la
      // destrucción de AVPlayer en iOS. El cierre definitivo de sockets de red TCP/TLS a nivel SO
      // es gestionado de manera asíncrona por el subsistema AVFoundation / CFNetwork.
      oldVideo.dispose();
    }
    oldChewie?.dispose();
  }

  void _playerListener() {
    if (_isDisposed || !mounted) return;
    final controller = _videoPlayerController;
    if (controller != null && controller.value.hasError) {
      final err = controller.value.errorDescription ?? 'Error en la transmisión de video';
      if (!_hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = err;
        });
        widget.onStatusChanged?.call(CameraPlayerStatus.error);
      }
    }
  }

  Future<void> _initializePlayer() async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    widget.onStatusChanged?.call(CameraPlayerStatus.loading);

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _videoPlayerController = controller;

      await controller.initialize();
      if (_isDisposed || !mounted) {
        controller.dispose();
        return;
      }

      controller.addListener(_playerListener);

      _chewieController = ChewieController(
        videoPlayerController: controller,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        showControls: false,
        allowFullScreen: true,
        allowMuting: true,
        placeholder: Container(
          color: const Color(0xFF0F172A),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF0284C7),
              ),
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
      );

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      widget.onStatusChanged?.call(CameraPlayerStatus.playing);
    } catch (e) {
      if (_isDisposed || !mounted) return;

      // Auto-reintento transparente una vez si es error de red o sesión perdida
      if (!_hasAttemptedAutoRetry && widget.onRetry != null) {
        _hasAttemptedAutoRetry = true;
        debugPrint("[SBS Mobile Camera] Auto-reintentando conexión tras error: $e");
        widget.onRetry!();
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      widget.onStatusChanged?.call(CameraPlayerStatus.error);
    }
  }

  void _handleManualRetry() {
    _hasAttemptedAutoRetry = false;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    widget.onStatusChanged?.call(CameraPlayerStatus.loading);
    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      _cleanupControllers().then((_) {
        if (!_isDisposed && mounted) _initializePlayer();
      });
    }
  }

  Widget _buildErrorWidget([String? customError]) {
    return Container(
      color: const Color(0xFF0B132B),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: Color(0xFFF87171),
                size: 32,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Cámara no disponible",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "No se pudo reproducir la cámara de ${widget.vesselName ?? 'este buque'}. Reintentá para restablecer la conexión.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _handleManualRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                "Reconectar cámara",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }
    if (_isLoading || _chewieController == null) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Conectando transmisión en vivo...",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final isGustavo = (widget.vesselName?.toUpperCase().contains('GUSTAVO') ?? false) ||
        widget.url.contains('BF1767228');

    final size = _videoPlayerController?.value.size;
    final double videoW = (size != null && size.width > 0) ? size.width : 1600.0;
    final double videoH = (size != null && size.height > 0) ? size.height : 900.0;

    Widget player = FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: videoW,
        height: videoH,
        child: Chewie(controller: _chewieController!),
      ),
    );

    if (isGustavo) {
      player = ClipRect(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(1.06)
            ..rotateZ(-3.4 * (math.pi / 180.0)),
          child: player,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: player,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _cleanupControllers();
    super.dispose();
  }
}

