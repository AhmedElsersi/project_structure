// Layout matrix: the sample feature's screens and the tab shell must render
// without overflow at every kLayoutMatrix size × system text scale {1.0, 2.0}
// × locale {ar, en}.
//
// Source: chinaparts-customer test/core/adaptive_surfaces_matrix_test.dart
//         (size × text-scale matrix, `tester.takeException()` is null).
// Merged: corsa-customer test/helpers/pump_at_scale.dart (sizes × scales ×
//         locales through one pump helper) — here test/helpers/pump_app.dart,
//         which applies the app's damped text scaler like lib/app.dart.
// See docs/CONVENTIONS.md#text-scaling.
import 'package:app_template/core/di/injector.dart';
import 'package:app_template/core/router/app_routes.dart';
import 'package:app_template/features/sample_feature/domain/entities/create_item_input.dart';
import 'package:app_template/features/sample_feature/domain/entities/item.dart';
import 'package:app_template/features/sample_feature/domain/use_cases/create_item_use_case.dart';
import 'package:app_template/features/sample_feature/items_routes.dart';
import 'package:app_template/features/sample_feature/presentation/managers/create_item_cubit.dart';
import 'package:app_template/features/sample_feature/presentation/managers/item_details_cubit.dart';
import 'package:app_template/features/sample_feature/presentation/managers/items_list_cubit.dart';
import 'package:app_template/features/sample_feature/presentation/screens/create_item_screen.dart';
import 'package:app_template/features/sample_feature/presentation/screens/item_details_screen.dart';
import 'package:app_template/features/sample_feature/presentation/screens/items_list_screen.dart';
import 'package:app_template/shared/screens/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/sample_feature/support/fake_items_repository.dart';
import '../helpers/pump_app.dart';

const _scales = [1.0, 2.0];
const _locales = [Locale('ar'), Locale('en')];

/// A repository whose first items have long titles / descriptions and every
/// status, so tiles and chips are stressed.
FakeItemsRepository _repository() {
  final repository = FakeItemsRepository();
  repository.items
    ..[0] = sampleItem(1, title: longTitle, description: longDescription, status: ItemStatus.archived)
    ..[1] = sampleItem(2, title: longTitle, status: ItemStatus.unknown)
    ..[2] = sampleItem(3, description: longDescription, status: ItemStatus.active);
  return repository;
}

/// The real tab shell (bar on phones, rail on tablets) with the items branch.
GoRouter _shellRouter({String initialLocation = ItemsRoutes.list}) {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: ItemsRoutes.routes(rootNavigatorKey: root)),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.settings, builder: (context, state) => const SizedBox.shrink())],
          ),
        ],
      ),
    ],
  );
}

void main() {
  late FakeItemsRepository repository;

  setUp(() {
    repository = _repository();
    getIt
      ..registerFactory<ItemsListCubit>(() => ItemsListCubit(repository))
      ..registerFactoryParam<ItemDetailsCubit, String, void>((id, _) => ItemDetailsCubit(repository, id: id))
      ..registerFactory<CreateItemCubit>(() => CreateItemCubit(CreateItemUseCase(repository)));
  });

  tearDown(getIt.reset);

  /// Runs [body] once per size × scale × locale.
  void matrix(String screen, Future<void> Function(WidgetTester tester, Size size, double scale, Locale locale) body) {
    for (final size in kLayoutMatrix.entries) {
      for (final scale in _scales) {
        for (final locale in _locales) {
          testWidgets('$screen at ${size.key} ×$scale ${locale.languageCode}', (tester) async {
            await body(tester, size.value, scale, locale);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  matrix('ItemsListScreen', (tester, size, scale, locale) async {
    await pumpApp(
      tester,
      BlocProvider(create: (_) => ItemsListCubit(repository)..loadFirstPage(), child: const ItemsListScreen()),
      size: size,
      textScale: scale,
      locale: locale,
      wrapInScaffold: false,
    );
    expect(find.byType(ItemsListScreen), findsOneWidget);
    // Scroll to the end to lay out more tiles (and the load-more footer).
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();
  });

  matrix('ItemDetailsScreen', (tester, size, scale, locale) async {
    await pumpApp(
      tester,
      BlocProvider(
        create: (_) => ItemDetailsCubit(repository, id: '1')..load(),
        child: const ItemDetailsScreen(id: '1'),
      ),
      size: size,
      textScale: scale,
      locale: locale,
      wrapInScaffold: false,
    );
    expect(find.text(longDescription), findsOneWidget);
  });

  matrix('CreateItemScreen (with field errors)', (tester, size, scale, locale) async {
    final cubit = CreateItemCubit(CreateItemUseCase(repository));
    addTearDown(cubit.close);
    // Server-side 422 on the title before the screen is built.
    await tester.runAsync(() => cubit.submit(const CreateItemInput(title: 'taken')));
    await pumpApp(
      tester,
      BlocProvider.value(value: cubit, child: const CreateItemScreen()),
      size: size,
      textScale: scale,
      locale: locale,
      wrapInScaffold: false,
    );
    expect(find.text('This title is already used'), findsOneWidget);
  });

  matrix('HomeShell + items list', (tester, size, scale, locale) async {
    await pumpRouterApp(tester, _shellRouter(), size: size, textScale: scale, locale: locale);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(ItemsListScreen), findsOneWidget);
  });

  matrix('HomeShell + item details', (tester, size, scale, locale) async {
    await pumpRouterApp(
      tester,
      _shellRouter(initialLocation: ItemsRoutes.details('1')),
      size: size,
      textScale: scale,
      locale: locale,
    );
    expect(find.byType(ItemDetailsScreen), findsOneWidget);
    // Image and info are both visible in every layout (stacked or two panes).
    expect(find.text(longDescription), findsOneWidget);
  });
}
