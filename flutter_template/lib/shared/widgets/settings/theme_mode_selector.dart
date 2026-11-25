// System / light / dark switch bound to ThemeCubit (persisted).
//
// Source: baytna lib/features/profile/presentation/pages/settings_page.dart
//         (segmented control of ThemeMode with icons, bound to the persisted
//         ThemeCubit.setMode).
// Merged: markspulse lib/core/widgets/settings/language_choice.dart (Material
//         SegmentedButton instead of a custom segmented widget).
// See docs/WIDGETS.md#settings.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/theme_cubit.dart';

/// A full-width [SegmentedButton] for [ThemeMode]. Needs a [ThemeCubit]
/// provided above (the app root provides it).
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    ButtonSegment<ThemeMode> segment(ThemeMode value, IconData icon, String label) => ButtonSegment<ThemeMode>(
      value: value,
      icon: Icon(icon),
      label: Text(label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
    );
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          segment(ThemeMode.system, Icons.brightness_auto_outlined, LocaleKeys.settings_theme_system.tr()),
          segment(ThemeMode.light, Icons.light_mode_outlined, LocaleKeys.settings_theme_light.tr()),
          segment(ThemeMode.dark, Icons.dark_mode_outlined, LocaleKeys.settings_theme_dark.tr()),
        ],
        selected: {mode},
        onSelectionChanged: (selection) => context.read<ThemeCubit>().setMode(selection.first),
      ),
    );
  }
}
