// Bearer token + ONE shared refresh for concurrent 401s, then retry.
//
// Source: corsa-customer lib/core/services/api_service.dart (_CorsaInterceptor:
//         QueuedInterceptorsWrapper so parallel 401s share one refresh; retry on
//         a bare Dio; "already refreshed while queued" check; end session once).
// Merged: chinaparts-customer session_expiry_service.dart (only a request that
//         carried a token can expire the session).
import 'package:dio/dio.dart';

import '../../storage/auth_token_store.dart';
import '../api_endpoints.dart';
import '../token_refresher.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor({
    required AuthTokenStore tokens,
    required TokenRefresher refresher,
    required Dio retryDio,
    required void Function() onSessionExpired,
  }) : _tokens = tokens,
       _refresher = refresher,
       _retryDio = retryDio,
       _onSessionExpired = onSessionExpired;

  final AuthTokenStore _tokens;
  final TokenRefresher _refresher;

  /// Client without this interceptor, used for retries (no queue deadlock).
  final Dio _retryDio;
  final void Function() _onSessionExpired;

  static const _retriedKey = 'auth_retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.accessToken;
    if (token != null && token.isNotEmpty && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final sentAuth = options.headers['Authorization'];
    final isAuthPath = ApiEndpoints.noRefreshPaths.any(options.path.endsWith);

    if (err.response?.statusCode != 401 || sentAuth == null || isAuthPath || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }
    options.extra[_retriedKey] = true;

    // Another queued request already refreshed: just retry with the new token.
    final current = _tokens.accessToken;
    if (current != null && sentAuth != 'Bearer $current') {
      return _retry(options, current, handler, err);
    }
    // Another queued request already failed to refresh and ended the session.
    if (current == null) return handler.next(err);

    final refreshToken = _tokens.refreshToken;
    final renewed = (refreshToken == null || refreshToken.isEmpty) ? null : await _refresher.refresh(refreshToken);
    if (renewed == null) {
      await _tokens.clear();
      _onSessionExpired();
      return handler.next(err);
    }
    await _tokens.save(renewed);
    return _retry(options, renewed.accessToken, handler, err);
  }

  Future<void> _retry(
    RequestOptions options,
    String token,
    ErrorInterceptorHandler handler,
    DioException original,
  ) async {
    options.headers['Authorization'] = 'Bearer $token';
    try {
      handler.resolve(await _retryDio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
