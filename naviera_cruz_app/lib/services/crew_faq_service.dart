import 'package:flutter/foundation.dart';
import '../models/crew_profile.dart';
import '../core/network.dart';

enum FAQCategory {
  seguridadReportes,
  emergenciasFamiliarizacion,
  descansoAptitud,
  embarquesCapacitacion,
  consultasBienestar,
  equiposDocumentos,
  usoApp,
  ciberseguridadSoporte,
  general,
  sistemasTI,
  operaciones,
  rrhh,
  compras,
  barcosFlota,
}

extension FAQCategoryExtension on FAQCategory {
  String get displayName {
    switch (this) {
      case FAQCategory.seguridadReportes:
        return "Seguridad y Reportes";
      case FAQCategory.emergenciasFamiliarizacion:
        return "Emergencias y Familiarización";
      case FAQCategory.descansoAptitud:
        return "Descanso, Medicación y Aptitud";
      case FAQCategory.embarquesCapacitacion:
        return "Embarques, Documentación y Capacitación";
      case FAQCategory.consultasBienestar:
        return "Consultas y Bienestar a Bordo";
      case FAQCategory.equiposDocumentos:
        return "Equipos, Documentos y Herramientas";
      case FAQCategory.usoApp:
        return "Uso de la App";
      case FAQCategory.ciberseguridadSoporte:
        return "Ciberseguridad, Claves y Soporte";
      case FAQCategory.general:
        return "General";
      case FAQCategory.sistemasTI:
        return "Sistemas / TI";
      case FAQCategory.operaciones:
        return "Operaciones";
      case FAQCategory.rrhh:
        return "RRHH";
      case FAQCategory.compras:
        return "Compras";
      case FAQCategory.barcosFlota:
        return "Barcos / Flota";
    }
  }

  String get iconName {
    switch (this) {
      case FAQCategory.seguridadReportes:
        return "shield";
      case FAQCategory.emergenciasFamiliarizacion:
        return "warning";
      case FAQCategory.descansoAptitud:
        return "hotel";
      case FAQCategory.embarquesCapacitacion:
        return "badge";
      case FAQCategory.consultasBienestar:
        return "people";
      case FAQCategory.equiposDocumentos:
        return "build";
      case FAQCategory.usoApp:
        return "phone_android";
      case FAQCategory.ciberseguridadSoporte:
        return "security";
      case FAQCategory.general:
        return "info";
      case FAQCategory.sistemasTI:
        return "computer";
      case FAQCategory.operaciones:
        return "anchor";
      case FAQCategory.rrhh:
        return "groups";
      case FAQCategory.compras:
        return "shopping_cart";
      case FAQCategory.barcosFlota:
        return "directions_boat";
    }
  }

  String get apiCode {
    switch (this) {
      case FAQCategory.seguridadReportes:
        return "seguridad_reportes";
      case FAQCategory.emergenciasFamiliarizacion:
        return "emergencias";
      case FAQCategory.descansoAptitud:
        return "descanso_aptitud";
      case FAQCategory.embarquesCapacitacion:
        return "embarques_doc";
      case FAQCategory.consultasBienestar:
        return "bienestar";
      case FAQCategory.equiposDocumentos:
        return "equipos_doc";
      case FAQCategory.usoApp:
        return "app";
      case FAQCategory.ciberseguridadSoporte:
        return "ciberseguridad";
      case FAQCategory.general:
        return "general";
      case FAQCategory.sistemasTI:
        return "sistemas";
      case FAQCategory.operaciones:
        return "operaciones";
      case FAQCategory.rrhh:
        return "rrhh";
      case FAQCategory.compras:
        return "compras";
      case FAQCategory.barcosFlota:
        return "barcos";
    }
  }

  static FAQCategory fromApiCode(String? code) {
    if (code == null) return FAQCategory.seguridadReportes;
    switch (code.toLowerCase().trim()) {
      case "seguridad_reportes":
      case "seguridad":
        return FAQCategory.seguridadReportes;
      case "emergencias":
      case "emergencias_familiarizacion":
        return FAQCategory.emergenciasFamiliarizacion;
      case "descanso_aptitud":
      case "descanso":
      case "salud":
        return FAQCategory.descansoAptitud;
      case "embarques_doc":
      case "embarques":
      case "capacitacion":
        return FAQCategory.embarquesCapacitacion;
      case "bienestar":
      case "consultas":
      case "quejas":
        return FAQCategory.consultasBienestar;
      case "equipos_doc":
      case "equipos":
      case "herramientas":
      case "mantenimiento":
        return FAQCategory.equiposDocumentos;
      case "app":
      case "uso_app":
      case "aplicacion":
        return FAQCategory.usoApp;
      case "ciberseguridad":
      case "claves":
        return FAQCategory.ciberseguridadSoporte;
      case "general":
        return FAQCategory.general;
      case "sistemas":
      case "ti":
      case "sistemas_ti":
        return FAQCategory.sistemasTI;
      case "operaciones":
        return FAQCategory.operaciones;
      case "rrhh":
      case "recursos_humanos":
        return FAQCategory.rrhh;
      case "compras":
        return FAQCategory.compras;
      case "barcos":
      case "flota":
      case "barcos_flota":
        return FAQCategory.barcosFlota;
      default:
        return FAQCategory.seguridadReportes;
    }
  }
}

class CrewFAQItem {
  final String id;
  final FAQCategory category;
  final String mainQuestion;
  final List<String> variants;
  final String answerTemplate;
  final String source;
  final List<String> requiredPermissions;
  final String fallbackAnswer;
  final String reviewStatus; // 'verificado' | 'pendiente_revision'
  final bool isPersonalData;
  final int orden;
  final bool activo;
  final DateTime? updatedAt;

  const CrewFAQItem({
    required this.id,
    required this.category,
    required this.mainQuestion,
    required this.variants,
    required this.answerTemplate,
    required this.source,
    this.requiredPermissions = const ['crew_access'],
    this.fallbackAnswer = "No tengo información oficial disponible para responder esta consulta.",
    this.reviewStatus = 'verificado',
    this.isPersonalData = false,
    this.orden = 0,
    this.activo = true,
    this.updatedAt,
  });

  /// Factory para instanciar directamente un ítem devuelto por la Intranet (/api/v1/faqs/)
  factory CrewFAQItem.fromIntranetJson(Map<String, dynamic> json, {CrewFAQItem? baseMatch}) {
    final rawCat = json['categoria']?.toString();
    final cat = FAQCategoryExtension.fromApiCode(rawCat);
    final idStr = json['id'] != null ? json['id'].toString() : (baseMatch?.id ?? '0');
    final question = (json['pregunta'] ?? baseMatch?.mainQuestion ?? '').toString().trim();
    final answer = (json['respuesta'] ?? baseMatch?.answerTemplate ?? '').toString().trim();
    final orden = json['orden'] is int ? json['orden'] as int : (int.tryParse(json['orden']?.toString() ?? '') ?? 0);
    final activo = json['activo'] == null || json['activo'] == true || json['activo'] == 1 || json['activo'] == 'true';

    DateTime? updated;
    if (json['updated_at'] != null) {
      updated = DateTime.tryParse(json['updated_at'].toString());
    }

    String source = baseMatch?.source ?? "Intranet NCS • Procedimientos Oficiales";
    if (json['updated_by_name'] != null && json['updated_by_name'].toString().isNotEmpty) {
      source = "Intranet NCS • Modificado por ${json['updated_by_name']}";
    }

    // Conservar variantes enriquecidas si coincide con la base de conocimiento
    final variants = (baseMatch != null && baseMatch.variants.isNotEmpty)
        ? baseMatch.variants
        : _generateDefaultVariants(question);

    return CrewFAQItem(
      id: "INT-$idStr",
      category: cat,
      mainQuestion: question,
      variants: variants,
      answerTemplate: answer,
      source: source,
      orden: orden,
      activo: activo,
      updatedAt: updated,
      reviewStatus: 'verificado',
      isPersonalData: baseMatch?.isPersonalData ?? false,
    );
  }

