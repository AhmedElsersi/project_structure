// BuildContext shortcuts for theme, text styles, colours, direction and keyboard.
//
// Source: baytna lib/core/utils/extensions/context_x.dart (theme / text /
//         colours shortcuts), corsa-customer lib/core/extensions/context_extensions.dart
//         (isRtl, hideKeyboard).
// Responsive helpers live in core/responsive/breakpoints.dart and the semantic
// palette in core/theme/app_palette.dart (`context.palette`).
import 'package:flutter/material.dart';

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Current text direction (from the locale).
  TextDirection get textDirection => Directionality.of(this);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Language code of the current UI locale (`ar`, `en`).
  String get languageCode => Localizations.localeOf(this).languageCode;

  /// Closes the soft keyboard by removing focus.
  void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();
}
