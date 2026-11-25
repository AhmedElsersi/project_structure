// The one table of supported languages: locales, names, direction, defaults.
//
// Source: chinaparts-customer lib/core/utilities/constants/app_languages.dart and
//         chinaparts-seller lib/core/utilities/constants/app_locales.dart (single
//         source of truth for supportedLocales, autonyms, text direction and the
//         Accept-Language value).
// Approved: start in Arabic; English is always the second language and the
//           fallback for missing keys.
// See docs/CONVENTIONS.md#localization.
import 'package:flutter/widgets.dart';

class AppLanguage {
  const AppLanguage(this.locale, this.nativeName, this.direction);

  final Locale locale;

  /// Name written in the language itself (never translated).
  final String nativeName;
  final TextDirection direction;

  String get code => locale.languageCode;
  bool get isRtl => direction == TextDirection.rtl;
}

abstract final class AppLanguages {
  static const AppLanguage arabic = AppLanguage(Locale('ar'), 'العربية', TextDirection.rtl);
  static const AppLanguage english = AppLanguage(Locale('en'), 'English', TextDirection.ltr);

  /// Order = order shown in the language picker.
  static const List<AppLanguage> all = [arabic, english];

  static const Locale startLocale = Locale('ar');
  static const Locale fallbackLocale = Locale('en');
  static const String translationsPath = 'assets/translations';

  static List<Locale> get supportedLocales => [for (final l in all) l.locale];

  static AppLanguage of(Locale locale) => all.firstWhere((l) => l.code == locale.languageCode, orElse: () => arabic);
}

/// Current UI language for code without a BuildContext (Dio headers,
/// formatters). Set by the app root on every build (cheap, no listeners).
abstract final class CurrentLocale {
  static Locale value = AppLanguages.startLocale;
  static String get languageCode => value.languageCode;
}
