import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/relay_buttons.dart';
import '../../nearby/presentation/qr_scanner_screen.dart'
    show CameraErrorPanel, QrScannerViewBuilder;
import '../domain/share_invitation.dart';

/// Camera view used only to read a sender's Relay share code.
///
/// The scanned text is parsed as a strict Relay envelope and never opened as a
/// URL. The raw payload is never logged and the parsed token is not rendered.
class ShareScannerScreen extends StatefulWidget {
  const ShareScannerScreen({super.key, this.scannerBuilder, this.onInvitation});

  /// Injection seam for widget tests. Production uses [MobileScanner].
  final QrScannerViewBuilder? scannerBuilder;

  /// When set, a valid invitation is delivered here instead of popping.
  final ValueChanged<ShareInvitation>? onInvitation;

  @override
  State<ShareScannerScreen> createState() => _ShareScannerScreenState();
}

class _ShareScannerScreenState extends State<ShareScannerScreen> {
  bool _busy = false;
  bool _accepted = false;
  String? _error;

  void _handleDetected(String raw) {
    if (_busy || _accepted || !mounted) return;
    _busy = true;

    final ShareInvitation invitation;
    try {
      invitation = ShareInvitation.parse(raw);
    } on ShareInvitationException catch (error) {
      setState(() {
        _busy = false;
        _error = error.message;
      });
      return;
    } catch (_) {
      setState(() {
        _busy = false;
        _error =
            'This isn’t a Relay share code. Ask the sender to show a new code.';
      });
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
    setState(() {
      _error = null;
      _busy = false;
    });
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
              _ShareCameraScanner(onDetect: _handleDetected, onClose: _close),
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
                          'Scan sender’s code',
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

class _ShareCameraScanner extends StatefulWidget {
  const _ShareCameraScanner({required this.onDetect, required this.onClose});

  final ValueChanged<String> onDetect;
  final VoidCallback onClose;

  @override
  State<_ShareCameraScanner> createState() => _ShareCameraScannerState();
}

class _ShareCameraScannerState extends State<_ShareCameraScanner> {
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
    // Android does not always surface a second permission denial as an error,
    // so keep the previous denial visible when the retry leaves the camera
    // stopped.
    final retryError =
        failure ??
        state.error ??
        (!state.isRunning && !state.isStarting ? previousError : null);
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
            onManual: widget.onClose,
          ),
          overlayBuilder: (context, constraints) =>
              const _ScannerFrameOverlay(),
        ),
        if (_retryError != null)
          Positioned.fill(
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                if (state.error != null) return const SizedBox.shrink();
                return CameraErrorPanel(
                  error: _retryError!,
                  onRetry: () => unawaited(_retry(_retryError!)),
                  onManual: widget.onClose,
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
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              'Point this camera at the QR code on the sending device.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The code is single-use, expires in minutes, and contains no '
              'account or long-lived secret. Nothing is saved until you '
              'approve the files.',
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
    required this.colors,
  });

  final String message;
  final VoidCallback onScanAgain;
  final RelaySemanticColors colors;

  @override
  Widget build(BuildContext context) {
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
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            RelayButton(
              label: 'Scan again',
              icon: Icons.qr_code_scanner_rounded,
              expanded: true,
              onPressed: onScanAgain,
            ),
          ],
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
