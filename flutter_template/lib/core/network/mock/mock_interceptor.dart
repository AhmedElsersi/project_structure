// Offline mock backend: answers requests from registered handlers + JSON assets.
//
// Source: corsa-driver lib/core/services/mock/mock_api_interceptor.dart +
//         mock_route_table.dart (route table, fixtures from assets, latency,
//         failNext, handler-driven failures via a status code). It is the LAST
//         interceptor so auth/logging still run on mocked calls.
// See docs/SERVICES.md#mock-backend.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// What a mock handler returns.
class MockResponse {
  const MockResponse(this.data, {this.statusCode = 200, this.headers = const {}});
  final Object? data;
  final int statusCode;
  final Map<String, List<String>> headers;

  /// Convenience for a backend-style error body.
  factory MockResponse.error(int statusCode, String message, {String? code, Map<String, Object?>? errors}) =>
      MockResponse({'message': message, 'code': ?code, 'errors': ?errors}, statusCode: statusCode);
}

/// A handler receives the request and the path parameters (`:id` → `id`).
typedef MockHandler = Future<MockResponse> Function(RequestOptions request, Map<String, String> params);

class _MockRoute {
  _MockRoute(this.method, this.pattern, this.handler) : _regex = _compile(pattern);
  final String method;
  final String pattern;
  final MockHandler handler;
  final RegExp _regex;

  static RegExp _compile(String pattern) {
    final escaped = pattern
        .split('/')
        .map((s) => s.startsWith(':') ? '(?<${s.substring(1)}>[^/]+)' : RegExp.escape(s))
        .join('/');
    return RegExp('^$escaped/?\$');
  }

  Map<String, String>? match(String method, String path) {
    if (method.toUpperCase() != this.method) return null;
    final m = _regex.firstMatch(path);
    if (m == null) return null;
    return {for (final name in m.groupNames) name: Uri.decodeComponent(m.namedGroup(name)!)};
  }
}

class MockInterceptor extends Interceptor {
  MockInterceptor({this.latency = const Duration(milliseconds: 350), AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final Duration latency;
  final AssetBundle _bundle;
  final List<_MockRoute> _routes = [];
  int? _failNextStatus;

  /// Registers a handler. [pattern] is relative to the base URL, e.g. `/items/:id`.
  void on(String method, String pattern, MockHandler handler) =>
      _routes.add(_MockRoute(method.toUpperCase(), pattern, handler));

  /// Serves a JSON asset (e.g. `assets/mocks/app_config.json`) for GET [pattern].
  void serveAsset(String pattern, String assetPath) =>
      on('GET', pattern, (_, _) async => MockResponse(await loadJson(assetPath)));

  /// Makes the next request fail with [statusCode] (dev menus, tests).
  void failNext([int statusCode = 500]) => _failNextStatus = statusCode;

  Future<Object?> loadJson(String assetPath) async => jsonDecode(await _bundle.loadString(assetPath));

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final path = _relativePath(options);

    final forced = _failNextStatus;
    if (forced != null) {
      _failNextStatus = null;
      return handler.reject(_error(options, MockResponse.error(forced, 'Mock failure')), true);
    }

    for (final route in _routes) {
      final params = route.match(options.method, path);
      if (params == null) continue;
      final MockResponse res;
      try {
        res = await route.handler(options, params);
      } catch (e) {
        return handler.reject(_error(options, MockResponse.error(500, 'Mock handler threw: $e')), true);
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return handler.resolve(_response(options, res), true);
      }
      return handler.reject(_error(options, res), true);
    }
    handler.reject(_error(options, MockResponse.error(404, 'No mock for ${options.method} $path')), true);
  }

  String _relativePath(RequestOptions options) {
    final uri = options.uri;
    final base = Uri.tryParse(options.baseUrl);
    var path = uri.path;
    final basePath = base?.path ?? '';
    if (basePath.isNotEmpty && basePath != '/' && path.startsWith(basePath)) {
      path = path.substring(basePath.length);
    }
    return path.isEmpty ? '/' : path;
  }

  Response<dynamic> _response(RequestOptions options, MockResponse res) => Response<dynamic>(
    requestOptions: options,
    data: res.data,
    statusCode: res.statusCode,
    headers: Headers.fromMap(res.headers),
  );

  DioException _error(RequestOptions options, MockResponse res) =>
      DioException.badResponse(statusCode: res.statusCode, requestOptions: options, response: _response(options, res));
}
