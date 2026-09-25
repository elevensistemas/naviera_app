import 'package:flutter/foundation.dart';
import '../app/config.dart';

// User Model
class User {
  final String id;
  final String name;
  final String role;
  final String? avatarURL;
  final String sector;
  final DateTime? birthDate;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.avatarURL,
    this.sector = "Operaciones",
    this.birthDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String fullName = json['name']?.toString() ?? '';
    if (fullName.isEmpty && (json['first_name'] != null || json['last_name'] != null)) {
      fullName = "${json['first_name'] ?? ''} ${json['last_name'] ?? ''}".trim();
    }
    if (fullName.isEmpty) {
      fullName = json['username']?.toString() ?? 'Usuario Naviera';
    }

    return User(
      id: (json['id'] ?? json['user_id'] ?? json['username'])?.toString() ?? '',
      name: fullName,
      role: json['role']?.toString() ?? (json['username']?.toString().toLowerCase().contains('lopresti') == true ? 'Gerencia General' : 'Personal Naviera'),
      avatarURL: json['avatar_url']?.toString() ?? json['avatarURL']?.toString(),
      sector: json['sector']?.toString() ?? 'Operaciones',
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatar_url': avatarURL,
      'sector': sector,
      'birth_date': birthDate?.toIso8601String(),
    };
  }
}

// Post Model
enum PostType { news, alert, event, birthday }

extension PostTypeExtension on PostType {
  String get rawValue {
    switch (this) {
      case PostType.news: return "Novedad";
      case PostType.alert: return "Aviso Importante";
      case PostType.event: return "Evento";
      case PostType.birthday: return "Cumpleaños";
    }
  }

  static PostType fromString(String value) {
    switch (value) {
      case "Aviso Importante":
      case "alert": return PostType.alert;
      case "Evento":
      case "event": return PostType.event;
      case "Cumpleaños":
      case "birthday": return PostType.birthday;
      case "Novedad":
      case "news":
      default: return PostType.news;
    }
  }
}

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final DateTime timestamp;
  final PostType type;
  final String? imageUrl;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.title = '',
    required this.content,
    required this.timestamp,
    required this.type,
    this.imageUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    String authorNameStr = json['author_name']?.toString() ?? '';
    String authorIdStr = json['author_id']?.toString() ?? '';

    if (json['user_detail'] is Map<String, dynamic>) {
      final userDetail = json['user_detail'] as Map<String, dynamic>;
      authorIdStr = userDetail['id']?.toString() ?? authorIdStr;
      final firstName = userDetail['first_name']?.toString() ?? '';
      final lastName = userDetail['last_name']?.toString() ?? '';
      final fullName = "$firstName $lastName".trim();
      authorNameStr = fullName.isNotEmpty ? fullName : (userDetail['username']?.toString() ?? authorNameStr);
    }
    if (authorNameStr.isEmpty) {
      authorNameStr = "Comunicados Institucionales";
    }

    final titleStr = json['title']?.toString() ?? '';
    final descriptionStr = json['description']?.toString() ?? json['content']?.toString() ?? '';
    
    String textContent = descriptionStr;
    if (textContent.isEmpty) {
      textContent = titleStr;
    }

    final dateRaw = json['starts_at'] ?? json['created_at'] ?? json['timestamp'];
    final parsedDate = dateRaw != null ? DateTime.tryParse(dateRaw.toString()) ?? DateTime.now() : DateTime.now();

    PostType postType = PostTypeExtension.fromString(json['type']?.toString() ?? '');
    final importance = json['importance'];
    if (importance != null && (importance == 1 || importance == '1' || importance == 'high')) {
      postType = PostType.alert;
    }

    return Post(
      id: json['id']?.toString() ?? '',
      authorId: authorIdStr,
      authorName: authorNameStr,
      title: titleStr,
      content: textContent,
      timestamp: parsedDate,
      type: postType,
      imageUrl: json['image']?.toString() ?? json['image_url']?.toString(),
    );
  }
}

// Ship Model
enum ShipStatus { active, maintenance, docked }

extension ShipStatusExtension on ShipStatus {
  String get rawValue {
    switch (this) {
      case ShipStatus.active: return "Activo";
      case ShipStatus.maintenance: return "Mantenimiento";
      case ShipStatus.docked: return "En Puerto";
    }
  }

