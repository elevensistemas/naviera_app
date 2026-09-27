import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/ncs_hero_header.dart';
import 'report_incident_view.dart';

class IncidentListView extends StatefulWidget {
  const IncidentListView({super.key});

  @override
  State<IncidentListView> createState() => _IncidentListViewState();
}

class _IncidentListViewState extends State<IncidentListView> {
  final List<Incident> _incidents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedShipFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final incidentService = IncidentService();
      final incidents = await incidentService.fetchIncidents();
      setState(() {
        _incidents.clear();
        _incidents.addAll(incidents);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getResolvedShipName(Incident incident) {
    final nameUpper = incident.shipName.trim().toUpperCase();
    if (nameUpper.contains('ALFA')) return 'ALFA C';
    if (nameUpper.contains('NANY')) return 'NANY';
    if (nameUpper.contains('GUSTAVO')) return 'GUSTAVO U';

    final idUpper = incident.shipId.trim().toUpperCase();
    if (idUpper.contains('ALFA')) return 'ALFA C';
    if (idUpper.contains('NANY')) return 'NANY';
    if (idUpper.contains('GUSTAVO')) return 'GUSTAVO U';

    // Django DB vessel IDs
    if (idUpper == '4' || idUpper == '1' || idUpper == '2071') return 'ALFA C';
    if (idUpper == '5' || idUpper == '2' || idUpper == '2072') return 'NANY';
    if (idUpper == '6' || idUpper == '3' || idUpper == '2073') return 'GUSTAVO U';

    if (nameUpper.isNotEmpty && !RegExp(r'^\d+$').hasMatch(nameUpper)) {
      return nameUpper;
    }
    if (idUpper.isNotEmpty && !RegExp(r'^\d+$').hasMatch(idUpper)) {
      return idUpper;
    }

    return 'ALFA C';
  }

  String _getResolvedReporterName(Incident incident) {
    final rName = incident.reporterName.trim();
    if (rName.isNotEmpty && !RegExp(r'^\d+$').hasMatch(rName)) {
      return rName;
    }
    final rId = incident.reporterId.trim();
    if (rId.isNotEmpty && !RegExp(r'^\d+$').hasMatch(rId)) {
      return rId;
    }
    if (rId.isNotEmpty) {
      if (rId == '2071' || rId == '1') return 'Nahuel';
      if (rId == '2') return 'Juan';
      if (rId == '3') return 'Jonathan';
      return 'Tripulante (#$rId)';
    }
    return 'Personal Naviera';
  }

  Color _getIncidentShipColor(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('ALFA')) return const Color(0xFF0057B8); // Blue
    if (upper.contains('GUSTAVO')) return const Color(0xFF64748B); // Slate / Grey
    if (upper.contains('NANY')) return const Color(0xFFED8B00); // Orange
    return const Color(0xFF0284C7); // Default Ocean Blue for 'Todos'
  }

  List<Incident> get _filteredIncidents {
    if (_selectedShipFilter == 'Todos') return _incidents;
    final filterTarget = _selectedShipFilter.toUpperCase().trim();
    return _incidents.where((i) {
      final shipNameResolved = _getResolvedShipName(i).toUpperCase().trim();
      return shipNameResolved.contains(filterTarget) || filterTarget.contains(shipNameResolved);
    }).toList();
  }

  Color _statusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return const Color(0xFFD32F2F); // Red
      case IncidentStatus.inReview:
        return const Color(0xFFED6C02); // Orange
      case IncidentStatus.resolved:
        return const Color(0xFF2E7D32); // Green
    }
  }

  Color _statusBgColor(IncidentStatus status, bool isDark) {
    if (isDark) {
      return _statusColor(status).withOpacity(0.15);
    }
    switch (status) {
      case IncidentStatus.open:
        return const Color(0xFFFFEBEE); // Light Red
      case IncidentStatus.inReview:
        return const Color(0xFFFFF3E0); // Light Orange
      case IncidentStatus.resolved:
        return const Color(0xFFE8F5E9); // Light Green
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: ReportIncidentView(
              onIncidentReported: _loadIncidents,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final captionColor = isDark ? Colors.white38 : Colors.black38;
    final text45Color = isDark ? Colors.white54 : Colors.black45;
    final dividerColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F5F9);

    final displayedIncidents = _filteredIncidents;

    final String bannerTitle = _selectedShipFilter == 'Todos'
        ? "Seguridad y salvamento"
        : "Incidentes • $_selectedShipFilter";
    final String bannerSubtitle = _selectedShipFilter == 'Todos'
        ? "Control de incidentes y reporte de novedades en tiempo real."
        : "Registro de novedades de seguridad del buque $_selectedShipFilter.";

    final filtersList = ['Todos', 'ALFA C', 'GUSTAVO U', 'NANY'];

    return Scaffold(
      backgroundColor: bodyBg,
      body: _isLoading && _incidents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIncidents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Reusable NcsHeroHeader
                    NcsHeroHeader(
                      title: bannerTitle,
                      subtitle: bannerSubtitle,
                      onTap: () {
                        final currIdx = filtersList.indexOf(_selectedShipFilter);
                        final nextIdx = (currIdx + 1) % filtersList.length;
                        setState(() {
                          _selectedShipFilter = filtersList[nextIdx];
                        });
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Control de Incidentes Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: ColorTheme.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.shield,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Control de Incidentes",
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Registrá novedades para revisión de capitanía",
                                              style: TextStyle(
                                                color: text45Color,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ColorTheme.accent, // Orange Button
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      onPressed: _showReportSheet,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add, size: 20),
                                          SizedBox(width: 6),
                                          Text(
                                            "Reportar incidente",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Section Title & Vessel Filter Chips Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Historial de incidentes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryTextColor,
                                ),
                              ),
                              Text(
                                "Filtrar por barco",
                                style: TextStyle(fontSize: 11, color: captionColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Vessel Filter Buttons Centered & Responsive (No Horiz Scroll Cutoff)
                          Row(
                            children: filtersList.map((shipFilter) {
                              final isSelected = _selectedShipFilter == shipFilter;
                              final shipColor = _getIncidentShipColor(shipFilter);

                              final Color chipBg = isSelected
                                  ? shipColor
                                  : (isDark ? shipColor.withValues(alpha: 0.22) : shipColor.withValues(alpha: 0.12));
                              final Color chipText = isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : shipColor);
                              final Color chipIcon = isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : shipColor);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedShipFilter = shipFilter;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: chipBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected ? shipColor : shipColor.withValues(alpha: isDark ? 0.45 : 0.35),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            shipFilter == 'Todos' ? Icons.apps_rounded : Icons.directions_boat_filled_rounded,
                                            size: 13,
                                            color: chipIcon,
                                          ),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                shipFilter,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: chipText,
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
                          const SizedBox(height: 14),

                          if (displayedIncidents.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40.0),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.verified_user_outlined,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _errorMessage ?? "No hay incidentes para este barco.",
                                      style: TextStyle(color: captionColor),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...displayedIncidents.map((incident) {
                              final statusCol = _statusColor(incident.status);
                              final statusBg = _statusBgColor(incident.status, isDark);
                              final shipDisplay = _getResolvedShipName(incident);
                              final reporterDisplay = _getResolvedReporterName(incident);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Code/ID and Status badge
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "#${incident.id.toUpperCase().padLeft(6, '0')}",
                                            style: const TextStyle(
                                              color: ColorTheme.accent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              incident.status.rawValue,
                                              style: TextStyle(
                                                color: statusCol,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Date row
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined, size: 14, color: captionColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatDate(incident.date),
                                            style: TextStyle(
                                              color: text45Color,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      // Description/Text
                                      Text(
                                        incident.description,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Divider
                                      Divider(height: 1, color: dividerColor),
                                      const SizedBox(height: 14),

                                      // Footer Row: Ship Badge & Reporter Info
                                      Row(
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final shipCol = _getIncidentShipColor(shipDisplay);
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: shipCol.withValues(alpha: isDark ? 0.2 : 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: shipCol.withValues(alpha: 0.35)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.directions_boat_filled_rounded, size: 14, color: shipCol),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Barco: $shipDisplay",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: shipCol,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          const Spacer(),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.person_outline, size: 15, color: captionColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Reportó: $reporterDisplay",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: secondaryTextColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
