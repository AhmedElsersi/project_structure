# brgr-old (legacy BRGR employee app)

> Legacy project superseded by `Datum/brgr` (analyzed separately). Its `lib/core` is the shared
> origin of `brgr-manager-old` and `brgr-maintenance-old`, which carry near-identical forks of it
> (see those reports for the per-file differences). This one has the richest core, so it gets the full report.

## Summary for comparison

```
PROJECT: brgr-old | path: Datum/old Projects/old brgr projects/brgr | stack: Flutter 3.29.3 (.fvmrc), Dart ^3.7.2 | last commit: 2026-01-21 (branch development, 37 commits since 2025-05-11, 28 uncommitted changes; lib mtime 2026-01-27) | source files: 203
ARCH: clean-arch-lite, feature-first — features/<f>/{data/{data_sources,models,repositories}, presentation/{<x>_cubit|managers,screens,widgets}}; NO domain layer (no entities/use cases); shared lib/core with base data source/repo/cubit classes
STATE: flutter_bloc 9 (Cubits only) — two bases: BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart, sealed-state cubits) and BaseSingleClassStateCubit.handleRequest + BaseSingleClassState{status enum, failure, success} (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/)
DI: get_it (manual, no injectable) — lib/core/services/di_container.dart (global `sl` + global `talker`; lazy singletons for data sources/repos, factories for cubits)
ROUTING: go_router 16 — lib/core/app_router/app_router.dart + app_routes_names.dart — ShellRoute for bottom nav, args via state.extra casts, TalkerRouteObserver, onExit hook; guards: none (auth gate lives in SplashScreen, 401 -> login in BottomNavScreen BlocListener); deep links: none
NETWORK: dio 5 — interceptors: TalkerDioLogger only (custom LoggingInterceptor is registered in DI but never attached) | token refresh: n | retry: n | error mapping: BaseRemoteDataSource maps HTTP 400/401/403/404/5xx + DioException (timeout / no response) to Failure subclasses and parses field errors into List<ErrorDetail> | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/base_architecture/data/models/base_request_model/network_request_model.dart
RESULT_TYPE: Either (dartz) via BaseRepository.handleNetworkCall (lib/core/base_architecture/data/repository/base_repo.dart) — Failure hierarchy: lib/core/utilities/failures/failure.dart (+ error_details_model.dart)
STORAGE: shared_preferences + flutter_secure_storage (token, password) — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart (hydrated_bloc declared but unused)
L10N: easy_localization — ar, en; start/fallback ar; assets/translations/{ar,en}.json (192 nested keys each) — hardcoded UI strings: some (~22 Text literals EN/AR in features, plus EN strings in NotificationService dialog, ImagePickerService snackbars, dropdown 'Search...'/'Select an option')
RTL: Directional=15 vs LeftRight=13 (+15 EdgeInsets.fromLTRB)
THEME: lib/core/theme/light_theme/light_theme.dart — dark mode n (dark_theme.dart is an empty file) | component themes in ThemeData y (appBar, bottomNav, elevated+text buttons, inputDecoration, snackBar, dialog, progressIndicator; one file each in light_widget_themes/) | colors class AppColors (lib/core/utilities/constants/colors.dart, 50-1000 tonal scales) | text styles TextThemeLight singleton (light_widget_themes/text_theme.dart) | fonts Alexandria (theme) + Cairo (bundled, unused)
RESPONSIVE: flutter_screenutil (design 393x852, minTextAdapt, splitScreenMode) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants — lib/core/utilities/constants/keys/api_keys.dart (BASE_URL/BASE_IMAGE_URL with commented alternates); environments only via git branches (development/staging/main); no flavors, no --dart-define
LOGGING: talker (talker_flutter + talker_dio_logger, global instance in di_container.dart) + debugPrint (55) + print (15)
ANALYTICS/CRASH: firebase_crashlytics (FlutterError.onError + runZonedGuarded in lib/main.dart) — no analytics
PUSH: fcm + flutter_local_notifications + FCM topics per role/language — lib/core/services/notification_service.dart (static class; background handler in lib/main.dart)
PAYMENTS/IAP: none
PERMISSIONS: permission_handler (notification, microphone, storage, location) + geolocator
DEEP_LINKS: none (notification tap handlers are TODO stubs)
MEDIA/FILES: image_picker + flutter_image_compress (size-tiered), flutter_sound + just_audio (voice notes), flutter_svg, Image.network (cached_network_image declared but unused), path_provider; native geofencing via MethodChannel (lib/geofence_service.dart + Kotlin/Swift)
TESTS: 1 — default counter smoke test (stale, would fail)
LINTS: flutter_lints ^6.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/services/secure_storage_manager.dart — flutter_secure_storage singleton with corruption recovery (resetOnError, delete+retry write, per-key fallback clear) — quality 4 — coupling: none
- lib/core/utilities/failures/failure.dart — Failure base (implements Exception; message, code, field errors) + BadRequest/Unauthorized/Forbidden/NotFound/Server/Network/Timeout/Cache/Validation/Unknown — quality 4 — coupling: none
- lib/core/services/app_validator.dart — static form validators via easy_localization keys (empty, email, phone, Saudi phone, password strength, confirm, numeric, numeric-in-range w/ namedArgs, image, IBAN mod-97, compose) — quality 4 — coupling: low (translation keys)
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — handleRequest<T>(path, method, parser) + status/DioException -> Failure mapping + field-error parsing — quality 3 — coupling: medium (resolves sl<ApiService>() inside; assumes {message, field:[..]} error body)
- lib/core/base_architecture/data/repository/base_repo.dart — handleNetworkCall -> Either<Failure,T> — quality 3 — coupling: none (only catches Failure; other exceptions escape)
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart (+ base_single_class_state.dart) — status-enum single-class state + handleRequest with overridable loading/success/failure — quality 3 — coupling: low (copyWith cannot clear failure)
- lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart (+ base_state.dart) — handleRequest(loadingState, call, onSuccess, onError) for sealed states — quality 3 — coupling: low (global talker, print)
- lib/core/services/image_picker_service.dart — pick image + size-tiered JPEG compression (<=300KB none, <=2MB q85/1920, <=5MB q75/1600, >5MB q65/1280 + second pass) — quality 3 — coupling: low (needs BuildContext for EN snackbars)
- lib/core/services/api_service.dart — Dio wrapper (ApiServiceBase interface, get/post/put/delete with NetworkRequestParams, updateHeaders for token/Accept-Language) — quality 3 — coupling: low (reads token from SharedPreferencesManager at construction)
- lib/core/services/toast_manager.dart + lib/core/utilities/widgets/toasts/animated_custom_toast.dart — Overlay toast (success/failure/warning) + context.showToast extension, configurable alignment — quality 3 — coupling: low (AppColors)
- lib/core/services/notification_service.dart — FCM + local notifications init, permission flow w/ settings dialog, foreground display, topics, channels — quality 3 — coupling: low (needs BuildContext; tap routing TODO)
- lib/core/services/shared_preferences_manager.dart — singleton, dynamic setValue/getValue by type — quality 3 — coupling: none
- lib/core/services/debounce.dart — Timer debounce — quality 4 — coupling: none
- lib/core/theme/light_theme/ (light_theme.dart + light_widget_themes/*) — ThemeData split into one file per component theme — quality 3 — coupling: low (screenutil units in theme)
- lib/core/services/get_and_set_device_locale.dart — set easy_localization locale to device language if supported — quality 3 — coupling: low (dart:io Platform, not web-safe)
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/buttons/app_default_button.dart — primary button (morphs to circular loader, svg icon, double-tap lock) — onTap, text, child, isLoading, enabled, blockMultipleClicks, backgroundColor, textColor, borderColor, svgIconPath, height/width/radius/margin/padding — quality 3 — generic? y (lock ineffective: VoidCallback not awaited)
- lib/core/utilities/widgets/buttons/app_icon_button.dart — AppIconButton (square icon button over AppDefaultButton) + AppBackButton — onTap, child, height, width, radius, backgroundColor — quality 2 — generic? y (back icon hardcoded arrow_forward, no default pop)
- lib/core/utilities/widgets/default_screen.dart — base scaffold w/ custom header row (title/titleWidget/back button), safe-area paddings, FAB — body, pageTitle, pageTitleWidget, appbar, hasAppBar, hasBackButton, hasBottomBorder, hasBottomMargin, onBackPressed, topMargin, appBarPadding, bodyPadding, backgroundColor, floatingActionButton(+Location) — quality 3 — generic? y
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget<B,S,T> (BlocBuilder switch on status) + BaseLoadingWidget + BaseErrorWidget(retry) — successBuilder, loadingWidget, failureWidget, onRetry — quality 3 — generic? y (unused in app)
- lib/core/utilities/widgets/base_list_view_widget.dart — list w/ empty state — items, itemBuilder, emptyWidget — quality 2 — generic? y (default empty text 'no_tasks'; unused)
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — titled TextFormField (tap-outside unfocus, icon constraints) — controller, title, hintText, validator, keyboardType, inputFormatters, prefix/suffixIcon(+constraints), obscureText, readOnly, enabled, maxLines, maxLength, focusNode, textAlign, onChanged/onTap/onSaved/onFieldSubmitted/onEditingComplete, title/text/hint styles — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password field w/ visibility toggle — controller, title, hintText, isConfirmPassword, confirmPasswordValidator, isLogin, onChanged — quality 2 — generic? y (confirm/isLogin params ignored by validator)
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart — email field w/ svg prefix + validator — controller, title, hintText, readOnly, onChanged — quality 3 — generic? y (unused)
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart — read-only field opening bottom-sheet list of strings — title, hintText, controller, items, validator, onChanged — quality 3 — generic? y (unused)
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — generic DynamicDropdownFormField<T> via showMenu, optional search, loading suffix — controller, options, displayText, title, hintText, onOptionSelected, showSearch, isLoading — quality 2 — generic? y (stale options, search doesn't refilter open menu, forced required validator)
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart — animated toast body (fade+slide) — message, state, duration, location — quality 3 — generic? y
- lib/core/utilities/widgets/toasts/custom_toast.dart — static toast body — message, state, duration — quality 2 — generic? y (unused duplicate)
- lib/core/utilities/widgets/image_picker_bottom_sheet.dart — showImagePickerSheet(camera/gallery) — context, onFilePicked — quality 2 — generic? y (uses popped sheet context; unused)
- lib/core/utilities/widgets/container_with_shadow.dart — tappable shadow card — child, width, height, margin, padding, radius, backgroundColor, border, image, boxShadow, shadowBlurRadius, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/custom_chip.dart — pill chip with title + optional description — title, description, bgColor, borderColor, radius, titleColor/FontSize, descColor/FontSize, padding — quality 3 — generic? y
- lib/core/utilities/widgets/selection_chip_widget.dart — selectable chip — isSelected, title, onTap — quality 2 — generic? y
- lib/core/utilities/widgets/custom_radio_group_widget.dart — CustomRadioGroup<T> + animated CustomSizeRadio<T> — options, selectedValue, onChanged, prefixText, label / value, groupValue, size, active/inactiveColor, animationDuration — quality 2 — generic? y (AnimationController created in didChangeDependencies)
- lib/core/utilities/widgets/linear_progress_indicator.dart — LinearPercentIndicator (0-100) — percent, minHeight — quality 2 — generic? y (completed check `percent == 1` wrong scale)
- lib/core/utilities/widgets/app_divider.dart — themed Divider w/ widthFactor — height, thickness, color, indent, endIndent, widthFactor — quality 3 — generic? y
- lib/core/utilities/widgets/voice_recorder_player_widget.dart — record (flutter_sound, 1-min cap) / play local or remote (just_audio) voice note — onFileSaved, voicePath — quality 2 — generic? partly (1142 lines, 739 commented; listeners never cancelled)
- lib/core/utilities/widgets/black_yellow_card.dart — branded dark card with decorative svg shapes — child, borderRadius, circleShapeBottomPosition, padding — quality 2 — generic? n (brand-specific)
- lib/core/services/show_loading_dialog.dart — showLoadingDialog() blocking spinner dialog — context, message, barrierDismissible — quality 3 — generic? y
- lib/features/shared/widgets/image_Widget.dart — ImageViewerWidget: asset/local/network by string prefix, placeholder on error, stacked badge — image, imageWidth/Height, radius, color, margin, stackedWidget, onTap, fit, border — quality 3 — generic? y (Image.network, no caching)
- lib/features/shared/screens/image_viewer.dart — full-screen image viewer w/ close — imagePath — quality 2 — generic? y (no zoom; Positioned right:)
NOTABLE_IDEAS: SecureStorageManager self-healing reads/writes (lib/core/services/secure_storage_manager.dart) + first-launch keychain wipe because iOS keychain survives uninstall (lib/features/splash/presentation/screens/splash_screen.dart); size-tiered image compression (lib/core/services/image_picker_service.dart); field-level server error parsing into ErrorDetail (base_remote_data_source.dart); AppValidator IBAN mod-97 + isNumericInRange with namedArgs + customValidator composition; MaterialApp.router keyed by ValueKey(locale) to force full rebuild on language switch + Accept-Language header pushed via ApiService.updateHeaders (lib/main.dart, splash_screen.dart); Overlay toast with BuildContext extension (toast_manager.dart); AppIcons.svg helper switching asset vs network svg (lib/core/utilities/constants/icons.dart); String.imageType extension for asset/local/network images (lib/features/shared/widgets/image_Widget.dart); role-based bottom-nav items in BottomNavCubit.updateNavItemsForRole (lib/features/bottom_nav/presentation/cubit/bottom_nav_cubit.dart); FCM topic naming `<role>_topic_<lang>` + `all_topic_<lang>`; one-file-per-component ThemeData split (lib/core/theme/light_theme/light_widget_themes/); native geofencing bridge over MethodChannel (lib/geofence_service.dart + android Kotlin GeofenceHelper/GeofenceBroadcastReceiver + iOS AppDelegate)
SMELLS: BaseRemoteDataSource hides its dependency (sl<ApiService>() inside); BaseRepository only catches Failure, BaseCubit turns the rest into UnknownFailure whose message embeds the stack trace (shown to users); BaseSingleClassState copyWith uses `failure ?? this.failure` so failures never clear; AppDefaultButton tap-lock is a no-op (sync VoidCallback); AppBackButton hardcodes arrow_forward + Color(0xFFE2E2E2) and does nothing without onTap; LinearPercentIndicator `percent == 1` on a 0-100 scale; CustomSizeRadio creates AnimationController in didChangeDependencies (leak / multiple tickers); DynamicDropdownFormField never refreshes options (no didUpdateWidget) and uses withOpacity; image_picker_bottom_sheet shows SnackBar on a popped context; voice_recorder_player_widget.dart 739 commented lines, stream listeners re-added on every play and never cancelled; text_theme.dart only base size uses .sp (copyWith sizes are raw); deprecated APIs: withOpacity x6, WillPopScope x1 (lib/features/bottom_nav/presentation/widgets/attendance_dialog.dart), ColorScheme background/onBackground (light_color_scheme.dart); print x15 (bloc_observer.dart, base_cubit.dart); empty files (dark_theme.dart, price_converter.dart); unused deps (hydrated_bloc, cached_network_image, country_picker, url_launcher, flutter_html, flutter_animate, animate_do, google_maps_flutter); unused core (GenericFetchWidget, BaseListView, Debounce, EmailTextFormField, DropdownTextFormField, BaseSuccessResponse, showImagePickerSheet, LoggingInterceptor, ensureStartsWithZero, setAppLanguageToDeviceLanguage); absurd relative imports ('../../../../../../../../../../../../core/exports/core_exports.dart'); di setup functions declared async but not awaited; NotificationService needs a BuildContext and `_isAndroid13OrHigher` always returns true; login is refused unless push permission is granted; background handler re-shows `notification` payloads (duplicates on Android); ~90 hardcoded Color(0x..) in features; package name copied into three apps instead of a shared package
```

