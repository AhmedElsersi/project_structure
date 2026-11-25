// App-wide logger facade with secret redaction, backed by Talker.
//
// Source: lexa-student lib/core/error/error_log.dart (one pluggable log facade
//         usable from any layer).
// Merged: corsa-customer api_service.dart (Authorization hidden in network logs);
//         petrobe api_service.dart (sensitive paths kept out of logs);
//         chinaparts-customer (talker enabled only in debug builds).
// See docs/SERVICES.md#logging.
import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';

/// Thin wrapper so feature code never depends on Talker directly.
class AppLogger {
  AppLogger({Talker? talker, bool? enabled})
    : talker =
          talker ??
          Talker(
            settings: TalkerSettings(enabled: enabled ?? kDebugMode, useConsoleLogs: kDebugMode),
          );

  /// Exposed for TalkerDioLogger / TalkerRouteObserver / TalkerScreen.
  final Talker talker;

  void debug(String message) => talker.debug(redact(message));
  void info(String message) => talker.info(redact(message));
  void warning(String message, [Object? error, StackTrace? stack]) => talker.warning(redact(message), error, stack);
  void error(String message, [Object? error, StackTrace? stack]) => talker.error(redact(message), error, stack);

  /// Logs an exception with its stack trace.
  void handle(Object error, [StackTrace? stack, String? context]) =>
      talker.handle(error, stack, context == null ? null : redact(context));

  static const _secretKeys =
      'access_token|refresh_token|id_token|token|password|passwd|secret|api_key|apikey|authorization';

  /// Each rule keeps group(1) (the key / scheme) and hides the value.
  static final List<RegExp> _patterns = [
    // "key": "value with spaces" (JSON) — the whole quoted value.
    RegExp('("(?:$_secretKeys)"\\s*:\\s*)"(?:[^"\\\\]|\\\\.)*"', caseSensitive: false),
    // Authorization schemes: Bearer / Basic / Token <credentials>.
    RegExp(r'\b((?:Bearer|Basic|Token)\s+)[A-Za-z0-9\-_.~+/]+=*', caseSensitive: false),
    // key=value / key: value (query strings, headers, form bodies).
    RegExp('\\b((?:$_secretKeys)\\s*[:=]\\s*)[^\\s&,;}"]+', caseSensitive: false),
    // Bare JWTs.
    RegExp(r'()eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
    // Emails.
    RegExp(r'()[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
  ];

  /// Removes tokens, passwords, credentials and emails from [input].
  static String redact(String input) {
    var out = input;
    for (final pattern in _patterns) {
      out = out.replaceAllMapped(pattern, (m) {
        final prefix = m.group(1) ?? '';
        final quoted = prefix.trimRight().endsWith(':') && m.group(0)!.endsWith('"');
        return quoted ? '$prefix"<redacted>"' : '$prefix<redacted>';
      });
    }
    return out;
  }
}
