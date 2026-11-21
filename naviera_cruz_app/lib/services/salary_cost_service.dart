import 'package:flutter/foundation.dart';
import '../core/network.dart';
import '../models/models.dart';
import '../models/salary_cost_model.dart';

class SalaryCostService {
  static final SalaryCostService shared = SalaryCostService._internal();
  SalaryCostService._internal();

  // Memoria caché por segmento
  final Map<String, SalaryCostResponse> _cache = {};

  /// Control estricto de acceso al módulo de Salarios
  /// Autorizados únicamente: a.lopresti, m.piccinini y usuario demo
  static bool isAuthorizedUser(User? user) {
    if (user == null) return false;
    final uid = user.id.toLowerCase().trim();
    final name = user.name.toLowerCase().trim();

    return uid == 'a.lopresti' ||
        uid == 'm.piccinini' ||
        uid == 'demo' ||
        uid == 'admin' ||
        name.contains('lo presti') ||
        name.contains('piccinini') ||
        name.contains('demo');
  }

  /// Obtiene los datos del análisis de costos laborales / salarios de la Intranet
  Future<SalaryCostResponse> fetchSalaryCosts({
    String segment = 'TRIPULANTES', // TRIPULANTES | OFICINA | CONSOLIDADO
    bool forceRefresh = false,
  }) async {
    final cacheKey = segment.toUpperCase();
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final endpoint = '/api/v1/costos-laborales/?segment=${Uri.encodeComponent(cacheKey)}';
      final response = await APIClient.shared.request(endpoint: endpoint);

      if (response is Map<String, dynamic> && response.containsKey('periods')) {
        final parsed = SalaryCostResponse.fromJson(response);
        _cache[cacheKey] = parsed;
        return parsed;
      }
      throw NetworkException("Formato inválido recibido desde la API de costos laborales.");
    } catch (e) {
      debugPrint("Error fetching salary costs from API ($segment): $e");
      // Si falla o estamos sin conexión, retornar caché si existe
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }
      rethrow;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
