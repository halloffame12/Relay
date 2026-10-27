import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/relay_progress_bar.dart';
import '../../domain/library_item.dart';
import '../../domain/document.dart';
import 'document_cover.dart';

class DocumentGridCard extends StatelessWidget {
  const DocumentGridCard({super.key, required this.item, required this.onTap});

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
          '${formatBytes(document.sizeBytes)}'
          '${document.isMissing ? ', file missing' : ''}'
          '${item.hasProgress ? ', ${item.percent} percent read' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: DocumentCover(document: document),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              document.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.serif(
                size: 15.5,
                weight: FontWeight.w600,
                height: 1.24,
                letterSpacing: -0.15,
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
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  document.format.label,
                  style: AppTypography.eyebrow(
                    colors.muted,
                  ).copyWith(fontSize: 9, letterSpacing: 0.8),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    document.isMissing
                        ? 'File missing'
                        : formatBytes(document.sizeBytes),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      color: document.isMissing ? colors.warning : null,
                    ),
                  ),
                ),
              ],
            ),
            if (item.hasProgress) ...[
              const SizedBox(height: AppSpacing.sm),
              if (item.isFinished)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 12,
                      color: colors.success,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Finished',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.success,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: RelayProgressBar(
                        value: item.fraction,
                        height: 3,
                        semanticLabel: '${document.title} reading progress',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${item.percent}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
