import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

class RelayProgressBar extends StatelessWidget {
  const RelayProgressBar({
    super.key,
    required this.value,
    this.height = 4,
    this.color,
    this.trackColor,
    this.semanticLabel = 'Reading progress',
  });

  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final progress = value.clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final bar = LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: trackColor ?? colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: reduceMotion ? Duration.zero : AppDurations.gentle,
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return Container(
                  height: height,
                  width: constraints.maxWidth * animatedValue,
                  decoration: BoxDecoration(
                    color: color ?? colors.accent,
                    borderRadius: BorderRadius.circular(height),
                  ),
                );
              },
            ),
          ],
        );
      },
    );

    return Semantics(
      label: semanticLabel,
      value: '${(progress * 100).round()} percent',
      child: bar,
    );
  }
}
