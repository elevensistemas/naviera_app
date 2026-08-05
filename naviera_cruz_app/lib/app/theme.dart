import 'package:flutter/material.dart';

class ColorTheme {
  static const Color primary = Color(0xFF0A2540);
  static const Color accent = Color(0xFF00E5FF);
  
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color danger = Colors.red;
  static const Color info = Colors.blue;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: Colors.white,
        background: Color(0xFFF1F5F9), // Slate 100
        error: danger,
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xE0E2E8F0), // Slate 200
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: Color(0xFF1E293B), // Slate 800
        background: Color(0xFF0F172A), // Slate 900
        error: danger,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E293B),
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x20FFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: accent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF1E293B),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class TypographyTheme {
  static TextStyle title2(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: color ?? theme.colorScheme.onSurface,
    );
  }

  static TextStyle headline(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: color ?? theme.colorScheme.onSurface,
    );
  }

  static TextStyle body(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: color ?? theme.colorScheme.onSurface.withOpacity(0.8),
    );
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: color ?? theme.colorScheme.onSurface.withOpacity(0.6),
    );
  }
}
