// Neutral splash shown while the app restores the session (no text).
//
// Source: new (the template's splash route only waits for SessionCubit; the
//         in-scope apps' splash screens are brand art + timers, dropped).
// Replace FlutterLogo with the client's logo asset (keep it text-free so it
// never needs translating).
// See docs/WIDGETS.md#screens.
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Centered placeholder logo with a small progress indicator.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // {{APP_LOGO}} — swap for the brand asset.
          FlutterLogo(size: AppSizes.iconLg * 3),
          SizedBox(height: AppSpacing.xxl),
          SizedBox.square(dimension: AppSizes.icon, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    ),
  );
}
