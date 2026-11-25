// Registers the app services (connectivity, URLs, permissions, image picker,
// push + link resolver, app config gate). Call after registerCoreDependencies.
//
// Source: corsa-customer lib/core/services/di_container.dart (one awaited
//         registration function per module; lazySingleton for services,
//         singletons for app-wide cubits; no platform calls inside factories).
// Merged: corsa-driver mock_route_table.dart (fixtures registered next to the
//         module that owns the endpoint).
// See docs/ARCHITECTURE.md#dependency-injection.
import 'dart:async';

import '../app_config/app_config_cubit.dart';
import '../app_config/app_config_repository.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/app_status_bus.dart';
import '../network/mock/mock_interceptor.dart';
import '../services/app_info_service.dart';
import '../services/connectivity/connectivity_cubit.dart';
import '../services/connectivity/connectivity_service.dart';
import '../services/image_picker_service.dart';
import '../services/permission_service.dart';
import '../services/push/notification_link_resolver.dart';
import '../services/push/push_service.dart';
import '../services/url_service.dart';
import '../storage/key_value_store.dart';
import 'injector.dart';

/// Mock fixture for `GET /app-config` (no maintenance, build 1 everywhere).
const String appConfigMockAsset = 'assets/mocks/app_config.json';

/// Registers the services module. Overrides are for tests.
///
/// [startConnectivity] starts DNS polling in the background (not awaited).
Future<void> registerServicesModule({
  ConnectivityService? connectivityService,
  PermissionService? permissionService,
  PushService? pushService,
  UrlService? urlService,
  bool startConnectivity = true,
}) async {
  final connectivity = connectivityService ?? ConnectivityService();
  getIt
    ..registerSingleton<ConnectivityService>(connectivity, dispose: (s) => s.dispose())
    ..registerSingleton<ConnectivityCubit>(ConnectivityCubit(connectivity), dispose: (c) => c.close())
    ..registerLazySingleton<UrlService>(() => urlService ?? UrlService())
    ..registerLazySingleton<PermissionService>(() => permissionService ?? const PermissionHandlerService())
    ..registerLazySingleton<ImagePickerService>(ImagePickerService.new)
    ..registerLazySingleton<PushService>(() => pushService ?? NoopPushService())
    ..registerLazySingleton<NotificationLinkResolver>(NotificationLinkResolver.new)
    ..registerLazySingleton<PendingLink>(PendingLink.new)
    ..registerLazySingleton<AppConfigRepository>(
      () => AppConfigRepositoryImpl(getIt<ApiClient>(), getIt<KeyValueStore>()),
    );

  final appInfo = getIt<AppInfo>();
  getIt.registerSingleton<AppConfigCubit>(
    AppConfigCubit(
      repository: getIt<AppConfigRepository>(),
      statusBus: getIt<AppStatusBus>(),
      store: getIt<KeyValueStore>(),
      installedBuild: appInfo.buildNumber,
      platform: appInfo.platform,
    ),
    dispose: (c) => c.close(),
  );

  if (getIt.isRegistered<MockInterceptor>()) {
    getIt<MockInterceptor>().serveAsset(ApiEndpoints.appConfig, appConfigMockAsset);
  }

  if (startConnectivity) unawaited(connectivity.start());
}
