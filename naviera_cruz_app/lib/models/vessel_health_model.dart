import 'dart:convert';

/// Modelo de Salud del Buque consolidado desde Centinela (100% Solo Lectura)
class VesselHealthResponse {
  final String status;
  final bool readOnly;
  final String serverTime;
  final int count;
  final List<VesselHealthCard> vessels;

  VesselHealthResponse({
    required this.status,
    required this.readOnly,
    required this.serverTime,
    required this.count,
    required this.vessels,
  });

  factory VesselHealthResponse.fromJson(Map<String, dynamic> json) {
    return VesselHealthResponse(
      status: json['status']?.toString() ?? 'ok',
      readOnly: json['read_only'] == true,
      serverTime: json['server_time']?.toString() ?? '',
      count: json['count'] is int ? json['count'] : (int.tryParse('${json['count']}') ?? 0),
      vessels: (json['vessels'] as List<dynamic>?)
              ?.map((v) => VesselHealthCard.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Tarjeta resumida del buque (precarga instantánea y selector ágil)
class VesselHealthCard {
  final String vesselId; // 'BT.ALFAC', 'BT.GUSTAVO.U', 'BT.NANY1'
  final String vesselName; // 'ALFA C', 'GUSTAVO U', 'NANY'
  final String imo;
  final int healthScoreFinal; // 0-100
  final int healthScoreBase;
  final String scoreTone; // 'green', 'amber', 'coral'
  final String colorHex; // '#10b981', '#f59e0b', '#ff5a5f'
  final String operationalStatus; // 'Operativo', 'Operativo con restricciones'
  final String operationalRestrictionReason;
  final String appliedCap;
  final String headline;
  final int deltaScore;
  final String calculatedAt;
  final HealthPillars pillars;
  final HealthKpis kpis;
  final CertificatesSummary certificatesSummary;
  final MaradOfficialParity maradParity;
  final List<HealthPriorityItem> priorities;
  final HealthSourcesSync sourcesSync;

  VesselHealthCard({
    required this.vesselId,
    required this.vesselName,
    required this.imo,
    required this.healthScoreFinal,
    required this.healthScoreBase,
    required this.scoreTone,
    required this.colorHex,
    required this.operationalStatus,
    required this.operationalRestrictionReason,
    required this.appliedCap,
    required this.headline,
    required this.deltaScore,
    required this.calculatedAt,
    required this.pillars,
    required this.kpis,
    required this.certificatesSummary,
    required this.maradParity,
    required this.priorities,
    required this.sourcesSync,
  });

  factory VesselHealthCard.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);

    return VesselHealthCard(
      vesselId: json['vessel_id']?.toString() ?? json['vessel_key']?.toString() ?? '',
      vesselName: json['vessel_name']?.toString() ?? '',
      imo: json['imo']?.toString() ?? '',
      healthScoreFinal: _i(json['health_score_final']),
      healthScoreBase: _i(json['health_score_base'] ?? json['health_score_final']),
      scoreTone: json['score_tone']?.toString() ?? 'green',
      colorHex: json['color_hex']?.toString() ?? '#10b981',
      operationalStatus: json['operational_status']?.toString() ?? 'Operativo',
      operationalRestrictionReason: json['operational_restriction_reason']?.toString() ?? '',
      appliedCap: json['applied_cap']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      deltaScore: _i(json['delta_score'] ?? json['delta']),
      calculatedAt: json['calculated_at']?.toString() ?? '',
      pillars: HealthPillars.fromJson(json['pillars'] as Map<String, dynamic>? ?? {}),
      kpis: HealthKpis.fromJson(json['kpis'] as Map<String, dynamic>? ?? {}),
      certificatesSummary: CertificatesSummary.fromJson(json['certificates_summary'] as Map<String, dynamic>? ?? {}),
      maradParity: MaradOfficialParity.fromJson(json['marad_official_parity'] as Map<String, dynamic>? ?? {}),
      priorities: (json['priorities'] as List<dynamic>?)
              ?.map((p) => HealthPriorityItem.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      sourcesSync: HealthSourcesSync.fromJson(json['sources_sync'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Detalle completo del buque seleccionado (incluye certificates, maintenance_tasks y crew)
class VesselHealthDetail {
  final String status;
  final bool readOnly;
  final String serverTime;
  final VesselHealthCard card;
  final List<HealthCertificateItem> certificates;
  final MaintenanceTasksSummary maintenanceTasks;
  final List<HealthCrewMember> crew;
  final List<dynamic> scoringEvents;

  VesselHealthDetail({
    required this.status,
    required this.readOnly,
    required this.serverTime,
    required this.card,
    required this.certificates,
    required this.maintenanceTasks,
    required this.crew,
    required this.scoringEvents,
  });

  factory VesselHealthDetail.fromJson(Map<String, dynamic> json) {
    final v = json['vessel'] as Map<String, dynamic>? ?? json;
    final card = VesselHealthCard.fromJson(v);

    return VesselHealthDetail(
      status: json['status']?.toString() ?? 'ok',
      readOnly: json['read_only'] == true || v['read_only'] == true,
      serverTime: json['server_time']?.toString() ?? '',
      card: card,
      certificates: (v['certificates'] as List<dynamic>?)
              ?.map((c) => HealthCertificateItem.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      maintenanceTasks: MaintenanceTasksSummary.fromJson(v['maintenance_tasks'] as Map<String, dynamic>? ?? {}),
      crew: (v['crew'] as List<dynamic>?)
              ?.map((cr) => HealthCrewMember.fromJson(cr as Map<String, dynamic>))
              .toList() ??
          [],
      scoringEvents: v['scoring_events'] as List<dynamic>? ?? [],
    );
  }
}

/// Los 4 Pilares de Salud de Centinela (0 - 100)
class HealthPillars {
  final int operacion;
  final int disponibilidad;
  final int seguridad;
  final int preparacion;

  HealthPillars({
    required this.operacion,
    required this.disponibilidad,
    required this.seguridad,
    required this.preparacion,
  });

  factory HealthPillars.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
    return HealthPillars(
      operacion: _i(json['operacion']),
      disponibilidad: _i(json['disponibilidad']),
      seguridad: _i(json['seguridad']),
      preparacion: _i(json['preparacion']),
    );
  }
}

/// KPIs críticos y operativos
class HealthKpis {
  final int criticalMaintOverdue;
  final int normalMaintOverdue;
  final int runningHoursOverdue;
  final int runningHoursOk;
  final int dockMaintCount;
  final int certsReallyExpired;
  final int certsInRenewalWindow;
  final int certsExpiringSoon;
  final int certsVigentes;
  final int certsUnverified;
  final int crewOnBoard;
  final bool crewMinManningOk;
  final int crewReliefsOverdue;
  final int crewReliefsPreventive;
  final int criticalPurchasesOpen;

  HealthKpis({
    required this.criticalMaintOverdue,
    required this.normalMaintOverdue,
    required this.runningHoursOverdue,
    required this.runningHoursOk,
    required this.dockMaintCount,
    required this.certsReallyExpired,
    required this.certsInRenewalWindow,
    required this.certsExpiringSoon,
    required this.certsVigentes,
    required this.certsUnverified,
    required this.crewOnBoard,
    required this.crewMinManningOk,
    required this.crewReliefsOverdue,
    required this.crewReliefsPreventive,
    required this.criticalPurchasesOpen,
  });

  factory HealthKpis.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
    return HealthKpis(
      criticalMaintOverdue: _i(json['critical_maint_overdue']),
      normalMaintOverdue: _i(json['normal_maint_overdue']),
      runningHoursOverdue: _i(json['running_hours_overdue']),
      runningHoursOk: _i(json['running_hours_ok']),
      dockMaintCount: _i(json['dock_maint_count']),
      certsReallyExpired: _i(json['certs_really_expired']),
      certsInRenewalWindow: _i(json['certs_in_renewal_window']),
      certsExpiringSoon: _i(json['certs_expiring_soon']),
      certsVigentes: _i(json['certs_vigentes']),
      certsUnverified: _i(json['certs_unverified']),
      crewOnBoard: _i(json['crew_on_board']),
      crewMinManningOk: json['crew_min_manning_ok'] == true,
      crewReliefsOverdue: _i(json['crew_reliefs_overdue']),
      crewReliefsPreventive: _i(json['crew_reliefs_preventive']),
      criticalPurchasesOpen: _i(json['critical_purchases_open'] ?? json['critical_purchases']),
    );
  }
}

/// Resumen de Certificados con los 5 estados obligatorios
class CertificatesSummary {
  final int total;
  final int vigentes;
  final int proximosAVencer;
  final int enVentanaRenovacion;
  final int vencidos;
  final int noVerificados;
  final int permanentes;

  CertificatesSummary({
    required this.total,
    required this.vigentes,
    required this.proximosAVencer,
    required this.enVentanaRenovacion,
    required this.vencidos,
    required this.noVerificados,
    required this.permanentes,
  });

  factory CertificatesSummary.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
    return CertificatesSummary(
      total: _i(json['total']),
      vigentes: _i(json['vigentes'] ?? json['vigente']),
      proximosAVencer: _i(json['proximos_a_vencer'] ?? json['proximo_a_vencer']),
      enVentanaRenovacion: _i(json['en_ventana_renovacion']),
      vencidos: _i(json['vencidos'] ?? json['vencido']),
      noVerificados: _i(json['no_verificados'] ?? json['estado_no_verificado']),
      permanentes: _i(json['permanentes']),
    );
  }
}

/// Detalle individual de certificado
class HealthCertificateItem {
  final String key;
  final String name;
  final String category;
  final String? seriesNo;
  final String state; // VIGENTE, PROXIMO_A_VENCER, EN_VENTANA_RENOVACION, VENCIDO, ESTADO_NO_VERIFICADO
  final String stateLabel;
  final bool isPermanent;
  final bool isStatutoryOrClass;
  final String? nominalExpirationDate;
  final String? effectiveExpirationDate;
  final int? daysToNominal;
  final int? daysRemainingEffective;
  final int daysOverdueEffective;
  final String? normativeBasis;

  HealthCertificateItem({
    required this.key,
    required this.name,
    required this.category,
    this.seriesNo,
    required this.state,
    required this.stateLabel,
    required this.isPermanent,
    required this.isStatutoryOrClass,
    this.nominalExpirationDate,
    this.effectiveExpirationDate,
    this.daysToNominal,
    this.daysRemainingEffective,
    required this.daysOverdueEffective,
    this.normativeBasis,
  });

  factory HealthCertificateItem.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
    int? _optI(dynamic v) => (v is num) ? v.toInt() : (v != null ? int.tryParse('$v') : null);

    return HealthCertificateItem(
      key: json['key']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'ESTATUTARIOS',
      seriesNo: json['series_no']?.toString(),
      state: (json['state']?.toString() ?? 'ESTADO_NO_VERIFICADO').toUpperCase(),
      stateLabel: json['state_label']?.toString() ?? json['state']?.toString() ?? '',
      isPermanent: json['is_permanent'] == true,
      isStatutoryOrClass: json['is_statutory_or_class'] == true,
      nominalExpirationDate: json['nominal_expiration_date']?.toString() ?? json['nominal_expiry']?.toString(),
      effectiveExpirationDate: json['effective_expiration_date']?.toString() ?? json['effective_deadline']?.toString(),
      daysToNominal: _optI(json['days_to_nominal']),
      daysRemainingEffective: _optI(json['days_remaining_effective'] ?? json['window_days_remaining']),
      daysOverdueEffective: _i(json['days_overdue_effective']),
      normativeBasis: json['normative_basis']?.toString() ?? json['notes']?.toString(),
    );
  }

  bool get isEnVentanaRenovacion => state == 'EN_VENTANA_RENOVACION';
  bool get isVigente => state == 'VIGENTE';
  bool get isProximoAVencer => state == 'PROXIMO_A_VENCER';
  bool get isVencido => state == 'VENCIDO';
  bool get isNoVerificado => state == 'ESTADO_NO_VERIFICADO';
}

/// Tareas de mantenimiento desglosadas con rigor
class MaintenanceTasksSummary {
  final List<MaintenanceTaskItem> criticalOverdue; // ▲ Críticos vencidos
  final List<MaintenanceTaskItem> normalOverdue; // ● Ordinarios vencidos
  final List<MaintenanceTaskItem> warning; // Próximos
  final List<MaintenanceTaskItem> dock; // Dique

  MaintenanceTasksSummary({
    required this.criticalOverdue,
    required this.normalOverdue,
    required this.warning,
    required this.dock,
  });

  factory MaintenanceTasksSummary.fromJson(Map<String, dynamic> json) {
    List<MaintenanceTaskItem> _list(dynamic v) {
      if (v is List) {
        return v.map((item) => MaintenanceTaskItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return MaintenanceTasksSummary(
      criticalOverdue: _list(json['critical_overdue']),
      normalOverdue: _list(json['normal_overdue']),
      warning: _list(json['warning']),
      dock: _list(json['dock']),
    );
  }

  int get totalOverdue => criticalOverdue.length + normalOverdue.length;
}

/// Detalle de tarea de mantenimiento MARAD
class MaintenanceTaskItem {
  final int id;
  final String maradJobId;
  final String name;
  final String description;
  final String category;
  final String dueDate;
  final String status;
  final bool isCritical;
  final bool isDock;
  final String ranks;

  MaintenanceTaskItem({
    required this.id,
    required this.maradJobId,
    required this.name,
    required this.description,
    required this.category,
    required this.dueDate,
    required this.status,
    required this.isCritical,
    required this.isDock,
    required this.ranks,
  });

  factory MaintenanceTaskItem.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
    return MaintenanceTaskItem(
      id: _i(json['id']),
      maradJobId: json['marad_job_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Maintenance',
      dueDate: json['dueDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Vencido',
      isCritical: json['isCritical'] == true || json['is_critical'] == 1,
      isDock: json['isDock'] == true,
      ranks: json['ranks']?.toString() ?? '',
    );
  }
}

/// Tripulación a bordo alineada con RRHH Vista Por Barco
class HealthCrewMember {
  final int id;
  final String name;
  final String role;
  final String roleShort; // CAP, 1ER OF CUB, etc.
  final String regime; // Efectivo (30d), Relevo (45d)
  final int maxDaysLimit;
  final int daysOnBoard;
  final String startDate;
  final bool isOverLimit;
  final bool isPreventive;
  final double gfrancoOnboard; // GF
  final double fcoPreEmbark; // F.Pre
  final bool hasExpiredCert;
  final bool hasExpiring1mCert;

  HealthCrewMember({
    required this.id,
    required this.name,
    required this.role,
    required this.roleShort,
    required this.regime,
    required this.maxDaysLimit,
    required this.daysOnBoard,
    required this.startDate,
    required this.isOverLimit,
    required this.isPreventive,
    required this.gfrancoOnboard,
    required this.fcoPreEmbark,
    required this.hasExpiredCert,
    required this.hasExpiring1mCert,
  });

  factory HealthCrewMember.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);

    return HealthCrewMember(
      id: _i(json['id']),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      roleShort: json['role_short']?.toString() ?? json['role']?.toString() ?? '',
      regime: json['regime']?.toString() ?? 'Efectivo (30d)',
      maxDaysLimit: _i(json['max_days_limit']),
      daysOnBoard: _i(json['days_on_board']),
      startDate: json['start_date']?.toString() ?? '',
      isOverLimit: json['is_over_limit'] == true,
      isPreventive: json['is_preventive'] == true,
      gfrancoOnboard: _d(json['gfranco_onboard']),
      fcoPreEmbark: _d(json['fco_pre_embark']),
      hasExpiredCert: json['has_expired_cert'] == true,
      hasExpiring1mCert: json['has_expiring_1m_cert'] == true,
    );
  }
}

/// Paridad oficial con MARAD
class MaradOfficialParity {
  final Map<String, dynamic> maintenance;
  final Map<String, dynamic> runningHours;
  final Map<String, dynamic> inventory;
  final Map<String, dynamic> certificates;
  final String lastSyncedAt;

  MaradOfficialParity({
    required this.maintenance,
    required this.runningHours,
    required this.inventory,
    required this.certificates,
    required this.lastSyncedAt,
  });

  factory MaradOfficialParity.fromJson(Map<String, dynamic> json) {
    return MaradOfficialParity(
      maintenance: json['maintenance'] is Map<String, dynamic> ? json['maintenance'] : {},
      runningHours: json['running_hours'] is Map<String, dynamic> ? json['running_hours'] : {},
      inventory: json['inventory'] is Map<String, dynamic> ? json['inventory'] : {},
      certificates: json['certificates'] is Map<String, dynamic> ? json['certificates'] : {},
      lastSyncedAt: json['last_synced_at']?.toString() ?? '',
    );
  }

  int get triangleRed => (maintenance['triangle']?['red'] as num?)?.toInt() ?? 0;
  int get circleRed => (maintenance['circle']?['red'] as num?)?.toInt() ?? 0;
  int get runningHoursRed => (runningHours['red'] as num?)?.toInt() ?? 0;
  int get runningHoursGreen => (runningHours['green'] as num?)?.toInt() ?? 0;
}

/// Prioridad o alerta accionable
class HealthPriorityItem {
  final String id;
  final String severity; // 'critical', 'warning', 'info'
  final String badge;
  final String title;
  final String description;
  final String category; // 'maintenance', 'certificates', 'crew', 'purchases'

  HealthPriorityItem({
    required this.id,
    required this.severity,
    required this.badge,
    required this.title,
    required this.description,
    required this.category,
  });

  factory HealthPriorityItem.fromJson(Map<String, dynamic> json) {
    return HealthPriorityItem(
      id: json['id']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'warning',
      badge: json['badge']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }

  bool get isCritical => severity == 'critical';
  bool get isRenewalWindow => category == 'certificates' && (title.toLowerCase().contains('renovación') || description.toLowerCase().contains('renovación'));
}

/// Sincronización real de fuentes (trazabilidad MARAD e Intranet)
class HealthSourcesSync {
  final String maradLastSuccessAt;
  final String maradLastSuccessFormatted;
  final String maradRelativeAge;
  final String intranetCrewLastSuccessAt;
  final String intranetPurchasesLastSuccessAt;
  final String status;

  HealthSourcesSync({
    required this.maradLastSuccessAt,
    required this.maradLastSuccessFormatted,
    required this.maradRelativeAge,
    required this.intranetCrewLastSuccessAt,
    required this.intranetPurchasesLastSuccessAt,
    required this.status,
  });

  factory HealthSourcesSync.fromJson(Map<String, dynamic> json) {
    return HealthSourcesSync(
      maradLastSuccessAt: json['marad_last_success_at']?.toString() ?? '',
      maradLastSuccessFormatted: json['marad_last_success_formatted']?.toString() ?? '',
      maradRelativeAge: json['marad_relative_age']?.toString() ?? '',
      intranetCrewLastSuccessAt: json['intranet_crew_last_success_at']?.toString() ?? '',
      intranetPurchasesLastSuccessAt: json['intranet_purchases_last_success_at']?.toString() ?? '',
      status: json['status']?.toString() ?? 'actualizado',
    );
  }
}
