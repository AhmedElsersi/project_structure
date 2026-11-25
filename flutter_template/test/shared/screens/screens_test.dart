// App screens: settings (language + theme + version) across the layout
// matrix, not-found navigation home, home shell tab switching, splash and the
// pre-localization config error app.
//
// Source: new (tests for lib/shared/screens/*).
import 'package:app_template/core/services/app_info_service.dart';
import 'package:app_template/core/storage/key_value_store.dart';
import 'package:app_template/core/theme/theme_cubit.dart';
import 'package:app_template/shared/screens/config_error_app.dart';
import 'package:app_template/shared/screens/home_shell.dart';
import 'package:app_template/shared/screens/not_found_screen.dart';
import 'package:app_template/shared/screens/settings_screen.dart';
import 'package:app_template/shared/screens/splash_screen.dart';
import 'package:app_template/shared/widgets/layout/adaptive_navigation_shell.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';

const _info = AppInfo(version: '1.2.3', buildNumber: 45, packageName: 'com.example.app', platform: 'android');

void main() {
  group('SettingsScreen', () {
    late ThemeCubit themeCubit;

    setUp(() => themeCubit = ThemeCubit(MemoryKeyValueStore()));
    tearDown(() => themeCubit.close());

    Widget provide(Widget app) => BlocProvider<ThemeCubit>.value(value: themeCubit, child: app);

    for (final entry in kLayoutMatrix.entries) {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        testWidgets('lays out at ${entry.key} (${locale.languageCode}, largest text)', (tester) async {
          await pumpApp(
            tester,
            const SettingsScreen(appInfo: _info),
            size: entry.value,
            locale: locale,
            textScale: 2.0,
            wrapInScaffold: false,
            wrap: provide,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('العربية'), findsOneWidget);
          expect(find.text('English'), findsOneWidget);
          expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
        });
      }
    }

    testWidgets('theme selector drives ThemeCubit; version shows version+build', (tester) async {
      await pumpApp(
        tester,
        const SettingsScreen(appInfo: _info),
        locale: const Locale('en'),
        wrapInScaffold: false,
        wrap: provide,
      );
      expect(find.textContaining('1.2.3+45'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(themeCubit.state, ThemeMode.dark);
    });

    testWidgets('language selector switches the locale', (tester) async {
      await pumpApp(
        tester,
        const SettingsScreen(appInfo: _info),
        locale: const Locale('en'),
        wrapInScaffold: false,
        wrap: provide,
      );
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(SettingsScreen)).locale, const Locale('ar'));
      expect(find.text('الإعدادات'), findsOneWidget);
    });
  });

  testWidgets('NotFoundScreen button goes home', (tester) async {
    final router = GoRouter(
      initialLocation: '/missing',
      routes: [GoRoute(path: '/', builder: (_, _) => const Text('home page'))],
      errorBuilder: (_, _) => const NotFoundScreen(),
    );
    await pumpRouterApp(tester, router, locale: const Locale('en'));
    expect(find.text('Page not found'), findsOneWidget);

    await tester.tap(find.text('Go to home'));
    await tester.pumpAndSettle();
    expect(find.text('home page'), findsOneWidget);
  });

  testWidgets('HomeShell switches tabs and shows the adaptive shell', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => HomeShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/', builder: (_, _) => const Text('home tab'))],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/settings', builder: (_, _) => const Text('settings tab'))],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, locale: const Locale('en'));
    expect(find.byType(AdaptiveNavigationShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('home tab'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('settings tab'), findsOneWidget);
  });

  testWidgets('SplashScreen has no text', (tester) async {
    await pumpApp(tester, const SplashScreen(), wrapInScaffold: false, settle: false);
    expect(find.byType(FlutterLogo), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('ConfigErrorApp shows Arabic and English without localization', (tester) async {
    await tester.pumpWidget(const ConfigErrorApp(details: 'BASE_URL is empty'));
    expect(find.text('التطبيق غير مُهيّأ'), findsOneWidget);
    expect(find.text('App not configured'), findsOneWidget);
    expect(find.text('BASE_URL is empty'), findsOneWidget); // tests run in debug mode
    expect(Directionality.of(tester.element(find.text('التطبيق غير مُهيّأ'))), TextDirection.rtl);
  });
}
