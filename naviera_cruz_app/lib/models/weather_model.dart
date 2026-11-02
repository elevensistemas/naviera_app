class WeatherLocation {
  final String name;
  final String country;
  final String timezone;

  const WeatherLocation({
    required this.name,
    required this.country,
    required this.timezone,
  });

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      name: json['name']?.toString() ?? 'Buenos Aires',
      country: json['country']?.toString() ?? 'AR',
      timezone: json['timezone']?.toString() ?? '',
    );
  }
}

class CurrentWeather {
  final double temperatureC;
  final double? feelsLikeC;
  final String condition;
  final String conditionCode;
  final bool isDay;
  final int? humidityPercent;
  final double? windKmh;
  final double? windGustsKmh;

  const CurrentWeather({
    required this.temperatureC,
    this.feelsLikeC,
    required this.condition,
    required this.conditionCode,
    required this.isDay,
    this.humidityPercent,
    this.windKmh,
    this.windGustsKmh,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    num? gusts = (json['wind_gusts_kmh'] ?? json['gusts_kmh'] ?? json['wind_gusts']) as num?;
    return CurrentWeather(
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 0.0,
      feelsLikeC: (json['feels_like_c'] as num?)?.toDouble(),
      condition: json['condition']?.toString() ?? 'Despejado',
      conditionCode: json['condition_code']?.toString() ?? 'clear',
      isDay: json['is_day'] == true || json['is_day'] == 1,
      humidityPercent: (json['humidity_percent'] as num?)?.toInt(),
      windKmh: (json['wind_kmh'] as num?)?.toDouble(),
      windGustsKmh: gusts?.toDouble(),
    );
  }
}

class TodayWeather {
  final double? maxC;
  final double? minC;
  final int? precipitationProbability;

  const TodayWeather({
    this.maxC,
    this.minC,
    this.precipitationProbability,
  });

  factory TodayWeather.fromJson(Map<String, dynamic> json) {
    return TodayWeather(
      maxC: (json['max_c'] as num?)?.toDouble(),
      minC: (json['min_c'] as num?)?.toDouble(),
      precipitationProbability: (json['precipitation_probability_percent'] as num?)?.toInt(),
    );
  }
}

class CentinelaWeatherData {
  final String status;
  final WeatherLocation location;
  final CurrentWeather current;
  final TodayWeather? today;
  final String source;
  final DateTime? updatedAt;
  final bool isStale;

  const CentinelaWeatherData({
    required this.status,
    required this.location,
    required this.current,
    this.today,
    required this.source,
    this.updatedAt,
    this.isStale = false,
  });

  factory CentinelaWeatherData.fromJson(Map<String, dynamic> json) {
    return CentinelaWeatherData(
      status: json['status']?.toString() ?? 'ok',
      location: WeatherLocation.fromJson(
        (json['location'] as Map<String, dynamic>?) ?? {},
      ),
      current: CurrentWeather.fromJson(
        (json['current'] as Map<String, dynamic>?) ?? {},
      ),
      today: json['today'] != null
          ? TodayWeather.fromJson(json['today'] as Map<String, dynamic>)
          : null,
      source: json['source']?.toString() ?? 'Centinela',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      isStale: json['stale'] == true,
    );
  }
}

