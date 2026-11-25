// Bloc observer: transitions in debug logs, errors to the ErrorReporter.
//
// Source: chinaparts-customer lib/core/services/bloc_observer.dart (debug-only
//         printing observer + release crash forwarding). Fixes brgr/petrobe
//         observers that printed every state change in release builds.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/error_reporter.dart';
import 'app_logger.dart';

class AppBlocObserver extends BlocObserver {
  AppBlocObserver({required this.logger, required this.reporter, this.verbose = false});

  final AppLogger logger;
  final ErrorReporter reporter;

  /// Log every change (VERBOSE_LOGS=true); otherwise only errors.
  final bool verbose;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (kDebugMode && verbose) logger.debug('${bloc.runtimeType}: ${change.nextState}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    logger.handle(error, stackTrace, 'Bloc error in ${bloc.runtimeType}');
    reporter.recordError(error, stackTrace, reason: 'bloc:${bloc.runtimeType}');
    super.onError(bloc, error, stackTrace);
  }
}
