// 404 page for unknown routes / broken deep links, with a way home.
//
// Source: corsa-customer lib/core/app_router/route_builders.dart (RouteErrorScreen from
//         GoRouter.errorBuilder: a real "not found" page with a way home
//         instead of a red error screen for a bad deep link).
// Merged: the shared EmptyView layout + not_found.* texts (new).
// See docs/WIDGETS.md#screens.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/generated/locale_keys.g.dart';
import '../../core/router/app_routes.dart';
import '../widgets/layout/app_scaffold.dart';
import '../widgets/states/empty_view.dart';

/// Shown by `GoRouter.errorBuilder`; the button goes to [AppRoutes.home].
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    body: EmptyView(
      icon: Icons.link_off,
      title: LocaleKeys.not_found_title.tr(),
      message: LocaleKeys.not_found_message.tr(),
      actionLabel: LocaleKeys.not_found_go_home.tr(),
      onAction: () => context.go(AppRoutes.home),
    ),
  );
}
