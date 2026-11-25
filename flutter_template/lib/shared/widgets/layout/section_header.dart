// Section title with an optional action ("See all").
//
// Source: corsa-customer lib/core/utilities/widgets/section_header.dart (title +
//         "View all" text action; title wraps to 2 lines instead of overflowing).
// Merged: markspulse lib/core/widgets/layout/app_section.dart (custom trailing
//         widget in the heading row; heading semantics).
// See docs/WIDGETS.md#layout.
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A section heading with an optional [actionLabel] / [onAction] button or a
/// custom [trailing] widget. Texts are already translated.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsetsDirectional.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Replaces the action button.
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    final Widget? end =
        trailing ?? (label != null && onAction != null ? TextButton(onPressed: onAction, child: Text(label)) : null);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ?end,
        ],
      ),
    );
  }
}