  static ShipStatus fromString(String value) {
    switch (value) {
      case "Mantenimiento":
      case "maintenance": return ShipStatus.maintenance;
      case "En Puerto":
      case "docked": return ShipStatus.docked;
      case "Activo":
      case "active":
      default: return ShipStatus.active;
    }
  }
}

class ShipCamera {
  final String id;
  final String name;
  final String serialNumber;
  final bool isActive;

  ShipCamera({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.isActive,
  });

  factory ShipCamera.fromJson(Map<String, dynamic> json) {
    return ShipCamera(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

class Ship {
  final String id;
  final String name;
  final ShipStatus status;
  final double totalCargo;
  final double totalWater;
  final double totalSlop;
  final double totalCarbon;
  final double latitude;
  final double longitude;
  final String? cameraUrl;
  final List<ShipCamera> cameras;

  Ship({
    required this.id,
    required this.name,
    required this.status,
    required this.totalCargo,
    this.totalWater = 0.0,
    this.totalSlop = 0.0,
    this.totalCarbon = 0.0,
    required this.latitude,
    required this.longitude,
    this.cameraUrl,
    this.cameras = const [],
  });

  Ship copyWith({
    String? id,
    String? name,
    ShipStatus? status,
    double? totalCargo,
    double? totalWater,
    double? totalSlop,
    double? totalCarbon,
    double? latitude,
    double? longitude,
    String? cameraUrl,
    List<ShipCamera>? cameras,
  }) {
    return Ship(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      totalCargo: totalCargo ?? this.totalCargo,
      totalWater: totalWater ?? this.totalWater,
      totalSlop: totalSlop ?? this.totalSlop,
      totalCarbon: totalCarbon ?? this.totalCarbon,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cameraUrl: cameraUrl ?? this.cameraUrl,
      cameras: cameras ?? this.cameras,
    );
  }

  factory Ship.fromJson(Map<String, dynamic> json) {
    var camerasJson = json['cameras'];
    List<ShipCamera> camerasList = [];
    if (camerasJson is List) {
      camerasList = camerasJson.map((e) => ShipCamera.fromJson(e)).toList();
    }
    final carbonVal = (json['total_carbon'] as num?)?.toDouble() ?? (json['total_cargo'] as num?)?.toDouble() ?? 0.0;
    final waterVal = (json['total_water'] as num?)?.toDouble() ?? 0.0;
    final slopVal = (json['total_slop'] as num?)?.toDouble() ?? 0.0;

    return Ship(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['description'] ?? json['code'] ?? '',
      status: json['status'] != null
          ? ShipStatusExtension.fromString(json['status'])
          : (json['active'] == true ? ShipStatus.active : ShipStatus.docked),
      totalCargo: carbonVal,
      totalCarbon: carbonVal,
      totalWater: waterVal,
      totalSlop: slopVal,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      cameraUrl: json['camera_url'],
      cameras: camerasList,
    );
  }
}

// ChatMessage Model
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String? attachmentURL;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.attachmentURL,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String? attachment = json['attachment_url'] ?? json['attachment'];
    if (attachment != null && attachment.startsWith('/') && !attachment.startsWith('http')) {
      attachment = "${AppConfig.apiBaseURL}$attachment";
    }
    
    DateTime parsedTime = DateTime.now();
    try {
      if (json['created_at'] != null) {
        parsedTime = DateTime.parse(json['created_at']);
      } else if (json['timestamp'] != null) {
        parsedTime = DateTime.parse(json['timestamp']);
      }
    } catch (_) {}

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      text: json['content'] ?? json['text'] ?? '',
      attachmentURL: attachment,
      timestamp: parsedTime,
    );
  }
}

// ChatChannel Model
class ChatChannel {
  final String id;
  final String name;
  final bool isGroup;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;

  ChatChannel({
    required this.id,
    required this.name,
    required this.isGroup,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  factory ChatChannel.fromJson(Map<String, dynamic> json) {
    return ChatChannel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      isGroup: json['is_group'] ?? false,
      lastMessage: json['last_message'],
      lastMessageTimestamp: json['last_message_timestamp'] != null
          ? DateTime.parse(json['last_message_timestamp'])
          : null,
    );
  }
}

// CrewMember Model
class CrewMember {
  final String id;
  final String shipId;
  final String name;
  final String role;
  final String situation;
  final String situationCode;
  final bool isOnBoard;
  final String? startDate;
  final String? endDate;
  final String? photoUrl;
  final int? daysOnBoard;
  final int orderIndex;

