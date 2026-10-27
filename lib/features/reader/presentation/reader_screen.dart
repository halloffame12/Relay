import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/relay_dialogs.dart';
import '../../../core/widgets/relay_loading.dart';
import '../../../core/widgets/relay_sheet.dart';
import '../../../core/widgets/relay_states.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/document.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../application/reading_providers.dart';
import '../domain/epub_document.dart';
import '../domain/pdf_document.dart';
import '../domain/reader_content.dart';
import '../domain/reading_progress.dart';
import '../domain/reading_progress_repository.dart';
import 'widgets/epub_reading_view.dart';
import 'widgets/pdf_reading_view.dart';
import 'widgets/reader_palette.dart';
import 'widgets/reader_sheets.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentByIdProvider(documentId));

    return documentAsync.when(
      loading: () => const _ReaderStateScaffold(
        child: RelayLoadingIndicator(label: 'Opening document…'),
      ),
      error: (error, stackTrace) => _ReaderStateScaffold(
        child: RelayErrorState(
          title: 'The document could not be opened',
          message:
              'Relay could not read this item from the local library. '
              'Your reading position has not been changed.',
          onRetry: () => ref.invalidate(documentsProvider),
        ),
      ),
      data: (document) {
        if (document == null) {
          return _ReaderStateScaffold(
            child: RelayEmptyState(
              icon: Icons.find_in_page_outlined,
              title: 'This document is no longer here',
              message:
                  'It may have been removed from your library on this device.',
              action: FilledButton(
                onPressed: () => context.go('/library'),
                child: const Text('Back to library'),
              ),
            ),
          );
        }

        if (document.isMissing) {
          return _ReaderStateScaffold(
            title: document.title,
            child: RelayEmptyState(
              icon: Icons.file_present_outlined,
              title: 'The file is missing',
              message:
                  'Relay has the library record for “${document.title}”, but '
                  'the stored copy is no longer on this device. Removing the '
                  'record will not delete the original file you imported.',
              action: FilledButton.icon(
                onPressed: () => _removeMissingDocument(context, ref, document),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove from library'),
              ),
            ),
          );
        }

        final progressAsync = ref.watch(readingProgressProvider);
        if (progressAsync.isLoading) {
          return _ReaderStateScaffold(
            title: document.title,
            child: const RelayLoadingIndicator(label: 'Restoring your place…'),
          );
        }

        final progress = progressAsync.value?[document.id];
        return ReaderExperience(
          key: ValueKey(document.id),
          document: document,
          initialProgress: progress,
        );
      },
    );
  }

  Future<void> _removeMissingDocument(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    final confirmed = await showRelayConfirmationDialog(
      context,
      title: 'Remove this library record?',
      message:
          'Relay will remove “${document.title}” from its library. The '
          'original file on your device is not affected.',
      confirmLabel: 'Remove from Relay',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(documentRepositoryProvider).removeDocument(document.id);
      if (!context.mounted) return;
      showRelaySnackBar(
        context,
        'Removed from Relay. The original is untouched.',
      );
      context.go('/library');
    } catch (_) {
      if (!context.mounted) return;
      showRelaySnackBar(
        context,
        'Relay could not finish removing this library record. Try again. '
        'Your original file is unchanged.',
        isError: true,
      );
    }
  }
}

