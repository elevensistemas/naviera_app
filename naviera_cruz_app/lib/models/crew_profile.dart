import 'package:flutter/foundation.dart';
import 'intranet_crew_catalog.dart';

/// Estados operativos y administrativos de situación de tripulante.
enum CrewStatus {
  /// Embarcado activo en buque con fecha vigente registrada
  embarcado,
  /// En tierra oficialmente (franco, licencia, baja temporal, vacaciones)
  enTierra,
  /// Desembarque completado (fecha de fin en el pasado)
  desembarqueRegistrado,
  /// Figura embarcado pero la fecha de inicio no se encuentra en el registro
  fechaAusente,
  /// Fecha de embarque futura o inconsistencia cronológica
  registroInconsistente,
  /// Usuario de la app autenticado sin perfil de tripulante vinculado en la intranet
  noVinculado,
  /// Error de conexión, timeout o falta de permisos al consultar la intranet
  errorConexion,
}

/// Modelo integral del Perfil de Tripulante en Naviera Cruz del Sur.
/// Construido a partir de datos reales de la Intranet (Django REST Framework).
class CrewProfile {
  final String id;
  final String? legajo;
  final String? dni;
  final String name;
  final String role;
  final bool isOnBoard;
  final String situation;
  final String? shipId;
  final String? shipName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? rawDaysOnBoard;
  final String? photoUrl;
  final List<String> permissions;
  final CrewStatus status;
  final bool hasError;
  final String? errorMessage;
  final bool isLinked;

  const CrewProfile({
    required this.id,
    this.legajo,
    this.dni,
    required this.name,
    required this.role,
    required this.isOnBoard,
    required this.situation,
    this.shipId,
    this.shipName,
    this.startDate,
    this.endDate,
    this.rawDaysOnBoard,
    this.photoUrl,
    this.permissions = const ['crew_access', 'manual_gestion_read', 'report_incidents'],
    this.status = CrewStatus.embarcado,
    this.hasError = false,
    this.errorMessage,
    this.isLinked = true,
  });

  /// Constructor para cuentas sin vinculación a tripulante en intranet
  factory CrewProfile.unlinked({required String name, required String userId}) {
    return CrewProfile(
      id: userId,
      name: name.isNotEmpty ? name : "Usuario Autenticado",
      role: "Sin cargo asignado",
      isOnBoard: false,
      situation: "No vinculado",
      status: CrewStatus.noVinculado,
      isLinked: false,
      hasError: false,
    );
  }

  /// Constructor para errores de conexión o sesión
  factory CrewProfile.error({required String name, required String errorMessage}) {
    return CrewProfile(
      id: 'error',
      name: name.isNotEmpty ? name : "Tripulante",
      role: "Información no disponible",
      isOnBoard: false,
      situation: "Error de conexión",
      status: CrewStatus.errorConexion,
      isLinked: false,
      hasError: true,
      errorMessage: errorMessage,
    );
  }

  /// Constructor a partir del registro oficial de dotación de la intranet
  factory CrewProfile.fromCatalog(IntranetCrewMember member) {
    return CrewProfile(
      id: member.id,
      name: member.name,
      role: member.roleName,
      isOnBoard: member.isOnBoard,
      situation: member.isOnBoard ? "A Bordo (${member.shipName ?? 'Buque'})" : "En Tierra",
      shipName: member.shipName,
      rawDaysOnBoard: member.days,
      status: member.isOnBoard ? CrewStatus.embarcado : CrewStatus.enTierra,
      isLinked: true,
      hasError: false,
    );
  }

