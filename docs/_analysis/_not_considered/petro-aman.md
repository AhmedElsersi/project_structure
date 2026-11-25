# petro-aman: analysis report

## Summary for comparison

```
PROJECT: petro-aman | path: Chinaparts/New Projects/petro_aman | stack: Flutter (CI pins 3.38.3), Dart SDK ^3.7.2 | last commit: 2026-09-22 | source files: 485
ARCH: clean-arch-lite feature-first, no domain layer — features/<f>/{data/{data_sources,models,repo}, presentation/{managers,screens,widgets}} on top of core/base_architecture base classes (BaseRemoteDataSource -> BaseRepository(Either) -> cubit)
STATE: flutter_bloc cubits only (0 Blocs). Two parallel bases: BaseSingleClassStateCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart, 29 cubits, one state class with FetchDataStatusEnum) and BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart, 26 cubits, sealed multi-class states). hydrated_bloc storage is initialised but no cubit is hydrated
DI: get_it, manual registration, global `diService`. Data sources and repos are lazySingletons, cubits are factories (~54 provided app-wide in main.dart MultiBlocProvider) — lib/core/services/di_container.dart
ROUTING: go_router 17 — lib/core/app_router/app_router.dart + app_routes_names.dart — ~79 flat GoRoutes, args passed via `state.extra as T` casts — guards? n (no redirect; splash decides by token; RBAC checked per screen) — deep links? n (push-tap routing only, via lib/core/services/notification_router.dart)
NETWORK: dio — interceptors: TalkerDioLogger (filters /sms/ paths out of logs); LoggingInterceptor is registered in DI but never attached | token refresh: n | retry: n | error mapping: BaseRemoteDataSource.handleRequest maps DioExceptionType (timeouts, connectionError) plus status 400/401/403/404/422/500 to typed Failures and parses `errors` (list or field map) into ErrorDetail | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/utilities/constants/keys/api_keys.dart
RESULT_TYPE: Either (dartz) via BaseRepository.handleNetworkCall — lib/core/utilities/failures/failure.dart (+ error_details_model.dart)
STORAGE: flutter_secure_storage (token), shared_preferences (flags), hydrated_bloc (initialised, unused) — lib/core/services/secure_storage_manager.dart, lib/core/services/shared_preferences_manager.dart
L10N: easy_localization — ar, en; start, fallback and default locale ar; assets/translations/{ar,en}.json (~940 nested keys) — hardcoded UI strings: some (~54 literal Text(), Arabic literals in 36 files, against ~1330 .tr() calls)
RTL: Directional=139 vs LeftRight=87
THEME: lib/core/theme/light_theme/light_theme.dart — dark mode n (dark_theme.dart is an empty file) | component themes in ThemeData y (appBar, elevated/text/button, input, dialog, snackBar, bottomNav, progress) | colors class AppColors (lib/core/utilities/constants/colors.dart, 47 consts) | text styles class TextThemeLight singleton (light_widget_themes/text_theme.dart, full M3 TextTheme) | fonts Alexandria in the theme (Cairo bundled but unused)
RESPONSIVE: flutter_screenutil (design size 393x852, minTextAdapt, splitScreenMode) — breakpoints: none
TEXT_SCALING: none (no textScaler clamp; relies on .sp)
ENV/FLAVORS: hardcoded constants (ApiKeys.BASE_URL with commented-out alternatives; static API-key header inside ApiService); no flavors, dotenv or dart-define — lib/core/utilities/constants/keys/api_keys.dart, lib/core/services/api_service.dart
LOGGING: talker (global `talker` in di_container.dart, TalkerDioLogger, TalkerRouteObserver, isolate log bridge), plus print (28 calls) and debugPrint (64); AppBlocObserver prints every transition. No in-app TalkerScreen is wired up
ANALYTICS/CRASH: none
PUSH: FCM + flutter_local_notifications + flutter_foreground_task (looping fire-alarm service), iOS critical alerts — lib/core/services/notification_service.dart, notification_router.dart, notification_log_bridge.dart, alarm_*.dart
PAYMENTS/IAP: none
PERMISSIONS: permission_handler + geolocator + local_auth — lib/core/services/permisssions_helper.dart, lib/features/home/presentation/services/permissions_service.dart (multi-permission rationale sheet), lib/core/services/silent_bypass_manager.dart (Android DND / iOS critical-alert opt-in)
DEEP_LINKS: none (only mapping FCM data.type to a screen)
MEDIA/FILES: image_picker (+video_compress), video_player, file_picker, image_gallery_saver_plus, share_plus, screenshot, pdf/printing, qr_flutter, google_maps_flutter, geolocator; cached_network_image, flutter_html, animate_do, country_picker, pretty_qr_code, package_info_plus are declared but never imported
TESTS: 1 — default counter widget_test.dart (stale; would fail)
LINTS: flutter_lints ^6.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — generic handleRequest<T>(path, method, parser) with full Dio/status → Failure mapping and `errors` list/map parsing — quality 4 — coupling: low (resolves ApiService through the diService locator; one print)
- lib/core/utilities/failures/failure.dart — Failure hierarchy implementing Exception (BadRequest/Unauthorized/Forbidden/NotFound/Validation/Server/Network/Timeout/Cache/Unknown, code + ErrorDetail list) — quality 4 — coupling: none (CacheFailure drops its message)
- lib/core/services/notification_router.dart — FCM data.type → screen router: waits for the navigator to be past splash/auth, dedupes taps for 3s, fetches the model behind a blocking loader, falls back to Home — quality 4 (pattern) — coupling: high (app types, repos, routes)
- lib/core/services/notification_log_bridge.dart — relays logs from the FCM background isolate to the main-isolate talker via IsolateNameServer, parks them in SharedPreferences when the app is terminated (capped at 50) — quality 4 — coupling: low (global talker)
- lib/core/base_architecture/data/repository/base_repo.dart — BaseRepository.handleNetworkCall → Either<Failure,T> — quality 3 — coupling: none (only catches Failure; anything else escapes)
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart (+ base_single_class_state.dart) — single-state cubit base with status enum and overridable loading/failure hooks — quality 3 — coupling: none (`as State` casts; copyWith can't clear failure)
- lib/core/services/api_service.dart — Dio wrapper (get/post/put/patch/delete via NetworkRequestParams, updateHeaders for token/locale) — quality 3 — coupling: low (static API-key header, async header init in constructor = race on first call)
- lib/core/services/show_loading_dialog.dart — LoadingDialogService.show/hide, re-entrancy safe, captures its own dialog context — quality 4 — coupling: low (AppColors)
- lib/core/services/toast_manager.dart (+ widgets/toasts/animated_custom_toast.dart) — overlay toast with context.showToast extension and success/failure/warning states — quality 3 — coupling: low (failure colour is the brand green)
- lib/features/home/presentation/services/permissions_service.dart — ensureAttendancePermissions: rationale bottom sheet → request → permanently-denied dialog → re-check — quality 4 — coupling: low (permission list hardcoded at file top)
- lib/core/services/url_manager.dart — UrlManagerService: call, mail, external/in-app link, map by coords or address — quality 4 — coupling: none
- lib/core/services/image_downloader_service.dart — download an image to the gallery with SDK-aware permission (no permission on Android 29+, add-only on iOS) — quality 4 — coupling: none (print)
- lib/core/services/app_validator.dart — static validators returning easy_localization keys (email, phone, Saudi phone, password, confirm, IBAN mod-97, compose) — quality 3 — coupling: low (isNumeric regex bug and one untranslated key)
- lib/core/services/secure_storage_manager.dart / shared_preferences_manager.dart — thin storage wrappers — quality 3 — coupling: none
- lib/core/services/debounce.dart — Timer-based Debounce — quality 4 — coupling: none
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/buttons/app_default_button.dart — primary button — text, onTap, isLoading (collapses to a circle), enabled, svgIconPath, gradient, width/height/radius, margin/padding, colours, blockMultipleClicks — quality 3 — generic? y (enabled/disabled text colours are swapped; tap lock useless with a sync onTap; 115 lines of the old version left commented out)
- lib/core/utilities/widgets/buttons/app_icon_button.dart — AppIconButton + AppBackButton (flips the arrow for RTL) — child, onTap, size, radius, colours, isLoading — quality 3 — generic? y (AppBackButton has no default pop)
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — titled text field — title, controller, hint, validator, externalError (backend error wins), prefix/suffix, formatters, maxLines, focus, callbacks — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password field with visibility toggle on top of AppTextFormField — controller, isConfirmPassword, confirmPasswordValidator, isLogin — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart — email field — controller, title, hint, readOnly — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/date_picker_text_form_field.dart — DateTimeTextFormField + pickDate/pickTime helpers — controller, isDate, pickDay, readOnly — quality 3 — generic? y (one hardcoded Arabic dialog title)
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart — string dropdown opened as a bottom sheet — items, controller, validator — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — generic searchable DynamicDropdownFormField<T> (showMenu anchored to the field) — options, displayText, searchText, widgetBuilder, showSearch — quality 4 — generic? y (menu position computed LTR-only)
- lib/core/utilities/widgets/default_screen.dart — base scaffold with title row and back button — body, pageTitle/pageTitleWidget, hasAppBar, hasBackButton, paddings, FAB — quality 3 — generic? y (used by only 2 screens)
- lib/core/utilities/widgets/custom_appbar.dart — CustomAppBar extends PreferredSize — pageTitle, actions — quality 2 — generic? y (unused; arrow_back_ios not RTL-aware)
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget<B,S,T> status switch + BaseLoadingWidget + BaseErrorWidget(retry) — successBuilder, loadingWidget, failureWidget, onRetry — quality 3 — generic? y (never used)
- lib/core/utilities/widgets/base_list_view_widget.dart — BaseListView<T> with empty state — items, itemBuilder, emptyWidget — quality 2 — generic? y (unused; default empty text is 'no_tasks')
- lib/core/utilities/widgets/failure_widget.dart — error + retry — errorMessage, onTapRetry — quality 2 — generic? n (message key is categories-specific)
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart — animated overlay toast — message, state, duration, location — quality 3 — generic? y
- lib/core/utilities/widgets/toasts/custom_toast.dart — static toast body — message, state — quality 2 — generic? y
- lib/core/utilities/widgets/container_with_shadow.dart — card container — child, padding, margin, radius, border, boxShadow, image, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/custom_chip.dart — chip — title, colours, radius, padding, onSelect — quality 3 — generic? y
- lib/core/utilities/widgets/selection_chip_widget.dart — selectable chip — isSelected, title, onTap, colours — quality 3 — generic? y
- lib/core/utilities/widgets/custom_radio_group_widget.dart — CustomRadioGroup<T> + animated CustomSizeRadio<T> — options, selectedValue, label, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/expandable_widget.dart — ExpandableContainer — title, description, expandedContent — quality 3 — generic? y
- lib/core/utilities/widgets/app_divider.dart — divider — height, thickness, colour, indents — quality 3 — generic? y
- lib/core/utilities/widgets/linear_progress_indicator.dart — LinearPercentIndicator — percent, minHeight — quality 3 — generic? y
- lib/core/utilities/widgets/animated_indicator.dart — step/page dot indicator — index, currentStep — quality 3 — generic? y
- lib/core/utilities/widgets/title_value_widget.dart — label/value row — title, value, valueStyle — quality 3 — generic? y
- lib/core/utilities/widgets/question_answer_widget.dart — Q/A row — question, answer, highlight — quality 3 — generic? y
- lib/core/utilities/widgets/image_picker_bottom_sheet.dart — showImagePickerSheet camera/gallery — callbacks — quality 3 — generic? y
- lib/core/utilities/widgets/image_picker_widget.dart — SingleImagePickerWidget — imagePath, onPickImage, onRemoveImage, size, radius — quality 3 — generic? y
- lib/core/utilities/widgets/shared/widgets/image_Widget.dart — ImageViewerWidget: works out asset/file/network from the string, optional download/share with a progress overlay, remove button — image, size, radius, fit, onTap, onTapRemove, hasDownloadBtn, hasShareBtn — quality 3 — generic? y (plain Image.network, so no caching; file name casing)
- lib/core/utilities/widgets/shared/widgets/video_widget.dart — VideoViewerWidget thumbnail/inline player — video, size, autoPlay, loop, onTapRemove — quality 3 — generic? y
- lib/core/utilities/widgets/shared/screens/image_viewer.dart — full-screen image — imagePath — quality 3 — generic? y
- lib/core/utilities/widgets/shared/screens/video_viewer.dart — FullScreenVideoPlayer — video, autoPlay, loop — quality 3 — generic? y
- lib/core/utilities/widgets/shared/screens/attachment_viewer_screen.dart — downloads and previews PDF/image attachments (printing), with an "open externally" action — url — quality 3 — generic? y
- lib/core/utilities/widgets/shared/screens/select_location_screen.dart — Google Maps location picker plus reverse geocode — none — quality 3 — generic? partly (GoogleMapsService has a hardcoded key)
- lib/core/utilities/widgets/custom_qr_widget.dart — CustomQrWidget + QrCodeService (screenshot → gallery/share, iPad sharePositionOrigin) — data, size, colours, hasDownloadBtn, hasShareBtn — quality 3 — generic? partly (stationCode param, demo screen left in)
- lib/core/utilities/widgets/silent_bypass_disabled_widget.dart — "enable silent bypass" banner listening to SilentBypassManager — margin — quality 3 — generic? n (hardcoded Arabic)
- lib/core/utilities/widgets/statistics_view.dart — stats tiles — statistics — quality 3 — generic? n
- lib/core/utilities/widgets/user_selection_widget.dart — user picker tied to UsersCubit — quality 3 — generic? n
- lib/core/utilities/widgets/dialogs/letter_destination_dialog.dart — bilingual text dialog — quality 3 — generic? n
NOTABLE_IDEAS: (1) BaseRemoteDataSource.handleRequest + Failure hierarchy with ErrorDetail parsing for both `errors: [..]` and `errors: {field: [..]}` (lib/core/base_architecture/data/data_sources/base_remote_data_source.dart); (2) AppTextFormField.externalError puts backend 422 messages ahead of local validators (lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart); (3) NotificationRouter waits for the navigator, dedupes and loads by id (lib/core/services/notification_router.dart); (4) NotificationLogBridge carries logs across isolates (lib/core/services/notification_log_bridge.dart); (5) TalkerDioLogger request/response/error filters that keep PII endpoints out of logs (lib/core/services/api_service.dart); (6) _refreshFor reads cubits off the live navigator context because factory cubits from get_it would be fresh instances (lib/core/services/notification_service.dart); (7) multi-permission rationale sheet flow (lib/features/home/presentation/services/permissions_service.dart); (8) SDK-aware gallery-save permission (lib/core/services/image_downloader_service.dart); (9) feature scaffolding scripts create_feature.dart and copy_feature.dart at the repo root (the latter clones a feature with name replacements and patches router/DI/api keys); (10) PushNotificationGuard central permission gate plus unauthorized fallback scaffold (lib/features/app_notifications/presentation/push_notification_guard.dart); (11) AppValidator.customValidator composes validators; (12) CI workflow builds from GitHub secrets (.github/workflows/flutter.yml)
SMELLS: two competing cubit bases (BaseCubit vs BaseSingleClassStateCubit); ~54 cubits created globally in main.dart; `state.user!.permissions!.contains("x.y")` string checks x54 (~94 `.permissions` references); the hasReachedMax pagination pattern copied into 42 files with no generic paginated cubit; list add/remove mutates state lists in place (Equatable won't emit) e.g. NoticesCubit; copyWith can't clear nullable fields (AppState.user, failure); GenericFetchWidget/BaseListView/CustomAppBar are dead code; dark_theme.dart and price_converter.dart are empty; hydrated_bloc initialised but unused; ColorScheme uses deprecated background/onBackground; withOpacity x56 (mixed with withValues x43); WillPopScope x1 (attendance_dialog.dart); print x28; logs the API token at splash (talker.info); hardcoded Arabic strings in services/widgets (ImagePickerService snackbars, alarm fallback text); raw Colors.* x401; failure toast and input errorBorder use the brand green rather than red; inverted button text colours; PermissionsHelper's two settings buttons are swapped; AppValidator.isNumeric regex ends in a literal `\$`; NotificationRouter._isLoggedIn reads the token from SharedPreferences although it is stored in secure storage; ApiKeys paths prepend BASE_URL although Dio already has baseUrl; relative import with 12 `../` in app_icon_button.dart; misspelled file names (permisssions_helper.dart, phone_handeler_service.dart, image_Widget.dart); copy-pasted naming ("tasks" vars inside notices cubit); 264 CRLF files mixed with LF; a Maps API key and a static API-key header are committed in source; android/app/playstore-key.json (service account), google-services.json, GoogleService-Info.plist and firebase_options.dart are git-tracked (only upload-keystore.jks and key.properties are ignored)
```

