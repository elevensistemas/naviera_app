import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/config.dart';
import '../core/storage.dart';
import '../models/ncs_chat_models.dart';
import '../models/intranet_crew_catalog.dart';
import 'ncs_chat_policy.dart';

class NCSChatService {
  static final NCSChatService shared = NCSChatService._internal();
  NCSChatService._internal();

  final String _baseURL = AppConfig.apiBaseURL;

  String? getTTSAudioURL(String text) {
    if (text.isEmpty) return null;
    final trimmed = text.length > 500 ? text.substring(0, 500) : text;
    final encoded = Uri.encodeComponent(trimmed);
    return "$_baseURL/api/chat/tts?text=$encoded";
  }

  Future<String?> queryCentinela(String prompt, {List<Map<String, String>>? history}) async {
    return _queryCentinelaLLM(prompt, history: history);
  }

  Future<String?> _queryCentinelaLLM(String prompt, {List<Map<String, String>>? history}) async {
    final List<String> endpoints = [
      "https://navieracruzdelsur.dyndns.org:5073/api/ai-chat/external-bot",
      "https://navieracruzdelsur.dyndns.org:6570/api/v1/chat/ai/",
      "https://navieracruzdelsur.dyndns.org:6570/api/ai-chat/external-bot",
      "http://192.168.2.169:3001/api/ai-chat/external-bot",
    ];

    final token = await SessionManager.shared.getToken();
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "x-api-key": "centinela-bridge-2026",
    };
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Token $token";
    }

    final Map<String, dynamic> payload = {
      "message": prompt,
      "prompt": prompt,
      "query": prompt,
      "stream": false,
      "history": history ?? [],
    };
    final bodyStr = jsonEncode(payload);

    for (final url in endpoints) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: bodyStr,
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final reply = data["reply"] ?? data["response"] ?? data["message"] ?? data["answer"] ?? data["content"];
          if (reply != null && reply.toString().trim().isNotEmpty) {
            return reply.toString().trim();
          }
        }
      } catch (e) {
        // Continue to next endpoint / fallback
      }
    }
    return null;
  }

  Stream<NCSStreamEvent> streamChatResponse(String prompt, {List<Map<String, String>>? history}) async* {
    final currentUser = SessionManager.shared.currentUser;

    // FASE 1: Verificación de Política Corporativa y Seguridad
    yield NCSStreamEvent(
      type: "log",
      logClass: "info",
      content: "Verificando política corporativa de seguridad y permisos...",
    );
    await Future.delayed(const Duration(milliseconds: 150));

    final targetShip = NCSCorporateChatPolicy.extractShipFromQuery(prompt);
    final hasShipAccess = targetShip == null || NCSCorporateChatPolicy.hasPermissionForShip(currentUser, targetShip);
    final hasProhibitedFinancial = NCSCorporateChatPolicy.containsProhibitedFinancialOrEconomicQuery(prompt);
    final hasProhibitedPii = NCSCorporateChatPolicy.containsProhibitedPiiQuery(prompt);
    final hasProhibitedSec = NCSCorporateChatPolicy.containsSecurityCredentialsQuery(prompt);
    final hasEvasion = NCSCorporateChatPolicy.containsEvasionAttempt(prompt);
    final isProhibited = hasProhibitedFinancial || hasProhibitedPii || hasProhibitedSec || hasEvasion;
    final isWithinScope = NCSCorporateChatPolicy.isWithinPermittedScope(prompt);

    // 1.A: Control de acceso a buques (un usuario de buque solo puede ver su buque)
    if (!hasShipAccess) {
      yield NCSStreamEvent(
        type: "log",
        logClass: "warning",
        content: "Control de acceso: Usuario sin permiso para consultar buques ajenos.",
      );
      await Future.delayed(const Duration(milliseconds: 150));
      yield NCSStreamEvent(
        type: "result",
        content: NCSCorporateChatPolicy.unauthorizedVesselMessage,
      );
      return;
    }

    // 1.B: Información prohibida pura (financiera, sueldos, evasión, etc. sin parte permitida)
    if (isProhibited && !isWithinScope) {
      yield NCSStreamEvent(
        type: "log",
        logClass: "warning",
        content: "Política corporativa: Consulta sobre información restringida bloqueada.",
      );
      await Future.delayed(const Duration(milliseconds: 150));
      final policyResponse = NCSCorporateChatPolicy.processCorporatePolicy(
        prompt: prompt,
        currentUser: currentUser,
      );
      yield NCSStreamEvent(
        type: "result",
        content: policyResponse,
      );
      return;
    }

    // 1.C: Consulta fuera de alcance
    if (!isWithinScope && !isProhibited) {
      yield NCSStreamEvent(
        type: "log",
        logClass: "info",
        content: "Evaluando alcance de consulta con política de empresa...",
      );
      await Future.delayed(const Duration(milliseconds: 150));
      yield NCSStreamEvent(
        type: "result",
        content: NCSCorporateChatPolicy.outOfScopeMessage,
      );
      return;
    }

    // FASE 2: Consulta al LLM corporativo (Centinela IA)
    yield NCSStreamEvent(
      type: "log",
      logClass: "info",
      content: "Conectando con Centinela IA (LLM local de Naviera Cruz del Sur)...",
    );
    await Future.delayed(const Duration(milliseconds: 150));

    yield NCSStreamEvent(
      type: "log",
      logClass: "info",
      content: "Consultando telemetría AIS en tiempo real y manuales operativos...",
    );

    String? llmReply = await _queryCentinelaLLM(prompt, history: history);

    if (llmReply == null || llmReply.isEmpty) {
      yield NCSStreamEvent(
        type: "log",
        logClass: "warning",
        content: "Enlace remoto no disponible. Utilizando procesador de contingencia corporativo...",
      );
      llmReply = NCSCorporateChatPolicy.processCorporatePolicy(
        prompt: prompt,
        currentUser: currentUser,
      );
    } else {
      yield NCSStreamEvent(
        type: "log",
        logClass: "success",
        content: "Respuesta generada exitosamente por Centinela IA.",
      );
    }

    NCSStructuredVesselData? structured;
    if (targetShip != null &&
        (prompt.toLowerCase().contains("donde") ||
         prompt.toLowerCase().contains("dónde") ||
         prompt.toLowerCase().contains("estado") ||
         prompt.toLowerCase().contains("barco") ||
         prompt.toLowerCase().contains("buque"))) {
      structured = _generateStructuredForPrompt(targetShip);
    }

    yield NCSStreamEvent(
      type: "result",
      content: llmReply,
      structured: structured,
    );
  }

  // MARK: - Smart Centinela Bot Intent Processor matching WhatsApp Bot Functions
  Stream<NCSStreamEvent> _mockStreamChatResponse(String prompt) async* {
    final lower = prompt.toLowerCase().trim();

    yield NCSStreamEvent(
      type: "log",
      logClass: "info",
      content: "Consultando al Asistente de NCS...",
    );
    await Future.delayed(const Duration(milliseconds: 300));

    yield NCSStreamEvent(
      type: "log",
      logClass: "info",
      content: "Sincronizando información operativa en tiempo real...",
    );
    await Future.delayed(const Duration(milliseconds: 300));

    final String responseText;
    final NCSStructuredVesselData? structuredData = _generateStructuredForPrompt(prompt);

    // PRIORITY 1: Tripulación / Personal / Capitanes (Checked FIRST before vessel names capture it)
    if (lower.contains("tripul") ||
        lower.contains("capitán") ||
        lower.contains("capitan") ||
        lower.contains("oficial") ||
        lower.contains("marinero") ||
        lower.contains("quien esta") ||
        lower.contains("quién está") ||
        lower.contains("dotacion") ||
        lower.contains("dotación") ||
        lower.contains("personal")) {
      String? shipFilter;
      if (lower.contains("alfa")) {
        shipFilter = "ALFA C";
      } else if (lower.contains("gustavo")) {
        shipFilter = "GUSTAVO U";
      } else if (lower.contains("nany")) {
        shipFilter = "NANY";
      }

      if (shipFilter != null) {
        final list = IntranetCrewCatalog.aBordo
            .where((m) => m.shipName != null && m.shipName!.toUpperCase() == shipFilter!.toUpperCase())
            .toList();
        final buffer = StringBuffer();
        buffer.writeln("### 👨‍✈️ Dotación y Tripulación - BT $shipFilter\n");
        buffer.writeln("Tripulación embarcada activa en regla STCW (${list.length} tripulantes):\n");
        int okCount = 0;
        int warnCount = 0;
        int excCount = 0;
        for (final m in list) {
          final isExceeded = m.days >= 90;
          final isWarn = m.days >= 60 && m.days < 90;
          final sem = isExceeded ? "🔴" : (isWarn ? "🟡" : "🟢");
          if (isExceeded) {
            excCount++;
          } else if (isWarn) {
            warnCount++;
          } else {
            okCount++;
          }
          final note = isExceeded
              ? " (Alerta Relevo STCW)"
              : (isWarn ? " (Próximo Relevo)" : "");
          final roleLabel = m.roleName.isNotEmpty ? m.roleName : m.roleCode;
          buffer.writeln("- **$roleLabel:** ${m.name} ➔ $sem ${m.days} días embarcado$note");
        }
        buffer.writeln("\n> **Semáforo de Relevos:** 🟢 $okCount OK (<60d) | 🟡 $warnCount Próx. Relevo | 🔴 $excCount Excedidos");
        buffer.writeln("> **Status Dotación:** Dotación mínima completa a bordo (${list.length} tripulantes).");
        responseText = buffer.toString();
      } else {
        final alfa = IntranetCrewCatalog.aBordo.where((m) => m.shipName == "ALFA C").toList();
        final gustavo = IntranetCrewCatalog.aBordo.where((m) => m.shipName == "GUSTAVO U").toList();
        final nany = IntranetCrewCatalog.aBordo.where((m) => m.shipName == "NANY").toList();
        final total = IntranetCrewCatalog.aBordo.length;
        final exc = IntranetCrewCatalog.aBordo.where((m) => m.days >= 90).length;
        final warn = IntranetCrewCatalog.aBordo.where((m) => m.days >= 60 && m.days < 90).length;
        final ok = total - exc - warn;

        final capAlfa = alfa.firstWhere((m) => m.roleCode == 'CAP', orElse: () => alfa.first).name;
        final capGus = gustavo.firstWhere((m) => m.roleCode == 'CAP' || m.roleCode == '1ER OF CUB', orElse: () => gustavo.first).name;
        final capNany = nany.firstWhere((m) => m.roleCode == 'CAP', orElse: () => nany.first).name;

        responseText = """
### 👨‍✈️ Resumen de Tripulación y Semáforo de Relevos - NCS Control Center

- 🚢 **BT ALFA C:** ${alfa.length} tripulantes ➔ Al mando: $capAlfa (🟢 ${alfa.where((m) => m.days < 60).length} OK)
- 🚢 **BT GUSTAVO U:** ${gustavo.length} tripulantes ➔ Al mando: $capGus (🔴 1 Excedido STCW: Tobias J. 137d)
- 🚢 **BT NANY:** ${nany.length} tripulantes ➔ Capitán: $capNany | 2do Of: Fleitas Emmanuel (6d) (🟢 ${nany.where((m) => m.days < 60).length} OK)

> **Semáforo Total Flota:** 🟢 $ok en norma (<60d) | 🟡 $warn próx. relevo | 🔴 $exc excedido STCW | Dotación mínima completa en los 3 buques ($total tripulantes a bordo).
""";
      }
    }
    // PRIORITY 2: Solicitud de Cámara de la Oficina o Cámaras de Buques
    else if (lower.contains("oficina") || lower.contains("central") || lower.contains("despacho")) {
      responseText = """
### 📹 Monitoreo en Vivo - Oficina Central NCS

Conexión establecida con la cámara de la **Oficina Central de Naviera Cruz del Sur**.

- **Ubicación:** Oficina Principal / Control Center (Puerto / Operaciones)
- **Estado:** Transmitiendo en Vivo (Stream HLS Online 24/7)
- **Supervisión:** Personal administrativo y de operaciones en turno activo.

*Puedes acceder a la transmisión en vivo directamente en la pestaña **Flota -> Monitoreo de Cámaras**.*
""";
    }
    else if (lower.contains("camara") || lower.contains("cámara") || lower.contains("video") || lower.contains("stream")) {
      responseText = """
### 📹 Monitoreo de Cámaras Ezviz - Flota y Oficina

El sistema cuenta con transmisiones HLS HD en tiempo real:

1. **Oficina Central NCS:** Online (Canal 1 - Control Center)
2. **BT ALFA C:** Online (Cámara de Puente y Cubierta)
3. **BT GUSTAVO U:** Online (Cámara de Cubierta)
4. **BT NANY:** Online (Cámara de Proa / Alijo)

> *Para seleccionar el feed en vivo de la oficina o buques, navega a la sección **Flota**.*
""";
    }
    // PRIORITY 3: Recursos de Tanques (Combustible, Agua, Slop, Residuos)
    else if (lower.contains("slop") ||
        lower.contains("agua") ||
        lower.contains("combustible") ||
        lower.contains("fuel") ||
        lower.contains("tanque") ||
        lower.contains("recursos") ||
        lower.contains("residuo")) {
      responseText = """
### Reporte de Recursos y Tanques - Asistente de NCS

Niveles actualizados de recursos en la flota:

1. **BT ALFA C**:
   - ⛽ **Combustible:** 71.34 m³ (71%)
   - 💧 **Agua Dulce:** 83.0 m³ (27%)
   - 🛢️ **Slop / Residuos:** 5.20 m³ (14%)

2. **BT GUSTAVO U**:
   - ⛽ **Combustible:** 62.50 m³ (58%)
   - 💧 **Agua Dulce:** 65.0 m³ (32%)
   - 🛢️ **Slop / Residuos:** 4.80 m³ (16%)

3. **BT NANY**:
   - ⛽ **Combustible:** 54.80 m³ (61%)
   - 💧 **Agua Dulce:** 52.0 m³ (35%)
   - 🛢️ **Slop / Residuos:** 3.40 m³ (12%)

*Todos los buques cuentan con niveles operativos sincronizados con el panel de flota.*
""";
    }
    // PRIORITY 4: Estado de Buques y Operaciones por Buque
    else if (lower.contains("alfa")) {
      responseText = """
### 🚢 Monitoreo - BT ALFA C

- **Cámara a Bordo:** Transmisión de video Ezviz en tiempo real (Pestaña Flota).
- **Carga Mensual:** Raizen (14.68 k tons • 25 buques provistos).
- **Recursos Tanques:** Combustible 150.54 m³, Agua 118.2 m³, Slop 8.31 m³.
""";
    }
    else if (lower.contains("gustavo")) {
      responseText = """
### 🚢 Monitoreo - BT GUSTAVO U

- **Cámara a Bordo:** Transmisión de video Ezviz en tiempo real (Pestaña Flota).
- **Carga Mensual:** WFS (7.39 k tons • 16 buques provistos).
- **Recursos Tanques:** Combustible 135.0 m³, Agua 95.0 m³, Slop 6.50 m³.
""";
    }
    else if (lower.contains("nany")) {
      responseText = """
### 🚢 Monitoreo - BT NANY

- **Cámara a Bordo:** Transmisión de video Ezviz en tiempo real (Pestaña Flota).
- **Carga Mensual:** WFS (10.99 k tons • 24 buques provistos).
- **Recursos Tanques:** Combustible 120.0 m³, Agua 88.0 m³, Slop 5.20 m³.
""";
    }
    else if (lower.contains("estado") ||
        lower.contains("barco") ||
        lower.contains("buque") ||
        lower.contains("flota") ||
        lower.contains("donde esta") ||
        lower.contains("dónde está")) {
      responseText = """
### Monitoreo de Flota - Asistente de NCS

Las operaciones y estado visual se verifican en tiempo real a través de las cámaras en vivo a bordo:

- 🚢 **BT ALFA C:** Cámara en vivo disponible (Carga: 14.68k t para Raizen).
- 🚢 **BT GUSTAVO U:** Cámara en vivo disponible (Carga: 7.39k t para WFS).
- 🚢 **BT NANY:** Cámara en vivo disponible (Carga: 10.99k t para WFS).

> *Para acceder a las transmisiones en directo, ingresa al módulo **Flota**.*
""";
    }
    // PRIORITY 5: Clima y Meteorología
    else if (lower.contains("clima") || lower.contains("viento") || lower.contains("tiempo") || lower.contains("marea")) {
      responseText = """
### Reporte Meteorológico de Operaciones

- **Dock Sud:** 20°C, Nublado. Viento ENE 10 nudos.
- **Río de la Plata (Rada):** 21°C, Vientos NNO 16 nudos con marejada leve.
- **Campana:** 19°C, Lluvia ligera.

*Previsión favorable para maniobras de alijo en las próximas 12 horas.*
""";
    }
    // PRIORITY 6: Saludos y conversación natural
    else if (lower.contains("quien eres") ||
        lower.contains("quién eres") ||
        lower.contains("quien sos") ||
        lower.contains("quién sos") ||
        lower.contains("como te llamas") ||
        lower.contains("cómo te llamas")) {
      responseText = "Soy el **Asistente de NCS**.";
    }
    else if (lower == "hola" ||
        lower.startsWith("hola ") ||
        lower.contains("como estas") ||
        lower.contains("cómo estás") ||
        lower.contains("buenos dias") ||
        lower.contains("buenas tardes") ||
        lower.contains("buenas noches") ||
        lower.contains("buenas")) {
      responseText = """
¡Hola! Todo en orden por aquí. Soy el **Asistente de NCS**.

¿En qué te puedo colaborar hoy? Puedes pedirme:
- 👨‍✈️ *"Dime la tripulación a bordo del Alfa C"*
- 🏢 *"Muéstrame la oficina"*
- 🚢 *"Estado de la flota"* (ALFA C, GUSTAVO U, NANY)
- ⛽ *"Nivel de recursos"* (Combustible, Agua Dulce, Slop)
""";
    }
    // PRIORITY 7: Respuestas por defecto
    else {
      responseText = """
Entendido. He procesado tu consulta: "*$prompt*".

Como Asistente de NCS, puedo ayudarte con:
1. 👨‍✈️ **Tripulación:** *"Dime la tripulación del Alfa C"*.
2. 🏢 **Cámaras en vivo:** *"Muéstrame la oficina"*.
3. 🚢 **Estado de buques:** *"¿Dónde está el Alfa C?"* o *"Estado de flota"*.
4. ⛽ **Recursos:** *"Nivel de combustible, agua y slop"*.
5. 🌤️ **Clima:** *"Condiciones meteorológicas en Rada"*.
""";
    }

    yield NCSStreamEvent(
      type: "result",
      logClass: null,
      content: responseText,
      structured: structuredData,
    );
  }

  NCSStructuredVesselData? _generateStructuredForPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains("gustavo")) {
      return NCSStructuredVesselData(
        vesselName: "BT GUSTAVO U",
        status: "Cámara Onboard",
        speed: "Flujo HD",
        coordinates: "Río de la Plata",
        eta: "Operativo",
        fuelLevel: "135.0 m³",
        cargoWeight: "7.39k Tons",
      );
    } else if (lower.contains("nany")) {
      return NCSStructuredVesselData(
        vesselName: "BT NANY",
        status: "Cámara Onboard",
        speed: "Flujo HD",
        coordinates: "Río de la Plata",
        eta: "Operativo",
        fuelLevel: "120.0 m³",
        cargoWeight: "10.99k Tons",
      );
    } else if (lower.contains("monarca")) {
      return NCSStructuredVesselData(
        vesselName: "BT MONARCA I",
        status: "Cámara Onboard",
        speed: "Flujo HD",
        coordinates: "Puerto",
        eta: "Operativo",
        fuelLevel: "90.0 m³",
        cargoWeight: "Flota NCS",
      );
    } else if (lower.contains("alfa")) {
      return NCSStructuredVesselData(
        vesselName: "BT ALFA C",
        status: "Cámara Onboard",
        speed: "Flujo HD",
        coordinates: "Río de la Plata",
        eta: "Operativo",
        fuelLevel: "150.54 m³",
        cargoWeight: "14.68k Tons",
      );
    }
    return null;
  }
}
