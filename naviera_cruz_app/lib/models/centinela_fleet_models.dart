import 'package:flutter/material.dart';

/// Modelo de frescura de estado
class CentinelaFreshness {
  final String status; // 'live', 'unverified', 'no_data', 'stale'
  final String? source;
  final DateTime? verifiedAt;
  final int ageSec;
  final bool isVerifiedRecently;
  final String? warning;
  final bool hasLocalGps;

  CentinelaFreshness({
    required this.status,
    this.source,
    this.verifiedAt,
    this.ageSec = 0,
    this.isVerifiedRecently = false,
    this.warning,
    this.hasLocalGps = false,
  });

  bool get isLive => status.toLowerCase() == 'live';
  bool get isUnverified => status.toLowerCase() == 'unverified';
  bool get isNoData => status.toLowerCase() == 'no_data' || status.isEmpty;

  factory CentinelaFreshness.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CentinelaFreshness(status: 'no_data');
    }
    DateTime? vAt;
    if (json['verified_at'] != null) {
      vAt = DateTime.tryParse(json['verified_at'].toString());
    } else if (json['updated_at'] != null) {
      vAt = DateTime.tryParse(json['updated_at'].toString());
    }
    final hasGps = json['has_local_gps'] == true ||
        (json['telemetry_source']?.toString().toLowerCase().contains('gps') ?? false) ||
        (json['source']?.toString().toLowerCase().contains('gps') ?? false);

    return CentinelaFreshness(
      status: (json['status'] ?? 'no_data').toString(),
      source: json['source']?.toString() ?? json['telemetry_source']?.toString(),
      verifiedAt: vAt,
      ageSec: int.tryParse(json['age_sec']?.toString() ?? '0') ?? 0,
      isVerifiedRecently: json['is_verified_recently'] == true,
      warning: json['warning']?.toString(),
      hasLocalGps: hasGps,
    );
  }
}

/// Modelo de un factor individual de la Auditoría OCIMF 2026
class OcimfFactor {
  final String key;
  final String label;
  final bool available;
  final String status;
  final dynamic rawValue;
  final String unit;
  final String displayValue;
  final String evaluationLabel;
  final String summaryText;
  final bool isAdverse;
  final String source;
  final DateTime? updatedAt;
  final int ageSec;

  OcimfFactor({
    required this.key,
    required this.label,
    required this.available,
    required this.status,
    this.rawValue,
    required this.unit,
    required this.displayValue,
    required this.evaluationLabel,
    required this.summaryText,
    required this.isAdverse,
    required this.source,
    this.updatedAt,
    this.ageSec = 0,
  });

  bool get isStale => status.toLowerCase() == 'stale';

  factory OcimfFactor.fromJson(String key, Map<String, dynamic> json) {
    return OcimfFactor(
      key: key,
      label: json['label']?.toString() ?? key,
      available: json['available'] == true,
      status: json['status']?.toString() ?? 'live',
      rawValue: json['value'],
      unit: json['unit']?.toString() ?? '',
      displayValue: json['display_value']?.toString() ?? '',
      evaluationLabel: json['evaluation_label']?.toString() ?? 'Óptimo',
      summaryText: json['summary_text']?.toString() ?? '',
      isAdverse: json['is_adverse'] == true,
      source: json['source']?.toString() ?? '',
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      ageSec: int.tryParse(json['age_sec']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Auditoría de Riesgo OCIMF 2026
class OcimfAudit {
  final String title;
  final String frameworkCode;
  final String frameworkLabel;
  final String validationNote;
  final String zoneName;
  final String zoneLocationRef;
  final int totalPenaltyPct;
  final int totalScorePct;
  final List<String> factorsOrder;
  final Map<String, OcimfFactor> factors;

  OcimfAudit({
    required this.title,
    required this.frameworkCode,
    required this.frameworkLabel,
    required this.validationNote,
    required this.zoneName,
    required this.zoneLocationRef,
    required this.totalPenaltyPct,
    required this.totalScorePct,
    required this.factorsOrder,
    required this.factors,
  });

  factory OcimfAudit.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return OcimfAudit(
        title: "Auditoría de Riesgo OCIMF",
        frameworkCode: "OCIMF_2026",
        frameworkLabel: "OCIMF 2026 ON",
        validationNote: "*Datos validados de forma matemática.",
        zoneName: "Zona Operativa Flota",
        zoneLocationRef: "",
        totalPenaltyPct: 0,
        totalScorePct: 100,
        factorsOrder: ["wind", "wave", "current", "visibility", "weather"],
        factors: {},
      );
    }

    final rawFactors = json['factors'] as Map<String, dynamic>? ?? {};
    final parsedFactors = <String, OcimfFactor>{};
    rawFactors.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        parsedFactors[k] = OcimfFactor.fromJson(k, v);
      }
    });

