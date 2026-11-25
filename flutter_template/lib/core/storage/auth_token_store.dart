// Access/refresh token persistence with an in-memory cache for interceptors.
//
// Source: corsa-customer api_service.dart (token read once at bootstrap, kept in
//         memory, refresh token in secure storage).
import 'secure_store.dart';
import 'storage_keys.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, this.refreshToken});
  final String accessToken;
  final String? refreshToken;
}

class AuthTokenStore {
  AuthTokenStore(this._secure);

  final SecureStore _secure;
  String? _access;
  String? _refresh;

  String? get accessToken => _access;
  String? get refreshToken => _refresh;
  bool get hasSession => (_access ?? '').isNotEmpty;

  /// Loads tokens into memory. Call once at startup.
  Future<void> load() async {
    _access = await _secure.read(StorageKeys.accessToken);
    _refresh = await _secure.read(StorageKeys.refreshToken);
  }

  Future<void> save(AuthTokens tokens) async {
    _access = tokens.accessToken;
    _refresh = tokens.refreshToken ?? _refresh;
    await _secure.write(StorageKeys.accessToken, tokens.accessToken);
    final refresh = tokens.refreshToken;
    if (refresh != null) await _secure.write(StorageKeys.refreshToken, refresh);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await _secure.delete(StorageKeys.accessToken);
    await _secure.delete(StorageKeys.refreshToken);
  }
}
