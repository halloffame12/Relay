import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/relay_buttons.dart';
import '../../../core/widgets/relay_dialogs.dart';
import '../../../core/widgets/relay_loading.dart';
import '../../../core/widgets/relay_progress_bar.dart';
import '../../../core/widgets/relay_states.dart';
import '../../../core/widgets/relay_wordmark.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_label.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/document.dart';
import '../../library/presentation/widgets/document_cover.dart';
import '../../settings/application/settings_providers.dart';
import '../application/transfer_providers.dart';
import '../domain/transfer_task.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.relayColors;
    final useCompactWordmark = MediaQuery.sizeOf(context).width < 380;
    final transfersAsync = ref.watch(transfersProvider);
    final documents = ref.watch(documentsProvider).value ?? const [];
    final documentsById = {
      for (final document in documents) document.id: document,
    };

    final tasks = transfersAsync.value ?? const <TransferTask>[];
    final active = tasks.where((task) => task.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final completed = tasks.where((task) => task.isComplete).toList()
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.createdAt;
        final bDate = b.completedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
    final failed =
        tasks.where((task) => task.isFailed || task.isCancelled).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(transfersProvider),
          color: colors.ink,
          backgroundColor: colors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: AppSpacing.giant),
            child: RelayContent(
              maxWidth: 860,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      RelayWordmark(
                        compact: useCompactWordmark,
                        onTap: () => context.go('/library'),
                      ),
                      const Spacer(),
                      const StatusLabel(
                        label: 'Local Wi-Fi',
                        tone: StatusTone.outline,
                        icon: Icons.wifi_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  PageHeading(
                    eyebrow: 'Direct transfer',
                    title: 'Transfers',
                    subtitle: active.isEmpty
                        ? 'Real incoming and outgoing document transfers appear '
                              'here.'
                        : '${active.length} '
                              '${active.length == 1 ? 'transfer' : 'transfers'} '
                              'in progress. Byte counts come from the socket.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const InlineNotice(
                    title: 'Both devices must be on the same Wi-Fi',
                    message:
                        'Relay streams the file directly between the two '
                        'devices. It does not use an internet relay, a cloud '
                        'service, Bluetooth, or a background server. Some '
                        'public or guest networks block device-to-device '
                        'connections.',
                    icon: Icons.lan_outlined,
                    tone: NoticeTone.sage,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  if (transfersAsync.isLoading)
                    const RelayLoadingIndicator(
                      label: 'Reading transfer records…',
                    )
                  else if (transfersAsync.hasError)
                    RelayErrorState(
                      title: 'Transfer activity could not be read',
                      message:
                          'Relay could not load the local transfer list. No '
                          'documents were affected.',
                      onRetry: () => ref.invalidate(transfersProvider),
                    )
                  else if (tasks.isEmpty)
                    RelayEmptyState(
                      brand: true,
                      icon: Icons.swap_horiz_rounded,
                      title: 'No transfers yet',
                      message:
                          'Open Nearby to offer receive mode or send a '
                          'Relay-managed document to another device.',
                      action: RelayButton(
                        label: 'Open nearby',
                        icon: Icons.near_me_outlined,
                        onPressed: () => context.go('/nearby'),
                      ),
                    )
                  else ...[
                    _ActiveSection(
                      tasks: active,
                      documentsById: documentsById,
                      onOpenNearby: () => context.go('/nearby'),
                      onAction: (task, action) =>
                          _handleAction(context, ref, task, action),
                    ),
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxxl),
                      _CompletedSection(
                        tasks: completed,
                        documentsById: documentsById,
                        onAction: (task, action) =>
                            _handleAction(context, ref, task, action),
                        onClear: () => _clearCompleted(context, ref, completed),
                      ),
                    ],
                    if (failed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxxl),
                      _FailedSection(
                        tasks: failed,
                        documentsById: documentsById,
                        onAction: (task, action) =>
                            _handleAction(context, ref, task, action),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    TransferTask task,
    _TransferAction action,
  ) async {
    final service = ref.read(transferServiceProvider);
    try {
      switch (action) {
        case _TransferAction.cancel:
          final confirm = ref.read(settingsProvider).confirmBeforeCancel;
          if (confirm) {
            if (!context.mounted) return;
            final confirmed = await showRelayConfirmationDialog(
              context,
              title: 'Cancel this transfer?',
              message:
                  '“${task.documentTitle}” will stop immediately. A partial '
                  'incoming file is deleted and never added to the library. '
                  'The sender’s document stays in their library.',
              confirmLabel: 'Cancel transfer',
              cancelLabel: 'Keep transfer',
              destructive: true,
            );
            if (!confirmed || !context.mounted) return;
          }
          await service.cancel(task.id);
          if (!context.mounted) return;
          showRelaySnackBar(context, 'Transfer cancelled.');
        case _TransferAction.remove:
          if (!context.mounted) return;
          final confirmed = await showRelayConfirmationDialog(
            context,
            title: 'Remove this transfer record?',
            message:
                'This only clears the finished transfer entry. Library '
                'documents and reading progress are not changed.',
            confirmLabel: 'Remove record',
            destructive: true,
          );
          if (!confirmed || !context.mounted) return;
          await service.removeTransfer(task.id);
          if (!context.mounted) return;
          showRelaySnackBar(context, 'Transfer record removed.');
        case _TransferAction.open:
          if (!context.mounted) return;
          final documentId = task.documentId;
          final documents = ref.read(documentsProvider).value ?? const [];
          final exists =
              documentId != null &&
              documents.any((document) => document.id == documentId);
          if (!exists) {
            showRelaySnackBar(
              context,
              'This document is no longer in your library.',
              isError: true,
            );
            return;
          }
          context.push('/document/$documentId');
      }
    } catch (_) {
      if (!context.mounted) return;
      showRelaySnackBar(
        context,
        'That transfer action could not be completed.',
        isError: true,
      );
    }
  }

  Future<void> _clearCompleted(
    BuildContext context,
    WidgetRef ref,
    List<TransferTask> completed,
  ) async {
    if (completed.isEmpty) return;
    final confirmed = await showRelayConfirmationDialog(
      context,
      title: 'Clear completed transfers?',
      message:
          '${completed.length} completed '
          '${completed.length == 1 ? 'entry' : 'entries'} will be removed from '
          'this activity list. Documents and reading progress are not '
          'affected.',
      confirmLabel: 'Clear history',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(transferServiceProvider).clearCompleted();
      if (!context.mounted) return;
      showRelaySnackBar(context, 'Completed transfers cleared.');
    } catch (_) {
      if (!context.mounted) return;
      showRelaySnackBar(
        context,
        'Completed transfers could not be cleared.',
        isError: true,
      );
    }
  }
}

enum _TransferAction { cancel, remove, open }

class _ActiveSection extends StatelessWidget {
  const _ActiveSection({
    required this.tasks,
    required this.documentsById,
    required this.onOpenNearby,
    required this.onAction,
  });

  final List<TransferTask> tasks;
  final Map<String, Document> documentsById;
  final VoidCallback onOpenNearby;
  final void Function(TransferTask task, _TransferAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: 'Live',
          title: 'In progress',
          trailing: Text(
            '${tasks.length} active',
            style: AppTypography.eyebrow(
              colors.muted,
            ).copyWith(fontSize: 9.5, letterSpacing: 0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (tasks.isEmpty)
          _QuietRow(
            icon: Icons.check_circle_outline_rounded,
            message: 'Nothing is transferring right now.',
            actionLabel: 'Share a document',
            onAction: onOpenNearby,
          )
        else
          for (var index = 0; index < tasks.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.md),
            _ActiveTransferCard(
              task: tasks[index],
              document: documentsById[tasks[index].documentId],
              onAction: (action) => onAction(tasks[index], action),
            ),
          ],
      ],
    );
  }
}

