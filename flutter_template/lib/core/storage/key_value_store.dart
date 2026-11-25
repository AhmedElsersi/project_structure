// Key-value storage behind an interface (SharedPreferences + in-memory fake).
//
// Source: baytna lib/core/services/settings_store.dart (SettingsStore interface so
//         features never import the SDK and tests use a fake).
// Merged: new — scoped clear that keeps device preferences (language/theme) on
//         sign-out, see [clear] `keep`.
// See docs/SERVICES.md#storage.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive persistent settings. Use [SecureStore] for tokens.
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  bool? getBool(String key);
  Future<void> setBool(String key, bool value);
  int? getInt(String key);
  Future<void> setInt(String key, int value);
  double? getDouble(String key);
  Future<void> setDouble(String key, double value);
  List<String>? getStringList(String key);
  Future<void> setStringList(String key, List<String> value);

  /// Decoded JSON object, or null when missing/corrupt.
  Map<String, dynamic>? getJson(String key);
  Future<void> setJson(String key, Map<String, dynamic> value);

  bool containsKey(String key);
  Future<void> remove(String key);

  /// Removes everything except [keep] (e.g. language and theme on sign-out).
  Future<void> clear({Set<String> keep = const {}});
}

/// Production implementation on `SharedPreferencesWithCache` (sync reads).
class SharedPrefsKeyValueStore implements KeyValueStore {
  SharedPrefsKeyValueStore._(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<SharedPrefsKeyValueStore> create() async {
    final prefs = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    return SharedPrefsKeyValueStore._(prefs);
  }

  /// Type-checked read: a key reused with another type across app versions
  /// returns null instead of throwing (the typed getters throw TypeError).
  T? _read<T>(String key) {
    final value = _prefs.get(key);
    return value is T ? value : null;
  }

  @override
  String? getString(String key) => _read<String>(key);
  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  @override
  bool? getBool(String key) => _read<bool>(key);
  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  @override
  int? getInt(String key) => _read<int>(key);
  @override
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  @override
  double? getDouble(String key) => _read<double>(key);
  @override
  Future<void> setDouble(String key, double value) => _prefs.setDouble(key, value);
  @override
  List<String>? getStringList(String key) => _read<List<Object?>>(key)?.whereType<String>().toList();
  @override
  Future<void> setStringList(String key, List<String> value) => _prefs.setStringList(key, List.of(value));

  @override
  Map<String, dynamic>? getJson(String key) => _decode(_read<String>(key));
  @override
  Future<void> setJson(String key, Map<String, dynamic> value) => _prefs.setString(key, jsonEncode(value));

  @override
  bool containsKey(String key) => _prefs.containsKey(key);
  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<void> clear({Set<String> keep = const {}}) async {
    for (final key in _prefs.keys.toList()) {
      if (!keep.contains(key)) await _prefs.remove(key);
    }
  }
}

/// In-memory implementation for tests and previews.
class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore([Map<String, Object>? initial]) : _data = {...?initial};

  final Map<String, Object> _data;

  T? _get<T>(String key) {
    final v = _data[key];
    return v is T ? v : null;
  }

  @override
  String? getString(String key) => _get<String>(key);
  @override
  Future<void> setString(String key, String value) async => _data[key] = value;
  @override
  bool? getBool(String key) => _get<bool>(key);
  @override
  Future<void> setBool(String key, bool value) async => _data[key] = value;
  @override
  int? getInt(String key) => _get<int>(key);
  @override
  Future<void> setInt(String key, int value) async => _data[key] = value;
  @override
  double? getDouble(String key) => _get<double>(key);
  @override
  Future<void> setDouble(String key, double value) async => _data[key] = value;
  @override
  List<String>? getStringList(String key) => _get<List<String>>(key);
  @override
  Future<void> setStringList(String key, List<String> value) async => _data[key] = List.of(value);
  @override
  Map<String, dynamic>? getJson(String key) => _decode(_get<String>(key));
  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async => _data[key] = jsonEncode(value);
  @override
  bool containsKey(String key) => _data.containsKey(key);
  @override
  Future<void> remove(String key) async => _data.remove(key);
  @override
  Future<void> clear({Set<String> keep = const {}}) async => _data.removeWhere((key, _) => !keep.contains(key));
}

Map<String, dynamic>? _decode(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}
