import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/relay_brand_icon.dart';
import '../../../core/widgets/relay_buttons.dart';
import '../../../core/widgets/screen_top_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../library/domain/document.dart';
import '../application/share_providers.dart';
import '../domain/share_invitation.dart';
import '../domain/share_state.dart';
import 'widgets/share_progress_panel.dart';

/// Receiver flow: scan the sender's code, review the offered files, then approve
/// or decline. The scanner is the only input and nothing is saved before the
/// explicit approval step.
class ShareReceiveScreen extends ConsumerStatefulWidget {
  const ShareReceiveScreen({super.key});

  @override
  ConsumerState<ShareReceiveScreen> createState() => _ShareReceiveScreenState();
}

class _ShareReceiveScreenState extends ConsumerState<ShareReceiveScreen> {
  bool _busy = false;
  String? _localError;

  Future<void> _scan() async {
    if (_busy) return;
    setState(() => _localError = null);
    final invitation = await context.push<ShareInvitation>('/nearby/scan');
    if (!mounted || invitation == null) return;
    await _join(invitation);
  }

  Future<void> _join(ShareInvitation invitation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _localError = null;
    });
    final service = ref.read(shareServiceProvider);
    unawaited(
      service.join(invitation).catchError((Object error) {
        if (!mounted) return;
        if (error is StateError) return;
        showRelaySnackBar(
          context,
          'Relay could not complete the connection. Scan a new code and try '
          'again.',
          isError: true,
        );
      }),
    );
    // The connection states arrive through the stream; release the button as
    // soon as the service leaves the initial connecting state.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _approve() async {
    try {
      await ref.read(shareServiceProvider).approveIncoming();
    } on Object {
      if (!mounted) return;
      showRelaySnackBar(
        context,
        'This transfer is no longer waiting for approval.',
        isError: true,
      );
    }
  }

  Future<void> _decline() async {
    await ref.read(shareServiceProvider).rejectIncoming();
  }

  Future<void> _cancel() async {
    await ref.read(shareServiceProvider).disconnectReceiver();
  }

  Future<void> _reset() async {
    try {
      await ref.read(shareServiceProvider).resetReceiver();
    } on Object {
      // A session still winding down will clear itself through the stream.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final receiver =
        ref.watch(receiverShareStateProvider).value ??
        const ReceiverShareState.idle();

    final content = switch (receiver.phase) {
      SharePhase.idle => _buildLanding(context, receiver),
      SharePhase.connecting => _buildConnecting(context, receiver),
      SharePhase.awaitingApproval => _buildApproval(context, receiver),
      SharePhase.preparing ||
      SharePhase.waiting ||
      SharePhase.transferring => _buildTransferring(context, receiver),
      SharePhase.completed ||
      SharePhase.failed ||
      SharePhase.cancelled => _buildResult(context, receiver),
    };

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenTopBar(
              title: 'Receive documents',
              subtitle: 'Scan once, then approve',
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
  // Landing
  // ---------------------------------------------------------------------------

  Widget _buildLanding(BuildContext context, ReceiverShareState receiver) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final crossNetwork = ref.watch(shareCrossNetworkConfiguredProvider);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                RelayBrandIcon(size: 72, borderRadius: AppRadii.xl),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Scan the sender’s code',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Open Relay on the sending device, choose Send documents, '
                  'and show its QR code. Then scan it here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          RelayButton(
            label: 'Open camera',
            icon: Icons.qr_code_scanner_rounded,
            expanded: true,
            isLoading: _busy,
            onPressed: _busy ? null : _scan,
          ),
          if (_localError != null) ...[
            const SizedBox(height: AppSpacing.md),
            InlineNotice(
              title: 'Connection not completed',
              message: _localError!,
              tone: NoticeTone.accent,
              icon: Icons.link_off_rounded,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _InfoRow(
            icon: Icons.visibility_outlined,
            title: 'You see the files first',
            body:
                'The receiving device always shows the sender name, file '
                'names and sizes before anything is downloaded.',
          ),
          _InfoRow(
            icon: crossNetwork ? Icons.route_rounded : Icons.lan_outlined,
            title: crossNetwork
                ? 'Nearby first, relay fallback'
                : 'Nearby networks',
            body: crossNetwork
                ? 'Relay tries the local network first, then a direct WebRTC '
                      'connection, and finally an encrypted relay when the '
                      'network blocks both.'
                : 'This build transfers between devices on the same network. '
                      'No address, port or code entry is needed.',
          ),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            title: 'Verified before it is saved',
            body:
                'Every file is streamed in chunks and checked against its '
                'SHA-256 checksum before it appears in your library.',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'The code is single-use and expires in minutes. Relay never opens '
            'scanned text as a link.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Connecting
  // ---------------------------------------------------------------------------

  Widget _buildConnecting(BuildContext context, ReceiverShareState receiver) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: _StatusShell(
        icon: Icons.sync_rounded,
        title: 'Connecting to ${receiver.senderName ?? 'the sender'}',
        message:
            receiver.message ??
            'Finding the fastest route. This usually takes a few seconds.',
        child: const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: LinearProgressIndicator(minHeight: 3),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Approval
  // ---------------------------------------------------------------------------

  Widget _buildApproval(BuildContext context, ReceiverShareState receiver) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final offer = receiver.offer;
    if (offer == null) {
      return _buildConnecting(context, receiver);
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'Approve or decline',
            title:
                '${offer.fileCount} '
                '${offer.fileCount == 1 ? 'file' : 'files'} from '
                '${receiver.senderName ?? 'the sender'}',
            description: receiver.path?.label,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              children: [
                for (var index = 0; index < offer.files.length; index++) ...[
                  if (index > 0) Divider(height: 1, color: colors.line),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Icon(
                            offer.files[index].format.name == 'pdf'
                                ? Icons.picture_as_pdf_outlined
                                : Icons.menu_book_outlined,
                            size: 19,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.files[index].fileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${offer.files[index].format.label} · '
                                '${formatBytes(offer.files[index].sizeBytes)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Divider(height: 1, color: colors.line),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Total', style: theme.textTheme.titleSmall),
                      ),
                      Text(
                        formatBytes(offer.totalBytes),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: RelayButton(
                  label: 'Decline',
                  variant: RelayButtonVariant.secondary,
                  onPressed: _decline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: RelayButton(
                  label: 'Approve & receive',
                  icon: Icons.download_rounded,
                  onPressed: _approve,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const InlineNotice(
            title: 'Nothing saved yet',
            message:
                'Approving starts the transfer. Files are checksum-verified '
                'and stored privately inside Relay; the sender cannot see what '
                'else is in your library.',
            tone: NoticeTone.neutral,
            icon: Icons.lock_outline_rounded,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Transferring
  // ---------------------------------------------------------------------------

  Widget _buildTransferring(BuildContext context, ReceiverShareState receiver) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'Receiving',
            title: receiver.message ?? 'Receiving files',
            description: receiver.path?.label,
          ),
          const SizedBox(height: AppSpacing.lg),
          ShareProgressPanel(
            title: 'Transfer progress',
            progress: receiver.progress,
            message: receiver.senderName == null
                ? null
                : 'From ${receiver.senderName}',
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

  // ---------------------------------------------------------------------------
  // Result
  // ---------------------------------------------------------------------------

  Widget _buildResult(BuildContext context, ReceiverShareState receiver) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final completed = receiver.phase == SharePhase.completed;
    final cancelled = receiver.phase == SharePhase.cancelled;

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
                      ? 'Files received'
                      : cancelled
                      ? 'Receive cancelled'
                      : 'Transfer did not finish',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  receiver.message ?? 'Relay stopped this transfer.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (receiver.results.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'File results'),
            const SizedBox(height: AppSpacing.sm),
            ShareResultsList(results: receiver.results),
          ],
          const SizedBox(height: AppSpacing.xl),
          RelayButton(
            label: completed ? 'Open library' : 'Done',
            expanded: true,
            onPressed: () async {
              final router = GoRouter.of(context);
              final navigator = Navigator.of(context);
              await _reset();
              if (!mounted) return;
              if (completed) {
                router.go('/library');
              } else {
                navigator.pop();
              }
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          if (!completed)
            RelayButton(
              label: 'Scan another code',
              variant: RelayButtonVariant.secondary,
              icon: Icons.qr_code_scanner_rounded,
              expanded: true,
              onPressed: () async {
                await _reset();
                if (!mounted) return;
                await _scan();
              },
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 18, color: colors.ink),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                  ),
                ),
              ],
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
