// Tests for lib/core/network/mock/mock_interceptor.dart. Source: new
import 'dart:convert';

import 'package:app_template/core/network/mock/mock_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves JSON strings from memory instead of the real asset bundle.
class _MemoryBundle extends CachingAssetBundle {
  _MemoryBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw StateError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}

void main() {
  late MockInterceptor mock;
  late Dio dio;

  setUp(() {
    mock = MockInterceptor(
      latency: Duration.zero,
      bundle: _MemoryBundle({'assets/mocks/config.json': '{"min_build": 3}'}),
    );
    dio = Dio(BaseOptions(baseUrl: 'https://mock.local/api'))..interceptors.add(mock);
  });

  Future<DioException> rejected(Future<Object?> request) async {
    try {
      await request;
    } on DioException catch (e) {
      return e;
    }
    fail('expected a DioException');
  }

  test('path parameters are extracted and URL-decoded (base path stripped)', () async {
    Map<String, String>? captured;
    mock.on('GET', '/items/:id/comments/:commentId', (_, params) async {
      captured = params;
      return const MockResponse('ok');
    });
    final res = await dio.get<dynamic>('/items/a%20b/comments/9');
    expect(res.statusCode, 200);
    expect(res.data, 'ok');
    expect(captured, {'id': 'a b', 'commentId': '9'});
  });

  test('method is matched case-insensitively; a trailing slash still matches', () async {
    mock.on('post', '/items', (req, _) async => MockResponse(req.data, statusCode: 201));
    final res = await dio.post<dynamic>('/items/', data: {'name': 'x'});
    expect(res.statusCode, 201);
    expect(res.data, {'name': 'x'});
    final wrongMethod = await rejected(dio.get<dynamic>('/items'));
    expect(wrongMethod.response?.statusCode, 404);
  });

  test('literal segments do not match partially', () async {
    mock.on('GET', '/items', (_, _) async => const MockResponse('list'));
    final e = await rejected(dio.get<dynamic>('/items/extra'));
    expect(e.response?.statusCode, 404);
  });

  test('unknown route → 404 badResponse naming the request', () async {
    final e = await rejected(dio.get<dynamic>('/nope'));
    expect(e.type, DioExceptionType.badResponse);
    expect(e.response?.statusCode, 404);
    expect((e.response?.data as Map<String, dynamic>)['message'], 'No mock for GET /nope');
  });

  test('first matching route wins', () async {
    mock
      ..on('GET', '/items/special', (_, _) async => const MockResponse('special'))
      ..on('GET', '/items/:id', (_, _) async => const MockResponse('generic'));
    expect((await dio.get<dynamic>('/items/special')).data, 'special');
    expect((await dio.get<dynamic>('/items/3')).data, 'generic');
  });

  test('non-2xx MockResponse → badResponse with that status, body and headers', () async {
    mock.on(
      'GET',
      '/limited',
      (_, _) async => const MockResponse(
        {'message': 'Slow down'},
        statusCode: 429,
        headers: {
          'retry-after': ['7'],
        },
      ),
    );
    final e = await rejected(dio.get<dynamic>('/limited'));
    expect(e.response?.statusCode, 429);
    expect(e.response?.headers.value('retry-after'), '7');
    expect(e.response?.data, {'message': 'Slow down'});
  });

  test('MockResponse.error builds the backend envelope', () {
    final r = MockResponse.error(
      422,
      'Invalid',
      code: 'bad',
      errors: {
        'f': ['m'],
      },
    );
    expect(r.statusCode, 422);
    expect(r.data, {
      'message': 'Invalid',
      'code': 'bad',
      'errors': {
        'f': ['m'],
      },
    });
    expect(MockResponse.error(500, 'x').data, {'message': 'x'});
  });

  test('a throwing handler → 500 with the error in the message', () async {
    mock.on('GET', '/throws', (_, _) async => throw StateError('fixture missing'));
    final e = await rejected(dio.get<dynamic>('/throws'));
    expect(e.response?.statusCode, 500);
    expect((e.response?.data as Map<String, dynamic>)['message'], contains('fixture missing'));
  });

  test('failNext fails exactly the next request (default 500, custom status)', () async {
    mock.on('GET', '/ping', (_, _) async => const MockResponse('pong'));

    mock.failNext();
    expect((await rejected(dio.get<dynamic>('/ping'))).response?.statusCode, 500);
    expect((await dio.get<dynamic>('/ping')).data, 'pong');

    mock.failNext(503);
    expect((await rejected(dio.get<dynamic>('/ping'))).response?.statusCode, 503);
    expect((await dio.get<dynamic>('/ping')).data, 'pong');
  });

  test('serveAsset answers GET with decoded JSON from the bundle', () async {
    mock.serveAsset('/app-config', 'assets/mocks/config.json');
    expect((await dio.get<dynamic>('/app-config')).data, {'min_build': 3});
  });

  test('a missing asset → 500 instead of a crash', () async {
    mock.serveAsset('/missing', 'assets/mocks/missing.json');
    expect((await rejected(dio.get<dynamic>('/missing'))).response?.statusCode, 500);
  });

  test('works with a base URL without a path', () async {
    final rootDio = Dio(BaseOptions(baseUrl: 'https://mock.local'))..interceptors.add(mock);
    mock.on('GET', '/root', (_, _) async => const MockResponse('root'));
    expect((await rootDio.get<dynamic>('/root')).data, 'root');
  });
}
