import 'package:flutter/material.dart';
import 'logo.dart';
import 'theme.dart';

class NavieraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showBackButton;

  const NavieraAppBar({
    super.key,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorTheme.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: showBackButton ? 0.0 : 16.0,
      leading: showBackButton 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: const NavieraLogo(
        size: 32,
        isWhiteVersion: true,
      ),
      actions: actions ?? [
        // Bell icon with orange dot
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 26),
              onPressed: () {},
            ),
            Positioned(
              right: 12,
              top: 12,
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
        // Hamburger menu
        if (!showBackButton)
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 26),
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
              // Fallback
              try {
                Scaffold.of(context).openEndDrawer();
              } catch (_) {}
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
