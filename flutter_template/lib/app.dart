// Root widget: localization, theme, router, and the app-wide builder
// (damped text scale, form-factor typography, config gate, offline banner).
//
// Source: chinaparts-customer lib/main.dart (the text-scale rule applied once, in
//         MaterialApp.builder), lexa-control (ThemeMode read before runApp),
//         chinaparts-seller lib/main.dart (AppConfigGate in the builder, above the
//         router, so deep links can't bypass maintenance / force update).
// Note: MaterialApp is NOT keyed by locale (chinaparts-customer smell: full tree
//       rebuild); easy_localization's `locale` + delegates relocalize in place.
// See docs/ARCHITECTURE.md#app-root.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'core/app_config/app_config_cubit.dart';
import 'core/config/app_env.dart';
import 'core/di/injector.dart';
import 'core/localization/app_languages.dart';
import 'core/localization/generated/locale_keys.g.dart';
import 'core/responsive/app_text_scale.dart';
import 'core/responsive/breakpoints.dart';
import 'core/services/connectivity/connectivity_cubit.dart';
import 'core/services/url_service.dart';
import 'core/session/session_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'shared/widgets/app_gate/app_config_gate.dart';
import 'shared/widgets/feedback/app_snackbar.dart';
import 'shared/widgets/states/offline_banner.dart';

/// Localization wrapper — Arabic first, English second and fallback.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) => EasyLocalization(
    supportedLocales: AppLanguages.supportedLocales,
    path: AppLanguages.translationsPath,
    startLocale: AppLanguages.startLocale,
    fallbackLocale: AppLanguages.fallbackLocale,
    useOnlyLangCode: true,
    saveLocale: true,
    // Arabic needs CLDR plural forms (few/many) — "منذ 5 دقائق", not "دقيقة".
    ignorePluralRules: false,
    child: const App(),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = buildAppRouter(getIt<SessionCubit>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep network headers / formatters in sync with the UI language.
    CurrentLocale.value = context.locale;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<SessionCubit>()),
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<ConnectivityCubit>()),
        BlocProvider.value(value: getIt<AppConfigCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          onGenerateTitle: (_) => LocaleKeys.app_name.tr(),
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          scaffoldMessengerKey: AppSnackBar.messengerKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          builder: (context, child) => AppTextScale.wrap(
            context,
            Theme(
              // Slightly larger type on tablets / unfolded foldables.
              data: AppTheme.adaptTo(Theme.of(context), context.formFactor),
              child: AppConfigGate(
                onOpenStore: (url) => getIt<UrlService>().open(url ?? AppEnv.storeUrl),
                child: OfflineBanner(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
