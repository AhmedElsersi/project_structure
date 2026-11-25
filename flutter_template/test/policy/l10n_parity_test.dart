// Policy: en/ar translations stay in sync (same keys, no empty values, same
// placeholders and plural forms) and every Failure has a sentence in both.
//
// Source: markspulse test/core/l10n/translations_test.dart (same keys, no
//         blank value, placeholders match, "every failure code the app can
//         raise has a sentence").
// Merged: chinaparts-seller tool/check_translations.dart (per-locale key
//         diff); new (the comparison is tool/check_translations.dart's, so
//         CI's translation step and this test can never disagree).
// See docs/CONVENTIONS.md#localization.
import 'dart:convert';
import 'dart:io';

import 'package:app_template/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_translations.dart' as checker;

Map<String, checker.TranslationValue> _load(String locale) => checker.flattenTranslations(
  jsonDecode(File('assets/translations/$locale.json').readAsStringSync()) as Map<String, dynamic>,
);

/// One instance of every Failure subclass. The switch below makes this list
/// impossible to forget: a new subclass is a compile error until it is
/// added there (and then here).
const List<Failure> _allFailures = [
  NetworkFailure(),
  TimeoutFailure(),
  CancelledFailure(),
  UnauthorizedFailure(),
  ForbiddenFailure(),
  NotFoundFailure(),
  ConflictFailure(),
  ValidationFailure(),
  RateLimitedFailure(),
  UpgradeRequiredFailure(),
  MaintenanceFailure(),
  ServerFailure(),
  StorageFailure(),
  PermissionFailure(),
  UnknownFailure(),
];

// Exhaustive over the sealed hierarchy: fails to compile when a Failure
// subclass is added without updating this test.
String _name(Failure failure) => switch (failure) {
  NetworkFailure() => 'NetworkFailure',
  TimeoutFailure() => 'TimeoutFailure',
  CancelledFailure() => 'CancelledFailure',
  UnauthorizedFailure() => 'UnauthorizedFailure',
  ForbiddenFailure() => 'ForbiddenFailure',
  NotFoundFailure() => 'NotFoundFailure',
  ConflictFailure() => 'ConflictFailure',
  ValidationFailure() => 'ValidationFailure',
  RateLimitedFailure() => 'RateLimitedFailure',
  UpgradeRequiredFailure() => 'UpgradeRequiredFailure',
  MaintenanceFailure() => 'MaintenanceFailure',
  ServerFailure() => 'ServerFailure',
  StorageFailure() => 'StorageFailure',
  PermissionFailure() => 'PermissionFailure',
  UnknownFailure() => 'UnknownFailure',
};

void main() {
  final en = _load(checker.referenceLocale);

  for (final locale in checker.otherLocales) {
    test('$locale matches ${checker.referenceLocale}: keys, non-empty values, placeholders, plural forms', () {
      final problems = checker.compareLocales(en, _load(locale), otherName: locale);
      expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
    });
  }

  test('every Failure subclass is covered by this test', () {
    final declared = RegExp(
      r'^final class (\w+) extends Failure\b',
      multiLine: true,
    ).allMatches(File('lib/core/errors/failure.dart').readAsStringSync()).map((m) => m[1]!).toSet();
    expect(_allFailures.map(_name).toSet(), declared);
  });

  test('every Failure.messageKey exists in every locale', () {
    final locales = {checker.referenceLocale: en, for (final l in checker.otherLocales) l: _load(l)};
    final missing = <String>[
      for (final failure in _allFailures)
        for (final entry in locales.entries)
          if (entry.value[failure.messageKey] is! checker.TextValue)
            '${entry.key}: ${_name(failure)} → "${failure.messageKey}"',
    ];
    expect(missing, isEmpty, reason: '\n${missing.join('\n')}');
  });

  group('comparison', () {
    Map<String, checker.TranslationValue> flat(Map<String, dynamic> json) => checker.flattenTranslations(json);
    List<String> compare(Map<String, dynamic> a, Map<String, dynamic> b) =>
        checker.compareLocales(flat(a), flat(b), otherName: 'ar');

    test('reports missing / extra keys, empty values and placeholder drift', () {
      expect(compare({'a': 'x', 'b': 'y'}, {'a': 'س'}), ['ar is missing "b"']);
      expect(compare({'a': 'x'}, {'a': 'س', 'c': 'ص'}), ['ar has "c", which en does not']);
      expect(compare({'a': 'x'}, {'a': ' '}), ['ar: "a" is empty']);
      expect(compare({'a': 'Hi {}'}, {'a': 'مرحبا'}), ['"a" has 1 "{}" in en but 0 in ar']);
      expect(compare({'a': 'Hi {name}'}, {'a': 'مرحبا {user}'}), hasLength(1));
    });

    test('compares plural forms; Arabic one/two may omit the number', () {
      const en = {
        'm': {'one': '{} minute', 'other': '{} minutes'},
      };
      expect(
        compare(en, {
          'm': {'one': 'دقيقة', 'other': '{} دقيقة'},
        }),
        isEmpty,
      );
      expect(
        compare(en, {
          'm': {'one': 'دقيقة', 'two': 'دقيقتان', 'other': '{} دقيقة'},
        }),
        [contains('plural forms differ')],
      );
    });
  });
}
