// Light + dark ThemeData with every component theme. Text sizes and button
// styles live HERE, never as per-widget overrides (your convention).
//
// Source: markspulse lib/core/theme/app_theme.dart (~25 component themes),
//         baytna lib/app/theme/app_theme.dart (tokens + ThemeExtension + dark).
// Merged: chinaparts-customer light_widget_themes/dialog_theme.dart (dialog
//         width cap through dialogTheme.constraints, not per-widget wrappers);
//         chinaparts-seller app_bottom_sheet.dart (640 sheet cap);
//         lexa-control theme.dart (type scale per breakpoint).
// See docs/CONVENTIONS.md#theming.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../responsive/breakpoints.dart';
import 'app_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Applies the form-factor type scale. Called from `MaterialApp.builder`
  /// so text grows a little on tablets / unfolded foldables.
  static ThemeData adaptTo(ThemeData theme, FormFactor formFactor) {
    final factor = AppTypography.scaleFor(formFactor);
    if (factor == 1.0) return theme;
    return theme.copyWith(textTheme: theme.textTheme.apply(fontSizeFactor: factor));
  }

  static ThemeData _build(Brightness brightness) {
    // Need a fixed secondary/tertiary brand colour? `.copyWith(tertiary: ...)`.
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.brandSeed, brightness: brightness);

    final text = AppTypography.base(scheme.onSurface);
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadii.mdAll);
    const buttonSize = Size(64, AppSizes.buttonHeight);
    const buttonPadding = EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xl);
    final TextStyle? buttonText = text.labelLarge;

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: AppRadii.mdAll,
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [AppPalette.from(scheme)],
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, AppSizes.minTouch),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size.square(AppSizes.minTouch)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        extendedTextStyle: buttonText,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
        disabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.5)),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lgAll,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.lgAll),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        constraints: const BoxConstraints(maxWidth: AppSizes.sheetMaxWidth),
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlTop),
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: null,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
        indicatorColor: scheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scheme.surfaceContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        indicatorColor: scheme.secondaryContainer,
        backgroundColor: scheme.surfaceContainer,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
        minVerticalPadding: AppSpacing.md,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(textStyle: text.labelLarge)),
      tooltipTheme: TooltipThemeData(textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface)),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
