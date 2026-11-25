# brgr-maintenance-old (legacy BRGR maintenance-technician app)

> Legacy project superseded by `Datum/brgr`. Its `lib/core` is a fork of **brgr-old**
> (`docs/_analysis/brgr-old.md`), with the package renamed `brgr_maintenance` and older dependency versions
> (flutter_bloc 8, go_router 14, talker 4). Per the assignment, this report has the Summary block plus
> catalogs **only for core files that differ** from brgr-old (`diff -rq brgr/lib/core brgr_maintenance/lib/core`).
> Everything not listed is byte-identical or differs only by the package-name import rename.
> Read brgr-old for the architecture, folder tree, infrastructure walkthrough and full catalogs.

## Summary for comparison

```
PROJECT: brgr-maintenance-old | path: Datum/old Projects/old brgr projects/brgr_maintenance | stack: Flutter (no .fvmrc), Dart ^3.7.2, flutter_bloc ^8.1.6 / go_router ^14.6.2 | last commit: no git, mtime 2026-02-08 | source files: 147
ARCH: clean-arch-lite, feature-first (same core fork as brgr-old) — features/<f>/{data/{data_sources,models,repositories}, presentation/{managers|<x>_cubit,screens,widgets}}; no domain layer; features: auth, bottom_nav, maintenance, notifications, settings, shared, splash
STATE: flutter_bloc 8 (Cubits) — BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart) + BaseSingleClassStateCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/) — identical to brgr-old
DI: get_it (manual) — lib/core/services/di_container.dart (global sl + talker)
ROUTING: go_router 14 — lib/core/app_router/app_router.dart + app_routes_names.dart — ShellRoute bottom nav, state.extra args, TalkerRouteObserver; guards: none (splash token check, 401 -> login in BottomNavScreen); deep links: none
NETWORK: dio 5 — interceptors: TalkerDioLogger (LoggingInterceptor never attached) | token refresh: n | retry: n | error mapping: BaseRemoteDataSource status/DioException -> Failure (identical to brgr-old) | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart
RESULT_TYPE: Either (dartz) via BaseRepository.handleNetworkCall — lib/core/utilities/failures/failure.dart (identical)
STORAGE: shared_preferences + flutter_secure_storage — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart (identical); + USER_ID, USER_BRANCH_ID keys
L10N: easy_localization — ar, en; start/fallback ar; assets/translations/{ar,en}.json (177/171 keys, out of sync) — hardcoded UI strings: some (~13 EN Text literals + EN dialog/snackbar strings; validator returns untranslated 'validation.empty_text')
RTL: Directional=15 vs LeftRight=9 (+10 EdgeInsets.fromLTRB)
THEME: lib/core/theme/light_theme/light_theme.dart — dark mode n | component themes y (input borders flattened to secondary300 / 1.w) | AppColors (identical) | TextThemeLight | fonts Alexandria (+Cairo bundled)
RESPONSIVE: flutter_screenutil (design 393x852, minTextAdapt, splitScreenMode) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants — lib/core/utilities/constants/keys/api_keys.dart; no flavors / dart-define
LOGGING: talker 4 (talker_flutter + talker_dio_logger) + debugPrint (69) + print (11)
ANALYTICS/CRASH: firebase_crashlytics (FlutterError.onError only; no runZonedGuarded / PlatformDispatcher.onError) — no analytics
PUSH: fcm + flutter_local_notifications — lib/core/services/notifications_service.dart (renamed; first 261 lines = commented old copy; active version adds Android channel creation + setForegroundNotificationPresentationOptions(false)); background handler in lib/main.dart only prints (no @pragma('vm:entry-point'))
PAYMENTS/IAP: none
PERMISSIONS: permission_handler ^11 (notification, mic, storage)
DEEP_LINKS: none (url_launcher used to open external Google Maps directions)
MEDIA/FILES: image_picker + flutter_image_compress (service identical to brgr-old), flutter_sound + just_audio (local-only voice notes), flutter_svg, url_launcher, device_info_plus (device id at login), wakelock_plus (imported, call commented)
TESTS: 1 — default counter smoke test (stale)
LINTS: flutter_lints ^5.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/services/secure_storage_manager.dart — identical to brgr-old — quality 4 — coupling: none
- lib/core/utilities/failures/failure.dart — identical to brgr-old — quality 4 — coupling: none
- lib/core/services/image_picker_service.dart — identical to brgr-old (tiered compression) — quality 3 — coupling: low
- lib/core/services/notifications_service.dart — brgr-old service + explicit Android channels (default, geofence) + iOS foreground presentation disabled to avoid duplicates — quality 3 — coupling: low (channel creation calls `AndroidFlutterLocalNotificationsPlugin()` directly, not via resolvePlatformSpecificImplementation, and is not awaited; 261 commented lines)
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — identical — quality 3 — coupling: medium (sl<ApiService>())
- lib/core/services/app_validator.dart — same regression as brgr-manager-old (no isNumericInRange, broken isNumeric regex) — quality 2 — coupling: low (prefer brgr-old)
GENERIC_WIDGETS (every reusable widget; only those differing from brgr-old are detailed — the rest are identical, see brgr-old.md):
- lib/core/utilities/widgets/buttons/app_default_button.dart — StatelessWidget variant: AnimatedSwitcher circular loader, disabled color only when enabled=false, no tap lock; old build kept commented — onTap, text, textStyle, child, height, width, radius, margin, padding, isLoading, backgroundColor, textColor, enabled, svgIconPath, borderColor — quality 2 — generic? y (brgr-old version preferred)
- lib/core/utilities/widgets/buttons/app_icon_button.dart — AppIconButton + locale-aware AppBackButton (same as brgr-manager-old) — onTap, child, height, width, radius, backgroundColor — quality 3 — generic? y
- lib/core/utilities/widgets/linear_progress_indicator.dart — 0-1 scale LinearPercentIndicator (consistent) — percent, minHeight — quality 3 — generic? y
- lib/core/utilities/widgets/voice_recorder_player_widget.dart — local-only record/play (no remote URL player), 625 lines (289 commented) — onFileSaved, voicePath — quality 2 — generic? partly
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — DynamicDropdownFormField<T> without isLoading — controller, options, displayText, title, onOptionSelected, hintText, showSearch — quality 2 — generic? y
- lib/core/services/toast_manager.dart (+ toasts/animated_custom_toast.dart) — overlay toast, default location Alignment.topCenter — context, message, state, location, duration — quality 3 — generic? y
- (identical / imports only) default_screen, base_fetching_widget, base_list_view_widget, app_text_form_field, password/email/dropdown text fields, toasts/custom_toast, container_with_shadow, custom_chip, selection_chip_widget, custom_radio_group_widget, image_picker_bottom_sheet, black_yellow_card; app_divider.dart absent
NOTABLE_IDEAS: Android notification channels created up front + `setForegroundNotificationPresentationOptions(alert:false,...)` so foreground FCM is shown only once via local notifications (lib/core/services/notifications_service.dart); device id (ANDROID_ID / identifierForVendor) sent at login (lib/features/auth/presentation/login_cubit/login_cubit.dart); external Google Maps directions via url_launcher (lib/features/maintenance/presentation/screens/maintenance_details_screen.dart)
SMELLS: core copy-pasted and drifting (AppDefaultButton lost tap lock, validator regressed, dropdown lost isLoading); notifications_service.dart keeps a full commented copy of itself; channel creation bypasses the plugin instance and isn't awaited; background FCM handler lacks @pragma('vm:entry-point') and only prints; no runZonedGuarded so async errors don't reach Crashlytics; translations out of sync (ar 177 vs en 171); DateFormatter.formatDateString dropped locale; deprecated withOpacity x4, ColorScheme background/onBackground; print x11 + debugPrint x69; older dependency majors than siblings (flutter_bloc 8, go_router 14, talker 4, permission_handler 11, skeletonizer 1, hydrated_bloc 9 unused); unused deps (hydrated_bloc, cached_network_image, flutter_html, flutter_animate, animate_do, google_maps_flutter, skeletonizer, dotted_border, wakelock_plus); empty dark_theme.dart / price_converter.dart; stale default test
```

