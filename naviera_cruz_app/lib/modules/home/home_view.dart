import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/ncs_hero_header.dart';
import '../../core/storage.dart';
import '../bulletins/bulletins_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<Goal> _goals = [];
  final List<Bulletin> _bulletins = [];
  final List<Post> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _activeTab = 0; // 0 for Novedades, 1 for Mis Objetivos

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goalService = GoalService();
      final goals = await goalService.fetchGoals().catchError((_) => <Goal>[]);
      final bulletins = await BulletinService.shared.fetchBulletins().catchError((_) => <Bulletin>[]);
      final posts = await HomeService().fetchPosts().catchError((_) => <Post>[]);

      if (mounted) {
        setState(() {
          _goals.clear();
          _goals.addAll(goals);
          _bulletins.clear();
          _bulletins.addAll(bulletins);
          _posts.clear();
          _posts.addAll(posts.where((p) => p.isForOffice).toList());
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _checkIsCompleted(Goal goal) {
    if (goal.goalType == 'boolean') {
      return goal.achievedValue == '1.00' || goal.achievedValue == '1' || goal.achievedValue == 'true';
    }
    final expected = double.tryParse(goal.expectedValue);
    final achieved = double.tryParse(goal.achievedValue ?? '');
    if (expected != null && achieved != null) {
      return achieved >= expected;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final captionColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final bodyBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final session = Provider.of<SessionManager>(context);
    final currentUser = session.currentUser;

    final now = DateTime.now();
    final currentYear = now.year;
    final currentSemester = now.month >= 7 ? 2 : 1;

    // Filter goals for current user
    final userSpecificGoals = currentUser == null
        ? _goals
        : _goals.where((g) {
            if (g.userId.isNotEmpty && g.userId == currentUser.id) return true;
            if (g.leaderId.isNotEmpty && g.leaderId == currentUser.id) return true;
            if (g.userId.isEmpty && g.leaderId.isEmpty) return true;
            return false;
          }).toList();

    final goalsToFilter = userSpecificGoals.isNotEmpty ? userSpecificGoals : _goals;

    final currentSemesterGoals = goalsToFilter.where((g) {
      if (g.targetDate.isEmpty) return true;
      final dt = DateTime.tryParse(g.targetDate);
      if (dt == null) return true;
      final sem = dt.month >= 7 ? 2 : 1;
      return dt.year == currentYear && sem == currentSemester;
    }).toList();

    List<Goal> userGoals;
    if (currentSemesterGoals.isNotEmpty) {
      userGoals = currentSemesterGoals;
    } else {
      final currentYearGoals = goalsToFilter.where((g) {
        if (g.targetDate.isEmpty) return true;
        final dt = DateTime.tryParse(g.targetDate);
        return dt != null && dt.year == currentYear;
      }).toList();

      if (currentYearGoals.isNotEmpty) {
        userGoals = currentYearGoals;
      } else {
        userGoals = goalsToFilter.where((g) {
          if (g.targetDate.isEmpty) return true;
          final dt = DateTime.tryParse(g.targetDate);
          return dt == null || dt.year >= currentYear;
        }).toList();
      }
    }

    if (userGoals.isEmpty && _goals.isNotEmpty) {
      userGoals = List.from(_goals);
    }

    userGoals.sort((a, b) => b.targetDate.compareTo(a.targetDate));

    final int totalCount = userGoals.length;
    final int completedCount = userGoals.where(_checkIsCompleted).length;
    final int inProgressCount = totalCount - completedCount;

    final String bannerTitle = _activeTab == 0 ? "Novedades y noticias" : "Mis objetivos";
    final String bannerSubtitle = _activeTab == 0
        ? "Actualidad y comunicados de Naviera Cruz del Sur."
        : "Seguimiento de metas operativas y estratégicas.";

    return Container(
      color: bodyBg,
      child: Column(
        children: [
          // Reusable Hero Header - PINNED AT TOP
          NcsHeroHeader(
            title: bannerTitle,
            subtitle: bannerSubtitle,
          ),

          // Scrollable Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [

              // Segmented Buttons (Novedades vs Mis Objetivos)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Button 1: Novedades
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _activeTab = 0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: _activeTab == 0 ? ColorTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 18,
                                  color: _activeTab == 0
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Novedades",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _activeTab == 0
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Button 2: Mis Objetivos
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _activeTab = 1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: _activeTab == 1 ? ColorTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.track_changes_outlined,
                                  size: 17,
                                  color: _activeTab == 1
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Mis Objetivos",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _activeTab == 1
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // TAB 0: NOVEDADES Y NOTICIAS (CARGADAS DE LA INTRANET VÍA SWAGGER)
              if (_activeTab == 0) ...[
                if (_posts.isEmpty)
                  _buildEmptyNovedades(context, isDark, cardBg, textColor, captionColor)
                else
                  ..._buildNovedadesList(context, isDark, cardBg, textColor, captionColor),
              ]

              // TAB 1: MIS OBJETIVOS (COMO ANTES)
              else ...[
                // KPI Stats Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                  child: Row(
                    children: [
                      _buildKpiCard(
                        label: "Total",
                        value: totalCount.toString(),
                        color: ColorTheme.primary,
                        icon: Icons.track_changes_rounded,
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        captionColor: captionColor,
                      ),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        label: "Completados",
                        value: completedCount.toString(),
                        color: const Color(0xFF16A34A),
                        icon: Icons.check_circle_rounded,
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        captionColor: captionColor,
                      ),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        label: "En Curso",
                        value: inProgressCount.toString(),
                        color: const Color(0xFFF59E0B),
                        icon: Icons.hourglass_top_rounded,
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        captionColor: captionColor,
                      ),
                    ],
                  ),
                ),

                // Main Goals Container
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Metas y Objetivos Asignados",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Período $currentYear - S$currentSemester",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: captionColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_isLoading && _goals.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (userGoals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.assignment_turned_in_outlined,
                                    size: 48, color: captionColor.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage ?? "No tienes objetivos asignados en este período.",
                                  style: TextStyle(color: captionColor, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userGoals.length,
                          itemBuilder: (context, index) {
                            return _buildGoalCard(context, userGoals[index], isDark, textColor, captionColor);
                          },
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    ),
  ],
),
);
}

  Widget _buildBulletinsList(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color captionColor,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            child: Row(
              children: [
                const Icon(Icons.article_outlined, color: ColorTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Boletines y Comunicados Oficiales (${_bulletins.length})",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bulletins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = _bulletins[i];
              final isLatest = i == 0;
              final meta = [
                if (b.date != null) "${b.date!.day}/${b.date!.month}/${b.date!.year}",
                if (b.category != null) b.category!,
              ].join(' · ');

              return Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BulletinPdfView(bulletin: b)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLatest
                            ? const Color(0xFF2EC4D6).withOpacity(0.6)
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        width: isLatest ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A2342), Color(0xFF0E3A66)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2EC4D6), size: 20),
                              SizedBox(height: 2),
                              Text('PDF', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isLatest)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2EC4D6).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ÚLTIMO BOLETÍN',
                                    style: TextStyle(
                                      color: Color(0xFF0E7C8A),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              Text(
                                b.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              if (meta.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  meta,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: captionColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: captionColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Tarjeta vacía para Novedades (tal como solicitó el usuario: "sin el boletin")
  Widget _buildEmptyNovedades(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color captionColor,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2D) : cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2E44) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F3260) : const Color(0xFFE0F0FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.newspaper_rounded,
              size: 32,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            "Sin novedades por el momento",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No hay avisos o comunicaciones publicadas al momento.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: captionColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // Lista de novedades cargadas desde Swagger (/api/v1/announcements/)
  List<Widget> _buildNovedadesList(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color captionColor,
  ) {
    if (_posts.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(18.0, 12.0, 18.0, 8.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF007AFF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "COMUNICADOS OFICIALES",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF007AFF),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2B48) : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF007AFF),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Sin novedades pendientes",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Esperando nuevos comunicados oficiales de la compañía.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: captionColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(18.0, 12.0, 18.0, 8.0),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF007AFF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "COMUNICADOS OFICIALES (${_posts.length})",
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF007AFF),
              ),
            ),
          ],
        ),
      ),
      ..._posts.map((post) => _buildNovedadCard(context, post, isDark, cardBg, textColor, captionColor)),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildNovedadCard(
    BuildContext context,
    Post post,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color captionColor,
  ) {
    final dateStr = "${post.timestamp.day.toString().padLeft(2, '0')}/${post.timestamp.month.toString().padLeft(2, '0')}/${post.timestamp.year}";
    final bool hasImage = post.imageUrl != null && post.imageUrl!.trim().isNotEmpty;
    final bool isImportant = post.type == PostType.alert;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2D) : cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isImportant
              ? Colors.redAccent.withOpacity(0.5)
              : (isDark ? const Color(0xFF1E2E44) : const Color(0xFFE2E8F0)),
          width: isImportant ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPostDetails(context, post, isDark),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado de la novedad (Autor + Fecha + Badge)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: isDark ? const Color(0xFF0F3260) : const Color(0xFFE0F0FE),
                      child: Text(
                        post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : "N",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 11, color: captionColor),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: captionColor,
                                ),
                              ),
                              if (post.targetDisplay.isNotEmpty && post.targetDisplay.toLowerCase() != 'todos') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    post.targetDisplay,
                                    style: TextStyle(fontSize: 10, color: captionColor, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isImportant)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.priority_high_rounded, size: 12, color: Colors.red),
                            SizedBox(width: 2),
                            Text(
                              "IMPORTANTE",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Título
                if (post.title.isNotEmpty) ...[
                  Text(
                    post.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Imagen si existe
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      width: double.infinity,
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Contenido
                if (post.content.isNotEmpty) ...[
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                ],

                // Ver más enlace sutil
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      "Ver detalle",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF007AFF)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPostDetails(BuildContext context, Post post, bool isDark) {
    final dateStr = "${post.timestamp.day.toString().padLeft(2, '0')}/${post.timestamp.month.toString().padLeft(2, '0')}/${post.timestamp.year}";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                post.title.isNotEmpty ? post.title : "Novedad Oficial",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Color(0xFF007AFF)),
                  const SizedBox(width: 4),
                  Text(
                    post.authorName,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (post.imageUrl != null && post.imageUrl!.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                post.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color captionColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: captionColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal, bool isDark, Color textColor, Color captionColor) {
    final itemBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final itemBorder = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    double progress = 0.0;
    bool isProgressBased = goal.goalType == 'percentage' || goal.goalType == 'free';

    double? achieved = double.tryParse(goal.achievedValue ?? '');
    double? expected = double.tryParse(goal.expectedValue);

    if (achieved != null && expected != null && expected > 0) {
      progress = (achieved / expected).clamp(0.0, 1.0);
    }

    final bool isCompleted = _checkIsCompleted(goal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: itemBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCompleted ? Colors.green : ColorTheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isCompleted ? Colors.green : ColorTheme.primary).withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  goal.goalType == 'percentage'
                      ? 'Porcentual'
                      : (goal.goalType == 'boolean' ? 'Cumplimiento' : 'General'),
                  style: TextStyle(
                    color: isCompleted
                        ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                        : (isDark ? Colors.blueAccent : ColorTheme.primary),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "Límite: ${goal.targetDate}",
                style: TextStyle(fontSize: 12, color: captionColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            goal.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),

          if (isProgressBased) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Progreso: ${(progress * 100).toInt()}%",
                  style: TextStyle(fontSize: 12, color: captionColor, fontWeight: FontWeight.w600),
                ),
                Text(
                  "${goal.achievedValue ?? '0'} / ${goal.expectedValue}${goal.goalType == 'percentage' ? '%' : ''}",
                  style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : ColorTheme.primary,
                ),
                minHeight: 8,
              ),
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : captionColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? "Completado" : "Pendiente de cumplimiento",
                  style: TextStyle(
                    fontSize: 13,
                    color: isCompleted
                        ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                        : captionColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