  static List<String> _generateDefaultVariants(String question) {
    var s = question.toLowerCase();
    s = s.replaceAll(RegExp(r'[áàäâ]'), 'a');
    s = s.replaceAll(RegExp(r'[éèëê]'), 'e');
    s = s.replaceAll(RegExp(r'[íìïî]'), 'i');
    s = s.replaceAll(RegExp(r'[óòöô]'), 'o');
    s = s.replaceAll(RegExp(r'[úùüû]'), 'u');
    s = s.replaceAll(RegExp(r'[¿?¡!.,:;()\[\]"_/\-]'), ' ');
    final words = s.split(' ').where((w) => w.length > 2).toList();
    final List<String> list = [s.trim()];
    if (words.length >= 3) {
      list.add(words.take(3).join(' '));
    }
    return list;
  }

  /// Resuelve la plantilla de respuesta
  String resolveAnswer(CrewProfile? profile) {
    if (reviewStatus != 'verificado') {
      return fallbackAnswer;
    }
    return answerTemplate;
  }
}

class FAQMatchResult {
  final CrewFAQItem? item;
  final String message;
  final List<CrewFAQItem> relatedItems;
  final bool isVerified;
  final String? source;

  const FAQMatchResult({
    this.item,
    required this.message,
    this.relatedItems = const [],
    this.isVerified = true,
    this.source,
  });
}

class CrewFAQService {
  static final CrewFAQService shared = CrewFAQService._internal();
  CrewFAQService._internal();