---

## Differences vs brgr-old (`lib/core`)

`diff -rq` reports 36 differing files. Only in brgr-old: `base_architecture/data/models/id_title_model.dart`,
`enums/task_type_enum.dart`, `services/get_percentage.dart`, `services/notification_service.dart` (renamed here to
`notifications_service.dart`), and `utilities/widgets/app_divider.dart`. Nothing in this core is missing from brgr-old except
the renamed notifications file.

- **Better here**: `notifications_service.dart` (Android channels, iOS foreground de-duplication), `AppBackButton` (locale-aware),
  and `LinearPercentIndicator` (consistent 0-1 scale).
- **Worse here**: `AppDefaultButton` (no tap lock, stateless), `AppValidator` (same breakage as brgr-manager-old), `DynamicDropdownFormField`
  (no `isLoading`), `DateFormatter.formatDateString` (no locale), the voice recorder (no remote playback), and `main.dart` (no `runZonedGuarded`).
- **Theme**: `input_decoration_theme.dart` uses uniform `secondary300` borders at `1.w` (brgr-old uses secondary100/200 at 1.1-1.2.w),
  and `elevated_btn_theme.dart` and `snack_bar_theme.dart` differ in imports only.
- **App-specific drift**: `app_cubit`, `app_router` (maintenance, maintenanceTask, completeTask, addTaskReport, successTask,
  notifications, notification, notificationDetails, settings), `di_container`, `api_keys`, `icons` (+maintenanceSuccess), `images`,
  `constant_lists`, and `shared_preferences_keys` (+USER_ID, USER_BRANCH_ID).
