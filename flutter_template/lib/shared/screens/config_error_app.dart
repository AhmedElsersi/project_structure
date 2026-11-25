// Standalone app shown when the build's configuration is invalid
// (AppEnv.validate() failed), BEFORE localization is initialised.
//
// EXCEPTION to the no-hardcoded-strings rule: easy_localization isn't running
// yet, so the config_error.* texts are duplicated here as const strings in
// Arabic AND English (keep them in sync with assets/translations/*.json).
//
// Source: new (approved: fail fast on a misconfigured build with a readable
//         screen instead of a crash).
// Merged: chinaparts-seller lib/features/app_config/presentation/widgets/app_config_gate.dart
//         (a blocking screen that sits above the whole app).
// See docs/WIDGETS.md#screens.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/responsive/app_text_scale.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Shows the configuration error in Arabic and English; [details] (which
/// variable is missing) only in debug builds.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, this.details});

  /// Developer detail, e.g. "BASE_URL is empty". Never shown in release.
  final String? details;

  static const String _titleAr = 'التطبيق غير مُهيّأ';
  static const String _messageAr = 'هذه النسخة تنقصها إعدادات أساسية. تواصل مع المطوّر.';
  static const String _titleEn = 'App not configured';
  static const String _messageEn = 'This build is missing required settings. Contact the developer.';

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    builder: (context, child) => AppTextScale.wrap(context, child ?? const SizedBox.shrink()),
    home: _ConfigErrorScreen(details: kDebugMode ? details : null),
  );
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen({this.details});

  final String? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final details = this.details;

    Widget block(String title, String message, TextDirection direction) => Directionality(
      textDirection: direction,
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: text.titleLarge),
          AppSpacing.gapSm,
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_suggest_outlined, size: AppSizes.iconLg * 2, color: theme.colorScheme.error),
                  AppSpacing.gapXl,
                  block(ConfigErrorApp._titleAr, ConfigErrorApp._messageAr, TextDirection.rtl),
                  const Padding(
                    padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xl),
                    child: Divider(),
                  ),
                  block(ConfigErrorApp._titleEn, ConfigErrorApp._messageEn, TextDirection.ltr),
                  if (details != null) ...[
                    AppSpacing.gapXl,
                    SelectableText(details, textDirection: TextDirection.ltr, style: text.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
