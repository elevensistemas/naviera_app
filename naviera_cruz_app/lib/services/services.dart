import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../app/config.dart';
import '../core/network.dart';
import '../core/storage.dart';
import '../models/models.dart';

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
    await Future.delayed(const Duration(milliseconds: 600));
    final u = username.trim().toLowerCase();

    final validUsers = {
      'a.lopresti': User(id: 'a.lopresti', name: 'A. Lo Presti', role: 'Gerencia General', sector: 'Gerencia'),
      'alejandro': User(id: 'alejandro', name: 'A. Lo Presti', role: 'Gerencia General', sector: 'Gerencia'),
      'm.piccinini': User(id: 'm.piccinini', name: 'M. Piccinini', role: 'Director de Operaciones', sector: 'Operaciones'),
      'admin': User(id: 'admin', name: 'Administrador', role: 'Sistemas', sector: 'Sistemas'),
    };

    if (validUsers.containsKey(u)) {
      const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
      return {'user': validUsers[u]!, 'token': token};
    } else if (u.isNotEmpty && passcode.isNotEmpty) {
      final user = User(
        id: u,
        name: username,
        role: "Personal Naviera",
        sector: "Operaciones",
      );
      return {'user': user, 'token': "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."};
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
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ChatChannel(
        id: "ch1",
        name: "Operaciones Central",
        isGroup: true,
        lastMessage: "¿Cómo viene la carga del Naviera I?",
        lastMessageTimestamp: DateTime.now(),
      ),
      ChatChannel(
        id: "ch2",
        name: "Capitán Pérez",
        isGroup: false,
        lastMessage: "Recibido.",
        lastMessageTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  @override
  Future<List<ChatChannel>> fetchContacts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return fetchChannels();
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
    final Map<String, dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/chat/conversations/');
    final List<dynamic> results = response['results'] ?? [];
    return results.map((json) {
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
  }

  @override
  Future<List<ChatChannel>> fetchContacts() async {
    final Map<String, dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/chat/users/');
    final List<dynamic> results = response['results'] ?? [];
    return results.map((json) {
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
    await Future.delayed(const Duration(milliseconds: 700));
    return [
      Ship(
        id: "s1",
        name: "Naviera I",
        status: ShipStatus.active,
        totalCargo: 1500,
        latitude: -42.76,
        longitude: -65.03,
        cameraUrl: "https://demo.unified-streaming.com/k8s/live/stable/sintel.isml/.m3u8", // Stream HLS de prueba
      ),
      Ship(
        id: "s2",
        name: "Naviera II",
        status: ShipStatus.docked,
        totalCargo: 0,
        latitude: -38.00,
        longitude: -57.55,
        cameraUrl: null,
      ),
      Ship(
        id: "s3",
        name: "Naviera III",
        status: ShipStatus.maintenance,
        totalCargo: 2200,
        latitude: -54.80,
        longitude: -68.30,
        cameraUrl: null,
      ),
    ];
  }

  @override
  Future<List<CrewMember>> fetchCrew(String shipId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      CrewMember(id: "c1", shipId: shipId, name: "Juan Pérez", role: "Capitán"),
      CrewMember(id: "c2", shipId: shipId, name: "Carlos Goméz", role: "Jefe de Máquinas"),
    ];
  }
}

class EzvizService {
  static final EzvizService shared = EzvizService._internal();
  EzvizService._internal();

  static const String _appKey = "b7b99e5c45d64148a1492fb25b84ceb8";
  static const String _appSecret = "2bd739f5c4614af0b33191f9a780fd42";

  String? _accessToken;
  DateTime? _tokenExpireTime;

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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["code"] == "200" && data["data"] != null) {
          _accessToken = data["data"]["accessToken"];
          // Token is valid for 7 days, cache it for 6 days
          _tokenExpireTime = DateTime.now().add(const Duration(days: 6));
          return _accessToken!;
        } else {
          throw Exception(data["msg"] ?? "Error obteniendo token de Ezviz");
        }
      } else {
        throw Exception("Error de conexión con Ezviz API (HTTP ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Fallo de red al autenticar en Ezviz: $e");
    }
  }

  Future<String> getLiveStreamUrl(String deviceSerial) async {
    final token = await _getAccessToken();

    try {
      final response = await http.post(
        Uri.parse("https://open.ezvizlife.com/api/lapp/v2/live/address/get"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "accessToken": token,
          "deviceSerial": deviceSerial,
          "channelNo": "1",
          "protocol": "2", // HLS
          "quality": "1",  // HD/Standard
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["code"] == "200" && data["data"] != null) {
          final url = data["data"]["url"];
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
        throw Exception(data["msg"] ?? "Error de Ezviz al obtener dirección de directo");
      } else {
        throw Exception("Error de red con Ezviz (HTTP ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Fallo al consultar dirección HLS de Ezviz: $e");
    }
  }
}

class ProductionFleetService implements FleetService {
  @override
  Future<List<Ship>> fetchShips() async {
    try {
      final response = await APIClient.shared.request(endpoint: '/api/v1/fleet-combo/');
      if (response is List) {
        final List<Ship> rawShips = response.map((json) => Ship.fromJson(json)).toList();
        
        final List<Ship> resolvedShips = [];
        for (var ship in rawShips) {
          String? cameraUrl = ship.cameraUrl;
          
          final activeCams = ship.cameras.where((c) => c.isActive && c.serialNumber.isNotEmpty);
          if (activeCams.isNotEmpty) {
            try {
              final camera = activeCams.first;
              cameraUrl = await EzvizService.shared.getLiveStreamUrl(camera.serialNumber);
            } catch (e) {
              print("Error resolving Ezviz camera stream for ${ship.name}: $e");
            }
          }
          
          resolvedShips.add(ship.copyWith(cameraUrl: cameraUrl));
        }
        
        return resolvedShips;
      }
    } catch (e) {
      print("Error fetching ships: $e");
    }
    return [];
  }

  @override
  Future<List<CrewMember>> fetchCrew(String shipId) async {
    final encodedShipId = Uri.encodeComponent(shipId);

    final endpoints = [
      '/api/ships/$encodedShipId/crew/',
      '/api/v1/ships/$encodedShipId/crew/',
      '/api/crew-members/?ship=$encodedShipId',
      '/api/v1/crew-members/?ship=$encodedShipId',
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
          final crewList = rawList.map((json) => CrewMember.fromJson(json)).toList();
          crewList.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          return crewList;
        }
      } catch (_) {}
    }

    return [];
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
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      Post(
        id: "1",
        authorId: "hr1",
        authorName: "Recursos Humanos",
        content: "¡Bienvenidos al nuevo portal móvil de Naviera Cruz del Sur! A partir de hoy centralizaremos comunicados aquí.",
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: PostType.news,
      ),
      Post(
        id: "2",
        authorId: "op1",
        authorName: "Centro Operativo",
        content: "Aviso: Zonas de ráfagas fuertes en el sur argentino. Mantener precauciones en flota pesquera.",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: PostType.alert,
      ),
    ];
  }
}

