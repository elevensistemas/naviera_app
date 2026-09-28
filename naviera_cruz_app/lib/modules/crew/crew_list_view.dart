import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/ncs_hero_header.dart';

class CrewListView extends StatefulWidget {
  final String? shipId;
  const CrewListView({super.key, this.shipId});

  @override
  State<CrewListView> createState() => _CrewListViewState();
}

class _CrewListViewState extends State<CrewListView> {
  final List<CrewMember> _crewMembers = [];
  final List<Ship> _ships = [];
  String? _selectedShipId;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedShipId = widget.shipId;
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      final fleetService = FleetService();
      
      // Load ships for filters
      final ships = await fleetService.fetchShips();
      setState(() {
        _ships.clear();
        if (ships.isNotEmpty) {
          _ships.addAll(ships);
        } else {
          // Fallback mock ships matching design if empty
          _ships.addAll([
            Ship(id: "s1", name: "ALFA C", status: ShipStatus.active, totalCargo: 1500, latitude: -42.76, longitude: -65.03),
            Ship(id: "s2", name: "GUSTAVO U", status: ShipStatus.active, totalCargo: 1200, latitude: -38.00, longitude: -57.55),
            Ship(id: "s3", name: "NANY", status: ShipStatus.docked, totalCargo: 800, latitude: -54.80, longitude: -68.30),
          ]);
        }
        
        if (_selectedShipId == null && _ships.isNotEmpty) {
          _selectedShipId = _ships.first.id;
        }
      });

