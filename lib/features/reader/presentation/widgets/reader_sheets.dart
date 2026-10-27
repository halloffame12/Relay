import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/relay_sheet.dart';
import '../../../settings/application/settings_providers.dart';
import '../../domain/epub_document.dart';
import 'reader_palette.dart';

class ReaderChaptersSheet extends StatelessWidget {
  const ReaderChaptersSheet({
    super.key,
    required this.book,
    required this.selectedIndex,
    required this.bookmarks,
    required this.onSelect,
  });

  final EpubDocument book;
  final int selectedIndex;
  final Set<int> bookmarks;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RelaySheetScaffold(
      title: 'Chapters',
      subtitle:
          '${book.chapters.length} chapters · ${book.readingMinutes} min read',
      trailing: IconButton(
        tooltip: 'Close',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (var index = 0; index < book.chapters.length; index++) ...[
              if (index > 0) const Divider(),
              Material(
                color: index == selectedIndex
                    ? colors.surfaceContainerHigh
                    : Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelect(index);
                  },
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${index + 1}'.padLeft(2, '0'),
                            style: AppTypography.eyebrow(
                              index == selectedIndex
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.chapters[index].title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(book.chapters[index].wordCount / 220).ceil().clamp(1, 99)} min read',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (bookmarks.contains(index))
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: Icon(
                              Icons.bookmark_rounded,
                              size: 16,
                              color: colors.secondary,
                            ),
                          ),
                        if (index == selectedIndex)
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReaderTextSettingsSheet extends ConsumerWidget {
  const ReaderTextSettingsSheet({
    super.key,
    required this.palette,
    required this.textScale,
  });

  final ReaderPalette palette;
  final double textScale;

  static const steps = [0.85, 1.0, 1.15, 1.3, 1.45];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final current = settings.readerTextScale;
    final closest = _closestIndex(current);
    final colors = Theme.of(context).colorScheme;

    return RelaySheetScaffold(
      title: 'Reading settings',
      subtitle: 'Type size applies to EPUB text in the reader.',
      trailing: IconButton(
        tooltip: 'Close',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TEXT SIZE',
              style: AppTypography.eyebrow(colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _SizeButton(
                  label: 'A−',
                  enabled: closest > 0,
                  onPressed: () =>
                      controller.setReaderTextScale(steps[closest - 1]),
                  tooltip: 'Decrease text size',
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${(current * 100).round()}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < steps.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : AppDurations.quick,
                              width: i == closest ? 18 : 6,
                              height: 4,
                              decoration: BoxDecoration(
                                color: i <= closest
                                    ? colors.primary
                                    : colors.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _SizeButton(
                  label: 'A+',
                  enabled: closest < steps.length - 1,
                  onPressed: () =>
                      controller.setReaderTextScale(steps[closest + 1]),
                  tooltip: 'Increase text size',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: palette.canvas,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: palette.line),
              ),
              child: Text(
                'A quieter page begins with a comfortable line. '
                'Adjust the type until the paragraph feels easy to enter.',
                style: AppTypography.serif(
                  size: 16 * current,
                  height: 1.65,
                  color: palette.ink,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                TextButton(
                  onPressed: current == 1.0
                      ? null
                      : controller.resetReadingPreferences,
                  child: const Text('Reset to default'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _closestIndex(double value) {
    var closest = 0;
    for (var i = 0; i < steps.length; i++) {
      if ((steps[i] - value).abs() < (steps[closest] - value).abs()) {
        closest = i;
      }
    }
    return closest;
  }
}

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.tooltip,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: SizedBox(
            width: 52,
            height: 48,
            child: Center(
              child: Text(
                label,
                style: AppTypography.serif(
                  size: 18,
                  color: enabled
                      ? colors.onSurface
                      : colors.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
