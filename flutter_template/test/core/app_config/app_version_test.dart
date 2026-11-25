// Tests for lib/core/app_config/app_version.dart. Source: new
import 'package:app_template/core/app_config/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parse', () {
    test('reads segments and ignores build / pre-release tails and a leading v', () {
      expect(AppVersion.parse('1.2.3'), [1, 2, 3]);
      expect(AppVersion.parse('1.2.3+45'), [1, 2, 3]);
      expect(AppVersion.parse('1.2.3-beta.1'), [1, 2, 3]);
      expect(AppVersion.parse(' v2.0 '), [2, 0]);
    });

    test('rejects garbage', () {
      for (final raw in [null, '', '   ', 'latest', '1..2', '1.x', '1.2.3.4.5', '-1.2', '+5']) {
        expect(AppVersion.parse(raw), isNull, reason: raw);
      }
    });
  });

  group('compare', () {
    test('numeric per segment, never lexicographic', () {
      expect(AppVersion.compare('1.10.0', '1.9.0'), 1);
      expect(AppVersion.compare('1.9.0', '1.10.0'), -1);
      expect(AppVersion.compare('2.3', '2.3.0'), 0);
      expect(AppVersion.compare('2.3', '2.3.1'), -1);
      expect(AppVersion.compare('1.2.3+99', '1.2.3+1'), 0);
    });

    test('null when either side is unparseable', () {
      expect(AppVersion.compare('1.0.0', 'abc'), isNull);
      expect(AppVersion.compare(null, '1.0.0'), isNull);
    });
  });

  group('isBelow (fail-closed)', () {
    test('compares when both parse', () {
      expect(AppVersion.isBelow('1.0.0', '1.0.1'), isTrue);
      expect(AppVersion.isBelow('1.0.1', '1.0.1'), isFalse);
      expect(AppVersion.isBelow('2.0', '1.9.9'), isFalse);
    });

    test('an unreadable side counts as below', () {
      expect(AppVersion.isBelow('garbage', '1.0.0'), isTrue);
      expect(AppVersion.isBelow('1.0.0', null), isTrue);
    });
  });

  group('builds', () {
    test('parseBuild accepts ints, numeric strings and whole doubles', () {
      expect(AppVersion.parseBuild(12), 12);
      expect(AppVersion.parseBuild(' 12 '), 12);
      expect(AppVersion.parseBuild(12.0), 12);
    });

    test('parseBuild rejects zero, negatives, fractions and garbage', () {
      for (final raw in <Object?>[0, -3, 12.5, 'x', null, true, double.nan]) {
        expect(AppVersion.parseBuild(raw), isNull, reason: '$raw');
      }
    });

    test('compareBuilds', () {
      expect(AppVersion.compareBuilds(3, '10'), -1);
      expect(AppVersion.compareBuilds('10', 10), 0);
      expect(AppVersion.compareBuilds(11, 10), 1);
      expect(AppVersion.compareBuilds('?', 10), isNull);
    });
  });
}
