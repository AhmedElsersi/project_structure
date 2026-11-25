// Fetches the app config through ApiClient and caches the last good copy.
// The cache is informational: it may drive the optional prompt after a failed
// fetch, never a forced update or maintenance on its own.
//
// Source: chinaparts-customer lib/features/app_config/data/repositories/
//         app_config_repository.dart (thin pass-through; the decision lives in
//         the cubit) + app_config_cubit.dart _cacheConfig / _hydrateFromCache
//         (best-effort cache; a corrupt cache is ignored, never fatal).
// See docs/SERVICES.md#app-config.
import '../data/repository_guard.dart';
import '../errors/failure.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../result/result.dart';
import '../storage/key_value_store.dart';
import '../storage/storage_keys.dart';
import 'app_config.dart';

abstract interface class AppConfigRepository {
  /// Live config from the backend (cached on success).
  Future<Result<AppConfig>> fetch();

  /// Last config that was fetched successfully, if any.
  AppConfig? cached();
}

class AppConfigRepositoryImpl with RepositoryGuard implements AppConfigRepository {
  AppConfigRepositoryImpl(this._api, this._store);

  final ApiClient _api;
  final KeyValueStore _store;

  @override
  Future<Result<AppConfig>> fetch() => guard(() async {
    final config = await _api.get<AppConfig>(ApiEndpoints.appConfig, parser: _parse);
    try {
      await _store.setJson(StorageKeys.appConfigCache, config.toJson());
    } on Object {
      // Caching is best-effort; it must not fail the fetch.
    }
    return config;
  });

  @override
  AppConfig? cached() {
    try {
      return AppConfig.tryParse(_store.getJson(StorageKeys.appConfigCache));
    } on Object {
      return null;
    }
  }

  static AppConfig _parse(Object? json) =>
      AppConfig.tryParse(json) ?? (throw const ServerFailure(debugMessage: 'app-config: body is not an object'));
}
