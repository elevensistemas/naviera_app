import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'sbs_camera_player.dart';

Widget buildPlatformPlayer(
  BuildContext context,
  String url, {
  VoidCallback? onRetry,
  ValueChanged<CameraPlayerStatus>? onStatusChanged,
  String? vesselName,
}) {
  return SBSWebCameraPlayer(
    url: url,
    onRetry: onRetry,
    onStatusChanged: onStatusChanged,
    vesselName: vesselName,
  );
}

class SBSWebCameraPlayer extends StatefulWidget {
  final String url;
  final VoidCallback? onRetry;
  final ValueChanged<CameraPlayerStatus>? onStatusChanged;
  final String? vesselName;

  const SBSWebCameraPlayer({
    super.key,
    required this.url,
    this.onRetry,
    this.onStatusChanged,
    this.vesselName,
  });

  @override
  State<SBSWebCameraPlayer> createState() => _SBSWebCameraPlayerState();
}

class _SBSWebCameraPlayerState extends State<SBSWebCameraPlayer> {
  late String _viewId;
  static final Set<String> _registeredViews = {};
  StreamSubscription? _msgSub;

  @override
  void initState() {
    super.initState();
    _initView();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    _msgSub = html.window.onMessage.listen((event) {
      try {
        final data = event.data;
        if (data is Map && data['type'] == 'camera_status') {
          final s = data['status']?.toString();
          if (s == 'playing') {
            widget.onStatusChanged?.call(CameraPlayerStatus.playing);
          } else if (s == 'error') {
            widget.onStatusChanged?.call(CameraPlayerStatus.error);
          } else if (s == 'buffering') {
            widget.onStatusChanged?.call(CameraPlayerStatus.loading);
          }
        }
      } catch (_) {}
    });

    // Notificación preventiva de playing si la URL es válida
    if (widget.url.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          widget.onStatusChanged?.call(CameraPlayerStatus.playing);
        }
      });
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SBSWebCameraPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.vesselName != widget.vesselName) {
      setState(() {
        _initView();
      });
      if (widget.url.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            widget.onStatusChanged?.call(CameraPlayerStatus.playing);
          }
        });
      }
    }
  }

  void _initView() {
    final vesselParam = widget.vesselName != null && widget.vesselName!.isNotEmpty
        ? '&vessel=${Uri.encodeComponent(widget.vesselName!)}'
        : '';
    // Unique view type per URL and vessel to avoid view factory conflicts
    _viewId = 'hls-player-${widget.url.hashCode}-${(widget.vesselName ?? '').hashCode}';
    
    // Register the view factory for the iframe only once
    if (!_registeredViews.contains(_viewId)) {
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'hls_player.html?url=${Uri.encodeComponent(widget.url)}$vesselParam'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '12px'
          ..style.overflow = 'hidden'
          ..setAttribute('allow', 'autoplay; fullscreen')
          ..setAttribute('allowfullscreen', 'true');
        return iframe;
      });
      _registeredViews.add(_viewId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(
        key: ValueKey(_viewId),
        viewType: _viewId,
      ),
    );
  }
}
