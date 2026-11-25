// Policy: colours come from the theme (ColorScheme / context.palette) —
// no Color(0x...) or Colors.xxx outside lib/core/theme/.
//
// Source: new (approved convention: colours only from
//         `Theme.of(context).colorScheme` and `context.palette`; the
//         per-widget hex colours of the house style are the #1 dark-mode bug).
// See docs/CONVENTIONS.md#theme.
import 'package:flutter_test/flutter_test.dart';

import 'support/source_scan.dart';

const _themeDir = 'lib/core/theme/';

List<Violation> colorLiterals(SourceFile file) {
  if (file.path.startsWith(_themeDir)) return const [];
  final code = file.code;
  final violations = <Violation>[];
  final patterns = {
    RegExp(r'\bColor\s*\(\s*0x'): 'Color(0x…) literal',
    RegExp(r'\bColor\.from(ARGB|RGBO)\s*\('): 'Color.fromARGB/fromRGBO literal',
    RegExp(r'\b(?:Cupertino)?Colors\.(?!transparent\b)\w+'): 'Colors.* constant',
  };
  patterns.forEach((pattern, rule) {
    for (final match in pattern.allMatches(code)) {
      violations.add(file.violation(match.start, '$rule → colorScheme / context.palette', match[0]!));
    }
  });
  return violations;
}

void main() {
  test('lib/ outside core/theme uses no colour literals', () {
    final violations = dartFiles().expand(colorLiterals).toList();
    expect(violations, isEmpty, reason: 'Take colours from the theme:${report(violations)}');
  });

  group('rule', () {
    int count(String code, {String path = 'lib/x.dart'}) => colorLiterals(SourceFile(path, code)).length;

    test('catches hex colours and Colors constants', () {
      expect(count('Color(0xFF112233)'), 1);
      expect(count('const Color( 0xFF112233)'), 1);
      expect(count('Colors.red'), 1);
      expect(count('Colors.black.withValues(alpha: 0.5)'), 1);
      expect(count('CupertinoColors.systemBlue'), 1);
      expect(count('Color.fromARGB(255, 1, 2, 3)'), 1);
    });

    test('allows Colors.transparent, theme colours, comments and lib/core/theme', () {
      expect(count('Colors.transparent'), 0);
      expect(count('Theme.of(context).colorScheme.primary'), 0);
      expect(count('// Colors.red'), 0);
      expect(count('Colors.red', path: 'lib/core/theme/app_colors.dart'), 0);
    });
  });
}
