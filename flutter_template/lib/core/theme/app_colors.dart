// Brand colours — the ONLY file with colour literals (enforced by
// test/policy/color_literals_test.dart).
//
// Source: baytna lib/app/theme/app_colors.dart (single token file; semantic
//         colours separate from brand), markspulse lib/core/theme/palette.dart.
// Replace the placeholder values with the client's brand when starting a project.
import 'package:flutter/material.dart';

abstract final class AppColors {
  /// {{BRAND_PRIMARY}} — seed of the Material 3 colour scheme.
  static const Color brandSeed = Color(0xFF3F51B5);

  // Semantic tones (light / dark).
  static const Color successLight = Color(0xFF1B7F3B);
  static const Color successDark = Color(0xFF7BD88F);
  static const Color warningLight = Color(0xFF9A5B00);
  static const Color warningDark = Color(0xFFFFC266);
  static const Color infoLight = Color(0xFF0B63B5);
  static const Color infoDark = Color(0xFF8CC8FF);

  /// Scrim behind blocking overlays.
  static const Color scrim = Color(0x8A000000);
}
