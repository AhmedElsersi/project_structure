// Locale-aware number, money, date and size formatting with a digits policy.
//
// Source: baytna lib/core/utils/formatters.dart (intl formatters per locale,
//         value and unit returned apart so RTL layouts can place the unit,
//         relative time returned as a translation key, Eastern-digit mapping).
// Merged: markspulse Western-digit formatters (digits policy, Western by
//         default); chinaparts-seller double_parser_service.dart idea (tolerant
//         parsing of user-typed numbers, see [AppFormat.parseNumber]).
// See docs/SERVICES.md#formatters.
import 'package:easy_localization/easy_localization.dart';

import '../localization/app_languages.dart';
import '../localization/generated/locale_keys.g.dart';
import 'digits.dart';

/// Which digits formatted output uses. Applied AFTER intl formatting.
enum DigitsPolicy {
  /// 0-9 everywhere (default; also converts any ٠-٩ intl produced).
  western,

  /// ٠-٩ (with ٫ ٬ separators for numbers) — only applied to Arabic output
  /// unless passed explicitly to a formatter.
  arabicIndic,
}

/// Bucket of a relative timestamp: a translation key and the count to
/// interpolate (null for keys without a number).
typedef RelativeTime = ({String key, int? count});

/// File-size units, smallest first.
enum FileSizeUnit {
  byte(LocaleKeys.format_unit_byte),
  kb(LocaleKeys.format_unit_kb),
  mb(LocaleKeys.format_unit_mb),
  gb(LocaleKeys.format_unit_gb),
  tb(LocaleKeys.format_unit_tb);

  const FileSizeUnit(this.labelKey);

  /// Translation key of the unit label (`KB`, `ك.ب`...).
  final String labelKey;
}

/// All user-visible number/date formatting goes through here.
///
/// Every method takes an optional `locale` (language code like `ar`, `en`);
/// when omitted it uses [CurrentLocale] (kept in sync with the UI by the app
/// root). `digits` overrides [AppFormat.digits] for one call.
abstract final class AppFormat {
  /// App-wide digits policy. Western by default (approved convention); an app
  /// that wants ٠-٩ in Arabic sets this once at startup or from a setting.
  static DigitsPolicy digits = DigitsPolicy.western;

  // ─── numbers ──────────────────────────────────────────────────────────────

  /// Grouped number: `12,500` / `12,500.5`.
  static String number(num value, {String? locale, DigitsPolicy? digits}) =>
      _num(NumberFormat.decimalPattern(_locale(locale)).format(value), locale, digits);

  /// Number with exactly [places] decimals: `12.50`.
  static String decimal(num value, {int places = 2, String? locale, DigitsPolicy? digits}) => _num(
    NumberFormat.decimalPatternDigits(locale: _locale(locale), decimalDigits: places).format(value),
    locale,
    digits,
  );

  /// Money. Pass an ISO [code] (`USD` → its locale symbol, e.g. `$`) and/or
  /// an explicit display [symbol]. With neither, a plain decimal.
  static String currency(
    num amount, {
    String? code,
    String? symbol,
    int decimalDigits = 2,
    String? locale,
    DigitsPolicy? digits,
  }) {
    final loc = _locale(locale);
    final NumberFormat format;
    if (symbol != null) {
      format = NumberFormat.currency(locale: loc, name: code, symbol: symbol, decimalDigits: decimalDigits);
    } else if (code != null) {
      format = NumberFormat.simpleCurrency(locale: loc, name: code, decimalDigits: decimalDigits);
    } else {
      format = NumberFormat.decimalPatternDigits(locale: loc, decimalDigits: decimalDigits);
    }
    return _num(format.format(amount), locale, digits);
  }

  /// [fraction] as a percentage: 0.256 → `26%` (or `25.6%` with decimals: 1).
  static String percent(num fraction, {int decimals = 0, String? locale, DigitsPolicy? digits}) {
    final format = NumberFormat.percentPattern(_locale(locale))
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = decimals;
    return _num(format.format(fraction), locale, digits);
  }

  /// Short form: `1.2K`, `3.4M` (localized suffixes).
  static String compact(num value, {String? locale, DigitsPolicy? digits}) =>
      _num(NumberFormat.compact(locale: _locale(locale)).format(value), locale, digits);

  /// Parses a user-typed number: accepts ٠-٩, `٫`, grouping commas and spaces.
  /// Returns null when it isn't a number.
  static num? parseNumber(String? input) {
    if (input == null) return null;
    final cleaned = Digits.toWestern(input).replaceAll(RegExp(r'[\s,]'), '');
    if (cleaned.isEmpty) return null;
    return num.tryParse(cleaned);
  }

  // ─── dates ────────────────────────────────────────────────────────────────

  /// Date. Default pattern is `yMMMd` (`Nov 5, 2026`); pass any intl
  /// [pattern] (`yyyy-MM-dd`, `EEEE`...) for something else.
  static String date(DateTime value, {String? pattern, String? locale, DigitsPolicy? digits}) {
    final format = _dateFormat(locale, (loc) => pattern == null ? DateFormat.yMMMd(loc) : DateFormat(pattern, loc));
    return _text(format.format(value.toLocal()), locale, digits);
  }

