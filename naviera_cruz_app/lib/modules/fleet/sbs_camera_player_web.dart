import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformPlayer(BuildContext context, String url) {
  return SBSWebCameraPlayer(url: url);
}

class SBSWebCameraPlayer extends StatefulWidget {
  final String url;
  const SBSWebCameraPlayer({super.key, required this.url});

  @override
  State<SBSWebCameraPlayer> createState() => _SBSWebCameraPlayerState();
}

class _SBSWebCameraPlayerState extends State<SBSWebCameraPlayer> {
  late String _viewId;
  static final Set<String> _registeredViews = {};

  @override
  void initState() {
    super.initState();
    _initView();
  }

  @override
  void didUpdateWidget(covariant SBSWebCameraPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _initView();
      });
    }
  }

  void _initView() {
    // Unique view type per URL to avoid view factory conflicts
    _viewId = 'hls-player-${widget.url.hashCode}';
    
    // Register the view factory for the iframe only once
    if (!_registeredViews.contains(_viewId)) {
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'hls_player.html?url=${Uri.encodeComponent(widget.url)}'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });
      _registeredViews.add(_viewId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
