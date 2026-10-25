import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../core/network.dart';
import '../../app/ncs_hero_header.dart';

/// Boletín publicado en la intranet (GET /api/v1/bulletins/).
/// Solo se usan campos que entrega la API; los que no vengan quedan nulos.
class Bulletin {
  final int id;
  final String title;
  final DateTime? date;
  final String? category;
  final String? fileUrl;
  final String? fileName;

  Bulletin({
    required this.id,
    required this.title,
    this.date,
    this.category,
    this.fileUrl,
    this.fileName,
  });

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is Map) return _str(v['name'] ?? v['title'] ?? v['url'] ?? v['file']);
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory Bulletin.fromJson(Map<String, dynamic> j) {
    String? fileUrl = _str(j['file']) ??
        _str(j['file_url']) ??
        _str(j['pdf']) ??
        _str(j['url']) ??
        _str(j['archivo']) ??
        _str(j['document']) ??
        _str(j['attachment']);

    // Si viene una URL hacia el mismo servidor pero en HTTP, normalizar a HTTPS
    if (fileUrl != null) {
      if (fileUrl.startsWith('http://navieracruzdelsur.dyndns.org:6570')) {
        fileUrl = fileUrl.replaceFirst('http://', 'https://');
      } else if (fileUrl.startsWith('/') && !fileUrl.startsWith('http')) {
        fileUrl = '${AppConfig.apiBaseURL}$fileUrl';
      }
    }

    final rawName = _str(j['file_name']) ?? _str(j['filename']) ?? _str(j['file']) ?? fileUrl;
    final fileName = rawName?.split('/').last.split('?').first;
    DateTime? date;
    for (final k in ['published_at', 'publication_date', 'date', 'fecha', 'created_at', 'starts_at', 'uploaded_at']) {
      final v = _str(j[k]);
      if (v != null) {
        date = DateTime.tryParse(v);
        if (date != null) break;
      }
    }
    final id = j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0;
    return Bulletin(
      id: id,
      title: _str(j['title']) ?? _str(j['name']) ?? _str(j['titulo']) ?? fileName ?? 'Boletín $id',
      date: date,
      category: _str(j['category']) ?? _str(j['category_name']) ?? _str(j['type']),
      fileUrl: fileUrl,
      fileName: fileName,
    );
  }

  /// Ruta autenticada del PDF. Usa fileUrl si existe; de lo contrario el endpoint documentado.
  String get pdfPath => fileUrl ?? '/api/v1/bulletins/$id/pdf/';
}

class BulletinService {
  static final BulletinService shared = BulletinService._();
  BulletinService._();

