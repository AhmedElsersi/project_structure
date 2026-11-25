// Language picker: every supported language named in itself, one tap applies
// and persists it.
//
// Source: chinaparts-seller lib/features/profile/presentation/widgets/app_language_sheet.dart
//         (list of supported locales from ONE table, current one marked,
//         applied with context.setLocale).
// Merged: markspulse lib/core/widgets/settings/language_choice.dart (each
//         language names itself — «العربية» / "English" — so a reader can
//         find their own; no-op when re-selecting the current language);
//         RadioGroup instead of the deprecated RadioListTile.groupValue (new).
// See docs/WIDGETS.md#settings.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_languages.dart';

/// Radio list of [AppLanguages.all] by native name. Selecting one calls
/// `context.setLocale` (persisted by EasyLocalization) and [onChanged].
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.onChanged, this.contentPadding});

  /// Called after the locale changed (e.g. to sync the user's profile).
  final ValueChanged<Locale>? onChanged;
  final EdgeInsetsGeometry? contentPadding;

  Future<void> _select(BuildContext context, String? code) async {
    if (code == null || code == context.locale.languageCode) return;
    final locale = AppLanguages.all.firstWhere((l) => l.code == code).locale;
    await context.setLocale(locale);
    onChanged?.call(locale);
  }

  @override
  Widget build(BuildContext context) => RadioGroup<String>(
    groupValue: context.locale.languageCode,
    onChanged: (code) => unawaited(_select(context, code)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final language in AppLanguages.all)
          RadioListTile<String>(
            value: language.code,
            contentPadding: contentPadding,
            // The name keeps its own direction inside the other language's UI.
            title: Text(language.nativeName, textDirection: language.direction),
          ),
      ],
    ),
  );
}
