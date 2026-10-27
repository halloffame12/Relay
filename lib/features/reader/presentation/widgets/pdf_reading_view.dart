import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/pdf_document.dart';
import 'reader_palette.dart';

class PdfReadingView extends StatelessWidget {
  const PdfReadingView({
    super.key,
    required this.document,
    required this.pageController,
    required this.palette,
    required this.zoom,
    required this.onPageChanged,
  });

  final PdfDocumentHandle document;
  final PageController pageController;
  final ReaderPalette palette;
  final double zoom;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.isDark ? const Color(0xFF0E110D) : const Color(0xFFDCD6C8),
      child: PageView.builder(
        controller: pageController,
        itemCount: document.pageCount,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final margin = constraints.maxWidth >= 600 ? 36.0 : 12.0;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: margin, vertical: 10),
                child: Center(
                  child: ClipRect(
                    child: Transform.scale(
                      scale: zoom,
                      child: _PdfPageImage(
                        key: ValueKey('$index-$zoom'),
                        document: document,
                        index: index,
                        palette: palette,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PdfPageImage extends StatefulWidget {
  const _PdfPageImage({
    super.key,
    required this.document,
    required this.index,
    required this.palette,
  });

  final PdfDocumentHandle document;
  final int index;
  final ReaderPalette palette;

  @override
  State<_PdfPageImage> createState() => _PdfPageImageState();
}

class _PdfPageImageState extends State<_PdfPageImage> {
  late Future<PdfPageBitmap> _future;

  @override
  void initState() {
    super.initState();
    _future = _render();
  }

  Future<PdfPageBitmap> _render() {
    return widget.document.renderPage(widget.index, targetWidth: 1500);
  }

  void _retry() {
    setState(() => _future = _render());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PdfPageBitmap>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final page = snapshot.requireData;
          return LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = math.max(120.0, constraints.maxWidth - 4);
              final availableHeight = math.max(
                180.0,
                constraints.maxHeight - 4,
              );
              final ratio = page.width <= 0 || page.height <= 0
                  ? 1 / 1.414
                  : page.width / page.height;
              var width = availableWidth;
              var height = width / ratio;
              if (height > availableHeight) {
                height = availableHeight;
                width = height * ratio;
              }
              return _PageFrame(
                width: width,
                height: height,
                palette: widget.palette,
                semanticsLabel:
                    'PDF page ${widget.index + 1} of ${widget.document.pageCount}',
                child: Image.memory(
                  page.bytes,
                  width: width,
                  height: height,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    return _PageError(palette: widget.palette, onRetry: _retry);
                  },
                ),
              );
            },
          );
        }
        if (snapshot.hasError) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return _PageFrame(
                width: math.min(680, constraints.maxWidth),
                height: math.max(240, constraints.maxHeight - 20),
                palette: widget.palette,
                semanticsLabel: 'PDF page could not be shown',
                child: _PageError(palette: widget.palette, onRetry: _retry),
              );
            },
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            return _PageFrame(
              width: math.min(680, constraints.maxWidth),
              height: math.max(240, constraints.maxHeight - 20),
              palette: widget.palette,
              semanticsLabel: 'Loading PDF page ${widget.index + 1}',
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.palette.muted,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.width,
    required this.height,
    required this.palette,
    required this.child,
    required this.semanticsLabel,
  });

  final double width;
  final double height;
  final ReaderPalette palette;
  final Widget child;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: palette.page,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: palette.isDark ? 0.4 : 0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: palette.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _PageError extends StatelessWidget {
  const _PageError({required this.palette, required this.onRetry});

  final ReaderPalette palette;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 30, color: palette.muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This page could not be rendered.',
              textAlign: TextAlign.center,
              style: AppTypography.serif(
                size: 14,
                color: palette.pageInk,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