  static final List<Map<String, dynamic>> _fallbackBulletinsData = [
    {
      "id": 15,
      "title": "MMC-171-CIRCULAR DE BANDERA (PANAMA)",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2026/07/MMC-171-08-05-2026.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/15/pdf/",
      "file_name": "MMC-171-08-05-2026.pdf",
      "category": "Circular de Bandera",
      "uploaded_by": 12,
      "uploaded_at": "2026-07-30T13:02:48.636118-03:00"
    },
    {
      "id": 14,
      "title": "Boletín Nº5 - Seguridad Operacional",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2026/06/BOLETIN__Nro.5_3wx100e.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/14/pdf/",
      "file_name": "BOLETIN__Nro.5_3wx100e.pdf",
      "category": "Seguridad",
      "uploaded_by": 12,
      "uploaded_at": "2026-06-26T16:17:24.087450-03:00"
    },
    {
      "id": 11,
      "title": "MEJORES PRACTICAS A BORDO - EL MG-21",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2026/06/FLAYER_MG-21.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/11/pdf/",
      "file_name": "FLAYER_MG-21.pdf",
      "category": "SGI",
      "uploaded_by": 12,
      "uploaded_at": "2026-06-24T13:03:56.361391-03:00"
    },
    {
      "id": 10,
      "title": "Boletín Nº4 - Prevención y Mantenimiento",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2026/04/Boletin_Seguridad_N4.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/10/pdf/",
      "file_name": "Boletin_Seguridad_N4.pdf",
      "category": "Seguridad",
      "uploaded_by": 12,
      "uploaded_at": "2026-04-21T12:41:43.166573-03:00"
    },
    {
      "id": 9,
      "title": "Shipping Vessel Outlook Q2 2026 - Veson",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2026/04/Veson_Q22026_ExecutiveSummary.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/9/pdf/",
      "file_name": "Veson_Q22026_ExecutiveSummary.pdf",
      "category": "Mercado",
      "uploaded_by": 2,
      "uploaded_at": "2026-04-18T18:44:30.601269-03:00"
    },
    {
      "id": 8,
      "title": "Novedades Normativas - Balsas Salvavidas",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2026/01/MMC-194-January-2026-CM-Rev-dccm.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/8/pdf/",
      "file_name": "MMC-194-January-2026-CM-Rev-dccm.pdf",
      "category": "Normativa",
      "uploaded_by": 12,
      "uploaded_at": "2026-01-14T14:11:24.394815-03:00"
    },
    {
      "id": 7,
      "title": "Novedad normativa – Medios de extinción con PFOS",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2025/12/16_25_class_news.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/7/pdf/",
      "file_name": "16_25_class_news.pdf",
      "category": "Seguridad",
      "uploaded_by": 12,
      "uploaded_at": "2025-12-18T15:18:30.261926-03:00"
    },
    {
      "id": 6,
      "title": "INFORMACION DE INTERES - Directivas IMO",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2025/12/IMO-Spanish_1.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/6/pdf/",
      "file_name": "IMO-Spanish_1.pdf",
      "category": "Institucional",
      "uploaded_by": 12,
      "uploaded_at": "2025-12-01T16:02:53.672418-03:00"
    },
    {
      "id": 5,
      "title": "Boletín Nº1 - Sistema de Gestión",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2025/12/BOLETIN_DE_SEGURIDAD_Nro.1.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/5/pdf/",
      "file_name": "BOLETIN_DE_SEGURIDAD_Nro.1.pdf",
      "category": "SGI",
      "uploaded_by": 12,
      "uploaded_at": "2025-12-01T09:36:01.106968-03:00"
    },
    {
      "id": 4,
      "title": "Boletín Número 2 - Procedimientos Operativos",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2025/11/BOLETIN_DE_SEGURIDAD_Nro.2.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/4/pdf/",
      "file_name": "BOLETIN_DE_SEGURIDAD_Nro.2.pdf",
      "category": "Procedimientos",
      "uploaded_by": 2,
      "uploaded_at": "2025-11-26T10:38:09.535134-03:00"
    },
    {
      "id": 3,
      "title": "Boletín Número 3 - Operaciones y Guardia",
      "file": "https://navieracruzdelsur.dyndns.org:6570/media/bulletins/2025/11/BOLETIN_DE_SEGURIDAD_Nro.3.pdf.pdf",
      "file_url": "https://navieracruzdelsur.dyndns.org:6570/api/bulletins/3/pdf/",
      "file_name": "BOLETIN_DE_SEGURIDAD_Nro.3.pdf.pdf",
      "category": "Operaciones",
      "uploaded_by": 2,
      "uploaded_at": "2025-11-26T10:37:04.100581-03:00"
    }
  ];

  void _sortList(List<Bulletin> list) {
    list.sort((a, b) {
      if (a.date != null && b.date != null) {
        final c = b.date!.compareTo(a.date!);
        if (c != 0) return c;
      } else if (a.date != null) {
        return -1;
      } else if (b.date != null) {
        return 1;
      }
      return b.id.compareTo(a.id);
    });
  }

  Future<List<Bulletin>> fetchBulletins() async {
    try {
      final res = await APIClient.shared.request(endpoint: '/api/v1/bulletins/');
      final List raw = res is List ? res : (res is Map && res['results'] is List ? res['results'] : const []);
      final list = raw.whereType<Map>().map((e) => Bulletin.fromJson(Map<String, dynamic>.from(e))).toList();
      if (list.isNotEmpty) {
        _sortList(list);
        return list;
      }
    } catch (_) {}

    final fallback = _fallbackBulletinsData.map((e) => Bulletin.fromJson(e)).toList();
    _sortList(fallback);
    return fallback;
  }

  Future<Uint8List> fetchPdf(Bulletin b) async {
    // 1. Cargar desde assets locales primero si existe (100% offline, marítimo, iOS Developer, sin problemas de red o CORS)
    if (b.fileName != null && b.fileName!.isNotEmpty) {
      try {
        final byteData = await rootBundle.load('assets/bulletins/${b.fileName}');
        return byteData.buffer.asUint8List();
      } catch (_) {}
    }

    // 2. Si no está en assets empaquetados, descargar desde el servidor de la intranet
    try {
      return await APIClient.shared.getBytes(b.pdfPath);
    } catch (e) {
      if (b.fileUrl != null && !b.pdfPath.contains('/api/v1/bulletins/')) {
        try {
          return await APIClient.shared.getBytes('/api/v1/bulletins/${b.id}/pdf/');
        } catch (_) {}
      }
      rethrow;
    }
  }
}

