import 'package:flutter/material.dart';
import 'dart:math' as math;
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

class _FleetViewState extends State<FleetView> {
  final List<Ship> _ships = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedShipIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadShips();
  }

  Future<void> _loadShips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
          targetShips: alfa.targetShips.isNotEmpty && !alfa.targetShips.any((t) => t.name.toUpperCase().contains('KOCIE') || t.name.toUpperCase().contains('ARTEM'))
              ? alfa.targetShips
              : Ship.getDefaultTargetShipsFor("ALFA C"),
        );
        gustavo = gustavo.copyWith(
          name: "GUSTAVO U",
          targetShips: gustavo.targetShips.isNotEmpty
              ? gustavo.targetShips
              : Ship.getDefaultTargetShipsFor("GUSTAVO U"),
        );
        nany = nany.copyWith(
          name: "NANY",
          targetShips: nany.targetShips.isNotEmpty
              ? nany.targetShips
              : Ship.getDefaultTargetShipsFor("NANY"),
        );

        sorted.add(alfa);
        if (gustavo.id != alfa.id) sorted.add(gustavo);
        if (nany.id != alfa.id && nany.id != gustavo.id) sorted.add(nany);
      } else {
        sorted.addAll(_getDefaultShipsList());
      }

      setState(() {
        _ships.clear();
        _ships.addAll(sorted);
        if (_selectedShipIndex >= _ships.length) {
          _selectedShipIndex = 0;
        }
      });
      _resolveCameras();
    } catch (e) {
      setState(() {
        _ships.clear();
        _ships.addAll(_getDefaultShipsList());
        _selectedShipIndex = 0;
      });
      _resolveCameras();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveCameras() async {
    final Map<String, String> serialMap = {
      'ALFA': 'BF1765385',
      'GUSTAVO': 'BF1767228',
      'NANY': 'BF1765344',
    };

    for (int i = 0; i < _ships.length; i++) {
      final ship = _ships[i];
      String? serial;
      for (final entry in serialMap.entries) {
        if (ship.name.toUpperCase().contains(entry.key)) {
          serial = entry.value;
          break;
        }
      }
      if (serial != null) {
        try {
          final liveUrl = await EzvizService.shared.getLiveStreamUrl(serial);
          if (liveUrl.isNotEmpty && mounted) {
            setState(() {
              _ships[i] = _ships[i].copyWith(cameraUrl: liveUrl);
            });
          }
        } catch (e) {
          debugPrint("Ezviz live stream resolution for ${ship.name}: $e");
        }
      }
    }
  }

  List<Ship> _getDefaultShipsList() {
    return [
      Ship(
        id: "4",
        name: "ALFA C",
        status: ShipStatus.active,
        totalCargo: 71.34,
        totalCarbon: 71.34,
        totalWater: 83.0,
        totalSlop: 5.20,
        imoNumber: "9711652",
        flag: "Panamá 🇵🇦",
        latitude: -42.76,
        longitude: -65.03,
        cameraUrl: "https://vtmsaopaulo.ezvizlife.com:4443/v3/openlive/BF1765385_1_1.m3u8?expire=1791983362&id=1030225763993604096&t=e7d9b21b67319bcd0f1d5b0014c5aee0c642b9114e21fb715375d4e3638897bf&ev=100&c=fe12620732&u=da1e897bca5549f4996a9d149f367b71",
        cameras: [
          ShipCamera(id: "cam-alfa", name: "BT.ALFAC", serialNumber: "BF1765385", isActive: true),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("ALFA C"),
        captainName: "Marenco Rubén Darío",
        chiefEngineerName: "Sosa Armando",
        lastPort: "BUENOS AIRES",
        weather: "Temp: 15°C • Viento: ESE 13 kn",
        eta: "21/09/2026 a las 08:30",
        provistosCount: 12,
        provistosTotal: 6915.00,
      ),
      Ship(
        id: "6",
        name: "GUSTAVO U",
        status: ShipStatus.maintenance,
        totalCargo: 62.50,
        totalCarbon: 62.50,
        totalWater: 65.0,
        totalSlop: 4.80,
        imoNumber: "9654321",
        flag: "Argentina 🇦🇷",
        latitude: -38.00,
        longitude: -57.55,
        cameraUrl: "https://vtmsaopaulo.ezvizlife.com:4443/v3/openlive/BF1767228_1_1.m3u8?expire=1791983362&id=1030225764011499520&t=c6cc87226530d49291195df67d1b5bbc7fa6210a5b4920541546ddc4c02ee008&ev=100&c=f5f9942f03&u=af7980d447c6451b9871bf77e62365f3",
        cameras: [
          ShipCamera(id: "cam-gustavo", name: "BT.GUSTAVO.U", serialNumber: "BF1767228", isActive: true),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("GUSTAVO U"),
        captainName: "Ramirez Pedro",
        chiefEngineerName: "Agüero Leandro",
        lastPort: "CAMPANA",
        weather: "Temp: 18°C • Viento: SE 10 kn",
        eta: "22/09/2026 a las 14:00",
        provistosCount: 4,
        provistosTotal: 1200.00,
      ),
      Ship(
        id: "5",
        name: "NANY",
        status: ShipStatus.docked,
        totalCargo: 54.80,
        totalCarbon: 54.80,
        totalWater: 52.0,
        totalSlop: 3.40,
        imoNumber: "9018115",
        flag: "Argentina 🇦🇷",
        latitude: -54.80,
        longitude: -68.30,
        cameraUrl: "https://vtmsaopaulo.ezvizlife.com:4443/v3/openlive/BF1765344_1_1.m3u8?expire=1791983362&id=1030225764045402112&t=65f8bd88ff9b15db0755ab8635accb3d8e96985b749553795c13b2a15104dcc5&ev=100&c=ea289a6356&u=06e37856b8214f938f8fd6a8bf5d9a36",
        cameras: [
          ShipCamera(id: "cam-nany", name: "BT.NANY1", serialNumber: "BF1765344", isActive: true),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("NANY"),
        captainName: "Maciel Jonathan",
        chiefEngineerName: "Porto Guillermo",
        lastPort: "DOCK SUD",
        weather: "Temp: 14°C • Viento: S 16 kn",
        eta: "23/09/2026 a las 11:15",
        provistosCount: 3,
        provistosTotal: 800.00,
      ),
    ];
  }

  String _getCargoProgramInfo(Ship ship) {
    final upper = ship.name.toUpperCase();
    if (upper.contains('ALFA')) {
      return "Raizen (6915.00 m³ • 12 buques)";
    } else if (upper.contains('NANY')) {
      return "WFS (4.32 k t • 6 buques)";
    } else if (upper.contains('GUSTAVO')) {
      return "WFS (7.39 k t • 16 buques)";
    }
    return "Raizen";
  }

  Color _statusColor(ShipStatus status) {
    switch (status) {
      case ShipStatus.active: return Colors.green;
      case ShipStatus.maintenance: return Colors.orange;
      case ShipStatus.docked: return ColorTheme.primary;
    }
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
      return (val / 100.48).clamp(0.0, 1.0); // 71.34 m³ -> 71%
    } else if (ship.name.toUpperCase().contains('GUSTAVO')) {
      return (val / 107.76).clamp(0.0, 1.0); // 62.50 m³ -> 58%
    } else {
      return (val / 89.84).clamp(0.0, 1.0); // 54.80 m³ -> 61%
    }
  }

  double _getWaterPercentage(Ship ship) {
    final val = ship.totalWater;
    if (val <= 0) return 0.0;
    if (ship.name.toUpperCase().contains('ALFA')) {
      return (val / 307.4).clamp(0.0, 1.0); // 83.0 m³ -> 27%
    } else if (ship.name.toUpperCase().contains('GUSTAVO')) {
      return (val / 203.1).clamp(0.0, 1.0); // 65.0 m³ -> 32%
    } else {
      return (val / 148.57).clamp(0.0, 1.0); // 52.0 m³ -> 35%
    }
  }

  double _getSlopPercentage(Ship ship) {
    final val = ship.totalSlop;
    if (val <= 0) return 0.0;
    if (ship.name.toUpperCase().contains('ALFA')) {
      return (val / 37.14).clamp(0.0, 1.0); // 5.20 m³ -> 14%
    } else if (ship.name.toUpperCase().contains('GUSTAVO')) {
      return (val / 30.0).clamp(0.0, 1.0); // 4.80 m³ -> 16%
    } else {
      return (val / 28.33).clamp(0.0, 1.0); // 3.40 m³ -> 12%
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

    return Scaffold(
      backgroundColor: bodyBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reusable NcsHeroHeader component
          NcsHeroHeader(
            title: bannerTitle,
            subtitle: bannerSubtitle,
            onTap: () {
              if (_ships.isNotEmpty) {
                setState(() {
                  _selectedShipIndex = (_selectedShipIndex + 1) % _ships.length;
                });
              }
            },
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
                          setState(() {
                            _selectedShipIndex = index;
                          });
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
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            children: [
                              _buildShipCard(context, _ships[_selectedShipIndex], theme),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipCard(BuildContext context, Ship ship, ThemeData theme) {
    final statusCol = _statusColor(ship.status);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9);
    final shipAccentColor = _getShipThemeColor(ship.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ship Name + Status
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusCol.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusCol.withValues(alpha: 0.35), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusCol,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        ship.status == ShipStatus.active
                            ? "En navegación"
                            : ship.status == ShipStatus.maintenance
                                ? "Mantenimiento"
                                : "En muelle",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusCol,
                        ),
                      ),
                    ],
                  ),
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
            
            // Officers & Weather Subrow matching Intranet
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: dividerColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 15, color: Color(0xFF0057B8)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Capitán: ${ship.resolvedCaptain}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.engineering_outlined, size: 15, color: Color(0xFFED8B00)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Jefe Máq.: ${ship.resolvedChiefEngineer}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, size: 14, color: secondaryTextColor),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          ship.resolvedWeather,
                          style: TextStyle(fontSize: 11.5, color: secondaryTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.anchor_outlined, size: 14, color: secondaryTextColor),
                      const SizedBox(width: 5),
                      Text(
                        "Puerto: ${ship.resolvedLastPort}",
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: secondaryTextColor),
                      ),
                    ],
                  ),
                ],
              ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.4)),
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
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Video Player or Fallback for SBS camera
            if (ship.cameraUrl != null && ship.cameraUrl!.isNotEmpty)
              SBSCameraPlayer(
                key: ValueKey(ship.cameraUrl),
                url: ship.cameraUrl!,
              )
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_outlined, color: Colors.grey, size: 30),
                      const SizedBox(height: 6),
                      Text(
                        "Cámara SBS no disponible",
                        style: TypographyTheme.caption(context),
                      ),
                    ],
                  ),
                ),
              ),
            
            Divider(height: 24, color: dividerColor),

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
                          Icons.directions_boat_filled_rounded,
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
                              color: shipAccentColor.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                target.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                target.flag,
                                style: const TextStyle(fontSize: 14),
                              ),
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
                          if (ship.resolvedEta.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded, size: 13, color: secondaryTextColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "ETA: ${ship.resolvedEta}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                      builder: (_) => CrewListView(shipId: ship.id),
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


