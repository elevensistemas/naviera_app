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
            _injectMapCustomizations();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("[Centinela Tactical Map Mobile] Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.webviewUrl));
  }

  void _injectMapCustomizations() {
    const js = '''
(function() {
  function applyStyles() {
    if (!document.getElementById('ncs-custom-map-hide-style')) {
      const style = document.createElement('style');
      style.id = 'ncs-custom-map-hide-style';
      style.textContent = `
        /* Ocultar selector inferior de barcos (cards flotantes de selección en el mapa) */
        .mobile-fleet-strip,
        .mobile-vessel-chip,
        .mobile-segmented-row,
        [class*="fleet-strip"],
        [class*="vessel-chip"],
        [class*="vessel-chips"] {
          display: none !important;
          visibility: hidden !important;
          opacity: 0 !important;
          pointer-events: none !important;
          height: 0 !important;
          min-height: 0 !important;
          max-height: 0 !important;
          overflow: hidden !important;
        }

        /* Ocultar barra superior redundante si existiese */
        .mobile-hud-top-bar {
          display: none !important;
        }

        /* Ocultar pintado de recorridos / estelas de color sobre el agua */
        .leaflet-pane.leaflet-overlay-pane svg g path,
        .leaflet-pane.leaflet-overlay-pane svg path {
          display: none !important;
        }
      `;
      (document.head || document.documentElement).appendChild(style);
    }

    const strips = document.querySelectorAll('.mobile-fleet-strip, [class*="fleet-strip"], .mobile-vessel-chip, [class*="vessel-chip"]');
    strips.forEach(el => {
      el.style.setProperty('display', 'none', 'important');
      el.style.setProperty('visibility', 'hidden', 'important');
      el.style.setProperty('height', '0px', 'important');
    });
  }

  applyStyles();
  if (window.MutationObserver) {
    new MutationObserver(applyStyles).observe(document.documentElement, {
      childList: true,
      subtree: true
    });
  }
  setInterval(applyStyles, 600);
})();
''';
    _controller.runJavaScript(js).catchError((e) {
      debugPrint("[Centinela Tactical Map Mobile] Error inyectando estilos: $e");
    });
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

