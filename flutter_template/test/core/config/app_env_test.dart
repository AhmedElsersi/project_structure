// Tests for lib/core/config/app_env.dart. Source: new
//
// AppFlavor.parse only: AppEnv getters are compile-time constants that depend
// on --dart-define, so they are not unit-testable deterministically.
import 'package:app_template/core/config/app_env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFlavor.parse', () {
    final cases = <String, AppFlavor>{
      '': AppFlavor.dev,
      '   ': AppFlavor.dev,
      'dev': AppFlavor.dev,
      'DEV': AppFlavor.dev,
      'development': AppFlavor.dev,
      'staging': AppFlavor.staging,
      ' Stage ': AppFlavor.staging,
      'prod': AppFlavor.prod,
      'PRODUCTION': AppFlavor.prod,
      'Prod\n': AppFlavor.prod,
    };
    cases.forEach((raw, flavor) {
      test('"${raw.replaceAll('\n', r'\n')}" → ${flavor.name}', () => expect(AppFlavor.parse(raw), flavor));
    });

    test('unknown values throw AppEnvError naming the value', () {
      for (final raw in ['qa', 'production2', 'prd', 'release']) {
        expect(
          () => AppFlavor.parse(raw),
          throwsA(isA<AppEnvError>().having((e) => e.message, 'message', contains('"$raw"'))),
          reason: raw,
        );
      }
    });
  });

  test('AppEnvError.toString', () {
    expect(const AppEnvError('boom').toString(), 'AppEnvError: boom');
  });
}
