// Card wrapper with an optional tap ripple; shape/colour from cardTheme.
//
// Source: baytna lib/core/widgets/app_card.dart (one card widget, padding token,
//         tappable variant).
// Merged: markspulse lib/core/widgets/cards/app_card.dart (InkWell inside the
//         card so the ripple is clipped to its shape; no per-card colours).
// See docs/WIDGETS.md#display.
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A themed [Card]. With [onTap] the whole card is tappable (ripple clipped
/// to the card shape by `cardTheme.clipBehavior`).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsetsDirectional.all(AppSpacing.lg),
    this.margin,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  /// Defaults to `cardTheme.margin` (zero in this template).
  final EdgeInsetsGeometry? margin;

  /// Override only with a colour from the theme / palette.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding, child: child);
    return Card(
      margin: margin,
      color: color,
      child: onTap == null && onLongPress == null
          ? content
          : InkWell(onTap: onTap, onLongPress: onLongPress, child: content),
    );
  }
}
