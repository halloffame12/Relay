import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/relay_sheet.dart';
import '../../application/library_providers.dart';
import '../../domain/document.dart';
import '../../domain/library_item.dart';
import '../../domain/library_query.dart';

Future<void> showLibraryFilterSheet(BuildContext context) {
  return showRelaySheet<void>(
    context,
    builder: (_) => const _LibraryFilterSheet(),
  );
}

class _LibraryFilterSheet extends ConsumerWidget {
  const _LibraryFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final query = ref.watch(libraryQueryProvider);
    final controller = ref.read(libraryQueryProvider.notifier);
    final resultCount = ref.watch(visibleLibraryProvider).value?.length;

    return RelaySheetScaffold(
      title: 'Sort & filter',
      subtitle: 'Arrange the collection or narrow it by format and status.',
      trailing: IconButton(
        tooltip: 'Close',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ORDER', style: AppTypography.eyebrow(colors.muted)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < LibrarySort.values.length;
                    index++
                  ) ...[
                    if (index > 0) const Divider(),
                    _SortRow(
                      label: LibrarySort.values[index].label,
                      selected: query.sort == LibrarySort.values[index],
                      onTap: () =>
                          controller.setSort(LibrarySort.values[index]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Text('FORMAT', style: AppTypography.eyebrow(colors.muted)),
                const Spacer(),
                if (query.filters.isActive)
                  Text(
                    '${query.filters.activeCount} active',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.accent,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final format in DocumentFormat.values)
                  _FilterChoice(
                    label: format.label,
                    selected: query.filters.formats.contains(format),
                    onTap: () => controller.toggleFormat(format),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('READING STATUS', style: AppTypography.eyebrow(colors.muted)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final status in LibraryReadingStatus.values)
                  _FilterChoice(
                    label: status.label,
                    selected: query.filters.statuses.contains(status),
                    onTap: () => controller.toggleStatus(status),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                TextButton(
                  onPressed: query.filters.isActive
                      ? controller.clearFilters
                      : null,
                  child: const Text('Clear filters'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      resultCount == null
                          ? 'Show results'
                          : 'Show $resultCount '
                                '${resultCount == 1 ? 'document' : 'documents'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AnimatedOpacity(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppDurations.quick,
                opacity: selected ? 1 : 0,
                child: Icon(Icons.check_rounded, size: 18, color: colors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.sage : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: BorderSide(
            color: selected ? colors.ink.withValues(alpha: 0.35) : colors.line,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 14, color: colors.ink),
                  const SizedBox(width: 6),
                ],
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
