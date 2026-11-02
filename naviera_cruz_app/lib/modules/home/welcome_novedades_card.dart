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
      margin: margin ?? const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF02172F),
            Color(0xFF012450),
            Color(0xFF003066),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02172F).withValues(alpha: 0.35),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Onda luminosa azul en el sector derecho del fondo
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 320,
              child: Opacity(
                opacity: 0.85,
                child: Image.memory(
                  ncsWaveBannerBytes,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),

            // Contenido frontal adaptable: Logo + Divisor + Textos nítidos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo oficial Naviera Cruz del Sur
                  Image.memory(
                    ncsLogoBannerBytes,
                    height: 46,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(width: 12),

                  // Divisor vertical
                  Container(
                    width: 1.2,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.30),
                  ),

                  const SizedBox(width: 14),

                  // Textos vectoriales nítidos adaptables a cualquier ancho de celular
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "Bienvenido a la app de NCS",
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Conectados a bordo y en tierra.",
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.82),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
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
}
