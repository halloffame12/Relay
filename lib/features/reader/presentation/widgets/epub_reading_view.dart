import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/epub_document.dart';
import 'reader_palette.dart';

class EpubReadingView extends StatelessWidget {
  const EpubReadingView({
    super.key,
    required this.book,
    required this.chapterIndex,
    required this.scrollController,
    required this.palette,
    required this.textScale,
    required this.onNextChapter,
    required this.onPreviousChapter,
    required this.onOpenChapters,
    required this.onScroll,
  });

  final EpubDocument book;
  final int chapterIndex;
  final ScrollController scrollController;
  final ReaderPalette palette;
  final double textScale;
  final VoidCallback? onNextChapter;
  final VoidCallback? onPreviousChapter;
  final VoidCallback onOpenChapters;
  final VoidCallback onScroll;

  @override
  Widget build(BuildContext context) {
    final chapter = book.chapters[chapterIndex];
    final bodySize = 18.5 * textScale;
    final isLast = chapterIndex == book.chapters.length - 1;
    final blocks = _visibleBlocks(chapter);

    return ColoredBox(
      color: palette.canvas,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          onScroll();
          return false;
        },
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width >= 600 ? 48 : 26,
                  vertical: 20,
                ),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _chapterNumber(chapterIndex),
                            style: AppTypography.eyebrow(palette.accent),
                          ),
                          Container(
                            width: 18,
                            height: 1,
                            color: palette.accent.withValues(alpha: 0.5),
                          ),
                          Text(
                            '${chapter.readingMinutes} min read',
                            style: AppTypography.eyebrow(
                              palette.muted,
                            ).copyWith(letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        chapter.title,
                        style: AppTypography.serif(
                          size: 30 * textScale.clamp(0.9, 1.15),
                          weight: FontWeight.w500,
                          height: 1.16,
                          letterSpacing: -0.5,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(width: 40, height: 1, color: palette.line),
                      const SizedBox(height: 26),
                      for (var i = 0; i < blocks.length; i++)
                        _EpubBlockView(
                          block: blocks[i],
                          palette: palette,
                          bodySize: bodySize,
                          textScale: textScale,
                          isFirstParagraph:
                              blocks[i].kind == EpubBlockKind.paragraph &&
                              !blocks
                                  .take(i)
                                  .any(
                                    (block) =>
                                        block.kind == EpubBlockKind.paragraph,
                                  ),
                        ),
                      const SizedBox(height: 34),
                      Center(
                        child: Text(
                          '·  ·  ·',
                          style: AppTypography.serif(
                            size: 18,
                            color: palette.muted.withValues(alpha: 0.65),
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.only(top: 14),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: palette.line)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 14,
                              color: palette.muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'From “${book.title}” · EPUB stored on this '
                                'device.',
                                style: AppTypography.serif(
                                  size: 12.5,
                                  height: 1.45,
                                  color: palette.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final previous = chapterIndex > 0
                              ? _ReaderOutlineButton(
                                  label: 'Previous',
                                  icon: Icons.arrow_back_rounded,
                                  palette: palette,
                                  onPressed: onPreviousChapter,
                                )
                              : null;
                          final next = !isLast && onNextChapter != null
                              ? _ReaderOutlineButton(
                                  label: 'Next chapter',
                                  icon: Icons.arrow_forward_rounded,
                                  palette: palette,
                                  onPressed: onNextChapter,
                                  trailingIcon: true,
                                )
                              : _ReaderOutlineButton(
                                  label: 'All chapters',
                                  icon: Icons.format_list_numbered_rounded,
                                  palette: palette,
                                  onPressed: onOpenChapters,
                                );
                          if (constraints.maxWidth < 340) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ?previous,
                                if (previous != null)
                                  const SizedBox(height: AppSpacing.sm),
                                next,
                              ],
                            );
                          }
                          return Row(
                            children: [?previous, const Spacer(), next],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<EpubBlock> _visibleBlocks(EpubChapter chapter) {
    final blocks = chapter.blocks;
    if (blocks.isEmpty) return const [];
    final first = blocks.first;
    if (first.kind == EpubBlockKind.heading &&
        first.text.trim().toLowerCase() == chapter.title.trim().toLowerCase()) {
      return blocks.sublist(1);
    }
    return blocks;
  }

  String _chapterNumber(int index) {
    const numerals = [
      'Chapter one',
      'Chapter two',
      'Chapter three',
      'Chapter four',
      'Chapter five',
      'Chapter six',
      'Chapter seven',
      'Chapter eight',
    ];
    if (index < numerals.length) return numerals[index].toUpperCase();
    return 'CHAPTER ${index + 1}';
  }
}

class _EpubBlockView extends StatelessWidget {
  const _EpubBlockView({
    required this.block,
    required this.palette,
    required this.bodySize,
    required this.textScale,
    required this.isFirstParagraph,
  });

  final EpubBlock block;
  final ReaderPalette palette;
  final double bodySize;
  final double textScale;
  final bool isFirstParagraph;

  @override
  Widget build(BuildContext context) {
    final image = block.image;
    if (block.kind == EpubBlockKind.image && image != null) {
      return Padding(
        padding: EdgeInsets.only(bottom: 24 * textScale),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Image.memory(
            image.bytes,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.medium,
            semanticLabel: block.text.isEmpty ? null : block.text,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      );
    }
    final spacing = switch (block.kind) {
      EpubBlockKind.heading => 28.0 * textScale,
      EpubBlockKind.quote => 20.0 * textScale,
      EpubBlockKind.code => 16.0 * textScale,
      EpubBlockKind.listItem => 8.0 * textScale,
      EpubBlockKind.image => 24.0 * textScale,
      EpubBlockKind.paragraph => 20.0 * textScale,
    };
    final textStyle = switch (block.kind) {
      EpubBlockKind.heading => AppTypography.serif(
        size: 21 * textScale,
        height: 1.35,
        weight: FontWeight.w600,
        color: palette.ink,
      ),
      EpubBlockKind.quote => AppTypography.serif(
        size: bodySize * 0.94,
        height: 1.6,
        color: palette.muted,
      ).copyWith(fontStyle: FontStyle.italic),
      EpubBlockKind.code => TextStyle(
        fontFamily: 'monospace',
        fontSize: 14 * textScale,
        height: 1.55,
        color: palette.ink,
      ),
      EpubBlockKind.listItem => AppTypography.serif(
        size: bodySize,
        height: 1.65,
        color: palette.ink,
      ),
      EpubBlockKind.image => const TextStyle(),
      EpubBlockKind.paragraph =>
        AppTypography.serif(
          size: bodySize,
          height: 1.72,
          letterSpacing: 0.05,
          color: palette.ink,
        ).copyWith(
          fontWeight: isFirstParagraph ? FontWeight.w500 : FontWeight.w400,
        ),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: switch (block.kind) {
        EpubBlockKind.quote => Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: palette.accent.withValues(alpha: 0.7),
                width: 2,
              ),
            ),
          ),
          child: Text(block.text, style: textStyle),
        ),
        EpubBlockKind.listItem => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 9),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(child: Text(block.text, style: textStyle)),
          ],
        ),
        EpubBlockKind.code => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.chrome,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: palette.line),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(block.text, style: textStyle),
          ),
        ),
        _ => Text(block.text, style: textStyle),
      },
    );
  }
}

class _ReaderOutlineButton extends StatelessWidget {
  const _ReaderOutlineButton({
    required this.label,
    required this.icon,
    required this.palette,
    required this.onPressed,
    this.trailingIcon = false,
  });

  final String label;
  final IconData icon;
  final ReaderPalette palette;
  final VoidCallback? onPressed;
  final bool trailingIcon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        side: BorderSide(color: palette.line),
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!trailingIcon) ...[
            Icon(icon, size: 16, color: palette.muted),
            const SizedBox(width: 6),
          ],
          Text(label),
          if (trailingIcon) ...[
            const SizedBox(width: 6),
            Icon(icon, size: 16, color: palette.muted),
          ],
        ],
      ),
    );
  }
}