---

## 1. Architecture pattern

A **feature-first "clean-arch-lite"**: it has data and presentation layers but **no domain layer** (no entities, no use cases, no abstract repository interfaces).

- **data/data_sources**: `XRemoteDataSource extends BaseRemoteDataSource`. Every method is one `handleRequest(path, method, parser, data, queryParameters)` call that returns a parsed model or throws a `Failure`. Some features also have a `XLocalDataSource` (auth, splash) that wraps `SecureStorageManager` or `SharedPreferencesManager`.
- **data/models**: hand-written `fromJson`/`toJson`, plus `toFormData()` for multipart (21 files). Response wrappers look like `XResponseModel { message, data, pagination }`. No codegen (no freezed or json_serializable).
- **data/repo** (`repositories` in auth, home and splash): concrete `XRepository extends BaseRepository`. Each method wraps the data-source call in `handleNetworkCall`, which returns `Either<Failure, T>`.
- **presentation/managers**: one folder per cubit. List cubits (`XsCubit`) extend `BaseSingleClassStateCubit`, using a single state class with `FetchDataStatusEnum` plus page/hasReachedMax. Action/detail cubits (`XCubit`) usually extend `BaseCubit`, using sealed `Loading/Success/Failure` state classes per action.
- **presentation/screens** and **presentation/widgets**: plain `Scaffold` + `AppBar` (theme-driven). `BlocBuilder`/`BlocConsumer` read app-wide cubits. Navigation uses `context.push(AppRoutesNames.x, extra: model)`.

