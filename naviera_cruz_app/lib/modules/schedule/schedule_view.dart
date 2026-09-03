import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/bar_widget.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  final List<Schedule> _schedules = [];
  final List<OperationCharge> _charges = [];
  final List<OperationCharge> _detailedCharges = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scheduleService = ScheduleService();
      final summaryChargesFuture = scheduleService.fetchOperationCharges(
        month: _selectedDate.month,
        year: _selectedDate.year,
        detailed: false,
      );
      final detailedChargesFuture = scheduleService.fetchOperationCharges(
        month: _selectedDate.month,
        year: _selectedDate.year,
        detailed: true,
      );
      final schedulesFuture = scheduleService.fetchMonthlySchedule(
        month: _selectedDate.month,
        year: _selectedDate.year,
      );
      
      final results = await Future.wait([summaryChargesFuture, detailedChargesFuture, schedulesFuture]);
      final summaryCharges = results[0] as List<OperationCharge>;
      final detailedCharges = results[1] as List<OperationCharge>;
      final schedules = results[2] as List<Schedule>;

      setState(() {
        _charges.clear();
        _charges.addAll(summaryCharges);
        _detailedCharges.clear();
        _detailedCharges.addAll(detailedCharges);
        _schedules.clear();
        _schedules.addAll(schedules);
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final captionColor = isDark ? Colors.white38 : Colors.black38;
    final dividerColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F5F9);

    final selectedMonthLabel = "${_monthName(_selectedDate.month)} ${_selectedDate.year}";

    return Scaffold(
      appBar: const NavieraAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
            child: Text(
              "Programación mensual",
              style: TextStyle(
                color: ColorTheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Month Date Picker Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: InkWell(
              onTap: () => _selectMonth(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: ColorTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedMonthLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: captionColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Schedule content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSchedules,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // Visual Operation Charges from API (/api/v1/operation-charges-chart/)
                  if (_charges.isNotEmpty) ...[
                    ..._charges.map((charge) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildOperationChargeCard(context, charge, selectedMonthLabel),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // Details Header
                  Text(
                    "Detalle de operaciones",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  (() {
                    final filteredSchedules = _schedules.where((sch) => 
                      sch.date.month == _selectedDate.month && 
                      sch.date.year == _selectedDate.year
                    ).toList();

                    if (_isLoading && filteredSchedules.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
                    } else if (filteredSchedules.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            _errorMessage ?? "No hay programación para este mes.",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    } else {
                      return Column(
                        children: filteredSchedules.map((schedule) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Icon & Ship ID & Date
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        color: ColorTheme.accent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDate(schedule.date),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: textColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: ColorTheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          schedule.shipId,
                                          style: const TextStyle(
                                            color: ColorTheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Divider(height: 1, color: dividerColor),
                                  const SizedBox(height: 14),

                                  // Cargo type details
                                  Text(
                                    "Tipo de Carga",
                                    style: TextStyle(color: captionColor, fontSize: 11),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    schedule.cargoType,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Specific comments/destinations
                                  Text(
                                    schedule.details,
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  })(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      helpText: "SELECCIONAR MES Y AÑO",
      confirmText: "ACEPTAR",
      cancelText: "CANCELAR",
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: ColorTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
      _loadSchedules();
    }
  }

  Widget _buildOperationChargeCard(BuildContext context, OperationCharge charge, String monthLabel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final captionColor = isDark ? Colors.white38 : Colors.black38;

    final isRaizen = charge.client.toLowerCase().contains('raizen');
    final cardColor = isRaizen ? ColorTheme.primary : ColorTheme.accent;

    final chartData = _getChartDataForCharge(charge);
    final bool hasData = chartData['hasData'] ?? false;
    final List<String> chartDates = List<String>.from(chartData['dates'] ?? []);
    final List<double> barHeights = List<double>.from(chartData['heights'] ?? []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Client & Ship Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Cargas diarias ${charge.client}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    charge.ship,
                    style: TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              monthLabel,
              style: TextStyle(color: captionColor, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Visual Bar Chart using 100% Real API Dates & Loads
            if (hasData && chartDates.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(chartDates.length, (index) {
                  return Column(
                    children: [
                      Container(
                        width: 44,
                        height: 90 * barHeights[index],
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chartDates[index],
                        style: TextStyle(color: captionColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    "Sin registros de cargas diarias en la API para este mes",
                    style: TextStyle(color: captionColor, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            // Real API Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    "Total Barcos",
                    "${charge.totalShips}",
                    Icons.directions_boat_outlined,
                    cardColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    "Total LSFO",
                    "${charge.totalLsfo.toStringAsFixed(0)} m³",
                    Icons.local_shipping_outlined,
                    Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    "Total MGO",
                    "${charge.totalMgo.toStringAsFixed(0)} m³",
                    Icons.water_drop_outlined,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getChartDataForCharge(OperationCharge charge) {
    // 1. Filter detailed charges from /api/v1/operation-charges-chart/?detailed=1 for this ship
    final shipName = charge.ship.toLowerCase().trim();
    final clientName = charge.client.toLowerCase().trim();

    final shipDetailed = _detailedCharges.where((d) {
      if (d.dateApplied == null) return false;
      final matchShip = d.ship.toLowerCase().trim() == shipName;
      final matchClient = d.client.toLowerCase().trim() == clientName;
      return matchShip || matchClient;
    }).toList();

    // Group loads by dateApplied (dd/MM)
    final Map<String, double> dayLoads = {};
    for (var d in shipDetailed) {
      if (d.dateApplied != null) {
        final dayKey = "${d.dateApplied!.day.toString().padLeft(2, '0')}/${d.dateApplied!.month.toString().padLeft(2, '0')}";
        final double loadVal = d.totalLsfo + d.totalMgo;
        dayLoads[dayKey] = (dayLoads[dayKey] ?? 0.0) + (loadVal > 0 ? loadVal : 1.0);
      }
    }

    final sortedDates = dayLoads.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return {
        'hasData': false,
        'dates': <String>[],
        'heights': <double>[],
      };
    }

    final List<String> selectedDates = sortedDates.length <= 4 
        ? sortedDates 
        : [sortedDates.first, sortedDates[(sortedDates.length * 0.33).floor()], sortedDates[(sortedDates.length * 0.66).floor()], sortedDates.last];

    double maxLoad = selectedDates.map((d) => dayLoads[d]!).reduce((a, b) => a > b ? a : b);
    if (maxLoad == 0) maxLoad = 1.0;

    final List<double> heights = selectedDates.map((d) => (dayLoads[d]! / maxLoad).clamp(0.35, 1.0)).toList();

    return {
      'hasData': true,
      'dates': selectedDates,
      'heights': heights,
    };
  }

  Widget _buildMetricTile(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      "", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ];
    return names[month];
  }
}
