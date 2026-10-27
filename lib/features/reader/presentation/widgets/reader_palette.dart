import 'package:flutter/material.dart';

import '../../../settings/domain/app_settings.dart';

@immutable
class ReaderPalette {
  const ReaderPalette({
    required this.canvas,
    required this.chrome,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.page,
    required this.pageInk,
    required this.isDark,
  });

  final Color canvas;
  final Color chrome;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;
  final Color page;
  final Color pageInk;
  final bool isDark;

  static ReaderPalette of(ReaderTheme theme) {
    return theme == ReaderTheme.night ? night : paper;
  }

  static const paper = ReaderPalette(
    canvas: Color(0xFFF6F1E5),
    chrome: Color(0xFFEFE9DC),
    ink: Color(0xFF2A2B25),
    muted: Color(0xFF79796F),
    line: Color(0xFFDCD6C8),
    accent: Color(0xFFC55F43),
    page: Color(0xFFFFFDF8),
    pageInk: Color(0xFF2A2B25),
    isDark: false,
  );

  static const night = ReaderPalette(
    canvas: Color(0xFF141712),
    chrome: Color(0xFF1B1F19),
    ink: Color(0xFFE9E4D8),
    muted: Color(0xFF9B9D91),
    line: Color(0xFF32372D),
    accent: Color(0xFFE58C70),
    page: Color(0xFF23271F),
    pageInk: Color(0xFFE7E3D7),
    isDark: true,
  );
}
