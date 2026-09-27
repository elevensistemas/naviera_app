import 'package:flutter/material.dart';
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

        alfa = alfa.copyWith(name: "ALFA C", flag: "Panamá 🇵🇦");
        gustavo = gustavo.copyWith(name: "GUSTAVO U");
        nany = nany.copyWith(name: "NANY");

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
    } catch (e) {
      setState(() {
        _ships.clear();
        _ships.addAll(_getDefaultShipsList());
        _selectedShipIndex = 0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Ship> _getDefaultShipsList() {
    return [
      Ship(
        id: "4",
        name: "ALFA C",
        status: ShipStatus.active,
        totalCargo: 312.5,
        totalCarbon: 312.5,
        totalWater: 85.0,
        totalSlop: 12.0,
        imoNumber: "9123456",
        flag: "Panamá 🇵🇦",
        latitude: -42.76,
        longitude: -65.03,
      ),
      Ship(
        id: "6",
        name: "GUSTAVO U",
        status: ShipStatus.maintenance,
        totalCargo: 180.0,
        totalCarbon: 180.0,
        totalWater: 65.0,
        totalSlop: 8.5,
        imoNumber: "9654321",
        flag: "Argentina 🇦🇷",
        latitude: -38.00,
        longitude: -57.55,
      ),
      Ship(
        id: "5",
        name: "NANY",
        status: ShipStatus.docked,
        totalCargo: 215.0,
        totalCarbon: 215.0,
        totalWater: 75.0,
        totalSlop: 15.0,
        imoNumber: "9018115",
        flag: "Argentina 🇦🇷",
        latitude: -54.80,
        longitude: -68.30,
      ),
    ];
  }

  String _getCargoProgramInfo(Ship ship) {
    final upper = ship.name.toUpperCase();
    if (upper.contains('ALFA')) {
      return "Raizen (15.75 k t)";
    } else if (upper.contains('NANY')) {
      return "WFS (12.83 k t)";
    } else if (upper.contains('GUSTAVO')) {
      return "WFS (14.89 k t)";
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
    final maxCap = ship.name.toUpperCase().contains('ALFA')
        ? 350.0
        : (ship.name.toUpperCase().contains('NANY') ? 250.0 : 300.0);
    return (val / maxCap).clamp(0.0, 1.0);
  }

  double _getWaterPercentage(Ship ship) {
    final val = ship.totalWater;
    if (val <= 0) return 0.0;
    const maxCap = 100.0;
    return (val / maxCap).clamp(0.0, 1.0);
  }

  double _getSlopPercentage(Ship ship) {
    final val = ship.totalSlop;
    if (val <= 0) return 0.0;
    const maxCap = 40.0;
    return (val / maxCap).clamp(0.0, 1.0);
  }

  String _getFuelValue(Ship ship) {
    final val = ship.totalCarbon > 0 ? ship.totalCarbon : ship.totalCargo;
    if (val <= 0) return "0.0 t";
    return "${val.toStringAsFixed(1)} t";
  }

  String _getWaterValue(Ship ship) {
    final val = ship.totalWater;
    if (val <= 0) return "0.0 m³";
    return "${val.toStringAsFixed(1)} m³";
  }

  String _getSlopValue(Ship ship) {
    final val = ship.totalSlop;
    if (val <= 0) return "0.0 m³";
    return "${val.toStringAsFixed(1)} m³";
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
          
          // Ship Selection Tabs (Cápsulas compactas adaptables para que NANY no se corte en móviles)
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

                  if (isSelected) {
                    chipBgColor = shipColor;
                    chipTextColor = Colors.white;
                    chipIconColor = Colors.white;
                  } else {
                    chipBgColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                    chipTextColor = isDark ? Colors.white70 : const Color(0xFF0F172A);
                    chipIconColor = isDark ? Colors.white70 : const Color(0xFF0F172A);
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
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_boat,
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
                                      fontSize: isMobile ? 12 : 13.5,
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
    final dividerColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F5F9);
    final shipAccentColor = _getShipThemeColor(ship.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ship Name and Status
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusCol.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusCol.withOpacity(0.3), width: 0.8),
                  ),
                  child: Text(
                    ship.status.rawValue,
                    style: TextStyle(
                      color: statusCol,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vessel Information: IMO, Flag & Cargo Program
            Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 14, color: secondaryTextColor),
                    const SizedBox(width: 4),
                    Text(
                      "IMO: ${ship.imoNumber}",
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
            
            // Video Player or Fallback for SBS camera (Invertido: ahora posicionado donde estaba el Programa de Carga)
            const SizedBox(height: 12),
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

            // Resources Container with Progress Bars (combustible, agua, slop) matching user design
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dividerColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
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
                    color: const Color(0xFFED8B00), // Orange
                    label: "Combustible",
                    value: _getFuelValue(ship),
                    progressPercentage: _getFuelPercentage(ship),
                  ),
                  Container(height: 36, width: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: dividerColor),
                  _buildResourceMetric(
                    context: context,
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF0057B8), // Blue
                    label: "Agua",
                    value: _getWaterValue(ship),
                    progressPercentage: _getWaterPercentage(ship),
                  ),
                  Container(height: 36, width: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: dividerColor),
                  _buildResourceMetric(
                    context: context,
                    icon: Icons.opacity_rounded,
                    color: const Color(0xFF00A86B), // Green/Teal
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
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Row(
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
                    Positioned(
                      right: 0,
                      child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                    ),
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

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Label
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Progress Bar Pill
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
