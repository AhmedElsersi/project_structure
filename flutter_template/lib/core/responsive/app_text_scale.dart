// Damped system font scaling: the device font-size setting has a SMALL effect.
//
// Source: tebbr lib/core/utilities/constants/app_text_scale.dart (damped
//         TextScaler applied once at the root, per font size so Android 14's
//         non-linear scaling is respected, plus extra()/isEnlarged() helpers).
// Merged: your convention 1.0–1.3 bounds (chinaparts-customer / lexa-student
//         clamp range) instead of tebbr's 1.15 cap.
//
// | System setting | App text |
// |----------------|----------|
// | ≤ 1.0          | 1.00     |
// | 1.15           | 1.075    |
// | 1.3            | 1.15     |
// | 1.5            | 1.25     |
// | ≥ 1.6 (to 2.0) | 1.30     |
// See docs/CONVENTIONS.md#text-scaling.
import 'package:flutter/widgets.dart';

abstract final class AppTextScale {
  /// Never smaller than the design size.
  static const double min = 1.0;

  /// Hard cap so layouts survive the largest accessibility setting.
  static const double max = 1.3;

  /// Share of the system's enlargement the app applies (0.5 = half).
  static const double damping = 0.5;

  /// Maps the device's [system] scaler to the app's damped scaler.
  static TextScaler apply(TextScaler system) => system == TextScaler.noScaling ? system : DampedTextScaler(system);

  /// Wraps [child] so every route, dialog and sheet below gets the damped
  /// scaler. Used in `MaterialApp.builder`.
  static Widget wrap(BuildContext context, Widget child) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: apply(mq.textScaler)),
      child: child,
    );
  }

  /// Extra height [lines] of text at [fontSize] need at the current scale, so
  /// fixed-height slots can grow with text (0 at default size).
  static double extra(BuildContext context, double fontSize, {double lineHeight = 1.2, int lines = 1}) {
    final scaled = MediaQuery.textScalerOf(context).scale(fontSize);
    return scaled <= fontSize ? 0 : (scaled - fontSize) * lineHeight * lines;
  }

  /// Whether the user enlarged text beyond the default.
  static bool isEnlarged(BuildContext context) => MediaQuery.textScalerOf(context).scale(10) > 10;
}

/// Applies [AppTextScale.damping] of the system enlargement, clamped to
/// [AppTextScale.min]..[AppTextScale.max], per font size.
class DampedTextScaler extends TextScaler {
  const DampedTextScaler(this.system);

  final TextScaler system;

  @override
  double scale(double fontSize) {
    if (fontSize <= 0) return fontSize;
    final requested = system.scale(fontSize) / fontSize;
    final factor = (1 + (requested - 1) * AppTextScale.damping).clamp(AppTextScale.min, AppTextScale.max);
    return fontSize * factor;
  }

  @override
  // Required by the TextScaler interface; mirrors scale() at 14sp like
  // Flutter's own non-linear scalers.
  // ignore: deprecated_member_use
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) => other is DampedTextScaler && other.system == system;

  @override
  int get hashCode => Object.hash(DampedTextScaler, system);

  @override
  String toString() => 'DampedTextScaler($system)';
}
