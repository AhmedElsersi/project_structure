// Full-screen "update required" view with a store button; replaces the app
// while this build is below the supported minimum (or the API answered 426).
//
// Source: chinaparts-customer lib/features/app_config/presentation/screens/
//         force_update_screen.dart (non-dismissible screen above the router).
// Merged: baytna app_gate.dart ForcedUpdateView (a screen, not a dialog: the
//         gate sits above the Navigator, so a dialog has nowhere to go);
//         corsa-customer ForceUpdateScreen (server message overrides).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import 'gate_layout.dart';

class ForceUpdateView extends StatelessWidget {
  const ForceUpdateView({super.key, this.message, this.onUpdate});

  /// Already-localized server message; null shows the bundled sentence.
  final String? message;

  /// Opens the store. Null hides the button (no store wired).
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final update = onUpdate;
    return GateLayout(
      icon: Icons.system_update_rounded,
      title: LocaleKeys.app_gate_force_update_title.tr(),
      message: message ?? LocaleKeys.app_gate_force_update_message.tr(),
      actions: [if (update != null) FilledButton(onPressed: update, child: Text(LocaleKeys.app_gate_update_now.tr()))],
    );
  }
}