  CrewMember({
    required this.id,
    required this.shipId,
    required this.name,
    required this.role,
    this.situation = "Embarcado",
    this.situationCode = "EMB",
    this.isOnBoard = true,
    this.startDate,
    this.endDate,
    this.photoUrl,
    this.daysOnBoard,
    this.orderIndex = 999,
  });

  int get calculatedDays {
    if (daysOnBoard != null) {
      return daysOnBoard!;
    }
    if (startDate != null && startDate!.isNotEmpty) {
      final parsedDate = DateTime.tryParse(startDate!);
      if (parsedDate != null) {
        final diff = DateTime.now().difference(parsedDate).inDays;
        return diff >= 0 ? diff + 1 : 0;
      }
    }
    return 0;
  }

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    String nameStr = json['name']?.toString() ?? '';
    if (nameStr.isEmpty && (json['first_name'] != null || json['last_name'] != null)) {
      nameStr = "${json['first_name'] ?? ''} ${json['last_name'] ?? ''}".trim();
    }
    if (nameStr.isEmpty && json['crew_member_detail'] is Map<String, dynamic>) {
      final detail = json['crew_member_detail'] as Map<String, dynamic>;
      final fn = detail['first_name']?.toString() ?? '';
      final ln = detail['last_name']?.toString() ?? '';
      nameStr = "$fn $ln".trim();
      if (nameStr.isEmpty) {
        nameStr = detail['name']?.toString() ?? '';
      }
    }
    if (nameStr.isEmpty) {
      nameStr = "Tripulante";
    }

    String roleStr = json['role']?.toString() ?? '';
    int orderIdx = 999;
    if (json['position_detail'] is Map<String, dynamic>) {
      final posDetail = json['position_detail'] as Map<String, dynamic>;
      roleStr = posDetail['name']?.toString() ?? posDetail['short_name']?.toString() ?? '';
      if (posDetail['order_index'] != null) {
        orderIdx = (posDetail['order_index'] as num?)?.toInt() ?? int.tryParse(posDetail['order_index'].toString()) ?? 999;
      }
    }
    if (roleStr.isEmpty && json['position'] != null) {
      roleStr = json['position']?.toString() ?? '';
    }
    if (orderIdx == 999 && json['order_index'] != null) {
      orderIdx = (json['order_index'] as num?)?.toInt() ?? int.tryParse(json['order_index'].toString()) ?? 999;
    }
    if (roleStr.isEmpty) {
      roleStr = "Personal de Flota";
    }

    String situationName = "Embarcado";
    String situationCode = "EMB";
    bool? isOnBoardExplicit;
    String? startDt;
    String? endDt;
    int? daysOnBoardVal;

    if (json['is_on_board'] is bool) {
      isOnBoardExplicit = json['is_on_board'] as bool;
    }

    final sitDetail = json['current_situation_detail'] ?? json['situation_detail'] ?? json['situation'];
    if (sitDetail is Map<String, dynamic>) {
      startDt = sitDetail['start_date']?.toString() ?? sitDetail['starts_at']?.toString();
      endDt = sitDetail['end_date']?.toString() ?? sitDetail['ends_at']?.toString();

      if (sitDetail['is_on_board'] is bool) {
        isOnBoardExplicit = sitDetail['is_on_board'] as bool;
      }

      if (sitDetail['days_on_board'] != null) {
        daysOnBoardVal = (sitDetail['days_on_board'] as num?)?.toInt() ?? int.tryParse(sitDetail['days_on_board'].toString());
      }

      final typeDetail = sitDetail['situation_type_detail'] ?? sitDetail['situation_type'] ?? sitDetail['type'];
      if (typeDetail is Map<String, dynamic>) {
        situationName = typeDetail['name']?.toString() ?? typeDetail['short_description']?.toString() ?? situationName;
        situationCode = typeDetail['short_description']?.toString() ?? typeDetail['code']?.toString() ?? situationCode;
        if (typeDetail['is_on_board'] is bool) {
          isOnBoardExplicit = typeDetail['is_on_board'] as bool;
        }
      } else if (typeDetail is String && typeDetail.isNotEmpty) {
        situationName = typeDetail;
      }
    } else if (sitDetail is String && sitDetail.isNotEmpty) {
      situationName = sitDetail;
    }

