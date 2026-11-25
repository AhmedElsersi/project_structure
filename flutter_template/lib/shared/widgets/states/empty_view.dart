// "Nothing here yet" view: icon, title, message and an optional action.
//
// Source: baytna lib/core/widgets/app_empty_state.dart (icon in a tinted circle,
//         title + body + one action, readable width).
// Merged: corsa-customer lib/core/utilities/widgets/base_fetching_widget.dart
//         (BaseEmptyWidget: scrolls instead of overflowing on short screens /
//         large text; compact variant).
// See docs/WIDGETS.md#states.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_spacing.dart';
import '../buttons/app_button.dart';

/// An empty state. All texts are already translated; [title] and [message]
/// default to the generic "Nothing here yet" sentences.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String? title;
  final String? message;

  /// Button shown when both [actionLabel] and [onAction] are set.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Smaller icon and padding (inside cards / sections).
  final bool compact;

  @override
  Widget build(BuildContext context) => StateMessage(
    icon: icon,
    title: title ?? LocaleKeys.states_empty_title.tr(),
    message: message ?? LocaleKeys.states_empty_message.tr(),
    actionLabel: actionLabel,
    onAction: onAction,
    compact: compact,
  );
}

/// Shared layout of [EmptyView] / `ErrorView`: tinted icon, title, message
/// and one action, centred, width-capped and scrollable so it never
/// overflows on a short window or with large text.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.compact = false,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final bool compact;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSize = compact ? AppSizes.iconLg : AppSizes.iconLg * 1.5;
    final label = actionLabel;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.all(compact ? AppSpacing.lg : AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBackground ?? scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.all(compact ? AppSpacing.md : AppSpacing.lg),
                  child: Icon(icon, size: iconSize, color: iconColor ?? scheme.onSurfaceVariant),
                ),
              ),
              compact ? AppSpacing.gapMd : AppSpacing.gapLg,
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge,
                ),
              ),
              if (message != null) ...[
                AppSpacing.gapSm,
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (label != null && onAction != null) ...[
                compact ? AppSpacing.gapMd : AppSpacing.gapXl,
                AppButton(label: label, icon: actionIcon, onPressed: onAction, variant: AppButtonVariant.tonal),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
