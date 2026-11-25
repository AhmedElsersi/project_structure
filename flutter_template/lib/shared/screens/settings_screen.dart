// Settings tab: language, appearance (theme mode) and the app version.
//
// Source: baytna lib/features/profile/presentation/pages/settings_page.dart
//         (language + theme sections, version line at the bottom).
// Merged: markspulse lib/core/widgets/settings/language_choice.dart (language
//         reachable from the main settings, named in itself); version shown
//         as `version+build` isolated LTR so it reads correctly in Arabic (new).
// See docs/WIDGETS.md#screens.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/localization/generated/locale_keys.g.dart';
import '../../core/services/app_info_service.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/display/app_card.dart';
import '../widgets/layout/app_scaffold.dart';
import '../widgets/layout/section_header.dart';
import '../widgets/settings/language_selector.dart';
import '../widgets/settings/theme_mode_selector.dart';

/// App settings. Needs a `ThemeCubit` above it (provided by the app root).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appInfo});

  final AppInfo appInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // LRI ... PDI: keeps "1.2.3+45" in one left-to-right run inside Arabic text.
    final version = '\u2066${appInfo.version}+${appInfo.buildNumber}\u2069';
    return AppScaffold(
      title: LocaleKeys.settings_title.tr(),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xl),
        children: [
          SectionHeader(title: LocaleKeys.settings_language.tr()),
          const AppCard(padding: EdgeInsets.zero, child: LanguageSelector()),
          SectionHeader(title: LocaleKeys.settings_theme.tr()),
          const ThemeModeSelector(),
          AppSpacing.gapXl,
          Text(
            LocaleKeys.settings_version.tr(args: [version]),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
