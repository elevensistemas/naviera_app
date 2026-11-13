import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformMapView(
  BuildContext context,
  String webviewUrl, {
  VoidCallback? onStsBadgeTap,
}) {
  return _WebPlatformMapView(
    webviewUrl: webviewUrl,
    onStsBadgeTap: onStsBadgeTap,
  );
}

class _WebPlatformMapView extends StatefulWidget {
  final String webviewUrl;
  final VoidCallback? onStsBadgeTap;

  const _WebPlatformMapView({
    required this.webviewUrl,
    this.onStsBadgeTap,
  });

  @override
  State<_WebPlatformMapView> createState() => _WebPlatformMapViewState();
}

class _WebPlatformMapViewState extends State<_WebPlatformMapView> {
  late String _viewId;
  static final Set<String> _registeredViews = {};
  static final Map<String, VoidCallback?> _callbackMap = {};

  @override
  void initState() {
    super.initState();
    _initView();
  }

  void _initView() {
    // Convertir la URL de Centinela para que pase por el proxy local en Web
    String effectiveUrl = widget.webviewUrl;
    if (effectiveUrl.contains('centinela.dyndns.org:5073')) {
      effectiveUrl = effectiveUrl.replaceFirst('https://centinela.dyndns.org:5073', 'http://127.0.0.1:8086');
    }

    final cb = DateTime.now().millisecondsSinceEpoch;
    final hash = effectiveUrl.hashCode.abs().toString();
    _viewId = 'centinela-map-iframe-$hash-$cb';
    _callbackMap[_viewId] = widget.onStsBadgeTap;

    if (!_registeredViews.contains(_viewId)) {
      _registeredViews.add(_viewId);
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final container = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative'
          ..style.overflow = 'hidden'
          ..style.borderRadius = '12px'
          ..style.backgroundColor = '#0F172A';

        final iframe = html.IFrameElement()
          ..src = effectiveUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.backgroundColor = '#0F172A'
          ..allow = 'geolocation *; fullscreen *'
          ..setAttribute('allowfullscreen', 'true');

        // Overlay interactivo nativo sobre la esquina superior izquierda (60x60 px)
        // para capturar el clic sobre el círculo STS directamente en el DOM de la web
        final stsOverlay = html.DivElement()
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.width = '60px'
          ..style.height = '60px'
          ..style.zIndex = '999999'
          ..style.cursor = 'pointer'
          ..title = 'Auditoría OCIMF 2026';

        DateTime? lastTap;
        stsOverlay.onClick.listen((e) {
          e.stopPropagation();
          e.preventDefault();
          final now = DateTime.now();
          if (lastTap != null && now.difference(lastTap!).inMilliseconds < 450) {
            return;
          }
          lastTap = now;
          _callbackMap[_viewId]?.call();
        });

        container.children.addAll([iframe, stsOverlay]);
        return container;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _WebPlatformMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _callbackMap[_viewId] = widget.onStsBadgeTap;
    if (oldWidget.webviewUrl != widget.webviewUrl) {
      _initView();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
