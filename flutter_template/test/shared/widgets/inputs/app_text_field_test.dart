// AppTextField: obscure toggle, server error first, digit folding, LTR,
// validate on blur.
//
// Source: new (tests for lib/shared/widgets/inputs/app_text_field.dart and
//         the email / password / OTP presets).
import 'package:app_template/shared/widgets/inputs/app_email_field.dart';
import 'package:app_template/shared/widgets/inputs/app_otp_field.dart';
import 'package:app_template/shared/widgets/inputs/app_password_field.dart';
import 'package:app_template/shared/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('obscure toggle reveals and hides the text', (tester) async {
    await pumpApp(tester, const AppPasswordField(label: 'Password'), locale: const Locale('en'));

    EditableText editable() => tester.widget<EditableText>(find.byType(EditableText));
    expect(editable().obscureText, isTrue);
    expect(editable().autocorrect, isFalse);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(editable().obscureText, isFalse);

    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(editable().obscureText, isTrue);
  });

  testWidgets('server errorText is shown first and cleared by editing', (tester) async {
    await pumpApp(
      tester,
      AppTextField(label: 'Email', errorText: 'Email already taken', validator: (_) => 'local error'),
    );
    expect(find.text('Email already taken'), findsOneWidget);
    expect(find.text('local error'), findsNothing);

    await tester.enterText(find.byType(TextField), 'new@example.com');
    await tester.pump();
    expect(find.text('Email already taken'), findsNothing);
  });

  testWidgets('Arabic-Indic and Persian digits are folded to ASCII', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpApp(tester, AppTextField(controller: controller, keyboardType: TextInputType.number));

    await tester.enterText(find.byType(TextField), '٠١٢٣ ۴۵۶');
    expect(controller.text, '0123 456');
  });

  testWidgets('email field forces LTR text and folds digits', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpApp(tester, AppEmailField(controller: controller, label: 'Email'));

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.textDirection, TextDirection.ltr);
    expect(Directionality.of(tester.element(find.byType(AppEmailField))), TextDirection.rtl);

    await tester.enterText(find.byType(TextField), 'user١@example.com');
    expect(controller.text, 'user1@example.com');
  });

  testWidgets('validates when the user leaves the field after typing', (tester) async {
    final first = FocusNode();
    addTearDown(first.dispose);
    await pumpApp(
      tester,
      Column(
        children: [
          AppTextField(focusNode: first, validator: (v) => (v ?? '').length < 3 ? 'Too short' : null),
          const AppTextField(),
        ],
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'ab');
    await tester.pump();
    expect(find.text('Too short'), findsNothing, reason: 'not while typing');

    await tester.tap(find.byType(TextField).last);
    await tester.pump();
    expect(find.text('Too short'), findsOneWidget, reason: 'on blur');

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pump();
    expect(find.text('Too short'), findsNothing, reason: 'cleared as soon as fixed');
  });

  testWidgets('OTP field keeps digits only and completes', (tester) async {
    String? completed;
    await pumpApp(tester, AppOtpField(length: 4, autofocus: false, onCompleted: (v) => completed = v));

    await tester.enterText(find.byType(TextField), '١٢-٣٤');
    await tester.pump();
    expect(completed, '1234');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}
