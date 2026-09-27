import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/config.dart';
import '../../core/storage.dart';
import '../../core/video_helper.dart';
import '../../app/ncs_hero_header.dart';
import '../../app/training_thumbnail_widget.dart';

typedef StatsView = TrainingView;

class TrainingView extends StatefulWidget {
  const TrainingView({super.key});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  final TrainingService _trainingService = ProductionTrainingService();
  bool _isLoading = false;
  List<Training> _trainings = [];
  int _activeTab = 0; // 0 = Mis cursos, 1 = Todos los cursos (Normas OCIMF removed)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
    _loadInitialCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialCourses() async {
    setState(() => _isLoading = true);
    final defaults = _getDefaultCoursesList();

    try {
      final remoteTrainings = await _trainingService.fetchTrainings();
      if (remoteTrainings.isNotEmpty) {
        final List<Training> enriched = [];

        for (int i = 0; i < defaults.length; i++) {
          final def = defaults[i];
          final r = i < remoteTrainings.length ? remoteTrainings[i] : null;

          if (r != null) {
            enriched.add(Training(
              id: i + 1, // ID 1..12 maps directly to real course images
              title: r.title.isNotEmpty ? r.title : def.title,
              code: r.code.isNotEmpty ? r.code : def.code,
              hours: r.hours > 0 ? r.hours : def.hours,
              sector: r.sector.isNotEmpty ? r.sector : def.sector,
              completionRate: r.userProgressPercentage > 0 ? r.userProgressPercentage : def.completionRate,
              status: r.status.isNotEmpty ? r.status : def.status,
              description: r.description.isNotEmpty ? r.description : def.description,
              instructor: r.instructor.isNotEmpty ? r.instructor : def.instructor,
              videoUrl: r.videoUrl ?? def.videoUrl,
              completedModules: r.completedModules > 0 ? r.completedModules : def.completedModules,
              totalModules: r.totalModules > 0 ? r.totalModules : def.totalModules,
              videoPositionSeconds: r.videoPositionSeconds > 0 ? r.videoPositionSeconds : def.videoPositionSeconds,
              totalVideoDurationSeconds: r.totalVideoDurationSeconds > 0 ? r.totalVideoDurationSeconds : def.totalVideoDurationSeconds,
              modules: r.modules.isNotEmpty ? r.modules : def.modules,
            ));
          } else {
            enriched.add(def);
          }
        }

        setState(() {
          _trainings = enriched;
        });
      } else {
        _useDefaultCourses();
      }
    } catch (_) {
      _useDefaultCourses();
    } finally {
      if (_trainings.isEmpty) {
        _useDefaultCourses();
      }
      setState(() => _isLoading = false);
    }
  }