class _ReaderStateScaffold extends StatelessWidget {
  const _ReaderStateScaffold({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/library');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class ReaderExperience extends ConsumerStatefulWidget {
  const ReaderExperience({
    super.key,
    required this.document,
    this.initialProgress,
  });

  final Document document;
  final ReadingProgress? initialProgress;

  @override
  ConsumerState<ReaderExperience> createState() => _ReaderExperienceState();
}

class _ReaderExperienceState extends ConsumerState<ReaderExperience>
    with WidgetsBindingObserver {
  static const _zoomLevels = [1.0, 1.25, 1.5];

  late final ReadingProgressRepository _progressRepository;
  late final ScrollController _epubController;
  late final ValueNotifier<double> _fraction;
  late final Debouncer _saveDebouncer;
  late final Set<int> _bookmarks;

  PageController? _pageController;
  PdfDocumentHandle? _pdf;
  EpubDocument? _epub;
  String? _loadError;
  bool _loading = true;
  int _chapterIndex = 0;
  int _pdfPage = 0;
  double _chapterScroll = 0;
  double _zoom = 1;
  bool _hasInteracted = false;
  bool _saveErrorShown = false;

  bool get _isPdf => widget.document.isPdf;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progressRepository = ref.read(readingProgressRepositoryProvider);
    _bookmarks = {...?widget.initialProgress?.bookmarks};
    _saveDebouncer = Debouncer(const Duration(milliseconds: 700));
    _epubController = ScrollController();
    final initialFraction = (widget.initialProgress?.fraction ?? 0).clamp(
      0.0,
      1.0,
    );
    _chapterScroll = (widget.initialProgress?.locationOffset ?? 0).clamp(
      0.0,
      1.0,
    );
    _chapterIndex = 0;
    _fraction = ValueNotifier(initialFraction);
    unawaited(_loadContent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebouncer.cancel();
    if ((!_loading && _loadError == null) || _hasInteracted) {
      unawaited(_save(_buildProgress(), silent: true));
    }
    _epubController.dispose();
    _pageController?.dispose();
    _fraction.dispose();
    final pdf = _pdf;
    if (pdf != null) unawaited(pdf.close());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveNow();
    }
  }

  Future<void> _loadContent() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    ReaderContent? content;
    try {
      content = await ref
          .read(readerContentServiceProvider)
          .open(widget.document);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error is ReaderContentException
            ? error.message
            : 'Relay could not open this document. The file may be damaged.';
      });
      return;
    }

    if (!mounted) {
      if (content is PdfReaderContent) unawaited(content.document.close());
      return;
    }

    final progress = widget.initialProgress;
    switch (content) {
      case PdfReaderContent(:final document):
        _pdf = document;
        final pageCount = document.pageCount;
        final derivedPage = pageCount <= 1
            ? 0
            : ((progress?.fraction ?? 0) * (pageCount - 1)).round();
        final savedPage = progress?.locationIndex ?? 0;
        final page = (savedPage > 0 ? savedPage : derivedPage).clamp(
          0,
          pageCount - 1,
        );
        _pdfPage = page;
        _pageController = PageController(initialPage: page);
        _fraction.value = pageCount <= 1 ? 0 : page / (pageCount - 1);
      case EpubReaderContent(:final document):
        _epub = document;
        var index = (progress?.locationIndex ?? 0).clamp(
          0,
          document.chapters.length - 1,
        );
        final savedRef = progress?.locationRef;
        if (savedRef != null) {
          final byRef = document.chapters.indexWhere(
            (chapter) => chapter.id == savedRef,
          );
          if (byRef >= 0) index = byRef;
        }
        _chapterIndex = index;
        _fraction.value = document.chapters.isEmpty
            ? 0
            : ((_chapterIndex + _chapterScroll) / document.chapters.length)
                  .clamp(0.0, 1.0);
        _scheduleScrollRestore();
    }

    setState(() => _loading = false);
    unawaited(
      ref.read(documentRepositoryProvider).markOpened(widget.document.id),
    );
  }

  void _scheduleScrollRestore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_epubController.hasClients) return;
      final max = _epubController.position.maxScrollExtent;
      if (_chapterScroll > 0 && max > 0) {
        _epubController.jumpTo(max * _chapterScroll);
      }
      _syncEpubPosition();
    });
  }

  /// A short final chapter may fit without scrolling. In that case the whole
  /// chapter is visible and the book is complete at the end of the last
  /// chapter, rather than appearing stuck at (n-1)/n.
  void _syncEpubPosition() {
    final book = _epub;
    if (book == null || !_epubController.hasClients) return;
    final position = _epubController.position;
    if (!position.hasContentDimensions) return;
    final max = position.maxScrollExtent;
    final isLast = _chapterIndex == book.chapters.length - 1;
    _chapterScroll = max <= 0
        ? (isLast ? 1.0 : 0.0)
        : (position.pixels / max).clamp(0.0, 1.0);
    _fraction.value = ((_chapterIndex + _chapterScroll) / book.chapters.length)
        .clamp(0.0, 1.0);
  }

  ReadingProgress _buildProgress() {
    return ReadingProgress(
      documentId: widget.document.id,
      fraction: _fraction.value.clamp(0.0, 1.0),
      locationIndex: _isPdf ? _pdfPage : _chapterIndex,
      locationOffset: _isPdf ? 0 : _chapterScroll,
      locationRef: _isPdf ? null : _epub?.chapters[_chapterIndex].id,
      lastReadAt: DateTime.now(),
      bookmarks: Set<int>.unmodifiable(_bookmarks),
    );
  }

  Future<void> _save(ReadingProgress progress, {bool silent = false}) async {
    try {
      await _progressRepository.saveProgress(progress);
    } catch (_) {
      if (!mounted || silent || _saveErrorShown) return;
      _saveErrorShown = true;
      showRelaySnackBar(
        context,
        'Your reading position could not be saved on this device.',
        isError: true,
      );
    }
  }

  void _saveNow() {
    if (_loading || _loadError != null) return;
    _saveDebouncer.cancel();
    unawaited(_save(_buildProgress()));
  }

  void _saveSoon() {
    if (_loading || _loadError != null) return;
    _saveDebouncer(() {
      if (!mounted) return;
      unawaited(_save(_buildProgress()));
    });
  }

  void _onEpubScroll() {
    final book = _epub;
    if (book == null || !_epubController.hasClients) return;
    final position = _epubController.position;
    if (!position.hasContentDimensions) return;
    _syncEpubPosition();
    _hasInteracted = true;
    _saveSoon();
  }

  void _goToChapter(int index) {
    final book = _epub;
    if (book == null || index < 0 || index >= book.chapters.length) return;
    if (index == _chapterIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _chapterIndex = index;
      _chapterScroll = 0;
    });
    _fraction.value = index / book.chapters.length;
    _hasInteracted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_epubController.hasClients) return;
      _epubController.jumpTo(0);
      _syncEpubPosition();
      _saveNow();
    });
  }

  void _onPdfPageChanged(int page) {
    final pdf = _pdf;
    if (pdf == null || page == _pdfPage) return;
    HapticFeedback.selectionClick();
    setState(() => _pdfPage = page);
    _fraction.value = pdf.pageCount <= 1 ? 0 : page / (pdf.pageCount - 1);
    _hasInteracted = true;
    _saveNow();
  }

  void _goToPdfPage(int page) {
    final pdf = _pdf;
    final controller = _pageController;
    if (pdf == null || controller == null) return;
    if (page < 0 || page >= pdf.pageCount) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      controller.jumpToPage(page);
    } else {
      controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _changeZoom(int direction) {
    final index = _zoomLevels.indexWhere((value) => value == _zoom);
    final next = (index + direction).clamp(0, _zoomLevels.length - 1);
    if (_zoomLevels[next] == _zoom) return;
    HapticFeedback.selectionClick();
    setState(() => _zoom = _zoomLevels[next]);
  }

  void _toggleBookmark() {
    final location = _isPdf ? _pdfPage : _chapterIndex;
    final nowBookmarked = !_bookmarks.contains(location);
    HapticFeedback.selectionClick();
    setState(() {
      if (nowBookmarked) {
        _bookmarks.add(location);
      } else {
        _bookmarks.remove(location);
      }
    });
    _hasInteracted = true;
    _saveNow();
    final label = _isPdf
        ? (nowBookmarked ? 'Page bookmarked' : 'Page bookmark removed')
        : (nowBookmarked ? 'Chapter bookmarked' : 'Chapter bookmark removed');
    showRelaySnackBar(
      context,
      label,
      icon: nowBookmarked
          ? Icons.bookmark_added_outlined
          : Icons.bookmark_remove_outlined,
    );
  }

  void _toggleReaderTheme() {
    final settings = ref.read(settingsProvider);
    final next = settings.readerTheme == ReaderTheme.paper
        ? ReaderTheme.night
        : ReaderTheme.paper;
    HapticFeedback.selectionClick();
    ref.read(settingsProvider.notifier).setReaderTheme(next);
  }

  void _openChapters() {
    final book = _epub;
    if (book == null) return;
    final settings = ref.read(settingsProvider);
    final palette = ReaderPalette.of(settings.readerTheme);
    showRelaySheet<void>(
      context,
      backgroundColor: palette.chrome,
      builder: (_) => Theme(
        data: palette.isDark ? AppTheme.dark : AppTheme.light,
        child: ReaderChaptersSheet(
          book: book,
          selectedIndex: _chapterIndex,
          bookmarks: _bookmarks,
          onSelect: _goToChapter,
        ),
      ),
    );
  }

  void _openTextSettings(double textScale) {
    final settings = ref.read(settingsProvider);
    final palette = ReaderPalette.of(settings.readerTheme);
    showRelaySheet<void>(
      context,
      backgroundColor: palette.chrome,
      builder: (_) => Theme(
        data: palette.isDark ? AppTheme.dark : AppTheme.light,
        child: ReaderTextSettingsSheet(palette: palette, textScale: textScale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final palette = ReaderPalette.of(settings.readerTheme);

    if (_loading) {
      return _ReaderStateScaffold(
        title: widget.document.title,
        child: const RelayLoadingIndicator(label: 'Preparing the document…'),
      );
    }
    if (_loadError != null) {
      return _ReaderStateScaffold(
        title: widget.document.title,
        child: RelayErrorState(
          title: 'This document could not be opened',
          message: _loadError!,
          onRetry: () => unawaited(_loadContent()),
        ),
      );
    }

    final pdf = _pdf;
    final epub = _epub;
    final currentBookmark = _isPdf ? _pdfPage : _chapterIndex;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: palette.chrome,
        statusBarIconBrightness: palette.isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: palette.isDark
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: palette.chrome,
        systemNavigationBarIconBrightness: palette.isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ReaderTopBar(
                document: widget.document,
                palette: palette,
                fraction: _fraction,
                isBookmarked: _bookmarks.contains(currentBookmark),
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/library');
                  }
                },
                onToggleBookmark: _toggleBookmark,
              ),
              Expanded(
                child: pdf != null
                    ? PdfReadingView(
                        document: pdf,
                        pageController: _pageController!,
                        palette: palette,
                        zoom: _zoom,
                        onPageChanged: _onPdfPageChanged,
                      )
                    : EpubReadingView(
                        book: epub!,
                        chapterIndex: _chapterIndex,
                        scrollController: _epubController,
                        palette: palette,
                        textScale: settings.readerTextScale,
                        onNextChapter: _chapterIndex < epub.chapters.length - 1
                            ? () => _goToChapter(_chapterIndex + 1)
                            : null,
                        onPreviousChapter: _chapterIndex > 0
                            ? () => _goToChapter(_chapterIndex - 1)
                            : null,
                        onOpenChapters: _openChapters,
                        onScroll: _onEpubScroll,
                      ),
              ),
              if (pdf != null)
                _PdfBottomBar(
                  palette: palette,
                  currentPage: _pdfPage,
                  pageCount: pdf.pageCount,
                  zoom: _zoom,
                  onPrevious: _pdfPage > 0
                      ? () => _goToPdfPage(_pdfPage - 1)
                      : null,
                  onNext: _pdfPage < pdf.pageCount - 1
                      ? () => _goToPdfPage(_pdfPage + 1)
                      : null,
                  onZoomOut: _zoom > _zoomLevels.first
                      ? () => _changeZoom(-1)
                      : null,
                  onZoomIn: _zoom < _zoomLevels.last
                      ? () => _changeZoom(1)
                      : null,
                )
              else
                _EpubBottomBar(
                  palette: palette,
                  fraction: _fraction,
                  chapterIndex: _chapterIndex,
                  chapterCount: epub!.chapters.length,
                  onOpenChapters: _openChapters,
                  onOpenTextSettings: () =>
                      _openTextSettings(settings.readerTextScale),
                  onToggleTheme: _toggleReaderTheme,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({
    required this.document,
    required this.palette,
    required this.fraction,
    required this.isBookmarked,
    required this.onBack,
    required this.onToggleBookmark,
  });

  final Document document;
  final ReaderPalette palette;
  final ValueListenable<double> fraction;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.chrome,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Back to document',
                  onPressed: onBack,
                  color: palette.ink,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.serif(
                          size: 15,
                          weight: FontWeight.w600,
                          color: palette.ink,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${document.author} · ${document.format.label} · '
                        'Stored on this device',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eyebrow(
                          palette.muted,
                        ).copyWith(fontSize: 8.5, letterSpacing: 0.7),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isBookmarked
                      ? 'Remove bookmark'
                      : 'Bookmark this location',
                  onPressed: onToggleBookmark,
                  color: isBookmarked ? palette.accent : palette.ink,
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: fraction,
            builder: (context, value, _) {
              return SizedBox(
                height: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: ColoredBox(color: palette.accent),
                  ),
                ),
              );
            },
          ),
          Divider(height: 1, color: palette.line),
        ],
      ),
    );
  }
}

