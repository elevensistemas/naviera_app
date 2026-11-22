import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/vessel_health_model.dart';
import '../../services/vessel_health_service.dart';
import '../../app/ncs_hero_header.dart';

class VesselHealthView extends StatefulWidget {
  final bool isTabModule;
  final String? initialVessel;

  const VesselHealthView({
    super.key,
    this.isTabModule = false,
    this.initialVessel,
  });

  @override
  State<VesselHealthView> createState() => _VesselHealthViewState();
}

class _VesselHealthViewState extends State<VesselHealthView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Buques habilitados en Salud del Buque (Regla: Monarca excluido)
  final List<String> _vessels = ['ALFA C', 'GUSTAVO U', 'NANY'];
  late String _selectedVessel;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isOfflineSnapshot = false;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? const Color(0xFF07101D) : const Color(0xFFF8FAFC);
  Color get _cardBg => _isDark ? const Color(0xFF0D1829) : Colors.white;
  Color get _cardBorder => _isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _textSecondary => _isDark ? Colors.white70 : const Color(0xFF64748B);
  Color get _textTertiary => _isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF94A3B8);

  VesselHealthResponse? _consolidated;
  VesselHealthDetail? _detail;

  Timer? _pollingTimer;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _selectedVessel = widget.initialVessel != null && _vessels.contains(widget.initialVessel)
        ? widget.initialVessel!
        : 'ALFA C';

    // 1. Fetch inmediato al montar con revalidación forzada (cache: 'no-store')
    _loadAll(forceRefresh: true);

    // 2. Polling liviano cada 60 segundos mientras la pantalla esté activa
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _animController.dispose();
    super.dispose();
  }

  /// 3. Revalidación inmediata al volver a primer plano (resumed)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("[VesselHealthView] App resumed: revalidando Salud del Buque...");
      _loadAll(forceRefresh: true);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        debugPrint("[VesselHealthView] Polling periódico (60s) en ejecución...");
        _loadDetailOnly(forceRefresh: true, silent: true);
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Carga inicial y cambio de buque
  Future<void> _loadAll({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final consolidatedFuture = VesselHealthService.shared.fetchConsolidated(forceRefresh: forceRefresh);
      final detailFuture = VesselHealthService.shared.fetchDetail(_selectedVessel, forceRefresh: forceRefresh);

      final results = await Future.wait([consolidatedFuture, detailFuture]);
      final cons = results[0] as VesselHealthResponse?;
      final det = results[1] as VesselHealthDetail?;

      VesselHealthDetail? effectiveDetail = det;
      if (effectiveDetail == null && cons != null && cons.vessels.isNotEmpty) {
        try {
          final card = cons.vessels.firstWhere(
            (c) => c.vesselName.toUpperCase() == _selectedVessel.toUpperCase() ||
                   c.vesselId.toUpperCase().contains(_selectedVessel.toUpperCase().replaceAll(' ', '')),
          );
          effectiveDetail = VesselHealthDetail(
            status: cons.status,
            readOnly: cons.readOnly,
            serverTime: cons.serverTime,
            card: card,
            certificates: [],
            maintenanceTasks: MaintenanceTasksSummary(
              criticalOverdue: [],
              normalOverdue: [],
              warning: [],
              dock: [],
            ),
            crew: [],
            scoringEvents: [],
          );
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _consolidated = cons;
          _detail = effectiveDetail;
          _isLoading = false;
          _isOfflineSnapshot = (cons == null && det == null);
        });
        _animController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        final cached = VesselHealthService.shared.getCachedDetail(_selectedVessel);
        setState(() {
          _detail = cached;
          _isLoading = false;
          _isOfflineSnapshot = true;
          if (cached == null) {
            _errorMessage = "No se pudo conectar con Centinela. Verifique la conexión.";
          }
        });
      }
    }
  }

  /// Carga o revalidación puntual del detalle
  Future<void> _loadDetailOnly({bool forceRefresh = false, bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final det = await VesselHealthService.shared.fetchDetail(_selectedVessel, forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _detail = det;
          _isLoading = false;
          _isOfflineSnapshot = det == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOfflineSnapshot = true;
        });
      }
    }
  }

  void _onVesselSelected(String vesselName) {
    if (_selectedVessel == vesselName) return;
    HapticFeedback.selectionClick();

    setState(() {
      _selectedVessel = vesselName;
      _isLoading = true;
    });

    _animController.forward(from: 0.0);
    _loadDetailOnly(forceRefresh: false);
  }

  Color _parseColor(String? hexStr, Color fallback) {
    if (hexStr == null || hexStr.isEmpty) return fallback;
    try {
      final clean = hexStr.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final bgNaval = _bg;

    return Scaffold(
      backgroundColor: bgNaval,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              NcsHeroHeader(
                title: "Salud del Buque",
                subtitle: "Health Score e indicadores operacionales Centinela",
                showBackButton: widget.isTabModule ? false : null,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF10B981),
                  backgroundColor: _cardBg,
                  onRefresh: () => _loadAll(forceRefresh: true),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildVesselSelector(),
                          if (_isOfflineSnapshot) ...[
                            const SizedBox(height: 10),
                            _buildOfflineBanner(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_isLoading && _detail == null)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF10B981)),
                            SizedBox(height: 16),
                            Text(
                              "Consultando Salud del Buque en Centinela...",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_errorMessage != null && _detail == null)
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_outlined, color: Color(0xFFFF5A5F), size: 54),
                              const SizedBox(height: 14),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007AFF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _loadAll(forceRefresh: true),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text("Reintentar conexión"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_detail != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMainScoreCard(_detail!.card),
                            const SizedBox(height: 14),
                            _buildQuickKpiGrid(_detail!),
                            const SizedBox(height: 14),
                            _buildPillarsCard(_detail!.card),
                            const SizedBox(height: 14),
                            _buildMaradParityCard(_detail!.card.maradParity),
                            const SizedBox(height: 14),
                            _buildPrioritiesSection(_detail!),
                            const SizedBox(height: 18),
                            _buildTraceabilityFooter(_detail!.card.sourcesSync, _detail!.card.calculatedAt),
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  /// Banner offline cuando no hay red (Resiliencia sin pisar con ceros)
  Widget _buildOfflineBanner() {
    final savedTime = VesselHealthService.shared.getLastSavedTime(_selectedVessel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              savedTime != null
                  ? "Sin conexión — Última lectura: $savedTime"
                  : "Sin conexión — Mostrando último estado confirmado.",
              style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Selector ágil superior con transición instantánea
  Widget _buildVesselSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: _vessels.map((vName) {
          final isSelected = _selectedVessel == vName;
          int? quickScore;
          Color? quickColor;

          if (_consolidated != null) {
            final card = _consolidated!.vessels.firstWhere(
              (c) => c.vesselName.toUpperCase() == vName.toUpperCase(),
              orElse: () => VesselHealthCard(
                vesselId: '',
                vesselName: '',
                imo: '',
                healthScoreFinal: 0,
                healthScoreBase: 0,
                scoreTone: 'green',
                colorHex: '#10b981',
                operationalStatus: '',
                operationalRestrictionReason: '',
                appliedCap: '',
                headline: '',
                deltaScore: 0,
                calculatedAt: '',
                pillars: HealthPillars(operacion: 0, disponibilidad: 0, seguridad: 0, preparacion: 0),
                kpis: HealthKpis(
                  criticalMaintOverdue: 0,
                  normalMaintOverdue: 0,
                  runningHoursOverdue: 0,
                  runningHoursOk: 0,
                  dockMaintCount: 0,
                  certsReallyExpired: 0,
                  certsInRenewalWindow: 0,
                  certsExpiringSoon: 0,
                  certsVigentes: 0,
                  certsUnverified: 0,
                  crewOnBoard: 0,
                  crewMinManningOk: true,
                  crewReliefsOverdue: 0,
                  crewReliefsPreventive: 0,
                  criticalPurchasesOpen: 0,
                ),
                certificatesSummary: CertificatesSummary(
                  total: 0,
                  vigentes: 0,
                  proximosAVencer: 0,
                  enVentanaRenovacion: 0,
                  vencidos: 0,
                  noVerificados: 0,
                  permanentes: 0,
                ),
                maradParity: MaradOfficialParity(
                  maintenance: {},
                  runningHours: {},
                  inventory: {},
                  certificates: {},
                  lastSyncedAt: '',
                ),
                priorities: [],
                sourcesSync: HealthSourcesSync(
                  maradLastSuccessAt: '',
                  maradLastSuccessFormatted: '',
                  maradRelativeAge: '',
                  intranetCrewLastSuccessAt: '',
                  intranetPurchasesLastSuccessAt: '',
                  status: '',
                ),
              ),
            );
            if (card.vesselId.isNotEmpty) {
              quickScore = card.healthScoreFinal;
              quickColor = _parseColor(card.colorHex, const Color(0xFF10B981));
            }
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => _onVesselSelected(vName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF0051B3)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    if (quickScore != null && quickScore > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : (quickColor ?? const Color(0xFF10B981)).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "$quickScore",
                          style: TextStyle(
                            color: isSelected ? Colors.white : (quickColor ?? const Color(0xFF10B981)),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Tarjeta Principal: Anillo Health Score (0-100) + Numeros Oficiales
  Widget _buildMainScoreCard(VesselHealthCard card) {
    final score = card.healthScoreFinal;
    final toneColor = _parseColor(card.colorHex, const Color(0xFF10B981));
    final deltaStr = card.deltaScore > 0
        ? "+${card.deltaScore} pts"
        : card.deltaScore < 0
            ? "${card.deltaScore} pts"
            : "=";

    return Container( 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1829),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Anillo circular con color oficial entregado por Centinela
          SizedBox(
            width: 98,
            height: 98,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(98, 98),
                  painter: _AppleHealthScorePainter(
                    score: score,
                    color: toneColor,
                    trackColor: _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$score",
                      style: TextStyle(
                        color: toneColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      "/ 100",
                      style: TextStyle(
                        color: _textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  [
                    Row(
                      children: [
                        Text(
                          card.vesselName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (card.imo.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            "IMO ${card.imo}",
                            style: TextStyle(color: _textTertiary, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Score Base: ",
                                style: TextStyle(color: _textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "${card.healthScoreBase}",
                                style: TextStyle(color: _textPrimary, fontSize: 11.5, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                " pts",
                                style: TextStyle(color: _textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        if (card.deltaScore != 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (card.deltaScore > 0 ? const Color(0xFF10B981) : const Color(0xFFFF5A5F)).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (card.deltaScore > 0 ? const Color(0xFF10B981) : const Color(0xFFFF5A5F)).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              deltaStr,
                              style: TextStyle(
                                color: card.deltaScore > 0 ? const Color(0xFF10B981) : const Color(0xFFFF5A5F),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
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
    );
  }

  /// Grilla compacta de 4 KPIs tocables que abren modales detallados
  Widget _buildQuickKpiGrid(VesselHealthDetail detail) {
    final kpis = detail.card.kpis;
    return Row(
      children: [
        // 1. Mant. Críticos (▲)
        Expanded(
          child: _buildTappableKpiCard(
            label: "MANT. CRÍTICOS",
            value: "${kpis.criticalMaintOverdue}",
            symbol: "▲",
            isDanger: kpis.criticalMaintOverdue > 0,
            color: kpis.criticalMaintOverdue > 0 ? const Color(0xFFFF5A5F) : const Color(0xFF10B981),
            onTap: () => _openMaintenanceSheet(detail.maintenanceTasks),
          ),
        ),
        const SizedBox(width: 8),
        // 2. Certs. Vencidos + subetiqueta en renovación
        Expanded(
          child: _buildTappableKpiCard(
            label: "CERTS. VENCIDOS",
            value: "${kpis.certsReallyExpired}",
            subLabel: kpis.certsInRenewalWindow > 0 ? "+${kpis.certsInRenewalWindow} en renov." : null,
            isDanger: kpis.certsReallyExpired > 0,
            color: kpis.certsReallyExpired > 0 ? const Color(0xFFFF5A5F) : const Color(0xFF10B981),
            onTap: () => _openCertificatesSheet(detail.certificates, detail.card.certificatesSummary),
          ),
        ),
        const SizedBox(width: 8),
        // 3. Relevos / Tripulación
        Expanded(
          child: _buildTappableKpiCard(
            label: "RELEVOS",
            value: "${kpis.crewReliefsOverdue}",
            subLabel: "${kpis.crewOnBoard} a bordo",
            isDanger: kpis.crewReliefsOverdue > 0,
            color: kpis.crewReliefsOverdue > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            onTap: () => _openCrewSheet(detail.crew),
          ),
        ),
        const SizedBox(width: 8),
        // 4. Pedidos Compras
        Expanded(
          child: _buildTappableKpiCard(
            label: "COMPRAS CRÍT.",
            value: "${kpis.criticalPurchasesOpen}",
            isDanger: kpis.criticalPurchasesOpen > 0,
            color: kpis.criticalPurchasesOpen > 0 ? const Color(0xFFFF5A5F) : Colors.white70,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildTappableKpiCard({
    required String label,
    required String value,
    String? symbol,
    String? subLabel,
    bool isDanger = false,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDanger ? const Color(0xFFFF5A5F).withValues(alpha: 0.35) : _cardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (symbol != null) ...[
                      Text(
                        symbol,
                        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textTertiary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                if (subLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjetas de los 4 Pilares con chips de 5 estados en Seguridad
  Widget _buildPillarsCard(VesselHealthCard card) {
    final pillars = card.pillars;
    final cert = card.certificatesSummary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF007AFF), size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                "PILARES DE SALUD CENTINELA",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPillarBar("Operación", pillars.operacion, const Color(0xFF10B981)),
          const SizedBox(height: 12),
          _buildPillarBar("Disponibilidad", pillars.disponibilidad, const Color(0xFF007AFF)),
          const SizedBox(height: 12),
          _buildPillarBar("Seguridad", pillars.seguridad, const Color(0xFFF59E0B)),
          // Chips de los 5 estados normativos en Seguridad
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, bottom: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildStateChip("Vigentes: ${cert.vigentes}", const Color(0xFF10B981)),
                _buildStateChip("Próximos: ${cert.proximosAVencer}", const Color(0xFFFCD34D)),
                _buildStateChip("En Renovación: ${cert.enVentanaRenovacion}", const Color(0xFFF59E0B), isAmberWindow: true),
                _buildStateChip("Vencidos: ${cert.vencidos}", const Color(0xFFFF5A5F)),
                if (cert.noVerificados > 0)
                  _buildStateChip("No Verif: ${cert.noVerificados}", const Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildPillarBar("Preparación", pillars.preparacion, const Color(0xFFAF52DE)),
        ],
      ),
    );
  }

  Widget _buildPillarBar(String title, int value, Color color) {
    final pct = (value / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              "$value%",
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 7,
            color: _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.7), color],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateChip(String text, Color color, {bool isAmberWindow = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
          if (isAmberWindow) ...[
            const SizedBox(width: 3),
            const Icon(Icons.hourglass_top_rounded, size: 10, color: Color(0xFFF59E0B)),
          ],
        ],
      ),
    );
  }

  /// Paridad Oficial con MARAD
  Widget _buildMaradParityCard(MaradOfficialParity marad) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "PARIDAD OFICIAL MARAD",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "100% LECTURA",
                  style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMaradMetric(
                  icon: Icons.warning_amber_rounded,
                  iconColor: marad.triangleRed > 0 ? const Color(0xFFFF5A5F) : const Color(0xFF10B981),
                  label: "▲ Críticos",
                  value: "${marad.triangleRed}",
                ),
              ),
              Expanded(
                child: _buildMaradMetric(
                  icon: Icons.circle,
                  iconColor: marad.circleRed > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  iconSize: 12,
                  label: "● Ordinarios",
                  value: "${marad.circleRed}",
                ),
              ),
              Expanded(
                child: _buildMaradMetric(
                  icon: Icons.timer_outlined,
                  iconColor: marad.runningHoursRed > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  label: "Hs Marcha",
                  value: "${marad.runningHoursRed}",
                ),
              ),
              Expanded(
                child: _buildMaradMetric(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: "Hs OK",
                  value: "${marad.runningHoursGreen}",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaradMetric({
    required IconData icon,
    required Color iconColor,
    double iconSize = 16,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: _textTertiary, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Lista de Prioridades tocables
  Widget _buildPrioritiesSection(VesselHealthDetail detail) {
    final priorities = detail.card.priorities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A5F).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFFFF5A5F), size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  "ALERTAS Y PRIORIDADES (${priorities.length})",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (priorities.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
            ),
            child: Center(
              child: Text(
                "Sin alertas prioritarias registradas por Centinela.",
                style: TextStyle(color: _textTertiary, fontSize: 13),
              ),
            ),
          )
        else
          ...priorities.map((prio) => _buildPriorityCard(prio, detail)),
      ],
    );
  }

  Widget _buildPriorityCard(HealthPriorityItem prio, VesselHealthDetail detail) {
    Color cardColor;
    IconData cardIcon;

    if (prio.isRenewalWindow) {
      cardColor = const Color(0xFFF59E0B);
      cardIcon = Icons.hourglass_top_rounded;
    } else if (prio.isCritical) {
      cardColor = const Color(0xFFFF5A5F);
      cardIcon = Icons.warning_rounded;
    } else {
      cardColor = const Color(0xFFFCD34D);
      cardIcon = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.35)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (prio.category == 'certificates') {
              _openCertificatesSheet(detail.certificates, detail.card.certificatesSummary);
            } else if (prio.category == 'maintenance') {
              _openMaintenanceSheet(detail.maintenanceTasks);
            } else if (prio.category == 'crew') {
              _openCrewSheet(detail.crew);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cardIcon, color: cardColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              prio.title,
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: _textTertiary, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prio.description,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          height: 1.3,
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

  /// Trazabilidad Real de Fuentes (Cero etiquetas ficticias)
  Widget _buildTraceabilityFooter(HealthSourcesSync sync, String calculatedAt) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                "TRAZABILIDAD OFICIAL CENTINELA (HORA ARGENTINA)",
                style: TextStyle(
                  color: _textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Cálculo Health Score: ${_formatIsoDate(calculatedAt)}",
            style: TextStyle(color: _textSecondary, fontSize: 11.5),
          ),
          if (sync.maradLastSuccessFormatted.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              "MARAD: ${sync.maradLastSuccessFormatted} (${sync.maradRelativeAge})",
              style: TextStyle(color: _textTertiary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _formatIsoDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return "$d/$m/${dt.year} $h:$min";
    } catch (_) {
      return iso;
    }
  }

  // ==========================================
  // MODALES Y HOJAS INFERIORES COMPLETAS
  // ==========================================

  /// 1. Hoja de Certificados (5 Estados Normativos)
  void _openCertificatesSheet(List<HealthCertificateItem> certs, CertificatesSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CertificatesDetailSheet(
        vesselName: _selectedVessel,
        certs: certs,
        summary: summary,
      ),
    );
  }

  /// 2. Hoja de Mantenimientos (Críticos ▲, Ordinarios ●, Dique)
  void _openMaintenanceSheet(MaintenanceTasksSummary tasks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MaintenanceDetailSheet(
        vesselName: _selectedVessel,
        tasks: tasks,
      ),
    );
  }

  /// 3. Hoja de Tripulación (Alineada a RRHH Vista Por Barco)
  void _openCrewSheet(List<HealthCrewMember> crew) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CrewDetailSheet(
        vesselName: _selectedVessel,
        crew: crew,
      ),
    );
  }
}

// =======================================================
// WIDGETS AUXILIARES DE HOJAS INFERIORES (BOTTOM SHEETS)
// =======================================================

/// Hoja Inferior: Certificados con los 5 estados obligatorios
class _CertificatesDetailSheet extends StatefulWidget {
  final String vesselName;
  final List<HealthCertificateItem> certs;
  final CertificatesSummary summary;

  const _CertificatesDetailSheet({
    required this.vesselName,
    required this.certs,
    required this.summary,
  });

  @override
  State<_CertificatesDetailSheet> createState() => _CertificatesDetailSheetState();
}

class _CertificatesDetailSheetState extends State<_CertificatesDetailSheet> {
  String _filterState = 'TODOS'; // TODOS, VIGENTE, PROXIMO_A_VENCER, EN_VENTANA_RENOVACION, VENCIDO

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? const Color(0xFF0D1829) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _textSecondary => _isDark ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF475569);
  Color get _textTertiary => _isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8);
  Color get _dividerColor => _isDark ? const Color(0xFF1B2A42) : const Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final filtered = widget.certs.where((c) {
      if (_filterState == 'TODOS') return true;
      return c.state == _filterState;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF007AFF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Certificados — ${widget.vesselName}",
                        style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "5 estados estatutarios (${widget.certs.length} certificados)",
                        style: TextStyle(color: _textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: _textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Selector de filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('TODOS', 'Todos (${widget.certs.length})', const Color(0xFF007AFF)),
                _buildFilterChip('VIGENTE', 'Vigentes (${widget.summary.vigentes})', const Color(0xFF10B981)),
                _buildFilterChip('PROXIMO_A_VENCER', 'Próximos (${widget.summary.proximosAVencer})', const Color(0xFFFCD34D)),
                _buildFilterChip('EN_VENTANA_RENOVACION', 'En Renovación (${widget.summary.enVentanaRenovacion})', const Color(0xFFF59E0B)),
                _buildFilterChip('VENCIDO', 'Vencidos (${widget.summary.vencidos})', const Color(0xFFFF5A5F)),
              ],
            ),
          ),
          Divider(color: _dividerColor, height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      "No hay certificados en este estado.",
                      style: TextStyle(color: _textTertiary),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      return _buildCertCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color color) {
    final isSel = _filterState == key;
    return GestureDetector(
      onTap: () => setState(() => _filterState = key),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.25) : (_isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? color : (_isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1))),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? color : _textSecondary,
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCertCard(HealthCertificateItem item) {
    Color stateColor;
    String stateLabel;
    IconData stateIcon;

    switch (item.state) {
      case 'VIGENTE':
        stateColor = const Color(0xFF10B981);
        stateLabel = "VIGENTE";
        stateIcon = Icons.check_circle_rounded;
        break;
      case 'PROXIMO_A_VENCER':
        stateColor = const Color(0xFFFCD34D);
        stateLabel = "PRÓXIMO A VENCER";
        stateIcon = Icons.timelapse_rounded;
        break;
      case 'EN_VENTANA_RENOVACION':
        // Ámbar: vencimiento nominal alcanzado pero con extensión válida. NUNCA MOSTRARLO COMO VENCIDO
        stateColor = const Color(0xFFF59E0B);
        stateLabel = "EN VENTANA DE RENOVACIÓN (PRÓRROGA VÁLIDA)";
        stateIcon = Icons.hourglass_bottom_rounded;
        break;
      case 'VENCIDO':
        stateColor = const Color(0xFFFF5A5F);
        stateLabel = "VENCIDO";
        stateIcon = Icons.cancel_rounded;
        break;
      default:
        stateColor = const Color(0xFF64748B);
        stateLabel = "NO VERIFICADO";
        stateIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stateColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(color: _textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(stateIcon, color: stateColor, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  stateLabel,
                  style: TextStyle(color: stateColor, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (item.nominalExpirationDate != null)
            Row(
              children: [
                Text(
                  "Vencimiento nominal: ${item.nominalExpirationDate}",
                  style: TextStyle(color: _textSecondary, fontSize: 11),
                ),
                if (item.effectiveExpirationDate != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    "Límite efectivo: ${item.effectiveExpirationDate}",
                    style: TextStyle(color: _textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          if (item.isEnVentanaRenovacion && item.daysRemainingEffective != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Ventana válida: ${item.daysRemainingEffective} días restantes de prórroga estatutaria.",
                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (item.isVencido && item.daysOverdueEffective > 0) ...[
            const SizedBox(height: 6),
            Text(
              "Excedido por ${item.daysOverdueEffective} días sobre la fecha límite efectiva.",
              style: const TextStyle(color: Color(0xFFFF5A5F), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
          if (item.normativeBasis != null && item.normativeBasis!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.normativeBasis!,
              style: TextStyle(color: _textTertiary, fontSize: 10.5, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hoja Inferior: Mantenimientos MARAD (Críticos ▲, Ordinarios ●, Dique)
class _MaintenanceDetailSheet extends StatefulWidget {
  final String vesselName;
  final MaintenanceTasksSummary tasks;

  const _MaintenanceDetailSheet({
    required this.vesselName,
    required this.tasks,
  });

  @override
  State<_MaintenanceDetailSheet> createState() => _MaintenanceDetailSheetState();
}

class _MaintenanceDetailSheetState extends State<_MaintenanceDetailSheet> {
  String _activeTab = 'CRITICAL'; // CRITICAL, NORMAL, WARNING, DOCK

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? const Color(0xFF0D1829) : Colors.white;
  Color get _cardBorder => _isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _textSecondary => _isDark ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF475569);
  Color get _textTertiary => _isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8);
  Color get _dividerColor => _isDark ? const Color(0xFF1B2A42) : const Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    List<MaintenanceTaskItem> list;
    switch (_activeTab) {
      case 'CRITICAL':
        list = widget.tasks.criticalOverdue;
        break;
      case 'NORMAL':
        list = widget.tasks.normalOverdue;
        break;
      case 'WARNING':
        list = widget.tasks.warning;
        break;
      case 'DOCK':
        list = widget.tasks.dock;
        break;
      default:
        list = widget.tasks.criticalOverdue;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A5F).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.build_rounded, color: Color(0xFFFF5A5F), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mantenimientos — ${widget.vesselName}",
                        style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Paridad MARAD oficial",
                        style: TextStyle(color: _textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: _textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildMaintTab('CRITICAL', '▲ Críticos (${widget.tasks.criticalOverdue.length})', const Color(0xFFFF5A5F)),
                _buildMaintTab('NORMAL', '● Ordinarios (${widget.tasks.normalOverdue.length})', const Color(0xFFF59E0B)),
                _buildMaintTab('WARNING', 'Advertencias (${widget.tasks.warning.length})', const Color(0xFFFCD34D)),
                _buildMaintTab('DOCK', 'Dique (${widget.tasks.dock.length})', const Color(0xFF007AFF)),
              ],
            ),
          ),
          Divider(color: _dividerColor, height: 16),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      "Sin tareas registradas en esta categoría.",
                      style: TextStyle(color: _textTertiary),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (context, idx) {
                      final task = list[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: task.isCritical ? const Color(0xFFFF5A5F).withValues(alpha: 0.35) : _cardBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (task.isCritical) ...[
                                  const Text("▲ ", style: TextStyle(color: Color(0xFFFF5A5F), fontWeight: FontWeight.bold, fontSize: 14)),
                                ] else ...[
                                  const Text("● ", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
                                ],
                                Expanded(
                                  child: Text(
                                    task.name,
                                    style: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (task.status == 'Vencido' ? const Color(0xFFFF5A5F) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    task.status,
                                    style: TextStyle(
                                      color: task.status == 'Vencido' ? const Color(0xFFFF5A5F) : const Color(0xFFF59E0B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (task.description.isNotEmpty && task.description != task.name) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.description,
                                style: TextStyle(color: _textSecondary, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (task.dueDate.isNotEmpty)
                                  Text(
                                    "Vencimiento: ${task.dueDate}",
                                    style: TextStyle(color: _textSecondary, fontSize: 11),
                                  ),
                                const Spacer(),
                                if (task.ranks.isNotEmpty)
                                  Text(
                                    task.ranks,
                                    style: const TextStyle(color: Color(0xFF007AFF), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintTab(String key, String label, Color color) {
    final isSel = _activeTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.25) : (_isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? color : (_isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1))),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? color : _textSecondary,
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Hoja Inferior: Tripulación a bordo (Alineada a RRHH Vista Por Barco)
class _CrewDetailSheet extends StatelessWidget {
  final String vesselName;
  final List<HealthCrewMember> crew;

  const _CrewDetailSheet({
    required this.vesselName,
    required this.crew,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0D1829) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF475569);
    final textTertiary = isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8);
    final dividerColor = isDark ? const Color(0xFF1B2A42) : const Color(0xFFE2E8F0);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tripulación — $vesselName",
                        style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Alineado con RRHH Vista Por Barco (${crew.length} tripulantes)",
                        style: TextStyle(color: textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(color: dividerColor, height: 16),
          Expanded(
            child: crew.isEmpty
                ? Center(
                    child: Text(
                      "Sin tripulantes reportados.",
                      style: TextStyle(color: textTertiary),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: crew.length,
                    itemBuilder: (context, idx) {
                      final c = crew[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: c.isOverLimit ? const Color(0xFFFF5A5F).withValues(alpha: 0.35) : cardBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              c.roleShort,
                                              style: const TextStyle(color: Color(0xFF007AFF), fontSize: 10, fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            c.regime,
                                            style: TextStyle(color: textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Días a bordo
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (c.isOverLimit ? const Color(0xFFFF5A5F) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: (c.isOverLimit ? const Color(0xFFFF5A5F) : const Color(0xFF10B981)).withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        "${c.daysOnBoard} / ${c.maxDaysLimit} d",
                                        style: TextStyle(
                                          color: c.isOverLimit ? const Color(0xFFFF5A5F) : const Color(0xFF10B981),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (c.isOverLimit) ...[
                                      const SizedBox(height: 2),
                                      const Text(
                                        "Límite excedido",
                                        style: TextStyle(color: Color(0xFFFF5A5F), fontSize: 9.5, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  "GF: ${c.gfrancoOnboard.toStringAsFixed(1)}",
                                  style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  "F.Pre: ${c.fcoPreEmbark.toStringAsFixed(1)}",
                                  style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                if (c.hasExpiredCert)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5A5F).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text("Cert. Vencido", style: TextStyle(color: Color(0xFFFF5A5F), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                  )
                                else if (c.hasExpiring1mCert)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text("Cert. x Vencer", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter para el Anillo de Score Apple Health
class _AppleHealthScorePainter extends CustomPainter {
  final int score;
  final Color color;
  final Color? trackColor;

  _AppleHealthScorePainter({required this.score, required this.color, this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    // Track de fondo
    final trackPaint = Paint()
      ..color = trackColor ?? Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Arco de progreso
    final progress = (score / 100.0).clamp(0.0, 1.0);
    final sweepAngle = 2 * math.pi * progress;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AppleHealthScorePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
