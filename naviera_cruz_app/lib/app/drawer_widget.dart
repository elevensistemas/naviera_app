import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/storage.dart';
import 'theme.dart';
import '../modules/profile/profile_view.dart';
import '../modules/crew/crew_list_view.dart';

class NavieraDrawer extends StatelessWidget {
  const NavieraDrawer({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Cerrar Sesión"),
          content: const Text("¿Estás seguro que deseas desconectarte?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                Navigator.pop(context); // Close drawer
                await SessionManager.shared.logout();
              },
              child: const Text("Salir", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionManager>(context);
    final user = session.currentUser;
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with User Profile Details (App NCS - Pantalla 8 style)
            if (user != null)
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: ColorTheme.primary, // Fondo azul corporativo
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: (user.avatarURL != null && user.avatarURL!.isNotEmpty)
                          ? NetworkImage(user.avatarURL!)
                          : null,
                      child: (user.avatarURL != null && user.avatarURL!.isNotEmpty)
                          ? null
                          : Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.role,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.sector,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),

            // Navigation Items (App NCS - Pantalla 7 style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline_outlined, color: ColorTheme.primary),
                    title: const Text(
                      "Mi perfil",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileView()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  
                  ListTile(
                    leading: const Icon(Icons.people_alt_outlined, color: ColorTheme.primary),
                    title: const Text(
                      "Tripulación",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CrewListView()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),

                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: ColorTheme.primary),
                    title: const Text(
                      "Configuración",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileView()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),

                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined, color: ColorTheme.primary),
                    title: const Text(
                      "Modo oscuro",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    value: session.isDarkMode,
                    onChanged: (val) {
                      session.toggleTheme(val);
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                ],
              ),
            ),
            
            const Spacer(),

            // Logout Button at the bottom
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: ColorTheme.danger,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text(
                    "Cerrar sesión",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
