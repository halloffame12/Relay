import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/relay_brand_icon.dart';
import '../../../core/widgets/relay_buttons.dart';
import '../../../core/widgets/relay_wordmark.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_label.dart';
import '../application/share_providers.dart';
import '../domain/share_state.dart';

/// Entry point for Relay sharing. The sender starts here, shows a QR code, and
/// the receiver scans it. No address, port, hostname or code is ever typed.
class ShareHomeScreen extends ConsumerWidget {
  const ShareHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.relayColors;
    final crossNetwork = ref.watch(shareCrossNetworkConfiguredProvider);
    final sender = ref.watch(senderShareStateProvider).value;
    final receiver = ref.watch(receiverShareStateProvider).value;
    final activeSender = sender != null && sender.isBusy;
    final activeReceiver = receiver != null && receiver.isBusy;
    final compactWordmark = MediaQuery.sizeOf(context).width < 380;

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
                      compact: compactWordmark,
                      onTap: () => context.go('/library'),
                    ),
                    const Spacer(),
                    StatusLabel(
                      label: crossNetwork ? 'Any network' : 'Nearby networks',
                      tone: StatusTone.outline,
                      icon: crossNetwork
                          ? Icons.public_rounded
                          : Icons.lan_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const PageHeading(
                  eyebrow: 'Direct sharing',
                  title: 'Send & receive',
                  subtitle:
                      'Move your PDFs and EPUBs between Relay devices without '
                      'accounts, cables or cloud storage. The sender shows a '
                      'code, the receiver scans it, and the receiver approves '
                      'every file before it is saved.',
                ),
                const SizedBox(height: AppSpacing.xl),
                if (activeSender) ...[
                  _ActiveSessionCard(
                    title: 'Sending in progress',
                    message: _senderSummary(sender),
                    onOpen: () => context.push('/nearby/send'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (activeReceiver) ...[
                  _ActiveSessionCard(
                    title: 'Receiving in progress',
                    message: receiver.message ?? 'Waiting for the sender.',
                    onOpen: () => context.push('/nearby/receive'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _ActionCard(
                  icon: Icons.upload_file_rounded,
                  title: 'Send documents',
                  description:
                      'Choose files from your library and show a one-time QR '
                      'code. The other device scans it to connect.',
                  primary: true,
                  badge: 'SENDER',
                  onTap: () => context.push('/nearby/send'),
                ),
                const SizedBox(height: AppSpacing.md),
                _ActionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Receive documents',
                  description:
                      'Scan the sender’s QR code, review the file list, then '
                      'approve or decline. Nothing is saved without you.',
                  badge: 'RECEIVER',
                  onTap: () => context.push('/nearby/receive'),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(
                  eyebrow: 'How it works',
                  title: 'A direct handoff',
                ),
                const SizedBox(height: AppSpacing.md),
                _HowItWorksStep(
                  number: '01',
                  title: 'Sender shows a code',
                  body:
                      'Relay opens a short-lived session on this device and '
                      'renders it as a QR code. The code contains no account, '
                      'no long-lived secret and no file contents.',
                ),
                _HowItWorksStep(
                  number: '02',
                  title: 'Receiver scans',
                  body:
                      'Relay validates the code, connects over the fastest '
                      'route it can find, and asks the sender to confirm the '
                      'file list.',
                ),
                _HowItWorksStep(
                  number: '03',
                  title: 'Verify, then save',
                  body:
                      'Files are streamed in chunks, checked against their '
                      'SHA-256 checksum, and only then added to the receiving '
                      'library.',
                  last: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                InlineNotice(
                  title: crossNetwork
                      ? 'Direct, with a relay fallback'
                      : 'Nearby transfers only in this build',
                  message: crossNetwork
                      ? 'Relay prefers a local network route, then a direct '
                            'WebRTC connection. If a restrictive network blocks '
                            'both, the connection can fall back to an encrypted '
                            'WebRTC relay. File bytes never pass through a '
                            'cloud library.'
                      : 'This build was compiled without a signaling endpoint, '
                            'so it can only transfer between devices on the '
                            'same network. The connection still needs no IP '
                            'address, port or code entry.',
                  tone: NoticeTone.neutral,
                  icon: crossNetwork ? Icons.route_rounded : Icons.lan_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _senderSummary(SenderShareState? sender) {
    if (sender == null) return 'Waiting for a receiver.';
    return sender.message ?? 'Waiting for a device to scan the QR code.';
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final foreground = primary ? colors.canvas : colors.ink;
    final body = primary ? colors.canvas.withValues(alpha: 0.82) : colors.muted;

    return Material(
      color: primary ? colors.accent : colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: primary ? null : Border.all(color: colors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary
                      ? colors.canvas.withValues(alpha: 0.16)
                      : colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, size: 24, color: foreground),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge,
                      style: AppTypography.eyebrow(
                        primary
                            ? colors.canvas.withValues(alpha: 0.7)
                            : colors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(color: body),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.arrow_forward_rounded, size: 20, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.title,
    required this.message,
    required this.onOpen,
  });

  final String title;
  final String message;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          RelayBrandIcon(size: 34, borderRadius: AppRadii.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          RelayButton(
            label: 'Open',
            compact: true,
            variant: RelayButtonVariant.secondary,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.body,
    this.last = false,
  });

  final String number;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(number, style: AppTypography.eyebrow(colors.accent)),
          ),
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