class ProductionHomeService implements HomeService {
  @override
  Future<List<Post>> fetchPosts() async {
    // 1. Try /api/v1/announcements/?active=true
    try {
      final response = await APIClient.shared.request(endpoint: '/api/v1/announcements/?active=true');
      if (response is List && response.isNotEmpty) {
        return response.map((json) => Post.fromJson(json)).toList();
      }
    } catch (_) {}

    // 2. Try /api/announcements/?active=true
    try {
      final response = await APIClient.shared.request(endpoint: '/api/announcements/?active=true');
      if (response is List && response.isNotEmpty) {
        return response.map((json) => Post.fromJson(json)).toList();
      }
    } catch (_) {}

    // 3. Try /api/v1/announcements/
    try {
      final response = await APIClient.shared.request(endpoint: '/api/v1/announcements/');
      if (response is List && response.isNotEmpty) {
        return response.map((json) => Post.fromJson(json)).toList();
      }
    } catch (_) {}

    // 4. Try /api/announcements/
    try {
      final response = await APIClient.shared.request(endpoint: '/api/announcements/');
      if (response is List && response.isNotEmpty) {
        return response.map((json) => Post.fromJson(json)).toList();
      }
    } catch (_) {}

    // 5. Fallback to /api/v1/posts/
    try {
      final response = await APIClient.shared.request(endpoint: '/api/v1/posts/');
      if (response is List && response.isNotEmpty) {
        return response.map((json) => Post.fromJson(json)).toList();
      }
    } catch (_) {}

    return [];
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
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      Incident(
        id: "inc1",
        description: "Falla en generador auxiliar",
        shipId: "s1",
        reporterId: "1",
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: IncidentStatus.inReview,
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
    await Future.delayed(const Duration(milliseconds: 1200));
    return Incident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      shipId: shipId,
      reporterId: "1",
      date: DateTime.now(),
      status: IncidentStatus.open,
      photoURLs: photos.isEmpty ? [] : ["mock_photo_url"],
    );
  }
}

