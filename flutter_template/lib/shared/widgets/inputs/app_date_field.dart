// Read-only form field that opens the Material date picker and shows the
// chosen date in the UI language (Western digits).
//
// Source: lexa-control lib/core/widgets/selection/app_date_picker_field.dart
//         (tappable field + showDatePicker boilerplate in one widget; first/last
//         date, helpText, selectableDayPredicate, custom formatter).
// Merged: locale-aware intl DateFormat with context.locale (new; the source
//         printed `d/m/y` by hand); a real FormField so validators and server
//         errors work like every other input (new).
// See docs/WIDGETS.md#inputs.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';

/// A date input. Tapping it opens [showDatePicker]; the value is displayed
/// with `DateFormat.yMMMd` in the current locale (Western digits).
class AppDateField extends StatefulWidget {
  const AppDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.label,
    this.hint,
    this.helper,
    this.helpText,
    this.validator,
    this.errorText,
    this.enabled = true,
    this.format,
    this.selectableDayPredicate,
  });

  /// The selected date, or null when none was picked yet.
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  /// Defaults to 100 years before / after today.
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Already-translated texts. [hint] defaults to "Choose a date".
  final String? label;
  final String? hint;
  final String? helper;

  /// Title of the picker dialog.
  final String? helpText;

  /// Validates the current [value]; returns a translated message or null.
  final FormFieldValidator<DateTime>? validator;

  /// Server-side error, shown before the validator's result.
  final String? errorText;
  final bool enabled;

  /// Custom display format; receives the date and the current locale tag.
  final String Function(DateTime date, String locale)? format;
  final SelectableDayPredicate? selectableDayPredicate;

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  final TextEditingController _text = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncText(); // locale may have changed
  }

  @override
  void didUpdateWidget(AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.format != widget.format) _syncText();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _syncText() {
    final date = widget.value;
    final text = date == null ? '' : _display(date);
    if (_text.text != text) _text.text = text;
  }

  String _display(DateTime date) {
    final locale = context.locale.toLanguageTag();
    final custom = widget.format;
    if (custom != null) return custom(date, locale);
    // Western digits in every language (digits policy).
    final formatter = DateFormat.yMMMd(locale)..useNativeDigits = false;
    return formatter.format(date);
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final first = widget.firstDate ?? DateTime(now.year - 100);
    final last = widget.lastDate ?? DateTime(now.year + 100);
    var initial = widget.value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: widget.helpText,
      selectableDayPredicate: widget.selectableDayPredicate,
    );
    if (picked != null && mounted) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final validator = widget.validator;
    return TextFormField(
      controller: _text,
      readOnly: true,
      enabled: widget.enabled,
      onTap: widget.enabled ? _pick : null,
      // Validates the DateTime, not the displayed text.
      validator: validator == null ? null : (_) => validator(widget.value),
      forceErrorText: widget.errorText,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? LocaleKeys.widgets_pick_date.tr(),
        helperText: widget.helper,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
    );
  }
}
