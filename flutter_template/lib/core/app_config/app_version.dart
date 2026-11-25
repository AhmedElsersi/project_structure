// Version and build-number comparison without packages, numeric per segment
// ('1.10.0' > '1.9.0'), and explicit about what "unparseable" means.
//
// Source: lexa-student lib/core/utils/app_version.dart (parse / compare with a
//         `+build` and `-pre` tail ignored; isBelow FAILS CLOSED: an unreadable
//         version counts as below the floor).
// Merged: chinaparts-customer lib/core/services/app_version_comparator.dart
//         (null = "cannot determine", leading `v` tolerated, missing segments
//         are 0); baytna (gate on integer build numbers, never on strings).
// Note: the app-config UPDATE gate (update_policy.dart) is deliberately
// fail-OPEN on bad config — use [AppVersion.isBelow] only where an unknown
// version must block (e.g. a security floor sent by your backend).
// See docs/SERVICES.md#app-config.
abstract final class AppVersion {
  /// `1.2.3`, `v1.2`, `1.2.3+45`, `1.2.3-beta` → `[1, 2, 3]`. Null when any
  /// segment isn't a non-negative integer or there are more than 4 segments.
  static List<int>? parse(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final core = trimmed.split(RegExp('[+-]')).first.replaceFirst(RegExp('^[vV]'), '').trim();
    if (core.isEmpty) return null;
    final parts = core.split('.');
    if (parts.length > 4) return null;
    final segments = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part.trim());
      if (value == null || value < 0) return null;
      segments.add(value);
    }
    return segments;
  }

  /// -1, 0 or 1; `1.2` == `1.2.0`. Null when either side is unparseable —
  /// never a silent "equal".
  static int? compare(String? a, String? b) {
    final left = parse(a);
    final right = parse(b);
    if (left == null || right == null) return null;
    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l < r ? -1 : 1;
    }
    return 0;
  }

  /// True when [version] is strictly below [floor]. **Fails closed**: an
  /// unparseable side returns true.
  static bool isBelow(String? version, String? floor) {
    final result = compare(version, floor);
    return result == null || result < 0;
  }

  /// A store build number from an int, a numeric string or a double.
  /// Null for anything else, zero or negative (unknown build).
  static int? parseBuild(Object? raw) {
    final int? value = switch (raw) {
      final int v => v,
      final double v when v.isFinite && v == v.truncateToDouble() => v.toInt(),
      final String v => int.tryParse(v.trim()),
      _ => null,
    };
    return value != null && value > 0 ? value : null;
  }

  /// -1, 0 or 1 for two build numbers; null when either is unknown.
  static int? compareBuilds(Object? a, Object? b) {
    final left = parseBuild(a);
    final right = parseBuild(b);
    if (left == null || right == null) return null;
    return left.compareTo(right).sign;
  }
}
