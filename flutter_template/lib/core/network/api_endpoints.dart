// Relative API paths. Dio already has the base URL — never prefix it here.
//
// Source: corsa-customer api_keys.dart (endpoint constants + auth-path list for
//         the refresh interceptor). Fixes the house-style bug of absolute
//         "$BASE_URL/..." strings combined with Dio's baseUrl (chinaparts-seller).
abstract final class ApiEndpoints {
  // App
  static const appConfig = '/app-config';

  // Auth (examples — adapt to your backend)
  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';

  /// Requests on these paths never trigger a token refresh on 401.
  static const Set<String> noRefreshPaths = {authLogin, authRefresh};
}
