import 'package:flutter/material.dart';

abstract final class AppColors {
  static const paper = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE0E0E0);
  static const fill = Color(0xFFF5F5F5);
  static const ink = Color(0xFF171717);
  static const secondary = Color(0xFF555555);
  static const muted = Color(0xFF999999);
  static const accent = Color(0xFF9E6A71);
  static const accentSoft = Color(0xFFF0E2E3);
  static const bubbleMe = Color(0xFFE4DAF2);
}

abstract final class AppRadii {
  static const small = 9.0;
  static const medium = 16.0;
  static const card = 22.0;
  static const hero = 26.0;
  static const pill = 999.0;
}

abstract final class AppSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 18.0;
  static const x5 = 24.0;
  static const x6 = 32.0;
}

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        scaffold: AppColors.paper,
        surface: AppColors.card,
        foreground: AppColors.ink,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scaffold: const Color(0xFF111111),
        surface: const Color(0xFF1B1B1B),
        foreground: const Color(0xFFF5F5F5),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color foreground,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
      surface: surface,
    ).copyWith(
      primary: foreground,
      onPrimary: scaffold,
      secondary: AppColors.accent,
      outline: AppColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'sans-serif',
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.line,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: foreground, fontSize: 17, fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: AppColors.line.withValues(alpha: .8)),
        ),
      ),
      iconTheme: IconThemeData(color: foreground),
      textTheme: Typography.blackCupertino.apply(
        bodyColor: foreground, displayColor: foreground,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.hero),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.hero),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.hero),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
      ),
    );
  }
}
