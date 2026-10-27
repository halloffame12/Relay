import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class RelayWordmark extends StatelessWidget {
  const RelayWordmark({super.key, this.compact = false, this.onTap});

  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final wordmark = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: compact ? 22 : 26,
          height: compact ? 22 : 26,
          child: CustomPaint(
            painter: _RelayMarkPainter(ink: colors.ink, accent: colors.accent),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 9),
          Text(
            'Relay',
            style: AppTypography.serif(
              size: 23,
              weight: FontWeight.w600,
              letterSpacing: 0.1,
              color: colors.ink,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) return Semantics(label: 'Relay', child: wordmark);
    return Semantics(
      button: true,
      label: 'Relay home',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: wordmark,
        ),
      ),
    );
  }
}

class _RelayMarkPainter extends CustomPainter {
  const _RelayMarkPainter({required this.ink, required this.accent});

  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = ink.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final line = Path()
      ..moveTo(size.width * 0.22, size.height * 0.76)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.68,
        size.width * 0.6,
        size.height * 0.35,
        size.width * 0.8,
        size.height * 0.24,
      );
    canvas.drawPath(line, stroke);

    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.76),
      size.width * 0.14,
      Paint()..color = ink,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.24),
      size.width * 0.11,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _RelayMarkPainter oldDelegate) {
    return oldDelegate.ink != ink || oldDelegate.accent != accent;
  }
}
