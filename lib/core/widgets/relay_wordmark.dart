import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';
import 'relay_brand_icon.dart';

class RelayWordmark extends StatelessWidget {
  const RelayWordmark({super.key, this.compact = false, this.onTap});

  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final wordmark = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RelayBrandIcon(size: compact ? 24 : 28, borderRadius: AppRadii.sm),
        if (!compact) ...[
          const SizedBox(width: 9),
          Text(
            'Relay',
            style: AppTypography.serif(
              size: 23,
              weight: FontWeight.w600,
              letterSpacing: 0.1,
              color: colors.ink,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) return Semantics(label: 'Relay', child: wordmark);
    return Semantics(
      button: true,
      label: 'Relay home',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: wordmark,
        ),
      ),
    );
  }
}