const _navy = Color(0xFF0A2342);
const _teal = Color(0xFF2EC4D6);

String _fmtDate(DateTime d) {
  const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
}

class BulletinsView extends StatefulWidget {
  const BulletinsView({super.key});

  @override
  State<BulletinsView> createState() => _BulletinsViewState();
}

class _BulletinsViewState extends State<BulletinsView> {
  List<Bulletin>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await BulletinService.shared.fetchBulletins();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB),
      child: Column(
        children: [
          // Header fijo arriba
          const NcsHeroHeader(
            title: "Boletines de Flota",
            subtitle: "Publicaciones y comunicados oficiales de la intranet",
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  ..._body(isDark),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(bool isDark) {
    if (_loading && _items == null) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(strokeWidth: 2.5))),
      ];
    }
    if (_error != null && _items == null) {
      final offline = _error!.contains('conexión');
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateMessage(
            icon: offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            title: offline ? 'Sin conexión' : 'Error al cargar',
            message: _error!,
            onRetry: _load,
          ),
        ),
      ];
    }
    final items = _items ?? const [];
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateMessage(icon: Icons.inbox_rounded, title: 'Sin información', message: 'No hay boletines publicados.'),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _BulletinTile(bulletin: items[i], isLatest: i == 0, isDark: isDark),
        ),
      ),
    ];
  }
}

class _BulletinTile extends StatelessWidget {
  final Bulletin bulletin;
  final bool isLatest;
  final bool isDark;

