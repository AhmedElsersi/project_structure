// Small pill that shows a status with a semantic tone.
//
// Source: lexa-control lib/core/ui/widgets/status_pill.dart (container /
//         on-container colour PAIRS so the label always has checked contrast,
//         optional icon, pill shape).
// Merged: the template's AppPalette.toneColors(StatusTone) (baytna /
//         markspulse semantic palette) instead of the source's ColorScheme map.
// See docs/WIDGETS.md#display.
import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

/// A status pill ("Paid", "Pending", "Failed"). [label] is already translated.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = StatusTone.neutral, this.icon});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette.toneColors(tone);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onContainer);
    // Icon follows the (damped) text size so it grows with the label.
    final iconSize = MediaQuery.textScalerOf(context).scale((style?.fontSize ?? AppSpacing.md) * 1.2);

    return DecoratedBox(
      decoration: BoxDecoration(color: colors.container, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: icon == null ? AppSpacing.md : AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: colors.onContainer),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
