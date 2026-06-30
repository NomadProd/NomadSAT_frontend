import 'package:flutter/material.dart';

/// TuranSAT design tokens — single source for colors, spacing, and theme.
abstract final class TuranColors {
  static const primary = Color(0xFF1A4AF0);
  static const primaryDark = Color(0xFF1539C4);
  static const bg = Color(0xFFF0F4FF);
  static const bgAlt = Color(0xFFF2F6FF);
  static const surface = Color(0xFFFFFFFF);
  static const panelBg = Color(0xFFF4F7FF);
  static const panelBgAlt = Color(0xFFFAFBFF);
  static const border = Color(0xFFD7E3FF);
  static const inputFill = Color(0xFFF7F9FF);
  static const inputBorder = Color(0xFFDDE3EE);

  static const textDark = Color(0xFF0D1B3E);
  static const textMid = Color(0xFF4A5A7A);
  static const textLight = Color(0xFF9AAAC6);
  static const textMuted = Color(0xFF7B8AA0);

  static const success = Color(0xFF1B873F);
  static const successBg = Color(0xFFE8F5E9);
  static const error = Color(0xFFC62828);
  static const errorBg = Color(0xFFFFEBEE);
  static const warning = Color(0xFFBF6000);
  static const warningBg = Color(0xFFFFF3E0);
  static const neutral = Color(0xFF607D8B);
  static const neutralBg = Color(0xFFF5F7FA);

  static const verbal = Color(0xFF7B1FA2);
  static const math = Color(0xFF00897B);
  static const mock = Color(0xFFEF6C00);
}

abstract final class TuranSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class TuranRadius {
  static const sm = 10.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const pill = 999.0;
}

abstract final class TuranMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 300);
}

abstract final class TuranBreakpoints {
  static const mobile = 600.0;
  static const tablet = 760.0;
  static const desktop = 1024.0;
}

abstract final class TuranTextStyles {
  static const display = TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w900,
    color: TuranColors.textDark,
    letterSpacing: -0.6,
    height: 1.1,
  );

  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: TuranColors.textDark,
    height: 1.25,
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: TuranColors.textMid,
    height: 1.5,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: TuranColors.textDark,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: TuranColors.textLight,
    height: 1.4,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: TuranColors.textMid,
    height: 1.3,
  );
}

ThemeData buildTuranTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: TuranColors.primary,
    primary: TuranColors.primary,
    surface: TuranColors.surface,
    error: TuranColors.error,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: TuranColors.bg,
    dividerColor: TuranColors.border,
    textTheme: const TextTheme(
      headlineLarge: TuranTextStyles.display,
      titleLarge: TuranTextStyles.title,
      titleMedium: TuranTextStyles.subtitle,
      bodyMedium: TuranTextStyles.body,
      bodySmall: TuranTextStyles.caption,
      labelMedium: TuranTextStyles.label,
    ),
    cardTheme: CardThemeData(
      color: TuranColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TuranRadius.xl),
        side: const BorderSide(color: TuranColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TuranColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TuranSpacing.md,
        vertical: TuranSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TuranRadius.md),
        borderSide: const BorderSide(color: TuranColors.inputBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TuranRadius.md),
        borderSide: const BorderSide(color: TuranColors.inputBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TuranRadius.md),
        borderSide: const BorderSide(color: TuranColors.primary, width: 1.8),
      ),
      labelStyle: const TextStyle(fontSize: 14, color: TuranColors.textMuted),
      floatingLabelStyle: const TextStyle(
        fontSize: 13,
        color: TuranColors.primary,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TuranColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Color(0x991A4AF0),
        elevation: 0,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TuranRadius.md),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TuranColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
