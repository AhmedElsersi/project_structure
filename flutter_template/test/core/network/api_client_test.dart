// Tests for lib/core/network/api_client.dart. Source: new
//
// Also covers interceptors/auth_interceptor.dart, app_headers_interceptor.dart,
// app_status_interceptor.dart and token_refresher.dart through the client.
//
// Runs the real interceptor stack against the real MockInterceptor
// (latency: zero), so no socket is ever opened.
import 'dart:async';

import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/logging/app_logger.dart';
import 'package:app_template/core/network/api_client.dart';
import 'package:app_template/core/network/interceptors/app_status_interceptor.dart';
import 'package:app_template/core/network/mock/mock_interceptor.dart';
import 'package:app_template/core/network/token_refresher.dart';
import 'package:app_template/core/storage/auth_token_store.dart';
import 'package:app_template/core/storage/secure_store.dart';
import 'package:app_template/core/storage/storage_keys.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts refresh calls; answers with [result] after a short delay so
/// concurrent 401s really overlap the refresh.
class _FakeRefresher implements TokenRefresher {
  _FakeRefresher(this.result);

  final AuthTokens? result;
  static const delay = Duration(milliseconds: 20);
  final List<String> received = [];
  int get calls => received.length;

  @override
  Future<AuthTokens?> refresh(String refreshToken) async {
    received.add(refreshToken);
    await Future<void>.delayed(delay);
    return result;
  }
}

class _Harness {
  _Harness({TokenRefresher? refresher}) : refresher = refresher ?? _FakeRefresher(null) {
    client = ApiClient(
      baseUrl: 'https://mock.local/api',
      tokens: tokens,
      logger: AppLogger(enabled: false),
      languageCode: () => language,
      appHeaders: () => const {'X-App-Version': '1.2.3', 'X-Platform': 'android'},
      onSessionExpired: () => expiredCalls++,
      onAppStatus: (signal, message) => signals.add((signal, message)),
      refresher: this.refresher,
      mock: mock,
    );
  }

  final MemorySecureStore secure = MemorySecureStore();
  late final AuthTokenStore tokens = AuthTokenStore(secure);
  final MockInterceptor mock = MockInterceptor(latency: Duration.zero);
  final TokenRefresher refresher;
  late final ApiClient client;
  String language = 'ar';
  int expiredCalls = 0;
  final List<(AppStatusSignal, String?)> signals = [];

  /// Registers GET [path] that only accepts `Bearer <validToken>`.
  List<String?> protectedRoute(String path, String validToken) {
    final seen = <String?>[];
    mock.on('GET', path, (req, _) async {
      final auth = req.headers['Authorization'] as String?;
      seen.add(auth);
      if (auth == 'Bearer $validToken') return MockResponse({'auth': auth});
      return MockResponse.error(401, 'Unauthenticated');
    });
    return seen;
  }
}

String _readAuth(Object? json) => (json! as Map<String, dynamic>)['auth'] as String;

