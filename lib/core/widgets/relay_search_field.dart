import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

class RelaySearchField extends StatelessWidget {
  const RelaySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search titles, authors or sources',
    this.autofocus = false,
    this.onSubmitted,
    this.semanticLabel = 'Search library',
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final String semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);

    return Semantics(
      label: semanticLabel,
      textField: true,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            enabled: enabled,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            autofocus: autofocus,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hintText,
              isDense: true,
              constraints: const BoxConstraints(
                minHeight: AppSizes.controlHeight,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: AppSizes.icon,
                color: colors.muted,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: AppSizes.controlHeight,
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: colors.muted,
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              fillColor: colors.surface,
            ),
          );
        },
      ),
    );
  }
}