    if (json['situation_name'] != null && json['situation_name'].toString().isNotEmpty) {
      situationName = json['situation_name'].toString();
    }

    if (daysOnBoardVal == null && json['days_on_board'] != null) {
      daysOnBoardVal = (json['days_on_board'] as num?)?.toInt() ?? int.tryParse(json['days_on_board'].toString());
    }

    bool isOnBoardFinal;
    if (isOnBoardExplicit != null) {
      isOnBoardFinal = isOnBoardExplicit;
    } else {
      final sitLower = situationName.toLowerCase();
      if (sitLower.contains('franco') || sitLower.contains('licenc') || sitLower.contains('baja') || sitLower.contains('tierra') || sitLower.contains('desembarc')) {
        isOnBoardFinal = false;
      } else {
        isOnBoardFinal = true;
      }
    }

    final photo = json['photo']?.toString() ?? json['avatar_url']?.toString() ?? json['image']?.toString();

    return CrewMember(
      id: json['id']?.toString() ?? '',
      shipId: json['ship_id']?.toString() ??
          json['ship']?.toString() ??
          json['current_ship_detail']?['id']?.toString() ??
          json['current_situation_detail']?['ship']?.toString() ??
          '',
      name: nameStr,
      role: roleStr,
      situation: situationName,
      situationCode: situationCode,
      isOnBoard: isOnBoardFinal,
      startDate: startDt,
      endDate: endDt,
      photoUrl: photo,
      daysOnBoard: daysOnBoardVal,
      orderIndex: orderIdx,
    );
  }
}

// OperationCharge Model (from /api/v1/operation-charges-chart/)
class OperationCharge {
  final String client;
  final String ship;
  final double totalLsfo;
  final double totalMgo;
  final int totalShips; // Cantidad de buques provistos
  final double? limit; // Límite base (en WFS a partir de este punto pagan más)
  final DateTime? dateApplied;

  OperationCharge({
    required this.client,
    required this.ship,
    required this.totalLsfo,
    required this.totalMgo,
    required this.totalShips,
    this.limit,
    this.dateApplied,
  });

  double get totalVolume => totalLsfo + totalMgo;
  bool get isWfs => client.toUpperCase().contains('WFS');
  double get effectiveLimit => limit ?? (isWfs ? 15000.0 : 17500.0);
  bool get exceedsLimit => totalVolume > effectiveLimit;
  double get surplus => exceedsLimit ? totalVolume - effectiveLimit : 0.0;

