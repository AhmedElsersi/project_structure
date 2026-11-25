// Tests for lib/core/utils/debouncer.dart. Source: new
//
// Debouncer timing runs under testWidgets' fake clock (tester.pump), so no
// real waiting and no direct fake_async import. Throttler takes a clock.
import 'package:app_template/core/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    testWidgets('runs only the last action after the quiet period', (tester) async {
      final calls = <int>[];
      final debouncer = Debouncer(const Duration(milliseconds: 300));

      debouncer.run(() => calls.add(1));
      await tester.pump(const Duration(milliseconds: 200));
      debouncer.run(() => calls.add(2));
      await tester.pump(const Duration(milliseconds: 299));
      expect(calls, isEmpty);
      expect(debouncer.isPending, isTrue);

      await tester.pump(const Duration(milliseconds: 1));
      expect(calls, [2]);
      expect(debouncer.isPending, isFalse);
      debouncer.dispose();
    });

    testWidgets('flush runs the pending action now, once', (tester) async {
      final calls = <int>[];
      final debouncer = Debouncer(const Duration(seconds: 1));

      debouncer.run(() => calls.add(1));
      debouncer.flush();
      expect(calls, [1]);
      await tester.pump(const Duration(seconds: 2));
      expect(calls, [1]);

      debouncer.flush(); // nothing pending: no-op
      expect(calls, [1]);
    });

    testWidgets('cancel and dispose drop the pending action', (tester) async {
      final calls = <int>[];
      final debouncer = Debouncer(const Duration(milliseconds: 100));

      debouncer.run(() => calls.add(1));
      debouncer.cancel();
      debouncer.run(() => calls.add(2));
      debouncer.dispose();
      await tester.pump(const Duration(seconds: 1));
      expect(calls, isEmpty);
    });
  });

  group('Throttler', () {
    test('leading edge, then at most once per interval', () {
      var now = DateTime(2026);
      final calls = <int>[];
      final throttler = Throttler(const Duration(seconds: 1), clock: () => now);

      expect(throttler.run(() => calls.add(1)), isTrue);
      now = now.add(const Duration(milliseconds: 500));
      expect(throttler.run(() => calls.add(2)), isFalse);
      now = now.add(const Duration(milliseconds: 500));
      expect(throttler.run(() => calls.add(3)), isTrue);
      expect(calls, [1, 3]);
    });

    test('reset lets the next call through immediately', () {
      final now = DateTime(2026);
      final calls = <int>[];
      final throttler = Throttler(const Duration(minutes: 1), clock: () => now);

      throttler.run(() => calls.add(1));
      throttler.reset();
      throttler.run(() => calls.add(2));
      expect(calls, [1, 2]);
    });
  });
}
