// Tests for lib/core/network/interceptors/retry_interceptor.dart. Source: new
//
// MockInterceptor can only reject with badResponse, so connection errors are
// simulated with a fake HttpClientAdapter. The wiring mirrors ApiClient: the
// retry goes through a second ("bare") Dio WITHOUT the RetryInterceptor.
import 'dart:typed_data';

import 'package:app_template/core/network/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Throws [failType] for the first [failures] calls, then answers 200.
class _FlakyAdapter implements HttpClientAdapter {
  _FlakyAdapter(this.failures, {this.failType = DioExceptionType.connectionError, this.statusCode = 200});

  final int failures;
  final DioExceptionType failType;
  final int statusCode;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (calls <= failures) throw DioException(requestOptions: options, type: failType, message: 'fake $failType');
    return ResponseBody.fromString(
      '{"ok":true}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({Dio dio, _FlakyAdapter adapter}) _build(_FlakyAdapter adapter, {int maxRetries = 2}) {
  final options = BaseOptions(baseUrl: 'https://api.example.test');
  final bare = Dio(options)..httpClientAdapter = adapter;
  final dio = Dio(options)
    ..httpClientAdapter = adapter
    ..interceptors.add(RetryInterceptor(retryDio: bare, maxRetries: maxRetries, baseDelay: Duration.zero));
  return (dio: dio, adapter: adapter);
}

Future<DioException> _error(Future<Object?> request) async {
  try {
    await request;
  } on DioException catch (e) {
    return e;
  }
  fail('expected a DioException');
}

void main() {
  test('GET is retried after one connection error and succeeds', () async {
    final s = _build(_FlakyAdapter(1));
    final res = await s.dio.get<dynamic>('/items');
    expect(res.statusCode, 200);
    expect(res.data, {'ok': true});
    expect(s.adapter.calls, 2);
  });

  test('connectionTimeout and receiveTimeout are retryable', () async {
    for (final type in [DioExceptionType.connectionTimeout, DioExceptionType.receiveTimeout]) {
      final s = _build(_FlakyAdapter(1, failType: type));
      expect((await s.dio.get<dynamic>('/items')).statusCode, 200, reason: '$type');
      expect(s.adapter.calls, 2, reason: '$type');
    }
  });

  test('GET is retried up to maxRetries (2) times', () async {
    final s = _build(_FlakyAdapter(2));
    final res = await s.dio.get<dynamic>('/items');
    expect(res.statusCode, 200);
    expect(s.adapter.calls, 3);
  });

  test('never retries more than maxRetries and surfaces the last error', () async {
    final s = _build(_FlakyAdapter(100));
    final e = await _error(s.dio.get<dynamic>('/items'));
    expect(e.type, DioExceptionType.connectionError);
    expect(s.adapter.calls, inInclusiveRange(2, 3));
  });

  test('maxRetries: 0 disables retries', () async {
    final s = _build(_FlakyAdapter(1), maxRetries: 0);
    await _error(s.dio.get<dynamic>('/items'));
    expect(s.adapter.calls, 1);
  });

  test('non-GET requests are never retried', () async {
    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      final s = _build(_FlakyAdapter(1));
      await _error(s.dio.request<dynamic>('/items', options: Options(method: method)));
      expect(s.adapter.calls, 1, reason: method);
    }
  });

  test('sendTimeout, cancel and HTTP errors are not retried', () async {
    for (final type in [DioExceptionType.sendTimeout, DioExceptionType.cancel, DioExceptionType.badCertificate]) {
      final s = _build(_FlakyAdapter(1, failType: type));
      await _error(s.dio.get<dynamic>('/items'));
      expect(s.adapter.calls, 1, reason: '$type');
    }
    final server = _build(_FlakyAdapter(0, statusCode: 500));
    final e = await _error(server.dio.get<dynamic>('/items'));
    expect(e.response?.statusCode, 500);
    expect(server.adapter.calls, 1);
  });
}
