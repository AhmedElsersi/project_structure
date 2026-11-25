// Tests for lib/core/logging/app_logger.dart. Source: new
import 'package:app_template/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';

void main() {
  group('AppLogger.redact', () {
    test('Bearer tokens', () {
      final out = AppLogger.redact('Authorization: Bearer abc.DEF-123_xyz~+/= sent');
      expect(out, isNot(contains('abc.DEF')));
      expect(out, contains('<redacted>'));
      expect(out, endsWith(' sent'));
      expect(AppLogger.redact('bearer lowercase-token'), isNot(contains('lowercase-token')));
    });

    test('JWTs anywhere in the text', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0In0.dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      final out = AppLogger.redact('token cookie=$jwt; path=/');
      expect(out, isNot(contains('eyJ')));
      expect(out, isNot(contains('dBjftJeZ4CVP')));
    });

    test('JSON secret fields keep the key, drop the value', () {
      const body = '{"email_verified":true,"password":"hunter2","access_token":"at-1","refresh_token":"rt-1"}';
      final out = AppLogger.redact(body);
      for (final secret in ['hunter2', 'at-1', 'rt-1']) {
        expect(out, isNot(contains(secret)), reason: secret);
      }
      // The value is replaced by a quoted placeholder, so the JSON stays valid.
      expect(out, contains('"password":"<redacted>"'));
      expect(out, contains('email_verified'));
    });

    test('key=value secrets (query strings, form bodies), case-insensitive', () {
      final out = AppLogger.redact('GET /x?page=2&token=abc123 api_key=K-9 Secret=s3 PASSWORD=pw');
      for (final secret in ['abc123', 'K-9', 's3', 'pw']) {
        expect(out, isNot(contains(secret)), reason: secret);
      }
      expect(out, startsWith('GET /x?page=2&token=<redacted>'));
    });

    test('a JSON password containing spaces is fully redacted', () {
      final out = AppLogger.redact('{"password":"correct horse battery staple"}');
      expect(out, isNot(contains('horse')));
    });

    test('emails', () {
      final out = AppLogger.redact('Signed in as first.last+tag@example.co.uk from app');
      expect(out, isNot(contains('example.co.uk')));
      expect(out, isNot(contains('first.last')));
      expect(out, 'Signed in as <redacted> from app');
    });

    test('text without secrets is unchanged', () {
      const plain = 'GET /items?page=2 → 200 in 35 ms';
      expect(AppLogger.redact(plain), plain);
    });
  });

  group('AppLogger', () {
    test('every log method redacts before it reaches Talker', () {
      final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
      AppLogger(talker: talker)
        ..debug('debug password=d1')
        ..info('info user@example.com')
        ..warning('warning Bearer w1')
        ..error('error token=e1')
        ..handle(StateError('x'), StackTrace.empty, 'context secret=c1');
      final messages = talker.history.map((e) => e.message ?? '').join('\n');
      for (final secret in ['d1', 'user@example.com', 'w1', 'e1', 'c1']) {
        expect(messages, isNot(contains(secret)), reason: secret);
      }
      expect(talker.history, hasLength(5));
    });

    test('can be disabled', () {
      final logger = AppLogger(enabled: false)..info('nothing');
      expect(logger.talker.history, isEmpty);
    });
  });
}