  factory OperationCharge.fromJson(Map<String, dynamic> json) {
    return OperationCharge(
      client: json['client'] ?? '',
      ship: json['ship'] ?? '',
      totalLsfo: (json['total_lsfo'] as num?)?.toDouble() ?? 0.0,
      totalMgo: (json['total_mgo'] as num?)?.toDouble() ?? 0.0,
      totalShips: (json['total_ships'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toDouble(),
      dateApplied: json['date_applied'] != null ? DateTime.tryParse(json['date_applied'].toString()) : null,
    );
  }
}

// Schedule Model
class Schedule {
  final String id;
  final String shipId;
  final DateTime date;
  final String cargoType;
  final String details;

  Schedule({
    required this.id,
    required this.shipId,
    required this.date,
    required this.cargoType,
    required this.details,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    String ship = json['ship']?.toString() ?? json['ship_id']?.toString() ?? json['voyage_number']?.toString() ?? 'Buque Flota';
    String cargo = json['cargo_type']?.toString() ?? json['observations']?.toString() ?? 'Operación Naviera';
    String details = json['details']?.toString() ?? '';

    if (json['date'] != null) {
      try {
        parsedDate = DateTime.parse(json['date'].toString());
      } catch (_) {}
    } else if (json['start_date_time'] != null) {
      try {
        parsedDate = DateTime.parse(json['start_date_time'].toString());
      } catch (_) {}
    } else if (json['records_detail'] is List && (json['records_detail'] as List).isNotEmpty) {
      final records = json['records_detail'] as List;
      final firstRec = records.first;
      if (firstRec is Map && firstRec['start_date_time'] != null) {
        try {
          parsedDate = DateTime.parse(firstRec['start_date_time'].toString());
        } catch (_) {}
      }
      final stages = records.map((r) => r['stage']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().join(' ➔ ');
      final obs = records.map((r) => r['observations']?.toString() ?? '').where((o) => o.isNotEmpty).toSet().join(', ');
      if (obs.isNotEmpty) cargo = obs;
      if (stages.isNotEmpty) details = "Ruta: $stages";
    }

    // Check if sheet_name provides month and year (e.g. "AGOSTO 2026")
    if (json['sheet_name'] != null) {
      final sheet = json['sheet_name'].toString().toUpperCase();
      final yearMatch = RegExp(r'\b(202\d|2\d)\b').firstMatch(sheet);
      int targetYear = parsedDate.year;
      if (yearMatch != null) {
        String yStr = yearMatch.group(1)!;
        if (yStr.length == 2) yStr = "20$yStr";
        targetYear = int.tryParse(yStr) ?? targetYear;
      }

      const monthsArr = [
        {"name": "ENERO", "num": 1},
        {"name": "FEBRERO", "num": 2},
        {"name": "MARZO", "num": 3},
        {"name": "ABRIL", "num": 4},
        {"name": "MAYO", "num": 5},
        {"name": "JUNIO", "num": 6},
        {"name": "JULIO", "num": 7},
        {"name": "AGOSTO", "num": 8},
        {"name": "SEPTIEMBRE", "num": 9},
        {"name": "OCTUBRE", "num": 10},
        {"name": "NOVIEMBRE", "num": 11},
        {"name": "DICIEMBRE", "num": 12}
      ];

      for (var m in monthsArr) {
        if (sheet.contains(m["name"] as String)) {
          int mNum = m["num"] as int;
          parsedDate = DateTime(targetYear, mNum, parsedDate.day.clamp(1, 28));
          break;
        }
      }
    }

    return Schedule(
      id: json['id']?.toString() ?? '',
      shipId: ship,
      date: parsedDate,
      cargoType: cargo,
      details: details.isNotEmpty ? details : "Etapa: ${json['stage'] ?? 'N/A'} | Carga: ${json['load'] ?? '0'} m³",
    );
  }
}

// Incident Model
enum IncidentStatus { open, inReview, resolved }

extension IncidentStatusExtension on IncidentStatus {
  String get rawValue {
    switch (this) {
      case IncidentStatus.open: return "Abierto";
      case IncidentStatus.inReview: return "En Revisión";
      case IncidentStatus.resolved: return "Resuelto";
    }
  }

  static IncidentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case "process":
      case "en revisión":
      case "inreview": return IncidentStatus.inReview;
      case "resolved":
      case "resuelto": return IncidentStatus.resolved;
      case "open":
      case "abierto":
      default: return IncidentStatus.open;
    }
  }
}

class Incident {
  final String id;
  final String description;
  final String shipId;
  final String reporterId;
  final DateTime date;
  final IncidentStatus status;
  final List<String> photoURLs;

  Incident({
    required this.id,
    required this.description,
    required this.shipId,
    required this.reporterId,
    required this.date,
    required this.status,
    this.photoURLs = const [],
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    var photos = json['photos'];
    List<String> photoList = [];
    if (photos is List) {
      photoList = photos.map((e) => e.toString()).toList();
    } else if (photos is String && photos.isNotEmpty) {
      photoList = [photos];
    }
    return Incident(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? '',
      shipId: json['ship_id']?.toString() ??
          json['ship']?.toString() ??
          json['vessel']?.toString() ??
          json['vessel_detail']?['id']?.toString() ??
          '',
      reporterId: json['reporter_id']?.toString() ??
          json['created_by']?.toString() ??
          '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : (json['date_time'] != null
              ? DateTime.parse(json['date_time'])
              : (json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now())),
      status: IncidentStatusExtension.fromString(json['status'] ?? json['state'] ?? ''),
      photoURLs: photoList,
    );
  }
}

// Goal Model
class Goal {
  final String id;
  final String description;
  final String expectedValue;
  final String? achievedValue;
  final String weightedValue;
  final String targetDate;
  final String goalType;
  final String leaderId;
  final String userId;
  final bool? userAgrees;
  final String? userConfirmationDate;
  final String? userConfirmationComment;

  Goal({
    required this.id,
    required this.description,
    required this.expectedValue,
    this.achievedValue,
    required this.weightedValue,
    required this.targetDate,
    required this.goalType,
    required this.leaderId,
    this.userId = '',
    this.userAgrees,
    this.userConfirmationDate,
    this.userConfirmationComment,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> goalData = json['goal'] is Map<String, dynamic>
        ? json['goal'] as Map<String, dynamic>
        : (json['goal_detail'] is Map<String, dynamic>
            ? json['goal_detail'] as Map<String, dynamic>
            : json);

    return Goal(
      id: json['id']?.toString() ?? goalData['id']?.toString() ?? '',
      description: goalData['description'] ?? json['description'] ?? '',
      expectedValue: json['expected_value']?.toString() ?? goalData['expected_value']?.toString() ?? json['progress']?.toString() ?? '',
      achievedValue: json['achieved_value']?.toString() ?? goalData['achieved_value']?.toString() ?? json['progress']?.toString(),
      weightedValue: json['weighted_value']?.toString() ?? goalData['weighted_value']?.toString() ?? '',
      targetDate: json['target_date'] ?? goalData['target_date'] ?? '',
      goalType: goalData['goal_type'] ?? json['goal_type'] ?? '',
      leaderId: goalData['leader']?.toString() ?? goalData['leader_id']?.toString() ?? '',
      userId: json['user']?.toString() ?? json['user_id']?.toString() ?? '',
      userAgrees: json['user_agrees'] as bool?,
      userConfirmationDate: json['user_confirmation_date']?.toString(),
      userConfirmationComment: json['user_confirmation_comment']?.toString(),
    );
  }
}

// AppNotification Model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['titulo'] ?? json['title'] ?? '',
      message: json['mensaje'] ?? json['message'] ?? '',
      timestamp: json['ts'] != null 
          ? DateTime.parse(json['ts']) 
          : (json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now()),
      isRead: json['read'] ?? json['is_read'] ?? false,
    );
  }
}