class ProductionIncidentService implements IncidentService {
  @override
  Future<List<Incident>> fetchIncidents() async {
    final List<dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/incidents/');
    return response.map((json) => Incident.fromJson(json)).toList();
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
    
    final body = {
      'code': code,
      'vessel': int.tryParse(shipId) ?? 1,
      'type': type,
      'title': title,
      'description': description,
      'date_time': DateTime.now().toIso8601String(),
      'photos': base64Photos,
    };
    
    final response = await APIClient.shared.request(
      endpoint: '/api/v1/incidents/',
      method: 'POST',
      body: body,
    );
    return Incident.fromJson(response);
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
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Schedule(
        id: "sch1",
        shipId: "Alfa C",
        date: DateTime.now(),
        cargoType: "Contenedores secos",
        details: "Descarga en Puerto Madryn",
      ),
      Schedule(
        id: "sch2",
        shipId: "Gustavo U",
        date: DateTime.now().add(const Duration(days: 3)),
        cargoType: "Pesca congelada",
        details: "Arribo programado a Ushuaia",
      ),
    ];
  }

  @override
  Future<List<OperationCharge>> fetchOperationCharges({int? month, int? year, bool detailed = false}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (detailed) {
      final now = DateTime.now();
      final m = month ?? now.month;
      final y = year ?? now.year;
      return [
        OperationCharge(client: "Raizen", ship: "ALFA C", totalLsfo: 3345, totalMgo: 100, totalShips: 6, limit: 17500, dateApplied: DateTime(y, m, 5)),
        OperationCharge(client: "WFS", ship: "GUSTAVO U", totalLsfo: 8500, totalMgo: 500, totalShips: 4, limit: 15000, dateApplied: DateTime(y, m, 3)),
        OperationCharge(client: "WFS", ship: "NANY", totalLsfo: 7200, totalMgo: 300, totalShips: 4, limit: 15000, dateApplied: DateTime(y, m, 5)),
      ];
    }
    return [
      OperationCharge(client: "Raizen", ship: "ALFA C", totalLsfo: 405468.95, totalMgo: 1926.75, totalShips: 673, limit: 17500),
      OperationCharge(client: "WFS", ship: "GUSTAVO U", totalLsfo: 276228.00, totalMgo: 27947.00, totalShips: 621, limit: 15000),
      OperationCharge(client: "WFS", ship: "NANY", totalLsfo: 246297.00, totalMgo: 21841.00, totalShips: 550, limit: 15000),
    ];
  }
}

class ProductionScheduleService implements ScheduleService {
  @override
  Future<List<Schedule>> fetchMonthlySchedule({int? month, int? year}) async {
    try {
      String query = '';
      if (month != null && year != null) {
        query = '?month=$month&year=$year';
      }
      final response = await APIClient.shared.request(endpoint: '/api/v1/schedule/$query');
      if (response is List && response.isNotEmpty) {
        return response.map((json) => Schedule.fromJson(json)).toList();
      }
    } catch (_) {}

    // Fallback to /api/v1/voyages/ if /schedule/ returns empty
    try {
      final List<dynamic> voyagesRes = await APIClient.shared.request(endpoint: '/api/v1/voyages/');
      return voyagesRes.map((json) => Schedule.fromJson(json)).toList();
    } catch (_) {}

    return [];
  }

  @override
  Future<List<OperationCharge>> fetchOperationCharges({int? month, int? year, bool detailed = false}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      final targetMonth = month ?? DateTime.now().month;
      final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
      
      final monthStr = targetMonth.toString().padLeft(2, '0');
      final lastDayStr = lastDay.toString().padLeft(2, '0');

      final dateFrom = "$targetYear-$monthStr-01";
      final dateTo = "$targetYear-$monthStr-$lastDayStr";

      String query = "?date_from=$dateFrom&date_to=$dateTo";
      if (detailed) {
        query += "&detailed=1";
      }

      final response = await APIClient.shared.request(endpoint: '/api/v1/operation-charges-chart/$query');
      if (response is List) {
        return response.map((json) => OperationCharge.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
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
    final Map<String, dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/notifications/');
    final List<dynamic> results = response['results'] ?? [];
    return results.map((json) => AppNotification.fromJson(json)).toList();
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
