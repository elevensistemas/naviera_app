import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/ncs_hero_header.dart';
import '../crew/crew_list_view.dart';
import 'sbs_camera_player.dart';

class FleetView extends StatefulWidget {
  const FleetView({super.key});

  @override
  State<FleetView> createState() => _FleetViewState();
}

class _FleetViewState extends State<FleetView> with WidgetsBindingObserver {
  final List<Ship> _ships = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedShipIndex = 0;
  Timer? _autoRefreshTimer;
  DateTime? _lastSyncTime;
  final Map<String, CameraPlayerStatus> _cameraStatuses = {};
  final Set<String> _reconnectingShips = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pre-poblar inmediatamente los buques para iniciar la conexión de Alfa C en el primer frame
    _ships.addAll(_getDefaultShipsList());
    _loadCameraForShip(_ships[0], forceRefresh: true);
    _loadShips(isSilent: true);
    // Auto-actualización periódica de recursos y programas de carga 4 veces al día (cada 6 horas)
    _autoRefreshTimer = Timer.periodic(const Duration(hours: 6), (_) {
      if (mounted) {
        _loadShips(isSilent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Al volver a primer plano, reconectar la cámara seleccionada si la sesión cayó
      if (mounted && _ships.isNotEmpty && _selectedShipIndex < _ships.length) {
        _loadCameraForShip(_ships[_selectedShipIndex], forceRefresh: true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  static String getShipCameraSerial(Ship ship) {
    final name = ship.name.toUpperCase();
    if (name.contains('ALFA')) return 'BF1765385';
    if (name.contains('NANY')) return 'BF1765344';
    if (name.contains('GUSTAVO')) return 'BF1767228';
    if (ship.cameras.isNotEmpty) {
      final cam = ship.cameras.firstWhere(
        (c) => c.serialNumber.isNotEmpty,
        orElse: () => ship.cameras.first,
      );
      if (cam.serialNumber.isNotEmpty) return cam.serialNumber;
    }
    return 'BF1765385';
  }

  static String? getShipCameraId(Ship ship) {
    final name = ship.name.toUpperCase();
    if (name.contains('ALFA')) return '10012';
    if (name.contains('NANY')) return '9';
    if (name.contains('GUSTAVO')) return '12';
    if (ship.cameras.isNotEmpty) {
      final cam = ship.cameras.firstWhere(
        (c) => c.id.isNotEmpty,
        orElse: () => ship.cameras.first,
      );
      if (cam.id.isNotEmpty) return cam.id;
    }
    return null;
  }

  Future<void> _loadShips({bool isSilent = false}) async {
    if (!isSilent && _ships.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final fleetService = FleetService();
      final ships = await fleetService.fetchShips();
      
      final List<Ship> sorted = [];
      if (ships.isNotEmpty) {
        Ship? alfa = ships.firstWhere((s) => s.name.toUpperCase().contains('ALFA'), orElse: () => ships.first);
        Ship? gustavo = ships.firstWhere((s) => s.name.toUpperCase().contains('GUSTAVO'), orElse: () => (ships.length > 1 ? ships[1] : ships.first));
        Ship? nany = ships.firstWhere((s) => s.name.toUpperCase().contains('NANY'), orElse: () => ships.last);

        alfa = alfa.copyWith(
          name: "ALFA C",
          flag: "Panamá 🇵🇦",
          imoNumber: "9711652",
          targetShips: alfa.targetShips.isNotEmpty
              ? alfa.targetShips
              : Ship.getDefaultTargetShipsFor("ALFA C"),
          lastPort: alfa.lastPort.isNotEmpty ? alfa.lastPort : 'BUENOS AIRES',
          provistosCount: alfa.targetShips.isNotEmpty ? alfa.targetShips.length : 2,
          weather: '',
        );
        gustavo = gustavo.copyWith(
          name: "GUSTAVO U",
          targetShips: gustavo.targetShips.isNotEmpty
              ? gustavo.targetShips
              : Ship.getDefaultTargetShipsFor("GUSTAVO U"),
          lastPort: gustavo.lastPort.isNotEmpty ? gustavo.lastPort : 'RADA LA PLATA',
          provistosCount: gustavo.targetShips.isNotEmpty ? gustavo.targetShips.length : 3,
          weather: '',
        );
        nany = nany.copyWith(
          name: "NANY",
          targetShips: nany.targetShips.isNotEmpty
              ? nany.targetShips
              : Ship.getDefaultTargetShipsFor("NANY"),
          lastPort: nany.lastPort.isNotEmpty ? nany.lastPort : 'CAMPANA',
          provistosCount: nany.targetShips.isNotEmpty ? nany.targetShips.length : 5,
          weather: '',
        );

        sorted.add(alfa);
        if (gustavo.id != alfa.id) sorted.add(gustavo);
        if (nany.id != alfa.id && nany.id != gustavo.id) sorted.add(nany);
      } else {
        sorted.addAll(_getDefaultShipsList());
      }

      // Preservar URLs de cámara que ya hayan sido resueltas en memoria para no reiniciarlas
      final Map<String, String> existingCameraUrls = {
        for (final s in _ships)
          if (s.cameraUrl != null && s.cameraUrl!.isNotEmpty)
            s.name.toUpperCase(): s.cameraUrl!
      };

      for (int i = 0; i < sorted.length; i++) {
        final key = sorted[i].name.toUpperCase();
        for (final entry in existingCameraUrls.entries) {
          if (key.contains(entry.key) || entry.key.contains(key)) {
            sorted[i] = sorted[i].copyWith(cameraUrl: entry.value);
            break;
          }
        }
      }

      setState(() {
        _ships.clear();
        _ships.addAll(sorted);
        _lastSyncTime = DateTime.now();
        if (_selectedShipIndex >= _ships.length) {
          _selectedShipIndex = 0;
        }
      });
      if (_ships.isNotEmpty) {
        final current = _ships[_selectedShipIndex];
        if (current.cameraUrl == null || current.cameraUrl!.isEmpty) {
          _loadCameraForShip(current, forceRefresh: true);
        }
      }
    } catch (e) {
      if (_ships.isEmpty) {
        setState(() {
          _ships.clear();
          _ships.addAll(_getDefaultShipsList());
          _lastSyncTime = DateTime.now();
          _selectedShipIndex = 0;
        });
        _loadCameraForShip(_ships[0], forceRefresh: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCameraForShip(Ship ship, {bool forceRefresh = false}) async {
    final serial = getShipCameraSerial(ship);
    final cameraId = getShipCameraId(ship);

    if (!forceRefresh && ship.cameraUrl != null && ship.cameraUrl!.isNotEmpty) {
      return;
    }

    setState(() {
      _reconnectingShips.add(ship.id);
      _cameraStatuses[ship.id] = CameraPlayerStatus.loading;
    });

    try {
      if (forceRefresh) {
        EzvizService.shared.clearOfflineStatus(serial);
        EzvizService.shared.invalidateCache(serial);
      }
      final freshUrl = await EzvizService.shared.getLiveStreamUrl(
        serial,
        cameraId: cameraId,
        forceRefresh: forceRefresh,
      );

      // Verificación estricta: asegurar que la URL pertenece al serial específico de este buque
      if (!freshUrl.contains(serial)) {
        debugPrint("[CÁMARA RECHAZADA] URL no coincide con serial $serial de ${ship.name}");
        throw Exception("Inconsistencia en transmisión de ${ship.name}");
      }

      if (mounted) {
        setState(() {
          // Búsqueda ESTRICTA por ID o nombre del buque (NUNCA por índice mutable)
          final idx = _ships.indexWhere((s) => s.id == ship.id || s.name == ship.name);
          if (idx != -1) {
            _ships[idx] = _ships[idx].copyWith(cameraUrl: freshUrl);
          }
          _reconnectingShips.remove(ship.id);
        });
      }
    } catch (e) {
      debugPrint("Error cargando cámara para ${ship.name} ($serial): $e");
      if (mounted) {
        setState(() {
          _reconnectingShips.remove(ship.id);
          _cameraStatuses[ship.id] = CameraPlayerStatus.error;
        });
      }
    }
  }

  Future<void> _reconnectCamera(Ship ship) async {
    final idx = _ships.indexWhere((s) => s.id == ship.id || s.name == ship.name);
    if (idx != -1) {
      setState(() {
        _ships[idx] = _ships[idx].copyWith(cameraUrl: "");
      });
    }

    final serial = getShipCameraSerial(ship);
    EzvizService.shared.clearOfflineStatus(serial);
    EzvizService.shared.invalidateCache(serial);

    await _loadCameraForShip(ship, forceRefresh: true);
  }

  Widget _buildCameraBadge(Ship ship, bool isDark) {
    final serial = getShipCameraSerial(ship);

    final hasConfiguredCamera = ship.cameras.isNotEmpty && ship.cameras.any((c) => c.serialNumber.isNotEmpty);
    final hasActiveCameraConfig = ship.cameras.any((c) => c.isActive && c.serialNumber.isNotEmpty);
    final isDeviceOffline = EzvizService.shared.isDeviceOffline(serial);
    final isReconnecting = _reconnectingShips.contains(ship.id);
    final status = _cameraStatuses[ship.id] ?? 
        (isReconnecting 
            ? CameraPlayerStatus.loading 
            : (ship.cameraUrl != null && ship.cameraUrl!.isNotEmpty ? CameraPlayerStatus.loading : CameraPlayerStatus.error));

    // SIN CÁMARA: el buque no tiene una cámara configurada en el sistema o está deshabilitada administrativamente
    // (IMPORTANTE: isActive: false representa configuración administrativa, NO desconexión física del equipo)
    if (!hasConfiguredCamera || !hasActiveCameraConfig) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, size: 11, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              "SIN CÁMARA",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // FUERA DE LÍNEA: EZVIZ confirma mediante telemetría que la cámara física está desconectada/offline
    if (isDeviceOffline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 11, color: Colors.blueGrey),
            SizedBox(width: 4),
            Text(
              "FUERA DE LÍNEA",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      );
    }

    // CONECTANDO...: mientras resuelve la URL o inicializa el reproductor
    if (isReconnecting || status == CameraPlayerStatus.loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF0284C7),
              ),
            ),
            SizedBox(width: 5),
            Text(
              "CONECTANDO...",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0284C7),
              ),
            ),
          ],
        ),
      );
    }

    // NO DISPONIBLE: cuando la transmisión no pudo reproducir o falló la conexión
    if (status == CameraPlayerStatus.error) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              "NO DISPONIBLE",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      );
    }

