// Tests for lib/core/storage/secure_store.dart. Source: new
import 'package:app_template/core/storage/key_value_store.dart';
import 'package:app_template/core/storage/secure_store.dart';
import 'package:app_template/core/storage/storage_keys.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

/// MemorySecureStore that counts deleteAll() calls.
class _CountingSecureStore extends MemorySecureStore {
  int wipes = 0;

  @override
  Future<void> deleteAll() {
    wipes++;
    return super.deleteAll();
  }
}

final _platformError = PlatformException(code: 'keystore', message: 'corrupted');

void main() {
  group('MemorySecureStore', () {
    test('read / write / delete / deleteAll', () async {
      final store = MemorySecureStore();
      expect(await store.read('k'), isNull);
      await store.write('k', 'v');
      await store.write('k2', 'v2');
      expect(await store.read('k'), 'v');
      await store.delete('k');
      expect(await store.read('k'), isNull);
      await store.deleteAll();
      expect(await store.read('k2'), isNull);
    });
  });

  group('FlutterSecureStore.wipeOnFirstLaunch', () {
    test('wipes the keychain only on the first launch', () async {
      final prefs = MemoryKeyValueStore();
      final secure = _CountingSecureStore();
      await secure.write(StorageKeys.accessToken, 'left-over-from-previous-install');

      await FlutterSecureStore.wipeOnFirstLaunch(prefs, secure);
      expect(secure.wipes, 1);
      expect(await secure.read(StorageKeys.accessToken), isNull);
      expect(prefs.getBool(StorageKeys.firstRunDone), isTrue);

      await secure.write(StorageKeys.accessToken, 'fresh-session');
      await FlutterSecureStore.wipeOnFirstLaunch(prefs, secure);
      await FlutterSecureStore.wipeOnFirstLaunch(prefs, secure);
      expect(secure.wipes, 1);
      expect(await secure.read(StorageKeys.accessToken), 'fresh-session');
    });

    test('the flag survives a sign-out clear (device-scoped key)', () async {
      final prefs = MemoryKeyValueStore();
      final secure = _CountingSecureStore();
      await FlutterSecureStore.wipeOnFirstLaunch(prefs, secure);
      await prefs.clear(keep: StorageKeys.deviceScoped);
      await FlutterSecureStore.wipeOnFirstLaunch(prefs, secure);
      expect(secure.wipes, 1);
    });
  });

  group('FlutterSecureStore self-healing', () {
    late _MockStorage storage;
    late FlutterSecureStore store;

    setUp(() {
      storage = _MockStorage();
      store = FlutterSecureStore(storage);
      when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
      when(() => storage.deleteAll()).thenAnswer((_) async {});
    });

    test('reads and writes pass through', () async {
      when(() => storage.read(key: 'k')).thenAnswer((_) async => 'v');
      when(() => storage.write(key: 'k', value: 'v')).thenAnswer((_) async {});
      expect(await store.read('k'), 'v');
      await store.write('k', 'v');
      verify(() => storage.write(key: 'k', value: 'v')).called(1);
      verifyNever(() => storage.deleteAll());
    });

    test('an unreadable entry is deleted and read as null', () async {
      when(() => storage.read(key: 'k')).thenThrow(_platformError);
      expect(await store.read('k'), isNull);
      verify(() => storage.delete(key: 'k')).called(1);
      verifyNever(() => storage.deleteAll());
    });

    test('if even the delete fails, everything is wiped', () async {
      when(() => storage.read(key: 'k')).thenThrow(_platformError);
      when(() => storage.delete(key: 'k')).thenThrow(_platformError);
      expect(await store.read('k'), isNull);
      verify(() => storage.deleteAll()).called(1);
    });

    test('a failed write wipes the store and retries once', () async {
      var attempts = 0;
      when(() => storage.write(key: 'k', value: 'v')).thenAnswer((_) async {
        if (attempts++ == 0) throw _platformError;
      });
      await store.write('k', 'v');
      expect(attempts, 2);
      verify(() => storage.deleteAll()).called(1);
    });

    test('a write that fails twice surfaces the PlatformException', () async {
      when(() => storage.write(key: 'k', value: 'v')).thenThrow(_platformError);
      await expectLater(store.write('k', 'v'), throwsA(isA<PlatformException>()));
    });

    test('delete / deleteAll never throw', () async {
      when(() => storage.delete(key: 'k')).thenThrow(_platformError);
      when(() => storage.deleteAll()).thenThrow(_platformError);
      await store.delete('k');
      await store.deleteAll();
    });
  });
}
