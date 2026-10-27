import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

Future<T?> showRelaySheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: builder(sheetContext),
        ),
      );
    },
  );
}

class RelaySheetScaffold extends StatelessWidget {
  const RelaySheetScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.showHandle = true,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.sm,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                trailing == null ? AppSpacing.xl : AppSpacing.xs,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: theme.textTheme.headlineSmall),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          Flexible(
            child: Padding(
              padding: title == null ? padding : _withoutTopPadding(padding),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

EdgeInsetsGeometry _withoutTopPadding(EdgeInsetsGeometry padding) {
  if (padding is EdgeInsets) return padding.copyWith(top: 0);
  if (padding is EdgeInsetsDirectional) {
    return EdgeInsetsDirectional.fromSTEB(
      padding.start,
      0,
      padding.end,
      padding.bottom,
    );
  }
  return padding;
}

class SheetActionRow extends StatelessWidget {
  const SheetActionRow({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryIcon,
    this.isPrimaryLoading = false,
    this.primaryEnabled = true,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? primaryIcon;
  final bool isPrimaryLoading;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (secondaryLabel != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: primaryEnabled && !isPrimaryLoading ? onPrimary : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPrimaryLoading) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ] else if (primaryIcon != null) ...[
                  Icon(primaryIcon, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    primaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
