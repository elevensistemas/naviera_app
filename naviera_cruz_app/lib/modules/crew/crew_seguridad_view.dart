import 'package:flutter/material.dart';
import '../../services/ncs_chat_policy.dart';
import '../../services/services.dart';
import '../../services/crew_profile_service.dart';
import '../../models/models.dart';
import '../../models/crew_profile.dart';
import '../../core/storage.dart';
import '../../app/ncs_hero_header.dart';
import '../incidents/report_incident_view.dart';
import '../incidents/incident_list_view.dart';

class CrewSeguridadView extends StatefulWidget {
  const CrewSeguridadView({super.key});

  @override
  State<CrewSeguridadView> createState() => _CrewSeguridadViewState();
}

class _CrewSeguridadViewState extends State<CrewSeguridadView> {
  final IncidentService _incidentService = IncidentService();
  final CrewProfileService _profileService = ProductionCrewProfileService();

  CrewProfile? _profile;
  List<Incident> _incidents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = SessionManager.shared.currentUser;
      final profile = await _profileService.fetchCurrentCrewProfile(currentUser: user);
      final allIncidents = await _incidentService.fetchIncidents();

      // Filtrar incidentes del buque del tripulante si está asignado
      List<Incident> relevantIncidents = allIncidents;
      final assignedShip = profile.shipName?.toUpperCase();
      if (profile.shipId != null && profile.shipId!.isNotEmpty) {
        relevantIncidents = allIncidents.where((inc) {
          return inc.shipId == profile.shipId ||
              (assignedShip != null && inc.shipName.toUpperCase() == assignedShip);
        }).toList();
        if (relevantIncidents.isEmpty) {
          relevantIncidents = allIncidents;
        }
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _incidents = relevantIncidents;
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

  void _openReportIncident() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportIncidentView(
          onIncidentReported: () {
            _loadData();
          },
        ),
      ),
    );
  }

  void _openProcedureDetails(NCSManagementProcedure proc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0057B8).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0057B8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proc.code,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0057B8),
                          ),
                        ),
                        Text(
                          proc.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow("Sección:", proc.section),
              const SizedBox(height: 6),
              _buildDetailRow("Vigencia:", proc.version),
              const SizedBox(height: 12),
              const Text(
                "Instrucción Operativa Oficial:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  proc.instruction,
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Toda maniobra a bordo debe ajustarse a la orden directa del Oficial de Guardia y Capitanía.",
                        style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0057B8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Cerrar Documento", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF0057B8),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera Hero Edge-to-Edge
              NcsHeroHeader(
                title: "Seguridad y Gestión",
                subtitle: "Prevención, reportes y procedimientos oficiales",
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================================================
                    // 1. ACCESO DESTACADO A "REPORTAR INCIDENTE"
                    // =========================================================
                    _buildProminentReportButton(isDark),

                    const SizedBox(height: 24),

                    // =========================================================
                    // 2. ACCESO AL MANUAL DE GESTIÓN (SGI)
                    // =========================================================
                    _buildManualSection(isDark),

                    const SizedBox(height: 24),

                    // =========================================================
                    // 3. REGISTRO DE INCIDENTES RECIENTES A BORDO
                    // =========================================================
                    _buildRecentIncidentsSection(isDark),

                    SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProminentReportButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00224A),
            Color(0xFF0057B8),
            Color(0xFF007AFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0057B8).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openReportIncident,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Reportar Incidente",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Condición insegura, acto inseguro o casi accidente a bordo (MG-21)",
                        style: TextStyle(
                          color: Color(0xFFBAE6FD),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualSection(bool isDark) {
    final procs = NCSCorporateChatPolicy.managementProcedures;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Manual de Gestión (SGI)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Rev. 2026 Vigente",
                style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...procs.map((proc) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0057B8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF0057B8), size: 22),
                ),
                title: Text(
                  proc.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "${proc.code} • ${proc.section}",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF007AFF)),
                onTap: () => _openProcedureDetails(proc),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentIncidentsSection(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Incidentes a Bordo (${_profile?.shipName ?? 'Flota NCS'})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IncidentListView()),
                );
              },
              child: const Text("Ver todos >", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF007AFF))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Error al sincronizar incidentes: $_errorMessage",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                TextButton(onPressed: _loadData, child: const Text("Reintentar")),
              ],
            ),
          )
        else if (_incidents.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "Sin incidentes activos registrados para tu buque.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ..._incidents.take(3).map((inc) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0057B8).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inc.code,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0057B8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        inc.shipName.isNotEmpty ? inc.shipName : "Buque",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const Spacer(),
                      Text(
                        "${inc.date.day.toString().padLeft(2, '0')}/${inc.date.month.toString().padLeft(2, '0')}/${inc.date.year}",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    inc.title.isNotEmpty ? inc.title : inc.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
