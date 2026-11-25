// Policy: no deprecated or banned APIs / packages in lib/.
//
// Source: new (approved conventions: PopScope not WillPopScope, withValues not
//         withOpacity, WidgetState* not MaterialState*, TextScaler not
//         textScaleFactor, ColorScheme.surface not background; no
//         flutter_screenutil, no dartz — the template's Result replaces Either).
// See docs/CONVENTIONS.md#deprecated-apis.
import 'package:flutter_test/flutter_test.dart';

import 'support/source_scan.dart';

/// Required overrides of deprecated members (path → rule names allowed).
const _allowlist = {
  // DampedTextScaler implements the TextScaler interface, which still
  // declares the deprecated `textScaleFactor` getter.
  'lib/core/responsive/app_text_scale.dart': {'textScaleFactor'},
};

final _rules = <String, (RegExp, String)>{
  'WillPopScope': (RegExp(r'\bWillPopScope\b'), 'use PopScope'),
  'withOpacity': (RegExp(r'\.withOpacity\s*\('), 'use .withValues(alpha: …)'),
  'textScaleFactor': (RegExp(r'\btextScaleFactor\b'), 'use MediaQuery.textScalerOf / TextScaler'),
  'MaterialStateProperty': (RegExp(r'\bMaterialStateProperty\b'), 'use WidgetStateProperty'),
  'MaterialState': (RegExp(r'\bMaterialState\.'), 'use WidgetState'),
  'ColorScheme.background': (
    RegExp(r'\b(?:colorScheme|scheme|ColorScheme)\s*\.\s*(?:background|onBackground)\b|\bonBackground\b'),
    'use surface / onSurface',
  ),
  'screenutil': (
    RegExp(r'''import\s+['"]package:flutter_screenutil/|\bScreenUtil\w*\b|\bscreenutil\b''', caseSensitive: false),
    'fixed logical px + AppSpacing tokens, no screenutil',
  ),
  'dartz': (RegExp(r'''import\s+['"]package:dartz/'''), 'use Result (lib/core/result/result.dart)'),
};

List<Violation> deprecatedApis(SourceFile file) {
  final allowed = _allowlist[file.path] ?? const <String>{};
  final violations = <Violation>[];
  _rules.forEach((name, rule) {
    if (allowed.contains(name)) return;
    for (final match in rule.$1.allMatches(file.code)) {
      violations.add(file.violation(match.start, '$name → ${rule.$2}', match[0]!));
    }
  });
  return violations;
}

void main() {
  test('lib/ uses no deprecated or banned APIs', () {
    final violations = dartFiles().expand(deprecatedApis).toList();
    expect(violations, isEmpty, reason: report(violations));
  });

  group('rule', () {
    List<String> names(String code, {String path = 'lib/x.dart'}) =>
        deprecatedApis(SourceFile(path, code)).map((v) => v.rule.split(' ').first).toList();

    test('catches each banned API', () {
      expect(names('WillPopScope(onWillPop: f, child: c)'), ['WillPopScope']);
      expect(names('color.withOpacity(0.5)'), ['withOpacity']);
      expect(names('MediaQuery.of(context).textScaleFactor'), ['textScaleFactor']);
      expect(names('MaterialStateProperty.all(x)'), ['MaterialStateProperty']);
      expect(names('states.contains(MaterialState.pressed)'), ['MaterialState']);
      expect(names('Theme.of(context).colorScheme.background'), ['ColorScheme.background']);
      expect(names("import 'package:flutter_screenutil/flutter_screenutil.dart';"), ['screenutil']);
      expect(names("import 'package:dartz/dartz.dart';"), ['dartz']);
    });

    test('allows modern APIs, comments and the allowlisted override', () {
      expect(names('PopScope(canPop: false, child: c)'), isEmpty);
      expect(names('color.withValues(alpha: 0.5)'), isEmpty);
      expect(names('WidgetStateProperty.all(x)'), isEmpty);
      expect(names('scheme.surface'), isEmpty);
      expect(names('// never use textScaleFactor'), isEmpty);
      expect(names('double get textScaleFactor => 1;', path: 'lib/core/responsive/app_text_scale.dart'), isEmpty);
    });
  });
}
