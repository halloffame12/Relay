import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../settings/domain/app_settings.dart';

class LibrarySkeleton extends StatefulWidget {
  const LibrarySkeleton({super.key, this.viewMode = LibraryViewMode.grid});

  final LibraryViewMode viewMode;

  @override
  State<LibrarySkeleton> createState() => _LibrarySkeletonState();
}

class _LibrarySkeletonState extends State<LibrarySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return _buildContent(context, 0.72);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return _buildContent(context, 0.45 + (t * 0.3));
      },
    );
  }

  Widget _buildContent(BuildContext context, double opacity) {
    return Semantics(
      label: 'Loading your library',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: opacity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (widget.viewMode == LibraryViewMode.list) {
                return Column(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      if (i > 0) const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.md,
                        ),
                        child: _SkeletonListRow(),
                      ),
                    ],
                  ],
                );
              }
              final columns = _columnsFor(constraints.maxWidth);
              const gap = AppSpacing.lg;
              final itemWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: AppSpacing.xxl,
                children: [
                  for (var i = 0; i < math.max(columns * 2, 4); i++)
                    SizedBox(
                      width: itemWidth,
                      child: const _SkeletonGridCard(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  int _columnsFor(double width) {
    if (width >= 1040) return 6;
    if (width >= 820) return 5;
    if (width >= 600) return 4;
    if (width >= 380) return 3;
    return 2;
  }
}

class _SkeletonGridCard extends StatelessWidget {
  const _SkeletonGridCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    Widget block({double? width, double height = 10, double radius = 3}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 2 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        block(height: 11, width: double.infinity),
        const SizedBox(height: 6),
        block(height: 11, width: 110),
        const SizedBox(height: 8),
        block(height: 8, width: 70),
      ],
    );
  }
}

class _SkeletonListRow extends StatelessWidget {
  const _SkeletonListRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    Widget block({double? width, double height = 9}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 76,
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              block(height: 11, width: double.infinity),
              const SizedBox(height: 7),
              block(height: 9, width: 130),
              const SizedBox(height: 10),
              block(height: 8, width: 190),
            ],
          ),
        ),
      ],
    );
  }
}
