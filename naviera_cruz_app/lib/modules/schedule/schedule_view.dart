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

  Widget _buildBarChartSection(BuildContext context, String title, String shipName, List<double> heights, List<String> dates, Color barColor, String monthLabel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final captionColor = isDark ? Colors.white38 : Colors.black38;

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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
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
            Text(
              monthLabel,
              style: TextStyle(color: captionColor, fontSize: 12),
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
                      style: TextStyle(color: captionColor, fontSize: 11),
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
                  // Visual Charts (App NCS - Pantalla 4 style)
                  ...[
                    _buildBarChartSection(
                      context,
                      "Cargas diarias Raizen",
                      "Alfa C",
                      [0.8, 0.5, 0.7, 0.9],
                      _getChartDates(_selectedDate),
                      ColorTheme.primary,
                      selectedMonthLabel,
                    ),
                    const SizedBox(height: 16),
                    _buildBarChartSection(
                      context,
                      "Cargas diarias WFS",
                      "Gustavo U",
                      [0.6, 0.4, 0.8, 0.5],
                      _getChartDates(_selectedDate),
                      ColorTheme.accent,
                      selectedMonthLabel,
                    ),
                    const SizedBox(height: 24),
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
    }
  }

  String _monthName(int month) {
    const names = [
      "", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ];
    return names[month];
  }

  List<String> _getChartDates(DateTime date) {
    final monthStr = date.month.toString().padLeft(2, '0');
    return ["04/$monthStr", "08/$monthStr", "12/$monthStr", "19/$monthStr"];
  }
}
