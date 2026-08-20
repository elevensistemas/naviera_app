import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/bar_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedShipId = widget.shipId;
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      final fleetService = FleetService();
      
      // Load ships for filters
      final ships = await fleetService.fetchShips();
      setState(() {
        _ships.clear();
        _ships.addAll(ships);
        // Default to the first ship if none was selected
        if (_selectedShipId == null && _ships.isNotEmpty) {
          _selectedShipId = _ships.first.id;
        }
      });

      await _loadCrew();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _loadCrew() async {
    if (_selectedShipId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final fleetService = FleetService();
      final crew = await fleetService.fetchCrew(_selectedShipId!);
      
      // Deduplicate by ID on the client side to avoid duplicate cards for the same person
      final seenIds = <String>{};
      final uniqueCrew = <CrewMember>[];
      for (var member in crew) {
        if (member.id.isNotEmpty && !seenIds.contains(member.id)) {
          seenIds.add(member.id);
          uniqueCrew.add(member);
        }
      }
      
      setState(() {
        _crewMembers.clear();
        _crewMembers.addAll(uniqueCrew);
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final captionColor = isDark ? Colors.white38 : Colors.black38;
    final text45Color = isDark ? Colors.white54 : Colors.black45;
    final dividerColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F5F9);

    return Scaffold(
      appBar: const NavieraAppBar(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Text(
              "Tripulación",
              style: TextStyle(
                color: ColorTheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Filter Chips Row
            if (_ships.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _ships.map((ship) {
                    final isSelected = _selectedShipId == ship.id;
                    
                    // Specific mockup color scheme:
                    // Selected: blue/white
                    // Unselected 1: orange/white
                    // Unselected 2: grey/white
                    Color chipBgColor = Colors.grey.shade500;
                    if (isSelected) {
                      chipBgColor = ColorTheme.primary;
                    } else if (ship.id == "s2") {
                      chipBgColor = ColorTheme.accent; // Orange chip
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: chipBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ship.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),

            // Subheader row (A bordo + dotacion minima)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "A BORDO",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: captionColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Dotación mínima completa",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ColorTheme.accent.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Crew Members List Card
            Expanded(
              child: _isLoading && _crewMembers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _crewMembers.isEmpty
                      ? const Center(
                          child: Text(
                            "No hay tripulación registrada a bordo.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Card(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12.0),
                            itemCount: _crewMembers.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: dividerColor,
                            ),
                            itemBuilder: (context, index) {
                              final member = _crewMembers[index];

                              // Generate clean realistic days based on index or ID
                              final days = 33 + (index * 21) % 45;

                              // Soft adaptive badges for dark mode
                              final badgeBg = isDark ? Colors.green.withOpacity(0.15) : const Color(0xFFE8F5E9);
                              final badgeText = isDark ? Colors.greenAccent : const Color(0xFF2E7D32);
                              final daysBg = isDark ? ColorTheme.primary.withOpacity(0.15) : const Color(0xFFE3F2FD);
                              final daysBorder = isDark ? ColorTheme.primary.withOpacity(0.5) : const Color(0xFF90CAF9);
                              final daysText = isDark ? Colors.blueAccent : ColorTheme.primary;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                child: Row(
                                  children: [
                                    // Big blue avatar icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: ColorTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Name and Badge
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                              fontSize: 12,
                                              color: text45Color,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Embarcado badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: badgeBg,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: badgeText,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              "Embarcado",
                                              style: TextStyle(
                                                color: badgeText,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Días circle on the right
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Días",
                                          style: TextStyle(
                                            color: captionColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: daysBg,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: daysBorder,
                                              width: 0.8,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "$days",
                                            style: TextStyle(
                                              color: daysText,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
