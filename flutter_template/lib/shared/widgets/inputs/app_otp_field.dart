// One-time-code field: N boxes over one invisible native TextField so SMS
// autofill, paste and the keyboard work natively; always left-to-right.
//
// Source: corsa-customer lib/core/utilities/widgets/text_form_fields/otp_form_field.dart
//         (boxes + hidden real field, oneTimeCode autofill, paste, onCompleted,
//         error state, LTR, boxes grow with the text scale).
// Merged: tebbr phone_text_form_field.dart digit folding (via
//         DigitsNormalizerFormatter); boxes shrink to fit narrow widths (new).
// See docs/WIDGETS.md#inputs.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/input_formatters.dart';

/// A verification-code input of [length] digit boxes.
///
/// Digits typed in any script are folded to ASCII; pasting "123-456" keeps
/// the digits. [onCompleted] fires once all boxes are filled.
class AppOtpField extends StatefulWidget {
  const AppOtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
    this.enabled = true,
    this.errorText,
    this.semanticLabel,
  }) : assert(length > 0, 'length must be positive');

  final int length;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;
  final bool enabled;

  /// Already-translated error shown under the boxes (boxes turn red).
  final String? errorText;

  /// Screen-reader label; defaults to "Verification code".
  final String? semanticLabel;

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  TextEditingController? _ownController;
  final FocusNode _focus = FocusNode();
  String _last = '';

  TextEditingController get _controller => widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _last = _controller.text;
    _controller.addListener(_onText);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AppOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onText);
      _controller.addListener(_onText);
      _last = _controller.text;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _ownController?.dispose();
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  void _onText() {
    final value = _controller.text;
    if (value == _last) return;
    _last = value;
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;
    final value = _controller.text;
    // Preferred box grows with the (damped) text scale.
    final preferred = MediaQuery.textScalerOf(context).scale(AppSizes.minTouch + AppSpacing.xs);

    final field = LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final fit = (constraints.maxWidth - gap * (widget.length - 1)) / widget.length;
        final box = fit.isFinite ? fit.clamp(0.0, preferred) : preferred;
        return Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  _OtpBox(
                    size: box,
                    char: i < value.length ? value[i] : '',
                    focused:
                        _focus.hasFocus &&
                        (i == value.length || (i == widget.length - 1 && value.length == widget.length)),
                    hasError: hasError,
                    enabled: widget.enabled,
                  ),
                ],
              ],
            ),
            // The real field, invisible, on top: taps focus it, the keyboard,
            // paste menu and SMS autofill all work natively.
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    const DigitsNormalizerFormatter(),
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  showCursor: false,
                  cursorColor: Colors.transparent,
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.transparent),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return Semantics(
      label: widget.semanticLabel ?? LocaleKeys.widgets_otp_label.tr(),
      textField: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Codes read left-to-right in every language.
          Directionality(textDirection: TextDirection.ltr, child: field),
          if (hasError) ...[
            AppSpacing.gapSm,
            Text(
              widget.errorText!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.size,
    required this.char,
    required this.focused,
    required this.hasError,
    required this.enabled,
  });

  final double size;
  final String char;
  final bool focused;
  final bool hasError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = hasError
        ? scheme.error
        : focused
        ? scheme.primary
        : scheme.outlineVariant;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.fast),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? theme.inputDecorationTheme.fillColor : scheme.surfaceContainerHighest,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: borderColor, width: focused || hasError ? 2 : 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(char, style: theme.textTheme.headlineSmall),
      ),
    );
  }
}
