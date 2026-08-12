import 'package:flutter/material.dart';

class NavieraLogo extends StatelessWidget {
  final double size;
  final Color? textColor;
  final Color? activeColor;
  final Color? orangeColor;
  final bool isWhiteVersion;

  const NavieraLogo({
    super.key,
    this.size = 60,
    this.textColor,
    this.activeColor,
    this.orangeColor,
    this.isWhiteVersion = false,
  });

  @override
  Widget build(BuildContext context) {
    final double circleSize = size / 5.5;
    final double spacing = size / 15;

    final Color primaryActive = activeColor ?? (isWhiteVersion ? Colors.white : const Color(0xFF0055B8));
    final Color primaryOrange = isWhiteVersion 
        ? Colors.white 
        : (orangeColor ?? const Color(0xFFF28000));
    final Color finalTextColor = textColor ?? (isWhiteVersion ? Colors.white : const Color(0xFF0055B8));

    // Grid definition: true = active (filled), false = inactive (outline), null = orange
    final List<List<dynamic>> grid = [
      [false, true, false, true],
      [false, false, null, false],
      [false, false, false, true],
      [true, false, false, false],
    ];

    Widget buildCircle(dynamic type) {
      if (type == null) {
        // Orange circle
        return Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: primaryOrange,
            shape: BoxShape.circle,
          ),
        );
      } else if (type == true) {
        // Filled circle
        return Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: primaryActive,
            shape: BoxShape.circle,
          ),
        );
      } else {
        // Outline circle
        return Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryActive,
              width: 1.8,
            ),
          ),
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 4x4 Grid
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (r) {
            return Padding(
              padding: EdgeInsets.only(bottom: r < 3 ? spacing : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (c) {
                  return Padding(
                    padding: EdgeInsets.only(right: c < 3 ? spacing : 0),
                    child: buildCircle(grid[r][c]),
                  );
                }),
              ),
            );
          }),
        ),
        SizedBox(width: size / 3.5),
        // Text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "NAVIERA",
              style: TextStyle(
                color: finalTextColor,
                fontSize: size / 4.8,
                fontWeight: FontWeight.bold,
                height: 1.0,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              "CRUZ",
              style: TextStyle(
                color: finalTextColor,
                fontSize: size / 2.4,
                fontWeight: FontWeight.w900,
                height: 0.95,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "DEL",
              style: TextStyle(
                color: finalTextColor,
                fontSize: size / 2.4,
                fontWeight: FontWeight.w900,
                height: 0.95,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "SUR",
              style: TextStyle(
                color: finalTextColor,
                fontSize: size / 2.4,
                fontWeight: FontWeight.w900,
                height: 0.95,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
