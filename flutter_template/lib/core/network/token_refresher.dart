// Strategy for exchanging a refresh token, injected into the auth interceptor.
//
// Source: corsa-customer api_service.dart _refreshToken (refresh on a bare Dio so
//         it never deadlocks behind the queued interceptor).
import 'package:dio/dio.dart';

import '../storage/auth_token_store.dart';
import 'api_endpoints.dart';

/// Returns new tokens, or null when the session cannot be renewed.
abstract interface class TokenRefresher {
  Future<AuthTokens?> refresh(String refreshToken);
}

/// Default: POST {refresh_token} to [ApiEndpoints.authRefresh] and read
/// `data.access_token` / `data.refresh_token` (or the same keys at the root).
class DioTokenRefresher implements TokenRefresher {
  DioTokenRefresher(this._bareDio);

  /// A Dio WITHOUT the auth interceptor.
  final Dio _bareDio;

  @override
  Future<AuthTokens?> refresh(String refreshToken) async {
    try {
      final res = await _bareDio.post<dynamic>(ApiEndpoints.authRefresh, data: {'refresh_token': refreshToken});
      final body = res.data;
      if (body is! Map) return null;
      final data = body['data'] is Map ? body['data'] as Map : body;
      final access = data['access_token'];
      if (access is! String || access.isEmpty) return null;
      final refresh = data['refresh_token'];
      return AuthTokens(accessToken: access, refreshToken: refresh is String ? refresh : null);
    } on DioException {
      return null;
    }
  }
}

/// For apps without refresh tokens: a 401 always ends the session.
class NoTokenRefresher implements TokenRefresher {
  const NoTokenRefresher();
  @override
  Future<AuthTokens?> refresh(String refreshToken) async => null;
}
