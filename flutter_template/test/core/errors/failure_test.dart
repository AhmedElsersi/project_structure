// Tests for lib/core/errors/failure.dart. Source: new
//
// Translations are NOT loaded here, so `messageKey.tr()` returns the key
// itself: assertions compare against `messageKey` and stay deterministic.
// failure_l10n_test.dart checks the real sentences with translations loaded.
import 'dart:convert';
import 'dart:io';

import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/localization/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

const List<Failure> _allFailures = [
  NetworkFailure(),
  TimeoutFailure(),
  CancelledFailure(),
  UnauthorizedFailure(),
  ForbiddenFailure(),
  NotFoundFailure(),
  ConflictFailure(),
  ValidationFailure(),
  RateLimitedFailure(),
  UpgradeRequiredFailure(),
  MaintenanceFailure(),
  ServerFailure(),
  StorageFailure(),
  PermissionFailure(),
  UnknownFailure(),
];

Object? _lookup(Map<String, dynamic> json, String dottedKey) {
  Object? node = json;
  for (final part in dottedKey.split('.')) {
    if (node is! Map<String, dynamic>) return null;
    node = node[part];
  }
  return node;
}

void main() {
  setUpAll(() => EasyLocalization.logger.enableBuildModes = []);

  group('displayMessage', () {
    test('prefers the (trimmed) server message', () {
      const f = ConflictFailure(serverMessage: '  Email already used  ');
      expect(f.displayMessage, 'Email already used');
    });

    test('falls back to the translated messageKey when the server message is null or blank', () {
      expect(const NotFoundFailure().displayMessage, LocaleKeys.errors_not_found);
      expect(const NotFoundFailure(serverMessage: '   ').displayMessage, LocaleKeys.errors_not_found);
      expect(const NetworkFailure(debugMessage: 'SocketException: x').displayMessage, LocaleKeys.errors_network);
    });

    test('debugMessage is never shown', () {
      for (final f in [
        const NetworkFailure(debugMessage: 'DEBUG-TEXT'),
        const TimeoutFailure(debugMessage: 'DEBUG-TEXT'),
        const ServerFailure(debugMessage: 'DEBUG-TEXT'),
        const StorageFailure(debugMessage: 'DEBUG-TEXT'),
        const PermissionFailure(debugMessage: 'DEBUG-TEXT'),
        const ValidationFailure(debugMessage: 'DEBUG-TEXT'),
      ]) {
        expect(f.displayMessage, isNot(contains('DEBUG-TEXT')), reason: f.messageKey);
        expect(f.displayMessage, f.messageKey);
      }
    });

    test('UnknownFailure always shows the generic sentence', () {
      const f = UnknownFailure(debugMessage: "type 'Null' is not a subtype of type 'String'");
      expect(f.displayMessage, LocaleKeys.errors_unknown);
      expect(f.displayMessage, isNot(contains('Null')));
    });
  });

  group('messageKey', () {
    test('each failure maps to its own errors.* sentence', () {
      expect(const NetworkFailure().messageKey, LocaleKeys.errors_network);
      expect(const TimeoutFailure().messageKey, LocaleKeys.errors_timeout);
      expect(const CancelledFailure().messageKey, LocaleKeys.errors_unknown);
      expect(const UnauthorizedFailure().messageKey, LocaleKeys.errors_unauthorized);
      expect(const ForbiddenFailure().messageKey, LocaleKeys.errors_forbidden);
      expect(const NotFoundFailure().messageKey, LocaleKeys.errors_not_found);
      expect(const ConflictFailure().messageKey, LocaleKeys.errors_conflict);
      expect(const ValidationFailure().messageKey, LocaleKeys.errors_validation);
      expect(const RateLimitedFailure().messageKey, LocaleKeys.errors_rate_limited);
      expect(const UpgradeRequiredFailure().messageKey, LocaleKeys.errors_upgrade_required);
      expect(const MaintenanceFailure().messageKey, LocaleKeys.errors_maintenance);
      expect(const ServerFailure().messageKey, LocaleKeys.errors_server);
      expect(const StorageFailure().messageKey, LocaleKeys.errors_storage);
      expect(const PermissionFailure().messageKey, LocaleKeys.errors_permission);
      expect(const UnknownFailure().messageKey, LocaleKeys.errors_unknown);
    });

    test('every messageKey has a non-empty sentence in en.json and ar.json', () {
      for (final lang in ['en', 'ar']) {
        final json = jsonDecode(File('assets/translations/$lang.json').readAsStringSync()) as Map<String, dynamic>;
        for (final f in _allFailures) {
          final value = _lookup(json, f.messageKey);
          expect(value, isA<String>(), reason: '$lang: ${f.messageKey}');
          expect((value! as String).trim(), isNotEmpty, reason: '$lang: ${f.messageKey}');
        }
      }
    });
  });

  group('ValidationFailure', () {
    const f = ValidationFailure(
      fieldErrors: {
        'email': ['Taken', 'Invalid'],
        'name': [],
      },
    );

    test('fieldError returns the first message or null', () {
      expect(f.fieldError('email'), 'Taken');
      expect(f.fieldError('name'), isNull);
      expect(f.fieldError('missing'), isNull);
      expect(f.hasFieldErrors, isTrue);
      expect(const ValidationFailure().hasFieldErrors, isFalse);
    });

    test('equality includes field errors (deep)', () {
      expect(
        // Built at runtime so it is not the same canonical const instance.
        ValidationFailure(
          fieldErrors: {
            'email': List.of(['Taken', 'Invalid']),
            'name': List<String>.empty(),
          },
        ),
        f,
      );
      expect(
        const ValidationFailure(
          fieldErrors: {
            'email': ['Other'],
          },
        ),
        isNot(f),
      );
    });
  });

  group('equality and identity', () {
    test('same type and fields are equal', () {
      expect(const NotFoundFailure(code: 'x'), const NotFoundFailure(code: 'x'));
      expect(const ServerFailure(statusCode: 500), const ServerFailure(statusCode: 500));
      expect(const ServerFailure(statusCode: 500), isNot(const ServerFailure(statusCode: 502)));
      expect(const PermissionFailure(permanentlyDenied: true), isNot(const PermissionFailure()));
    });

    test('different types with the same fields are not equal', () {
      expect(const ForbiddenFailure(code: 'x'), isNot(const NotFoundFailure(code: 'x')));
      expect(const UnknownFailure(), isNot(const CancelledFailure()));
    });

    test('is an Exception that can be thrown and caught as Failure', () {
      expect(const NetworkFailure(), isA<Exception>());
      expect(() => throw const TimeoutFailure(), throwsA(isA<Failure>()));
    });

    test('toString carries code, server and debug text for logs', () {
      final s = const ConflictFailure(serverMessage: 'srv', code: 'dup').toString();
      expect(s, contains('ConflictFailure'));
      expect(s, contains('dup'));
      expect(s, contains('srv'));
    });

    test('RateLimitedFailure keeps retryAfter', () {
      expect(const RateLimitedFailure(retryAfter: Duration(seconds: 5)).retryAfter, const Duration(seconds: 5));
    });
  });
}
