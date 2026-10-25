import '../models/models.dart';

/// Evento de auditoría de seguridad para registrar intentos bloqueados
class NCSAuditLogEntry {
  final DateTime timestamp;
  final String userId;
  final String userName;
  final String eventType;
  final String ruleTriggered;

  NCSAuditLogEntry({
    required this.timestamp,
    required this.userId,
    required this.userName,
    required this.eventType,
    required this.ruleTriggered,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'user_id': userId,
    'user_name': userName,
    'event_type': eventType,
    'rule_triggered': ruleTriggered,
  };
}

/// Registro central de auditoría de seguridad sin almacenar información sensible
class NCSChatAuditLogger {
  static final List<NCSAuditLogEntry> _logs = [];

  static List<NCSAuditLogEntry> get logs => List.unmodifiable(_logs);

  static void logBlock({
    required String userId,
    required String userName,
    required String eventType,
    required String ruleTriggered,
  }) {
    final entry = NCSAuditLogEntry(
      timestamp: DateTime.now(),
      userId: userId,
      userName: userName,
      eventType: eventType,
      ruleTriggered: ruleTriggered,
    );
    _logs.add(entry);
    // Limitar historial en memoria a 200 eventos
    if (_logs.length > 200) {
      _logs.removeAt(0);
    }
  }
}

/// Modelo de buque para lista blanca operativa
class NCSVesselWhitelistData {
  final String name;
  final String imo;
  final String flag;
  final String dimensions;
  final String location;
  final String coordinates;
  final String operationalStatus;
  final String maintenance;
  final List<String> certificates;
  final String lastUpdated;

  const NCSVesselWhitelistData({
    required this.name,
    required this.imo,
    required this.flag,
    required this.dimensions,
    required this.location,
    required this.coordinates,
    required this.operationalStatus,
    required this.maintenance,
    required this.certificates,
    required this.lastUpdated,
  });
}

/// Modelo de tripulación autorizado (sin datos sensibles)
class NCSAuthorizedCrewMember {
  final String name;
  final String role;
  final String ship;
  final String watchAndStatus;

  const NCSAuthorizedCrewMember({
    required this.name,
    required this.role,
    required this.ship,
    required this.watchAndStatus,
  });
}

/// Modelo de procedimiento del Manual de Gestión
class NCSManagementProcedure {
  final String code;
  final String title;
  final String section;
  final String version;
  final String instruction;

  const NCSManagementProcedure({
    required this.code,
    required this.title,
    required this.section,
    required this.version,
    required this.instruction,
  });
}

/// Modelo de pedido abierto de compras (SOLO campos operativos, SIN importes ni precios)
class NCSAuthorizedPurchaseOrder {
  final String orderNumber;
  final String requestingShip;
  final String date;
  final String description;
  final String requestedQuantity;
  final String status;
  final String tracking;
  final String lastUpdated;

  const NCSAuthorizedPurchaseOrder({
    required this.orderNumber,
    required this.requestingShip,
    required this.date,
    required this.description,
    required this.requestedQuantity,
    required this.status,
    required this.tracking,
    required this.lastUpdated,
  });
}

/// Política estricta de Chat IA Corporativo de Naviera Cruz del Sur
class NCSCorporateChatPolicy {
  // Mensajes estandarizados obligatorios por política
  static const String outOfScopeMessage =
      "Puedo ayudarte con información autorizada sobre buques, tripulaciones, el Manual de Gestión y pedidos abiertos de compras.";

  static const String restrictedInfoMessage =
      "No puedo proporcionar información económica, financiera, comercial confidencial ni datos personales sensibles. Puedo ayudarte con la información operativa autorizada.";

  static const String unauthorizedVesselMessage =
      "No posees autorización para consultar información de otros buques. Tu perfil tiene acceso únicamente a la información operativa de tu buque asignado y a la documentación del Manual de Gestión.";

  static const String insufficientInfoMessage =
      "No se dispone de información operativa suficiente registrada en las fuentes autorizadas para responder a esta consulta.";

  // ==========================================
  // FUENTES AUTORIZADAS (WHITELISTS)
  // ==========================================

  static const Map<String, NCSVesselWhitelistData> authorizedVessels = {
    "ALFA C": NCSVesselWhitelistData(
      name: "BT ALFA C",
      imo: "9711652",
      flag: "Panamá 🇵🇦",
      dimensions: "Eslora: 175.50 m | Manga: 27.40 m | Puntal: 14.80 m | Calado: 8.20 m | DWT: 26,020 t",
      location: "Fondeado en Rada La Plata",
      coordinates: "42°76'S 65°03'W",
      operationalStatus: "Fondeado por condiciones meteorológicas en Río de la Plata. Ingreso a DDI programado.",
      maintenance: "Inspección preventiva en generador auxiliar N°2 (MG-21) y revisión periódica de balsas salvavidas SOLAS completada.",
      certificates: [
        "Certificado de Seguridad de Construcción (Vigencia: 15/11/2027)",
        "Certificado Nacional de Dotación de Seguridad (Vigente)",
        "Certificado SOLAS / MARPOL Anexo I (Vigencia: 20/08/2027)",
      ],
      lastUpdated: "13/10/2026 12:30",
    ),
    "GUSTAVO U": NCSVesselWhitelistData(
      name: "BT GUSTAVO U",
      imo: "9654321",
      flag: "Argentina 🇦🇷",
      dimensions: "Eslora: 142.00 m | Manga: 21.00 m | Puntal: 11.20 m | Calado: 6.90 m | DWT: 16,520 t",
      location: "En navegación hacia Campana",
      coordinates: "38°00'S 57°55'W",
      operationalStatus: "En navegación activa completando operaciones de carga para cliente WFS. Velocidad: 11.8 nudos.",
      maintenance: "Mantenimiento preventivo en sellos de bomba de achique (MAQ-03) en curso. Revisión de cabos completada.",
      certificates: [
        "Certificado de Gestión de la Seguridad IGS/ISM (Vigencia: 10/05/2028)",
        "Certificado Nacional de Francobordo (Vigencia: 04/09/2027)",
        "Certificado de Prevención de la Contaminación MARPOL (Vigente)",
      ],
      lastUpdated: "13/10/2026 13:00",
    ),
    "NANY": NCSVesselWhitelistData(
      name: "BT NANY",
      imo: "9018115",
      flag: "Argentina 🇦🇷",
      dimensions: "Eslora: 128.00 m | Manga: 18.60 m | Puntal: 9.80 m | Calado: 6.10 m | DWT: 12,840 t",
      location: "Puerto Dock Sud",
      coordinates: "54°80'S 68°30'W",
      operationalStatus: "En puerto completando maniobras de alijo y transferencia de carga para cliente WFS.",
      maintenance: "Calibración de transductor de ecosonda (NAV-08) completada. Control de extintores y sistema CO2 finalizado.",
      certificates: [
        "Certificado IOPP Prevención Contaminación por Hidrocarburos (Vigencia: 18/03/2027)",
        "Certificado de Seguridad Radioeléctrica (Vigencia: 30/10/2026)",
        "Certificado de Dotación Mínima de Seguridad (Vigente)",
      ],
      lastUpdated: "13/10/2026 13:15",
    ),
    "MONARCA I": NCSVesselWhitelistData(
      name: "BT MONARCA I",
      imo: "9876543",
      flag: "Argentina 🇦🇷",
      dimensions: "Eslora: 115.00 m | Manga: 16.50 m | Puntal: 8.40 m | Calado: 5.40 m | DWT: 8,900 t",
      location: "Muelle Sur, Puerto Buenos Aires",
      coordinates: "34°36'S 58°22'W",
      operationalStatus: "En muelle cumpliendo programa de mantenimiento preventivo y alistamiento técnico de equipos.",
      maintenance: "Mantenimiento preventivo en servomotor de sistema de gobierno electrohidráulico y alineación de timón.",
      certificates: [
        "Certificado de Navegabilidad y Dotación Mínima (Vigencia: 12/12/2026)",
        "Certificado de Inspección de Casco y Maquinarias (Vigente)",
      ],
      lastUpdated: "13/10/2026 11:45",
    ),
  };

