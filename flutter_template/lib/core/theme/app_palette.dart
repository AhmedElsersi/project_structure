// Semantic colours (success / warning / info / danger) as a ThemeExtension, with
// container / on-container pairs so badges keep contrast in light and dark.
//
// Source: baytna lib/app/theme/app_colors.dart (AppPalette ThemeExtension, day
//         and night), lexa-control lib/core/ui/widgets/status_pill.dart (StatTone
//         container/on-container pairs), markspulse status_colors.dart.
// Usage: `context.palette.success`, `context.palette.toneColors(StatusTone.warning)`.
import 'package:flutter/material.dart';

import 'app_colors.dart';

enum StatusTone { neutral, info, success, warning, danger }

class ToneColors {
  const ToneColors(this.container, this.onContainer);
  final Color container;
  final Color onContainer;
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
    required this.neutral,
  });

  final ToneColors success;
  final ToneColors warning;
  final ToneColors info;
  final ToneColors danger;
  final ToneColors neutral;

  factory AppPalette.from(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    ToneColors tone(Color base) => ToneColors(
      Color.alphaBlend(base.withValues(alpha: dark ? 0.24 : 0.14), scheme.surface),
      dark ? base : Color.lerp(base, Colors.black, 0.15)!,
    );
    return AppPalette(
      success: tone(dark ? AppColors.successDark : AppColors.successLight),
      warning: tone(dark ? AppColors.warningDark : AppColors.warningLight),
      info: tone(dark ? AppColors.infoDark : AppColors.infoLight),
      danger: ToneColors(scheme.errorContainer, scheme.onErrorContainer),
      neutral: ToneColors(scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    );
  }

  ToneColors toneColors(StatusTone tone) => switch (tone) {
    StatusTone.neutral => neutral,
    StatusTone.info => info,
    StatusTone.success => success,
    StatusTone.warning => warning,
    StatusTone.danger => danger,
  };

  @override
  AppPalette copyWith({
    ToneColors? success,
    ToneColors? warning,
    ToneColors? info,
    ToneColors? danger,
    ToneColors? neutral,
  }) => AppPalette(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    danger: danger ?? this.danger,
    neutral: neutral ?? this.neutral,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    ToneColors l(ToneColors a, ToneColors b) =>
        ToneColors(Color.lerp(a.container, b.container, t)!, Color.lerp(a.onContainer, b.onContainer, t)!);
    return AppPalette(
      success: l(success, other.success),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      danger: l(danger, other.danger),
      neutral: l(neutral, other.neutral),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
