// Form body that fills the viewport with the footer pinned at the bottom, and
// scrolls instead of overflowing (keyboard, landscape, large text).
//
// Source: chinaparts-customer lib/core/utilities/responsive/scrollable_form_body.dart
//         (content gets the viewport height as a MINIMUM inside a scroll view:
//         footer pinned when there is room, scrolls when there isn't).
// Merged: a min-height Column with spaceBetween instead of IntrinsicHeight, so
//         children that can't report intrinsic sizes (LayoutBuilder, the OTP
//         field) work (new); drag dismisses the keyboard.
// See docs/WIDGETS.md#layout.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Scrollable form layout: [child] at the top, [footer] (e.g. the submit
/// button) pinned to the bottom of the viewport when it fits, otherwise
/// following the content.
///
/// Don't put `Spacer` / `Expanded` directly in [child] (its height is
/// unbounded); the space between content and footer is handled here.
class ScrollableFormBody extends StatelessWidget {
  const ScrollableFormBody({super.key, required this.child, this.footer, this.padding, this.controller});

  final Widget child;
  final Widget? footer;

  /// Padding around content and footer. Defaults to vertical spacing only
  /// (horizontal gutters usually come from `AppScaffold`).
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    final padding = this.padding ?? const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.lg);
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = padding.resolve(Directionality.of(context)).vertical;
        final minHeight = constraints.hasBoundedHeight ? math.max(0.0, constraints.maxHeight - vertical) : 0.0;
        return SingleChildScrollView(
          controller: controller,
          padding: padding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            // In an unbounded scroll view a Column is as tall as its content,
            // but at least minHeight; spaceBetween pushes the footer down.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child,
                if (footer != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl),
                    child: footer,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
