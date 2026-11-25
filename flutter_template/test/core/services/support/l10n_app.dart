// Test harness: pumps a themed MaterialApp with the real en/ar translations.
//
// Source: new (same loading pattern as test/core/errors/failure_l10n_test.dart:
//         asset I/O runs outside the fake-async zone, then pumpAndSettle).
import 'package:app_template/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Call from `setUpAll`.
Future<void> setUpL10n() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
}

/// Pumps `MaterialApp(home: home, builder: builder)` under EasyLocalization
/// and waits for the translations. [wrap] goes above MaterialApp (providers).
Future<void> pumpL10nApp(
  WidgetTester tester, {
  Widget home = const Scaffold(body: SizedBox.shrink()),
  TransitionBuilder? builder,
  Widget Function(Widget app)? wrap,
  Locale locale = const Locale('en'),
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'assets/translations',
        startLocale: locale,
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        useOnlyLangCode: true,
        child: Builder(
          builder: (context) {
            final app = MaterialApp(
              navigatorKey: navigatorKey,
              theme: AppTheme.light(),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              builder: builder,
              home: home,
            );
            return wrap == null ? app : wrap(app);
          },
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}
