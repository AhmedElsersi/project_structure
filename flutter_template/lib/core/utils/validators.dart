// Composable form validators that return translated messages (validation.*).
//
// Source: baytna lib/core/utils/validators.dart (pure validators, messages from
//         translation keys, never hardcoded text).
// Merged: brgr lib/core/services/app_validator.dart (compose, numeric range,
//         IBAN mod-97 checksum). FIXED: the house-style isNumeric regex ended
//         in a literal `\$` inside a raw string (brgr, tebbr, chinaparts x2,
//         instaops, petrobe), so it only matched numbers followed by "$".
//         Dropped: country-specific phone rules (decision D8).
// See docs/SERVICES.md#validators.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../localization/generated/locale_keys.g.dart';
import 'digits.dart';
import 'formatters.dart';

/// Same shape as Flutter's `FormFieldValidator<String>`: null = valid,
/// otherwise the (already translated) message to show under the field.
typedef Validator = String? Function(String? value);

/// Usage:
/// ```dart
/// TextFormField(validator: Validators.compose([Validators.required(), Validators.email()]))
/// ```
///
/// Every rule except [required] ACCEPTS an empty value, so optional fields
/// work; add [required] first when the field is mandatory. Every rule takes an
/// optional `message` (already translated) to override the default sentence.
abstract final class Validators {
  /// Runs [validators] in order and returns the first error.
  static Validator compose(List<Validator> validators) => (value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  };

  /// Not null and not only whitespace.
  static Validator required({String? message}) =>
      (value) => _isEmpty(value) ? message ?? LocaleKeys.validation_required.tr() : null;

  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  /// A plausible email address (`name@domain.tld`).
  static Validator email({String? message}) => (value) {
    if (_isEmpty(value)) return null;
    return _email.hasMatch(value!.trim()) ? null : message ?? LocaleKeys.validation_email.tr();
  };

  /// At least [min] characters (user-perceived characters, so emoji count once).
  static Validator minLength(int min, {String? message}) => (value) {
    if (_isEmpty(value)) return null;
    return value!.trim().characters.length >= min
        ? null
        : message ?? LocaleKeys.validation_min_length.tr(namedArgs: {'min': AppFormat.number(min)});
  };

  /// At most [max] characters.
  static Validator maxLength(int max, {String? message}) => (value) {
    if (value == null) return null;
    return value.trim().characters.length <= max
        ? null
        : message ?? LocaleKeys.validation_max_length.tr(namedArgs: {'max': AppFormat.number(max)});
  };

  static final RegExp _phone = RegExp(r'^\+?[0-9]{7,15}$');

  /// Generic international phone: optional `+`, then 7–15 digits. Spaces,
  /// dashes, dots and parentheses are ignored; ٠-٩ / ۰-۹ are accepted.
  /// Country-specific rules belong in the app, not the template.
  static Validator phone({String? message}) => (value) {
    if (_isEmpty(value)) return null;
    return _phone.hasMatch(normalizePhone(value!)) ? null : message ?? LocaleKeys.validation_phone.tr();
  };

  /// Phone as the backend should receive it: Western digits, no separators.
  static String normalizePhone(String value) => Digits.toWestern(value).replaceAll(RegExp(r'[\s\-().]'), '');

  // The fixed house-style regex: `$` is the end anchor, not a literal dollar.
  static final RegExp _numeric = RegExp(r'^[-+]?\d+(\.\d+)?$');

  /// A plain number (`12`, `-3.5`); accepts ٠-٩ and the Arabic decimal mark.
  static Validator numeric({String? message}) => (value) {
    if (_isEmpty(value)) return null;
    return _parse(value!) == null ? message ?? LocaleKeys.validation_numeric.tr() : null;
  };

  /// A number between [min] and [max] (inclusive).
  static Validator range(num min, num max, {String? message}) => (value) {
    if (_isEmpty(value)) return null;
    final number = _parse(value!);
    if (number == null) return message ?? LocaleKeys.validation_numeric.tr();
    if (number < min || number > max) {
      return message ??
          LocaleKeys.validation_range.tr(namedArgs: {'min': AppFormat.number(min), 'max': AppFormat.number(max)});
    }
    return null;
  };

  /// Equal to the current value of another field (confirm password / email).
  static Validator match(String? Function() other, {String? message}) =>
      (value) => (value ?? '') == (other() ?? '') ? null : message ?? LocaleKeys.validation_mismatch.tr();

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _digit = RegExp(r'\p{Nd}', unicode: true);

  /// At least [minLength] characters with at least one letter and one digit.
  static Validator password({int minLength = 8, String? message}) => (value) {
    if (value == null || value.isEmpty) return null;
    final ok = value.characters.length >= minLength && _letter.hasMatch(value) && _digit.hasMatch(value);
    return ok ? null : message ?? LocaleKeys.validation_password.tr(namedArgs: {'min': AppFormat.number(minLength)});
  };

  /// An absolute http(s) URL with a host. [httpsOnly] rejects `http://`.
  static Validator url({bool httpsOnly = false, String? message}) => (value) {
    if (_isEmpty(value)) return null;
    final uri = Uri.tryParse(value!.trim());
    final ok =
        uri != null &&
        uri.isAbsolute &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || (!httpsOnly && uri.scheme == 'http'));
    return ok ? null : message ?? LocaleKeys.validation_url.tr();
  };

  static final RegExp _ibanShape = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$');

  /// An IBAN with a valid ISO 13616 mod-97 checksum (spaces allowed).
  static Validator iban({String? message}) => (value) {
    if (_isEmpty(value)) return null;
    return isValidIban(value!) ? null : message ?? LocaleKeys.validation_iban.tr();
  };

  /// Pure IBAN check: shape + mod-97 == 1.
  static bool isValidIban(String value) {
    final iban = Digits.toWestern(value).replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!_ibanShape.hasMatch(iban)) return false;
    final rearranged = iban.substring(4) + iban.substring(0, 4);
    var remainder = 0;
    for (final unit in rearranged.codeUnits) {
      // 0-9 → 0-9, A-Z → 10-35; process digit by digit to avoid BigInt.
      final digits = unit <= 0x39 ? '${unit - 0x30}' : '${unit - 55}';
      for (final d in digits.codeUnits) {
        remainder = (remainder * 10 + (d - 0x30)) % 97;
      }
    }
    return remainder == 1;
  }

  static bool _isEmpty(String? value) => value == null || value.trim().isEmpty;

  static num? _parse(String value) {
    final western = Digits.toWestern(value.trim());
    return _numeric.hasMatch(western) ? num.tryParse(western) : null;
  }
}
