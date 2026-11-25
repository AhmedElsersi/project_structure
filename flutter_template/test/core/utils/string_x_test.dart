// Tests for lib/core/extensions/string_x.dart and context_x.dart. Source: new
import 'package:app_template/core/extensions/context_x.dart';
import 'package:app_template/core/extensions/string_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringX', () {
    test('isBlank / isNotBlank / nullIfBlank', () {
      const String? none = null;
      expect(none.isBlank, isTrue);
      expect(''.isBlank, isTrue);
      expect(' \n\t'.isBlank, isTrue);
      expect(' a '.isBlank, isFalse);
      expect('a'.isNotBlank, isTrue);
      expect('  '.nullIfBlank, isNull);
      expect(' a '.nullIfBlank, ' a ');
    });

    test('capitalize is safe on empty, Arabic and emoji', () {
      expect(''.capitalize(), '');
      expect('hello world'.capitalize(), 'Hello world');
      expect('مرحبا'.capitalize(), 'مرحبا');
      expect('👍🏽ok'.capitalize(), '👍🏽ok');
    });

    test('withWesternDigits', () => expect('رقم ١٢٣'.withWesternDigits, 'رقم 123'));
  });

  testWidgets('ContextX reads theme and direction', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(captured.isRtl, isTrue);
    expect(captured.textDirection, TextDirection.rtl);
    expect(captured.colorScheme, Theme.of(captured).colorScheme);
    expect(captured.textTheme, Theme.of(captured).textTheme);
    expect(captured.languageCode, 'en');
    captured.hideKeyboard(); // no focus: no-op, must not throw
  });
}
