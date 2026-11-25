# brgr-manager-old (legacy BRGR manager app)

> Legacy project superseded by `Datum/brgr`. Its `lib/core` is a fork of **brgr-old**
> (`docs/_analysis/brgr-old.md`), with the package renamed `brgr_manager`. Per the assignment, this report
> has the Summary block plus catalogs **only for core files that differ** from brgr-old
> (`diff -rq brgr/lib/core "brgr manager/lib/core"`). Everything not listed is byte-identical or
> differs only by the `package:brgr` -> `package:brgr_manager` import rename. Read brgr-old for the
> architecture, folder tree, infrastructure walkthrough and full catalogs.

## Summary for comparison

```
PROJECT: brgr-manager-old | path: Datum/old Projects/old brgr projects/brgr manager | stack: Flutter (no .fvmrc), Dart ^3.7.2, flutter_bloc 9 / go_router 16 | last commit: no git, mtime 2026-02-22 | source files: 174
ARCH: clean-arch-lite, feature-first (same core fork as brgr-old) — features/<f>/{data/{data_sources,models,repositories}, presentation/{managers|<x>_cubit,screens,widgets}}; no domain layer; features: auth, bottom_nav, checklists, home, notifications, reports, settings, shared, splash
STATE: flutter_bloc 9 (Cubits) — BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart) + BaseSingleClassStateCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/) — identical to brgr-old
DI: get_it (manual) — lib/core/services/di_container.dart (global sl + talker)
ROUTING: go_router 16 — lib/core/app_router/app_router.dart + app_routes_names.dart — ShellRoute bottom nav, state.extra args, TalkerRouteObserver; guards: none (splash token check, 401 -> login in BottomNavScreen); deep links: none
NETWORK: dio 5 — interceptors: TalkerDioLogger (LoggingInterceptor imported/registered, never attached) | token refresh: n | retry: n | error mapping: BaseRemoteDataSource status/DioException -> Failure (identical to brgr-old) | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart
RESULT_TYPE: Either (dartz) via BaseRepository.handleNetworkCall — lib/core/utilities/failures/failure.dart (identical)
STORAGE: shared_preferences + flutter_secure_storage — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart (identical); more keys (USER_TYPE, USER_ID, COMPANY_ID, USER_BRANCH_ID) in lib/core/utilities/constants/keys/shared_preferences_keys.dart
L10N: easy_localization — ar, en; start/fallback ar; assets/translations/{ar,en}.json (168/169 keys, ar missing one) — hardcoded UI strings: some (~16 Text literals + EN dialog/snackbar strings; validator returns untranslated 'validation.empty_text')
RTL: Directional=12 vs LeftRight=8 (+13 EdgeInsets.fromLTRB)
THEME: lib/core/theme/light_theme/light_theme.dart (identical to brgr-old apart from imports) — dark mode n | component themes y | AppColors (primary50 differs) | TextThemeLight | fonts Alexandria (+Cairo bundled)
RESPONSIVE: flutter_screenutil (design 393x852, minTextAdapt, splitScreenMode) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants — lib/core/utilities/constants/keys/api_keys.dart; no flavors / dart-define
LOGGING: talker (talker_flutter + talker_dio_logger) + debugPrint (45) + print (18)
ANALYTICS/CRASH: firebase_crashlytics (FlutterError.onError + runZonedGuarded) — no analytics
PUSH: fcm + flutter_local_notifications — lib/core/services/notification_service.dart (same as brgr-old, reformatted) + lib/core/services/notification_topic_handler.dart (role/lang topic subscribe/unsubscribe-all); background local-notification display commented out in lib/main.dart
PAYMENTS/IAP: none
PERMISSIONS: permission_handler (notification, mic, storage); native Android geofence service exists but Dart side lib/geofence_handler.dart is fully commented out
DEEP_LINKS: none
MEDIA/FILES: image_picker (imageQuality 75, no compression service), flutter_sound + just_audio (voice notes, local + remote), flutter_svg, Image.network, fl_chart + percent_indicator (reports), device_info_plus (device id sent at login), country_picker (imported only)
TESTS: 1 — default counter smoke test (stale)
LINTS: flutter_lints ^5.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/services/notification_topic_handler.dart — UserRole enum + NotificationTopics.{all, roleTopic}(isAr) + subscribe/unsubscribeAll helpers — quality 3 — coupling: low (role names app-specific; parseUserRole throws on unknown)
- lib/core/services/secure_storage_manager.dart — identical to brgr-old (self-healing secure storage) — quality 4 — coupling: none
- lib/core/utilities/failures/failure.dart — identical to brgr-old — quality 4 — coupling: none
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — identical to brgr-old — quality 3 — coupling: medium (sl<ApiService>())
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart — identical — quality 3 — coupling: low
- lib/core/services/app_validator.dart — regressed fork: no isNumericInRange, isNumeric regex ends in `\$` (never matches plain numbers) and an untranslated key — quality 2 — coupling: low (prefer brgr-old version)
- lib/core/services/image_picker_service.dart — simplified: pickImage(imageQuality 75) only, no tiered compression or size helpers — quality 2 — coupling: low (prefer brgr-old version)
GENERIC_WIDGETS (every reusable widget; only those differing from brgr-old are detailed — the rest are identical, see brgr-old.md):
- lib/core/utilities/widgets/buttons/app_icon_button.dart — AppIconButton + AppBackButton with locale-aware arrow (arrow_back for LTR, arrow_forward for RTL) — onTap, child, height, width, radius, backgroundColor — quality 3 — generic? y (better than brgr-old)
- lib/core/utilities/widgets/custom_chip.dart — chip with title/description, adds crossAxisAlignment + spacing params, FittedBox on description — title, description, bgColor, borderColor, radius, titleColor/FontSize, descColor/FontSize, padding, crossAxisAlignment, spacing — quality 3 — generic? y (better than brgr-old)
- lib/core/utilities/widgets/linear_progress_indicator.dart — LinearPercentIndicator on a 0-1 scale (value: percent; completed when == 1, consistent) — percent, minHeight — quality 3 — generic? y (fixes the brgr-old scale bug)
- lib/core/utilities/widgets/voice_recorder_player_widget.dart — voice note record/play, local + remote URL, 407 lines (commented legacy removed), no 1-min cap — onFileSaved, voicePath, hasDeleteButton — quality 3 — generic? y (cleanest of the three forks; listeners still not cancelled)
- lib/core/utilities/widgets/expandable_container.dart — tap-to-expand card with rotating arrow, AnimatedContainer heights — title, image, description, collapsedContent, expandedContent, collapsedHeight, expandedHeight, onToggle — quality 2 — generic? y (fixed heights, hardcoded white/shadow, Colors.grey)
- lib/core/utilities/widgets/measure_size.dart — MeasureSize reports size via post-frame callback — child, onChange — quality 2 — generic? y (wraps child in OverflowBox so it reports parent constraints, fires every build)
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget/BaseLoadingWidget/BaseErrorWidget, loading key changed to 'loading_please_wait' — successBuilder, loadingWidget, failureWidget, onRetry — quality 3 — generic? y (unused)
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — DynamicDropdownFormField<T> WITHOUT isLoading suffix (older than brgr-old) — controller, options, displayText, title, onOptionSelected, hintText, showSearch — quality 2 — generic? y
- (identical to brgr-old) app_default_button, default_screen, app_text_form_field, password/email/dropdown text fields, toasts/*, container_with_shadow, selection_chip_widget, custom_radio_group_widget, image_picker_bottom_sheet, base_list_view_widget, black_yellow_card; app_divider.dart absent
NOTABLE_IDEAS: NotificationTopicHandler role+language topic mapping with unsubscribeAll on logout/language change (lib/core/services/notification_topic_handler.dart, used in lib/features/settings/settings/presentation/screens/settings_screen.dart); device binding: login sends ANDROID_ID / identifierForVendor via device_info_plus (lib/features/auth/presentation/login_cubit/login_cubit.dart); locale-aware AppBackButton; cleaned-up voice recorder with hasDeleteButton; fl_chart reports screen (lib/features/reports/presentation/screens/reports_screen.dart)
SMELLS: core copy-pasted from brgr-old and drifting (validator regressed, image compression dropped, dropdown isLoading missing, while button/chip/progress improved); AppValidator.isNumeric regex `r'^-?\d+(\.\d+)?\$'` is broken + 'validation.empty_text' not .tr()'d; MeasureSize OverflowBox measuring bug; parseUserRole throws on unknown role; geofence_handler.dart 100% commented; background handler body commented out; LoggingInterceptor imported but unused; BaseSingleClassState failure can't be cleared (same as brgr-old); deprecated withOpacity x6, ColorScheme background/onBackground; print x18; stray sibling folder `brgr%20manager/` containing only `.dart_tool` (URL-encoded duplicate); BottomNavCubit created directly in main instead of via sl; empty dark_theme.dart / price_converter.dart; default stale test
```

