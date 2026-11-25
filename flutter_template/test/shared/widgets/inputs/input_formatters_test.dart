// DigitsNormalizerFormatter / DecimalInputFormatter (lib/core/utils/input_formatters.dart).
//
// Source: new (unit tests; the formatters back AppTextField / AppOtpField).
import 'package:app_template/core/utils/input_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _edit(TextInputFormatter f, String oldText, String newText) => f.formatEditUpdate(
  TextEditingValue(
    text: oldText,
    selection: TextSelection.collapsed(offset: oldText.length),
  ),
  TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newText.length),
  ),
);

void main() {
  group('DigitsNormalizerFormatter', () {
    test('normalizeDigits folds Arabic-Indic and Persian digits only', () {
      expect(DigitsNormalizerFormatter.normalizeDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(DigitsNormalizerFormatter.normalizeDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
      expect(DigitsNormalizerFormatter.normalizeDigits('شقة ١٢ - Flat 3'), 'شقة 12 - Flat 3');
      expect(DigitsNormalizerFormatter.normalizeDigits(''), '');
    });

    test('keeps the cursor position', () {
      final value = _edit(const DigitsNormalizerFormatter(), '', 'a١٢');
      expect(value.text, 'a12');
      expect(value.selection.baseOffset, 3);
    });
  });

  group('DecimalInputFormatter', () {
    const f = DecimalInputFormatter(decimalPlaces: 2);

    test('accepts one separator in any script, stored as "."', () {
      expect(_edit(f, '', '12.5').text, '12.5');
      expect(_edit(f, '', '12,5').text, '12.5');
      expect(_edit(f, '', '١٢٫٥').text, '12.5');
    });

    test('rejects a second separator, letters and too many decimals', () {
      expect(_edit(f, '1.2', '1.2.').text, '1.2');
      expect(_edit(f, '12', '12a').text, '12');
      expect(_edit(f, '1.25', '1.253').text, '1.25');
    });

    test('whole numbers and negatives', () {
      expect(_edit(const DecimalInputFormatter(decimalPlaces: 0), '1', '1.').text, '1');
      expect(_edit(f, '', '-3').text, '');
      expect(_edit(const DecimalInputFormatter(allowNegative: true), '', '-3').text, '-3');
    });

    test('tryParse reads any digit script and separator', () {
      expect(DecimalInputFormatter.tryParse(' ١٢٫٥ '), 12.5);
      expect(DecimalInputFormatter.tryParse('7,25'), 7.25);
      expect(DecimalInputFormatter.tryParse('x'), isNull);
    });
  });
}