Wiring: `lib/core/services/di_container.dart` registers every data source, repo (lazySingleton) and cubit (factory). `lib/main.dart` provides ~54 cubits app-wide through one `MultiBlocProvider` above `MaterialApp.router`. There is no per-route scoping, apart from `SplashCubit`, which is provided in the route.

Example of the pattern (repo base, verbatim):

```dart
class BaseRepository {
  Future<Either<Failure, T>> handleNetworkCall<T>({
    required Future<T> Function() call,
  }) async {
    try {
      final result = await call();
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    }
  }
}
```

## 2. Folder tree (`lib/`, 4 levels)

```
lib/
├── main.dart                         FCM background handler, init sequence, EasyLocalization, ScreenUtilInit, global MultiBlocProvider, MaterialApp.router
├── firebase_options.dart             (secret file, not opened)
├── geofence_service.dart             GeofencingService singleton over a native MethodChannel (+ GeofenceEvent stream)
├── core/
│   ├── app_cubit/                    AppCubit/AppState: logged-in user (+ permissions), network flag
│   ├── app_router/                   app_router.dart (GoRouter, ~79 routes), app_routes_names.dart (path constants)
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/         base_remote_data_source.dart (handleRequest + error mapping)
│   │   │   ├── models/               base_request_model/network_request_model.dart, base_response_model/base_success_response.dart, base_success_model.dart, pagination_model.dart
│   │   │   └── repository/           base_repo.dart (Either wrapper)
│   │   └── presentation/managers/
│   │       ├── base_cubit/           BaseCubit + BaseState (multi-class states)
│   │       └── base_single_class_state_bloc/  BaseSingleClassStateCubit + BaseSingleClassState
│   ├── enums/                        app_roles, fetch_data_status, http_method, toast_state (part of toast_manager)
│   ├── exports/core_exports.dart     barrel: material, go_router, easy_localization, screenutil, AppColors, DefaultScreen, AppCubit
│   ├── extensions/                   context_extensions (theme/textTheme/colorScheme/isAr), list_extensions (isNullOrEmpty)
│   ├── models/                       downloaded_file_result, geocoding_address_details, selection_model, statistics_response_model
│   ├── services/                     33 files: api, DI, storage, notifications/alarm stack, validators, media, permissions, url, pdf…
│   ├── theme/
│   │   ├── dark_theme/dark_theme.dart          EMPTY
│   │   └── light_theme/              light_theme.dart, my_light_themes_export.dart, light_widget_themes/ (app_bar, bottom_nav, btn_txt, dialog, elevated_btn, input_decoration, light_color_scheme, snack_bar, text_theme)
│   └── utilities/
│       ├── constants/                colors, icons (AppIcons.svg helper), images (AppImages), temp_images, constant_lists, attachment_types, keys/{api_keys, shared_preferences_keys}
│       ├── converters/price_converter.dart     EMPTY
│       ├── failures/                 failure.dart, error_details_model.dart
│       ├── formatters/date_formatter.dart
│       └── widgets/                  buttons/, text_form_fields/, toasts/, dialogs/, shared/{screens,widgets}/, + ~20 single widgets
└── features/                         20 features
    alerts(26) app_notifications(20) attendance(10) auth(16) client_reviews(12) dashboard(13)
    evaluations(30) fire_alarm(9) headquarters(13) home(28) maintenance(25) notices(15)
    quality_inspections(15) roles(18) settings(9) sms(19) splash(8) stations(27) tasks(17) users(32)
```