---

## Differences vs brgr-old (`lib/core`)

`diff -rq` reports 38 differing files, 2 files only in brgr-old (`services/get_percentage.dart`,
`utilities/widgets/app_divider.dart`) and 3 only here (`services/notification_topic_handler.dart`,
`utilities/widgets/expandable_container.dart`, `utilities/widgets/measure_size.dart`). Most "differences"
are just the package rename in imports. The real changes:

- **Better here**: `AppBackButton` (locale-aware icon), `CustomChip` (spacing/crossAxisAlignment), `LinearPercentIndicator`
  (consistent 0-1 scale), `VoiceRecorderPlayer` (dead code removed, `hasDeleteButton`), and the new `NotificationTopicHandler`.
- **Worse here**: `AppValidator` (broken `isNumeric`, missing `isNumericInRange`), `ImagePickerService` (no compression),
  and `DynamicDropdownFormField` (no `isLoading`).
- **App-specific drift**: `AppCubit`/`AppState` (no attendance), `app_router.dart`/`app_routes_names.dart` (checklists, reports,
  notification detail), `di_container.dart`, the `api_keys.dart` endpoints, `icons.dart` (+reports/tasks/checklists/calendar...), `images.dart`,
  `colors.dart` (`primary50`), `constant_lists.dart`, `shared_preferences_keys.dart` (+user type/id, company, branch keys),
  and `date_formatter.dart` (`locale` is a required positional parameter).
