import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget buildPlatformMapView(
  BuildContext context,
  String webviewUrl, {
  VoidCallback? onStsBadgeTap,
}) {
  return _MobilePlatformMapView(webviewUrl: webviewUrl, onStsBadgeTap: onStsBadgeTap);
}

class _MobilePlatformMapView extends StatefulWidget {
  final String webviewUrl;
  final VoidCallback? onStsBadgeTap;
  const _MobilePlatformMapView({required this.webviewUrl, this.onStsBadgeTap});

  @override
  State<_MobilePlatformMapView> createState() => _MobilePlatformMapViewState();
}

class _MobilePlatformMapViewState extends State<_MobilePlatformMapView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("[Centinela Tactical Map Mobile] Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.webviewUrl));
  }

  @override
  void didUpdateWidget(covariant _MobilePlatformMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.webviewUrl != widget.webviewUrl) {
      _controller.loadRequest(Uri.parse(widget.webviewUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: const Color(0xFF0F172A),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Cargando cartas náuticas y AIS...",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

