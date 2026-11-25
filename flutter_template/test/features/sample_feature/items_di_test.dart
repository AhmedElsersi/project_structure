// Tests for registerItemsFeature(): registrations, mock API wiring and the
// `item` notification link.
//
// Source: new.
import 'dart:io';

import 'package:app_template/core/di/injector.dart';
import 'package:app_template/core/logging/app_logger.dart';
import 'package:app_template/core/network/api_client.dart';
import 'package:app_template/core/network/mock/mock_interceptor.dart';
import 'package:app_template/core/services/push/notification_link_resolver.dart';
import 'package:app_template/core/storage/auth_token_store.dart';
import 'package:app_template/core/storage/secure_store.dart';
import 'package:app_template/features/sample_feature/domain/repositories/items_repository.dart';
import 'package:app_template/features/sample_feature/domain/use_cases/create_item_use_case.dart';
import 'package:app_template/features/sample_feature/items_di.dart';
import 'package:app_template/features/sample_feature/presentation/managers/create_item_cubit.dart';
import 'package:app_template/features/sample_feature/presentation/managers/item_details_cubit.dart';
import 'package:app_template/features/sample_feature/presentation/managers/items_list_cubit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(Uint8List.fromList(File(key).readAsBytesSync()));
}

void main() {
  tearDown(getIt.reset);

  void registerCore({bool withMocks = true, bool withResolver = true}) {
    final mock = MockInterceptor(latency: Duration.zero, bundle: _DiskBundle());
    if (withMocks) getIt.registerSingleton<MockInterceptor>(mock);
    if (withResolver) getIt.registerSingleton<NotificationLinkResolver>(NotificationLinkResolver());
    getIt.registerSingleton<ApiClient>(
      ApiClient(
        baseUrl: 'https://mock.local/api',
        tokens: AuthTokenStore(MemorySecureStore()),
        logger: AppLogger(enabled: false),
        languageCode: () => 'en',
        appHeaders: () => const {},
        onSessionExpired: () {},
        onAppStatus: (_, _) {},
        mock: withMocks ? mock : null,
      ),
    );
  }

  test('registers singletons for data/domain and fresh cubits per screen', () async {
    registerCore();
    await registerItemsFeature();

    expect(identical(getIt<ItemsRepository>(), getIt<ItemsRepository>()), isTrue);
    expect(identical(getIt<CreateItemUseCase>(), getIt<CreateItemUseCase>()), isTrue);
    final a = getIt<ItemsListCubit>();
    final b = getIt<ItemsListCubit>();
    expect(identical(a, b), isFalse);
    final details = getIt<ItemDetailsCubit>(param1: '5');
    expect(details.id, '5');
    final create = getIt<CreateItemCubit>();
    for (final cubit in [a, b, details, create]) {
      await cubit.close();
    }
  });

  test('USE_MOCKS: the mock API answers /items', () async {
    registerCore();
    await registerItemsFeature();
    final page = (await getIt<ItemsRepository>().fetchPage(1)).valueOrNull;
    expect(page?.items, hasLength(15));
  });

  test('maps {"type": "item", "id": ...} notifications to the details route', () async {
    registerCore();
    await registerItemsFeature();
    final resolver = getIt<NotificationLinkResolver>();
    expect(resolver.resolve({'type': 'item', 'id': 5}), '/items/5');
    expect(resolver.resolve({'type': 'ITEM', 'id': 'a b'}), '/items/a%20b');
    expect(resolver.resolve({'type': 'item'}), isNull); // incomplete → fallback (none set)
  });

  test('works without the mock interceptor or the resolver registered', () async {
    registerCore(withMocks: false, withResolver: false);
    await registerItemsFeature();
    expect(getIt.isRegistered<ItemsRepository>(), isTrue);
  });
}
