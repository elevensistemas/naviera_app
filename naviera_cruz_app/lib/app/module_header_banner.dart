import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'logo.dart';
import 'theme.dart';
import '../core/storage.dart';
import '../modules/notifications/notifications_view.dart';

class ModuleHeaderBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? backgroundImage;
  final bool showBackButton;
  final bool showLogo;
  final bool hideText;

  const ModuleHeaderBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.backgroundImage,
    this.showBackButton = false,
    this.showLogo = true,
    this.hideText = false,
  });

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionManager>(context);
    final bool hasUnread = session.hasUnreadNotifications;

    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          constraints: const BoxConstraints(
            minHeight: 145,
            maxHeight: 180,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: const LinearGradient(
              colors: [
                Color(0xFF002855), // Deep Naviera Navy
                Color(0xFF00509D), // Royal Brand Blue
                Color(0xFF023E8A), // Mid Sea Blue
                Color(0xFFD97706), // Warm Sunset Amber
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background image (if provided) with safe error fallback
                if (backgroundImage != null)
                  Positioned.fill(
                    child: Image.asset(
                      backgroundImage!,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),

                // Sunset background overlay glow
                if (backgroundImage == null)
                  Positioned(
                    right: -20,
                    top: -30,
                    bottom: -30,
                    child: Container(
                      width: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFF97316).withOpacity(0.45),
                            const Color(0xFFEA580C).withOpacity(0.1),
                            Colors.transparent,
                          ],
                          radius: 0.8,
                        ),
                      ),
                    ),
                  ),

                // Content Layout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top Row: Logo & Brand + Action Buttons (Bell & Menu)
                      Row(
                        children: [
                          if (showBackButton)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () => Navigator.maybePop(context),
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          if (showLogo)
                            const NavieraLogo(size: 30, isWhiteVersion: true),
                          const Spacer(),
                          // Notification Bell Button
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 22),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const NotificationsView()),
                                  );
                                },
                              ),
                              if (hasUnread)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: ColorTheme.accent, // Orange dot
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          // Hamburger Menu Button
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                            onPressed: () {
                              ScaffoldState? scaffoldState;
                              BuildContext? currentContext = context;
                              while (currentContext != null) {
                                scaffoldState = currentContext.findAncestorStateOfType<ScaffoldState>();
                                if (scaffoldState == null) break;
                                if (scaffoldState.widget.endDrawer != null) {
                                  scaffoldState.openEndDrawer();
                                  return;
                                }
                                BuildContext? parentContext;
                                scaffoldState.context.visitAncestorElements((element) {
                                  parentContext = element;
                                  return false;
                                });
                                currentContext = parentContext;
                              }
                              try {
                                Scaffold.of(context).openEndDrawer();
                              } catch (_) {}
                            },
                          ),
                        ],
                      ),
                      if (!hideText) ...[
                        const SizedBox(height: 12),

                        // Dynamic Module Title
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Text(
                            title,
                            key: ValueKey(title),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Dynamic Subtitle
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            subtitle,
                            key: ValueKey(subtitle),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
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

