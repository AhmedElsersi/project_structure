// Retries idempotent GETs on network errors with a short backoff.
//
// Source: corsa-customer lib/core/services/api_service.dart (GET retried twice on
//         connectionError/timeouts, 400 ms × attempt, retry on a bare Dio).
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({required Dio retryDio, this.maxRetries = 2, this.baseDelay = const Duration(milliseconds: 400)})
    : _retryDio = retryDio;

  final Dio _retryDio;
  final int maxRetries;
  final Duration baseDelay;

  static const _attemptKey = 'get_retry_attempt';

  bool _isRetryable(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (options.method.toUpperCase() != 'GET') return handler.next(err);
    var attempt = (options.extra[_attemptKey] as int?) ?? 0;
    var last = err;
    // Retries run on the bare Dio (no RetryInterceptor), so loop here.
    while (_isRetryable(last) && attempt < maxRetries) {
      attempt++;
      options.extra[_attemptKey] = attempt;
      await Future<void>.delayed(baseDelay * attempt);
      try {
        return handler.resolve(await _retryDio.fetch<dynamic>(options));
      } on DioException catch (e) {
        last = e;
      }
    }
    handler.next(last);
  }
}
