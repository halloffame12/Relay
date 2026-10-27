import 'package:flutter/material.dart';

/// Relay uses the platform's own sans-serif for interface text and a
/// platform serif for editorial headings and reading content. No remote fonts
/// are downloaded at runtime.
abstract final class AppFonts {
  static const serif = 'serif';

  static const serifFallback = <String>[
    'Noto Serif',
    'Source Serif 4',
    'Georgia',
    'Times New Roman',
  ];

  static const sansFallback = <String>[
    'Noto Sans',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
  ];
}

abstract final class AppTypography {
  static TextStyle serif({
    double? size,
    FontWeight weight = FontWeight.w500,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: AppFonts.serif,
      fontFamilyFallback: AppFonts.serifFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextTheme textTheme(Color ink, Color muted) {
    final base = Typography.material2021().black;
    return base.copyWith(
      displayLarge: serif(
        size: 40,
        weight: FontWeight.w500,
        height: 1.08,
        letterSpacing: -0.8,
        color: ink,
      ),
      displayMedium: serif(
        size: 34,
        weight: FontWeight.w500,
        height: 1.12,
        letterSpacing: -0.6,
        color: ink,
      ),
      displaySmall: serif(
        size: 30,
        weight: FontWeight.w500,
        height: 1.16,
        letterSpacing: -0.4,
        color: ink,
      ),
      headlineLarge: serif(
        size: 28,
        weight: FontWeight.w500,
        height: 1.2,
        letterSpacing: -0.4,
        color: ink,
      ),
      headlineMedium: serif(
        size: 24,
        weight: FontWeight.w500,
        height: 1.24,
        letterSpacing: -0.3,
        color: ink,
      ),
      headlineSmall: serif(
        size: 20,
        weight: FontWeight.w500,
        height: 1.3,
        letterSpacing: -0.2,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontFamilyFallback: AppFonts.sansFallback,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontFamilyFallback: AppFonts.sansFallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontFamilyFallback: AppFonts.sansFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontFamilyFallback: AppFonts.sansFallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontFamilyFallback: AppFonts.sansFallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: ink,
      ),
      bodySmall: TextStyle(
        fontFamilyFallback: AppFonts.sansFallback,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontFamilyFallback: AppFonts.sansFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontFamilyFallback: AppFonts.sansFallback,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
        color: ink,
      ),
      labelSmall: TextStyle(
        fontFamilyFallback: AppFonts.sansFallback,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 1.15,
        color: muted,
      ),
    );
  }

  /// The eyebrow style used above section titles.
  static TextStyle eyebrow(Color color) {
    return TextStyle(
      fontFamilyFallback: AppFonts.sansFallback,
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.35,
      height: 1.2,
      color: color,
    );
  }
}