  /// Catálogo oficial de 70 preguntas frecuentes para Tripulantes,
  /// auditado y estructurado en 8 categorías operativas de Naviera Cruz del Sur.
  static const List<CrewFAQItem> catalog = [
    // =========================================================================
    // 1. SEGURIDAD Y REPORTES (Preguntas 1 a 9)
    // =========================================================================
    CrewFAQItem(
      id: "FAQ-SEG-01",
      category: FAQCategory.seguridadReportes,
      mainQuestion: "¿Cómo reporto un accidente o incidente a bordo?",
      variants: [
        "como reporto un accidente",
        "como reporto un incidente",
        "reportar accidente a bordo",
        "accidente a bordo",
        "tuve un accidente",
        "informar accidente",
        "como informar un incidente",
        "reportar un incidente",
      ],
      answerTemplate: "Avisá de inmediato al oficial responsable o al Capitán. Después, el hecho debe registrarse mediante el procedimiento de incidentes de la compañía. Si hay una emergencia, primero se atiende la situación y luego se completa el reporte.",
      source: "Procedimiento de Gestión de Incidentes NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-SEG-02",
      category: FAQCategory.seguridadReportes,
      mainQuestion: "¿Tengo que informar una situación peligrosa aunque nadie se haya lastimado?",
      variants: [
        "situacion peligrosa",
        "informar peligro",
        "nadie se lastimo",
        "situacion de riesgo",
        "riesgo sin lesiones",
        "informar situacion peligrosa",
        "avisar riesgo",
      ],
      answerTemplate: "Sí. También deben informarse las situaciones que podrían causar lesiones, daños o contaminación. Reportarlas permite corregirlas antes de que ocurra un accidente.",
      source: "Manual de Seguridad NCS - Reporte Proactivo",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-SEG-03",
      category: FAQCategory.seguridadReportes,
      mainQuestion: "¿Qué es un cuasi accidente?",
      variants: [
        "que es un cuasi accidente",
        "cuasi accidente",
        "near miss",
        "definicion de cuasi accidente",
        "casi un accidente",
      ],
      answerTemplate: "Es un suceso que pudo haber causado lesiones, daños o contaminación, pero finalmente no los produjo. Aunque no haya consecuencias, debe informarse para prevenir que se repita.",
      source: "Sistema de Gestión de Seguridad NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-SEG-04",
      category: FAQCategory.seguridadReportes,
      mainQuestion: "¿Qué es una condición insegura?",
      variants: [
        "que es una condicion insegura",
        "condicion insegura",
        "ejemplo de condicion insegura",
        "lugar peligroso",
        "equipo roto",
      ],
      answerTemplate: "Es una situación del lugar de trabajo, de una instalación o de un equipo que puede provocar un accidente. Por ejemplo, una pérdida, un elemento deteriorado o una zona de circulación obstruida.",
      source: "Normas de Higiene y Seguridad NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-SEG-05",
      category: FAQCategory.seguridadReportes,
      mainQuestion: "¿Qué es un acto inseguro?",
      variants: [
        "que es un acto inseguro",
        "acto inseguro",
        "accion insegura",
        "definicion acto inseguro",
        "hacer algo sin seguridad",
      ],
      answerTemplate: "Es una acción que puede poner en riesgo a las personas, al buque o al ambiente, como realizar una tarea sin respetar el procedimiento de seguridad correspondiente.",
      source: "Manual de Prevención de Riesgos NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-SEG-06",
      category: FAQCategory.seguridadReportes,
      mainQuestion: "¿Dónde se registran los incidentes de seguridad?",
      variants: [
        "donde se registran los incidentes",
        "donde cargo el incidente",
        "donde se registra un incidente de seguridad",
        "modulo incidentes intranet",
        "cargar accidente en intranet",
      ],
      answerTemplate: "El manual contempla su registro en la intranet de la compañía, dentro de “Incidentes Seguridad”. La carga y el tratamiento se realizan según el tipo de evento y las responsabilidades establecidas.",
      source: "Intranet NCS - Módulo Incidentes Seguridad",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-SEG-07",
      category: FAQCategory.seguridadReportes,
      mainQuestion: "¿Qué hago si detecto que no se está cumpliendo un procedimiento?",
      variants: [
        "no se cumple un procedimiento",
        "detecto incumplimiento",
        "alguien no cumple procedimiento",
        "incumplimiento de normas",
        "que hacer si no cumplen protocolo",
      ],
      answerTemplate: "Ponelo en conocimiento del oficial responsable o del Capitán. Todo el personal puede identificar e informar incumplimientos para que sean evaluados y tratados.",
      source: "Manual de Gestión Operativa NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-SEG-08",
      category: FAQCategory.seguridadReportes,
      mainQuestion: "¿Cualquier tripulante puede emitir una no conformidad?",
      variants: [
        "puedo emitir una no conformidad",
        "quien emite una no conformidad",
        "no conformidad tripulante",
        "emitir no conformidad",
        "quienes pueden emitir no conformidades",
      ],
      answerTemplate: "Todo tripulante puede informar un incumplimiento. La emisión formal de una no conformidad corresponde a los responsables autorizados: Capitán, gerentes, Persona Designada y auditores internos en ejercicio de sus funciones.",
      source: "Procedimiento de No Conformidades y Acciones Correctivas NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-SEG-09",
      category: FAQCategory.seguridadReportes,
      mainQuestion: "¿Para qué sirven las lecciones aprendidas?",
      variants: [
        "para que sirven las lecciones aprendidas",
        "lecciones aprendidas",
        "que son las lecciones aprendidas",
        "difusion de lecciones aprendidas",
      ],
      answerTemplate: "Sirven para compartir lo aprendido de incidentes y otras experiencias, mejorar las prácticas de trabajo y evitar que los mismos problemas se repitan.",
      source: "Sistema de Mejora Continua NCS",
      reviewStatus: 'verificado',
    ),

    // =========================================================================
    // 2. EMERGENCIAS Y FAMILIARIZACIÓN (Preguntas 10 a 17)
    // =========================================================================
    CrewFAQItem(
      id: "FAQ-EME-10",
      category: FAQCategory.emergenciasFamiliarizacion,
      mainQuestion: "¿Qué hago si suena una alarma de emergencia?",
      variants: [
        "suena alarma de emergencia",
        "que hacer si suena alarma",
        "alarma de emergencia",
        "toque de zafarrancho",
        "sonar de alarma",
      ],
      answerTemplate: "Cumplí las instrucciones correspondientes a tu función y al cuadro de zafarranchos del buque. Es importante conocer de antemano tu puesto y tus responsabilidades.",
      source: "Cuadro de Zafarranchos y Plan de Contingencias NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EME-11",
      category: FAQCategory.emergenciasFamiliarizacion,
      mainQuestion: "¿Cómo sé cuál es mi función durante una emergencia?",
      variants: [
        "como se mi funcion en emergencia",
        "cual es mi puesto de emergencia",
        "mi rol en zafarrancho",
        "donde me presento en emergencia",
        "conocer funcion emergencia",
      ],
      answerTemplate: "Debés conocerla durante la familiarización a bordo. Si no tenés claro qué hacer o dónde presentarte, consultá al oficial responsable antes de comenzar tus tareas.",
      source: "Manual de Familiarización a Bordo NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EME-12",
      category: FAQCategory.emergenciasFamiliarizacion,
      mainQuestion: "¿Para qué se realizan los zafarranchos?",
      variants: [
        "para que se hacen los zafarranchos",
        "objetivo de los zafarranchos",
        "porque hacemos zafarranchos",
        "ejercicios de zafarrancho",
      ],
      answerTemplate: "Para entrenar a la tripulación y comprobar que puede responder ante una emergencia. También permiten detectar dificultades y mejorar los planes de respuesta.",
      source: "Plan de Instrucción y Adiestramiento NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EME-13",
      category: FAQCategory.emergenciasFamiliarizacion,
      mainQuestion: "¿Con qué frecuencia se hacen los ejercicios de emergencia?",
      variants: [
        "con que frecuencia se hacen zafarranchos",
        "cada cuanto se hace un zafarrancho",
        "frecuencia ejercicios emergencia",
        "cuando se hacen los simulacros",
      ],
      answerTemplate: "Depende del ejercicio y del tipo de navegación del buque. El manual establece un programa con distintas frecuencias y el Capitán puede aumentarlas cuando lo considere necesario.",
      source: "Cronograma de Ejercicios y Zafarranchos NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EME-14",
      category: FAQCategory.emergenciasFamiliarizacion,
      mainQuestion: "¿La participación en los zafarranchos queda registrada?",
      variants: [
        "queda registrada la participacion en zafarrancho",
        "formulario pe-01",
        "pe 01 zafarrancho",
        "firmar zafarrancho",
        "registro de ejercicios de emergencia",
      ],
      answerTemplate: "Sí. Los ejercicios y sus participantes se documentan en los registros correspondientes. El formulario PE-01 debe llevar la firma de los tripulantes que participaron.",
      source: "Registro PE-01 de Participación en Ejercicios NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EME-15",
      category: FAQCategory.emergenciasFamiliarizacion,
      mainQuestion: "¿Qué debo conocer cuando embarco por primera vez en un buque?",
      variants: [
        "que debo conocer al embarcar por primera vez",
        "primer embarque en buque",
        "instrucciones de seguridad previas a zarpada",
        "familiarizacion inicial",
        "embarcar por primera vez",
      ],
      answerTemplate: "Debés recibir las instrucciones de seguridad previas a la zarpada y familiarizarte con el buque, los equipos y tus funciones. Si tenés responsabilidades ante un derrame, también debés conocer el plan correspondiente.",
      source: "Procedimiento de Familiarización de Seguridad NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EME-16",
      category: FAQCategory.emergenciasFamiliarizacion,
      mainQuestion: "¿Debo repetir la familiarización si ya trabajé en ese buque?",
      variants: [
        "repetir familiarizacion",
        "ya trabaje en este buque familiarizacion",
        "tres anos ultimo embarque",
        "cuando repetir la familiarizacion",
      ],
      answerTemplate: "El manual exige repetirla si pasaron más de tres años desde tu último embarque en ese mismo buque. Cualquier duda sobre equipos, cambios o procedimientos debe aclararse antes de asumir funciones.",
      source: "Directiva de Embarques y Familiarizaciones NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EME-17",
      category: FAQCategory.emergenciasFamiliarizacion,
      mainQuestion: "¿Qué hago si detecto un derrame o un posible riesgo de contaminación?",
      variants: [
        "detecto un derrame",
        "derrame a bordo",
        "riesgo de contaminacion",
        "derrame de combustible",
        "plan de contingencia contaminacion",
      ],
      answerTemplate: "Avisá inmediatamente al oficial responsable o al Capitán y cumplí las instrucciones del plan de contingencia del buque. Actuá según tu función y el entrenamiento recibido.",
      source: "Plan SOPEP / Contingencias Ambientales NCS",
      reviewStatus: 'verificado',
    ),

    // =========================================================================
    // 3. DESCANSO, MEDICACIÓN Y APTITUD PARA EL SERVICIO (Preguntas 18 a 27)
    // =========================================================================
    CrewFAQItem(
      id: "FAQ-DES-18",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿Qué hago si estoy muy cansado para cumplir mi guardia?",
      variants: [
        "estoy muy cansado para la guardia",
        "fatiga en la guardia",
        "cansancio para guardia",
        "no puedo hacer guardia cansado",
        "aviso de fatiga",
      ],
      answerTemplate: "Informalo de inmediato al oficial responsable o al Capitán. La situación debe evaluarse para organizar las guardias y evitar que la fatiga comprometa la seguridad.",
      source: "Política de Gestión de Fatiga y Guardias NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DES-19",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿Dónde se registran las horas de trabajo y descanso?",
      variants: [
        "donde se registran horas de descanso",
        "registro horas de trabajo",
        "watchkeeper",
        "cargar horas descanso",
        "sistema watchkeeper",
      ],
      answerTemplate: "En los buques que cuentan con Watchkeeper, los registros se cargan diariamente en ese sistema por las personas designadas por el Capitán.",
      source: "Sistema Watchkeeper y Normas MLC NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DES-20",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿Los amarres y los zafarranchos cuentan como horas de trabajo?",
      variants: [
        "amarres cuentan como horas de trabajo",
        "zafarranchos son horas de trabajo",
        "fondeos y zarpadas horas de trabajo",
        "actividades que cuentan como trabajo",
      ],
      answerTemplate: "Sí. El manual indica que los zafarranchos, amarres, fondeos, zarpadas y otras actividades de trabajo deben incluirse en el registro.",
      source: "Control de Horas de Trabajo y Descanso NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DES-21",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿Qué pasa si se detectan desvíos en las horas de descanso?",
      variants: [
        "desvios horas de descanso",
        "incumplimiento descanso",
        "falta de descanso",
        "que pasa si no cumplo horas descanso",
        "desvio en watchkeeper",
      ],
      answerTemplate: "Deben tratarse de inmediato. La primera medida prevista es ajustar internamente el sistema de guardias para corregir el desvío. Si no puede resolverse, el Capitán debe proceder según lo establecido en el manual.",
      source: "Procedimiento de Ajuste de Guardias y Descanso NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DES-22",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿Debo informar si tomo medicamentos recetados?",
      variants: [
        "medicamentos recetados",
        "informar medicamentos",
        "tomo remedios",
        "declarar medicamentos al embarcar",
        "medicacion a bordo",
      ],
      answerTemplate: "Sí. Debés declararlo al Capitán al momento de embarcar, para que se evalúe tu aptitud para el servicio.",
      source: "Manual de Salud Ocupacional y Aptitud NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DES-23",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿Puedo trabajar bajo los efectos de una sustancia que afecte mi atención?",
      variants: [
        "trabajar bajo efectos de medicamentos",
        "sustancias que afecten atencion",
        "medicacion que da sueno",
        "trabajar con calmantes",
      ],
      answerTemplate: "La compañía prohíbe el uso de sustancias, medicinales o no, que afecten la aptitud necesaria para trabajar con seguridad. Si tenés un tratamiento indicado, informalo al Capitán para su evaluación.",
      source: "Política de Aptitud para el Servicio NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DES-24",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿Cuál es la política sobre consumo de alcohol?",
      variants: [
        "politica de alcohol",
        "se puede tomar alcohol",
        "alcohol cero",
        "consumo de alcohol a bordo",
        "prohibicion de alcohol",
      ],
      answerTemplate: "La compañía aplica alcohol cero. Está prohibido consumir bebidas alcohólicas a bordo y desempeñar funciones o permanecer en servicio con presencia de alcohol en el organismo.",
      source: "Política de Alcohol Cero y Drogas NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DES-25",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿Cuánto tiempo antes de embarcar debo evitar el alcohol?",
      variants: [
        "cuanto tiempo antes evitar alcohol",
        "abstinencia antes de embarcar",
        "48 horas antes alcohol",
        "tomar alcohol antes del embarque",
      ],
      answerTemplate: "El manual establece abstinencia absoluta de bebidas alcohólicas y sustancias ilícitas durante las 48 horas previas al embarque.",
      source: "Reglamento de Embarque y Presentación NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DES-26",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿La política de alcohol y drogas también rige si el buque está amarrado?",
      variants: [
        "alcohol si buque esta amarrado",
        "alcohol en dique seco",
        "politica de alcohol amarrado",
        "alcohol en reparaciones",
      ],
      answerTemplate: "Sí. Rige mientras permanezcas formalmente embarcado, incluso durante reparaciones, mantenimiento, dique seco, paradas técnicas u otras condiciones operativas.",
      source: "Manual de Políticas de Seguridad NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DES-27",
      category: FAQCategory.descansoAptitud,
      mainQuestion: "¿Se pueden realizar controles de alcohol y drogas sin aviso previo?",
      variants: [
        "controles de alcohol sin aviso",
        "controles aleatorios alcohol",
        "test de alcoholemia a bordo",
        "control antidoping sorpresivo",
      ],
      answerTemplate: "Sí. El manual contempla controles aleatorios y sin aviso previo, además de controles ante determinadas circunstancias, como accidentes, incidentes o sospechas fundadas.",
      source: "Procedimiento de Controles Toxicológicos NCS",
      reviewStatus: 'verificado',
    ),

    // =========================================================================
    // 4. EMBARQUES, DOCUMENTACIÓN Y CAPACITACIÓN (Preguntas 28 a 33)
    // =========================================================================
    CrewFAQItem(
      id: "FAQ-DOC-28",
      category: FAQCategory.embarquesCapacitacion,
      mainQuestion: "¿Qué documentación necesito para embarcar?",
      variants: [
        "que documentacion necesito para embarcar",
        "documentos para embarcar",
        "libreta de embarque certificados",
        "requisitos para embarcar",
        "titulos para embarque",
      ],
      answerTemplate: "La correspondiente a tu cargo, funciones y buque asignado: libreta de embarque, títulos, certificados y aptitud médica, según corresponda. Personal Embarcado verifica la documentación antes del embarque.",
      source: "Requisitos de Personal Embarcado NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DOC-29",
      category: FAQCategory.embarquesCapacitacion,
      mainQuestion: "¿Puedo embarcar si me falta documentación de la bandera del buque?",
      variants: [
        "falta documentacion bandera del buque",
        "embarcar sin endoso",
        "libretas del estado de bandera",
        "documentacion de bandera pendiente",
      ],
      answerTemplate: "En los casos en que se requieren endosos o libretas del Estado de bandera, el manual establece que no puede disponerse el embarque sin esa documentación.",
      source: "Reglamento de Habilitaciones y Banderas NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DOC-30",
      category: FAQCategory.embarquesCapacitacion,
      mainQuestion: "¿Con quién consulto mi relevo o desembarque?",
      variants: [
        "con quien consulto mi relevo",
        "consultar desembarque",
        "fecha de relevo",
        "cuando me relevan",
        "plan de relevo",
      ],
      answerTemplate: "Consultá con Personal Embarcado y con el Capitán. Los planes de relevo y las instrucciones de desembarque deben comunicarse al comando y quedar registrados por los medios establecidos.",
      source: "Procedimiento de Relevos y Desembarques NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DOC-31",
      category: FAQCategory.embarquesCapacitacion,
      mainQuestion: "¿Qué hago si necesito capacitación para una tarea?",
      variants: [
        "necesito capacitacion para una tarea",
        "pedir curso o capacitacion",
        "solicitar entrenamiento",
        "capacitacion para tarea nueva",
      ],
      answerTemplate: "Comunicalo al comando del buque. Las necesidades de capacitación se elevan a Personal Embarcado para su evaluación y planificación.",
      source: "Plan Anual de Capacitación NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DOC-32",
      category: FAQCategory.embarquesCapacitacion,
      mainQuestion: "¿Qué pasa si el resultado de una capacitación no es satisfactorio?",
      variants: [
        "capacitacion no satisfactoria",
        "desaprobe un curso",
        "resultado insatisfactorio en capacitacion",
        "reforzar capacitacion",
      ],
      answerTemplate: "El manual prevé capacitación adicional sobre el tema para los tripulantes involucrados.",
      source: "Evaluación del Desempeño y Capacitación NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-DOC-33",
      category: FAQCategory.embarquesCapacitacion,
      mainQuestion: "¿Puedo solicitar apoyo para mejorar mi inglés?",
      variants: [
        "apoyo para mejorar ingles",
        "curso de ingles tripulante",
        "aprender ingles buque",
        "clases de ingles maritimo",
      ],
      answerTemplate: "Sí. El manual contempla incorporar al plan de capacitación al personal que necesite apoyo o formación adicional en inglés.",
      source: "Plan de Idiomas y Competencias NCS",
      reviewStatus: 'verificado',
    ),

    // =========================================================================
    // 5. CONSULTAS Y BIENESTAR A BORDO (Preguntas 34 a 38)
    // =========================================================================
    CrewFAQItem(
      id: "FAQ-BIE-34",
      category: FAQCategory.consultasBienestar,
      mainQuestion: "¿Cómo presento una queja por un problema a bordo?",
      variants: [
        "como presento una queja",
        "hacer un reclamo a bordo",
        "procedimiento de quejas",
        "tengo un problema a bordo reclamo",
        "presentar queja",
      ],
      answerTemplate: "Como vía habitual, podés comunicarla al oficial del que dependés. El procedimiento también permite dirigirte directamente al Capitán o a la compañía.",
      source: "Procedimiento de Quejas y Reclamos a Bordo (MLC) NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-BIE-35",
      category: FAQCategory.consultasBienestar,
      mainQuestion: "¿Quién es el oficial designado para recibir quejas?",
      variants: [
        "oficial designado para quejas",
        "quien recibe quejas a bordo",
        "oficial de quejas",
        "primer oficial quejas",
      ],
      answerTemplate: "El Primer Oficial. Puede orientarte sobre el procedimiento, facilitar los formularios y brindar asesoramiento imparcial.",
      source: "Organigrama y Funciones de Bienestar NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-BIE-36",
      category: FAQCategory.consultasBienestar,
      mainQuestion: "¿Puedo estar acompañado al presentar una queja?",
      variants: [
        "puedo estar acompanado al presentar queja",
        "acompanante para queja",
        "presentar reclamo con un companero",
      ],
      answerTemplate: "Sí. El procedimiento contempla que puedas estar acompañado por una persona que vos elijas.",
      source: "Protocolo de Garantías y Quejas NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-BIE-37",
      category: FAQCategory.consultasBienestar,
      mainQuestion: "¿Mi queja debe quedar registrada?",
      variants: [
        "queja debe quedar registrada",
        "copia de la queja",
        "registro formal de queja",
        "constancia de reclamo",
      ],
      answerTemplate: "Sí. Tanto la queja como la decisión tomada deben registrarse. El procedimiento establece entregar una copia a quien presentó la queja y enviar otra a la oficina.",
      source: "Registro y Seguimiento de Reclamos NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-BIE-38",
      category: FAQCategory.consultasBienestar,
      mainQuestion: "¿A quién aviso si faltan víveres o detecto alimentos en mal estado?",
      variants: [
        "faltan viveres",
        "alimentos en mal estado",
        "comida en mal estado",
        "aviso comida viveres",
        "falta de alimentos a bordo",
      ],
      answerTemplate: "Informalo al cocinero y al Capitán. El cocinero controla las existencias y el consumo, y el Capitán supervisa y aprueba las necesidades de abastecimiento.",
      source: "Procedimiento de Aprovisionamiento y Bromatología NCS",
      reviewStatus: 'verificado',
    ),

    // =========================================================================
    // 6. EQUIPOS, DOCUMENTOS Y HERRAMIENTAS (Preguntas 39 a 42)
    // =========================================================================
    CrewFAQItem(
      id: "FAQ-EQU-39",
      category: FAQCategory.equiposDocumentos,
      mainQuestion: "¿Cómo se solicita una reparación o un repuesto para el buque?",
      variants: [
        "solicitar reparacion o repuesto",
        "pedido de repuestos",
        "falla de equipo pedir repuesto",
        "pedido de mantenimiento",
      ],
      answerTemplate: "El requerimiento se canaliza por los responsables a bordo y se registra mediante los formularios de mantenimiento y materiales previstos por la compañía.",
      source: "Sistema de Mantenimiento y Pedidos NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EQU-40",
      category: FAQCategory.equiposDocumentos,
      mainQuestion: "¿Una reparación que afecta la seguridad debe esperar al pedido mensual?",
      variants: [
        "reparacion urgente de seguridad",
        "esperar pedido mensual reparacion",
        "repuesto urgente seguridad",
        "pedido fuera de fecha reparacion",
      ],
      answerTemplate: "No. Los pedidos urgentes o que afectan la seguridad se envían cuando surge la necesidad, acompañados por la información y el análisis de riesgo correspondientes.",
      source: "Gestión de Pedidos Críticos de Seguridad NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EQU-41",
      category: FAQCategory.equiposDocumentos,
      mainQuestion: "¿Qué versión de un procedimiento debo utilizar?",
      variants: [
        "que version de procedimiento usar",
        "version vigente del procedimiento",
        "manual actualizado o antiguo",
        "control de documentos vigentes",
      ],
      answerTemplate: "Siempre la versión vigente disponible en los medios oficiales de la compañía. Si tenés una copia antigua o dudas sobre su actualización, consultá al responsable a bordo.",
      source: "Control de Documentación del Sistema Integrado NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-EQU-42",
      category: FAQCategory.equiposDocumentos,
      mainQuestion: "¿Puedo usar los equipos o internet de la compañía para cuestiones personales?",
      variants: [
        "usar internet para cosas personales",
        "usar pc para temas personales",
        "internet del buque uso personal",
        "wifi personal a bordo",
      ],
      answerTemplate: "El manual permite un uso personal limitado, siempre que no interfiera con las tareas, no consuma recursos significativos ni genere costos adicionales importantes. No está permitido utilizarlos para negocios personales ajenos a la compañía.",
      source: "Política de Uso de Redes y Comunicaciones NCS",
      reviewStatus: 'verificado',
    ),

    // =========================================================================
    // 7. USO DE LA APP (Preguntas 43 a 50)
    // =========================================================================
    CrewFAQItem(
      id: "FAQ-APP-43",
      category: FAQCategory.usoApp,
      mainQuestion: "¿Dónde veo cuántos días llevo embarcado?",
      variants: [
        "donde veo cuantos dias llevo embarcado",
        "dias embarcado",
        "cuantos dias llevo a bordo",
        "tiempo de embarque actual",
        "contador de dias",
      ],
      answerTemplate: "En la tarjeta de tu perfil, en la pantalla de inicio. Allí se muestra la información de tu embarque obtenida de la intranet de la compañía.",
      source: "Guía de Usuario App NCS - Módulo Perfil",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-APP-44",
      category: FAQCategory.usoApp,
      mainQuestion: "¿Dónde consulto mi buque y mi cargo?",
      variants: [
        "donde consulto mi buque y mi cargo",
        "ver mi buque y cargo",
        "datos de mi embarque en app",
        "que buque tengo asignado",
      ],
      answerTemplate: "En tu perfil de la pantalla de inicio, junto con tu estado de embarque y los demás datos disponibles.",
      source: "Guía de Usuario App NCS - Pantalla Principal",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-APP-45",
      category: FAQCategory.usoApp,
      mainQuestion: "¿Qué hago si mi fecha de embarque o mis datos están incorrectos?",
      variants: [
        "fecha de embarque incorrecta",
        "datos incorrectos en app",
        "error en fecha de embarque",
        "corregir datos del perfil",
      ],
      answerTemplate: "Comunicalo a Personal Embarcado e indicá qué dato aparece y cuál debería figurar, para que revisen el registro de origen.",
      source: "Soporte de Personal Embarcado NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-APP-46",
      category: FAQCategory.usoApp,
      mainQuestion: "¿Dónde encuentro los boletines de la compañía?",
      variants: [
        "donde encuentro los boletines",
        "ver boletines en la app",
        "seccion boletines",
        "leer boletines de seguridad",
        "boletines de la compania",
      ],
      answerTemplate: "En la sección Boletines. Allí podés consultar las publicaciones disponibles desde la intranet.",
      source: "Guía de Usuario App NCS - Sección Boletines",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-APP-47",
      category: FAQCategory.usoApp,
      mainQuestion: "¿Dónde veo los cursos que tengo asignados?",
      variants: [
        "donde veo los cursos asignados",
        "mis cursos",
        "cursos en la app",
        "seccion cursos",
        "capacitaciones asignadas",
      ],
      answerTemplate: "En la sección Cursos. La información se obtiene de los registros de capacitación de la intranet.",
      source: "Guía de Usuario App NCS - Sección Cursos",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-APP-48",
      category: FAQCategory.usoApp,
      mainQuestion: "¿Qué hago si realicé un curso y no aparece en la app?",
      variants: [
        "hice un curso y no aparece",
        "curso realizado no figura",
        "actualizar cursos en la app",
        "falta curso aprobado",
      ],
      answerTemplate: "Consultá con Personal Embarcado, indicando el nombre del curso y la fecha en que lo realizaste para que puedan verificar el registro.",
      source: "Administración de Capacitación NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-APP-49",
      category: FAQCategory.usoApp,
      mainQuestion: "¿Con quién me comunico si no puedo ingresar o la app presenta un error?",
      variants: [
        "no puedo ingresar a la app",
        "error en la app",
        "app no funciona",
        "problemas para entrar a la app",
        "soporte tecnico app",
      ],
      answerTemplate: "Con Sistemas. Indicá qué problema aparece y, si podés, adjuntá una captura de pantalla para facilitar la revisión. Nunca envíes tu contraseña.",
      source: "Mesa de Ayuda Sistemas NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-APP-50",
      category: FAQCategory.usoApp,
      mainQuestion: "¿Puedo usar la app para avisar una emergencia?",
      variants: [
        "puedo usar la app para avisar una emergencia",
        "avisar emergencia por la app",
        "reportar emergencia en la app",
        "boton de emergencia en la app",
        "usar celular en emergencia",
      ],
      answerTemplate: "Ante una emergencia, avisá inmediatamente por los medios establecidos a bordo y seguí las instrucciones del buque. Cualquier registro en la app debe realizarse después de atender la situación.",
      source: "Procedimiento de Emergencias y Uso de la App NCS",
      reviewStatus: 'verificado',
    ),

    // =========================================================================
    // 8. CIBERSEGURIDAD, CLAVES Y SOPORTE (Preguntas 51 a 70)
    // =========================================================================
    CrewFAQItem(
      id: "FAQ-CIB-51",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Cómo solicito un usuario para acceder a los sistemas de la compañía?",
      variants: [
        "como solicito un usuario",
        "solicitar usuario sistemas",
        "pedir usuario intranet",
        "crear usuario nuevo",
        "alta de usuario sistemas",
        "solicitud de cuenta de acceso",
        "pedir acceso a sistemas",
      ],
      answerTemplate: "La solicitud debe canalizarse a Sistemas con la aprobación del responsable del área. Debe indicar nombre del usuario, cargo, sector o buque y los sistemas a los que necesita acceder.",
      source: "Procedimiento de Gestión de Identidades y Accesos NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-52",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Puedo utilizar el usuario de un compañero mientras espero el mío?",
      variants: [
        "usar usuario de companero",
        "prestar usuario",
        "usar cuenta ajena",
        "compartir usuario",
        "iniciar sesion con cuenta de otro",
        "usar clave de otro companero",
      ],
      answerTemplate: "Cada persona debe utilizar su propia cuenta. Si todavía no tenés acceso, comunicate con Sistemas para gestionar el alta o una solución autorizada.",
      source: "Política de Cuentas Individuales e Intransferibles NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-53",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Cómo solicito acceso a otro sistema o carpeta?",
      variants: [
        "solicitar acceso a carpeta",
        "acceso a otro sistema",
        "permisos de carpeta de red",
        "pedir permisos sistemas",
        "acceso a carpeta compartida",
        "ampliar permisos de usuario",
      ],
      answerTemplate: "Informá qué acceso necesitás y para qué tarea. El responsable del área debe aprobarlo y Sistemas evaluará los permisos correspondientes.",
      source: "Procedimiento de Asignación de Permisos y Perfiles NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-54",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Cómo cambio mi contraseña?",
      variants: [
        "como cambio mi contrasena",
        "cambiar contrasena",
        "cambiar mi clave",
        "cambio de contrasena",
        "modificar password",
        "actualizar clave de acceso",
      ],
      answerTemplate: "Utilizá la opción de cambio de contraseña del servicio correspondiente. Si no la encontrás o accedés con una cuenta administrada por la compañía, pedí asistencia a Sistemas. No todas las plataformas comparten la misma clave.",
      source: "Manual de Autogestión de Credenciales NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-55",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Qué hago si olvidé mi contraseña o se bloqueó mi cuenta?",
      variants: [
        "olvide mi contrasena",
        "olvide mi clave",
        "cuenta bloqueada",
        "usuario bloqueado",
        "desbloquear usuario",
        "recuperar mi clave",
        "restablecer contrasena",
        "bloqueo de cuenta",
      ],
      answerTemplate: "Comunicate con Sistemas por el canal habitual. Para recuperar el acceso se verificará tu identidad. No compartas contraseñas ni códigos de verificación.",
      source: "Protocolo de Desbloqueo y Recuperación de Cuentas NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-56",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Cómo elijo una contraseña segura?",
      variants: [
        "como elijo una contrasena segura",
        "contrasena segura",
        "crear clave segura",
        "password robusto",
        "requisitos de clave",
        "ejemplo contrasena segura",
      ],
      answerTemplate: "Elegí una contraseña larga, única y difícil de adivinar. Podés usar una frase con varias palabras sin relación entre sí. Evitá nombres, fechas, nombres de buques y claves que ya uses en cuentas personales.",
      source: "Guía de Buenas Prácticas de Contraseñas NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-57",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Cuándo debo cambiar mi contraseña?",
      variants: [
        "cuando debo cambiar mi contrasena",
        "cuando cambiar la clave",
        "cada cuanto cambiar contrasena",
        "sospecha de filtracion de clave",
        "clave ingresada en sitio sospechoso",
      ],
      answerTemplate: "Cambiala de inmediato si sospechás que alguien la conoce, si la ingresaste en un sitio sospechoso o si Sistemas te lo solicita. Si usabas esa misma clave en otras cuentas, también debés cambiarla allí.",
      source: "Política de Seguridad de Contraseñas NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-58",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Sistemas puede pedirme mi contraseña o un código de verificación?",
      variants: [
        "sistemas me pide la clave",
        "soporte me pide mi contrasena",
        "codigo de verificacion sistemas",
        "entregar contrasena a soporte",
        "compartir clave con sistemas",
      ],
      answerTemplate: "No compartas tu contraseña ni códigos de verificación con ninguna persona. Sistemas puede ayudarte a recuperar el acceso sin que le informes tu clave.",
      source: "Norma de Confidencialidad de Credenciales NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-59",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Qué hago si recibo una solicitud de autenticación que no inicié?",
      variants: [
        "solicitud de autenticacion que no inicie",
        "aviso de inicio de sesion inesperado",
        "notificacion 2fa no pedida",
        "codigo mfa recibido sin pedirlo",
        "rechazar autenticacion",
      ],
      answerTemplate: "Rechazala y avisá inmediatamente a Sistemas. No apruebes solicitudes para que dejen de aparecer ni compartas el código recibido.",
      source: "Protocolo de Respuesta ante Alertas MFA NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-60",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Cómo reconozco un correo o mensaje sospechoso?",
      variants: [
        "como reconozco correo sospechoso",
        "mail sospechoso",
        "phishing correo falso",
        "mensaje sospechoso",
        "detectar mail trampa",
        "correo trampa como saber",
      ],
      answerTemplate: "Prestá atención a pedidos urgentes de dinero, contraseñas, códigos o cambios de datos bancarios. Revisá la dirección completa del remitente y desconfiá de enlaces o archivos inesperados, aunque el mensaje tenga un nombre o logo conocido.",
      source: "Manual de Prevención de Phishing NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-61",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Qué hago si recibo un mensaje sospechoso?",
      variants: [
        "que hago si recibo mensaje sospechoso",
        "recibi correo sospechoso",
        "reportar phishing",
        "que hacer con correo falso",
        "marcar como phishing",
      ],
      answerTemplate: "No respondas, no abras sus archivos ni ingreses a sus enlaces. Reportalo a Sistemas por el canal habitual. Si el correo permite marcarlo como phishing, utilizá esa opción.",
      source: "Procedimiento de Notificación de Phishing NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-62",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Qué hago si un mensaje parece venir de un gerente o compañero y me pide algo inusual?",
      variants: [
        "mensaje de gerente pide algo inusual",
        "mensaje de companero sospechoso",
        "suplantacion de identidad de jefatura",
        "pedido urgente de dinero por mail",
        "verificar mensaje sospechoso de directivo",
      ],
      answerTemplate: "Verificá el pedido por otro medio que ya conozcas, como una llamada al número habitual. No uses los teléfonos o enlaces incluidos en el mensaje sospechoso para confirmar su autenticidad.",
      source: "Procedimiento Antifraude y Suplantación de Identidad NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-63",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Qué hago si ya abrí un enlace o archivo sospechoso?",
      variants: [
        "abri enlace sospechoso",
        "hice clic en link sospechoso",
        "abri archivo peligroso",
        "descargue archivo con virus",
        "que hacer si abri phishing",
      ],
      answerTemplate: "Avisá inmediatamente a Sistemas y explicá qué abriste, a qué hora y si ingresaste datos o descargaste algo. No sigas interactuando con el contenido ni intentes borrar rastros o resolverlo por tu cuenta.",
      source: "Protocolo de Respuesta Inmediata a Incidentes Informáticos NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-64",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Qué hago si ingresé mi contraseña en una página sospechosa?",
      variants: [
        "ingrese mi contrasena en pagina sospechosa",
        "puse mi clave en pagina falsa",
        "me robaron la contrasena en phishing",
        "clave comprometida",
        "ingrese password en sitio falso",
      ],
      answerTemplate: "Contactá de inmediato a Sistemas. Desde otro dispositivo confiable, ingresá al servicio por su dirección oficial y cambiá la contraseña. Sistemas deberá revisar también las sesiones abiertas y los accesos a la cuenta.",
      source: "Procedimiento de Contención de Cuentas Comprometidas NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-65",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Qué debo hacer ante un posible ciberataque?",
      variants: [
        "que hacer ante ciberataque",
        "posible ciberataque",
        "ataque informatico a bordo",
        "desconectar de la red pc",
        "ciberseguridad a bordo buque",
        "ataque a sistemas del buque",
      ],
      answerTemplate: "Avisá inmediatamente a Sistemas y, si estás a bordo, al Capitán u oficial responsable. Si afecta una PC de uso administrativo, desconectala de la red retirando el cable o desactivando el Wi-Fi. Si afecta sistemas de navegación, comunicaciones, máquinas u operación, cualquier desconexión debe coordinarse con el comando para no comprometer la seguridad.",
      source: "Plan de Respuesta a Incidentes de Ciberseguridad Marítima NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-66",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Qué hago si aparecen archivos bloqueados o un mensaje que pide dinero?",
      variants: [
        "archivos bloqueados pide dinero",
        "ransomware",
        "virus bloqueo la maquina",
        "pantalla de rescate",
        "archivos encriptados",
        "piden rescate por archivos",
      ],
      answerTemplate: "Dejá de usar el equipo y reportalo de inmediato. Aislalo de la red si es una PC administrativa y no conectes discos externos ni pendrives. No pagues, no contactes al atacante y no apagues ni reinicies el equipo por iniciativa propia; seguí las indicaciones de Sistemas.",
      source: "Protocolo Específico ante Ransomware NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-67",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Puedo instalar programas, extensiones o herramientas por mi cuenta?",
      variants: [
        "puedo instalar programas",
        "instalar software en la pc",
        "instalar extensiones navegador",
        "instalar herramientas por mi cuenta",
        "descargar aplicaciones pc",
      ],
      answerTemplate: "Solicitá autorización a Sistemas antes de instalarlos. Indicá qué herramienta necesitás y para qué, de modo que puedan revisar su seguridad y compatibilidad.",
      source: "Política de Software Autorizado y Control de Aplicaciones NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-68",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Puedo conectar un pendrive o un equipo personal a la red del buque?",
      variants: [
        "conectar pendrive a la red",
        "conectar equipo personal a la red",
        "usar pendrive en el buque",
        "conectar celular usb pc",
        "conectar notebook personal red",
      ],
      answerTemplate: "Consultá previamente a Sistemas. No conectes dispositivos desconocidos o encontrados, ni los utilices en equipos operativos sin autorización.",
      source: "Norma de Uso de Dispositivos Extraíbles y Redes de Buques NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-69",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Qué hago si pierdo un celular o una computadora con acceso a información de la compañía?",
      variants: [
        "perdi celular de la compania",
        "perdi computadora de la empresa",
        "robo de celular o notebook",
        "extravio de dispositivo con correo",
        "dispositivo perdido con datos de la empresa",
      ],
      answerTemplate: "Avisá inmediatamente a Sistemas e indicá qué dispositivo perdiste y qué cuentas tenía configuradas. Esto permite evaluar el bloqueo de accesos, el cierre de sesiones y las medidas de protección disponibles.",
      source: "Protocolo de Pérdida o Robo de Dispositivos Móviles NCS",
      reviewStatus: 'verificado',
    ),
    CrewFAQItem(
      id: "FAQ-CIB-70",
      category: FAQCategory.ciberseguridadSoporte,
      mainQuestion: "¿Cómo informo una baja de usuario o un cambio de puesto o buque?",
      variants: [
        "informar baja de usuario",
        "cambio de puesto o buque usuario",
        "desvincular usuario sistemas",
        "dar de baja cuenta de acceso",
        "devolucion de equipos sistemas",
        "cambio de buque permisos",
      ],
      answerTemplate: "El responsable del área o Personal Embarcado debe comunicarlo a Sistemas, indicando la fecha y el cambio correspondiente. Así se pueden actualizar o retirar los permisos y gestionar la devolución de los equipos asignados.",
      source: "Procedimiento de Altas, Bajas y Modificaciones de Personal NCS",
      reviewStatus: 'verificado',
    ),
  ];

