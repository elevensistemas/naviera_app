import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../core/storage.dart';

class TrainingView extends StatefulWidget {
  const TrainingView({super.key});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  final TrainingService _trainingService = ProductionTrainingService();
  bool _isLoading = true;
  TrainingConsumption? _consumption;
  List<Training> _trainings = [];
  String? _selectedShip;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final consumption = await _trainingService.fetchTrainingConsumption(ship: _selectedShip);
      final trainings = await _trainingService.fetchTrainings();
      setState(() {
        _consumption = consumption;
        _trainings = trainings;
      });
    } catch (e) {
      debugPrint('Error loading training data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openTrainingDetailModal(Training training) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TrainingDetailSheet(
        training: training,
        onAdvanceProgress: (updatedTraining) {
          setState(() {
            final idx = _trainings.indexWhere((t) => t.id == updatedTraining.id);
            if (idx != -1) {
              _trainings[idx] = updatedTraining;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Capacitaciones", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con usuario activo
                    Row(
                      children: [
                        const Icon(Icons.school, color: ColorTheme.primary, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Consumo de Capacitación",
                                style: TypographyTheme.title2(context),
                              ),
                              Text(
                                "Control de instrucción marítima y certificaciones STCW • Registro por usuario activo",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // User Badge Clarification
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: ColorTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ColorTheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_circle, color: ColorTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Usuario Activo: ${SessionManager.shared.currentUser?.name ?? 'Usuario Autenticado'} (Registro en servidor)",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KPI Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildKPICard(
                            context,
                            title: "Horas Consumidas",
                            value: "${_consumption?.totalHoursConsumed ?? 0} h",
                            icon: Icons.access_time_outlined,
                            color: ColorTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKPICard(
                            context,
                            title: "Cursos Completados",
                            value: "${_consumption?.totalTrainingsCompleted ?? 0}",
                            icon: Icons.assignment_turned_in_outlined,
                            color: ColorTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKPICard(
                            context,
                            title: "Cumplimiento Plan",
                            value: "${_consumption?.complianceRate ?? 0}%",
                            icon: Icons.donut_large_outlined,
                            color: ColorTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKPICard(
                            context,
                            title: "Certificados Vigentes",
                            value: "${_consumption?.activeCertificates ?? 0}",
                            icon: Icons.verified_user_outlined,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Consumo por Buque Card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.directions_boat_filled, color: ColorTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Consumo por Buque",
                                  style: TypographyTheme.headline(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_consumption?.consumptionByShip != null)
                              ..._consumption!.consumptionByShip.map((shipItem) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            shipItem.ship,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            "${shipItem.hours} hrs (${shipItem.completionRate}% completado)",
                                            style: TextStyle(
                                              color: isDark ? Colors.white70 : Colors.black54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: shipItem.completionRate / 100.0,
                                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                                        color: ColorTheme.primary,
                                        minHeight: 8,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Cursos y Capacitaciones Activas Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Programa de Cursos y Normas",
                          style: TypographyTheme.title2(context),
                        ),
                        Text(
                          "Toca para abrir y continuar",
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_trainings.isEmpty)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.school_outlined, size: 44, color: Colors.grey),
                                const SizedBox(height: 10),
                                Text(
                                  "No hay capacitaciones asignadas o registradas en el servidor para este usuario.",
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._trainings.map((t) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openTrainingDetailModal(t),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: ColorTheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.play_circle_fill, color: ColorTheme.primary, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              t.code,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text("${t.hours} hrs • ${t.sector}", style: const TextStyle(fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: t.userProgressPercentage / 100.0,
                                              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                                              color: ColorTheme.success,
                                              minHeight: 5,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${t.completedModules}/${t.totalModules} mód",
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: ColorTheme.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${t.userProgressPercentage.toStringAsFixed(0)}%",
                                    style: const TextStyle(
                                      color: ColorTheme.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Modal Detail View for interactive training viewer and advancing progress
class _TrainingDetailSheet extends StatefulWidget {
  final Training training;
  final ValueChanged<Training> onAdvanceProgress;

  const _TrainingDetailSheet({
    required this.training,
    required this.onAdvanceProgress,
  });

  @override
  State<_TrainingDetailSheet> createState() => _TrainingDetailSheetState();
}

class _TrainingDetailSheetState extends State<_TrainingDetailSheet> {
  late Training _current;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _current = widget.training;
  }

  Future<void> _advanceCourse() async {
    if (_current.completedModules >= _current.totalModules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Capacitación completada al 100%!"), backgroundColor: Colors.green),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final service = ProductionTrainingService();
      final updated = await service.updateTrainingProgress(
        trainingId: _current.id,
        completedModules: _current.completedModules + 1,
      );
      setState(() {
        _current = updated;
      });
      widget.onAdvanceProgress(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Módulo avanzado! Progreso actual: ${updated.userProgressPercentage.toStringAsFixed(0)}%"),
            backgroundColor: ColorTheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error advancing progress: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _current.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Video Player Simulated Frame
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0B192C), Color(0xFF1E3E62)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 70),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: ColorTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Ver Clase en Video (STCW)",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sector & Instructor info
                Row(
                  children: [
                    Chip(
                      label: Text(_current.code, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: ColorTheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text("${_current.hours} Horas", style: const TextStyle(fontSize: 11)),
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_current.sector, style: const TextStyle(fontSize: 11)),
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _current.description,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(
                  "Instructor: ${_current.instructor}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorTheme.primary),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Progreso personal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Progreso del Marino", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      "${_current.completedModules} de ${_current.totalModules} Módulos (${_current.userProgressPercentage.toStringAsFixed(0)}%)",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorTheme.success),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _current.userProgressPercentage / 100.0,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  color: ColorTheme.success,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),

                const SizedBox(height: 20),
                const Text("Módulos del Curso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),

                // Lista de módulos
                ..._current.modules.map((m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: m.isCompleted ? ColorTheme.success.withOpacity(0.4) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          m.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: m.isCompleted ? ColorTheme.success : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            m.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: m.isCompleted ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          "${m.durationMinutes} min",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Action Button Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _advanceCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isUpdating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_current.completedModules >= _current.totalModules ? Icons.verified : Icons.play_arrow),
                label: Text(
                  _current.completedModules >= _current.totalModules
                      ? "Capacitación Completada"
                      : "Continuar Capacitación (Avanzar Módulo)",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compatibility Alias
typedef StatsView = TrainingView;

