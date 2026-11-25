// Shared widget-test harness: real translations (EasyLocalization), the app
// theme, the damped text scaler and a chosen window size / locale.
//
// Source: new (mirrors lib/app.dart's MaterialApp.builder so widgets are tested
//         under the same text scale, form-factor typography and RTL as the app).
// Merged: chinaparts-customer / markspulse test helpers idea (one pump helper,
//         a size matrix for phones, tablets and landscape).
// Usage:
//   await pumpApp(tester, const MyWidget(), locale: const Locale('en'), size: kLayoutMatrix['tablet']!);
//   await pumpApp(tester, const LoadingThing(), settle: false); // infinite animations
import 'package:app_template/core/localization/app_languages.dart';
import 'package:app_template/core/responsive/app_text_scale.dart';
import 'package:app_template/core/responsive/breakpoints.dart';
import 'package:app_template/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Window sizes every layout should survive (logical pixels).
const Map<String, Size> kLayoutMatrix = {
  'small_phone': Size(320, 640),
  'phone': Size(393, 852),
  'tablet': Size(600, 960),
  'large_tablet': Size(1024, 1366),
  'landscape_phone': Size(852, 393),
};

bool _localizationReady = false;

Future<void> _ensureLocalization() async {
  if (_localizationReady) return;
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
  _localizationReady = true;
}

/// Pumps [child] inside the app's localization + theme.
///
/// * [locale]: `ar` (RTL, default) or `en`.
/// * [size]: the window size; devicePixelRatio is [devicePixelRatio].
/// * [textScale]: the SYSTEM font scale; the app's damped scaler
///   (`AppTextScale.wrap`) is applied on top, exactly like `lib/app.dart`.
/// * [wrapInScaffold]: puts [child] in a `Scaffold` body (TextFields,
///   SnackBars and Material ink need one). Pass false for full screens.
/// * [wrap]: wraps the whole app, e.g. with `BlocProvider`s.
/// * [scaffoldMessengerKey]: e.g. `AppSnackBar.messengerKey` for context-free
///   snackbars.
/// * [settle]: `pumpAndSettle` at the end; pass false when [child] animates
///   forever (spinners, skeletons) — the helper then pumps a few frames.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('ar'),
  Size size = const Size(393, 852),
  double textScale = 1.0,
  ThemeMode themeMode = ThemeMode.light,
  double devicePixelRatio = 1.0,
  bool wrapInScaffold = true,
  Widget Function(Widget app)? wrap,
  GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  bool settle = true,
}) => _pump(
  tester,
  locale: locale,
  size: size,
  textScale: textScale,
  devicePixelRatio: devicePixelRatio,
  wrap: wrap,
  settle: settle,
  app: (context, builder) => MaterialApp(
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: scaffoldMessengerKey,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    locale: context.locale,
    supportedLocales: context.supportedLocales,
    localizationsDelegates: context.localizationDelegates,
    builder: builder,
    home: wrapInScaffold ? Scaffold(body: child) : child,
  ),
);

/// Like [pumpApp] but with a [GoRouter] (screens that call `context.go`).
Future<void> pumpRouterApp(
  WidgetTester tester,
  GoRouter router, {
  Locale locale = const Locale('ar'),
  Size size = const Size(393, 852),
  double textScale = 1.0,
  ThemeMode themeMode = ThemeMode.light,
  double devicePixelRatio = 1.0,
  Widget Function(Widget app)? wrap,
  bool settle = true,
}) {
  addTearDown(router.dispose);
  return _pump(
    tester,
    locale: locale,
    size: size,
    textScale: textScale,
    devicePixelRatio: devicePixelRatio,
    wrap: wrap,
    settle: settle,
    app: (context, builder) => MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      builder: builder,
      routerConfig: router,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget Function(BuildContext context, TransitionBuilder builder) app,
  required Locale locale,
  required Size size,
  required double textScale,
  required double devicePixelRatio,
  required Widget Function(Widget app)? wrap,
  required bool settle,
}) async {
  await _ensureLocalization();
  // rootBundle caches loadString FUTURES; one created in a previous test's
  // fake-async zone never completes in this one, so start clean.
  rootBundle.clear();

  tester.view
    ..devicePixelRatio = devicePixelRatio
    ..physicalSize = size * devicePixelRatio;
  addTearDown(tester.view.reset);

  // Same as lib/app.dart's MaterialApp.builder, below a MediaQuery that plays
  // the SYSTEM font scale so the damped scaler is exercised.
  Widget builder(BuildContext context, Widget? child) {
    final system = MediaQuery.of(context);
    return MediaQuery(
      data: system.copyWith(textScaler: TextScaler.linear(textScale)),
      child: Builder(
        builder: (context) => AppTextScale.wrap(
          context,
          Builder(
            builder: (context) => Theme(
              data: AppTheme.adaptTo(Theme.of(context), context.formFactor),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  final Widget root = EasyLocalization(
    // Fresh state per call: a second pumpApp in one test may switch locale.
    key: UniqueKey(),
    supportedLocales: AppLanguages.supportedLocales,
    path: AppLanguages.translationsPath,
    startLocale: locale,
    fallbackLocale: AppLanguages.fallbackLocale,
    saveLocale: false,
    useOnlyLangCode: true,
    child: Builder(builder: (context) => app(context, builder)),
  );

  await tester.pumpWidget(wrap == null ? root : wrap(root));
  // Translations load asynchronously; give them a few frames.
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
  if (settle) await tester.pumpAndSettle();
}
