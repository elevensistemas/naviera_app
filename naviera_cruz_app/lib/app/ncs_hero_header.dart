import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ncs_header_data.dart';
import 'logo.dart';
import '../core/storage.dart';
import '../models/models.dart';
import '../modules/notifications/notifications_view.dart';
import '../modules/profile/profile_view.dart';
import '../modules/auth/login_view.dart';

/// Componente de cabecera edge-to-edge (sin bordes laterales ni superiores) 
/// para la app Naviera Cruz del Sur, diseñado para cubrir la parte superior del iPhone
/// bajo la barra de estado/Notch/Dynamic Island.
class NcsHeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool? showBackButton;
  final VoidCallback? onBackTap;
  final Uint8List? customCoverBytes;

  const NcsHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showBackButton,
    this.onBackTap,
    this.customCoverBytes,
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

    // Portada dinámica (NANY o ALFA C día/tarde/noche para tripulantes, o portada oficina)
    final String coverAsset = session.activeCoverAsset;
    final bool isDefaultAlfaC = coverAsset.contains('header_bg') || coverAsset.contains('alfa');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (DragEndDetails details) {
        // Deslizar horizontalmente para cambiar de portada en oficina entre Alfa C y Nany
        if (!session.isTripulanteMode) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -80) {
            // Desliza hacia la izquierda -> Siguiente portada (Alfa C <-> Nany)
            session.nextOfficeCover();
            _showCoverNotification(context, session.currentOfficeCoverName);
          } else if (velocity > 80) {
            // Desliza hacia la derecha -> Portada anterior (Alfa C <-> Nany)
            session.previousOfficeCover();
            _showCoverNotification(context, session.currentOfficeCoverName);
          }
        }
      },
      onDoubleTap: () {
        // Doble clic para cambiar de portada en oficina
        if (!session.isTripulanteMode) {
          session.cycleOfficeCover();
          _showCoverNotification(context, session.currentOfficeCoverName);
        }
      },
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
            // Imagen de fondo con cobertura total edge-to-edge anclada al centro-derecha y transición fluida
            Positioned.fill(
              child: customCoverBytes != null
                  ? Image.memory(
                      customCoverBytes!,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(
                        coverAsset,
                        key: ValueKey(coverAsset),
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.memory(
                            ncsHeaderImageBytes,
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
                          );
                        },
                      ),
                    ),
            ),

            // Gradiente de contraste en el lado izquierdo para resaltar el título y el logo
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF001228).withOpacity(0.82),
                      const Color(0xFF001F42).withOpacity(0.45),
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
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 550.0 : 1200.0),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 18.0 : 28.0,
                    statusBarHeight + (isMobile ? 6.0 : 12.0),
                    isMobile ? 18.0 : 28.0,
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
                              Builder(
                                builder: (ctx) {
                                  final route = ModalRoute.of(ctx);
                                  final bool canSafelyPop = route != null && route.canPop && !route.isFirst;
                                  final bool shouldShowBack = showBackButton ?? canSafelyPop;

                                  if (!shouldShowBack) return const SizedBox.shrink();

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _HeaderActionButton(
                                        icon: Icons.arrow_back_rounded,
                                        tooltip: 'Volver',
                                        onTap: () {
                                          if (onBackTap != null) {
                                            onBackTap!();
                                          } else if (Navigator.canPop(ctx) && !(route?.isFirst ?? false)) {
                                            Navigator.pop(ctx);
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  );
                                },
                              ),
                              // Si no es la imagen de Alfa C tradicional (que ya tiene el logo impreso en la esquina)
                              // O si tiene customCoverBytes, mostramos el logo corporativo oficial
                              if (!isDefaultAlfaC || customCoverBytes != null)
                                const NavieraLogo(
                                  size: 26,
                                  isWhiteVersion: true,
                                ),
                            ],
                          ),

                          // Botones de acción en la esquina derecha: Notificaciones + Modo Oscuro + Perfil
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
                                icon: session.isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                                iconColor: session.isDarkMode ? const Color(0xFFFFD166) : Colors.white,
                                tooltip: session.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
                                onTap: () {
                                  session.toggleTheme(!session.isDarkMode);
                                },
                              ),
                              const SizedBox(width: 8),

                              // 👤 Menú / Chip de Perfil
                              if (!isMobile && user != null && user.name.trim().isNotEmpty) ...[
                                _buildDesktopUserChip(context, user),
                                const SizedBox(width: 8),
                                _buildLogoutButton(context, false),
                              ] else ...[
                                Builder(
                                  builder: (ctx) => _HeaderActionButton(
                                    icon: Icons.person_rounded,
                                    avatarLetter: (user != null && user.name.trim().isNotEmpty)
                                        ? user.name.trim()[0].toUpperCase()
                                        : 'A',
                                    bgColor: const Color(0xFFE89B38).withOpacity(0.85),
                                    tooltip: 'Mi Perfil',
                                    onTap: () {
                                      Navigator.push(
                                        ctx,
                                        MaterialPageRoute(builder: (_) => const ProfileView()),
                                      );
                                    },
                                  ),
                                ),
                              ],
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
                            fontWeight: FontWeight.w800,
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
          ),
        ),

        // Control deslizador de portada interactivo para personal de oficina (Alfa C <-> Nany)
        if (!session.isTripulanteMode)
              Positioned(
                bottom: 8,
                right: isMobile ? 14 : 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          session.previousOfficeCover();
                          _showCoverNotification(context, session.currentOfficeCoverName);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(Icons.chevron_left_rounded, size: 16, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 2),
                      GestureDetector(
                        onTap: () {
                          session.toggleOfficeShipCover();
                          _showCoverNotification(context, session.currentOfficeCoverName);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              session.currentOfficeCoverName,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: () {
                          session.nextOfficeCover();
                          _showCoverNotification(context, session.currentOfficeCoverName);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCoverNotification(BuildContext context, String coverName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Portada: $coverName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF003D7A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDesktopUserChip(BuildContext context, User user) {
    final String letter = user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : 'U';
    return Tooltip(
      message: 'Ver Mi Perfil (${user.name})',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileView()));
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Tooltip(
        message: 'Cerrar Sesión',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.92),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.40),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Cerrar Sesión',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.90),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.40), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.logout_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  "Cerrar Sesión",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          "¿Estás seguro de que deseas salir de tu sesión?",
          style: TextStyle(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            key: const ValueKey('btn_confirm_logout'),
            icon: const Icon(Icons.logout_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await SessionManager.shared.logout();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
            label: const Text("Sí, Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? avatarLetter;
  final Color? bgColor;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    this.iconColor = Colors.white,
    this.avatarLetter,
    this.bgColor,
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
              color: bgColor ?? Colors.white.withOpacity(0.20),
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
