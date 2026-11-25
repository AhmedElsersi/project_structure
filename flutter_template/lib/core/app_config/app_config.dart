// Remote app config (maintenance flag + message, per-platform update policy),
// parsed tolerantly: garbage fields fall back to "nothing to do", never block.
//
// Source: baytna lib/features/config/domain/entities/app_config.dart +
//         data/models/app_config_model.dart (per-platform policy with INTEGER
//         build numbers, maintenance message per language, numbers typed as
//         strings still read, a missing field never resets to a blocking value).
// Merged: chinaparts-customer lib/features/app_config/data/models/responses/
//         app_config_model.dart (every section nullable; an unreadable payload
//         must never take the app down; `data` envelope).
// See docs/SERVICES.md#app-config.
import 'package:equatable/equatable.dart';

import '../utils/json_x.dart';

/// Update policy for one store. Build numbers are the monotonically
/// increasing integers the stores require — never semver strings.
class PlatformUpdatePolicy extends Equatable {
  const PlatformUpdatePolicy({this.minBuild, this.latestBuild, this.storeUrl});

  /// Builds below this are blocked (force update). Null = no floor.
  final int? minBuild;

  /// Builds below this get the optional prompt. Null = none.
  final int? latestBuild;

  /// Store listing; null = use the URL compiled into the app (AppEnv).
  final String? storeUrl;

  static PlatformUpdatePolicy? fromJson(Object? json) {
    final map = asJsonMap(json);
    if (map == null) return null;
    return PlatformUpdatePolicy(
      minBuild: _positive(map.intOrNull('min_build') ?? map.intOrNull('minBuild')),
      latestBuild: _positive(map.intOrNull('latest_build') ?? map.intOrNull('latestBuild')),
      storeUrl: map.stringOrNull('store_url') ?? map.stringOrNull('storeUrl'),
    );
  }

  Map<String, dynamic> toJson() => {'min_build': minBuild, 'latest_build': latestBuild, 'store_url': storeUrl};

  static int? _positive(int? value) => value != null && value > 0 ? value : null;

  @override
  List<Object?> get props => [minBuild, latestBuild, storeUrl];
}

class AppConfig extends Equatable {
  const AppConfig({this.maintenance = false, this.maintenanceMessage = const {}, this.android, this.ios});

  final bool maintenance;

  /// Language code → message (`{ar: ..., en: ...}`); blank entries dropped.
  final Map<String, String> maintenanceMessage;
  final PlatformUpdatePolicy? android;
  final PlatformUpdatePolicy? ios;

  /// Parses a decoded response. Accepts a `{data: {...}}` envelope, snake or
  /// camel case, `maintenance` as a bool or as `{enabled, message}`. Returns
  /// null only when [json] isn't an object at all.
  static AppConfig? tryParse(Object? json) {
    var map = asJsonMap(json);
    if (map == null) return null;
    final data = map.mapOrNull('data');
    if (data != null) map = data;

    final maintenanceMap = map.mapOrNull('maintenance');
    final maintenance = maintenanceMap != null
        ? (maintenanceMap.boolOrNull('enabled') ?? maintenanceMap.boolOr('is_active'))
        : map.boolOr('maintenance');
    final messageRaw = maintenanceMap?['message'] ?? map['maintenance_message'] ?? map['maintenanceMessage'];

    return AppConfig(
      maintenance: maintenance,
      maintenanceMessage: _messages(messageRaw),
      android: PlatformUpdatePolicy.fromJson(map['android']),
      ios: PlatformUpdatePolicy.fromJson(map['ios']),
    );
  }

  Map<String, dynamic> toJson() => {
    'maintenance': maintenance,
    'maintenance_message': maintenanceMessage,
    'android': android?.toJson(),
    'ios': ios?.toJson(),
  };

  /// The policy for `android` / `ios`; null elsewhere (web, desktop).
  PlatformUpdatePolicy? policyFor(String platform) => switch (platform.toLowerCase()) {
    'android' => android,
    'ios' => ios,
    _ => null,
  };

  /// The server's maintenance message in [languageCode] (or its
  /// language-neutral one), else null — the caller then shows the bundled
  /// translation.
  String? maintenanceMessageFor(String languageCode) =>
      maintenanceMessage[languageCode] ?? maintenanceMessage[anyLanguage];

  /// Key used when the server sends one plain string for every language.
  static const String anyLanguage = '*';

  static Map<String, String> _messages(Object? raw) {
    final map = asJsonMap(raw);
    if (map == null) {
      // A single string is used for every language.
      final text = raw is String ? raw.trim() : '';
      return text.isEmpty ? const {} : {anyLanguage: text};
    }
    return {
      for (final entry in map.entries)
        if (entry.value is String && (entry.value as String).trim().isNotEmpty)
          entry.key: (entry.value as String).trim(),
    };
  }

  @override
  List<Object?> get props => [maintenance, maintenanceMessage, android, ios];
}
