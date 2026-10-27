import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/relay_dialogs.dart';
import '../../../core/widgets/relay_buttons.dart';
import '../../../core/widgets/relay_loading.dart';
import '../../../core/widgets/relay_progress_bar.dart';
import '../../../core/widgets/relay_sheet.dart';
import '../../../core/widgets/relay_states.dart';
import '../../../core/widgets/screen_top_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_label.dart';
import '../../nearby/application/share_intent_provider.dart';
import '../../reader/application/reading_providers.dart';
import '../../reader/domain/reading_progress.dart';
import '../application/library_providers.dart';
import '../domain/document.dart';
import '../domain/library_item.dart';
import 'widgets/document_cover.dart';

class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentByIdProvider(documentId));
    final item = ref.watch(libraryItemByIdProvider(documentId));
    final colors = context.relayColors;

    return documentAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.canvas,
        body: Column(
          children: [
            const ScreenTopBar(title: 'Document details', showDivider: true),
            const Expanded(
              child: RelayLoadingIndicator(label: 'Opening document details…'),
            ),
          ],
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: colors.canvas,
        body: Column(
          children: [
            ScreenTopBar(
              title: 'Document details',
              showDivider: true,
              leading: IconButton(
                tooltip: 'Back',
                onPressed: () => _goBack(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Expanded(
              child: RelayErrorState(
                title: 'This document could not be loaded',
                message:
                    'Relay could not read the local library. Nothing has been '
                    'removed from the device.',
                onRetry: () => ref.invalidate(documentsProvider),
              ),
            ),
          ],
        ),
      ),
      data: (document) {
        if (document == null) {
          return Scaffold(
            backgroundColor: colors.canvas,
            body: Column(
              children: [
                ScreenTopBar(
                  title: 'Document details',
                  showDivider: true,
                  leading: IconButton(
                    tooltip: 'Back',
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                Expanded(
                  child: RelayEmptyState(
                    icon: Icons.find_in_page_outlined,
                    title: 'Document not found',
                    message:
                        'This item is no longer part of your local library.',
                    action: RelayButton(
                      label: 'Back to library',
                      onPressed: () => context.go('/library'),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: colors.canvas,
          body: Column(
            children: [
              ScreenTopBar(
                title: 'Document details',
                showDivider: true,
                leading: IconButton(
                  tooltip: 'Back',
                  onPressed: () => _goBack(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                actions: [
                  PopupMenuButton<_DocumentAction>(
                    tooltip: 'More options',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (action) =>
                        _handleAction(context, ref, document, action),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _DocumentAction.toggleFinished,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item?.isFinished == true
                                ? Icons.mark_email_unread_outlined
                                : Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                          title: Text(
                            item?.isFinished == true
                                ? 'Mark as unread'
                                : 'Mark as finished',
                          ),
                        ),
                      ),
                      const PopupMenuItem(
                        value: _DocumentAction.fileInformation,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.description_outlined, size: 20),
                          title: Text('File information'),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: _DocumentAction.remove,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline_rounded, size: 20),
                          title: Text('Remove from library'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.giant),
                  child: RelayContent(
                    maxWidth: 880,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xxl),
                        _DocumentHeader(document: document, item: item),
                        const SizedBox(height: AppSpacing.xxl),
                        if (item != null && item.hasProgress) ...[
                          _ProgressPanel(item: item),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        _ActionRow(
                          document: document,
                          item: item,
                          onRead: () => context.push('/reader/${document.id}'),
                          canRead: !document.isMissing,
                          onShare: () {
                            ref
                                .read(shareIntentProvider.notifier)
                                .setDocument(document.id);
                            ref.read(shareIntentResetProvider.notifier).reset();
                            context.go('/nearby');
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        _MetadataSection(document: document),
                        const SizedBox(height: AppSpacing.xxxl),
                        SectionHeader(
                          eyebrow: 'About this document',
                          title: document.title,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          document.description,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colors.ink.withValues(alpha: 0.86),
                                height: 1.6,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Source: ${document.source}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (document.isMissing)
                          InlineNotice(
                            title: 'File missing',
                            message:
                                'Relay can no longer find its stored copy of '
                                'this document. You can remove the library '
                                'record. The original file you imported is not '
                                'affected.',
                            icon: Icons.warning_amber_rounded,
                            tone: NoticeTone.accent,
                          )
                        else
                          InlineNotice(
                            title: 'Stored privately in Relay',
                            message:
                                'Relay keeps its own copy in app-managed '
                                'storage so the document opens offline. '
                                'Removing it deletes only that copy; the '
                                'original file on your device stays where it is.',
                            icon: Icons.offline_pin_outlined,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    Document document,
    _DocumentAction action,
  ) async {
    switch (action) {
      case _DocumentAction.fileInformation:
        showRelaySheet<void>(
          context,
          builder: (_) => _FileInformationSheet(document: document),
        );
      case _DocumentAction.toggleFinished:
        await _toggleFinished(context, ref, document);
      case _DocumentAction.remove:
        await _removeDocument(context, ref, document);
    }
  }

  Future<void> _toggleFinished(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    final current = ref.read(readingProgressForProvider(document.id));
    final nowFinished = !(current?.isFinished ?? false);
    final progress = ReadingProgress(
      documentId: document.id,
      fraction: nowFinished ? 1 : 0,
      locationIndex: nowFinished ? (current?.locationIndex ?? 0) : 0,
      locationOffset: nowFinished ? (current?.locationOffset ?? 0) : 0,
      locationRef: nowFinished ? current?.locationRef : null,
      lastReadAt: nowFinished ? DateTime.now() : null,
      bookmarks: current?.bookmarks ?? const {},
    );
    try {
      await ref.read(readingProgressRepositoryProvider).saveProgress(progress);
      if (!context.mounted) return;
      showRelaySnackBar(
        context,
        nowFinished ? 'Marked as finished.' : 'Marked as unread.',
        icon: nowFinished
            ? Icons.check_circle_outline_rounded
            : Icons.circle_outlined,
      );
    } catch (_) {
      if (!context.mounted) return;
      showRelaySnackBar(
        context,
        'Reading status could not be updated.',
        isError: true,
      );
    }
  }

  Future<void> _removeDocument(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    final confirmed = await showRelayConfirmationDialog(
      context,
      title: 'Remove from Relay?',
      message: document.isMissing
          ? 'Relay will remove the library record for “${document.title}”. '
                'Relay has no stored file for it. Your original file is not '
                'affected.'
          : 'Relay will permanently delete its own stored copy of '
                '“${document.title}” and its reading progress. The original '
                'file you imported is not affected and will remain on your '
                'device.',
      confirmLabel: 'Remove from Relay',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(documentRepositoryProvider).removeDocument(document.id);
      if (!context.mounted) return;
      showRelaySnackBar(
        context,
        'Removed from Relay. Your original file is unchanged.',
      );
      context.go('/library');
    } catch (_) {
      if (!context.mounted) return;
      showRelaySnackBar(
        context,
        'Relay could not finish removing this document. Check the library; '
        'the item may now show as missing. Your original file is unchanged.',
        isError: true,
      );
    }
  }
}

enum _DocumentAction { toggleFinished, fileInformation, remove }

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({required this.document, required this.item});

  final Document document;
  final LibraryItem? item;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 380;
    final wide = screenWidth >= 720;
    final coverWidth = wide
        ? 190.0
        : compact
        ? 96.0
        : 124.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: coverWidth,
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: DocumentCover(document: document),
          ),
        ),
        SizedBox(width: compact ? AppSpacing.md : AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.format.description.toUpperCase(),
                style: AppTypography.eyebrow(colors.muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                document.title,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: compact ? 22 : (wide ? 32 : 27),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                document.author,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusLabel(
                    label: item?.readingStatus.label ?? 'Unread',
                    tone: item?.isFinished == true
                        ? StatusTone.success
                        : item?.hasProgress == true
                        ? StatusTone.accent
                        : StatusTone.neutral,
                  ),
                  StatusLabel(
                    label:
                        '${document.format.label} · '
                        '${formatBytes(document.sizeBytes)}',
                    tone: StatusTone.outline,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    document.isMissing
                        ? Icons.warning_amber_rounded
                        : Icons.offline_pin_outlined,
                    size: 15,
                    color: document.isMissing ? colors.warning : colors.success,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      document.isMissing
                          ? 'Relay’s stored copy is missing'
                          : 'Stored offline in Relay · original file untouched',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: document.isMissing
                            ? colors.warning
                            : colors.success,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.document,
    required this.item,
    required this.onRead,
    required this.onShare,
    required this.canRead,
  });

  final Document document;
  final LibraryItem? item;
  final VoidCallback onRead;
  final VoidCallback onShare;
  final bool canRead;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final label = !canRead
        ? 'File missing'
        : item?.isFinished == true
        ? 'Read again'
        : item?.hasProgress == true
        ? 'Continue reading'
        : 'Start reading';

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: canRead ? onRead : null,
            icon: Icon(
              canRead ? Icons.menu_book_rounded : Icons.file_present_outlined,
              size: 18,
            ),
            label: Text(label),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: 'Share locally',
          onTap: onShare,
          excludeSemantics: true,
          child: Tooltip(
            message: 'Share locally',
            excludeFromSemantics: true,
            child: OutlinedButton(
              onPressed: onShare,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, AppSizes.controlHeight),
                padding: EdgeInsets.zero,
                side: BorderSide(color: colors.line),
              ),
              child: Icon(Icons.near_me_outlined, size: 19, color: colors.ink),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final lastRead = item.lastReadAt;
    final bookmarks = item.progress?.bookmarks.length ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.sage,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'READING PROGRESS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.eyebrow(
                    colors.muted,
                  ).copyWith(color: colors.ink.withValues(alpha: 0.68)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${item.percent}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          RelayProgressBar(
            value: item.fraction,
            height: 5,
            color: item.isFinished ? colors.success : colors.accent,
            trackColor: colors.ink.withValues(alpha: 0.12),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              if (lastRead != null)
                Text(
                  item.isFinished
                      ? 'Finished ${formatTimeAgo(lastRead)}'
                      : 'Last read ${formatTimeAgo(lastRead)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.ink.withValues(alpha: 0.72),
                  ),
                ),
              if (bookmarks > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 13,
                      color: colors.ink.withValues(alpha: 0.68),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$bookmarks ${bookmarks == 1 ? 'bookmark' : 'bookmarks'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.ink.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, String)>[
      ('Format', document.format.label),
      ('File size', formatBytes(document.sizeBytes)),
      if (document.pageCount != null) ('Pages', '${document.pageCount}'),
      ('Added', formatDate(document.addedAt)),
      if (document.lastOpenedAt != null)
        ('Last opened', formatDate(document.lastOpenedAt!)),
      ('Language', document.language),
      ('Source', document.source),
      (
        'Availability',
        document.isMissing ? 'Relay copy missing' : 'Stored in Relay',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(eyebrow: 'At a glance', title: 'Document details'),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620 ? 3 : 2;
            const gap = AppSpacing.lg;
            final itemWidth =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: AppSpacing.xl,
              children: [
                for (final entry in entries)
                  SizedBox(
                    width: itemWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.$1.toUpperCase(),
                          style: AppTypography.eyebrow(
                            context.relayColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.$2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const Divider(),
      ],
    );
  }
}

class _FileInformationSheet extends StatelessWidget {
  const _FileInformationSheet({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, String)>[
      ('Title', document.title),
      ('Author', document.author),
      ('Source', document.source),
      ('Format', document.format.description),
      ('File size', formatBytes(document.sizeBytes)),
      if (document.pageCount != null) ('Pages', '${document.pageCount}'),
      ('Language', document.language),
      ('Original file name', document.displayFileName),
      ('Added to library', formatDate(document.addedAt)),
      if (document.lastOpenedAt != null)
        ('Last opened', formatDate(document.lastOpenedAt!)),
      (
        'Availability',
        document.isMissing
            ? 'Relay copy missing — original file not affected'
            : 'Stored in Relay app storage',
      ),
      if (document.sha256 != null) ('Checksum', document.sha256!),
    ];

    return RelaySheetScaffold(
      title: 'File information',
      subtitle: 'Details recorded for this library item.',
      trailing: IconButton(
        tooltip: 'Close',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              if (index > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 122,
                      child: Text(
                        entries[index].$1.toUpperCase(),
                        style: AppTypography.eyebrow(context.relayColors.muted),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        entries[index].$2,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