---

## 1. Architecture pattern

Feature-first "clean architecture lite", with no domain layer:

- **data**: `data_sources/*_remote_data_source.dart` extends `BaseRemoteDataSource` and calls
  `handleRequest(path, method, parser)`; `*_local_data_source.dart` wraps storage; `models/` holds
  hand-written `fromJson/toJson` classes; `repositories/*_repo.dart` extends `BaseRepository` and
  returns `Future<Either<Failure, T>>` through `handleNetworkCall`.
- **presentation**: cubits (`<name>_cubit/` or `managers/<name>_cubit/`) extend either `BaseCubit`
  (sealed `XxxInitial/Loading/Success/Failure` states that extend `BaseState`) or
  `BaseSingleClassStateCubit` (a single state class with `FetchDataStatusEnum status`, `failure`,
  plus feature fields and a `copyWith`). `screens/` and `widgets/` hold the UI.
- Repositories depend on concrete data sources, and cubits on concrete repositories. There are no
  interfaces and no use cases. Everything is wired in `lib/core/services/di_container.dart`.
- App-wide state lives in `AppCubit` (`lib/core/app_cubit/`: user + attendance). It is a
  `BaseSingleClassState` subclass.

Flow: Screen -> Cubit.handleRequest -> Repository.handleNetworkCall -> RemoteDataSource.handleRequest
-> `sl<ApiService>()` -> Dio.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                         # runZonedGuarded, prefs+easy_localization init, native splash, DI, Firebase, Crashlytics, FCM bg handler, MaterialApp.router
├── firebase_options.dart             # (exists; secret-class file, not opened)
├── geofence_service.dart             # GeofencingService singleton over MethodChannel + GeofenceEvent
├── core/
│   ├── app_cubit/                    # AppCubit/AppState (user, attendance, network flag)
│   ├── app_router/                   # app_router.dart (GoRouter), app_routes_names.dart (path consts)
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/         # base_remote_data_source.dart
│   │   │   ├── models/               # base_success_model.dart, id_title_model.dart, base_request_model/network_request_model.dart, base_response_model/base_success_response.dart
│   │   │   └── repository/           # base_repo.dart
│   │   └── presentation/managers/
│   │       ├── base_cubit/           # base_cubit.dart, base_state.dart
│   │       └── base_single_class_state_bloc/  # base_single_class_state(.dart|_bloc.dart)
│   ├── enums/                        # app_roles, fetch_data_status, http_method, task_type, toast_state
│   ├── exports/core_exports.dart     # barrel: material, go_router, easy_localization, screenutil, AppColors, DefaultScreen
│   ├── extensions/                   # context_extensions (theme/textTheme/colorScheme/isAr), list_extensions
│   ├── models/selection_model.dart
│   ├── services/                     # api_service, logging_interceptors, di_container, storage managers, notification, image picker, validator, toast, debounce, locale, misc helpers
│   ├── theme/
│   │   ├── dark_theme/dark_theme.dart        # EMPTY
│   │   └── light_theme/                      # light_theme.dart, my_light_themes_export.dart, light_widget_themes/{app_bar,bottom_nav,btn_txt,dialog,elevated_btn,input_decoration,light_color_scheme,snack_bar,text}_theme.dart
│   └── utilities/
│       ├── constants/                # colors, icons (AppIcons + svg helper), images, temp_images, constant_lists, keys/{api_keys,shared_preferences_keys}
│       ├── converters/price_converter.dart   # EMPTY
│       ├── failures/                 # failure.dart, error_details_model.dart
│       ├── formatters/date_formatter.dart
│       └── widgets/                  # buttons/, text_form_fields/, toasts/, default_screen, base_fetching_widget, base_list_view, cards/chips/radio/progress/divider, voice recorder
└── features/                         # auth, bottom_nav, home, maintenance, notifications, settings{language,notifications,settings}, shared, splash, supervisors, tasks
```

Features (files / lines): auth 8/439, bottom_nav 6/1039, home 14/1081, maintenance 15/2174,
notifications 8/565, settings 12/929, shared 3/190, splash 3/255, supervisors 18/2121, tasks 30/5340.

Representative feature, fully expanded (`features/notifications`):

```
features/notifications/
├── data/
│   ├── data_sources/notifications_remote_data_source.dart   # extends BaseRemoteDataSource; getNotifications() -> handleRequest(GET, parser)
│   ├── models/notifications_response_model.dart             # hand-written fromJson
│   └── repositories/notifications_repo.dart                 # extends BaseRepository; Either<Failure, NotificationsResponseModel>
└── presentation/
    ├── managers/notifications_cubit/
    │   ├── notifications_cubit.dart   # extends BaseSingleClassStateCubit; overrides loading/success/failure emits
    │   └── notifications_state.dart   # part of; extends BaseSingleClassState + notifications list + copyWith
    ├── screens/notifications_screen.dart
    └── widgets/{notifications_card,notifications_view}.dart
