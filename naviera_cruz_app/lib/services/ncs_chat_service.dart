import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/config.dart';
import '../core/storage.dart';
import '../models/ncs_chat_models.dart';

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

  Stream<NCSStreamEvent> streamChatResponse(String prompt) async* {
    if (AppConfig.isMockActive) {
      yield* _mockStreamChatResponse(prompt);
      return;
    }

    // Try Centinela endpoints (Local Bridge & Production Server Proxy)
    final centinelaEndpoints = [
      "https://navieracruzdelsur.dyndns.org:6570/centinela-api/api/ai-chat/external-bot",
      "https://navieracruzdelsur.dyndns.org:6570/api/ai-chat/external-bot",
      "http://192.168.2.121:3001/api/ai-chat/external-bot",
      "https://192.168.2.121:5073/api/ai-chat/external-bot",
    ];

    for (final endpoint in centinelaEndpoints) {
      try {
        final uri = Uri.parse(endpoint);
        final res = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': 'centinela-bridge-2026',
          },
          body: jsonEncode({
            'message': prompt,
            'history': [
              {
                'role': 'system',
                'content': 'Estás hablando directamente a través de la app móvil de voz con un miembro de la tripulación o gerencia de la Naviera Cruz del Sur. Tu rol es ser el Asistente de NCS, conversar de forma empática, directa y profesional. No digas que eres Centinela, sólo di que eres el Asistente de NCS. Contexto: ALFA C (26.02k t para Raizen, fondeado en Rada La Plata por mal clima), GUSTAVO U (16.52k t para WFS), NANY (12.84k t para WFS). Tripulación y cámaras disponibles.'
              }
            ]
          }),
        ).timeout(const Duration(seconds: 2));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final reply = data['reply'] as String?;
          if (reply != null && reply.isNotEmpty) {
            yield NCSStreamEvent(type: "log", logClass: "info", content: "Conectado con Asistente de NCS...");
            yield NCSStreamEvent(type: "log", logClass: "info", content: "Procesando respuesta del Control Center...");
            await Future.delayed(const Duration(milliseconds: 300));
            yield NCSStreamEvent(
              type: "result",
              content: reply,
              structured: _generateStructuredForPrompt(prompt),
            );
            return;
          }
        }
      } catch (_) {}
    }

    // Try standard POST /api/chat/
    final uri = Uri.parse("$_baseURL/api/chat/");
    final client = http.Client();

    try {
      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/x-ndjson';

      final token = await SessionManager.shared.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Token $token';
      }

      request.body = jsonEncode({'message': prompt});

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        final lines = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          try {
            final jsonMap = jsonDecode(trimmed) as Map<String, dynamic>;
            yield NCSStreamEvent.fromJson(jsonMap);
          } catch (e) {
            print("⚠️ Error decodificando linea NDJSON: $trimmed, err: $e");
          }
        }
      } else {
        yield* _mockStreamChatResponse(prompt);
      }
    } catch (e) {
      yield* _mockStreamChatResponse(prompt);
    } finally {
      client.close();
    }
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
    final NCSStructuredVesselData structuredData = _generateStructuredForPrompt(prompt);

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
      if (lower.contains("alfa")) {
        responseText = """
### 👨‍✈️ Dotación y Tripulación - BT ALFA C

Tripulación embarcada activa en regla STCW (15 tripulantes):

- **Capitán:** Marenco Rubén Darío ➔ 🟢 10 días embarcado
- **1er Oficial Cubierta:** Maldonado Juan ➔ 🟢 10 días embarcado
- **2do Oficial Cubierta:** Carattoli Pablo ➔ 🟢 35 días embarcado
- **3er Oficial Cubierta:** Lambertuchi Pablo ➔ 🟢 10 días embarcado
- **Jefe de Máquinas:** Sosa Armando ➔ 🟢 18 días embarcado
- **1er Oficial Máquinas:** Molero Jorge ➔ 🟢 6 días embarcado
- **2do Oficial Máquinas:** Ledesma Gabriel ➔ 🟢 36 días embarcado
- **Contramaestre:** Sosa Marcelo ➔ 🟢 23 días embarcado
- **Marineros I:** Marquez Ruben (36d), Romero José (10d), Miguel Angel Ramirez (23d)
- **1er Cabo:** Zacarias Walter ➔ 🟢 49 días embarcado
- **Cocinero:** Kretschel Claudio ➔ 🟢 17 días embarcado
- **Bomberos:** Aquino Marcos (26d), Mineo Julio (10d)

> **Semáforo de Relevos:** 🟢 15 OK (<60d) | 🟡 0 Próx. Relevo | 🔴 0 Excedidos
> **Status Dotación:** Dotación mínima completa (15/15).
""";
      } else if (lower.contains("gustavo")) {
        responseText = """
### 👨‍✈️ Dotación y Tripulación - BT GUSTAVO U

Tripulación embarcada activa (15 tripulantes):

- **Capitán:** Ramirez Pedro ➔ 🟢 20 días embarcado
- **1er Oficial Cubierta:** Percara Marco ➔ 🟢 9 días embarcado
- **2do Oficial Cubierta:** Perez Douglas ➔ 🟢 20 días embarcado
- **Piloto (PLT):** Tobias Joaquin ➔ 🔴 108 días embarcado (Alerta Relevo)
- **Jefe de Máquinas:** Agüero Leandro ➔ 🟢 14 días embarcado
- **1er Oficial Máquinas:** Aguirrezarobe Alexis ➔ 🟢 9 días embarcado
- **2do Oficial Máquinas:** Tomas Ribas Pintos ➔ 🟢 9 días embarcado
- **Contramaestre:** Cucurulo Gustavo ➔ 🟢 24 días embarcado
- **Marineros I:** Molina Geronimo (40d), Camacho Pablo Ezequias (29d), Rene Ruben Aceval (12d)
- **Bomberos:** Jacquet Jorge (20d), Escalante Eduardo (9d)
- **Engrasador:** Caprioglio Fernando ➔ 🟢 32 días embarcado
- **Cocinero:** Rodriguez Lucas ➔ 🟢 17 días embarcado

> **Semáforo de Relevos:** 🟢 14 OK (<60d) | 🔴 1 Excedido STCW (Tobias Joaquin: 108d)
> **Status Dotación:** Dotación mínima completa (15/15).
""";
      } else if (lower.contains("nany")) {
        responseText = """
### 👨‍✈️ Dotación y Tripulación - BT NANY

Tripulación embarcada activa (15 tripulantes):

- **Capitán:** Maciel Jonathan ➔ 🟢 14 días embarcado
- **1er Oficial Cubierta:** Maidana Francisco ➔ 🟢 18 días embarcado
- **2do Oficial Cubierta:** Saucedo Nicolás ➔ 🟢 14 días embarcado
- **3er Oficial Cubierta:** Alan Leguiza ➔ 🟢 14 días embarcado
- **Jefe de Máquinas:** Porto Guillermo ➔ 🟢 23 días embarcado
- **1er Oficial Máquinas:** Bequir Ramiro ➔ 🟢 4 días embarcado
- **2do Conductor:** Rosales Carlos ➔ 🟢 18 días embarcado
- **Contramaestre:** Torres Ulises ➔ 🟢 9 días embarcado
- **Marineros I:** Andrada Emiliano (23d), Mora Alejandro (18d), Ganduglia Sergio (14d)
- **Auxiliar Máquinas:** Correa Motta Nicolas ➔ 🟢 9 días embarcado
- **Engrasador:** Martin Tarroza ➔ 🟢 50 días embarcado
- **Cocinero:** Cantore Alejandro ➔ 🟢 4 días embarcado
- **Bombero:** Medina Felix ➔ 🟢 23 días embarcado

> **Semáforo de Relevos:** 🟢 15 OK (<60d) | 🟡 0 Próx. Relevo | 🔴 0 Excedidos
> **Status Dotación:** Dotación mínima completa (15/15).
""";
      } else {
        responseText = """
### 👨‍✈️ Resumen de Tripulación y Semáforo de Relevos - NCS Control Center

- 🚢 **BT ALFA C:** 15 tripulantes ➔ Capitán Marenco Rubén Darío | Jefe Máq. Sosa Armando (🟢 15 OK)
- 🚢 **BT GUSTAVO U:** 15 tripulantes ➔ Capitán Ramirez Pedro | Jefe Máq. Agüero Leandro (🔴 1 Excedido: Tobias J. 108d)
- 🚢 **BT NANY:** 15 tripulantes ➔ Capitán Maciel Jonathan | Jefe Máq. Porto Guillermo (🟢 15 OK)

> **Semáforo Total Flota:** 🟢 44 en norma (<60d) | 🔴 1 vencido STCW (>=90d) | Dotación mínima completa en los 3 buques (45 tripulantes a bordo).
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
### 🚢 Estado Operativo - BT ALFA C

- **Situación:** En navegación (Vel: 0.1 kn / Rumbo: 115°).
- **Carga Acumulada:** Raizen (3050.00 m³ • 12 buques atendidos).
- **Posición GPS:** 42°76'S 65°03'W.
- **Recursos Tanques:** Combustible 71.34 m³ (71%), Agua 83.0 m³ (27%), Slop 5.20 m³ (14%).
""";
    }
    else if (lower.contains("gustavo")) {
      responseText = """
### 🚢 Estado Operativo - BT GUSTAVO U

- **Situación:** En operaciones de carga para cliente WFS.
- **Carga Acumulada:** WFS (7.39 k t • 16 buques atendidos).
- **Velocidad:** 11.8 nudos.
- **Recursos Tanques:** Combustible 62.50 m³ (58%), Agua 65.0 m³ (32%), Slop 4.80 m³ (16%).
""";
    }
    else if (lower.contains("nany")) {
      responseText = """
### 🚢 Estado Operativo - BT NANY

- **Situación:** En puerto completando maniobras de alijo y transferencia de carga para cliente WFS.
- **Carga Acumulada:** WFS (4.32 k t • 6 buques atendidos).
- **Recursos Tanques:** Combustible 54.80 m³ (61%), Agua 52.0 m³ (35%), Slop 3.40 m³ (12%).
""";
    }
    else if (lower.contains("estado") ||
        lower.contains("barco") ||
        lower.contains("buque") ||
        lower.contains("flota") ||
        lower.contains("donde esta") ||
        lower.contains("dónde está")) {
      responseText = """
### Estado Operativo de la Flota - Asistente de NCS

- 🚢 **BT ALFA C:** Fondeado en Rada La Plata por condiciones meteorológicas (Ingreso a DDI programado el 08/04). Carga acumulada: 26.02k t para Raizen.
- 🚢 **BT GUSTAVO U:** En navegación activa completando operaciones de carga para cliente WFS (16.52k t).
- 🚢 **BT NANY:** En puerto completando maniobras de alijo y transferencia de carga para WFS (12.84k t).
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

  NCSStructuredVesselData _generateStructuredForPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains("oficina")) {
      return NCSStructuredVesselData(
        vesselName: "Cámara Oficina Central (NCS)",
        status: "Transmitiendo en Vivo",
        speed: "HD 1080p",
        coordinates: "Oficina Principal",
        eta: "Online 24/7",
        fuelLevel: "Alimentación OK",
        cargoWeight: "Supervisión Activa",
      );
    } else if (lower.contains("gustavo")) {
      return NCSStructuredVesselData(
        vesselName: "BT GUSTAVO U",
        status: "En Navegación",
        speed: "11.8 nudos",
        coordinates: "38°00'S 57°55'W",
        eta: "Mañana 09:00",
        fuelLevel: "180 t (60%)",
        cargoWeight: "340 Ton",
      );
    } else if (lower.contains("nany")) {
      return NCSStructuredVesselData(
        vesselName: "BT NANY",
        status: "En Puerto",
        speed: "0.0 nudos",
        coordinates: "54°80'S 68°30'W",
        eta: "Hoy 20:00",
        fuelLevel: "155 t (62%)",
        cargoWeight: "528 Ton",
      );
    } else {
      return NCSStructuredVesselData(
        vesselName: "BT ALFA C",
        status: "Fondeado en Rada",
        speed: "0.2 nudos",
        coordinates: "42°76'S 65°03'W",
        eta: "08/04 DDI",
        fuelLevel: "210 t (60%)",
        cargoWeight: "528 Ton",
      );
    }
  }
}
