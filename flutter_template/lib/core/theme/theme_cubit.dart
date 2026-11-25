// Persisted ThemeMode (system / light / dark), read synchronously at startup so
// there is no flash of the wrong theme.
//
// Source: baytna lib/app/theme/theme_cubit.dart (persisted ThemeMode, defaults
//         to system), lexa-control lib/core/theme/theme_cubit.dart (loaded
//         before runApp).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/key_value_store.dart';
import '../storage/storage_keys.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._store) : super(_read(_store));

  final KeyValueStore _store;

  static ThemeMode _read(KeyValueStore store) => switch (store.getString(StorageKeys.themeMode)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _store.setString(StorageKeys.themeMode, mode.name);
  }
}
