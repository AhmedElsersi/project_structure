// Converts between Western (0-9) and Arabic-Indic (٠-٩) digits.
//
// Source: baytna lib/core/utils/formatters.dart (toEasternDigits: digit-only
//         mapping that leaves separators and symbols untouched).
// Merged: tebbr Arabic-Indic digit normalizer idea (accept ٠-٩ / ۰-۹ typed on
//         Arabic and Persian keyboards before validating or parsing).
// See docs/SERVICES.md#formatters.

/// Digit helpers shared by validators, formatters and parsers.
abstract final class Digits {
  static const int _zero = 0x30;
  static const int _arabicIndicZero = 0x0660; // ٠
  static const int _persianZero = 0x06F0; // ۰

  /// Arabic decimal separator (٫) and thousands separator (٬).
  static const String arabicDecimalSeparator = '٫';
  static const String arabicGroupSeparator = '٬';

  /// Replaces Arabic-Indic and Persian digits with 0-9, and the Arabic decimal /
  /// thousands separators with `.` / `,`. Everything else is kept.
  static String toWestern(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= _arabicIndicZero && rune <= _arabicIndicZero + 9) {
        buffer.writeCharCode(_zero + rune - _arabicIndicZero);
      } else if (rune >= _persianZero && rune <= _persianZero + 9) {
        buffer.writeCharCode(_zero + rune - _persianZero);
      } else if (rune == 0x066B) {
        buffer.write('.');
      } else if (rune == 0x066C) {
        buffer.write(',');
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Replaces 0-9 with ٠-٩. When [separators] is true (numbers, not dates),
  /// `.` and `,` become the Arabic decimal and thousands separators too.
  static String toArabicIndic(String input, {bool separators = false}) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= _zero && rune <= _zero + 9) {
        buffer.writeCharCode(_arabicIndicZero + rune - _zero);
      } else if (separators && rune == 0x2E) {
        buffer.write(arabicDecimalSeparator);
      } else if (separators && rune == 0x2C) {
        buffer.write(arabicGroupSeparator);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// True when [input] contains any Arabic-Indic or Persian digit.
  static bool hasNonWesternDigits(String input) => input.runes.any(
    (r) => (r >= _arabicIndicZero && r <= _arabicIndicZero + 9) || (r >= _persianZero && r <= _persianZero + 9),
  );
}