  /// Cálculo oficial de días embarcado:
  /// 1. Si la Intranet provee el total oficial (sitData['days_on_board']), se utiliza directamente como fuente de verdad.
  /// 2. Si sólo se provee fecha de inicio y el tripulante está efectivamente embarcado:
  ///    Se calcula la diferencia en días calendario tomando la zona horaria oficial de Argentina (UTC-3).
  /// 3. Casos especiales:
  ///    - En tierra o desembarcado: retorna null.
  ///    - Fecha ausente o inconsistente (ej. fecha futura): retorna null.
  ///    - Error de API o no vinculado: retorna null (no se deduce "EN TIERRA").
  int? get daysOnBoard {
    if (status != CrewStatus.embarcado || !isOnBoard) return null;

    // 1. Fuente oficial de la intranet
    if (rawDaysOnBoard != null && rawDaysOnBoard! >= 0) {
      return rawDaysOnBoard;
    }

    // 2. Cálculo en base a fechas calendario UTC-3 (Argentina)
    if (startDate != null) {
      final nowUtc3 = DateTime.now().toUtc().subtract(const Duration(hours: 3));
      final startUtc3 = DateTime.utc(startDate!.year, startDate!.month, startDate!.day);
      final todayUtc3 = DateTime.utc(nowUtc3.year, nowUtc3.month, nowUtc3.day);

      if (todayUtc3.isBefore(startUtc3)) {
        return null; // Fecha futura / programada
      }

      final difference = todayUtc3.difference(startUtc3).inDays;
      if (difference >= 0) {
        return difference; // Días calendario transcurridos desde la fecha de inicio
      }
    }

    return null;
  }

  /// Días de cómputo para mostrar en la interfaz (sean a bordo o en tierra según situación)
  int get displayDays {
    if (rawDaysOnBoard != null) return rawDaysOnBoard!;
    final d = daysOnBoard;
    if (d != null) return d;
    return 0;
  }

  /// Días registrados en tierra para tripulantes desembarcados
  int? get daysOnLand {
    if (!isOnBoard && rawDaysOnBoard != null) {
      return rawDaysOnBoard;
    }
    return null;
  }

  /// Texto descriptivo de la situación para la tarjeta de cabecera
  String get situationBadgeText {
    switch (status) {
      case CrewStatus.embarcado:
        return "EMBARCADO";
      case CrewStatus.enTierra:
        return "EN TIERRA";
      case CrewStatus.desembarqueRegistrado:
        return "DESEMBARCADO";
      case CrewStatus.fechaAusente:
        return "EMBARCADO (SIN FECHA)";
      case CrewStatus.registroInconsistente:
        return "PROGRAMADO / A CONFIRMAR";
      case CrewStatus.noVinculado:
        return "CUENTA SIN LEGAJO VINCULADO";
      case CrewStatus.errorConexion:
        return "ERROR AL CONSULTAR INTRANET";
    }
  }

  /// Texto descriptivo de días a bordo
  String get daysOnBoardText {
    switch (status) {
      case CrewStatus.embarcado:
        final d = daysOnBoard;
        if (d != null) {
          return "$d ${d == 1 ? 'día' : 'días'} a bordo";
        }
        return "Días no computados";
      case CrewStatus.enTierra:
        return "En tierra ($situation)";
      case CrewStatus.desembarqueRegistrado:
        return "Desembarque registrado";
      case CrewStatus.fechaAusente:
        return "Fecha de embarque no registrada";
      case CrewStatus.registroInconsistente:
        return "Fecha de embarque futura o inconsistente";
      case CrewStatus.noVinculado:
        return "Perfil no vinculado en la intranet";
      case CrewStatus.errorConexion:
        return "Información no disponible (Error de red)";
    }
  }

  /// Texto formateado para la fecha de embarque (ej: "12 oct 2026")
  String get formattedStartDate {
    if (startDate == null) return "Fecha no registrada";
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return "${startDate!.day} ${months[startDate!.month - 1]} ${startDate!.year}";
  }

  /// Texto formateado para la fecha de desembarque
  String get formattedEndDate {
    if (endDate == null) return "No registrada";
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return "${endDate!.day} ${months[endDate!.month - 1]} ${endDate!.year}";
  }

