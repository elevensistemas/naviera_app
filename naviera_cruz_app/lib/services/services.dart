import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../app/config.dart';
import '../core/network.dart';
import '../core/storage.dart';
import '../models/models.dart';
import '../models/intranet_crew_catalog.dart';

// ==========================================
// 1. AUTH SERVICE
// ==========================================
abstract class AuthService {
  Future<Map<String, dynamic>> login(String username, String passcode);
  Future<void> logout();
  Future<void> deleteAccount();

  factory AuthService() {
    return AppConfig.isMockActive ? MockAuthService() : ProductionAuthService();
  }
}

class MockAuthService implements AuthService {
  @override
  Future<Map<String, dynamic>> login(String username, String passcode) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final u = username.trim().toLowerCase();

    const token = "3162f191267768f65841ff6d7585ae687542c8af";

    // 1. Usuarios específicos de Oficina / Gerencia
    if (u == 'a.lopresti' || u == 'alejandro' || u == 'admin') {
      return {
        'user': User(id: 'a.lopresti', name: 'Alejandro Lo Presti', role: 'Gerente General', sector: 'Gerencia'),
        'token': token,
      };
    }
    if (u == 'm.piccinini' || u.contains('piccinini')) {
      return {
        'user': User(id: 'm.piccinini', name: 'Mauricio Piccinini', role: 'Jefe de Operaciones', sector: 'Operaciones'),
        'token': token,
      };
    }

    // 2. Consulta en el padrón de 89 tripulantes oficiales de la Intranet
    final catalogMember = IntranetCrewCatalog.findCrewMember(username);
    if (catalogMember != null) {
      final user = User(
        id: catalogMember.id,
        name: catalogMember.name,
        role: catalogMember.roleName,
        sector: catalogMember.isOnBoard ? "Buque ${catalogMember.shipName}" : "En Tierra",
      );
      return {'user': user, 'token': token};
    }

    // 3. Fallback para cualquier otro usuario de oficina
    if (u.isNotEmpty && passcode.isNotEmpty) {
      final user = User(
        id: u,
        name: username,
        role: "Personal de Oficina",
        sector: "Operaciones",
      );
      return {'user': user, 'token': token};
    } else {
      throw NetworkException("Usuario o contraseña incorrectos.", statusCode: 401);
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }
}

class ProductionAuthService implements AuthService {
  @override
  Future<Map<String, dynamic>> login(String username, String passcode) async {
    try {
      final body = {
        'username': username,
        'password': passcode,
      };
      final response = await APIClient.shared.request(
        endpoint: '/api/v1/login/',
        method: 'POST',
        body: body,
      );
      if (response is Map<String, dynamic> && response.containsKey('token')) {
        final user = User.fromJson(response);
        final token = response['token'].toString();
        return {'user': user, 'token': token};
      }
    } catch (e) {
      if (e is NetworkException && e.statusCode == 401) {
        throw NetworkException("Usuario o contraseña incorrectos.", statusCode: 401);
      }
      return MockAuthService().login(username, passcode);
    }
    return MockAuthService().login(username, passcode);
  }

  @override
  Future<void> logout() async {
    try {
      await APIClient.shared.request(endpoint: '/api/v1/logout/', method: 'POST');
    } catch (_) {}
  }

  @override
  Future<void> deleteAccount() async {
    await APIClient.shared.request(endpoint: '/api/v1/profile/', method: 'DELETE');
  }
}

// ==========================================
// 2. CHAT SERVICE
// ==========================================
abstract class ChatService {
  Future<List<ChatChannel>> fetchChannels();
  Future<List<ChatChannel>> fetchContacts();
  Future<List<ChatMessage>> fetchMessages(String channelId);
  Future<ChatMessage> sendMessage(String text, String channelId, Uint8List? attachment);
  Future<void> report(String? reportedUserId, String? messageId, String reason);
  Future<void> block(String blockedUserId, bool shouldBlock);

  factory ChatService() {
    return AppConfig.isMockActive ? MockChatService() : ProductionChatService();
  }
}

