import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/relay_buttons.dart';
import '../../../core/widgets/relay_search_field.dart';
import '../../../core/widgets/relay_segmented_control.dart';
import '../../../core/widgets/relay_states.dart';
import '../../../core/widgets/relay_wordmark.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_label.dart';
import '../../reader/application/reading_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../application/library_providers.dart';
import '../domain/document.dart';
import '../domain/library_item.dart';
import '../domain/library_query.dart';
import 'widgets/continue_reading_card.dart';
import 'widgets/document_grid_card.dart';
import 'widgets/document_list_tile.dart';
import 'widgets/library_filter_sheet.dart';
import 'widgets/library_skeleton.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(libraryQueryProvider).search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(documentsProvider);
    ref.invalidate(readingProgressProvider);
    try {
      await Future.wait([
        ref.read(documentsProvider.future),
        ref.read(readingProgressProvider.future),
      ]);
    } catch (_) {
      if (!mounted) return;
      showRelaySnackBar(
        context,
        'The library could not be refreshed. Your local list is unchanged.',
        isError: true,
      );
    }
  }

  void _openFilters() {
    FocusManager.instance.primaryFocus?.unfocus();
    showLibraryFilterSheet(context);
  }

  void _clearEverything() {
    _searchController.clear();
    ref.read(libraryQueryProvider.notifier).clearAll();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppDurations.gentle,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final query = ref.watch(libraryQueryProvider);
    final itemsAsync = ref.watch(libraryItemsProvider);
    final visibleAsync = ref.watch(visibleLibraryProvider);
    final continueItems = ref.watch(continueReadingProvider);
    final summary = ref.watch(librarySummaryProvider);
    final viewMode = ref.watch(
      settingsProvider.select((settings) => settings.libraryView),
    );

    final isLoading = itemsAsync.isLoading;
    final hasError = itemsAsync.hasError;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: colors.ink,
          backgroundColor: colors.surface,
          edgeOffset: 8,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: AppSpacing.giant),
            child: RelayContent(
              maxWidth: 1180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _LibraryTopBar(
                    onWordmark: _scrollToTop,
                    onImport: () => context.push('/import'),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  PageHeading(
                    eyebrow: 'Personal collection',
                    title: 'Your library',
                    subtitle: isLoading
                        ? 'Preparing your collection…'
                        : hasError
                        ? 'Your local library is unavailable right now.'
                        : '${summary.documentCount} '
                              '${summary.documentCount == 1 ? 'document' : 'documents'} · '
                              '${summary.totalSizeLabel} stored'
                              '${summary.missingCount > 0 ? ' · ${summary.missingCount} missing' : ''}',
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (isLoading)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SearchRow(
                          controller: _searchController,
                          query: query,
                          enabled: false,
                          onChanged: (_) {},
                          onOpenFilters: _openFilters,
                          viewMode: viewMode,
                          onViewModeChanged: _setViewMode,
                          filterCount: 0,
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        LibrarySkeleton(viewMode: viewMode),
                      ],
                    )
                  else if (hasError)
                    RelayErrorState(
                      title: 'The library could not be opened',
                      message:
                          'Relay could not read the local collection. Nothing '
                          'has been removed from this device.',
                      onRetry: _refresh,
                    )
                  else
                    _buildLibraryContent(
                      context: context,
                      query: query,
                      itemsAsync: itemsAsync,
                      visibleAsync: visibleAsync,
                      continueItems: continueItems,
                      viewMode: viewMode,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryContent({
    required BuildContext context,
    required LibraryQuery query,
    required AsyncValue<List<LibraryItem>> itemsAsync,
    required AsyncValue<List<LibraryItem>> visibleAsync,
    required List<LibraryItem> continueItems,
    required LibraryViewMode viewMode,
  }) {
    final colors = context.relayColors;
    final allItems = itemsAsync.value ?? const <LibraryItem>[];
    final visible = visibleAsync.value ?? const <LibraryItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchRow(
          controller: _searchController,
          query: query,
          enabled: true,
          onChanged: ref.read(libraryQueryProvider.notifier).setSearch,
          onOpenFilters: _openFilters,
          viewMode: viewMode,
          onViewModeChanged: _setViewMode,
          filterCount: query.filters.activeCount,
        ),
        if (query.filters.isActive) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final format in query.filters.formats)
                _ActiveFilterChip(
                  label: format.label,
                  onRemove: () => ref
                      .read(libraryQueryProvider.notifier)
                      .removeFormat(format),
                ),
              for (final status in query.filters.statuses)
                _ActiveFilterChip(
                  label: status.label,
                  onRemove: () => ref
                      .read(libraryQueryProvider.notifier)
                      .removeStatus(status),
                ),
              TextButton(
                onPressed: () =>
                    ref.read(libraryQueryProvider.notifier).clearFilters(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  foregroundColor: colors.accent,
                  textStyle: Theme.of(context).textTheme.labelMedium,
                ),
                child: const Text('Clear all'),
              ),
            ],
          ),
        ],
        if (!query.isFiltering && continueItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxxl),
          SectionHeader(
            eyebrow: 'Pick up where you left off',
            title: 'Continue reading',
            trailing: Text(
              '${continueItems.length} in progress',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ContinueReadingRail(items: continueItems),
          const SizedBox(height: AppSpacing.xxxl),
        ] else
          const SizedBox(height: AppSpacing.xxxl),
        _CollectionHeader(
          query: query,
          visibleCount: visible.length,
          totalCount: allItems.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (allItems.isEmpty)
          RelayEmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'Your library is empty',
            message:
                'Import a PDF or EPUB to begin building your offline '
                'collection.',
            action: RelayButton(
              label: 'Import a document',
              icon: Icons.add_rounded,
              onPressed: () => context.push('/import'),
            ),
          )
        else if (visible.isEmpty)
          RelayEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No documents found',
            message: query.hasSearch
                ? 'Nothing matches “${query.search.trim()}”. Try a different '
                      'title, author, file name or source.'
                : 'No documents match the selected filters.',
            action: RelayButton(
              label: 'Clear search & filters',
              variant: RelayButtonVariant.secondary,
              onPressed: _clearEverything,
            ),
          )
        else
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppDurations.standard,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: viewMode == LibraryViewMode.grid
                ? _LibraryGrid(
                    key: const ValueKey('grid'),
                    items: visible,
                    onOpen: _openDocument,
                  )
                : _LibraryList(
                    key: const ValueKey('list'),
                    items: visible,
                    onOpen: _openDocument,
                  ),
          ),
      ],
    );
  }

  void _openDocument(LibraryItem item) {
    context.push('/document/${item.document.id}');
  }

  void _setViewMode(LibraryViewMode mode) {
    ref.read(settingsProvider.notifier).setLibraryView(mode);
  }
}