    final orderList = (json['factors_order'] as List?)?.map((e) => e.toString()).toList() ??
        ["wind", "wave", "current", "visibility", "weather"];

    final zone = json['zone'] as Map<String, dynamic>? ?? {};

    return OcimfAudit(
      title: json['title']?.toString() ?? "Auditoría de Riesgo OCIMF",
      frameworkCode: json['framework_code']?.toString() ?? "OCIMF_2026",
      frameworkLabel: json['framework_label']?.toString() ?? "OCIMF 2026 ON",
      validationNote: json['validation_note']?.toString() ?? "*Datos validados de forma matemática.",
      zoneName: zone['name']?.toString() ?? "Río de la Plata",
      zoneLocationRef: zone['location_ref']?.toString() ?? "Rada La Plata",
      totalPenaltyPct: int.tryParse(json['total_penalty_pct']?.toString() ?? '0') ?? 0,
      totalScorePct: int.tryParse(json['total_score_pct']?.toString() ?? '100') ?? 100,
      factorsOrder: orderList,
      factors: parsedFactors,
    );
  }
}

/// Estado STS consolidado
class CentinelaStsRisk {
  final String vesselKey;
  final String vesselName;
  final int score;
  final String colorHex;
  final String uiLevel;
  final String evaluationState;
  final bool hasSufficientData;
  final String? notice;
  final OcimfAudit ocimfAudit;

  // Estado operacional
  final String rawOperationalState;
  final String? counterpartVessel;
  final DateTime? stateStartedAt;
  final int stateDurationSec;
  final CentinelaFreshness stateFreshness;
  final CentinelaFreshness positionFreshness;
  final String dataStatus;
  final String badgeShort;
  final bool isStale;
  final double? speedKn;

  CentinelaStsRisk({
    required this.vesselKey,
    required this.vesselName,
    required this.score,
    required this.colorHex,
    required this.uiLevel,
    required this.evaluationState,
    required this.hasSufficientData,
    this.notice,
    required this.ocimfAudit,
    required this.rawOperationalState,
    this.counterpartVessel,
    this.stateStartedAt,
    required this.stateDurationSec,
    required this.stateFreshness,
    required this.positionFreshness,
    required this.dataStatus,
    required this.badgeShort,
    required this.isStale,
    this.speedKn,
  });

