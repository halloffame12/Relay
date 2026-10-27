import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/relay_buttons.dart';
import '../../../core/widgets/relay_dialogs.dart';
import '../../../core/widgets/relay_loading.dart';
import '../../../core/widgets/relay_wordmark.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_label.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/document.dart';
import '../../library/presentation/widgets/document_cover.dart';
import '../../transfers/application/transfer_providers.dart';
import '../../transfers/domain/transfer_invitation.dart';
import '../../transfers/domain/transfer_service.dart';
import '../application/share_intent_provider.dart';
import 'widgets/nearby_share_sheet.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _startingReceiver = false;
  bool _sending = false;
  bool _openingScanner = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(shareIntentResetProvider, (previous, next) {
      if (previous == null || previous == next) return;
      _hostController.clear();
      _portController.clear();
      _codeController.clear();
    });
    final colors = context.relayColors;
    final useCompactWordmark = MediaQuery.sizeOf(context).width < 380;
    final documents = ref.watch(documentsProvider).value ?? const <Document>[];
    final selectedId = ref.watch(shareIntentProvider);
    Document? selected;
    for (final document in documents) {
      if (document.id == selectedId) {
        selected = document;
        break;
      }
    }
    final receiverAsync = ref.watch(receiverEndpointProvider);
    final receiver = receiverAsync.value ?? const ReceiverEndpoint.idle();
    final pending = ref.watch(pendingIncomingTransferProvider);

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
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
                      label: 'Local network',
                      tone: StatusTone.outline,
                      icon: Icons.lan_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const PageHeading(
                  eyebrow: 'Direct sharing',
                  title: 'Nearby',
                  subtitle:
                      'Send a PDF or EPUB directly to another Relay device on '
                      'the same Wi-Fi network. Scan the receiver’s one-time QR '
                      'code, or use address and code as a manual fallback. No '
                      'internet relay, account or cloud service is used.',
                ),
                const SizedBox(height: AppSpacing.xl),
                const InlineNotice(
                  title: 'Same Wi-Fi required',
                  message:
                      'Relay connects two devices directly. Scan the '
                      'receiver’s single-use QR code, or enter its address, '
                      'port and six-digit code manually if scanning is '
                      'unavailable. Guest networks and access-point isolation '
                      'can block this connection. Both devices must stay open '
                      'until the transfer finishes.',
                  icon: Icons.wifi_rounded,
                  tone: NoticeTone.sage,
                ),
                if (pending != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  InlineNotice(
                    title: 'Incoming document needs approval',
                    message:
                        '“${pending.title}” from ${pending.peerName}. Use the '
                        'approval dialog to receive or reject it.',
                    icon: Icons.download_outlined,
                    tone: NoticeTone.accent,
                  ),
                ],
                const SizedBox(height: AppSpacing.xxxl),
                const SectionHeader(
                  eyebrow: 'Receive',
                  title: 'Offer to receive',
                ),
                const SizedBox(height: AppSpacing.lg),
                if (receiverAsync.isLoading)
                  const RelayLoadingIndicator(label: 'Reading receive mode…')
                else
                  _ReceiveCard(
                    endpoint: receiver,
                    isStarting: _startingReceiver,
                    onStart: _startReceiver,
                    onStop: _stopReceiver,
                    onRefresh: _refreshInvitation,
                  ),
                const SizedBox(height: AppSpacing.xxxl),
                const SectionHeader(eyebrow: 'Send', title: 'Scan and send'),
                const SizedBox(height: AppSpacing.lg),
                _SendCard(
                  selected: selected,
                  sending: _sending,
                  hostController: _hostController,
                  portController: _portController,
                  codeController: _codeController,
                  onChoose: _chooseDocument,
                  onScan: _scanToSend,
                  onSend: _sendDocument,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startReceiver() async {
    if (_startingReceiver) return;
    setState(() => _startingReceiver = true);
    try {
      final endpoint = await ref.read(transferServiceProvider).startReceiving();
      if (!mounted) return;
      if (!endpoint.isListening) {
        showRelaySnackBar(
          context,
          endpoint.message ?? 'Receive mode could not start.',
          isError: true,
        );
      } else if (!endpoint.hasWifiAddress) {
        showRelaySnackBar(
          context,
          'Receive mode is on, but Relay found no Wi-Fi IPv4 address.',
          isError: true,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (_) {
      if (!mounted) return;
      showRelaySnackBar(
        context,
        'Relay could not start receive mode.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _startingReceiver = false);
    }
  }

  Future<void> _stopReceiver() async {
    try {
      await ref.read(transferServiceProvider).stopReceiving();
      if (!mounted) return;
      showRelaySnackBar(context, 'Receive mode stopped.');
    } catch (_) {
      if (!mounted) return;
      showRelaySnackBar(
        context,
        'Receive mode could not be stopped.',
        isError: true,
      );
    }
  }

  Future<void> _refreshInvitation() async {
    try {
      await ref.read(transferServiceProvider).refreshInvitation();
      if (!mounted) return;
      showRelaySnackBar(context, 'A new one-time code is ready.');
    } catch (error) {
      if (!mounted) return;
      showRelaySnackBar(
        context,
        error is TransferRequestException
            ? error.message
            : 'Relay could not create a new code.',
        isError: true,
      );
    }
  }

  Future<void> _scanToSend() async {
    if (_openingScanner) return;
    _openingScanner = true;
    try {
      final invitation = await context.push<TransferInvitation>('/nearby/scan');
      if (!mounted || invitation == null) return;
      await context.push<void>('/nearby/send', extra: invitation);
    } finally {
      _openingScanner = false;
    }
  }

  Future<void> _chooseDocument() async {
    FocusScope.of(context).unfocus();
    final documents = ref.read(documentsProvider).value ?? const <Document>[];
    final selectedId = ref.read(shareIntentProvider);
    final document = await showNearbyDocumentPicker(
      context,
      documents: documents,
      selectedId: selectedId,
    );
    if (document == null) return;
    ref.read(shareIntentProvider.notifier).setDocument(document.id);
  }

  Future<void> _sendDocument() async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    final documents = ref.read(documentsProvider).value ?? const <Document>[];
    final selectedId = ref.read(shareIntentProvider);
    Document? document;
    for (final item in documents) {
      if (item.id == selectedId) {
        document = item;
        break;
      }
    }
    if (document == null) {
      showRelaySnackBar(
        context,
        'Choose a document from your library first.',
        isError: true,
      );
      return;
    }
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

    final host = _hostController.text.trim();
    final address = InternetAddress.tryParse(host);
    if (address == null || address.type != InternetAddressType.IPv4) {
      showRelaySnackBar(
        context,
        'Enter the IPv4 address shown on the receiving device.',
        isError: true,
      );
      return;
    }
    final port = int.tryParse(_portController.text.trim());
    if (port == null || port < 1 || port > 65535) {
      showRelaySnackBar(
        context,
        'Enter the port shown on the receiving device.',
        isError: true,
      );
      return;
    }
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      showRelaySnackBar(
        context,
        'Enter the six-digit pairing code shown on the receiving device.',
        isError: true,
      );
      return;
    }

    final confirmed = await showRelayConfirmationDialog(
      context,
      title: 'Send this document?',
      message:
          '“${document.title}” (${document.format.label}, '
          '${formatBytes(document.sizeBytes)}) will be streamed to '
          '$host:$port. The receiving device must approve before any bytes '
          'are sent. The document stays in your library.',
      confirmLabel: 'Send document',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !mounted) return;

    setState(() => _sending = true);
    final service = ref.read(transferServiceProvider);
    final future = service.sendDocument(
      documentId: document.id,
      host: host,
      port: port,
      pairingCode: code,
    );
    ref.read(shareIntentProvider.notifier).clear();
    showRelaySnackBar(
      context,
      'Connecting to $host. Waiting for the receiver to approve.',
      icon: Icons.wifi_find_rounded,
      duration: const Duration(seconds: 4),
    );
    context.go('/transfers');
    unawaited(
      future.then<void>(
        (_) {},
        onError: (Object error) {
          if (!mounted) return;
          showRelaySnackBar(
            context,
            error is TransferRequestException
                ? error.message
                : 'Relay could not start this transfer.',
            isError: true,
          );
        },
      ),
    );
    if (mounted) setState(() => _sending = false);
  }
}

class _ReceiveCard extends StatefulWidget {
  const _ReceiveCard({
    required this.endpoint,
    required this.isStarting,
    required this.onStart,
    required this.onStop,
    required this.onRefresh,
  });

  final ReceiverEndpoint endpoint;
  final bool isStarting;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRefresh;

  @override
  State<_ReceiveCard> createState() => _ReceiveCardState();
}

class _ReceiveCardState extends State<_ReceiveCard> {
  Timer? _ticker;
  bool _showManualDetails = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          widget.endpoint.isListening &&
          widget.endpoint.invitation != null) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ReceiveCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!oldWidget.endpoint.isListening && widget.endpoint.isListening) ||
        oldWidget.endpoint.phase != widget.endpoint.phase) {
      _showManualDetails = false;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final endpoint = widget.endpoint;
    final listening = endpoint.isListening;
    final phase = endpoint.phase;
    final title = switch (phase) {
      ReceiverPhase.idle => 'Receive a document',
      ReceiverPhase.waiting => 'Ready to receive',
      ReceiverPhase.connected => 'Sender connected',
      ReceiverPhase.awaitingApproval => 'Incoming document',
      ReceiverPhase.transferring => 'Receiving document',
    };
    final status = switch (phase) {
      ReceiverPhase.waiting => const StatusLabel(
        label: 'Live',
        tone: StatusTone.success,
        icon: Icons.circle,
      ),
      ReceiverPhase.connected => const StatusLabel(
        label: 'Connected',
        tone: StatusTone.accent,
        icon: Icons.circle,
      ),
      ReceiverPhase.awaitingApproval => const StatusLabel(
        label: 'Approval',
        tone: StatusTone.warning,
        icon: Icons.circle,
      ),
      ReceiverPhase.transferring => const StatusLabel(
        label: 'Receiving',
        tone: StatusTone.accent,
        icon: Icons.circle,
      ),
      ReceiverPhase.idle => null,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: listening ? colors.accent : colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: listening ? colors.accentSoft : colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  _phaseIcon(phase),
                  size: 19,
                  color: listening ? colors.accent : colors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ?status,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!listening) ...[
            Text(
              'Turn on receive mode to show this device’s QR code and a '
              'one-time pairing code. Relay accepts one sender connection and '
              'one document at a time.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            RelayButton(
              label: 'Offer to receive',
              icon: Icons.wifi_tethering_rounded,
              isLoading: widget.isStarting,
              onPressed: widget.isStarting ? null : widget.onStart,
            ),
          ] else if (phase == ReceiverPhase.waiting)
            _buildWaiting(context, endpoint)
          else if (phase == ReceiverPhase.connected)
            _buildConnected(context, endpoint)
          else if (phase == ReceiverPhase.awaitingApproval)
            _buildAwaitingApproval(context, endpoint)
          else
            _buildTransferring(context, endpoint),
        ],
      ),
    );
  }

  Widget _buildWaiting(BuildContext context, ReceiverEndpoint endpoint) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final invitation = endpoint.invitation;
    final manualOnly = invitation == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invitation != null)
          Text(
            'Scan this code from the sender’s Relay app. It is single-use, '
            'refreshes automatically, and only works while receive mode stays '
            'on.',
            style: theme.textTheme.bodyMedium,
          )
        else
          Text(
            endpoint.hasWifiAddress
                ? 'This receive session is ready. Use the manual connection '
                      'details below to connect.'
                : endpoint.message ??
                      'No Wi-Fi IPv4 address was found. Connect to Wi-Fi and '
                          'try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: endpoint.hasWifiAddress ? null : colors.warning,
            ),
          ),
        if (endpoint.statusMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          _StatusNotice(message: endpoint.statusMessage!),
        ],
        if (invitation != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _InvitationQr(invitation: invitation),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              _refreshLabel(invitation),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () =>
                setState(() => _showManualDetails = !_showManualDetails),
            icon: Icon(
              _showManualDetails
                  ? Icons.expand_less_rounded
                  : Icons.keyboard_alt_outlined,
              size: 18,
            ),
            label: Text(
              _showManualDetails
                  ? 'Hide manual connection details'
                  : 'Manual connection details',
            ),
          ),
          if (_showManualDetails) _buildManualDetails(context, endpoint),
        ] else ...[
          if (endpoint.hasWifiAddress) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildManualDetails(context, endpoint),
          ],
        ],
        if (endpoint.message != null && endpoint.hasWifiAddress) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            endpoint.message!,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.warning),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (!manualOnly)
          RelayButton(
            label: 'New one-time code',
            icon: Icons.refresh_rounded,
            variant: RelayButtonVariant.secondary,
            onPressed: widget.onRefresh,
          ),
        if (!manualOnly) const SizedBox(height: AppSpacing.sm),
        RelayButton(
          label: 'Stop receiving',
          icon: Icons.stop_rounded,
          variant: RelayButtonVariant.secondary,
          onPressed: widget.onStop,
        ),
      ],
    );
  }

  Widget _buildManualDetails(BuildContext context, ReceiverEndpoint endpoint) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAIRING CODE', style: AppTypography.eyebrow(colors.muted)),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            endpoint.pairingCode ?? '------',
            style: theme.textTheme.displaySmall?.copyWith(
              letterSpacing: 6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('ADDRESS AND PORT', style: AppTypography.eyebrow(colors.muted)),
          const SizedBox(height: AppSpacing.xs),
          if (endpoint.addresses.isEmpty)
            Text(
              'No Wi-Fi IPv4 address was found.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.warning),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final address in endpoint.addresses)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: SelectableText(
                      '$address:${endpoint.port}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          if (endpoint.addresses.length > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'If one address does not connect, try another from this list.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
          if (endpoint.invitation != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'These details are only for troubleshooting. The code is '
              'single-use and expires with the QR code.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnected(BuildContext context, ReceiverEndpoint endpoint) {
    final theme = Theme.of(context);
    final colors = context.relayColors;
    final peerName = endpoint.peerName ?? 'the sender';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected to $peerName. Waiting for them to choose a document.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'No bytes have been sent yet. You will get a blocking approval '
          'prompt before Relay receives anything.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: LinearProgressIndicator(
            minHeight: 3,
            color: colors.accent,
            backgroundColor: colors.surfaceSubtle,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        RelayButton(
          label: 'Stop receiving',
          icon: Icons.stop_rounded,
          variant: RelayButtonVariant.secondary,
          onPressed: widget.onStop,
        ),
      ],
    );
  }

  Widget _buildAwaitingApproval(
    BuildContext context,
    ReceiverEndpoint endpoint,
  ) {
    final theme = Theme.of(context);
    final colors = context.relayColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '“${endpoint.documentTitle ?? 'A document'}” from '
          '${endpoint.peerName ?? 'the sender'} is waiting for your approval.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Use the approval dialog to receive or reject it. Nothing is added '
          'to your library unless you approve and the size and SHA-256 '
          'checksum both match.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }

  Widget _buildTransferring(BuildContext context, ReceiverEndpoint endpoint) {
    final theme = Theme.of(context);
    final colors = context.relayColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receiving “${endpoint.documentTitle ?? 'a document'}” from '
          '${endpoint.peerName ?? 'the sender'}.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Keep Relay open. The document is added only after the declared '
          'size and SHA-256 checksum are verified.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
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
        const SizedBox(height: AppSpacing.lg),
        RelayButton(
          label: 'Stop and cancel',
          icon: Icons.stop_rounded,
          variant: RelayButtonVariant.secondary,
          onPressed: widget.onStop,
        ),
      ],
    );
  }

  IconData _phaseIcon(ReceiverPhase phase) => switch (phase) {
    ReceiverPhase.idle => Icons.download_outlined,
    ReceiverPhase.waiting => Icons.wifi_tethering_rounded,
    ReceiverPhase.connected => Icons.devices_rounded,
    ReceiverPhase.awaitingApproval => Icons.download_outlined,
    ReceiverPhase.transferring => Icons.swap_vert_rounded,
  };

  String _refreshLabel(TransferInvitation invitation) {
    final remaining = invitation.remainingAt(DateTime.now());
    if (remaining == Duration.zero) return 'Refreshing code…';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return 'Code refreshes in $minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _InvitationQr extends StatelessWidget {
  const _InvitationQr({required this.invitation});

  final TransferInvitation invitation;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.max(
            120.0,
            math.min(constraints.maxWidth - 20, 240.0),
          );
          return Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: colors.line),
            ),
            child: QrImageView(
              data: invitation.payload,
              size: size,
              padding: const EdgeInsets.all(8),
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              semanticsLabel:
                  'Relay receiver QR code. Scan it from the sending device.',
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _SendCard extends StatefulWidget {
  const _SendCard({
    required this.selected,
    required this.sending,
    required this.hostController,
    required this.portController,
    required this.codeController,
    required this.onChoose,
    required this.onScan,
    required this.onSend,
  });

  final Document? selected;
  final bool sending;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController codeController;
  final VoidCallback onChoose;
  final VoidCallback onScan;
  final VoidCallback onSend;

  @override
  State<_SendCard> createState() => _SendCardState();
}

class _SendCardState extends State<_SendCard> {
  bool _showManual = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 19,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Scan to send', style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Scan the QR code on the receiving device. Relay verifies the '
            'receiver before you choose a managed document. The receiver '
            'still has to approve the transfer.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.selected == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file_outlined, size: 19, color: colors.ink),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'No document selected. You can choose after connecting.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onChoose,
                    child: const Text('Choose'),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  height: 66,
                  child: DocumentCover(
                    document: widget.selected!,
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
                        widget.selected!.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.selected!.format.label} · '
                        '${formatBytes(widget.selected!.sizeBytes)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.selected!.displayFileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eyebrow(
                          colors.muted,
                        ).copyWith(fontSize: 9, letterSpacing: 0.55),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.onChoose,
                  child: const Text('Change'),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          RelayButton(
            label: 'Scan receiver’s QR code',
            icon: Icons.qr_code_scanner_rounded,
            expanded: true,
            onPressed: widget.onScan,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => setState(() => _showManual = !_showManual),
            icon: Icon(
              _showManual
                  ? Icons.expand_less_rounded
                  : Icons.keyboard_alt_outlined,
              size: 18,
            ),
            label: Text(
              _showManual
                  ? 'Hide manual connection'
                  : 'Enter address and code manually',
            ),
          ),
          if (_showManual) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Manual connection',
              style: AppTypography.eyebrow(colors.muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Use the address, port and six-digit code shown on the receiving '
              'device. This is a troubleshooting fallback; the code is '
              'single-use.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            _TransferField(
              controller: widget.hostController,
              label: 'Receiver IPv4 address',
              hint: 'e.g. 192.168.1.42',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            _TransferField(
              controller: widget.portController,
              label: 'Port',
              hint: 'Port shown on the receiver',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            _TransferField(
              controller: widget.codeController,
              label: 'Six-digit pairing code',
              hint: '000000',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => widget.onSend(),
            ),
            const SizedBox(height: AppSpacing.lg),
            RelayButton(
              label: widget.selected == null
                  ? 'Choose a document to send'
                  : 'Send document',
              icon: Icons.send_rounded,
              expanded: true,
              isLoading: widget.sending,
              onPressed: widget.selected == null || widget.sending
                  ? null
                  : widget.onSend,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Relay verifies the declared size and SHA-256 checksum on the '
            'receiving device before importing the file.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _TransferField extends StatelessWidget {
  const _TransferField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
    required this.inputFormatters,
    required this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        constraints: const BoxConstraints(minHeight: AppSizes.controlHeight),
      ),
    );
  }
}
