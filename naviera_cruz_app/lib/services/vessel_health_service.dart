import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vessel_health_model.dart';
import 'centinela_fleet_service.dart';
import 'services.dart';

class VesselHealthService {
  static final VesselHealthService shared = VesselHealthService._internal();

  VesselHealthService._internal() {
    _loadFromDisk();
  }

  static const String centinelaBaseUrl = "https://centinela.dyndns.org:5073";
  static const String localProxyBaseUrl = "http://127.0.0.1:8086";

  // Caché en memoria por buque
  final Map<String, VesselHealthDetail> _cachedDetailByVessel = {};
  final Map<String, DateTime> _detailCacheExpiryByVessel = {};
  final Map<String, String> _lastSavedTimestampByVessel = {};

  VesselHealthResponse? _cachedConsolidated;
  DateTime? _consolidatedExpiry;
  String? _lastSavedConsolidatedTime;

  /// Claves canónicas permitidas (excluyendo Monarca)
  static const List<String> allowedVesselKeys = ['BT.ALFAC', 'BT.GUSTAVO.U', 'BT.NANY1'];

  /// Convierte el nombre o ID en su clave canónica de Centinela
  static String? resolveVesselKey(String vesselIdentifier) {
    return CentinelaFleetService.resolveVesselKey(vesselIdentifier);
  }

  /// Carga snapshots previos de disco para tolerancia a fallos offline
  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rawConsolidated = prefs.getString('centinela_vessel_health_consolidated');
      final timeConsolidated = prefs.getString('centinela_vessel_health_consolidated_time');
      if (rawConsolidated != null && rawConsolidated.isNotEmpty) {
        final data = jsonDecode(rawConsolidated);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          _cachedConsolidated = VesselHealthResponse.fromJson(data);
          _lastSavedConsolidatedTime = timeConsolidated;
        }
      }

      for (final key in allowedVesselKeys) {
        final raw = prefs.getString('centinela_vessel_health_$key');
        final savedTime = prefs.getString('centinela_vessel_health_${key}_time');
        if (raw != null && raw.isNotEmpty) {
          final data = jsonDecode(raw);
          if (data is Map<String, dynamic> && data['status'] == 'ok') {
            _cachedDetailByVessel[key] = VesselHealthDetail.fromJson(data);
            if (savedTime != null) {
              _lastSavedTimestampByVessel[key] = savedTime;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[VesselHealthService] Error leyendo snapshots de disco: $e");
    }
  }

  /// Retorna detalle cacheado en memoria si existe
  VesselHealthDetail? getCachedDetail(String vesselIdentifier) {
    final key = resolveVesselKey(vesselIdentifier);
    if (key == null) return null;
    return _cachedDetailByVessel[key];
  }

  /// Retorna timestamp guardado para mostrar en caso de fallo offline
  String? getLastSavedTime(String vesselIdentifier) {
    final key = resolveVesselKey(vesselIdentifier);
    if (key == null) return _lastSavedConsolidatedTime;
    return _lastSavedTimestampByVessel[key] ?? _lastSavedConsolidatedTime;
  }

  /// Obtiene cabeceras anti-caché y token CAT idéntico a STS
  Future<Map<String, String>> _buildHeaders() async {
    final cat = await EzvizService.shared.getCameraAccessToken();
    return {
      if (cat.isNotEmpty) 'Authorization': 'Bearer $cat',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
  }

  /// Obtiene la lista consolidada de los 3 buques (/api/v1/external/vessel-health)
  Future<VesselHealthResponse?> fetchConsolidated({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedConsolidated != null &&
        _consolidatedExpiry != null &&
        now.isBefore(_consolidatedExpiry!)) {
      return _cachedConsolidated;
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
        var headers = await _buildHeaders();
        final uri = Uri.parse('$host/api/v1/external/vessel-health?_t=${DateTime.now().millisecondsSinceEpoch}');

        var resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
        debugPrint("[VesselHealthService] fetchConsolidated en $host -> status: ${resp.statusCode}");

        // Si 401, invalidar CAT y reintentar una sola vez
        if (resp.statusCode == 401) {
          EzvizService.shared.invalidateCATCache();
          headers = await _buildHeaders();
          resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 7));
        }

        if (resp.statusCode == 200) {
          final bodyStr = resp.body.trim();
          // Ignorar HTML si el servidor no tiene la ruta activa
          if (bodyStr.startsWith('{')) {
            final data = jsonDecode(bodyStr);
            if (data is Map<String, dynamic> && data['status'] == 'ok') {
              final parsed = VesselHealthResponse.fromJson(data);
              _cachedConsolidated = parsed;
              _consolidatedExpiry = DateTime.now().add(const Duration(seconds: 30));
              final savedTime = _formatNow();
              _lastSavedConsolidatedTime = savedTime;

              SharedPreferences.getInstance().then((prefs) {
                prefs.setString('centinela_vessel_health_consolidated', bodyStr);
                prefs.setString('centinela_vessel_health_consolidated_time', savedTime);
              }).catchError((_) {});

              return parsed;
            }
          }
        }
      } catch (e) {
        debugPrint("[VesselHealthService] Error consultando consolidado en $host: $e");
      }
    }

    return _cachedConsolidated;
  }

  /// Obtiene el detalle completo del buque seleccionado (/api/v1/external/vessel-health/:vesselId)
  Future<VesselHealthDetail?> fetchDetail(String vesselIdentifier, {bool forceRefresh = false}) async {
    final vesselKey = resolveVesselKey(vesselIdentifier);
    if (vesselKey == null) return null;

    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedDetailByVessel.containsKey(vesselKey) &&
        _detailCacheExpiryByVessel.containsKey(vesselKey) &&
        now.isBefore(_detailCacheExpiryByVessel[vesselKey]!)) {
      return _cachedDetailByVessel[vesselKey];
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
        var headers = await _buildHeaders();
        final uri = Uri.parse('$host/api/v1/external/vessel-health/$vesselKey?_t=${DateTime.now().millisecondsSinceEpoch}');

        var resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
        debugPrint("[VesselHealthService] fetchDetail $vesselKey en $host -> status: ${resp.statusCode}");

        if (resp.statusCode == 401) {
          EzvizService.shared.invalidateCATCache();
          headers = await _buildHeaders();
          resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 7));
        }

        if (resp.statusCode == 200) {
          final bodyStr = resp.body.trim();
          if (bodyStr.startsWith('{')) {
            final data = jsonDecode(bodyStr);
            if (data is Map<String, dynamic> && data['status'] == 'ok') {
              final parsed = VesselHealthDetail.fromJson(data);
              _cachedDetailByVessel[vesselKey] = parsed;
              _detailCacheExpiryByVessel[vesselKey] = DateTime.now().add(const Duration(seconds: 30));
              final savedTime = _formatNow();
              _lastSavedTimestampByVessel[vesselKey] = savedTime;

              SharedPreferences.getInstance().then((prefs) {
                prefs.setString('centinela_vessel_health_$vesselKey', bodyStr);
                prefs.setString('centinela_vessel_health_${keySafe(vesselKey)}_time', savedTime);
              }).catchError((_) {});

              return parsed;
            }
          }
        }
      } catch (e) {
        debugPrint("[VesselHealthService] Error consultando detalle $vesselKey en $host: $e");
      }
    }

    return _cachedDetailByVessel[vesselKey];
  }

  static String keySafe(String key) => key.replaceAll('.', '_');

  static String _formatNow() {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return "$d/$m $h:$min";
  }
}