// Training & TrainingConsumption Models (from /api/v1/trainings/ & /api/v1/trainings/consumption/)
class TrainingModule {
  final int id;
  final String title;
  final int durationMinutes;
  final bool isCompleted;

  TrainingModule({
    required this.id,
    required this.title,
    required this.durationMinutes,
    this.isCompleted = false,
  });

  TrainingModule copyWith({bool? isCompleted}) {
    return TrainingModule(
      id: id,
      title: title,
      durationMinutes: durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory TrainingModule.fromJson(Map<String, dynamic> json) {
    return TrainingModule(
      id: (json['id'] as num?)?.toInt() ?? (json['pk'] as num?)?.toInt() ?? 0,
      title: json['title'] ?? json['titulo'] ?? json['nombre'] ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? (json['duracion_minutos'] as num?)?.toInt() ?? 15,
      isCompleted: json['is_completed'] == true || json['completado'] == true,
    );
  }
}

class Training {
  final int id;
  final String slug;
  final String title;
  final String code;
  final int hours;
  final String sector;
  final double completionRate;
  final String status;
  final String description;
  final String instructor;
  final String? videoUrl;
  final int completedModules;
  final int totalModules;
  final List<TrainingModule> modules;

  Training({
    required this.id,
    this.slug = '',
    required this.title,
    required this.code,
    required this.hours,
    required this.sector,
    required this.completionRate,
    required this.status,
    this.description = '',
    this.instructor = '',
    this.videoUrl,
    this.completedModules = 0,
    this.totalModules = 0,
    this.modules = const [],
  });

  double get userProgressPercentage {
    if (totalModules == 0) return completionRate;
    return ((completedModules / totalModules) * 100).clamp(0.0, 100.0);
  }

  Training copyWith({
    int? completedModules,
    double? completionRate,
    List<TrainingModule>? modules,
    String? status,
    String? videoUrl,
  }) {
    return Training(
      id: id,
      slug: slug,
      title: title,
      code: code,
      hours: hours,
      sector: sector,
      completionRate: completionRate ?? this.completionRate,
      status: status ?? this.status,
      description: description,
      instructor: instructor,
      videoUrl: videoUrl ?? this.videoUrl,
      completedModules: completedModules ?? this.completedModules,
      totalModules: totalModules,
      modules: modules ?? this.modules,
    );
  }

  factory Training.fromJson(Map<String, dynamic> json) {
    var rawMods = json['modules'] as List? ?? json['modulos'] as List? ?? [];
    List<TrainingModule> modLists = rawMods.map((m) => TrainingModule.fromJson(m)).toList();
    
    int doneMods = (json['completed_modules'] as num?)?.toInt() ??
                   (json['modulos_completados'] as num?)?.toInt() ??
                   (rawMods.where((m) => m['is_completed'] == true || m['completado'] == true).length);
    int totMods = (json['total_modules'] as num?)?.toInt() ??
                  (json['modulos_totales'] as num?)?.toInt() ??
                  modLists.length;

    double rate = (json['completion_rate'] as num?)?.toDouble() ??
                  (json['porcentaje_cumplimiento'] as num?)?.toDouble() ??
                  (json['progress'] as num?)?.toDouble() ?? 0.0;

    String? vUrl = json['video_url']?.toString() ??
                   json['url_video']?.toString() ??
                   json['video']?.toString() ??
                   json['file']?.toString() ??
                   json['file_url']?.toString() ??
                   json['url']?.toString() ??
                   json['archivo']?.toString();

    if ((vUrl == null || vUrl.trim().isEmpty) && json['files'] is List && (json['files'] as List).isNotEmpty) {
      for (final f in (json['files'] as List)) {
        if (f is Map<String, dynamic>) {
          final candidate = f['url']?.toString() ??
                            f['file']?.toString() ??
                            f['file_url']?.toString() ??
                            f['video_url']?.toString() ??
                            f['archivo']?.toString();
          if (candidate != null && candidate.trim().isNotEmpty) {
            vUrl = candidate;
            break;
          }
        } else if (f is String && f.trim().isNotEmpty) {
          vUrl = f;
          break;
        }
      }
    }

    if (vUrl != null && vUrl.trim().isNotEmpty) {
      String cleanUrl = vUrl.trim();
      if (!cleanUrl.contains('?')) {
        while (cleanUrl.endsWith('/')) {
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1).trim();
        }
      }
      vUrl = cleanUrl;
    } else {
      vUrl = null;
    }

    final slugStr = json['slug']?.toString() ?? json['id']?.toString() ?? '';
    final parsedId = (json['id'] as num?)?.toInt() ??
                     int.tryParse(json['id']?.toString() ?? '') ??
                     slugStr.hashCode;

    return Training(
      id: parsedId,
      slug: slugStr,
      title: json['title'] ?? json['titulo'] ?? json['nombre'] ?? json['name'] ?? '',
      code: json['code'] ?? json['codigo'] ?? '',
      hours: (json['hours'] as num?)?.toInt() ?? (json['duracion_horas'] as num?)?.toInt() ?? (json['horas'] as num?)?.toInt() ?? 0,
      sector: json['sector'] ?? json['categoria'] ?? 'General',
      completionRate: rate,
      status: json['status'] ?? json['estado'] ?? 'pending',
      description: json['description'] ?? json['descripcion'] ?? '',
      instructor: json['instructor'] ?? json['instructor_name'] ?? json['profesor'] ?? json['docente'] ?? '',
      videoUrl: vUrl,
      completedModules: doneMods,
      totalModules: totMods,
      modules: modLists,
    );
  }
}

class ShipTrainingConsumption {
  final String ship;
  final int hours;
  final double completionRate;

