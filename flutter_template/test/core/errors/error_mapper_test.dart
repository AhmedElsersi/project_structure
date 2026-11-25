// Tests for lib/core/errors/error_mapper.dart. Source: new
import 'dart:async';
import 'dart:io';

import 'package:app_template/core/errors/error_mapper.dart';
import 'package:app_template/core/errors/failure.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _request = RequestOptions(path: '/items');

Response<dynamic> _response(int? status, Object? data, {Map<String, List<String>> headers = const {}}) =>
    Response<dynamic>(requestOptions: _request, statusCode: status, data: data, headers: Headers.fromMap(headers));

Failure _map(int? status, Object? data, {Map<String, List<String>> headers = const {}}) =>
    ErrorMapper.fromResponse(_response(status, data, headers: headers));

DioException _dio(DioExceptionType type, {Object? error, Response<dynamic>? response, String? message}) =>
    DioException(requestOptions: _request, type: type, error: error, response: response, message: message);

void main() {
  // Translations are not loaded in unit tests: keep easy_localization quiet.
  setUpAll(() => EasyLocalization.logger.enableBuildModes = []);

  group('validation (400 / 422)', () {
    test('errors: {field: [..]} and {field: ".."}', () {
      final f = _map(422, {
        'message': 'The given data was invalid.',
        'code': 'validation_error',
        'errors': {
          'email': ['Email is taken', 'Email is invalid'],
          'name': 'Name is required',
        },
      });
      expect(f, isA<ValidationFailure>());
      final v = f as ValidationFailure;
      expect(v.fieldErrors, {
        'email': ['Email is taken', 'Email is invalid'],
        'name': ['Name is required'],
      });
      expect(v.serverMessage, 'The given data was invalid.');
      expect(v.code, 'validation_error');
      expect(v.fieldError('email'), 'Email is taken');
      expect(v.fieldError('name'), 'Name is required');
      expect(v.fieldError('phone'), isNull);
      expect(v.hasFieldErrors, isTrue);
    });

    test('errors: [{field, message}] with key/param and msg/messages aliases', () {
      final f =
          _map(400, {
                'message': 'Invalid',
                'errors': [
                  {'field': 'email', 'message': 'Email is taken'},
                  {'key': 'phone', 'msg': 'Phone is invalid'},
                  {
                    'param': 'age',
                    'messages': ['Too young', 'Must be a number'],
                  },
                  {'field': 'email', 'message': 'Email is too long'},
                  {'message': 'no field: ignored'},
                  'not a map: ignored',
                ],
              })
              as ValidationFailure;
      expect(f.fieldErrors, {
        'email': ['Email is taken', 'Email is too long'],
        'phone': ['Phone is invalid'],
        'age': ['Too young', 'Must be a number'],
      });
    });

    test('field arrays at the top level, envelope keys skipped', () {
      final f =
          _map(422, {
                'message': 'Invalid',
                'status': false,
                'success': false,
                'code': 'E1',
                'email': ['Email is taken'],
                'password': ['Too short', 'Needs a digit'],
                'note': 'a plain string at top level is not a field error',
              })
              as ValidationFailure;
      expect(f.fieldErrors, {
        'email': ['Email is taken'],
        'password': ['Too short', 'Needs a digit'],
      });
      expect(f.serverMessage, 'Invalid');
    });

    test('field map under `data` is read when `errors` is absent', () {
      final f =
          _map(422, {
                'message': 'Invalid',
                'data': {
                  'email': ['Email is taken'],
                },
              })
              as ValidationFailure;
      expect(f.fieldError('email'), 'Email is taken');
    });

    test('blank messages are dropped and messages are trimmed', () {
      final f =
          _map(422, {
                'errors': {
                  'email': ['  ', ' Email is taken  ', null],
                  'name': '   ',
                  '': ['empty field name ignored'],
                },
              })
              as ValidationFailure;
      expect(f.fieldErrors, {
        'email': ['Email is taken'],
      });
      expect(f.hasFieldErrors, isTrue);
    });

    test('no field errors and no message', () {
      final f = _map(400, const <String, dynamic>{}) as ValidationFailure;
      expect(f.fieldErrors, isEmpty);
      expect(f.hasFieldErrors, isFalse);
      expect(f.serverMessage, isNull);
    });

    test('`error` is used as the message when `message` is missing', () {
      expect(_map(422, {'error': 'Bad input'}).serverMessage, 'Bad input');
    });

    test('non-map body (list / string) is ignored safely', () {
      expect((_map(422, ['x']) as ValidationFailure).fieldErrors, isEmpty);
      expect((_map(400, 'Bad Request') as ValidationFailure).serverMessage, isNull);
    });

    test('parseFieldErrors is usable directly', () {
      expect(
        ErrorMapper.parseFieldErrors({
          'errors': {
            'a': ['x'],
          },
        }),
        {
          'a': ['x'],
        },
      );
    });
  });

  group('status codes', () {
    final body = {'message': 'Backend says', 'code': 'some_code'};

    test('401 → UnauthorizedFailure', () {
      expect(_map(401, body), const UnauthorizedFailure(serverMessage: 'Backend says', code: 'some_code'));
    });

    test('403 → ForbiddenFailure', () {
      expect(_map(403, body), const ForbiddenFailure(serverMessage: 'Backend says', code: 'some_code'));
    });

    test('404 → NotFoundFailure', () {
      expect(_map(404, body), const NotFoundFailure(serverMessage: 'Backend says', code: 'some_code'));
    });

    test('408 and 504 → TimeoutFailure', () {
      expect(_map(408, body), const TimeoutFailure());
      expect(_map(504, '<html>Gateway Timeout</html>'), const TimeoutFailure());
    });

    test('409 and 410 → ConflictFailure', () {
      expect(_map(409, body), const ConflictFailure(serverMessage: 'Backend says', code: 'some_code'));
      expect(_map(410, body), const ConflictFailure(serverMessage: 'Backend says', code: 'some_code'));
    });

    test('426 → UpgradeRequiredFailure', () {
      expect(_map(426, body), const UpgradeRequiredFailure(serverMessage: 'Backend says'));
    });

    test('429 reads retry-after seconds', () {
      final f = _map(
        429,
        body,
        headers: {
          'retry-after': ['30'],
        },
      );
      expect(f, isA<RateLimitedFailure>());
      expect((f as RateLimitedFailure).retryAfter, const Duration(seconds: 30));
      expect(f.serverMessage, 'Backend says');
    });

    test('429 without (or with a non-numeric) retry-after', () {
      expect((_map(429, body) as RateLimitedFailure).retryAfter, isNull);
      final dated = _map(
        429,
        body,
        headers: {
          'retry-after': ['Wed, 21 Oct 2015 07:28:00 GMT'],
        },
      );
      expect((dated as RateLimitedFailure).retryAfter, isNull);
    });

    test('503 → MaintenanceFailure with the backend message', () {
      expect(_map(503, body), const MaintenanceFailure(serverMessage: 'Backend says'));
    });

    test('500 with an HTML body → ServerFailure, HTML only in debugMessage', () {
      const html = '<!DOCTYPE html><html><body><h1>Internal Server Error</h1></body></html>';
      final f = _map(500, html) as ServerFailure;
      expect(f.statusCode, 500);
      expect(f.serverMessage, isNull);
      expect(f.debugMessage, html);
      expect(f.displayMessage, isNot(contains('html')));
    });

    test('5xx never exposes the server message', () {
      for (final status in [500, 501, 502, 599]) {
        final f = _map(status, {'message': 'SQLSTATE[42S22]: Column not found', 'code': 'db'});
        expect(f, isA<ServerFailure>(), reason: '$status');
        expect(f.serverMessage, isNull, reason: '$status');
        expect(f.code, 'db', reason: '$status');
        expect((f as ServerFailure).statusCode, status);
        expect(f.displayMessage, f.messageKey, reason: 'falls back to the generic sentence');
        expect(f.displayMessage, isNot(contains('SQLSTATE')));
      }
    });

    test('plain-text timeout bodies from proxies → TimeoutFailure', () {
      expect(_map(502, 'upstream request timeout'), const TimeoutFailure());
      expect(_map(520, 'Connection timed out'), const TimeoutFailure());
    });

    test('long plain bodies are truncated in debugMessage', () {
      final f = _map(500, 'x' * 1000) as ServerFailure;
      expect(f.debugMessage, hasLength(301));
      expect(f.debugMessage, endsWith('…'));
    });

    test('other 4xx keep the backend message', () {
      final f = _map(418, body) as ServerFailure;
      expect(f.statusCode, 418);
      expect(f.serverMessage, 'Backend says');
    });

    test('missing status code → ServerFailure(0)', () {
      expect((_map(null, null) as ServerFailure).statusCode, 0);
    });
  });

  group('fromDio by DioExceptionType', () {
    test('timeouts (connect/send/receive/transform) → TimeoutFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        expect(ErrorMapper.fromDio(_dio(type, message: 'slow')), isA<TimeoutFailure>(), reason: '$type');
      }
    });

    test('connectionError → NetworkFailure', () {
      expect(ErrorMapper.fromDio(_dio(DioExceptionType.connectionError)), isA<NetworkFailure>());
    });

    test('cancel → CancelledFailure', () {
      expect(ErrorMapper.fromDio(_dio(DioExceptionType.cancel)), const CancelledFailure());
    });

    test('badCertificate → NetworkFailure', () {
      final f = ErrorMapper.fromDio(_dio(DioExceptionType.badCertificate, message: 'pin'));
      expect(f, isA<NetworkFailure>());
      expect(f.debugMessage, contains('Bad certificate'));
    });

    test('badResponse → mapped by status', () {
      final e = _dio(DioExceptionType.badResponse, response: _response(404, {'message': 'Gone'}));
      expect(ErrorMapper.fromDio(e), const NotFoundFailure(serverMessage: 'Gone'));
    });

    test('unknown with a response → mapped by status', () {
      final e = _dio(DioExceptionType.unknown, response: _response(403, null));
      expect(ErrorMapper.fromDio(e), isA<ForbiddenFailure>());
    });

    test('unknown wrapping a SocketException → NetworkFailure', () {
      final e = _dio(DioExceptionType.unknown, error: const SocketException('Failed host lookup'));
      final f = ErrorMapper.fromDio(e);
      expect(f, isA<NetworkFailure>());
      expect(f.debugMessage, 'Failed host lookup');
    });

    test('unknown without a response → UnknownFailure keeping the text in debugMessage', () {
      final f = ErrorMapper.fromDio(_dio(DioExceptionType.unknown, error: StateError('boom')));
      expect(f, isA<UnknownFailure>());
      expect(f.debugMessage, contains('boom'));
      expect(f.displayMessage, isNot(contains('boom')));
    });

    test('a Failure attached as DioException.error wins over the response', () {
      const attached = UnauthorizedFailure(code: 'session_expired');
      final e = _dio(DioExceptionType.badResponse, error: attached, response: _response(500, 'oops'));
      expect(identical(ErrorMapper.fromDio(e), attached), isTrue);
      final cancelled = _dio(DioExceptionType.cancel, error: const MaintenanceFailure());
      expect(ErrorMapper.fromDio(cancelled), const MaintenanceFailure());
    });
  });

  group('fromObject', () {
    test('Failure passes through unchanged', () {
      const f = ConflictFailure(code: 'dup');
      expect(identical(ErrorMapper.fromObject(f), f), isTrue);
    });

    test('DioException is delegated to fromDio', () {
      expect(ErrorMapper.fromObject(_dio(DioExceptionType.connectionError)), isA<NetworkFailure>());
    });

    test('SocketException → NetworkFailure', () {
      final f = ErrorMapper.fromObject(const SocketException('Network is unreachable'));
      expect(f, const NetworkFailure(debugMessage: 'Network is unreachable'));
    });

    test('HttpException → NetworkFailure', () {
      expect(ErrorMapper.fromObject(const HttpException('closed')), const NetworkFailure(debugMessage: 'closed'));
    });

    test('TimeoutException → TimeoutFailure', () {
      expect(ErrorMapper.fromObject(TimeoutException('slow')), const TimeoutFailure(debugMessage: 'slow'));
    });

    test('FormatException → ServerFailure (bad response format)', () {
      final f = ErrorMapper.fromObject(const FormatException('Unexpected character'));
      expect(f, isA<ServerFailure>());
      expect(f.debugMessage, 'Bad response format: Unexpected character');
    });

    test('PlatformException → UnknownFailure with code in debugMessage', () {
      final f = ErrorMapper.fromObject(PlatformException(code: 'E42', message: 'plugin died'));
      expect(f, const UnknownFailure(debugMessage: 'E42: plugin died'));
    });

    test('anything else → UnknownFailure; its text never reaches the UI', () {
      final f = ErrorMapper.fromObject(StateError('secret internals'));
      expect(f, isA<UnknownFailure>());
      expect(f.debugMessage, contains('secret internals'));
      expect(f.serverMessage, isNull);
      expect(f.displayMessage, isNot(contains('secret internals')));
      expect(ErrorMapper.fromObject('a string'), isA<UnknownFailure>());
    });
  });
}
