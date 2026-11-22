import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/compras_model.dart';
import '../../services/compras_service.dart';
import '../salarios/salary_apple_charts.dart';
import '../../app/ncs_hero_header.dart';

class ComprasView extends StatefulWidget {
  final bool isTabModule;
  const ComprasView({super.key, this.isTabModule = false});

  @override
  State<ComprasView> createState() => _ComprasViewState();
}

class _ComprasViewState extends State<ComprasView> with SingleTickerProviderStateMixin {
  String _selectedBarco = 'Todos'; // 'Todos', 'Alfa C', 'Gustavo U', 'Nany'
  String _selectedTab = 'Todos'; // 'Todos', 'Abiertos', 'Críticos', 'Vencidos', 'Cerrados'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  ComprasResponse? _comprasData;
  late AnimationController _animController;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? const Color(0xFF070B14) : const Color(0xFFF8FAFC);
  Color get _cardBg => _isDark ? const Color(0xFF131B2E) : Colors.white;
  Color get _cardBorder => _isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _textSecondary => _isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF64748B);
  Color get _textTertiary => _isDark ? Colors.white.withOpacity(0.40) : const Color(0xFF94A3B8);


  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      final res = await ComprasService.shared.fetchPedidos(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _comprasData = res;
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

  // Lista base filtrada por barco (para el cálculo de KPIs contextuales del barco)
  List<PedidoCompra> get _barcoFilteredPedidos {
    if (_comprasData == null) return [];
    var list = _comprasData!.results;
    if (_selectedBarco != 'Todos') {
      list = list.where((p) => p.barco.toLowerCase() == _selectedBarco.toLowerCase()).toList();
    }
    return list;
  }

  // Lista completamente filtrada (barco + estado/tab + búsqueda) para el listado
  List<PedidoCompra> get _filteredPedidos {
    var list = _barcoFilteredPedidos;

    switch (_selectedTab) {
      case 'Abiertos':
        // Abiertos son los que NO están cumplidos (En plan + Vencidos)
        list = list.where((p) => !p.cumplido).toList();
        break;
      case 'Críticos':
        // Críticos o con urgencia Urgente
        list = list.where((p) => p.esCritico || p.urgencia.toLowerCase() == 'urgente').toList();
        break;
      case 'Vencidos':
        // Pedidos vencidos
        list = list.where((p) => p.vigencia.toLowerCase() == 'vencido' || p.estado.toLowerCase() == 'vencido').toList();
        break;
      case 'Cerrados':
      case 'Cumplidos':
        // Pedidos cumplidos/cerrados
        list = list.where((p) => p.cumplido).toList();
        break;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final numMatch = p.numero.toLowerCase().contains(q);
        final barcoMatch = p.barco.toLowerCase().contains(q);
        final depMatch = p.departamento.toLowerCase().contains(q);
        final tipoMatch = p.tipoPedido.toLowerCase().contains(q);
        final artMatch = p.articulos.any((a) => a.nombre.toLowerCase().contains(q) || a.descripcion.toLowerCase().contains(q));
        return numMatch || barcoMatch || depMatch || tipoMatch || artMatch;
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos métricas dinámicas basadas en los filtros seleccionados
    final currentList = _barcoFilteredPedidos;
    final totalPedidos = currentList.length;

    int totalArticulos = 0;
    double totalUnidades = 0;
    int criticosTotal = 0;
    int criticosCumplidos = 0;
    int criticosVencidos = 0;
    int criticosEnPlan = 0;

    int noCriticosTotal = 0;
    int noCriticosCumplidos = 0;
    int noCriticosVencidos = 0;
    int noCriticosEnPlan = 0;

    int vencidosTotal = 0;
    int cumplidosTotal = 0;
    int enPlanTotal = 0;

    for (var p in currentList) {
      totalArticulos += p.cantidadArticulos;
      totalUnidades += p.totalUnidadesSolicitadas;

      final bool isCrit = p.esCritico || p.urgencia.toLowerCase() == 'urgente';
      final bool isVenc = p.vigencia.toLowerCase() == 'vencido' || p.estado.toLowerCase() == 'vencido';
      final bool isCump = p.cumplido;

      if (isCump) {
        cumplidosTotal++;
      } else if (isVenc) {
        vencidosTotal++;
      } else {
        enPlanTotal++;
      }

      if (isCrit) {
        criticosTotal++;
        if (isCump) {
          criticosCumplidos++;
        } else if (isVenc) {
          criticosVencidos++;
        } else {
          criticosEnPlan++;
        }
      } else {
        noCriticosTotal++;
        if (isCump) {
          noCriticosCumplidos++;
        } else if (isVenc) {
          noCriticosVencidos++;
        } else {
          noCriticosEnPlan++;
        }
      }
    }

    final pedidos = _filteredPedidos;

    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              NcsHeroHeader(
                title: "Compras",
                subtitle: "Requerimientos y pedidos de insumos por buque",
                showBackButton: widget.isTabModule ? false : null,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF00C7BE),
                  backgroundColor: _cardBg,
                  onRefresh: () => _loadData(forceRefresh: true),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      // Filters Section (Vessel Selector + Search Bar + Status Tabs)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildBarcoSelector(),
                        const SizedBox(height: 12),
                        _buildQuickStatusTabs(),
                      ],
                    ),
                  ),
                ),

                // Content State
                if (_isLoading && _comprasData == null)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF00C7BE)),
                          SizedBox(height: 16),
                          Text(
                            "Cargando pedidos de compras...",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage != null && _comprasData == null)
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
                else ...[
                  // Dynamic KPI Cards (Updating instantly with filters)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildDynamicHeroTotalCard(
                            totalPedidos: totalPedidos,
                            totalArticulos: totalArticulos,
                            totalUnidades: totalUnidades,
                            cumplidos: cumplidosTotal,
                            enPlan: enPlanTotal,
                            vencidos: vencidosTotal,
                          ),
                          const SizedBox(height: 14),
                          _buildDynamicRingsGrid(
                            criticosTotal: criticosTotal,
                            criticosCumplidos: criticosCumplidos,
                            criticosVencidos: criticosVencidos,
                            criticosEnPlan: criticosEnPlan,
                            noCriticosTotal: noCriticosTotal,
                            noCriticosCumplidos: noCriticosCumplidos,
                            noCriticosVencidos: noCriticosVencidos,
                            noCriticosEnPlan: noCriticosEnPlan,
                            cumplidosTotal: cumplidosTotal,
                            totalPedidos: totalPedidos,
                          ),
                          const SizedBox(height: 16),
                          _buildDynamicDonutsCard(
                            total: totalPedidos,
                            vencidos: vencidosTotal,
                            cumplidos: cumplidosTotal,
                            enPlan: enPlanTotal,
                          ),
                          const SizedBox(height: 16),
                          if (_selectedBarco == 'Todos') ...[
                            _buildDynamicFleetCard(),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Section Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00C7BE),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "PEDIDOS MOSTRADOS (${pedidos.length})",
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedBarco != 'Todos' || _selectedTab != 'Todos' || _searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _selectedBarco = 'Todos';
                                  _selectedTab = 'Todos';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Limpiar filtros",
                                  style: TextStyle(color: Color(0xFF007AFF), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // List of filtered orders
                  if (pedidos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              "No hay pedidos con el filtro '$_selectedTab' en '$_selectedBarco'.",
                              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final pedido = pedidos[index];
                            return _buildPedidoCard(pedido);
                          },
                          childCount: pedidos.length,
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

  /// Search Bar estilo Cupertino
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: _textPrimary, fontSize: 14),
        cursorColor: const Color(0xFF00C7BE),
        decoration: InputDecoration(
          hintText: "Buscar por número, buque, departamento o artículo...",
          hintStyle: TextStyle(color: _textTertiary, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: _textSecondary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: _textSecondary, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
      ),
    );
  }

  /// Barco Selector (Pills estilo Salarios con gradiente y sombras Apple)
  Widget _buildBarcoSelector() {
    final barcos = [
      {'label': 'Todos', 'icon': Icons.apps_rounded, 'color': const Color(0xFF007AFF)},
      {'label': 'Alfa C', 'icon': Icons.directions_boat_filled_rounded, 'color': const Color(0xFF007AFF)},
      {'label': 'Gustavo U', 'icon': Icons.directions_boat_filled_rounded, 'color': const Color(0xFF30D158)},
      {'label': 'Nany', 'icon': Icons.directions_boat_filled_rounded, 'color': const Color(0xFFF39200)},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF131B2E) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: barcos.map((b) {
          final isSelected = _selectedBarco == b['label'];
          final Color bColor = b['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedBarco != b['label']) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedBarco = b['label'] as String;
                  });
                  _animController.forward(from: 0.0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [bColor, bColor.withOpacity(0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: bColor.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(b['icon'] as IconData, size: 14, color: isSelected ? Colors.white : (_isDark ? Colors.white54 : const Color(0xFF64748B))),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        b['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (_isDark ? Colors.white60 : const Color(0xFF64748B)),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
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

  /// Quick Status Tabs con Iconos estilo Apple (Todos | Abiertos | Críticos | Vencidos | Cerrados)
  Widget _buildQuickStatusTabs() {
    final tabs = [
      {'key': 'Todos', 'label': 'Todos', 'icon': Icons.list_alt_rounded, 'color': const Color(0xFF007AFF)},
      {'key': 'Abiertos', 'label': 'Abiertos', 'icon': Icons.timelapse_rounded, 'color': const Color(0xFFFFD60A)},
      {'key': 'Críticos', 'label': 'Críticos', 'icon': Icons.warning_amber_rounded, 'color': const Color(0xFFFF453A)},
      {'key': 'Vencidos', 'label': 'Vencidos', 'icon': Icons.event_busy_rounded, 'color': const Color(0xFFFF453A)},
      {'key': 'Cerrados', 'label': 'Cerrados', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF30D158)},
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF131B2E) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _selectedTab == t['key'];
          final Color tabColor = t['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTab != t['key']) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedTab = t['key'] as String;
                  });
                  _animController.forward(from: 0.0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [tabColor, tabColor.withOpacity(0.75)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: tabColor.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 15,
                      color: isSelected ? Colors.white : (_isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (_isDark ? Colors.white60 : const Color(0xFF64748B)),
                        fontSize: 10.5,
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

  /// Dynamic Hero Total Card (Estilo Hero Card de Salarios)
  Widget _buildDynamicHeroTotalCard({
    required int totalPedidos,
    required int totalArticulos,
    required double totalUnidades,
    required int cumplidos,
    required int enPlan,
    required int vencidos,
  }) {
    final double cumplidosPct = totalPedidos > 0 ? (cumplidos / totalPedidos * 100) : 0.0;
    final double enPlanPct = totalPedidos > 0 ? (enPlan / totalPedidos * 100) : 0.0;
    final double vencidosPct = totalPedidos > 0 ? (vencidos / totalPedidos * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? const [
                  Color(0xFF0F2B36),
                  Color(0xFF143B4A),
                  Color(0xFF0A202A),
                ]
              : const [
                  Color(0xFFF0FDFA),
                  Colors.white,
                  Color(0xFFF8FAFC),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00C7BE).withOpacity(_isDark ? 0.35 : 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C7BE).withOpacity(_isDark ? 0.15 : 0.08),
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
                      color: Color(0xFF00C7BE),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedBarco == 'Todos'
                        ? "TOTAL PEDIDOS COMPRAS"
                        : "PEDIDOS — ${_selectedBarco.toUpperCase()}",
                    style: TextStyle(
                      color: _isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF0F766E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C7BE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00C7BE).withOpacity(0.4)),
                ),
                child: Text(
                  "${cumplidosPct.toStringAsFixed(0)}% CUMPLIMIENTO",
                  style: const TextStyle(color: Color(0xFF00C7BE), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$totalPedidos",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$totalArticulos artículos solicitados · ${totalUnidades.toStringAsFixed(0)} unidades totales",
            style: TextStyle(color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (cumplidos > 0)
                    Expanded(
                      flex: cumplidos,
                      child: Container(color: const Color(0xFF30D158)), // Verde cumplidos
                    ),
                  if (enPlan > 0)
                    Expanded(
                      flex: enPlan,
                      child: Container(color: const Color(0xFFFFD60A)), // Amarillo en plan
                    ),
                  if (vencidos > 0)
                    Expanded(
                      flex: vencidos,
                      child: Container(color: const Color(0xFFFF453A)), // Rojo vencidos
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendPill("Cumplidos $cumplidos (${cumplidosPct.toStringAsFixed(0)}%)", const Color(0xFF30D158)),
              _buildLegendPill("En Plan $enPlan (${enPlanPct.toStringAsFixed(0)}%)", const Color(0xFFFFD60A)),
              _buildLegendPill("Vencidos $vencidos (${vencidosPct.toStringAsFixed(0)}%)", const Color(0xFFFF453A)),
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
          style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Twin Cards: Críticos & No Críticos con AppleMiniRings
  Widget _buildDynamicRingsGrid({
    required int criticosTotal,
    required int criticosCumplidos,
    required int criticosVencidos,
    required int criticosEnPlan,
    required int noCriticosTotal,
    required int noCriticosCumplidos,
    required int noCriticosVencidos,
    required int noCriticosEnPlan,
    required int cumplidosTotal,
    required int totalPedidos,
  }) {
    final double criticosCumplidosRatio = criticosTotal > 0 ? (criticosCumplidos / criticosTotal) : 0.0;

    final double noCriticosCumplidosRatio = noCriticosTotal > 0 ? (noCriticosCumplidos / noCriticosTotal) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 550;

        final cardCriticos = _buildAppleRingKpiCard(
          title: "Pedidos Críticos",
          count: criticosTotal,
          subtitle: "$criticosVencidos vencidos · $criticosEnPlan en plan",
          percentage: criticosCumplidosRatio,
          ringColor: const Color(0xFFFF453A),
          icon: Icons.warning_amber_rounded,
          cumplidos: criticosCumplidos,
          vencidos: criticosVencidos,
          enPlan: criticosEnPlan,
        );

        final cardNoCriticos = _buildAppleRingKpiCard(
          title: "Pedidos No Críticos",
          count: noCriticosTotal,
          subtitle: "$noCriticosVencidos vencidos · $noCriticosEnPlan en plan",
          percentage: noCriticosCumplidosRatio,
          ringColor: const Color(0xFF30D158),
          icon: Icons.inventory_2_rounded,
          cumplidos: noCriticosCumplidos,
          vencidos: noCriticosVencidos,
          enPlan: noCriticosEnPlan,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cardCriticos),
              const SizedBox(width: 14),
              Expanded(child: cardNoCriticos),
            ],
          );
        } else {
          return Column(
            children: [
              cardCriticos,
              const SizedBox(height: 12),
              cardNoCriticos,
            ],
          );
        }
      },
    );
  }

  Widget _buildAppleRingKpiCard({
    required String title,
    required int count,
    required String subtitle,
    required double percentage,
    required Color ringColor,
    required IconData icon,
    required int cumplidos,
    required int vencidos,
    required int enPlan,
  }) {
    final pctText = '${(percentage * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ringColor.withOpacity(_isDark ? 0.35 : 0.5)),
        boxShadow: [
          BoxShadow(
            color: ringColor.withOpacity(_isDark ? 0.1 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ringColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: ringColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              AppleMiniRing(
                percentage: percentage,
                ringColor: ringColor,
                size: 46,
                strokeWidth: 5.0,
                centerChild: Text(
                  pctText,
                  style: TextStyle(color: _textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$count",
            style: TextStyle(color: _textPrimary, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: _textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: _isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniMetric(cumplidos, "Cumplidos", const Color(0xFF30D158)),
                _buildMiniMetric(vencidos, "Vencidos", const Color(0xFFFF453A)),
                _buildMiniMetric(enPlan, "En Plan", const Color(0xFFFFD60A)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(int value, String label, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: TextStyle(color: _textSecondary, fontSize: 9.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// Gráficos Donut Dinámicos (Idénticos a la Intranet)
  Widget _buildDynamicDonutsCard({
    required int total,
    required int vencidos,
    required int cumplidos,
    required int enPlan,
  }) {
    final int noVencidos = total - vencidos;
    final double vencidosPct = total > 0 ? (vencidos / total * 100) : 0.0;
    final double noVencidosPct = total > 0 ? (noVencidos / total * 100) : 0.0;

    final segmentsCount = [
      DonutSegment(label: "No Vencidos", value: noVencidos.toDouble(), color: const Color(0xFF30D158)),
      DonutSegment(label: "Vencidos", value: vencidos.toDouble(), color: const Color(0xFFFF453A)),
    ];

    final segmentsPct = [
      DonutSegment(label: "No Vencidos", value: noVencidosPct, color: const Color(0xFF30D158)),
      DonutSegment(label: "Vencidos", value: vencidosPct, color: const Color(0xFFFF453A)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Estado de Vencimientos",
                style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildLegendPill("Vencidos ($vencidos)", const Color(0xFFFF453A)),
                  const SizedBox(width: 10),
                  _buildLegendPill("No Vencidos ($noVencidos)", const Color(0xFF30D158)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  AppleDonutChart(
                    segments: segmentsCount,
                    centerTitle: "$vencidos",
                    centerSubtitle: "Vencidos",
                    size: 140,
                    holeRadiusRatio: 0.68,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Pedidos",
                    style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                children: [
                  AppleDonutChart(
                    segments: segmentsPct,
                    centerTitle: "${vencidosPct.toStringAsFixed(0)}%",
                    centerSubtitle: "% Vencidos",
                    size: 140,
                    holeRadiusRatio: 0.68,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "% Pedidos",
                    style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dynamic Fleet Breakdown Card
  Widget _buildDynamicFleetCard() {
    final summary = _comprasData?.summary;
    if (summary == null || summary.porBarco.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Distribución por Barco",
                style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                "${summary.porBarco.length} BUQUES",
                style: TextStyle(color: _textTertiary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...summary.porBarco.map((b) {
            Color shipColor = const Color(0xFF007AFF);
            if (b.barco.toLowerCase().contains('gustavo')) shipColor = const Color(0xFF30D158);
            if (b.barco.toLowerCase().contains('nany')) shipColor = const Color(0xFFF39200);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_boat_filled_rounded, size: 15, color: shipColor),
                          const SizedBox(width: 7),
                          Text(
                            b.barco,
                            style: TextStyle(color: _textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (b.criticos > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${b.criticos} críticos",
                                style: const TextStyle(color: Colors.redAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        "${b.totalPedidos} pedidos (${b.enPlan} abiertos)",
                        style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: b.cumplidos,
                            child: Container(color: const Color(0xFF30D158)),
                          ),
                          Expanded(
                            flex: b.enPlan,
                            child: Container(color: const Color(0xFFFFD60A)),
                          ),
                          Expanded(
                            flex: b.vencidos,
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

  /// Tarjeta de Pedido Individual (Estilo Salarios / Apple Cupertino)
  Widget _buildPedidoCard(PedidoCompra pedido) {
    Color barcoColor = const Color(0xFF007AFF);
    if (pedido.barco.toLowerCase().contains('gustavo')) barcoColor = const Color(0xFF30D158);
    if (pedido.barco.toLowerCase().contains('nany')) barcoColor = const Color(0xFFF39200);

    final bool isVencido = pedido.vigencia.toLowerCase() == 'vencido' || pedido.estado.toLowerCase() == 'vencido';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pedido.esCritico
              ? Colors.redAccent.withOpacity(0.4)
              : isVencido
                  ? Colors.orangeAccent.withOpacity(0.25)
                  : _cardBorder,
          width: pedido.esCritico ? 1.2 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showPedidoDetailModal(pedido),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Número + Badges estilo Apple
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: barcoColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_boat_filled_rounded, size: 12, color: barcoColor),
                                const SizedBox(width: 4),
                                Text(
                                  pedido.barco,
                                  style: TextStyle(color: barcoColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              pedido.numero,
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pedido.esCritico)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF453A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFF453A).withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 11, color: Color(0xFFFF453A)),
                            SizedBox(width: 3),
                            Text(
                              "CRÍTICO",
                              style: TextStyle(color: Color(0xFFFF453A), fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      )
                    else if (pedido.urgencia.toLowerCase() == 'urgente')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9F0A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFF9F0A).withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 11, color: Color(0xFFFF9F0A)),
                            SizedBox(width: 3),
                            Text(
                              "URGENTE",
                              style: TextStyle(color: Color(0xFFFF9F0A), fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Department & Category
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        pedido.departamento.toLowerCase().contains('máquina')
                            ? Icons.settings_rounded
                            : Icons.anchor_rounded,
                        size: 13,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${pedido.departamento} · ${pedido.tipoPedido}",
                      style: TextStyle(color: _textSecondary, fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      "${pedido.cantidadArticulos} art. (${pedido.totalUnidadesSolicitadas.toStringAsFixed(0)} u)",
                      style: TextStyle(color: _textTertiary, fontSize: 11.5),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: _cardBorder, height: 1),
                const SizedBox(height: 10),

                // Footer row: Estado + Fechas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: pedido.cumplido
                                ? const Color(0xFF30D158)
                                : isVencido
                                    ? const Color(0xFFFF453A)
                                    : const Color(0xFFFFD60A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          pedido.estado,
                          style: TextStyle(
                            color: pedido.cumplido
                                ? const Color(0xFF30D158)
                                : isVencido
                                    ? const Color(0xFFFF453A)
                                    : const Color(0xFFFFD60A),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: _textTertiary),
                        const SizedBox(width: 5),
                        Text(
                          pedido.fechaPedido,
                          style: TextStyle(color: _textTertiary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPedidoDetailModal(PedidoCompra pedido) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textTertiary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pedido.numero,
                                style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${pedido.barcoNombreCompleto} · ${pedido.departamento}",
                                style: TextStyle(color: _textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: _textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: _cardBorder, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildModalDetailItem("Estado", pedido.estado),
                          _buildModalDetailItem("Urgencia", pedido.urgencia),
                          _buildModalDetailItem("Plazo", "${pedido.diasPlazo} días"),
                          _buildModalDetailItem("Vencimiento", pedido.fechaVencimiento ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "ARTÍCULOS SOLICITADOS (${pedido.articulos.length})",
                        style: TextStyle(
                          color: _textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: pedido.articulos.length,
                      itemBuilder: (context, i) {
                        final art = pedido.articulos[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF007AFF), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      art.nombre,
                                      style: TextStyle(color: _textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                                    ),
                                    if (art.descripcion.isNotEmpty && art.descripcion != art.nombre)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          art.descripcion,
                                          style: TextStyle(color: _textSecondary, fontSize: 11.5),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (art.esDispositivoCritico)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              "DISPOSITIVO CRÍTICO",
                                              style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        Text(
                                          "Ref: ${art.codigoReferencia}",
                                          style: TextStyle(color: _textTertiary, fontSize: 10.5),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${art.cantidadSolicitada.toStringAsFixed(0)} ${art.unidad}",
                                style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
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
          },
        );
      },
    );
  }

  Widget _buildModalDetailItem(String title, String val) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: _textTertiary, fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
