import 'dart:async';

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
import '../../../core/widgets/screen_top_bar.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/document.dart';
import '../../library/presentation/widgets/document_cover.dart';
import '../../transfers/application/transfer_providers.dart';
import '../../transfers/domain/transfer_invitation.dart';
import '../../transfers/domain/transfer_service.dart';
import '../application/share_intent_provider.dart';
import 'widgets/nearby_share_sheet.dart';

/// Connected send flow reached only from a successfully scanned invitation.
/// The TCP connection is verified here before the user chooses a document.
class QrSendScreen extends ConsumerStatefulWidget {
  const QrSendScreen({super.key, required this.invitation, this.service});

  final TransferInvitation invitation;

  /// Injection seam for widget tests.
  final TransferService? service;

  @override
  ConsumerState<QrSendScreen> createState() => _QrSendScreenState();
}

class _QrSendScreenState extends ConsumerState<QrSendScreen> {
  late final TransferService _service;
  ConnectedPeer? _peer;
  bool _connecting = true;
  bool _attempting = false;
  bool _sending = false;
  bool _sendStarted = false;
  String? _error;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ref.read(transferServiceProvider);
    _selectedId = ref.read(shareIntentProvider);
    unawaited(_connect());
  }

  @override
  void dispose() {
    final peer = _peer;
    if (peer != null && !_sendStarted) {
      unawaited(_service.disconnectPeer(peer.id));
    }
    super.dispose();
  }

  Future<void> _connect() async {
    if (_attempting) return;
    _attempting = true;
    if (mounted) {
      setState(() {
        _connecting = true;
        _error = null;
      });
    }
    final previous = _peer;
    if (previous != null) {
      _peer = null;
      unawaited(_service.disconnectPeer(previous.id));
    }

    try {
      final peer = await _service.connectWithInvitation(widget.invitation);
      if (!mounted) {
        unawaited(_service.disconnectPeer(peer.id));
        return;
      }
      setState(() => _peer = peer);
    } on TransferRequestException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Relay could not connect to this receiver. Ask them to show a new '
            'QR code.',
      );
    } finally {
      _attempting = false;
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _scanAnotherCode() async {
    if (_connecting || _sending) return;
    final invitation = await context.push<TransferInvitation>('/nearby/scan');
    if (!mounted || invitation == null) return;
    context.pushReplacement('/nearby/send', extra: invitation);
  }

  Future<void> _chooseDocument(List<Document> documents) async {
    if (_peer == null || _connecting || _sending) return;
    final document = await showNearbyDocumentPicker(
      context,
      documents: documents,
      selectedId: _selectedId,
    );
    if (document == null || !mounted) return;
    ref.read(shareIntentProvider.notifier).setDocument(document.id);
    setState(() => _selectedId = document.id);
  }

  Future<void> _send(Document document) async {
    final peer = _peer;
    if (peer == null || _sending || _connecting) return;
    if (!document.isAvailableOffline) {
      showRelaySnackBar(
        context,
        'Relay no longer has its managed copy of that document.',
        isError: true,
      );
      return;
    }
    if (document.sha256 == null ||
        !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(document.sha256!)) {
      showRelaySnackBar(
        context,
        'Relay cannot verify this document. Import it again before sending.',
        isError: true,
      );
      return;
    }
    final confirmed = await showRelayConfirmationDialog(
      context,
      title: 'Send to ${peer.deviceName}?',
      message:
          '“${document.title}” (${document.format.label}, '
          '${formatBytes(document.sizeBytes)}) will be streamed directly to '
          '${peer.deviceName} at ${peer.address}:${peer.port}. The receiving '
          'device must approve before any bytes are sent. The document stays '
          'in your library.',
      confirmLabel: 'Send document',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _sending = true;
      _sendStarted = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.relayColors;
    final future = _service.sendDocumentToPeer(
      documentId: document.id,
      peerId: peer.id,
    );
    ref.read(shareIntentProvider.notifier).clear();
    showRelaySnackBar(
      context,
      'Sending to ${peer.deviceName}. Waiting for the receiver to approve.',
      icon: Icons.wifi_find_rounded,
      duration: const Duration(seconds: 4),
    );
    context.go('/transfers');
    unawaited(
      future.then<void>(
        (_) {},
        onError: (Object error) {
          showRelaySnackBarWithMessenger(
            messenger,
            colors,
            error is TransferRequestException
                ? error.message
                : 'Relay could not start this transfer.',
            isError: true,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final documents = ref.watch(documentsProvider).value ?? const <Document>[];
    Document? selected;
    for (final document in documents) {
      if (document.id == _selectedId) {
        selected = document;
        break;
      }
    }
    final peer = _peer;
    final chosen = selected;
    final connected = peer != null && !_connecting && _error == null;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenTopBar(
              title: 'Send nearby',
              subtitle: 'Scan-to-send',
              leading: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.giant),
                child: RelayContent(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Send one document',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'The receiver is connected with a single-use code. '
                        'Choose a managed PDF or EPUB, then send it. The other '
                        'device still has to approve the transfer.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ConnectionPanel(
                        connecting: _connecting,
                        peer: peer,
                        error: _error,
                        onRetry: _connect,
                        onScanAgain: _scanAnotherCode,
                        onManual: () => Navigator.of(context).maybePop(),
                      ),
                      if (connected) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _DocumentPanel(
                          documents: documents,
                          selected: chosen,
                          onChoose: () => _chooseDocument(documents),
                          onSend: chosen == null ? null : () => _send(chosen),
                          sending: _sending,
                          peerName: peer.deviceName,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.connecting,
    required this.peer,
    required this.error,
    required this.onRetry,
    required this.onScanAgain,
    required this.onManual,
  });

  final bool connecting;
  final ConnectedPeer? peer;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onScanAgain;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    if (connecting) {
      return _StatusShell(
        borderColor: colors.line,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_find_rounded, size: 20, color: colors.accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Connecting to receiver',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Verifying the one-time invitation over the local network. '
              'Nothing is sent until you choose a document and the receiver '
              'approves it.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: colors.accent,
                backgroundColor: colors.surfaceSubtle,
              ),
            ),
          ],
        ),
      );
    }
    if (error != null) {
      return _StatusShell(
        borderColor: colors.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link_off_rounded, size: 20, color: colors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Connection not ready',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            RelayButton(
              label: 'Scan another code',
              icon: Icons.qr_code_scanner_rounded,
              expanded: true,
              onPressed: onScanAgain,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: RelayButton(
                    label: 'Try again',
                    variant: RelayButtonVariant.secondary,
                    onPressed: onRetry,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RelayButton(
                    label: 'Manual',
                    variant: RelayButtonVariant.secondary,
                    onPressed: onManual,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final connectedPeer = peer;
    final deviceName = connectedPeer?.deviceName ?? 'the receiving device';
    return _StatusShell(
      borderColor: colors.accent,
      tint: colors.accentSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 22, color: colors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected to $deviceName',
                  style: theme.textTheme.titleSmall,
                ),
                if (connectedPeer != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Direct address '
                    '${connectedPeer.address}:${connectedPeer.port}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose a document below. The receiver must approve it '
                  'before Relay sends any bytes.',
                  style: theme.textTheme.bodySmall,
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
    required this.child,
    required this.borderColor,
    this.tint,
  });

  final Widget child;
  final Color borderColor;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tint ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _DocumentPanel extends StatelessWidget {
  const _DocumentPanel({
    required this.documents,
    required this.selected,
    required this.onChoose,
    required this.onSend,
    required this.sending,
    required this.peerName,
  });

  final List<Document> documents;
  final Document? selected;
  final VoidCallback onChoose;
  final VoidCallback? onSend;
  final bool sending;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final hasDocuments = documents.any(
      (document) => document.isAvailableOffline,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DOCUMENT', style: AppTypography.eyebrow(colors.muted)),
        const SizedBox(height: AppSpacing.sm),
        if (!hasDocuments)
          const InlineNotice(
            title: 'No managed documents to send',
            message:
                'Import a PDF or EPUB into Relay first. Relay only sends its '
                'own managed copy and never exposes other files.',
            tone: NoticeTone.neutral,
            icon: Icons.menu_book_outlined,
          )
        else if (selected == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: colors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    Icons.upload_file_outlined,
                    size: 20,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Choose one document from your library',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                TextButton(onPressed: onChoose, child: const Text('Choose')),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: colors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  height: 66,
                  child: DocumentCover(
                    document: selected!,
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
                        selected!.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${selected!.format.label} · '
                        '${formatBytes(selected!.sizeBytes)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selected!.displayFileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eyebrow(
                          colors.muted,
                        ).copyWith(fontSize: 9, letterSpacing: 0.55),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onChoose, child: const Text('Change')),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        RelayButton(
          label: selected == null
              ? 'Choose a document to send'
              : 'Send to $peerName',
          icon: Icons.send_rounded,
          expanded: true,
          isLoading: sending,
          onPressed: selected == null || sending ? null : onSend,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Relay verifies the declared size and SHA-256 checksum on the '
          'receiving device before importing the file. The receiver can '
          'decline the document.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}
