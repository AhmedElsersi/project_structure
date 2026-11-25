// Tests for lib/core/services/url_service.dart (with a fake launcher). Source: new
import 'package:app_template/core/services/url_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

class _FakeLauncher {
  final List<(Uri, LaunchMode)> calls = [];

  /// Decides per call whether the launch "opened" something.
  bool Function(Uri uri, LaunchMode mode) opens = (_, _) => true;

  Future<bool> call(Uri uri, LaunchMode mode) async {
    calls.add((uri, mode));
    return opens(uri, mode);
  }
}

void main() {
  late _FakeLauncher launcher;
  late UrlService service;

  setUp(() {
    launcher = _FakeLauncher();
    service = UrlService(launcher: launcher.call);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('open', () {
    test('web links go to the external browser by default', () async {
      expect(await service.open('https://example.com'), isTrue);
      expect(launcher.calls.single.$2, LaunchMode.externalApplication);
    });

    test('inApp tries the in-app browser view, then falls back to external', () async {
      launcher.opens = (_, mode) => mode != LaunchMode.inAppBrowserView;
      expect(await service.open(Uri.parse('https://example.com'), inApp: true), isTrue);
      expect(launcher.calls.map((c) => c.$2), [LaunchMode.inAppBrowserView, LaunchMode.externalApplication]);
    });

    test('malformed or scheme-less URLs return false without launching', () async {
      for (final url in ['', '   ', 'example.com', 'https://']) {
        expect(await service.open(url), isFalse, reason: url);
      }
      expect(launcher.calls, isEmpty);
    });

    test('never throws: a launcher exception is false', () async {
      final throwing = UrlService(launcher: (_, _) => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'));
      expect(await throwing.open('https://example.com'), isFalse);
      expect(await throwing.call('123'), isFalse);
    });
  });

  test('call keeps a leading + and strips separators (Arabic digits too)', () async {
    await service.call('+1 (555) ٥٥٥-0100');
    expect(launcher.calls.single.$1.toString(), 'tel:+15555550100');
    expect(await service.call('---'), isFalse);
  });

  test('email encodes spaces as %20, not +', () async {
    await service.email('a@b.com', subject: 'Hello there', body: 'Line & more');
    final uri = launcher.calls.single.$1;
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'a@b.com');
    expect(uri.query, 'subject=Hello%20there&body=Line%20%26%20more');
  });

  test('sms and whatsapp', () async {
    await service.sms('+1 555 0100', body: 'Hi');
    await service.whatsapp('+1 555 555 0100', text: 'Salam');
    expect(launcher.calls[0].$1.toString(), 'sms:+15550100?body=Hi');
    expect(launcher.calls[1].$1.toString(), 'https://wa.me/15555550100?text=Salam');
    expect(launcher.calls[1].$2, LaunchMode.externalApplication);
  });

  test('navigate tries apps in order and falls back to the web', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    launcher.opens = (uri, _) => uri.scheme == 'https';
    expect(await service.navigate(30.1, 31.2), isTrue);
    expect(launcher.calls.map((c) => c.$1.scheme), ['waze', 'google.navigation', 'https']);
  });

  test('maps on iOS prefers Apple Maps', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await service.maps(30.1, 31.2, label: 'Office');
    expect(launcher.calls.first.$1.host, 'maps.apple.com');
    expect(launcher.calls.first.$1.queryParameters, {'ll': '30.1,31.2', 'q': 'Office'});
  });
}
