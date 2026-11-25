// DirtyGuard: a clean form pops silently; a dirty one asks first.
//
// Source: new (tests for lib/shared/widgets/guards/dirty_guard.dart).
import 'package:app_template/shared/widgets/guards/dirty_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

Widget _home({required bool dirty}) => Builder(
  builder: (context) => TextButton(
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DirtyGuard(
          dirty: dirty,
          child: Scaffold(appBar: AppBar(), body: const Text('form')),
        ),
      ),
    ),
    child: const Text('open'),
  ),
);

void main() {
  testWidgets('clean form closes without asking', (tester) async {
    await pumpApp(tester, _home(dirty: false), locale: const Locale('en'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('form'), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('dirty form asks; keep editing stays, discard leaves', (tester) async {
    await pumpApp(tester, _home(dirty: true), locale: const Locale('en'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('form'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('form'), findsNothing);
  });
}
