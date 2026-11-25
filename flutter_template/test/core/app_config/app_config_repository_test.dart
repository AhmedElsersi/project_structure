// Tests for lib/core/app_config/app_config_repository.dart. Source: new
//
// Real ApiClient + MockInterceptor (latency zero), MemoryKeyValueStore.
import 'package:app_template/core/app_config/app_config.dart';
import 'package:app_template/core/app_config/app_config_repository.dart';
import 'package:app_template/core/di/services_module.dart';
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/logging/app_logger.dart';
import 'package:app_template/core/network/api_client.dart';
import 'package:app_template/core/network/api_endpoints.dart';
import 'package:app_template/core/network/mock/mock_interceptor.dart';
import 'package:app_template/core/result/result.dart';
import 'package:app_template/core/storage/auth_token_store.dart';
import 'package:app_template/core/storage/key_value_store.dart';
import 'package:app_template/core/storage/secure_store.dart';
import 'package:app_template/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockInterceptor mock;
  late MemoryKeyValueStore store;
  late AppConfigRepositoryImpl repo;

  setUp(() {
    mock = MockInterceptor(latency: Duration.zero);
    store = MemoryKeyValueStore();
    final api = ApiClient(
      baseUrl: 'https://mock.local/api',
      tokens: AuthTokenStore(MemorySecureStore()),
      logger: AppLogger(enabled: false),
      languageCode: () => 'en',
      appHeaders: () => const {},
      onSessionExpired: () {},
      onAppStatus: (_, _) {},
      mock: mock,
    );
    repo = AppConfigRepositoryImpl(api, store);
  });

  test('the bundled mock asset parses and never gates', () async {
    mock.serveAsset(ApiEndpoints.appConfig, appConfigMockAsset);
    final result = await repo.fetch();
    final config = result.valueOrNull!;
    expect(config.maintenance, isFalse);
    expect(config.android?.minBuild, 1);
    expect(config.android?.latestBuild, 1);
    expect(config.ios?.latestBuild, 1);
  });

  test('a successful fetch is cached and readable later', () async {
    mock.on(
      'GET',
      ApiEndpoints.appConfig,
      (_, _) async => const MockResponse({
        'maintenance': false,
        'android': {'min_build': 2, 'latest_build': 5},
      }),
    );
    expect(repo.cached(), isNull);
    await repo.fetch();
    expect(store.containsKey(StorageKeys.appConfigCache), isTrue);
    expect(repo.cached()?.android, const PlatformUpdatePolicy(minBuild: 2, latestBuild: 5));
  });

  test('a non-object body is a ServerFailure and leaves the cache alone', () async {
    await store.setJson(StorageKeys.appConfigCache, const AppConfig(maintenance: true).toJson());
    mock.on('GET', ApiEndpoints.appConfig, (_, _) async => const MockResponse('<html>oops</html>'));
    final result = await repo.fetch();
    expect(result, isA<Err<AppConfig>>());
    expect(result.failureOrNull, isA<ServerFailure>());
    expect(repo.cached()?.maintenance, isTrue);
  });

  test('a corrupt cache reads as null', () async {
    await store.setString(StorageKeys.appConfigCache, '{not json');
    expect(repo.cached(), isNull);
  });
}
