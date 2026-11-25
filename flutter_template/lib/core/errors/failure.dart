// Sealed Failure hierarchy: what every Result.err carries.
//
// Source: baytna lib/core/errors/failures.dart — failures carry a TRANSLATION KEY,
//         never user text, so error paths stay localized.
// Merged: corsa-customer lib/core/utilities/failures/failure.dart — statusCode,
//         backend `code`, field errors + fieldError(); brgr failure.dart —
//         "never show raw/unknown text" (displayMessage); markspulse — "every
//         failure has a sentence" (enforced by test/policy/l10n_parity_test.dart).
// See docs/SERVICES.md#failures.
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

import '../localization/generated/locale_keys.g.dart';

/// Base of every expected error. Thrown by data sources, returned by
/// repositories inside `Result.err`, rendered by the UI with [displayMessage].
sealed class Failure extends Equatable implements Exception {
  const Failure({this.serverMessage, this.code, this.debugMessage});

  /// Message sent by the backend (already in the request's Accept-Language).
  /// Shown instead of [messageKey] when present.
  final String? serverMessage;

  /// Backend error code (e.g. `email_taken`), for branching in the UI.
  final String? code;

  /// Developer detail for logs. **Never shown to users.**
  final String? debugMessage;

  /// Translation key of the generic sentence for this failure.
  String get messageKey;

  /// User-facing text: the backend message if any, else the localized sentence.
  String get displayMessage {
    final server = serverMessage?.trim();
    if (server != null && server.isNotEmpty) return server;
    return messageKey.tr();
  }

  @override
  List<Object?> get props => [runtimeType, serverMessage, code, debugMessage];

  @override
  String toString() => '$runtimeType(code: $code, server: $serverMessage, debug: $debugMessage)';
}

/// No connection / DNS failure / socket closed.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.debugMessage});
  @override
  String get messageKey => LocaleKeys.errors_network;
}

/// Connect/send/receive timeout, HTTP 408/504.
final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.debugMessage});
  @override
  String get messageKey => LocaleKeys.errors_timeout;
}

/// The request was cancelled (screen closed, newer search). Never shown.
final class CancelledFailure extends Failure {
  const CancelledFailure();
  @override
  String get messageKey => LocaleKeys.errors_unknown;
}

/// HTTP 401 after the refresh attempt — the session is over.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.serverMessage, super.code});
  @override
  String get messageKey => LocaleKeys.errors_unauthorized;
}

/// HTTP 403 — signed in but not allowed.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.serverMessage, super.code});
  @override
  String get messageKey => LocaleKeys.errors_forbidden;
}

/// HTTP 404 or a missing local record.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.serverMessage, super.code});
  @override
  String get messageKey => LocaleKeys.errors_not_found;
}

/// HTTP 409 — duplicate / stale write.
final class ConflictFailure extends Failure {
  const ConflictFailure({super.serverMessage, super.code});
  @override
  String get messageKey => LocaleKeys.errors_conflict;
}

/// HTTP 400/422 or local validation. [fieldErrors] maps a field name to its
/// messages so forms can show them under the right input.
final class ValidationFailure extends Failure {
  const ValidationFailure({this.fieldErrors = const {}, super.serverMessage, super.code, super.debugMessage});

  final Map<String, List<String>> fieldErrors;

  /// First message for [field], or null.
  String? fieldError(String field) {
    final messages = fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  @override
  String get messageKey => LocaleKeys.errors_validation;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// HTTP 429.
final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({super.serverMessage, this.retryAfter});
  final Duration? retryAfter;
  @override
  String get messageKey => LocaleKeys.errors_rate_limited;
  @override
  List<Object?> get props => [...super.props, retryAfter];
}

/// HTTP 426 — this build is too old; the app gate takes over.
final class UpgradeRequiredFailure extends Failure {
  const UpgradeRequiredFailure({super.serverMessage});
  @override
  String get messageKey => LocaleKeys.errors_upgrade_required;
}

/// HTTP 503 — planned maintenance; the app gate takes over.
final class MaintenanceFailure extends Failure {
  const MaintenanceFailure({super.serverMessage});
  @override
  String get messageKey => LocaleKeys.errors_maintenance;
}

/// HTTP 5xx or an unreadable response body.
final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode, super.serverMessage, super.code, super.debugMessage});
  final int? statusCode;
  @override
  String get messageKey => LocaleKeys.errors_server;
  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Local storage read/write failed.
final class StorageFailure extends Failure {
  const StorageFailure({super.debugMessage});
  @override
  String get messageKey => LocaleKeys.errors_storage;
}

/// A device permission was denied.
final class PermissionFailure extends Failure {
  const PermissionFailure({this.permanentlyDenied = false, super.debugMessage});
  final bool permanentlyDenied;
  @override
  String get messageKey => LocaleKeys.errors_permission;
  @override
  List<Object?> get props => [...super.props, permanentlyDenied];
}

/// Anything unexpected (parsing bug, plugin crash). Its text never reaches the
/// UI — [displayMessage] always shows the generic sentence.
final class UnknownFailure extends Failure {
  const UnknownFailure({super.debugMessage});
  @override
  String get messageKey => LocaleKeys.errors_unknown;
  @override
  String get displayMessage => messageKey.tr();
}
