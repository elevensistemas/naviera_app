import 'dart:convert';

/// Modelo de datos para el módulo "Salarios" / Información Laboral
class SalaryCostResponse {
  final Map<String, dynamic> filters;
  final int count;
  final SalaryTotals? totals;
  final List<SalaryPeriod> periods;

  SalaryCostResponse({
    required this.filters,
    required this.count,
    this.totals,
    required this.periods,
  });

  factory SalaryCostResponse.fromJson(Map<String, dynamic> json) {
    return SalaryCostResponse(
      filters: json['filters'] is Map<String, dynamic> ? json['filters'] : {},
      count: json['count'] is int ? json['count'] : (int.tryParse('${json['count']}') ?? 0),
      totals: json['totals'] is Map<String, dynamic> ? SalaryTotals.fromJson(json['totals']) : null,
      periods: (json['periods'] as List<dynamic>?)
              ?.map((p) => SalaryPeriod.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SalaryTotals {
  final int periodsCount;
  final double totalEmployerCost;
  final double netPay;
  final double withholdings;
  final double employerContributions;
  final double severanceCost;
  final double headcountAvg;
  final int headcountSeverancesTotal;
  final double costToNetRatio;

  SalaryTotals({
    required this.periodsCount,
    required this.totalEmployerCost,
    required this.netPay,
    required this.withholdings,
    required this.employerContributions,
    required this.severanceCost,
    required this.headcountAvg,
    required this.headcountSeverancesTotal,
    required this.costToNetRatio,
  });

  factory SalaryTotals.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    int _i(dynamic v) => (v is int) ? v : (int.tryParse('$v') ?? 0);

    return SalaryTotals(
      periodsCount: _i(json['periods_count']),
      totalEmployerCost: _d(json['total_employer_cost']),
      netPay: _d(json['net_pay']),
      withholdings: _d(json['withholdings']),
      employerContributions: _d(json['employer_contributions']),
      severanceCost: _d(json['severance_cost']),
      headcountAvg: _d(json['headcount_avg']),
      headcountSeverancesTotal: _i(json['headcount_severances_total']),
      costToNetRatio: _d(json['cost_to_net_ratio']),
    );
  }
}

class SalaryPeriod {
  final String periodCode; // e.g. "2026-10"
  final String periodDate;
  final String periodLabel; // e.g. "Octubre 2026"
  final String previousPeriodCode;
  final String previousPeriodLabel;
  final String segment; // TRIPULANTES, OFICINA, CONSOLIDADO
  final String reportType;
  final String title;
  final String subtitle;
  final double totalEmployerCost;
  final double netPay;
  final double withholdings;
  final double employerContributions;
  final double costToNetRatio;
  final double contribToRemunRatio;
  final int headcountTotal;
  final int headcountSeverances;
  final double severanceCost;
  final double momVariationPct;
  final String momVariationNote;
  final List<String> executiveNotes;
  final List<SalaryCenter> centers;
  final List<SalaryCompositionItem> composition;

  SalaryPeriod({
    required this.periodCode,
    required this.periodDate,
    required this.periodLabel,
    required this.previousPeriodCode,
    required this.previousPeriodLabel,
    required this.segment,
    required this.reportType,
    required this.title,
    required this.subtitle,
    required this.totalEmployerCost,
    required this.netPay,
    required this.withholdings,
    required this.employerContributions,
    required this.costToNetRatio,
    required this.contribToRemunRatio,
    required this.headcountTotal,
    required this.headcountSeverances,
    required this.severanceCost,
    required this.momVariationPct,
    required this.momVariationNote,
    required this.executiveNotes,
    required this.centers,
    required this.composition,
  });

  factory SalaryPeriod.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    int _i(dynamic v) => (v is int) ? v : (int.tryParse('$v') ?? 0);

    return SalaryPeriod(
      periodCode: json['period_code']?.toString() ?? '',
      periodDate: json['period_date']?.toString() ?? '',
      periodLabel: json['period_label']?.toString() ?? '',
      previousPeriodCode: json['previous_period_code']?.toString() ?? '',
      previousPeriodLabel: json['previous_period_label']?.toString() ?? '',
      segment: json['segment']?.toString() ?? '',
      reportType: json['report_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      totalEmployerCost: _d(json['total_employer_cost']),
      netPay: _d(json['net_pay']),
      withholdings: _d(json['withholdings']),
      employerContributions: _d(json['employer_contributions']),
      costToNetRatio: _d(json['cost_to_net_ratio']),
      contribToRemunRatio: _d(json['contrib_to_remun_ratio']),
      headcountTotal: _i(json['headcount_total']),
      headcountSeverances: _i(json['headcount_severances']),
      severanceCost: _d(json['severance_cost']),
      momVariationPct: _d(json['mom_variation_pct']),
      momVariationNote: json['mom_variation_note']?.toString() ?? '',
      executiveNotes: (json['executive_notes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      centers: (json['centers'] as List<dynamic>?)
              ?.map((c) => SalaryCenter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      composition: (json['composition'] as List<dynamic>?)
              ?.map((cp) => SalaryCompositionItem.fromJson(cp as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SalaryCenter {
  final String centerName;
  final int shipId;
  final int departmentId;
  final int headcountTotal;
  final int headcountActive;
  final int headcountSeverances;
  final double netPay;
  final double withholdings;
  final double employerContributions;
  final double totalEmployerCost;
  final double costSharePct;
  final double activeCost;
  final double severanceCost;
  final double severanceNetPay;
  final double severanceCostSharePct;

  // Breakdown of contributions
  final double contribSocialSecurity;
  final double contribHealthInsurance;
  final double contribArt;
  final double contribLifeInsurance;
  final double contribUnion;
  final double contribToRemunRatio;

  SalaryCenter({
    required this.centerName,
    required this.shipId,
    required this.departmentId,
    required this.headcountTotal,
    required this.headcountActive,
    required this.headcountSeverances,
    required this.netPay,
    required this.withholdings,
    required this.employerContributions,
    required this.totalEmployerCost,
    required this.costSharePct,
    required this.activeCost,
    required this.severanceCost,
    required this.severanceNetPay,
    required this.severanceCostSharePct,
    required this.contribSocialSecurity,
    required this.contribHealthInsurance,
    required this.contribArt,
    required this.contribLifeInsurance,
    required this.contribUnion,
    required this.contribToRemunRatio,
  });

  factory SalaryCenter.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    int _i(dynamic v) => (v is int) ? v : (int.tryParse('$v') ?? 0);

    return SalaryCenter(
      centerName: json['center_name']?.toString() ?? '',
      shipId: _i(json['ship_id']),
      departmentId: _i(json['department_id']),
      headcountTotal: _i(json['headcount_total']),
      headcountActive: _i(json['headcount_active']),
      headcountSeverances: _i(json['headcount_severances']),
      netPay: _d(json['net_pay']),
      withholdings: _d(json['withholdings']),
      employerContributions: _d(json['employer_contributions']),
      totalEmployerCost: _d(json['total_employer_cost']),
      costSharePct: _d(json['cost_share_pct']),
      activeCost: _d(json['active_cost']),
      severanceCost: _d(json['severance_cost']),
      severanceNetPay: _d(json['severance_net_pay']),
      severanceCostSharePct: _d(json['severance_cost_share_pct']),
      contribSocialSecurity: _d(json['contrib_social_security']),
      contribHealthInsurance: _d(json['contrib_health_insurance']),
      contribArt: _d(json['contrib_art']),
      contribLifeInsurance: _d(json['contrib_life_insurance']),
      contribUnion: _d(json['contrib_union']),
      contribToRemunRatio: _d(json['contrib_to_remun_ratio']),
    );
  }
}

class SalaryCompositionItem {
  final String conceptCode;
  final String conceptLabel;
  final String macroGroup; // NETO, CONTRIBUCION, RETENCION
  final double amount;
  final double sharePct;

  SalaryCompositionItem({
    required this.conceptCode,
    required this.conceptLabel,
    required this.macroGroup,
    required this.amount,
    required this.sharePct,
  });

  factory SalaryCompositionItem.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    return SalaryCompositionItem(
      conceptCode: json['concept_code']?.toString() ?? '',
      conceptLabel: json['concept_label']?.toString() ?? '',
      macroGroup: json['macro_group']?.toString() ?? '',
      amount: _d(json['amount']),
      sharePct: _d(json['share_pct']),
    );
  }
}
