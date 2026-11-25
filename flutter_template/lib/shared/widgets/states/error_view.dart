// Full-area (or compact inline) error with a retry button.
//
// Source: corsa-customer lib/core/utilities/widgets/base_fetching_widget.dart
//         (BaseErrorWidget: failure → localized sentence, retry button, compact
//         row variant for list footers).
// Merged: baytna lib/core/widgets/app_empty_state.dart (error variant shares the
//         empty-state layout so the screen doesn't jump; offline gets its own
//         icon); markspulse lib/core/widgets/feedback/error_view.dart (the
//         failure mapper's sentence, never raw text).
// See docs/WIDGETS.md#states.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/errors/failure.dart';
import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import 'empty_view.dart';

/// Shows [failure] (its localized `displayMessage`) or [message], with a
/// retry button when [onRetry] is set. [compact] renders a one-row version
/// for the end of a list ("couldn't load more · Try again").
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.failure, this.message, this.title, this.onRetry, this.compact = false});

  final Failure? failure;

  /// Already-translated message; wins over [failure].
  final String? message;

  /// Already-translated title; defaults to "Couldn't load this".
  final String? title;
  final VoidCallback? onRetry;
  final bool compact;

  String get _message => message ?? failure?.displayMessage ?? LocaleKeys.errors_unknown.tr();

  IconData get _icon => switch (failure) {
    NetworkFailure() => Icons.wifi_off_outlined,
    TimeoutFailure() => Icons.hourglass_empty_outlined,
    NotFoundFailure() => Icons.search_off_outlined,
    ForbiddenFailure() || UnauthorizedFailure() => Icons.lock_outline,
    _ => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    if (compact) return _compact(context);
    final tone = context.palette.danger;
    return StateMessage(
      icon: _icon,
      title: title ?? LocaleKeys.states_error_title.tr(),
      message: _message,
      actionLabel: onRetry == null ? null : LocaleKeys.common_retry.tr(),
      actionIcon: Icons.refresh,
      onAction: onRetry,
      iconColor: tone.onContainer,
      iconBackground: tone.container,
    );
  }

  Widget _compact(BuildContext context) {
    final theme = Theme.of(context);
    // Message and retry share a row when they fit; otherwise the button
    // drops under the message (long translations, large text).
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.end,
        overflowSpacing: AppSpacing.xs,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, color: theme.colorScheme.error, size: AppSizes.iconSm),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(_message, style: theme.textTheme.bodySmall)),
            ],
          ),
          if (onRetry != null) TextButton(onPressed: onRetry, child: Text(LocaleKeys.common_retry.tr())),
        ],
      ),
    );
  }
}
