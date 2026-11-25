// Startup: error hooks, environment check, localization, DI, session restore,
// then runApp. Composition root — the only place that wires features to core.
//
// Source: baytna lib/bootstrap.dart (runZonedGuarded + FlutterError +
//         PlatformDispatcher hooks, ordered init).
// Merged: markspulse lib/app/environment.dart (fail closed: an invalid env shows
//         a configuration-error app instead of silently using mocks);
//         corsa-customer main.dart (session hooks wired here, so core never
//         imports features); chinaparts-customer (first-launch keychain wipe —
//         done in registerCoreDependencies).
// See docs/ARCHITECTURE.md#startup.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/app_config/app_config_cubit.dart';
import 'core/config/app_env.dart';
import 'core/di/injector.dart';
import 'core/logging/app_bloc_observer.dart';
import 'core/logging/app_logger.dart';
import 'core/services/error_reporter.dart';
import 'core/session/session_cubit.dart';
import 'shared/screens/config_error_app.dart';

/// Feature/module registrations, called after core DI. Add new features here.
typedef ModuleRegistrar = FutureOr<void> Function();

Future<void> bootstrap({List<ModuleRegistrar> modules = const []}) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        AppEnv.validate();
      } on AppEnvError catch (e) {
        runApp(ConfigErrorApp(details: kDebugMode ? e.message : null));
        return;
      }

      await EasyLocalization.ensureInitialized();
      EasyLocalization.logger.enableBuildModes = []; // silence missing-key spam

      await registerCoreDependencies();
      for (final register in modules) {
        await register();
      }

      final reporter = getIt<ErrorReporter>();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(reporter.recordError(details.exception, details.stack, reason: 'flutter'));
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(reporter.recordError(error, stack, fatal: true, reason: 'platform'));
        return true;
      };
      Bloc.observer = AppBlocObserver(logger: getIt<AppLogger>(), reporter: reporter, verbose: AppEnv.verboseLogs);

      // No orientation lock (chinaparts-customer rule): a lock decided at launch
      // is wrong after a foldable unfolds. Every screen must survive landscape.

      await getIt<SessionCubit>().restore();
      // Fail-open: no config / failed fetch never blocks the app.
      unawaited(getIt<AppConfigCubit>().load());

      runApp(const AppRoot());
    },
    (error, stack) {
      if (getIt.isRegistered<ErrorReporter>()) {
        unawaited(getIt<ErrorReporter>().recordError(error, stack, fatal: true, reason: 'zone'));
      } else {
        debugPrint('Uncaught before DI: $error\n$stack');
      }
    },
  );
}
