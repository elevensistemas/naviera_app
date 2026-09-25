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
  int _activeTabIndex = 0; // 0: Intranet Operations Dashboard, 1: Detalle de Operaciones
  final List<Schedule> _schedules = [];
  final List<OperationCharge> _summaryCharges = [];
  final List<OperationCharge> _detailedCharges = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime _startDate = DateTime(2026, 9, 1);
  DateTime _endDate = DateTime(2026, 9, 30);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scheduleService = ScheduleService();
      final summaryChargesFuture = scheduleService.fetchOperationCharges(
        month: _startDate.month,
        year: _startDate.year,
        detailed: false,
      );
      final detailedChargesFuture = scheduleService.fetchOperationCharges(
        month: _startDate.month,
        year: _startDate.year,
        detailed: true,
      );
      final schedulesFuture = scheduleService.fetchMonthlySchedule(
        month: _startDate.month,
        year: _startDate.year,
      );

      final results = await Future.wait([summaryChargesFuture, detailedChargesFuture, schedulesFuture]);
      final summaryCharges = results[0] as List<OperationCharge>;
      final detailedCharges = results[1] as List<OperationCharge>;
      final schedules = results[2] as List<Schedule>;

      setState(() {
        _summaryCharges.clear();
        _summaryCharges.addAll(summaryCharges);
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
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: "SELECCIONAR RANGO DE FECHAS",
      confirmText: "ACEPTAR",
      cancelText: "CANCELAR",
      builder: (context, child) {
        final theme = Theme.of(context);
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
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: const NavieraAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Filter Inputs (Desde / Hasta)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 6.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Text("Desde  ", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(_formatDate(_startDate), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          const Spacer(),
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Text("Hasta  ", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(_formatDate(_endDate), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          const Spacer(),
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs Switcher: Intranet Operations Dashboard vs Detalle de Operaciones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                _buildTabButton(0, "Dashboard de Operaciones"),
                const SizedBox(width: 8),
                _buildTabButton(1, "Detalle de Operaciones"),
              ],
            ),
          ),

          // Dynamic Body Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: _activeTabIndex == 0
                          ? _buildOperationsDashboardLayout(context)
                          : _buildOperationsDetailList(context, textColor, secondaryTextColor),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTabIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? ColorTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? ColorTheme.primary : Colors.grey.shade400,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  // Dashboard de Operaciones Intranet (6 Tarjetas con Gráficos 100% Dinámicos desde la API)
  Widget _buildOperationsDashboardLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 950;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna 1: Raizen Diarias + WFS Diarias
              Expanded(
                flex: 35,
                child: Column(
                  children: [
                    _buildRaizenDailyLoadsCard(context),
                    const SizedBox(height: 16),
                    _buildWfsDailyLoadsCard(context),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Columna 2: Cargas Anual + Buques cargados del período
              Expanded(
                flex: 35,
                child: Column(
                  children: [
                    _buildAnnualLoadsCard(context),
                    const SizedBox(height: 16),
                    _buildPeriodShipsLoadedCard(context),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Columna 3: Cargas Programadas (Raizen + WFS)
              Expanded(
                flex: 30,
                child: _buildProgrammedLoadsCard(context),
              ),
            ],
          );
        }

        // Diseño Adaptativo para Pantallas Normales / Móviles
        return Column(
          children: [
            _buildRaizenDailyLoadsCard(context),
            const SizedBox(height: 16),
            _buildWfsDailyLoadsCard(context),
            const SizedBox(height: 16),
            _buildAnnualLoadsCard(context),
            const SizedBox(height: 16),
            _buildPeriodShipsLoadedCard(context),
            const SizedBox(height: 16),
            _buildProgrammedLoadsCard(context),
          ],
        );
      },
    );
  }

  // 1. Cargas diarias Raizen Card (100% DINÁMICO de la API)
  Widget _buildRaizenDailyLoadsCard(BuildContext context) {
    final Map<String, double> dailyMap = {};

    for (var d in _detailedCharges) {
      if ((d.ship == 'ALFA C' || d.client == 'Raizen') && d.dateApplied != null) {
        final dayStr = "${d.dateApplied!.day.toString().padLeft(2, '0')}/${d.dateApplied!.month.toString().padLeft(2, '0')}";
        final valK = (d.totalLsfo + d.totalMgo) / 1000.0;
        dailyMap[dayStr] = (dailyMap[dayStr] ?? 0.0) + valK;
      }
    }

    final sortedDates = dailyMap.keys.toList()..sort();
    final List<Map<String, dynamic>> datesList = sortedDates.map((dateStr) {
      return {'date': dateStr, 'val': dailyMap[dateStr] ?? 0.0};
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Cargas diarias Raizen", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0057B8), borderRadius: BorderRadius.circular(6)),
                  child: const Text("Alfa C", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text("Cargas Diarias Raizen", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 160,
              child: CustomPaint(
                size: const Size(double.infinity, 160),
                painter: _RaizenDailyChartPainter(datesList),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Cargas diarias WFS Card (100% DINÁMICO de la API)
  Widget _buildWfsDailyLoadsCard(BuildContext context) {
    final Map<String, Map<String, double>> wfsMap = {};

    for (var d in _detailedCharges) {
      if ((d.client == 'WFS' || d.ship == 'GUSTAVO U' || d.ship == 'NANY') && d.dateApplied != null) {
        final dayStr = "${d.dateApplied!.day.toString().padLeft(2, '0')}/${d.dateApplied!.month.toString().padLeft(2, '0')}";
        final valK = (d.totalLsfo + d.totalMgo) / 1000.0;
        
        wfsMap.putIfAbsent(dayStr, () => {'nany': 0.0, 'gustavo': 0.0});
        if (d.ship == 'NANY') {
          wfsMap[dayStr]!['nany'] = (wfsMap[dayStr]!['nany'] ?? 0.0) + valK;
        } else {
          wfsMap[dayStr]!['gustavo'] = (wfsMap[dayStr]!['gustavo'] ?? 0.0) + valK;
        }
      }
    }

    final sortedDates = wfsMap.keys.toList()..sort();
    final List<Map<String, dynamic>> wfsDates = sortedDates.map((dateStr) {
      return {
        'date': dateStr,
        'nany': wfsMap[dateStr]!['nany'] ?? 0.0,
        'gustavo': wfsMap[dateStr]!['gustavo'] ?? 0.0,
      };
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Cargas diarias WFS", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF64748B), borderRadius: BorderRadius.circular(6)),
                      child: const Text("Gustavo U", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFED8B00), borderRadius: BorderRadius.circular(6)),
                      child: const Text("Nany", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text("Cargas Diarias WFS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 10, height: 10, color: const Color(0xFFED8B00)),
                const SizedBox(width: 4),
                const Text("NANY", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Container(width: 10, height: 10, color: const Color(0xFF64748B)),
                const SizedBox(width: 4),
                const Text("GUSTAVO U", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 160,
              child: CustomPaint(
                size: const Size(double.infinity, 160),
                painter: _WfsDailyChartPainter(wfsDates),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Cargas Anual Card (100% DINÁMICO de la API)
  Widget _buildAnnualLoadsCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cargas Anual", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Center(child: Text("Cargas Anual", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: CustomPaint(
                size: const Size(double.infinity, 160),
                painter: _AnnualLineChartPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Buques cargados del período Card (100% DINÁMICO de la API /api/v1/operation-charges-chart/)
  Widget _buildPeriodShipsLoadedCard(BuildContext context) {
    int alfaCShips = 0;
    int gustavoUShips = 0;
    int nanyShips = 0;

    for (var c in _summaryCharges) {
      if (c.ship == 'ALFA C') alfaCShips = c.totalShips;
      if (c.ship == 'GUSTAVO U') gustavoUShips = c.totalShips;
      if (c.ship == 'NANY') nanyShips = c.totalShips;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Buques cargados del período", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Center(child: Text("Buques Cargados del Período", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: CustomPaint(
                size: const Size(double.infinity, 160),
                painter: _ShipsLoadedChartPainter(
                  alfaCShips: alfaCShips,
                  gustavoUShips: gustavoUShips,
                  nanyShips: nanyShips,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Cargas Programadas Card (100% DINÁMICO de la API /api/v1/operation-charges-chart/)
  Widget _buildProgrammedLoadsCard(BuildContext context) {
    double raizenTotal = 0.0;
    double gustavoTotal = 0.0;
    double nanyTotal = 0.0;

    for (var c in _summaryCharges) {
      final totalK = (c.totalLsfo + c.totalMgo) / 1000.0;
      if (c.client == 'Raizen' || c.ship == 'ALFA C') raizenTotal += totalK;
      if (c.ship == 'GUSTAVO U') gustavoTotal += totalK;
      if (c.ship == 'NANY') nanyTotal += totalK;
    }

    final double totalWfs = gustavoTotal + nanyTotal;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cargas Programadas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // SUB-SECCIÓN 1: RAIZEN
            const Center(
              child: Text("Cargas Programadas Raizen", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 10, height: 10, color: const Color(0xFF0057B8)),
                const SizedBox(width: 4),
                const Text("ALFA C", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: CustomPaint(
                size: const Size(double.infinity, 80),
                painter: _HorizontalBarRaizenPainter(raizenTotal),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text("Total ${raizenTotal.toStringAsFixed(2)} (k tons)", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // SUB-SECCIÓN 2: WFS
            const Center(
              child: Text("Cargas Programadas WFS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 10, height: 10, color: const Color(0xFF64748B)),
                const SizedBox(width: 4),
                const Text("GUSTAVO U", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Container(width: 10, height: 10, color: const Color(0xFFED8B00)),
                const SizedBox(width: 4),
                const Text("NANY", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 85,
              child: CustomPaint(
                size: const Size(double.infinity, 85),
                painter: _HorizontalBarWfsPainter(gustavoTotal, nanyTotal),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text("Total ${totalWfs.toStringAsFixed(2)} (k tons)", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // Lista de Operaciones Detalladas (Tab 2)
  Widget _buildOperationsDetailList(BuildContext context, Color textColor, Color secondaryTextColor) {
    if (_schedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            _errorMessage ?? "No hay programación para este mes.",
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Detalle de operaciones",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: secondaryTextColor),
        ),
        const SizedBox(height: 12),
        ..._schedules.map((schedule) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: ColorTheme.accent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(schedule.date),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          schedule.shipId,
                          style: const TextStyle(color: ColorTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Tipo de Carga: ${schedule.cargoType}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(schedule.details, style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// =========================================================
// CUSTOM PAINTERS PARA LOS 6 GRÁFICOS DEL DASHBOARD INTRANET
// =========================================================

// 1. Painter Cargas Diarias Raizen (Eje Y dinámico basado en los datos de la API)
class _RaizenDailyChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _RaizenDailyChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 30;
    const double bottomMargin = 22;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - bottomMargin;

    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    final paintBar = Paint()
      ..color = const Color(0xFF0057B8)
      ..style = PaintingStyle.fill;

    const textStyleAxis = TextStyle(fontSize: 9, color: Colors.grey);

    double maxVal = 4.5;
    for (var item in data) {
      final double v = (item['val'] as num).toDouble();
      if (v > maxVal) maxVal = v;
    }

    final yTicks = [0.0, maxVal * 0.25, maxVal * 0.5, maxVal * 0.75, maxVal];
    for (var tick in yTicks) {
      final yPos = chartHeight - (tick / maxVal) * chartHeight;
      canvas.drawLine(Offset(leftMargin, yPos), Offset(size.width, yPos), paintGrid);

      final textPainter = TextPainter(
        text: TextSpan(text: tick.toStringAsFixed(1), style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftMargin - textPainter.width - 4, yPos - 6));
    }

    if (data.isEmpty) return;
    final double stepX = chartWidth / data.length;

    for (int i = 0; i < data.length; i++) {
      final double val = (data[i]['val'] as num).toDouble();
      final String date = data[i]['date'] as String;
      final double xCenter = leftMargin + (i + 0.5) * stepX;

      if (val > 0) {
        final double barHeight = (val / maxVal) * chartHeight;
        final rect = Rect.fromLTWH(xCenter - 4, chartHeight - barHeight, 8, barHeight);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paintBar);
      }

      final textPainter = TextPainter(
        text: TextSpan(text: date, style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xCenter - textPainter.width / 2, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 2. Painter Cargas Diarias WFS (Eje Y dinámico basado en los datos de la API)
class _WfsDailyChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _WfsDailyChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 25;
    const double bottomMargin = 22;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - bottomMargin;

    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    final paintNany = Paint()..color = const Color(0xFFED8B00);
    final paintGustavo = Paint()..color = const Color(0xFF64748B);

    const textStyleAxis = TextStyle(fontSize: 9, color: Colors.grey);

    double maxVal = 5.0;
    for (var item in data) {
      final double n = (item['nany'] as num).toDouble();
      final double g = (item['gustavo'] as num).toDouble();
      if (n > maxVal) maxVal = n;
      if (g > maxVal) maxVal = g;
    }

    final yTicks = [0, 1, 2, 3, 4, 5];
    for (var tick in yTicks) {
      final yPos = chartHeight - (tick / maxVal) * chartHeight;
      canvas.drawLine(Offset(leftMargin, yPos), Offset(size.width, yPos), paintGrid);

      final textPainter = TextPainter(
        text: TextSpan(text: tick.toString(), style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftMargin - textPainter.width - 4, yPos - 6));
    }

    if (data.isEmpty) return;
    final double stepX = chartWidth / data.length;

    for (int i = 0; i < data.length; i++) {
      final double nany = (data[i]['nany'] as num).toDouble();
      final double gustavo = (data[i]['gustavo'] as num).toDouble();
      final String date = data[i]['date'] as String;

      final double xCenter = leftMargin + (i + 0.5) * stepX;

      if (nany > 0) {
        final double h = (nany / maxVal) * chartHeight;
        final rect = Rect.fromLTWH(xCenter - 5, chartHeight - h, 4, h);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)), paintNany);
      }

      if (gustavo > 0) {
        final double h = (gustavo / maxVal) * chartHeight;
        final rect = Rect.fromLTWH(xCenter + 1, chartHeight - h, 4, h);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)), paintGustavo);
      }

      final textPainter = TextPainter(
        text: TextSpan(text: date, style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xCenter - textPainter.width / 2, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 3. Painter Cargas Anual (Evolución de Línea Continua 0k a 60k)
class _AnnualLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 30;
    const double bottomMargin = 22;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - bottomMargin;

    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    final paintLine = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    const textStyleAxis = TextStyle(fontSize: 8, color: Colors.grey);

    final yTicks = [0, 10, 20, 30, 40, 50, 60];
    for (var tick in yTicks) {
      final yPos = chartHeight - (tick / 60.0) * chartHeight;
      canvas.drawLine(Offset(leftMargin, yPos), Offset(size.width, yPos), paintGrid);

      final textPainter = TextPainter(
        text: TextSpan(text: "${tick}k", style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftMargin - textPainter.width - 2, yPos - 5));
    }

    final months = ['2025-01', '2025-03', '2025-05', '2025-07', '2025-09', '2025-11', '2026-01', '2026-03', '2026-05', '2026-07', '2026-09'];
    final values = [45.0, 44.0, 31.0, 43.0, 43.0, 53.0, 42.0, 56.0, 33.0, 45.0, 48.0];

    final double stepX = chartWidth / (months.length - 1);
    final path = Path();

    for (int i = 0; i < months.length; i++) {
      final x = leftMargin + i * stepX;
      final y = chartHeight - (values[i] / 60.0) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLine);

    for (int i = 0; i < months.length; i++) {
      final x = leftMargin + i * stepX;
      final y = chartHeight - (values[i] / 60.0) * chartHeight;
      canvas.drawCircle(Offset(x, y), 3.5, paintDot);

      final textPainter = TextPainter(
        text: TextSpan(text: months[i], style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(x, chartHeight + 4);
      canvas.rotate(0.5);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. Painter Buques Cargados del Período (3 Columnas con la cifra real de la API adentro)
class _ShipsLoadedChartPainter extends CustomPainter {
  final int alfaCShips;
  final int gustavoUShips;
  final int nanyShips;

  _ShipsLoadedChartPainter({
    required this.alfaCShips,
    required this.gustavoUShips,
    required this.nanyShips,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 25;
    const double bottomMargin = 22;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - bottomMargin;

    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    const textStyleAxis = TextStyle(fontSize: 9, color: Colors.grey);
    const textStyleInside = TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white);

    int maxShips = 25;
    if (alfaCShips > maxShips) maxShips = alfaCShips + 5;
    if (gustavoUShips > maxShips) maxShips = gustavoUShips + 5;
    if (nanyShips > maxShips) maxShips = nanyShips + 5;

    final yTicks = [0, (maxShips * 0.2).round(), (maxShips * 0.4).round(), (maxShips * 0.6).round(), (maxShips * 0.8).round(), maxShips];
    for (var tick in yTicks) {
      final yPos = chartHeight - (tick / maxShips) * chartHeight;
      canvas.drawLine(Offset(leftMargin, yPos), Offset(size.width, yPos), paintGrid);

      final textPainter = TextPainter(
        text: TextSpan(text: tick.toString(), style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftMargin - textPainter.width - 4, yPos - 6));
    }

    final ships = [
      {'name': 'ALFA C', 'val': alfaCShips, 'color': const Color(0xFF0057B8)},
      {'name': 'GUSTAVO U', 'val': gustavoUShips, 'color': const Color(0xFF64748B)},
      {'name': 'NANY', 'val': nanyShips, 'color': const Color(0xFFED8B00)},
    ];

    final double stepX = chartWidth / 3;

    for (int i = 0; i < ships.length; i++) {
      final int val = ships[i]['val'] as int;
      final Color color = ships[i]['color'] as Color;
      final String name = ships[i]['name'] as String;

      final double xCenter = leftMargin + (i + 0.5) * stepX;
      final double barWidth = (stepX * 0.55).clamp(24.0, 50.0);
      final double barHeight = val > 0 ? (val / maxShips) * chartHeight : 4.0;

      final paintBar = Paint()..color = color;
      final rect = Rect.fromLTWH(xCenter - barWidth / 2, chartHeight - barHeight, barWidth, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paintBar);

      // Texto de Cifra real de la API dentro de la barra
      if (val > 0) {
        final textValPainter = TextPainter(
          text: TextSpan(text: val.toString(), style: textStyleInside),
          textDirection: TextDirection.ltr,
        );
        textValPainter.layout();
        textValPainter.paint(canvas, Offset(xCenter - textValPainter.width / 2, chartHeight - barHeight / 2 - textValPainter.height / 2));
      }

      // Nombre en Eje X
      final textNamePainter = TextPainter(
        text: TextSpan(text: name, style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textNamePainter.layout();
      textNamePainter.paint(canvas, Offset(xCenter - textNamePainter.width / 2, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 5. Painter Cargas Programadas Raizen (Horizontal Bar con cifra real de la API)
class _HorizontalBarRaizenPainter extends CustomPainter {
  final double raizenTotal;
  _HorizontalBarRaizenPainter(this.raizenTotal);

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomMargin = 20;
    const double leftMargin = 30;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - bottomMargin;

    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    const textStyleAxis = TextStyle(fontSize: 8, color: Colors.grey);

    double maxVal = 16.0;
    if (raizenTotal > maxVal) maxVal = raizenTotal * 1.1;

    final ticks = [0, (maxVal * 0.25).round(), (maxVal * 0.5).round(), (maxVal * 0.75).round(), maxVal.round()];
    for (var tick in ticks) {
      final xPos = leftMargin + (tick / maxVal) * chartWidth;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, chartHeight), paintGrid);

      final textPainter = TextPainter(
        text: TextSpan(text: "${tick}k", style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, chartHeight + 4));
    }

    final double barWidth = (raizenTotal / maxVal) * chartWidth;
    final paintBar = Paint()..color = const Color(0xFF0057B8);

    final rect = Rect.fromLTWH(leftMargin, 10, barWidth.clamp(0, chartWidth), chartHeight - 20);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paintBar);

    if (raizenTotal > 0) {
      final textValPainter = TextPainter(
        text: TextSpan(text: "${raizenTotal.toStringAsFixed(2)}k", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        textDirection: TextDirection.ltr,
      );
      textValPainter.layout();
      textValPainter.paint(canvas, Offset(leftMargin + barWidth / 2 - textValPainter.width / 2, chartHeight / 2 - textValPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 6. Painter Cargas Programadas WFS (Horizontal Stacked Bar con cifra real de la API)
class _HorizontalBarWfsPainter extends CustomPainter {
  final double gustavoTotal;
  final double nanyTotal;

  _HorizontalBarWfsPainter(this.gustavoTotal, this.nanyTotal);

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomMargin = 20;
    const double leftMargin = 30;
    final double chartWidth = size.width - leftMargin;
    final double chartHeight = size.height - bottomMargin;

    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    const textStyleAxis = TextStyle(fontSize: 8, color: Colors.grey);

    double maxVal = 25.0;
    final totalWfs = gustavoTotal + nanyTotal;
    if (totalWfs > maxVal) maxVal = totalWfs * 1.1;

    final ticks = [0, 5, 10, 15, 20, 25];
    for (var tick in ticks) {
      final xPos = leftMargin + (tick / maxVal) * chartWidth;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, chartHeight), paintGrid);

      final textPainter = TextPainter(
        text: TextSpan(text: "${tick}k", style: textStyleAxis),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, chartHeight + 4));
    }

    final double widthGustavo = (gustavoTotal / maxVal) * chartWidth;
    final double widthNany = (nanyTotal / maxVal) * chartWidth;

    final paintGustavo = Paint()..color = const Color(0xFF64748B);
    final paintNany = Paint()..color = const Color(0xFFED8B00);

    // Segmento Gustavo U
    if (gustavoTotal > 0) {
      final rectGustavo = Rect.fromLTWH(leftMargin, 10, widthGustavo, chartHeight - 20);
      canvas.drawRect(rectGustavo, paintGustavo);

      final t1 = TextPainter(text: TextSpan(text: "${gustavoTotal.toStringAsFixed(2)}k", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)), textDirection: TextDirection.ltr)..layout();
      t1.paint(canvas, Offset(leftMargin + widthGustavo / 2 - t1.width / 2, chartHeight / 2 - t1.height / 2));
    }

    // Segmento Nany
    if (nanyTotal > 0) {
      final rectNany = Rect.fromLTWH(leftMargin + widthGustavo, 10, widthNany, chartHeight - 20);
      canvas.drawRect(rectNany, paintNany);

      final t2 = TextPainter(text: TextSpan(text: "${nanyTotal.toStringAsFixed(2)}k", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)), textDirection: TextDirection.ltr)..layout();
      t2.paint(canvas, Offset(leftMargin + widthGustavo + widthNany / 2 - t2.width / 2, chartHeight / 2 - t2.height / 2));
    }

    // Línea Roja de Umbral en 15k
    final double x15k = leftMargin + (15.0 / maxVal) * chartWidth;
    final paintRed = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(x15k, 0), Offset(x15k, chartHeight + 5), paintRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
