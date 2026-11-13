import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/centinela_fleet_models.dart';

class CentinelaOcimfSheet extends StatelessWidget {
  final CentinelaStsRisk stsRisk;
  final String vesselName;

  const CentinelaOcimfSheet({
    super.key,
    required this.stsRisk,
    required this.vesselName,
  });

  static Future<void> show(
    BuildContext context, {
    required CentinelaStsRisk stsRisk,
    required String vesselName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CentinelaOcimfSheet(stsRisk: stsRisk, vesselName: vesselName),
    );
  }

  IconData _getFactorIcon(String key) {
    switch (key.toLowerCase()) {
      case 'wind':
        return Icons.air_rounded;
      case 'wave':
        return Icons.waves_rounded;
      case 'current':
        return Icons.water_rounded;
      case 'visibility':
        return Icons.visibility_rounded;
      case 'weather':
        return Icons.cloud_rounded;
      default:
        return Icons.verified_user_rounded;
    }
  }

  Color _getEvaluationColor(String evalCode, String evalLabel) {
    final code = evalCode.toUpperCase();
    final label = evalLabel.toLowerCase();
    if (code == 'OPTIMAL' || label.contains('óptim') || label.contains('optimo') || label == '0%') {
      return const Color(0xFF00FFC8); // Verde óptimo Centinela
    } else if (code == 'MODERATE' || label.contains('moder')) {
      return const Color(0xFFFBBF24); // Amarillo
    } else if (code == 'CRITICAL' || label.contains('adver') || label.contains('crític')) {
      return const Color(0xFFEF4444); // Rojo
    }
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    final audit = stsRisk.ocimfAudit;
    final primaryColor = stsRisk.stsColor;
    final isStale = stsRisk.isStale;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: const Color(0xF20B132B), // Dark Apple glass translucent
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xEB0B132B),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle deslizable superior
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Cabecera: Título y Botón Cerrar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audit.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "$vesselName · ${audit.frameworkLabel}",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta de Zona y Referencia de Posición
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                audit.zoneName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (audit.zoneLocationRef.isNotEmpty)
                                Text(
                                  audit.zoneLocationRef,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isStale)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              "Datos Anteriores",
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Lista de los 5 factores OCIMF 2026 ON
                  ...audit.factorsOrder.map((factorKey) {
                    final factor = audit.factors[factorKey];
                    if (factor == null) return const SizedBox.shrink();

                    final evalColor = _getEvaluationColor(factor.evaluationLabel, factor.evaluationLabel);
                    final isFactorStale = factor.isStale;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFactorStale
                              ? Colors.amber.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFactorIcon(factor.key),
                            size: 18,
                            color: isFactorStale ? const Color(0xFFFBBF24) : primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  factor.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (factor.source.isNotEmpty)
                                  Text(
                                    factor.source,
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                factor.available ? factor.summaryText : "Sin datos",
                                style: TextStyle(
                                  color: factor.available ? evalColor : Colors.white54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (factor.available && isFactorStale)
                                const Text(
                                  "No verificado",
                                  style: TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Resumen Final: ÍNDICE TOTAL REAL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ÍNDICE TOTAL REAL",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stsRisk.hasSufficientData ? "EVALUACIÓN ÓPTIMA" : "DATOS INSUFICIENTES",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          stsRisk.hasSufficientData ? "${stsRisk.score}%" : "S/D",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Nota de validación matemática y frescura
                  Center(
                    child: Text(
                      audit.validationNote,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),
),
);
  }
}
