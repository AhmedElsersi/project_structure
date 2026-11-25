// App version/build/platform, read once at startup; also the request headers.
//
// Source: chinaparts-customer lib/core/services/app_version_service.dart
//         (X-Platform / X-App-Version / X-Build-Number headers); fail-open
//         (AppInfo.unknown) when package info is unreadable is new.
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  const AppInfo({required this.version, required this.buildNumber, required this.packageName, required this.platform});

  final String version;
  final int buildNumber;
  final String packageName;
  final String platform;

  static const unknown = AppInfo(version: '0.0.0', buildNumber: 0, packageName: 'com.example.app', platform: 'unknown');

  Map<String, String> get headers => {
    'X-Platform': platform,
    'X-App-Version': version,
    'X-Build-Number': '$buildNumber',
  };
}

abstract final class AppInfoService {
  static Future<AppInfo> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppInfo(
        version: info.version,
        buildNumber: int.tryParse(info.buildNumber) ?? 0,
        packageName: info.packageName,
        platform: _platform(),
      );
    } on Object {
      return AppInfo.unknown;
    }
  }

  static String _platform() => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => kIsWeb ? 'web' : defaultTargetPlatform.name,
  };
}
