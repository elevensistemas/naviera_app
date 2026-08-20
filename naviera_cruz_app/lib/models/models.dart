import 'package:flutter/foundation.dart';

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
    return User(
      id: (json['id'] ?? json['user_id'])?.toString() ?? '',
      name: json['name'] ?? json['username'] ?? '',
      role: json['role'] ?? 'Personal Naviera',
      avatarURL: json['avatar_url'],
      sector: json['sector'] ?? 'Operaciones',
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
  final String content;
  final DateTime timestamp;
  final PostType type;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    required this.type,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorName: json['author_name'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      type: PostTypeExtension.fromString(json['type'] ?? ''),
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
  final double latitude;
  final double longitude;
  final String? cameraUrl;
  final List<ShipCamera> cameras;

  Ship({
    required this.id,
    required this.name,
    required this.status,
    required this.totalCargo,
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
    return Ship(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['description'] ?? json['code'] ?? '',
      status: json['status'] != null
          ? ShipStatusExtension.fromString(json['status'])
          : (json['active'] == true ? ShipStatus.active : ShipStatus.docked),
      totalCargo: (json['total_carbon'] as num?)?.toDouble() ?? (json['total_cargo'] as num?)?.toDouble() ?? 0.0,
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
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      text: json['content'] ?? json['text'] ?? '',
      attachmentURL: json['attachment_url'] ?? json['attachment'],
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now()),
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

  CrewMember({
    required this.id,
    required this.shipId,
    required this.name,
    required this.role,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      id: json['id']?.toString() ?? '',
      shipId: json['ship_id']?.toString() ??
          json['ship']?.toString() ??
          json['current_ship_detail']?['id']?.toString() ??
          json['current_situation_detail']?['ship']?.toString() ??
          '',
      name: json['name'] ?? '',
      role: json['role'] ??
          json['position_detail']?['name'] ??
          json['position_detail']?['short_name'] ??
          '',
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
    return Schedule(
      id: json['id']?.toString() ?? '',
      shipId: json['ship_id']?.toString() ?? json['ship']?.toString() ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      cargoType: json['cargo_type'] ?? '',
      details: json['details'] ?? '',
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

  Goal({
    required this.id,
    required this.description,
    required this.expectedValue,
    this.achievedValue,
    required this.weightedValue,
    required this.targetDate,
    required this.goalType,
    required this.leaderId,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? '',
      expectedValue: json['expected_value']?.toString() ?? '',
      achievedValue: json['achieved_value']?.toString(),
      weightedValue: json['weighted_value']?.toString() ?? '',
      targetDate: json['target_date'] ?? '',
      goalType: json['goal_type'] ?? '',
      leaderId: json['leader']?.toString() ?? '',
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