  /// Catálogo en memoria que se sincroniza dinámicamente con la Intranet (/api/v1/faqs/)
  /// Se inicializa con el catálogo oficial (70) para funcionamiento offline sin interrupciones.
  List<CrewFAQItem> _currentCatalog = List<CrewFAQItem>.from(catalog);

  /// Notificador reactivo para actualización automática de la interfaz
  final ValueNotifier<List<CrewFAQItem>> catalogNotifier =
      ValueNotifier<List<CrewFAQItem>>(List<CrewFAQItem>.from(catalog));

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;

  List<CrewFAQItem> get currentCatalog => _currentCatalog;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;

  /// Sincroniza dinámicamente las preguntas frecuentes desde el endpoint /api/v1/faqs/
  /// Si un usuario modifica una FAQ en la intranet o agrega una nueva, se refleja en vivo en la App.
  Future<List<CrewFAQItem>> fetchFaqsFromIntranet({bool forceRefresh = false}) async {
    // Si ya se sincronizó recientemente y no es forzado, reusar caché en memoria
    if (!forceRefresh &&
        _lastSyncTime != null &&
        DateTime.now().difference(_lastSyncTime!).inSeconds < 15) {
      return _currentCatalog;
    }

    _isSyncing = true;
    _lastSyncError = null;

    try {
      final response = await APIClient.shared.request(
        endpoint: '/api/v1/faqs/',
        method: 'GET',
      );

      if (response is List) {
        final List<CrewFAQItem> loaded = [];
        for (var raw in response) {
          if (raw is Map<String, dynamic>) {
            // Filtrar únicamente ítems activos
            final activo = raw['activo'] == null ||
                raw['activo'] == true ||
                raw['activo'] == 1 ||
                raw['activo'] == 'true';
            if (!activo) continue;

            final qText = (raw['pregunta'] ?? '').toString().trim();
            final rawId = raw['id']?.toString() ?? '';

            // Correlacionar con el catálogo estático para preservar sinónimos y metadatos
            CrewFAQItem? baseMatch;
            try {
              final qNorm = _normalize(qText);
              baseMatch = catalog.firstWhere((b) =>
                _normalize(b.mainQuestion) == qNorm ||
                b.id == "FAQ-CIB-$rawId" ||
                b.id == "FAQ-SEG-$rawId" ||
                b.id == "FAQ-APP-$rawId"
              );
            } catch (_) {}

            loaded.add(CrewFAQItem.fromIntranetJson(raw, baseMatch: baseMatch));
          }
        }

        if (loaded.isNotEmpty) {
          // Ordenar por el orden configurado en la Intranet
          loaded.sort((a, b) => a.orden.compareTo(b.orden));
          _currentCatalog = loaded;
          catalogNotifier.value = List.unmodifiable(_currentCatalog);
          _lastSyncTime = DateTime.now();
          debugPrint("CrewFAQService: Sincronizadas ${loaded.length} FAQs en vivo desde Intranet NCS.");
          return _currentCatalog;
        }
      }
    } catch (e) {
      _lastSyncError = e.toString();
      debugPrint("CrewFAQService: Aviso de sincronización remota: $e. Manteniendo catálogo activo.");
    } finally {
      _isSyncing = false;
    }

    return _currentCatalog;
  }

