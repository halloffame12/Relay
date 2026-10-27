import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/relay_buttons.dart';
import '../../transfers/domain/transfer_invitation.dart';

typedef QrScannerViewBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onDetect);

/// Chooses which camera error to keep after the user taps "Try camera again".
///
/// Android can stop reporting a denied permission after the first prompt. If
/// the retry leaves the camera stopped without a new error, the original
/// error is kept so the denial panel and Settings guidance stay visible.
@visibleForTesting
MobileScannerException? resolveCameraRetryError({
  required MobileScannerException previousError,
  required MobileScannerException? startFailure,
  required MobileScannerException? stateError,
  required bool isRunning,
  required bool isStarting,
}) {
  return startFailure ??
      stateError ??
      (!isRunning && !isStarting ? previousError : null);
}

/// Camera view used only for reading a Relay receiver invitation. The parsed
/// value is never opened as a URL, and the raw text is never logged.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.scannerBuilder, this.onInvitation});

  /// Injection seam for widget tests. Production uses [MobileScanner].
  final QrScannerViewBuilder? scannerBuilder;

  /// When set, a valid invitation is delivered here instead of popping.
  final ValueChanged<TransferInvitation>? onInvitation;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _busy = false;
  bool _accepted = false;
  String? _error;

  void _handleDetected(String raw) {
    if (_busy || _accepted || !mounted) return;
    _busy = true;
    final TransferInvitation invitation;
    try {
      invitation = TransferInvitation.parse(raw);
    } on TransferInvitationException catch (error) {
      setState(() => _error = error.message);
      return;
    } catch (_) {
      setState(
        () => _error =
            'This is not a valid Relay QR code. Ask the receiver to show a '
            'new one.',
      );
      return;
    }

    _accepted = true;
    unawaited(HapticFeedback.mediumImpact());
    final onInvitation = widget.onInvitation;
    if (onInvitation != null) {
      onInvitation(invitation);
    } else {
      Navigator.of(context).pop(invitation);
    }
  }

  void _scanAgain() {
    setState(() => _error = null);
    _busy = false;
  }

  void _close() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          widget.scannerBuilder?.call(context, _handleDetected) ??
              _CameraScanner(onDetect: _handleDetected, onManual: _close),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close scanner',
                        onPressed: _close,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Scan receiver code',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: _error == null
                      ? const _ScannerInstructions()
                      : _ScanErrorPanel(
                          message: _error!,
                          onScanAgain: _scanAgain,
                          onManual: _close,
                          colors: colors,
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

class _CameraScanner extends StatefulWidget {
  const _CameraScanner({required this.onDetect, required this.onManual});

  final ValueChanged<String> onDetect;
  final VoidCallback onManual;

  @override
  State<_CameraScanner> createState() => _CameraScannerState();
}

class _CameraScannerState extends State<_CameraScanner> {
  late final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
  );

  MobileScannerException? _retryError;
  bool _retrying = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _retry(MobileScannerException previousError) async {
    if (_retrying) return;
    setState(() {
      _retryError = null;
      _retrying = true;
    });

    MobileScannerException? failure;
    try {
      await _controller.start();
    } on MobileScannerException catch (error) {
      failure = error;
    }

    if (!mounted) return;
    final state = _controller.value;
    // Android does not always surface a second permission denial as an
    // error. Keep the denial panel visible when the retry leaves the camera
    // stopped rather than relying on the platform to report it again.
    final retryError = resolveCameraRetryError(
      previousError: previousError,
      startFailure: failure,
      stateError: state.error,
      isRunning: state.isRunning,
      isStarting: state.isStarting,
    );
    setState(() {
      _retrying = false;
      _retryError = retryError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          fit: BoxFit.cover,
          onDetect: (capture) {
            for (final barcode in capture.barcodes) {
              final raw = barcode.rawValue;
              if (raw != null && raw.isNotEmpty) {
                widget.onDetect(raw);
                return;
              }
            }
          },
          errorBuilder: (context, error) => CameraErrorPanel(
            error: error,
            onRetry: () => unawaited(_retry(error)),
            onManual: widget.onManual,
          ),
          overlayBuilder: (context, constraints) =>
              const _ScannerFrameOverlay(),
        ),
        if (_retryError != null)
          Positioned.fill(
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                // The MobileScanner errorBuilder already owns the panel when
                // the platform reported a new error. This overlay is only for
                // the case where Android stops reporting the denial.
                if (state.error != null) return const SizedBox.shrink();
                return CameraErrorPanel(
                  error: _retryError!,
                  onRetry: () => unawaited(_retry(_retryError!)),
                  onManual: widget.onManual,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ScannerInstructions extends StatelessWidget {
  const _ScannerInstructions();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              'Point the camera at the QR code on the receiving device.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Camera access is requested only while this scanner is open. '
              'The code is single-use and expires quickly.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanErrorPanel extends StatelessWidget {
  const _ScanErrorPanel({
    required this.message,
    required this.onScanAgain,
    required this.onManual,
    required this.colors,
  });

  final String message;
  final VoidCallback onScanAgain;
  final VoidCallback onManual;
  final RelaySemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.warning),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_2_rounded, size: 20, color: colors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Code not accepted',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            RelayButton(
              label: 'Scan again',
              icon: Icons.qr_code_scanner_rounded,
              expanded: true,
              onPressed: onScanAgain,
            ),
            const SizedBox(height: AppSpacing.xs),
            RelayButton(
              label: 'Use manual connection',
              variant: RelayButtonVariant.secondary,
              expanded: true,
              onPressed: onManual,
            ),
          ],
        ),
      ),
    );
  }
}

