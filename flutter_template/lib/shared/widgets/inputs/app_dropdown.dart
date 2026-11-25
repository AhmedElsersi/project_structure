// Generic form dropdown over DropdownButtonFormField (uses `initialValue`,
// never the deprecated `value`).
//
// Source: lexa-control lib/core/widgets/selection/app_dropdown.dart (generic
//         AppDropdown<T>: label, helper, validator, enabled, isExpanded).
// Merged: markspulse lib/core/widgets/input/app_dropdown.dart (errorText shown
//         under the field, null onChanged disables); items from a plain list +
//         label function so every item ellipsizes the same way (new).
// See docs/WIDGETS.md#inputs.
import 'package:flutter/material.dart';

/// A labelled choice from a short, known list.
///
/// [initialValue] is read once (like any `FormField`); to reset the field
/// from outside, give it a new `key`.
///
/// ```dart
/// AppDropdown<Status>(
///   label: LocaleKeys.items_status.tr(),
///   items: Status.values,
///   labelOf: (s) => s.labelKey.tr(),
///   initialValue: state.status,
///   onChanged: cubit.setStatus,
/// )
/// ```
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.initialValue,
    this.label,
    this.hint,
    this.helper,
    this.validator,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.isExpanded = true,
    this.itemBuilder,
  });

  final List<T> items;

  /// Already-translated text for an item.
  final String Function(T item) labelOf;

  /// Null (or [enabled] false) disables the field.
  final ValueChanged<T?>? onChanged;
  final T? initialValue;

  /// Already-translated texts.
  final String? label;
  final String? hint;
  final String? helper;
  final FormFieldValidator<T>? validator;

  /// Server-side error, shown before the validator's result.
  final String? errorText;
  final IconData? prefixIcon;
  final bool enabled;

  /// Fill the width and ellipsize long items (default).
  final bool isExpanded;

  /// Custom menu row; defaults to a one-line [Text] of [labelOf].
  final Widget Function(BuildContext context, T item)? itemBuilder;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: initialValue,
    isExpanded: isExpanded,
    validator: validator,
    forceErrorText: errorText,
    onChanged: enabled ? onChanged : null,
    style: Theme.of(context).textTheme.bodyLarge,
    hint: hint == null ? null : Text(hint!, maxLines: 1, overflow: TextOverflow.ellipsis),
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
    ),
    items: [
      for (final item in items)
        DropdownMenuItem<T>(
          value: item,
          child: itemBuilder?.call(context, item) ?? Text(labelOf(item), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
    ],
  );
}
