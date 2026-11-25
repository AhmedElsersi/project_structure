// Circular avatar: network photo, or Arabic-aware initials when there is no
// photo (or it fails to load).
//
// Source: baytna lib/core/widgets/app_avatar.dart (photo with the initials as
//         placeholder AND error fallback — a missing photo is the normal case;
//         grapheme-safe first character via `characters`).
// Merged: markspulse lib/core/widgets/data/initials_avatar.dart (two initials,
//         one from each of the first two names; honorifics such as «أ.» /
//         "Dr" skipped; initials excluded from semantics because the name is
//         usually next to it).
// See docs/WIDGETS.md#display.
import 'package:flutter/material.dart';

import '../media/app_network_image.dart';

/// A circular avatar of [size]. Shows [imageUrl] when it loads, otherwise
/// the initials of [name] (up to two, any script) on `primaryContainer`.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.imageUrl, this.name, this.size = 40, this.semanticLabel});

  final String? imageUrl;
  final String? name;
  final double size;

  /// Screen-reader label; null when the name is shown next to the avatar.
  final String? semanticLabel;

  static const Set<String> _honorifics = {
    'mr',
    'mrs',
    'ms',
    'miss',
    'dr',
    'prof',
    'eng',
    'أ',
    'د',
    'م',
    'أستاذ',
    'أستاذة',
    'الأستاذ',
    'الأستاذة',
    'دكتور',
    'دكتورة',
    'الدكتور',
    'الدكتورة',
    'مهندس',
    'مهندسة',
    'المهندس',
    'المهندسة',
  };

  static bool _isHonorific(String word) {
    final bare = word.toLowerCase().replaceAll(RegExp(r'[.،,]+$'), '');
    return word.endsWith('.') || _honorifics.contains(bare);
  }

  /// Up to two initials: the first grapheme of each of the first two words,
  /// skipping honorifics unless they are all there is. `?` for no name.
  static String initialsOf(String? name) {
    final words = (name ?? '').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final named = words.where((w) => !_isHonorific(w)).toList();
    final parts = named.isEmpty ? words : named;
    if (parts.isEmpty) return '?';
    final buffer = StringBuffer(parts.first.characters.first);
    if (parts.length > 1) buffer.write(parts[1].characters.first);
    return buffer.toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget initials = ExcludeSemantics(
      child: ColoredBox(
        color: scheme.primaryContainer,
        child: Padding(
          padding: EdgeInsetsDirectional.all(size * 0.22),
          // Scales the themed text to the avatar instead of a font-size literal.
          child: FittedBox(
            child: Text(
              initialsOf(name),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ),
      ),
    );

    final url = imageUrl?.trim();
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: url == null || url.isEmpty
              ? initials
              : AppNetworkImage(url: url, width: size, height: size, placeholder: initials, fallback: initials),
        ),
      ),
    );
  }
}