  factory CrewProfile.fromIntranet({
    required Map<String, dynamic> json,
    Map<String, dynamic>? situationJson,
    Map<String, dynamic>? shipJson,
  }) {
    // 1. Identificadores
    final id = json['id']?.toString() ?? json['user_id']?.toString() ?? '';
    final dniVal = json['dni']?.toString() ?? json['document_id']?.toString();
    final legajoVal = json['legajo']?.toString() ?? dniVal;

    // 2. Nombre
    String fullName = json['name']?.toString() ?? '';
    if (fullName.isEmpty && (json['first_name'] != null || json['last_name'] != null)) {
      fullName = "${json['first_name'] ?? ''} ${json['last_name'] ?? ''}".trim();
    }
    if (fullName.isEmpty) {
      fullName = "Tripulante";
    }

    // 3. Cargo / Posición
    String roleStr = '';
    if (json['position_detail'] is Map<String, dynamic>) {
      final pd = json['position_detail'] as Map<String, dynamic>;
      roleStr = pd['name']?.toString() ?? pd['short_name']?.toString() ?? '';
    } else if (json['position'] != null) {
      roleStr = json['position'].toString();
    } else if (json['role'] != null) {
      roleStr = json['role'].toString();
    }
    if (roleStr.isEmpty) {
      roleStr = "Personal de Flota";
    }

    // 4. Situación de embarque
    bool isOnBoard = true;
    String situationName = "Embarcado";
    DateTime? startDt;
    DateTime? endDt;
    int? daysCount;

    final sitData = situationJson ??
        (json['current_situation_detail'] is Map<String, dynamic>
            ? json['current_situation_detail'] as Map<String, dynamic>
            : null);

    if (sitData != null) {
      final sStr = sitData['start_date']?.toString() ?? sitData['starts_at']?.toString();
      if (sStr != null && sStr.isNotEmpty) {
        startDt = DateTime.tryParse(sStr);
      }
      final eStr = sitData['end_date']?.toString() ?? sitData['ends_at']?.toString();
      if (eStr != null && eStr.isNotEmpty) {
        endDt = DateTime.tryParse(eStr);
      }

      if (sitData['days_on_board'] != null) {
        daysCount = (sitData['days_on_board'] as num?)?.toInt() ??
            int.tryParse(sitData['days_on_board'].toString());
      }

      final typeDetail = sitData['situation_type_detail'] ?? sitData['situation_type'];
      if (typeDetail is Map<String, dynamic>) {
        situationName = typeDetail['name']?.toString() ??
            typeDetail['short_description']?.toString() ??
            situationName;
        if (typeDetail['is_on_board'] is bool) {
          isOnBoard = typeDetail['is_on_board'] as bool;
        }
      } else if (typeDetail is String && typeDetail.isNotEmpty) {
        situationName = typeDetail;
      }
    } else {
      final sStr = json['start_date']?.toString() ?? json['boarding_date']?.toString();
      if (sStr != null && sStr.isNotEmpty) {
        startDt = DateTime.tryParse(sStr);
      }
      if (json['days_on_board'] != null) {
        daysCount = (json['days_on_board'] as num?)?.toInt() ??
            int.tryParse(json['days_on_board'].toString());
      }
      if (json['situation'] != null) {
        situationName = json['situation'].toString();
      }
    }

    if (json['is_on_board'] is bool) {
      isOnBoard = json['is_on_board'] as bool;
    } else {
      final sitLower = situationName.toLowerCase();
      if (sitLower.contains('tierra') ||
          sitLower.contains('franco') ||
          sitLower.contains('licenc') ||
          sitLower.contains('baja') ||
          sitLower.contains('desembarc') ||
          sitLower.contains('vacacion')) {
        isOnBoard = false;
      } else if (sitLower.contains('embarc') || sitLower.contains('bordo')) {
        isOnBoard = true;
      }
    }

    // 5. Determinar estado tipificado riguroso
    CrewStatus determinedStatus;
    final nowUtc3 = DateTime.now().toUtc().subtract(const Duration(hours: 3));
    final todayUtc3 = DateTime.utc(nowUtc3.year, nowUtc3.month, nowUtc3.day);

    if (!isOnBoard) {
      if (endDt != null && endDt.isBefore(todayUtc3)) {
        determinedStatus = CrewStatus.desembarqueRegistrado;
      } else {
        determinedStatus = CrewStatus.enTierra;
      }
    } else {
      if (startDt == null) {
        determinedStatus = CrewStatus.fechaAusente;
      } else {
        final startUtc3 = DateTime.utc(startDt.year, startDt.month, startDt.day);
        if (todayUtc3.isBefore(startUtc3)) {
          determinedStatus = CrewStatus.registroInconsistente;
        } else {
          determinedStatus = CrewStatus.embarcado;
        }
      }
    }

    // 6. Buque asignado
    String? shipIdVal;
    String? shipNameVal;

    final shipData = shipJson ??
        (json['current_ship_detail'] is Map<String, dynamic>
            ? json['current_ship_detail'] as Map<String, dynamic>
            : (sitData != null && sitData['ship_detail'] is Map<String, dynamic>
                ? sitData['ship_detail'] as Map<String, dynamic>
                : null));

    if (shipData != null) {
      shipIdVal = shipData['id']?.toString();
      shipNameVal = shipData['name']?.toString() ?? shipData['description']?.toString();
    } else {
      shipIdVal = json['ship_id']?.toString() ?? json['ship']?.toString();
      shipNameVal = json['ship_name']?.toString();
    }

    if (shipNameVal == null || shipNameVal.isEmpty) {
      if (shipIdVal == '4' || shipIdVal == 'S1') shipNameVal = 'ALFA C';
      if (shipIdVal == '5' || shipIdVal == 'S3') shipNameVal = 'NANY';
      if (shipIdVal == '6' || shipIdVal == 'S2') shipNameVal = 'GUSTAVO U';
    }

    // 7. Foto
    final photo = json['picture']?.toString() ??
        json['photo']?.toString() ??
        json['avatar_url']?.toString();

    // Fallback de días al catálogo oficial de la intranet si no viene en el payload
    if (daysCount == null || daysCount == 0) {
      final catalogMember = IntranetCrewCatalog.findCrewMember(fullName);
      if (catalogMember != null) {
        daysCount = catalogMember.days;
      }
    }

    return CrewProfile(
      id: id,
      legajo: legajoVal,
      dni: dniVal,
      name: fullName,
      role: roleStr,
      isOnBoard: isOnBoard,
      situation: situationName,
      shipId: shipIdVal,
      shipName: shipNameVal,
      startDate: startDt,
      endDate: endDt,
      rawDaysOnBoard: daysCount,
      photoUrl: photo,
      status: determinedStatus,
      isLinked: true,
      hasError: false,
    );
  }
}

