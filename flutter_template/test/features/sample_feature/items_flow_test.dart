// Widget tests of the items feature through its real routes and screens:
// list → details, deep link by id, debounced search, create with field
// errors → success on top of the list, unsaved-changes guard.
//
// Source: new (ItemsRoutes + screens + cubits over an in-memory repository).
import 'package:app_template/core/di/injector.dart';
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/features/sample_feature/domain/use_cases/create_item_use_case.dart';
import 'package:app_template/features/sample_feature/items_routes.dart';
import 'package:app_template/features/sample_feature/presentation/managers/create_item_cubit.dart';
import 'package:app_template/features/sample_feature/presentation/managers/item_details_cubit.dart';
import 'package:app_template/features/sample_feature/presentation/managers/items_list_cubit.dart';
import 'package:app_template/features/sample_feature/presentation/screens/create_item_screen.dart';
import 'package:app_template/features/sample_feature/presentation/screens/item_details_screen.dart';
import 'package:app_template/features/sample_feature/presentation/widgets/item_tile.dart';
import 'package:app_template/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';
import 'support/fake_items_repository.dart';

void main() {
  late FakeItemsRepository repository;

  setUp(() {
    repository = FakeItemsRepository();
    getIt
      ..registerFactory<ItemsListCubit>(() => ItemsListCubit(repository))
      ..registerFactoryParam<ItemDetailsCubit, String, void>((id, _) => ItemDetailsCubit(repository, id: id))
      ..registerFactory<CreateItemCubit>(() => CreateItemCubit(CreateItemUseCase(repository)));
  });

  tearDown(getIt.reset);

  GoRouter router({String initialLocation = ItemsRoutes.list}) {
    final root = GlobalKey<NavigatorState>();
    return GoRouter(
      navigatorKey: root,
      initialLocation: initialLocation,
      routes: ItemsRoutes.routes(rootNavigatorKey: root),
    );
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Finder submit() => find.widgetWithText(AppButton, 'Add item');

  testWidgets('shows the first page and opens the details of a tapped item', (tester) async {
    await pumpRouterApp(tester, router(), locale: const Locale('en'));

    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Sample item 01'), findsOneWidget);
    expect(find.byType(ItemTile), findsWidgets);

    await tester.tap(find.text('Sample item 02'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailsScreen), findsOneWidget);
    expect(find.text('Sample item 02'), findsWidgets); // app bar + headline
    expect(find.text('Added on'), findsOneWidget);
    expect(find.text(longDescription), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailsScreen), findsNothing);
    expect(find.text('Sample item 01'), findsOneWidget);
  });

  testWidgets('a deep link opens the details by id (no state.extra), unknown ids show the error view', (tester) async {
    await pumpRouterApp(tester, router(initialLocation: ItemsRoutes.details('7')), locale: const Locale('en'));
    expect(find.text('Sample item 07'), findsWidgets);
    expect(find.text('Unknown'), findsOneWidget); // item 7's status in the fake: values[7 % 4]

    await pumpRouterApp(tester, router(initialLocation: ItemsRoutes.details('999')), locale: const Locale('en'));
    expect(find.text("We couldn't find what you were looking for."), findsOneWidget);
  });

  testWidgets('search waits 400 ms after typing, then shows only the matches', (tester) async {
    await pumpRouterApp(tester, router(), locale: const Locale('en'));
    final callsBefore = repository.pageCalls.length;

    await tester.enterText(find.byType(TextField).first, 'item 1');
    await tester.pump(const Duration(milliseconds: 399));
    expect(repository.pageCalls.length, callsBefore);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(repository.pageCalls.last, (page: 1, query: 'item 1'));
    expect(find.text('Sample item 10'), findsOneWidget);
    expect(find.text('Sample item 02'), findsNothing);
  });

  testWidgets('create: required, domain and server field errors, then success on top of the list', (tester) async {
    await pumpRouterApp(tester, router(), locale: const Locale('en'));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(CreateItemScreen), findsOneWidget);
    expect(find.text('New item'), findsOneWidget);

    // Client validator.
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('This field is required.'), findsOneWidget);

    // Domain rule from the use case, shown under the title.
    await tester.enterText(field('Title'), 'ab');
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('Use at least 3 characters for the title.'), findsOneWidget);
    expect(repository.created, isEmpty);

    // Server-side 422.
    // A frame passes between typing and tapping (the edit hides the old
    // server error, which would otherwise still block validation).
    await tester.enterText(field('Title'), 'taken');
    await tester.pump();
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('This title is already used'), findsOneWidget);

    // Success: snackbar, pop with the item, item on top of the list.
    await tester.enterText(field('Title'), '  Brand new item ');
    await tester.enterText(field('Description'), 'Made in a test');
    await tester.pump();
    await tester.tap(submit());
    await tester.pumpAndSettle();

    expect(find.byType(CreateItemScreen), findsNothing);
    expect(find.text('Item added.'), findsOneWidget);
    expect(repository.created.single.title, 'Brand new item');
    final firstTile = tester.widget<ItemTile>(find.byType(ItemTile).first);
    expect(firstTile.item.title, 'Brand new item');
  });

  testWidgets('leaving an edited form asks first; Discard closes it', (tester) async {
    await pumpRouterApp(tester, router(initialLocation: ItemsRoutes.create), locale: const Locale('en'));

    await tester.enterText(field('Title'), 'Draft');
    await tester.pump();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateItemScreen), findsOneWidget);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateItemScreen), findsNothing);
    expect(find.text('Sample item 01'), findsOneWidget);
  });

  testWidgets('a failed refresh keeps the list and shows a snackbar', (tester) async {
    await pumpRouterApp(tester, router(), locale: const Locale('en'));
    repository.failNext = const ServerFailure();

    await tester.fling(find.byType(ItemTile).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Sample item 01'), findsOneWidget);
    expect(find.text('Something went wrong on our side. Please try again.'), findsOneWidget);
  });
}
