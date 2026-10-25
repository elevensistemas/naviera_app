import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/storage.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../models/intranet_crew_catalog.dart';
import '../auth/login_view.dart';

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
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Eliminar Cuenta", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            "¿Estás completamente seguro de que deseas eliminar tu cuenta? Esta acción borrará de forma permanente todos tus datos personales y es irreversible.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _deleteAccount();
              },
              child: const Text("Eliminar definitivamente", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
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
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: ColorTheme.danger, size: 24),
              SizedBox(width: 10),
              Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("¿Estás seguro que deseas desconectarte de tu cuenta?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorTheme.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await SessionManager.shared.logout();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                }
              },
              child: const Text("Cerrar sesión", style: TextStyle(fontWeight: FontWeight.bold)),
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
    final isDark = session.isDarkMode;
    final isTripulante = session.isTripulanteMode;

    final bgColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final crewMember = isTripulante
        ? (IntranetCrewCatalog.findCrewMember(user?.name ?? '') ??
            IntranetCrewCatalog.findCrewMember(user?.id ?? '') ??
            IntranetCrewCatalog.findCrewMember('Marenco'))
        : null;

    final String displayName = (user?.name ?? '').trim().isNotEmpty
        ? user!.name.trim()
        : (crewMember?.name ?? (isTripulante ? 'Marenco Rubén Darío' : 'Alejandro Lo Presti'));
    final String displayRole = (user?.role ?? '').trim().isNotEmpty
        ? user!.role.trim()
        : (crewMember?.roleName ?? (isTripulante ? 'Capitán' : 'Gerencia General'));
    final String displaySector = (user?.sector ?? '').trim().isNotEmpty
        ? user!.sector.trim()
        : (crewMember != null
            ? (crewMember.isOnBoard ? 'Buque ${crewMember.shipName}' : 'En Tierra')
            : (isTripulante ? 'Buque ALFA C' : 'Gerencia'));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF001F3F) : const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Mi Perfil",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Tarjeta Principal de Usuario
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar circular con iniciales o foto
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066CC), Color(0xFF0099FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066CC).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: (user?.avatarURL != null && user!.avatarURL!.isNotEmpty)
                                ? ClipOval(
                                    child: Image.network(
                                      user.avatarURL!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => _buildAvatarLetter(displayName),
                                    ),
                                  )
                                : _buildAvatarLetter(displayName),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Nombre de usuario
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Cargo y Sector
                        Text(
                          "$displayRole • $displaySector",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Badge distintivo de tipo de usuario
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isTripulante
                                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                                : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isTripulante
                                  ? (isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC))
                                  : (isDark ? const Color(0xFF2563EB) : const Color(0xFF93C5FD)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isTripulante ? Icons.directions_boat_rounded : Icons.business_rounded,
                                size: 14,
                                color: isTripulante
                                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
                                    : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF0066CC)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isTripulante ? "PERSONAL DE BUQUE / FLOTA" : "PERSONAL DE OFICINA / GERENCIA",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: isTripulante
                                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
                                      : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF0066CC)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1.1 Sección Situación Oficial de Intranet (para tripulantes)
                  if (crewMember != null) ...[
                    const SizedBox(height: 18),
                    _buildSectionHeader("SITUACIÓN OFICIAL EN INTRANET", secondaryTextColor),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: crewMember.isOnBoard ? Icons.directions_boat_rounded : Icons.home_work_rounded,
                            label: "Situación de Dotación",
                            value: crewMember.isOnBoard
                                ? "A BORDO • ${crewMember.shipName ?? 'Buque'}"
                                : "EN TIERRA (Desembarcado)",
                            valueColor: crewMember.isOnBoard ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            isDark: isDark,
                          ),
                          Divider(height: 20, color: borderColor),
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: crewMember.isOnBoard ? "Días Embarcado (Intranet)" : "Días en Tierra (Intranet)",
                            value: "${crewMember.days} ${crewMember.days == 1 ? 'día' : 'días'}",
                            valueColor: const Color(0xFF0066CC),
                            isDark: isDark,
                          ),
                          Divider(height: 20, color: borderColor),
                          _buildDetailRow(
                            icon: Icons.badge_rounded,
                            label: "Rol en Dotación",
                            value: "${crewMember.roleName} (${crewMember.roleCode})",
                            valueColor: primaryTextColor,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 2. Sección: Preferencias
                  _buildSectionHeader("PREFERENCIAS Y CONFIGURACIÓN", secondaryTextColor),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: isDark ? const Color(0xFFFFD166) : const Color(0xFF0066CC),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            "Modo Oscuro",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
                          ),
                          subtitle: Text(
                            isDark ? "Tema nocturno activado" : "Tema claro corporativo",
                            style: TextStyle(fontSize: 12, color: secondaryTextColor),
                          ),
                          value: session.isDarkMode,
                          onChanged: (val) {
                            session.toggleTheme(val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Sección: Información y Privacidad
                  _buildSectionHeader("INFORMACIÓN LEGAL Y PRIVACIDAD", secondaryTextColor),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF0066CC), size: 20),
                          ),
                          title: Text(
                            "Política de Privacidad",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                          onTap: () => _openUrl("https://www.navieracruz.cl/privacy-policy/"),
                        ),
                        Divider(height: 1, indent: 64, color: borderColor),
                        ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.gavel_outlined, color: Color(0xFF0066CC), size: 20),
                          ),
                          title: Text(
                            "Términos de Uso (EULA)",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                          onTap: () => _openUrl("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Botón de Cerrar Sesión
                  Material(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _confirmLogout(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: ColorTheme.danger,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Cerrar Sesión",
                                    style: TextStyle(
                                      color: ColorTheme.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Desconectarte y salir al ingreso principal",
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: ColorTheme.danger, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Eliminar cuenta
                  Center(
                    child: TextButton.icon(
                      onPressed: _isDeletingAccount ? null : () => _confirmDeleteAccount(context),
                      icon: _isDeletingAccount
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 16),
                      label: const Text(
                        "Eliminar mi cuenta",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),

                  if (_deleteErrorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _deleteErrorMessage!,
                      style: const TextStyle(color: ColorTheme.danger, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarLetter(String name) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    return Text(
      letter,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: valueColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