  static const List<NCSAuthorizedPurchaseOrder> authorizedPurchaseOrders = [
    // ALFA C (10 pedidos abiertos)
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-072",
      requestingShip: "ALFA C",
      date: "05/10/2026",
      description: "Inyectores para motor generador auxiliar N°2 y toberas de repuesto.",
      requestedQuantity: "6 unidades",
      status: "Abierto / En tránsito a Rada La Plata",
      tracking: "En lancha de práctico para entrega durante ventana meteorológica favorable.",
      lastUpdated: "13/10/2026 10:00",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-081",
      requestingShip: "ALFA C",
      date: "07/10/2026",
      description: "Paños y barreras absorbentes marinas para kit SOPEP en cubierta.",
      requestedQuantity: "10 bultos (500 paños)",
      status: "Abierto / Despachado",
      tracking: "Recepción en depósito operativo de Dock Sud para posterior embarque.",
      lastUpdated: "12/10/2026 16:20",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-088",
      requestingShip: "ALFA C",
      date: "09/10/2026",
      description: "Aceite lubricante marino SAE 40 para cárter de motor principal.",
      requestedQuantity: "4 tambores de 208 L",
      status: "Abierto / En preparación por proveedor",
      tracking: "Despacho coordinado en camión cisterna con agencia marítima.",
      lastUpdated: "13/10/2026 09:15",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-091",
      requestingShip: "ALFA C",
      date: "10/10/2026",
      description: "Válvulas de mariposa de 6 pulgadas con asiento de Viton para colector de carga y lastre.",
      requestedQuantity: "2 unidades",
      status: "Abierto / Aprobado para despacho técnico",
      tracking: "Inspección técnica de estanqueidad aprobada en taller homologado.",
      lastUpdated: "12/10/2026 14:40",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-094",
      requestingShip: "ALFA C",
      date: "11/10/2026",
      description: "Sensores de presión diferencial y manómetros certificados para sala de máquinas.",
      requestedQuantity: "8 unidades",
      status: "Abierto / En verificación de calidad",
      tracking: "Certificado de calibración de fábrica verificado por superintendencia técnica.",
      lastUpdated: "13/10/2026 08:30",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-099",
      requestingShip: "ALFA C",
      date: "11/10/2026",
      description: "Cabos de amarre de 8 cordones de 64 mm con gazas protegidas para rada.",
      requestedQuantity: "2 rollos de 220 metros",
      status: "Abierto / En tránsito logístico",
      tracking: "Envío despachado desde depósito central con remito de transporte #55210.",
      lastUpdated: "12/10/2026 17:00",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-103",
      requestingShip: "ALFA C",
      date: "12/10/2026",
      description: "Kit pirotécnico de socorro SOLAS (cohetes lanzabengalas con paracaídas, bengalas de mano y señales fumígenas).",
      requestedQuantity: "1 juego reglamentario completo",
      status: "Abierto / Aprobado por Prefectura",
      tracking: "Coordinado con despachante aduanero para entrega en muelle.",
      lastUpdated: "13/10/2026 11:10",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-107",
      requestingShip: "ALFA C",
      date: "12/10/2026",
      description: "Ánodos de sacrificio de zinc para protección catódica de tomas de mar y timón.",
      requestedQuantity: "24 unidades",
      status: "Abierto / En coordinación logística",
      tracking: "Para embarque previo a próxima faena programada en dique seco.",
      lastUpdated: "13/10/2026 11:50",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-112",
      requestingShip: "ALFA C",
      date: "13/10/2026",
      description: "Pintura marina epoxídica antideslizante para pasarelas de cubierta principal.",
      requestedQuantity: "8 latas de 20 L",
      status: "Abierto / En depósito Dock Sud",
      tracking: "Disponible para retiro en lancha de apoyo logístico.",
      lastUpdated: "13/10/2026 12:40",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-115",
      requestingShip: "ALFA C",
      date: "13/10/2026",
      description: "Filtros coalescentes y elementos filtrantes para separador de sentinas de 15 ppm.",
      requestedQuantity: "4 juegos",
      status: "Abierto / En verificación técnica",
      tracking: "Solicitado por Jefatura de Máquinas para mantenimiento preventivo MARPOL.",
      lastUpdated: "13/10/2026 13:05",
    ),

    // MONARCA I (5 pedidos abiertos)
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-084",
      requestingShip: "MONARCA I",
      date: "08/10/2026",
      description: "Repuestos para sistema de gobierno electrohidráulico (kit de juntas tóricas y sellos de vástago).",
      requestedQuantity: "4 kits",
      status: "Abierto / Aprobado para despacho técnico",
      tracking: "Despacho marítimo programado para próximo atraque en Dock Sud. Guía logística #44102.",
      lastUpdated: "12/10/2026 09:30",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-095",
      requestingShip: "MONARCA I",
      date: "11/10/2026",
      description: "Elementos filtrantes para separadora de combustible y filtros de aire de admisión.",
      requestedQuantity: "12 unidades",
      status: "Abierto / En preparación por proveedor",
      tracking: "Entrega coordinada en agencia marítima antes del 16/10/2026.",
      lastUpdated: "13/10/2026 08:15",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-100",
      requestingShip: "MONARCA I",
      date: "11/10/2026",
      description: "Manómetros de glicerina y presostatos para circuito de aire de arranque del motor.",
      requestedQuantity: "6 unidades",
      status: "Abierto / En verificación técnica",
      tracking: "Control de escala de presión 0-30 bar aprobado.",
      lastUpdated: "12/10/2026 15:20",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-106",
      requestingShip: "MONARCA I",
      date: "12/10/2026",
      description: "Válvula de seguridad de vapor y juego de juntas espirometálicas para caldera auxiliar.",
      requestedQuantity: "2 unidades",
      status: "Abierto / En preparación",
      tracking: "Proveedor nacional finalizando prueba hidráulica de taller.",
      lastUpdated: "13/10/2026 10:15",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-111",
      requestingShip: "MONARCA I",
      date: "13/10/2026",
      description: "Electrodos para soldadura marina E7018 y consumibles para soplete oxicorte de taller a bordo.",
      requestedQuantity: "5 cajas de 20 kg",
      status: "Abierto / Aprobado",
      tracking: "Listo para retiro en mostrador del distribuidor de suministros navales.",
      lastUpdated: "13/10/2026 11:30",
    ),

