// Tests for lib/core/utils/formatters.dart and digits.dart. Source: new
import 'package:app_template/core/localization/generated/locale_keys.g.dart';
import 'package:app_template/core/utils/digits.dart';
import 'package:app_template/core/utils/formatters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../services/support/l10n_app.dart';

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableBuildModes = [];
    await initializeDateFormatting();
  });

  tearDown(() => AppFormat.digits = DigitsPolicy.western);

  group('Digits', () {
    test('toWestern converts Arabic-Indic, Persian digits and Arabic separators', () {
      expect(Digits.toWestern('١٢٬٣٤٥٫٦٧'), '12,345.67');
      expect(Digits.toWestern('۰۹'), '09');
      expect(Digits.toWestern('abc 12'), 'abc 12');
    });

    test('toArabicIndic maps separators only for numbers', () {
      expect(Digits.toArabicIndic('12,345.67', separators: true), '١٢٬٣٤٥٫٦٧');
      expect(Digits.toArabicIndic('5.11.2026'), '٥.١١.٢٠٢٦');
    });
  });

  group('numbers', () {
    test('number / decimal / compact / percent (en)', () {
      expect(AppFormat.number(12500.5, locale: 'en'), '12,500.5');
      expect(AppFormat.decimal(3, places: 2, locale: 'en'), '3.00');
      expect(AppFormat.compact(1200, locale: 'en'), '1.2K');
      expect(AppFormat.percent(0.256, locale: 'en'), '26%');
      expect(AppFormat.percent(0.256, decimals: 1, locale: 'en'), '25.6%');
    });

    test('currency with a code, a symbol, or neither', () {
      expect(AppFormat.currency(1234.5, code: 'USD', symbol: r'$', locale: 'en'), r'$1,234.50');
      expect(AppFormat.currency(10, code: 'USD', locale: 'en'), r'$10.00');
      expect(AppFormat.currency(10, code: 'EGP', locale: 'en'), contains('10.00'));
      expect(AppFormat.currency(10, locale: 'en'), '10.00');
    });

    test('Arabic output keeps Western digits by default', () {
      expect(AppFormat.number(1234567, locale: 'ar'), '1,234,567');
    });

    test('arabicIndic policy applies to Arabic only, unless passed explicitly', () {
      AppFormat.digits = DigitsPolicy.arabicIndic;
      expect(AppFormat.number(1234.5, locale: 'ar'), '١٬٢٣٤٫٥');
      expect(AppFormat.number(1234.5, locale: 'en'), '1,234.5');
      expect(AppFormat.number(7, locale: 'en', digits: DigitsPolicy.arabicIndic), '٧');
    });

    test('western policy normalizes locales that emit Arabic-Indic digits', () {
      expect(AppFormat.number(12, locale: 'ar_EG'), '12');
    });

    test('parseNumber accepts Arabic digits and grouping', () {
      expect(AppFormat.parseNumber('١٬٢٣٤٫٥'), 1234.5);
      expect(AppFormat.parseNumber(' 1,000 '), 1000);
      expect(AppFormat.parseNumber('abc'), isNull);
      expect(AppFormat.parseNumber(''), isNull);
    });
  });

  group('dates', () {
    final when = DateTime(2026, 11, 5, 15, 7);

    test('date / time / dateTime (en)', () {
      expect(AppFormat.date(when, locale: 'en'), 'Nov 5, 2026');
      expect(AppFormat.date(when, pattern: 'yyyy-MM-dd', locale: 'en'), '2026-11-05');
      expect(AppFormat.time(when, locale: 'en'), matches(RegExp(r'^3:07\sPM$')));
      expect(AppFormat.dateTime(when, locale: 'en'), startsWith('Nov 5, 2026'));
    });

    test('dates get the digits policy without separator mapping', () {
      final western = AppFormat.date(when, pattern: 'd.M.yyyy', locale: 'ar');
      expect(western, '5.11.2026');
      final eastern = AppFormat.date(when, pattern: 'd.M.yyyy', locale: 'ar', digits: DigitsPolicy.arabicIndic);
      expect(eastern, '٥.١١.٢٠٢٦');
    });
  });

  group('relativeOf (pure)', () {
    final now = DateTime(2026, 11, 5, 12);

    RelativeTime at(Duration ago) => AppFormat.relativeOf(now.subtract(ago), now: now);

    test('buckets', () {
      expect(at(const Duration(seconds: 30)), (key: LocaleKeys.format_just_now, count: null));
      expect(at(const Duration(minutes: 5)), (key: LocaleKeys.format_minutes_ago, count: 5));
      expect(at(const Duration(hours: 3)), (key: LocaleKeys.format_hours_ago, count: 3));
      expect(at(const Duration(hours: 30)), (key: LocaleKeys.format_yesterday, count: null));
      expect(at(const Duration(days: 4)), (key: LocaleKeys.format_days_ago, count: 4));
      expect(at(const Duration(days: 9)).key, isEmpty, reason: 'older than a week → show the date');
    });

    test('slight future skew is "just now"; far future shows the date', () {
      expect(at(const Duration(seconds: -20)).key, LocaleKeys.format_just_now);
      expect(at(const Duration(hours: -2)).key, isEmpty);
    });
  });

  group('fileSize', () {
    test('fileSizeParts picks binary units', () {
      expect(AppFormat.fileSizeParts(512), (amount: 512.0, unit: FileSizeUnit.byte));
      expect(AppFormat.fileSizeParts(2048).unit, FileSizeUnit.kb);
      expect(AppFormat.fileSizeParts(5 * 1024 * 1024).unit, FileSizeUnit.mb);
      expect(AppFormat.fileSizeParts(3 * 1024 * 1024 * 1024).unit, FileSizeUnit.gb);
    });

    test('value and unit come back apart (one decimal from MB up)', () {
      final size = AppFormat.fileSize((2.44 * 1024 * 1024).round(), locale: 'en');
      expect(size.value, '2.4');
      expect(size.unit, LocaleKeys.format_unit_mb, reason: 'translations not loaded → key');
      expect(AppFormat.fileSize(1536, locale: 'en').value, '2');
    });

    test('value honours the digits policy', () {
      final size = AppFormat.fileSize(1536 * 1024, locale: 'ar', digits: DigitsPolicy.arabicIndic);
      expect(size.value, '١٫٥');
    });
  });

  group('l10n', () {
    setUpAll(setUpL10n);
    final now = DateTime(2026, 11, 5, 12);

    testWidgets('relative() uses plural keys (en)', (tester) async {
      await pumpL10nApp(tester);
      expect(AppFormat.relative(now.subtract(const Duration(minutes: 1)), now: now, locale: 'en'), '1 minute ago');
      expect(AppFormat.relative(now.subtract(const Duration(minutes: 5)), now: now, locale: 'en'), '5 minutes ago');
      expect(AppFormat.relative(now.subtract(const Duration(hours: 30)), now: now, locale: 'en'), 'Yesterday');
      expect(AppFormat.relative(now.subtract(const Duration(days: 10)), now: now, locale: 'en'), 'Oct 26, 2026');
      expect(AppFormat.fileSize(3 * 1024 * 1024, locale: 'en').unit, 'MB');
    });

    testWidgets('relative() Arabic dual form and Arabic-Indic digits', (tester) async {
      await pumpL10nApp(tester, locale: const Locale('ar'));
      expect(AppFormat.relative(now.subtract(const Duration(hours: 2)), now: now, locale: 'ar'), 'منذ ساعتين');
      expect(
        AppFormat.relative(
          now.subtract(const Duration(minutes: 15)),
          now: now,
          locale: 'ar',
          digits: DigitsPolicy.arabicIndic,
        ),
        'منذ ١٥ دقيقة',
      );
      expect(AppFormat.fileSize(3 * 1024 * 1024, locale: 'ar').unit, 'م.ب');
    });
  });
}
