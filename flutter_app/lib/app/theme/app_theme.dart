import 'package:flutter/material.dart';

/// phone 黑白主题：以纯白、墨黑和中性灰构成层次。
abstract final class AppColors {
  static const paper = Color(0xFFFAFAFA);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE7E7E7);
  static const fill = Color(0xFFF3F3F3);
  static const ink = Color(0xFF202020);
  static const secondary = Color(0xFF666666);
  static const muted = Color(0xFFA3A3A3);
  static const accent = Color(0xFF242424);
  static const accentSoft = Color(0xFFEDEDED);
  static const bubbleMe = Color(0xFFF0F0F0);
  static const bubblePartner = Color(0xFFFFFFFF);
  static const blush = Color(0xFFF3F3F3);
  static const sky = Color(0xFFF1F1F1);
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
        surface: const Color(0xFF1C1C1C),
        foreground: const Color(0xFFF3F3F3),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color foreground,
  }) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
      surface: surface,
    ).copyWith(
      primary: isLight ? const Color(0xFF242424) : const Color(0xFFF1F1F1),
      onPrimary: isLight ? Colors.white : const Color(0xFF171717),
      secondary: isLight ? const Color(0xFF666666) : const Color(0xFFBDBDBD),
      outline: isLight ? AppColors.line : const Color(0xFF3B3B3B),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'sans-serif',
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: isLight ? AppColors.line : const Color(0xFF363636),
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
          side: BorderSide(
            color: isLight ? AppColors.line : const Color(0xFF383838),
          ),
        ),
      ),
      iconTheme: IconThemeData(color: foreground),
      textTheme: (isLight ? Typography.blackCupertino : Typography.whiteCupertino)
          .apply(bodyColor: foreground, displayColor: foreground),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.fill : const Color(0xFF292929),
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
          borderSide: BorderSide(
            color: isLight ? AppColors.accent : const Color(0xFFBDBDBD),
            width: 1,
          ),
        ),
      ),
    );
  }
}
