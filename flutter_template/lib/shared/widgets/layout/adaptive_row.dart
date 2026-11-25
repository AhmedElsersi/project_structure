// A row that becomes a column when it is too narrow or the text is enlarged.
//
// Source: corsa-driver lib/core/utilities/widgets/adaptive_row.dart (Row ↔
//         Column by available width or text scale; Expanded/Flexible children
//         unwrapped in column mode so they don't assert).
// See docs/WIDGETS.md#layout.
import 'package:flutter/widgets.dart';

import '../../../core/theme/app_spacing.dart';

/// Lays [children] out in a row, or stacks them when the available width is
/// below [minRowWidth] or the effective text scale reaches [stackAtTextScale].
class AdaptiveRow extends StatelessWidget {
  const AdaptiveRow({
    super.key,
    required this.children,
    this.spacing = AppSpacing.sm,
    this.minRowWidth,
    this.stackAtTextScale = 1.2,
    this.forceColumn = false,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.columnCrossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final double spacing;

  /// Below this width the children stack. Null = only text scale decides.
  final double? minRowWidth;

  /// Effective (already damped) text scale at which the children stack.
  final double stackAtTextScale;
  final bool forceColumn;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final CrossAxisAlignment columnCrossAxisAlignment;

  static Widget _unflex(Widget child) => child is Flexible ? child.child : child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const probe = 14.0;
      final scale = MediaQuery.textScalerOf(context).scale(probe) / probe;
      final min = minRowWidth;
      final stack = forceColumn || scale >= stackAtTextScale || (min != null && constraints.maxWidth < min);
      if (stack) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: columnCrossAxisAlignment,
          spacing: spacing,
          children: children.map(_unflex).toList(),
        );
      }
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        spacing: spacing,
        children: children,
      );
    },
  );
}