```

`features/auth` follows the same layout: a `BaseCubit` subclass with sealed states, the repo
saves the token to secure storage, and it calls `ApiService.updateHeaders(token)`.

## 3. Infrastructure

### State management
- `flutter_bloc ^9.1.1` and `equatable`. Only Cubits are used (`_initBlocs` is empty).
- `BaseCubit<State extends BaseState>.handleRequest<T>({loadingState, call, onSuccess, onError, showLoading})`
  emits the loading state, folds the Either, and catches anything else as `UnknownFailure` (with the
  stack trace in the message). It logs with `talker.info` and `print`.
- `BaseSingleClassStateCubit<State extends BaseSingleClassState>.handleRequest<T>({call, onNotDefaultSuccess, onNotDefaultFailure, onNotDefaultLoading})`
  emits `copyWith(status: loading)` by default, uses `copyWith(status: failure, failure:)` on Left,
  and always delegates success to the callback (the default success branch is commented out). It
  casts `copyWith(...) as State`.
- `BaseState` (Equatable) and the unused `LoadingState`/`ErrorState` are in `base_state.dart`.
- `AppBlocObserver` (`lib/core/services/bloc_observer.dart`) prints every create/event/change/transition/error/close with `print`.
- Quality: the two parallel base patterns are the most reusable part. The weak spots: `failure ?? this.failure` means
  failures cannot be cleared, the casts are unchecked, and the stack trace leaks into user-facing messages.

### DI
- `get_it ^8.0.3`. In `lib/core/services/di_container.dart`, `diContainerSetup()` calls `_initExternalServices`
  (prefs, secure storage, Dio, LoggingInterceptor), `_initDioAndRemoteDataSource` (ApiService with
  `ApiKeys.BASE_URL`, plus every data source), `_initRepo`, and `_initCubits` (`registerFactory`).
- The global `talker = Talker()` is also declared here. The functions are `async` but not awaited. The file imports every feature (hub coupling).

### Routing
- `go_router ^16.2.1`. In `lib/core/app_router/app_router.dart`, the top-level `final GoRouter appRouter` has
  `observers: [TalkerRouteObserver(talker)]`. The splash route uses a `CustomTransitionPage` fade. A `ShellRoute` wraps
  home/supervisors/maintenance/settings in `BottomNavScreen` and provides shell-scoped cubits. Other
  routes take arguments as `state.extra as Model`. `onExit` reloads data on the checklist route.
- Path constants live in `app_routes_names.dart` (several are unused: otp, onBoardingLanguage, singleTask, tasksLists, profile).
- There are no `redirect` guards. `SplashScreen` reads the token and calls `context.go(home|login)`. `BottomNavScreen` listens
  for `UnauthorizedFailure` and goes to login. There is no deep-link config.

### Networking
- `dio ^5.7.0`. `ApiService implements ApiServiceBase` (`lib/core/services/api_service.dart`) sets the base URL and 30 s
  connect/receive timeouts, and builds headers (JSON + `Authorization: Bearer` from a token read from
  SharedPreferences at construction). `updateHeaders({token, customHeaders})` can add or remove headers (a null value removes
  one). It is used for the token after login and for `Accept-Language` in the splash screen.
- The only interceptor is `TalkerDioLogger(printRequestHeaders: true)`. `LoggingInterceptor` (`logging_interceptors.dart`,
  chunked debugPrint) is registered in get_it but never added to Dio.
- `NetworkRequestParams` carries the uri, data, query, Options, CancelToken and progress callbacks. The base data source only
  forwards path/data/query, so cancel and progress are not reachable from features.
- Error mapping is in `BaseRemoteDataSource`. Status 200/201 go to the parser. 400 becomes `BadRequestFailure` (+ `ErrorDetail` list
  parsed from `{field: [msgs] | msg}`), 401 `Unauthorized`, 403 `Forbidden`, 404 `NotFound`, 500 and anything else `ServerFailure`.
  Dio `connectionTimeout` becomes `TimeoutFailure`, and no response becomes `NetworkFailure`. Messages fall back to hardcoded English.
- There is no token refresh, no retry, and no connectivity check (`hasNetworkConnection` in AppState is never updated).

### Local storage
- `SharedPreferencesManager` (singleton, `init()` awaited in main) offers `setValue(dynamic)`, `getValue`, `remove`, and `clear`.
- `SecureStorageManager` (singleton) uses Android `encryptedSharedPreferences + resetOnError` and the iOS `first_unlock` accessibility setting.
  Every operation is wrapped in a try block with self-healing (delete the corrupted key, retry the write once, fall back to clearing keys one by one).
- Keys live in `lib/core/utilities/constants/keys/shared_preferences_keys.dart`. The token and password go to secure storage. The user JSON,
  phone and email go to prefs (`features/auth/data/data_sources/auth_local_data_source.dart`).
- On first launch, the splash screen wipes secure storage, because the iOS keychain survives an uninstall. This is a good pattern.

### Localization and RTL
- `easy_localization ^3.0.7`, with `supportedLocales [ar, en]` and start/fallback `ar`. Files are in `assets/translations/{ar,en}.json`
  (nested keys such as `validation.*`, `auth.*`, `messages.*`, `bottom_nav.*`). `ConstantLists.languagesList` defines the
  language picker. `LanguageService.getFlagEmoji` maps a locale to a flag emoji.
- RTL: `MaterialApp.builder` wraps the app in a `Directionality` keyed on `languageCode == 'ar'`, which duplicates what the delegates already do.
  `context.isAr` (`context_extensions.dart`) is used to pick alignments. The counts are 15 Directional uses vs 13 left/right
  uses plus 15 `EdgeInsets.fromLTRB`. The core is mostly Directional (`DefaultScreen` body padding, text-field icons), but
  `DefaultScreen` header padding, `BlackYellowCard`, `ImageViewerScreen` and `AppBackButton` (forward arrow) assume one direction.
- `MaterialApp.router` gets `key: ValueKey(context.locale.toString())` to force a rebuild on language change.

### Theming
- `lib/core/theme/light_theme/light_theme.dart` builds `lightTheme` (M3). It uses `ColorScheme.fromSeed(primary)` with the deprecated
  `background/onBackground`, and component themes, one per file: AppBar (centered, 24.sp), BottomNav, ElevatedButton (fixed
  343x52, asymmetric radius), TextButton, legacy ButtonThemeData, SnackBar (floating), Dialog, InputDecoration (filled, outline
  borders in secondary100/200, error red500, hint/error from TextThemeLight), and ProgressIndicator.
- Colors: `AppColors` holds tonal scales for primary (amber), secondary (near-black grey), neutral, green and red, plus task-status colors and
  a `newColor(int)` helper.
- Text: `TextThemeLight` is a lazy singleton with the full M3 TextTheme and Alexandria font. Only the base style uses `.sp`, while the per-style
  `fontSize`s are raw numbers.
- No dark mode (`dark_theme.dart` is empty). Asset helpers: `AppIcons` (+ `svg()` that switches between asset and network) and `AppImages`.

### Responsive
- `flutter_screenutil ^5.9.3`, with `ScreenUtilInit(designSize: Size(393, 852), minTextAdapt: true, splitScreenMode: true)` in `lib/main.dart`.
  `.w/.h/.r/.sp` are used throughout, including inside theme files. There are no breakpoints or tablet layouts.

### Text scaling
- None. There is no `textScaler` clamp, and `minTextAdapt` is the only related setting.

### Env / flavors
- None. `ApiKeys` (`lib/core/utilities/constants/keys/api_keys.dart`) hardcodes `BASE_URL`/`BASE_IMAGE_URL` (`{{BASE_URL}}`) with
  commented alternates, plus all endpoint paths, some as functions (`GET_CHECKLIST_DETAILS(int id)`). The git branches
  `development/staging/main` stand in for environments.

### Logging
- `talker_flutter ^5` (global `talker`) is used for route observing, Dio logging (`TalkerDioLogger`) and BaseCubit info logs. There are also 55 `debugPrint`
  and 15 `print` calls, many with emoji. Nothing is gated on `kDebugMode`.

### Analytics / crash reporting
- `firebase_crashlytics ^5.0.5`. `FlutterError.onError = recordFlutterFatalError`, and `runZonedGuarded` passes errors to `recordError(fatal: true)`.
  There is no `PlatformDispatcher.onError`, no analytics, and no user identifiers set.

### Push notifications
- `firebase_messaging ^16` + `flutter_local_notifications ^19`. `NotificationService` (`lib/core/services/notification_service.dart`) is
  all static. `init(context)` is called from the splash screen. It requests permission (Android always, assuming 13+; iOS via FCM), opens a
  settings dialog when the permission is permanently denied, initializes local notifications, listens to `onMessage` and shows a local notification, and handles
  `onMessageOpenedApp`/`getInitialMessage` (only logged, TODO). It also logs the FCM token, listens to token refresh (TODO), and provides
  `showLocalNotification`, `showGeofenceNotification` (separate channel), cancel, and subscribe/unsubscribe.
- Topic scheme (commented in the file): `<role>_topic_<ar|en>` and `all_topic_<ar|en>`. Login subscribes to the topics (`features/auth/presentation/screens/login_screen.dart`).
- The background handler in `lib/main.dart` re-initializes Firebase and shows a local notification for `message.notification`. On Android
  that duplicates the system notification.
- The FCM token is sent as `device_token` in the login body, and login fails if the push permission is not authorized.

### IAP / payments
- None.

### Permissions
- `permission_handler ^12.0.1`: notification (NotificationService), microphone and storage (voice recorder), and location (geofence and attendance dialog,
  plus `geolocator ^14`). The Dart side has no central permission service.

### Deep links
- None.

### Other: geofencing
- `lib/geofence_service.dart` (`GeofencingService` singleton) talks to a native MethodChannel (`com.example.app/geofencing`) to add/remove
  geofences and receive `onGeofenceEvent`. The native code is in the Android Kotlin `GeofenceHelper`/`GeofenceBroadcastReceiver`/`MainActivity` and the iOS
  `AppDelegate`. The Dart side also has distance helpers that use geolocator. This is app-specific but a clean bridge.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/services/api_service.dart | Dio wrapper + header management | `ApiServiceBase`; `ApiService(baseUrl, dioClient, sharedPreferencesManager)`; `get/post/put/delete(NetworkRequestParams)`; `updateHeaders({token, customHeaders})` | dio, talker_dio_logger, SharedPreferencesManager | generic |
| lib/core/services/logging_interceptors.dart | Chunked debugPrint request/response/error logger | `LoggingInterceptor` (onRequest/onResponse/onError) | dio | generic (unused) |
| lib/core/services/di_container.dart | get_it wiring + global talker | `sl`, `talker`, `diContainerSetup()` | get_it, every feature | app-specific |
| lib/core/services/shared_preferences_manager.dart | Typed-by-runtime prefs singleton | `init()`, `setValue(key, dynamic)`, `getValue(key)`, `remove`, `clear` | shared_preferences | generic |
| lib/core/services/secure_storage_manager.dart | Self-healing secure storage singleton | `init()`, `read`, `write`, `delete`, `clearAll`, `containsKey`, `readAll` | flutter_secure_storage | generic |
| lib/core/services/notification_service.dart | FCM + local notifications | static `init(context)`, `showLocalNotification(...)`, `showGeofenceNotification`, `cancelNotification`, `cancelAllNotifications`, `subscribeToTopic`, `unsubscribeFromTopic` | firebase_messaging, flutter_local_notifications, permission_handler | generic (topics app-specific) |
| lib/core/services/image_picker_service.dart | Pick + tiered compression | `pickImage(context, source)`, `getImageSizeKB`, `getFormattedImageSize` | image_picker, flutter_image_compress, path_provider, path | generic |
| lib/core/services/app_validator.dart | Localized form validators | static `isNotEmpty`, `isValidEmail`, `isValidPhone`, `isValidSaudiPhone`, `isValidPassword(v, isLogin)`, `confirmPassword`, `isNumeric`, `isNumericInRange(min,max)`, `isNotEmptyImage`, `ibanValidator`, `customValidator(v, list)` | easy_localization | generic |
| lib/core/services/toast_manager.dart | Overlay toast + `context.showToast` | static `showToast(context, message, state, location, duration)`; extension `CustomToastExtension.showToast` | AnimatedCustomToast | generic |
| lib/core/services/show_loading_dialog.dart | Blocking loading dialog | `showLoadingDialog(context, message, barrierDismissible)` | material | generic |
| lib/core/services/bloc_observer.dart | Bloc lifecycle logging | `AppBlocObserver` | flutter_bloc | generic (uses print) |
| lib/core/services/debounce.dart | Timer debounce | `Debounce(milliseconds).run(cb)`, `cancel()` | dart:async | generic (unused) |
| lib/core/services/get_and_set_device_locale.dart | Device-locale helpers | `setAppLanguageToDeviceLanguage(context)`, `getDeviceLocale()` | easy_localization, dart:io | generic (unused) |
| lib/core/services/language_flags_service.dart | Locale -> flag emoji | `LanguageService.getFlagEmoji(locale)` | — | generic |
| lib/core/services/get_percentage.dart | Floor percent helper | `getPercentage(completed, total)` | — | generic |
| lib/core/services/phone_handeler_service.dart | Prefix '0' to phone | `ensureStartsWithZero(number)` | — | generic (unused) |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | Request executor + error mapping | `handleRequest<T>(path, method, parser, data, queryParameters)` | ApiService via `sl`, Failure, ErrorDetail | generic (body shape assumption) |
| lib/core/base_architecture/data/repository/base_repo.dart | Either wrapper | `handleNetworkCall<T>(call)` | dartz | generic |
| lib/core/base_architecture/data/models/base_request_model/network_request_model.dart | Request params bag | `NetworkRequestParams(uri, data, queryParameters, options, cancelToken, onSend/ReceiveProgress)` | dio | generic |
| lib/core/base_architecture/data/models/base_response_model/base_success_response.dart | `{status,message,data}` envelope | `BaseSuccessResponse<T>.fromJson(json, fromJsonT)`, `toJson` | — | generic (unused) |
| lib/core/base_architecture/data/models/base_success_model.dart | Marker success model | `BaseSuccessModel`, `BaseSuccessModelWithData<T>` | equatable | generic |
| lib/core/base_architecture/data/models/id_title_model.dart | id/title pair | `IdTitleModel` | — | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart | Cubit request helper (sealed states) | `handleRequest<T>(loadingState, call, onSuccess, onError, showLoading)` | flutter_bloc, dartz, talker | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/base_state.dart | State base | `BaseState`, `LoadingState`, `ErrorState` | equatable | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state.dart | Single-class state base | `BaseSingleClassState{status, failure, success, copyWith}` | equatable | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart | Cubit request helper (status enum) | `handleRequest<T>(call, onNotDefaultSuccess, onNotDefaultFailure, onNotDefaultLoading)` | flutter_bloc, dartz | generic |
| lib/core/app_cubit/app_cubit.dart (+ app_state.dart) | Global user/attendance state | `setUser`, `setAttendance`, `reset` | feature models | app-specific |
| lib/core/app_router/app_router.dart | GoRouter config | `appRouter` | go_router, every screen | app-specific |
| lib/core/app_router/app_routes_names.dart | Path constants | `AppRoutesNames.*` | — | app-specific |
| lib/core/utilities/failures/failure.dart | Failure hierarchy | `Failure(message, code, errors)` + 10 subclasses | — | generic |
| lib/core/utilities/failures/error_details_model.dart | Field error | `ErrorDetail(field, messages)`, `fromJson(field, list)` | — | generic |
| lib/core/utilities/formatters/date_formatter.dart | intl formatting | `formatDateString(str, fmt, {locale})`, `formatDate(date, fmt, locale)`, `isMorning(date)` | intl | generic (returns EN 'Invalid date or format') |
| lib/core/utilities/constants/colors.dart | Palette | `AppColors.*`, `newColor(int)` | — | app-specific values, generic shape |
| lib/core/utilities/constants/icons.dart | SVG paths + helper | `AppIcons.*`, `AppIcons.svg(assetName, width, height, color)` | flutter_svg, ApiKeys | generic helper |
| lib/core/utilities/constants/images.dart / temp_images.dart | Image paths + helper | `AppImages.image(...)`, `TempImages.image(...)` | — | generic helper |
| lib/core/utilities/constants/constant_lists.dart | Language list | `ConstantLists.languagesList` | LanguageModel (feature) | app-specific |
| lib/core/utilities/constants/keys/api_keys.dart | Base URLs + endpoints | `ApiKeys.*` | — | app-specific |
| lib/core/utilities/constants/keys/shared_preferences_keys.dart | Storage keys | `SharedPreferencesKeys.*` | — | app-specific |
| lib/core/extensions/context_extensions.dart | Theme shortcuts + isAr | `theme`, `textTheme`, `colorScheme`, `isAr` | material | generic |
| lib/core/extensions/list_extensions.dart | Null/empty check | `List?.isNullOrEmpty()` | — | generic |
| lib/core/enums/*.dart | `AppRoles`, `FetchDataStatusEnum`, `HttpMethod`, `TaskType`, `ToastState` | — | — | mixed |
| lib/core/models/selection_model.dart | Selection item | `SelectionModel(title, subTitle, value, image, colors)` | dart:ui | generic |
| lib/geofence_service.dart | Native geofencing bridge | `GeofencingService.instance.initialize/addGeofence/removeGeofence/...`, `onGeofenceEvent` | MethodChannel, geolocator, permission_handler | app-specific |
| lib/core/utilities/converters/price_converter.dart, lib/core/theme/dark_theme/dark_theme.dart | — | empty files | — | — |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/buttons/app_default_button.dart | Primary button; AnimatedSwitcher to circular loader; optional svg icon; tap lock | onTap, text, textStyle, child, height, width, radius, margin, padding, isLoading, backgroundColor, textColor, enabled, svgIconPath, svgIconColor, borderColor, blockMultipleClicks | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart | `AppIconButton` (icon tile) + `AppBackButton` | onTap, child, height, width, radius, backgroundColor / onTap | y (back arrow not locale-aware) |
| lib/core/utilities/widgets/default_screen.dart | Base scaffold with custom header | body, backgroundColor, appBarPadding, bodyPadding, topMargin, appbar, floatingActionButton, floatingActionButtonLocation, pageTitle, pageTitleWidget, hasAppBar, hasBottomBorder, hasBackButton, hasBottomMargin, onBackPressed | y |
| lib/core/utilities/widgets/base_fetching_widget.dart | `GenericFetchWidget<B,S,T>`, `BaseLoadingWidget`, `BaseErrorWidget` | successBuilder, loadingWidget, failureWidget(retry), onRetry / message, onRetry | y |
| lib/core/utilities/widgets/base_list_view_widget.dart | `BaseListView<T>` separated list + empty state | items, itemBuilder, emptyWidget | y |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart | Titled TextFormField | (see summary; 28 params) | y |
| lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart | Password + visibility toggle | controller, isConfirmPassword, title, hintText, confirmPasswordValidator, isLogin, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart | Email field | controller, title, hintText, readOnly, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart | Bottom-sheet string picker field | title, hintText, controller, items, validator, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart | `DynamicDropdownFormField<T>` popup menu picker | controller, options, displayText, title, onOptionSelected, hintText, showSearch, isLoading | y |
| lib/core/utilities/widgets/toasts/animated_custom_toast.dart | Animated toast body | message, state, duration, location | y |
| lib/core/utilities/widgets/toasts/custom_toast.dart | Static toast body | message, state, duration | y |
| lib/core/utilities/widgets/image_picker_bottom_sheet.dart | `showImagePickerSheet()` camera/gallery sheet | context, onFilePicked | y |
| lib/core/utilities/widgets/container_with_shadow.dart | Shadow card / tappable container | child, margin, padding, radius, width, height, image, backgroundColor, border, onTap, boxShadow, shadowBlurRadius | y |
| lib/core/utilities/widgets/custom_chip.dart | Title/description pill | title, description, bgColor, borderColor, titleColor, radius, titleFontSize, padding, descColor, descFontSize | y |
| lib/core/utilities/widgets/selection_chip_widget.dart | Selectable chip | isSelected, title, onTap | y |
| lib/core/utilities/widgets/custom_radio_group_widget.dart | `CustomRadioGroup<T>` + `CustomSizeRadio<T>` | options, selectedValue, onChanged, prefixText, label / value, groupValue, onChanged, size, activeColor, inactiveColor, animationDuration | y |
| lib/core/utilities/widgets/linear_progress_indicator.dart | Rounded linear progress (0-100) | percent, minHeight | y |
| lib/core/utilities/widgets/app_divider.dart | Divider with width factor | height, thickness, color, indent, endIndent, widthFactor | y |
| lib/core/utilities/widgets/voice_recorder_player_widget.dart | Voice note record/play (local + remote) | onFileSaved, voicePath | partly |
| lib/core/utilities/widgets/black_yellow_card.dart | Branded decorative card | child, borderRadius, circleShapeBottomPosition, padding | n |
| lib/core/services/show_loading_dialog.dart | Loading dialog | context, message, barrierDismissible | y |
| lib/features/shared/widgets/image_Widget.dart | `ImageViewerWidget` asset/local/network + `ImageType` extension | image, imageWidth, imageHeight, margin, onTap, stackedWidget, radius, fit, color, border | y |
| lib/features/shared/screens/image_viewer.dart | Full-screen image screen | imagePath | y |
| lib/features/splash/presentation/screens/splash_screen.dart (`AnimatedImageViewer`) | Animated logo (opacity/scale/shake) | image, imageHeight, imageWidth, radius | y |

Missing (not present): shimmer/skeleton widget (raw `Skeletonizer` used once in home_screen), empty-state widget,
confirm dialog, cached network image, pagination list, generic bottom sheet, app bar widget, snackbar helper.

## 6. Packages (`pubspec.yaml`)

- **State**: flutter_bloc ^9.1.1, equatable ^2.0.7, hydrated_bloc ^10.1.1 (unused)
- **DI**: get_it ^8.0.3
- **Routing**: go_router ^16.2.1
- **Network**: dio ^5.7.0, dartz ^0.10.1, talker_dio_logger ^5.0.0
- **Storage**: shared_preferences ^2.3.3, flutter_secure_storage ^9.2.4, path_provider ^2.1.5, path ^1.9.1
- **L10n**: easy_localization ^3.0.7, intl ^0.20.2, flutter_localizations
- **UI**: flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, skeletonizer ^2.1.0+1, flutter_native_splash ^2.4.3, dotted_border ^3.1.0, flutter_animate ^4.5.2 (unused), animate_do ^4.2.0 (unused), flutter_html ^3.0.0 (unused), cupertino_icons
- **Firebase**: firebase_core ^4.1.0, firebase_messaging ^16.0.1, firebase_crashlytics ^5.0.5, flutter_local_notifications ^19.4.1
- **Media**: image_picker ^1.1.2, flutter_image_compress ^2.4.0, cached_network_image ^3.4.1 (unused), flutter_sound ^9.2.13, just_audio ^0.10.0
- **Location**: geolocator ^14.0.2, google_maps_flutter ^2.3.2 (unused in Dart)
- **Utils**: permission_handler ^12.0.1, package_info_plus ^8.3.0, url_launcher ^6.3.1 (unused), country_picker ^2.0.2 (unused), talker_flutter ^5.0.0, flutter_launcher_icons ^0.14.4 (listed under dependencies)
- **Dev**: flutter_test, flutter_lints ^6.0.0

## 7. Quality notes

- **Null safety**: yes (Dart ^3.7.2), with heavy `!` on parsed fields (`response.token!`, `token!` from FCM).
- **Lints**: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` and adds no rules.
- **Tests**: `test/widget_test.dart` is the default counter template and would fail against this app.
- **Duplication**: the whole `lib/core` is copy-pasted into `brgr manager` and `brgr_maintenance`, with only the package
  name renamed and small drift (see those reports). Validators, toasts and buttons have already diverged three ways.
- **Deprecated APIs**: `withOpacity` x6, `WillPopScope` x1, `ColorScheme.background/onBackground`, and legacy `ButtonThemeData`.
- **Dead code**: about 739 commented lines in the voice recorder, empty `dark_theme.dart`/`price_converter.dart`, a registered but unattached
  `LoggingInterceptor`, and unused base widgets and helpers (listed in SMELLS).
- **Hardcoded values**: about 90 `Color(0x..)` in features, English fallback failure messages, English permission dialog text,
  and a hardcoded base URL with no environment separation.
- **Secrets**: Google Maps API keys sit in native config (see the final message). `firebase_options.dart`, `android/app/google-services.json` and
  an iOS plist exist (not opened). A `RECOVERY-CODES-*.txt` file sits in the parent `old brgr projects/` folder (not opened).
- **Best reuse candidates for the template**: `secure_storage_manager.dart`, `failure.dart` + `error_details_model.dart`,
  `app_validator.dart`, the two base cubits (after fixing failure clearing), the `base_remote_data_source.dart` error mapping (inject
  ApiService instead of `sl`), `image_picker_service.dart` compression tiers, the toast overlay plus extension, and the theme-per-component layout.
