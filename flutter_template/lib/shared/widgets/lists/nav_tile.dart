// Settings / navigation row: tinted leading icon, title, subtitle, trailing
// widget and a chevron that mirrors in RTL.
//
// Source: markspulse lib/core/widgets/cards/nav_tile.dart (one row widget for
//         "opens somewhere else"; `Icons.chevron_right` in BOTH languages —
//         it mirrors by itself in RTL; tinted square behind the icon; trailing
//         badge before the chevron).
// Merged: corsa-customer lib/core/utilities/widgets/app_main_card.dart AppMenuTile
//         (danger tint for "Sign out" / "Delete account").
// See docs/WIDGETS.md#lists.
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A tappable row that navigates somewhere. Texts are already translated.
class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.destructive = false,
  });

  final String title;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? subtitle;

  /// Before the chevron: a count badge, a status chip, the current value.
  final Widget? trailing;
  final bool showChevron;

  /// Error colours, for "Sign out" / "Delete account".
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = destructive ? scheme.error : scheme.primary;
    final accentBackground = destructive ? scheme.errorContainer : scheme.primaryContainer;
    final extra = trailing;

    return ListTile(
      onTap: onTap,
      leading: icon == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(color: accentBackground, borderRadius: AppRadii.smAll),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                child: Icon(icon, size: AppSizes.iconSm, color: accent),
              ),
            ),
      title: Text(title, style: destructive ? theme.listTileTheme.titleTextStyle?.copyWith(color: scheme.error) : null),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: !showChevron
          ? extra
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (extra != null) ...[extra, const SizedBox(width: AppSpacing.sm)],
                // Mirrors automatically in RTL (matchTextDirection).
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
    );
  }
}
