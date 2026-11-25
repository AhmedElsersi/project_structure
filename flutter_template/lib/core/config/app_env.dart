// Compile-time environment read from `.env` via `--dart-define-from-file=.env`.
//
// Source: corsa-customer lib/core/utilities/constants/keys/api_keys.dart (AppEnv;
//         USE_MOCKS defaults on when BASE_URL is empty).
// Merged: markspulse lib/app/environment.dart (unknown env throws instead of
//         silently falling back); https required outside dev.
// See docs/CONVENTIONS.md#environment.
import 'package:flutter/foundation.dart';

/// Build flavor selected by `APP_FLAVOR`.
enum AppFlavor {
  dev,
  staging,
  prod;

  static AppFlavor parse(String raw) => switch (raw.trim().toLowerCase()) {
    '' || 'dev' || 'development' => AppFlavor.dev,
    'staging' || 'stage' => AppFlavor.staging,
    'prod' || 'production' => AppFlavor.prod,
    _ => throw AppEnvError('Unknown APP_FLAVOR "$raw" (use dev|staging|prod).'),
  };
}

/// Thrown by [AppEnv.validate]; bootstrap shows the config-error screen.
class AppEnvError implements Exception {
  const AppEnvError(this.message);
  final String message;
  @override
  String toString() => 'AppEnvError: $message';
}

/// Values compiled into the binary. Never put server secrets here.
abstract final class AppEnv {
  static const String _flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String _useMocks = String.fromEnvironment('USE_MOCKS');
  static const String androidStoreUrl = String.fromEnvironment('ANDROID_STORE_URL');
  static const String iosStoreUrl = String.fromEnvironment('IOS_STORE_URL');
  static const bool verboseLogs = bool.fromEnvironment('VERBOSE_LOGS');

  static AppFlavor get flavor => AppFlavor.parse(_flavor);

  /// Mocks are on when explicitly requested, or by default when no BASE_URL
  /// was provided (so a fresh clone runs without a backend).
  static bool get useMocks => _useMocks.isEmpty ? baseUrl.isEmpty : _useMocks.toLowerCase() == 'true';

  /// Base URL used by Dio. Mock mode uses a placeholder host that the mock
  /// interceptor answers before any socket is opened.
  static String get effectiveBaseUrl => baseUrl.isNotEmpty ? baseUrl : 'https://mock.local/api';

  /// Store URL for the current platform (update gate).
  static String get storeUrl => defaultTargetPlatform == TargetPlatform.iOS ? iosStoreUrl : androidStoreUrl;

  /// Fails closed: a staging/prod build without a real https backend must not
  /// start against mocks.
  static void validate() {
    final f = flavor; // throws on unknown flavor
    if (f == AppFlavor.dev) return;
    if (useMocks) {
      throw AppEnvError('USE_MOCKS must be false for the ${f.name} flavor.');
    }
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw AppEnvError('BASE_URL must be an https URL for the ${f.name} flavor.');
    }
  }
}
