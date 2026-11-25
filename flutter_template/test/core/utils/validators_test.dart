// Tests for lib/core/utils/validators.dart. Source: new
//
// Translations are not loaded here, so `.tr()` returns the key itself: the
// assertions check WHICH sentence each rule picks. The real wording is
// covered by the l10n group at the end.
import 'package:app_template/core/localization/generated/locale_keys.g.dart';
import 'package:app_template/core/utils/validators.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import '../services/support/l10n_app.dart';

void main() {
  setUpAll(() => EasyLocalization.logger.enableBuildModes = []);

  group('required', () {
    final v = Validators.required();
    test('rejects null, empty and whitespace', () {
      expect(v(null), LocaleKeys.validation_required);
      expect(v(''), LocaleKeys.validation_required);
      expect(v('   '), LocaleKeys.validation_required);
    });
    test('accepts text', () => expect(v('a'), isNull));
    test('custom message', () => expect(Validators.required(message: 'Name?')(''), 'Name?'));
  });

  group('email', () {
    final v = Validators.email();
    test('valid', () {
      for (final email in ['a@b.co', 'first.last+tag@sub.example.com', ' user@example.org ']) {
        expect(v(email), isNull, reason: email);
      }
    });
    test('invalid', () {
      for (final email in ['plain', 'a@b', '@b.com', 'a b@c.com', 'a@b..com']) {
        expect(v(email), LocaleKeys.validation_email, reason: email);
      }
    });
    test('empty passes (combine with required)', () => expect(v(''), isNull));
  });

  group('minLength / maxLength', () {
    test('min counts user-perceived characters', () {
      final v = Validators.minLength(3);
      expect(v('ab'), LocaleKeys.validation_min_length);
      expect(v('abc'), isNull);
      expect(v('👍🏽👍🏽'), LocaleKeys.validation_min_length, reason: 'two emoji are two characters');
      expect(v(''), isNull);
    });
    test('max', () {
      final v = Validators.maxLength(3);
      expect(v('abcd'), LocaleKeys.validation_max_length);
      expect(v('abc'), isNull);
      expect(v(null), isNull);
    });
  });

  group('phone (generic E.164-ish)', () {
    final v = Validators.phone();
    test('valid', () {
      for (final phone in [
        '+15555550100',
        '0555550100',
        '+1 (415) 555-2671',
        '1234567',
        '٠٥٥٥٥٥٠١٠٠',
        '+۱۵۵۵۵۵۵۰۱۰۰',
      ]) {
        expect(v(phone), isNull, reason: phone);
      }
    });
    test('invalid', () {
      for (final phone in ['123456', '+1234567890123456', '12ab567', '++123456789', '123+4567']) {
        expect(v(phone), LocaleKeys.validation_phone, reason: phone);
      }
    });
    test('normalizePhone converts Arabic digits and strips separators', () {
      expect(Validators.normalizePhone('+١ (٥٥٥) ٥٥٥-٠١٠٠'), '+15555550100');
    });
  });

  group('numeric (house-style regex bug fixed)', () {
    final v = Validators.numeric();
    test('plain numbers pass — no trailing "\$" needed', () {
      for (final n in ['12', '-3.5', '+7', '0.25', '١٢٫٥']) {
        expect(v(n), isNull, reason: n);
      }
    });
    test('rejects text, a literal dollar and separators', () {
      for (final n in ['12\$', 'abc', '1.2.3', '1,000', '.5', '5.']) {
        expect(v(n), LocaleKeys.validation_numeric, reason: n);
      }
    });
  });

  group('range', () {
    final v = Validators.range(1, 10);
    test('inclusive bounds', () {
      expect(v('1'), isNull);
      expect(v('10'), isNull);
      expect(v('5.5'), isNull);
    });
    test('out of range and not a number', () {
      expect(v('0'), LocaleKeys.validation_range);
      expect(v('10.01'), LocaleKeys.validation_range);
      expect(v('x'), LocaleKeys.validation_numeric);
    });
  });

  test('match compares with the other field at validation time', () {
    var password = 'secret1';
    final v = Validators.match(() => password);
    expect(v('secret1'), isNull);
    password = 'changed';
    expect(v('secret1'), LocaleKeys.validation_mismatch);
  });

  group('password', () {
    final v = Validators.password();
    test('needs 8+ characters with a letter and a digit', () {
      expect(v('abcdefg1'), isNull);
      expect(v('كلمةسر١٢'), isNull, reason: 'Arabic letters and digits count');
      expect(v('abc1'), LocaleKeys.validation_password);
      expect(v('abcdefgh'), LocaleKeys.validation_password);
      expect(v('12345678'), LocaleKeys.validation_password);
    });
    test('custom minimum', () => expect(Validators.password(minLength: 12)('abcdefgh1234'), isNull));
  });

  group('url', () {
    final v = Validators.url();
    test('valid', () {
      expect(v('https://example.com/path?q=1'), isNull);
      expect(v('http://localhost:8080'), isNull);
    });
    test('invalid', () {
      for (final url in ['example.com', 'ftp://example.com', 'https://', 'mailto:a@b.com', 'not a url']) {
        expect(v(url), LocaleKeys.validation_url, reason: url);
      }
    });
    test('httpsOnly', () => expect(Validators.url(httpsOnly: true)('http://example.com'), LocaleKeys.validation_url));
  });

  group('iban (mod-97)', () {
    test('valid IBANs, with or without spaces and in lower case', () {
      for (final iban in [
        'GB82 WEST 1234 5698 7654 32',
        'DE89370400440532013000',
        'SA03 8000 0000 6080 1016 7519',
        'ae070331234567890123456',
        'NO9386011117947',
      ]) {
        expect(Validators.isValidIban(iban), isTrue, reason: iban);
        expect(Validators.iban()(iban), isNull, reason: iban);
      }
    });
    test('bad checksum or shape', () {
      for (final iban in ['GB82 WEST 1234 5698 7654 33', 'DE89370400440532013001', 'XX00', '1234567890123456']) {
        expect(Validators.iban()(iban), LocaleKeys.validation_iban, reason: iban);
      }
    });
  });

  test('compose returns the first error in order', () {
    final v = Validators.compose([Validators.required(), Validators.email(), Validators.maxLength(10)]);
    expect(v(''), LocaleKeys.validation_required);
    expect(v('nope'), LocaleKeys.validation_email);
    expect(v('long.name@example.com'), LocaleKeys.validation_max_length);
    expect(v('a@b.co'), isNull);
  });

  group('l10n', () {
    setUpAll(setUpL10n);

    testWidgets('messages are translated with their arguments (en)', (tester) async {
      await pumpL10nApp(tester);
      expect(Validators.required()(''), 'This field is required.');
      expect(Validators.minLength(3)('a'), 'Enter at least 3 characters.');
      expect(Validators.range(1, 10)('11'), 'Enter a value between 1 and 10.');
    });

    testWidgets('messages are translated with their arguments (ar)', (tester) async {
      await pumpL10nApp(tester, locale: const Locale('ar'));
      expect(Validators.required()(''), 'هذا الحقل مطلوب.');
      expect(Validators.password()('a'), 'استخدم 8 أحرف على الأقل، منها حرف ورقم.');
    });
  });
}
