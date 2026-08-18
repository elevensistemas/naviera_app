import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    // logo_NCS.svg is for dark backgrounds (white version)
    // logo2.svg is for light backgrounds
    final assetName = isWhiteVersion ? 'assets/logo/logo_NCS.svg' : 'assets/logo/logo2.svg';

    return SvgPicture.asset(
      assetName,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