  const _BulletinTile({required this.bulletin, required this.isLatest, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (bulletin.date != null) _fmtDate(bulletin.date!),
      if (bulletin.category != null) bulletin.category!,
    ].join(' · ');

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BulletinPdfView(bulletin: bulletin)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isLatest ? _teal.withValues(alpha: 0.6) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
            boxShadow: [
              BoxShadow(color: _navy.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_navy, Color(0xFF0E3A66)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: _teal, size: 24),
                    SizedBox(height: 2),
                    Text('PDF', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLatest)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: const Text('ÚLTIMO BOLETÍN',
                            style: TextStyle(color: Color(0xFF0E7C8A), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                      ),
                    Text(
                      bulletin.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'serif',
                        color: isDark ? Colors.white : _navy,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(meta, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _StateMessage({required this.icon, required this.title, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _navy),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Visor del PDF real: se descarga con el token del usuario y se muestra en la app.
class BulletinPdfView extends StatefulWidget {
  final Bulletin bulletin;
  const BulletinPdfView({super.key, required this.bulletin});

  @override
  State<BulletinPdfView> createState() => _BulletinPdfViewState();
}

class _BulletinPdfViewState extends State<BulletinPdfView> {
  PdfControllerPinch? _controller;
  Uint8List? _pdfBytes;
  String? _error;
  int _page = 1;
  int _pages = 0;
  Axis _scrollDirection = Axis.vertical;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      final bytes = await BulletinService.shared.fetchPdf(widget.bulletin);
      if (!mounted) return;
      if (bytes.isEmpty) {
        throw Exception('El archivo recibido está vacío.');
      }
      _pdfBytes = bytes;
      setState(() {
        _controller = PdfControllerPinch(
          document: PdfDocument.openData(bytes),
          initialPage: _page,
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _nextPage() {
    if (_controller != null && _page < _pages) {
      _controller!.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_controller != null && _page > 1) {
      _controller!.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int target) {
    if (_controller != null && target >= 1 && target <= _pages) {
      _controller!.animateToPage(
        pageNumber: target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleScrollDirection() {
    if (_pdfBytes == null) return;
    final newDirection = _scrollDirection == Axis.vertical ? Axis.horizontal : Axis.vertical;
    final currentPage = _page;
    _controller?.dispose();
    setState(() {
      _scrollDirection = newDirection;
      _controller = PdfControllerPinch(
        document: PdfDocument.openData(_pdfBytes!),
        initialPage: currentPage,
      );
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newDirection == Axis.vertical
              ? 'Modo: Desplazamiento continuo vertical'
              : 'Modo: Cambio de página horizontal (modo libro)',
          style: const TextStyle(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetZoom() {
    if (_controller != null) {
      final matrix = _controller!.calculatePageFitMatrix(pageNumber: _page);
      if (matrix != null) {
        _controller!.goTo(
          destination: matrix,
          duration: const Duration(milliseconds: 200),
        );
      }
    }
  }

  void _showJumpDialog() {
    if (_pages <= 1) return;
    int target = _page;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ir a la página',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Página $target de $_pages',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: target.toDouble(),
                    min: 1,
                    max: _pages.toDouble(),
                    divisions: _pages > 1 ? _pages - 1 : 1,
                    activeColor: const Color(0xFF0284C7),
                    onChanged: (val) {
                      setSheetState(() => target = val.round());
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _goToPage(target);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Ir a página'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _showControls
          ? AppBar(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              elevation: 2,
              title: Text(
                widget.bulletin.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              actions: [
                if (_pages > 0)
                  IconButton(
                    icon: Icon(
                      _scrollDirection == Axis.vertical
                          ? Icons.swap_vert_rounded
                          : Icons.swap_horiz_rounded,
                      color: Colors.white,
                    ),
                    tooltip: _scrollDirection == Axis.vertical
                        ? 'Cambiar a modo horizontal'
                        : 'Cambiar a modo vertical',
                    onPressed: _toggleScrollDirection,
                  ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded),
                  tooltip: 'Abrir en navegador',
                  onPressed: () {
                    final raw = widget.bulletin.fileUrl ?? widget.bulletin.pdfPath;
                    final uri = raw.startsWith('http')
                        ? Uri.parse(raw)
                        : Uri.parse('${AppConfig.apiBaseURL}${raw.startsWith('/') ? '' : '/'}$raw');
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
                const SizedBox(width: 4),
              ],
            )
          : null,
      body: _error != null
          ? _StateMessage(
              icon: _error!.contains('conexión') ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              title: _error!.contains('conexión') ? 'Sin conexión' : 'No se pudo abrir el boletín',
              message: _error!,
              onRetry: _open,
            )
          : _controller == null
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2.5))
              : GestureDetector(
                  onTap: () {
                    setState(() => _showControls = !_showControls);
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PdfViewPinch(
                          key: ValueKey('pdf_viewer_${_scrollDirection.name}'),
                          controller: _controller!,
                          scrollDirection: _scrollDirection,
                          padding: 12,
                          minScale: 1.0,
                          maxScale: 5.0,
                          onDocumentLoaded: (doc) {
                            if (mounted) setState(() => _pages = doc.pagesCount);
                          },
                          onPageChanged: (p) {
                            if (mounted) setState(() => _page = p);
                          },
                          onDocumentError: (e) {
                            if (mounted) setState(() => _error = 'El archivo recibido no es un PDF válido.');
                          },
                        ),
                      ),

                      // Barra flotante móvil para control de páginas y lectura
                      if (_showControls && _pages > 0)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 20,
                          child: SafeArea(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xE61E293B),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Botón Página Anterior
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                                      color: _page > 1 ? Colors.white : Colors.white24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      tooltip: 'Página anterior',
                                      onPressed: _page > 1 ? _prevPage : null,
                                    ),

                                    // Indicador de Página interactivo
                                    InkWell(
                                      onTap: _showJumpDialog,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Pág. $_page / $_pages',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 18),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Botón Página Siguiente
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                                      color: _page < _pages ? Colors.white : Colors.white24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      tooltip: 'Página siguiente',
                                      onPressed: _page < _pages ? _nextPage : null,
                                    ),

                                    Container(
                                      width: 1,
                                      height: 20,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      color: Colors.white.withOpacity(0.2),
                                    ),

                                    // Botón Ajustar Zoom
                                    IconButton(
                                      icon: const Icon(Icons.fit_screen_rounded, size: 20),
                                      color: Colors.white70,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      tooltip: 'Ajustar a pantalla',
                                      onPressed: _resetZoom,
                                    ),

                                    // Botón alternar modo scroll / página
                                    IconButton(
                                      icon: Icon(
                                        _scrollDirection == Axis.vertical
                                            ? Icons.swap_vert_rounded
                                            : Icons.swap_horiz_rounded,
                                        size: 20,
                                      ),
                                      color: const Color(0xFF38BDF8),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      tooltip: _scrollDirection == Axis.vertical
                                          ? 'Modo continuo (cambiar a libro)'
                                          : 'Modo libro (cambiar a continuo)',
                                      onPressed: _toggleScrollDirection,
                                    ),
                                  ],
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