  /// Color para pintar el badge de STS
  Color get stsColor {
    if (!hasSufficientData) return const Color(0xFF94A3B8); // Gris S/D
    try {
      final hex = colorHex.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse("FF$hex", radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF00FFC8); // Verde óptimo por defecto
  }

  /// Texto limpio del estado operacional
  String get operationalStateDisplay {
    if (stateFreshness.isNoData || rawOperationalState.isEmpty) {
      return "Estado no disponible";
    }

    final rawUpper = rawOperationalState.toUpperCase().trim();
    if (rawUpper.contains("DESCARGA") || rawUpper.contains("STS")) {
      if (counterpartVessel != null && counterpartVessel!.isNotEmpty) {
        return "Operando descarga con $counterpartVessel";
      }
      return "Operando descarga";
    } else if (rawUpper.contains("NAVEGANDO")) {
      if (speedKn != null && speedKn! > 0.0) {
        final speedFormatted = speedKn! % 1 == 0 ? speedKn!.toInt().toString() : speedKn!.toStringAsFixed(1);
        return "Navegando a $speedFormatted kn";
      }
      return "Navegando";
    } else if (rawUpper.contains("PUERTO")) {
      return "En puerto";
    } else if (rawUpper.contains("FONDEADO") || rawUpper.contains("FONDEO")) {
      return "Fondeado";
    }

    // Capitalizar adecuadamente si viene en MAYÚSCULAS_CON_GUION
    final words = rawOperationalState.replaceAll('_', ' ').toLowerCase().split(' ');
    return words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  /// Formatea la duración según las reglas estrictas (live, unverified, no_data)
  String get durationDisplay {
    if (stateFreshness.isNoData) return "";

    int seconds = stateDurationSec;
    // Si es live y tenemos stateStartedAt, calcular dinámicamente el tiempo transcurrido
    if (stateFreshness.isLive && stateStartedAt != null) {
      final diff = DateTime.now().difference(stateStartedAt!).inSeconds;
      if (diff > 0) {
        seconds = diff;
      }
    }

    if (seconds <= 0) return "";

    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (days > 0) {
      if (hours > 0) {
        return "Hace $days ${days == 1 ? 'día' : 'días'} $hours h";
      }
      return "Hace $days ${days == 1 ? 'día' : 'días'}";
    } else if (hours > 0) {
      if (minutes > 0) {
        return "Hace $hours h $minutes min";
      }
      return "Hace $hours h";
    } else if (minutes > 0) {
      return "Hace $minutes min";
    } else {
      return "Hace unos instantes";
    }
  }

  /// Etiqueta limpia de telemetría de posición: GPS o AIS
  String get telemetryLabel {
    if (positionFreshness.hasLocalGps ||
        (positionFreshness.source ?? '').toLowerCase().contains('gps')) {
      return "GPS";
    }
    return "AIS";
  }

  bool get isGps => telemetryLabel == "GPS";

  factory CentinelaStsRisk.fromJson(Map<String, dynamic> json) {
    final vessel = json['vessel'] as Map<String, dynamic>? ?? {};
    final sts = json['sts'] as Map<String, dynamic>? ?? {};
    final display = json['display'] as Map<String, dynamic>? ?? {};
    final auditJson = sts['ocimf_audit'] as Map<String, dynamic>?;

    final evalState = sts['evaluation_state']?.toString() ?? 'DATOS_SUFICIENTES';
    final hasSuff = evalState == 'DATOS_SUFICIENTES';

    DateTime? startedAt;
    if (json['state_started_at'] != null) {
      startedAt = DateTime.tryParse(json['state_started_at'].toString());
    }

    final sFreshness = CentinelaFreshness.fromJson(json['state_freshness'] as Map<String, dynamic>?);
    final pFreshness = CentinelaFreshness.fromJson(json['position_freshness'] as Map<String, dynamic>?);
    final freshnessJson = json['freshness'] as Map<String, dynamic>? ?? {};

    return CentinelaStsRisk(
      vesselKey: vessel['key']?.toString() ?? '',
      vesselName: vessel['name']?.toString() ?? '',
      score: int.tryParse(sts['score']?.toString() ?? '100') ?? 100,
      colorHex: sts['color_hex']?.toString() ?? display['color_hex']?.toString() ?? '#00ffc8',
      uiLevel: sts['ui_level']?.toString() ?? 'OPTIMAL',
      evaluationState: evalState,
      hasSufficientData: hasSuff,
      notice: sts['notice']?.toString(),
      ocimfAudit: OcimfAudit.fromJson(auditJson),
      rawOperationalState: json['operational_state']?.toString() ?? '',
      counterpartVessel: json['counterpart_vessel']?.toString(),
      stateStartedAt: startedAt,
      stateDurationSec: int.tryParse(json['state_duration_sec']?.toString() ?? '0') ?? 0,
      stateFreshness: sFreshness,
      positionFreshness: pFreshness,
      dataStatus: json['data_status']?.toString() ?? 'live',
      badgeShort: display['badge_short']?.toString() ?? 'STS 100',
      isStale: freshnessJson['is_stale'] == true,
      speedKn: double.tryParse(json['speed_kn']?.toString() ?? json['speed']?.toString() ?? json['sog']?.toString() ?? ''),
    );
  }
}

/// Respuesta de sesión de mapa táctico efímero
class CentinelaMapSession {
  final String status;
  final String bootstrapTicket;
  final int bootstrapTtlSec;
  final String focusVessel;
  final String webviewUrl;

  CentinelaMapSession({
    required this.status,
    required this.bootstrapTicket,
    required this.bootstrapTtlSec,
    required this.focusVessel,
    required this.webviewUrl,
  });

  factory CentinelaMapSession.fromJson(Map<String, dynamic> json) {
    return CentinelaMapSession(
      status: json['status']?.toString() ?? 'ok',
      bootstrapTicket: json['bootstrap_ticket']?.toString() ?? '',
      bootstrapTtlSec: int.tryParse(json['bootstrap_ttl_sec']?.toString() ?? '60') ?? 60,
      focusVessel: json['focus_vessel']?.toString() ?? '',
      webviewUrl: json['webview_url']?.toString() ?? '',
    );
  }
}

