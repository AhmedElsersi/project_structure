// AppSnackBar: context and context-free (messengerKey) paths, palette colours,
// cancelled failures never shown, undo calls back.
//
// Source: new (tests for lib/shared/widgets/feedback/app_snackbar.dart).
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/theme/app_palette.dart';
import 'package:app_template/shared/widgets/feedback/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('context-free success uses the palette success pair', (tester) async {
    await pumpApp(tester, const SizedBox.expand(), scaffoldMessengerKey: AppSnackBar.messengerKey);

    AppSnackBar.success('Saved');
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
    final palette = tester.element(find.text('Saved')).palette;
    final material = tester.widget<Material>(
      find.ancestor(of: find.text('Saved'), matching: find.byType(Material)).first,
    );
    expect(material.color, palette.success.container);
    expect(tester.widget<Text>(find.text('Saved')).style?.color, palette.success.onContainer);
  });

  testWidgets('error shows the failure sentence; cancelled is ignored', (tester) async {
    late BuildContext context;
    await pumpApp(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox.expand();
        },
      ),
      locale: const Locale('en'),
    );

    AppSnackBar.error(const CancelledFailure(), context: context);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    AppSnackBar.error(const NetworkFailure(), context: context);
    await tester.pumpAndSettle();
    expect(find.text('No internet connection. Check your connection and try again.'), findsOneWidget);
  });

  testWidgets('undo calls back and hides the bar', (tester) async {
    late BuildContext context;
    var undone = 0;
    await pumpApp(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox.expand();
        },
      ),
      locale: const Locale('en'),
    );

    AppSnackBar.undo('Item deleted', onUndo: () => undone++, context: context);
    await tester.pump(); // starts the entrance animation
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Item deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('Item deleted'), findsNothing);
  });
}
