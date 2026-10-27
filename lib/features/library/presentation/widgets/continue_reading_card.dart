import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/relay_progress_bar.dart';
import '../../domain/library_item.dart';
import 'document_cover.dart';

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final LibraryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final document = item.document;
    final lastRead = item.lastReadAt;

    return Semantics(
      button: true,
      label:
          'Continue reading ${document.title}, ${item.percent} percent read'
          '${lastRead != null ? ', last opened ${formatTimeAgo(lastRead)}' : ''}',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 58,
                  height: 84,
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
                          size: 16,
                          weight: FontWeight.w600,
                          height: 1.22,
                          letterSpacing: -0.15,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '${item.percent}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.accent,
                              fontSize: 11.5,
                            ),
                          ),
                          if (lastRead != null)
                            Expanded(
                              child: Text(
                                '  ·  ${formatTimeAgo(lastRead)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: colors.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      RelayProgressBar(
                        value: item.fraction,
                        height: 3,
                        semanticLabel: '${document.title} reading progress',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
