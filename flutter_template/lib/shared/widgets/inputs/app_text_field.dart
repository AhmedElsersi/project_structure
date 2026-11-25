// The app's text field: themed TextFormField with validate-on-blur, server
// errors, show/hide for passwords, LTR for codes and digit folding.
//
// Source: corsa-customer lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart
//         (one field for every form: helper/error wrap, autofillHints,
//         textInputAction, maxLength without counter).
// Merged: markspulse lib/core/widgets/input/app_text_field.dart (validate when
//         the user leaves the field after typing; reveal toggle on the END side
//         with a tooltip; no autocorrect on passwords/emails; digits folded);
//         petrobe lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart
//         (externalError shown before the local validator → here `errorText`);
//         lexa-student lib/core/widgets/inputs/app_text_field.dart (forceLtr: only
//         the typed text is LTR, the label follows the UI direction).
// See docs/WIDGETS.md#inputs.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/utils/input_formatters.dart';

/// A themed text field (decoration comes from `inputDecorationTheme`).
///
/// * **Validated on blur**: once the user has typed, leaving the field runs
///   [validator]; after an error is shown, every edit re-validates so the
///   message disappears as soon as the value is fixed. Inside a `Form`,
///   `formKey.currentState!.validate()` still validates it on submit.
/// * **Server errors first**: [errorText] (e.g. `failure.fieldError('email')`)
///   is shown instead of the validator's result until the user edits the
///   field or the parent passes a different value.
/// * **[obscureText]** adds a show/hide button on the end side.
/// * **[forceLtr]** keeps the typed text left-to-right (emails, phones,
///   numbers, codes) while the label follows the UI direction.
/// * **[normalizeDigits]** folds Arabic-Indic / Persian digits to ASCII.
///   Defaults to on for number / phone keyboards and [forceLtr] fields.
/// * Tapping outside the field closes the keyboard.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.validator,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.forceLtr = false,
    this.normalizeDigits,
    this.textAlign = TextAlign.start,
  });

  /// Optional; when null the field keeps its own text ([initialValue]).
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;

  /// Already-translated label / hint / helper texts.
  final String? label;
  final String? hint;
  final String? helper;

  /// Returns an already-translated message, or null when the value is valid.
  final FormFieldValidator<String>? validator;

  /// Server-side error for this field, shown before the validator's result.
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final IconData? prefixIcon;

  /// Widget at the end of the field (ignored when [obscureText] is true; the
  /// show/hide button takes that slot).
  final Widget? suffix;
  final int? maxLines;
  final int? minLines;

  /// Hard limit; no counter is shown.
  final int? maxLength;

  /// Extra formatters, applied after digit folding.
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  /// Lays the typed text out left-to-right regardless of the UI language.
  final bool forceLtr;

  /// Folds Arabic-Indic / Persian digits to ASCII. Null = automatic (number or
  /// phone keyboard, or [forceLtr]).
  final bool? normalizeDigits;
  final TextAlign textAlign;

  @override
  State<AppTextField> createState() => AppTextFieldState();
}

/// State of [AppTextField]; reach it with a `GlobalKey<AppTextFieldState>` to
/// [validate] a single field.
class AppTextFieldState extends State<AppTextField> {
  final GlobalKey<FormFieldState<String>> _fieldKey = GlobalKey<FormFieldState<String>>();
  FocusNode? _ownFocus;
  bool _edited = false;

  /// Never remembered: a revealed password must not stay revealed.
  bool _revealed = false;

  /// True once the user edited the field after [AppTextField.errorText] arrived.
  bool _serverErrorDismissed = false;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocusChange);
      _focus.addListener(_onFocusChange);
    }
    if (oldWidget.errorText != widget.errorText) _serverErrorDismissed = false;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ownFocus?.dispose();
    super.dispose();
  }

  /// Runs the validator now; true when the value is valid.
  bool validate() => _fieldKey.currentState?.validate() ?? true;

  void _onFocusChange() {
    if (!_focus.hasFocus && _edited) _fieldKey.currentState?.validate();
  }

  void _onChanged(String value) {
    _edited = true;
    if (widget.errorText != null && !_serverErrorDismissed) {
      setState(() => _serverErrorDismissed = true);
    } else if (_fieldKey.currentState?.hasError ?? false) {
      // An error is on screen: clear it as soon as the value is fixed.
      _fieldKey.currentState?.validate();
    }
    widget.onChanged?.call(value);
  }

  bool get _isNumeric {
    final index = widget.keyboardType?.index;
    return index == TextInputType.number.index || index == TextInputType.phone.index;
  }

  bool get _isEmail => widget.keyboardType?.index == TextInputType.emailAddress.index;

  List<TextInputFormatter> get _formatters => [
    if (widget.normalizeDigits ?? (_isNumeric || widget.forceLtr)) const DigitsNormalizerFormatter(),
    if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength),
    ...?widget.inputFormatters,
  ];

  @override
  Widget build(BuildContext context) {
    final serverError = _serverErrorDismissed ? null : widget.errorText;
    final multiline = !widget.obscureText && (widget.maxLines == null || widget.maxLines! > 1);

    return TextFormField(
      key: _fieldKey,
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      focusNode: _focus,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText && !_revealed,
      // Neither a password nor an email is prose to be corrected.
      autocorrect: !widget.obscureText && !_isEmail,
      enableSuggestions: !widget.obscureText && !_isEmail,
      keyboardType: widget.keyboardType ?? (multiline ? TextInputType.multiline : null),
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      textAlign: widget.textAlign,
      textDirection: widget.forceLtr ? TextDirection.ltr : null,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.obscureText ? null : widget.minLines,
      inputFormatters: _formatters,
      autofillHints: widget.enabled ? widget.autofillHints : null,
      validator: widget.validator,
      forceErrorText: serverError,
      onTap: widget.onTap,
      onChanged: _onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTapOutside: (_) => _focus.unfocus(),
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: widget.obscureText ? _revealToggle() : widget.suffix,
      ),
    );
  }

  /// Show/hide control on the END side (left in Arabic: `suffixIcon` is
  /// direction-aware). An IconButton so it is a real target with a tooltip.
  Widget _revealToggle() {
    final tooltip = _revealed ? LocaleKeys.widgets_hide_password.tr() : LocaleKeys.widgets_show_password.tr();
    return IconButton(
      tooltip: tooltip,
      icon: Icon(_revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      onPressed: widget.enabled ? () => setState(() => _revealed = !_revealed) : null,
    );
  }
}