Representative feature, fully expanded (`features/notices/`):

```
notices/
├── data/
│   ├── data_sources/notices_remote_data_source.dart   getNotices(page,status,createdBy,searchKey), create/get/update/delete, changeNoticeStatus
│   ├── models/notice_model.dart                       model + toFormData(isUpdate)
│   ├── models/notice_status_enum.dart                 enum with value/label (tr)
│   ├── models/notices_response_model.dart             list + pagination; NoticeDetailsResponseModel
│   └── repo/notices_repo.dart                         Either wrappers
└── presentation/
    ├── managers/notice_cubit/{notice_cubit,notice_state}.dart     BaseCubit, sealed action states
    ├── managers/notices_cubit/{notices_cubit,notices_state}.dart  BaseSingleClassStateCubit, page + hasReachedMax + filters
    ├── screens/{notices_screen, notice_details_screen, add_notice_screen}.dart
    └── widgets/{notice_card, notices_view (scroll pagination), submit_notice_bottom_sheet}.dart
```

`home/` also contains `presentation/services/` (`check_geofence.dart`, `permissions_service.dart`), which is presentation-level orchestration for attendance check-in.

## 3. Infrastructure

### State management
- `flutter_bloc ^9.1.1`, cubits only.
- `BaseSingleClassStateCubit<State extends BaseSingleClassState>.handleRequest({call, onNotDefaultSuccess, onNotDefaultFailure?, onNotDefaultLoading?})` emits `copyWith(status: loading)` and then failure or the caller's success. It relies on `state.copyWith(...) as State` casts. Status values: `FetchDataStatusEnum {initial, loading, success, failure}`.
- `BaseCubit<State extends BaseState>.handleRequest({loadingState, call, onSuccess, onError, showLoading})` logs via talker/print.
- Having two bases means two styles coexist (29 vs 26 cubits). `AppCubit` is a plain `Cubit` holding the logged-in `UserModel` (with permissions) and is provided above `MyApp`. `AppBlocObserver` prints every lifecycle event.
- `HydratedBloc.storage` is built in `main()`, but no Hydrated cubit exists.

### DI
- `get_it ^9.2.1` with a manual `diContainerSetup()` in `lib/core/services/di_container.dart` (531 lines; most of it imports). The global `final diService = GetIt.instance; final talker = Talker();` also lives here.
- `diContainerSetup` is `async`, but its sub-inits are not awaited (they are synchronous anyway).
- Data sources take no constructor args; they pull `ApiService` from the locator inside `BaseRemoteDataSource`.

### Routing
- `go_router ^17.2.3`, `lib/core/app_router/app_router.dart`: a top-level `final GoRouter appRouter` with `observers: [TalkerRouteObserver(talker)]`.
- Splash uses a `CustomTransitionPage` fade. Everything else is a flat `GoRoute` with `builder`, and data travels as `state.extra as Model` (about 35 casts; they crash on a cold deep link).
- There is no `redirect` or `refreshListenable`. Splash chooses `/home` or `/login` based on the token in secure storage. 401s are handled per screen (home, profile and drawer listeners delete the token and `go(login)`).
- Notifications navigate through `appRouter.push` from `NotificationRouter` (no context needed).

