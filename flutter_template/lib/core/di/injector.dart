// get_it container + core registrations. Features register themselves in their
// own `<feature>_di.dart`; bootstrap.dart composes everything (core never
// imports features).
//
// Source: corsa-customer lib/core/services/di_container.dart + features_di.dart
//         (core and features split) and its registration rules:
//         lazySingleton for services/repositories, factory for cubits, no
//         platform calls inside registrations, setup is AWAITED (brgr, instaops
//         and chinaparts-seller didn't await theirs).
// See docs/ARCHITECTURE.md#dependency-injection.
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../config/app_env.dart';
import '../data/repository_guard.dart';
import '../localization/app_languages.dart';
import '../logging/app_logger.dart';
import '../network/api_client.dart';
import '../network/app_status_bus.dart';
import '../network/mock/mock_interceptor.dart';
import '../services/app_info_service.dart';
import '../services/error_reporter.dart';
import '../session/session_cubit.dart';
import '../storage/auth_token_store.dart';
import '../storage/key_value_store.dart';
import '../storage/secure_store.dart';
import '../theme/theme_cubit.dart';

/// The single container. Resolve with `getIt<T>()` in composition code only
/// (DI files, route builders); classes receive dependencies via constructors.
final GetIt getIt = GetIt.instance;

/// Registers logging, storage, session, theme and the HTTP client.
/// Pass fakes for tests.
Future<void> registerCoreDependencies({
  KeyValueStore? keyValueStore,
  SecureStore? secureStore,
  AppInfo? appInfo,
  ErrorReporter? errorReporter,
}) async {
  final logger = AppLogger();
  getIt.registerSingleton<AppLogger>(logger);

  final reporter = errorReporter ?? ConsoleErrorReporter(logger);
  getIt.registerSingleton<ErrorReporter>(reporter);
  RepositoryGuard.onUnexpectedError = (e, s) => reporter.recordError(e, s, reason: 'repository');

  final prefs = keyValueStore ?? await SharedPrefsKeyValueStore.create();
  getIt.registerSingleton<KeyValueStore>(prefs);

  final secure = secureStore ?? FlutterSecureStore();
  getIt.registerSingleton<SecureStore>(secure);
  if (keyValueStore == null) await FlutterSecureStore.wipeOnFirstLaunch(prefs, secure);

  final info = appInfo ?? await AppInfoService.load();
  getIt.registerSingleton<AppInfo>(info);

  final tokens = AuthTokenStore(secure);
  getIt.registerSingleton<AuthTokenStore>(tokens);

  final session = SessionCubit(tokens);
  getIt.registerSingleton<SessionCubit>(session);
  getIt.registerSingleton<ThemeCubit>(ThemeCubit(prefs));

  final statusBus = AppStatusBus();
  getIt.registerSingleton<AppStatusBus>(statusBus);

  final mock = AppEnv.useMocks ? MockInterceptor() : null;
  if (mock != null) getIt.registerSingleton<MockInterceptor>(mock);

  getIt.registerSingleton<ApiClient>(
    ApiClient(
      baseUrl: AppEnv.effectiveBaseUrl,
      tokens: tokens,
      logger: logger,
      languageCode: () => CurrentLocale.languageCode,
      appHeaders: () => info.headers,
      onSessionExpired: session.expire,
      onAppStatus: statusBus.add,
      mock: mock,
      logBodies: kDebugMode && AppEnv.verboseLogs,
    ),
  );
}

/// For tests: clears every registration.
Future<void> resetDependencies() => getIt.reset();
