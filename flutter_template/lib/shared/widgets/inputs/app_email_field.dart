// Email field: LTR text, email keyboard, autofill, no autocorrect, ASCII digits.
//
// Source: lexa-student lib/core/widgets/inputs/app_text_field.dart (forceLtr for
//         emails/phones: only the typed text is LTR).
// Merged: markspulse lib/core/widgets/input/app_text_field.dart (no autocorrect
//         or suggestions on emails); corsa-customer app_text_form_field.dart
//         (autofillHints).
// See docs/WIDGETS.md#inputs.
import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// An [AppTextField] preset for email addresses (always left-to-right).
class AppEmailField extends StatelessWidget {
  const AppEmailField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.validator,
    this.errorText,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon = Icons.alternate_email,
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
  final bool readOnly;
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
    keyboardType: TextInputType.emailAddress,
    textInputAction: textInputAction,
    prefixIcon: prefixIcon,
    enabled: enabled,
    readOnly: readOnly,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    forceLtr: true,
    normalizeDigits: true,
    autofillHints: const [AutofillHints.email],
  );
}