  ShipTrainingConsumption({
    required this.ship,
    required this.hours,
    required this.completionRate,
  });

  factory ShipTrainingConsumption.fromJson(Map<String, dynamic> json) {
    return ShipTrainingConsumption(
      ship: json['ship'] ?? '',
      hours: (json['hours'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TrainingConsumption {
  final int totalHoursConsumed;
  final int totalTrainingsCompleted;
  final double complianceRate;
  final int activeCertificates;
  final List<ShipTrainingConsumption> consumptionByShip;

  TrainingConsumption({
    required this.totalHoursConsumed,
    required this.totalTrainingsCompleted,
    required this.complianceRate,
    required this.activeCertificates,
    required this.consumptionByShip,
  });

  factory TrainingConsumption.fromJson(Map<String, dynamic> json) {
    var rawList = json['consumption_by_ship'] as List? ?? [];
    List<ShipTrainingConsumption> list = rawList.map((i) => ShipTrainingConsumption.fromJson(i)).toList();

    return TrainingConsumption(
      totalHoursConsumed: (json['total_hours_consumed'] as num?)?.toInt() ?? 0,
      totalTrainingsCompleted: (json['total_trainings_completed'] as num?)?.toInt() ?? 0,
      complianceRate: (json['compliance_rate'] as num?)?.toDouble() ?? 0.0,
      activeCertificates: (json['active_certificates'] as num?)?.toInt() ?? 0,
      consumptionByShip: list,
    );
  }
}
