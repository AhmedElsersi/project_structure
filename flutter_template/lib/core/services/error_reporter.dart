// Crash/error reporting facade. The template ships a console implementation;
// plug Crashlytics/Sentry in by implementing [ErrorReporter] (see
// docs/SERVICES.md#errorreporter for the Crashlytics recipe).
//
// Source: chinaparts-customer lib/core/services/error_reporter.dart (facade;
//         FlutterError = non-fatal, zone/platform = fatal; release-only).
// Approved decision C7: Firebase is an opt-in module, not a hard dependency.
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

abstract interface class ErrorReporter {
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false, String? reason});
  Future<void> setUserId(String? id);
  void log(String message);
}

/// Logs to the console (debug). Replace with a Crashlytics implementation in
/// production apps.
class ConsoleErrorReporter implements ErrorReporter {
  ConsoleErrorReporter(this._logger);
  final AppLogger _logger;

  @override
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false, String? reason}) async {
    _logger.error('${fatal ? 'FATAL' : 'Non-fatal'}${reason == null ? '' : ' ($reason)'}', error, stack);
    if (kDebugMode && fatal) debugPrintStack(stackTrace: stack, label: error.toString());
  }

  @override
  Future<void> setUserId(String? id) async {}

  @override
  void log(String message) => _logger.info(message);
}
