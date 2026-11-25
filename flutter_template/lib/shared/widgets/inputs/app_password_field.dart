// Password field: obscured with a show/hide button, no autocorrect, autofill.
//
// Source: markspulse lib/core/widgets/input/app_text_field.dart (obscure +
//         reveal toggle, autocorrect/suggestions off).
// Merged: corsa-customer lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart
//         (autofillHints for password managers).
// See docs/WIDGETS.md#inputs.
import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// An [AppTextField] preset for passwords. Set [isNewPassword] on sign-up /
/// change-password screens so password managers offer to generate one.
class AppPasswordField extends StatelessWidget {
  const AppPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.validator,
    this.errorText,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.isNewPassword = false,
    this.prefixIcon = Icons.lock_outline,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Already-translated texts.
  final String? label;
  final String? hint;
  final String? helper;
  final FormFieldValidator<String>? validator;

  /// Server-side error, shown before the validator's result.
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// Uses the `newPassword` autofill hint instead of `password`.
  final bool isNewPassword;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: controller,
    focusNode: focusNode,
    label: label,
    hint: hint,
    helper: helper,
    validator: validator,
    errorText: errorText,
    keyboardType: TextInputType.visiblePassword,
    textInputAction: textInputAction,
    obscureText: true,
    prefixIcon: prefixIcon,
    enabled: enabled,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    autofillHints: [isNewPassword ? AutofillHints.newPassword : AutofillHints.password],
  );
}
