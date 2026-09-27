import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ncs_header_data.dart';
import '../core/storage.dart';
import '../modules/notifications/notifications_view.dart';
import '../modules/profile/profile_view.dart';

/// Componente de cabecera reutilizable para la app Naviera Cruz del Sur.
/// Carga la imagen del buque ALFA C y atardecer directamente en memoria
/// para garantizar visualización instantánea en Flutter Web sin depender del dev server asset manifest.
class NcsHeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const NcsHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  static const String assetPath = 'assets/images/header_bg.png';

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionManager>(context);
    final user = session.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final double headerHeight = isMobile ? 165.0 : (screenWidth * 0.16).clamp(160.0, 230.0);

    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: headerHeight,
          margin: EdgeInsets.fromLTRB(
            isMobile ? 14.0 : 16.0,
            isMobile ? 10.0 : 10.0,
            isMobile ? 14.0 : 16.0,
            6.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: const LinearGradient(
              colors: [
                Color(0xFF001A38), // Deep Naviera Navy
                Color(0xFF003D7A), // Royal Brand Blue
                Color(0xFF023E8A), // Mid Sea Blue
                Color(0xFFD97706), // Warm Sunset Amber
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Renderizado garantizado en memoria anclado arriba a la derecha para ver la marca completa y el barco ALFA C
                Positioned.fill(
                  child: Image.memory(
                    ncsHeaderImageBytes,
                    fit: BoxFit.cover,
                    alignment: Alignment.topRight,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.topRight,
                        errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),

                // Gradiente de legibilidad oscuro en el lado izquierdo para que el texto sea nítido y no tape el barco
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF001228).withOpacity(0.70),
                          const Color(0xFF001F42).withOpacity(0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),

                // Botones de acción rápida en la cabecera: Notificaciones (Campanita), Modo Oscuro/Claro y Perfil / Menú Lateral
                Positioned(
                  top: isMobile ? 10.0 : 12.0,
                  right: isMobile ? 10.0 : 14.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔔 Notificaciones (Campanita)
                      _HeaderActionButton(
                        icon: Icons.notifications_outlined,
                        tooltip: 'Notificaciones',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsView()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // 🌙 Conmutador rápido de Modo Oscuro / Claro
                      _HeaderActionButton(
                        icon: session.isDarkMode ? Icons.wb_sunny_rounded : Icons.dark_mode_outlined,
                        iconColor: session.isDarkMode ? const Color(0xFFFFD166) : Colors.white,
                        tooltip: session.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
                        onTap: () {
                          session.toggleTheme(!session.isDarkMode);
                        },
                      ),
                      const SizedBox(width: 8),

                      // 👤 Perfil del Usuario / Menú Lateral
                      _HeaderActionButton(
                        icon: Icons.person_outline_rounded,
                        avatarLetter: (user != null && user.name.trim().isNotEmpty)
                            ? user.name.trim()[0].toUpperCase()
                            : null,
                        tooltip: 'Perfil de Usuario y Menú',
                        onTap: () {
                          try {
                            Scaffold.of(context).openEndDrawer();
                          } catch (_) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileView()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Textos dinámicos superpuestos sobre el mar
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 18.0 : 22.0,
                    isMobile ? 56.0 : 50.0,
                    isMobile ? 18.0 : 22.0,
                    14.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Título dinámico del módulo
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          title,
                          key: ValueKey(title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 22 : 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Subtítulo dinámico del módulo
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          subtitle,
                          key: ValueKey(subtitle),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.96),
                            fontSize: isMobile ? 12.5 : 13.5,
                            fontWeight: FontWeight.w500,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? avatarLetter;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    this.iconColor = Colors.white,
    this.avatarLetter,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF00152A).withOpacity(0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.30),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: avatarLetter != null
                  ? Text(
                      avatarLetter!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(
                      icon,
                      color: iconColor,
                      size: 19,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

