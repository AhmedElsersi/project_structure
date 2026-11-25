// Tests for lib/core/responsive/breakpoints.dart. Source: new
import 'package:app_template/core/responsive/breakpoints.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _contextWithSize(WidgetTester tester, Size size) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('FormFactor.fromShortestSide boundaries', () {
    final cases = <double, FormFactor>{
      0.0: FormFactor.phone,
      320.0: FormFactor.phone,
      599.0: FormFactor.phone,
      599.99: FormFactor.phone,
      600.0: FormFactor.tablet,
      839.0: FormFactor.tablet,
      839.99: FormFactor.tablet,
      840.0: FormFactor.largeTablet,
      1366.0: FormFactor.largeTablet,
    };
    cases.forEach((side, expected) {
      test('$side → ${expected.name}', () => expect(FormFactor.fromShortestSide(side), expected));
    });

    test('FormFactor.of uses the shortest side (orientation-independent)', () {
      expect(FormFactor.of(const Size(852, 393)), FormFactor.phone);
      expect(FormFactor.of(const Size(393, 852)), FormFactor.phone);
      expect(FormFactor.of(const Size(1280, 800)), FormFactor.tablet);
      expect(FormFactor.of(const Size(1366, 1024)), FormFactor.largeTablet);
    });

    test('isPhone / isTabletOrLarger', () {
      expect(FormFactor.phone.isPhone, isTrue);
      expect(FormFactor.phone.isTabletOrLarger, isFalse);
      expect(FormFactor.tablet.isTabletOrLarger, isTrue);
      expect(FormFactor.largeTablet.isTabletOrLarger, isTrue);
    });
  });

  group('ResponsiveContext', () {
    testWidgets('portrait phone', (tester) async {
      final c = await _contextWithSize(tester, const Size(393, 852));
      expect(c.formFactor, FormFactor.phone);
      expect(c.isPhone, isTrue);
      expect(c.isTablet, isFalse);
      expect(c.isLandscape, isFalse);
      expect(c.pageGutter, 16);
      expect(c.maxContentWidth, double.infinity);
      expect(c.windowSize, const Size(393, 852));
    });

    testWidgets('landscape phone 852x393 is still a phone', (tester) async {
      final c = await _contextWithSize(tester, const Size(852, 393));
      expect(c.formFactor, FormFactor.phone);
      expect(c.isPhone, isTrue);
      expect(c.isLandscape, isTrue);
      expect(c.responsive(phone: 'p', tablet: 't', largeTablet: 'l'), 'p');
    });

    testWidgets('tablet (portrait and landscape) and an unfolded foldable', (tester) async {
      for (final size in const [Size(800, 1280), Size(1280, 800), Size(673, 841)]) {
        final c = await _contextWithSize(tester, size);
        expect(c.formFactor, FormFactor.tablet, reason: '$size');
        expect(c.isTablet, isTrue, reason: '$size');
        expect(c.isTabletOrLarger, isTrue, reason: '$size');
        expect(c.pageGutter, 24, reason: '$size');
        expect(c.maxContentWidth, 720, reason: '$size');
        expect(
          c.responsive(phone: 'p', tablet: 't', largeTablet: 'l'),
          't',
          reason: '$size',
        );
      }
    });

    testWidgets('large tablet', (tester) async {
      final c = await _contextWithSize(tester, const Size(1024, 1366));
      expect(c.formFactor, FormFactor.largeTablet);
      expect(c.isLargeTablet, isTrue);
      expect(c.pageGutter, 32);
      expect(c.maxContentWidth, 840);
      expect(c.responsive(phone: 'p', tablet: 't', largeTablet: 'l'), 'l');
    });

    testWidgets('responsive() falls back to the next smaller value', (tester) async {
      final large = await _contextWithSize(tester, const Size(1024, 1366));
      expect(large.responsive(phone: 'p', tablet: 't'), 't');
      expect(large.responsive(phone: 'p'), 'p');
      final tablet = await _contextWithSize(tester, const Size(700, 1000));
      expect(tablet.responsive(phone: 'p', largeTablet: 'l'), 'p');
    });

    testWidgets('re-evaluated when the window changes (never cached)', (tester) async {
      expect((await _contextWithSize(tester, const Size(393, 852))).formFactor, FormFactor.phone);
      expect((await _contextWithSize(tester, const Size(900, 1200))).formFactor, FormFactor.largeTablet);
      expect((await _contextWithSize(tester, const Size(393, 852))).formFactor, FormFactor.phone);
    });
  });

  group('columnsForWidth', () {
    test('degenerate widths → 1 column', () {
      expect(columnsForWidth(0), 1);
      expect(columnsForWidth(-10), 1);
      expect(columnsForWidth(double.infinity), 1);
      expect(columnsForWidth(100), 1);
    });

    test('floor(width / 160), clamped to 1..6', () {
      expect(columnsForWidth(159), 1);
      expect(columnsForWidth(320), 2);
      expect(columnsForWidth(479), 2);
      expect(columnsForWidth(480), 3);
      expect(columnsForWidth(960), 6);
      expect(columnsForWidth(5000), 6);
    });

    test('custom tile width and max columns', () {
      expect(columnsForWidth(600, minTileWidth: 200), 3);
      expect(columnsForWidth(5000, minTileWidth: 200, maxColumns: 4), 4);
    });
  });
}
