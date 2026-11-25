// Tests for lib/core/responsive/app_text_scale.dart. Source: new
import 'package:app_template/core/responsive/app_text_scale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Android 14-style non-linear scaler: small text grows more than big text.
class _NonLinearScaler extends TextScaler {
  const _NonLinearScaler();

  @override
  double scale(double fontSize) => fontSize < 20 ? fontSize * 2.0 : fontSize * 1.2;

  @override
  // Required by the interface; not used by the code under test.
  // ignore: deprecated_member_use
  double get textScaleFactor => 2.0;
}

double _factor(double system, [double fontSize = 14]) =>
    DampedTextScaler(TextScaler.linear(system)).scale(fontSize) / fontSize;

Future<BuildContext> _contextWithScaler(WidgetTester tester, TextScaler system, {bool wrap = true}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: system),
      child: Builder(
        builder: (outer) {
          final child = Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          );
          return wrap ? AppTextScale.wrap(outer, child) : child;
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('DampedTextScaler (linear system setting)', () {
    final table = <double, double>{
      0.85: 1.0,
      1.0: 1.0,
      1.15: 1.075,
      1.3: 1.15,
      1.5: 1.25,
      1.6: 1.3,
      2.0: 1.3,
      3.0: 1.3,
    };
    table.forEach((system, app) {
      test('system $system → app $app', () => expect(_factor(system), closeTo(app, 1e-9)));
    });

    test('the same factor applies to every font size for a linear scaler', () {
      for (final size in [11.0, 14.0, 22.0, 57.0]) {
        expect(_factor(1.3, size), closeTo(1.15, 1e-9), reason: '$size');
      }
    });

    test('never below min or above max', () {
      expect(AppTextScale.min, 1.0);
      expect(AppTextScale.max, 1.3);
      for (var s = 0.5; s <= 3.0; s += 0.05) {
        expect(_factor(s), inInclusiveRange(AppTextScale.min, AppTextScale.max), reason: '$s');
      }
    });

    test('zero / negative font sizes pass through', () {
      const scaler = DampedTextScaler(TextScaler.linear(2));
      expect(scaler.scale(0), 0);
      expect(scaler.scale(-4), -4);
    });

    test('value equality', () {
      expect(const DampedTextScaler(TextScaler.linear(1.3)), const DampedTextScaler(TextScaler.linear(1.3)));
      expect(
        const DampedTextScaler(TextScaler.linear(1.3)).hashCode,
        const DampedTextScaler(TextScaler.linear(1.3)).hashCode,
      );
      expect(const DampedTextScaler(TextScaler.linear(1.3)), isNot(const DampedTextScaler(TextScaler.linear(1.5))));
    });
  });

  test('DampedTextScaler is computed per font size for non-linear scalers', () {
    const scaler = DampedTextScaler(_NonLinearScaler());
    // 14sp: system 2.0 → damped 1.5 → capped 1.3.
    expect(scaler.scale(14), closeTo(14 * 1.3, 1e-9));
    // 30sp: system 1.2 → damped 1.1.
    expect(scaler.scale(30), closeTo(30 * 1.1, 1e-9));
  });

  group('AppTextScale.apply', () {
    test('noScaling passes through untouched', () {
      expect(identical(AppTextScale.apply(TextScaler.noScaling), TextScaler.noScaling), isTrue);
    });

    test('any other scaler is damped', () {
      final applied = AppTextScale.apply(const TextScaler.linear(1.5));
      expect(applied, isA<DampedTextScaler>());
      expect(applied.scale(10), closeTo(12.5, 1e-9));
    });
  });

  group('AppTextScale.wrap / extra / isEnlarged', () {
    testWidgets('wrap damps the scaler seen by descendants', (tester) async {
      final c = await _contextWithScaler(tester, const TextScaler.linear(1.5));
      expect(MediaQuery.textScalerOf(c).scale(10), closeTo(12.5, 1e-9));
    });

    testWidgets('extra() is the extra height scaled text needs', (tester) async {
      final enlarged = await _contextWithScaler(tester, const TextScaler.linear(1.5));
      // 16sp × 1.25 = 20 → 4 extra × 1.2 line height.
      expect(AppTextScale.extra(enlarged, 16), closeTo(4.8, 1e-9));
      expect(AppTextScale.extra(enlarged, 16, lines: 2, lineHeight: 1.5), closeTo(12, 1e-9));
      expect(AppTextScale.isEnlarged(enlarged), isTrue);
    });

    testWidgets('default and smaller system sizes need no extra space', (tester) async {
      for (final system in const [TextScaler.linear(1.0), TextScaler.linear(0.85)]) {
        final c = await _contextWithScaler(tester, system);
        expect(AppTextScale.extra(c, 16), 0);
        expect(AppTextScale.isEnlarged(c), isFalse);
      }
    });
  });
}
