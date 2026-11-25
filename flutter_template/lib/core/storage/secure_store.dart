// Encrypted storage for tokens and secrets, with corruption self-healing.
//
// Source: brgr / instaops lib/core/services/secure_storage_manager.dart (on a
//         platform error the keystore is wiped and the write retried once, so a
//         corrupted Android keystore never bricks the app).
// Merged: chinaparts-customer lib/main.dart _clearStaleSessionOnFirstLaunch (iOS
//         keeps Keychain items after uninstall) — see [wipeOnFirstLaunch].
// See docs/SERVICES.md#storage.
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_value_store.dart';
import 'storage_keys.dart';

abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException {
      // Unreadable entry (keystore rotated / restored backup): drop it.
      await _safeDelete(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException {
      await _safeDeleteAll();
      await _storage.write(key: key, value: value);
    }
  }

  @override
  Future<void> delete(String key) => _safeDelete(key);

  @override
  Future<void> deleteAll() => _safeDeleteAll();

  Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException {
      await _safeDeleteAll();
    }
  }

  Future<void> _safeDeleteAll() async {
    try {
      await _storage.deleteAll();
    } on PlatformException {
      // Nothing more we can do; reads will keep returning null.
    }
  }

  /// iOS keeps Keychain items after an uninstall: wipe them the first time the
  /// app runs after a fresh install. Call once from bootstrap.
  static Future<void> wipeOnFirstLaunch(KeyValueStore prefs, SecureStore secure) async {
    if (prefs.getBool(StorageKeys.firstRunDone) ?? false) return;
    await secure.deleteAll();
    await prefs.setBool(StorageKeys.firstRunDone, true);
  }
}

/// In-memory implementation for tests.
class MemorySecureStore implements SecureStore {
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
  @override
  Future<void> deleteAll() async => _data.clear();
}
