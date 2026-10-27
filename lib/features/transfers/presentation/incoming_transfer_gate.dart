import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../library/domain/document.dart';
import '../../transfers/application/transfer_providers.dart';
import '../../transfers/domain/transfer_service.dart';

/// Shows a blocking approval dialog wherever the user is in Relay. Receiving
/// bytes is never automatic; the sender waits until this decision is made or
/// the configurable approval timeout expires.
class IncomingTransferApprovalGate extends ConsumerStatefulWidget {
  const IncomingTransferApprovalGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingTransferApprovalGate> createState() =>
      _IncomingTransferApprovalGateState();
}

class _IncomingTransferApprovalGateState
    extends ConsumerState<IncomingTransferApprovalGate> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<IncomingTransferRequest?>(pendingIncomingTransferProvider, (
      previous,
      next,
    ) {
      if (next != null && !_showing) _schedule(next);
    });
    return widget.child;
  }

  void _schedule(IncomingTransferRequest request) {
    _showing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final accepted = await _ask(request);
      if (!mounted) return;
      try {
        final service = ref.read(transferServiceProvider);
        if (accepted) {
          await service.approveIncoming(request.transferId);
          if (!mounted) return;
          showRelaySnackBar(
            context,
            'Receiving “${request.title}”. Keep Relay open.',
            icon: Icons.download_rounded,
            duration: const Duration(seconds: 4),
          );
        } else {
          await service.rejectIncoming(request.transferId);
          if (!mounted) return;
          showRelaySnackBar(context, 'Incoming transfer rejected.');
        }
      } catch (_) {
        if (!mounted) return;
        showRelaySnackBar(
          context,
          'This incoming transfer is no longer waiting for approval.',
          isError: true,
        );
      } finally {
        _showing = false;
      }
    });
  }

  Future<bool> _ask(IncomingTransferRequest request) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Receive this document?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${request.format.label} · '
                  '${formatBytes(request.sizeBytes)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'From ${request.peerName}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Relay will write the file to temporary app storage, verify '
                  'every byte and its SHA-256 checksum, then add it to your '
                  'library. Nothing is imported if the transfer fails, and a '
                  'duplicate will not overwrite an existing document.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Reject'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Receive document'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
