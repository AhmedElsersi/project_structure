// Policy: RTL-first layouts — only start/end (directional) geometry in lib/.
//
// Source: new (approved convention "RTL-first": EdgeInsetsDirectional,
//         AlignmentDirectional, PositionedDirectional, BorderRadiusDirectional,
//         TextAlign.start/end; chinaparts-customer / -seller CLAUDE.md rule
//         "never left/right variants", enforced here instead of by review).
// See docs/CONVENTIONS.md#rtl.
import 'package:flutter_test/flutter_test.dart';

import 'support/source_scan.dart';

final _leftRight = RegExp(r'\b(left|right)\s*:');
final _corner = RegExp(r'\b(topLeft|topRight|bottomLeft|bottomRight)\s*:');

List<Violation> physicalGeometry(SourceFile file) {
  final code = file.code;
  final violations = <Violation>[];
  void add(int offset, String rule, String args) =>
      violations.add(file.violation(offset, rule, args.length > 80 ? '${args.substring(0, 80)}…' : args));

  for (final call in callsOf(code, RegExp(r'\bEdgeInsets\.only'))) {
    if (_leftRight.hasMatch(topLevel(call.args))) {
      add(call.offset, 'EdgeInsets.only(left/right) → EdgeInsetsDirectional.only(start/end)', call.args);
    }
  }
  for (final call in callsOf(code, RegExp(r'\bEdgeInsets\.fromLTRB'))) {
    final parts = splitArguments(call.args);
    if (parts.length == 4 && parts[0] != parts[2]) {
      add(call.offset, 'EdgeInsets.fromLTRB(left ≠ right) → EdgeInsetsDirectional.fromSTEB', call.args);
    }
  }
  for (final call in callsOf(code, RegExp(r'\bPositioned(?:\.fill)?'))) {
    if (_leftRight.hasMatch(topLevel(call.args))) {
      add(call.offset, 'Positioned(left/right) → PositionedDirectional(start/end)', call.args);
    }
  }
  for (final call in callsOf(code, RegExp(r'\bBorderRadius\.only'))) {
    if (_corner.hasMatch(topLevel(call.args))) {
      add(call.offset, 'BorderRadius.only(topLeft…) → BorderRadiusDirectional.only(topStart…)', call.args);
    }
  }
  for (final call in callsOf(code, RegExp(r'\bBorderRadius\.horizontal'))) {
    if (_leftRight.hasMatch(topLevel(call.args))) {
      add(call.offset, 'BorderRadius.horizontal(left/right) → BorderRadiusDirectional.horizontal', call.args);
    }
  }
  final alignment = RegExp(r'\bAlignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b');
  for (final match in alignment.allMatches(code)) {
    add(match.start, 'Alignment.${match[1]} → AlignmentDirectional', match[0]!);
  }
  for (final match in RegExp(r'\bTextAlign\.(left|right)\b').allMatches(code)) {
    add(match.start, 'TextAlign.${match[1]} → TextAlign.start/end', match[0]!);
  }
  return violations;
}

void main() {
  test('lib/ uses only directional (start/end) geometry', () {
    final violations = dartFiles().expand(physicalGeometry).toList();
    expect(violations, isEmpty, reason: 'Left/right geometry breaks Arabic (RTL):${report(violations)}');
  });

  group('rule', () {
    int count(String code) => physicalGeometry(SourceFile('lib/x.dart', code)).length;

    test('catches physical left/right geometry, also across lines', () {
      expect(count('EdgeInsets.only(left: 8)'), 1);
      expect(count('const EdgeInsets.only(\n  top: 4,\n  right: 8,\n)'), 1);
      expect(count('EdgeInsets.fromLTRB(16, 0, 8, 0)'), 1);
      expect(count('Positioned(\n  left: 0,\n  child: SizedBox(),\n)'), 1);
      expect(count('Positioned.fill(right: 4, child: x)'), 1);
      expect(count('BorderRadius.only(topLeft: Radius.circular(8))'), 1);
      expect(count('Align(alignment: Alignment.centerLeft)'), 1);
      expect(count('Text(x, textAlign: TextAlign.right)'), 1);
    });

    test('accepts directional and symmetric geometry', () {
      expect(count('EdgeInsetsDirectional.only(start: 8)'), 0);
      expect(count('EdgeInsets.only(top: 8, bottom: 4)'), 0);
      expect(count('EdgeInsets.fromLTRB(16, 4, 16, 0)'), 0);
      expect(count('EdgeInsets.symmetric(horizontal: 8)'), 0);
      expect(count('Positioned(top: 0, child: Padding(padding: x))'), 0);
      expect(count('PositionedDirectional(start: 0, child: x)'), 0);
      expect(count('AlignmentDirectional.centerStart'), 0);
      expect(count('Alignment.center'), 0);
      expect(count('BorderRadius.vertical(top: Radius.circular(8))'), 0);
      expect(count('TextAlign.start'), 0);
      expect(count('// Alignment.centerLeft'), 0);
    });
  });
}
