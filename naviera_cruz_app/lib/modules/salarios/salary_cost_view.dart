import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/storage.dart';
import '../../models/salary_cost_model.dart';
import '../../services/salary_cost_service.dart';
import 'salary_apple_charts.dart';

class SalaryCostView extends StatefulWidget {
  final bool isTabModule;
  const SalaryCostView({super.key, this.isTabModule = false});

  @override
  State<SalaryCostView> createState() => _SalaryCostViewState();
}

class _SalaryCostViewState extends State<SalaryCostView> with SingleTickerProviderStateMixin {
  String _selectedSegment = 'TRIPULANTES'; // 'TRIPULANTES', 'OFICINA', 'CONSOLIDADO'
  String? _selectedPeriodCode; // e.g. '2026-10'

  bool _isLoading = false;
  String? _errorMessage;
  SalaryCostResponse? _costData;
  late AnimationController _animController;

  static String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '\$ $formattedInt,$decimalPart';
  }

  static String _formatCompact(double val) {
    if (val >= 1000000000) {
      return '\$ ${(val / 1000000000).toStringAsFixed(1).replaceAll('.', ',')} B';
    }
    if (val >= 1000000) {
      return '\$ ${(val / 1000000).toStringAsFixed(1).replaceAll('.', ',')} M';
    }
    if (val >= 1000) {
      return '\$ ${(val / 1000).toStringAsFixed(1).replaceAll('.', ',')} K';
    }
    return _formatCurrency(val);
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await SalaryCostService.shared.fetchSalaryCosts(
        segment: _selectedSegment,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _costData = res;
          if (_selectedPeriodCode == null ||
              !res.periods.any((p) => p.periodCode == _selectedPeriodCode)) {
            if (res.periods.isNotEmpty) {
              _selectedPeriodCode = res.periods.last.periodCode;
            }
          }
          _isLoading = false;
        });
        _animController.forward(from: 0.0);
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

  SalaryPeriod? get _currentPeriod {
    if (_costData == null || _costData!.periods.isEmpty) return null;
    return _costData!.periods.firstWhere(
      (p) => p.periodCode == _selectedPeriodCode,
      orElse: () => _costData!.periods.last,
    );
  }

  void _changePeriodByOffset(int offset) {
    if (_costData == null || _costData!.periods.isEmpty) return;
    final periods = _costData!.periods;
    final currentIndex = periods.indexWhere((p) => p.periodCode == _selectedPeriodCode);
    if (currentIndex == -1) return;

    final newIndex = currentIndex + offset;
    if (newIndex >= 0 && newIndex < periods.length) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedPeriodCode = periods[newIndex].periodCode;
      });
      _animController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionManager>(context);
    final user = session.currentUser;
    final isAuthorized = SalaryCostService.isAuthorizedUser(user);

    if (!isAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFF070B14),
        appBar: AppBar(
          title: const Text("Acceso Restringido"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 64, color: Colors.orange.shade300),
                const SizedBox(height: 20),
                const Text(
                  "Módulo Confidencial",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Este módulo de información salarial de Directorio está restringido exclusivamente a la dirección de la compañía.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final period = _currentPeriod;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: RefreshIndicator(
            color: const Color(0xFF007AFF),
            backgroundColor: const Color(0xFF131B2E),
            onRefresh: () => _loadData(forceRefresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
              // Apple Header Bar
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0A0F1D).withOpacity(0.95),
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: widget.isTabModule
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    tooltip: "Actualizar datos",
                    onPressed: () => _loadData(forceRefresh: true),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Salarios",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filters Section (Segment & Month Selector)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSegmentSelector(),
                      const SizedBox(height: 14),
                      _buildPeriodNavigator(),
                    ],
                  ),
                ),
              ),

              // Content State
              if (_isLoading && _costData == null)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF007AFF)),
                        SizedBox(height: 16),
                        Text(
                          "Cargando análisis de costos...",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage != null && _costData == null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _loadData(forceRefresh: true),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text("Reintentar"),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (period != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeroSummaryCard(period),
                      const SizedBox(height: 16),
                      _buildKpiMetricsGrid(period),
                      const SizedBox(height: 20),
                      _buildMonthlyEvolutionCard(),
                      const SizedBox(height: 20),
                      _buildDonutCompositionCard(period),
                      const SizedBox(height: 20),
                      _buildCentersStackedBarsCard(period),
                      const SizedBox(height: 20),
                      _buildContributionsBreakdownCard(period),
                      const SizedBox(height: 20),
                      _buildActiveVsSeveranceCard(period),
                      const SizedBox(height: 20),
                      if (period.executiveNotes.isNotEmpty) ...[
                        _buildExecutiveNotesCard(period),
                        const SizedBox(height: 20),
                      ],
                      _buildFooterMeta(period),
                    ]),
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// Segment Selector (Tripulantes | Oficina | Consolidado)
  Widget _buildSegmentSelector() {
    final segments = [
      {'key': 'TRIPULANTES', 'label': 'Tripulantes', 'icon': Icons.directions_boat_rounded},
      {'key': 'OFICINA', 'label': 'Oficina', 'icon': Icons.business_rounded},
      {'key': 'CONSOLIDADO', 'label': 'Consolidado', 'icon': Icons.auto_graph_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: segments.map((s) {
          final isSelected = _selectedSegment == s['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedSegment != s['key']) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedSegment = s['key'] as String;
                  });
                  _loadData();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF0056B3)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      s['icon'] as IconData,
                      size: 15,
                      color: isSelected ? Colors.white : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Month / Period Navigator (← Mes Analizado →)
  Widget _buildPeriodNavigator() {
    final periods = _costData?.periods ?? [];
    final currentIndex = periods.indexWhere((p) => p.periodCode == _selectedPeriodCode);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex != -1 && currentIndex < periods.length - 1;
    final currentLabel = _currentPeriod?.periodLabel ?? 'Cargando...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: hasPrev ? Colors.white : Colors.white24,
              size: 28,
            ),
            onPressed: hasPrev ? () => _changePeriodByOffset(-1) : null,
            tooltip: "Mes anterior",
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showPeriodPickerModal(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF007AFF), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      currentLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 18),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: hasNext ? Colors.white : Colors.white24,
              size: 28,
            ),
            onPressed: hasNext ? () => _changePeriodByOffset(1) : null,
            tooltip: "Mes siguiente",
          ),
        ],
      ),
    );
  }

  void _showPeriodPickerModal() {
    final periods = _costData?.periods ?? [];
    if (periods.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  "Seleccionar Periodo Analizado",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: periods.length,
                  itemBuilder: (context, index) {
                    final p = periods[index];
                    final isSelected = p.periodCode == _selectedPeriodCode;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                        color: isSelected ? const Color(0xFF007AFF) : Colors.white38,
                        size: 20,
                      ),
                      title: Text(
                        p.periodLabel,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        _formatCompact(p.totalEmployerCost),
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF007AFF) : Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedPeriodCode = p.periodCode;
                        });
                        _animController.forward(from: 0.0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Apple Hero Card (Costo Empleador Total)
  Widget _buildHeroSummaryCard(SalaryPeriod period) {
    final isNegativeDiff = period.momVariationPct < 0;
    final diffPctStr = '${(period.momVariationPct * 100).toStringAsFixed(1)} %';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2042),
            Color(0xFF142952),
            Color(0xFF0A1833),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "COSTO EMPLEADOR TOTAL",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (period.previousPeriodLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isNegativeDiff ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isNegativeDiff ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isNegativeDiff ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        color: isNegativeDiff ? Colors.greenAccent : Colors.orangeAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        diffPctStr,
                        style: TextStyle(
                          color: isNegativeDiff ? Colors.greenAccent : Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(period.totalEmployerCost),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (period.momVariationNote.isNotEmpty)
            Text(
              period.momVariationNote,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (period.netPay / period.totalEmployerCost * 100).round(),
                    child: Container(color: const Color(0xFF007AFF)), // Neto
                  ),
                  Expanded(
                    flex: (period.employerContributions / period.totalEmployerCost * 100).round(),
                    child: Container(color: const Color(0xFFF39200)), // Contribuciones
                  ),
                  Expanded(
                    flex: (period.withholdings / period.totalEmployerCost * 100).round(),
                    child: Container(color: const Color(0xFFAF52DE)), // Retenciones
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendPill("Neto ${(period.netPay / period.totalEmployerCost * 100).toStringAsFixed(1)}%", const Color(0xFF007AFF)),
              _buildLegendPill("Contrib. ${(period.employerContributions / period.totalEmployerCost * 100).toStringAsFixed(1)}%", const Color(0xFFF39200)),
              _buildLegendPill("Retenc. ${(period.withholdings / period.totalEmployerCost * 100).toStringAsFixed(1)}%", const Color(0xFFAF52DE)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Apple Metrics Grid (4 cards con AppleMiniRings integrados)
  Widget _buildKpiMetricsGrid(SalaryPeriod period) {
    final double netShare = period.totalEmployerCost > 0 ? (period.netPay / period.totalEmployerCost) : 0.0;
    final double contribShare = period.totalEmployerCost > 0 ? (period.employerContributions / period.totalEmployerCost) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return GridView.count(
          crossAxisCount: isWide ? 2 : 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 2.4 : 2.5,
          children: [
            _buildMetricCardWithRing(
              title: "Neto a Pagar",
              amount: _formatCurrency(period.netPay),
              subtitle: "${(netShare * 100).toStringAsFixed(1)}% del costo total",
              percentage: netShare,
              ringColor: const Color(0xFF007AFF),
            ),
            _buildMetricCardWithRing(
              title: "Contribuciones",
              amount: _formatCurrency(period.employerContributions),
              subtitle: "${(period.contribToRemunRatio * 100).toStringAsFixed(1)}% del sueldo remunerativo",
              percentage: contribShare,
              ringColor: const Color(0xFFF39200),
            ),
            _buildMetricCardWithRing(
              title: "Personas Liquidadas",
              amount: "${period.headcountTotal} personas",
              subtitle: period.headcountSeverances > 0
                  ? "${period.headcountSeverances} bajas en el mes"
                  : "Sin bajas registradas",
              percentage: period.headcountTotal > 0
                  ? (period.headcountTotal - period.headcountSeverances) / period.headcountTotal
                  : 1.0,
              ringColor: const Color(0xFF30D158),
            ),
            _buildMetricCardWithRing(
              title: "Ratio Costo / Neto",
              amount: "\$ ${period.costToNetRatio.toStringAsFixed(2)}",
              subtitle: "gasto total por cada \$ 1 neto",
              percentage: (period.costToNetRatio / 2.0).clamp(0.0, 1.0),
              ringColor: const Color(0xFFAF52DE),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCardWithRing({
    required String title,
    required String amount,
    required String subtitle,
    required double percentage,
    required Color ringColor,
  }) {
    final pctText = '${(percentage * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppleMiniRing(
            percentage: percentage,
            ringColor: ringColor,
            size: 50,
            strokeWidth: 5.5,
            centerChild: Text(
              pctText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gráfico 1: Evolución Mensual del Costo (Apple Bar Chart Marzo - Octubre 2026)
  Widget _buildMonthlyEvolutionCard() {
    final periods = _costData?.periods ?? [];
    if (periods.isEmpty) return const SizedBox.shrink();

    final monthlyBars = periods.map((p) {
      final parts = p.periodLabel.split(' ');
      final monthName = parts.isNotEmpty ? parts[0].substring(0, math.min(3, parts[0].length)) : p.periodCode;
      return MonthlyBarData(
        periodCode: p.periodCode,
        monthLabel: monthName,
        cost: p.totalEmployerCost,
        shortCostLabel: _formatCompact(p.totalEmployerCost),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Evolución Mensual del Costo",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Toca cualquier mes para inspeccionarlo",
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "MAR - OCT 2026",
                  style: TextStyle(color: Color(0xFF007AFF), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppleMonthlyBarsChart(
            monthlyData: monthlyBars,
            selectedPeriodCode: _selectedPeriodCode ?? '',
            onSelectPeriod: (code) {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPeriodCode = code;
              });
              _animController.forward(from: 0.0);
            },
          ),
        ],
      ),
    );
  }

  /// Gráfico 2: A Dónde Va Cada Peso (Apple Donut Chart con Leyenda)
  Widget _buildDonutCompositionCard(SalaryPeriod period) {
    final netPay = period.netPay;
    final contrib = period.employerContributions;
    final withh = period.withholdings;
    final total = period.totalEmployerCost;

    final segments = [
      DonutSegment(label: "Neto a Pagar", value: netPay, color: const Color(0xFF007AFF)),
      DonutSegment(label: "Contribuciones", value: contrib, color: const Color(0xFFF39200)),
      DonutSegment(label: "Retenciones", value: withh, color: const Color(0xFFAF52DE)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "A Dónde Va Cada Peso",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "DISTRIBUCIÓN",
                  style: TextStyle(color: Colors.white60, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;
              final donutWidget = AppleDonutChart(
                segments: segments,
                centerTitle: _formatCompact(total),
                centerSubtitle: "100% Costo",
                size: 170,
              );

              final legendWidget = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: segments.map((s) {
                  final pctStr = '${(s.value / total * 100).toStringAsFixed(1)} %';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.label,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          pctStr,
                          style: TextStyle(color: s.color, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatCompact(s.value),
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11.5),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );

              if (isWide) {
                return Row(
                  children: [
                    donutWidget,
                    const SizedBox(width: 32),
                    Expanded(child: legendWidget),
                  ],
                );
              } else {
                return Column(
                  children: [
                    donutWidget,
                    const SizedBox(height: 20),
                    legendWidget,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Gráfico 3: Costo Empleador por Buque (Barras Apiladas Apple)
  Widget _buildCentersStackedBarsCard(SalaryPeriod period) {
    final centers = period.centers;
    if (centers.isEmpty) return const SizedBox.shrink();

    final maxCost = centers.map((c) => c.totalEmployerCost).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Costo Empleador por Buque",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${centers.length} CENTROS",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...centers.map((center) {
            final double ratio = maxCost > 0 ? (center.totalEmployerCost / maxCost) : 0.0;
            final sharePctStr = '${(center.costSharePct * 100).toStringAsFixed(1)} %';

            final double netRatio = center.totalEmployerCost > 0 ? (center.netPay / center.totalEmployerCost) : 0.0;
            final double contribRatio = center.totalEmployerCost > 0 ? (center.employerContributions / center.totalEmployerCost) : 0.0;
            final double withhRatio = center.totalEmployerCost > 0 ? (center.withholdings / center.totalEmployerCost) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            center.centerName.toLowerCase() == 'oficina'
                                ? Icons.business_rounded
                                : Icons.directions_boat_filled_rounded,
                            size: 15,
                            color: const Color(0xFF007AFF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            center.centerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "(${center.headcountTotal} personas)",
                            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrency(center.totalEmployerCost),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Stacked Bar
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final totalBarWidth = constraints.maxWidth * ratio;
                      return Stack(
                        children: [
                          Container(
                            height: 14,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: SizedBox(
                              height: 14,
                              width: totalBarWidth,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: (netRatio * 100).round(),
                                    child: Container(color: const Color(0xFF007AFF)),
                                  ),
                                  Expanded(
                                    flex: (contribRatio * 100).round(),
                                    child: Container(color: const Color(0xFFF39200)),
                                  ),
                                  Expanded(
                                    flex: (withhRatio * 100).round(),
                                    child: Container(color: const Color(0xFFAF52DE)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Participación: $sharePctStr",
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                      ),
                      Text(
                        "Neto ${_formatCompact(center.netPay)} · Contrib ${_formatCompact(center.employerContributions)}",
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Gráfico 4: Contribuciones Patronales por Tipo
  Widget _buildContributionsBreakdownCard(SalaryPeriod period) {
    double totalSS = 0;
    double totalHealth = 0;
    double totalART = 0;
    double totalLife = 0;
    double totalUnion = 0;

    for (var c in period.centers) {
      totalSS += c.contribSocialSecurity;
      totalHealth += c.contribHealthInsurance;
      totalART += c.contribArt;
      totalLife += c.contribLifeInsurance;
      totalUnion += c.contribUnion;
    }

    final items = [
      {'label': 'Seguridad Social', 'amount': totalSS, 'color': const Color(0xFF007AFF), 'icon': Icons.security_rounded},
      {'label': 'Obra Social', 'amount': totalHealth, 'color': const Color(0xFF30D158), 'icon': Icons.health_and_safety_rounded},
      {'label': 'ART (Aseguradora)', 'amount': totalART, 'color': const Color(0xFFFF9F0A), 'icon': Icons.medical_services_rounded},
      {'label': 'Contrib. Sindicales', 'amount': totalUnion, 'color': const Color(0xFFAF52DE), 'icon': Icons.groups_rounded},
      {'label': 'Seguro de Vida', 'amount': totalLife, 'color': const Color(0xFF64D2FF), 'icon': Icons.volunteer_activism_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Contribuciones Patronales por Tipo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                _formatCompact(period.employerContributions),
                style: const TextStyle(
                  color: Color(0xFFF39200),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((it) {
            final double amt = it['amount'] as double;
            final Color color = it['color'] as Color;
            final double pct = period.employerContributions > 0 ? (amt / period.employerContributions) : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(it['icon'] as IconData, color: color, size: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          it['label'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _formatCurrency(amt),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Gráfico 5: Activos vs Bajas por Buque
  Widget _buildActiveVsSeveranceCard(SalaryPeriod period) {
    final centers = period.centers;
    if (centers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Activos y Bajas por Buque",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  _buildLegendPill("Activos", const Color(0xFF30D158)),
                  const SizedBox(width: 12),
                  _buildLegendPill("Bajas", const Color(0xFFFF453A)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...centers.map((center) {
            final int total = center.headcountTotal;
            final int activos = center.headcountActive;
            final int bajas = center.headcountSeverances;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        center.centerName,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "$activos activos · $bajas bajas ($total total)",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: activos > 0 ? activos : 1,
                            child: Container(color: const Color(0xFF30D158)),
                          ),
                          if (bajas > 0)
                            Expanded(
                              flex: bajas,
                              child: Container(color: const Color(0xFFFF453A)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Notas Ejecutivas
  Widget _buildExecutiveNotesCard(SalaryPeriod period) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: const Icon(Icons.description_outlined, color: Color(0xFF007AFF)),
          title: const Text(
            "Notas Ejecutivas & Verificación",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${period.executiveNotes.length} observaciones del estudio y F931",
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          children: period.executiveNotes.map((note) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFooterMeta(SalaryPeriod period) {
    return Center(
      child: Column(
        children: [
          Text(
            "Fuente: ${period.title}",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            "Controlado contra F931 y asientos contables",
            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
