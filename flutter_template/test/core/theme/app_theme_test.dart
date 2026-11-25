// Tests for lib/core/theme/app_theme.dart. Source: new
//
// Also covers app_typography.dart.
import 'package:app_template/core/responsive/breakpoints.dart';
import 'package:app_template/core/theme/app_palette.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_theme.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, TextStyle?> _slots(TextTheme t) => {
  'displayLarge': t.displayLarge,
  'displayMedium': t.displayMedium,
  'displaySmall': t.displaySmall,
  'headlineLarge': t.headlineLarge,
  'headlineMedium': t.headlineMedium,
  'headlineSmall': t.headlineSmall,
  'titleLarge': t.titleLarge,
  'titleMedium': t.titleMedium,
  'titleSmall': t.titleSmall,
  'bodyLarge': t.bodyLarge,
  'bodyMedium': t.bodyMedium,
  'bodySmall': t.bodySmall,
  'labelLarge': t.labelLarge,
  'labelMedium': t.labelMedium,
  'labelSmall': t.labelSmall,
};

void main() {
  final themes = {'light': AppTheme.light(), 'dark': AppTheme.dark()};

  test('brightness matches', () {
    expect(themes['light']!.brightness, Brightness.light);
    expect(themes['light']!.colorScheme.brightness, Brightness.light);
    expect(themes['dark']!.brightness, Brightness.dark);
    expect(themes['dark']!.colorScheme.brightness, Brightness.dark);
  });

  themes.forEach((name, theme) {
    group('$name theme', () {
      test('uses Material 3 and carries the AppPalette extension', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.extension<AppPalette>(), isNotNull);
      });

      test('dialogs and sheets are width-capped', () {
        expect(theme.dialogTheme.constraints?.maxWidth, AppSizes.dialogMaxWidth);
        expect(AppSizes.dialogMaxWidth, 560);
        expect(theme.bottomSheetTheme.constraints?.maxWidth, AppSizes.sheetMaxWidth);
      });

      test('every TextTheme slot has a size, weight, height and the onSurface colour', () {
        _slots(theme.textTheme).forEach((slot, style) {
          expect(style, isNotNull, reason: slot);
          expect(style!.fontSize, isNotNull, reason: slot);
          expect(style.fontSize, greaterThan(0), reason: slot);
          expect(style.fontWeight, isNotNull, reason: slot);
          expect(style.height, isNotNull, reason: slot);
          expect(style.color, theme.colorScheme.onSurface, reason: slot);
        });
      });

      test('type scale matches AppTypography', () {
        final base = AppTypography.base(theme.colorScheme.onSurface);
        final expected = _slots(base);
        _slots(theme.textTheme).forEach((slot, style) {
          expect(style!.fontSize, expected[slot]!.fontSize, reason: slot);
        });
        expect(theme.textTheme.bodyMedium!.fontSize, 14);
        expect(theme.textTheme.titleLarge!.fontSize, 22);
      });

      test('buttons get their size/shape/text from the theme', () {
        final filled = theme.filledButtonTheme.style!;
        expect(filled.minimumSize?.resolve({}), const Size(64, AppSizes.buttonHeight));
        expect(filled.textStyle?.resolve({})?.fontSize, theme.textTheme.labelLarge!.fontSize);
        expect(theme.outlinedButtonTheme.style, isNotNull);
        expect(theme.textButtonTheme.style!.minimumSize?.resolve({})?.height, AppSizes.minTouch);
        expect(theme.elevatedButtonTheme.style, isNotNull);
      });

      testWidgets('builds a real widget tree without errors', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              appBar: AppBar(title: const Text('Title')),
              body: Column(
                children: [
                  FilledButton(onPressed: () {}, child: const Text('Filled')),
                  OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                  TextButton(onPressed: () {}, child: const Text('Text')),
                  const TextField(decoration: InputDecoration(labelText: 'Label')),
                  const Card(child: ListTile(title: Text('Tile'))),
                  const Chip(label: Text('Chip')),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(Theme.of(tester.element(find.text('Filled'))).extension<AppPalette>(), isNotNull);
      });
    });
  });

  group('AppTheme.adaptTo', () {
    final light = AppTheme.light();

    test('phone keeps the same theme instance', () {
      expect(identical(AppTheme.adaptTo(light, FormFactor.phone), light), isTrue);
    });

    test('tablets scale every font size by AppTypography.scaleFor', () {
      for (final ff in [FormFactor.tablet, FormFactor.largeTablet]) {
        final factor = AppTypography.scaleFor(ff);
        expect(factor, greaterThan(1));
        final adapted = AppTheme.adaptTo(light, ff);
        final before = _slots(light.textTheme);
        _slots(adapted.textTheme).forEach((slot, style) {
          expect(style!.fontSize, closeTo(before[slot]!.fontSize! * factor, 1e-9), reason: '${ff.name} $slot');
        });
        expect(adapted.extension<AppPalette>(), isNotNull, reason: 'extensions survive copyWith');
      }
      expect(AppTypography.scaleFor(FormFactor.tablet), 1.06);
      expect(AppTypography.scaleFor(FormFactor.largeTablet), 1.1);
    });
  });
}
