// AdaptiveNavigationShell (bar ↔ rail ↔ extended rail, RTL side, hinge) and
// AdaptiveTwoPane (single / two panes / hinge splits), AdaptiveRow.
//
// Source: new (tests for lib/shared/widgets/layout/*).
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app_template/shared/widgets/layout/adaptive_navigation_shell.dart';
import 'package:app_template/shared/widgets/layout/adaptive_row.dart';
import 'package:app_template/shared/widgets/layout/two_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

const _destinations = [
  AdaptiveDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  AdaptiveDestination(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
];

Widget _shell({ValueChanged<int>? onSelect}) => AdaptiveNavigationShell(
  currentIndex: 0,
  onSelect: onSelect ?? (_) {},
  destinations: _destinations,
  body: const Center(child: Text('body')),
);

/// Injects a display feature (fold / hinge) into the MediaQuery.
Widget _withFeature(Rect bounds, Widget child, {DisplayFeatureType type = DisplayFeatureType.fold}) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      displayFeatures: [DisplayFeature(bounds: bounds, type: type, state: DisplayFeatureState.postureHalfOpened)],
    ),
    child: child,
  ),
);

const _primary = ColoredBox(
  color: Colors.transparent,
  child: SizedBox.expand(key: Key('primary')),
);
const _secondary = ColoredBox(
  color: Colors.transparent,
  child: SizedBox.expand(key: Key('secondary')),
);

void main() {
  group('AdaptiveNavigationShell', () {
    testWidgets('phone (393 wide) → bottom NavigationBar', (tester) async {
      var selected = -1;
      await pumpApp(tester, _shell(onSelect: (i) => selected = i), wrapInScaffold: false);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(selected, 1);
    });

    testWidgets('tablet (800x1200) → NavigationRail on the start side', (tester) async {
      await pumpApp(tester, _shell(), size: const Size(800, 1200), wrapInScaffold: false);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isFalse);
      // Arabic (RTL): the rail sits on the right edge.
      expect(tester.getTopRight(find.byType(NavigationRail)).dx, 800);

      await pumpApp(tester, _shell(), size: const Size(800, 1200), wrapInScaffold: false, locale: const Locale('en'));
      expect(tester.getTopLeft(find.byType(NavigationRail)).dx, 0);
    });

    testWidgets('large tablet in landscape → extended rail', (tester) async {
      await pumpApp(tester, _shell(), size: const Size(1366, 1024), wrapInScaffold: false);
      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isTrue);
    });

    testWidgets('occluding vertical hinge (dual screen) → rail and body stay on one side of it', (tester) async {
      await pumpApp(
        tester,
        _withFeature(const Rect.fromLTWH(490, 0, 20, 1200), _shell(), type: DisplayFeatureType.hinge),
        size: const Size(1000, 1200),
        locale: const Locale('en'),
        wrapInScaffold: false,
      );
      expect(tester.getTopRight(find.text('body')).dx, lessThanOrEqualTo(490));
    });

    testWidgets('half-opened fold (continuous pixels) → the shell keeps the full width', (tester) async {
      await pumpApp(
        tester,
        _withFeature(const Rect.fromLTWH(500, 0, 0, 1200), _shell()),
        size: const Size(1000, 1200),
        locale: const Locale('en'),
        wrapInScaffold: false,
      );
      expect(tester.getTopRight(find.text('body')).dx, greaterThan(500));
    });
  });

  group('AdaptiveTwoPane', () {
    testWidgets('single pane on phones', (tester) async {
      await pumpApp(tester, const AdaptiveTwoPane(primary: _primary, secondary: _secondary));
      expect(find.byKey(const Key('primary')), findsOneWidget);
      expect(find.byKey(const Key('secondary')), findsNothing);
    });

    testWidgets('two panes at 1024 wide, primary on the start side', (tester) async {
      await pumpApp(
        tester,
        const AdaptiveTwoPane(primary: _primary, secondary: _secondary),
        size: kLayoutMatrix['large_tablet']!,
        locale: const Locale('en'),
      );
      expect(find.byKey(const Key('secondary')), findsOneWidget);
      final primary = tester.getRect(find.byKey(const Key('primary')));
      expect(primary.left, 0);
      expect(primary.width, closeTo(1024 * 0.4, 0.5));

      // RTL: primary moves to the right.
      await pumpApp(
        tester,
        const AdaptiveTwoPane(primary: _primary, secondary: _secondary),
        size: kLayoutMatrix['large_tablet']!,
      );
      expect(tester.getRect(find.byKey(const Key('primary'))).right, 1024);
    });

    testWidgets('narrow tablet portrait keeps one pane', (tester) async {
      await pumpApp(
        tester,
        const AdaptiveTwoPane(primary: _primary, secondary: _secondary),
        size: kLayoutMatrix['tablet']!,
      );
      expect(find.byKey(const Key('secondary')), findsNothing);
    });

    testWidgets('vertical hinge → split exactly at the hinge', (tester) async {
      await pumpApp(
        tester,
        _withFeature(
          const Rect.fromLTWH(500, 0, 0, 1200),
          const AdaptiveTwoPane(primary: _primary, secondary: _secondary),
        ),
        size: const Size(1000, 1200),
        locale: const Locale('en'),
      );
      expect(tester.getRect(find.byKey(const Key('primary'))), const Rect.fromLTWH(0, 0, 500, 1200));
      expect(tester.getRect(find.byKey(const Key('secondary'))).left, 500);
    });

    testWidgets('occluding hinge area stays empty (RTL: primary right of it)', (tester) async {
      await pumpApp(
        tester,
        _withFeature(
          const Rect.fromLTWH(480, 0, 40, 1200),
          const AdaptiveTwoPane(primary: _primary, secondary: _secondary),
        ),
        size: const Size(1000, 1200),
      );
      expect(tester.getRect(find.byKey(const Key('primary'))).left, 520);
      expect(tester.getRect(find.byKey(const Key('secondary'))).right, 480);
    });

    testWidgets('horizontal hinge (tabletop) → stacked around it', (tester) async {
      await pumpApp(
        tester,
        _withFeature(
          const Rect.fromLTWH(0, 600, 1000, 0),
          const AdaptiveTwoPane(primary: _primary, secondary: _secondary),
        ),
        size: const Size(1000, 1200),
      );
      expect(tester.getRect(find.byKey(const Key('primary'))).bottom, 600);
      expect(tester.getRect(find.byKey(const Key('secondary'))).top, 600);
    });
  });

  group('AdaptiveRow', () {
    const row = AdaptiveRow(minRowWidth: 360, children: [Text('label'), Text('value')]);

    testWidgets('row when wide, column when narrow', (tester) async {
      await pumpApp(tester, row);
      expect(find.byType(Row), findsWidgets);
      expect(tester.getTopLeft(find.text('label')).dy, tester.getTopLeft(find.text('value')).dy);

      await pumpApp(tester, row, size: kLayoutMatrix['small_phone']!);
      expect(tester.getTopLeft(find.text('value')).dy, greaterThan(tester.getTopLeft(find.text('label')).dy));
    });

    testWidgets('column when the system text is enlarged', (tester) async {
      await pumpApp(tester, row, textScale: 2.0);
      expect(tester.getTopLeft(find.text('value')).dy, greaterThan(tester.getTopLeft(find.text('label')).dy));
    });
  });
}
