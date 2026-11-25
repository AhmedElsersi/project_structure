// Tests for lib/core/theme/app_palette.dart. Source: new
//
// WCAG contrast of every StatusTone container/onContainer pair.
//
// Merged: lexa-control test/ui/theme_contrast_test.dart (relative luminance +
//         contrast ratio asserted per foreground/background pair).
import 'dart:math' as math;

import 'package:app_template/core/theme/app_palette.dart';
import 'package:app_template/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x relative luminance of an opaque colour.
double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colours (1..21).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('contrast helper sanity: black on white is 21:1', () {
    expect(_contrast(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(_contrast(Colors.white, Colors.white), closeTo(1, 0.001));
  });

  for (final brightness in Brightness.values) {
    group('${brightness.name} palette', () {
      final theme = brightness == Brightness.light ? AppTheme.light() : AppTheme.dark();
      final palette = theme.extension<AppPalette>()!;

      for (final tone in StatusTone.values) {
        test('${tone.name}: onContainer on container ≥ 4.5:1 (WCAG AA)', () {
          final colors = palette.toneColors(tone);
          expect(colors.container.a, 1.0, reason: 'container must be opaque for the ratio to hold');
          final ratio = _contrast(colors.onContainer, colors.container);
          expect(ratio, greaterThanOrEqualTo(4.5), reason: '${tone.name} is ${ratio.toStringAsFixed(2)}:1');
        });

        test('${tone.name}: onContainer is readable on the page surface too (≥ 3:1)', () {
          final ratio = _contrast(palette.toneColors(tone).onContainer, theme.colorScheme.surface);
          expect(ratio, greaterThanOrEqualTo(3), reason: '${tone.name} is ${ratio.toStringAsFixed(2)}:1');
        });
      }
    });
  }

  test('toneColors maps every tone to its own pair', () {
    final palette = AppTheme.light().extension<AppPalette>()!;
    expect(palette.toneColors(StatusTone.success), same(palette.success));
    expect(palette.toneColors(StatusTone.warning), same(palette.warning));
    expect(palette.toneColors(StatusTone.info), same(palette.info));
    expect(palette.toneColors(StatusTone.danger), same(palette.danger));
    expect(palette.toneColors(StatusTone.neutral), same(palette.neutral));
  });

  test('lerp interpolates between light and dark palettes', () {
    final light = AppTheme.light().extension<AppPalette>()!;
    final dark = AppTheme.dark().extension<AppPalette>()!;
    expect(light.lerp(dark, 0).success.container, light.success.container);
    expect(light.lerp(dark, 1).success.container, dark.success.container);
    expect(identical(light.lerp(null, 0.5), light), isTrue);
    final copy = light.copyWith(success: dark.success);
    expect(copy.success, same(dark.success));
    expect(copy.warning, same(light.warning));
  });
}
