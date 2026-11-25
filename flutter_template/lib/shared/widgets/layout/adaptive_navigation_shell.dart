// Top-level navigation that adapts to the window: bottom NavigationBar on
// phones, NavigationRail on the start side for tablets (extended on large
// landscape tablets), and never across a vertical hinge.
//
// Source: corsa-customer lib/core/utilities/widgets/adaptive_shell.dart (swap
//         the bottom bar for a NavigationRail on wider windows; the rail sits
//         on the leading edge so it flips in RTL).
// Merged: approved decision C2 (adaptive shell by form factor; foldables via
//         DisplayFeatureSubScreen so the rail + body stay on one side of a
//         book-posture hinge) — new; themed Material NavigationBar instead of
//         the source's custom curved bar.
// See docs/WIDGETS.md#layout.
import 'package:flutter/material.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/display_features.dart';

/// One top-level destination. [label] is already translated.
class AdaptiveDestination {
  const AdaptiveDestination({required this.icon, required this.label, IconData? selectedIcon})
    : selectedIcon = selectedIcon ?? icon;

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// App shell with adaptive navigation:
///
/// * phone → bottom [NavigationBar];
/// * tablet → [NavigationRail] on the start side (right in Arabic);
/// * large tablet in landscape → extended rail with labels beside icons;
/// * a vertical separating hinge (book posture) → the whole shell is placed
///   in the start-side half so the body never straddles the fold.
class AdaptiveNavigationShell extends StatelessWidget {
  const AdaptiveNavigationShell({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.destinations,
    required this.body,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<AdaptiveDestination> destinations;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    assert(destinations.length >= 2, 'NavigationBar / NavigationRail need at least two destinations');
    final Widget shell = context.isPhone ? _bottomBar() : _rail(context);
    final hinge = context.separatingHinge;
    // Only an OCCLUDING vertical hinge (dual-screen devices) hides pixels: keep
    // rail + body on the start-side screen there. A fold (Galaxy Fold, Pixel
    // Fold) has continuous pixels, so the shell keeps the full width and
    // screens split around the fold themselves with AdaptiveTwoPane.
    if (hinge != null && hinge.isVertical && hinge.isOccluding) return DisplayFeatureSubScreen(child: shell);
    return shell;
  }

  Widget _bottomBar() => Scaffold(
    body: body,
    bottomNavigationBar: NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelect,
      destinations: [
        for (final d in destinations)
          NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
      ],
    ),
  );

  Widget _rail(BuildContext context) {
    final extended = context.isLargeTablet && context.isLandscape;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      body: Row(
        children: [
          // The rail pads itself for the start-side safe area.
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onSelect,
            extended: extended,
            // An extended rail shows labels beside icons; labelType must be none.
            labelType: extended ? NavigationRailLabelType.none : null,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
            ],
          ),
          const VerticalDivider(),
          // ...so the body must not pad for that side again.
          Expanded(
            child: MediaQuery.removePadding(context: context, removeLeft: !rtl, removeRight: rtl, child: body),
          ),
        ],
      ),
    );
  }
}
