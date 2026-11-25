// The only HTTP client features use. Throws [Failure]; repositories wrap it in Result.
//
// Source: corsa-customer lib/core/services/api_service.dart (one Dio + a bare
//         Dio for refresh/retries, interceptor order, redacted logging,
//         Idempotency-Key helper, mock interceptor last).
// Merged: corsa-customer base_remote_data_source.dart handleRequest(parser) —
//         typed parse step whose crashes become Failures, not red screens;
//         chinaparts-customer app headers; sensible 20s/30s timeouts instead of
//         the house-style 5 minutes.
// See docs/SERVICES.md#apiclient.
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../errors/error_mapper.dart';
import '../errors/failure.dart';
import '../logging/app_logger.dart';
import '../storage/auth_token_store.dart';
import 'interceptors/app_headers_interceptor.dart';
import 'interceptors/app_status_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'mock/mock_interceptor.dart';
import 'token_refresher.dart';

/// Parses a decoded JSON body into [T]. Throwing inside is safe: it becomes
/// a [ServerFailure] with the parse error in `debugMessage`.
typedef JsonParser<T> = T Function(Object? json);

class ApiClient {
  ApiClient({
    required String baseUrl,
    required AuthTokenStore tokens,
    required AppLogger logger,
    required String Function() languageCode,
    required Map<String, String> Function() appHeaders,
    required void Function() onSessionExpired,
    required void Function(AppStatusSignal signal, String? message) onAppStatus,
    TokenRefresher? refresher,
    MockInterceptor? mock,
    bool logBodies = false,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) : _logger = logger {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    dio = Dio(options);
    _bare = Dio(options);

    final headers = AppHeadersInterceptor(languageCode: languageCode, staticHeaders: appHeaders);
    final talkerLogger = TalkerDioLogger(
      talker: logger.talker,
      settings: TalkerDioLoggerSettings(
        printRequestHeaders: true,
        hiddenHeaders: const {'authorization', 'Authorization', 'cookie', 'Cookie'},
        printRequestData: logBodies,
        printResponseData: logBodies,
        // Never log bodies of auth endpoints (passwords, tokens).
        requestFilter: (o) => !o.path.contains('/auth/'),
        responseFilter: (r) => !r.requestOptions.path.contains('/auth/'),
      ),
    );

    dio.interceptors.addAll([
      headers,
      AuthInterceptor(
        tokens: tokens,
        refresher: refresher ?? DioTokenRefresher(_bare),
        retryDio: _bare,
        onSessionExpired: onSessionExpired,
      ),
      RetryInterceptor(retryDio: _bare),
      AppStatusInterceptor(onSignal: onAppStatus),
      talkerLogger,
      ?mock,
    ]);
    _bare.interceptors.addAll([headers, talkerLogger, ?mock]);
  }

  /// Main client (auth, retry, status, logging, mocks). Exposed for uploads etc.
  late final Dio dio;

  /// Client without auth/retry (refresh calls and retries).
  late final Dio _bare;

  final AppLogger _logger;

  Future<T> get<T>(
    String path, {
    required JsonParser<T> parser,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) => _send('GET', path, parser: parser, query: query, options: options, cancelToken: cancelToken);

  Future<T> post<T>(
    String path, {
    required JsonParser<T> parser,
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) => _send(
    'POST',
    path,
    parser: parser,
    data: data,
    query: query,
    options: options,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
  );

  Future<T> put<T>(
    String path, {
    required JsonParser<T> parser,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) => _send('PUT', path, parser: parser, data: data, options: options, cancelToken: cancelToken);

  Future<T> patch<T>(
    String path, {
    required JsonParser<T> parser,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) => _send('PATCH', path, parser: parser, data: data, options: options, cancelToken: cancelToken);

  Future<T> delete<T>(
    String path, {
    required JsonParser<T> parser,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) => _send('DELETE', path, parser: parser, data: data, options: options, cancelToken: cancelToken);

  Future<T> _send<T>(
    String method,
    String path, {
    required JsonParser<T> parser,
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final Response<dynamic> response;
    try {
      response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: (options ?? Options()).copyWith(method: method),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    } on Object catch (e) {
      throw ErrorMapper.fromObject(e);
    }
    try {
      return parser(response.data);
    } on Failure {
      rethrow;
    } on Object catch (e, stack) {
      _logger.handle(e, stack, 'Response parse error for $method $path');
      throw ServerFailure(statusCode: response.statusCode, debugMessage: 'Parse error: $e');
    }
  }

  /// Headers for a money-moving POST. Reuse the same key when retrying.
  static Options idempotent(String key) => Options(headers: {'Idempotency-Key': key});

  /// A random 128-bit idempotency key (UUID v4 format).
  static String newIdempotencyKey() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hex(int from, int to) => b.sublist(from, to).map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
