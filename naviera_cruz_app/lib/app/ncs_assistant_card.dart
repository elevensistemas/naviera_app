import 'package:flutter/material.dart';

/// Tarjeta premium del Asistente NCS con diseño oceánico,
/// resplandor radial, curvas de ondas marítimas y estética Liquid Glass.
class NcsAssistantCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String subtitle;
  final EdgeInsetsGeometry? margin;

  const NcsAssistantCard({
    super.key,
    this.onTap,
    this.title = "Asistente NCS",
    this.subtitle = "Consultá procedimientos, documentos\ny normativa del SGS.",
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.0,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF063A89), // Deep ocean royal sapphire
            Color(0xFF0E54BA), // Rich electric navy
            Color(0xFF1B6BE5), // Vibrant cobalt blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E54BA).withValues(alpha: isDark ? 0.40 : 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF1B6BE5).withValues(alpha: isDark ? 0.20 : 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Resplandor radial celeste / cian en esquina inferior derecha
            Positioned(
              right: -25,
              bottom: -35,
              child: Container(
                width: 150,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38BDF8).withValues(alpha: 0.35),
                      const Color(0xFF2563EB).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Ondas marítimas y tecnológicas sutiles en la esquina inferior derecha
            Positioned(
              right: 0,
              bottom: 0,
              width: 150,
              height: 75,
              child: CustomPaint(
                painter: _NcsAssistantWavePainter(),
              ),
            ),

            // Contenido interactivo con InkWell
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.white.withValues(alpha: 0.12),
                highlightColor: Colors.white.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
                      // Squircle con gradiente cian-azul-índigo e icono de chispas IA
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF38BDF8), // Cyan glow
                              Color(0xFF2563EB), // Electric blue
                              Color(0xFF4F46E5), // Indigo accent
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.40),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Textos del Asistente (Título + Subtítulo de 2 líneas)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12.0,
                                height: 1.25,
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Botón circular chevron traslúcido
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter de líneas onduladas suaves y luminosas
class _NcsAssistantWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wave1Paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final wave2Paint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final wave3Paint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Onda 1 (superior/media)
    final path1 = Path();
    path1.moveTo(0, size.height * 0.72);
    path1.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.18,
      size.width,
      size.height * 0.52,
    );
    canvas.drawPath(path1, wave1Paint);

    // Onda 2 (inferior/intermedia)
    final path2 = Path();
    path2.moveTo(size.width * 0.18, size.height);
    path2.quadraticBezierTo(
      size.width * 0.62,
      size.height * 0.38,
      size.width,
      size.height * 0.76,
    );
    canvas.drawPath(path2, wave2Paint);

    // Onda 3 (delicada inferior)
    final path3 = Path();
    path3.moveTo(size.width * 0.38, size.height);
    path3.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.60,
      size.width,
      size.height * 0.94,
    );
    canvas.drawPath(path3, wave3Paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
