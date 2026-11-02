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
      margin: margin ?? const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AspectRatio(
            aspectRatio: 1024 / 512,
            child: Image.memory(
              welcomeNcsBannerBytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
