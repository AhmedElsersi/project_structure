// The app's type scale — the ONLY place text sizes are defined. Widgets read
// `Theme.of(context).textTheme.*`; never pass a raw fontSize.
//
// Source: baytna lib/app/theme/app_typography.dart (TextTheme from tokens, Arabic
//         + Latin font), lexa-control lib/core/ui/theme.dart (type scale baked
//         into ThemeData per breakpoint; colour bound before sizing).
// Responsive: sizes grow slightly on tablets (see [scaleFor]) instead of
// screenutil's `.sp`; the user's system font setting is damped separately
// (app_text_scale.dart).
import 'package:flutter/material.dart';

import '../responsive/breakpoints.dart';

abstract final class AppTypography {
  /// {{FONT_FAMILY}} — e.g. 'Cairo' (Arabic + Latin). Add the font files under
  /// assets/fonts and a `fonts:` entry in pubspec.yaml, then set it here.
  /// null = platform font (Roboto / SF + system Arabic).
  static const String? fontFamily = null;

  /// Material 3 type scale with explicit sizes/heights (Arabic needs height).
  static TextTheme base(Color onSurface) {
    TextStyle s(double size, FontWeight weight, double height, [double letter = 0]) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letter,
      color: onSurface,
    );
    return TextTheme(
      displayLarge: s(57, FontWeight.w400, 1.12),
      displayMedium: s(45, FontWeight.w400, 1.16),
      displaySmall: s(36, FontWeight.w400, 1.22),
      headlineLarge: s(32, FontWeight.w600, 1.25),
      headlineMedium: s(28, FontWeight.w600, 1.29),
      headlineSmall: s(24, FontWeight.w600, 1.33),
      titleLarge: s(22, FontWeight.w600, 1.27),
      titleMedium: s(16, FontWeight.w600, 1.5, 0.1),
      titleSmall: s(14, FontWeight.w600, 1.43, 0.1),
      bodyLarge: s(16, FontWeight.w400, 1.5),
      bodyMedium: s(14, FontWeight.w400, 1.43),
      bodySmall: s(12, FontWeight.w400, 1.33),
      labelLarge: s(14, FontWeight.w600, 1.43, 0.1),
      labelMedium: s(12, FontWeight.w600, 1.33, 0.4),
      labelSmall: s(11, FontWeight.w600, 1.45, 0.4),
    );
  }

  /// Size multiplier per form factor (tablets read from further away).
  static double scaleFor(FormFactor formFactor) => switch (formFactor) {
    FormFactor.phone => 1.0,
    FormFactor.tablet => 1.06,
    FormFactor.largeTablet => 1.1,
  };
}
