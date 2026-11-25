// DI registrations of the sample feature (called from main.dart's modules).
//
// Source: corsa-customer lib/core/services/features_di.dart (one registration
//         function per feature; lazySingleton for data sources, repositories
//         and use cases, factory for cubits).
// Merged: corsa-driver mock_route_table.dart (the feature registers its own
//         mock endpoints); chinaparts-customer notification_link_handler.dart
//         (each feature maps its notification type to a route).
// See docs/ARCHITECTURE.md#dependency-injection.
import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/network/mock/mock_interceptor.dart';
import '../../core/services/push/notification_link_resolver.dart';
import 'data/data_sources/items_remote_data_source.dart';
import 'data/mock/items_mock_api.dart';
import 'data/repositories/items_repository_impl.dart';
import 'domain/repositories/items_repository.dart';
import 'domain/use_cases/create_item_use_case.dart';
import 'items_routes.dart';
import 'presentation/managers/create_item_cubit.dart';
import 'presentation/managers/item_details_cubit.dart';
import 'presentation/managers/items_list_cubit.dart';

/// Registers the items feature. Needs `registerCoreDependencies()` first.
Future<void> registerItemsFeature() async {
  getIt
    // Data + domain: one instance for the whole app.
    ..registerLazySingleton<ItemsRemoteDataSource>(() => ItemsRemoteDataSource(getIt<ApiClient>()))
    ..registerLazySingleton<ItemsRepository>(() => ItemsRepositoryImpl(getIt<ItemsRemoteDataSource>()))
    ..registerLazySingleton<CreateItemUseCase>(() => CreateItemUseCase(getIt<ItemsRepository>()))
    // Cubits: a fresh one per screen (closed by its BlocProvider).
    ..registerFactory<ItemsListCubit>(() => ItemsListCubit(getIt<ItemsRepository>()))
    ..registerFactoryParam<ItemDetailsCubit, String, void>(
      (id, _) => ItemDetailsCubit(getIt<ItemsRepository>(), id: id),
    )
    ..registerFactory<CreateItemCubit>(() => CreateItemCubit(getIt<CreateItemUseCase>()));

  // USE_MOCKS builds: answer /items from assets/mocks/items.json.
  if (getIt.isRegistered<MockInterceptor>()) registerItemsMockApi(getIt<MockInterceptor>());

  // Push payload `{"type": "item", "id": 5}` opens the item.
  if (getIt.isRegistered<NotificationLinkResolver>()) {
    getIt<NotificationLinkResolver>().register('item', (payload) {
      final id = payload['id'];
      return id == null || '$id'.trim().isEmpty ? null : ItemsRoutes.details('$id');
    });
  }
}
