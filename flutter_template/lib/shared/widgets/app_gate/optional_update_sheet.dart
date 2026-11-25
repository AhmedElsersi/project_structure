// Dismissible "update available" bottom sheet, shown once per latest build.
//
// Source: baytna lib/features/config/presentation/widgets/app_gate.dart
//         (_OptionalUpdateSheet: icon, title, message, update + later).
// Merged: chinaparts-customer app_config_gate.dart (hosted by the root
//         navigator's context because the gate sits above every Navigator).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_spacing.dart';

class OptionalUpdateSheet extends StatelessWidget {
  const OptionalUpdateSheet({super.key, this.onUpdate});

  /// Opens the store. Null hides the update button.
  final VoidCallback? onUpdate;

  /// Shows the sheet on [context] (a context under a Navigator).
  static Future<void> show(BuildContext context, {VoidCallback? onUpdate}) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => OptionalUpdateSheet(onUpdate: onUpdate),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final update = onUpdate;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.system_update_rounded, color: scheme.primary, size: AppSizes.icon),
                AppSpacing.gapMd,
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(LocaleKeys.app_gate_optional_update_title.tr(), style: theme.textTheme.titleLarge),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            Text(
              LocaleKeys.app_gate_optional_update_message.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            AppSpacing.gapXl,
            if (update != null) ...[
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  update();
                },
                child: Text(LocaleKeys.app_gate_update_now.tr()),
              ),
              AppSpacing.gapSm,
            ],
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(LocaleKeys.app_gate_later.tr())),
          ],
        ),
      ),
    );
  }
}
