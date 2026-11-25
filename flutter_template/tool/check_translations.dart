// Translation gate for CI: en/ar parity, empty values, placeholders, plural
// forms, untranslated Text literals and `.tr()` on unknown keys.
//
// Source: chinaparts-seller tool/check_translations.dart (missing keys per
//         locale, `'a.b'.tr()` / `tr('a.b')` keys that no locale defines,
//         `Text('literal')` without `.tr()`; exit 1 for CI).
// Merged: markspulse test/core/l10n/translations_test.dart (same keys, no
//         blank value, placeholders match, plural forms); new (one checker
//         shared by CI and test/policy/l10n_parity_test.dart).
// See docs/CONVENTIONS.md#localization.
//
// Usage (from the project root):
//   dart run tool/check_translations.dart
//   dart run tool/check_translations.dart --help
//
// Pure Dart (no Flutter imports) so it runs with `dart run`. The functions
// below are also used by test/policy/l10n_parity_test.dart.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// The reference locale and the locales that must match it.
const String referenceLocale = 'en';
const List<String> otherLocales = ['ar'];
const String translationsDir = 'assets/translations';

/// Files allowed to show hardcoded text (they run before translations load).
const Set<String> hardcodedTextAllowlist = {'lib/shared/screens/config_error_app.dart'};

/// easy_localization plural form names.
const Set<String> pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};

/// A translation value: a string, or a plural map (form → string).
sealed class TranslationValue {
  const TranslationValue();
}

final class TextValue extends TranslationValue {
  const TextValue(this.text);
  final String text;
}

final class PluralValue extends TranslationValue {
  const PluralValue(this.forms);
  final Map<String, String> forms;
}

/// True for `{"one": "...", "other": "..."}`-style maps.
bool isPluralMap(Map<String, dynamic> map) =>
    map.isNotEmpty &&
    map.containsKey('other') &&
    map.keys.every(pluralForms.contains) &&
    map.values.every((v) => v is String);

/// Flattens nested translations into `a.b.c` keys. Plural maps stay one key.
/// Non-string leaves (numbers, lists) are reported through [problems].
Map<String, TranslationValue> flattenTranslations(
  Map<String, dynamic> json, {
  List<String>? problems,
  String prefix = '',
}) {
  final result = <String, TranslationValue>{};
  json.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is String) {
      result[path] = TextValue(value);
    } else if (value is Map<String, dynamic>) {
      if (isPluralMap(value)) {
        result[path] = PluralValue(value.map((form, text) => MapEntry(form, text as String)));
      } else {
        result.addAll(flattenTranslations(value, problems: problems, prefix: path));
      }
    } else {
      problems?.add('"$path" must be a string or an object (found ${value.runtimeType}).');
    }
  });
  return result;
}