  List<Training> _getDefaultCoursesList() {
    return [
      Training(
        id: 1,
        title: "Amarre efectivo - OCIMF",
        code: "OCIMF",
        hours: 2,
        sector: "General",
        completionRate: 50.0,
        status: "Obligatorio",
        description: "Guía de seguridad OCIMF Megomp para operaciones de amarre en muelles y monoboyas.",
        instructor: "Cap. Esteban Valdez (Instructor STCW)",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        completedModules: 2,
        totalModules: 4,
        videoPositionSeconds: 3600,
        totalVideoDurationSeconds: 7200,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Equipos y líneas de amarre", durationMinutes: 30, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Inspección y mantenimiento", durationMinutes: 30, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Zonas de peligro (Snap-back zone)", durationMinutes: 30, isCompleted: false),
          TrainingModule(id: 4, title: "Módulo 4: Procedimientos en monoboyas", durationMinutes: 30, isCompleted: false),
        ],
      ),
      Training(
        id: 2,
        title: "Equipo de izado",
        code: "OCIMF",
        hours: 1,
        sector: "General",
        completionRate: 100.0,
        status: "Completado",
        description: "Inspección de plumas, grúas, estrobos y grilletes según normativa internacional marítima.",
        instructor: "Ing. Gabriel Rossi",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        completedModules: 3,
        totalModules: 3,
        videoPositionSeconds: 3600,
        totalVideoDurationSeconds: 3600,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Inspección pre-operacional", durationMinutes: 20, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Ensayos de carga y certificación", durationMinutes: 20, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Señales de mano y comunicación", durationMinutes: 20, isCompleted: true),
        ],
      ),
      Training(
        id: 3,
        title: "La importancia de reportar",
        code: "STCW",
        hours: 1,
        sector: "General",
        completionRate: 20.0,
        status: "En progreso",
        description: "Cultura de seguridad, reporte de cuasi-accidentes (Near Miss) y condiciones inseguras a bordo.",
        instructor: "Lic. Roberto Soria",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        completedModules: 1,
        totalModules: 3,
        videoPositionSeconds: 720,
        totalVideoDurationSeconds: 3600,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Cultura de Seguridad Marítima", durationMinutes: 20, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Formulario de Near Miss", durationMinutes: 20, isCompleted: false),
          TrainingModule(id: 3, title: "Módulo 3: Análisis causa raíz y acción correctiva", durationMinutes: 20, isCompleted: false),
        ],
      ),
      Training(
        id: 4,
        title: "Peligros Eléctricos",
        code: "STCW",
        hours: 1,
        sector: "General",
        completionRate: 0.0,
        status: "Nuevo",
        description: "Procedimientos Lockout/Tagout (LOTO), aislamiento de tableros eléctricos y protección en salas de máquinas.",
        instructor: "Ing. Carlos Benítez",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        completedModules: 0,
        totalModules: 4,
        videoPositionSeconds: 0,
        totalVideoDurationSeconds: 5400,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Aislamiento Eléctrico y LOTO", durationMinutes: 25, isCompleted: false),
          TrainingModule(id: 2, title: "Módulo 2: Equipos de protección arc-flash", durationMinutes: 20, isCompleted: false),
          TrainingModule(id: 3, title: "Módulo 3: Puesta a tierra y tableros", durationMinutes: 20, isCompleted: false),
          TrainingModule(id: 4, title: "Módulo 4: Primeros auxilios por electrocución", durationMinutes: 25, isCompleted: false),
        ],
      ),
      Training(
        id: 5,
        title: "Seguridad en operaciones",
        code: "STCW",
        hours: 2,
        sector: "General",
        completionRate: 10.0,
        status: "En progreso",
        description: "Prácticas seguras en maniobras de cubierta, elementos de protección personal (EPP) y comunicación.",
        instructor: "Cap. Marcos Benítez",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        completedModules: 1,
        totalModules: 5,
        videoPositionSeconds: 720,
        totalVideoDurationSeconds: 7200,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Uso adecuado de EPP", durationMinutes: 24, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Prevención de caídas a distinto nivel", durationMinutes: 24, isCompleted: false),
          TrainingModule(id: 3, title: "Módulo 3: Trabajos en caliente", durationMinutes: 24, isCompleted: false),
          TrainingModule(id: 4, title: "Módulo 4: Orden y limpieza en cubierta", durationMinutes: 24, isCompleted: false),
          TrainingModule(id: 5, title: "Módulo 5: Protocolos de zafarrancho", durationMinutes: 24, isCompleted: false),
        ],
      ),
    ];
  }

  void _useDefaultCourses() {
    _trainings = _getDefaultCoursesList();
  }

  void _openTrainingDetailModal(Training training) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TrainingVideoModalSheet(
        training: training,
        onUpdateTraining: (updated) {
          setState(() {
            final idx = _trainings.indexWhere((t) => t.id == updated.id);
            if (idx != -1) {
              _trainings[idx] = updated;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    // Compute Summary counts
    final int availableCount = _trainings.length;
    final int inProgressCount = _trainings.where((t) => t.userProgressPercentage > 0 && t.userProgressPercentage < 100).length;
    final int completedCount = _trainings.where((t) => t.userProgressPercentage >= 100).length;

    // Filter courses
    final filteredCourses = _trainings.where((course) {
      // Search filter
      final matchesSearch = course.title.toLowerCase().contains(_searchQuery) ||
          course.code.toLowerCase().contains(_searchQuery) ||
          course.sector.toLowerCase().contains(_searchQuery);

      if (!matchesSearch) return false;

      // Dropdown Filter
      if (_selectedFilter == 'Obligatorio') {
        return course.status.toLowerCase().contains('obligatorio');
      } else if (_selectedFilter == 'Completado') {
        return course.userProgressPercentage >= 100;
      } else if (_selectedFilter != 'Todos') {
        return course.sector.toLowerCase() == _selectedFilter.toLowerCase() ||
            course.code.toLowerCase() == _selectedFilter.toLowerCase();
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Official NcsHeroHeader
            const NcsHeroHeader(
              title: "Capacitaciones",
              subtitle: "Programa de formación STCW y cursos normativos.",
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Row 1: Summary Stats Cards (12 Cursos disponibles, 3 En progreso, 8 Completados)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          count: availableCount.toString(),
                          label: "Cursos disponibles",
                          icon: Icons.school_rounded,
                          iconColor: const Color(0xFF2563EB),
                          bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          count: inProgressCount.toString(),
                          label: "En progreso",
                          icon: Icons.pie_chart_outline_rounded,
                          iconColor: const Color(0xFF16A34A),
                          bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          count: completedCount.toString(),
                          label: "Completados",
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: const Color(0xFF475569),
                          bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 2: Segmented Control Tabs (Mis cursos & Todos los cursos - Normas OCIMF removed)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            title: "Mis cursos",
                            isActive: _activeTab == 0,
                            onTap: () => setState(() => _activeTab = 0),
                          ),
                        ),
                        Expanded(
                          child: _buildSegmentButton(
                            title: "Todos los cursos",
                            isActive: _activeTab == 1,
                            onTap: () => setState(() => _activeTab = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Search Bar & Filter Dropdown
                  Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(fontSize: 13, color: textColor),
                                  decoration: InputDecoration(
                                    hintText: "Buscar cursos, temas...",
                                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                  },
                                  child: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Filter Menu Button
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          initialValue: _selectedFilter,
                          onSelected: (val) {
                            setState(() {
                              _selectedFilter = val;
                            });
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'Todos', child: Text('Todos los temas')),
                            const PopupMenuItem(value: 'Obligatorio', child: Text('! Obligatorios')),
                            const PopupMenuItem(value: 'Completado', child: Text('✓ Completados')),
                            const PopupMenuItem(value: 'General', child: Text('📖 Sector General')),
                            const PopupMenuItem(value: 'Cubierta', child: Text('⚓ Sector Cubierta')),
                            const PopupMenuItem(value: 'Máquinas', child: Text('⚙️ Sector Máquinas')),
                          ],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                _selectedFilter == 'Todos' ? "Filtrar" : _selectedFilter,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Course Video List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (filteredCourses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              "No se encontraron cursos para '$_searchQuery'",
                              style: TextStyle(fontSize: 14, color: secondaryText),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                        return _buildCourseCard(context, course, isDark, cardBg, textColor, secondaryText);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 10,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 5 : 8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: isMobile ? 18 : 22),
          ),
          SizedBox(width: isMobile ? 5 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isMobile ? 9.5 : 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0057B8) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF0057B8).withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    Training course,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color secondaryText,
  ) {
    final bool isCompleted = course.userProgressPercentage >= 100;
    final bool isObligatory = course.status.toLowerCase().contains('obligatorio');
    final double progressRatio = (course.userProgressPercentage / 100.0).clamp(0.0, 1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: EdgeInsets.all(isMobile ? 10.0 : 12.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openTrainingDetailModal(course),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Thumbnail with cropped ultra-sharp NCS logo
            TrainingThumbnailWidget(
              courseId: course.id,
              width: isMobile ? 88 : 110,
              height: isMobile ? 58 : 65,
            ),
            SizedBox(width: isMobile ? 8 : 12),

            // Middle Course Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Badges (Obligatorio / Completado & Category Code)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 12),
                              SizedBox(width: 4),
                              Text(
                                "COMPLETADO",
                                style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      else if (isObligatory)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 12),
                              SizedBox(width: 4),
                              Text(
                                "OBLIGATORIO",
                                style: TextStyle(color: Color(0xFFEA580C), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      // Top Right Category Code
                      Text(
                        course.code,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Course Title
                  Text(
                    course.title,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Info Wrap: General • 2 hrs • 4 módulos (Non-overflowing responsive Wrap)
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            course.sector,
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const Text("•", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            "${course.hours} hrs",
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const Text("•", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_outlined, size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            "${course.totalModules} módulos",
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Linear Progress Bar with % text (Bigger & more visible indicator bar)
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0088FF),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${(progressRatio * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0088FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: isMobile ? 4 : 8),

            // Far Right Action Button (Continuar / Iniciar / Revisar)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: isMobile ? 32 : 36,
                  height: isMobile ? 32 : 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFF0088FF).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                    color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0088FF),
                    size: isMobile ? 19 : 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted
                      ? "Revisar"
                      : (course.userProgressPercentage > 0 ? "Continuar" : "Iniciar"),
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0088FF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Modal Sheet for interactive Video Player and Tracking Playback position
class _TrainingVideoModalSheet extends StatefulWidget {
  final Training training;
  final ValueChanged<Training> onUpdateTraining;

  const _TrainingVideoModalSheet({
    required this.training,
    required this.onUpdateTraining,
  });

  @override
  State<_TrainingVideoModalSheet> createState() => _TrainingVideoModalSheetState();
}

class _TrainingVideoModalSheetState extends State<_TrainingVideoModalSheet> {
  late Training _current;
  bool _isPlaying = false;
  double _sliderPositionSeconds = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.training;
    _sliderPositionSeconds = _current.videoPositionSeconds.toDouble();
  }

  String _formatDuration(int totalSec) {
    final hours = totalSec ~/ 3600;
    final mins = (totalSec % 3600) ~/ 60;
    final secs = totalSec % 60;
    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    }
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _onSliderChanged(double val) {
    setState(() {
      _sliderPositionSeconds = val;
    });
  }

  void _saveProgress() {
    final newPosSec = _sliderPositionSeconds.toInt();
    final double posRatio = (newPosSec / _current.totalVideoDurationSeconds).clamp(0.0, 1.0);
    final int newDoneMods = (posRatio * _current.totalModules).round();

    final updated = _current.copyWith(
      videoPositionSeconds: newPosSec,
      completedModules: newDoneMods,
    );

    widget.onUpdateTraining(updated);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Progreso guardado: min ${(newPosSec ~/ 60)} (${(posRatio * 100).toInt()}%)"),
        backgroundColor: const Color(0xFF0088FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final String formattedCurrentPos = _formatDuration(_sliderPositionSeconds.toInt());
    final String formattedTotalDur = _formatDuration(_current.totalVideoDurationSeconds);
    final double playbackPercent = ((_sliderPositionSeconds / _current.totalVideoDurationSeconds) * 100).clamp(0.0, 100.0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _current.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Instructor: ${_current.instructor}",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
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
                // Video Player Frame
                if (_isPlaying && _current.videoUrl != null && _current.videoUrl!.isNotEmpty)
                  InlineTrainingVideoPlayer(videoUrl: _current.videoUrl!)
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: TrainingThumbnailWidget(
                              courseId: _current.id,
                              width: double.infinity,
                              height: 200,
                            ),
                          ),
                        ),

                        // Video Controls Overlay
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _current.code,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                                        SizedBox(width: 4),
                                        Text("CLASE STCW", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Center Play Icon
                              GestureDetector(
                                onTap: _togglePlay,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0088FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                ),
                              ),

                              // Bottom scrub bar & timestamp
                              Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 8,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                                    ),
                                    child: Slider(
                                      value: _sliderPositionSeconds.clamp(0.0, _current.totalVideoDurationSeconds.toDouble()),
                                      min: 0.0,
                                      max: _current.totalVideoDurationSeconds.toDouble(),
                                      activeColor: const Color(0xFF0088FF),
                                      inactiveColor: Colors.white30,
                                      onChanged: _onSliderChanged,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$formattedCurrentPos / $formattedTotalDur",
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "${playbackPercent.toInt()}% visto",
                                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),



                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveProgress,
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text(
                      "Guardar y actualizar progreso",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0057B8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InlineTrainingVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const InlineTrainingVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<InlineTrainingVideoPlayer> createState() => _InlineTrainingVideoPlayerState();
}

class _InlineTrainingVideoPlayerState extends State<InlineTrainingVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  int _attemptIndex = 0;

  late final List<String> _fallbackUrls;

  @override
  void initState() {
    super.initState();
    _fallbackUrls = [
      widget.videoUrl,
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    ];
    _initController();
  }

  Future<void> _initController() async {
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });

    final targetUrl = _attemptIndex < _fallbackUrls.length ? _fallbackUrls[_attemptIndex] : _fallbackUrls.last;

    try {
      final Uri uri = Uri.parse(targetUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _controller!,
          aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16 / 9,
          autoPlay: true,
          looping: false,
          showControls: true,
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF0088FF)),
            ),
          ),
          errorBuilder: (context, errorMessage) {
            return _buildErrorStateWidget();
          },
        );

        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (_attemptIndex + 1 < _fallbackUrls.length) {
        _attemptIndex++;
        await _initController();
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    }
  }

  Widget _buildErrorStateWidget() {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_camera_back_rounded, color: Color(0xFF38BDF8), size: 42),
              const SizedBox(height: 8),
              const Text(
                "Transmisión de Clase STCW",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                "No se pudo cargar la transmisión en vivo.",
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _attemptIndex = 0;
                  _initController();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Reintentar Video", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorStateWidget();
    }

    if (!_isInitialized || _chewieController == null) {
      return Container(
        height: 210,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0088FF)),
              SizedBox(height: 12),
              Text(
                "Cargando clase STCW...",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}
