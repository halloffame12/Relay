import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

class RelaySegmentedOption<T> {
  const RelaySegmentedOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class RelaySegmentedControl<T> extends StatelessWidget {
  const RelaySegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.fullWidth = true,
  });

  final List<RelaySegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final theme = Theme.of(context);

    final row = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            flex: fullWidth ? 1 : 0,
            child: Semantics(
              button: true,
              selected: options[i].value == value,
              label: options[i].label,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  onTap: () => onChanged(options[i].value),
                  child: AnimatedContainer(
                    duration: reduceMotion ? Duration.zero : AppDurations.quick,
                    curve: Curves.easeOut,
                    height: 38,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: options[i].value == value
                          ? colors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      boxShadow: options[i].value == value
                          ? [
                              BoxShadow(
                                color: colors.shadow,
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (options[i].icon != null) ...[
                          Icon(
                            options[i].icon,
                            size: 16,
                            color: options[i].value == value
                                ? colors.ink
                                : colors.muted,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            options[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: options[i].value == value
                                  ? colors.ink
                                  : colors.muted,
                              fontWeight: options[i].value == value
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line),
      ),
      child: row,
    );
  }
}

class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.gridSelected,
    required this.onChanged,
  });

  final bool gridSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    Widget option(IconData icon, bool grid, String label) {
      final selected = gridSelected == grid;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(grid),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppDurations.quick,
              width: 38,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? colors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? colors.ink : colors.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadii.sm + 2),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(Icons.grid_view_rounded, true, 'Grid view'),
          option(Icons.view_agenda_outlined, false, 'List view'),
        ],
      ),
    );
  }
}
