// Tests for lib/core/storage/key_value_store.dart. Source: new
//
// The same contract runs against MemoryKeyValueStore and the production
// SharedPrefsKeyValueStore (SharedPreferencesWithCache on the official
// in-memory async platform from shared_preferences_platform_interface, a
// transitive dependency of shared_preferences).
import 'package:app_template/core/storage/key_value_store.dart';
import 'package:app_template/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

typedef _Factory = Future<KeyValueStore> Function();

void main() {
  final factories = <String, _Factory>{
    'MemoryKeyValueStore': () async => MemoryKeyValueStore(),
    'SharedPrefsKeyValueStore': () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      return SharedPrefsKeyValueStore.create();
    },
  };

  factories.forEach((name, create) {
    group(name, () {
      late KeyValueStore store;
      setUp(() async => store = await create());

      test('missing keys read as null', () {
        expect(store.getString('k'), isNull);
        expect(store.getBool('k'), isNull);
        expect(store.getInt('k'), isNull);
        expect(store.getDouble('k'), isNull);
        expect(store.getStringList('k'), isNull);
        expect(store.getJson('k'), isNull);
        expect(store.containsKey('k'), isFalse);
      });

      test('typed round-trips', () async {
        await store.setString('s', 'value');
        await store.setBool('b', true);
        await store.setInt('i', 42);
        await store.setDouble('d', 1.5);
        await store.setStringList('l', ['a', 'b']);
        expect(store.getString('s'), 'value');
        expect(store.getBool('b'), isTrue);
        expect(store.getInt('i'), 42);
        expect(store.getDouble('d'), 1.5);
        expect(store.getStringList('l'), ['a', 'b']);
        expect(store.containsKey('s'), isTrue);
      });

      test('a stored list is a copy', () async {
        final list = ['a'];
        await store.setStringList('l', list);
        list.add('mutated');
        expect(store.getStringList('l'), ['a']);
      });

      test('json round-trip', () async {
        final value = <String, dynamic>{
          'a': 1,
          'b': [1, 2],
          'c': {'d': true, 'e': null},
          's': 'text',
        };
        await store.setJson('j', value);
        expect(store.getJson('j'), value);
      });

      test('corrupt, empty or non-object json reads as null', () async {
        await store.setString('corrupt', '{"a": ');
        await store.setString('empty', '');
        await store.setString('list', '[1, 2]');
        await store.setString('scalar', '"text"');
        for (final key in ['corrupt', 'empty', 'list', 'scalar']) {
          expect(store.getJson(key), isNull, reason: key);
        }
      });

      test('remove', () async {
        await store.setString('s', 'v');
        await store.remove('s');
        expect(store.getString('s'), isNull);
        expect(store.containsKey('s'), isFalse);
        await store.remove('never-existed');
      });

      test('clear() removes everything', () async {
        await store.setString('a', '1');
        await store.setBool('b', true);
        await store.clear();
        expect(store.containsKey('a'), isFalse);
        expect(store.containsKey('b'), isFalse);
      });

      test('clear(keep:) keeps device-scoped keys (sign-out)', () async {
        await store.setString(StorageKeys.themeMode, 'dark');
        await store.setBool(StorageKeys.firstRunDone, true);
        await store.setJson(StorageKeys.appConfigCache, {'v': 1});
        await store.setString('user.profile', 'x');
        await store.clear(keep: StorageKeys.deviceScoped);
        expect(store.getString(StorageKeys.themeMode), 'dark');
        expect(store.getBool(StorageKeys.firstRunDone), isTrue);
        expect(store.containsKey(StorageKeys.appConfigCache), isFalse);
        expect(store.containsKey('user.profile'), isFalse);
      });
    });
  });

  test('MemoryKeyValueStore: initial values; a value of another type reads as null', () {
    final store = MemoryKeyValueStore({'s': 'text', 'i': 1});
    expect(store.getString('s'), 'text');
    expect(store.getInt('i'), 1);
    expect(store.getInt('s'), isNull);
    expect(store.getBool('i'), isNull);
    expect(store.getJson('i'), isNull);
  });

  test('SharedPrefsKeyValueStore: a value of another type reads as null (like the Memory fake)', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final store = await SharedPrefsKeyValueStore.create();
    await store.setInt('k', 1);
    expect(store.getString('k'), isNull);
    expect(store.getJson('k'), isNull);
    expect(store.getBool('k'), isNull);
  });

  test('SharedPrefsKeyValueStore persists through the platform (new instance sees old values)', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final first = await SharedPrefsKeyValueStore.create();
    await first.setString(StorageKeys.themeMode, 'light');
    final second = await SharedPrefsKeyValueStore.create();
    expect(second.getString(StorageKeys.themeMode), 'light');
  });
}
