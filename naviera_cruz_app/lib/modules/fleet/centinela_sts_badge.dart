import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/centinela_fleet_models.dart';
import 'centinela_ocimf_sheet.dart';

class CentinelaStsBadge extends StatelessWidget {
  final CentinelaStsRisk? stsRisk;
  final String vesselName;
  final bool isLoading;
  final VoidCallback? onTap;

  const CentinelaStsBadge({
    super.key,
    required this.stsRisk,
    required this.vesselName,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = stsRisk != null && stsRisk!.hasSufficientData;
    final score = hasData ? "${stsRisk!.score}" : "S/D";
    final borderColor = hasData ? stsRisk!.stsColor : const Color(0xFF64748B);
    final isStale = stsRisk?.isStale == true;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (stsRisk != null) {
            CentinelaOcimfSheet.show(context, stsRisk: stsRisk!, vesselName: vesselName);
          }
        },
        child: Container(
          width: 57,
          height: 57,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isStale ? borderColor.withValues(alpha: 0.5) : borderColor,
              width: 2.8,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: isStale ? 0.15 : 0.35),
                blurRadius: 10,
                spreadRadius: 1.2,
              ),
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: const Color(0xD90B132B), // Dark translucent Apple style
                      ),
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  child: isLoading && stsRisk == null
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(borderColor),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              score,
                              style: TextStyle(
                                color: isStale ? Colors.white70 : Colors.white,
                                fontSize: score.length > 2 ? 17.5 : 19.0,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              "STS",
                              style: TextStyle(
                                color: borderColor,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                                letterSpacing: 0.5,
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