  /// Búsqueda inteligente por coincidencia textual y semántica
  FAQMatchResult findAnswer({
    required String query,
    CrewProfile? profile,
  }) {
    final cleanQuery = _normalize(query);
    if (cleanQuery.isEmpty) {
      return FAQMatchResult(
        message: "Por favor, escribe tu consulta para buscar entre las ${_currentCatalog.length} preguntas frecuentes oficiales.",
        isVerified: false,
      );
    }

    if (_isRestrictedQuery(cleanQuery)) {
      return const FAQMatchResult(
        message: "Por políticas estrictas de seguridad y privacidad del Sistema de Gestión Integrado, no puedo proporcionar información económica confidencial, salarios de terceros ni datos financieros.",
        isVerified: false,
      );
    }

    CrewFAQItem? bestItem;
    double maxScore = 0.0;
    final List<MapEntry<CrewFAQItem, double>> allScores = [];

    for (final item in _currentCatalog) {
      final score = _calculateRelevance(cleanQuery, item);
      allScores.add(MapEntry(item, score));
      if (score > maxScore) {
        maxScore = score;
        bestItem = item;
      }
    }

    allScores.sort((a, b) => b.value.compareTo(a.value));
    final related = allScores
        .where((e) => e.key.id != bestItem?.id && e.value > 0.15)
        .take(3)
        .map((e) => e.key)
        .toList();

    if (bestItem != null && maxScore >= 0.35) {
      final answer = bestItem.resolveAnswer(profile);
      return FAQMatchResult(
        item: bestItem,
        message: answer,
        relatedItems: related,
        isVerified: true,
        source: bestItem.source,
      );
    }

    final topSuggestions = allScores.take(3).map((e) => e.key).toList();
    return FAQMatchResult(
      message: "No encontré una respuesta exacta para tu consulta. Te sugiero revisar las siguientes preguntas frecuentes oficiales:",
      relatedItems: topSuggestions,
      isVerified: false,
    );
  }

