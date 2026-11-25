// Tests for lib/core/app_config/update_policy.dart. Source: new
//
// Table of (config, installed build, platform) → GateDecision.
import 'package:app_template/core/app_config/app_config.dart';
import 'package:app_template/core/app_config/update_policy.dart';
import 'package:flutter_test/flutter_test.dart';

AppConfig _config({bool maintenance = false, int? min, int? latest, int? iosMin, int? iosLatest}) => AppConfig(
  maintenance: maintenance,
  android: PlatformUpdatePolicy(minBuild: min, latestBuild: latest),
  ios: PlatformUpdatePolicy(minBuild: iosMin, latestBuild: iosLatest),
);

void main() {
  final cases = <(String, AppConfig?, int, String, GateDecision)>[
    ('no config', null, 10, 'android', GateDecision.none),
    ('maintenance wins over force', _config(maintenance: true, min: 99), 10, 'android', GateDecision.maintenance),
    ('maintenance applies on web too', _config(maintenance: true), 10, 'web', GateDecision.maintenance),
    ('below min → force', _config(min: 11, latest: 12), 10, 'android', GateDecision.forceUpdate),
    ('equal to min, below latest → optional', _config(min: 10, latest: 12), 10, 'android', GateDecision.optionalUpdate),
    ('at latest → none', _config(min: 5, latest: 10), 10, 'android', GateDecision.none),
    ('above latest (unreleased build) → none', _config(min: 5, latest: 10), 11, 'android', GateDecision.none),
    ('only min set, below it → force', _config(min: 20), 10, 'android', GateDecision.forceUpdate),
    ('only latest set, below it → optional', _config(latest: 20), 10, 'android', GateDecision.optionalUpdate),
    ('min > latest is inconsistent → none', _config(min: 30, latest: 20), 10, 'android', GateDecision.none),
    ('unknown installed build (0) → none', _config(min: 30, latest: 40), 0, 'android', GateDecision.none),
    ('negative installed build → none', _config(min: 30), -1, 'android', GateDecision.none),
    ('iOS uses its own policy', _config(min: 99, iosMin: 1, iosLatest: 2), 10, 'ios', GateDecision.none),
    ('iOS force', _config(iosMin: 11), 10, 'ios', GateDecision.forceUpdate),
    ('platform is case-insensitive', _config(min: 11), 10, 'Android', GateDecision.forceUpdate),
    ('web / desktop never get update gates', _config(min: 99, latest: 99), 10, 'web', GateDecision.none),
    ('empty policies → none', const AppConfig(), 10, 'android', GateDecision.none),
  ];

  for (final (name, config, build, platform, expected) in cases) {
    test(name, () {
      expect(UpdatePolicy.decide(config: config, installedBuild: build, platform: platform), expected);
    });
  }

  test('garbage JSON parses to a config that never gates', () {
    final config = AppConfig.tryParse({
      'maintenance': 'maybe',
      'android': {'min_build': 'abc', 'latest_build': -4},
      'ios': 'nope',
    });
    expect(UpdatePolicy.decide(config: config, installedBuild: 3, platform: 'android'), GateDecision.none);
    expect(UpdatePolicy.decide(config: config, installedBuild: 3, platform: 'ios'), GateDecision.none);
  });

  test('isBlocking', () {
    expect(GateDecision.maintenance.isBlocking, isTrue);
    expect(GateDecision.forceUpdate.isBlocking, isTrue);
    expect(GateDecision.optionalUpdate.isBlocking, isFalse);
    expect(GateDecision.none.isBlocking, isFalse);
  });
}
