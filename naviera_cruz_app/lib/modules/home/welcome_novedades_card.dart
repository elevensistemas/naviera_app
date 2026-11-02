import 'package:flutter/material.dart';
import 'welcome_banner_data.dart';

class WelcomeNovedadesCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const WelcomeNovedadesCard({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Proporción original del banner: 1024 / 107 = ~9.57
            // En pantallas de escritorio / web escala proporcionalmente.
            // En dispositivos móviles se mantiene una altura mínima confortable para legibilidad del logo y texto.
            final double targetHeight =
                (constraints.maxWidth / (1024 / 107)).clamp(74.0, 115.0);

            return SizedBox(
              width: double.infinity,
              height: targetHeight,
              child: Image.memory(
                welcomeBannerBytes,
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              ),
            );
          },
        ),
      ),
    );
  }
}
