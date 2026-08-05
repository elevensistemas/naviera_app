import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/storage.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../finance/finance_view.dart';
import '../stats/stats_view.dart';
import '../crew/crew_list_view.dart';
import '../incidents/incident_list_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isDeletingAccount = false;
  String? _deleteErrorMessage;

  void _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Eliminar Cuenta"),
          content: const Text(
              "¿Estás completamente seguro de que deseas eliminar tu cuenta? Esta acción borrará de forma permanente todos tus datos personales y es irreversible."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount();
              },
              child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
      _deleteErrorMessage = null;
    });

    try {
      final authService = AuthService();
      await authService.deleteAccount();
      await SessionManager.shared.logout();
    } catch (e) {
      setState(() {
        _deleteErrorMessage = "No se pudo eliminar la cuenta: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cerrar Sesión"),
          content: const Text("¿Estás seguro que deseas desconectarte?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mi Perfil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          // User card
          if (user != null)
            Container(
              padding: const EdgeInsets.all(20.0),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: ColorTheme.primary,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TypographyTheme.title2(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.role,
                          style: TypographyTheme.body(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sector: ${user.sector}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: ColorTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),

          // Configuración General
          _buildSectionHeader("Configuración General"),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode, color: Colors.blueGrey),
                  title: const Text("Modo Oscuro"),
                  value: session.isDarkMode,
                  onChanged: (val) {
                    session.toggleTheme(val);
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.pie_chart, color: Colors.purple),
                  title: const Text("Módulo Contable (Gerencial)"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FinanceView()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.indigo),
                  title: const Text("Estadísticas Operativas"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatsView()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.people_alt, color: Colors.teal),
                  title: const Text("Tripulación Actual"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CrewListView()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.warning, color: ColorTheme.danger),
                  title: const Text("Incidentes HSE"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IncidentListView()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Privacidad
          _buildSectionHeader("Privacidad"),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.grey),
                  title: const Text("Política de Privacidad"),
                  onTap: () => _openUrl("https://www.navieracruz.cl/privacy-policy/"),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.gavel, color: Colors.grey),
                  title: const Text("Términos de Uso (EULA)"),
                  onTap: () => _openUrl("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: _isDeletingAccount
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_forever, color: ColorTheme.danger),
                  title: const Text(
                    "Eliminar mi Cuenta",
                    style: TextStyle(color: ColorTheme.danger),
                  ),
                  onTap: _isDeletingAccount ? null : () => _confirmDeleteAccount(context),
                ),
              ],
            ),
          ),
          
          if (_deleteErrorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                _deleteErrorMessage!,
                style: const TextStyle(color: ColorTheme.danger, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorTheme.danger.withOpacity(0.1),
                foregroundColor: ColorTheme.danger,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.exit_to_app),
              label: const Text(
                "Cerrar Sesión",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
