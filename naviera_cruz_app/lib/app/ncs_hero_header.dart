import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ncs_header_data.dart';
import '../core/storage.dart';
import '../modules/notifications/notifications_view.dart';
import '../modules/profile/profile_view.dart';

/// Componente de cabecera edge-to-edge (sin bordes laterales ni superiores) 
/// para la app Naviera Cruz del Sur, diseñado para cubrir la parte superior del iPhone
/// bajo la barra de estado/Notch/Dynamic Island.
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

    // Inset superior para la barra de estado (Notch / Dynamic Island en iOS)
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double contentHeight = isMobile ? 150.0 : 165.0;
    final double totalHeaderHeight = statusBarHeight + contentHeight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: totalHeaderHeight,
        margin: EdgeInsets.zero, // Cobertura total sin márgenes externos
        decoration: const BoxDecoration(
          gradient: LinearGradient(
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
        child: Stack(
          children: [
            // Imagen de fondo en memoria anclada arriba a la derecha (cobertura total edge-to-edge)
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

            // Gradiente de contraste en el lado izquierdo para resaltar el título y el logo
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF001228).withOpacity(0.78),
                      const Color(0xFF001F42).withOpacity(0.40),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Contenido dinámico iniciando justo DEBAJO de la barra de estado del dispositivo
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 18.0 : 24.0,
                statusBarHeight + (isMobile ? 6.0 : 10.0),
                isMobile ? 18.0 : 24.0,
                14.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Fila Superior: Logo / Flecha de retorno + Botones de acción rápida
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (Navigator.canPop(context)) ...[
                            _HeaderActionButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Volver',
                              onTap: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 10),
                          ],
                          _buildNcsLogo(),
                        ],
                      ),

                      // Botones de acción en la esquina derecha: Notificaciones (Campanita con indicador rojo) + Menú
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔔 Campanita con punto rojo distintivo
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
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
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 8.5,
                                  height: 8.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444), // Red dot
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.2),
                                  ),
                                ),
                              ),
                            ],
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

                          // ☰ Menú Hamburguesa / Perfil
                          _HeaderActionButton(
                            icon: Icons.menu_rounded,
                            avatarLetter: (user != null && user.name.trim().isNotEmpty)
                                ? user.name.trim()[0].toUpperCase()
                                : null,
                            tooltip: 'Menú Lateral',
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
                    ],
                  ),

                  // Fila Inferior: Título principal y subtítulo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: Text(
                          title,
                          key: ValueKey(title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 23.0 : 26.0,
                            fontWeight: FontWeight.extrabold,
                            letterSpacing: -0.5,
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
                      const SizedBox(height: 3),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: Text(
                          subtitle,
                          key: ValueKey(subtitle),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: isMobile ? 12.0 : 13.0,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el logo corporativo de Naviera Cruz del Sur (Matriz de puntos + texto)
  Widget _buildNcsLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (r) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (c) {
                  final bool isFilled = (r == 0 && c == 2) || (r == 3 && c == 0);
                  return Container(
                    width: 4.5,
                    height: 4.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? Colors.white : Colors.transparent,
                      border: Border.all(color: Colors.white, width: 1.0),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "NAVIERA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                height: 1.0,
              ),
            ),
            Text(
              "CRUZ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                height: 1.0,
              ),
            ),
            Text(
              "DEL",
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                height: 1.0,
              ),
            ),
            Text(
              "SUR",
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
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
              color: Colors.white.withOpacity(0.20),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.0,
              ),
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
