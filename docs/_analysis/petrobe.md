# petrobe: analysis report (short, secondary)

> **petrobe is an older snapshot of petro-aman, not a separate codebase.** Its git history (59 commits, HEAD 2026-08-20 "build on ios") is entirely contained in petro-aman's history: petro-aman has those same 59 commits plus 12 more, up to 2026-09-22. The working tree is clean. Both point at the same backend (`{{BASE_URL}}`) and carry the same hardcoded keys. Everything in `docs/_analysis/petro-aman.md` applies here too, except for the differences listed below. **For the template, always prefer the petro-aman version of a file.**

## Summary for comparison

```
PROJECT: petrobe | path: Chinaparts/New Projects/petrobe | stack: Flutter (CI pins 3.38.3), Dart SDK ^3.7.2 | last commit: 2026-08-20 | source files: 449
ARCH: clean-arch-lite feature-first, no domain layer — identical to petro-aman (features/<f>/{data/{data_sources,models,repo}, presentation/{managers,screens,widgets}} on core/base_architecture); 18 features (lacks app_notifications, attendance)
STATE: flutter_bloc cubits — same two bases as petro-aman: BaseSingleClassStateCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart, 27 cubits) and BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart, 24 cubits); hydrated_bloc initialised but unused
DI: get_it, manual registration, global `diService` (~51 cubits provided app-wide in main.dart) — lib/core/services/di_container.dart
ROUTING: go_router 17 — lib/core/app_router/app_router.dart + app_routes_names.dart — ~75 flat GoRoutes, args via `state.extra` — guards? n — deep links? n (push-tap routing via lib/core/services/notification_router.dart)
NETWORK: dio — interceptors: TalkerDioLogger (/sms/ filtered); LoggingInterceptor registered but not attached | token refresh: n | retry: n | error mapping: BaseRemoteDataSource.handleRequest status/DioExceptionType → typed Failure (byte-identical to petro-aman) | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/utilities/constants/keys/api_keys.dart
RESULT_TYPE: Either (dartz) via BaseRepository.handleNetworkCall — lib/core/utilities/failures/failure.dart
STORAGE: flutter_secure_storage (token) + shared_preferences + hydrated_bloc (unused) — lib/core/services/secure_storage_manager.dart, lib/core/services/shared_preferences_manager.dart
L10N: easy_localization — ar, en; start, fallback and default ar; assets/translations/{ar,en}.json (~840 keys, older than petro-aman's) — hardcoded UI strings: some (~54 literal Text(), Arabic literals in 36 files, against ~1220 .tr())
RTL: Directional=125 vs LeftRight=84
THEME: lib/core/theme/light_theme/light_theme.dart — dark mode n (empty dark_theme.dart) | component themes y | colors class AppColors (lib/core/utilities/constants/colors.dart) | text styles class TextThemeLight | fonts Alexandria (+Cairo bundled) — identical to petro-aman
RESPONSIVE: flutter_screenutil (design 393x852, minTextAdapt) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants (ApiKeys.BASE_URL, API-key header in ApiService), no flavors — lib/core/utilities/constants/keys/api_keys.dart
LOGGING: talker (global in di_container.dart, TalkerDioLogger, TalkerRouteObserver) + print (32) + debugPrint (53); no isolate log bridge
ANALYTICS/CRASH: none
PUSH: FCM + flutter_local_notifications + flutter_foreground_task alarm — lib/core/services/notification_service.dart (older 557-line version: no payload logging, no alarm cue or volume helper, no iOS background alarm banner), notification_router.dart (identical to petro-aman)
PAYMENTS/IAP: none
PERMISSIONS: permission_handler + geolocator + local_auth — lib/core/services/permisssions_helper.dart, lib/features/home/presentation/services/permissions_service.dart, lib/core/services/silent_bypass_manager.dart (no promptIfNeeded)
DEEP_LINKS: none
MEDIA/FILES: image_picker, video_player, video_compress, image_gallery_saver_plus ^4, share_plus, screenshot, pdf/printing, qr_flutter, google_maps_flutter; no file_picker; cached_network_image declared but unused
TESTS: 1 — default counter widget_test.dart (identical, stale)
LINTS: flutter_lints ^6.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — handleRequest + Failure mapping — quality 4 — coupling: low (byte-identical to petro-aman; use either)
- lib/core/utilities/failures/failure.dart — Failure hierarchy — quality 4 — coupling: none (identical)
- lib/core/services/notification_router.dart — push type → screen router with navigator wait/dedupe — quality 4 — coupling: high (identical)
- lib/core/base_architecture/data/repository/base_repo.dart — Either wrapper — quality 3 — coupling: none (identical)
- lib/core/services/show_loading_dialog.dart — LoadingDialogService — quality 4 — coupling: low (identical)
- lib/core/services/url_manager.dart — url_launcher helpers — quality 3 — coupling: none (older: lacks openLinkInApp; prefer petro-aman)
- lib/core/services/api_service.dart — Dio wrapper — quality 3 — coupling: low (identical, same hardcoded header)
GENERIC_WIDGETS (every reusable widget):
- same catalog as petro-aman (lib/core/utilities/widgets/**), byte-identical except: dynamic_drop_down_text_field.dart (older: no searchText, showSearch defaults false, search autofocuses) — quality 3; custom_qr_widget.dart (older: no iPad sharePositionOrigin, no temp-file sweep, print instead of debugPrint) — quality 2; base_fetching_widget.dart (different l10n key only); user_selection_widget.dart (no searchText). Missing: shared/screens/attachment_viewer_screen.dart, dialogs/letter_destination_dialog.dart
NOTABLE_IDEAS: none beyond petro-aman. Every idea there (externalError field, NotificationRouter, PII-filtered TalkerDioLogger, permission rationale sheet, create_feature.dart/copy_feature.dart scaffolding, secrets-based CI) exists here in the same or an older form; NotificationLogBridge and AlarmCueService exist only in petro-aman
SMELLS: stale duplicate of petro-aman (should not be maintained in parallel); same smells as petro-aman (two cubit bases, ~51 global cubits, copied pagination in 36 files, `permissions!.contains` strings x52, withOpacity x56, WillPopScope x1, print x32, token logged at splash, empty dark theme, unused packages); 291 CRLF files; same hardcoded Maps key and API-key header in source; android/app/playstore-key.json, google-services.json, GoogleService-Info.plist and firebase_options.dart are git-tracked
```