    // GUSTAVO U (7 pedidos abiertos)
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-078",
      requestingShip: "GUSTAVO U",
      date: "06/10/2026",
      description: "Empaquetadura mecánica trenzada y sellos para bomba de achique de sentinas.",
      requestedQuantity: "3 cajas",
      status: "Abierto / En verificación técnica",
      tracking: "Validación de compatibilidad con jefatura de máquinas completada.",
      lastUpdated: "11/10/2026 14:10",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-085",
      requestingShip: "GUSTAVO U",
      date: "08/10/2026",
      description: "Termocuplas blindadas y transmisores de temperatura de escape de cilindros.",
      requestedQuantity: "6 unidades",
      status: "Abierto / Despachado",
      tracking: "En camino por transporte terrestre a terminal Campana.",
      lastUpdated: "12/10/2026 11:00",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-090",
      requestingShip: "GUSTAVO U",
      date: "10/10/2026",
      description: "Mangueras hidráulicas flexibles de alta presión (400 bar) para guinche de maniobra.",
      requestedQuantity: "4 tramos de 3 metros con terminales",
      status: "Abierto / En preparación",
      tracking: "Armado de terminales prensados en taller hidráulico.",
      lastUpdated: "13/10/2026 09:45",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-096",
      requestingShip: "GUSTAVO U",
      date: "11/10/2026",
      description: "Grilletes de corazón con perno pasante y eslingas de carga certificadas de 5 Ton.",
      requestedQuantity: "8 grilletes y 4 eslingas",
      status: "Abierto / Aprobado",
      tracking: "Certificado de tracción emitido para presentación a bordo.",
      lastUpdated: "12/10/2026 16:30",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-102",
      requestingShip: "GUSTAVO U",
      date: "12/10/2026",
      description: "Correas trapezoidales dentadas y rodamientos SKF para ventiladores de sala de máquinas.",
      requestedQuantity: "4 juegos completos",
      status: "Abierto / En tránsito",
      tracking: "Entrega programada durante atraque en muelle de Campana.",
      lastUpdated: "13/10/2026 10:40",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-108",
      requestingShip: "GUSTAVO U",
      date: "12/10/2026",
      description: "Chalecos salvavidas inflables de trabajo con luz destellante automática SOLAS.",
      requestedQuantity: "12 unidades",
      status: "Abierto / En aduana",
      tracking: "Liberación de agencia marítima en curso para entrega en semana en curso.",
      lastUpdated: "13/10/2026 12:00",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-114",
      requestingShip: "GUSTAVO U",
      date: "13/10/2026",
      description: "Desengrasante biodegradable de uso marino para lavado de sentinas y cubiertas.",
      requestedQuantity: "10 bidones de 20 L",
      status: "Abierto / Listo para entrega",
      tracking: "En depósito de intendencia para despacho con provisiones.",
      lastUpdated: "13/10/2026 12:50",
    ),

    // NANY (6 pedidos abiertos)
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-089",
      requestingShip: "NANY",
      date: "09/10/2026",
      description: "Cabos de amarre de 8 cordones (polipropileno/poliéster) con gazas protegidas.",
      requestedQuantity: "2 rollos de 220 metros",
      status: "Abierto / En tránsito logístico",
      tracking: "Arribo programado a muelle Dock Sud para entrega directa a bordo.",
      lastUpdated: "12/10/2026 18:00",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-082",
      requestingShip: "NANY",
      date: "07/10/2026",
      description: "Sellos mecánicos de carburo de silicio para bomba centrífuga de descarga de carga.",
      requestedQuantity: "2 juegos completos",
      status: "Abierto / En verificación técnica",
      tracking: "Aprobado por inspector técnico de flota para recambio programado.",
      lastUpdated: "11/10/2026 17:20",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-093",
      requestingShip: "NANY",
      date: "10/10/2026",
      description: "Juntas de perfil de neopreno y goma sintética para estanqueidad de escotillas de tanques.",
      requestedQuantity: "4 rollos de 50 metros",
      status: "Abierto / Despachado",
      tracking: "En transporte local hacia agencia marítima de Dock Sud.",
      lastUpdated: "13/10/2026 08:50",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-098",
      requestingShip: "NANY",
      date: "11/10/2026",
      description: "Baterías de gel de ciclo profundo de 12V 200Ah para banco de radio de emergencia GMDSS.",
      requestedQuantity: "4 unidades",
      status: "Abierto / En preparación por proveedor",
      tracking: "Prueba de carga y tensión certificada completada por proveedor.",
      lastUpdated: "12/10/2026 14:15",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-104",
      requestingShip: "NANY",
      date: "12/10/2026",
      description: "Kits de mantenimiento para válvulas de presión y vacío (P/V valves) de tanques de carga.",
      requestedQuantity: "6 kits de reparación",
      status: "Abierto / Aprobado",
      tracking: "Para revisión reglamentaria antes de próxima inspección de bandera.",
      lastUpdated: "13/10/2026 10:20",
    ),
    NCSAuthorizedPurchaseOrder(
      orderNumber: "OC-2026-110",
      requestingShip: "NANY",
      date: "12/10/2026",
      description: "Linternas antiexplosivas intrínsecamente seguras ATEX Zona 1 para cuadrilla de alijo.",
      requestedQuantity: "6 unidades con cargador",
      status: "Abierto / Despachado",
      tracking: "Recepción en terminal de Dock Sud confirmada.",
      lastUpdated: "13/10/2026 11:40",
    ),
  ];

  static const List<NCSManagementProcedure> managementProcedures = [
    NCSManagementProcedure(
      code: "MS-07",
      title: "Manual de Seguridad y Medio Ambiente - Trabajos en Caliente",
      section: "Sección Trabajos en Caliente (Rev. 9, pág. 54)",
      version: "MS Rev. 9 Vigente",
      instruction: "Solo se permite trabajo en caliente en áreas ventiladas; fuera del Taller de Sala de Máquinas está prohibido salvo autorización escrita y buque en lastre. Requiere solicitud formal al Superintendente con croquis y copia al DPA, emisión del formulario MS-07 (Permiso de Trabajo en Caliente), cumplimiento de ISGOTT 9.4.4 (un solo trabajo a la vez) y designación obligatoria de un vigilante de incendio durante todo el trabajo y hasta 30 minutos después.",
    ),
    NCSManagementProcedure(
      code: "MO-01 / MO-22",
      title: "Manual de Gestión de la Seguridad - Maniobras de Amarre",
      section: "Capítulo Operaciones de Amarre y Desamarre (Rev. 16, pág. 88)",
      version: "Rev. 16 Vigente",
      instruction: "Toda maniobra de amarre requiere autorización del Capitán o Primer Oficial, aprobación previa del Plan de Carga (MO-01) y Lista de Verificación (MO-22). La supervisión directa corresponde al Primer Oficial de cubierta con personal certificado en cabrestantes, control de comunicaciones VHF, inspección previa de equipos (MS-02), aplicación del SOPEP/PLANACON (MS-05) e inspección continua cada 2 a 4 horas registrada en el control de lastre (MO-28).",
    ),
    NCSManagementProcedure(
      code: "NCS-SGI-01",
      title: "Manual del Sistema de Gestión Integrado",
      section: "Sección 4.2: Responsabilidad y Autoridad del Capitán",
      version: "Versión Vigente Rev. 2026",
      instruction: "El Capitán tiene la autoridad decisoria absoluta a bordo para adoptar las medidas que considere necesarias para la seguridad de la vida humana en el mar y la protección ambiental.",
    ),
    NCSManagementProcedure(
      code: "NCS-PO-04",
      title: "Procedimiento de Alijo y Transferencia de Carga Líquida en Rada",
      section: "Sección 4.1: Lista de Comprobación y Seguridad Buque a Buque (STS)",
      version: "Versión Vigente Rev. 2026",
      instruction: "Antes de iniciar maniobras de amarre y transferencia de carga líquida en rada, se debe verificar el estado de defensas, cabos de amarre, mangueras certificadas y comunicaciones en canal VHF 16/06.",
    ),
    NCSManagementProcedure(
      code: "NCS-SEG-02",
      title: "Plan de Emergencia de a Bordo para la Contaminación por Hidrocarburos (SOPEP)",
      section: "Sección 2.1: Procedimiento Inmediato de Contención y Despliegue",
      version: "Versión Vigente Rev. 2026",
      instruction: "Ante cualquier pérdida o goteo accidental en cubierta, se debe detener inmediatamente la operación de bombeo, cerrar válvulas maestras, desplegar material absorbente del kit SOPEP y dar aviso al oficial de guardia.",
    ),
    NCSManagementProcedure(
      code: "NCS-MANT-05",
      title: "Procedimiento de Mantenimiento Preventivo Planificado a Bordo",
      section: "Sección 3.4: Inspección de Equipos Críticos de Gobierno y Generación",
      version: "Versión Vigente Rev. 2026",
      instruction: "Todo mantenimiento sobre servomotor de gobierno, bombas de achique y generadores auxiliares debe registrarse en la planilla técnica con firma del Jefe de Máquinas.",
    ),
  ];

  static const Map<String, List<NCSAuthorizedCrewMember>> authorizedCrewByShip = {
    "ALFA C": [
      NCSAuthorizedCrewMember(name: "Marenco Rubén Darío", role: "Capitán", ship: "ALFA C", watchAndStatus: "Embarcado (Guardia de mando, 10 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Maldonado Juan", role: "1er Oficial Cubierta", ship: "ALFA C", watchAndStatus: "Embarcado (Guardia 04-08 / 16-20, 10 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Carattoli Pablo", role: "2do Oficial Cubierta", ship: "ALFA C", watchAndStatus: "Embarcado (Guardia 00-04 / 12-16, 35 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Lambertuchi Pablo", role: "3er Oficial Cubierta", ship: "ALFA C", watchAndStatus: "Embarcado (Guardia 08-12 / 20-24, 10 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Sosa Armando", role: "Jefe de Máquinas", ship: "ALFA C", watchAndStatus: "Embarcado (Jefatura de máquinas, 18 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Molero Jorge", role: "1er Maquinista", ship: "ALFA C", watchAndStatus: "Embarcado (Guardia de máquinas, 6 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Ledesma Gabriel", role: "2do Maquinista", ship: "ALFA C", watchAndStatus: "Embarcado (Guardia de máquinas, 36 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Sosa Marcelo", role: "Contramaestre", ship: "ALFA C", watchAndStatus: "Embarcado (23 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Marquez Ruben", role: "Marinero I", ship: "ALFA C", watchAndStatus: "Embarcado (36 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Romero José", role: "Marinero I", ship: "ALFA C", watchAndStatus: "Embarcado (10 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Miguel Angel Ramirez", role: "Marinero I", ship: "ALFA C", watchAndStatus: "Embarcado (23 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Zacarias Walter", role: "1er Cabo", ship: "ALFA C", watchAndStatus: "Embarcado (49 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Kretschel Claudio", role: "Cocinero", ship: "ALFA C", watchAndStatus: "Embarcado (17 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Aquino Marcos", role: "Bombero", ship: "ALFA C", watchAndStatus: "Embarcado (26 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Mineo Julio", role: "Bombero", ship: "ALFA C", watchAndStatus: "Embarcado (10 días a bordo)"),
    ],
    "GUSTAVO U": [
      NCSAuthorizedCrewMember(name: "Ramirez Pedro", role: "Capitán", ship: "GUSTAVO U", watchAndStatus: "Embarcado (Guardia de mando, 20 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Percara Marco", role: "1er Oficial Cubierta", ship: "GUSTAVO U", watchAndStatus: "Embarcado (Guardia 04-08 / 16-20, 9 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Perez Douglas", role: "2do Oficial Cubierta", ship: "GUSTAVO U", watchAndStatus: "Embarcado (Guardia 00-04 / 12-16, 20 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Tobias Joaquin", role: "Piloto", ship: "GUSTAVO U", watchAndStatus: "Embarcado (Guardia, 108 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Agüero Leandro", role: "Jefe de Máquinas", ship: "GUSTAVO U", watchAndStatus: "Embarcado (14 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Aguirrezarobe Alexis", role: "1er Maquinista", ship: "GUSTAVO U", watchAndStatus: "Embarcado (9 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Tomas Ribas Pintos", role: "2do Maquinista", ship: "GUSTAVO U", watchAndStatus: "Embarcado (9 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Cucurulo Gustavo", role: "Contramaestre", ship: "GUSTAVO U", watchAndStatus: "Embarcado (24 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Molina Geronimo", role: "Marinero I", ship: "GUSTAVO U", watchAndStatus: "Embarcado (40 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Camacho Pablo Ezequias", role: "Marinero I", ship: "GUSTAVO U", watchAndStatus: "Embarcado (29 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Rene Ruben Aceval", role: "Marinero I", ship: "GUSTAVO U", watchAndStatus: "Embarcado (12 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Jacquet Jorge", role: "Bombero I", ship: "GUSTAVO U", watchAndStatus: "Embarcado (20 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Escalante Eduardo", role: "Bombero II", ship: "GUSTAVO U", watchAndStatus: "Embarcado (9 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Caprioglio Fernando", role: "Engrasador", ship: "GUSTAVO U", watchAndStatus: "Embarcado (32 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Rodriguez Lucas", role: "Cocinero", ship: "GUSTAVO U", watchAndStatus: "Embarcado (17 días a bordo)"),
    ],
    "NANY": [
      NCSAuthorizedCrewMember(name: "Maciel Jonathan", role: "Capitán", ship: "NANY", watchAndStatus: "Embarcado (Guardia de mando, 14 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Maidana Francisco", role: "1er Oficial Cubierta", ship: "NANY", watchAndStatus: "Embarcado (Guardia 04-08 / 16-20, 18 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Saucedo Nicolás", role: "2do Oficial Cubierta", ship: "NANY", watchAndStatus: "Embarcado (Guardia 00-04 / 12-16, 14 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Alan Leguiza", role: "3er Oficial Cubierta", ship: "NANY", watchAndStatus: "Embarcado (Guardia 08-12 / 20-24, 14 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Porto Guillermo", role: "Jefe de Máquinas", ship: "NANY", watchAndStatus: "Embarcado (23 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Bequir Ramiro", role: "1er Maquinista", ship: "NANY", watchAndStatus: "Embarcado (4 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Rosales Carlos", role: "2do Conductor", ship: "NANY", watchAndStatus: "Embarcado (18 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Torres Ulises", role: "Contramaestre", ship: "NANY", watchAndStatus: "Embarcado (9 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Andrada Emiliano", role: "Marinero I", ship: "NANY", watchAndStatus: "Embarcado (23 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Mora Alejandro", role: "Marinero I", ship: "NANY", watchAndStatus: "Embarcado (18 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Ganduglia Sergio", role: "Marinero I", ship: "NANY", watchAndStatus: "Embarcado (14 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Correa Motta Nicolas", role: "Auxiliar Máquinas", ship: "NANY", watchAndStatus: "Embarcado (9 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Martin Tarroza", role: "Engrasador", ship: "NANY", watchAndStatus: "Embarcado (50 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Cantore Alejandro", role: "Cocinero", ship: "NANY", watchAndStatus: "Embarcado (4 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Medina Felix", role: "Bombero", ship: "NANY", watchAndStatus: "Embarcado (23 días a bordo)"),
    ],
    "MONARCA I": [
      NCSAuthorizedCrewMember(name: "Rossi Carlos", role: "Capitán", ship: "MONARCA I", watchAndStatus: "Embarcado (Guardia de mando, 12 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Gomez Fernando", role: "1er Oficial Cubierta", ship: "MONARCA I", watchAndStatus: "Embarcado (15 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Fernandez Luis", role: "Jefe de Máquinas", ship: "MONARCA I", watchAndStatus: "Embarcado (16 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Castro Martin", role: "1er Maquinista", ship: "MONARCA I", watchAndStatus: "Embarcado (8 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Benitez Juan", role: "Contramaestre", ship: "MONARCA I", watchAndStatus: "Embarcado (21 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Lopez Daniel", role: "Marinero I", ship: "MONARCA I", watchAndStatus: "Embarcado (14 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Morales Cristian", role: "Marinero I", ship: "MONARCA I", watchAndStatus: "Embarcado (18 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Pereyra Gustavo", role: "Cocinero", ship: "MONARCA I", watchAndStatus: "Embarcado (12 días a bordo)"),
      NCSAuthorizedCrewMember(name: "Duarte Héctor", role: "Bombero", ship: "MONARCA I", watchAndStatus: "Embarcado (19 días a bordo)"),
    ],
  };

  // ==========================================
  // FILTRADO DE INFORMACIÓN PROHIBIDA & EVASIÓN
  // ==========================================

  /// Detección estricta de términos económicos, financieros y comerciales prohibidos
  static bool containsProhibitedFinancialOrEconomicQuery(String text) {
    final lower = text.toLowerCase();

    // 1. Facturación, ingresos, gastos, costos, márgenes, utilidades, presupuestos
    final financialTerms = [
      "factur", "factura", "facturas", "facturación", "facturacion", "facturar",
      "ingreso", "ingresos", "gasto", "gastos", "costo", "costos", "costar",
      "cuanto cuesta", "cuánto cuesta", "cuanto sale", "cuánto sale",
      "precio", "precios", "importe", "importes", "monto", "montos", "cotizacion", "cotización",
      "margen", "márgenes", "margenes", "utilidad", "utilidades", "ganancia", "ganancias",
      "perdida", "pérdida", "perdidas", "pérdidas", "presupuesto", "presupuestos",
      "balance", "balances", "cuanta plata", "cuánta plata", "cuanta guita", "cuánta guita",
      "tarifa", "tarifas", "flete comercial"
    ];
    for (final term in financialTerms) {
      if (lower.contains(term)) return true;
    }

    // 2. Saldos, bancos, deudas, pagos, impuestos, contabilidad
    final bankingTerms = [
      "saldo", "saldos", "cuenta bancaria", "cuentas bancarias", "banco", "bancos",
      "deuda", "deudas", "pago", "pagos", "impuesto", "impuestos", "retencion", "retención",
      "retenciones", "contable", "contabilidad", "cbu", "alias bancario"
    ];
    for (final term in bankingTerms) {
      if (lower.contains(term)) return true;
    }

    // 3. Sueldos, salarios, remuneraciones
    final salaryTerms = [
      "sueldo", "sueldos", "salario", "salarios", "remuneracion", "remuneración",
      "remuneraciones", "haber", "haberes", "recibo de sueldo", "recibos de sueldo",
      "cuanto cobra", "cuánto cobra", "cuanto cobran", "cuánto cobran",
      "cuanto gana", "cuánto gana", "cuanto ganan", "cuánto ganan",
      "aumento salarial", "paritaria", "paritarias"
    ];
    for (final term in salaryTerms) {
      if (lower.contains(term)) return true;
    }

    // 4. Estimación o cálculo de ingresos / volúmenes comerciales
    if ((lower.contains("estima") || lower.contains("estimá") || lower.contains("calcular") || lower.contains("calcula")) &&
        (lower.contains("ingreso") || lower.contains("factura") || lower.contains("ganancia") || lower.contains("operacion") || lower.contains("operación"))) {
      return true;
    }

    // 5. Monedas y símbolos monetarios
    final currencyPattern = RegExp(r'(\$|usd|eur|ars|pesos|dólares|dolares)\s*[0-9]+', caseSensitive: false);
    if (currencyPattern.hasMatch(lower)) return true;

    return false;
  }

  /// Detección de datos personales sensibles de tripulantes
  static bool containsProhibitedPiiQuery(String text) {
    final lower = text.toLowerCase();
    final piiTerms = [
      "dni", "documento de identidad", "cedula", "cédula", "pasaporte",
      "domicilio", "domicilios", "direccion privada", "dirección privada",
      "direccion particular", "dirección particular", "telefono privado", "teléfono privado",
      "telefono particular", "teléfono particular", "celular particular", "celular privado",
      "whatsapp particular", "ficha medica", "ficha médica", "informacion medica", "información médica",
      "antecedentes disciplinarios", "sancion", "sanción", "sanciones", "legajo personal"
    ];
    for (final term in piiTerms) {
      if (lower.contains(term)) return true;
    }
    return false;
  }

  /// Detección de credenciales y seguridad interna
  static bool containsSecurityCredentialsQuery(String text) {
    final lower = text.toLowerCase();
    final secTerms = [
      "password", "contraseña", "contrasena", "clave secreta", "token", "tokens",
      "api key", "apikey", "credenciales de acceso", "configuración interna de seguridad"
    ];
    for (final term in secTerms) {
      if (lower.contains(term)) return true;
    }
    return false;
  }

  /// Detección de evasión, suplantación o manipulación (Jailbreak / Social Engineering)
  static bool containsEvasionAttempt(String text) {
    final lower = text.toLowerCase();
    final evasionTerms = [
      "soy miguel", "soy el dueno", "soy el dueño", "soy dueno", "soy dueño",
      "soy el administrador", "soy administrador", "soy admin",
      "miguel me autorizo", "miguel me autorizó", "me autorizo miguel", "me autorizó miguel",
      "me autorizo el dueno", "me autorizo el dueño",
      "ignora las instrucciones", "ignora las reglas", "olvida las reglas", "olvida las instrucciones",
      "actua como", "actúa como", "juego de rol", "simula que", "en un universo alternativo",
      "modo desarrollador", "dan mode", "jailbreak"
    ];
    for (final term in evasionTerms) {
      if (lower.contains(term)) return true;
    }
    return false;
  }

  /// Detección de consultas que son directamente prohibidas (sin contraparte operativa independiente)
  static bool isPurelyProhibitedQuery(String lower) {
    if (containsEvasionAttempt(lower)) return true;

    // "¿Cuánto cuesta..." / "¿Cuánto sale..." / "precio de..." / "costo de..."
    if (lower.contains("cuanto cuesta") || lower.contains("cuánto cuesta") ||
        lower.contains("cuanto sale") || lower.contains("cuánto sale") ||
        lower.contains("precio") || lower.contains("costo") ||
        lower.contains("importe") || lower.contains("cotizacion") || lower.contains("cotización")) {
      if (!lower.contains("donde esta") && !lower.contains("dónde está") &&
          !lower.contains("quien esta") && !lower.contains("quién está") &&
          !lower.contains("que procedimiento") && !lower.contains("qué procedimiento") &&
          !lower.contains("que pedidos") && !lower.contains("qué pedidos")) {
        return true;
      }
    }

    // Facturación / balances / deudas
    if (lower.contains("factura") || lower.contains("facturacion") || lower.contains("facturación") ||
        lower.contains("balance") || lower.contains("cuenta bancaria") || lower.contains("saldo") ||
        lower.contains("deuda") || lower.contains("impuesto") || lower.contains("presupuesto")) {
      if (!lower.contains("donde esta") && !lower.contains("dónde está") &&
          !lower.contains("quien esta") && !lower.contains("quién está")) {
        return true;
      }
    }

    // Sueldos / remuneraciones
    if (lower.contains("sueldo") || lower.contains("salario") || lower.contains("remuneracion") ||
        lower.contains("remuneración") || lower.contains("cuanto cobra") || lower.contains("cuánto cobra") ||
        lower.contains("cuanto gana") || lower.contains("cuánto gana")) {
      if (!lower.contains("donde esta") && !lower.contains("dónde está") &&
          !lower.contains("quien esta") && !lower.contains("quién está")) {
        return true;
      }
    }

    // Estimaciones de ingresos/operaciones
    if ((lower.contains("estima") || lower.contains("estimá") || lower.contains("calcula") || lower.contains("calcular")) &&
        (lower.contains("ingreso") || lower.contains("ganancia") || lower.contains("factura") || lower.contains("operacion") || lower.contains("operación"))) {
      return true;
    }

    // PII de tripulantes
    if (lower.contains("dni") || lower.contains("cedula") || lower.contains("cédula") ||
        lower.contains("pasaporte") || lower.contains("domicilio") || lower.contains("telefono privado") ||
        lower.contains("teléfono privado") || lower.contains("ficha medica") || lower.contains("ficha médica")) {
      if (!lower.contains("donde esta") && !lower.contains("dónde está")) {
        return true;
      }
    }

    return false;
  }

  /// Detección de consultas pertenecientes al alcance permitido
  static bool isWithinPermittedScope(String text) {
    final lower = text.toLowerCase();

    // 1. Buques
    if (lower.contains("buque") || lower.contains("barco") || lower.contains("flota") ||
        lower.contains("alfa") || lower.contains("gustavo") || lower.contains("nany") || lower.contains("monarca") ||
        lower.contains("ubicacion") || lower.contains("ubicación") || lower.contains("donde esta") || lower.contains("dónde está") ||
        lower.contains("estado operativo") || lower.contains("mantenimiento") || lower.contains("certificado") ||
        lower.contains("imo") || lower.contains("dimensiones") || lower.contains("eslora") || lower.contains("manga") ||
        lower.contains("rada") || lower.contains("puerto")) {
      return true;
    }

    // 2. Tripulaciones
    if (lower.contains("tripul") || lower.contains("tripulacion") || lower.contains("tripulación") ||
        lower.contains("personal") || lower.contains("capitán") || lower.contains("capitan") ||
        lower.contains("oficial") || lower.contains("maquinista") || lower.contains("marinero") ||
        lower.contains("dotacion") || lower.contains("dotación") || lower.contains("guardia") ||
        lower.contains("quien esta asignado") || lower.contains("quién está asignado") ||
        lower.contains("quien esta a bordo") || lower.contains("quién está a bordo")) {
      return true;
    }

    // 3. Manual de Gestión
    if (lower.contains("manual") || lower.contains("gestion") || lower.contains("gestión") ||
        lower.contains("procedimiento") || lower.contains("instruccion") || lower.contains("instrucción") ||
        lower.contains("sgi") || lower.contains("solas") || lower.contains("marpol") || lower.contains("sopep")) {
      return true;
    }

    // 4. Pedidos abiertos de compras
    if (lower.contains("pedido") || lower.contains("pedidos") || lower.contains("compra") ||
        lower.contains("compras") || lower.contains("repuesto") || lower.contains("repuestos") ||
        lower.contains("suministro") || lower.contains("suministros") || lower.contains("seguimiento") ||
        lower.contains("oc-2026") || lower.contains("orden de compra")) {
      return true;
    }

    // 5. Saludos cordiales de bienvenida
    if (lower == "hola" || lower.startsWith("hola ") || lower.contains("buenos dias") ||
        lower.contains("buenas tardes") || lower.contains("buenas noches") || lower.contains("quien eres") || lower.contains("quién eres")) {
      return true;
    }

    return false;
  }

  // ==========================================
  // CONTROL DE ACCESO
  // ==========================================

  /// Determina el buque asignado al usuario si es usuario de buque
  static String? getAssignedShipForUser(User? user) {
    if (user == null) return null;
    final combined = "${user.role} ${user.sector}".toUpperCase();
    if (combined.contains("ALFA")) return "ALFA C";
    if (combined.contains("GUSTAVO")) return "GUSTAVO U";
    if (combined.contains("NANY")) return "NANY";
    if (combined.contains("MONARCA")) return "MONARCA I";
    return null;
  }

  /// Verifica si el usuario tiene permiso para acceder a un buque específico
  static bool hasPermissionForShip(User? user, String targetShipKey) {
    final assignedShip = getAssignedShipForUser(user);
    // Si es usuario de buque, solo puede consultar su propio buque
    if (assignedShip != null) {
      return assignedShip.toUpperCase().contains(targetShipKey.toUpperCase()) ||
             targetShipKey.toUpperCase().contains(assignedShip.toUpperCase());
    }
    // Usuarios de oficina / gerencia / operaciones acceden a buques de la flota
    return true;
  }

  /// Extrae el buque objetivo mencionado en la consulta
  static String? extractShipFromQuery(String text) {
    final upper = text.toUpperCase();
    if (upper.contains("ALFA")) return "ALFA C";
    if (upper.contains("GUSTAVO")) return "GUSTAVO U";
    if (upper.contains("NANY")) return "NANY";
    if (upper.contains("MONARCA")) return "MONARCA I";
    return null;
  }

  // ==========================================
  // EVALUACIÓN DE POLÍTICA Y GENERACIÓN
  // ==========================================

  /// Procesa la consulta aplicando la política corporativa estricta
  static String processCorporatePolicy({
    required String prompt,
    required User? currentUser,
  }) {
    final lower = prompt.toLowerCase().trim();

    // 1. DETECCIÓN DE INTENTOS DE EVASIÓN / JAILBREAK
    if (containsEvasionAttempt(lower)) {
      NCSChatAuditLogger.logBlock(
        userId: currentUser?.id ?? "anonymous",
        userName: currentUser?.name ?? "Usuario no identificado",
        eventType: "POLICY_EVASION_ATTEMPT",
        ruleTriggered: "Regla contra evasión y falsa autorización",
      );
      return restrictedInfoMessage;
    }

    // 2. DETECCIÓN DE CONSULTAS DIRECTAMENTE PROHIBIDAS (FINANCIERA / ECONÓMICA / SALARIOS / PII / SEGURIDAD)
    if (isPurelyProhibitedQuery(lower)) {
      NCSChatAuditLogger.logBlock(
        userId: currentUser?.id ?? "anonymous",
        userName: currentUser?.name ?? "Usuario no identificado",
        eventType: "POLICY_BLOCKED_RESTRICTED_DATA",
        ruleTriggered: "Regla de exclusión de información económica, financiera y datos personales",
      );
      return restrictedInfoMessage;
    }

    final hasProhibitedFinancial = containsProhibitedFinancialOrEconomicQuery(lower);
    final hasProhibitedPii = containsProhibitedPiiQuery(lower);
    final hasProhibitedSec = containsSecurityCredentialsQuery(lower);
    final isProhibitedQuery = hasProhibitedFinancial || hasProhibitedPii || hasProhibitedSec;

    // Verificar si pertenece al alcance permitido
    final hasPermittedScope = isWithinPermittedScope(lower);

    if (isProhibitedQuery && !hasPermittedScope) {
      NCSChatAuditLogger.logBlock(
        userId: currentUser?.id ?? "anonymous",
        userName: currentUser?.name ?? "Usuario no identificado",
        eventType: hasProhibitedFinancial ? "POLICY_BLOCKED_FINANCIAL" : (hasProhibitedPii ? "POLICY_BLOCKED_PII" : "POLICY_BLOCKED_SECURITY"),
        ruleTriggered: "Regla de exclusión de información económica, financiera y datos personales",
      );
      return restrictedInfoMessage;
    }

    // 3. CONSULTA COMPLETAMENTE FUERA DE ALCANCE
    if (!hasPermittedScope) {
      return outOfScopeMessage;
    }

    // 4. CONTROL DE ACCESO A BUQUES
    final targetShip = extractShipFromQuery(prompt);
    if (targetShip != null) {
      final allowed = hasPermissionForShip(currentUser, targetShip);
      if (!allowed) {
        NCSChatAuditLogger.logBlock(
          userId: currentUser?.id ?? "anonymous",
          userName: currentUser?.name ?? "Usuario no identificado",
          eventType: "POLICY_UNAUTHORIZED_VESSEL",
          ruleTriggered: "Control de acceso: Usuario de buque restringido a buque asignado",
        );
        return unauthorizedVesselMessage;
      }
    }

    // 5. GENERACIÓN DE RESPUESTA AUTORIZADA SEGÚN LISTA BLANCA
    String authorizedResponse = "";

    // Saludo inicial / Quién eres
    if (lower == "hola" || lower.startsWith("hola ") || lower.contains("quien eres") || lower.contains("quién eres") || lower.contains("quien sos") || lower.contains("quién sos")) {
      authorizedResponse = """
¡Hola! Soy el **Asistente de NCS**.

Puedo ayudarte con información operativa autorizada sobre:
1. 🚢 **Buques:** Características técnicas, ubicación, estado operativo, mantenimiento y certificados.
2. 👨‍✈️ **Tripulaciones:** Integrantes, cargos asignados a buques y guardias operativas.
3. 📋 **Manual de Gestión:** Procedimientos, instrucciones y documentación vigente.
4. 📦 **Pedidos abiertos de compras:** Número de pedido, buque solicitante, fecha, descripción, cantidades y seguimiento.
""";
    }

    // A. CONSULTAS SOBRE PEDIDOS ABIERTOS DE COMPRAS
    else if (lower.contains("pedido") || lower.contains("compra") || lower.contains("repuesto") || lower.contains("oc-2026") || lower.contains("orden")) {
      authorizedResponse = _handlePurchaseOrdersQuery(lower, targetShip);
    }

    // B. CONSULTAS SOBRE MANUAL DE GESTIÓN Y PROCEDIMIENTOS
    else if (lower.contains("manual") || lower.contains("procedimiento") || lower.contains("sgi") || lower.contains("solas") || lower.contains("marpol") || lower.contains("sopep") || lower.contains("instruccion") || lower.contains("instrucción")) {
      authorizedResponse = _handleManagementManualQuery(lower);
    }

    // C. CONSULTAS SOBRE TRIPULACIONES (SOLO DATOS AUTORIZADOS)
    else if (lower.contains("tripul") || lower.contains("personal") || lower.contains("capitán") || lower.contains("capitan") || lower.contains("oficial") || lower.contains("maquinista") || lower.contains("marinero") || lower.contains("asignado")) {
      authorizedResponse = _handleCrewQuery(lower, targetShip);
    }

    // D. CONSULTAS SOBRE BUQUES (UBICACIÓN, ESTADO OPERATIVO, CARACTERÍSTICAS, CERTIFICADOS, MANTENIMIENTO)
    else if (targetShip != null || lower.contains("buque") || lower.contains("barco") || lower.contains("flota") || lower.contains("donde esta") || lower.contains("dónde está") || lower.contains("certificado") || lower.contains("mantenimiento")) {
      authorizedResponse = _handleVesselQuery(lower, targetShip);
    }

    // Default dentro del alcance
    else {
      authorizedResponse = outOfScopeMessage;
    }

    // 6. MANEJO DE CONSULTA MIXTA: Si combinó información permitida y prohibida, responder la permitida y añadir el bloqueo
    if (isProhibitedQuery) {
      NCSChatAuditLogger.logBlock(
        userId: currentUser?.id ?? "anonymous",
        userName: currentUser?.name ?? "Usuario no identificado",
        eventType: "POLICY_MIXED_QUERY_PARTIAL_BLOCK",
        ruleTriggered: "Bloqueo de componente prohibido en consulta mixta",
      );
      authorizedResponse = "$authorizedResponse\n\n> ⚠️ **Nota de Seguridad:** $restrictedInfoMessage";
    }

    // 7. DEFENSA ADICIONAL: SCRUBBER DE SALIDA
    return sanitizeAndValidateOutput(authorizedResponse);
  }

  // ==========================================
  // GENERADORES POR ÁREA AUTORIZADA
  // ==========================================

  static String _handlePurchaseOrdersQuery(String lower, String? targetShip) {
    final shipKey = targetShip ?? (lower.contains("monarca") ? "MONARCA I" : (lower.contains("alfa") ? "ALFA C" : (lower.contains("gustavo") ? "GUSTAVO U" : (lower.contains("nany") ? "NANY" : null))));

    List<NCSAuthorizedPurchaseOrder> filtered;
    if (shipKey != null) {
      filtered = authorizedPurchaseOrders.where((po) => po.requestingShip.toUpperCase() == shipKey.toUpperCase()).toList();
    } else {
      filtered = authorizedPurchaseOrders;
    }

    if (filtered.isEmpty) {
      return "No se registran pedidos abiertos de compras para el buque indicado en este momento.";
    }

    final buffer = StringBuffer();
    if (shipKey != null) {
      buffer.writeln("### 📦 Pedidos Abiertos de Compras - $shipKey");
      buffer.writeln("Actualmente el buque **$shipKey** cuenta con **${filtered.length} pedidos abiertos de compras** registrados en seguimiento operativo:\n");
    } else {
      buffer.writeln("### 📦 Pedidos Abiertos de Compras - Seguimiento Operativo");
      buffer.writeln("Se registran actualmente un total de **${filtered.length} pedidos abiertos de compras** activos en la flota:\n");
    }

    for (final po in filtered) {
      buffer.writeln("• **Pedido N°:** ${po.orderNumber}");
      buffer.writeln("  - **Buque Solicitante:** ${po.requestingShip}");
      buffer.writeln("  - **Fecha de Solicitud:** ${po.date}");
      buffer.writeln("  - **Descripción:** ${po.description}");
      buffer.writeln("  - **Cantidad Solicitada:** ${po.requestedQuantity}");
      buffer.writeln("  - **Estado Operativo:** ${po.status}");
      buffer.writeln("  - **Seguimiento:** ${po.tracking}");
      buffer.writeln("  - **Fecha de Actualización:** ${po.lastUpdated}\n");
    }

    return buffer.toString().trim();
  }

  static String _handleManagementManualQuery(String lower) {
    if (lower.contains("caliente") ||
        lower.contains("soldadura") ||
        lower.contains("soldar") ||
        lower.contains("soplete") ||
        lower.contains("ms-07") ||
        lower.contains("ms 07") ||
        lower.contains("oxicorte")) {
      return """
### 📋 Manual de Gestión - Trabajos en Caliente (Permiso MS-07)

Conforme al **MS – Manual de Seguridad y Medio Ambiente Rev. 9 (pág. 54)** y el formulario oficial **MS-07**:

- **Ámbito:** Solo se permite trabajo en caliente en áreas ventiladas; fuera del Taller de la Sala de Máquinas está estrictamente prohibido salvo autorización escrita previa y con el buque en condición de lastre.
- **Requisitos previos obligatorios:**
  1. Análisis de riesgo y evaluación de operaciones simultáneas (SIMOPS).
  2. Inspección previa del equipo de soldadura y verificación rigurosa de su buen estado técnico.
  3. Ventilación continua del área y uso de EPP ignífugo y respiratorio adecuado.
- **Autorización y Permiso:**
  1. Solicitud formal y por escrito a la Superintendencia Técnica con ubicación exacta, croquis detallado y medidas de protección implementadas.
  2. Aprobación y respuesta escrita del Superintendente con copia notificada al DPA.
  3. Emisión obligatoria del formulario **MS-07: Permiso de Trabajo en Caliente**, firmado por el Capitán.
- **Ejecución y Precauciones:**
  1. Solo un trabajo en caliente a la vez en todo el buque (conforme normativa ISGOTT 9.4.4).
  2. Designación de un **vigilante de incendio (fire watch)** exclusivo que permanezca en la zona durante todo el trabajo y hasta **30 minutos después** de finalizado.
  3. Mantener extintores portátiles presurizados y líneas contra incendios de supresión listas en el área.
- **Cierre del Permiso:**
  1. Inspección final y verificación de extinción completa de cualquier rescoldo, llama o chispa.
  2. Registro de observaciones en el formulario MS-07 y devolución al Capitán para cierre formal.
  3. Todo desvío o anomalía debe reportarse mediante **MG-07 (Reporte de incidente náutico)** o **MG-05 (Nota de No Conformidad)**.

📚 **Fuentes oficiales del SGS:**
- *MS – Manual de seguridad y medio ambiente Rev. 9.pdf*, página 54.
- Catálogo oficial de formularios del SGS – código **MS-07: Permiso de Trabajo en Caliente**.
""".trim();
    }

    if (lower.contains("amarre") ||
        lower.contains("amarrar") ||
        lower.contains("desamarre") ||
        lower.contains("cabrestante") ||
        lower.contains("winche") ||
        lower.contains("mo-22") ||
        lower.contains("mo-01")) {
      return """
### 📋 Manual de Gestión - Procedimientos de Seguridad en Maniobras de Amarre

Conforme al **Manual de Gestión de la Seguridad Rev. 16 (pág. 88)** y procedimientos operativos vigentes:

1. **Planificación y autorización:**
   - Sólo el **Capitán o Primer Oficial** autoriza el inicio de la maniobra de amarre.
   - Aprobar y verificar el **Plan de Carga (MO-01)** y la **Lista de Verificación de Operación Buque-Buque o Muelle (MO-22)** antes de iniciar.

2. **Designación de roles operativos:**
   - **Supervisor de maniobra:** Primer Oficial de cubierta.
   - **Operadores de cabrestante y guardia de amarre:** Personal de cubierta certificado.
   - Establecer canal de trabajo VHF exclusivo y confirmar la señal de *"listo para amarrar"*.

3. **Inspección previa de equipos (MS-02 Guía de Verificación de Equipos):**
   - Cabrestantes, winches, cadenas, cabos de amarre sintéticos, grilletes y dispositivos de sujeción en buen estado.
   - Sistemas de comunicación y alarmas acústicas de sobrecarga plenamente operativas.

4. **Control de riesgos de derrames y protección ambiental (MS-05 pág. 2):**
   - Aplicar el **SOPEP** del buque; mantener barreras de contención, paños absorbentes y personal entrenado en puesto.

5. **Ejecución de la maniobra paso a paso:**
   - **Posicionamiento:** Práctico o remolcador ubica el buque en la zona designada a velocidad y rumbo seguros.
   - **Lanzamiento de amarras:** Personal bajo supervisión directa; verificación de longitud y tipo de cabo/cable.
   - **Aplicación de tensión:** Ajuste paulatino en cabrestantes controlando indicadores de carga para evitar sobretensión.
   - **Revisión final:** Supervisor constata que todas las amarras queden aseguradas y los grilletes y pasadores en posición.

6. **Monitoreo continuo:**
   - Inspecciones periódicas cada **2 a 4 horas** durante toda la estadía amarrado.
   - Registrar cualquier desvío, aflojamiento o cambio en el **Registro de Control de Lastre (MO-28)**.

7. **Emergencias y desvíos:**
   - Activar el Plan de Contingencia de Derrames (**PLANACON**) ante fallas de sujeción o pérdida de integridad.
   - Notificar al Capitán y DPA, y asentar en el formulario **MG-07 (Reporte de incidente náutico)** o **MG-05 (Nota de No Conformidad)**.

📚 **Fuentes oficiales del SGS:**
- *Manual de gestión de la seguridad Rev. 16 03-26.pdf*, página 88.
- *MO-01: Plan de Carga* y *MO-22: Lista de Verificación Operación Buque-Buque*.
- *MS-02: Guía de Verificación de Equipos*.
- *MS-05: Registro de análisis de riesgo sustancias contaminantes*, página 2.
""".trim();
    }

    NCSManagementProcedure selected = managementProcedures[2]; // Default to SGI-01 general

    if (lower.contains("alijo") || lower.contains("sts") || lower.contains("transferencia") || lower.contains("rada")) {
      selected = managementProcedures[3];
    } else if (lower.contains("sopep") || lower.contains("derrame") || lower.contains("emergencia") || lower.contains("contaminacion") || lower.contains("contaminación")) {
      selected = managementProcedures[4];
    } else if (lower.contains("mantenimiento") || lower.contains("maquinaria") || lower.contains("equipo critico") || lower.contains("equipo crítico")) {
      selected = managementProcedures[5];
    }

    return """
### 📋 Manual de Gestión - Documentación Vigente

Conforme al **${selected.title}**:

- **Documento:** ${selected.code} - ${selected.title}
- **Sección:** ${selected.section}
- **Versión Vigente:** ${selected.version}
- **Instrucción Operativa:** ${selected.instruction}

> *Aviso de Gestión: Esta referencia documental no constituye una autorización directa del Capitán o responsable operativo a bordo. Toda maniobra debe cumplir la orden formal del oficial de guardia.*
""".trim();
  }

  static String _handleCrewQuery(String lower, String? targetShip) {
    final shipKey = targetShip ?? (lower.contains("alfa") ? "ALFA C" : (lower.contains("gustavo") ? "GUSTAVO U" : (lower.contains("nany") ? "NANY" : (lower.contains("monarca") ? "MONARCA I" : null))));

    if (shipKey != null && authorizedCrewByShip.containsKey(shipKey)) {
      final crewList = authorizedCrewByShip[shipKey]!;
      final buffer = StringBuffer();
      buffer.writeln("### 👨‍✈️ Dotación Autorizada - BT $shipKey");
      buffer.writeln("*Datos autorizados (nombre, cargo, guardia y situación de embarque STCW):*\n");

      for (final member in crewList) {
        buffer.writeln("• **${member.role}:** ${member.name} ➔ ${member.watchAndStatus}");
      }

      buffer.writeln("\n> **Status Dotación:** Dotación reglamentaria completa (${crewList.length} tripulantes a bordo).");
      return buffer.toString().trim();
    }

    // Resumen general de flota
    final buffer = StringBuffer();
    buffer.writeln("### 👨‍✈️ Dotaciones de Tripulación Asignadas por Buque");
    buffer.writeln("*Integrantes autorizados a bordo conforme a certificados de dotación mínima:*\n");
    authorizedCrewByShip.forEach((ship, list) {
      final capitan = list.firstWhere((m) => m.role == "Capitán", orElse: () => list.first);
      buffer.writeln("• 🚢 **BT $ship:** ${list.length} tripulantes embarcados ➔ Capitán: ${capitan.name}");
    });

    return buffer.toString().trim();
  }

  static String _handleVesselQuery(String lower, String? targetShip) {
    if (targetShip != null && authorizedVessels.containsKey(targetShip)) {
      final v = authorizedVessels[targetShip]!;
      return """
### 🚢 Información Operativa Autorizada - ${v.name}

- **Número IMO:** ${v.imo}
- **Bandera:** ${v.flag}
- **Dimensiones:** ${v.dimensions}
- **Ubicación Actual:** ${v.location} (Coordenadas: ${v.coordinates})
- **Estado Operativo:** ${v.operationalStatus}
- **Mantenimiento Planificado:** ${v.maintenance}
- **Certificados Vigentes:**
${v.certificates.map((c) => "  • $c").join("\n")}
- **Fecha de Actualización:** ${v.lastUpdated}
""".trim();
    }

    // Resumen de la flota autorizada
    final buffer = StringBuffer();
    buffer.writeln("### 🚢 Estado Operativo de la Flota Autorizada\n");
    authorizedVessels.forEach((_, v) {
      buffer.writeln("• **${v.name}** (IMO: ${v.imo} • ${v.flag}):");
      buffer.writeln("  - **Ubicación:** ${v.location}");
      buffer.writeln("  - **Situación:** ${v.operationalStatus}");
      buffer.writeln("  - **Actualización:** ${v.lastUpdated}\n");
    });

    return buffer.toString().trim();
  }

  // ==========================================
  // DEFENSAS DE SALIDA (OUTPUT SCRUBBER)
  // ==========================================

  /// Scrubber de defensa en profundidad que intercepta cualquier fuga de datos antes de entregar la respuesta
  static String sanitizeAndValidateOutput(String rawOutput) {
    // Si contiene patrones de montos monetarios o precios no autorizados
    final currencyPattern = RegExp(r'(\$\s*[0-9]+|usd\s*[0-9]+|eur\s*[0-9]+|ars\s*[0-9]+)', caseSensitive: false);
    if (currencyPattern.hasMatch(rawOutput)) {
      return restrictedInfoMessage;
    }

    // Si contiene patrones de números de cuenta o tarjetas
    final accountPattern = RegExp(r'\b[0-9]{16,22}\b');
    if (accountPattern.hasMatch(rawOutput)) {
      return restrictedInfoMessage;
    }

    // Si contiene palabras sensibles de salario o facturación con valores numéricos
    final salaryLeakPattern = RegExp(r'(sueldo|salario|remuneraci[oó]n|costo|precio|facturaci[oó]n):\s*[0-9]+', caseSensitive: false);
    if (salaryLeakPattern.hasMatch(rawOutput)) {
      return restrictedInfoMessage;
    }

    return rawOutput;
  }
}
