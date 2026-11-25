// List/detail layout: one pane on phones and narrow widths, two panes when the
// available width allows, split exactly at a foldable's hinge.
//
// Source: new (approved decision C2: hinge-aware two-pane layouts from
//         MediaQuery.displayFeatures). Uses the template's
//         lib/core/responsive/display_features.dart (separatingHinge) and
//         breakpoints.dart; widths come from LayoutBuilder, not the device.
// Merged: corsa-customer lib/core/utilities/widgets/adaptive_shell.dart idea
//         (layout switches on the window, start side flips in RTL).
// See docs/WIDGETS.md#layout.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/display_features.dart';

/// Shows [primary] alone on phones / narrow widths, or [primary] (start side)
/// next to [secondary] when both panes can be at least [minPaneWidth] wide.
///
/// Foldables:
/// * vertical hinge (book posture) → split exactly at the hinge, the hinge
///   area stays empty;
/// * horizontal hinge (tabletop) → [primary] above, [secondary] below it.
///
/// Hinge bounds are window coordinates; the widget measures its own position
/// after layout, so it also works when it doesn't start at the window edge.
class AdaptiveTwoPane extends StatefulWidget {
  const AdaptiveTwoPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.minPaneWidth = 320,
    this.primaryFraction = 0.4,
  }) : assert(primaryFraction > 0 && primaryFraction < 1, 'primaryFraction must be in (0, 1)');

  /// The list / master pane; the only pane in single-pane mode.
  final Widget primary;

  /// The detail pane.
  final Widget secondary;
  final double minPaneWidth;

  /// Share of the width given to [primary] (at least [minPaneWidth]).
  final double primaryFraction;

  @override
  State<AdaptiveTwoPane> createState() => _AdaptiveTwoPaneState();
}

class _AdaptiveTwoPaneState extends State<AdaptiveTwoPane> {
  /// Global position of this widget's top-left corner (for hinge maths).
  Offset _origin = Offset.zero;

  void _measureOrigin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final origin = box.localToGlobal(Offset.zero);
      if ((origin - _origin).distance > 0.5) setState(() => _origin = origin);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hinge = context.separatingHinge;
    final isPhone = context.isPhone;
    if (hinge != null) _measureOrigin();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (hinge != null && size.isFinite) {
          final local = hinge.bounds.shift(-_origin);
          if (hinge.isVertical && local.left > 0 && local.right < size.width) {
            return _splitAtVerticalHinge(context, size, local);
          }
          if (!hinge.isVertical && local.top > 0 && local.bottom < size.height) {
            return _splitAtHorizontalHinge(local, size);
          }
        }

        if (isPhone || !constraints.hasBoundedWidth) return widget.primary;
        final width = constraints.maxWidth;
        final primaryWidth = math.max(width * widget.primaryFraction, widget.minPaneWidth);
        if (width - primaryWidth < widget.minPaneWidth) return widget.primary;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: primaryWidth, child: widget.primary),
            const VerticalDivider(),
            Expanded(child: widget.secondary),
          ],
        );
      },
    );
  }

  /// Book posture: start pane = the part before the hinge in reading order.
  Widget _splitAtVerticalHinge(BuildContext context, Size size, Rect hinge) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final startWidth = rtl ? size.width - hinge.right : hinge.left;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: startWidth, child: widget.primary),
        SizedBox(width: hinge.width),
        Expanded(child: widget.secondary),
      ],
    );
  }

  /// Tabletop posture: content on the upper half, the rest below.
  Widget _splitAtHorizontalHinge(Rect hinge, Size size) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: hinge.top, child: widget.primary),
      SizedBox(height: hinge.height),
      Expanded(child: widget.secondary),
    ],
  );
}
