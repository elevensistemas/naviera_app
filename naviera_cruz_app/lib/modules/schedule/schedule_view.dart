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
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedMonthIndex = 0; // 0 = Junio 2026, 1 = Mayo 2026, 2 = Abril 2026

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
      final schedules = await scheduleService.fetchMonthlySchedule();
      setState(() {
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

  Widget _buildBarChartSection(String title, String shipName, List<double> heights, List<String> dates, Color barColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    shipName,
                    style: TextStyle(
                      color: barColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Junio 2026",
              style: TextStyle(color: Colors.black38, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Bar Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(4, (index) {
                return Column(
                  children: [
                    Container(
                      width: 50,
                      height: 100 * heights[index],
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dates[index],
                      style: const TextStyle(color: Colors.black38, fontSize: 11),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // Month Filter Chips (App NCS - Pantalla 4 style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                _buildMonthChip("Junio 2026", 0),
                const SizedBox(width: 10),
                _buildMonthChip("Mayo 2026", 1),
                const SizedBox(width: 10),
                _buildMonthChip("Abril 2026", 2),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Schedule content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSchedules,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // Visual Charts (App NCS - Pantalla 4 style)
                  if (_selectedMonthIndex == 0) ...[
                    _buildBarChartSection(
                      "Cargas diarias Raizen",
                      "Alfa C",
                      [0.8, 0.5, 0.7, 0.9],
                      ["04/06", "08/06", "12/06", "19/06"],
                      ColorTheme.primary,
                    ),
                    const SizedBox(height: 16),
                    _buildBarChartSection(
                      "Cargas diarias WFS",
                      "Gustavo U",
                      [0.6, 0.4, 0.8, 0.5],
                      ["04/06", "08/06", "12/06", "19/06"],
                      ColorTheme.accent,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Details Header
                  const Text(
                    "Detalle de operaciones",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading && _schedules.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
                  else if (_schedules.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          _errorMessage ?? "No hay programación para este mes.",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._schedules.map((schedule) {
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
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
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 14),

                              // Cargo type details
                              const Text(
                                "Tipo de Carga",
                                style: TextStyle(color: Colors.black38, fontSize: 11),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                schedule.cargoType,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Specific comments/destinations
                              Text(
                                schedule.details,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChip(String label, int index) {
    final isSelected = _selectedMonthIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMonthIndex = index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? ColorTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? ColorTheme.primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
