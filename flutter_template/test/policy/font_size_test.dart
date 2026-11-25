// Policy: text sizes and weights come from the theme's TextTheme — no
// `fontSize:` / `fontWeight:` outside lib/core/theme/.
//
// Source: new (approved convention: never set fontSize / fontWeight literals
//         in widgets; use Theme.of(context).textTheme.xxx so the form-factor
//         type scale and the damped text scaler apply).
// See docs/CONVENTIONS.md#typography.
import 'package:flutter_test/flutter_test.dart';

import 'support/source_scan.dart';

const _themeDir = 'lib/core/theme/';

List<Violation> fontSizes(SourceFile file) {
  if (file.path.startsWith(_themeDir)) return const [];
  return [
    for (final match in RegExp(r'\b(fontSize|fontWeight)\s*:').allMatches(file.code))
      file.violation(match.start, '${match[1]}: → Theme.of(context).textTheme.*', match[0]!),
  ];
}

void main() {
  test('lib/ outside core/theme sets no fontSize / fontWeight', () {
    final violations = dartFiles().expand(fontSizes).toList();
    expect(violations, isEmpty, reason: 'Use the TextTheme:${report(violations)}');
  });

  group('rule', () {
    int count(String code, {String path = 'lib/x.dart'}) => fontSizes(SourceFile(path, code)).length;

    test('catches fontSize / fontWeight arguments', () {
      expect(count('TextStyle(fontSize: 14)'), 1);
      expect(count('style.copyWith(\n  fontSize : 18,\n  fontWeight: FontWeight.bold,\n)'), 2);
    });

    test('allows reading fontSize, comments and lib/core/theme', () {
      expect(count('final size = style?.fontSize ?? 14;'), 0);
      expect(count('final bold = style?.fontWeight == FontWeight.bold;'), 0);
      expect(count('// TextStyle(fontSize: 14)'), 0);
      expect(count('TextStyle(fontSize: 14)', path: 'lib/core/theme/app_typography.dart'), 0);
    });
  });
}
