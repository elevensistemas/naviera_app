import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/centinela_fleet_models.dart';
import 'services.dart';

class CentinelaFleetService {
  static final CentinelaFleetService shared = CentinelaFleetService._internal();
  CentinelaFleetService._internal();

  static const String centinelaBaseUrl = "https://centinela.dyndns.org:5073";
  static const String localProxyBaseUrl = "http://127.0.0.1:8086";

  // Caché en memoria por buque
  final Map<String, CentinelaStsRisk> _cachedStsByVessel = {};
  final Map<String, DateTime> _stsCacheExpiryByVessel = {};

  /// Convierte el nombre o ID del buque en su clave canónica de Centinela
  static String? resolveVesselKey(String vesselIdentifier) {
    final v = vesselIdentifier.toUpperCase().trim();
    if (v.contains('ALFA') || v == '1' || v == '2071' || v == 'BT.ALFAC') {
      return 'BT.ALFAC';
    } else if (v.contains('GUSTAVO') || v == '2' || v == '6' || v == '2073' || v == 'BT.GUSTAVO.U') {
      return 'BT.GUSTAVO.U';
    } else if (v.contains('NANY') || v == '4' || v == '5' || v == '2072' || v == 'BT.NANY1') {
      return 'BT.NANY1';
    }
    // MONARCA I u otros quedan explícitamente excluidos
    return null;
  }

  /// Obtiene los datos de riesgo STS, auditoría OCIMF y estado operacional
  Future<CentinelaStsRisk?> fetchStsRisk(String vesselIdentifier, {bool forceRefresh = false}) async {
    final vesselKey = resolveVesselKey(vesselIdentifier);
    if (vesselKey == null) return null;

    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedStsByVessel.containsKey(vesselKey) &&
        _stsCacheExpiryByVessel.containsKey(vesselKey) &&
        now.isBefore(_stsCacheExpiryByVessel[vesselKey]!)) {
      return _cachedStsByVessel[vesselKey];
    }

    try {
      final cat = await EzvizService.shared.getCameraAccessToken();
      if (cat.isEmpty) {
        debugPrint("[CentinelaFleetService] No se pudo obtener CAT para STS risk");
        return _cachedStsByVessel[vesselKey];
      }

      final hosts = [
        if (kIsWeb)
          localProxyBaseUrl
        else ...[
          centinelaBaseUrl,
          "https://192.168.2.169:5073",
        ],
      ];

      for (final host in hosts) {
        try {
          final uri = Uri.parse('$host/api/v1/external/sts-risk/$vesselKey');
          var resp = await http.get(
            uri,
            headers: {
              'Authorization': 'Bearer $cat',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 4));

          // Si el token expiró, reintentar una vez tras forzar renovación del CAT
          if (resp.statusCode == 401) {
            EzvizService.shared.invalidateCATCache();
            final freshCat = await EzvizService.shared.getCameraAccessToken();
            if (freshCat.isNotEmpty) {
              resp = await http.get(
                uri,
                headers: {
                  'Authorization': 'Bearer $freshCat',
                  'Accept': 'application/json',
                },
              ).timeout(const Duration(seconds: 7));
            }
          }

          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            if (data is Map<String, dynamic> && data['status'] == 'ok') {
              final parsed = CentinelaStsRisk.fromJson(data);
              _cachedStsByVessel[vesselKey] = parsed;
              _stsCacheExpiryByVessel[vesselKey] = DateTime.now().add(const Duration(seconds: 20));
              return parsed;
            }
          }
        } catch (e) {
          debugPrint("[CentinelaFleetService] Falló consulta STS en host $host: $e");
        }
      }
    } catch (e) {
      debugPrint("[CentinelaFleetService] Error al consultar STS risk: $e");
    }

    return _cachedStsByVessel[vesselKey];
  }

  /// Genera una sesión segura para abrir el mapa táctico de Centinela con ticket efímero
  Future<CentinelaMapSession?> createMapSession(
    String vesselIdentifier, {
    String initialLayer = 'satellite',
    int initialHours = 6,
  }) async {
    final vesselKey = resolveVesselKey(vesselIdentifier);
    if (vesselKey == null) return null;

    try {
      final cat = await EzvizService.shared.getCameraAccessToken();
      if (cat.isEmpty) {
        debugPrint("[CentinelaFleetService] No se pudo obtener CAT para map-session");
        return null;
      }

      final payload = jsonEncode({
        'focus_vessel': vesselKey,
        'initial_layer': initialLayer,
        'initial_hours': initialHours,
      });

      final hosts = [
        if (kIsWeb)
          localProxyBaseUrl
        else ...[
          centinelaBaseUrl,
          "https://192.168.2.169:5073",
        ],
      ];

      for (final host in hosts) {
        try {
          final uri = Uri.parse('$host/api/v1/external/map-session');
          var resp = await http.post(
            uri,
            headers: {
              'Authorization': 'Bearer $cat',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: payload,
          ).timeout(const Duration(seconds: 4));

          // Si el token expiró, reintentar tras forzar renovación del CAT
          if (resp.statusCode == 401) {
            EzvizService.shared.invalidateCATCache();
            final freshCat = await EzvizService.shared.getCameraAccessToken();
            if (freshCat.isNotEmpty) {
              resp = await http.post(
                uri,
                headers: {
                  'Authorization': 'Bearer $freshCat',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: payload,
              ).timeout(const Duration(seconds: 8));
            }
          }

          if (resp.statusCode == 200 || resp.statusCode == 201) {
            final data = jsonDecode(resp.body);
            if (data is Map<String, dynamic> && data['status'] == 'ok') {
              final session = CentinelaMapSession.fromJson(data);
              return session;
            }
          }
        } catch (e) {
          debugPrint("[CentinelaFleetService] Falló map-session en host $host: $e");
        }
      }
    } catch (e) {
      debugPrint("[CentinelaFleetService] Error al crear sesión de mapa: $e");
    }

    return null;
  }
}
