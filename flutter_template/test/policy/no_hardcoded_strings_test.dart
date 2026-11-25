// Policy: no user-facing string literals in lib/ — every text goes through
// LocaleKeys.xxx.tr().
//
// Source: chinaparts-seller tool/check_translations.dart (`Text('literal')`
//         without `.tr()` fails CI).
// Merged: new (named text parameters — tooltip / hintText / labelText /
//         label… — and multi-line constructor calls via the shared scanner).
// See docs/CONVENTIONS.md#localization.
import 'package:flutter_test/flutter_test.dart';

import 'support/source_scan.dart';

/// Runs before translations exist (bad build configuration screen).
const _allowlist = {'lib/shared/screens/config_error_app.dart'};

/// Named arguments that carry user-facing text.
const _textParams = [
  'tooltip',
  'hintText',
  'labelText',
  'helperText',
  'errorText',
  'counterText',
  'semanticLabel',
  'semanticsLabel',
  'label',
  'hint',
  'helper',
  'title',
  'subtitle',
  'message',
  'actionLabel',
  'confirmLabel',
  'cancelLabel',
];

final _letter = RegExp(r'\p{L}', unicode: true);
final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*');

/// True when the literal at [quote] contains letters (outside interpolation)
/// and is not immediately translated (`'key'.tr()`).
bool _isUserText(String code, int quote) {
  final end = stringEnd(code, quote);
  final literal = code.substring(quote, end);
  final translated = RegExp(r'^\s*\.\s*(tr|plural)\(').hasMatch(code.substring(end));
  return !translated && _letter.hasMatch(literal.replaceAll(_interpolation, '').substring(1));
}

List<Violation> hardcodedStrings(SourceFile file) {
  if (_allowlist.contains(file.path)) return const [];
  final code = file.code;
  final violations = <Violation>[];

  // Text('...') / SelectableText("...") / TextSpan(text: '...').
  for (final match in RegExp(r'''\b(?:Text|SelectableText)\s*\(\s*r?(['"])''').allMatches(code)) {
    final quote = match.end - 1;
    if (_isUserText(code, quote)) {
      violations.add(file.violation(match.start, 'Text literal', code.substring(match.start, stringEnd(code, quote))));
    }
  }
  final named = RegExp('\\b(${_textParams.join('|')}|text)\\s*:\\s*r?([\'"])');
  for (final match in named.allMatches(code)) {
    final quote = match.end - 1;
    if (_isUserText(code, quote)) {
      violations.add(
        file.violation(match.start, '${match[1]}: literal', code.substring(match.start, stringEnd(code, quote))),
      );
    }
  }
  return violations;
}

void main() {
  test('lib/ has no hardcoded user-facing strings', () {
    final violations = dartFiles().expand(hardcodedStrings).toList();
    expect(violations, isEmpty, reason: 'Use LocaleKeys.xxx.tr():${report(violations)}');
  });

  group('rule', () {
    List<String> rules(String code) => hardcodedStrings(SourceFile('lib/x.dart', code)).map((v) => v.rule).toList();

    test('catches literals in Text and text parameters (any script, multi-line)', () {
      expect(rules("const Text('Hello')"), ['Text literal']);
      expect(rules('Text(\n  "مرحبا",\n)'), ['Text literal']);
      expect(rules("IconButton(tooltip: 'Close', icon: x)"), ['tooltip: literal']);
      expect(rules("InputDecoration(hintText: 'Search', labelText: 'Name')"), [
        'hintText: literal',
        'labelText: literal',
      ]);
      expect(rules("NavigationDestination(label: Text('Home'))"), ['Text literal']);
      expect(rules("AppButton(label: 'Save')"), ['label: literal']);
    });

    test('ignores keys, interpolation-only text, symbols and comments', () {
      expect(rules('Text(LocaleKeys.common_ok.tr())'), isEmpty);
      expect(rules("Text('common.ok'.tr())"), isEmpty);
      expect(rules(r"Text('$count')"), isEmpty);
      expect(rules(r"Text('${a.b} · ${c}')"), isEmpty);
      expect(rules("Text('—')"), isEmpty);
      expect(rules("// Text('Hello')\n/// tooltip: 'x'"), isEmpty);
    });

    test('the allowlisted config error screen may use literals', () {
      expect(hardcodedStrings(SourceFile('lib/shared/screens/config_error_app.dart', "Text('Hi')")), isEmpty);
    });
  });
}
