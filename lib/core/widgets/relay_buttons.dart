import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

enum RelayButtonVariant { primary, secondary, tertiary }

class RelayButton extends StatelessWidget {
  const RelayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = RelayButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
    this.compact = false,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final RelayButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final bool compact;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final foreground = switch (variant) {
      RelayButtonVariant.primary => colors.canvas,
      _ => colors.ink,
    };

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(foreground),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: 18, color: foreground),
        ],
      ],
    );

    final style = compact
        ? const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, 40)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
          )
        : null;

    final button = switch (variant) {
      RelayButtonVariant.primary => FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      ),
      RelayButtonVariant.secondary => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      ),
      RelayButtonVariant.tertiary => TextButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    };

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class RelayIconTextButton extends StatelessWidget {
  const RelayIconTextButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: selected ? colors.accent : colors.ink),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: selected ? colors.accent : colors.ink,
        ),
      ),
    );
  }
}
