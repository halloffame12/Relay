import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/relay_brand_icon.dart';
import '../../../core/widgets/relay_buttons.dart';
import '../../../core/widgets/relay_states.dart';
import '../../../core/widgets/screen_top_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_label.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/document.dart';
import '../../library/presentation/widgets/document_cover.dart';
import '../application/share_providers.dart';
import '../data/share_service.dart';
import '../domain/share_offer.dart';
import '../domain/share_state.dart';
import 'widgets/share_progress_panel.dart';

/// Sender flow: choose files, show a QR code, then stream after the receiver
/// approves. The QR is the only pairing artifact and it expires automatically.
class ShareSendScreen extends ConsumerStatefulWidget {
  const ShareSendScreen({super.key});

  @override
  ConsumerState<ShareSendScreen> createState() => _ShareSendScreenState();
}

class _ShareSendScreenState extends ConsumerState<ShareSendScreen> {
  final Set<String> _selected = <String>{};
  bool _starting = false;
  String? _localError;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final phase = ref.read(senderShareStateProvider).value?.phase;
      if (phase == SharePhase.waiting) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting || _selected.isEmpty) return;
    setState(() {
      _starting = true;
      _localError = null;
    });
    try {
      await ref.read(shareServiceProvider).startSender(_selected.toList());
    } on ShareException catch (error) {
      if (mounted) setState(() => _localError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _localError =
              'Relay could not start this share. Check that the selected files '
              'are still on this device and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _cancel() async {
    await ref.read(shareServiceProvider).cancelSender();
  }

  Future<void> _reset({bool pop = false}) async {
    _selected.clear();
    await ref.read(shareServiceProvider).resetSender();
    if (pop && mounted) context.pop();
  }

  Future<void> _refreshCode() async {
    try {
      await ref.read(shareServiceProvider).refreshSenderInvitation();
    } on ShareException catch (error) {
      if (!mounted) return;
      showRelaySnackBar(context, error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      showRelaySnackBar(
        context,
        'Relay could not create a new code.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final sender =
        ref.watch(senderShareStateProvider).value ??
        const SenderShareState.idle();

    final content = switch (sender.phase) {
      SharePhase.idle => _buildSelection(context),
      SharePhase.preparing => _StatusShell(
        icon: Icons.hourglass_top_rounded,
        title: 'Preparing your documents',
        message:
            sender.message ??
            'Checking that every selected file is still on this device.',
        child: const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: LinearProgressIndicator(minHeight: 3),
        ),
      ),
      SharePhase.waiting => _buildWaiting(context, sender),
      SharePhase.connecting ||
      SharePhase.awaitingApproval ||
      SharePhase.transferring => _buildSession(context, sender),
      SharePhase.completed ||
      SharePhase.failed ||
      SharePhase.cancelled => _buildResult(context, sender),
    };

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenTopBar(
              title: 'Send documents',
              subtitle: 'No address, port or code entry',
              leading: IconButton(
                tooltip: 'Back',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: RelayBrandIcon(size: 28, borderRadius: AppRadii.sm),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.giant),
                child: RelayContent(maxWidth: 720, child: content),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  Widget _buildSelection(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final documents = ref.watch(documentsProvider).value ?? const <Document>[];
    final available = documents
        .where((document) => document.isAvailableOffline)
        .toList();

    if (available.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxxl),
        child: RelayEmptyState(
          brand: true,
          icon: Icons.menu_book_outlined,
          title: 'Nothing to send yet',
          message:
              'Import a PDF or EPUB into Relay first. Relay only sends its own '
              'managed copy and never exposes other files on this device.',
          action: RelayButton(
            label: 'Import a document',
            icon: Icons.add_rounded,
            onPressed: () => context.push('/import'),
          ),
        ),
      );
    }

    final selectedBytes = available
        .where((document) => _selected.contains(document.id))
        .fold<int>(0, (sum, document) => sum + document.sizeBytes);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'Step 1 of 2',
            title: 'Choose documents',
            description:
                'Select up to $shareMaxFilesPerBatch files, '
                '${formatBytes(shareMaxBatchBytes)} in total.',
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final document in available)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SelectableDocument(
                document: document,
                selected: _selected.contains(document.id),
                onTap: () => _toggle(document, selectedBytes),
              ),
            ),
          if (_localError != null) ...[
            const SizedBox(height: AppSpacing.md),
            InlineNotice(
              title: 'Could not start',
              message: _localError!,
              tone: NoticeTone.accent,
              icon: Icons.error_outline_rounded,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selected.isEmpty
                            ? 'No documents selected'
                            : '${_selected.length} '
                                  '${_selected.length == 1 ? 'document' : 'documents'}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      formatBytes(selectedBytes),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                RelayButton(
                  label: 'Show QR code',
                  icon: Icons.qr_code_2_rounded,
                  expanded: true,
                  isLoading: _starting,
                  onPressed: _selected.isEmpty ? null : _start,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'The receiver scans this code. Nothing is sent until they '
                  'review and approve the file list.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(Document document, int selectedBytes) {
    if (_selected.contains(document.id)) {
      setState(() => _selected.remove(document.id));
      return;
    }
    if (_selected.length >= shareMaxFilesPerBatch) {
      showRelaySnackBar(
        context,
        'Relay can send up to $shareMaxFilesPerBatch files at once.',
      );
      return;
    }
    if (selectedBytes + document.sizeBytes > shareMaxBatchBytes) {
      showRelaySnackBar(
        context,
        'That would exceed the ${formatBytes(shareMaxBatchBytes)} batch limit.',
      );
      return;
    }
    setState(() => _selected.add(document.id));
  }

  // ---------------------------------------------------------------------------
  // Waiting with QR
  // ---------------------------------------------------------------------------

  Widget _buildWaiting(BuildContext context, SenderShareState sender) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final invitation = sender.invitation;
    if (invitation == null) {
      return _StatusShell(
        icon: Icons.qr_code_2_rounded,
        title: 'Preparing a new code',
        message: 'Relay is refreshing the share session.',
      );
    }
    final remaining = invitation.remainingAt(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'Step 2 of 2',
            title: 'Show this code',
            description:
                'On the other device, open Relay, choose Receive documents, '
                'and scan this code.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: colors.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: QrImageView(
                      data: invitation.payload,
                      size: 232,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      semanticsLabel:
                          'Relay share code. Scan it from the receiving device.',
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                StatusLabel(
                  label: 'Expires in ${_formatCountdown(remaining)}',
                  tone: remaining.inSeconds <= 60
                      ? StatusTone.warning
                      : StatusTone.outline,
                  icon: Icons.timer_outlined,
                  uppercase: false,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  sender.message ?? 'Waiting for a device to scan…',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: RelayButton(
                        label: 'New code',
                        icon: Icons.refresh_rounded,
                        variant: RelayButtonVariant.secondary,
                        onPressed: _refreshCode,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: RelayButton(
                        label: 'Stop',
                        variant: RelayButtonVariant.secondary,
                        onPressed: _cancel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SenderSummary(
            fileCount: sender.fileCount,
            totalBytes: sender.totalBytes,
          ),
          const SizedBox(height: AppSpacing.md),
          const InlineNotice(
            title: 'Single use',
            message:
                'This code works once and expires automatically. Relay never '
                'shows an IP address or port on screen, and the code contains '
                'no account or long-lived secret.',
            tone: NoticeTone.neutral,
            icon: Icons.shield_outlined,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active session
  // ---------------------------------------------------------------------------

  Widget _buildSession(BuildContext context, SenderShareState sender) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final peer = sender.peerName ?? 'the receiving device';

    if (sender.phase == SharePhase.transferring) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              eyebrow: 'Sending',
              title: 'Transferring to $peer',
              description: sender.path?.label,
            ),
            const SizedBox(height: AppSpacing.lg),
            ShareProgressPanel(
              title: 'Transfer progress',
              progress: sender.progress,
              message: sender.message,
            ),
            const SizedBox(height: AppSpacing.lg),
            RelayButton(
              label: 'Cancel transfer',
              variant: RelayButtonVariant.secondary,
              expanded: true,
              onPressed: _cancel,
            ),
          ],
        ),
      );
    }

    final connecting = sender.phase == SharePhase.connecting;
    final awaiting = sender.phase == SharePhase.awaitingApproval;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: connecting ? 'Connecting' : 'Waiting for approval',
            title: connecting ? 'Linking to $peer' : 'Waiting for $peer',
            description:
                sender.path?.label ??
                'Establishing the fastest available route.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusShell(
            icon: connecting
                ? Icons.sync_rounded
                : Icons.hourglass_bottom_rounded,
            title: connecting
                ? 'Establishing a connection'
                : 'Review in progress',
            message:
                sender.message ??
                (connecting
                    ? 'Relay is negotiating a route to the other device.'
                    : 'The receiving device is reviewing the file list. '
                          'Nothing is sent until they approve.'),
            child: const Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SenderSummary(
            fileCount: sender.fileCount,
            totalBytes: sender.totalBytes,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (awaiting)
            RelayButton(
              label: 'Cancel',
              variant: RelayButtonVariant.secondary,
              expanded: true,
              onPressed: _cancel,
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Keep this screen open. Relay will continue while the app is in '
            'the foreground.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result
  // ---------------------------------------------------------------------------

  Widget _buildResult(BuildContext context, SenderShareState sender) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final completed = sender.phase == SharePhase.completed;
    final cancelled = sender.phase == SharePhase.cancelled;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                RelayBrandIcon(size: 64, borderRadius: AppRadii.lg),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  completed
                      ? 'Transfer finished'
                      : cancelled
                      ? 'Share cancelled'
                      : 'Transfer did not finish',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  sender.message ??
                      (completed
                          ? 'The files were delivered.'
                          : 'Relay stopped this transfer.'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (sender.results.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'File results'),
            const SizedBox(height: AppSpacing.sm),
            ShareResultsList(results: sender.results),
          ],
          const SizedBox(height: AppSpacing.xl),
          RelayButton(
            label: 'Done',
            expanded: true,
            onPressed: () => _reset(pop: true),
          ),
          const SizedBox(height: AppSpacing.xs),
          RelayButton(
            label: 'Send something else',
            variant: RelayButtonVariant.secondary,
            expanded: true,
            onPressed: () => _reset(),
          ),
        ],
      ),
    );
  }

  static String _formatCountdown(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 99999);
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

class _SelectableDocument extends StatelessWidget {
  const _SelectableDocument({
    required this.document,
    required this.selected,
    required this.onTap,
  });

  final Document document;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Material(
      color: selected ? colors.accentSoft : colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: selected ? colors.accent : colors.line),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 60,
                child: DocumentCover(
                  document: document,
                  showShadow: false,
                  borderRadius: 3,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${document.format.label} · '
                      '${formatBytes(document.sizeBytes)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.accent : colors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SenderSummary extends StatelessWidget {
  const _SenderSummary({required this.fileCount, required this.totalBytes});

  final int fileCount;
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 18, color: colors.muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$fileCount ${fileCount == 1 ? 'document' : 'documents'} · '
              '${formatBytes(totalBytes)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusShell extends StatelessWidget {
  const _StatusShell({
    required this.icon,
    required this.title,
    required this.message,
    this.child,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: colors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
          if (child != null) ?child,
        ],
      ),
    );
  }
}
