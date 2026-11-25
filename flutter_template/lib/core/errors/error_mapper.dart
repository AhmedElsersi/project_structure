// Maps anything thrown (DioException, Failure, platform errors) to a Failure.
//
// Source: corsa-customer lib/core/base_architecture/data/data_sources/
//         base_remote_data_source.dart (failureFromResponse: status + backend
//         `message`/`code`/`errors`, HTML/plain 5xx bodies, timeout bodies, cancel).
// Merged: chinaparts-seller base_remote_data_source.dart (validation errors in
//         many shapes: `errors: {field: [..]}`, `errors: {field: ".."}`,
//         `errors: [{field, message}]`, top-level field map); brgr failure.dart
//         ("never show raw/unknown errors").
// See docs/SERVICES.md#error-mapping.
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'failure.dart';

abstract final class ErrorMapper {
  /// Converts any error into a [Failure]. Unknown errors keep their text only
  /// in [Failure.debugMessage].
  static Failure fromObject(Object error) => switch (error) {
    Failure() => error,
    DioException() => fromDio(error),
    SocketException() => NetworkFailure(debugMessage: error.message),
    TimeoutException() => TimeoutFailure(debugMessage: error.message),
    HttpException() => NetworkFailure(debugMessage: error.message),
    FormatException() => ServerFailure(debugMessage: 'Bad response format: ${error.message}'),
    PlatformException() => UnknownFailure(debugMessage: '${error.code}: ${error.message}'),
    _ => UnknownFailure(debugMessage: error.toString()),
  };

  /// Maps a Dio error. A Failure attached by an interceptor wins.
  static Failure fromDio(DioException e) {
    final attached = e.error;
    if (attached is Failure) return attached;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutFailure(debugMessage: e.message);
      case DioExceptionType.connectionError:
        return NetworkFailure(debugMessage: e.message);
      case DioExceptionType.cancel:
        return const CancelledFailure();
      case DioExceptionType.badCertificate:
        return NetworkFailure(debugMessage: 'Bad certificate: ${e.message}');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }
    final response = e.response;
    if (response != null) return fromResponse(response);
    if (attached is SocketException) {
      return NetworkFailure(debugMessage: attached.message);
    }
    return UnknownFailure(debugMessage: e.message ?? attached?.toString());
  }

  /// Maps a non-2xx [response] using the backend envelope
  /// `{ "message": "...", "code": "...", "errors": ... }`.
  static Failure fromResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final raw = response.data;
    // Proxies can answer 5xx with HTML or plain text: never parse those as JSON.
    final body = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    final message = _string(body['message']) ?? _string(body['error']);
    final code = _string(body['code']);

    switch (status) {
      case 400:
      case 422:
        return ValidationFailure(fieldErrors: parseFieldErrors(body), serverMessage: message, code: code);
      case 401:
        return UnauthorizedFailure(serverMessage: message, code: code);
      case 403:
        return ForbiddenFailure(serverMessage: message, code: code);
      case 404:
        return NotFoundFailure(serverMessage: message, code: code);
      case 408:
      case 504:
        return const TimeoutFailure();
      case 409:
      case 410:
        return ConflictFailure(serverMessage: message, code: code);
      case 426:
        return UpgradeRequiredFailure(serverMessage: message);
      case 429:
        final retry = int.tryParse(response.headers.value('retry-after') ?? '');
        return RateLimitedFailure(
          serverMessage: message,
          retryAfter: retry == null ? null : Duration(seconds: retry),
        );
      case 503:
        return MaintenanceFailure(serverMessage: message);
      default:
        if (raw is String && _looksLikeTimeout(raw)) return const TimeoutFailure();
        return ServerFailure(
          statusCode: status,
          serverMessage: status >= 500 ? null : message,
          code: code,
          debugMessage: raw is String ? _truncate(raw) : null,
        );
    }
  }

  /// Reads validation errors from the shapes seen across our backends.
  static Map<String, List<String>> parseFieldErrors(Map<String, dynamic> body) {
    final result = <String, List<String>>{};
    void add(String field, Object? value) {
      if (field.isEmpty) return;
      final messages = switch (value) {
        final String s when s.trim().isNotEmpty => [s.trim()],
        final List<dynamic> l => l.map((e) => e?.toString().trim() ?? '').where((s) => s.isNotEmpty).toList(),
        _ => const <String>[],
      };
      if (messages.isNotEmpty) result.putIfAbsent(field, () => []).addAll(messages);
    }

    final errors = body['errors'] ?? body['data'];
    if (errors is Map) {
      errors.forEach((key, value) => add(key.toString(), value));
    } else if (errors is List) {
      for (final item in errors) {
        if (item is Map) {
          final field = _string(item['field']) ?? _string(item['key']) ?? _string(item['param']);
          final msg = item['message'] ?? item['msg'] ?? item['messages'];
          if (field != null) add(field, msg);
        }
      }
    } else {
      // Some backends put field arrays at the top level.
      body.forEach((key, value) {
        if (const {'message', 'code', 'status', 'success', 'error'}.contains(key)) return;
        if (value is List) add(key, value);
      });
    }
    return result;
  }

  static String? _string(Object? v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static bool _looksLikeTimeout(String body) {
    final lower = body.toLowerCase();
    return lower.contains('timed out') || lower.contains('timeout');
  }

  static String _truncate(String s) => s.length <= 300 ? s : '${s.substring(0, 300)}…';
}
