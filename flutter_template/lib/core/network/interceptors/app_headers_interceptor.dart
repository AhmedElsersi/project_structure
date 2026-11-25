// Adds Accept-Language and app/platform headers to every request.
//
// Source: chinaparts-customer lib/core/services/app_version_service.dart +
//         api_service.dart (X-Platform / X-App-Version / X-Build-Number, and
//         Accept-Language kept in sync with the UI locale).
import 'package:dio/dio.dart';

class AppHeadersInterceptor extends Interceptor {
  AppHeadersInterceptor({required this.languageCode, required this.staticHeaders});

  /// Reads the current UI language at request time (e.g. `ar`).
  final String Function() languageCode;

  /// Platform / version headers computed once at startup.
  final Map<String, String> Function() staticHeaders;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Accept', () => 'application/json');
    options.headers['Accept-Language'] = languageCode();
    staticHeaders().forEach((key, value) => options.headers.putIfAbsent(key, () => value));
    handler.next(options);
  }
}
