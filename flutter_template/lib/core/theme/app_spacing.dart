// Spacing, radius and size tokens — use these instead of magic numbers.
// Fixed logical pixels (no screenutil); responsiveness comes from form-factor
// gutters (breakpoints.dart) and max content widths.
//
// Source: baytna lib/app/theme/app_spacing.dart (AppSpacing/AppRadii/AppSizes),
//         markspulse app_radii.dart + app_insets.dart (directional insets),
//         lexa responsive.dart (spacing scale).
import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Vertical gap widgets.
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
}

abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlTop = BorderRadius.vertical(top: Radius.circular(xl));
}

abstract final class AppSizes {
  /// Minimum touch target (Material / iOS HIG).
  static const double minTouch = 48;
  static const double buttonHeight = 52;
  static const double iconSm = 18;
  static const double icon = 24;
  static const double iconLg = 32;

  /// Dialog / bottom-sheet width caps (applied through the theme).
  static const double dialogMaxWidth = 560;
  static const double sheetMaxWidth = 640;
}
