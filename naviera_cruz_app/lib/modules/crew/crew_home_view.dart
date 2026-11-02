import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/storage.dart';
import '../../models/crew_profile.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../services/crew_profile_service.dart';
import '../../app/ncs_hero_header.dart';
import '../bulletins/bulletins_view.dart';
import '../profile/profile_view.dart';
import '../incidents/report_incident_view.dart';
import 'crew_faq_search_view.dart';
import 'crew_novedades_view.dart';
import '../../services/crew_faq_service.dart';
import '../../app/ayuda_avatar_data.dart';
import '../home/welcome_novedades_card.dart';

class CrewHomeView extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const CrewHomeView({super.key, this.onNavigateTab});

  @override
  State<CrewHomeView> createState() => _CrewHomeViewState();
}

class _CrewHomeViewState extends State<CrewHomeView> {
  final CrewProfileService _profileService = ProductionCrewProfileService();
  final TextEditingController _faqSearchController = TextEditingController();

  CrewProfile? _profile;
  Bulletin? _latestBulletin;
  List<Post> _crewPosts = [];

  bool _isLoading = true;
  String? _errorMessage;
  String? _bulletinError;
  String? _crewPostsError;

  // Índice del elemento expandido en Preguntas Frecuentes (0 expandido por defecto)
  int? _expandedFaqIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _faqSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _bulletinError = null;
      _crewPostsError = null;
    });

    final currentUser = SessionManager.shared.currentUser;

    try {
      // 1. Cargar perfil de tripulante desde la API de la intranet en tiempo real
      final profile = await _profileService.fetchCurrentCrewProfile(
        currentUser: currentUser,
        forceRefresh: true,
      );

      // 2. Cargar boletines de intranet (/api/v1/bulletins/)
      Bulletin? latestBulletin;
      String? bulletinErr;
      try {
        final bulletins = await BulletinService.shared.fetchBulletins();
        if (bulletins.isNotEmpty) {
          latestBulletin = bulletins.first;
        }
      } catch (e) {
        bulletinErr = e.toString();
      }

      // 3. Sincronizar catálogo oficial de FAQs desde la Intranet (/api/v1/faqs/)
      try {
        await CrewFAQService.shared.fetchFaqsFromIntranet();
      } catch (_) {}

      // 4. Cargar novedades de la Intranet vía Swagger (/api/v1/announcements/)
      List<Post> crewPosts = [];
      String? crewPostsErr;
      try {
        final posts = await HomeService().fetchPosts();
        crewPosts = posts.where((p) => p.isForCrew).toList();
      } catch (e) {
        crewPostsErr = e.toString();
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _latestBulletin = latestBulletin;
          _bulletinError = bulletinErr;
          _crewPosts = crewPosts;
          _crewPostsError = crewPostsErr;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToFaqSearch([String? initialQuery]) {
    final query = initialQuery ?? _faqSearchController.text.trim();
    _faqSearchController.clear();
    if (widget.onNavigateTab != null && query.isEmpty) {
      widget.onNavigateTab!(4); // Cambiar directamente a la pestaña FAQ
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CrewFaqSearchView(
            initialQuery: query.isNotEmpty ? query : null,
            profile: _profile,
            onNavigateTab: widget.onNavigateTab,
          ),
        ),
      );
    }
  }

  void _openBulletinsTab() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(2); // Pestaña Boletines (índice 2)
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BulletinsView()),
      );
    }
  }

  void _openSeguridadTab() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(1); // Pestaña Seguridad (índice 1)
    }
  }

  void _openCursosTab() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(3); // Pestaña Cursos (índice 3)
    }
  }

  void _openReportIncident() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportIncidentView(
          onIncidentReported: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(1);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(">>> CREW_HOME_VIEW_BUILDING <<<");
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9);

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // 1. Cabecera Maritime Hero edge-to-edge exactamente como la captura - PINNED AT TOP
          const NcsHeroHeader(
            title: "Mi espacio a bordo",
            subtitle: "Todo lo que necesitás durante tu embarque",
          ),

          // 2. Contenido Principal idéntico a la captura
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllData,
              color: const Color(0xFF0057B8),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Banner sutil si hay desconexión
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Modo sin conexión. Mostrando datos autorizados de sesión.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loadAllData,
                                  child: const Text("Reintentar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // 1. Tarjeta de Perfil Unificada con Anillo y 4 Columnas
                        _buildProfileCard(isDark),

                        const SizedBox(height: 16),

                        // 2. Accesos rápidos (Reportar incidente, Boletines, Cursos, Preguntas Frecuentes)
                        _buildAccesosRapidosSection(isDark),

                        const SizedBox(height: 16),

                        // 3. Tarjeta "Tu ayuda a bordo" con avatar 3D + buscador
                        _buildAyudaABordoCard(isDark),

                        const SizedBox(height: 16),

                        // 4. Preguntas Frecuentes (Acordeón interactivo idéntico a la captura)
                        _buildFaqSection(isDark),

                        const SizedBox(height: 16),

                        // 5. Tarjeta "Novedades oficiales" (Swagger /api/v1/announcements/)
                        _buildNovedadesCard(isDark),

                        const SizedBox(height: 16),

                        // 6. Tarjeta "Últimos boletines"
                        _buildBoletinesCard(isDark),

                        // Espacio inferior seguro para la barra de navegación de 4 módulos
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  // =========================================================================
  // FORMATTERS SEGUROS (SIN DATOS INVENTADOS)
  // =========================================================================
  /// Formatea el nombre del tripulante abreviando el nombre de pila a su inicial
  /// (ej: "Marenco Rubén Darío" -> "Marenco R.") evitando siempre puntos suspensivos ("...").
  String _formatCrewDisplayName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return "Tripulante";

    // Si viene con coma: "Marenco, Rubén" -> "Marenco R."
    if (trimmed.contains(',')) {
      final parts = trimmed.split(',');
      final apellido = parts[0].trim();
      final rest = parts.length > 1 ? parts[1].trim() : '';
      if (rest.isNotEmpty) {
        return "$apellido ${rest[0].toUpperCase()}.";
      }
      return apellido;
    }

    final tokens = trimmed.split(RegExp(r'\s+'));
    if (tokens.length <= 1) {
      return tokens.first;
    }

    // Prefijos de apellidos compuestos en español (ej: "De la Cruz Juan" -> "De la Cruz J.")
    int nameIndex = 1;
    final firstLower = tokens[0].toLowerCase();
    if ((firstLower == 'de' || firstLower == 'del' || firstLower == 'di' || firstLower == 'san' || firstLower == 'santa') && tokens.length > 2) {
      if (firstLower == 'de' && tokens[1].toLowerCase() == 'la' && tokens.length > 3) {
        nameIndex = 3;
      } else {
        nameIndex = 2;
      }
    }

    final apellido = tokens.sublist(0, nameIndex).join(' ');
    final nombre = tokens[nameIndex];

    if (nombre.isNotEmpty) {
      final initial = nombre[0].toUpperCase();
      return "$apellido $initial.";
    }

    return apellido;
  }

  String _formatDateShort(DateTime? dt) {
    if (dt == null) return "-";
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}";
  }

  String _formatRelevoDays(DateTime? endDate) {
    if (endDate == null) return "";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = target.difference(today).inDays;
    if (diff > 0) return "($diff días)";
    if (diff == 0) return "(Hoy)";
    return "";
  }

  // =========================================================================
  // 1. TARJETA DE PERFIL UNIFICADA (Foto/Ícono + Nombre + EMBARCADO | Ring)
  // =========================================================================
  Widget _buildProfileCard(bool isDark) {
    final p = _profile;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    // Datos reales sin inventar (solo datos reales de intranet o usuario activo)
    final currentUserName = SessionManager.shared.currentUser?.name;
    final String name = (p != null && p.name.trim().isNotEmpty)
        ? p.name
        : (currentUserName != null && currentUserName.trim().isNotEmpty
            ? currentUserName
            : "Tripulante");
    final bool isOnBoard = p?.isOnBoard ?? true;
    final int displayDays = p != null ? p.displayDays : 0;
    final String? shipName = p?.shipName;

    final Color badgeBg = isOnBoard ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final Color badgeBorder = isOnBoard ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A);
    final Color badgeDot = isOnBoard ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final Color badgeTextColor = isOnBoard ? const Color(0xFF16A34A) : const Color(0xFFB45309);
    final String badgeLabel = isOnBoard
        ? (shipName != null && shipName.isNotEmpty ? "• A BORDO • $shipName" : "• A BORDO •")
        : "• EN TIERRA •";

    // Columnas de datos reales (guion "-" si no están presentes)
    final String embarqueVal = _formatDateShort(p?.startDate);
    final String buqueVal = (shipName != null && shipName.trim().isNotEmpty) ? shipName : "-";
    final String cargoVal = (p != null && p.role.trim().isNotEmpty) ? p.role : "-";
    final String relevoDateVal = _formatDateShort(p?.endDate);
    final String relevoDaysVal = _formatRelevoDays(p?.endDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileView()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fila Superior: Avatar + Nombre + Badge + Anillo de Días
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ícono circular barco
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isOnBoard ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isOnBoard ? Icons.directions_boat_rounded : Icons.person_pin_circle_rounded,
                          color: isOnBoard ? const Color(0xFF007AFF) : const Color(0xFF64748B),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Saludo + Nombre + Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Hola,",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _formatCrewDisplayName(name),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: badgeBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: badgeDot,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      color: badgeTextColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Separador vertical sutil
                    Container(
                      width: 1,
                      height: 48,
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),

                    // Anillo de días con lógica verde/rojo
                    CrewDaysRingIndicator(
                      days: displayDays,
                      isOnBoard: isOnBoard,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Contenedor inferior: 4 Columnas (Embarque, Buque, Cargo, Próximo relevo)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        icon: Icons.calendar_today_outlined,
                        label: "Embarque",
                        value: embarqueVal,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        icon: Icons.anchor_rounded,
                        label: "Buque",
                        value: buqueVal,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        icon: Icons.person_outline_rounded,
                        label: "Cargo",
                        value: cargoVal,
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        icon: Icons.access_time_rounded,
                        label: "Próximo relevo",
                        value: relevoDateVal,
                        subValue: relevoDaysVal.isNotEmpty ? relevoDaysVal : null,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF007AFF)),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subValue != null)
          Text(
            subValue,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  // =========================================================================
  // 2. SECCIÓN "ACCESOS RÁPIDOS" (4 BOTONES IDENTICOS A LA CAPTURA)
  // =========================================================================
  Widget _buildAccesosRapidosSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Accesos rápidos",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () {
                Scaffold.of(context).openEndDrawer();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Ver todos",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF007AFF)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                title: "Reportar\nincidente",
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF059669),
                bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                borderColor: isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0),
                textColor: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                onTap: _openReportIncident,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                title: "\nBoletines",
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF2563EB),
                bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                borderColor: isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE),
                textColor: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF),
                onTap: _openBulletinsTab,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                title: "\nCursos",
                icon: Icons.school_outlined,
                iconColor: const Color(0xFF7C3AED),
                bgColor: isDark ? const Color(0xFF581C87).withValues(alpha: 0.3) : const Color(0xFFF5F3FF),
                borderColor: isDark ? const Color(0xFF6D28D9) : const Color(0xFFDDD6FE),
                textColor: isDark ? const Color(0xFFDDD6FE) : const Color(0xFF5B21B6),
                onTap: _openCursosTab,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                title: "Preguntas\nFrecuentes",
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB),
                borderColor: isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A),
                textColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                onTap: () => _navigateToFaqSearch(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 25),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. TARJETA "TU AYUDA A BORDO" (AVATAR 3D + BUSCADOR)
  // =========================================================================
  Widget _buildAyudaABordoCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila superior: Avatar 3D con auriculares + Título y descripción
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.memory(
                  ayudaAvatarBytes,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDBEAFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFF0066CC),
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tu ayuda a bordo",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Encontrá respuestas para tu día a día",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Buscador "¿Qué necesitás resolver? Buscá aquí..."
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white54 : const Color(0xFF0057B8),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _faqSearchController,
                    onSubmitted: (val) => _navigateToFaqSearch(val),
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: "¿Qué necesitás resolver? Buscá aquí...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _navigateToFaqSearch(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF0057B8),
                      size: 20,
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

  // =========================================================================
  // 4. SECCIÓN "PREGUNTAS FRECUENTES" (ACORDEÓN IDÉNTICO A LA CAPTURA)
  // =========================================================================
  Widget _buildFaqSection(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final catalogList = CrewFAQService.shared.currentCatalog;
    final faq1 = catalogList.firstWhere(
      (i) => i.id == "FAQ-SEG-01" || i.mainQuestion.toLowerCase().contains("accidente") || i.mainQuestion.toLowerCase().contains("incidente"),
      orElse: () => CrewFAQService.catalog[0],
    );

    final isExpanded = _expandedFaqIndex == 0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: PREGUNTAS FRECUENTES ... Ver todas >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PREGUNTAS FRECUENTES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              InkWell(
                onTap: () => _navigateToFaqSearch(),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "Ver todas",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF007AFF)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Acordeón destacado: ¿Cómo reporto un accidente o incidente a bordo?
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2B48) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBFDBFE),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedFaqIndex = isExpanded ? null : 0;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Círculo con escudo
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shield_outlined,
                              color: Color(0xFF007AFF),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            faq1.mainQuestion,
                            style: const TextStyle(
                              color: Color(0xFF0057B8),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF007AFF),
                          size: 24,
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      Text(
                        faq1.answerTemplate,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _openSeguridadTab,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Ver procedimiento completo",
                                style: TextStyle(
                                  color: Color(0xFF0057B8),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: Color(0xFF0057B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openNovedadesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrewNovedadesView()),
    );
  }

  Widget _buildNovedadesErrorCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 32, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
          const SizedBox(height: 10),
          Text(
            "No se pudieron cargar las novedades",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Verificá tu conexión al servidor para actualizar.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text("Reintentar", style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // C. TARJETA "NOVEDADES OFICIALES" (CARGADAS DESDE SWAGGER /api/v1/announcements/)
  // =========================================================================
  Widget _buildNovedadesCard(bool isDark) {
    if (_crewPostsError != null) {
      return _buildNovedadesErrorCard(isDark);
    }

    if (_crewPosts.isEmpty) {
      return const WelcomeNovedadesCard(margin: EdgeInsets.zero);
    }

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2B48) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF0066CC),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Novedades oficiales",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _openNovedadesScreen,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Ver todas",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066CC),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0066CC)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
                final post = _crewPosts.first;
                final dateStr = "${post.timestamp.day.toString().padLeft(2, '0')}/${post.timestamp.month.toString().padLeft(2, '0')}/${post.timestamp.year}";
                final bool hasImage = post.imageUrl != null && post.imageUrl!.trim().isNotEmpty;

                return InkWell(
                  onTap: () => _showPostDetailsDialog(post),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post.title.isNotEmpty ? post.title : "Comunicado de la compañía",
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 12, color: Color(0xFF007AFF)),
                            const SizedBox(width: 4),
                            Text(
                              post.authorName,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (hasImage) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              color: isDark ? Colors.black26 : const Color(0xFFEDF2F7),
                              child: Image.network(
                                post.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                        if (post.content.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            post.content,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showPostDetailsDialog(Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

  // =========================================================================
  // D. TARJETA "ÚLTIMOS BOLETINES"
  // =========================================================================
  Widget _buildBoletinesCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2B48) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.article_outlined,
                    color: Color(0xFF0066CC),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Últimos boletines",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _openBulletinsTab,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Ver todos",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066CC),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0066CC)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              (_latestBulletin != null && _bulletinError == null)
                  ? _latestBulletin!.title
                  : "Sin boletines nuevos por el momento.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// =========================================================================
// INDICADOR CIRCULAR CON REGLAS DE COLOR VERDE / ROJO SEGÚN EMBARQUE
// =========================================================================
class CrewDaysRingIndicator extends StatelessWidget {
  final int days;
  final bool isOnBoard;
  final bool isDark;

  const CrewDaysRingIndicator({
    super.key,
    required this.days,
    required this.isOnBoard,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // REGLAS ESPECÍFICAS SOLICITADAS:
    // 1. Embarcados: del día 1 al 30 en verde, y del 30 en adelante en rojo (hasta que baje).
    // 2. Desembarcados: del día 0 al 35 en verde, y luego en rojo (> 35).
    final Color progressColor;
    final double progress;

    if (isOnBoard) {
      if (days > 30) {
        progressColor = const Color(0xFFEF4444); // Rojo (excedido de 30 días)
        progress = 1.0;
      } else {
        progressColor = const Color(0xFF10B981); // Verde (1 a 30 días o inicio)
        progress = (days / 30.0).clamp(0.0, 1.0);
      }
    } else {
      if (days > 35) {
        progressColor = const Color(0xFFEF4444); // Rojo (excedido de 35 días en tierra)
        progress = 1.0;
      } else {
        progressColor = const Color(0xFF10B981); // Verde (0 a 35 días en tierra)
        progress = (days / 35.0).clamp(0.0, 1.0);
      }
    }

    final Color trackColor = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.5)
        : const Color(0xFFE2E8F0);
    final String subtext = isOnBoard ? "embarcado" : "en tierra";

    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(82, 82),
            painter: _CrewRingPainter(
              progress: progress,
              progressColor: progressColor,
              trackColor: trackColor,
              strokeWidth: 6.0,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$days",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                days == 1 ? "día" : "días",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrewRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  const _CrewRingPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circular de fondo
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Arco de progreso con punta redondeada
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -pi / 2; // Inicia a las 12 en punto
      final sweepAngle = 2 * pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CrewRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