  /// Time of day in the locale's style (`3:05 PM` / `3:05 م`).
  static String time(DateTime value, {String? locale, DigitsPolicy? digits}) {
    return _text(_dateFormat(locale, DateFormat.jm).format(value.toLocal()), locale, digits);
  }

  /// Date and time: `Nov 5, 2026 3:05 PM`.
  static String dateTime(DateTime value, {String? locale, DigitsPolicy? digits}) {
    final format = _dateFormat(locale, (loc) => DateFormat.yMMMd(loc).add_jm());
    return _text(format.format(value.toLocal()), locale, digits);
  }

  /// "Just now", "5 minutes ago", "Yesterday", ... then a plain date after a
  /// week. Uses `format.*` plural keys, so Arabic gets its dual/plural forms.
  static String relative(DateTime value, {DateTime? now, String? locale, DigitsPolicy? digits}) {
    final bucket = relativeOf(value, now: now);
    final count = bucket.count;
    if (bucket.key == _onDate) return date(value, locale: locale, digits: digits);
    if (count == null) return bucket.key.tr();
    return bucket.key.plural(
      count,
      args: [number(count, locale: locale, digits: digits)],
    );
  }

  /// Pure bucketing behind [relative] (no translation; easy to test).
  /// A key of `''` means "older than a week — show the date".
  static RelativeTime relativeOf(DateTime value, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(value);
    // Small clock skew (a server timestamp slightly in the future) is "now".
    if (diff.inSeconds < 60) {
      return diff.inMinutes <= -1 ? (key: _onDate, count: null) : (key: LocaleKeys.format_just_now, count: null);
    }
    if (diff.inMinutes < 60) return (key: LocaleKeys.format_minutes_ago, count: diff.inMinutes);
    if (diff.inHours < 24) return (key: LocaleKeys.format_hours_ago, count: diff.inHours);
    if (diff.inDays == 1) return (key: LocaleKeys.format_yesterday, count: null);
    if (diff.inDays < 7) return (key: LocaleKeys.format_days_ago, count: diff.inDays);
    return (key: _onDate, count: null);
  }

  static const String _onDate = '';

  // ─── sizes ────────────────────────────────────────────────────────────────

  /// Byte count split into a formatted value and a translated unit, so the
  /// caller can lay them out per direction (`2.4` + `MB` / `٢٫٤` + `م.ب`).
  /// Binary units (1024). One decimal from MB up.
  static ({String value, String unit}) fileSize(int bytes, {String? locale, DigitsPolicy? digits}) {
    final parts = fileSizeParts(bytes);
    final format = NumberFormat.decimalPattern(_locale(locale))
      ..maximumFractionDigits = parts.unit.index >= FileSizeUnit.mb.index ? 1 : 0;
    return (value: _num(format.format(parts.amount), locale, digits), unit: parts.unit.labelKey.tr());
  }

  /// Pure unit selection behind [fileSize].
  static ({double amount, FileSizeUnit unit}) fileSizeParts(int bytes) {
    var size = bytes.abs().toDouble();
    var index = 0;
    while (size >= 1024 && index < FileSizeUnit.values.length - 1) {
      size /= 1024;
      index++;
    }
    return (amount: bytes < 0 ? -size : size, unit: FileSizeUnit.values[index]);
  }

  // ─── digits ───────────────────────────────────────────────────────────────

  /// Applies a digits policy to already-formatted text. [numeric] also maps
  /// the decimal / thousands separators (numbers only, never dates).
  static String applyDigits(String text, {DigitsPolicy? digits, String? locale, bool numeric = true}) {
    final policy = digits ?? AppFormat.digits;
    final explicit = digits != null;
    switch (policy) {
      case DigitsPolicy.western:
        return Digits.hasNonWesternDigits(text) ? Digits.toWestern(text) : text;
      case DigitsPolicy.arabicIndic:
        // The app-wide default only affects Arabic; an explicit request always applies.
        if (!explicit && _locale(locale) != 'ar') return text;
        return Digits.toArabicIndic(text, separators: numeric);
    }
  }

  static String _num(String text, String? locale, DigitsPolicy? digits) =>
      applyDigits(text, digits: digits, locale: locale);

  static String _text(String text, String? locale, DigitsPolicy? digits) =>
      applyDigits(text, digits: digits, locale: locale, numeric: false);

  static String _locale(String? locale) => locale ?? CurrentLocale.languageCode;

  /// Date symbols for a locale are loaded by flutter_localizations; if they
  /// aren't (tests, background isolates), fall back to English instead of throwing.
  static DateFormat _dateFormat(String? locale, DateFormat Function(String locale) build) {
    try {
      return build(_locale(locale));
    } on Object {
      return build(AppLanguages.fallbackLocale.languageCode);
    }
  }
}
