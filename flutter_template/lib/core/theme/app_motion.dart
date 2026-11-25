// Animation durations/curves that collapse to zero when the OS asks for
// reduced motion.
//
// Source: baytna lib/app/theme/app_motion.dart (AppMotion.of returns zero under
//         reduced motion), markspulse app_motion.dart (scaled()).
import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// [duration], or zero when animations are disabled in accessibility settings.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
