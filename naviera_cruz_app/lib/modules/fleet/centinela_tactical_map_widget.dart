import 'package:flutter/material.dart';
import '../../models/centinela_fleet_models.dart';
import '../../services/centinela_fleet_service.dart';
import 'centinela_map_platform_stub.dart'
    if (dart.library.html) 'centinela_map_platform_web.dart';

class CentinelaTacticalMapWidget extends StatefulWidget {
  final String vesselIdentifier;
  final String vesselName;
  final bool isFullscreen;
  final VoidCallback? onStsBadgeTap;

  const CentinelaTacticalMapWidget({
    super.key,
    required this.vesselIdentifier,
    required this.vesselName,
    this.isFullscreen = false,
    this.onStsBadgeTap,
  });

  @override
  State<CentinelaTacticalMapWidget> createState() => _CentinelaTacticalMapWidgetState();
}

class _CentinelaTacticalMapWidgetState extends State<CentinelaTacticalMapWidget> {
  CentinelaMapSession? _session;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void didUpdateWidget(covariant CentinelaTacticalMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vesselIdentifier != widget.vesselIdentifier) {
      _loadSession();
    }
  }

  Future<void> _loadSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await CentinelaFleetService.shared.createMapSession(
        widget.vesselIdentifier,
        initialLayer: 'satellite',
        initialHours: 6,
      );

      if (mounted) {
        if (session != null && session.webviewUrl.isNotEmpty) {
          setState(() {
            _session = session;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "No se pudo generar la sesión del mapa táctico.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error de conexión con Centinela.";
          _isLoading = false;
        });
      }
    }
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            title: Text(
              "Mapa Táctico Satelital · ${widget.vesselName}",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                onPressed: _loadSession,
                tooltip: "Actualizar mapa",
              ),
            ],
          ),
          body: CentinelaTacticalMapWidget(
            vesselIdentifier: widget.vesselIdentifier,
            vesselName: widget.vesselName,
            isFullscreen: true,
            onStsBadgeTap: widget.onStsBadgeTap,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFF0B1120),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Iniciando sesión segura de Mapa Táctico...",
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _session == null) {
      return Container(
        color: const Color(0xFF0B1120),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, color: Colors.white38, size: 38),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? "Mapa no disponible",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _loadSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Reintentar", style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: buildPlatformMapView(
            context,
            _session!.webviewUrl,
            onStsBadgeTap: widget.onStsBadgeTap,
          ),
        ),
        if (!widget.isFullscreen)
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openFullscreen(context),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xB30B132B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