  /// Alias de compatibilidad para el asistente
  FAQMatchResult answerQuery({
    required String query,
    CrewProfile? profile,
  }) {
    return findAnswer(query: query, profile: profile);
  }

  /// Preguntas sugeridas de acceso rápido para la pantalla de inicio y el asistente
  List<CrewFAQItem> get suggestedQuestions {
    final list = _currentCatalog;
    if (list.isEmpty) return const [];
    return [
      list.firstWhere((i) => i.id == "FAQ-SEG-01" || i.mainQuestion.contains("accidente"), orElse: () => list[0]),
      list.firstWhere((i) => i.id == "FAQ-EME-10" || i.mainQuestion.contains("alarma"), orElse: () => list[list.length > 9 ? 9 : 0]),
      list.firstWhere((i) => i.id == "FAQ-APP-46" || i.mainQuestion.contains("boletines"), orElse: () => list[list.length > 45 ? 45 : 0]),
      list.firstWhere((i) => i.id == "FAQ-APP-43" || i.mainQuestion.contains("embarcado"), orElse: () => list[list.length > 42 ? 42 : 0]),
      list.firstWhere((i) => i.id == "FAQ-CIB-54" || i.mainQuestion.contains("contraseña"), orElse: () => list[list.length > 53 ? 53 : 0]),
      list.firstWhere((i) => i.id == "FAQ-DOC-28" || i.mainQuestion.contains("documentación"), orElse: () => list[list.length > 27 ? 27 : 0]),
    ];
  }

