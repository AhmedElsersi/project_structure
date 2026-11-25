// showConfirmDialog / showTypedConfirmDialog results, LoadingOverlay always
// closes, showAppBottomSheet is a sheet on phones and a dialog on tablets.
//
// Source: new (tests for lib/shared/widgets/feedback/*).
import 'package:app_template/shared/widgets/feedback/app_bottom_sheet.dart';
import 'package:app_template/shared/widgets/feedback/confirm_dialog.dart';
import 'package:app_template/shared/widgets/feedback/loading_overlay.dart';
import 'package:app_template/shared/widgets/feedback/typed_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// A button that runs [onPressed] with its context.
Widget _launcher(void Function(BuildContext context) onPressed) => Builder(
  builder: (context) => TextButton(onPressed: () => onPressed(context), child: const Text('open')),
);

void main() {
  group('showConfirmDialog', () {
    testWidgets('returns true on confirm', (tester) async {
      bool? result;
      await pumpApp(
        tester,
        _launcher((context) async => result = await showConfirmDialog(context, title: 'Delete?', confirmLabel: 'Yes')),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete?'), findsOneWidget);

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.text('Delete?'), findsNothing);
    });

    testWidgets('returns false on cancel and on barrier tap', (tester) async {
      bool? result;
      await pumpApp(
        tester,
        _launcher((context) async => result = await showConfirmDialog(context, title: 'Leave?', destructive: true)),
        locale: const Locale('en'),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      result = null;
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  testWidgets('typed confirm enables only after the word is typed', (tester) async {
    bool? result;
    await pumpApp(
      tester,
      _launcher(
        (context) async => result = await showTypedConfirmDialog(
          context,
          title: 'Delete workspace',
          confirmWord: 'DELETE',
          consequence: 'Everything will be removed.',
          confirmLabel: 'Delete forever',
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    FilledButton confirm() => tester.widget<FilledButton>(
      find.ancestor(of: find.text('Delete forever'), matching: find.byType(FilledButton)),
    );
    expect(confirm().onPressed, isNull);

    await tester.enterText(find.byType(TextField), ' delete ');
    await tester.pump();
    expect(confirm().onPressed, isNotNull);

    await tester.tap(find.text('Delete forever'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  group('LoadingOverlay.run', () {
    testWidgets('closes on success and on error; nested runs share one overlay', (tester) async {
      late BuildContext context;
      await pumpApp(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      );

      final done = LoadingOverlay.run(context, Future<int>.delayed(const Duration(seconds: 1), () => 42));
      await tester.pump();
      expect(LoadingOverlay.isShowing, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final inner = LoadingOverlay.run(context, Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'one overlay for nested runs');

      await tester.pump(const Duration(milliseconds: 600));
      await inner;
      expect(LoadingOverlay.isShowing, isTrue, reason: 'outer run still in flight');

      await tester.pump(const Duration(milliseconds: 500));
      expect(await done, 42);
      await tester.pumpAndSettle();
      expect(LoadingOverlay.isShowing, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final failing = LoadingOverlay.run<void>(context, Future<void>.error(StateError('boom')));
      await expectLater(failing, throwsStateError);
      await tester.pumpAndSettle();
      expect(LoadingOverlay.isShowing, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('showAppBottomSheet', () {
    testWidgets('modal sheet on phones, returns the popped value', (tester) async {
      String? result;
      await pumpApp(
        tester,
        _launcher(
          (context) async => result = await showAppBottomSheet<String>(
            context,
            title: 'Pick',
            builder: (sheet) => TextButton(onPressed: () => Navigator.of(sheet).pop('a'), child: const Text('A')),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Pick'), findsOneWidget);

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(result, 'a');
    });

    testWidgets('centred dialog on tablets with a close button', (tester) async {
      await pumpApp(
        tester,
        _launcher((context) => showAppBottomSheet<void>(context, title: 'Pick', builder: (_) => const Text('body'))),
        size: kLayoutMatrix['tablet']!,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
