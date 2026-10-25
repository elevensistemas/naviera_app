import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage.dart';
import '../../models/crew_profile.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../services/crew_profile_service.dart';
import '../../app/ncs_hero_header.dart';
import '../../app/ncs_header_data.dart';
import '../bulletins/bulletins_view.dart';
import '../profile/profile_view.dart';
import 'crew_faq_search_view.dart';
import 'crew_novedades_view.dart';
import '../../services/crew_faq_service.dart';
import '../../app/ayuda_avatar_data.dart';

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
    });

    final currentUser = SessionManager.shared.currentUser;

    try {
      // 1. Cargar perfil de tripulante desde la API de la intranet
      final profile = await _profileService.fetchCurrentCrewProfile(currentUser: currentUser);

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
      try {
        final posts = await HomeService().fetchPosts();
        crewPosts = posts.where((p) => p.isForCrew).toList();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _profile = profile;
          _latestBulletin = latestBulletin;
          _bulletinError = bulletinErr;
          _crewPosts = crewPosts;
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
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.amber.withOpacity(0.4)),
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

                        // A. Tarjeta de Perfil Unificada (Hola, Rubén Marenco | 20 días embarcado)
                        _buildProfileCard(isDark),

                        const SizedBox(height: 16),

                        // B. Tarjeta "Tu ayuda a bordo" con avatar 3D + buscador + FAQs
                        _buildAyudaABordoCard(isDark),

                        const SizedBox(height: 16),

                        // C. Tarjeta "Novedades oficiales" (Swagger /api/v1/announcements/)
                        _buildNovedadesCard(isDark),

                        const SizedBox(height: 16),

                        // D. Tarjeta "Últimos boletines"
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
  // A. TARJETA DE PERFIL UNIFICADA (Foto/Ícono + Nombre + EMBARCADO | Días)
  // =========================================================================
  Widget _buildProfileCard(bool isDark) {
    final p = _profile;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final String name = p?.name ?? SessionManager.shared.currentUser?.name ?? "Rubén Marenco";
    final bool isOnBoard = p?.isOnBoard ?? true;
    final int displayDays = p != null ? p.displayDays : 23;
    final String? shipName = p?.shipName;

    final Color badgeBg = isOnBoard ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final Color badgeBorder = isOnBoard ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A);
    final Color badgeDot = isOnBoard ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final Color badgeTextColor = isOnBoard ? const Color(0xFF16A34A) : const Color(0xFFB45309);
    final String badgeLabel = isOnBoard
        ? (shipName != null && shipName.isNotEmpty ? "A BORDO • $shipName" : "EMBARCADO")
        : "EN TIERRA";
    final String daysSubtext = isOnBoard ? "embarcado" : "en tierra";

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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          // Ícono/Avatar circular celeste claro con ícono azul
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
          const SizedBox(width: 14),

          // Columna central: Saludo + Nombre + Badge dinámico (A BORDO / EN TIERRA)
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
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
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
            height: 42,
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          // Columna derecha: Número grande de días + etiqueta
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "$displayDays",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isOnBoard ? const Color(0xFF0066CC) : const Color(0xFFD97706),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayDays == 1 ? "día" : "días",
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    daysSubtext,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
}

  // =========================================================================
  // B. TARJETA "TU AYUDA A BORDO" (Avatar 3D + Buscador + Preguntas Frecuentes)
  // =========================================================================
  Widget _buildAyudaABordoCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final catalogList = CrewFAQService.shared.currentCatalog;
    final faq1 = catalogList.firstWhere(
      (i) => i.id == "FAQ-SEG-01" || i.mainQuestion.contains("accidente"),
      orElse: () => CrewFAQService.catalog[0],
    );
    final faq2 = catalogList.firstWhere(
      (i) => i.id == "FAQ-EME-10" || i.mainQuestion.contains("alarma"),
      orElse: () => CrewFAQService.catalog[9],
    );
    final faq3 = catalogList.firstWhere(
      (i) => i.id == "FAQ-APP-46" || i.mainQuestion.contains("boletines"),
      orElse: () => CrewFAQService.catalog[45],
    );
    final faq4 = catalogList.firstWhere(
      (i) => i.id == "FAQ-CIB-54" || i.mainQuestion.contains("contraseña"),
      orElse: () => CrewFAQService.catalog[53],
    );

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
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
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
                borderRadius: BorderRadius.circular(35),
                child: Image.memory(
                  ayudaAvatarBytes,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDBEAFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFF0066CC),
                      size: 36,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
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

          // Buscador "¿Qué necesitás resolver?"
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
                      hintText: "¿Qué necesitás resolver? Buscar preguntas...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        fontSize: 14,
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

          const SizedBox(height: 18),

          // Encabezado PREGUNTAS FRECUENTES
          Text(
            "PREGUNTAS FRECUENTES",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 10),

          // Acordeón 1: Seguridad / Incidentes (Azul claro, expandido por defecto)
          _buildFaqItem(
            index: 0,
            question: faq1.mainQuestion,
            answer: faq1.answerTemplate,
            linkText: "Ir a Seguridad",
            onLinkTap: _openSeguridadTab,
            icon: Icons.shield_outlined,
            isBlue: true,
            isDark: isDark,
          ),

          // Acordeón 2: Emergencias / Alarma (Naranja cálido)
          _buildFaqItem(
            index: 1,
            question: faq2.mainQuestion,
            answer: faq2.answerTemplate,
            linkText: "Ver Zafarranchos",
            onLinkTap: () => _navigateToFaqSearch(faq2.mainQuestion),
            icon: Icons.warning_amber_rounded,
            isBlue: false,
            isDark: isDark,
          ),

          // Acordeón 3: Boletines (Azul claro)
          _buildFaqItem(
            index: 2,
            question: faq3.mainQuestion,
            answer: faq3.answerTemplate,
            linkText: "Ver Boletines",
            onLinkTap: _openBulletinsTab,
            icon: Icons.description_outlined,
            isBlue: true,
            isDark: isDark,
          ),

          // Acordeón 4: Ciberseguridad / Acceso (Naranja cálido)
          _buildFaqItem(
            index: 3,
            question: faq4.mainQuestion,
            answer: faq4.answerTemplate,
            linkText: "Ver Ciberseguridad",
            onLinkTap: () => _navigateToFaqSearch(faq4.mainQuestion),
            icon: Icons.security_rounded,
            isBlue: false,
            isDark: isDark,
          ),

          // Botón para acceder al catálogo completo de preguntas frecuentes predefinidas
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToFaqSearch(),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: Text(
                "Ver catálogo completo de preguntas frecuentes (${catalogList.length})",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0057B8),
                side: BorderSide(
                  color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFF93C5FD),
                  width: 1.2,
                ),
                backgroundColor: isDark ? const Color(0xFF0F2B48).withOpacity(0.5) : const Color(0xFFF0F7FF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Elemento del Acordeón con estilos exactos a la captura
  // =========================================================================
  Widget _buildFaqItem({
    required int index,
    required String question,
    required String answer,
    required IconData icon,
    required bool isBlue,
    String? linkText,
    VoidCallback? onLinkTap,
    required bool isDark,
  }) {
    final isExpanded = _expandedFaqIndex == index;
    final bgColor = isBlue
        ? (isDark ? const Color(0xFF0F2B48) : const Color(0xFFF0F7FF))
        : (isDark ? const Color(0xFF332014) : const Color(0xFFFFF7ED));
    final borderColor = isBlue
        ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD0E4FF))
        : (isDark ? const Color(0xFF5A351D) : const Color(0xFFFFEDD5));
    final primaryColor = isBlue ? const Color(0xFF0057B8) : const Color(0xFFC2410C);
    final iconColor = isBlue ? const Color(0xFF0066CC) : const Color(0xFFEA580C);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedFaqIndex = isExpanded ? null : index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                Text(
                  answer,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (linkText != null && onLinkTap != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onLinkTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          linkText,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 16, color: primaryColor),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openNovedadesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrewNovedadesView()),
    );
  }

  // =========================================================================
  // C. TARJETA "NOVEDADES OFICIALES" (CARGADAS DESDE SWAGGER /api/v1/announcements/)
  // =========================================================================
  Widget _buildNovedadesCard(bool isDark) {
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
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
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
          if (_crewPosts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 28, color: Color(0xFF0066CC)),
                  const SizedBox(height: 8),
                  Text(
                    "Sin novedades pendientes",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Esperando nuevos comunicados oficiales de la compañía.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else ...[
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
          ],
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
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
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
