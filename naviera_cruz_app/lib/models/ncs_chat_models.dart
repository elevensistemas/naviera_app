import 'dart:convert';

class NCSStreamEvent {
  final String type; // "log", "result", "error"
  final String? logClass; // "info", "warning", "error"
  final String? content;
  final NCSStructuredVesselData? structured;

  NCSStreamEvent({
    required this.type,
    this.logClass,
    this.content,
    this.structured,
  });

  factory NCSStreamEvent.fromJson(Map<String, dynamic> json) {
    return NCSStreamEvent(
      type: json['type'] ?? 'log',
      logClass: json['class'] ?? json['logClass'],
      content: json['content'] as String?,
      structured: json['structured'] != null
          ? NCSStructuredVesselData.fromJson(
              json['structured'] is String
                  ? jsonDecode(json['structured'])
                  : json['structured'],
            )
          : null,
    );
  }
}

class NCSStructuredVesselData {
  final String? vesselName;
  final String? status;
  final String? speed;
  final String? coordinates;
  final String? eta;
  final String? fuelLevel;
  final String? cargoWeight;

  NCSStructuredVesselData({
    this.vesselName,
    this.status,
    this.speed,
    this.coordinates,
    this.eta,
    this.fuelLevel,
    this.cargoWeight,
  });

  factory NCSStructuredVesselData.fromJson(Map<String, dynamic> json) {
    String? parseStringOrNum(dynamic val, [String? suffix]) {
      if (val == null) return null;
      if (suffix != null) {
        return "$val $suffix";
      }
      return val.toString();
    }

    return NCSStructuredVesselData(
      vesselName: json['vessel_name'] ?? json['vesselName'],
      status: json['status']?.toString(),
      speed: json['speed'] != null ? parseStringOrNum(json['speed'], 'nudos') : null,
      coordinates: json['coordinates']?.toString(),
      eta: json['eta']?.toString(),
      fuelLevel: json['fuel_level'] != null ? parseStringOrNum(json['fuel_level'], '%') : json['fuelLevel']?.toString(),
      cargoWeight: json['cargo_weight'] != null ? parseStringOrNum(json['cargo_weight'], 'Ton') : json['cargoWeight']?.toString(),
    );
  }
}

enum NCSMessageSender { user, assistant, system }

class NCSLogItem {
  final String id;
  final String category;
  final String message;
  final DateTime timestamp;

  NCSLogItem({
    required this.id,
    required this.category,
    required this.message,
    required this.timestamp,
  });
}

class NCSAIMessage {
  final String id;
  final NCSMessageSender sender;
  String text;
  List<NCSLogItem> logs;
  NCSStructuredVesselData? structuredData;
  final DateTime timestamp;
  bool isStreaming;
  bool isAudioPlaying;

  NCSAIMessage({
    required this.id,
    required this.sender,
    required this.text,
    List<NCSLogItem>? logs,
    this.structuredData,
    DateTime? timestamp,
    this.isStreaming = false,
    this.isAudioPlaying = false,
  })  : logs = logs ?? [],
        timestamp = timestamp ?? DateTime.now();
}