      await _loadCrew();
    } catch (_) {
      _loadFallbackCrew();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadCrew() async {
    if (_selectedShipId == null && _ships.isNotEmpty) {
      _selectedShipId = _ships.first.id;
    }
    
    setState(() => _isLoading = true);
    try {
      final fleetService = FleetService();
      final crew = await fleetService.fetchCrew(_selectedShipId ?? 's1');
      
      final seenIds = <String>{};
      final uniqueCrew = <CrewMember>[];
      for (var member in crew) {
        if (member.id.isNotEmpty && !seenIds.contains(member.id)) {
          seenIds.add(member.id);
          uniqueCrew.add(member);
        }
      }

      if (uniqueCrew.isEmpty) {
        _loadFallbackCrew();
      } else {
        setState(() {
          _crewMembers.clear();
          _crewMembers.addAll(uniqueCrew);
        });
      }
    } catch (_) {
      _loadFallbackCrew();
    }
    setState(() => _isLoading = false);
  }

  void _loadFallbackCrew() {
    final shipId = _selectedShipId ?? 's1';
    setState(() {
      _crewMembers.clear();
      _crewMembers.addAll([
        CrewMember(id: "c1", shipId: shipId, name: "Carrá Leonel", role: "Capitán", dni: "28.123.456", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 20, orderIndex: 1),
        CrewMember(id: "c2", shipId: shipId, name: "Caballero Diego", role: "1er Oficial Cubierta", dni: "31.987.654", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 20, orderIndex: 2),
        CrewMember(id: "c3", shipId: shipId, name: "Caratolli Pablo", role: "2do Oficial Cubierta", dni: "28.654.321", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 19, orderIndex: 3),
        CrewMember(id: "c4", shipId: shipId, name: "Escalante Jorge", role: "3er Oficial Cubierta", dni: "27.321.098", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 20, orderIndex: 4),
        CrewMember(id: "c5", shipId: shipId, name: "Sosa Armando", role: "Jefe de Maquinas", dni: "24.567.890", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 2, orderIndex: 5),
        CrewMember(id: "c6", shipId: shipId, name: "Medina Cesar", role: "1er Conductor", dni: "33.444.555", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 20, orderIndex: 6),
        CrewMember(id: "c7", shipId: shipId, name: "Ledesma Gabriel", role: "2do Oficial Maquinas", dni: "29.111.222", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 20, orderIndex: 7),
        CrewMember(id: "c8", shipId: shipId, name: "Pereyra Matías", role: "3er Oficial Maquinas", dni: "32.777.333", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 18, orderIndex: 8),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final captionColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final bodyBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? Colors.white24 : const Color(0xFFE2E8F0);

    // Filter crew list by search query
    final filteredCrew = _crewMembers.where((member) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final nameMatch = member.name.toLowerCase().contains(query);
      final roleMatch = member.role.toLowerCase().contains(query);
      final dniMatch = member.dni != null && member.dni!.toLowerCase().contains(query);
      return nameMatch || roleMatch || dniMatch;
    }).toList();

    final onBoardCount = filteredCrew.where((m) => m.isOnBoard).length;

    return Scaffold(
      backgroundColor: bodyBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Reusable Header with ALFA C ship image
                const NcsHeroHeader(
                  title: "Tripulación",
                  subtitle: "Gestión de nuestra tripulación.",
                ),

                // Main Content Card Container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Ship Chips & Search Box
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildShipFilters(isDark)),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 360,
                              child: _buildSearchBar(inputBg, inputBorder, isDark),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShipFilters(isDark),
                            const SizedBox(height: 14),
                            _buildSearchBar(inputBg, inputBorder, isDark),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Subheader Row: A BORDO badge + Dotación mínima completa check
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "A BORDO",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: ColorTheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: ColorTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "$onBoardCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Dotación mínima completa",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ColorTheme.accent,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Botón para volver atrás a la pantalla de Flota (Flecha colocada abajo de A BORDO)
                      if (Navigator.canPop(context)) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_rounded,
                                  size: 18,
                                  color: textColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Volver a Flota",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Crew Members List (Cards on Mobile, Table or Cards on Web)
                      if (_isLoading && _crewMembers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (filteredCrew.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? "No se encontraron tripulantes que coincidan con '$_searchQuery'."
                                  : "No hay tripulación registrada.",
                              style: TextStyle(color: captionColor, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredCrew.length,
                          itemBuilder: (context, index) {
                            final member = filteredCrew[index];
                            return _buildCrewCard(member, isDark, textColor, captionColor);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShipFilters(bool isDark) {
    final shipsList = _ships.isNotEmpty
        ? _ships
        : [
            Ship(id: "s1", name: "ALFA C", status: ShipStatus.active, totalCargo: 0, latitude: 0, longitude: 0),
            Ship(id: "s2", name: "GUSTAVO U", status: ShipStatus.active, totalCargo: 0, latitude: 0, longitude: 0),
            Ship(id: "s3", name: "NANY", status: ShipStatus.active, totalCargo: 0, latitude: 0, longitude: 0),
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: shipsList.map((ship) {
          final isSelected = _selectedShipId == ship.id ||
              (_selectedShipId == null && ship == shipsList.first);

          final nameUpper = ship.name.toUpperCase();
          Color chipBg;
          if (nameUpper.contains("ALFA")) {
            chipBg = ColorTheme.primary; // Azul
          } else if (nameUpper.contains("NANY")) {
            chipBg = ColorTheme.accent; // Naranja
          } else if (nameUpper.contains("GUSTAVO")) {
            chipBg = isDark ? Colors.grey.shade700 : const Color(0xFF94A3B8); // Gris
          } else {
            chipBg = isSelected ? ColorTheme.primary : (isDark ? Colors.grey.shade700 : const Color(0xFF94A3B8));
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedShipId = ship.id;
                });
                _loadCrew();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(22),
                  border: isSelected
                      ? Border.all(color: Colors.white.withOpacity(0.9), width: 2)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: chipBg.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  ship.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(Color inputBg, Color inputBorder, bool isDark) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inputBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          hintText: "Buscar tripulante por nombre, cargo o DNI...",
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCrewCard(CrewMember member, bool isDark, Color textColor, Color captionColor) {
    final days = member.daysOnBoard ?? member.calculatedDays;
    final itemBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final itemBorder = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: itemBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Role-specific Avatar Badge matching user design
          (member.photoUrl != null && member.photoUrl!.isNotEmpty)
              ? Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: ColorTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      member.photoUrl!,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _CrewRoleAvatarWidget(role: member.role),
                    ),
                  ),
                )
              : _CrewRoleAvatarWidget(role: member.role),
          const SizedBox(width: 14),

          // Middle Column: Name, Cargo, Embarcado Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.role,
                  style: TextStyle(
                    fontSize: 13,
                    color: captionColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.green.withOpacity(0.15) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.green.withOpacity(0.4) : const Color(0xFFA5D6A7),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    member.situation.isNotEmpty ? member.situation : "Embarcado",
                    style: TextStyle(
                      color: isDark ? Colors.greenAccent : const Color(0xFF2E7D32),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right Column: Days Label + Count Circle + Menu Dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Días",
                    style: TextStyle(
                      fontSize: 11,
                      color: captionColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? ColorTheme.primary.withOpacity(0.2) : const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "$days",
                      style: TextStyle(
                        color: isDark ? Colors.lightBlueAccent : const Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrewRoleAvatarWidget extends StatelessWidget {
  final String role;
  final double size;

  const _CrewRoleAvatarWidget({
    required this.role,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final r = role.toLowerCase().trim();

    // 1. Capitán / Captain / Patrón
    if (r.contains('capit') || r.contains('patron')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF0F2240), // Dark Navy
          shape: BoxShape.circle,
        ),
        child: CustomPaint(
          size: Size(size, size),
          painter: _CaptainHatPainter(),
        ),
      );
    }

    // 2. Deck Officer / Cubierta / Contramaestre / Marinero / Cocinero / Mozo / Marmitón
    if (r.contains('cubierta') ||
        r.contains('marinero') ||
        r.contains('contramaestre') ||
        r.contains('cocin') ||
        r.contains('mozo') ||
        r.contains('marmit') ||
        r.contains('servicio') ||
        r.contains('camarer')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF0057B8), // Bright Blue
          shape: BoxShape.circle,
        ),
        child: CustomPaint(
          size: Size(size, size),
          painter: _DeckHelmetPainter(),
        ),
      );
    }

    // 3. Engine / Máquinas / Conductor / Electricista / Engrasador
    if (r.contains('maquina') ||
        r.contains('máquina') ||
        r.contains('conductor') ||
        r.contains('electricista') ||
        r.contains('engrasador') ||
        r.contains('motor')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF0B192C), // Dark Navy Engine
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.engineering_rounded, // Engineer icon for engine crew
          color: Colors.white,
          size: 26,
        ),
      );
    }

    // 5. Default Maritime Avatar
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF0057B8),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.directions_boat_filled_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _CaptainHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // White cap crown
    final capTopPaint = Paint()..color = Colors.white;
    final capTopPath = Path()
      ..moveTo(cx - 13, cy - 1)
      ..cubicTo(cx - 15, cy - 13, cx + 15, cy - 13, cx + 13, cy - 1)
      ..close();
    canvas.drawPath(capTopPath, capTopPaint);

    // Gold band
    final goldBandPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawRect(Rect.fromLTWH(cx - 13, cy - 1, 26, 4), goldBandPaint);

    // Gold anchor badge emblem
    final badgePaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawCircle(Offset(cx, cy - 5), 3.5, badgePaint);

    // Dark visor / brim
    final visorPaint = Paint()..color = const Color(0xFF0F172A);
    final visorPath = Path()
      ..moveTo(cx - 15, cy + 3)
      ..quadraticBezierTo(cx, cy + 9, cx + 15, cy + 3)
      ..quadraticBezierTo(cx, cy + 4, cx - 15, cy + 3)
      ..close();
    canvas.drawPath(visorPath, visorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeckHelmetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Face
    final facePaint = Paint()..color = const Color(0xFFFFD1B3);
    canvas.drawCircle(Offset(cx, cy + 2), 8.5, facePaint);

    // Body / Shirt
    final shirtPaint = Paint()..color = Colors.white;
    final shirtPath = Path()
      ..moveTo(cx - 14, cy + 18)
      ..quadraticBezierTo(cx, cy + 8, cx + 14, cy + 18)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Yellow Helmet Dome
    final helmetPaint = Paint()..color = const Color(0xFFFACC15);
    final helmetPath = Path()
      ..moveTo(cx - 12, cy - 2)
      ..cubicTo(cx - 12, cy - 14, cx + 12, cy - 14, cx + 12, cy - 2)
      ..close();
    canvas.drawPath(helmetPath, helmetPaint);

    // Yellow Helmet Brim
    final brimPaint = Paint()..color = const Color(0xFFEAB308);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 14, cy - 3, 28, 3.5), const Radius.circular(2)), brimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

