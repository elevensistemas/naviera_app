import 'package:flutter/material.dart';
import 'ncs_header_data.dart';

/// Componente de cabecera reutilizable para la app Naviera Cruz del Sur.
/// Carga la imagen del buque ALFA C y atardecer directamente en memoria
/// para garantizar visualización instantánea en Flutter Web sin depender del dev server asset manifest.
class NcsHeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const NcsHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  static const String assetPath = 'assets/images/header_bg.png';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adaptación responsive: en móvil usa ~150px y en escritorio escala hasta 230px para mantener la altura adecuada
    final double headerHeight = (screenWidth * 0.16).clamp(150.0, 230.0);

    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: headerHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: const LinearGradient(
              colors: [
                Color(0xFF002855), // Deep Naviera Navy
                Color(0xFF00509D), // Royal Brand Blue
                Color(0xFF023E8A), // Mid Sea Blue
                Color(0xFFD97706), // Warm Sunset Amber
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Renderizado garantizado en memoria anclado abajo a la derecha para ver el barco ALFA C completo
                Positioned.fill(
                  child: Image.memory(
                    ncsHeaderImageBytes,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomRight,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomRight,
                        errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),

                // Textos dinámicos superpuestos sobre la imagen del ALFA C (debajo del logo oficial)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22.0, 48.0, 18.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Título dinámico del módulo
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          title,
                          key: ValueKey(title),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtítulo dinámico del módulo
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          subtitle,
                          key: ValueKey(subtitle),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