## Differences from petro-aman

Method: `diff -rq petro_aman/lib petrobe/lib`, with line endings normalised (`tr -d '\r'`) to filter out CRLF-only noise. Infra files that differ were then inspected one by one.

**File inventory**
- petrobe has 449 Dart files, petro-aman has 485. Of petrobe's files, 407 are byte-identical and 42 differ in content. **No file exists only in petrobe.**
- Missing from petrobe (36 files): the whole `features/app_notifications/` (in-app notification centre, send-push screen, `PushNotificationGuard`) and `features/attendance/` (admin attendance listing), plus these core files:
  - `lib/core/services/notification_log_bridge.dart`
  - `lib/core/services/alarm_cue_service.dart`
  - `lib/core/services/alarm_volume_helper.dart`
  - `lib/core/utilities/constants/attachment_types.dart`
  - `lib/core/utilities/widgets/shared/screens/attachment_viewer_screen.dart`
  - `lib/core/utilities/widgets/dialogs/letter_destination_dialog.dart`

**Infra files that differ (petro-aman is the newer, better version in every case)**

| File | petrobe vs petro-aman |
|---|---|
| lib/main.dart | No `NotificationLogBridge.initMainIsolate()`. The background handler doesn't log the payload, raise alarm volume, play the stop cue or post the iOS alarm banner. No app_notifications cubits are provided. |
| lib/core/services/notification_service.dart | 557 vs 749 lines. No `logRemoteMessage`, no silent alarm channel, no `playSound:false` foreground alarm banner, no `AlarmCueService`/`AlarmVolumeHelper` calls. The foreground path shows a local notification only when `message.notification != null`, so data-only pushes are silent. `_refreshFor` has no notification-centre refresh. |
| lib/core/services/silent_bypass_manager.dart | Lacks `promptIfNeeded(context)` (re-prompt on every alarm). |
| lib/core/services/di_container.dart | Lacks the app_notifications and attendance registrations. Otherwise the same. |
| lib/core/services/url_manager.dart | Lacks `openLinkInApp` (in-app browser view). |
| lib/core/utilities/constants/keys/api_keys.dart | Lacks the attendance, app-notification and push-send endpoints. Same `BASE_URL`. |
| lib/core/app_router/app_router.dart, app_routes_names.dart | 75 vs 79 routes. No attendance, appNotifications, sendPushNotification or attachmentViewer routes. |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart | No `searchText` override, `showSearch` defaults to false, the search field autofocuses (covers the options), and the query isn't trimmed. |
| lib/core/utilities/widgets/custom_qr_widget.dart | Share has no `sharePositionOrigin` (broken on iPad), no sweep of old temp files, no `flush:true`, and uses `print`. |
| lib/core/utilities/widgets/base_fetching_widget.dart | Loading text key is `loading_please_wait` instead of `messages.loading_please_wait`. |
| lib/core/utilities/widgets/user_selection_widget.dart | No `searchText` (name + role) passed to the dropdown. |

**Feature-level differences (app-specific, not template-relevant)**
- Roles: `role_request_model.dart` sends permission ids as form data; petro-aman sends localized label/description and permission names as JSON.
- Users: add/details/working-hours screens lack the role_type- and workplace-driven form logic.
- Tasks: `task_model.dart` lacks the tolerant `_parseId` for int/string ids.
- Stations: the QR layout constants differ, and stations/images screens and cubits are older.
- Home/drawer: no attendance or notification entries.
- Profile: older version.
- The add_* screens for alerts, maintenance, notices and quality inspections are older versions (petro-aman has attachment handling).

**Non-lib differences**
- `pubspec.yaml`: version `1.0.1+26` (vs `+32`). Older firebase_core ^4.7.0, firebase_messaging ^16.2.0, cloud_firestore ^6.3.0, google_maps_flutter ^2.17.0, image_gallery_saver_plus ^4.0.1 and flutter_foreground_task ^9.2.2. No `file_picker`.
- `assets/translations/{ar,en}.json` are older (~840 vs ~940 keys).
- AndroidManifest lacks `USE_FULL_SCREEN_INTENT` and the `tools:replace` storage-permission fix.
- iOS lacks the `.caf` alarm sounds and `ios/ci_scripts/ci_post_clone.sh` (Xcode Cloud).
- petrobe keeps a stray `petro_control.iml` at the root.
- `MainActivity.kt` lacks the `alarm_audio` MethodChannel (STREAM_ALARM volume maximiser).
- Identical in both: `analysis_options.yaml`, `test/widget_test.dart`, `.github/workflows/flutter.yml`, `create_feature.dart`, `copy_feature.dart`, the other native Kotlin geofence/alarm classes, and every theme, base-architecture, storage, validator and media service file.

**Recommendation for the coordinator:** treat petrobe as superseded. Take every file from petro-aman. petrobe has no unique code worth merging.
