// Routes of the sample feature: list at '/', create above the shell, details
// by id in the path.
//
// Source: baytna lib/app/router/routes.dart (path constants + typed location
//         builders; IDs in the path so deep links and state restoration work).
// Merged: corsa-customer lib/core/app_router/auth_routes.dart (cubits created
//         in the route builder with BlocProvider, so each screen owns its
//         cubit's lifetime).
// Rule: never pass objects through `state.extra` (the `extra as X` casts crash
//       on deep links and restoration) — pass the id and load.
// See docs/ARCHITECTURE.md#routing.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injector.dart';
import 'presentation/managers/create_item_cubit.dart';
import 'presentation/managers/item_details_cubit.dart';
import 'presentation/managers/items_list_cubit.dart';
import 'presentation/screens/create_item_screen.dart';
import 'presentation/screens/item_details_screen.dart';
import 'presentation/screens/items_list_screen.dart';

abstract final class ItemsRoutes {
  /// The list (first tab of the shell).
  static const list = '/';

  /// Full-screen form above the shell (no navigation bar).
  static const create = '/items/new';

  /// Details of item [id].
  static String details(String id) => '/items/${Uri.encodeComponent(id)}';

  /// The routes to put in a shell branch (see app_router.dart).
  static List<RouteBase> routes({required GlobalKey<NavigatorState> rootNavigatorKey}) => [
    GoRoute(
      path: list,
      builder: (context, state) =>
          BlocProvider(create: (_) => getIt<ItemsListCubit>()..loadFirstPage(), child: const ItemsListScreen()),
      routes: [
        // Before `items/:id`, so "new" is never read as an id.
        GoRoute(
          path: 'items/new',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => MaterialPage<void>(
            key: state.pageKey,
            fullscreenDialog: true,
            child: BlocProvider(create: (_) => getIt<CreateItemCubit>(), child: const CreateItemScreen()),
          ),
        ),
        GoRoute(
          path: 'items/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BlocProvider(
              create: (_) => getIt<ItemDetailsCubit>(param1: id)..load(),
              child: ItemDetailsScreen(id: id),
            );
          },
        ),
      ],
    ),
  ];
}
