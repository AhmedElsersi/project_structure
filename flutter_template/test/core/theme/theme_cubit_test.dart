// Tests for lib/core/theme/theme_cubit.dart. Source: new
//
// Also covers app_motion.dart.
import 'package:app_template/core/storage/key_value_store.dart';
import 'package:app_template/core/storage/storage_keys.dart';
import 'package:app_template/core/theme/app_motion.dart';
import 'package:app_template/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeCubit', () {
    test('reads the persisted mode synchronously; unknown/missing → system', () async {
      final cases = <String?, ThemeMode>{
        null: ThemeMode.system,
        'light': ThemeMode.light,
        'dark': ThemeMode.dark,
        'system': ThemeMode.system,
        'purple': ThemeMode.system,
      };
      for (final entry in cases.entries) {
        final store = MemoryKeyValueStore({if (entry.key != null) StorageKeys.themeMode: entry.key!});
        final cubit = ThemeCubit(store);
        expect(cubit.state, entry.value, reason: '${entry.key}');
        await cubit.close();
      }
    });

    test('setMode emits and persists', () async {
      final store = MemoryKeyValueStore();
      final cubit = ThemeCubit(store);
      await cubit.setMode(ThemeMode.dark);
      expect(cubit.state, ThemeMode.dark);
      expect(store.getString(StorageKeys.themeMode), 'dark');
      expect(ThemeCubit(store).state, ThemeMode.dark, reason: 'survives a restart');
      await cubit.close();
    });
  });

  group('AppMotion.of', () {
    Future<Duration> durationWith(WidgetTester tester, {required bool disableAnimations}) async {
      late Duration result;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Builder(
            builder: (context) {
              result = AppMotion.of(context, AppMotion.medium);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return result;
    }

    testWidgets('keeps the duration normally', (tester) async {
      expect(await durationWith(tester, disableAnimations: false), AppMotion.medium);
    });

    testWidgets('collapses to zero under reduced motion', (tester) async {
      expect(await durationWith(tester, disableAnimations: true), Duration.zero);
    });
  });
}