/// Placeholders of [text]: the number of `{}` and the set of `{name}`s.
({int positional, Set<String> named}) placeholdersOf(String text) {
  final positional = RegExp(r'\{\}').allMatches(text).length;
  final named = {for (final m in RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}').allMatches(text)) m.group(1)!};
  return (positional: positional, named: named);
}

/// Placeholders of a value; for plurals, the union over all forms (Arabic
/// "one" / "two" forms often drop the number, so forms aren't compared 1:1).
({int positional, Set<String> named}) _placeholders(TranslationValue value) => switch (value) {
  TextValue(:final text) => placeholdersOf(text),
  PluralValue(:final forms) => forms.values.map(placeholdersOf).fold(
    (positional: 0, named: <String>{}),
    (a, b) => (positional: a.positional > b.positional ? a.positional : b.positional, named: {...a.named, ...b.named}),
  ),
};

/// Compares [other] ([otherName]) against the [reference] locale. Returns
/// human-readable problems (empty = in sync).
List<String> compareLocales(
  Map<String, TranslationValue> reference,
  Map<String, TranslationValue> other, {
  String referenceName = referenceLocale,
  required String otherName,
}) {
  final problems = <String>[];
  for (final key in reference.keys.toSet().difference(other.keys.toSet())) {
    problems.add('$otherName is missing "$key"');
  }
  for (final key in other.keys.toSet().difference(reference.keys.toSet())) {
    problems.add('$otherName has "$key", which $referenceName does not');
  }
  for (final entry in {referenceName: reference, otherName: other}.entries) {
    entry.value.forEach((key, value) {
      final empty = switch (value) {
        TextValue(:final text) => text.trim().isEmpty,
        PluralValue(:final forms) => forms.values.any((t) => t.trim().isEmpty),
      };
      if (empty) problems.add('${entry.key}: "$key" is empty');
    });
  }
  for (final key in reference.keys.where(other.containsKey)) {
    final a = reference[key]!;
    final b = other[key]!;
    if (a is PluralValue != b is PluralValue) {
      problems.add('"$key" is a plural in one locale only');
      continue;
    }
    if (a is PluralValue && b is PluralValue) {
      final formsA = a.forms.keys.toSet();
      final formsB = b.forms.keys.toSet();
      if (formsA.length != formsB.length || !formsA.containsAll(formsB)) {
        problems.add(
          '"$key" plural forms differ: $referenceName ${formsA.toList()..sort()} vs $otherName ${formsB.toList()..sort()}',
        );
      }
    }
    final pa = _placeholders(a);
    final pb = _placeholders(b);
    if (pa.positional != pb.positional) {
      problems.add('"$key" has ${pa.positional} "{}" in $referenceName but ${pb.positional} in $otherName');
    }
    if (pa.named.length != pb.named.length || !pa.named.containsAll(pb.named)) {
      problems.add('"$key" named placeholders differ: $referenceName ${pa.named} vs $otherName ${pb.named}');
    }
  }
  return problems;
}

final RegExp _quotedTr = RegExp(
  r"""(?:'([a-z0-9_]+(?:\.[a-z0-9_]+)+)'|"([a-z0-9_]+(?:\.[a-z0-9_]+)+)")\s*\.\s*(?:tr|plural)\(""",
);
final RegExp _trCall = RegExp(r"""\btr\(\s*(?:'([a-z0-9_]+(?:\.[a-z0-9_]+)+)'|"([a-z0-9_]+(?:\.[a-z0-9_]+)+)")""");

/// `Text('words')` / `Text("words")` — the literal starts with a letter (any
/// script) and isn't immediately translated with `.tr()`.
final RegExp _literalText = RegExp(
  r"""\bText\(\s*(?:'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)")(?!\s*\.\s*(?:tr|plural)\()""",
);

/// Scans one Dart source for unknown translation keys and untranslated Text
/// literals. [keys] are the reference locale's flattened keys.
List<String> scanSource(String path, String source, Set<String> keys) {
  final problems = <String>[];
  final lines = source.split('\n');
  final allowText = hardcodedTextAllowlist.contains(path);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('//')) continue;
    for (final match in [..._quotedTr.allMatches(line), ..._trCall.allMatches(line)]) {
      final key = match.group(1) ?? match.group(2)!;
      final isGroup = keys.any((k) => k.startsWith('$key.'));
      if (!keys.contains(key) && !isGroup) problems.add('$path:${i + 1} uses undefined key "$key"');
    }
    if (allowText) continue;
    for (final match in _literalText.allMatches(line)) {
      final literal = match.group(1) ?? match.group(2) ?? '';
      // Interpolation only ('$count') is not text.
      final bare = literal.replaceAll(RegExp(r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*'), '');
      if (RegExp(r'\p{L}', unicode: true).hasMatch(bare)) {
        problems.add('$path:${i + 1} has an untranslated Text: ${match.group(0)}');
      }
    }
  }
  return problems;
}

Map<String, dynamic> _readJson(File file) => jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

/// Runs every check from [root] (the project directory). Returns problems.
List<String> checkProject(Directory root) {
  final problems = <String>[];
  Map<String, TranslationValue> load(String locale) {
    final file = File('${root.path}/$translationsDir/$locale.json');
    if (!file.existsSync()) {
      problems.add('Missing ${file.path}');
      return const {};
    }
    try {
      return flattenTranslations(_readJson(file), problems: problems);
    } on FormatException catch (e) {
      problems.add('$locale.json is not valid JSON: ${e.message}');
      return const {};
    }
  }

  final reference = load(referenceLocale);
  for (final locale in otherLocales) {
    problems.addAll(compareLocales(reference, load(locale), otherName: locale));
  }

  final lib = Directory('${root.path}/lib');
  if (lib.existsSync()) {
    final keys = reference.keys.toSet();
    final files = lib.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      if (file.path.endsWith('.g.dart')) continue;
      final relative = file.path.substring(root.path.length + 1).replaceAll(r'\', '/');
      problems.addAll(scanSource(relative, file.readAsStringSync(), keys));
    }
  }
  return problems;
}

const String _usage = '''
Checks translations (en / ar) and lib/ for localization mistakes.

Usage: dart run tool/check_translations.dart [--help]

Fails (exit 1) when:
  * a key exists in one locale only, or a value is empty;
  * placeholders differ between locales ({} count or {name} names);
  * plural forms (zero/one/two/few/many/other) differ;
  * lib/ has Text('literal') / Text("literal") (allowlist: lib/shared/screens/config_error_app.dart);
  * lib/ calls .tr() / tr() on a quoted key that doesn't exist.
''';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    print(_usage);
    return;
  }
  if (args.isNotEmpty) {
    stderr.writeln('Unknown arguments: ${args.join(' ')}\n\n$_usage');
    exit(64);
  }
  final problems = checkProject(Directory.current);
  if (problems.isEmpty) {
    print('Translations OK ($referenceLocale + ${otherLocales.join(', ')}).');
    return;
  }
  problems.forEach(print);
  print('${problems.length} translation problem(s).');
  exit(1);
}
