// Tests for lib/core/storage/auth_token_store.dart. Source: new
import 'package:app_template/core/storage/auth_token_store.dart';
import 'package:app_template/core/storage/secure_store.dart';
import 'package:app_template/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecureStore secure;
  late AuthTokenStore tokens;

  setUp(() {
    secure = MemorySecureStore();
    tokens = AuthTokenStore(secure);
  });

  test('empty until loaded; empty storage → no session', () async {
    expect(tokens.accessToken, isNull);
    expect(tokens.hasSession, isFalse);
    await tokens.load();
    expect(tokens.accessToken, isNull);
    expect(tokens.refreshToken, isNull);
    expect(tokens.hasSession, isFalse);
  });

  test('load reads both tokens from secure storage into memory', () async {
    await secure.write(StorageKeys.accessToken, 'a1');
    await secure.write(StorageKeys.refreshToken, 'r1');
    await tokens.load();
    expect(tokens.accessToken, 'a1');
    expect(tokens.refreshToken, 'r1');
    expect(tokens.hasSession, isTrue);
  });

  test('an empty stored access token is not a session', () async {
    await secure.write(StorageKeys.accessToken, '');
    await tokens.load();
    expect(tokens.hasSession, isFalse);
  });

  test('save updates memory and storage', () async {
    await tokens.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
    expect(tokens.accessToken, 'a1');
    expect(tokens.refreshToken, 'r1');
    expect(tokens.hasSession, isTrue);
    expect(await secure.read(StorageKeys.accessToken), 'a1');
    expect(await secure.read(StorageKeys.refreshToken), 'r1');

    final reloaded = AuthTokenStore(secure);
    await reloaded.load();
    expect(reloaded.accessToken, 'a1');
    expect(reloaded.refreshToken, 'r1');
  });

  test('save without a refresh token keeps the previous one', () async {
    await tokens.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
    await tokens.save(const AuthTokens(accessToken: 'a2'));
    expect(tokens.accessToken, 'a2');
    expect(tokens.refreshToken, 'r1');
    expect(await secure.read(StorageKeys.accessToken), 'a2');
    expect(await secure.read(StorageKeys.refreshToken), 'r1');
  });

  test('clear wipes memory and storage', () async {
    await tokens.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
    await tokens.clear();
    expect(tokens.accessToken, isNull);
    expect(tokens.refreshToken, isNull);
    expect(tokens.hasSession, isFalse);
    expect(await secure.read(StorageKeys.accessToken), isNull);
    expect(await secure.read(StorageKeys.refreshToken), isNull);
  });
}
