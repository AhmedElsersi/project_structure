// Text input formatters: Arabic-Indic / Persian digits → ASCII, decimal numbers.
//
// Source: chinaparts-seller lib/core/utilities/formatters/decimal_input_formatter.dart
//         (digits in any script + one `.`, `,` or `٫` separator; reject the edit
//         otherwise instead of sending 0 later).
// Merged: tebbr lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart
//         (rune-offset digit folding), markspulse WesternDigitsFormatter idea (fold
//         first so later digit filters keep an Arabic digit as the number it is).
// See docs/WIDGETS.md#inputs.
import 'package:flutter/services.dart';

/// Folds Arabic-Indic (`٠-٩`) and Extended Arabic-Indic / Persian (`۰-۹`)
/// digits to ASCII `0-9` as they are typed or pasted. Every other character
/// is kept, so it is safe on any field (names, addresses, emails).
///
/// Put it FIRST in a formatter list so filters such as
/// `FilteringTextInputFormatter.digitsOnly` see ASCII digits.
class DigitsNormalizerFormatter extends TextInputFormatter {
  const DigitsNormalizerFormatter();

  static const int _arabicZero = 0x0660;
  static const int _persianZero = 0x06F0;
  static const int _asciiZero = 0x30;

  /// Returns [input] with every Arabic-Indic / Persian digit replaced by its
  /// ASCII equivalent. Each digit is one UTF-16 unit in both scripts, so
  /// offsets (cursor, selection) stay valid.
  static String normalizeDigits(String input) {
    if (input.isEmpty) return input;
    var changed = false;
    final units = List<int>.of(input.codeUnits);
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      if (unit >= _arabicZero && unit <= _arabicZero + 9) {
        units[i] = unit - _arabicZero + _asciiZero;
        changed = true;
      } else if (unit >= _persianZero && unit <= _persianZero + 9) {
        units[i] = unit - _persianZero + _asciiZero;
        changed = true;
      }
    }
    return changed ? String.fromCharCodes(units) : input;
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final normalized = normalizeDigits(newValue.text);
    if (identical(normalized, newValue.text)) return newValue;
    // 1:1 replacement: selection and composing ranges are still correct.
    return newValue.copyWith(text: normalized);
  }
}

/// Accepts a decimal number: digits in any script (folded to ASCII), at most
/// one separator (`.`, `,` or the Arabic `٫`, stored as `.`) and at most
/// [decimalPlaces] digits after it. Any other edit is rejected (the previous
/// value stays), so the field never holds text that cannot be parsed.
///
/// Read the value with [DecimalInputFormatter.tryParse].
class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({this.decimalPlaces = 2, this.allowNegative = false})
    : assert(decimalPlaces >= 0, 'decimalPlaces must be >= 0');

  /// Digits allowed after the separator; 0 = whole numbers only.
  final int decimalPlaces;

  /// Allows a single leading `-`.
  final bool allowNegative;

  static const String _separators = '.,٫';

  /// Parses user input written with any digit script or separator.
  static double? tryParse(String input) {
    var text = DigitsNormalizerFormatter.normalizeDigits(input.trim());
    for (final separator in _separators.split('')) {
      text = text.replaceAll(separator, '.');
    }
    return double.tryParse(text);
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final source = DigitsNormalizerFormatter.normalizeDigits(newValue.text);
    final buffer = StringBuffer();
    var separators = 0;
    var decimals = 0;
    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      final unit = char.codeUnitAt(0);
      if (unit >= 0x30 && unit <= 0x39) {
        if (separators > 0 && ++decimals > decimalPlaces) return oldValue;
        buffer.write(char);
      } else if (_separators.contains(char)) {
        if (decimalPlaces == 0 || ++separators > 1) return oldValue;
        buffer.write('.');
      } else if (char == '-' && allowNegative && i == 0) {
        buffer.write(char);
      } else {
        return oldValue;
      }
    }
    final text = buffer.toString();
    if (text == newValue.text) return newValue;
    // Same length as the input (1:1 replacements), so the selection holds.
    return newValue.copyWith(text: text);
  }
}
