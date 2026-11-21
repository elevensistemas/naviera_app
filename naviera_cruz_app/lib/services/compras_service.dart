import 'package:flutter/foundation.dart';
import '../core/network.dart';
import '../models/compras_model.dart';

class ComprasService {
  static final ComprasService shared = ComprasService._internal();
  ComprasService._internal();

  ComprasResponse? _cachedFullResponse;
  DateTime? _lastFetchTime;

  /// Obtiene los pedidos y resumen del módulo Compras desde la Intranet
  Future<ComprasResponse> fetchPedidos({
    String? barco, // 'Alfa C', 'Gustavo U', 'Nany' o null (todos)
    String? estado, // 'abierto' (o 'en_plan'), 'vencidos', 'cumplidos' o null
    bool? critico, // true | false | null
    String? urgencia, // 'Urgente' | 'Normal' | null
    String? q, // búsqueda de texto
    bool forceRefresh = false,
  }) async {
    // Si no hay filtros específicos y tenemos caché reciente (< 2 min), reutilizar
    final hasFilters = (barco != null && barco.isNotEmpty && barco.toLowerCase() != 'todos') ||
        (estado != null && estado.isNotEmpty && estado.toLowerCase() != 'todos') ||
        (critico != null) ||
        (urgencia != null && urgencia.isNotEmpty) ||
        (q != null && q.isNotEmpty);

    if (!forceRefresh && !hasFilters && _cachedFullResponse != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inMinutes < 2) {
        return _cachedFullResponse!;
      }
    }

    try {
      final queryParams = <String>[];
      if (barco != null && barco.isNotEmpty && barco.toLowerCase() != 'todos') {
        queryParams.add('barco=${Uri.encodeComponent(barco)}');
      }
      if (estado != null && estado.isNotEmpty && estado.toLowerCase() != 'todos') {
        queryParams.add('estado=${Uri.encodeComponent(estado)}');
      }
      if (critico != null) {
        queryParams.add('critico=$critico');
      }
      if (urgencia != null && urgencia.isNotEmpty) {
        queryParams.add('urgencia=${Uri.encodeComponent(urgencia)}');
      }
      if (q != null && q.trim().isNotEmpty) {
        queryParams.add('q=${Uri.encodeComponent(q.trim())}');
      }

      final queryStr = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final endpoint = '/api/v1/compras/pedidos/$queryStr';

      final response = await APIClient.shared.request(endpoint: endpoint);

      if (response is Map<String, dynamic> && response.containsKey('summary')) {
        final parsed = ComprasResponse.fromJson(response);
        if (!hasFilters) {
          _cachedFullResponse = parsed;
          _lastFetchTime = DateTime.now();
        }
        return parsed;
      }

      throw NetworkException("Respuesta inesperada del módulo de compras.");
    } catch (e) {
      debugPrint("Error fetching compras from API: $e");
      if (_cachedFullResponse != null) {
        return _cachedFullResponse!;
      }
      rethrow;
    }
  }

  void clearCache() {
    _cachedFullResponse = null;
    _lastFetchTime = null;
  }
}
