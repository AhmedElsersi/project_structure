// The app's button: a thin wrapper over the themed Material buttons with a
// busy state that keeps the button's size and blocks repeat taps.
//
// Source: markspulse lib/core/widgets/input/busy_button.dart (spinner inside the
//         pressed button; label kept invisible so the width never jumps; taps
//         ignored while busy).
// Merged: lexa-control lib/core/widgets/buttons/app_primary_button.dart (icon,
//         destructive tint, expand to full width, spinner in the "on" colour);
//         corsa-customer lib/core/utilities/widgets/buttons/app_default_button.dart
//         (one widget + variant enum instead of a class per look; 2-line labels).
// See docs/WIDGETS.md#buttons.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_spacing.dart';

/// Visual weight of an [AppButton]. All styles come from the theme
/// (`filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`).
enum AppButtonVariant {
  /// Primary action (`FilledButton`).
  filled,

  /// Secondary emphasis (`FilledButton.tonal`).
  tonal,

  /// Medium emphasis (`OutlinedButton`).
  outlined,

  /// Low emphasis (`TextButton`).
  text,

  /// Destructive primary action (`FilledButton` in the error colours).
  danger,
}

/// A themed button with an optional leading [icon] and a [busy] state.
///
/// While [busy], a spinner replaces the label **inside the same button**, the
/// label keeps its space (no width jump) and taps are ignored, so an action in
/// flight can't be submitted twice. A null [onPressed] disables the button.
///
/// ```dart
/// AppButton(label: LocaleKeys.common_save.tr(), onPressed: _save, busy: state.isSaving, expand: true)
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.busy = false,
    this.expand = false,
  });

  /// Already-translated label.
  final String label;

  /// Null disables the button. Ignored while [busy].
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Shown before the label (mirrors with the text direction).
  final IconData? icon;

  /// Shows a spinner and ignores taps, keeping the button's size.
  final bool busy;

  /// Fills the available width (form submit buttons).
  final bool expand;

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    // While busy the button keeps its ENABLED look (a greyed-out button reads
    // as "can't do this"), but pointer taps are blocked below and keyboard /
    // accessibility activation hits a no-op.
    final VoidCallback? action = onPressed == null ? null : (busy ? _ignore : onPressed);
    final scheme = Theme.of(context).colorScheme;

    final Widget text = Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center);
    final Widget content = icon == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconSm),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: text),
            ],
          );

    // The label stays laid out (invisible) under the spinner so the button
    // keeps its exact size while busy.
    final Widget child = Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Visibility(visible: !busy, maintainSize: true, maintainAnimation: true, maintainState: true, child: content),
        if (busy) const _ButtonSpinner(),
      ],
    );

    final Widget button = switch (variant) {
      AppButtonVariant.filled => FilledButton(onPressed: action, child: child),
      AppButtonVariant.tonal => FilledButton.tonal(onPressed: action, child: child),
      AppButtonVariant.outlined => OutlinedButton(onPressed: action, child: child),
      AppButtonVariant.text => TextButton(onPressed: action, child: child),
      // Documented variant: the only per-widget style override.
      AppButtonVariant.danger => FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
        child: child,
      ),
    };

    final Widget semantic = Semantics(
      // Read "Loading…" while busy instead of a silent no-op button.
      value: busy ? LocaleKeys.common_loading.tr() : null,
      child: IgnorePointer(ignoring: busy, child: button),
    );

    return expand ? SizedBox(width: double.infinity, child: semantic) : semantic;
  }
}

/// Spinner sized for a button label, drawn in the button's foreground colour.
class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    // IconTheme inside a ButtonStyleButton carries the resolved foreground
    // colour, so the spinner is visible on filled and text buttons alike.
    final color = IconTheme.of(context).color;
    return SizedBox.square(
      dimension: AppSizes.iconSm,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
