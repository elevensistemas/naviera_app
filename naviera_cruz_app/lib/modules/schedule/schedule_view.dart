import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  final List<Schedule> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Programación Mensual",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
          ),
        ],
      ),
      body: _isLoading && _schedules.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: _schedules.isEmpty
                  ? Center(
                      child: Text(
                        _errorMessage ?? "No hay programación disponible.",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = _schedules[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      color: ColorTheme.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(schedule.date),
                                      style: TypographyTheme.headline(context),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: ColorTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        schedule.shipId,
                                        style: const TextStyle(
                                          color: ColorTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Text(
                                  "Tipo de Carga",
                                  style: TypographyTheme.caption(context),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  schedule.cargoType,
                                  style: TypographyTheme.body(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  schedule.details,
                                  style: TypographyTheme.caption(context).copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
