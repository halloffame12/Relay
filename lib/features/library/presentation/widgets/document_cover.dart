import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../domain/document.dart';

class DocumentCover extends StatelessWidget {
  const DocumentCover({
    super.key,
    required this.document,
    this.showShadow = true,
    this.borderRadius = 3,
  });

  final Document document;
  final bool showShadow;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = CoverPaletteColors.of(document.coverPalette);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final padding = math.max(6.0, width * 0.085);
          final showType = width >= 70 && height >= 100;
          final content = showType
              ? _CoverContent(
                  document: document,
                  palette: palette,
                  width: width,
                  height: height,
                  padding: padding,
                )
              : const SizedBox.shrink();

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: showShadow
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: math.max(8, width * 0.08),
                        offset: Offset(0, math.max(3, width * 0.035)),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: palette.background),
                  _CoverArtwork(
                    design: document.coverDesign,
                    palette: palette,
                    width: width,
                  ),
                  Positioned.fill(child: content),
                  // The quiet suggestion of a bound spine.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: math.max(2, width * 0.016),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoverArtwork extends StatelessWidget {
  const _CoverArtwork({
    required this.design,
    required this.palette,
    required this.width,
  });

  final CoverDesign design;
  final CoverPaletteColors palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    return switch (design) {
      CoverDesign.bands => Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(-0.45, 0),
            child: FractionallySizedBox(
              widthFactor: 0.2,
              heightFactor: 1,
              child: ColoredBox(color: palette.accent.withValues(alpha: 0.26)),
            ),
          ),
          Align(
            alignment: const Alignment(0.78, 0),
            child: FractionallySizedBox(
              widthFactor: 0.06,
              heightFactor: 1,
              child: ColoredBox(color: palette.accent.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
      CoverDesign.frame => Padding(
        padding: EdgeInsets.all(width * 0.075),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: palette.accent.withValues(alpha: 0.75),
              width: math.max(1, width * 0.006),
            ),
          ),
        ),
      ),
      CoverDesign.arch => CustomPaint(
        painter: _ArchPainter(color: palette.accent.withValues(alpha: 0.32)),
      ),
      CoverDesign.sun => Stack(
        children: [
          Positioned(
            right: -width * 0.18,
            top: -width * 0.12,
            child: Container(
              width: width * 0.68,
              height: width * 0.68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent.withValues(alpha: 0.28),
              ),
            ),
          ),
          Positioned(
            left: width * 0.13,
            right: width * 0.13,
            top: width * 0.72,
            child: Container(
              height: math.max(1, width * 0.006),
              color: palette.ink.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
      CoverDesign.grid => CustomPaint(
        painter: _GridPainter(
          color: palette.ink.withValues(alpha: 0.12),
          accent: palette.accent.withValues(alpha: 0.3),
        ),
      ),
      CoverDesign.editorial => Stack(
        children: [
          Positioned(
            left: width * 0.085,
            right: width * 0.085,
            bottom: width * 0.14,
            child: Container(
              height: math.max(1, width * 0.008),
              color: palette.accent.withValues(alpha: 0.75),
            ),
          ),
          Positioned(
            right: width * 0.085,
            top: width * 0.085,
            child: Container(
              width: math.max(5, width * 0.055),
              height: math.max(5, width * 0.055),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      CoverDesign.spine => Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: width * 0.17,
            child: ColoredBox(color: palette.accent.withValues(alpha: 0.24)),
          ),
          Positioned(
            left: width * 0.17,
            top: 0,
            bottom: 0,
            width: math.max(1, width * 0.008),
            child: ColoredBox(color: palette.accent.withValues(alpha: 0.55)),
          ),
        ],
      ),
      CoverDesign.minimal => Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.all(width * 0.09),
          child: Container(
            width: width * 0.2,
            height: width * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.accent.withValues(alpha: 0.5),
                width: math.max(1, width * 0.007),
              ),
            ),
          ),
        ),
      ),
    };
  }
}

class _CoverContent extends StatelessWidget {
  const _CoverContent({
    required this.document,
    required this.palette,
    required this.width,
    required this.height,
    required this.padding,
  });

  final Document document;
  final CoverPaletteColors palette;
  final double width;
  final double height;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final titleSize = (width * 0.105).clamp(6.5, 26.0);
    final authorSize = (width * 0.058).clamp(4.5, 12.0);
    final microSize = (width * 0.048).clamp(4.0, 9.0);
    final titleLines = height < 90 ? 3 : (height < 160 ? 4 : 5);

    final title = Text(
      document.title,
      textScaler: TextScaler.noScaling,
      maxLines: titleLines,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.serif(
        size: titleSize,
        weight: FontWeight.w500,
        height: 1.12,
        letterSpacing: -titleSize * 0.015,
        color: palette.ink,
      ),
    );

    final author = Text(
      document.author.toUpperCase(),
      textScaler: TextScaler.noScaling,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.eyebrow(
        palette.ink.withValues(alpha: 0.72),
      ).copyWith(fontSize: authorSize, letterSpacing: authorSize * 0.14),
    );