### Networking
- `dio ^5.7.0`. `ApiService` (`lib/core/services/api_service.dart`) implements `ApiServiceBase` and exposes get/post/put/patch/delete taking `NetworkRequestParams` (uri, data, query, options, cancelToken, progress callbacks).
- Default headers are JSON, `Accept-Language: ar`, and a static API-key header (value committed, not reproduced). `Authorization: Bearer <token>` is read from secure storage in `_buildHeaders()`. `updateHeaders(token, customHeaders)` rebuilds the headers; it is used on login, at splash and on language change.
- Timeouts are 30s connect and 30s receive.
- Interceptor: `TalkerDioLogger` with request/response/error filters that drop `/sms/` endpoints. The custom `LoggingInterceptor` (`lib/core/services/logging_interceptors.dart`) is registered but never added to Dio.
- No token refresh, no retry, no connectivity check, no cancel-token use in features.
- Error mapping lives in `BaseRemoteDataSource._handleDioError` and `_handleErrorResponse` (status → Failure) plus `_parseErrorDetails`, which accepts `errors` as a list of strings or a map of field → list. The `_executeRequest` switch per `HttpMethod` repeats `diService<ApiService>()` five times.
- Endpoints: `lib/core/utilities/constants/keys/api_keys.dart` (`ApiKeys`), which holds `BASE_URL = {{BASE_URL}}` and absolute paths built as `"$BASE_URL/…"`, plus id functions such as `SINGLE_TASK(int id)`.

### Local storage
- `SecureStorageManager` wraps `FlutterSecureStorage` (write/read/delete/clearAll/containsKey) and holds the token.
- `SharedPreferencesManager` is a singleton with `init()` in `main()` and a dynamic `setValue`/`getValue`/`remove`/`clear`.
- Keys live in `SharedPreferencesKeys`. On first launch, splash clears both stores, which handles the iOS keychain surviving a reinstall (good).
- `SilentBypassManager` and `NotificationLogBridge` call `SharedPreferences.getInstance()` directly; the bridge uses `reload()` for cross-isolate reads.

### Localization and RTL
- `easy_localization ^3.0.7`: `supportedLocales [ar, en]`, `path assets/translations`, `fallbackLocale` and `startLocale` both `ar`. Nested JSON keys such as `validation.empty_email` and `screens.notices.title`, about 940 leaves each.
- `MaterialApp.router` uses `key: ValueKey(locale)`, which forces a full rebuild on a language switch. A `builder` wraps the app in an explicit `Directionality`, which is redundant.
- `lib/core/services/get_and_set_device_locale.dart` can match the device locale. `ContextExtensions.isAr` exists. Language change: `profile_screen.dart` calls `context.setLocale` and then `ApiService.updateHeaders(Accept-Language)`.
- RTL: 139 directional usages against 87 left/right ones. Core widgets mostly use `EdgeInsetsDirectional`; `AppBackButton` flips its arrow. `DynamicDropdownFormField` positions its menu with LTR maths, and `CustomAppBar` uses `arrow_back_ios`.

### Theming
- `lib/core/theme/light_theme/light_theme.dart`: `ThemeData(useMaterial3: true)` with `ColorScheme.fromSeed(AppColors.primary)` (deprecated `background`/`onBackground`), plus appBar, bottomNav, button, elevated, text-button, snackBar, dialog, inputDecoration and progressIndicator themes. Each component theme is its own file under `light_widget_themes/`.
- `TextThemeLight` is a singleton giving a full M3 TextTheme in Alexandria with a fixed colour. Only the base style uses `.sp`; the per-style sizes are raw numbers.
- `AppColors` (`lib/core/utilities/constants/colors.dart`) is documented by role: brand, neutrals, status, button states. Note that `accentGreen` is used for input error borders and failure toasts.
- `dark_theme.dart` is empty and there is no ThemeMode switch.

### Responsive
- `flutter_screenutil ^5.9.3`, `ScreenUtilInit(designSize: Size(393, 852), minTextAdapt: true, splitScreenMode: true)`. `.w/.h/.r/.sp` are used everywhere. No breakpoints, no tablet layout and only one LayoutBuilder.

### Text scaling
- None. There is no `textScaler`/`MediaQuery` clamp, so system font scaling multiplies on top of `.sp`.

### Env / flavors
- None. BASE_URL is a constant, with the alternatives left as commented lines. The API-key header and the Maps key are hardcoded.
- Android has a single release signing config. `.github/workflows/flutter.yml` decodes the keystore and service account from GitHub secrets and deploys to Play.

### Logging
- `talker_flutter` + `talker_dio_logger` 5.x. The global `talker` is declared in `di_container.dart`. `TalkerRouteObserver` is attached and `NotificationLogBridge` carries background-isolate logs.
- No log-viewer screen is wired up (no `TalkerScreen`).
- Also 28 `print` and 64 `debugPrint` calls, and `AppBlocObserver` prints everything. Splash logs the bearer token through `talker.info`.

### Analytics / crash
- None (no firebase_analytics, crashlytics or sentry).

### Push notifications
- `firebase_messaging ^16.6.0` + `flutter_local_notifications ^21.0.0`.
- `NotificationService` (749 lines) is all static:
  - `init(context)` is called from splash. It requests permissions (Android `Permission.notification`; iOS `requestPermission` including `criticalAlert`), creates channels (alarm, silent alarm and normal; the `_v2` channel IDs are versioned on purpose), and sets `setForegroundNotificationPresentationOptions(false…)` so the foreground path posts exactly one local notification.
  - It handles `onMessage`, `onMessageOpenedApp`, `getInitialMessage`, `getNotificationAppLaunchDetails` (cold-start local tap) and `onTokenRefresh`, which re-registers the token via `AuthRepository.registerFCM`.
  - `initializeForBackground()` serves the background isolate.
  - `logRemoteMessage` dumps the full payload.
- The background handler lives in `main.dart`. Commented notes there explain why it does not post a local notification (FCM/APNs already drew one).
- Fire-alarm stack:
  - `AlarmService` (flutter_foreground_task) and `AlarmTaskHandler` play a looping just_audio clip with `AndroidAudioUsage.alarm`.
  - `AlarmManager` is the main-isolate player on iOS.
  - `AlarmCueService` plays a one-shot stop cue.
  - `AlarmVolumeHelper` raises the Android alarm stream through a MethodChannel (`com.example.app/alarm_audio`).
  - `SilentBypassManager` handles Android DND access and the iOS critical-alert opt-in, with an explainer dialog and a `statusStream`.
- `NotificationRouter` maps `data.type` (task/notice/evaluation/inspection/review/alarm constants in `NotificationTypes`) to a screen: it fetches the model by id behind a blocking loader, dedupes taps within 3s, waits up to 15s until it is past splash/auth, and falls back to Home.
- Also: `NotificationService._refreshFor(type)` refreshes the matching list cubit from the navigator context.

### IAP / payments
- None.

