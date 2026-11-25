// App-level route paths and navigator keys. Feature routes live in each
// feature (e.g. features/sample_feature/items_routes.dart).
//
// Source: baytna lib/app/router/routes.dart (path constants + typed builders),
//         brgr root_navigator_key.dart (root key for context-free navigation).
// Rule: pass IDs in the path, never objects in `extra` (deep-link safe; the
//       `state.extra as X` casts in 10 of 12 projects crash on restore).
import 'package:flutter/widgets.dart';

abstract final class AppRoutes {
  static const splash = '/splash';

  /// First tab of the shell. app_router.dart decides which screen it shows.
  static const home = '/';
  static const settings = '/settings';

  /// Root navigator: dialogs above the shell and context-free navigation.
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
}