- `base_state.dart` differs only by the trailing newline.

`pubspec.yaml` vs brgr-old: older majors (flutter_bloc ^8.1.6, go_router ^14.6.2, permission_handler ^11.3.1,
talker_flutter/talker_dio_logger ^4.6.0, skeletonizer ^1.4.2, animate_do ^3.3.4, hydrated_bloc ^9.1.5, dotted_border ^2.1.0),
geolocator commented out, plus wakelock_plus ^1.3.2 and device_info_plus ^12.3.0, flutter_lints ^5.0.0, and a separate
`flutter_launcher_icons.yaml`.

## Services catalog (differing files only)

| File | Purpose | Public API | Dependencies | Generic? | Diff vs brgr-old |
|---|---|---|---|---|---|
| lib/core/services/notifications_service.dart | FCM + local notifications | same static API as brgr-old (`init(context)`, `showLocalNotification`, `showGeofenceNotification`, cancel*, subscribe/unsubscribe) + private `_createNotificationChannels()` | firebase_messaging, flutter_local_notifications, permission_handler | generic | renamed; channels + foreground options added; 261 commented lines |
| lib/core/services/app_validator.dart | Localized validators | brgr-old API minus `isNumericInRange` | easy_localization | generic | regressed |
| lib/core/services/toast_manager.dart | Overlay toast | same; default `location ?? Alignment.topCenter` | AnimatedCustomToast | generic | default position |
| lib/core/services/api_service.dart | Dio wrapper | same | dio, talker_dio_logger 4 | generic | unused import only |
| lib/core/services/get_and_set_device_locale.dart | Device locale | same | easy_localization, dart:io | generic | needless await |
| lib/core/services/di_container.dart | get_it wiring | `sl`, `talker`, `diContainerSetup()` | features (auth, maintenance, notifications, settings, bottom_nav home) | app-specific | feature set differs |
| lib/core/app_router/app_router.dart, app_routes_names.dart | Routes | `appRouter`, `AppRoutesNames.*` | go_router 14 | app-specific | feature set differs |
| lib/core/app_cubit/app_cubit.dart, app_state.dart | Global user state | `setUser`, `reset` | — | app-specific | attendance removed |
| lib/core/utilities/formatters/date_formatter.dart | intl formatting | `formatDateString(str, fmt)` (no locale), `formatDate`, `isMorning` | intl | generic | locale dropped |
| lib/core/utilities/constants/keys/shared_preferences_keys.dart | Storage keys | + `USER_ID`, `USER_BRANCH_ID` | — | app-specific | extended |
| lib/core/utilities/constants/{api_keys,icons,images,constant_lists,colors}.dart, exports/core_exports.dart | Constants | — | — | app-specific | assets/endpoints/imports |
| (absent) services/get_percentage.dart, base_architecture/data/models/id_title_model.dart, enums/task_type_enum.dart | — | — | — | — | only in brgr-old |

## Widgets catalog (differing files only)

| Path | Purpose | Constructor params | Generic? | Diff vs brgr-old |
|---|---|---|---|---|
| lib/core/utilities/widgets/buttons/app_default_button.dart | Primary button with loader | onTap, text, textStyle, child, height, width, radius, margin, padding, isLoading, backgroundColor, textColor, enabled, svgIconPath, borderColor | y | Stateless, no `blockMultipleClicks`/`svgIconColor`, commented legacy build |
| lib/core/utilities/widgets/buttons/app_icon_button.dart | Icon tile + back button | onTap, child, height, width, radius, backgroundColor | y | locale-aware back arrow |
| lib/core/utilities/widgets/linear_progress_indicator.dart | Linear progress | percent (0-1), minHeight | y | 0-1 scale |
| lib/core/utilities/widgets/voice_recorder_player_widget.dart | Voice note record/play | onFileSaved, voicePath | partly | local-only, 625 lines |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart | Generic popup dropdown | controller, options, displayText, title, onOptionSelected, hintText, showSearch | y | no isLoading |
| lib/core/utilities/widgets/{default_screen,base_fetching_widget,custom_chip,selection_chip_widget,custom_radio_group_widget}.dart, text_form_fields/{app_text_form_field,email_text_form_field,password_text_form_field}.dart | — | same as brgr-old | y | imports only |
| (absent) lib/core/utilities/widgets/app_divider.dart | — | — | — | only in brgr-old |

Feature-level reusable widgets: `lib/features/shared/widgets/image_Widget.dart` (`ImageViewerWidget`) and
`lib/features/shared/screens/image_viewer.dart`, the same pattern as brgr-old.

## Quality notes (delta)

- Lints: flutter_lints ^5.0.0 with no extra rules. Tests: 1 stale template test.
- Deprecated: `withOpacity` x4 and `ColorScheme.background/onBackground`.
- Secrets: no API keys matched in native config. `firebase_options.dart` and `android/app/google-services.json` exist (not opened).