/// Configuración para las 3 portadas personalizables del tripulante.
/// Permite asociar una imagen de cabecera según buque y situación.
/// Fallback garantizado: imagen corporativa autorizada (ncsHeaderImageBytes).
class CrewCoverConfig {
  final Uint8List? slot1ImageBytes;
  final String? slot1ShipId;
  final String? slot1Situation;

  final Uint8List? slot2ImageBytes;
  final String? slot2ShipId;
  final String? slot2Situation;

  final Uint8List? slot3ImageBytes;
  final String? slot3ShipId;
  final String? slot3Situation;

  const CrewCoverConfig({
    this.slot1ImageBytes,
    this.slot1ShipId,
    this.slot1Situation,
    this.slot2ImageBytes,
    this.slot2ShipId,
    this.slot2Situation,
    this.slot3ImageBytes,
    this.slot3ShipId,
    this.slot3Situation,
  });

  /// Selecciona la imagen adecuada o retorna null para usar la corporativa de respaldo.
  Uint8List? resolveCoverBytes({required String? shipId, required String? situation}) {
    if (shipId != null) {
      final s = shipId.toUpperCase();
      if (slot1ShipId != null && s.contains(slot1ShipId!.toUpperCase()) && slot1ImageBytes != null) {
        return slot1ImageBytes;
      }
      if (slot2ShipId != null && s.contains(slot2ShipId!.toUpperCase()) && slot2ImageBytes != null) {
        return slot2ImageBytes;
      }
      if (slot3ShipId != null && s.contains(slot3ShipId!.toUpperCase()) && slot3ImageBytes != null) {
        return slot3ImageBytes;
      }
    }
    return null; // Fallback corporativo
  }
}
