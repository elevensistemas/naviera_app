import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/ncs_hero_header.dart';
import '../bulletins/bulletins_view.dart';

class CrewNovedadesView extends StatefulWidget {
  const CrewNovedadesView({super.key});

  @override
  State<CrewNovedadesView> createState() => _CrewNovedadesViewState();
}

class _CrewNovedadesViewState extends State<CrewNovedadesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HomeService _homeService = HomeService();

  List<Post> _posts = [];
  bool _loadingPosts = true;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _loadingPosts = true;
      _postsError = null;
    });

    try {
      final posts = await _homeService.fetchPosts();
      if (mounted) {
        setState(() {
          _posts = posts.where((p) => p.isForCrew).toList();
          _loadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postsError = e.toString();
          _loadingPosts = false;
        });
      }
    }
  }

  void _showPostDialog(Post post) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            post.title.isNotEmpty ? post.title : "Comunicado Oficial",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      "${post.timestamp.day.toString().padLeft(2, '0')}/${post.timestamp.month.toString().padLeft(2, '0')}/${post.timestamp.year}",
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
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Cabecera Hero Edge-to-Edge
          NcsHeroHeader(
            title: "Novedades y Boletines",
            subtitle: "Comunicaciones oficiales para la tripulación",
          ),

          // Pestañas Segmentadas
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF007AFF),
              indicatorWeight: 3,
              labelColor: const Color(0xFF007AFF),
              unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.announcement_outlined, size: 20),
                  text: "Avisos y RRHH",
                ),
                Tab(
                  icon: Icon(Icons.article_outlined, size: 20),
                  text: "Boletines de Intranet",
                ),
              ],
            ),
          ),

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Avisos y Comunicados Oficiales
                _buildAnnouncementsTab(isDark),

                // 2. Boletines con PDF
                const BulletinsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab(bool isDark) {
    if (_loadingPosts) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0057B8)));
    }

    if (_postsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              const Text(
                "No se pudieron cargar los comunicados",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(_postsError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAnnouncements,
                icon: const Icon(Icons.refresh),
                label: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 48, color: Color(0xFF0066CC)),
              const SizedBox(height: 14),
              Text(
                "Sin novedades pendientes",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Esperando nuevos comunicados oficiales de la compañía.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      color: const Color(0xFF0057B8),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = _posts[index];
          final dateStr = "${post.timestamp.day.toString().padLeft(2, '0')}/${post.timestamp.month.toString().padLeft(2, '0')}/${post.timestamp.year}";

          return InkWell(
            onTap: () => _showPostDialog(post),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.announcement_outlined, size: 20, color: Color(0xFF007AFF)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title.isNotEmpty ? post.title : "Aviso Oficial",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post.authorName,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Ver comunicado completo >",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
