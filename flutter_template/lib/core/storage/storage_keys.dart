// Every persisted key in one place, so a clear() can keep the right ones.
//
// Source: chinaparts-seller lib/core/utilities/constants/keys/shared_preferences_keys.dart
//         (central key registry); `deviceScoped` set is new (kept across sign-out).
abstract final class StorageKeys {
  // KeyValueStore (non-sensitive)
  static const firstRunDone = 'app.first_run_done';
  static const themeMode = 'app.theme_mode';
  static const lastOptionalUpdatePrompt = 'app.last_optional_update_build';
  static const appConfigCache = 'app.config_cache';

  // SecureStore (sensitive)
  static const accessToken = 'auth.access_token';
  static const refreshToken = 'auth.refresh_token';

  /// Survive sign-out: device preferences, not account data.
  static const Set<String> deviceScoped = {firstRunDone, themeMode, lastOptionalUpdatePrompt};
}