class CameraErrorPanel extends StatelessWidget {
  const CameraErrorPanel({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onManual,
  });

  final MobileScannerException error;
  final VoidCallback onRetry;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final permission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    final theme = Theme.of(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                permission
                    ? Icons.no_photography_outlined
                    : Icons.camera_alt_outlined,
                size: 40,
                color: Colors.white70,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                permission ? 'Camera access is off' : 'Camera unavailable',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                permission
                    ? 'Relay needs the camera only to scan the receiver’s QR '
                          'code. If Android no longer shows the prompt, open '
                          'Settings > Apps > Relay > Permissions > Camera, '
                          'allow access, then try again.'
                    : 'Relay could not start the camera. Close other camera '
                          'apps and try again, or use manual connection.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              RelayButton(
                label: 'Try camera again',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
              const SizedBox(height: AppSpacing.xs),
              RelayButton(
                label: 'Use manual connection',
                variant: RelayButtonVariant.secondary,
                onPressed: onManual,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerFrameOverlay extends StatelessWidget {
  const _ScannerFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortest = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final side = math.min(shortest * 0.68, 290.0);
          return CustomPaint(
            size: constraints.biggest,
            painter: _ScannerFramePainter(
              frame: Rect.fromCenter(
                center: constraints.biggest.center(Offset.zero),
                width: side,
                height: side,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter({required this.frame});

  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(frame, const Radius.circular(AppRadii.lg)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.78);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(AppRadii.lg)),
      border,
    );

    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    const length = 24.0;
    final corners = <(Offset, Offset, Offset)>[
      (
        frame.topLeft,
        frame.topLeft.translate(length, 0),
        frame.topLeft.translate(0, length),
      ),
      (
        frame.topRight,
        frame.topRight.translate(-length, 0),
        frame.topRight.translate(0, length),
      ),
      (
        frame.bottomLeft,
        frame.bottomLeft.translate(length, 0),
        frame.bottomLeft.translate(0, -length),
      ),
      (
        frame.bottomRight,
        frame.bottomRight.translate(-length, 0),
        frame.bottomRight.translate(0, -length),
      ),
    ];
    for (final (origin, horizontal, vertical) in corners) {
      canvas.drawLine(origin, horizontal, corner);
      canvas.drawLine(origin, vertical, corner);
    }
  }

  @override
  bool shouldRepaint(_ScannerFramePainter oldDelegate) =>
      oldDelegate.frame != frame;
}