- Theme files, `api_service.dart`, `toast_manager.dart`, `notification_service.dart`, the text fields and `default_screen.dart` differ only in
  imports or formatting.

`pubspec.yaml` vs brgr-old: adds `percent_indicator ^4.2.5`, `fl_chart ^0.68.0` and `device_info_plus ^12.3.0`, has `flutter_lints ^5.0.0`,
and drops the `flutter_launcher_icons` config block. All other versions are identical (same unused deps: hydrated_bloc,
cached_network_image, url_launcher, flutter_html, flutter_animate, animate_do, google_maps_flutter, geolocator).

## Services catalog (differing files only)

| File | Purpose | Public API | Dependencies | Generic? | Diff vs brgr-old |
|---|---|---|---|---|---|
| lib/core/services/notification_topic_handler.dart | Role/lang FCM topic management | `enum UserRole`; `NotificationTopics.all(isAr)`, `.roleTopic(role, isAr)`; `parseUserRole(String)`; `NotificationTopicHandler.handleNotificationsSubscriptions(context, role)`, `.unsubscribeAll(context)` | NotificationService, context.isAr | semi-generic (role list app-specific) | new |
| lib/core/services/app_validator.dart | Localized validators | same as brgr-old minus `isNumericInRange` | easy_localization | generic | regressed (broken numeric regex, untranslated key) |
| lib/core/services/image_picker_service.dart | Pick image | `pickImage(context, source)` (imageQuality 75) | image_picker | generic | simplified (no compression/size helpers) |
| lib/core/services/api_service.dart | Dio wrapper | same | dio, talker_dio_logger | generic | extra unused imports only |
| lib/core/services/get_and_set_device_locale.dart | Device locale | same | easy_localization, dart:io | generic | needless `await Platform.localeName` |
| lib/core/services/notification_service.dart | FCM + local notifications | same | same | generic | formatting only |
| lib/core/services/toast_manager.dart | Overlay toast | same | same | generic | extra import only |
| lib/core/services/di_container.dart | get_it wiring | `sl`, `talker`, `diContainerSetup()` | features (auth, home, checklists, notifications, settings...) | app-specific | feature set differs |
| lib/core/app_router/app_router.dart, app_routes_names.dart | Routes | `appRouter`, `AppRoutesNames.*` (home, checklists, checklistDetails, reports, settings, notifications, notification) | go_router | app-specific | feature set differs |
| lib/core/app_cubit/app_cubit.dart, app_state.dart | Global user state | `setUser`, `reset` | — | app-specific | attendance removed |
| lib/core/utilities/formatters/date_formatter.dart | intl formatting | `formatDateString(str, fmt, Locale?)` positional | intl | generic | signature changed |
| lib/core/utilities/constants/keys/shared_preferences_keys.dart | Storage keys | + `USER_TYPE`, `USER_ID`, `COMPANY_ID`, `USER_BRANCH_ID` (snake_case values) | — | app-specific | extended |
| lib/core/utilities/constants/keys/api_keys.dart | Base URLs + endpoints | `ApiKeys.*` | — | app-specific | endpoints differ |
| lib/core/utilities/constants/{colors,icons,images,constant_lists}.dart, enums/task_type_enum.dart, exports/core_exports.dart | Constants | — | — | app-specific | asset lists / one color / imports |
| (absent) lib/core/services/get_percentage.dart | — | — | — | — | only in brgr-old |