    // EN VIVO: cuando el stream está reproduciendo activamente
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            "EN VIVO",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  List<Ship> _getDefaultShipsList() {
    return [
      Ship(
        id: "4",
        name: "ALFA C",
        status: ShipStatus.active,
        totalCargo: 150.54,
        totalCarbon: 150.54,
        totalWater: 118.2,
        totalSlop: 8.31,
        imoNumber: "9711652",
        flag: "Panamá 🇵🇦",
        latitude: -42.76,
        longitude: -65.03,
        cameraUrl: "",
        cameras: [
          ShipCamera(id: "cam-alfa", name: "BT.ALFAC", serialNumber: "BF1765385", isActive: true),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("ALFA C"),
        captainName: "Carré Leonel",
        chiefEngineerName: "Lescano Cristian",
        lastPort: "BUENOS AIRES",
        weather: "",
        provistosCount: 2,
        provistosTotal: 6915.00,
      ),
      Ship(
        id: "6",
        name: "GUSTAVO U",
        status: ShipStatus.active,
        totalCargo: 89.76,
        totalCarbon: 89.76,
        totalWater: 90.0,
        totalSlop: 11.89,
        imoNumber: "9654321",
        flag: "Argentina 🇦🇷",
        latitude: -38.00,
        longitude: -57.55,
        cameraUrl: "",
        cameras: [
          ShipCamera(id: "cam-gustavo", name: "BT.GUSTAVO.U", serialNumber: "BF1767228", isActive: true),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("GUSTAVO U"),
        captainName: "Percara Marco",
        chiefEngineerName: "Alday Alexis",
        lastPort: "RADA LA PLATA",
        weather: "",
        provistosCount: 3,
        provistosTotal: 1300.00,
      ),
      Ship(
        id: "5",
        name: "NANY",
        status: ShipStatus.active,
        totalCargo: 115.52,
        totalCarbon: 115.52,
        totalWater: 125.36,
        totalSlop: 86.39,
        imoNumber: "9018115",
        flag: "Argentina 🇦🇷",
        latitude: -54.80,
        longitude: -68.30,
        cameraUrl: "",
        cameras: [
          ShipCamera(id: "cam-nany", name: "BT.NANY1", serialNumber: "BF1765344", isActive: true),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("NANY"),
        captainName: "Hernandez Pablo",
        chiefEngineerName: "Carlino Hernan",
        lastPort: "CAMPANA",
        weather: "",
        provistosCount: 5,
        provistosTotal: 4320.00,
      ),
    ];
  }

  String _getCargoProgramInfo(Ship ship) {
    final upper = ship.name.toUpperCase();
    final count = ship.targetShips.isNotEmpty ? ship.targetShips.length : (ship.provistosCount > 0 ? ship.provistosCount : 0);
    if (upper.contains('ALFA')) {
      final totalStr = ship.provistosTotal > 0 ? "${ship.provistosTotal.toStringAsFixed(0)} m³" : "6915 m³";
      return "Raizen ($totalStr • $count buques)";
    } else if (upper.contains('NANY')) {
      final totalStr = ship.provistosTotal > 0 ? "${(ship.provistosTotal / 1000).toStringAsFixed(2)} k t" : "4.32 k t";
      return "WFS ($totalStr • $count buques)";
    } else if (upper.contains('GUSTAVO')) {
      final totalStr = ship.provistosTotal > 0 ? "${(ship.provistosTotal / 1000).toStringAsFixed(2)} k t" : "7.39 k t";
      return "WFS ($totalStr • $count buques)";
    }
    return "Raizen";
  }

  Color _getShipThemeColor(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('ALFA')) return const Color(0xFF0057B8); // Azul
    if (upper.contains('GUSTAVO')) return const Color(0xFF64748B); // Gris
    if (upper.contains('NANY')) return const Color(0xFFED8B00); // Naranja
    return const Color(0xFF0057B8);
  }

  double _getFuelPercentage(Ship ship) {
    final val = ship.totalCarbon > 0 ? ship.totalCarbon : ship.totalCargo;
    if (val <= 0) return 0.0;
    if (ship.name.toUpperCase().contains('ALFA')) {
      return (val / 200.0).clamp(0.0, 1.0); // 150.54 m³ / 200 = 75%
    } else if (ship.name.toUpperCase().contains('GUSTAVO')) {
      return (val / 150.0).clamp(0.0, 1.0); // 89.76 m³ / 150 = 60%
    } else {
      return (val / 160.0).clamp(0.0, 1.0); // 115.52 m³ / 160 = 72%
    }
  }

  double _getWaterPercentage(Ship ship) {
    final val = ship.totalWater;
    if (val <= 0) return 0.0;
    if (ship.name.toUpperCase().contains('ALFA')) {
      return (val / 250.0).clamp(0.0, 1.0); // 118.2 m³ / 250 = 47%
    } else if (ship.name.toUpperCase().contains('GUSTAVO')) {
      return (val / 200.0).clamp(0.0, 1.0); // 90.0 m³ / 200 = 45%
    } else {
      return (val / 200.0).clamp(0.0, 1.0); // 125.36 m³ / 200 = 63%
    }
  }

  double _getSlopPercentage(Ship ship) {
    final val = ship.totalSlop;
    if (val <= 0) return 0.0;
    if (ship.name.toUpperCase().contains('ALFA')) {
      return (val / 30.0).clamp(0.0, 1.0); // 8.31 m³ / 30 = 28%
    } else if (ship.name.toUpperCase().contains('GUSTAVO')) {
      return (val / 30.0).clamp(0.0, 1.0); // 11.89 m³ / 30 = 40%
    } else {
      return (val / 120.0).clamp(0.0, 1.0); // 86.39 m³ / 120 = 72%
    }
  }

  String _getFuelValue(Ship ship) {
    final val = ship.totalCarbon > 0 ? ship.totalCarbon : ship.totalCargo;
    if (val <= 0) return "0.00 m³";
    return "${val.toStringAsFixed(2)} m³";
  }

  String _getWaterValue(Ship ship) {
    final val = ship.totalWater;
    if (val <= 0) return "0.0 m³";
    return "${val.toStringAsFixed(1)} m³";
  }

  String _getSlopValue(Ship ship) {
    final val = ship.totalSlop;
    if (val <= 0) return "0.00 m³";
    return "${val.toStringAsFixed(2)} m³";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final currentShip = (_ships.isNotEmpty && _selectedShipIndex < _ships.length)
        ? _ships[_selectedShipIndex]
        : null;

    final String shipDisplayName = currentShip != null
        ? (currentShip.name.startsWith('BT ') ? currentShip.name : "BT ${currentShip.name}")
        : "BT ALFA C";

    final String bannerTitle = shipDisplayName;

    final String bannerSubtitle = currentShip != null
        ? "Monitoreo en tiempo real • IMO ${currentShip.imoNumber}"
        : "Monitoreo en tiempo real de nuestra flota.";

    return Container(
      color: bodyBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reusable NcsHeroHeader component
          NcsHeroHeader(
            title: bannerTitle,
            subtitle: bannerSubtitle,
          ),
          
          // Ship Selection Tabs (Cápsulas predefinidas azul, gris y naranja adaptables para móvil)
          if (!_isLoading && _ships.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: _ships.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ship = entry.value;
                  final isSelected = _selectedShipIndex == index;
                  final shipColor = _getShipThemeColor(ship.name);
                  
                  final Color chipBgColor;
                  final Color chipTextColor;
                  final Color chipIconColor;
                  final Border chipBorder;

                  if (isSelected) {
                    chipBgColor = shipColor;
                    chipTextColor = Colors.white;
                    chipIconColor = Colors.white;
                    chipBorder = Border.all(color: shipColor, width: 1.5);
                  } else {
                    chipBgColor = isDark
                        ? shipColor.withValues(alpha: 0.25)
                        : shipColor.withValues(alpha: 0.12);
                    chipTextColor = isDark
                        ? Colors.white
                        : shipColor;
                    chipIconColor = isDark
                        ? Colors.white70
                        : shipColor;
                    chipBorder = Border.all(
                      color: shipColor.withValues(alpha: isDark ? 0.5 : 0.35),
                      width: 1.5,
                    );
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedShipIndex != index) {
                            setState(() {
                              _selectedShipIndex = index;
                            });
                            final selected = _ships[index];
                            if (selected.cameraUrl == null || selected.cameraUrl!.isEmpty) {
                              _loadCameraForShip(selected, forceRefresh: true);
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          decoration: BoxDecoration(
                            color: chipBgColor,
                            borderRadius: BorderRadius.circular(24),
                            border: chipBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_boat_filled_rounded,
                                size: isMobile ? 15 : 17,
                                color: chipIconColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    ship.name.toUpperCase(),
                                    style: TextStyle(
                                      color: chipTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 11.5 : 13.5,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Sincronización en tiempo real y auto-actualización periódica (4 veces al día)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _lastSyncTime != null
                          ? "Sincronizado: ${_lastSyncTime!.hour.toString().padLeft(2, '0')}:${_lastSyncTime!.minute.toString().padLeft(2, '0')} hs • Auto-actualización (4x/día)"
                          : "Auto-actualización de recursos y programa (4x/día)",
                      style: TextStyle(
                        fontSize: isMobile ? 10.5 : 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _isLoading ? null : () => _loadShips(),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: Color(0xFF0057B8),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "Actualizar",
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0057B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading && _ships.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadShips,
                    child: _ships.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                _errorMessage ?? "No hay barcos disponibles.",
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              left: isMobile ? 10.0 : 16.0,
                              right: isMobile ? 10.0 : 16.0,
                              top: 8.0,
                              bottom: 90.0,
                            ),
                            children: [
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 960),
                                  child: _buildShipCard(context, _ships[_selectedShipIndex], theme),
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipCard(BuildContext context, Ship ship, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9);
    final shipAccentColor = _getShipThemeColor(ship.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: dividerColor, width: 1.0),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Ship Name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: shipAccentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ship.name.startsWith('BT ') ? ship.name : "BT ${ship.name}",
                      style: TypographyTheme.headline(context).copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vessel Information: Flag & Cargo Program
            Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined, size: 14, color: secondaryTextColor),
                    const SizedBox(width: 4),
                    Text(
                      "Bandera: ${ship.flag}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics_outlined, size: 14, color: shipAccentColor),
                    const SizedBox(width: 4),
                    Text(
                      "Programa: ",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: shipAccentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: shipAccentColor.withOpacity(0.3), width: 0.8),
                      ),
                      child: Text(
                        _getCargoProgramInfo(ship),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: shipAccentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            

            
            // Header de Cámara a Bordo
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam_rounded, size: 17, color: Color(0xFF0057B8)),
                    const SizedBox(width: 6),
                    Text(
                      "Cámara en Vivo a Bordo",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ship.cameras.any((c) => c.isActive)) ...[
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        tooltip: "Reconectar señal",
                        color: isDark ? Colors.white70 : Colors.black54,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () => _reconnectCamera(ship),
                      ),
                      const SizedBox(width: 4),
                    ],
                    _buildCameraBadge(ship, isDark),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),

          // Video Player or Fallback for SBS camera: full width within card (border 1px)
          if (ship.cameraUrl != null && ship.cameraUrl!.isNotEmpty)
            SBSCameraPlayer(
              key: ValueKey('${ship.id}-${ship.name}-${ship.cameraUrl}'),
              url: ship.cameraUrl!,
              vesselName: ship.name,
              onStatusChanged: (status) {
                if (mounted) {
                  setState(() {
                    _cameraStatuses[ship.id] = status;
                  });
                  // Un enlace rechazado por el reproductor debe invalidarse de inmediato
                  // aunque en teoría todavía no haya alcanzado su fecha de expiración
                  if (status == CameraPlayerStatus.error) {
                    final serial = getShipCameraSerial(ship);
                    EzvizService.shared.invalidateCache(serial);
                  }
                }
              },
              onRetry: () => _reconnectCamera(ship),
            )
          else if (ship.cameras.any((c) => c.isActive))
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.withOpacity(0.05),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Conectando transmisión de a bordo...",
                        style: TypographyTheme.caption(context),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_outlined, color: Colors.grey, size: 32),
                      const SizedBox(height: 6),
                      Text(
                        "Cámara SBS no disponible",
                        style: TypographyTheme.caption(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 16, color: dividerColor),

            // Native Mobile Resources Container (Combustible, Agua, Slop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dividerColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  _buildResourceMetric(
                    context: context,
                    icon: Icons.local_gas_station_rounded,
                    color: const Color(0xFFED8B00), // Orange / Combustible
                    label: "Combustible",
                    value: _getFuelValue(ship),
                    progressPercentage: _getFuelPercentage(ship),
                  ),
                  Container(height: 42, width: 1, margin: const EdgeInsets.symmetric(horizontal: 10), color: dividerColor),
                  _buildResourceMetric(
                    context: context,
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF0057B8), // Blue / Agua
                    label: "Agua",
                    value: _getWaterValue(ship),
                    progressPercentage: _getWaterPercentage(ship),
                  ),
                  Container(height: 42, width: 1, margin: const EdgeInsets.symmetric(horizontal: 10), color: dividerColor),
                  _buildResourceMetric(
                    context: context,
                    icon: Icons.opacity_rounded,
                    color: const Color(0xFF00A86B), // Green/Teal / Slop
                    label: "Slop",
                    value: _getSlopValue(ship),
                    progressPercentage: _getSlopPercentage(ship),
                  ),
                ],
              ),
            ),
            
            // Programa de Carga Card (Invertido: ahora posicionado debajo de los recursos)
            if (ship.targetShips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 15,
                          color: shipAccentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Programa de Carga:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ship.targetShips.map((target) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: shipAccentColor.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_boat,
                                size: 13,
                                color: shipAccentColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                target.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: textColor,
                                ),
                              ),
                              if (target.flag.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  target.flag,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    
                    // Intranet Cargo Progress Bar
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "VLSFO: ${ship.resolvedProvistosTotal.toStringAsFixed(0)} m³ (100%)",
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0057B8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0057B8).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Buques Provistos: ${ship.resolvedProvistosCount}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0057B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 1.0,
                              minHeight: 7,
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0057B8)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total: ${ship.resolvedProvistosTotal.toStringAsFixed(2)} m³",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
                                ),
                              ),
                              Text(
                                "LSFO: ${ship.resolvedProvistosTotal.toStringAsFixed(2)} m³",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),

            // Solid Blue "Ver Tripulación" Button matching user design
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0057B8), // Brand Blue
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrewListView(shipId: ship.id, shipName: ship.name),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    SizedBox(width: 22),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            "Ver Tripulación",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }

  Widget _buildResourceMetric({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required double progressPercentage,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final int pctInt = (progressPercentage * 100).round();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "$pctInt%",
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              width: double.infinity,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressPercentage.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


