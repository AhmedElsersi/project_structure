// Opens links, dialer, mail, SMS, WhatsApp and maps. Never throws: every call
// returns whether something actually opened, so the UI can say so.
//
// Source: chinaparts-customer lib/core/services/url_handler.dart (launch
//         directly and check launchUrl's result instead of gating on
//         canLaunchUrl, which is false on Android 11+ without <queries>).
// Merged: baytna lib/core/services/url_service.dart (http(s) in the in-app
//         browser view, external fallback, malformed URL → false);
//         corsa-driver lib/core/services/launcher_service.dart (WhatsApp digits
//         only, navigate() trying Waze → Google Maps → Apple Maps → web).
// See docs/SERVICES.md#urlservice.
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/digits.dart';

/// Launch seam (tests inject a fake).
typedef UrlLauncher = Future<bool> Function(Uri uri, LaunchMode mode);

Future<bool> _defaultLauncher(Uri uri, LaunchMode mode) => launchUrl(uri, mode: mode);

class UrlService {
  UrlService({UrlLauncher? launcher}) : _launch = launcher ?? _defaultLauncher;

  final UrlLauncher _launch;

  /// Opens [url] (a [Uri] or a [String]). Web links open in the external
  /// browser, or — with [inApp] — in the in-app browser view (Custom Tabs /
  /// SFSafariViewController) with the external browser as fallback. Other
  /// schemes (`tel:`, `mailto:`, app links) always go to the external app.
  Future<bool> open(Object url, {bool inApp = false}) async {
    final uri = _parse(url);
    if (uri == null) return false;
    final isWeb = uri.scheme == 'http' || uri.scheme == 'https';
    if (isWeb && uri.host.isEmpty) return false;
    if (isWeb && inApp && await _try(uri, LaunchMode.inAppBrowserView)) return true;
    return _try(uri, isWeb ? LaunchMode.externalApplication : LaunchMode.platformDefault);
  }

  /// Opens the dialer with [phone] (not placing the call).
  Future<bool> call(String phone) {
    final number = _phoneDigits(phone, keepPlus: true);
    if (number.isEmpty) return Future.value(false);
    return _try(Uri(scheme: 'tel', path: number), LaunchMode.platformDefault);
  }

  /// Opens the mail composer. Spaces are encoded as `%20` (Uri's
  /// queryParameters would use `+`, which mail apps show literally).
  Future<bool> email(String to, {String? subject, String? body}) {
    if (to.trim().isEmpty) return Future.value(false);
    final query = _encodeQuery({'subject': subject, 'body': body});
    return _try(Uri(scheme: 'mailto', path: to.trim(), query: query), LaunchMode.platformDefault);
  }

  /// Opens the SMS composer.
  Future<bool> sms(String phone, {String? body}) {
    final number = _phoneDigits(phone, keepPlus: true);
    if (number.isEmpty) return Future.value(false);
    return _try(Uri(scheme: 'sms', path: number, query: _encodeQuery({'body': body})), LaunchMode.platformDefault);
  }

  /// Opens a WhatsApp chat. [phone] in international format (country code,
  /// any separators); [text] is pre-filled.
  Future<bool> whatsapp(String phone, {String? text}) {
    final digits = _phoneDigits(phone, keepPlus: false);
    if (digits.isEmpty) return Future.value(false);
    final query = _encodeQuery({'text': text});
    return _try(Uri.parse('https://wa.me/$digits${query == null ? '' : '?$query'}'), LaunchMode.externalApplication);
  }

  /// Shows a location in the platform maps app (web Google Maps fallback).
  Future<bool> maps(double lat, double lng, {String? label}) async {
    final q = label == null || label.trim().isEmpty ? '$lat,$lng' : '$lat,$lng(${label.trim()})';
    final candidates = <Uri>[
      if (_isIOS) Uri.https('maps.apple.com', '/', {'ll': '$lat,$lng', 'q': ?label}),
      if (_isAndroid) Uri.parse('geo:$lat,$lng?q=${Uri.encodeComponent(q)}'),
      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$lat,$lng'}),
    ];
    return _firstThatOpens(candidates);
  }

  /// Turn-by-turn directions: Waze if installed, then Google Maps, Apple Maps
  /// on iOS, and the Google Maps website as the last resort.
  Future<bool> navigate(double lat, double lng, {String? label}) {
    final candidates = <Uri>[
      Uri.parse('waze://?ll=$lat,$lng&navigate=yes'),
      if (_isAndroid) Uri.parse('google.navigation:q=$lat,$lng'),
      if (_isIOS) Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving'),
      if (_isIOS) Uri.https('maps.apple.com', '/', {'daddr': '$lat,$lng', 'dirflg': 'd', 'q': ?label}),
      Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '$lat,$lng'}),
    ];
    return _firstThatOpens(candidates);
  }

  Future<bool> _firstThatOpens(List<Uri> candidates) async {
    for (final uri in candidates) {
      if (await _try(uri, LaunchMode.externalApplication)) return true;
    }
    return false;
  }

  Future<bool> _try(Uri uri, LaunchMode mode) async {
    try {
      return await _launch(uri, mode);
    } on Object {
      // PlatformException (no handler), ArgumentError (bad mode on platform)...
      return false;
    }
  }

  static Uri? _parse(Object url) {
    if (url is Uri) return url.hasScheme ? url : null;
    final text = '$url'.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    return uri == null || !uri.hasScheme ? null : uri;
  }

  static String _phoneDigits(String phone, {required bool keepPlus}) {
    final trimmed = Digits.toWestern(phone).trim();
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return keepPlus && trimmed.startsWith('+') && digits.isNotEmpty ? '+$digits' : digits;
  }

  static String? _encodeQuery(Map<String, String?> params) {
    final parts = [
      for (final MapEntry(:key, :value) in params.entries)
        if (value != null && value.isNotEmpty) '$key=${Uri.encodeComponent(value)}',
    ];
    return parts.isEmpty ? null : parts.join('&');
  }

  static bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
