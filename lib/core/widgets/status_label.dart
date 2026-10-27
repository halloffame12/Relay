import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

enum StatusTone { neutral, accent, sage, success, warning, danger, outline }

class StatusLabel extends StatelessWidget {
  const StatusLabel({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.uppercase = true,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final (foreground, background) = switch (tone) {
      StatusTone.neutral => (colors.muted, colors.surfaceSubtle),
      StatusTone.accent => (colors.accent, colors.accentSoft),
      StatusTone.sage => (colors.ink, colors.sage),
      StatusTone.success => (
        colors.success,
        colors.success.withValues(alpha: 0.12),
      ),
      StatusTone.warning => (
        colors.warning,
        colors.warning.withValues(alpha: 0.12),
      ),
      StatusTone.danger => (
        colors.danger,
        colors.danger.withValues(alpha: 0.12),
      ),
      StatusTone.outline => (colors.muted, Colors.transparent),
    };

    final text = uppercase ? label.toUpperCase() : label;

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3.5,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.xs),
          border: tone == StatusTone.outline
              ? Border.all(color: colors.line)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: foreground),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.eyebrow(
                  foreground,
                ).copyWith(fontSize: 9.5, letterSpacing: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
