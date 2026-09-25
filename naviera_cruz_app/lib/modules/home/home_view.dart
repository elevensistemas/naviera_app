import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/bar_widget.dart';
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

  Color _colorForType(PostType type) {
    switch (type) {
      case PostType.alert: return ColorTheme.danger;
      case PostType.news: return ColorTheme.primary;
      case PostType.event: return ColorTheme.accent;
      case PostType.birthday: return Colors.pink;
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

  Widget _buildTabButton(BuildContext context, int index, String title) {
    final isSelected = _activeTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final unselectedBg = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;
    final unselectedText = isDark ? Colors.white70 : Colors.black87;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ColorTheme.primary : unselectedBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : unselectedText,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

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

    // Filter goals for current active period (Current Semester & Year)
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
      // If no goals for exact semester, check current year goals
      final currentYearGoals = goalsToFilter.where((g) {
        if (g.targetDate.isEmpty) return true;
        final dt = DateTime.tryParse(g.targetDate);
        return dt != null && dt.year == currentYear;
      }).toList();
      
      if (currentYearGoals.isNotEmpty) {
        userGoals = currentYearGoals;
      } else {
        // Exclude expired past years (e.g. 2025)
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

    return Scaffold(
      appBar: const NavieraAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
            child: Text(
              "Portal corporativo",
              style: TextStyle(
                color: ColorTheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Custom Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                _buildTabButton(context, 0, "Novedades"),
                const SizedBox(width: 10),
                _buildTabButton(context, 1, "Mis Objetivos"),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading && (_posts.isEmpty && _goals.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _activeTab == 0
                        ? (_posts.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(40.0),
                                  child: Text(
                                    _errorMessage ?? "No hay comunicados ni novedades activas en este momento.",
                                    style: const TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20.0),
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  final post = _posts[index];
                                  final badgeColor = _colorForType(post.type);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.8),
                                                ),
                                                child: Text(
                                                  post.type.rawValue,
                                                  style: TextStyle(
                                                    color: badgeColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatDate(post.timestamp),
                                                style: TypographyTheme.caption(context).copyWith(color: secondaryTextColor),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            post.content,
                                            style: TextStyle(
                                              fontSize: 15,
                                              height: 1.4,
                                              color: textColor,
                                            ),
                                          ),

                                          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            GestureDetector(
                                              onTap: () => _showImageDialog(context, post.imageUrl!),
                                              child: Stack(
                                                alignment: Alignment.bottomRight,
                                                children: [
                                                  Container(
                                                    constraints: const BoxConstraints(maxHeight: 280),
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(10),
                                                      color: Colors.black.withOpacity(0.03),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Image.network(
                                                        post.imageUrl!,
                                                        width: double.infinity,
                                                        fit: BoxFit.contain,
                                                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: const EdgeInsets.all(8),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.65),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          "Toca para ampliar",
                                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 16),
                                          Divider(
                                            height: 1, 
                                            color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F5F9)
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.account_circle_outlined,
                                                size: 16,
                                                color: secondaryTextColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                post.authorName,
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
                                    ),
                                  );
                                },
                              ))
                        : (userGoals.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(40.0),
                                  child: Text(
                                    _errorMessage ?? "No tienes objetivos asignados en este período.",
                                    style: const TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20.0),
                                itemCount: userGoals.length,
                                itemBuilder: (context, index) {
                                  return _buildGoalCard(context, userGoals[index]);
                                },
                              )),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

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

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal Type Tag & Target Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  style: TypographyTheme.caption(context).copyWith(color: secondaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            // Description
            Text(
              goal.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress Bar / Value indicator
            if (isProgressBased) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Progreso: ${(progress * 100).toInt()}%",
                    style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "${goal.achievedValue ?? '0'} / ${goal.expectedValue}${goal.goalType == 'percentage' ? '%' : ''}",
                    style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : ColorTheme.primary,
                  ),
                  minHeight: 8,
                ),
              ),
            ] else ...[
              // Boolean Checkbox style indicator
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? Colors.green : secondaryTextColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCompleted ? "Completado" : "Pendiente de cumplimiento",
                    style: TextStyle(
                      fontSize: 13,
                      color: isCompleted 
                          ? (isDark ? Colors.greenAccent : Colors.green.shade700) 
                          : secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