class _EpubBottomBar extends StatelessWidget {
  const _EpubBottomBar({
    required this.palette,
    required this.fraction,
    required this.chapterIndex,
    required this.chapterCount,
    required this.onOpenChapters,
    required this.onOpenTextSettings,
    required this.onToggleTheme,
  });

  final ReaderPalette palette;
  final ValueListenable<double> fraction;
  final int chapterIndex;
  final int chapterCount;
  final VoidCallback onOpenChapters;
  final VoidCallback onOpenTextSettings;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.chrome,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 4),
              _ReaderBarButton(
                icon: Icons.format_list_numbered_rounded,
                label: 'Chapters',
                palette: palette,
                onPressed: onOpenChapters,
              ),
              Expanded(
                child: ValueListenableBuilder<double>(
                  valueListenable: fraction,
                  builder: (context, value, _) {
                    return Text(
                      '${(value.clamp(0, 1) * 100).round()}%  ·  '
                      'Chapter ${chapterIndex + 1} of $chapterCount',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.eyebrow(
                        palette.muted,
                      ).copyWith(fontSize: 9, letterSpacing: 0.6),
                    );
                  },
                ),
              ),
              _ReaderBarButton(
                icon: Icons.text_fields_rounded,
                label: 'Text',
                palette: palette,
                onPressed: onOpenTextSettings,
              ),
              _ReaderBarButton(
                icon: palette.isDark
                    ? Icons.light_mode_outlined
                    : Icons.bedtime_outlined,
                label: palette.isDark ? 'Day' : 'Night',
                palette: palette,
                onPressed: onToggleTheme,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderBarButton extends StatelessWidget {
  const _ReaderBarButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final ReaderPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: SizedBox(
          width: 58,
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: palette.ink),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.eyebrow(
                  palette.muted,
                ).copyWith(fontSize: 8, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfBottomBar extends StatelessWidget {
  const _PdfBottomBar({
    required this.palette,
    required this.currentPage,
    required this.pageCount,
    required this.zoom,
    required this.onPrevious,
    required this.onNext,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  final ReaderPalette palette;
  final int currentPage;
  final int pageCount;
  final double zoom;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.chrome,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              const SizedBox(width: 2),
              _CompactBarButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous page',
                palette: palette,
                onPressed: onPrevious,
              ),
              Expanded(
                child: Text(
                  'Page ${currentPage + 1} of $pageCount',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.eyebrow(
                    palette.muted,
                  ).copyWith(fontSize: 9),
                ),
              ),
              _CompactBarButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next page',
                palette: palette,
                onPressed: onNext,
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: palette.line,
              ),
              _CompactBarButton(
                icon: Icons.remove_rounded,
                tooltip: 'Zoom out',
                palette: palette,
                onPressed: onZoomOut,
              ),
              SizedBox(
                width: 43,
                child: Text(
                  '${(zoom * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: AppTypography.eyebrow(
                    palette.muted,
                  ).copyWith(fontSize: 9),
                ),
              ),
              _CompactBarButton(
                icon: Icons.add_rounded,
                tooltip: 'Zoom in',
                palette: palette,
                onPressed: onZoomIn,
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactBarButton extends StatelessWidget {
  const _CompactBarButton({
    required this.icon,
    required this.tooltip,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final ReaderPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: SizedBox(
            width: 38,
            height: 46,
            child: Icon(
              icon,
              size: 20,
              color: onPressed == null
                  ? palette.muted.withValues(alpha: 0.35)
                  : palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}
