// Tests for lib/core/di/services_module.dart: registrations resolve and the
// mock /app-config fixture drives the gate to "none". Source: new
import 'package:app_template/core/app_config/app_config_cubit.dart';
import 'package:app_template/core/app_config/app_config_repository.dart';
import 'package:app_template/core/app_config/update_policy.dart';
import 'package:app_template/core/di/injector.dart';
import 'package:app_template/core/di/services_module.dart';
import 'package:app_template/core/network/mock/mock_interceptor.dart';
import 'package:app_template/core/services/app_info_service.dart';
import 'package:app_template/core/services/connectivity/connectivity_cubit.dart';
import 'package:app_template/core/services/connectivity/connectivity_service.dart';
import 'package:app_template/core/services/image_picker_service.dart';
import 'package:app_template/core/services/permission_service.dart';
import 'package:app_template/core/services/push/notification_link_resolver.dart';
import 'package:app_template/core/services/push/push_service.dart';
import 'package:app_template/core/services/url_service.dart';
import 'package:app_template/core/storage/key_value_store.dart';
import 'package:app_template/core/storage/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await registerCoreDependencies(
      keyValueStore: MemoryKeyValueStore(),
      secureStore: MemorySecureStore(),
      appInfo: const AppInfo(version: '1.0.0', buildNumber: 1, packageName: 'com.example.app', platform: 'android'),
    );
    await registerServicesModule(
      connectivityService: ConnectivityService(probe: () async => true, listenToLifecycle: false),
      startConnectivity: false,
    );
  });

  tearDown(resetDependencies);

  test('every service resolves', () {
    expect(getIt<ConnectivityService>(), isA<ConnectivityService>());
    expect(getIt<ConnectivityCubit>().state, ConnectivityStatus.online);
    expect(getIt<UrlService>(), isA<UrlService>());
    expect(getIt<PermissionService>(), isA<PermissionHandlerService>());
    expect(getIt<ImagePickerService>(), isA<ImagePickerService>());
    expect(getIt<PushService>(), isA<NoopPushService>());
    expect(getIt<NotificationLinkResolver>(), same(getIt<NotificationLinkResolver>()));
    expect(getIt<PendingLink>(), same(getIt<PendingLink>()));
    expect(getIt<AppConfigRepository>(), isA<AppConfigRepositoryImpl>());
    expect(getIt<AppConfigCubit>(), same(getIt<AppConfigCubit>()));
  });

  test('in mock mode, /app-config is served from the asset and opens no gate', () async {
    expect(getIt.isRegistered<MockInterceptor>(), isTrue, reason: 'tests run without BASE_URL → mocks on');
    final cubit = getIt<AppConfigCubit>();
    await cubit.load();
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.config, isNotNull, reason: 'loaded from assets/mocks/app_config.json');
    expect(cubit.state.decision, GateDecision.none);
  });

  test('NoopPushService is inert', () async {
    final push = NoopPushService();
    await push.init();
    expect(await push.requestPermission(), isFalse);
    expect(await push.initialMessage(), isNull);
    expect(await push.tokenStream.toList(), isEmpty);
    expect(await push.onMessageOpened.toList(), isEmpty);
  });
}
