// Tolerant readers for decoded JSON maps (numbers as strings, 0/1 booleans,
// missing keys) so a sloppy payload degrades to defaults instead of crashing.
//
// Source: corsa-customer lib/core/utilities/converters/json_helpers.dart
//         (Json.intOr / doubleOr / boolOr / listOf / date).
// Merged: markspulse lib/domain/common/parse.dart idea (skip bad list items
//         instead of failing the whole list).
// See docs/SERVICES.md#json-helpers.

/// Converts any decoded JSON value to `Map<String, dynamic>` (or null).
Map<String, dynamic>? asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, v) => MapEntry('$key', v));
  return null;
}

/// Tolerant readers. Usage:
/// ```dart
/// factory Item.fromJson(Map<String, dynamic> json) => Item(
///   id: json.string('id'),
///   price: json.doubleOr('price'),
///   active: json.boolOr('is_active'),
///   tags: json.listOf('tags', Tag.fromJson),
/// );
/// ```
extension JsonX on Map<String, dynamic> {
  /// Text value (numbers/bools are stringified), or [fallback].
  String string(String key, [String fallback = '']) => stringOrNull(key) ?? fallback;

  /// Text value, or null when missing / null / blank.
  String? stringOrNull(String key) {
    final value = this[key];
    if (value == null || value is Map || value is List) return null;
    final text = '$value';
    return text.trim().isEmpty ? null : text;
  }

  /// Integer from an int, a double (truncated) or a numeric string.
  int? intOrNull(String key) => _toInt(this[key]);

  int intOr(String key, [int fallback = 0]) => intOrNull(key) ?? fallback;

  /// Double from a number or a numeric string.
  double? doubleOrNull(String key) => _toDouble(this[key]);

  double doubleOr(String key, [double fallback = 0]) => doubleOrNull(key) ?? fallback;

  /// Bool from `true`/`false`, `1`/`0`, `"true"`/`"false"`, `"1"`/`"0"`,
  /// `"yes"`/`"no"`; anything else → [fallback].
  bool boolOr(String key, [bool fallback = false]) => _toBool(this[key]) ?? fallback;

  bool? boolOrNull(String key) => _toBool(this[key]);

  /// ISO-8601 string, or epoch seconds / milliseconds (number or numeric
  /// string). Returned in local time; null when unreadable.
  DateTime? dateTime(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    final asInt = value is num ? value.toInt() : int.tryParse('$value'.trim());
    if (asInt != null) {
      // Heuristic: anything below 10^11 is seconds (until the year 5138).
      final millis = asInt.abs() < 100000000000 ? asInt * 1000 : asInt;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
    }
    return DateTime.tryParse('$value'.trim())?.toLocal();
  }

  /// Nested object, or null when missing / not an object.
  Map<String, dynamic>? mapOrNull(String key) => asJsonMap(this[key]);

  /// List of objects mapped with [mapper]. Non-object items and items whose
  /// mapper throws are skipped, so one bad row never hides the rest.
  List<T> listOf<T>(String key, T Function(Map<String, dynamic> json) mapper) {
    final value = this[key];
    if (value is! List) return <T>[];
    final result = <T>[];
    for (final item in value) {
      final map = asJsonMap(item);
      if (map == null) continue;
      try {
        result.add(mapper(map));
      } on Object {
        // Skip the malformed item.
      }
    }
    return result;
  }

  /// List of scalars as non-blank strings (`[1, "a", null]` → `['1', 'a']`).
  List<String> stringList(String key) {
    final value = this[key];
    if (value is! List) return const <String>[];
    return [
      for (final item in value)
        if (item != null && item is! Map && item is! List && '$item'.trim().isNotEmpty) '$item',
    ];
  }
}

int? _toInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.isFinite ? value.toInt() : null;
  if (value is bool) return null;
  final text = '$value'.trim();
  final parsed = int.tryParse(text);
  if (parsed != null) return parsed;
  final asDouble = double.tryParse(text);
  return asDouble != null && asDouble.isFinite ? asDouble.toInt() : null;
}

double? _toDouble(Object? value) {
  if (value == null || value is bool) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value'.trim());
}

bool? _toBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value == 1 ? true : (value == 0 ? false : null);
  return switch ('$value'.trim().toLowerCase()) {
    'true' || '1' || 'yes' => true,
    'false' || '0' || 'no' => false,
    _ => null,
  };
}
