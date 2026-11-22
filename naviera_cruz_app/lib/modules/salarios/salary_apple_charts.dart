import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ring circular estilo Apple Activity para KPI cards
class AppleMiniRing extends StatelessWidget {
  final double percentage; // 0.0 to 1.0
  final Color ringColor;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? centerChild;

  const AppleMiniRing({
    super.key,
    required this.percentage,
    required this.ringColor,
    this.backgroundColor,
    this.size = 54.0,
    this.strokeWidth = 6.0,
    this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = backgroundColor ??
        (isDark ? const Color(0x1FFFFFFF) : const Color(0x15000000));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _AppleRingPainter(
              percentage: percentage.clamp(0.0, 1.0),
              ringColor: ringColor,
              backgroundColor: effectiveBg,
              strokeWidth: strokeWidth,
            ),
          ),
          if (centerChild != null) centerChild!,
        ],
      ),
    );
  }
}

class _AppleRingPainter extends CustomPainter {
  final double percentage;
  final Color ringColor;
  final Color backgroundColor;
  final double strokeWidth;

  _AppleRingPainter({
    required this.percentage,
    required this.ringColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (percentage <= 0) return;

    // Progress Arc
    final fgPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AppleRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Gráfico de Dona / Pastel estilo Apple con leyenda y centro interactivo
class AppleDonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final String centerTitle;
  final String centerSubtitle;
  final double size;
  final double holeRadiusRatio;

  const AppleDonutChart({
    super.key,
    required this.segments,
    this.centerTitle = '',
    this.centerSubtitle = '',
    this.size = 200.0,
    this.holeRadiusRatio = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _AppleDonutPainter(
              segments: segments,
              total: total,
              holeRadiusRatio: holeRadiusRatio,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerTitle.isNotEmpty)
                Text(
                  centerTitle,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              if (centerSubtitle.isNotEmpty)
                Text(
                  centerSubtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.55) : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DonutSegment {
  final String label;
  final double value;
  final Color color;

  DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _AppleDonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double total;
  final double holeRadiusRatio;

  _AppleDonutPainter({
    required this.segments,
    required this.total,
    required this.holeRadiusRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * holeRadiusRatio;
    final strokeWidth = outerRadius - innerRadius;
    final midRadius = (outerRadius + innerRadius) / 2;

    double startAngle = -math.pi / 2;
    const gapAngle = 0.03; // separación estética sutil

    for (var seg in segments) {
      if (seg.value <= 0) continue;
      final sweepAngle = (seg.value / total) * 2 * math.pi;
      final effectiveSweep = sweepAngle > gapAngle ? sweepAngle - gapAngle : sweepAngle;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: midRadius),
        startAngle + (gapAngle / 2),
        effectiveSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _AppleDonutPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.segments != segments;
  }
}

/// Gráfico de Barras de Evolución Mensual Apple (Marzo a Octubre)
class AppleMonthlyBarsChart extends StatelessWidget {
  final List<MonthlyBarData> monthlyData;
  final String selectedPeriodCode;
  final ValueChanged<String> onSelectPeriod;

  const AppleMonthlyBarsChart({
    super.key,
    required this.monthlyData,
    required this.selectedPeriodCode,
    required this.onSelectPeriod,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = monthlyData.map((m) => m.cost).reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = ((constraints.maxWidth - (monthlyData.length * 8)) / monthlyData.length).clamp(24.0, 52.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: monthlyData.map((item) {
            final isSelected = item.periodCode == selectedPeriodCode;
            final double heightRatio = maxVal > 0 ? (item.cost / maxVal) : 0.0;
            final barHeight = (heightRatio * 130.0).clamp(16.0, 130.0);

            return GestureDetector(
              onTap: () => onSelectPeriod(item.periodCode),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.shortCostLabel,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF007AFF)
                          : (isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF64748B)),
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: barWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [const Color(0xFF007AFF), const Color(0xFF5856D6)]
                            : (isDark
                                ? [const Color(0xFF2C3E5D), const Color(0xFF1B283E)]
                                : [const Color(0xFFCBD5E1), const Color(0xFFE2E8F0)]),
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: isDark ? Colors.white : const Color(0xFF007AFF), width: 1.5)
                          : Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFCBD5E1)),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF007AFF).withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.monthLabel,
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF007AFF))
                          : (isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B)),
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class MonthlyBarData {
  final String periodCode;
  final String monthLabel;
  final double cost;
  final String shortCostLabel;

  MonthlyBarData({
    required this.periodCode,
    required this.monthLabel,
    required this.cost,
    required this.shortCostLabel,
  });
}
