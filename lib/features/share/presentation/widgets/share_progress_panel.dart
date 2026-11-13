import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/relay_progress_bar.dart';
import '../../../../core/widgets/status_label.dart';
import '../../domain/share_state.dart';

/// Shared progress surface for the sender and receiver. It shows only quantities
/// that are directly measured: bytes copied, a smoothed transfer rate, and an
/// estimate that is hidden until the rate is stable enough to be useful.
class ShareProgressPanel extends StatelessWidget {
  const ShareProgressPanel({
    super.key,
    required this.title,
    required this.progress,
    this.message,
  });

  final String title;
  final ShareProgress progress;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final transferred = formatBytes(progress.transferredBytes);
    final total = formatBytes(progress.totalBytes);
    final percent = (progress.fraction * 100).floor();
    final speed = progress.bytesPerSecond >= 1024
        ? '${formatBytes(progress.bytesPerSecond.round())}/s'
        : null;
    final remaining = progress.remaining;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              StatusLabel(
                label: '$percent%',
                tone: StatusTone.accent,
                uppercase: false,
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          RelayProgressBar(
            value: progress.fraction,
            height: 6,
            semanticLabel: title,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.currentFile ?? 'Preparing…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('$transferred of $total', style: theme.textTheme.bodySmall),
            ],
          ),
          if (speed != null || remaining != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (speed != null) ...[
                  Icon(Icons.speed_rounded, size: 14, color: colors.muted),
                  const SizedBox(width: 4),
                  Text(speed, style: theme.textTheme.bodySmall),
                ],
                if (speed != null && remaining != null)
                  Text('  ·  ', style: theme.textTheme.bodySmall),
                if (remaining != null) ...[
                  Icon(Icons.schedule_rounded, size: 14, color: colors.muted),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDuration(remaining)} left',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
          if (progress.fileCount > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'File ${progress.fileIndex + 1} of ${progress.fileCount}',
              style: AppTypography.eyebrow(colors.muted),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    if (duration.inSeconds < 1) return 'a moment';
    if (duration.inMinutes < 1) return '${duration.inSeconds}s';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes < 60) return '${minutes}m ${seconds}s';
    final hours = duration.inHours;
    return '${hours}h ${minutes % 60}m';
  }
}

class ShareResultsList extends StatelessWidget {
  const ShareResultsList({super.key, required this.results});

  final List<ShareFileResult> results;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    if (results.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          for (var index = 0; index < results.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.line),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    switch (results[index].status) {
                      ShareResultStatus.imported => Icons.check_circle_rounded,
                      ShareResultStatus.duplicate =>
                        Icons.library_add_check_rounded,
                      ShareResultStatus.failed => Icons.error_outline_rounded,
                    },
                    size: 18,
                    color: switch (results[index].status) {
                      ShareResultStatus.imported => colors.success,
                      ShareResultStatus.duplicate => colors.warning,
                      ShareResultStatus.failed => colors.danger,
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          results[index].fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        if (results[index].message != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            results[index].message!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(switch (results[index].status) {
                    ShareResultStatus.imported => 'Added',
                    ShareResultStatus.duplicate => 'Already here',
                    ShareResultStatus.failed => 'Not added',
                  }, style: AppTypography.eyebrow(colors.muted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