### Permissions
- `permission_handler ^12.0.1`, `geolocator`, `local_auth`.
- `PermissionsHelper.checkLocationPermission` handles dialogs for denied and deniedForever, but its "open settings" handlers are swapped.
- `ensureAttendancePermissions` (home/presentation/services) is a reusable rationale-sheet → request → settings-dialog flow.
- `ImageDownloaderService` and `QrCodeService` check the Android SDK version before asking for storage.
- `BiometricService` wraps local_auth (available/types/authenticate).

### Deep links
- None configured (no app_links, no intent filters for https or custom schemes). Only push-payload routing exists.

## 4. Services catalog

| File | Purpose | Public API | Depends on | Generic? |
|---|---|---|---|---|
| lib/core/services/api_service.dart | Dio wrapper (ApiServiceBase/ApiService) | get/post/put/patch/delete(NetworkRequestParams), updateHeaders(token, customHeaders) | dio, talker_dio_logger, SecureStorageManager | generic (remove the hardcoded header) |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | request + error mapping | handleRequest<T>(path, method, parser, data, query, options) | ApiService via diService, Failure | generic |
| lib/core/base_architecture/data/repository/base_repo.dart | Either wrapper | handleNetworkCall<T>(call) | dartz | generic |
| lib/core/base_architecture/data/models/* | NetworkRequestParams, BaseSuccessResponse<T>, BaseSuccessModel(+WithData<T>), Pagination | fromJson/toJson | equatable | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/* | BaseCubit/BaseState/LoadingState/ErrorState | handleRequest(loadingState, call, onSuccess, onError, showLoading) | flutter_bloc, talker | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/* | BaseSingleClassStateCubit/State | handleRequest(call, onNotDefaultSuccess, onNotDefaultFailure?, onNotDefaultLoading?) | flutter_bloc | generic |
| lib/core/services/di_container.dart | get_it setup + global talker | diContainerSetup() | every feature | app-specific |
| lib/core/services/secure_storage_manager.dart | secure storage wrapper | write/read/delete/clearAll/containsKey | flutter_secure_storage | generic |
| lib/core/services/shared_preferences_manager.dart | prefs singleton | init/setValue/getValue/remove/clear | shared_preferences | generic |
| lib/core/services/bloc_observer.dart | AppBlocObserver | lifecycle overrides (print) | flutter_bloc | generic (switch to talker) |
| lib/core/services/logging_interceptors.dart | debugPrint Dio interceptor (unused) | onRequest/onResponse/onError | dio | generic |
| lib/core/services/toast_manager.dart | overlay toast + BuildContext.showToast | ToastManager.showToast, context.showToast(message, state, duration, location) | AnimatedCustomToast | generic |
| lib/core/services/show_loading_dialog.dart | blocking loader dialog | LoadingDialogService.show(context, message), hide() | AppColors | generic |
| lib/core/services/app_validator.dart | form validators (l10n keys) | isNotEmpty, isValidEmail, isValidPhone, isValidSaudiPhone, isValidPassword, confirmPassword, isNumeric, isValidEmployeeNumber, isNotEmptyImage, ibanValidator, customValidator | easy_localization | generic (Saudi/employee rules app-specific) |
| lib/core/services/input_formatters.dart | TextInputFormatters + image-ext check | onlyAlphabets, onlyNumbers, alphanumeric, decimalNumber, noWhitespace, numberCounts(max), isSupportedImageFormat | flutter/services | generic |
| lib/core/services/debounce.dart | debounce | run(action), cancel() | dart:async | generic |
| lib/core/services/url_manager.dart | url_launcher helpers | makeCall, sendMail, openLink, openLinkInApp, openMapLocation, openMapByAddress | url_launcher | generic |
| lib/core/services/get_and_set_device_locale.dart | device locale → app | setAppLanguageToDeviceLanguage(context), getDeviceLocale() | easy_localization, dart:io | generic |
| lib/core/services/language_flags_service.dart | locale → flag emoji | LanguageService.getFlagEmoji | – | generic (unused) |
| lib/core/services/phone_handeler_service.dart | phone prefix | ensureStartsWithZero | – | generic (trivial) |
| lib/core/services/random_color.dart | random colour + role colour | getRandomColor, getRoleColor(UserModel) | UserModel | app-specific |
| lib/core/services/biometric_service.dart | local_auth wrapper | isBiometricAvailable, getAvailableBiometrics, authenticate(reason) | local_auth | generic |
| lib/core/services/permisssions_helper.dart | location permission dialogs | checkLocationPermission(context) | geolocator, permission_handler | generic (buttons swapped) |
| lib/core/services/image_picker_service.dart | pick image(s)/video(s)/media + video compression | pickImage, pickMultiImage, pickVideo, pickMultipleMedia, pickMultiVideo | image_picker, video_compress | generic (hardcoded Arabic snackbars) |
| lib/core/services/image_downloader_service.dart | save URL image to gallery | downloadImage(url, onProgress) | dio, image_gallery_saver_plus, device_info_plus, permission_handler | generic |
| lib/core/services/image_share_service.dart | share image from URL/path | shareImage(path, text, subject, onProgress) | dio, share_plus, path_provider | generic (deprecated Share.shareXFiles) |
| lib/core/services/file_export_service.dart | write bytes to temp | saveToTemp(bytes, fileName) | path_provider | generic |
| lib/core/services/pdf_service.dart | build alerts PDF report | generateAndSaveAlerts(...) | pdf, printing | app-specific |
| lib/core/services/google_maps_services.dart | reverse geocoding | getAddressFromLatLng(lat, lng) | dio (own instance, key hardcoded) | generic after moving the key out |
| lib/core/services/notification_service.dart | FCM + local notifications + alarm orchestration | init(context), initializeForBackground, logRemoteMessage, showLocalNotification, showAlarmNotification, cancelAlarmNotification, cancel/cancelAll, subscribe/unsubscribeFromTopic | firebase_messaging, flutter_local_notifications, permission_handler, many feature cubits/repos | app-specific (skeleton generic) |
| lib/core/services/notification_router.dart | push payload → screen | NotificationTypes consts, NotificationRouter.handle(data) | appRouter, repos, prefs | app-specific (pattern generic) |
| lib/core/services/notification_log_bridge.dart | cross-isolate log relay | initMainIsolate, drainPending, log(entry) | dart:isolate, shared_preferences, talker | generic |
| lib/core/services/silent_bypass_manager.dart | DND/critical-alert opt-in | init, requestPermission(context, force), refresh, promptIfNeeded, wasSkipped, statusStream, isEnabled | permission_handler, firebase_messaging, shared_preferences | generic for alarm-type apps |
| lib/core/services/alarm_service.dart | foreground-service alarm | initCommunicationPort, configure, start(title, body), stop | flutter_foreground_task | niche |
| lib/core/services/alarm_task_handler.dart | FG task looping audio | startAlarmCallback, AlarmTaskHandler | just_audio, audio_session | niche |
| lib/core/services/alarm_manager.dart | main-isolate alarm player | startAlarm, stopAlarm, isPlaying | just_audio, audio_session | niche |
| lib/core/services/alarm_cue_service.dart | one-shot stop cue | playStopCue | just_audio, audio_session | niche |
| lib/core/services/alarm_volume_helper.dart | raise Android alarm stream | maximizeAlarmVolume | MethodChannel (native code) | niche |
| lib/core/utilities/formatters/date_formatter.dart | date formatting | formatDateString, formatDate, isMorning | intl | generic |
| lib/core/utilities/constants/icons.dart / images.dart | asset path consts + svg/image helpers | AppIcons.svg(...), AppImages.image(...) | flutter_svg | generic |
| lib/core/utilities/constants/attachment_types.dart | allowed attachment extensions, size limit, ext helpers | kAllowedAttachmentExtensions, kImageAttachmentExtensions, kMaxAttachmentBytes, helpers | – | generic |
| lib/core/extensions/context_extensions.dart | theme shortcuts + isAr | theme, textTheme, colorScheme, isAr | – | generic |
| lib/core/extensions/list_extensions.dart | null/empty check | isNullOrEmpty() | – | generic |
| lib/geofence_service.dart | native geofencing bridge | instance, initialize, onGeofenceEvent, … | MethodChannel, geolocator | niche |
| lib/features/home/presentation/services/permissions_service.dart | multi-permission rationale flow | ensureAttendancePermissions(context) | permission_handler | generic once the permission list is a parameter |
| lib/features/home/presentation/services/check_geofence.dart | attendance check-in/out orchestration | handleAttendanceCheck, getStoredManagerLocation, clearManagerLocation | geolocator, GeofencingService | app-specific |
| lib/features/app_notifications/presentation/push_notification_guard.dart | RBAC gate | canSend(context), unauthorizedScaffold() | AppCubit | pattern generic |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/buttons/app_default_button.dart | primary button with loading morph | text, onTap, isLoading, enabled, svgIconPath, svgIconColor, textStyle, backgroundColor, textColor, loadingColor, borderColor, gradient, child, margin, padding, height, width, radius, blockMultipleClicks | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart | AppIconButton / AppBackButton | child, onTap, height, width, radius, backgroundColor, padding, margin, isLoading, loadingColor / onTap | y |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart | titled TextFormField | title, controller, hintText, onTap, onChanged, enabled, readOnly, obscureText, keyboardType, validator, inputFormatters, prefixIcon, suffixIcon, titleStyle, textStyle, hintTextStyle, maxLength, maxLines, focusNode, textAlign, onSaved, onFieldSubmitted, onEditingComplete, externalError | y |
| lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart | password + toggle | controller, isConfirmPassword, confirmPasswordValidator, title, hintText, isLogin, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart | email field | controller, title, hintText, readOnly, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/date_picker_text_form_field.dart | date/time picker field | controller, title, hintText, isDate, readOnly, pickDay | y |
| lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart | string dropdown (bottom sheet) | title, hintText, controller, items, validator, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart | searchable generic dropdown | controller, options, displayText, title, onOptionSelected, hintText, showSearch, widgetBuilder, searchText | y |
| lib/core/utilities/widgets/default_screen.dart | base scaffold | body, appbar, pageTitle, pageTitleWidget, hasAppBar, hasBackButton, hasBottomBorder, hasBottomMargin, onBackPressed, floatingActionButton(+Location), topMargin, appBarPadding, bodyPadding, backgroundColor | y |
| lib/core/utilities/widgets/custom_appbar.dart | custom AppBar (unused) | pageTitle, actions | y |
| lib/core/utilities/widgets/base_fetching_widget.dart | GenericFetchWidget / BaseLoadingWidget / BaseErrorWidget | successBuilder, loadingWidget, failureWidget, onRetry / – / message, onRetry | y |
| lib/core/utilities/widgets/base_list_view_widget.dart | list with empty state (unused) | items, itemBuilder, emptyWidget | y |
| lib/core/utilities/widgets/failure_widget.dart | error + retry text | errorMessage, onTapRetry | n |
| lib/core/utilities/widgets/toasts/animated_custom_toast.dart | animated toast | message, state, duration, location | y |
| lib/core/utilities/widgets/toasts/custom_toast.dart | static toast | message, state, duration | y |
| lib/core/utilities/widgets/container_with_shadow.dart | card | child, margin, padding, radius, width, height, image, backgroundColor, border, onTap, boxShadow, shadowBlurRadius | y |
| lib/core/utilities/widgets/custom_chip.dart | chip | title, titleStyle, bgColor, borderColor, txtColor, radius, fontSize, padding, onSelect | y |
| lib/core/utilities/widgets/selection_chip_widget.dart | selectable chip | isSelected, title, onTap, unSelectedColor, selectedColor | y |
| lib/core/utilities/widgets/custom_radio_group_widget.dart | radio group + custom radio | options, selectedValue, onChanged, prefixText, label / value, groupValue, onChanged, size, activeColor, inactiveColor, animationDuration | y |
| lib/core/utilities/widgets/expandable_widget.dart | expandable container | title, description, expandedContent, expandedHeight | y |
| lib/core/utilities/widgets/app_divider.dart | divider | height, thickness, color, indent, endIndent | y |
| lib/core/utilities/widgets/linear_progress_indicator.dart | percent bar | percent, minHeight | y |
| lib/core/utilities/widgets/animated_indicator.dart | step dot | index, currentStep | y |
| lib/core/utilities/widgets/title_value_widget.dart | label/value | title, value, valueStyle | y |
| lib/core/utilities/widgets/question_answer_widget.dart | Q/A row | question, answer, highlight | y |
| lib/core/utilities/widgets/image_picker_bottom_sheet.dart | camera/gallery sheet (function) | context + callbacks | y |
| lib/core/utilities/widgets/image_picker_widget.dart | single image picker tile | title, imagePath, onPickImage, onRemoveImage, width, height, radius | y |
| lib/core/utilities/widgets/shared/widgets/image_Widget.dart | universal image + download/share | image, width, height, radius, borderRadius, color, margin, stackedWidget, onTap, onTapRemove, hasDownloadBtn, hasShareBtn, fit, border | y |
| lib/core/utilities/widgets/shared/widgets/video_widget.dart | video tile | video, width, height, radius, borderRadius, color, margin, onTap, fit, border, autoPlay, loop, onTapRemove | y |
| lib/core/utilities/widgets/shared/screens/image_viewer.dart | full-screen image | imagePath | y |
| lib/core/utilities/widgets/shared/screens/video_viewer.dart | full-screen video | video, autoPlay, loop | y |
| lib/core/utilities/widgets/shared/screens/attachment_viewer_screen.dart | PDF/image viewer | url | y |
| lib/core/utilities/widgets/shared/screens/select_location_screen.dart | map location picker | – | partly |
| lib/core/utilities/widgets/custom_qr_widget.dart | QR + download/share | data, stationCode, size, backgroundColor, foregroundColor, padding, hasDownloadBtn, hasShareBtn, shareText, shareSubject | partly |
| lib/core/utilities/widgets/silent_bypass_disabled_widget.dart | permission banner | margin | n |
| lib/core/utilities/widgets/statistics_view.dart | stats tiles | statistics | n |
| lib/core/utilities/widgets/user_selection_widget.dart | user picker (UsersCubit) | title, hasAll, userController, onOptionSelected | n |
| lib/core/utilities/widgets/dialogs/letter_destination_dialog.dart | bilingual input dialog | – | n |
| lib/features/app_notifications/presentation/widgets/notifications_bell_button.dart | unread badge bell | – | n (feature-bound) |

No shimmer or skeleton widget lives in core; `skeletonizer` is used inline in 3 feature screens. No pagination list widget exists either: each list view re-implements `ScrollController` + `_onScroll` (15 files).

## 6. Packages (pubspec.yaml)

- **State:** flutter_bloc ^9.1.1, hydrated_bloc ^11.0.0 (unused), equatable ^2.0.7
- **DI:** get_it ^9.2.1
- **Routing:** go_router ^17.2.3
- **Network:** dio ^5.7.0, dartz ^0.10.1
- **Storage:** shared_preferences ^2.3.3, flutter_secure_storage ^10.0.0, path_provider ^2.1.5
- **L10n:** easy_localization ^3.0.7, intl ^0.20.2, flutter_localizations
- **UI:** flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, skeletonizer ^2.1.0+1, flutter_animate ^4.5.2, animate_do ^5.1.0 (unused), flutter_html ^3.0.0 (unused), cupertino_icons, country_picker ^2.0.2 (unused), flutter_native_splash ^2.4.3, flutter_launcher_icons ^0.14.4 (listed under dependencies)
- **Firebase:** firebase_core ^4.14.0, firebase_messaging ^16.6.0, cloud_firestore ^6.9.0 (only in delete_account_service.dart)
- **Notifications/audio:** flutter_local_notifications ^21.0.0, flutter_foreground_task ^10.0.0, just_audio ^0.10.0, audio_session ^0.2.3
- **Media/files:** image_picker ^1.2.1, cached_network_image ^3.4.1 (unused), video_player ^2.11.1, video_compress ^3.1.4, file_picker ^11.0.3, image_gallery_saver_plus ^5.1.1, share_plus ^12.0.2, screenshot ^3.0.0, pdf ^3.11.0, printing ^5.11.0, qr_flutter ^4.1.0, pretty_qr_code ^3.5.0 (unused)
- **Location/maps:** google_maps_flutter ^2.18.0, geolocator ^14.0.2
- **Utils/platform:** permission_handler ^12.0.1, url_launcher ^6.3.1, local_auth ^3.0.1, device_info_plus ^12.3.0, package_info_plus ^9.0.1 (unused)
- **Logging:** talker_flutter ^5.0.0, talker_dio_logger ^5.0.0
- **Dev:** flutter_test, flutter_lints ^6.0.0

## 7. Quality notes

- **Null safety:** yes (Dart ^3.7.2). Heavy `!` use on user permissions (`state.user!.permissions!`).
- **Lints:** the stock `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` and adds no rules. `print` is still widespread, so warnings are probably ignored.
- **Tests:** only the template counter test, which references a `MyApp` that needs DI and Firebase and would fail. The CI test step is commented out.
- **Tooling:** `create_feature.dart` (folder and boilerplate generator) and `copy_feature.dart` (clones a feature with token replacement, then patches routes, DI and api keys) sit at the repo root, worth keeping in a template under `tool/`. CI (GitHub Actions) builds an AAB and deploys to Play using secrets.
- **Duplication:**
  - Two cubit base classes.
  - The pagination logic (`_currentPage`, `hasReachedMax`, `resetTasks`, `_onScroll`) is copied into about 42 files.
  - Failure/empty/loading UI is re-implemented in each `XsView` with hardcoded English ("Failed to fetch tasks", "Retry").
  - `_executeRequest` repeats `NetworkRequestParams` per HTTP method.
  - Two image/QR download implementations (`ImageDownloaderService` and `QrCodeService`).
- **Deprecated/legacy APIs:** `WillPopScope` (1), `withOpacity` (56), `ColorScheme.background/onBackground`, `Share.shareXFiles` in image_share_service.dart (the QR widget already uses `SharePlus.instance.share`).
- **Bugs spotted:**
  - Disabled/enabled button text colours are inverted in `AppDefaultButton`.
  - The "open settings" handlers in `PermissionsHelper` are swapped.
  - `AppValidator.isNumeric` has an escaped `$` in its regex and an untranslated key.
  - `CacheFailure` discards its message.
  - `NotificationRouter._isLoggedIn` checks SharedPreferences, but the token is in secure storage.
  - The list cubits' `addX`/`removeX` mutate state in place.
  - `ApiService` builds its headers asynchronously from the constructor, so a very early request can go out without auth or locale headers.
- **Security:**
  - A Maps API key is hardcoded in `lib/core/services/google_maps_services.dart`, `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`.
  - A static API-key header is hardcoded in `lib/core/services/api_service.dart`.
  - The bearer token is logged at splash.
  - `android/app/playstore-key.json`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` and `lib/firebase_options.dart` are tracked by git (the keystore and key.properties are ignored).
- **Good parts worth keeping:** typed Failure mapping, the `externalError` field pattern, the notification router and its dedupe, the isolate log bridge, the permission rationale flow, PII-filtered network logging, first-run secure-storage wipe, and thorough comments explaining platform behaviour in the notification code.
