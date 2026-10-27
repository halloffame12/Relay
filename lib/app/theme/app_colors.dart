import 'package:flutter/material.dart';

/// The raw Relay palette. Widgets should normally read semantic colours from
/// [RelaySemanticColors] so light and dark themes stay coherent.
abstract final class AppColors {
  static const forestInk = Color(0xFF242820);
  static const warmPaper = Color(0xFFF4F0E6);
  static const white = Color(0xFFFFFFFF);
  static const terracotta = Color(0xFFD96C4F);
  static const sage = Color(0xFFD8E0CF);
  static const oliveGray = Color(0xFF79796F);
  static const paperLine = Color(0xFFDED9CD);
  static const success = Color(0xFF526D51);
  static const warning = Color(0xFFB47A36);
  static const error = Color(0xFFB94B43);

  // A few quiet derivatives used for surfaces and cover art.
  static const deepOlive = Color(0xFF3B4036);
  static const softClay = Color(0xFFEBCFC2);
  static const agedPaper = Color(0xFFEDE6D6);
  static const ochre = Color(0xFFC99A52);
  static const moss = Color(0xFF526D51);
  static const charcoal = Color(0xFF2D302A);

  static const light = RelaySemanticColors(
    canvas: warmPaper,
    surface: white,
    surfaceSubtle: Color(0xFFEDE8DC),
    ink: forestInk,
    muted: oliveGray,
    line: paperLine,
    accent: terracotta,
    accentSoft: Color(0xFFF3DED6),
    sage: sage,
    success: success,
    warning: warning,
    danger: error,
    onAccent: white,
    shadow: Color(0x1A242820),
  );

  static const dark = RelaySemanticColors(
    canvas: Color(0xFF171A15),
    surface: Color(0xFF20241E),
    surfaceSubtle: Color(0xFF2A2E26),
    ink: Color(0xFFECE8DC),
    muted: Color(0xFFA3A599),
    line: Color(0xFF373C32),
    accent: Color(0xFFE58C70),
    accentSoft: Color(0xFF3A2721),
    sage: Color(0xFF2A3428),
    success: Color(0xFF95B08D),
    warning: Color(0xFFD2A05A),
    danger: Color(0xFFE38D84),
    onAccent: Color(0xFF241611),
    shadow: Color(0x66000000),
  );
}

@immutable
class RelaySemanticColors extends ThemeExtension<RelaySemanticColors> {
  const RelaySemanticColors({
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.sage,
    required this.success,
    required this.warning,
    required this.danger,
    required this.onAccent,
    required this.shadow,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceSubtle;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color sage;
  final Color success;
  final Color warning;
  final Color danger;
  final Color onAccent;
  final Color shadow;

  @override
  RelaySemanticColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSubtle,
    Color? ink,
    Color? muted,
    Color? line,
    Color? accent,
    Color? accentSoft,
    Color? sage,
    Color? success,
    Color? warning,
    Color? danger,
    Color? onAccent,
    Color? shadow,
  }) {
    return RelaySemanticColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      sage: sage ?? this.sage,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      onAccent: onAccent ?? this.onAccent,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  RelaySemanticColors lerp(
    ThemeExtension<RelaySemanticColors>? other,
    double t,
  ) {
    if (other is! RelaySemanticColors) return this;
    return RelaySemanticColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension RelayThemeContext on BuildContext {
  RelaySemanticColors get relayColors =>
      Theme.of(this).extension<RelaySemanticColors>() ?? AppColors.light;
}
