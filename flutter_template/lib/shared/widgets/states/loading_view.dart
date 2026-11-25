// Centered progress indicator with an optional message.
//
// Source: corsa-customer lib/core/utilities/widgets/base_fetching_widget.dart
//         (BaseLoadingWidget: spinner + message, compact variant for list
//         footers).
// Merged: markspulse / lexa loading views (screen-reader label).
// See docs/WIDGETS.md#states.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_spacing.dart';

/// A centered spinner. [compact] draws a small one without text (list
/// footers, inline sections).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message, this.compact = false});

  /// Already-translated text under the spinner.
  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = message;
    final Widget spinner = compact
        ? const SizedBox.square(dimension: AppSizes.icon, child: CircularProgressIndicator(strokeWidth: 2))
        : const CircularProgressIndicator();
    return Semantics(
      label: text ?? LocaleKeys.common_loading.tr(),
      child: Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(compact ? AppSpacing.lg : AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              spinner,
              if (text != null && !compact) ...[
                AppSpacing.gapLg,
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