class _ActiveTransferCard extends StatelessWidget {
  const _ActiveTransferCard({
    required this.task,
    required this.document,
    required this.onAction,
  });

  final TransferTask task;
  final Document? document;
  final ValueChanged<_TransferAction> onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final tone = switch (task.status) {
      TransferStatus.connecting => StatusTone.warning,
      TransferStatus.awaitingApproval => StatusTone.warning,
      TransferStatus.verifying => StatusTone.sage,
      _ => StatusTone.accent,
    };
    final icon = switch (task.status) {
      TransferStatus.connecting => Icons.wifi_find_rounded,
      TransferStatus.awaitingApproval => Icons.hourglass_top_rounded,
      TransferStatus.verifying => Icons.verified_outlined,
      _ => Icons.sync_rounded,
    };
    final statusNote = switch (task.status) {
      TransferStatus.connecting =>
        'Opening a direct connection to the other device.',
      TransferStatus.awaitingApproval =>
        task.direction == TransferDirection.send
            ? 'Waiting for the receiver to approve this document.'
            : 'Waiting for this device to approve the incoming document.',
      TransferStatus.verifying =>
        'Checking the byte count and SHA-256 checksum before import.',
      _ =>
        'Streaming directly over the local network. Do not close Relay '
            'until this finishes.',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverThumb(document: document),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.documentTitle,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusLabel(
                          label: task.statusLabel,
                          tone: tone,
                          icon: icon,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${task.directionLabel} '
                      '${task.direction == TransferDirection.send ? 'to' : 'from'} '
                      '${task.deviceName}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${task.fileTypeLabel} · '
                      '${formatBytes(task.sizeBytes)} · started '
                      '${formatTimeAgo(task.createdAt)}',
                      style: AppTypography.eyebrow(colors.muted).copyWith(
                        fontSize: 9,
                        letterSpacing: 0.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                '${task.percent}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${formatBytes(task.transferredBytes)} of '
                  '${formatBytes(task.sizeBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          RelayProgressBar(
            value: task.progress,
            height: 5,
            color: tone == StatusTone.warning ? colors.warning : colors.accent,
            semanticLabel: '${task.directionLabel} ${task.documentTitle}',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusNote,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
          if (task.canCancel) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                _SmallAction(
                  label: 'Cancel',
                  icon: Icons.close_rounded,
                  destructive: true,
                  onPressed: () => onAction(_TransferAction.cancel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletedSection extends StatelessWidget {
  const _CompletedSection({
    required this.tasks,
    required this.documentsById,
    required this.onAction,
    required this.onClear,
  });

  final List<TransferTask> tasks;
  final Map<String, Document> documentsById;
  final void Function(TransferTask task, _TransferAction action) onAction;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: 'Finished',
          title: 'Completed',
          trailing: TextButton(
            onPressed: onClear,
            child: const Text('Clear history'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < tasks.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _CompletedTransferRow(
            task: tasks[index],
            document: documentsById[tasks[index].documentId],
            onOpen: () => onAction(tasks[index], _TransferAction.open),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Clearing history only removes these entries. Documents stay in your '
          'library.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

class _CompletedTransferRow extends StatelessWidget {
  const _CompletedTransferRow({
    required this.task,
    required this.document,
    required this.onOpen,
  });

  final TransferTask task;
  final Document? document;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final completedAt = task.completedAt;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          _CoverThumb(document: document, width: 30, height: 45),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.documentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.directionLabel} · ${task.deviceName}'
                  '${completedAt == null ? '' : ' · ${formatTimeAgo(completedAt)}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                if (task.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const StatusLabel(
                      label: 'Completed',
                      tone: StatusTone.success,
                      icon: Icons.check_rounded,
                    ),
                    Text(
                      '${task.fileTypeLabel} · '
                      '${formatBytes(task.sizeBytes)}',
                      style: AppTypography.eyebrow(colors.muted).copyWith(
                        fontSize: 9,
                        letterSpacing: 0.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: document == null ? null : onOpen,
            child: Text(document == null ? 'Unavailable' : 'Open'),
          ),
        ],
      ),
    );
  }
}

class _FailedSection extends StatelessWidget {
  const _FailedSection({
    required this.tasks,
    required this.documentsById,
    required this.onAction,
  });

  final List<TransferTask> tasks;
  final Map<String, Document> documentsById;
  final void Function(TransferTask task, _TransferAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: 'Needs attention',
          title: 'Interrupted or cancelled',
          trailing: Text(
            '${tasks.length}',
            style: AppTypography.eyebrow(
              colors.muted,
            ).copyWith(fontSize: 9.5, letterSpacing: 0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < tasks.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _FailedTransferCard(
            task: tasks[index],
            document: documentsById[tasks[index].documentId],
            onRemove: () => onAction(tasks[index], _TransferAction.remove),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Interrupted transfers are never added to the library. Start again '
          'from Nearby when both devices are ready.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

class _FailedTransferCard extends StatelessWidget {
  const _FailedTransferCard({
    required this.task,
    required this.document,
    required this.onRemove,
  });

  final TransferTask task;
  final Document? document;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final cancelled = task.isCancelled;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: cancelled
              ? colors.line
              : colors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverThumb(document: document, width: 30, height: 45),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.documentTitle,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusLabel(
                          label: task.statusLabel,
                          tone: cancelled
                              ? StatusTone.neutral
                              : StatusTone.danger,
                          icon: cancelled
                              ? Icons.cancel_outlined
                              : Icons.error_outline_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${task.directionLabel} · ${task.deviceName} · '
                      '${task.percent}% transferred',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (task.failureReason != null || task.note != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                task.failureReason ?? task.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.ink.withValues(alpha: 0.82),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.end,
            children: [
              _SmallAction(
                label: 'Remove',
                icon: Icons.delete_outline_rounded,
                destructive: true,
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({
    required this.document,
    this.width = 38,
    this.height = 57,
  });

  final Document? document;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    if (document == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: colors.line),
        ),
        child: Icon(Icons.description_outlined, size: 16, color: colors.muted),
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: DocumentCover(
        document: document!,
        showShadow: false,
        borderRadius: 2,
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final foreground = destructive ? colors.danger : colors.ink;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        backgroundColor: destructive
            ? Colors.transparent
            : colors.surfaceSubtle,
        foregroundColor: foreground,
        side: destructive ? BorderSide(color: colors.danger) : null,
        textStyle: Theme.of(context).textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }
}

class _QuietRow extends StatelessWidget {
  const _QuietRow({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
