import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    colors: AppColors.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.forestInk,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.sage,
      onPrimaryContainer: AppColors.forestInk,
      secondary: AppColors.terracotta,
      onSecondary: AppColors.white,
      secondaryContainer: Color(0xFFF3DED6),
      onSecondaryContainer: AppColors.forestInk,
      tertiary: AppColors.moss,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.sage,
      onTertiaryContainer: AppColors.forestInk,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: Color(0xFFF5DDDA),
      onErrorContainer: Color(0xFF5D201C),
      surface: AppColors.warmPaper,
      onSurface: AppColors.forestInk,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: Color(0xFFF9F6EE),
      surfaceContainer: Color(0xFFF1ECE0),
      surfaceContainerHigh: Color(0xFFEAE5D8),
      surfaceContainerHighest: Color(0xFFE3DED0),
      onSurfaceVariant: AppColors.oliveGray,
      outline: AppColors.paperLine,
      outlineVariant: Color(0xFFEAE5DA),
      shadow: Color(0x1F242820),
      scrim: Color(0x66242820),
      inverseSurface: AppColors.forestInk,
      onInverseSurface: AppColors.warmPaper,
      inversePrimary: AppColors.sage,
    ),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colors: AppColors.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFECE8DC),
      onPrimary: AppColors.forestInk,
      primaryContainer: Color(0xFF343A2F),
      onPrimaryContainer: Color(0xFFECE8DC),
      secondary: Color(0xFFE58C70),
      onSecondary: Color(0xFF241611),
      secondaryContainer: Color(0xFF3A2721),
      onSecondaryContainer: Color(0xFFF6DFD5),
      tertiary: Color(0xFFB9C7AC),
      onTertiary: Color(0xFF1F291C),
      tertiaryContainer: Color(0xFF2A3428),
      onTertiaryContainer: Color(0xFFDCE6D3),
      error: Color(0xFFE38D84),
      onError: Color(0xFF34100D),
      errorContainer: Color(0xFF48211E),
      onErrorContainer: Color(0xFFF6DAD6),
      surface: Color(0xFF171A15),
      onSurface: Color(0xFFECE8DC),
      surfaceContainerLowest: Color(0xFF131610),
      surfaceContainerLow: Color(0xFF1C201A),
      surfaceContainer: Color(0xFF20241E),
      surfaceContainerHigh: Color(0xFF2A2E26),
      surfaceContainerHighest: Color(0xFF32372E),
      onSurfaceVariant: Color(0xFFA3A599),
      outline: Color(0xFF373C32),
      outlineVariant: Color(0xFF2C3128),
      shadow: Color(0xFF000000),
      scrim: Color(0xB3000000),
      inverseSurface: Color(0xFFECE8DC),
      onInverseSurface: AppColors.forestInk,
      inversePrimary: Color(0xFF586650),
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required RelaySemanticColors colors,
    required ColorScheme scheme,
  }) {
    final textTheme = AppTypography.textTheme(colors.ink, colors.muted);
    final isDark = brightness == Brightness.dark;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );

    return base.copyWith(
      primaryColor: scheme.primary,
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: colors.ink, size: AppSizes.iconLarge),
      ),
      iconTheme: IconThemeData(color: colors.ink, size: AppSizes.iconLarge),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent,
        selectionColor: colors.accent.withValues(alpha: 0.22),
        selectionHandleColor: colors.accent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: colors.ink,
              foregroundColor: colors.canvas,
              disabledBackgroundColor: colors.line,
              disabledForegroundColor: colors.muted,
              minimumSize: const Size(0, AppSizes.controlHeight),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              shape: rounded,
              textStyle: textTheme.labelLarge,
              elevation: 0,
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                colors.canvas.withValues(alpha: 0.09),
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          disabledForegroundColor: colors.muted,
          minimumSize: const Size(0, AppSizes.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: BorderSide(color: colors.line),
          shape: rounded,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.ink,
          disabledForegroundColor: colors.muted,
          minimumSize: const Size(0, AppSizes.compactControlHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.ink,
          disabledForegroundColor: colors.muted,
          minimumSize: const Size(44, 44),
          iconSize: AppSizes.iconLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.muted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.muted),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.danger),
        prefixIconColor: colors.muted,
        suffixIconColor: colors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.ink, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.danger, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.sage,
        disabledColor: colors.surfaceSubtle,
        side: BorderSide(color: colors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelMedium!,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.canvas;
          return colors.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.ink;
          return colors.surfaceSubtle;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.ink;
          return colors.line;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.ink,
        inactiveTrackColor: colors.line,
        thumbColor: colors.ink,
        overlayColor: colors.accent.withValues(alpha: 0.12),
        trackHeight: 3,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceSubtle,
        circularTrackColor: colors.line,
        linearMinHeight: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.canvas),
        actionTextColor: colors.sage,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 640),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxl,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: colors.line),
        ),
        textStyle: textTheme.bodyMedium,
        labelTextStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.ink,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colors.canvas),
        waitDuration: const Duration(milliseconds: 500),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.muted,
        textColor: colors.ink,
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: AppSpacing.md,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }
}
