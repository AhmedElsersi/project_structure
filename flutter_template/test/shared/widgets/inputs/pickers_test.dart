// AppDateField (locale display, Western digits, picker), AppDropdown
// (selection, server error), AppSearchField (debounce, clear).
//
// Source: new (tests for lib/shared/widgets/inputs/*).
import 'package:app_template/shared/widgets/inputs/app_date_field.dart';
import 'package:app_template/shared/widgets/inputs/app_dropdown.dart';
import 'package:app_template/shared/widgets/inputs/app_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppDateField', () {
    testWidgets('shows the date in the UI language with Western digits', (tester) async {
      await pumpApp(tester, AppDateField(label: 'Date', value: DateTime(2026, 11, 5), onChanged: (_) {}));
      final text = tester.widget<EditableText>(find.byType(EditableText)).controller.text;
      expect(text, contains('2026'));
      expect(text, isNot(contains('٢')));

      await pumpApp(
        tester,
        AppDateField(label: 'Date', value: DateTime(2026, 11, 5), onChanged: (_) {}),
        locale: const Locale('en'),
      );
      expect(find.text('Nov 5, 2026'), findsOneWidget);
    });

    testWidgets('tapping opens the picker and reports the chosen day', (tester) async {
      DateTime? picked;
      await pumpApp(
        tester,
        AppDateField(label: 'Date', value: DateTime(2026, 11, 5), onChanged: (d) => picked = d),
        locale: const Locale('en'),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('12'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 11, 12));
    });

    testWidgets('validator receives the DateTime', (tester) async {
      final formKey = GlobalKey<FormState>();
      await pumpApp(
        tester,
        Form(
          key: formKey,
          child: AppDateField(value: null, onChanged: (_) {}, validator: (d) => d == null ? 'Pick a date' : null),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Pick a date'), findsOneWidget);
    });
  });

  group('AppDropdown', () {
    testWidgets('selects an item and shows a server error', (tester) async {
      String? selected;
      await pumpApp(
        tester,
        AppDropdown<String>(
          label: 'City',
          items: const ['Cairo', 'Giza'],
          labelOf: (c) => c,
          errorText: 'Unknown city',
          onChanged: (c) => selected = c,
        ),
      );
      expect(find.text('Unknown city'), findsOneWidget);

      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giza').last);
      await tester.pumpAndSettle();
      expect(selected, 'Giza');
    });

    testWidgets('disabled when enabled is false', (tester) async {
      await pumpApp(
        tester,
        AppDropdown<String>(items: const ['A'], labelOf: (c) => c, enabled: false, onChanged: (_) {}),
      );
      expect(
        tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>)).onChanged,
        isNull,
      );
    });
  });

  group('AppSearchField', () {
    testWidgets('debounces typing; clear reports an empty query at once', (tester) async {
      final queries = <String>[];
      await pumpApp(tester, AppSearchField(onChanged: queries.add), locale: const Locale('en'));

      await tester.enterText(find.byType(TextField), 'ph');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 100));
      expect(queries, isEmpty);

      await tester.pump(const Duration(milliseconds: 400));
      expect(queries, ['phone']);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(queries, ['phone', '']);
      expect(find.byTooltip('Clear search'), findsNothing);
    });
  });
}
