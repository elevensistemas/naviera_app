import 'dart:async';
import 'dart:convert';
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
        if (data == null) return;

        String? status;
        if (data is String) {
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map && decoded['type'] == 'camera_status') {
              status = decoded['status']?.toString();
            }
          } catch (_) {}
        } else if (data is Map && data['type'] == 'camera_status') {
          status = data['status']?.toString();
        }

        if (status != null) {
          if (status == 'playing') {
            widget.onStatusChanged?.call(CameraPlayerStatus.playing);
          } else if (status == 'error') {
            widget.onStatusChanged?.call(CameraPlayerStatus.error);
          } else if (status == 'buffering') {
            widget.onStatusChanged?.call(CameraPlayerStatus.loading);
          }
        }
      } catch (_) {}
    });

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
    final cb = DateTime.now().millisecondsSinceEpoch;
    _viewId = 'hls-player-${widget.url.hashCode}-${(widget.vesselName ?? '').hashCode}-$cb';

    if (!_registeredViews.contains(_viewId)) {
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final container = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative'
          ..style.overflow = 'hidden'
          ..style.borderRadius = '12px'
          ..style.backgroundColor = '#0B1120';

        final iframe = html.IFrameElement()
          ..src = 'hls_player.html?cb=$cb&url=${Uri.encodeComponent(widget.url)}$vesselParam'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '12px'
          ..style.overflow = 'hidden'
          ..setAttribute('allow', 'autoplay; fullscreen')
          ..setAttribute('allowfullscreen', 'true');

        // Overlay interactivo nativo sobre la esquina superior izquierda (75x75 px)
        // para capturar de inmediato el clic sobre el círculo STS en web
        final stsOverlay = html.DivElement()
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.width = '75px'
          ..style.height = '75px'
          ..style.zIndex = '999999'
          ..style.cursor = 'pointer';

        DateTime? lastStsTap;
        stsOverlay.onClick.listen((e) {
          e.stopPropagation();
          e.preventDefault();
          final now = DateTime.now();
          if (lastStsTap != null && now.difference(lastStsTap!).inMilliseconds < 450) {
            return;
          }
          lastStsTap = now;
          html.window.postMessage('ncs_sts_click', '*');
        });

        container.children.addAll([iframe, stsOverlay]);
        return container;
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