## Widgets catalog (differing files only)

| Path | Purpose | Constructor params | Generic? | Diff vs brgr-old |
|---|---|---|---|---|
| lib/core/utilities/widgets/buttons/app_icon_button.dart | Icon tile button + back button | onTap, child, height, width, radius, backgroundColor | y | back arrow flips with `context.isAr`; `margin: zero` instead of `padding: zero` |
| lib/core/utilities/widgets/custom_chip.dart | Title/description pill | + crossAxisAlignment, spacing | y | new params, FittedBox description |
| lib/core/utilities/widgets/linear_progress_indicator.dart | Linear progress | percent (0-1), minHeight | y | 0-1 scale (consistent) |
| lib/core/utilities/widgets/voice_recorder_player_widget.dart | Voice note record/play | onFileSaved, voicePath, hasDeleteButton | y | 407 vs 1142 lines; no max duration |
| lib/core/utilities/widgets/expandable_container.dart | Expandable card | title, image, description, collapsedContent, expandedContent, collapsedHeight, expandedHeight, onToggle | y | new |
| lib/core/utilities/widgets/measure_size.dart | Size reporter | child, onChange | y | new (buggy measurement) |
| lib/core/utilities/widgets/base_fetching_widget.dart | Fetch-state switcher | successBuilder, loadingWidget, failureWidget, onRetry | y | loading l10n key renamed |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart | Generic popup dropdown | controller, options, displayText, title, onOptionSelected, hintText, showSearch | y | no isLoading |
| lib/core/utilities/widgets/{default_screen,buttons/app_default_button,selection_chip_widget,custom_radio_group_widget}.dart, text_form_fields/{app_text_form_field,email_text_form_field,password_text_form_field}.dart | — | same as brgr-old | y | imports only |
| (absent) lib/core/utilities/widgets/app_divider.dart | — | — | — | only in brgr-old |

Feature-level reusable widgets: `lib/features/shared/widgets/image_Widget.dart` (`ImageViewerWidget`, same idea as brgr-old)
and `lib/features/shared/screens/image_viewer.dart`.

## Quality notes (delta)

- Lints: flutter_lints ^5.0.0 with no extra rules. Tests: 1 stale template test.
- Deprecated: `withOpacity` x6 and `ColorScheme.background/onBackground` (no WillPopScope here).
- Secrets: Google Maps API keys in native config (see the final message). `firebase_options.dart` and `android/app/google-services.json` exist (not opened).