    final micro = Text(
      document.format.label,
      textScaler: TextScaler.noScaling,
      style: AppTypography.eyebrow(
        palette.ink.withValues(alpha: 0.6),
      ).copyWith(fontSize: microSize, letterSpacing: microSize * 0.2),
    );

    final contentPadding = EdgeInsets.fromLTRB(
      padding * 1.7,
      padding,
      padding,
      padding,
    );

    if (document.coverDesign == CoverDesign.editorial) {
      return Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                micro,
                if (width > 74)
                  Flexible(
                    child: Text(
                      'THE FOLIO ROOM',
                      textScaler: TextScaler.noScaling,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTypography.eyebrow(
                        palette.ink.withValues(alpha: 0.5),
                      ).copyWith(fontSize: microSize * 0.85),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(child: title),
            const Spacer(),
            author,
          ],
        ),
      );
    }

    if (document.coverDesign == CoverDesign.minimal) {
      return Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),
            title,
            const SizedBox(height: 8),
            author,
            const Spacer(),
            micro,
          ],
        ),
      );
    }

    if (document.coverDesign == CoverDesign.frame) {
      return Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Text(
              document.format.label,
              textScaler: TextScaler.noScaling,
              style: AppTypography.eyebrow(
                palette.ink.withValues(alpha: 0.55),
              ).copyWith(fontSize: microSize),
            ),
            const SizedBox(height: 10),
            Flexible(child: title),
            const SizedBox(height: 10),
            Container(
              width: width * 0.18,
              height: 1,
              color: palette.accent.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 10),
            author,
            const Spacer(flex: 3),
          ],
        ),
      );
    }

    if (document.coverDesign == CoverDesign.spine) {
      return Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            micro,
            const Spacer(),
            title,
            const SizedBox(height: 8),
            author,
          ],
        ),
      );
    }

    return Padding(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: math.max(4, width * 0.045),
                height: math.max(4, width * 0.045),
                color: palette.accent.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              micro,
            ],
          ),
          const Spacer(),
          title,
          const SizedBox(height: 8),
          Container(
            width: width * 0.35,
            height: 1,
            color: palette.ink.withValues(alpha: 0.28),
          ),
          const SizedBox(height: 8),
          author,
        ],
      ),
    );
  }
}

class CoverPaletteColors {
  const CoverPaletteColors({
    required this.background,
    required this.ink,
    required this.accent,
  });

  final Color background;
  final Color ink;
  final Color accent;

  static CoverPaletteColors of(CoverPalette palette) {
    return switch (palette) {
      CoverPalette.forest => const CoverPaletteColors(
        background: Color(0xFF2C352B),
        ink: Color(0xFFF4F0E6),
        accent: Color(0xFFA9BCA0),
      ),
      CoverPalette.clay => const CoverPaletteColors(
        background: Color(0xFFD96C4F),
        ink: Color(0xFFFFF8F0),
        accent: Color(0xFFF4D9B8),
      ),
      CoverPalette.sage => const CoverPaletteColors(
        background: Color(0xFFD8E0CF),
        ink: Color(0xFF242820),
        accent: Color(0xFF526D51),
      ),
      CoverPalette.ochre => const CoverPaletteColors(
        background: Color(0xFFC99A52),
        ink: Color(0xFF241F13),
        accent: Color(0xFFF4E6C8),
      ),
      CoverPalette.ink => const CoverPaletteColors(
        background: Color(0xFF242820),
        ink: Color(0xFFF4F0E6),
        accent: Color(0xFFD96C4F),
      ),
      CoverPalette.paper => const CoverPaletteColors(
        background: Color(0xFFEDE6D6),
        ink: Color(0xFF242820),
        accent: Color(0xFFB47A36),
      ),
      CoverPalette.moss => const CoverPaletteColors(
        background: Color(0xFF4E654D),
        ink: Color(0xFFF6F2E8),
        accent: Color(0xFFD8E0CF),
      ),
      CoverPalette.charcoal => const CoverPaletteColors(
        background: Color(0xFF2D302A),
        ink: Color(0xFFEDE8DC),
        accent: Color(0xFFD96C4F),
      ),
    };
  }
}

class _ArchPainter extends CustomPainter {
  const _ArchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(
      size.width * 0.48,
      size.height * 0.16,
      size.width * 0.6,
      size.height * 0.7,
    );
    final path = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + rect.width / 2)
      ..arcToPoint(
        Offset(rect.right, rect.top + rect.width / 2),
        radius: Radius.circular(rect.width / 2),
        clockwise: true,
      )
      ..lineTo(rect.right, rect.bottom)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArchPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.7;
    const divisions = 6;
    final step = size.width / divisions;
    for (var i = 1; i < divisions; i++) {
      canvas.drawLine(
        Offset(step * i, 0),
        Offset(step * i, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, step * i * 1.2),
        Offset(size.width, step * i * 1.2),
        paint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.1,
        size.width * 0.24,
        size.width * 0.18,
      ),
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.accent != accent;
  }
}
