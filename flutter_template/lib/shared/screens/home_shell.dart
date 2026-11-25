// Tab shell for the StatefulShellRoute: adaptive bottom bar / rail.
//
// Source: baytna lib/features/space/presentation/widgets/app_shell.dart
//         (StatefulShellRoute.indexedStack shell; re-tapping the current tab
//         returns to its first page via goBranch(initialLocation: true)).
// Merged: corsa-customer lib/core/utilities/widgets/adaptive_shell.dart (bar on
//         phones, rail on tablets) through AdaptiveNavigationShell.
// Add a tab: add a StatefulShellBranch in app_router.dart AND a destination
// here, in the same order.
// See docs/WIDGETS.md#screens.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/generated/locale_keys.g.dart';
import '../widgets/layout/adaptive_navigation_shell.dart';

/// Shell of the tab branches (home, settings).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) =>
      // Re-selecting the current tab pops it back to its first page.
      navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) => AdaptiveNavigationShell(
    currentIndex: navigationShell.currentIndex,
    onSelect: _onSelect,
    destinations: [
      AdaptiveDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: LocaleKeys.nav_home.tr()),
      AdaptiveDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: LocaleKeys.nav_settings.tr(),
      ),
    ],
    body: navigationShell,
  );
}