class _LibraryTopBar extends StatelessWidget {
  const _LibraryTopBar({required this.onWordmark, required this.onImport});

  final VoidCallback onWordmark;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;
    final useCompactImport = width < 380;
    return Row(
      children: [
        RelayWordmark(onTap: onWordmark),
        const Spacer(),
        if (isWide) ...[
          const StatusLabel(
            label: 'Local only',
            tone: StatusTone.outline,
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
        if (useCompactImport)
          Tooltip(
            message: 'Import a document',
            child: OutlinedButton(
              onPressed: onImport,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                side: BorderSide(color: colors.line),
              ),
              child: Icon(Icons.add_rounded, size: 20, color: colors.ink),
            ),
          )
        else
          FilledButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Import'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              backgroundColor: colors.ink,
              foregroundColor: colors.canvas,
            ),
          ),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.query,
    required this.enabled,
    required this.onChanged,
    required this.onOpenFilters,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.filterCount,
  });

  final TextEditingController controller;
  final LibraryQuery query;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilters;
  final LibraryViewMode viewMode;
  final ValueChanged<LibraryViewMode> onViewModeChanged;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Column(
      children: [
        RelaySearchField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ToolbarButton(
                onTap: onOpenFilters,
                semanticLabel: 'Change sort order or filters',
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_vert_rounded,
                      size: 17,
                      color: colors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        query.sort.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _RectangleIconButton(
              onPressed: enabled ? onOpenFilters : null,
              tooltip: 'Filter library',
              icon: Icons.tune_rounded,
              badgeCount: filterCount,
            ),
            const SizedBox(width: AppSpacing.md),
            ViewModeToggle(
              gridSelected: viewMode == LibraryViewMode.grid,
              onChanged: (grid) => onViewModeChanged(
                grid ? LibraryViewMode.grid : LibraryViewMode.list,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.onTap,
    required this.child,
    required this.semanticLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: BorderSide(color: colors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RectangleIconButton extends StatelessWidget {
  const _RectangleIconButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    this.badgeCount = 0,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: badgeCount > 0 ? '$tooltip, $badgeCount active' : tooltip,
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            side: BorderSide(color: colors.line),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: onPressed == null ? colors.muted : colors.ink,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: 7,
                      top: 7,
                      child: Container(
                        width: 13,
                        height: 13,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return InputChip(
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium,
      backgroundColor: colors.sage,
      deleteIcon: const Icon(Icons.close_rounded, size: 14),
      deleteIconColor: colors.ink,
      onDeleted: onRemove,
      deleteButtonTooltipMessage: 'Remove $label filter',
      side: BorderSide(color: colors.line.withValues(alpha: 0.8)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ContinueReadingRail extends StatelessWidget {
  const _ContinueReadingRail({required this.items});

  final List<LibraryItem> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 600 ? 340.0 : 292.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final railHeight = 132 + (textScale - 1).clamp(0.0, 1.2) * 64;
    return SizedBox(
      height: railHeight,
      child: ListView.separated(
        key: const PageStorageKey('continue-reading'),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: math.min(cardWidth, width - 48),
            child: ContinueReadingCard(
              item: item,
              onTap: () => context.push('/reader/${item.document.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.query,
    required this.visibleCount,
    required this.totalCount,
  });

  final LibraryQuery query;
  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final eyebrow = query.hasSearch
        ? 'Search results'
        : query.filters.isActive
        ? 'Filtered collection'
        : 'Collection';
    final title = query.hasSearch
        ? 'Results'
        : query.filters.isActive
        ? 'Filtered books'
        : 'Your collection';
    return SectionHeader(
      eyebrow: eyebrow,
      title: title,
      trailing: Text(
        query.isFiltering
            ? '$visibleCount of $totalCount'
            : '$totalCount ${totalCount == 1 ? 'document' : 'documents'}',
        style: AppTypography.eyebrow(
          colors.muted,
        ).copyWith(fontSize: 9.5, letterSpacing: 0.8),
      ),
    );
  }
}

class _LibraryGrid extends StatelessWidget {
  const _LibraryGrid({super.key, required this.items, required this.onOpen});

  final List<LibraryItem> items;
  final ValueChanged<LibraryItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        const gap = AppSpacing.lg;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: AppSpacing.xxl,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: DocumentGridCard(item: item, onTap: () => onOpen(item)),
              ),
          ],
        );
      },
    );
  }

  int _columnsFor(double width) {
    if (width >= 1040) return 6;
    if (width >= 820) return 5;
    if (width >= 600) return 4;
    if (width >= 380) return 3;
    return 2;
  }
}

class _LibraryList extends StatelessWidget {
  const _LibraryList({super.key, required this.items, required this.onOpen});

  final List<LibraryItem> items;
  final ValueChanged<LibraryItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0)
            const Divider(indent: AppSpacing.xs, endIndent: AppSpacing.xs),
          DocumentListTile(
            item: items[index],
            onTap: () => onOpen(items[index]),
          ),
        ],
      ],
    );
  }
}
