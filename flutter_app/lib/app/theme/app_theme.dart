import 'package:flutter/material.dart';

abstract final class AppColors {
  static const paper = Color(0xFFF7FAF8);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE5ECE7);
  static const fill = Color(0xFFEEF3EF);
  static const ink = Color(0xFF29362F);
  static const secondary = Color(0xFF68796F);
  static const muted = Color(0xFF9AA79F);
  static const accent = Color(0xFF789A88);
  static const accentSoft = Color(0xFFE8F0EA);
  static const bubbleMe = Color(0xFFDCEBE1);
  static const bubblePartner = Color(0xFFFFFFFF);
  static const blush = Color(0xFFF2E9E9);
  static const sky = Color(0xFFE8EFF2);
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
        scaffold: const Color(0xFF111A15),
        surface: const Color(0xFF1B2820),
        foreground: const Color(0xFFF0F5F1),
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
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
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
      cardTheme: CardThemeData(
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