void main() {
  group('parsing', () {
    test('GET passes the decoded body to the parser', () async {
      final h = _Harness();
      h.mock.on('GET', '/items/:id', (_, params) async => MockResponse({'id': params['id'], 'name': 'Item'}));
      final name = await h.client.get('/items/7', parser: (json) => (json! as Map<String, dynamic>)['id'] as String);
      expect(name, '7');
    });

    test('query parameters reach the backend', () async {
      final h = _Harness();
      h.mock.on('GET', '/search', (req, _) async => MockResponse(req.queryParameters));
      final q = await h.client.get(
        '/search',
        query: {'q': 'tea', 'page': 2},
        parser: (json) => json! as Map<String, dynamic>,
      );
      expect(q, {'q': 'tea', 'page': 2});
    });

    test('a parser crash becomes ServerFailure with the status and parse error', () async {
      final h = _Harness();
      h.mock.on('GET', '/items', (_, _) async => const MockResponse({'items': 'not-a-list'}));
      await expectLater(
        h.client.get('/items', parser: (json) => (json! as Map<String, dynamic>)['items'] as List<dynamic>),
        throwsA(
          isA<ServerFailure>()
              .having((f) => f.statusCode, 'statusCode', 200)
              .having((f) => f.debugMessage, 'debugMessage', startsWith('Parse error')),
        ),
      );
    });

    test('a Failure thrown by the parser is rethrown unchanged', () async {
      final h = _Harness();
      h.mock.on('GET', '/items', (_, _) async => const MockResponse(null));
      await expectLater(
        h.client.get<int>('/items', parser: (_) => throw const NotFoundFailure(code: 'empty')),
        throwsA(const NotFoundFailure(code: 'empty')),
      );
    });

    test('PUT / PATCH / DELETE / POST use their HTTP method and send data', () async {
      final h = _Harness();
      for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
        h.mock.on(method, '/items/1', (req, _) async => MockResponse({'method': req.method, 'data': req.data}));
      }
      String parse(Object? json) {
        final map = json! as Map<String, dynamic>;
        return '${map['method']} ${map['data']}';
      }

      expect(await h.client.post('/items/1', data: {'a': 1}, parser: parse), 'POST {a: 1}');
      expect(await h.client.put('/items/1', data: {'a': 2}, parser: parse), 'PUT {a: 2}');
      expect(await h.client.patch('/items/1', data: {'a': 3}, parser: parse), 'PATCH {a: 3}');
      expect(await h.client.delete('/items/1', parser: parse), 'DELETE null');
    });
  });

  group('error mapping', () {
    test('422 → ValidationFailure with field errors', () async {
      final h = _Harness();
      h.mock.on(
        'POST',
        '/items',
        (_, _) async => MockResponse.error(
          422,
          'Please fix the form',
          code: 'invalid',
          errors: {
            'title': ['Title is required'],
          },
        ),
      );
      final failure = await h.client
          .post('/items', data: const <String, dynamic>{}, parser: (j) => j)
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(failure, isA<ValidationFailure>());
      final v = failure! as ValidationFailure;
      expect(v.fieldError('title'), 'Title is required');
      expect(v.serverMessage, 'Please fix the form');
      expect(v.code, 'invalid');
    });

    test('unknown mock route → NotFoundFailure', () async {
      final h = _Harness();
      await expectLater(h.client.get('/nope', parser: (j) => j), throwsA(isA<NotFoundFailure>()));
    });

    test('429 retry-after header from the mock reaches RateLimitedFailure', () async {
      final h = _Harness();
      h.mock.on(
        'GET',
        '/otp',
        (_, _) async => const MockResponse(
          {'message': 'Slow down'},
          statusCode: 429,
          headers: {
            'retry-after': ['12'],
          },
        ),
      );
      await expectLater(
        h.client.get('/otp', parser: (j) => j),
        throwsA(isA<RateLimitedFailure>().having((f) => f.retryAfter, 'retryAfter', const Duration(seconds: 12))),
      );
    });

    test('a cancelled request → CancelledFailure', () async {
      final h = _Harness();
      final gate = Completer<void>();
      h.mock.on('GET', '/slow', (_, _) async {
        await gate.future;
        return const MockResponse('late');
      });
      final token = CancelToken();
      final future = h.client.get('/slow', parser: (j) => j, cancelToken: token);
      token.cancel('screen closed');
      await expectLater(future, throwsA(isA<CancelledFailure>()));
      gate.complete();
    });

    test('426 / 503 signal the app gate and still throw their Failure', () async {
      final h = _Harness();
      h.mock.on('GET', '/old', (_, _) async => MockResponse.error(426, 'Please update'));
      h.mock.on('GET', '/down', (_, _) async => MockResponse.error(503, 'Back at 5pm'));
      h.mock.on('GET', '/broken', (_, _) async => MockResponse.error(500, 'Boom'));

      await expectLater(h.client.get('/old', parser: (j) => j), throwsA(isA<UpgradeRequiredFailure>()));
      await expectLater(h.client.get('/down', parser: (j) => j), throwsA(isA<MaintenanceFailure>()));
      await expectLater(h.client.get('/broken', parser: (j) => j), throwsA(isA<ServerFailure>()));

      expect(h.signals, [
        (AppStatusSignal.upgradeRequired, 'Please update'),
        (AppStatusSignal.maintenance, 'Back at 5pm'),
      ]);
    });

    test('failNext fails exactly one request', () async {
      final h = _Harness();
      h.mock.on('GET', '/ping', (_, _) async => const MockResponse('pong'));
      h.mock.failNext();
      await expectLater(h.client.get('/ping', parser: (j) => j), throwsA(isA<ServerFailure>()));
      expect(await h.client.get('/ping', parser: (j) => j), 'pong');
    });
  });

  group('headers', () {
    test('Accept-Language follows the current UI language; app headers are sent', () async {
      final h = _Harness();
      final seen = <Map<String, dynamic>>[];
      h.mock.on('GET', '/headers', (req, _) async {
        seen.add(Map.of(req.headers));
        return const MockResponse(null);
      });

      await h.client.get('/headers', parser: (j) => j);
      h.language = 'en';
      await h.client.get('/headers', parser: (j) => j);

      expect(seen[0]['Accept-Language'], 'ar');
      expect(seen[1]['Accept-Language'], 'en');
      for (final headers in seen) {
        expect(headers['X-App-Version'], '1.2.3');
        expect(headers['X-Platform'], 'android');
        expect(headers['Accept'], 'application/json');
        expect(headers.containsKey('Authorization'), isFalse, reason: 'no token stored');
      }
    });

    test('a per-request header wins over the static app header', () async {
      final h = _Harness();
      String? platform;
      h.mock.on('GET', '/headers', (req, _) async {
        platform = req.headers['X-Platform'] as String?;
        return const MockResponse(null);
      });
      await h.client.get(
        '/headers',
        parser: (j) => j,
        options: Options(headers: {'X-Platform': 'custom'}),
      );
      expect(platform, 'custom');
    });

    test('Bearer token is attached when signed in', () async {
      final h = _Harness();
      await h.tokens.save(const AuthTokens(accessToken: 't1', refreshToken: 'r1'));
      final seen = h.protectedRoute('/me', 't1');
      expect(await h.client.get('/me', parser: _readAuth), 'Bearer t1');
      expect(seen, ['Bearer t1']);
    });

    test('idempotency helpers', () {
      final key = ApiClient.newIdempotencyKey();
      expect(key, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(ApiClient.newIdempotencyKey(), isNot(key));
      expect(ApiClient.idempotent(key).headers, {'Idempotency-Key': key});
    });
  });

  group('auth refresh', () {
    test('two concurrent 401s share ONE refresh, then both retry with the new token', () async {
      final refresher = _FakeRefresher(const AuthTokens(accessToken: 'new', refreshToken: 'r2'));
      final h = _Harness(refresher: refresher);
      await h.tokens.save(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      final seen = h.protectedRoute('/me', 'new');

      final results = await Future.wait([
        h.client.get('/me', parser: _readAuth),
        h.client.get('/me', parser: _readAuth),
      ]);

      expect(results, ['Bearer new', 'Bearer new']);
      expect(refresher.calls, 1);
      expect(refresher.received, ['r1']);
      expect(seen.where((a) => a == 'Bearer old'), hasLength(2));
      expect(seen.where((a) => a == 'Bearer new'), hasLength(2));
      expect(h.tokens.accessToken, 'new');
      expect(h.tokens.refreshToken, 'r2');
      expect(await h.secure.read(StorageKeys.accessToken), 'new');
      expect(h.expiredCalls, 0);
    });

    test('a request after the refresh uses the new token directly', () async {
      final refresher = _FakeRefresher(const AuthTokens(accessToken: 'new'));
      final h = _Harness(refresher: refresher);
      await h.tokens.save(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      final seen = h.protectedRoute('/me', 'new');

      await h.client.get('/me', parser: _readAuth);
      await h.client.get('/me', parser: _readAuth);

      expect(refresher.calls, 1);
      expect(seen, ['Bearer old', 'Bearer new', 'Bearer new']);
      expect(h.tokens.refreshToken, 'r1', reason: 'kept when the refresh does not rotate it');
    });

    test('refresh returns null → session expired once, tokens cleared, UnauthorizedFailure', () async {
      final refresher = _FakeRefresher(null);
      final h = _Harness(refresher: refresher);
      await h.tokens.save(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      h.protectedRoute('/me', 'never');

      await expectLater(h.client.get('/me', parser: _readAuth), throwsA(isA<UnauthorizedFailure>()));

      expect(refresher.calls, 1);
      expect(h.expiredCalls, 1);
      expect(h.tokens.accessToken, isNull);
      expect(h.tokens.refreshToken, isNull);
      expect(await h.secure.read(StorageKeys.accessToken), isNull);
      expect(await h.secure.read(StorageKeys.refreshToken), isNull);
    });

    test('concurrent 401s with a failed refresh call the refresher once', () async {
      final refresher = _FakeRefresher(null);
      final h = _Harness(refresher: refresher);
      await h.tokens.save(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      h.protectedRoute('/me', 'never');

      final outcomes = await Future.wait([
        h.client.get('/me', parser: _readAuth).then<Object?>((v) => v, onError: (Object e) => e),
        h.client.get('/me', parser: _readAuth).then<Object?>((v) => v, onError: (Object e) => e),
      ]);

      expect(outcomes, everyElement(isA<UnauthorizedFailure>()));
      expect(refresher.calls, 1);
      expect(h.tokens.hasSession, isFalse);
    });

    test('concurrent 401s with a failed refresh end the session only once', () async {
      final h = _Harness(refresher: _FakeRefresher(null));
      await h.tokens.save(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      h.protectedRoute('/me', 'never');

      await Future.wait([
        h.client.get('/me', parser: _readAuth).then<Object?>((v) => v, onError: (Object e) => e),
        h.client.get('/me', parser: _readAuth).then<Object?>((v) => v, onError: (Object e) => e),
      ]);

      expect(h.expiredCalls, 1);
    });

    test('no stored refresh token → no refresh call, session expired', () async {
      final refresher = _FakeRefresher(const AuthTokens(accessToken: 'new'));
      final h = _Harness(refresher: refresher);
      await h.tokens.save(const AuthTokens(accessToken: 'old'));
      h.protectedRoute('/me', 'new');

      await expectLater(h.client.get('/me', parser: _readAuth), throwsA(isA<UnauthorizedFailure>()));
      expect(refresher.calls, 0);
      expect(h.expiredCalls, 1);
      expect(h.tokens.hasSession, isFalse);
    });

    test('a retried request that is still 401 fails without a second refresh', () async {
      final refresher = _FakeRefresher(const AuthTokens(accessToken: 'new', refreshToken: 'r2'));
      final h = _Harness(refresher: refresher);
      await h.tokens.save(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      final seen = h.protectedRoute('/me', 'never');

      await expectLater(h.client.get('/me', parser: _readAuth), throwsA(isA<UnauthorizedFailure>()));
      expect(refresher.calls, 1);
      expect(seen, ['Bearer old', 'Bearer new']);
    });

    test('401 from /auth/login never triggers a refresh or ends the session', () async {
      final refresher = _FakeRefresher(const AuthTokens(accessToken: 'new'));
      final h = _Harness(refresher: refresher);
      await h.tokens.save(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
      h.mock.on('POST', '/auth/login', (_, _) async => MockResponse.error(401, 'Wrong password'));

      await expectLater(
        h.client.post('/auth/login', data: {'password': 'x'}, parser: (j) => j),
        throwsA(const UnauthorizedFailure(serverMessage: 'Wrong password')),
      );
      expect(refresher.calls, 0);
      expect(h.expiredCalls, 0);
      expect(h.tokens.accessToken, 'old');
    });

    test('401 on a request that carried no token does not refresh or expire', () async {
      final refresher = _FakeRefresher(const AuthTokens(accessToken: 'new'));
      final h = _Harness(refresher: refresher);
      h.protectedRoute('/me', 'new');

      await expectLater(h.client.get('/me', parser: _readAuth), throwsA(isA<UnauthorizedFailure>()));
      expect(refresher.calls, 0);
      expect(h.expiredCalls, 0);
    });
  });

  group('DioTokenRefresher (default, via the mock backend)', () {
    test('reads data.access_token / data.refresh_token', () async {
      final mock = MockInterceptor(latency: Duration.zero)
        ..on('POST', '/auth/refresh', (req, _) async {
          final body = req.data as Map<String, dynamic>;
          return MockResponse({
            'data': {'access_token': 'a-${body['refresh_token']}', 'refresh_token': 'r-next'},
          });
        });
      final dio = Dio(BaseOptions(baseUrl: 'https://mock.local/api'))..interceptors.add(mock);
      final tokens = await DioTokenRefresher(dio).refresh('r1');
      expect(tokens?.accessToken, 'a-r1');
      expect(tokens?.refreshToken, 'r-next');
    });

    test('reads root-level keys; returns null on errors or bad bodies', () async {
      var reply = const MockResponse({'access_token': 'root'});
      final mock = MockInterceptor(latency: Duration.zero)..on('POST', '/auth/refresh', (_, _) async => reply);
      final dio = Dio(BaseOptions(baseUrl: 'https://mock.local/api'))..interceptors.add(mock);
      final refresher = DioTokenRefresher(dio);

      expect((await refresher.refresh('r'))?.accessToken, 'root');
      reply = const MockResponse({'access_token': ''});
      expect(await refresher.refresh('r'), isNull);
      reply = const MockResponse('not json');
      expect(await refresher.refresh('r'), isNull);
      reply = MockResponse.error(401, 'Refresh token expired');
      expect(await refresher.refresh('r'), isNull);
      expect(await const NoTokenRefresher().refresh('r'), isNull);
    });
  });
}
