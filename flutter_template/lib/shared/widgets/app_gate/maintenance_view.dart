// Full-screen maintenance view with a retry button; replaces the app while
// the server is in maintenance.
//
// Source: chinaparts-customer lib/features/app_config/presentation/screens/
//         maintenance_screen.dart (blocking screen above the router).
// Merged: corsa-customer system_config_gate.dart MaintenanceScreen (retry with
//         a busy state); baytna app_gate.dart MaintenanceView (the server's
//         message wins; the bundled sentence is the fallback).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import 'gate_layout.dart';

class MaintenanceView extends StatelessWidget {
  const MaintenanceView({super.key, this.message, this.isLoading = false, this.onRetry});

  /// Already-localized server message; null shows the bundled sentence.
  final String? message;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return GateLayout(
      icon: Icons.construction_rounded,
      title: LocaleKeys.app_gate_maintenance_title.tr(),
      message: message ?? LocaleKeys.app_gate_maintenance_message.tr(),
      actions: [
        if (retry != null)
          FilledButton(
            onPressed: isLoading ? null : retry,
            child: isLoading ? const GateButtonProgress() : Text(LocaleKeys.common_retry.tr()),
          ),
      ],
    );
  }
}
