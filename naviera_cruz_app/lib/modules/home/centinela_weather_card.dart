import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../app/theme.dart';
import 'weather_backgrounds_data.dart';

class CentinelaWeatherCard extends StatelessWidget {
  final CentinelaWeatherData? weather;
  final bool isLoading;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? margin;

  const CentinelaWeatherCard({
    super.key,
    required this.weather,
    this.isLoading = false,
    this.onRetry,
    this.margin,
  });

  String _formatDeviceDateTime() {
    final now = DateTime.now();
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    final weekday = weekdays[(now.weekday - 1).clamp(0, 6)];
    final month = months[(now.month - 1).clamp(0, 11)];
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return "$weekday ${now.day} de $month • $hour:$minute hs";
  }

  Uint8List _getWeatherBackgroundBytes(CurrentWeather current) {
    final isDay = current.isDay;
    final code = current.conditionCode.toLowerCase();
    final text = current.condition.toLowerCase();

    // 1. Tormenta / Relámpagos
    if (code.contains('thunder') ||
        code.contains('storm') ||
        text.contains('tormenta') ||
        text.contains('relámpago') ||
        text.contains('rayo')) {
      return weatherThunderstormBytes;
    }

    // 2. Lluvia / Chubascos
    if (code.contains('rain') ||
        code.contains('drizzle') ||
        code.contains('shower') ||
        text.contains('lluvia') ||
        text.contains('llovizna') ||
        text.contains('chubasco')) {
      return weatherRainBytes;
    }

    // 3. Niebla / Neblina
    if (code.contains('fog') ||
        code.contains('mist') ||
        code.contains('haze') ||
        text.contains('niebla') ||
        text.contains('neblina') ||
        text.contains('bruma')) {
      return weatherFogBytes;
    }

    // 4. Horario Nocturno
    if (!isDay) {
      if (code.contains('cloud') ||
          code.contains('overcast') ||
          text.contains('nublado') ||
          text.contains('cubierto') ||
          text.contains('parcial')) {
        return weatherCloudyNightBytes;
      }
      return weatherClearNightBytes;
    }

    // 5. Horario Diurno: Nublado denso o cubierto
    if (code.contains('overcast') ||
        text.contains('cubierto') ||
        (code.contains('cloud') &&
            !code.contains('partly') &&
            (text.contains('muy nublado') || text.contains('mayormente nublado')))) {
      return weatherCloudyBytes;
    }

    // 6. Horario Diurno: Parcialmente nublado / Casi Despejado / Algo nublado
    if (code.contains('partly') ||
        code.contains('cloud') ||
        text.contains('casi despejado') ||
        text.contains('algo nublado') ||
        text.contains('parcial')) {
      return weatherPartlyCloudyDayBytes;
    }

    // 7. Horario Diurno: Cielo totalmente despejado / Soleado
    return weatherClearDayBytes;
  }

  IconData _getWeatherIcon(CurrentWeather current) {
    if (!current.isDay) {
      final code = current.conditionCode.toLowerCase();
      if (code.contains('cloud') || code.contains('overcast')) {
        return Icons.nights_stay_rounded;
      }
      return Icons.nightlight_round;
    }

    final code = current.conditionCode.toLowerCase();
    final text = current.condition.toLowerCase();

    if (code.contains('thunder') || code.contains('storm')) {
      return Icons.thunderstorm_rounded;
    }
    if (code.contains('rain') || code.contains('drizzle') || code.contains('shower')) {
      return Icons.water_drop_rounded;
    }
    if (code.contains('fog') || code.contains('mist') || code.contains('haze')) {
      return Icons.blur_on_rounded;
    }
    if (code.contains('overcast') || text.contains('cubierto')) {
      return Icons.cloud_rounded;
    }
    if (code.contains('partly') || code.contains('cloud') || text.contains('casi despejado')) {
      return Icons.wb_sunny_rounded;
    }
    return Icons.wb_sunny_rounded;
  }

  Color _getWeatherIconColor(CurrentWeather current) {
    if (!current.isDay) {
      return const Color(0xFFE0E7FF);
    }
    final code = current.conditionCode.toLowerCase();
    if (code.contains('rain') || code.contains('shower')) {
      return const Color(0xFF38BDF8);
    }
    if (code.contains('cloud') || code.contains('overcast')) {
      return const Color(0xFFF1F5F9);
    }
    return const Color(0xFFFBBF24);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    // Estado 1: Cargando inicial sin datos previos
    if (isLoading && weather == null) {
      return Container(
        margin: margin ?? const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
            const SizedBox(width: 12),
            Text(
              "Obteniendo información meteorológica...",
              style: TextStyle(
                fontSize: 12.5,
                color: captionColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Estado 2: Servicio no disponible (estado discreto sin bloquear la pantalla)
    if (weather == null) {
      return Container(
        margin: margin ?? const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 13.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 18,
              color: captionColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Servicio meteorológico temporalmente no disponible",
                style: TextStyle(
                  fontSize: 12.5,
                  color: captionColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null)
              GestureDetector(
                onTap: onRetry,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    "Reintentar",
                    style: TextStyle(
                      fontSize: 12.0,
                      color: ColorTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final data = weather!;
    final bgBytes = _getWeatherBackgroundBytes(data.current);
    final weatherIcon = _getWeatherIcon(data.current);
    final iconColor = _getWeatherIconColor(data.current);

    final tempRound = data.current.temperatureC.round();
    final feelsLikeRound = data.current.feelsLikeC?.round();
    final maxRound = data.today?.maxC?.round();
    final minRound = data.today?.minC?.round();

    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Stack(
          children: [
            // 1. Imagen de fondo realista según clima y horario
            Positioned.fill(
              child: Image.memory(
                bgBytes,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),

            // 2. Capa de oscurecimiento suave para garantizar máxima legibilidad de tipografía
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Contenido de la tarjeta
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fila Superior: Ubicación y Fecha / Hora Local
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    data.location.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                if (data.location.country.isNotEmpty) ...[
                                  Text(
                                    ", ${data.location.country}",
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDeviceDateTime(),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ícono circular translúcido
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            weatherIcon,
                            size: 26,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Fila Central: Temperatura Destacada y Condiciones
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "$tempRound°",
                        style: const TextStyle(
                          fontSize: 48.0,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -2.0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.current.condition,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (maxRound != null && minRound != null) ...[
                                  Text(
                                    "Máx. $maxRound° • Mín. $minRound°",
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.90),
                                    ),
                                  ),
                                ],
                                if (feelsLikeRound != null && feelsLikeRound != tempRound) ...[
                                  Text(
                                    " • Sens. $feelsLikeRound°",
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.90),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Fila Inferior: Telemetría (Viento, Ráfagas, Humedad, Precipitación)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Viento y ráfagas
                        Icon(
                          Icons.air_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _formatWind(data.current.windKmh, data.current.windGustsKmh),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Humedad
                        if (data.current.humidityPercent != null) ...[
                          Icon(
                            Icons.water_drop_outlined,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${data.current.humidityPercent}%",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Probabilidad de precipitación
                        if (data.today?.precipitationProbability != null &&
                            data.today!.precipitationProbability! > 0) ...[
                          Icon(
                            Icons.umbrella_outlined,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${data.today!.precipitationProbability}%",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWind(double? windKmh, double? gustsKmh) {
    if (windKmh == null) return "Viento calmo";
    final w = windKmh.round();
    if (gustsKmh != null && gustsKmh > windKmh) {
      return "Viento $w km/h (ráf. ${gustsKmh.round()})";
    }
    return "Viento $w km/h";
  }
}
