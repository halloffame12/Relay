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
import '../../../core/widgets/relay_progress_bar.dart';
import '../../../core/widgets/screen_top_bar.dart';
import '../../../core/widgets/status_label.dart';
import '../../library/domain/document.dart';
import '../application/import_providers.dart';
import '../domain/document_import_service.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

enum _ImportStage { intro, picked, importing, success, failure }

class _ImportScreenState extends ConsumerState<ImportScreen> {
  _ImportStage _stage = _ImportStage.intro;
  PickedImportFile? _file;
  Document? _duplicate;
  Document? _imported;
  String? _error;
  String? _pickerError;
  bool _isPicking = false;
  double _progress = 0;
  int _importRunId = 0;
  ImportCancellationToken? _cancellation;

  bool get _isImporting => _stage == _ImportStage.importing;

  Future<void> _chooseFile() async {
    setState(() {
      _isPicking = true;
      _pickerError = null;
    });
    try {
      final service = ref.read(documentImportServiceProvider);
      final file = await service.pickFile();
      if (!mounted) return;
      if (file == null) {
        setState(() => _isPicking = false);
        return;
      }
      final duplicate = await service.findDuplicate(file);
      if (!mounted) return;
      setState(() {
        _file = file;
        _duplicate = duplicate;
        _stage = _ImportStage.picked;
        _error = null;
        _isPicking = false;
        _progress = 0;
      });
    } on ImportPickerException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPicking = false;
        _pickerError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPicking = false;
        _pickerError = 'The file picker could not be opened.';
      });
    }
  }

  Future<void> _startImport() async {
    final file = _file;
    if (file == null) return;
    final runId = ++_importRunId;
    final cancellation = ImportCancellationToken();
    _cancellation = cancellation;
    setState(() {
      _stage = _ImportStage.importing;
      _progress = 0;
      _error = null;
    });

    try {
      final result = await ref
          .read(documentImportServiceProvider)
          .importFile(
            file,
            onProgress: (progress) {
              if (!mounted || runId != _importRunId) return;
              setState(() => _progress = progress);
            },
            cancellation: cancellation,
          );
      if (!mounted || runId != _importRunId) return;

      switch (result.outcome) {
        case ImportOutcome.success:
          setState(() {
            _imported = result.document;
            _stage = _ImportStage.success;
            _progress = 1;
          });
        case ImportOutcome.duplicate:
          setState(() {
            _duplicate = result.existingDocument;
            _stage = _ImportStage.picked;
            _progress = 0;
          });
        case ImportOutcome.failure:
          setState(() {
            _error = result.message ?? 'The document could not be imported.';
            _stage = _ImportStage.failure;
          });
      }
    } on ImportCancelledException {
      if (!mounted || runId != _importRunId) return;
      setState(() {
        _stage = _ImportStage.picked;
        _progress = 0;
      });
    } catch (_) {
      if (!mounted || runId != _importRunId) return;
      setState(() {
        _error =
            'The import stopped unexpectedly. Your original file was '
            'not changed.';
        _stage = _ImportStage.failure;
      });
    }
  }

  void _cancelImport() {
    _importRunId++;
    _cancellation?.cancel();
    setState(() {
      _stage = _ImportStage.picked;
      _progress = 0;
    });
  }

  Future<void> _handleBack() async {
    if (_isImporting) {
      final shouldCancel = await showRelayConfirmationDialog(
        context,
        title: 'Stop importing?',
        message:
            'The import will stop and the document will not be added to your '
            'library.',
        confirmLabel: 'Stop import',
        cancelLabel: 'Keep importing',
        destructive: true,
      );
      if (shouldCancel && mounted) _cancelImport();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  void _reset() {
    setState(() {
      _stage = _ImportStage.intro;
      _file = null;
      _duplicate = null;
      _imported = null;
      _error = null;
      _pickerError = null;
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;

    return PopScope(
      canPop: !_isImporting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: colors.canvas,
        body: Column(
          children: [
            ScreenTopBar(
              title: 'Import document',
              showDivider: true,
              leading: IconButton(
                tooltip: _isImporting ? 'Cancel import' : 'Close import',
                onPressed: _handleBack,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.giant),
                child: RelayContent(
                  maxWidth: 640,
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppDurations.gentle,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Padding(
                      key: ValueKey(_stage),
                      padding: const EdgeInsets.only(top: AppSpacing.xxl),
                      child: _stage == _ImportStage.success
                          ? _SuccessView(
                              document: _imported!,
                              file: _file!,
                              onOpen: () {
                                context.pushReplacement(
                                  '/document/${_imported!.id}',
                                );
                              },
                              onDone: _handleBack,
                            )
                          : _stage == _ImportStage.failure
                          ? _FailureView(
                              message: _error ?? 'The import did not finish.',
                              onRetry: _file == null
                                  ? _chooseFile
                                  : _startImport,
                              onChooseAnother: _chooseFile,
                              retryLabel: _file == null
                                  ? 'Choose a file'
                                  : 'Try again',
                            )
                          : _stage == _ImportStage.importing
                          ? _ImportingView(
                              file: _file!,
                              progress: _progress,
                              onCancel: _cancelImport,
                            )
                          : _stage == _ImportStage.picked
                          ? _PickedView(
                              file: _file!,
                              duplicate: _duplicate,
                              onImport: _startImport,
                              onChooseAnother: _chooseFile,
                              onOpenExisting: _duplicate == null
                                  ? null
                                  : () {
                                      context.pushReplacement(
                                        '/document/${_duplicate!.id}',
                                      );
                                    },
                              onBackToStart: _reset,
                            )
                          : _IntroView(
                              isPicking: _isPicking,
                              pickerError: _pickerError,
                              onChooseFile: _chooseFile,
                            ),
                    ),
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

class _IntroView extends StatelessWidget {
  const _IntroView({
    required this.isPicking,
    required this.pickerError,
    required this.onChooseFile,
  });

  final bool isPicking;
  final String? pickerError;
  final VoidCallback onChooseFile;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ADD TO LIBRARY', style: AppTypography.eyebrow(colors.muted)),
        const SizedBox(height: AppSpacing.md),
        Text('Import a document', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Choose a PDF or EPUB from this device. Relay copies it into '
          'app-managed storage so it opens offline, while leaving your '
          'original file exactly where it is.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.muted,
            height: 1.55,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const Center(child: _ImportIllustration()),
        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: const [
            StatusLabel(label: 'PDF', tone: StatusTone.outline),
            StatusLabel(label: 'EPUB', tone: StatusTone.outline),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Up to ${formatBytes(AppConstants.maxImportBytes)} per file. '
          'Files are checked before the library copy is kept.',
          style: theme.textTheme.bodySmall,
        ),
        if (pickerError != null) ...[
          const SizedBox(height: AppSpacing.lg),
          InlineNotice(
            title: 'File not selected',
            message: pickerError!,
            icon: Icons.error_outline_rounded,
            tone: NoticeTone.accent,
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        RelayButton(
          label: isPicking ? 'Opening file picker…' : 'Choose a file',
          icon: Icons.folder_open_rounded,
          isLoading: isPicking,
          expanded: true,
          onPressed: isPicking ? null : onChooseFile,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: colors.success),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Nothing is uploaded. Importing and reading are designed to '
                'happen entirely on this device.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickedView extends StatelessWidget {
  const _PickedView({
    required this.file,
    required this.duplicate,
    required this.onImport,
    required this.onChooseAnother,
    required this.onOpenExisting,
    required this.onBackToStart,
  });

  final PickedImportFile file;
  final Document? duplicate;
  final VoidCallback onImport;
  final VoidCallback onChooseAnother;
  final VoidCallback? onOpenExisting;
  final VoidCallback onBackToStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final isDuplicate = duplicate != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDuplicate ? 'ALREADY IN YOUR LIBRARY' : 'READY TO IMPORT',
          style: AppTypography.eyebrow(colors.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          isDuplicate ? 'This file is already here' : 'Add this document?',
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          isDuplicate
              ? 'Relay found a file with identical content in your collection.'
              : 'Review the file before copying it into your library.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.muted,
            height: 1.55,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SelectedFileCard(file: file),
        if (isDuplicate) ...[
          const SizedBox(height: AppSpacing.lg),
          InlineNotice(
            title: 'Duplicate file',
            message:
                '“${duplicate!.title}” is already in your library. Relay '
                'matched the file content, so importing it again is not '
                'necessary.',
            icon: Icons.copy_all_outlined,
            tone: NoticeTone.accent,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (isDuplicate)
          RelayButton(
            label: 'Open existing document',
            icon: Icons.open_in_new_rounded,
            expanded: true,
            onPressed: onOpenExisting,
          )
        else
          RelayButton(
            label: 'Add to library',
            icon: Icons.add_rounded,
            expanded: true,
            onPressed: onImport,
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onChooseAnother,
                child: const Text('Choose another'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextButton(
                onPressed: onBackToStart,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _LocalImportNote(),
      ],
    );
  }
}

class _ImportingView extends StatelessWidget {
  const _ImportingView({
    required this.file,
    required this.progress,
    required this.onCancel,
  });

  final PickedImportFile file;
  final double progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final percent = (progress.clamp(0, 1) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('IMPORTING', style: AppTypography.eyebrow(colors.muted)),
        const SizedBox(height: AppSpacing.md),
        Text('Adding to your library', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Copying the file and preparing the library entry.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.muted,
            height: 1.55,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    file.format == DocumentFormat.pdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.menu_book_outlined,
                    size: 20,
                    color: colors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$percent%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              RelayProgressBar(
                value: progress,
                height: 5,
                semanticLabel: 'Import progress',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                percent < 60
                    ? 'Copying into Relay storage…'
                    : percent < 90
                    ? 'Checking the document…'
                    : 'Finishing…',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Cancel import'),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.document,
    required this.file,
    required this.onOpen,
    required this.onDone,
  });

  final Document document;
  final PickedImportFile file;
  final VoidCallback onOpen;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: colors.sage, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, size: 26, color: colors.success),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('Added to your library', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          '“${document.title}” is now stored in your local library.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.muted,
            height: 1.55,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SelectedFileCard(file: file),
        const SizedBox(height: AppSpacing.lg),
        _LocalImportNote(),
        const SizedBox(height: AppSpacing.xxl),
        RelayButton(
          label: 'Open document',
          icon: Icons.menu_book_rounded,
          expanded: true,
          onPressed: onOpen,
        ),
        const SizedBox(height: AppSpacing.md),
        RelayButton(
          label: 'Back to library',
          variant: RelayButtonVariant.secondary,
          expanded: true,
          onPressed: onDone,
        ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.message,
    required this.onRetry,
    required this.onChooseAnother,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onChooseAnother;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline_rounded,
            size: 25,
            color: colors.danger,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('That didn’t import', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.muted,
            height: 1.55,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        RelayButton(
          label: retryLabel,
          icon: Icons.refresh_rounded,
          expanded: true,
          onPressed: onRetry,
        ),
        const SizedBox(height: AppSpacing.md),
        RelayButton(
          label: 'Choose another file',
          variant: RelayButtonVariant.secondary,
          expanded: true,
          onPressed: onChooseAnother,
        ),
      ],
    );
  }
}

class _SelectedFileCard extends StatelessWidget {
  const _SelectedFileCard({required this.file});

  final PickedImportFile file;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final isPdf = file.format == DocumentFormat.pdf;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 60,
            decoration: BoxDecoration(
              color: isPdf ? colors.accentSoft : colors.sage,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.menu_book_outlined,
                  size: 20,
                  color: isPdf ? colors.accent : colors.success,
                ),
                const SizedBox(height: 4),
                Text(
                  file.format.label,
                  style: AppTypography.eyebrow(
                    isPdf ? colors.accent : colors.success,
                  ).copyWith(fontSize: 8),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${file.format.description} · ${formatBytes(file.sizeBytes)}',
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

class _LocalImportNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const InlineNotice(
      title: 'A private local copy',
      message:
          'Relay copies the file into app-managed storage and checks it '
          'before adding the library record. Your original file is not moved '
          'or changed, and Relay makes no network request.',
      icon: Icons.offline_pin_outlined,
      tone: NoticeTone.sage,
    );
  }
}

class _ImportIllustration extends StatelessWidget {
  const _ImportIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return SizedBox(
      width: 230,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.09,
            child: _PaperSheet(
              width: 122,
              height: 148,
              color: colors.surfaceSubtle,
              lineColor: colors.line,
              label: 'EPUB',
              labelColor: colors.muted,
            ),
          ),
          Transform.rotate(
            angle: 0.035,
            child: _PaperSheet(
              width: 128,
              height: 154,
              color: colors.surface,
              lineColor: colors.line,
              label: 'PDF',
              labelColor: colors.accent,
              showContent: true,
            ),
          ),
          Positioned(
            right: 18,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colors.ink,
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LOCAL FILE',
                    style: AppTypography.eyebrow(
                      colors.canvas,
                    ).copyWith(fontSize: 8, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperSheet extends StatelessWidget {
  const _PaperSheet({
    required this.width,
    required this.height,
    required this.color,
    required this.lineColor,
    required this.label,
    required this.labelColor,
    this.showContent = false,
  });

  final double width;
  final double height;
  final Color color;
  final Color lineColor;
  final String label;
  final Color labelColor;
  final bool showContent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: lineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.eyebrow(labelColor).copyWith(fontSize: 8),
          ),
          const SizedBox(height: 16),
          if (showContent) ...[
            Container(height: 3, width: width * 0.48, color: lineColor),
            const SizedBox(height: 8),
            Container(height: 3, width: width * 0.34, color: lineColor),
            const SizedBox(height: 16),
            Container(height: 2, width: width * 0.56, color: lineColor),
            const SizedBox(height: 6),
            Container(height: 2, width: width * 0.46, color: lineColor),
            const SizedBox(height: 6),
            Container(height: 2, width: width * 0.5, color: lineColor),
          ],
        ],
      ),
    );
  }
}
