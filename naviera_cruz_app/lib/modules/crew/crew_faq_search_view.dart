import 'package:flutter/material.dart';
import '../../services/crew_faq_service.dart';
import '../../models/crew_profile.dart';

class CrewFaqSearchView extends StatefulWidget {
  final String? initialQuery;
  final CrewProfile? profile;
  final Function(int)? onNavigateTab;

  final bool isTabModule;

  const CrewFaqSearchView({
    super.key,
    this.initialQuery,
    this.profile,
    this.onNavigateTab,
    this.isTabModule = false,
  });

  @override
  State<CrewFaqSearchView> createState() => _CrewFaqSearchViewState();
}

class _CrewFaqSearchViewState extends State<CrewFaqSearchView> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  FAQCategory? _selectedCategory;
  final Set<String> _expandedIds = {};
  final Set<FAQCategory> _collapsedCategories = {};
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: initial);
    _searchQuery = initial.trim();
    // Si viene con búsqueda inicial, expandir el primer resultado que coincida
    if (_searchQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoExpandFirstMatch();
      });
    }
    // Sincronizar dinámicamente con la Intranet NCS al ingresar
    _syncFaqs();
  }

  Future<void> _syncFaqs({bool force = false}) async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    try {
      await CrewFAQService.shared.fetchFaqsFromIntranet(forceRefresh: force);
    } catch (_) {}
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _autoExpandFirstMatch() {
    final matches = _filteredItems;
    if (matches.isNotEmpty) {
      setState(() {
        _expandedIds.add(matches.first.id);
      });
    }
  }

  List<CrewFAQItem> get _filteredItems {
    var items = CrewFAQService.shared.currentCatalog;

    // Filtro por categoría
    if (_selectedCategory != null) {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }

    // Filtro por texto de búsqueda
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return items;
    }

    final queryWords = query
        .replaceAll(RegExp(r'[¿?¡!.,:;()\[\]"_/\-]'), ' ')
        .split(' ')
        .where((w) => w.length > 2)
        .toList();

    // Puntuación y ordenamiento por relevancia
    final scored = <MapEntry<CrewFAQItem, double>>[];

    for (final item in items) {
      double score = 0.0;
      final qLower = item.mainQuestion.toLowerCase();
      final aLower = item.answerTemplate.toLowerCase();

      // Coincidencia exacta o contenida en pregunta principal
      if (qLower == query) {
        score += 100.0;
      } else if (qLower.contains(query)) {
        score += 50.0;
      }

      // Coincidencia en variantes
      for (final v in item.variants) {
        final vLower = v.toLowerCase();
        if (vLower == query) {
          score += 80.0;
        } else if (vLower.contains(query)) {
          score += 40.0;
        }
      }

      // Coincidencia por palabras clave
      for (final word in queryWords) {
        if (qLower.contains(word)) score += 15.0;
        for (final v in item.variants) {
          if (v.toLowerCase().contains(word)) score += 10.0;
        }
        if (aLower.contains(word)) score += 5.0;
      }

      // Coincidencia con categoría
      if (item.category.displayName.toLowerCase().contains(query)) {
        score += 20.0;
      }

      if (score > 0) {
        scored.add(MapEntry(item, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  List<_FaqListItem> get _displayItems {
    final filtered = _filteredItems;
    if (filtered.isEmpty) return [];

    if (_selectedCategory != null) {
      final isCollapsed = _collapsedCategories.contains(_selectedCategory!);
      final list = <_FaqListItem>[
        _CategoryHeaderItem(_selectedCategory!, filtered.length),
      ];
      if (!isCollapsed) {
        for (int i = 0; i < filtered.length; i++) {
          list.add(_FaqCardItem(filtered[i], i));
        }
      }
      return list;
    }

    final list = <_FaqListItem>[];
    final Map<FAQCategory, List<CrewFAQItem>> grouped = {};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    for (final cat in FAQCategory.values) {
      final items = grouped[cat];
      if (items != null && items.isNotEmpty) {
        list.add(_CategoryHeaderItem(cat, items.length));
        if (!_collapsedCategories.contains(cat)) {
          for (int i = 0; i < items.length; i++) {
            list.add(_FaqCardItem(items[i], i));
          }
        }
      }
    }

    return list;
  }

  void _toggleCategoryCollapse(FAQCategory cat) {
    setState(() {
      if (_collapsedCategories.contains(cat)) {
        _collapsedCategories.remove(cat);
      } else {
        _collapsedCategories.add(cat);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _expandedIds.clear();
    });
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _navigateToSection(int tabIndex) {
    if (!widget.isTabModule && Navigator.canPop(context)) {
      Navigator.of(context).pop(); // Volver a la pantalla principal si fue abierta como modal/push
    }
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(tabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0057B8),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.isTabModule
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: "Volver",
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "Preguntas Frecuentes",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Respuestas oficiales y procedimientos predefinidos",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded, color: Colors.white),
              tooltip: "Sincronizar con Intranet",
              onPressed: () => _syncFaqs(force: true),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barra de Búsqueda Superior
              Container(
                color: const Color(0xFF0057B8),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: "¿Qué necesitás resolver? (ej: francos, incidente, buque)",
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF0057B8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              color: const Color(0xFF64748B),
                              onPressed: _clearSearch,
                              tooltip: "Limpiar búsqueda",
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
              ),

              // 2. Selector Desplegable de Categorías (estilo Intranet NCS)
              _buildCategoryDropdown(isDark: isDark),

              // 2b. Chips Rápidos de Categorías
              Container(
                color: isDark ? const Color(0xFF131C2E) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _buildCategoryChip(
                        label: "Todas (${CrewFAQService.shared.currentCatalog.length})",
                        icon: Icons.all_inclusive_rounded,
                        isSelected: _selectedCategory == null,
                        onTap: () {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      ...FAQCategory.values.map((cat) {
                        final count = CrewFAQService.shared.currentCatalog.where((i) => i.category == cat).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildCategoryChip(
                            label: "${cat.displayName} ($count)",
                            icon: _getCategoryIcon(cat),
                            isSelected: _selectedCategory == cat,
                            onTap: () {
                              setState(() {
                                _selectedCategory = (_selectedCategory == cat) ? null : cat;
                              });
                            },
                            isDark: isDark,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // 3. Encabezado con Contador de Resultados y Agrupación
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? "RESULTADOS DE BÚSQUEDA (${filtered.length})"
                            : (_selectedCategory != null
                                ? "${_selectedCategory!.displayName.toUpperCase()} (${filtered.length})"
                                : "PREGUNTAS FRECUENTES (${filtered.length}) • AGRUPADAS POR CATEGORÍA"),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty || _selectedCategory != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = null;
                            _clearSearch();
                          });
                        },
                        child: const Text(
                          "Restablecer filtros",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0057B8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 4. Lista de Preguntas Frecuentes Agrupadas
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: () => _syncFaqs(force: true),
                        color: const Color(0xFF0057B8),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _displayItems.length,
                          itemBuilder: (context, index) {
                            final entry = _displayItems[index];
                            if (entry is _CategoryHeaderItem) {
                              return _buildCategoryGroupHeader(
                                category: entry.category,
                                count: entry.count,
                                isDark: isDark,
                              );
                            } else if (entry is _FaqCardItem) {
                              final item = entry.item;
                              final isExpanded = _expandedIds.contains(item.id);
                              final isBlue = entry.indexInCategory % 2 == 0;
                              return _buildFaqCard(
                                item: item,
                                isExpanded: isExpanded,
                                isBlue: isBlue,
                                isDark: isDark,
                                cardColor: cardColor,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({required bool isDark}) {
    final catalog = CrewFAQService.shared.currentCatalog;
    return Container(
      color: isDark ? const Color(0xFF131C2E) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<FAQCategory?>(
            value: _selectedCategory,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0057B8), size: 24),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            items: [
              DropdownMenuItem<FAQCategory?>(
                value: null,
                child: Row(
                  children: [
                    const Icon(Icons.all_inclusive_rounded, size: 18, color: Color(0xFF0057B8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Todas las categorías (${catalog.length})",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...FAQCategory.values.map((cat) {
                final count = catalog.where((i) => i.category == cat).length;
                return DropdownMenuItem<FAQCategory?>(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(cat), size: 18, color: const Color(0xFF0057B8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${cat.displayName} ($count)",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedCategory == cat ? FontWeight.bold : FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (FAQCategory? newCat) {
              setState(() {
                _selectedCategory = newCat;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGroupHeader({
    required FAQCategory category,
    required int count,
    required bool isDark,
  }) {
    final isCollapsed = _collapsedCategories.contains(category);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleCategoryCollapse(category),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16253D) : const Color(0xFFE8F1FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBCD8F8),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0057B8).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    size: 18,
                    color: const Color(0xFF0057B8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? Colors.white : const Color(0xFF0F2B48),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0057B8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$count",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF0057B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final bgColor = isSelected
        ? const Color(0xFF0057B8)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white70 : const Color(0xFF475569));
    final iconColor = isSelected ? Colors.white : const Color(0xFF0066CC);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0057B8)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCard({
    required CrewFAQItem item,
    required bool isExpanded,
    required bool isBlue,
    required bool isDark,
    required Color cardColor,
  }) {
    final bgColor = isBlue
        ? (isDark ? const Color(0xFF0F2B48) : const Color(0xFFF0F7FF))
        : (isDark ? const Color(0xFF332014) : const Color(0xFFFFF7ED));
    final borderColor = isBlue
        ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD0E4FF))
        : (isDark ? const Color(0xFF5A351D) : const Color(0xFFFFEDD5));
    final primaryColor = isBlue ? const Color(0xFF0057B8) : const Color(0xFFC2410C);
    final iconColor = isBlue ? const Color(0xFF0066CC) : const Color(0xFFEA580C);

    final resolvedAnswer = item.resolveAnswer(widget.profile);

    // Verificar si la respuesta sugiere navegar a alguna pestaña
    final bool hasSeguridadLink = item.category == FAQCategory.seguridadReportes ||
        item.answerTemplate.contains("Seguridad") ||
        item.answerTemplate.contains("Reportar Incidente");
    final bool hasBoletinesLink = item.category == FAQCategory.equiposDocumentos ||
        item.answerTemplate.contains("Boletines");
    final bool hasCursosLink = item.category == FAQCategory.embarquesCapacitacion ||
        item.answerTemplate.contains("Cursos");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleExpanded(item.id),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila de Categoría y Chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_getCategoryIcon(item.category), color: iconColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chip sutil de categoría
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.mainQuestion,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                ],
              ),

              // Contenido Expandido: Respuesta Oficial Predefinida
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF091426) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de información oficial
                      Row(
                        children: [
                          Icon(
                            item.reviewStatus == 'verificado'
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                            size: 15,
                            color: item.reviewStatus == 'verificado'
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.reviewStatus == 'verificado'
                                ? "Respuesta Oficial Verificada"
                                : "Información Institucional",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.reviewStatus == 'verificado'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Texto de la respuesta
                      Text(
                        resolvedAnswer,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),

                      // Fuente Oficial
                      const SizedBox(height: 10),
                      Text(
                        "Fuente: ${item.source}",
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),

                      // Botones de acción directa para ir a la pestaña relevante
                      if (hasSeguridadLink || hasBoletinesLink || hasCursosLink) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (hasSeguridadLink)
                              ElevatedButton.icon(
                                onPressed: () => _navigateToSection(1),
                                icon: const Icon(Icons.shield_rounded, size: 14),
                                label: const Text("Ir a Seguridad", style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0057B8),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            if (hasBoletinesLink)
                              ElevatedButton.icon(
                                onPressed: () => _navigateToSection(2),
                                icon: const Icon(Icons.description_rounded, size: 14),
                                label: const Text("Ver Boletines", style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0057B8),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            if (hasCursosLink)
                              ElevatedButton.icon(
                                onPressed: () => _navigateToSection(3),
                                icon: const Icon(Icons.school_rounded, size: 14),
                                label: const Text("Ir a Cursos", style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0057B8),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: isDark ? Colors.white38 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No se encontraron preguntas oficiales",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No existen preguntas predefinidas que coincidan con \"$_searchQuery\".\n\nLos tripulantes disponen de un catálogo oficial con 70 preguntas y respuestas predefinidas sobre seguridad, familiarización, descanso, documentación, bienestar, sistemas, uso de la app y ciberseguridad.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _clearSearch();
                  _selectedCategory = null;
                });
              },
              icon: const Icon(Icons.list_alt_rounded, size: 16),
              label: const Text("Ver todas las 70 preguntas oficiales"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0057B8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(FAQCategory category) {
    switch (category) {
      case FAQCategory.seguridadReportes:
        return Icons.shield_rounded;
      case FAQCategory.emergenciasFamiliarizacion:
        return Icons.warning_amber_rounded;
      case FAQCategory.descansoAptitud:
        return Icons.hotel_rounded;
      case FAQCategory.embarquesCapacitacion:
        return Icons.badge_rounded;
      case FAQCategory.consultasBienestar:
        return Icons.people_rounded;
      case FAQCategory.equiposDocumentos:
        return Icons.build_rounded;
      case FAQCategory.usoApp:
        return Icons.phone_android_rounded;
      case FAQCategory.ciberseguridadSoporte:
        return Icons.security_rounded;
      case FAQCategory.general:
        return Icons.info_outline_rounded;
      case FAQCategory.sistemasTI:
        return Icons.computer_rounded;
      case FAQCategory.operaciones:
        return Icons.anchor_rounded;
      case FAQCategory.rrhh:
        return Icons.groups_rounded;
      case FAQCategory.compras:
        return Icons.shopping_cart_rounded;
      case FAQCategory.barcosFlota:
        return Icons.directions_boat_rounded;
    }
  }
}

abstract class _FaqListItem {}

class _CategoryHeaderItem extends _FaqListItem {
  final FAQCategory category;
  final int count;
  _CategoryHeaderItem(this.category, this.count);
}

class _FaqCardItem extends _FaqListItem {
  final CrewFAQItem item;
  final int indexInCategory;
  _FaqCardItem(this.item, this.indexInCategory);
}

