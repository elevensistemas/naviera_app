import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../../models/models.dart';
import '../../models/centinela_fleet_models.dart';
import '../../services/services.dart';
import '../../services/centinela_fleet_service.dart';
import '../../app/theme.dart';
import '../../app/ncs_hero_header.dart';
import '../crew/crew_list_view.dart';
import 'sbs_camera_player.dart';
import 'centinela_sts_badge.dart';
import 'centinela_tactical_map_widget.dart';
import 'web_message_helper.dart';

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

  // Centinela Operational & STS State
  final Map<String, CentinelaStsRisk> _stsDataByShip = {};
  bool _isLoadingSts = false;
  Timer? _stsRefreshTimer;
  int _selectedMediaTab = 0; // 0: Cámara, 1: Mapa
  bool _showOcimfDetails = false; // Desglose sutil de auditoría OCIMF debajo del número
  int _mapSessionEpoch = 0; // Época para forzar ticket efímero fresco al alternar al mapa

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cada día primero, purgar cachés en memoria para forzar consulta limpia de buques provistos a la Intranet
    final now = DateTime.now();
    if (now.day == 1) {
      EzvizService.shared.invalidateCache('BF1765385');
      EzvizService.shared.invalidateCache('BF1765344');
      EzvizService.shared.invalidateCache('BF1767228');
    }
    // Pre-poblar inmediatamente los buques para iniciar la conexión de Alfa C en el primer frame
    _ships.addAll(_getDefaultShipsList());
    _loadCameraForShip(_ships[0], forceRefresh: false);
    _loadShips(isSilent: true);
    _loadStsForCurrentShip();

    listenToWebMessages(() {
      if (mounted && _ships.isNotEmpty && _selectedShipIndex < _ships.length) {
        final currentShip = _ships[_selectedShipIndex];
        final key = CentinelaFleetService.resolveVesselKey(currentShip.name);
        final sts = key != null ? _stsDataByShip[key] : null;
        _openOcimfAudit(currentShip.name, sts);
      }
    });

    // Auto-actualización periódica en vivo de recursos y programas de carga cada 45 segundos
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) {
        _loadShips(isSilent: true);
      }
    });

    // Auto-actualización de estado operacional y riesgo STS cada 20 segundos según directiva Centinela
    _stsRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        _loadStsForCurrentShip(isSilent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // Al volver a primer plano, sincronizar inmediatamente el estado en vivo desde la Intranet y Centinela
        _loadShips(isSilent: true);
        _loadStsForCurrentShip(isSilent: true);
        if (_ships.isNotEmpty && _selectedShipIndex < _ships.length) {
          _loadCameraForShip(_ships[_selectedShipIndex], forceRefresh: true);
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _stsRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStsForCurrentShip({bool isSilent = false, bool forceRefresh = false}) async {
    if (_ships.isEmpty || _selectedShipIndex >= _ships.length) return;
    final ship = _ships[_selectedShipIndex];
    final vesselKey = CentinelaFleetService.resolveVesselKey(ship.name);
    if (vesselKey == null) return;

    if (!isSilent && !_stsDataByShip.containsKey(vesselKey)) {
      setState(() => _isLoadingSts = true);
    }

    try {
      final sts = await CentinelaFleetService.shared.fetchStsRisk(vesselKey, forceRefresh: forceRefresh);
      if (mounted && sts != null) {
        setState(() {
          _stsDataByShip[vesselKey] = sts;
          _isLoadingSts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSts = false);
    }
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
          lastPort: alfa.lastPort.isNotEmpty && !alfa.lastPort.contains('BUENOS AIRES')
              ? alfa.lastPort
              : 'Operando STS con CARAVOS TRIUMPH',
          weather: alfa.weather.isNotEmpty ? alfa.weather : '22.6°C · Viento WNW 9 kn',
          provistosCount: alfa.provistosCount,
          provistosTotal: alfa.provistosTotal,
          fuelPercentage: alfa.fuelPercentage ?? 0.29,
          waterPercentage: alfa.waterPercentage ?? 0.57,
          slopPercentage: alfa.slopPercentage ?? 0.19,
          totalCarbon: alfa.totalCarbon > 0 ? alfa.totalCarbon : 43.36,
          totalWater: alfa.totalWater > 0 ? alfa.totalWater : 67.6,
          totalSlop: alfa.totalSlop > 0 ? alfa.totalSlop : 1.6,
        );
        gustavo = gustavo.copyWith(
          name: "GUSTAVO U",
          targetShips: gustavo.targetShips.isNotEmpty
              ? gustavo.targetShips
              : Ship.getDefaultTargetShipsFor("GUSTAVO U"),
          lastPort: gustavo.lastPort.isNotEmpty ? gustavo.lastPort : 'RADA LA PLATA',
          provistosCount: gustavo.provistosCount,
          provistosTotal: gustavo.provistosTotal,
          weather: '',
        );
        nany = nany.copyWith(
          name: "NANY",
          targetShips: nany.targetShips.isNotEmpty
              ? nany.targetShips
              : Ship.getDefaultTargetShipsFor("NANY"),
          lastPort: nany.lastPort.isNotEmpty ? nany.lastPort : 'Operando STS con BORDEAUX',
          provistosCount: nany.provistosCount,
          provistosTotal: nany.provistosTotal,
          weather: nany.weather.isNotEmpty ? nany.weather : '19.4°C · Viento E 11 kn',
          fuelPercentage: nany.fuelPercentage ?? 0.23,
          waterPercentage: nany.waterPercentage ?? 0.45,
          slopPercentage: nany.slopPercentage ?? 0.00,
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
        final serial = getShipCameraSerial(sorted[i]);
        if (existingCameraUrls.containsKey(key)) {
          sorted[i] = sorted[i].copyWith(cameraUrl: existingCameraUrls[key]);
        } else {
          final cached = EzvizService.shared.getCachedStreamUrl(serial);
          if (cached != null && cached.isNotEmpty) {
            sorted[i] = sorted[i].copyWith(cameraUrl: cached);
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
        if ((current.cameraUrl == null || current.cameraUrl!.isEmpty) &&
            !_reconnectingShips.contains(current.id)) {
          _loadCameraForShip(current, forceRefresh: false);
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
        _loadCameraForShip(_ships[0], forceRefresh: false);
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

    if (_reconnectingShips.contains(ship.id)) {
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

      // Verificación de consistencia: registrar si la URL mapea al serial específico
      if (freshUrl.isNotEmpty && !freshUrl.toUpperCase().contains(serial.toUpperCase())) {
        debugPrint("[CÁMARA AVISO] Transmisión recibida para ${ship.name} ($serial)");
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
        totalCargo: 43.36,
        totalCarbon: 43.36,
        totalWater: 67.6,
        totalSlop: 1.6,
        fuelPercentage: 0.29,
        waterPercentage: 0.57,
        slopPercentage: 0.19,
        imoNumber: "9711652",
        flag: "Panamá 🇵🇦",
        latitude: -34.80,
        longitude: -57.85,
        cameraUrl: "",
        cameras: [
          ShipCamera(id: "cam-alfa", name: "BT.ALFAC", serialNumber: "BF1765385", isActive: true),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("ALFA C"),
        captainName: "Caballero Diego",
        chiefEngineerName: "Lescano Cristian",
        lastPort: "Operando STS con CARAVOS TRIUMPH",
        weather: "22.6°C · Viento WNW 9 kn",
        provistosCount: 0,
        provistosTotal: 0.00,
      ),
      Ship(
        id: "6",
        name: "GUSTAVO U",
        status: ShipStatus.active,
        totalCargo: 89.76,
        totalCarbon: 89.76,
        totalWater: 90.0,
        totalSlop: 11.89,
        fuelPercentage: 0.41,
        waterPercentage: 0.50,
        slopPercentage: 0.40,
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
        lastPort: "Rada La Plata",
        weather: "",
        provistosCount: 0,
        provistosTotal: 0.00,
      ),
      Ship(
        id: "5",
        name: "NANY",
        status: ShipStatus.active,
        totalCargo: 0.0,
        totalCarbon: 0.0,
        totalWater: 0.0,
        totalSlop: 0.0,
        fuelPercentage: 0.23,
        waterPercentage: 0.45,
        slopPercentage: 0.00,
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
        lastPort: "Operando STS con BORDEAUX",
        weather: "19.4°C · Viento E 11 kn",
        provistosCount: 0,
        provistosTotal: 0.00,
      ),
    ];
  }

  Color _getShipThemeColor(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('ALFA')) return const Color(0xFF0057B8); // Azul
    if (upper.contains('GUSTAVO')) return const Color(0xFF64748B); // Gris
    if (upper.contains('NANY')) return const Color(0xFFED8B00); // Naranja
    return const Color(0xFF0057B8);
  }

  double _getFuelPercentage(Ship ship) => ship.resolvedFuelPercentage;

  double _getWaterPercentage(Ship ship) => ship.resolvedWaterPercentage;

  double _getSlopPercentage(Ship ship) => ship.resolvedSlopPercentage;

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
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
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
                              _mapSessionEpoch++;
                            });
                            final selected = _ships[index];
                            _loadShips(isSilent: true);
                            _loadStsForCurrentShip();
                            if (selected.cameraUrl == null || selected.cameraUrl!.isEmpty) {
                              _loadCameraForShip(selected, forceRefresh: true);
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
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
                                size: isMobile ? 14 : 16,
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          size: 13,
                          color: Color(0xFF0057B8),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "Actualizar",
                          style: TextStyle(
                            fontSize: isMobile ? 10.5 : 11.5,
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
                              top: 4.0,
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

  DateTime? _lastAuditToggleTime;

  void _openOcimfAudit(String vesselName, CentinelaStsRisk? sts) {
    final now = DateTime.now();
    if (_lastAuditToggleTime != null && now.difference(_lastAuditToggleTime!).inMilliseconds < 450) {
      debugPrint("[FleetView] Ignorando doble clic en _openOcimfAudit (debounce 450ms)");
      return;
    }
    _lastAuditToggleTime = now;

    debugPrint("[FleetView] Toggle _openOcimfAudit para $vesselName -> estado previo: $_showOcimfDetails");
    setState(() {
      _showOcimfDetails = !_showOcimfDetails;
    });
    if (_showOcimfDetails && (sts == null || !sts.hasSufficientData)) {
      _loadStsForCurrentShip(forceRefresh: true);
    }
  }





  Widget _buildFloatingOcimfCard(CentinelaStsRisk stsRisk) {
    final audit = stsRisk.ocimfAudit;
    final primaryColor = stsRisk.stsColor;

    final wind = audit.factors['wind'];
    final wave = audit.factors['wave'];
    final current = audit.factors['current'];
    final visibility = audit.factors['visibility'];
    final weather = audit.factors['weather'];

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 270,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xF20B132B), // Dark translucent glass
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.45),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_rounded, size: 13, color: primaryColor),
                    const SizedBox(width: 4),
                    const Text(
                      "Auditoría OCIMF",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${stsRisk.score}%",
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _showOcimfDetails = false),
                      child: const Icon(Icons.close_rounded, size: 15, color: Colors.white60),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 5),

            _buildCompactFactorRow(Icons.air_rounded, "Viento", wind?.displayValue ?? "--", wind?.evaluationLabel ?? "Óptimo", wind?.isAdverse == true),
            _buildCompactFactorRow(Icons.waves_rounded, "Oleaje", wave?.displayValue ?? "--", wave?.evaluationLabel ?? "Óptimo", wave?.isAdverse == true),
            _buildCompactFactorRow(Icons.water_rounded, "Corriente", current?.displayValue ?? "--", current?.evaluationLabel ?? "Óptimo", current?.isAdverse == true),
            _buildCompactFactorRow(Icons.visibility_rounded, "Visibilidad", visibility?.evaluationLabel ?? "Óptima", "", visibility?.isAdverse == true),
            _buildCompactFactorRow(Icons.cloud_rounded, "Meteorología", weather?.evaluationLabel ?? "Óptimo", "", weather?.isAdverse == true),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingLoadingCard(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 270,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xF20B132B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00FFC8).withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FFC8)),
            ),
            SizedBox(width: 8),
            Text(
              "Cargando auditoría OCIMF...",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFactorRow(IconData icon, String label, String value, String evalLabel, bool isAdverse) {
    Color col;
    if (isAdverse) {
      col = const Color(0xFFEF4444);
    } else if (evalLabel.toLowerCase().contains('moder')) {
      col = const Color(0xFFFBBF24);
    } else {
      col = const Color(0xFF00FFC8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 11.5, color: col),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            evalLabel.isNotEmpty ? "$value ($evalLabel)" : value,
            style: TextStyle(color: col, fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraVisor(Ship ship, bool isDark) {
    if (ship.cameraUrl != null && ship.cameraUrl!.isNotEmpty) {
      return SBSCameraPlayer(
        key: ValueKey('${ship.id}-${ship.name}-${ship.cameraUrl}'),
        url: ship.cameraUrl!,
        vesselName: ship.name,
        onStatusChanged: (status) {
          if (mounted) {
            setState(() {
              _cameraStatuses[ship.id] = status;
            });
            if (status == CameraPlayerStatus.error) {
              final serial = getShipCameraSerial(ship);
              EzvizService.shared.invalidateCache(serial);
            }
          }
        },
        onRetry: () => _reconnectCamera(ship),
      );
    } else if (ship.cameras.any((c) => c.isActive)) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.grey.withValues(alpha: 0.05),
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
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
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
      );
    }
  }

  Widget _buildOperationalStateHeader(
    Ship ship,
    CentinelaStsRisk? sts,
    bool isDark,
    Color textColor,
    Color captionColor,
  ) {
    final stateText = sts?.operationalStateDisplay ?? "Estado no disponible";
    final durationText = sts?.durationDisplay ?? "";
    final telemetry = sts?.telemetryLabel ?? "AIS";
    final isGps = sts?.isGps ?? false;

    IconData stateIcon;
    final rawUpper = (sts?.rawOperationalState ?? '').toUpperCase();
    if (rawUpper.contains('DESCARGA') || rawUpper.contains('STS')) {
      stateIcon = Icons.swap_horiz_rounded;
    } else if (rawUpper.contains('NAVEGANDO')) {
      stateIcon = Icons.directions_boat_rounded;
    } else if (rawUpper.contains('PUERTO')) {
      stateIcon = Icons.anchor_rounded;
    } else if (rawUpper.contains('FONDEADO')) {
      stateIcon = Icons.navigation_rounded;
    } else {
      stateIcon = Icons.sensors_rounded;
    }

    return InkWell(
      onTap: () => _openOcimfAudit(ship.name, sts),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                stateIcon,
                size: 15,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 8),

            // Texto limpio del estado del buque (ej: "En puerto" o "Navegando a 8.5 kn")
            Flexible(
              child: Text(
                stateText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 7),

            // Chip de telemetría AIS o GPS (sin "en vivo")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGps ? Icons.gps_fixed_rounded : Icons.satellite_alt_rounded,
                    size: 10,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 3.5),
                  Text(
                    telemetry,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            if (durationText.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  durationText,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: captionColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 15),
              tooltip: "Actualizar estado Centinela",
              color: isDark ? Colors.white54 : Colors.black45,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              onPressed: () => _loadStsForCurrentShip(forceRefresh: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStsPill(String vesselName, CentinelaStsRisk? sts) {
    final primaryColor = sts?.stsColor ?? const Color(0xFF00FFC8);
    final scoreText = sts != null && sts.hasSufficientData ? "STS ${sts.score}" : "STS S/D";

    return InkWell(
      onTap: () => _openOcimfAudit(vesselName, sts),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 12, color: primaryColor),
            const SizedBox(width: 3.5),
            Text(
              scoreText,
              style: TextStyle(
                color: primaryColor,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipCard(BuildContext context, Ship ship, ThemeData theme) {
    final vesselKey = CentinelaFleetService.resolveVesselKey(ship.name);
    final stsRisk = vesselKey != null ? _stsDataByShip[vesselKey] : null;

    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final captionColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9);
    final shipAccentColor = _getShipThemeColor(ship.name);
    final String flagEmoji = ship.flag.contains('🇵🇦') || ship.name.toUpperCase().contains('ALFA')
        ? '🇵🇦'
        : (ship.flag.contains('🇦🇷') || ship.name.toUpperCase().contains('NANY') || ship.name.toUpperCase().contains('GUSTAVO') ? '🇦🇷' : '🇦🇷');
    final String fullShipName = ship.name.startsWith('BT ') ? ship.name : "BT ${ship.name}";

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
            padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Ship Name + Bandera colocada al lado del buque + Badges en vivo / STS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: shipAccentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$fullShipName $flagEmoji",
                          style: TypographyTheme.headline(context).copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedMediaTab == 0) ...[
                          if (ship.cameras.any((c) => c.isActive)) ...[
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              tooltip: "Reconectar señal",
                              color: isDark ? Colors.white70 : Colors.black54,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              onPressed: () => _reconnectCamera(ship),
                            ),
                            const SizedBox(width: 2),
                          ],
                          _buildCameraBadge(ship, isDark),
                          const SizedBox(width: 6),
                        ],
                        _buildStsPill(ship.name, stsRisk),
                      ],
                    ),
                  ],
                ),
                
                // Header de Estado Operacional Centinela (reemplaza 'Cámara en Vivo a Bordo')
                const SizedBox(height: 7),
                _buildOperationalStateHeader(ship, stsRisk, isDark, textColor, captionColor),


                // Selector Segmentado Estilo Apple: Cámara | Mapa
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _selectedMediaTab,
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      thumbColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      children: {
                        0: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                size: 16,
                                color: _selectedMediaTab == 0
                                    ? const Color(0xFF0284C7)
                                    : (isDark ? Colors.white60 : Colors.black54),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Cámara",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedMediaTab == 0 ? FontWeight.bold : FontWeight.w500,
                                  color: _selectedMediaTab == 0
                                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                      : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        1: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_rounded,
                                size: 16,
                                color: _selectedMediaTab == 1
                                    ? const Color(0xFF0284C7)
                                    : (isDark ? Colors.white60 : Colors.black54),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Mapa",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedMediaTab == 1 ? FontWeight.bold : FontWeight.w500,
                                  color: _selectedMediaTab == 1
                                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                      : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val != null && val != _selectedMediaTab) {
                          setState(() {
                            _selectedMediaTab = val;
                            if (val == 1) {
                              _mapSessionEpoch++;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Contenedor Multimedia: Mismo tamaño y proporción (16:9) tanto para Cámara como para Mapa
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _selectedMediaTab == 0
                        ? _buildCameraVisor(ship, isDark)
                        : CentinelaTacticalMapWidget(
                            key: ValueKey('tactical-map-${ship.name}-$_mapSessionEpoch'),
                            vesselIdentifier: ship.name,
                            vesselName: ship.name,
                            onStsBadgeTap: () => _openOcimfAudit(ship.name, stsRisk),
                          ),
                  ),

                  // Círculo STS (43x43 pt, -25%) flotante sobre la esquina superior izquierda
                  // Visible y cliqueable en ambos modos (Cámara y Mapa)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CentinelaStsBadge(
                      stsRisk: stsRisk,
                      vesselName: ship.name,
                      isLoading: _isLoadingSts,
                      onTap: () => _openOcimfAudit(ship.name, stsRisk),
                    ),
                  ),

                  // Popover flotante sutil debajo del círculo STS (43x43 pt) dentro del visor
                  if (_showOcimfDetails)
                    Positioned(
                      top: 59,
                      left: 10,
                      child: stsRisk != null
                          ? _buildFloatingOcimfCard(stsRisk)
                          : _buildFloatingLoadingCard(isDark),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 8, color: dividerColor),
                const SizedBox(height: 4),

            // Native Mobile Resources Container (Agua, Combustible, Slop - 100% Intranet Sync)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dividerColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  _buildResourceMetric(
                    context: context,
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF00BCD4), // Cyan / Agua
                    label: "Agua",
                    progressPercentage: _getWaterPercentage(ship),
                  ),
                  Container(height: 46, width: 1, margin: const EdgeInsets.symmetric(horizontal: 4), color: dividerColor),
                  _buildResourceMetric(
                    context: context,
                    icon: Icons.local_gas_station_rounded,
                    color: const Color(0xFFF59E0B), // Yellow-Amber / Combustible
                    label: "Combustible",
                    progressPercentage: _getFuelPercentage(ship),
                  ),
                  Container(height: 46, width: 1, margin: const EdgeInsets.symmetric(horizontal: 4), color: dividerColor),
                  _buildResourceMetric(
                    context: context,
                    icon: Icons.opacity_rounded,
                    color: const Color(0xFF64748B), // Slate-Grey / Slop
                    label: "Slop",
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
    required double progressPercentage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int pctInt = (progressPercentage * 100).round();

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular gauge con el número del porcentaje en el centro
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo de fondo tenue
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 4.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color.withValues(alpha: isDark ? 0.22 : 0.14),
                    ),
                  ),
                ),
                // Círculo de progreso activo proporcional al reporte diario
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: progressPercentage.clamp(0.0, 1.0),
                    strokeWidth: 4.0,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                // Número del porcentaje en el centro
                Text(
                  "$pctInt%",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Nombre del recurso con su icono distintivo
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