  /// Retorna todas las preguntas coincidentes ordenadas por relevancia
  List<CrewFAQItem> search(String query) {
    final clean = _normalize(query);
    if (clean.isEmpty) return _currentCatalog;

    final scored = <MapEntry<CrewFAQItem, double>>[];
    for (final item in _currentCatalog) {
      final score = _calculateRelevance(clean, item);
      if (score > 0.05) {
        scored.add(MapEntry(item, score));
      }
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  CrewFAQItem? getById(String id) {
    try {
      return _currentCatalog.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CrewFAQItem> getByCategory(FAQCategory category) {
    return _currentCatalog.where((i) => i.category == category).toList();
  }

  static double _calculateRelevance(String cleanQuery, CrewFAQItem item) {
    final qNorm = _normalize(item.mainQuestion);
    if (cleanQuery == qNorm) return 1.0;
    if (qNorm.contains(cleanQuery) || cleanQuery.contains(qNorm)) return 0.95;

    for (final v in item.variants) {
      final vNorm = _normalize(v);
      if (cleanQuery == vNorm) return 0.90;
      if (vNorm.contains(cleanQuery) || cleanQuery.contains(vNorm)) return 0.85;
    }

    final queryTokens = _tokenize(cleanQuery);
    if (queryTokens.isEmpty) return 0.0;

    double maxVariantScore = 0.0;
    for (final v in [item.mainQuestion, ...item.variants]) {
      final vTokens = _tokenize(_normalize(v));
      if (vTokens.isEmpty) continue;

      int common = 0;
      for (final t in queryTokens) {
        if (vTokens.contains(t)) {
          common++;
        }
      }

      final score = (common / queryTokens.length) * 0.80;
      if (score > maxVariantScore) {
        maxVariantScore = score;
      }
    }

    return maxVariantScore;
  }

  static String _normalize(String text) {
    var s = text.toLowerCase();
    s = s.replaceAll(RegExp(r'[áàäâ]'), 'a');
    s = s.replaceAll(RegExp(r'[éèëê]'), 'e');
    s = s.replaceAll(RegExp(r'[íìïî]'), 'i');
    s = s.replaceAll(RegExp(r'[óòöô]'), 'o');
    s = s.replaceAll(RegExp(r'[úùüû]'), 'u');
    s = s.replaceAll(RegExp(r'[¿?¡!.,:;()\[\]"_/\-]'), ' ').replaceAll("'", ' ').replaceAll('"', ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static Set<String> _tokenize(String normalizedText) {
    const stopwords = {
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
      'de', 'del', 'a', 'al', 'en', 'para', 'por', 'con',
      'que', 'cual', 'cuales', 'como', 'donde', 'cuando', 'quien',
      'mi', 'mis', 'tu', 'tus', 'su', 'sus', 'me', 'se', 'es', 'son',
    };

    return normalizedText
        .split(' ')
        .where((word) => word.length > 2 && !stopwords.contains(word))
        .toSet();
  }

  static bool _isRestrictedQuery(String lower) {
    final restricted = [
      'sueldo de', 'salario de', 'cuanto gana', 'cuanto cobra',
      'precio de', 'cuanto costo', 'cuanto cuesta', 'factura', 'facturacion',
      'ganancia', 'balance financiero', 'cuenta bancaria', 'cbu',
      'dni de', 'telefono de', 'domicilio de', 'legajo de',
      'revelar password', 'clave de admin', 'contrasena de admin',
    ];

    for (final term in restricted) {
      if (lower.contains(term)) return true;
    }
    return false;
  }
}
