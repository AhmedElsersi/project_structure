// Shared widgets must not overflow at 320 px with the largest app text scale,
// in Arabic and English, nor on tablets / landscape.
//
// Source: new (convention: layouts survive the max app scale 1.3 at 320 px).
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/theme/app_palette.dart';
import 'package:app_template/shared/widgets/buttons/app_button.dart';
import 'package:app_template/shared/widgets/display/status_chip.dart';
import 'package:app_template/shared/widgets/inputs/app_date_field.dart';
import 'package:app_template/shared/widgets/inputs/app_dropdown.dart';
import 'package:app_template/shared/widgets/inputs/app_otp_field.dart';
import 'package:app_template/shared/widgets/inputs/app_search_field.dart';
import 'package:app_template/shared/widgets/inputs/app_text_field.dart';
import 'package:app_template/shared/widgets/layout/app_scaffold.dart';
import 'package:app_template/shared/widgets/layout/scrollable_form_body.dart';
import 'package:app_template/shared/widgets/layout/section_header.dart';
import 'package:app_template/shared/widgets/lists/nav_tile.dart';
import 'package:app_template/shared/widgets/states/empty_view.dart';
import 'package:app_template/shared/widgets/states/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

Widget _form() => AppScaffold(
  title: 'A rather long screen title that must ellipsize',
  busy: true,
  bottomAction: AppButton(label: 'Submit the form now', onPressed: () {}, expand: true),
  body: ScrollableFormBody(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Personal information and contact', actionLabel: 'Edit all', onAction: () {}),
        const AppTextField(label: 'Full name', helper: 'As written on your ID card'),
        const SizedBox(height: 12),
        AppDropdown<String>(
          label: 'City',
          items: const ['Cairo', 'Alexandria', 'A city with a very very long name'],
          labelOf: (c) => c,
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        AppDateField(label: 'Birth date', value: DateTime(2000, 1, 31), onChanged: (_) {}),
        const SizedBox(height: 12),
        const AppSearchField(),
        const SizedBox(height: 12),
        const AppOtpField(length: 6, autofocus: false),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          children: [
            StatusChip(label: 'Delivered', tone: StatusTone.success, icon: Icons.check),
            StatusChip(label: 'Awaiting payment', tone: StatusTone.warning),
          ],
        ),
        NavTile(title: 'Notifications', subtitle: 'Push, email and SMS', icon: Icons.notifications, onTap: () {}),
      ],
    ),
  ),
);

void main() {
  for (final entry in kLayoutMatrix.entries) {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets('form widgets at ${entry.key} (${locale.languageCode}, largest text)', (tester) async {
        await pumpApp(
          tester,
          _form(),
          size: entry.value,
          locale: locale,
          textScale: 2.0,
          wrapInScaffold: false,
          settle: false,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('state views fit a small phone at the largest text', (tester) async {
    await pumpApp(
      tester,
      Column(
        children: [
          Expanded(
            child: EmptyView(actionLabel: 'Create the first item', onAction: () {}),
          ),
          Expanded(
            child: ErrorView(failure: const NetworkFailure(), onRetry: () {}),
          ),
          ErrorView(failure: const ServerFailure(), onRetry: () {}, compact: true),
        ],
      ),
      size: kLayoutMatrix['small_phone']!,
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });
}
