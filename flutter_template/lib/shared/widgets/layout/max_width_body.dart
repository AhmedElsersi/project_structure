// Caps content width on tablets so forms and lists don't stretch edge to edge.
//
// Source: chinaparts-customer lib/core/utilities/responsive/max_width_body.dart
//         (centre + cap on larger screens, transparent pass-through on phones;
//         keep the scrollable INSIDE so only content is capped).
// Merged: lexa ContentWidthLimit idea + the template's context.maxContentWidth
//         token; content fills the capped width instead of shrink-wrapping (new).
// See docs/WIDGETS.md#layout.
import 'package:flutter/widgets.dart';

import '../../../core/responsive/breakpoints.dart';

/// Centres [child] and limits its width to [maxWidth] (default
/// `context.maxContentWidth`: unlimited on phones, 720 / 840 on tablets).
/// The child always gets the full capped width.
class MaxWidthBody extends StatelessWidget {
  const MaxWidthBody({super.key, required this.child, this.maxWidth, this.alignment = AlignmentDirectional.topCenter});

  final Widget child;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final cap = maxWidth ?? context.maxContentWidth;
    if (cap.isInfinite) return child;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
