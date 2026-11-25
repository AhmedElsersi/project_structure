// Yes/no confirmation dialog that resolves to a bool.
//
// Source: chinaparts-customer lib/core/utilities/widgets/confirm_dialog.dart
//         (Future<bool> helper, localized default cancel, destructive styling,
//         width cap from dialogTheme instead of a per-dialog wrapper).
// Merged: baytna lib/core/widgets/app_dialog.dart (optional icon; safe action
//         first in reading order, destructive one tinted danger; shown on the
//         root navigator so it covers the tab shell).
// See docs/WIDGETS.md#feedback.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../buttons/app_button.dart';

/// Asks the user to confirm. Resolves to `true` only when the confirm button
/// is pressed (barrier tap / back = `false`).
///
/// All texts are already translated; [confirmLabel] defaults to "Confirm"
/// and [cancelLabel] to "Cancel". [destructive] tints the confirm button red.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? LocaleKeys.common_confirm.tr(),
      cancelLabel: cancelLabel ?? LocaleKeys.common_cancel.tr(),
      destructive: destructive,
      icon: icon,
    ),
  );
  return result ?? false;
}

/// The dialog behind [showConfirmDialog]; pops `true` / `false`.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.message,
    this.destructive = false,
    this.icon,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: icon == null ? null : Icon(icon, color: destructive ? scheme.error : scheme.primary),
      title: Text(title, textAlign: icon == null ? TextAlign.start : TextAlign.center),
      content: message == null ? null : SingleChildScrollView(child: Text(message!)),
      actions: [
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant: destructive ? AppButtonVariant.danger : AppButtonVariant.filled,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
