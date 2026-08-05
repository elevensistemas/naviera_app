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
      id: json['id']?.toString() ?? '',
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

class Ship {
  final String id;
  final String name;
  final ShipStatus status;
  final double totalCargo;
  final double latitude;
  final double longitude;
  final String? cameraUrl;

  Ship({
    required this.id,
    required this.name,
    required this.status,
    required this.totalCargo,
    required this.latitude,
    required this.longitude,
    this.cameraUrl,
  });

  factory Ship.fromJson(Map<String, dynamic> json) {
    return Ship(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      status: ShipStatusExtension.fromString(json['status'] ?? ''),
      totalCargo: (json['total_cargo'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      cameraUrl: json['camera_url'],
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
      text: json['text'] ?? '',
      attachmentURL: json['attachment'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
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
      shipId: json['ship_id']?.toString() ?? json['ship']?.toString() ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
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
    switch (value) {
      case "En Revisión":
      case "inReview": return IncidentStatus.inReview;
      case "Resuelto":
      case "resolved": return IncidentStatus.resolved;
      case "Abierto":
      case "open":
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
      shipId: json['ship_id']?.toString() ?? json['ship']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      status: IncidentStatusExtension.fromString(json['status'] ?? ''),
      photoURLs: photoList,
    );
  }
}
