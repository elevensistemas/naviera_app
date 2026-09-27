import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/ncs_hero_header.dart';
import '../../app/save_the_date_data.dart';
import '../../core/storage.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<Post> _posts = [];
  final List<Goal> _goals = [];
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
      final homeService = HomeService();
      final goalService = GoalService();

      final results = await Future.wait([
        homeService.fetchPosts().catchError((_) => <Post>[]),
        goalService.fetchGoals().catchError((_) => <Goal>[]),
      ]);

      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll((results[0] as List).cast<Post>());
          _goals.clear();
          _goals.addAll((results[1] as List).cast<Goal>());
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text("Error al cargar la imagen", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemoryImageDialog(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.92),
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

    final String bannerTitle = _activeTab == 0
        ? "Novedades y noticias"
        : "Mis objetivos";
    final String bannerSubtitle = _activeTab == 0
        ? "Actualidad y comunicados de Naviera Cruz del Sur."
        : "Seguimiento de metas operativas y estratégicas.";

    return Scaffold(
      backgroundColor: bodyBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Standard NcsHeroHeader with ship ALFA C
            NcsHeroHeader(
              title: bannerTitle,
              subtitle: bannerSubtitle,
            ),

            // Main Full-Width Card Container with top rounded corners
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
                  // Row 1: Segmented Buttons (Novedades vs Mis Objetivos)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                    color: _activeTab == 0 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      "Novedades",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _activeTab == 0 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                                    color: _activeTab == 1 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      "Mis Objetivos",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _activeTab == 1 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
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
                  const SizedBox(height: 20),

                  // Tab Content
                  if (_isLoading && (_posts.isEmpty && _goals.isEmpty))
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_activeTab == 0) ...[
                    // Novedades List
                    if (_posts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Center(
                          child: Text(
                            _errorMessage ?? "No hay comunicados ni novedades activas en este momento.",
                            style: TextStyle(color: captionColor, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return _buildPostCard(post, isDark, textColor, captionColor);
                        },
                      ),
                  ] else ...[
                    // Mis Objetivos List
                    if (userGoals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Center(
                          child: Text(
                            _errorMessage ?? "No tienes objetivos asignados en este período.",
                            style: TextStyle(color: captionColor, fontSize: 14),
                            textAlign: TextAlign.center,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post, bool isDark, Color textColor, Color captionColor) {
    final itemBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final itemBorder = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    final titleText = post.title.isNotEmpty ? post.title : "Save the Date";
    final subtitleText = post.content.isNotEmpty ? post.content : "Un encuentro para disfrutar juntos";
    final authorText = post.authorName.isNotEmpty ? post.authorName : "Alejandro Lo Presti";

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: itemBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tag + Date + Menu dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tag Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF451A03).withOpacity(0.5) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Aviso Importante",
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Date + Menu icon
              Row(
                children: [
                  Text(
                    _formatDate(post.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: captionColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.more_vert,
                    size: 18,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            titleText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle / Content text
          Text(
            subtitleText,
            style: TextStyle(
              fontSize: 14,
              color: captionColor,
            ),
          ),
          const SizedBox(height: 14),

          // Mini 16:9 AspectRatio Banner Card (Clean, Prolijo, Tap to Zoom)
          GestureDetector(
            onTap: () {
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
                _showImageDialog(context, post.imageUrl!);
              } else {
                _showMemoryImageDialog(context, saveTheDateImageBytes);
              }
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                            ? Image.network(
                                post.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Image.memory(
                                  saveTheDateImageBytes,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.memory(
                                saveTheDateImageBytes,
                                fit: BoxFit.cover,
                              ),
                      ),
                      // Zoom hint pill on bottom right
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                "Toca para ampliar",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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
            ),
          ),
          const SizedBox(height: 14),

          // Author Row below banner
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 20,
                color: captionColor,
              ),
              const SizedBox(width: 6),
              Text(
                authorText,
                style: TextStyle(
                  fontSize: 13,
                  color: captionColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal, bool isDark, Color textColor, Color captionColor) {
    final itemBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final itemBorder = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    double progress = 0.0;
    bool isProgressBased = goal.goalType == 'percentage' || goal.goalType == 'free';
    
    double? achieved = double.tryParse(goal.achievedValue ?? '');
    double? expected = double.tryParse(goal.expectedValue);
    
    if (achieved != null && expected != null && expected > 0) {
      progress = (achieved / expected).clamp(0.0, 1.0);
    }
    
    bool isCompleted = false;
    if (goal.goalType == 'boolean') {
      isCompleted = goal.achievedValue == '1.00' || goal.achievedValue == '1' || goal.achievedValue == 'true';
    } else if (expected != null && achieved != null) {
      isCompleted = achieved >= expected;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
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
              fontSize: 15,
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
                backgroundColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F5F9),
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
