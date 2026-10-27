import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/relay_progress_bar.dart';
import '../../domain/library_item.dart';
import '../../domain/document.dart';
import 'document_cover.dart';

class DocumentListTile extends StatelessWidget {
  const DocumentListTile({super.key, required this.item, required this.onTap});

  final LibraryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final document = item.document;

    return Semantics(
      button: true,
      label:
          '${document.title}, by ${document.author}, ${document.format.label}, '
          '${formatBytes(document.sizeBytes)}, added '
          '${formatRelativeDate(document.addedAt)}'
          '${document.isMissing ? ', file missing' : ''}'
          '${item.hasProgress ? ', ${item.percent} percent read' : ', unread'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 76,
                child: DocumentCover(document: document, showShadow: false),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.serif(
                        size: 16.5,
                        weight: FontWeight.w600,
                        height: 1.22,
                        letterSpacing: -0.2,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      document.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      document.isMissing
                          ? '${document.format.label} · File missing · '
                                'Added ${formatRelativeDate(document.addedAt).toLowerCase()}'
                          : '${document.format.label} · '
                                '${formatBytes(document.sizeBytes)} · '
                                'Added ${formatRelativeDate(document.addedAt).toLowerCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: document.isMissing
                            ? colors.warning
                            : colors.muted,
                      ),
                    ),
                    if (item.hasProgress) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: RelayProgressBar(
                              value: item.fraction,
                              height: 3,
                              color: item.isFinished
                                  ? colors.success
                                  : colors.accent,
                              semanticLabel:
                                  '${document.title} reading progress',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            item.isFinished ? 'Finished' : '${item.percent}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: item.isFinished
                                  ? colors.success
                                  : colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.muted.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
