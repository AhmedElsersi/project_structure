// AppButton: busy keeps the exact size, blocks taps, every variant renders.
//
// Source: new (tests for lib/shared/widgets/buttons/app_button.dart).
import 'package:app_template/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('busy keeps the button size and ignores taps', (tester) async {
    var taps = 0;
    var busy = false;
    late StateSetter setBusy;

    await pumpApp(
      tester,
      Center(
        child: StatefulBuilder(
          builder: (context, setState) {
            setBusy = setState;
            return AppButton(label: 'Save changes', icon: Icons.save, busy: busy, onPressed: () => taps++);
          },
        ),
      ),
    );

    final idle = tester.getSize(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    expect(taps, 1);

    setBusy(() => busy = true);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)), idle);

    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(taps, 1, reason: 'taps are ignored while busy');
    // Busy is not disabled: it keeps its enabled colours.
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });

  testWidgets('null onPressed disables; expand fills the width', (tester) async {
    await pumpApp(tester, const AppButton(label: 'Go', onPressed: null, expand: true));
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.enabled, isFalse);
    expect(tester.getSize(find.byType(FilledButton)).width, 393);
  });

  testWidgets('each variant maps to its Material button', (tester) async {
    await pumpApp(
      tester,
      Column(
        children: [
          for (final variant in AppButtonVariant.values)
            AppButton(label: variant.name, variant: variant, onPressed: () {}),
        ],
      ),
    );
    expect(find.byType(FilledButton), findsNWidgets(3)); // filled, tonal, danger
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
