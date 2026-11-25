// GoRouter assembly: app routes + each feature's routes, one pure redirect,
// a StatefulShellRoute for tabs (state kept per tab) and a 404 screen.
//
// Source: baytna lib/app/router/app_router.dart (status-based redirect,
//         refreshListenable, StatefulShellRoute.indexedStack, root/shell keys).
// Merged: markspulse redirect.dart (pure, tested); corsa-customer app_router.dart
//         (errorBuilder not-found page; cold-start deep link via splash `from`).
// To add a feature: put its GoRoutes in `<feature>_routes.dart` and add them to
// a branch (or the root list for full-screen flows) below.
// See docs/ARCHITECTURE.md#routing.
import 'package:go_router/go_router.dart';

import 'core/di/injector.dart';
import 'core/router/app_routes.dart';
import 'core/router/redirect.dart';
import 'core/router/router_refresh_stream.dart';
import 'core/services/app_info_service.dart';
import 'core/session/session_cubit.dart';
import 'features/sample_feature/items_routes.dart';
import 'shared/screens/home_shell.dart';
import 'shared/screens/not_found_screen.dart';
import 'shared/screens/settings_screen.dart';
import 'shared/screens/splash_screen.dart';

const _redirectConfig = RedirectConfig(
  splash: AppRoutes.splash,
  home: AppRoutes.home,
  // signIn: AuthRoutes.signIn,           // when the app gets an auth feature
  // protectedPrefixes: ['/profile'],     // routes that need a session
);

GoRouter buildAppRouter(SessionCubit session) => GoRouter(
  navigatorKey: AppRoutes.rootNavigatorKey,
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  refreshListenable: RouterRefreshStream([session.stream]),
  redirect: (context, state) => computeRedirect(session.state.status, state.uri.toString(), _redirectConfig),
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(navigationShell: shell),
      branches: [
        // Tab 1 — the sample feature lives at '/' (replace with your home).
        StatefulShellBranch(routes: ItemsRoutes.routes(rootNavigatorKey: AppRoutes.rootNavigatorKey)),
        // Tab 2 — settings.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => SettingsScreen(appInfo: getIt<AppInfo>()),
            ),
          ],
        ),
      ],
    ),
  ],
);
