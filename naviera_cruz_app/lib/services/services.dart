import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../app/config.dart';
import '../core/network.dart';
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
    await Future.delayed(const Duration(seconds: 1));
    if (username.toLowerCase() == "admin" && (passcode == "123456" || passcode == "mate8286")) {
      final user = User(
        id: "1",
        name: "Administrador",
        role: "Gerencia",
        sector: "Gerencia",
        avatarURL: "https://i.pravatar.cc/150?img=60",
      );
      const token = "eyJhbGciOiJIUzI1NiIsInR...";
      return {'user': user, 'token': token};
    } else {
      throw NetworkException("Usuario o contraseña incorrectos.", statusCode: 401);
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }
}

class ProductionAuthService implements AuthService {
  @override
  Future<Map<String, dynamic>> login(String username, String passcode) async {
    final body = {
      'username': username,
      'password': passcode,
    };
    final response = await APIClient.shared.request(
      endpoint: '/api/v1/login/',
      method: 'POST',
      body: body,
    );
    final user = User.fromJson(response);
    final token = response['token'] ?? '';
    return {'user': user, 'token': token};
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
    final List<dynamic> response = await APIClient.shared.request(
      endpoint: '/api/v1/chat/messages/${Uri.encodeComponent(channelId)}/',
    );
    return response.map((json) => ChatMessage.fromJson(json)).toList();
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
    return ChatMessage.fromJson(response);
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
    final List<dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/fleet-combo/');
    final List<Ship> rawShips = response.map((json) => Ship.fromJson(json)).toList();
    
    // Resolve dynamic HLS streams for active cameras on the fly
    final List<Ship> resolvedShips = [];
    for (var ship in rawShips) {
      String? cameraUrl = ship.cameraUrl;
      
      // If there is an active camera on this ship, fetch its live HLS stream address dynamically
      final activeCams = ship.cameras.where((c) => c.isActive && c.serialNumber.isNotEmpty);
      if (activeCams.isNotEmpty) {
        try {
          final camera = activeCams.first;
          cameraUrl = await EzvizService.shared.getLiveStreamUrl(camera.serialNumber);
        } catch (e) {
          // Fallback to null (or mock/static if present) in case of fetch errors
          print("Error resolving Ezviz camera stream for ${ship.name}: $e");
        }
      }
      
      resolvedShips.add(ship.copyWith(cameraUrl: cameraUrl));
    }
    
    return resolvedShips;
  }

  @override
  Future<List<CrewMember>> fetchCrew(String shipId) async {
    final List<dynamic> response = await APIClient.shared.request(
      endpoint: '/api/v1/ships/${Uri.encodeComponent(shipId)}/crew/',
    );
    return response.map((json) => CrewMember.fromJson(json)).toList();
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
    final List<dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/posts/');
    return response.map((json) => Post.fromJson(json)).toList();
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
  Future<List<Schedule>> fetchMonthlySchedule();

  factory ScheduleService() {
    return AppConfig.isMockActive ? MockScheduleService() : ProductionScheduleService();
  }
}

class MockScheduleService implements ScheduleService {
  @override
  Future<List<Schedule>> fetchMonthlySchedule() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Schedule(
        id: "sch1",
        shipId: "s1",
        date: DateTime.now(),
        cargoType: "Contenedores secos",
        details: "Descarga en Puerto Madryn",
      ),
      Schedule(
        id: "sch2",
        shipId: "s3",
        date: DateTime.now().add(const Duration(days: 3)),
        cargoType: "Pesca congelada",
        details: "Arribo programado a Ushuaia",
      ),
    ];
  }
}

class ProductionScheduleService implements ScheduleService {
  @override
  Future<List<Schedule>> fetchMonthlySchedule() async {
    final List<dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/schedule/');
    return response.map((json) => Schedule.fromJson(json)).toList();
  }
}

// ==========================================
// 7. GOAL SERVICE
// ==========================================
abstract class GoalService {
  Future<List<Goal>> fetchGoals();

  factory GoalService() {
    return AppConfig.isMockActive ? MockGoalService() : ProductionGoalService();
  }
}

class MockGoalService implements GoalService {
  @override
  Future<List<Goal>> fetchGoals() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Goal(
        id: "1",
        description: "Optimizar procesos contables e intranet",
        expectedValue: "100.00",
        achievedValue: "50.00",
        weightedValue: "1.00",
        targetDate: "2025-12-31",
        goalType: "percentage",
        leaderId: "1",
      ),
      Goal(
        id: "2",
        description: "Mantener servidores seguros contra ciberataques",
        expectedValue: "1.00",
        achievedValue: null,
        weightedValue: "1.00",
        targetDate: "2025-12-31",
        goalType: "boolean",
        leaderId: "1",
      ),
    ];
  }
}

class ProductionGoalService implements GoalService {
  @override
  Future<List<Goal>> fetchGoals() async {
    final List<dynamic> response = await APIClient.shared.request(endpoint: '/api/v1/goals/');
    return response.map((json) => Goal.fromJson(json)).toList();
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