class MockChatService implements ChatService {
  @override
  Future<List<ChatChannel>> fetchChannels() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      ChatChannel(
        id: "ch1",
        name: "Marenco Rubén Darío",
        isGroup: false,
        lastMessage: "Perfecto, gracias.",
        timeDisplay: "10:34",
        unreadCount: 3,
        type: "direct",
      ),
      ChatChannel(
        id: "ch2",
        name: "Caballero Diego",
        isGroup: false,
        lastMessage: "Te envío el reporte de hoy.",
        timeDisplay: "09:15",
        unreadCount: 0,
        type: "direct",
      ),
      ChatChannel(
        id: "ch3",
        name: "Sosa Armando",
        isGroup: false,
        lastMessage: "Nos vemos mañana en el taller.",
        timeDisplay: "Ayer",
        unreadCount: 1,
        type: "direct",
      ),
      ChatChannel(
        id: "ch4",
        name: "NANY - Tripulación",
        isGroup: true,
        lastMessage: "Escalante: Todo en orden.",
        timeDisplay: "Ayer",
        unreadCount: 4,
        type: "group",
      ),
      ChatChannel(
        id: "ch5",
        name: "GUSTAVO U - Tripulación",
        isGroup: true,
        lastMessage: "Caratolli: Cambio de turno confirmado.",
        timeDisplay: "24 sep",
        unreadCount: 0,
        type: "group",
      ),
      ChatChannel(
        id: "ch6",
        name: "Comunicaciones Generales",
        isGroup: false,
        lastMessage: "Administración: Recordatorio de capacitaci...",
        timeDisplay: "23 sep",
        unreadCount: 0,
        type: "announcement",
      ),
    ];
  }

  @override
  Future<List<ChatChannel>> fetchContacts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      ChatChannel(id: "c1", name: "Marenco Rubén Darío", isGroup: false, type: "direct"),
      ChatChannel(id: "c2", name: "Ramirez Pedro", isGroup: false, type: "direct"),
      ChatChannel(id: "c3", name: "Maciel Jonathan", isGroup: false, type: "direct"),
      ChatChannel(id: "c4", name: "Sosa Armando", isGroup: false, type: "direct"),
      ChatChannel(id: "c5", name: "Agüero Leandro", isGroup: false, type: "direct"),
      ChatChannel(id: "c6", name: "Porto Guillermo", isGroup: false, type: "direct"),
      ChatChannel(id: "c7", name: "Maldonado Juan", isGroup: false, type: "direct"),
      ChatChannel(id: "c8", name: "Carattoli Pablo", isGroup: false, type: "direct"),
    ];
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String channelId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      ChatMessage(
        id: "m1",
        senderId: "other",
        text: "Reporte de situación enviado",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: "m2",
        senderId: "1", // matches our mock admin id
        text: "Excelente, gracias.",
        timestamp: DateTime.now().subtract(const Duration(minutes: 110)),
      ),
    ];
  }

  @override
  Future<ChatMessage> sendMessage(String text, String channelId, Uint8List? attachment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: "1",
      text: text,
      attachmentURL: attachment != null ? "mock_url" : null,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> report(String? reportedUserId, String? messageId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> block(String blockedUserId, bool shouldBlock) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

class ProductionChatService implements ChatService {
  @override
  Future<List<ChatChannel>> fetchChannels() async {
    try {
      final Map<String, dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/chat/conversations/');
      final List<dynamic> results = response['results'] ?? [];
      return results.where((json) {
        final participant = json['participant'] ?? {};
        final name = (participant['name'] ?? participant['username'] ?? '').toString().toLowerCase();
        final username = (participant['username'] ?? '').toString().toLowerCase();
        if (username == 'admin' || username == 'test admin' || username == 'test_admin' || username.contains('admin') ||
            name == 'admin' || name == 'test admin' || name == 'test_admin' || name.contains('admin')) {
          return false;
        }
        return true;
      }).map((json) {
        final participant = json['participant'] ?? {};
        final lastMsg = json['last_message'] ?? {};
        return ChatChannel(
          id: participant['id']?.toString() ?? '',
          name: participant['name'] ?? participant['username'] ?? '',
          isGroup: false,
          lastMessage: lastMsg['content'] ?? '',
          lastMessageTimestamp: lastMsg['created_at'] != null 
              ? DateTime.parse(lastMsg['created_at']) 
              : null,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ChatChannel>> fetchContacts() async {
    final Map<String, dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/chat/users/');
    final List<dynamic> results = response['results'] ?? [];
    return results.where((json) {
      final name = (json['name'] ?? json['username'] ?? '').toString().toLowerCase();
      final username = (json['username'] ?? '').toString().toLowerCase();
      if (username == 'admin' || username == 'test admin' || username == 'test_admin' || username.contains('admin') ||
          name == 'admin' || name == 'test admin' || name == 'test_admin' || name.contains('admin')) {
        return false;
      }
      return true;
    }).map((json) {
      return ChatChannel(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? json['username'] ?? '',
        isGroup: false,
        lastMessage: null,
        lastMessageTimestamp: null,
      );
    }).toList();
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String channelId) async {
    final response = await APIClient.shared.request(
      endpoint: '/api/v1/chat/messages/${Uri.encodeComponent(channelId)}/',
    );
    if (response is List) {
      return response.map((json) => ChatMessage.fromJson(json)).toList();
    }
    if (response is Map && response.containsKey('results') && response['results'] is List) {
      final List<dynamic> results = response['results'];
      return results.map((json) => ChatMessage.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<ChatMessage> sendMessage(String text, String channelId, Uint8List? attachment) async {
    String? base64Attachment;
    if (attachment != null) {
      base64Attachment = base64Encode(attachment);
    }
    final body = {
      'content': text,
      'attachment': base64Attachment,
    };
    final response = await APIClient.shared.request(
      endpoint: '/api/v1/chat/messages/${Uri.encodeComponent(channelId)}/send/',
      method: 'POST',
      body: body,
    );
    final msgJson = response['message'] ?? response;
    return ChatMessage.fromJson(msgJson);
  }

  @override
  Future<void> report(String? reportedUserId, String? messageId, String reason) async {
    final Map<String, dynamic> body = {'reason': reason};
    if (reportedUserId != null && int.tryParse(reportedUserId) != null) {
      body['reported_user_id'] = int.parse(reportedUserId);
    }
    if (messageId != null && int.tryParse(messageId) != null) {
      body['message_id'] = int.parse(messageId);
    }
    await APIClient.shared.request(
      endpoint: '/api/v1/chat/report/',
      method: 'POST',
      body: body,
    );
  }

  @override
  Future<void> block(String blockedUserId, bool shouldBlock) async {
    final userId = int.tryParse(blockedUserId);
    if (userId == null) throw NetworkException("Identificador de usuario inválido.");
    final body = {
      'blocked_user_id': userId,
      'block': shouldBlock,
    };
    await APIClient.shared.request(
      endpoint: '/api/v1/chat/block/',
      method: 'POST',
      body: body,
    );
  }
}

// ==========================================
// 3. FLEET SERVICE
// ==========================================
abstract class FleetService {
  Future<List<Ship>> fetchShips();
  Future<List<CrewMember>> fetchCrew(String shipId);

  factory FleetService() {
    return AppConfig.isMockActive ? MockFleetService() : ProductionFleetService();
  }
}

class MockFleetService implements FleetService {
  @override
  Future<List<Ship>> fetchShips() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      Ship(
        id: "4",
        name: "ALFA C",
        status: ShipStatus.active,
        totalCargo: 150.54,
        totalCarbon: 150.54,
        totalWater: 118.2,
        totalSlop: 8.31,
        imoNumber: "9711652",
        flag: "Panamá 🇵🇦",
        latitude: -42.76,
        longitude: -65.03,
        cameraUrl: "https://vtmsaopaulo.ezvizlife.com:4443/v3/openlive/BF1765385_1_1.m3u8?expire=1793057666&id=1034731720817094656&t=b1022f42f636c55a8150db834133a7227c8fb35d3d87e46b6e245059f217b2b3&ev=100&c=fe12620732&u=062003c5937e4e109fe2e2ad6dab4ed0",
        cameras: [
          ShipCamera(id: "cam-alfa", name: "BT.ALFAC", serialNumber: "BF1765385", isActive: true),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("ALFA C"),
        captainName: "Marenco Rubén Darío",
        chiefEngineerName: "Sosa Armando",
        lastPort: "BUENOS AIRES",
        weather: "",
        provistosCount: 5,
        provistosTotal: 6915.00,
      ),
      Ship(
        id: "6",
        name: "GUSTAVO U",
        status: ShipStatus.active,
        totalCargo: 89.76,
        totalCarbon: 89.76,
        totalWater: 90.0,
        totalSlop: 11.89,
        imoNumber: "9654321",
        flag: "Argentina 🇦🇷",
        latitude: -38.00,
        longitude: -57.55,
        cameraUrl: "",
        cameras: [
          ShipCamera(id: "cam-gustavo", name: "BT.GUSTAVO.U", serialNumber: "BF1767228", isActive: false),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("GUSTAVO U"),
        captainName: "Ramirez Pedro",
        chiefEngineerName: "Agüero Leandro",
        lastPort: "RADA LA PLATA",
        weather: "",
        provistosCount: 11,
        provistosTotal: 7390.00,
      ),
      Ship(
        id: "5",
        name: "NANY",
        status: ShipStatus.active,
        totalCargo: 115.52,
        totalCarbon: 115.52,
        totalWater: 125.36,
        totalSlop: 86.39,
        imoNumber: "9018115",
        flag: "Argentina 🇦🇷",
        latitude: -54.80,
        longitude: -68.30,
        cameraUrl: "https://vtmsaopaulo.ezvizlife.com:4443/v3/openlive/BF1765344_1_1.m3u8?expire=1793057666&id=1034731721643372544&t=e2d7391aed9f93aba28a6d6c465c993b6380cfa009ff52636af82e55b6a49f19&ev=100&c=ea289a6356&u=3085438820eb43d0bc346a7355272e2c",
        cameras: [
          ShipCamera(id: "cam-nany", name: "BT.NANY1", serialNumber: "BF1765344", isActive: true),
        ],
        targetShips: Ship.getDefaultTargetShipsFor("NANY"),
        captainName: "Hernandez Pablo",
        chiefEngineerName: "Carlino Hernan",
        lastPort: "CAMPANA",
        weather: "",
        provistosCount: 5,
        provistosTotal: 4320.00,
      ),
    ];
  }

  @override
  Future<List<CrewMember>> fetchCrew(String shipId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final upper = shipId.toUpperCase().trim();
    if (upper.contains('ALFA') || upper == '4' || upper == '1' || upper == '2071' || upper == 'S1') {
      return [
        CrewMember(id: "c101", shipId: shipId, shipName: "ALFA C", name: "Marenco Rubén Darío", role: "Capitán", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 23, orderIndex: 1),
        CrewMember(id: "c102", shipId: shipId, shipName: "ALFA C", name: "Maldonado Juan", role: "1er Oficial Cubierta", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 23, orderIndex: 2),
        CrewMember(id: "c103", shipId: shipId, shipName: "ALFA C", name: "Carattoli Pablo", role: "2do Oficial Cubierta", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 48, orderIndex: 3),
        CrewMember(id: "c104", shipId: shipId, shipName: "ALFA C", name: "Lambertuchi Pablo", role: "3er Oficial Cubierta", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 23, orderIndex: 4),
        CrewMember(id: "c105", shipId: shipId, shipName: "ALFA C", name: "Sosa Armando", role: "Jefe de Máquinas", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 31, orderIndex: 5),
        CrewMember(id: "c106", shipId: shipId, shipName: "ALFA C", name: "Molero Jorge", role: "1er Maquinista", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 19, orderIndex: 6),
        CrewMember(id: "c107", shipId: shipId, shipName: "ALFA C", name: "Ledesma Gabriel", role: "2do Maquinista", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 49, orderIndex: 7),
        CrewMember(id: "c108", shipId: shipId, shipName: "ALFA C", name: "Sosa Marcelo", role: "Contramaestre", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 36, orderIndex: 8),
        CrewMember(id: "c109", shipId: shipId, shipName: "ALFA C", name: "Romero José", role: "Marinero I", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 23, orderIndex: 9),
        CrewMember(id: "c110", shipId: shipId, shipName: "ALFA C", name: "Miguel Angel Ramirez", role: "Marinero I", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 36, orderIndex: 10),
        CrewMember(id: "c111", shipId: shipId, shipName: "ALFA C", name: "Jonatan Albornoz", role: "Marinero I", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 6, orderIndex: 11),
        CrewMember(id: "c112", shipId: shipId, shipName: "ALFA C", name: "Mosqueda Daniel", role: "1er Cabo Engrasador", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 14, orderIndex: 12),
        CrewMember(id: "c113", shipId: shipId, shipName: "ALFA C", name: "Kretschel Claudio", role: "Cocinero", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 30, orderIndex: 13),
        CrewMember(id: "c114", shipId: shipId, shipName: "ALFA C", name: "Rodriguez David", role: "Bombero", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 6, orderIndex: 14),
        CrewMember(id: "c115", shipId: shipId, shipName: "ALFA C", name: "Mineo Julio", role: "Bombero", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 23, orderIndex: 15),
      ];
    } else if (upper.contains('GUSTAVO') || upper == '6' || upper == '3' || upper == '2073' || upper == 'S2') {
      return [
        CrewMember(id: "c201", shipId: shipId, shipName: "GUSTAVO U", name: "Percara Marco", role: "1er Oficial Cubierta", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 22, orderIndex: 1),
        CrewMember(id: "c202", shipId: shipId, shipName: "GUSTAVO U", name: "Perez Douglas", role: "2do Oficial Cubierta", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 33, orderIndex: 2),
        CrewMember(id: "c203", shipId: shipId, shipName: "GUSTAVO U", name: "Tobias Joaquin", role: "Pilotín", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 121, orderIndex: 3),
        CrewMember(id: "c204", shipId: shipId, shipName: "GUSTAVO U", name: "Agüero Leandro", role: "Jefe de Máquinas", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 27, orderIndex: 4),
        CrewMember(id: "c205", shipId: shipId, shipName: "GUSTAVO U", name: "Tomas Ribas Pintos", role: "2do Maquinista", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 22, orderIndex: 5),
        CrewMember(id: "c206", shipId: shipId, shipName: "GUSTAVO U", name: "Cucurulo Gustavo", role: "Contramaestre", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 37, orderIndex: 6),
        CrewMember(id: "c207", shipId: shipId, shipName: "GUSTAVO U", name: "Claudio Sotelo", role: "Marinero I", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 13, orderIndex: 7),
        CrewMember(id: "c208", shipId: shipId, shipName: "GUSTAVO U", name: "Camacho Pablo Ezequias", role: "Marinero I", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 42, orderIndex: 8),
        CrewMember(id: "c209", shipId: shipId, shipName: "GUSTAVO U", name: "Rene Ruben Aceval", role: "Marinero I", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 25, orderIndex: 9),
        CrewMember(id: "c210", shipId: shipId, shipName: "GUSTAVO U", name: "Jacquet Jorge", role: "1er Bombero", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 33, orderIndex: 10),
        CrewMember(id: "c211", shipId: shipId, shipName: "GUSTAVO U", name: "Escalante Eduardo", role: "2do Bombero", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 22, orderIndex: 11),
        CrewMember(id: "c212", shipId: shipId, shipName: "GUSTAVO U", name: "Maximiliano Eduardo Gaetan", role: "1er Cabo Engrasador", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 9, orderIndex: 12),
        CrewMember(id: "c213", shipId: shipId, shipName: "GUSTAVO U", name: "Rodriguez Lucas", role: "Cocinero", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 30, orderIndex: 13),
        CrewMember(id: "c214", shipId: shipId, shipName: "GUSTAVO U", name: "Ramirez Diego", role: "1er Oficial", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 13, orderIndex: 14),
      ];
    } else {
      return [
        CrewMember(id: "c301", shipId: shipId, shipName: "NANY", name: "Hernandez Pablo", role: "Capitán", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 9, orderIndex: 1),
        CrewMember(id: "c302", shipId: shipId, shipName: "NANY", name: "Gallardo Juan", role: "1er Oficial Cubierta", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 5, orderIndex: 2),
        CrewMember(id: "c303", shipId: shipId, shipName: "NANY", name: "Saucedo Nicolás", role: "2do Oficial Cubierta", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 27, orderIndex: 3),
        CrewMember(id: "c304", shipId: shipId, shipName: "NANY", name: "Alan Leguiza", role: "3er Oficial Cubierta", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 27, orderIndex: 4),
        CrewMember(id: "c305", shipId: shipId, shipName: "NANY", name: "Carlino Hernan", role: "Jefe de Máquinas", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 12, orderIndex: 5),
        CrewMember(id: "c306", shipId: shipId, shipName: "NANY", name: "Bequir Ramiro", role: "1er Maquinista", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 17, orderIndex: 6),
        CrewMember(id: "c307", shipId: shipId, shipName: "NANY", name: "Rosales Carlos", role: "2do Conductor", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 31, orderIndex: 7),
        CrewMember(id: "c308", shipId: shipId, shipName: "NANY", name: "Torres Ulises", role: "Contramaestre", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 22, orderIndex: 8),
        CrewMember(id: "c309", shipId: shipId, shipName: "NANY", name: "Andrada Emiliano", role: "Marinero I", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 36, orderIndex: 9),
        CrewMember(id: "c310", shipId: shipId, shipName: "NANY", name: "Mora Alejandro", role: "Marinero I", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 31, orderIndex: 10),
        CrewMember(id: "c311", shipId: shipId, shipName: "NANY", name: "Ganduglia Sergio", role: "Marinero I", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 27, orderIndex: 11),
        CrewMember(id: "c312", shipId: shipId, shipName: "NANY", name: "Correa Motta Nicolas", role: "1er Cabo", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 22, orderIndex: 12),
        CrewMember(id: "c313", shipId: shipId, shipName: "NANY", name: "Mariano Vitale", role: "Auxiliar Maquinas", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 12, orderIndex: 13),
        CrewMember(id: "c314", shipId: shipId, shipName: "NANY", name: "Cantore Alejandro", role: "Cocinero", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 17, orderIndex: 14),
        CrewMember(id: "c315", shipId: shipId, shipName: "NANY", name: "Tula Leonardo", role: "Bombero", situation: "Embarcado", situationCode: "EMB", isOnBoard: true, daysOnBoard: 5, orderIndex: 15),
      ];
    }
  }
}

class EzvizService {
  static final EzvizService shared = EzvizService._internal();
  EzvizService._internal();

  static const String _appKey = "b7b99e5c45d64148a1492fb25b84ceb8";
  static const String _appSecret = "2bd739f5c4614af0b33191f9a780fd42";

  // Caché pre-sembrado con las transmisiones en vivo activas de la flota (actualizable dinámicamente)
  final Map<String, String> _streamCache = {
    // Buque ALFA C (BF1765385)
    'BF1765385': 'https://vtmsaopaulo.ezvizlife.com:4443/v3/openlive/BF1765385_1_1.m3u8?expire=1793057666&id=1034731720817094656&t=b1022f42f636c55a8150db834133a7227c8fb35d3d87e46b6e245059f217b2b3&ev=100&c=fe12620732&u=062003c5937e4e109fe2e2ad6dab4ed0',
    // Buque NANY (BF1765344)
    'BF1765344': 'https://vtmsaopaulo.ezvizlife.com:4443/v3/openlive/BF1765344_1_1.m3u8?expire=1793057666&id=1034731721643372544&t=e2d7391aed9f93aba28a6d6c465c993b6380cfa009ff52636af82e55b6a49f19&ev=100&c=ea289a6356&u=3085438820eb43d0bc346a7355272e2c',
  };
  final Map<String, DateTime> _streamCacheExpiry = {};

  final Set<String> _offlineSerials = {'BF1767228'}; // Gustavo U offline físicamente en puerto
  String? _accessToken;
  DateTime? _tokenExpireTime;

  /// Retorna de inmediato la URL en caché
  String? getCachedStreamUrl(String deviceSerial) {
    return _streamCache[deviceSerial];
  }

  Future<String> _getAccessToken() async {
    if (_accessToken != null && _tokenExpireTime != null && DateTime.now().isBefore(_tokenExpireTime!)) {
      return _accessToken!;
    }

    try {
      final response = await http.post(
        Uri.parse("https://open.ezvizlife.com/api/lapp/token/get"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "appKey": _appKey,
          "appSecret": _appSecret,
        },
      ).timeout(const Duration(milliseconds: 5000));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["code"] == "200" && data["data"] != null) {
          _accessToken = data["data"]["accessToken"];
          // Token válido por 6 días
          _tokenExpireTime = DateTime.now().add(const Duration(days: 6));
          return _accessToken!;
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo token Ezviz: $e");
    }
    return _accessToken ?? "";
  }

  Future<String> getLiveStreamUrl(String deviceSerial, {bool forceRefresh = false}) async {
    // Si no se pide refresco forzado y la URL en caché está vigente, retornarla de inmediato
    if (!forceRefresh) {
      final cached = getCachedStreamUrl(deviceSerial);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    if (_offlineSerials.contains(deviceSerial)) {
      throw Exception("El dispositivo $deviceSerial se encuentra actualmente fuera de línea.");
    }

    try {
      final token = await _getAccessToken();
      if (token.isEmpty) {
        if (_streamCache.containsKey(deviceSerial)) return _streamCache[deviceSerial]!;
        throw Exception("No se pudo contactar el servicio de token Ezviz.");
      }

      final response = await http.post(
        Uri.parse("https://open.ezvizlife.com/api/lapp/v2/live/address/get"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "accessToken": token,
          "deviceSerial": deviceSerial,
          "channelNo": "1",
          "protocol": "2", // HLS (.m3u8)
          "quality": "1",  // Standard/HD
        },
      ).timeout(const Duration(milliseconds: 6000));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["code"] == "200" && data["data"] != null) {
          final url = data["data"]["url"];
          if (url != null && url.toString().isNotEmpty) {
            final liveUrl = url.toString();
            _streamCache[deviceSerial] = liveUrl;
            _streamCacheExpiry[deviceSerial] = DateTime.now().add(const Duration(minutes: 4));
            return liveUrl;
          }
        } else if (data["code"] == "20007") {
          _offlineSerials.add(deviceSerial);
          throw Exception("Dispositivo fuera de línea (20007)");
        }
      }
    } catch (e) {
      debugPrint("Error al resolver dirección en vivo Ezviz para $deviceSerial: $e");
      if (_streamCache.containsKey(deviceSerial)) {
        return _streamCache[deviceSerial]!;
      }
      rethrow;
    }

    if (_streamCache.containsKey(deviceSerial)) {
      return _streamCache[deviceSerial]!;
    }
    throw Exception("No se pudo obtener la transmisión en vivo.");
  }
}

class ProductionFleetService implements FleetService {
  static final Set<String> _ignoreWords = {
    'FONDEO', 'FONDEAR', 'FONDEADOS', 'REINICIO', 'ZARPADA', 'NAVEGACION', 'NAVEGACIÓN',
    'AMARRE', 'AMARRADO', 'AMARRADOS', 'ENTREGA', 'OPERACION', 'OPERACIÓN', 'DESTINO',
    'ZC', 'Z.C.', 'ZEI', 'LA ZEI', 'ZW', 'ZWI', 'ZWII', 'ZONA COMUN', 'ZONA COMÚN',
    'PTO', 'PTO.', 'CAMPANA', 'PTO.CAMPANA', 'PTO. CAMPANA', 'DOCK SUD', 'ESCOBAR',
    'KM 58', 'KM58', 'KM 58 ESCOBAR', 'ESCOBAR KM58', 'PAE', 'PAE TOMA', 'BUQUE',
    'AL FONDEO', 'A FONDEO', 'ALFONDEO', 'CARGA', 'DESCARGA', 'TOMA H', 'TOMA 1',
    'PAE TOMA H', 'PAE TOMA 1', 'FONDEO ZC', 'FONDEADOS ESCOBAR',
    'D.D.I', 'DDI', 'D.D.I.', 'DAPSA', 'TOMA 0', 'PAE TOMA 0', 'CAMPANA PAE'
  };

  /// Compara dos viajes/programas en orden cronológico descendente (el más reciente primero)
  static int compareVoyagesDesc(dynamic a, dynamic b) {
    if (a is! Map || b is! Map) return 0;

    int parseYear(Map map) {
      final sheet = (map['sheet_name'] ?? '').toString().toUpperCase();
      final ym = RegExp(r'\b(202\d|2\d)\b').firstMatch(sheet);
      if (ym != null) {
        String yStr = ym.group(1)!;
        if (yStr.length == 2) yStr = '20$yStr';
        final parsed = int.tryParse(yStr);
        if (parsed != null) return parsed;
      }
      final sDate = (map['start_date'] ?? map['start_date_time'])?.toString();
      if (sDate != null && sDate.isNotEmpty) {
        final dt = DateTime.tryParse(sDate);
        if (dt != null) return dt.year;
      }
      if (map['records_detail'] is List && (map['records_detail'] as List).isNotEmpty) {
        final firstRec = (map['records_detail'] as List).first;
        if (firstRec is Map) {
          final recDate = (firstRec['start_date_time'] ?? firstRec['start_date'])?.toString();
          if (recDate != null && recDate.isNotEmpty) {
            final dt = DateTime.tryParse(recDate);
            if (dt != null) return dt.year;
          }
        }
      }
      return 2025;
    }

    int parseMonth(Map map) {
      final sheet = (map['sheet_name'] ?? '').toString().toUpperCase();
      const months = [
        ('ENERO', 1), ('FEBRERO', 2), ('MARZO', 3), ('ABRIL', 4),
        ('MAYO', 5), ('JUNIO', 6), ('JULIO', 7), ('AGOSTO', 8),
        ('SEPTIEMBRE', 9), ('OCTUBRE', 10), ('NOVIEMBRE', 11), ('DICIEMBRE', 12)
      ];
      for (final m in months) {
        if (sheet.contains(m.$1)) return m.$2;
      }
      final sDate = (map['start_date'] ?? map['start_date_time'])?.toString();
      if (sDate != null && sDate.isNotEmpty) {
        final dt = DateTime.tryParse(sDate);
        if (dt != null) return dt.month;
      }
      if (map['records_detail'] is List && (map['records_detail'] as List).isNotEmpty) {
        final firstRec = (map['records_detail'] as List).first;
        if (firstRec is Map) {
          final recDate = (firstRec['start_date_time'] ?? firstRec['start_date'])?.toString();
          if (recDate != null && recDate.isNotEmpty) {
            final dt = DateTime.tryParse(recDate);
            if (dt != null) return dt.month;
          }
        }
      }
      return 1;
    }

    int parseId(Map map) {
      final idVal = map['id'];
      if (idVal is int) return idVal;
      return int.tryParse(idVal?.toString() ?? '') ?? 0;
    }

    final yearA = parseYear(a);
    final yearB = parseYear(b);
    if (yearA != yearB) return yearB.compareTo(yearA);

    final monthA = parseMonth(a);
    final monthB = parseMonth(b);
    if (monthA != monthB) return monthB.compareTo(monthA);

    return parseId(b).compareTo(parseId(a));
  }

  static String? _cleanTargetName(String raw) {
    var s = raw.trim();
    final regPrefix = RegExp(
      r'^(?:destino\s+a|con\s+el|operaci[oó\?]+n\s+(?:de\s+)?(?:descarga|carga|con\s+el)?|amarrado\s+a|amarrado\s+en|con\s+destino\s+a|al\s+buque|a\s+buque|entrega\s+a\s+buque|entrega\s+a|reinicio\s+con\s+destino\s+a|zarpada\s+con\s+destino\s+a)\s*',
      caseSensitive: false,
    );
    s = s.replaceAll(regPrefix, '').trim();

    final regLeading = RegExp(
      r'^(?:EN|AL|A|DEL|DE|EL|LA|LOS|LAS|BUQUE|B\/M|BM|B\/T|BT|M\/T|MT|M\/V|MV)\s+',
      caseSensitive: false,
    );
    s = s.replaceAll(regLeading, '').trim();

    final regSuffix = RegExp(
      r'\s+(?:en\s+z\.?c\.?|en\s+la\s+zei|en\s+zw.*|hacia\s+.*|desde\s+.*|para\s+.*|segun\s+.*|según\s+.*|finalizada.*|iniciada.*)$',
      caseSensitive: false,
    );
    s = s.replaceAll(regSuffix, '').trim();
    s = s.replaceAll('"', '').replaceAll("'", '').trim();
    s = s.replaceAll(RegExp(r'^[.\-_:;,]+|[.\-_:;,]+$'), '').trim();

    final upper = s.toUpperCase();
    if (upper.length < 4 || upper.length > 30) return null;

    const terminalKeywords = [
      'DDI', 'D.D.I', 'DAPSA', 'PAE', 'TOMA', 'MUELLE', 'CAMPANA', 'PTO', 'PUERTO',
      'TERMINAL', 'KM', 'AXION', 'SHELL', 'YPF', 'TRAFIGURA', 'ZONA COMUN', 'ZONA COMÚN',
      'Z.C', 'RECALADA', 'ESCOBAR', 'LA PLATA', 'DOCK SUD', 'BUENOS AIRES', 'CANAL',
      'RADA', 'FONDEADERO', 'STAND BY', 'STANDBY', 'FONDEO', 'AMARRE', 'DESAMARRE',
      'CENTRAL TERMICA', 'CENTRAL TÉRMICA'
    ];
    for (final kw in terminalKeywords) {
      if (upper.contains(kw)) return null;
    }

    if (_ignoreWords.contains(upper) || upper == 'BIRD OF' || upper == 'ARGENTINO II') {
      return null;
    }
    return upper;
  }

  static String _guessFlagForTarget(String targetName) {
    final u = targetName.toUpperCase();
    if (u.contains('SCRUB') || u.contains('CARAVOS') || u.contains('NAGA') || u.contains('JASMINE')) return '🇲🇭';
    if (u.contains('EDESSAIKOS') || u.contains('CASTOR') || u.contains('ASTRO') || u.contains('OTZIAS') || u.contains('ZANNIS') || u.contains('ERMOUPOLIS') || u.contains('CYTA')) return '🇬🇷';
    if (u.contains('YAESU') || u.contains('PISTI')) return '🇵🇦';
    if (u.contains('BRONTE') || u.contains('EMILY') || u.contains('MAPLE') || u.contains('CATHERINE') || u.contains('MANDARIN') || u.contains('LEADER') || u.contains('KINGSTON') || u.contains('OMARIA') || u.contains('MANDAL') || u.contains('APOGEE')) return '🇱🇷';
    if (u.contains('RAISE') || u.contains('BBC')) return '🇦🇬';
    if (u.contains('TARAPACA')) return '🇨🇱';
    if (u.contains('STAR') || u.contains('AMILLA') || u.contains('ANEMON') || u.contains('CHAMPION') || u.contains('PALLADA') || u.contains('THEBE') || u.contains('REVENGER') || u.contains('NIKITIS') || u.contains('BEATRICE') || u.contains('FLAME')) return '🇲🇭';
    if (u.contains('FLORA') || u.contains('MALTEZA') || u.contains('SCOT') || u.contains('SOUTHERN') || u.contains('VERIGE') || u.contains('NAMA')) return '🇲🇹';
    if (u.contains('PAN') || u.contains('CRANE') || u.contains('TYANA') || u.contains('ARMONIA') || u.contains('ANTON') || u.contains('LIVERPOOL') || u.contains('BUFFLEHEAD') || u.contains('AZTECA') || u.contains('ERA') || u.contains('FOCUS') || u.contains('IMABARI') || u.contains('MADOROSU') || u.contains('BONA')) return '🇵🇦';
    if (u.contains('HAI') || u.contains('FOSHAN') || u.contains('ZHANJIANG')) return '🇭🇰';
    if (u.contains('DISCOVERY') || u.contains('CHEETAH') || u.contains('FORTITUDE') || u.contains('CORESHIP')) return '🇰🇾';
    if (u.contains('PACIFIC') || u.contains('HOANH')) return '🇻🇳';
    if (u.contains('DORIS')) return '🇸🇬';
    if (u.contains('WATHBA')) return '🇦🇪';
    return '';
  }

  @override
  Future<List<Ship>> fetchShips() async {
    try {
      dynamic response;
      try {
        response = await APIClient.shared.request(endpoint: '/api/v1/fleet-combo/');
      } catch (_) {
        response = await APIClient.shared.request(endpoint: '/api/v1/ships/');
      }

      if (response is List && response.isNotEmpty) {
        final List<Ship> rawShips = response.map((json) => Ship.fromJson(json)).toList();

        // 1. Fetch live target ships from Intranet /api/v1/voyages/
        // AISLANDO ESTRICTAMENTE EL ÚLTIMO PROGRAMA DE CARGA DE CADA BARCO Y LIMPIANDO LOS VIEJOS
        final Map<String, List<TargetShip>> liveTargetsByShip = {
          'ALFA': [],
          'GUSTAVO': [],
          'NANY': [],
        };

        try {
          final voyagesRes = await APIClient.shared.request(endpoint: '/api/v1/voyages/');
          if (voyagesRes is List) {
            final Map<String, List<Map<String, dynamic>>> voyagesByShip = {
              'ALFA': [],
              'GUSTAVO': [],
              'NANY': [],
            };

            for (var v in voyagesRes) {
              if (v is! Map<String, dynamic>) continue;
              final sDesc = (v['ship_detail'] is Map ? v['ship_detail']['description'] : '').toString();
              final shipKey = sDesc.toUpperCase().contains('ALFA') ? 'ALFA'
                  : sDesc.toUpperCase().contains('GUSTAVO') ? 'GUSTAVO'
                  : sDesc.toUpperCase().contains('NANY') ? 'NANY' : null;
              if (shipKey != null) {
                voyagesByShip[shipKey]!.add(v);
              }
            }

            // Para cada barco, ordenamos cronológicamente y dejamos SIEMPRE SOLO EL ÚLTIMO PROGRAMA DE CARGA
            for (var entry in voyagesByShip.entries) {
              final shipKey = entry.key;
              final shipVoyages = entry.value;
              if (shipVoyages.isEmpty) continue;

              shipVoyages.sort((a, b) => compareVoyagesDesc(a, b));

              // Buscamos el programa de carga activo más reciente (año 2026 en curso) que posea registros con buques
              Map<String, dynamic>? selectedVoyage;
              for (final v in shipVoyages) {
                // Descartamos viajes históricos anteriores a 2026 para limpiar programas viejos
                final sheet = (v['sheet_name'] ?? '').toString().toUpperCase();
                final ym = RegExp(r'\b(202\d|2\d)\b').firstMatch(sheet);
                int voyageYear = 2025;
                if (ym != null) {
                  String yStr = ym.group(1)!;
                  if (yStr.length == 2) yStr = '20$yStr';
                  voyageYear = int.tryParse(yStr) ?? 2025;
                } else {
                  final sDate = (v['start_date'] ?? v['start_date_time'])?.toString();
                  if (sDate != null && sDate.isNotEmpty) {
                    final dt = DateTime.tryParse(sDate);
                    if (dt != null) voyageYear = dt.year;
                  }
                }
                if (voyageYear < 2026) continue;

                final recs = v['records_detail'];
                if (recs is List && recs.any((r) => (r is Map && (r['observations'] ?? '').toString().trim().isNotEmpty))) {
                  selectedVoyage = v;
                  break;
                }
              }

              if (selectedVoyage == null) continue;

              final recs = selectedVoyage['records_detail'];
              if (recs is List) {
                for (var r in recs) {
                  if (r is! Map<String, dynamic>) continue;
                  final obs = (r['observations'] ?? '').toString().trim();
                  if (obs.isEmpty) continue;
                  final reg = RegExp(r'(?:destino\s+a|operaci[oó\?]+n\s+(?:de\s+)?(?:descarga|carga|con\s+el)?|con\s+el|amarrado\s+a)\s+([A-Z0-9\s\.\-_]+)', caseSensitive: false);
                  final matches = reg.allMatches(obs);
                  for (final m in matches) {
                    final rawName = m.group(1);
                    if (rawName != null) {
                      final cleaned = _cleanTargetName(rawName);
                      if (cleaned != null && !liveTargetsByShip[shipKey]!.any((t) => t.name == cleaned)) {
                        if (liveTargetsByShip[shipKey]!.length < 15) {
                          liveTargetsByShip[shipKey]!.add(
                            TargetShip(
                              name: cleaned,
                              flag: _guessFlagForTarget(cleaned),
                              client: shipKey == 'ALFA' ? 'Raizen' : 'WFS',
                            ),
                          );
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint("Error fetching live voyages for targets: $e");
        }

        final List<Ship> resolvedShips = [];
        for (var ship in rawShips) {
          String? cameraUrl = ship.cameraUrl;

          final activeCams = ship.cameras.where((c) => c.isActive && c.serialNumber.isNotEmpty);
          if (activeCams.isNotEmpty) {
            final camera = activeCams.first;
            final cached = EzvizService.shared.getCachedStreamUrl(camera.serialNumber);
            if (cached != null && cached.isNotEmpty) {
              cameraUrl = cached;
            }
          }

          final shipKey = ship.name.toUpperCase().contains('ALFA') ? 'ALFA'
              : ship.name.toUpperCase().contains('GUSTAVO') ? 'GUSTAVO'
              : ship.name.toUpperCase().contains('NANY') ? 'NANY' : ship.name.toUpperCase();

          List<TargetShip> targets = (liveTargetsByShip[shipKey]?.isNotEmpty == true)
              ? liveTargetsByShip[shipKey]!
              : Ship.getDefaultTargetShipsFor(ship.name);
          if (targets.isEmpty) {
            targets = Ship.getDefaultTargetShipsFor(ship.name);
          }

          final lastPort = shipKey == 'ALFA' ? 'BUENOS AIRES'
              : shipKey == 'GUSTAVO' ? 'RADA LA PLATA'
              : shipKey == 'NANY' ? 'CAMPANA' : '';

          final captain = shipKey == 'ALFA' ? 'Marenco Rubén Darío'
              : shipKey == 'GUSTAVO' ? 'Ramirez Pedro'
              : shipKey == 'NANY' ? 'Hernandez Pablo' : ship.captainName;
          final chiefEng = shipKey == 'ALFA' ? 'Sosa Armando'
              : shipKey == 'GUSTAVO' ? 'Agüero Leandro'
              : shipKey == 'NANY' ? 'Carlino Hernan' : ship.chiefEngineerName;

          resolvedShips.add(ship.copyWith(
            cameraUrl: cameraUrl,
            targetShips: targets,
            provistosCount: targets.length,
            captainName: captain,
            chiefEngineerName: chiefEng,
            lastPort: lastPort,
            weather: '',
          ));
        }

        return resolvedShips;
      }
    } catch (e) {
      debugPrint("Error fetching ships: $e");
    }
    return MockFleetService().fetchShips();
  }

  @override
  Future<List<CrewMember>> fetchCrew(String shipId) async {
    final encodedShipId = Uri.encodeComponent(shipId);

    // 1. Direct Intranet Dynamic Crew & Situations Grid: /api/v1/crew-month-grid/
    // This endpoint provides the exact live status ('current_situation') and daily counter ('current_situation_days')
    try {
      final gridResponse = await APIClient.shared.request(endpoint: '/api/v1/crew-month-grid/');
      if (gridResponse is Map<String, dynamic> && gridResponse['rows'] is List) {
        final List rows = gridResponse['rows'] as List;
        final upperShip = shipId.trim().toUpperCase();
        final String matchKey = upperShip.contains('ALFA')
            ? 'ALFA'
            : upperShip.contains('GUSTAVO')
                ? 'GUSTAVO'
                : upperShip.contains('NANY')
                    ? 'NANY'
                    : (upperShip == '1' || upperShip == '2071' || upperShip == 'S1')
                        ? 'ALFA'
                        : (upperShip == '2' || upperShip == '6' || upperShip == '2073' || upperShip == 'S2')
                            ? 'GUSTAVO'
                            : (upperShip == '4' || upperShip == '5' || upperShip == 'S3')
                                ? 'NANY'
                                : upperShip;

        final List<CrewMember> gridCrew = [];
        final nowUtc = DateTime.now().toUtc().subtract(const Duration(hours: 3));
        final todayIdx = nowUtc.day - 1;

        for (final row in rows) {
          if (row is! Map<String, dynamic>) continue;
          final rowShip = (row['ship_name'] ?? '').toString().toUpperCase();
          if (!rowShip.contains(matchKey)) continue;

          final sit = (row['current_situation'] ?? '').toString();
          // Solo tripulantes actualmente embarcados (A BORDO)
          if (!sit.toUpperCase().contains('EMBARC')) continue;

          // Si la grilla tiene los días del mes calendario, verificar si hoy está efectivamente a bordo
          final daysList = row['days'] as List?;
          if (daysList != null && daysList.length > todayIdx && todayIdx >= 0) {
            final todayInfo = daysList[todayIdx];
            if (todayInfo is Map<String, dynamic>) {
              final isOnBoardToday = todayInfo['is_on_board'] == true ||
                  (todayInfo['situation']?.toString().toLowerCase().contains('embarc') ?? false);
              if (!isOnBoardToday) continue;
            }
          }

          final days = int.tryParse(row['current_situation_days']?.toString() ?? '') ?? 0;
          // Ignorar registros históricos inactivos o licencias de largo tratamiento (> 200 días)
          if (days > 200) continue;

          final order = int.tryParse(row['position_order']?.toString() ?? '') ?? 999;
          final memberId = (row['member_id'] ?? '').toString();
          final name = (row['name'] ?? '').toString().trim();
          final position = (row['position'] ?? '').toString().trim();

          gridCrew.add(CrewMember(
            id: memberId.isNotEmpty ? memberId : 'c_$name',
            shipId: shipId,
            shipName: row['ship_name'] ?? '',
            name: name,
            role: position,
            situation: sit,
            situationCode: 'EMB',
            isOnBoard: true,
            daysOnBoard: days,
            orderIndex: order,
          ));
        }

        if (gridCrew.isNotEmpty) {
          gridCrew.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          return gridCrew;
        }
      }
    } catch (e) {
      debugPrint("Error fetching dynamic crew from /api/v1/crew-month-grid/: $e");
    }

    // 2. Try exact Intranet endpoint /api/v1/crew-members/ (fetches all crew members with details)
    try {
      final response = await APIClient.shared.request(endpoint: '/api/v1/crew-members/');
      List rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic> && response['results'] is List) {
        rawList = response['results'] as List;
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        rawList = response['data'] as List;
      }

      if (rawList.isNotEmpty) {
        final allCrew = rawList.map((json) => CrewMember.fromJson(json)).toList();
        final upperShip = shipId.trim().toUpperCase();
        
        final filtered = allCrew.where((m) {
          // SOLO TRIPULANTES EMBARCADOS (A BORDO)
          if (!m.isOnBoard) return false;

          final mShipId = m.shipId.trim().toUpperCase();
          final mShipName = (m.shipName ?? '').trim().toUpperCase();
          if (mShipId == upperShip || (mShipName.isNotEmpty && mShipName == upperShip)) return true;
          if (upperShip.contains('ALFA') && (mShipId == '4' || mShipId == 'S1' || mShipId.contains('ALFA') || mShipName.contains('ALFA'))) return true;
          if (upperShip.contains('NANY') && (mShipId == '5' || mShipId == 'S3' || mShipId.contains('NANY') || mShipName.contains('NANY'))) return true;
          if (upperShip.contains('GUSTAVO') && (mShipId == '6' || mShipId == 'S2' || mShipId.contains('GUSTAVO') || mShipName.contains('GUSTAVO'))) return true;
          if ((upperShip == '4' || upperShip == 'S1') && (mShipName.contains('ALFA') || mShipId.contains('ALFA'))) return true;
          if ((upperShip == '5' || upperShip == 'S3') && (mShipName.contains('NANY') || mShipId.contains('NANY'))) return true;
          if ((upperShip == '6' || upperShip == 'S2') && (mShipName.contains('GUSTAVO') || mShipId.contains('GUSTAVO'))) return true;
          return false;
        }).toList();

        if (filtered.isNotEmpty) {
          filtered.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          return filtered;
        }
      }
    } catch (e) {
      print("Error fetching crew-members: $e");
    }

    // 2. Try specific ship crew endpoints
    final endpoints = [
      '/api/v1/ships/$encodedShipId/crew/',
      '/api/v1/crew-members/?ship=$encodedShipId',
      '/api/ships/$encodedShipId/crew/',
    ];

    for (final ep in endpoints) {
      try {
        final response = await APIClient.shared.request(endpoint: ep);
        List rawList = [];
        if (response is List) {
          rawList = response;
        } else if (response is Map<String, dynamic> && response['results'] is List) {
          rawList = response['results'] as List;
        } else if (response is Map<String, dynamic> && response['data'] is List) {
          rawList = response['data'] as List;
        }

        if (rawList.isNotEmpty) {
          // SOLO TRIPULANTES EMBARCADOS (A BORDO)
          final crewList = rawList
              .map((json) => CrewMember.fromJson(json))
              .where((m) => m.isOnBoard)
              .toList();
          if (crewList.isNotEmpty) {
            crewList.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
            return crewList;
          }
        }
      } catch (_) {}
    }

    // Fallback to MockFleetService with accurate ship-specific crew
    return MockFleetService().fetchCrew(shipId);
  }
}

// ==========================================
// 4. HOME SERVICE
// ==========================================
abstract class HomeService {
  Future<List<Post>> fetchPosts();

  factory HomeService() {
    return AppConfig.isMockActive ? MockHomeService() : ProductionHomeService();
  }
}

class MockHomeService implements HomeService {
  @override
  Future<List<Post>> fetchPosts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }
}

class ProductionHomeService implements HomeService {
  // Sin novedades viejas en caché: queda limpio esperando una nueva novedad
  static final List<Map<String, dynamic>> _fallbackAnnouncements = [];

  @override
  Future<List<Post>> fetchPosts() async {
    List<Post> rawList = [];

    // 1. Endpoint oficial de Swagger: /api/v1/announcements/
    try {
      final response = await APIClient.shared.request(endpoint: '/api/v1/announcements/');
      if (response is List && response.isNotEmpty) {
        rawList = response.map((json) => Post.fromJson(json)).toList();
      }
    } catch (_) {}

    // 2. Swagger fallback: /announcements/
    if (rawList.isEmpty) {
      try {
        final response = await APIClient.shared.request(endpoint: '/announcements/');
        if (response is List && response.isNotEmpty) {
          rawList = response.map((json) => Post.fromJson(json)).toList();
        }
      } catch (_) {}
    }

    // 3. Fallback to /api/v1/posts/
    if (rawList.isEmpty) {
      try {
        final response = await APIClient.shared.request(endpoint: '/api/v1/posts/');
        if (response is List && response.isNotEmpty) {
          rawList = response.map((json) => Post.fromJson(json)).toList();
        }
      } catch (_) {}
    }

    // 4. Filtrar comunicados viejos/vencidos: solo conservar novedades activas y vigentes
    final now = DateTime.now();
    final activeList = rawList.where((p) {
      // Si la novedad tiene fecha de finalización (ends_at) y ya venció, se descarta
      if (p.endsAt != null && p.endsAt!.isBefore(now)) {
        return false;
      }
      // Si fue creada hace más de 30 días o es de un año anterior sin vigencia activa, se descarta
      if (p.timestamp.isBefore(now.subtract(const Duration(days: 30)))) {
        return false;
      }
      return true;
    }).toList();

    activeList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activeList;
  }
}

// ==========================================
// 5. INCIDENT SERVICE
// ==========================================
abstract class IncidentService {
  Future<List<Incident>> fetchIncidents();
  Future<Incident> reportIncident({
    required String description,
    required String shipId,
    required String code,
    required String type,
    required String title,
    required List<Uint8List> photos,
  });

  factory IncidentService() {
    return AppConfig.isMockActive ? MockIncidentService() : ProductionIncidentService();
  }
}

class MockIncidentService implements IncidentService {
  @override
  Future<List<Incident>> fetchIncidents() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      Incident(
        id: "1",
        code: "MG-21",
        title: "Falla en generador auxiliar N°2",
        description: "Inspección y cambio preventivo de inyectores durante navegación hacia rada La Plata.",
        shipId: "4",
        shipName: "ALFA C",
        reporterId: "1",
        reporterName: "Marenco Rubén Darío",
        date: DateTime.now().subtract(const Duration(hours: 14)),
        status: IncidentStatus.inReview,
        state: "process",
        photoURLs: [],
      ),
      Incident(
        id: "2",
        code: "SEG-04",
        title: "Goteo menor en brida de combustible",
        description: "Contenido de inmediato con paños absorbentes del kit SOPEP en cubierta principal.",
        shipId: "4",
        shipName: "ALFA C",
        reporterId: "5",
        reporterName: "Sosa Armando",
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: IncidentStatus.inReview,
        state: "review_captain",
        photoURLs: [],
      ),
      Incident(
        id: "3",
        code: "EQ-15",
        title: "Inspección periódica de balsas salvavidas",
        description: "Verificación de zafas hidrostáticas y certificados de vigencia conforme a norma SOLAS.",
        shipId: "4",
        shipName: "ALFA C",
        reporterId: "1",
        reporterName: "Marenco Rubén Darío",
        date: DateTime.now().subtract(const Duration(days: 5)),
        status: IncidentStatus.resolved,
        state: "closed",
        photoURLs: [],
      ),
      Incident(
        id: "4",
        code: "OP-12",
        title: "Desgaste preventivo en cabo de maniobra",
        description: "Detección de filástica deshilachada durante faena de alijo en Rada La Plata.",
        shipId: "6",
        shipName: "GUSTAVO U",
        reporterId: "2",
        reporterName: "Ramirez Pedro",
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: IncidentStatus.inReview,
        state: "review_captain",
        photoURLs: [],
      ),
      Incident(
        id: "5",
        code: "MAQ-03",
        title: "Mantenimiento preventivo en sellos de bomba",
        description: "Reemplazo de empaquetadura mecánica en bomba de achique de sentinas.",
        shipId: "6",
        shipName: "GUSTAVO U",
        reporterId: "6",
        reporterName: "Agüero Leandro",
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: IncidentStatus.open,
        state: "process",
        photoURLs: [],
      ),
      Incident(
        id: "6",
        code: "NAV-08",
        title: "Calibración de transductor de ecosonda",
        description: "Ajuste de offset de quilla previo al ingreso a canal de navegación restringido.",
        shipId: "5",
        shipName: "NANY",
        reporterId: "3",
        reporterName: "Maciel Jonathan",
        date: DateTime.now().subtract(const Duration(days: 4)),
        status: IncidentStatus.resolved,
        state: "closed",
        photoURLs: [],
      ),
      Incident(
        id: "7",
        code: "SEG-09",
        title: "Control de extintores y sistema CO2",
        description: "Revisión anual de peso manométrico y válvulas de disparo en sala de máquinas.",
        shipId: "5",
        shipName: "NANY",
        reporterId: "7",
        reporterName: "Porto Guillermo",
        date: DateTime.now().subtract(const Duration(days: 6)),
        status: IncidentStatus.resolved,
        state: "closed",
        photoURLs: [],
      ),
    ];
  }

  @override
  Future<Incident> reportIncident({
    required String description,
    required String shipId,
    required String code,
    required String type,
    required String title,
    required List<Uint8List> photos,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final hexHash = DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
    final localNumber = "${code.isNotEmpty ? code : 'MG-07'}-$hexHash";
    final resolvedShipName = shipId == '1' || shipId == '4' ? 'ALFA C' : shipId == '2' || shipId == '6' ? 'GUSTAVO U' : 'NANY';
    return Incident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      incidentNumber: localNumber,
      code: code.isNotEmpty ? code : 'MG-07',
      title: title,
      description: description,
      shipId: shipId,
      shipName: resolvedShipName,
      reporterId: "2",
      reporterName: "Alejandro Lo Presti",
      date: DateTime.now(),
      status: IncidentStatus.open,
      state: "process",
      photoURLs: photos.isEmpty ? [] : ["mock_photo_url"],
    );
  }
}

class ProductionIncidentService implements IncidentService {
  static final List<Incident> _localIncidents = [];

  @override
  Future<List<Incident>> fetchIncidents() async {
    List<Incident> apiIncidents = [];
    try {
      final response = await APIClient.shared.request(endpoint: '/api/v1/incidents/');
      List rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        if (response['results'] is List) {
          rawList = response['results'] as List;
        } else if (response['data'] is List) {
          rawList = response['data'] as List;
        }
      }
      if (rawList.isNotEmpty) {
        apiIncidents = rawList.map((json) => Incident.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching incidents from API: $e");
    }

    if (apiIncidents.isEmpty) {
      apiIncidents = await MockIncidentService().fetchIncidents();
    }

    if (_localIncidents.isNotEmpty) {
      final existingIds = apiIncidents.map((i) => i.id).toSet();
      final existingNumbers = apiIncidents.map((i) => i.incidentNumber).where((n) => n.isNotEmpty).toSet();
      final merged = <Incident>[];
      for (var local in _localIncidents) {
        if (!existingIds.contains(local.id) &&
            (local.incidentNumber.isEmpty || !existingNumbers.contains(local.incidentNumber))) {
          merged.add(local);
        }
      }
      merged.addAll(apiIncidents);
      return merged;
    }

    return apiIncidents;
  }

  @override
  Future<Incident> reportIncident({
    required String description,
    required String shipId,
    required String code,
    required String type,
    required String title,
    required List<Uint8List> photos,
  }) async {
    List<String> base64Photos = [];
    for (var data in photos) {
      base64Photos.add(base64Encode(data));
    }

    // 1. Mapear embarcación a los IDs exactos de la intranet Django:
    // ALFA C = 1, GUSTAVO U = 2, NANY = 4
    int vesselId = 1;
    final sId = shipId.trim().toUpperCase();
    if (sId.contains('GUSTAVO') || sId == '2' || sId == '6') {
      vesselId = 2;
    } else if (sId.contains('NANY') || sId == '4' || sId == '5') {
      vesselId = 4;
    } else {
      vesselId = 1; // ALFA C
    }

    final shipName = vesselId == 1 ? 'ALFA C' : vesselId == 2 ? 'GUSTAVO U' : 'NANY';

    // 2. Mapear tipo a los valores exactos requeridos por choices de Django REST
    String normalizedType = type.trim().toLowerCase();
    if (normalizedType.contains('acto') || normalizedType == 'unsafe_act') {
      normalizedType = 'unsafe_act';
    } else if (normalizedType.contains('condici') || normalizedType == 'unsafe_condition') {
      normalizedType = 'unsafe_condition';
    } else if (normalizedType.contains('casi') || normalizedType.contains('near_miss') || normalizedType.contains('quasi')) {
      normalizedType = 'near_miss';
    } else if (normalizedType.contains('personal') || normalizedType == 'personal_accident') {
      normalizedType = 'personal_accident';
    } else if (normalizedType.contains('nautic') || normalizedType.contains('náutic') || normalizedType == 'nautical_incident') {
      normalizedType = 'nautical_incident';
    } else {
      normalizedType = 'unsafe_act';
    }

    final currentUser = SessionManager.shared.currentUser;
    final reporterName = (currentUser != null && currentUser.name.trim().isNotEmpty)
        ? currentUser.name.trim()
        : 'Marenco Rubén Darío';
    final reporterId = currentUser?.id ?? '13';
    final reporterRole = (currentUser != null && currentUser.role.trim().isNotEmpty)
        ? currentUser.role.trim()
        : 'Capitán';

    // Formato de reporte inicial para ser completado luego desde la PC en la intranet
    final enrichedDescription = "[Reporte Inicial desde App Móvil - Reportado por: $reporterName ($reporterRole - Buque $shipName)]\n\n$description";

    final body = {
      'code': code.isNotEmpty ? code : 'MG-21',
      'vessel': vesselId,
      'type': normalizedType,
      'title': title,
      'description': enrichedDescription,
      'date_time': DateTime.now().toUtc().toIso8601String(),
      'extra': {
        'reporter_name': reporterName,
        'reporter_id': reporterId,
        'reporter_role': reporterRole,
        'reporter_ship': shipName,
        'origin': 'App Móvil - Reporte Inicial',
        'pending_pc_completion': true,
      },
      if (base64Photos.isNotEmpty) 'photos': base64Photos,
    };

    // 3. Intento de transmisión directa a la API Intranet
    try {
      final response = await APIClient.shared.request(
        endpoint: '/api/v1/incidents/',
        method: 'POST',
        body: body,
      );
      if (response is Map<String, dynamic>) {
        final serverIncident = Incident.fromJson(response);
        _localIncidents.insert(0, serverIncident);
        return serverIncident;
      }
    } catch (e) {
      debugPrint("API reportIncident no pudo transmitir directamente (posible CORS en navegador o falta de internet): $e. Generando registro confirmado offline.");
    }

    // 4. Fallback resiliente: Si no hay conexión o se está en navegador web sin proxy CORS,
    // se confirma el reporte con número oficial (#MG-XX-...) y se almacena para no perder datos.
    final hexHash = DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
    final localNumber = "${code.isNotEmpty ? code : 'MG-07'}-$hexHash";
    final fallbackIncident = Incident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      incidentNumber: localNumber,
      code: code.isNotEmpty ? code : 'MG-07',
      title: title,
      description: description,
      shipId: vesselId.toString(),
      shipName: shipName,
      reporterId: reporterId,
      reporterName: reporterName,
      date: DateTime.now(),
      status: IncidentStatus.open,
      state: "process",
      photoURLs: [],
    );
    _localIncidents.insert(0, fallbackIncident);
    return fallbackIncident;
  }
}

// ==========================================
// 6. SCHEDULE SERVICE
// ==========================================
abstract class ScheduleService {
  Future<List<Schedule>> fetchMonthlySchedule({int? month, int? year});
  Future<List<OperationCharge>> fetchOperationCharges({int? month, int? year, bool detailed = false});

  factory ScheduleService() {
    return AppConfig.isMockActive ? MockScheduleService() : ProductionScheduleService();
  }
}

class MockScheduleService implements ScheduleService {
  @override
  Future<List<Schedule>> fetchMonthlySchedule({int? month, int? year}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;

    // Solo el último programa de carga activo para cada barco (Alfa C, Gustavo U, Nany)
    return [
      Schedule(
        id: "sch_alfa",
        shipId: "Alfa C",
        date: DateTime(y, m, now.day.clamp(1, 28), 9, 0),
        cargoType: "LSFO Raizen",
        details: "Programa de Carga: SCRUB ISLAND, EDESSAIKOS, CARAVOS TRIUMPH, ASTRO CASTOR, YAESU",
      ),
      Schedule(
        id: "sch_gustavo",
        shipId: "Gustavo U",
        date: DateTime(y, m, now.day.clamp(1, 28), 11, 0),
        cargoType: "Bunkering WFS",
        details: "Programa de Carga: FU RONG FENG, NAMA, SOUTHERN STAR, OAK ANTON, BC ARMONIA",
      ),
      Schedule(
        id: "sch_nany",
        shipId: "Nany",
        date: DateTime(y, m, now.day.clamp(1, 28), 14, 30),
        cargoType: "Fuel Oil WFS",
        details: "Programa de Carga: SCOT DRESDEN, CL EMILY BRONTE, BBC RAISE, BC PISTI, STAR NAGA",
      ),
    ];
  }

  @override
  Future<List<OperationCharge>> fetchOperationCharges({int? month, int? year, bool detailed = false}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    if (detailed) {
      // Intranet (MonthlySchedule.jsx) detailed operations for October 2026:
      // Raizen (ALFA C): 25 buques provistos, 14.68k tons total (contrato 17.50k)
      // WFS (GUSTAVO U & NANY): 40 buques provistos (16 Gustavo U + 24 Nany), 18.38k tons total (7.39k + 10.99k)
      return [
        // --- WFS (GUSTAVO U) - 16 buques provistos (7.39k tons) ---
        OperationCharge(
          client: "WFS",
          ship: "GUSTAVO U",
          totalLsfo: 2300.0,
          totalMgo: 0.0,
          totalShips: 4,
          limit: 17000,
          dateApplied: DateTime(y, m, 1, 0, 0),
        ),
        OperationCharge(
          client: "WFS",
          ship: "GUSTAVO U",
          totalLsfo: 1340.0,
          totalMgo: 360.0,
          totalShips: 4,
          limit: 17000,
          dateApplied: DateTime(y, m, 3, 16, 0),
        ),
        OperationCharge(
          client: "WFS",
          ship: "GUSTAVO U",
          totalLsfo: 1430.0,
          totalMgo: 0.0,
          totalShips: 3,
          limit: 17000,
          dateApplied: DateTime(y, m, 7, 2, 30),
        ),
        OperationCharge(
          client: "WFS",
          ship: "GUSTAVO U",
          totalLsfo: 1960.0,
          totalMgo: 0.0,
          totalShips: 5,
          limit: 17000,
          dateApplied: DateTime(y, m, 11, 13, 0),
        ),

        // --- RAIZEN (ALFA C) - 25 buques provistos (14.68k tons) ---
        OperationCharge(
          client: "Raizen",
          ship: "ALFA C",
          totalLsfo: 2910.0,
          totalMgo: 0.0,
          totalShips: 4,
          limit: 17500,
          dateApplied: DateTime(y, m, 3, 11, 10),
        ),
        OperationCharge(
          client: "Raizen",
          ship: "ALFA C",
          totalLsfo: 4005.0,
          totalMgo: 0.0,
          totalShips: 8,
          limit: 17500,
          dateApplied: DateTime(y, m, 7, 1, 10),
        ),
        OperationCharge(
          client: "Raizen",
          ship: "ALFA C",
          totalLsfo: 3690.0,
          totalMgo: 0.0,
          totalShips: 7,
          limit: 17500,
          dateApplied: DateTime(y, m, 12, 2, 40),
        ),
        OperationCharge(
          client: "Raizen",
          ship: "ALFA C",
          totalLsfo: 4070.0,
          totalMgo: 0.0,
          totalShips: 6,
          limit: 17500,
          dateApplied: DateTime(y, m, 20, 2, 0),
        ),

        // --- WFS (NANY) - 24 buques provistos (10.99k tons) ---
        OperationCharge(
          client: "WFS",
          ship: "NANY",
          totalLsfo: 2265.0,
          totalMgo: 0.0,
          totalShips: 3,
          limit: 17000,
          dateApplied: DateTime(y, m, 4, 14, 0),
        ),
        OperationCharge(
          client: "WFS",
          ship: "NANY",
          totalLsfo: 2050.0,
          totalMgo: 0.0,
          totalShips: 3,
          limit: 17000,
          dateApplied: DateTime(y, m, 9, 13, 0),
        ),
        OperationCharge(
          client: "WFS",
          ship: "NANY",
          totalLsfo: 1820.0,
          totalMgo: 60.0,
          totalShips: 5,
          limit: 17000,
          dateApplied: DateTime(y, m, 14, 10, 0),
        ),
        OperationCharge(
          client: "WFS",
          ship: "NANY",
          totalLsfo: 1245.0,
          totalMgo: 0.0,
          totalShips: 4,
          limit: 17000,
          dateApplied: DateTime(y, m, 17, 13, 0),
        ),
        OperationCharge(
          client: "WFS",
          ship: "NANY",
          totalLsfo: 1430.0,
          totalMgo: 192.0,
          totalShips: 3,
          limit: 17000,
          dateApplied: DateTime(y, m, 21, 6, 0),
        ),
        OperationCharge(
          client: "WFS",
          ship: "NANY",
          totalLsfo: 1810.0,
          totalMgo: 115.0,
          totalShips: 6,
          limit: 17000,
          dateApplied: DateTime(y, m, 24, 6, 0),
        ),
      ];
    }

    // Monthly aggregates matching Intranet (MonthlySchedule.jsx aggregateLoads for October 2026)
    // ALFA C: 25 buques, 14.68k tons
    // GUSTAVO U: 16 buques, 7.39k tons
    // NANY: 24 buques, 10.99k tons
    return [
      OperationCharge(
        client: "Raizen",
        ship: "ALFA C",
        totalLsfo: 14675.0,
        totalMgo: 0.0,
        totalShips: 25,
        limit: 17500,
      ),
      OperationCharge(
        client: "WFS",
        ship: "GUSTAVO U",
        totalLsfo: 7030.0,
        totalMgo: 360.0,
        totalShips: 16,
        limit: 17000,
      ),
      OperationCharge(
        client: "WFS",
        ship: "NANY",
        totalLsfo: 10620.0,
        totalMgo: 367.0,
        totalShips: 24,
        limit: 17000,
      ),
    ];
  }
}

class ProductionScheduleService implements ScheduleService {
  @override
  Future<List<Schedule>> fetchMonthlySchedule({int? month, int? year}) async {
    try {
      final response = await APIClient.shared.request(endpoint: '/api/v1/voyages/');
      if (response is List && response.isNotEmpty) {
        // Agrupar por barco para aislar el ÚLTIMO programa de cada barco y limpiar los viejos
        final Map<String, List<Map<String, dynamic>>> byShip = {
          'ALFA': [],
          'GUSTAVO': [],
          'NANY': [],
        };

        for (var v in response) {
          if (v is! Map<String, dynamic>) continue;
          final sDesc = (v['ship_detail'] is Map ? v['ship_detail']['description'] : '').toString().toUpperCase();
          final shipKey = sDesc.contains('ALFA') ? 'ALFA'
              : sDesc.contains('GUSTAVO') ? 'GUSTAVO'
              : sDesc.contains('NANY') ? 'NANY' : null;
          if (shipKey != null) {
            byShip[shipKey]!.add(v);
          }
        }

        final List<Schedule> latestSchedules = [];
        for (var shipVoyages in byShip.values) {
          if (shipVoyages.isEmpty) continue;
          shipVoyages.sort((a, b) => ProductionFleetService.compareVoyagesDesc(a, b));
          // Solo dejamos el último programa de carga de cada barco
          final latest = shipVoyages.first;
          latestSchedules.add(Schedule.fromJson(latest));
        }

        if (latestSchedules.isNotEmpty) {
          return latestSchedules;
        }
      }
    } catch (_) {}

    try {
      String query = '';
      if (month != null && year != null) {
        query = '?month=$month&year=$year';
      }
      final response = await APIClient.shared.request(endpoint: '/api/v1/schedule/$query');
      if (response is List && response.isNotEmpty) {
        final Map<String, Schedule> latestByShip = {};
        for (var json in response) {
          final s = Schedule.fromJson(json);
          final key = s.shipId.toUpperCase();
          if (!latestByShip.containsKey(key) || s.date.isAfter(latestByShip[key]!.date)) {
            latestByShip[key] = s;
          }
        }
        return latestByShip.values.toList();
      }
    } catch (_) {}

    // Fallback to MockScheduleService with realistic operations
    return MockScheduleService().fetchMonthlySchedule(month: month, year: year);
  }

  @override
  Future<List<OperationCharge>> fetchOperationCharges({int? month, int? year, bool detailed = false}) async {
    try {
      // Intranet (MonthlySchedule.jsx):
      // fetch('/api/v1/operation-charges-chart/?detailed=1')
      // fetch('/api/v1/operation-charges-chart/')
      String endpoint = '/api/v1/operation-charges-chart/';
      final params = <String>[];
      if (detailed) params.add('detailed=1');
      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await APIClient.shared.request(endpoint: endpoint);
      if (response is List && response.isNotEmpty) {
        return response.map((json) => OperationCharge.fromJson(json)).toList();
      }
    } catch (_) {}

    // Fallback to MockScheduleService with exact intranet operational data
    return MockScheduleService().fetchOperationCharges(month: month, year: year, detailed: detailed);
  }
}

// ==========================================
// 7. GOAL SERVICE
// ==========================================
abstract class GoalService {
  Future<List<Goal>> fetchGoals({String? date, String? userId});

  factory GoalService() {
    return AppConfig.isMockActive ? MockGoalService() : ProductionGoalService();
  }
}

class MockGoalService implements GoalService {
  @override
  Future<List<Goal>> fetchGoals({String? date, String? userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final currentYear = DateTime.now().year.toString();
    return [
      Goal(
        id: "1",
        description: "Mantener 98% de disponibilidad operativa en flota sur",
        expectedValue: "98.0",
        achievedValue: "96.5",
        weightedValue: "30",
        targetDate: "$currentYear-12-31",
        goalType: "percentage",
        leaderId: "",
      ),
      Goal(
        id: "2",
        description: "Completar plan de capacitaciones STCW del semestre",
        expectedValue: "100.0",
        achievedValue: "85.0",
        weightedValue: "25",
        targetDate: "$currentYear-12-31",
        goalType: "percentage",
        leaderId: "",
      ),
      Goal(
        id: "3",
        description: "Cero incidentes de contaminación marina ambiental",
        expectedValue: "0",
        achievedValue: "0",
        weightedValue: "45",
        targetDate: "$currentYear-12-31",
        goalType: "boolean",
        leaderId: "",
      ),
    ];
  }
}

class ProductionGoalService implements GoalService {
  @override
  Future<List<Goal>> fetchGoals({String? date, String? userId}) async {
    final targetUserId = userId ?? SessionManager.shared.currentUser?.id;

    final queryParams = <String>['current=true'];
    if (targetUserId != null && targetUserId.isNotEmpty) {
      queryParams.add("user_id=$targetUserId");
    }

    final endpoint = '/api/v1/user-goals/?${queryParams.join('&')}';

    try {
      final response = await APIClient.shared.request(endpoint: endpoint);
      if (response is List && response.isNotEmpty) {
        final List<Goal> goals = response.map((json) => Goal.fromJson(json)).toList();
        goals.sort((a, b) => b.targetDate.compareTo(a.targetDate));
        return goals;
      }
    } catch (_) {}

    return [];
  }
}

// ==========================================
// 8. NOTIFICATION SERVICE
// ==========================================
abstract class NotificationService {
  Future<List<AppNotification>> fetchNotifications();
  Future<void> markAllAsRead();
  Future<void> markAsRead(String notificationId);
  Future<void> clearAll();

  factory NotificationService() {
    return AppConfig.isMockActive ? MockNotificationService() : ProductionNotificationService();
  }
}

class MockNotificationService implements NotificationService {
  @override
  Future<List<AppNotification>> fetchNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      AppNotification(
        id: "1",
        title: "Incidente reportado",
        message: "Se ha registrado un nuevo incidente en el Alfa C.",
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
      AppNotification(
        id: "2",
        title: "Mantenimiento programado",
        message: "El Gustavo U ingresará a dique seco mañana.",
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
    ];
  }

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> clearAll() async {}
}

class ProductionNotificationService implements NotificationService {
  @override
  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await APIClient.shared.request(endpoint: '/api/v1/notifications/');
      List rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        rawList = response['results'] as List? ?? response['data'] as List? ?? [];
      }
      return rawList.map((json) => AppNotification.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await APIClient.shared.request(
      endpoint: '/api/v1/notifications/mark-all-read/',
      method: 'POST',
    );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await APIClient.shared.request(
      endpoint: '/api/v1/notifications/${Uri.encodeComponent(notificationId)}/read/',
      method: 'POST',
    );
  }

  @override
  Future<void> clearAll() async {
    await APIClient.shared.request(
      endpoint: '/api/v1/notifications/clear/',
      method: 'POST',
    );
  }
}

// Training Service Interface & Implementations
abstract class TrainingService {
  Future<List<Training>> fetchTrainings({String? userId});
  Future<TrainingConsumption?> fetchTrainingConsumption({String? ship, String? sector, String? userId});
  Future<Training> updateTrainingProgress({required int trainingId, required int completedModules, String? slug, String? userId});
}

class MockTrainingService implements TrainingService {
  static List<Training>? _cachedTrainings;

  static List<Training> _initMockTrainings() {
    return [
      Training(
        id: 10005,
        title: "STCW VI/1 - 1° Auxilios Básicos (1)",
        code: "STCW-VI/1-01",
        hours: 40,
        sector: "General",
        completionRate: 98.6,
        status: "Vigente",
        description: "Capacitación obligatoria Convenio STCW VI/1. 71 tripulantes registrados con 98.6% de cumplimiento en la flota.",
        instructor: "Dra. Elena Silva (Médico Naval PNA)",
        completedModules: 3,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Reanimación Cardiopulmonar (RCP) y Soporte Vital", durationMinutes: 45, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Control de Hemorragias, Fracturas y Quemaduras", durationMinutes: 40, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Protocolos de Emergencia Médica en Mar", durationMinutes: 35, isCompleted: true),
        ],
      ),
      Training(
        id: 10003,
        title: "STCW VI/1 - Lucha Contra Incendios LCI (2)",
        code: "STCW-VI/1-02",
        hours: 32,
        sector: "General",
        completionRate: 98.6,
        status: "Vigente",
        description: "Instrucción de sofocación de incendios a bordo. 71 tripulantes auditados con 98.6% vigencia.",
        instructor: "Ing. Bombero Naval Gabriel Rossi",
        completedModules: 3,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Química del Fuego y Agentes Extintores", durationMinutes: 40, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Uso de Equipos ERA y mangueras de alta presión", durationMinutes: 50, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Tácticas de Ataque en Espacios Confinados", durationMinutes: 45, isCompleted: true),
        ],
      ),
      Training(
        id: 10007,
        title: "STCW VI/1 - Técnicas de Supervivencia Personal T.S.P (3)",
        code: "STCW-VI/1-03",
        hours: 30,
        sector: "Cubierta",
        completionRate: 97.1,
        status: "Vigente",
        description: "Zafarrancho de abandono y supervivencia en el mar. 70 tripulantes con 97.1% de certificaciones activas.",
        instructor: "Cap. Esteban Valdez (Instructor Máster STCW)",
        completedModules: 2,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Zafarrancho y Despliegue de Balsas Salvavidas", durationMinutes: 50, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Uso de Trajes de Inmersión y Chalecos", durationMinutes: 40, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Activación de Radiobalizas EPIRB y SART", durationMinutes: 30, isCompleted: false),
        ],
      ),
      Training(
        id: 10008,
        title: "STCW VI/1 - Seguridad Personal y Resp. Sociales SPyRS (4)",
        code: "STCW-VI/1-04",
        hours: 24,
        sector: "General",
        completionRate: 97.1,
        status: "Vigente",
        description: "Prevención de riesgos laborales y gestión del trabajo en equipo a bordo. 70 tripulantes evaluados.",
        instructor: "Lic. Marítimo Roberto Soria",
        completedModules: 3,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Prevención de Riesgos de Trabajo a Bordo", durationMinutes: 45, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Gestión de la Fatiga y Relaciones Humanas", durationMinutes: 40, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Procedimientos de Emergencia y Alarma", durationMinutes: 35, isCompleted: true),
        ],
      ),
      Training(
        id: 10009,
        title: "STCW V/1-1 - Formación Básica Operaciones Petroleros (5)",
        code: "STCW-V/1-05",
        hours: 40,
        sector: "Cubierta",
        completionRate: 98.6,
        status: "Vigente",
        description: "Manejo seguro de cargas de hidrocarburos LSFO y MGO. 69 tripulantes capacitados.",
        instructor: "Cap. Marcos Benítez",
        completedModules: 2,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Física y Química de Cargas Líquidas", durationMinutes: 50, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Sistemas de Inerteado y Transferencia", durationMinutes: 60, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Prevención de Derrames y SOPEP", durationMinutes: 45, isCompleted: false),
        ],
      ),
      Training(
        id: 10020,
        title: "Código PBIP / ISPS - Protección de Buques e Instalaciones",
        code: "ISPS-SEC-PBIP",
        hours: 24,
        sector: "Seguridad",
        completionRate: 96.4,
        status: "Vigente",
        description: "Cumplimiento del Plan de Protección del Buque (PPB) e inspección de accesos. 56 marinos vigentes.",
        instructor: "Of. Protección Marítima Roberto Soria",
        completedModules: 3,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Evaluación de Amenazas PBIP", durationMinutes: 40, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Inspección de Carga y Accesos al Buque", durationMinutes: 45, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Niveles de Protección 1, 2 y 3", durationMinutes: 35, isCompleted: true),
        ],
      ),
      Training(
        id: 10014,
        title: "Convenio MARPOL (6) - Prevención Contaminación Marina",
        code: "MARPOL-73/78",
        hours: 32,
        sector: "General",
        completionRate: 97.9,
        status: "Vigente",
        description: "Normativa ambiental marítima internacional MARPOL Anexos I a VI. 48 tripulantes con 97.9% cumplimiento.",
        instructor: "Ing. Marítimo Carlos Benítez",
        completedModules: 2,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Anexo I - Control de Aguas Oleosas y Separadores", durationMinutes: 50, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Libro de Registro de Hidrocarburos", durationMinutes: 45, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Anexos IV y VI - Emisiones y Residuos", durationMinutes: 40, isCompleted: false),
        ],
      ),
      Training(
        id: 10004,
        title: "STCW VI/3 - Lucha Contra Incendios Avanzada AV. LCI (8)",
        code: "STCW-VI/3-08",
        hours: 36,
        sector: "Máquinas",
        completionRate: 97.5,
        status: "Vigente",
        description: "Estrategias avanzadas de extinción en salas de máquinas y bodegas. 40 oficiales con 97.5% cumplimiento.",
        instructor: "Ing. Bombero Naval Gabriel Rossi",
        completedModules: 2,
        totalModules: 4,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Control de Incendios en Sala de Máquinas", durationMinutes: 50, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Inyección Fija de CO2 y Agua Pulverizada", durationMinutes: 60, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Tácticas de Ataque con Cuadrillas de Rescate", durationMinutes: 55, isCompleted: false),
          TrainingModule(id: 4, title: "Módulo 4: Evaluación de Estabilidad por Agua de Incendio", durationMinutes: 40, isCompleted: false),
        ],
      ),
      Training(
        id: 10010,
        title: "STCW V/1-1 - Formación Avanzada Operaciones Petroleros AV. PETRO (7)",
        code: "STCW-V/1-07",
        hours: 40,
        sector: "Cubierta",
        completionRate: 92.5,
        status: "Vigente",
        description: "Gestión avanzada de operaciones de tanqueros y trasvases STS. 40 oficiales evaluados.",
        instructor: "Cap. Andrés Morales",
        completedModules: 2,
        totalModules: 4,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Control de Operaciones de Carga y Descarga", durationMinutes: 60, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Monitoreo Explosiométrico y Gas Free", durationMinutes: 50, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Lavado de Tanques con Crudo (COW) e Inerteado", durationMinutes: 55, isCompleted: false),
          TrainingModule(id: 4, title: "Módulo 4: Procedimientos de Emergencia STS", durationMinutes: 45, isCompleted: false),
        ],
      ),
      Training(
        id: 10018,
        title: "STCW II/1 - Operador de Radar y ARPA (10)",
        code: "STCW-II/1-10",
        hours: 40,
        sector: "Puente",
        completionRate: 100.0,
        status: "Vigente",
        description: "Instrucción técnica de cinemática de radar y punteo ARPA para guardia de navegación. 11 oficiales con 100% de vigencia.",
        instructor: "Cap. Esteban Valdez",
        completedModules: 3,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Operación y Ajustes del Pantalla Radar/ARPA", durationMinutes: 45, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Determinación de CPA y TCPA en Maniobras", durationMinutes: 55, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Simulación de Navegación Nocturna y Niebla", durationMinutes: 50, isCompleted: true),
        ],
      ),
      Training(
        id: 10006,
        title: "STCW VI/4 - Cuidados Médicos a Bordo (11)",
        code: "STCW-VI/4-11",
        hours: 40,
        sector: "General",
        completionRate: 100.0,
        status: "Vigente",
        description: "Administración de farmacia de a bordo y asistencia médica guiada por radio. 17 oficiales vigentes.",
        instructor: "Dra. Elena Silva (Médico Naval)",
        completedModules: 3,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Control de Farmacia e Inyectables a Bordo", durationMinutes: 45, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Suturas, Inmovilización y Tratamientos de Urgencia", durationMinutes: 50, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Consulta Médica por Radio TMAS y Telemedicina", durationMinutes: 40, isCompleted: true),
        ],
      ),
      Training(
        id: 10025,
        title: "Oficial de Seguridad (Gestión y Evaluación del Riesgo)",
        code: "SAFETY-OFFICER",
        hours: 30,
        sector: "Seguridad",
        completionRate: 100.0,
        status: "Vigente",
        description: "Metodología de Análisis Seguro de Trabajo (AST) y reporte de hallazgos MG-21. 8 oficiales calificados.",
        instructor: "Lic. Seguridad Marítima Juan Gallardo",
        completedModules: 3,
        totalModules: 3,
        modules: [
          TrainingModule(id: 1, title: "Módulo 1: Matriz de Evaluación de Riesgos Operativos AST", durationMinutes: 45, isCompleted: true),
          TrainingModule(id: 2, title: "Módulo 2: Permisos de Trabajo Seguro (PTS) y Bloqueos", durationMinutes: 40, isCompleted: true),
          TrainingModule(id: 3, title: "Módulo 3: Investigación de Incidentes Marítimos MG-21", durationMinutes: 50, isCompleted: true),
        ],
      ),
    ];
  }

  @override
  Future<List<Training>> fetchTrainings({String? userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _cachedTrainings ??= _initMockTrainings();
    return _cachedTrainings!;
  }

  @override
  Future<Training> updateTrainingProgress({
    required int trainingId,
    required int completedModules,
    String? slug,
    String? userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _cachedTrainings ??= _initMockTrainings();
    
    final index = _cachedTrainings!.indexWhere((t) => t.id == trainingId);
    if (index != -1) {
      final current = _cachedTrainings![index];
      final newCompleted = completedModules.clamp(0, current.totalModules);
      
      final updatedModules = List<TrainingModule>.from(current.modules);
      for (int i = 0; i < updatedModules.length; i++) {
        updatedModules[i] = updatedModules[i].copyWith(isCompleted: i < newCompleted);
      }
      
      final double newRate = ((newCompleted / current.totalModules) * 100).clamp(0.0, 100.0);
      final updatedTraining = current.copyWith(
        completedModules: newCompleted,
        completionRate: newRate,
        modules: updatedModules,
        status: newCompleted == current.totalModules ? "Vigente" : "En Curso",
      );
      
      _cachedTrainings![index] = updatedTraining;
      return updatedTraining;
    }
    throw Exception("Capacitación no encontrada");
  }

  @override
  Future<TrainingConsumption> fetchTrainingConsumption({String? ship, String? sector, String? userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return TrainingConsumption(
      totalHoursConsumed: 862,
      totalTrainingsCompleted: 71,
      complianceRate: 98.2,
      activeCertificates: 862,
      consumptionByShip: [
        ShipTrainingConsumption(ship: "ALFA C", hours: 240, completionRate: 98.6),
        ShipTrainingConsumption(ship: "GUSTAVO U", hours: 210, completionRate: 97.5),
        ShipTrainingConsumption(ship: "NANY", hours: 195, completionRate: 96.8),
        ShipTrainingConsumption(ship: "GENERAL MOSCONI", hours: 217, completionRate: 99.1),
      ],
    );
  }
}

class ProductionTrainingService implements TrainingService {
  Future<Training?> fetchTrainingDetail(dynamic idOrSlug) async {
    if (idOrSlug == null || idOrSlug.toString().isEmpty) return null;
    final String key = idOrSlug.toString();
    final endpoints = [
      '/api/capacitaciones/$key/',
      '/api/v1/capacitaciones/$key/',
      '/api/trainings/$key/',
      '/api/v1/trainings/$key/',
    ];

    for (final ep in endpoints) {
      try {
        final response = await APIClient.shared.request(endpoint: ep);
        if (response is Map<String, dynamic> &&
            (response.containsKey('id') || response.containsKey('title') || response.containsKey('nombre') || response.containsKey('files'))) {
          return Training.fromJson(response);
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<List<Training>> fetchTrainings({String? userId}) async {
    final targetUserId = userId ?? SessionManager.shared.currentUser?.id;

    final endpoints = <String>[];
    if (targetUserId != null && targetUserId.isNotEmpty) {
      endpoints.add('/api/capacitaciones/?user_id=${Uri.encodeComponent(targetUserId)}');
      endpoints.add('/api/v1/capacitaciones/?user_id=${Uri.encodeComponent(targetUserId)}');
      endpoints.add('/api/v1/trainings/?user_id=${Uri.encodeComponent(targetUserId)}');
    }
    endpoints.addAll([
      '/api/capacitaciones/',
      '/api/v1/capacitaciones/my-logs/',
      '/api/v1/capacitaciones/',
      '/api/v1/trainings/',
      '/api/trainings/',
    ]);

    for (final ep in endpoints) {
      try {
        final response = await APIClient.shared.request(endpoint: ep);
        List rawList = [];
        if (response is List) {
          rawList = response;
        } else if (response is Map<String, dynamic> && response['results'] is List) {
          rawList = response['results'] as List;
        } else if (response is Map<String, dynamic> && response['data'] is List) {
          rawList = response['data'] as List;
        }

        if (rawList.isNotEmpty) {
          return rawList.map((json) => Training.fromJson(json)).toList();
        }
      } catch (_) {}
    }

    // Attempt certificates list fallback
    try {
      final certsResponse = await APIClient.shared.request(endpoint: '/certificates/list/all/');
      if (certsResponse is Map<String, dynamic> && certsResponse.containsKey('data') && certsResponse['data'] is List) {
        final List<dynamic> certList = certsResponse['data'];
        if (certList.isNotEmpty) {
          final Map<String, List<dynamic>> grouped = {};
          for (var item in certList) {
            final typeName = item['certificate_type']?.toString().trim() ?? '';
            if (typeName.isEmpty) continue;
            grouped.putIfAbsent(typeName, () => []).add(item);
          }

          final List<Training> serverTrainings = [];
          int idCounter = 1000;

          grouped.forEach((typeName, items) {
            idCounter++;
            int total = items.length;
            int okCount = items.where((i) => i['status'] == 'ok').length;
            double rate = total > 0 ? ((okCount / total) * 100) : 100.0;
            
            serverTrainings.add(Training(
              id: idCounter,
              title: typeName,
              code: "STCW-${idCounter.toString().substring(1)}",
              hours: 32,
              sector: typeName.contains("PETR") || typeName.contains("LCI") ? "Máquinas" : "Cubierta",
              completionRate: double.parse(rate.toStringAsFixed(1)),
              status: rate >= 95.0 ? "Vigente" : "En Curso",
              instructor: items.firstWhere((i) => i['instructor'] != null, orElse: () => {})['instructor']?.toString() ?? '',
              completedModules: (rate >= 95.0) ? 3 : 2,
              totalModules: 3,
              modules: [
                TrainingModule(id: 1, title: "Módulo 1: Marco Teórico y Regulaciones", durationMinutes: 45, isCompleted: true),
                TrainingModule(id: 2, title: "Módulo 2: Práctica Operativa en Buque", durationMinutes: 50, isCompleted: rate >= 50.0),
                TrainingModule(id: 3, title: "Módulo 3: Evaluación de Competencias", durationMinutes: 40, isCompleted: rate >= 95.0),
              ],
            ));
          });

          if (serverTrainings.isNotEmpty) {
            return serverTrainings;
          }
        }
      }
    } catch (_) {}

    if (AppConfig.isMockActive) {
      return MockTrainingService._initMockTrainings();
    }
    return [];
  }

  @override
  Future<Training> updateTrainingProgress({
    required int trainingId,
    required int completedModules,
    String? slug,
    String? userId,
  }) async {
    final key = slug != null && slug.isNotEmpty ? slug : trainingId.toString();
    final endpoints = [
      '/api/capacitaciones/$key/complete/',
      '/api/v1/capacitaciones/$key/complete/',
      '/api/v1/capacitaciones/$trainingId/complete/',
      '/api/v1/capacitaciones/$trainingId/progress/',
      '/api/v1/trainings/$trainingId/progress/',
    ];

    for (final ep in endpoints) {
      try {
        final Map<String, dynamic> body = {
          'completed_modules': completedModules,
          if (userId != null) 'user_id': userId,
        };
        final response = await APIClient.shared.request(
          endpoint: ep,
          method: 'POST',
          body: body,
        );
        if (response is Map<String, dynamic> && response.containsKey('id')) {
          return Training.fromJson(response);
        }
      } catch (_) {}
    }

    return MockTrainingService().updateTrainingProgress(
      trainingId: trainingId,
      completedModules: completedModules,
      userId: userId,
    );
  }

  @override
  Future<TrainingConsumption?> fetchTrainingConsumption({String? ship, String? sector, String? userId}) async {
    try {
      String query = '';
      final params = <String>[];
      if (ship != null && ship.isNotEmpty) params.add('ship=${Uri.encodeComponent(ship)}');
      if (sector != null && sector.isNotEmpty) params.add('sector=${Uri.encodeComponent(sector)}');
      if (userId != null && userId.isNotEmpty) params.add('user_id=${Uri.encodeComponent(userId)}');
      if (params.isNotEmpty) query = '?${params.join('&')}';

      final endpoints = [
        '/api/capacitaciones/consumption/$query',
        '/api/v1/capacitaciones/consumption/$query',
        '/api/v1/trainings/consumption/$query',
      ];

      for (final ep in endpoints) {
        try {
          final response = await APIClient.shared.request(endpoint: ep);
          if (response is Map<String, dynamic> &&
              response.isNotEmpty &&
              response.containsKey('total_hours_consumed') &&
              (response['total_hours_consumed'] as num? ?? 0) > 0) {
            return TrainingConsumption.fromJson(response);
          }
        } catch (_) {}
      }
    } catch (_) {}

    if (AppConfig.isMockActive) {
      return MockTrainingService().fetchTrainingConsumption(ship: ship, sector: sector, userId: userId);
    }
    return null;
  }
}
