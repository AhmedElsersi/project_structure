// Null-safe string helpers: blank checks and a capitalize that never throws.
//
// Source: new (small helpers repeated across the in-scope apps; the house-style
//         capitalize crashed on empty strings).
import 'package:flutter/widgets.dart' show StringCharacters;

import '../utils/digits.dart';

extension NullableStringX on String? {
  /// Null, empty or only whitespace.
  bool get isBlank => this == null || this!.trim().isEmpty;

  bool get isNotBlank => !isBlank;

  /// The string, or null when blank (handy before sending optional fields).
  String? get nullIfBlank => isBlank ? null : this;
}

extension StringX on String {
  /// First user-perceived character upper-cased; safe on empty strings and
  /// scripts without case (Arabic is returned unchanged).
  String capitalize() {
    if (isEmpty) return this;
    final chars = characters;
    return chars.first.toUpperCase() + chars.skip(1).string;
  }

  /// ٠-٩ / ۰-۹ → 0-9 (for parsing user input).
  String get withWesternDigits => Digits.toWestern(this);
}
