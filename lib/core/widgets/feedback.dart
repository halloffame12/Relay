import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

void showRelaySnackBar(
  BuildContext context,
  String message, {
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  showRelaySnackBarWithMessenger(
    ScaffoldMessenger.of(context),
    context.relayColors,
    message,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
    isError: isError,
    duration: duration,
  );
}

/// Shows a snackbar through a messenger captured before navigation. This keeps
/// background failures visible after the initiating screen has been disposed.
void showRelaySnackBarWithMessenger(
  ScaffoldMessengerState messenger,
  RelaySemanticColors colors,
  String message, {
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  if (!messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          children: [
            Icon(
              icon ??
                  (isError ? Icons.error_outline : Icons.check_circle_outline),
              color: isError ? colors.danger : colors.sage,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
}

class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.action,
    this.tone = NoticeTone.sage,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final background = switch (tone) {
      NoticeTone.sage => colors.sage,
      NoticeTone.neutral => colors.surfaceSubtle,
      NoticeTone.accent => colors.accentSoft,
    };
    final foreground = tone == NoticeTone.accent ? colors.accent : colors.ink;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.eyebrow(
                    foreground,
                  ).copyWith(fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum NoticeTone { sage, neutral, accent }
