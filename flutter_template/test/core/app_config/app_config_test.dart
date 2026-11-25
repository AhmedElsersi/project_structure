// Tests for lib/core/app_config/app_config.dart (tolerant parsing). Source: new
import 'package:app_template/core/app_config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the documented snake_case shape', () {
    final config = AppConfig.tryParse({
      'maintenance': true,
      'maintenance_message': {'ar': 'صيانة', 'en': 'Down for maintenance'},
      'android': {'min_build': 3, 'latest_build': '7', 'store_url': 'https://example.com/a'},
      'ios': {'min_build': 1, 'latest_build': 2},
    })!;

    expect(config.maintenance, isTrue);
    expect(config.maintenanceMessageFor('ar'), 'صيانة');
    expect(config.maintenanceMessageFor('en'), 'Down for maintenance');
    expect(config.maintenanceMessageFor('fr'), isNull);
    expect(config.android, const PlatformUpdatePolicy(minBuild: 3, latestBuild: 7, storeUrl: 'https://example.com/a'));
    expect(config.policyFor('ios')?.latestBuild, 2);
    expect(config.policyFor('web'), isNull);
  });

  test('accepts camelCase, a data envelope and maintenance as an object', () {
    final config = AppConfig.tryParse({
      'data': {
        'maintenance': {
          'enabled': 'true',
          'message': {'en': '  Back soon  ', 'ar': ''},
        },
        'android': {'minBuild': '4', 'latestBuild': 5.0, 'storeUrl': 'market://x'},
      },
    })!;

    expect(config.maintenance, isTrue);
    expect(config.maintenanceMessageFor('en'), 'Back soon');
    expect(config.maintenanceMessageFor('ar'), isNull, reason: 'blank messages are dropped');
    expect(config.android?.minBuild, 4);
    expect(config.android?.latestBuild, 5);
    expect(config.android?.storeUrl, 'market://x');
  });

  test('a plain string message is used for every language', () {
    final config = AppConfig.tryParse({'maintenance': 1, 'maintenance_message': 'Upgrading servers'})!;
    expect(config.maintenance, isTrue);
    expect(config.maintenanceMessageFor('ar'), 'Upgrading servers');
    expect(config.maintenanceMessageFor('en'), 'Upgrading servers');
  });

  group('garbage in → nothing to do', () {
    test('non-object bodies return null', () {
      for (final body in <Object?>[null, 'oops', 42, <Object?>[]]) {
        expect(AppConfig.tryParse(body), isNull, reason: '$body');
      }
    });

    test('bad fields fall back to defaults', () {
      final config = AppConfig.tryParse({
        'maintenance': 'sometimes',
        'maintenance_message': 12,
        'android': {'min_build': 'abc', 'latest_build': 0, 'store_url': '   '},
        'ios': ['not', 'a', 'map'],
      })!;

      expect(config.maintenance, isFalse);
      expect(config.maintenanceMessage, isEmpty);
      expect(config.android, const PlatformUpdatePolicy());
      expect(config.ios, isNull);
    });

    test('empty object', () {
      expect(AppConfig.tryParse(<String, dynamic>{}), const AppConfig());
    });
  });

  test('toJson round-trips through tryParse (used by the cache)', () {
    const config = AppConfig(
      maintenance: true,
      maintenanceMessage: {'en': 'Soon'},
      android: PlatformUpdatePolicy(minBuild: 2, latestBuild: 3, storeUrl: 'https://example.com'),
      ios: PlatformUpdatePolicy(latestBuild: 9),
    );
    expect(AppConfig.tryParse(config.toJson()), config);
  });
}
