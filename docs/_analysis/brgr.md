# brgr — analysis report

## Summary for comparison

```
PROJECT: brgr | path: Datum/brgr | stack: Flutter, Dart ^3.7.2 (flutter_lints ^6) | last commit: 2026-07-14 | source files: 276
ARCH: clean-arch-lite, feature-first — features/<role_feature>/<sub>/{data: data_sources, models, repositories | presentation: managers(cubits), screens, widgets}; no domain layer (no entities/usecases); shared bases in core/base_architecture
STATE: flutter_bloc 9 (Cubits only) — two bases: BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart, sealed per-feature states, 11 cubits) + BaseSingleClassStateCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart, one state class + FetchDataStatusEnum + copyWith, 8 cubits); global AppCubit (user/role/attendance)
DI: get_it, manual registration, global `sl` (+ global `talker`) — lib/core/services/di_container.dart
ROUTING: go_router 16 — lib/core/app_router/app_router.dart (+ app_routes_names.dart, root_navigator_key.dart) — guards: none (no redirect; splash picks start route by token+role) — ShellRoute for role-based bottom nav — args via state.extra — deep links: none
NETWORK: dio 5 — interceptors: UnauthorizedInterceptor (global 401 → logout, excluded auth paths, re-entrancy guard), TalkerDioLogger (custom LoggingInterceptor exists but unused) | token refresh: n | retry: n | error mapping: BaseRemoteDataSource maps status code / DioException type → Failure subclasses, parses field errors; Failure.displayMessage hides UnknownFailure text | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/services/unauthorized_interceptor.dart, lib/core/utilities/helpers/handle_unauthorized.dart
RESULT_TYPE: Either (dartz) — data source throws Failure (implements Exception), BaseRepository.handleNetworkCall wraps to Either — lib/core/utilities/failures/failure.dart
STORAGE: shared_preferences + flutter_secure_storage (token, password) — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart (hydrated_bloc declared, unused)
L10N: easy_localization — ar, en; default/start/fallback = ar; assets/translations/{ar,en}.json (nested, 280 keys each) — hardcoded UI strings: some (~86 Arabic literal lines in ~10 feature files, partly mock data; English strings in NotificationService permission dialog)
RTL: Directional=25 vs LeftRight=43 (15 by brief regex + EdgeInsets.fromLTRB; 29 fromLTRB lines total)
THEME: lib/core/theme/light_theme/light_theme.dart (+ light_widget_themes/*) — dark mode n (dark_theme.dart is an empty file) | component themes y (appBar, elevated/text/legacy button, inputDecoration, dialog, snackBar, bottomNav, progressIndicator) | colors class AppColors (lib/core/utilities/constants/colors.dart, 50–1000 tonal scales) | text styles TextThemeLight singleton (lib/core/theme/light_theme/light_widget_themes/text_theme.dart, full M3 TextTheme, fixed px) | fonts: Alexandria (used), Cairo (bundled, unused)
RESPONSIVE: flutter_screenutil (design 393x852, minTextAdapt, splitScreenMode) — breakpoints: none (.w/.h/.r heavily used; .sp almost never)
TEXT_SCALING: none (no TextScaler clamp; theme font sizes are raw px)
ENV/FLAVORS: hardcoded constants (live/testing base URLs toggled by commenting) — lib/core/utilities/constants/keys/api_keys.dart; no flavors, no --dart-define
LOGGING: talker (+ talker_dio_logger, TalkerRouteObserver) mixed with print (15) and debugPrint (60)
ANALYTICS/CRASH: firebase_crashlytics (FlutterError.onError + runZonedGuarded) ; no analytics
PUSH: fcm + flutter_local_notifications (static NotificationService, topic subscriptions per role+lang) — lib/core/services/notification_service.dart, lib/core/services/notification_topic_handler.dart
PAYMENTS/IAP: none
PERMISSIONS: permission_handler (notification, camera/photos on iOS, location always/when-in-use, mic/storage) — inline in services
DEEP_LINKS: none (notification tap navigation is TODO)
MEDIA/FILES: image_picker + flutter_image_compress (size-tiered compression, lost-data recovery), flutter_sound + just_audio (voice notes), flutter_svg, path_provider; cached_network_image declared but unused (Image.network used)
TESTS: 1 — default counter smoke test (broken, references counter text)
LINTS: flutter_lints/flutter.yaml, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — generic handleRequest<T>(path, method, parser) + status→Failure mapping + field-error parsing — quality 4 — coupling: low (resolves ApiService via sl, logs via global talker)
- lib/core/utilities/failures/failure.dart — Failure hierarchy (400/401/403/404/5xx/network/timeout/cache/validation/unknown) + displayMessage extension — quality 4 — coupling: low (easy_localization key)
- lib/core/services/unauthorized_interceptor.dart — Dio 401 interceptor with excluded paths, defers to context-free logout — quality 4 — coupling: low (ApiKeys paths)
- lib/core/utilities/helpers/handle_unauthorized.dart — triggerUnauthorizedLogout via rootNavigatorKey with next-frame retry + re-entrancy guard — quality 3 — coupling: high (imports app-specific cubits/topics)
- lib/core/services/secure_storage_manager.dart — FlutterSecureStorage wrapper with corruption recovery (delete-and-retry, resetOnError) — quality 4 — coupling: none
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart (+ base_single_class_state.dart) — single-state cubit base with loading/failure defaults and override hooks — quality 3 — coupling: low
- lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart — handleRequest(loadingState, call, onSuccess, onError) — quality 3 — coupling: low (print + talker)
- lib/core/base_architecture/data/repository/base_repo.dart — handleNetworkCall → Either — quality 3 — coupling: none (only catches Failure)
- lib/core/services/api_service.dart — Dio wrapper with abstract ApiServiceBase, header mutation (token, custom headers, null removes) — quality 3 — coupling: low (reads token from prefs, 5-min timeouts)
- lib/core/services/image_picker_service.dart — pick + per-platform permission gate + settings dialog + size-tiered compression + retrieveLostData — quality 4 — coupling: low (tr keys)
- lib/core/services/app_validator.dart — static validators incl. IBAN mod-97, numeric range, Saudi phone, combinator — quality 4 — coupling: low (tr keys)
- lib/core/services/toast_manager.dart (+ widgets/toasts/animated_custom_toast.dart) — overlay toast + BuildContext.showToast extension — quality 3 — coupling: low
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget<B,S,T> status switch + BaseLoadingWidget + BaseErrorWidget — quality 3 — coupling: low
- lib/core/services/pending_capture_service.dart — persist "camera open for id X" to recover photos after Android process death — quality 4 — coupling: low (prefs keys)
- lib/core/services/notification_service.dart — FCM + local notifications init, channels, foreground display, topics — quality 2 — coupling: low (hardcoded English dialog, broken channel creation, tap TODOs)
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/buttons/app_default_button.dart — primary button — text, onTap, isLoading, enabled, svgIconPath, colors, radius, width/height, margin/padding, child, blockMultipleClicks — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart — icon button + AppBackButton — child, onTap, size, radius, bg — quality 2 — generic? y (AppBackButton hardcodes arrow_forward + color, no default pop)
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — titled text field — controller, title, hint, validator, prefix/suffix, obscure, readOnly, formatters, maxLines, callbacks — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password field with visibility toggle — controller, title, hint, isLogin, isConfirmPassword — quality 2 — generic? y (confirm validator ignored)
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart — email field — controller, title, hint, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart — read-only field opening bottom-sheet list — title, hint, controller, items, validator, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — generic <T> dropdown via showMenu with optional search — options, displayText, onOptionSelected, isLoading, showSearch — quality 3 — generic? y (validator forced, 'Search...' hardcoded)
- lib/core/utilities/widgets/default_screen.dart — base scaffold with custom header row — body, pageTitle/pageTitleWidget, hasAppBar, hasBackButton, onBackPressed, paddings, FAB — quality 3 — generic? y
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget / BaseLoadingWidget / BaseErrorWidget — successBuilder, loadingWidget, failureWidget, onRetry — quality 3 — generic? y
- lib/core/utilities/widgets/base_list_view_widget.dart — separated list with empty state — items, itemBuilder, emptyWidget — quality 2 — generic? y (empty text key 'no_tasks')
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart — animated overlay toast — message, state, duration, location — quality 3 — generic? y
- lib/core/utilities/widgets/toasts/custom_toast.dart — static toast — message, state — quality 2 — generic? y (superseded by animated one)
- lib/core/services/show_loading_dialog.dart — blocking loading dialog fn — context, message, barrierDismissible — quality 3 — generic? y
- lib/core/utilities/widgets/image_picker_bottom_sheet.dart — camera/gallery sheet fn — context, onFilePicked — quality 2 — generic? y (uses popped sheet context)
- lib/core/utilities/widgets/container_with_shadow.dart — tappable card container — child, padding, margin, radius, bg, border, boxShadow, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/app_divider.dart — divider — height, thickness, color, indent, widthFactor — quality 3 — generic? y
- lib/core/utilities/widgets/app_tab_switcher.dart — pill segmented TabBar — tabController, selectedIndex, tabs, onTabChanged — quality 3 — generic? y
- lib/core/utilities/widgets/custom_chip.dart — chip with title/description — title, description, colors, radius, font sizes — quality 3 — generic? y
- lib/core/utilities/widgets/selection_chip_widget.dart — selectable chip — isSelected, title, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/custom_radio_group_widget.dart — CustomRadioGroup<T> + animated CustomSizeRadio<T> — options, selectedValue, onChanged, label, prefixText, size — quality 3 — generic? y
- lib/core/utilities/widgets/expandable_container.dart — expandable card with image/description — title, image, collapsed/expanded content, onToggle — quality 2 — generic? partly (imports feature ImageViewerWidget)
- lib/core/utilities/widgets/linear_progress_indicator.dart — percent bar (green at 100%) — percent, minHeight — quality 3 — generic? y (name clashes with percent_indicator pkg)
- lib/core/utilities/widgets/voice_recorder_player_widget.dart — record/play voice note (local or remote URL) — onFileSaved, voicePath — quality 2 — generic? y (723 of 1142 lines commented-out)
- lib/core/utilities/widgets/black_yellow_card.dart — branded header card with decorative shapes — child, borderRadius, padding — quality 2 — generic? n (brand art)
- lib/features/shared/widgets/image_Widget.dart — ImageViewerWidget: asset/file/network by path prefix with placeholder fallback — image, size, radius, fit, border, stackedWidget, onTap — quality 3 — generic? y (prefixes BASE_IMAGE_URL)
- lib/features/shared/screens/image_viewer.dart — full-screen image viewer — imagePath — quality 2 — generic? y (no zoom)
- lib/features/splash/presentation/screens/splash_screen.dart (AnimatedImageViewer) — fade/scale/shake logo animation — image, size, radius — quality 3 — generic? y
- lib/features/bottom_nav/presentation/widgets/navigation_widget.dart — bottom-nav item — navItem, isSelected, onTapItem — quality 3 — generic? y
- lib/features/settings/settings/presentation/widgets/settings_item_widget.dart — settings row with icon bubble — navigationItemModel, widget — quality 3 — generic? y
NOTABLE_IDEAS: global 401 handling = UnauthorizedInterceptor + context-free triggerUnauthorizedLogout via rootNavigatorKey with next-frame retry and re-entrancy guard (lib/core/services/unauthorized_interceptor.dart, lib/core/utilities/helpers/handle_unauthorized.dart); Failure.displayMessage that never leaks raw/unknown errors (lib/core/utilities/failures/failure.dart); defensive error-body parsing for non-map responses (base_remote_data_source.dart); secure-storage corruption recovery + iOS-reinstall token wipe using IS_FIRST_TIME flag (secure_storage_manager.dart, splash_screen.dart); Android process-death photo recovery (pending_capture_service.dart + ImagePickerService.retrieveLostData + MainApp._recoverLostImage); size-tiered image compression (image_picker_service.dart); UserRole enhanced enum with backend value/code + tryFromString (lib/core/enums/app_roles_enum.dart); single role→route+nav mapping (lib/core/utilities/helpers/role_navigation.dart); FCM topics per role+language with resubscribe on language change (notification_topic_handler.dart, settings_cubit.dart); persisted per-task wall-clock timer (features/maintenance_technician_feature/technician_maintenance/presentation/managers/task_timer_service.dart); native geofencing bridge via MethodChannel + Haversine fallback (lib/geofence_service.dart + native Kotlin/Swift); AppButton tap-lock idea; Accept-Language header synced with locale
SMELLS: hardcoded demo-account credentials and role overrides inside AuthRepository; two competing cubit bases (BaseCubit vs BaseSingleClassStateCubit) + 2 toast widgets + 2 logging interceptors; managers_checklists models are near-verbatim copies of supervisor tasks models (6 task_clones_models + others); diContainerSetup() is async but not awaited and its sub-inits are not awaited (TaskTimerService registered after an await); handle_unauthorized calls sl<TechnicianMaintenancesCubit>() which is a registerFactory → new instance, not the live one; ApiService reads token from SharedPreferences while it is stored in secure storage; AppDefaultButton tap-lock is ineffective (VoidCallback not awaited); NotificationService creates channels on a fresh AndroidFlutterLocalNotificationsPlugin() (resolvePlatformSpecificImplementation referenced but not called), _isAndroid13OrHigher always true, hardcoded English dialog; ToastManager's delayed remove can kill a newer toast; Content-Type header toggled globally for multipart (race-prone); empty dark_theme.dart/price_converter.dart; ColorScheme.background/onBackground (deprecated), withOpacity x8, WillPopScope x1; print x15 + debugPrint x60 (FCM token logged); hardcoded Arabic UI strings incl. mock notifications; core imports features (circular coupling: core/di, core/handle_unauthorized, core/app_cubit, constant_lists → features); unused deps (hydrated_bloc, flutter_html, country_picker, animate_do, flutter_animate, google_maps_flutter, cached_network_image); absurd relative imports ('../../../../../../../../core/...'); no router guards; 5-minute timeouts; broken default widget test; Google Maps API key committed in native files
```

---

## 1. Architecture pattern

**Clean-architecture-lite, feature-first, Cubit-based.**

- `lib/core/` holds everything shared: base classes (`base_architecture/`), services, theme, router, enums, extensions, constants, failures, and generic widgets.
- `lib/features/<feature>/` (sometimes `<role_feature>/<sub_feature>/`) contains:
  - `data/data_sources/`: a `*RemoteDataSource extends BaseRemoteDataSource` that calls `handleRequest(path, method, parser)`. Some features also have a `*LocalDataSource`, which wraps SharedPreferences/SecureStorage through `sl`.
  - `data/models/`: hand-written `fromJson`/`toJson`/`copyWith` models. There is no codegen and no freezed/json_serializable. Request params also live here (`requests/`).
  - `data/repositories/`: a `*Repository extends BaseRepository` that wraps each call in `handleNetworkCall`, which returns `Either<Failure, T>`.
  - `presentation/managers/<x>_cubit/` (named `cubit/`, `<x>_cubit/` or `managers/` depending on the feature): a cubit plus a `part` state file.
  - `presentation/screens/` and `presentation/widgets/`.
- **No domain layer.** There are no entities, use cases or abstract repository interfaces. Cubits depend on concrete repositories, and repositories depend on concrete data sources.
- Features are split **by user role**: supervisor/branch manager, maintenance technician, managers (area/operation). Each role gets its own bottom-nav item set.
- Two state styles coexist:
  1. `BaseCubit<S extends BaseState>` with a sealed state hierarchy per feature (`LoginLoading/LoginSuccess/LoginFailure`). Used by 11 cubits.
  2. `BaseSingleClassStateCubit<S extends BaseSingleClassState>`: one immutable state with `status: FetchDataStatusEnum`, `failure` and `copyWith`. Used by 8 cubits (notifications, maintenances, checklists, ...). `GenericFetchWidget` renders this style.

Data flow: `Screen → context.read<Cubit>() → Cubit.handleRequest(call: repo.x) → Repository.handleNetworkCall(call: ds.x) → BaseRemoteDataSource.handleRequest → sl<ApiService>() (Dio)`. The data source throws a `Failure`, the repository converts it to `Left`, and the cubit emits a state. The UI shows `failure.displayMessage` through a toast.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                       – runZonedGuarded bootstrap: prefs, easy_localization, native splash, DI, BlocObserver, Firebase, FCM bg handler, Crashlytics; MainApp = ScreenUtilInit + MultiBlocProvider + MaterialApp.router + Directionality
├── firebase_options.dart           – FlutterFire generated (secret file; exists, not opened for report)
├── geofence_service.dart           – GeofencingService singleton (MethodChannel to native geofence), Haversine distance, permission helper, register fn
├── core/
│   ├── app_cubit/                  – AppCubit/AppState: global user, role, attendance (extends BaseSingleClassState)
│   ├── app_router/                 – app_router.dart (GoRouter), app_routes_names.dart (path consts), root_navigator_key.dart
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/       – base_remote_data_source.dart (handleRequest + error mapping)
│   │   │   ├── models/             – base_success_model.dart, id_title_model.dart, base_request_model/network_request_model.dart, base_response_model/base_success_response.dart
│   │   │   └── repository/         – base_repo.dart (handleNetworkCall → Either)
│   │   └── presentation/managers/
│   │       ├── base_cubit/         – BaseCubit + BaseState/LoadingState/ErrorState
│   │       └── base_single_class_state_bloc/ – BaseSingleClassState + BaseSingleClassStateCubit
│   ├── enums/                      – app_roles_enum (UserRole), fetch_data_status, http_method, task_status (title/color/icon), task_type, toast_state
│   ├── exports/core_exports.dart   – barrel: material, go_router, easy_localization, screenutil, AppColors, DefaultScreen
│   ├── extensions/                 – context_extensions (theme/textTheme/colorScheme/isAr), list_extensions (isNullOrEmpty)
│   ├── models/selection_model.dart – generic selectable item model
│   ├── services/                   – api_service, unauthorized_interceptor, logging_interceptors, di_container, secure/shared prefs managers, notification_service + topic handler, image_picker_service, pending_capture_service, toast_manager, show_loading_dialog, app_validator, bloc_observer, debounce, locale/flags/percentage/phone helpers
│   ├── theme/
│   │   ├── dark_theme/dark_theme.dart        – EMPTY
│   │   └── light_theme/
│   │       ├── light_theme.dart              – ThemeData assembly
│   │       ├── my_light_themes_export.dart   – barrel
│   │       └── light_widget_themes/          – app_bar, bottom_nav, btn_txt, dialog, elevated_btn, input_decoration, light_color_scheme, snack_bar, text_theme
│   └── utilities/
│       ├── constants/              – colors.dart (AppColors), icons.dart (AppIcons + svg helper), images.dart, temp_images.dart, constant_lists.dart (languages), keys/api_keys.dart (base URL + endpoints), keys/shared_preferences_keys.dart
│       ├── converters/             – price_converter.dart (EMPTY)
│       ├── failures/               – failure.dart, error_details_model.dart
│       ├── formatters/             – date_formatter.dart
│       ├── helpers/                – handle_unauthorized.dart, role_navigation.dart
│       └── widgets/                – buttons/, text_form_fields/, toasts/, default_screen, base_fetching_widget, base_list_view_widget, container_with_shadow, app_divider, app_tab_switcher, custom_chip, selection_chip, custom_radio_group, expandable_container, image_picker_bottom_sheet, linear_progress_indicator, black_yellow_card, voice_recorder_player_widget
└── features/
    ├── auth/                       – data (auth local/remote DS, login/register params, user_model, login_response) + presentation (auth/login/register cubits, login & register screens)
    ├── splash/presentation/        – config_cubit (brand identity), splash_screen (token/role routing, AnimatedImageViewer)
    ├── bottom_nav/                 – navigation_item_model, BottomNavCubit (role → items), BottomNavScreen (ShellRoute host), attendance_dialog (geofence check-in/out, 790 lines), navigation_widget
    ├── settings/settings/          – data (settings DS/repo, change_language, language_model, delete_account_service[Firestore]) + presentation (settings_cubit, settings_screen, logout/profile/item widgets)
    ├── notifications/              – data (DS, repo, response model) + presentation (notifications_cubit, list + detail screens, card/view widgets)
    ├── shared/                     – screens (image_viewer, select_location stub), widgets (image_Widget.dart → ImageViewerWidget)
    ├── supervisor_branch_manager_feature/
    │   ├── home/                   – user/attendance/check-in; home_cubit + attendances_cubit; home_screen
    │   ├── tasks/                  – checklists + polymorphic task clones (yes/no, data, category item, staff member); checklist_cubit, tasks_cubit; 5 large completion screens (460–790 lines)
    │   ├── supervisors/            – supervisors list, attendance, supervisor checklists
    │   └── maintenance/            – (expanded below)
    ├── maintenance_technician_feature/technician_maintenance/ – technician maintenance list/details/complete/report/success; TaskTimerService
    └── managers_feature/
        ├── managers_home/          – statics, performance cards, (mock) notifications/checklists views
        ├── managers_checklists/    – checklists, statics, details (models duplicated from supervisor tasks)
        └── managers_reports/       – reports_screen (fl_chart)
```

Representative feature, fully expanded (`features/supervisor_branch_manager_feature/maintenance/`):

```
maintenance/
├── data/
│   ├── data_sources/maintenance_remote_data_source.dart   – MaintenancesRemoteDataSource extends BaseRemoteDataSource
│   ├── models/
│   │   ├── maintenances_response_model.dart               – list + MaintenanceModel (fromJson/copyWith)
│   │   ├── branch_location_model.dart, issue_type_model.dart
│   │   ├── end_maintenance_request_model.dart
│   │   ├── maintenance_status_enum.dart, priority_enum.dart – enums with title/color (some Arabic literals)
│   └── repositories/maintenance_repo.dart                 – MaintenancesRepository extends BaseRepository
└── presentation/
    ├── managers/maintenances_cubit/{maintenances_cubit,maintenances_state}.dart – BaseSingleClassStateCubit style
    ├── screens/maintenances_screen.dart, maintenance_details_screen.dart (689 lines), maintenance_request_bottom_sheet.dart
    └── widgets/maintenance_card.dart, priority_selection_widget.dart
```

## 3. Infrastructure

### State management
- `flutter_bloc ^9.1.1`, Cubits only. `BaseCubit.handleRequest` emits the loading state if `showLoading`, awaits `Either`, then calls `onSuccess`/`onError`. Unexpected throws turn into `UnknownFailure` and are logged with `talker.error`. It mixes `print` and `talker.info`.
- `BaseSingleClassStateCubit.handleRequest` sets the default loading state (`status=loading, failure=null`) and the default failure state. `onNotDefaultSuccess` is mandatory, and there are optional loading/failure overrides. The default "success" emit is commented out, so every caller must emit success itself. `copyWith(...) as State` casts are unchecked.
- `AppCubit` is a global user/role/attendance holder. It is provided at the root. Many feature cubits are provided globally in `main.dart` (Tasks, Checklist, Attendances, Maintenances, TechnicianMaintenances, Notifications, Settings, Auth, BottomNav), and the role-specific ones are provided in the ShellRoute.
- `AppBlocObserver` (`lib/core/services/bloc_observer.dart`) prints every create/change/close with `print`. There is no debug guard.

### DI
- `get_it ^8`, `lib/core/services/di_container.dart`. A global `sl` and a global `talker = Talker()` live in the same file. Registration is manual and grouped into `_initExternalServices`, `_initDioAndRemoteDataSource`, `_initRepo`, `_initCubits`. Data sources and repos are lazy singletons, cubits are factories.
- Issues: `diContainerSetup()` is `async` but `main` does not await it, and the inner `_init*` calls are not awaited either. `TaskTimerService` is registered after `await SharedPreferences.getInstance()`, so it races. The core DI file imports every feature.

### Routing
- `go_router ^16.2.1`, a global `appRouter` with `navigatorKey: rootNavigatorKey` and a `TalkerRouteObserver`. Route paths are string constants in `AppRoutesNames`.
- A `ShellRoute` hosts `BottomNavScreen` and provides the role-specific cubits. Tab switches go through `BottomNavCubit.changeBottomNavIndex`, and a `BlocConsumer` listener calls `context.go(route)`.
- There are no `redirect` guards. `SplashScreen` decides login vs role landing route using the token in secure storage plus the cached role. `role_navigation.dart` centralizes role → route and role → nav items.
- Arguments are passed via `state.extra` casts, which break on web refresh and deep links. `onExit` is used to refresh a list after leaving a detail screen.

### Networking
- `ApiService implements ApiServiceBase` (`lib/core/services/api_service.dart`):
  - It wraps an injected `Dio` and sets the base URL from `ApiKeys.BASE_URL`, 5-minute connect/receive timeouts, and JSON headers.
  - `updateHeaders(token:, customHeaders:)` rebuilds the global headers. A `null` value removes a header; this is used to toggle `Content-Type` for multipart.
  - `_executeRequest` rethrows `SocketException`/`FormatException` with new messages, which adds nothing.
  - The token is initially read from SharedPreferences, but the app saves it to SecureStorage. The splash screen then pushes the token in via `updateHeaders`.
- Interceptors: `UnauthorizedInterceptor` (401 → `triggerUnauthorizedLogout()`, skipped for login/config/logout paths, passes the error on) and `TalkerDioLogger(printRequestHeaders: true)`, which logs bearer tokens. A custom `LoggingInterceptor` is registered in DI but never added.
- `BaseRemoteDataSource.handleRequest<T>(path, method, parser, data, queryParameters)`:
  - It switches on the `HttpMethod` enum and accepts 200/201.
  - Status mapping: 400 → `BadRequestFailure` (with `ErrorDetail` list parsed from `{field: [msgs]}`), 401/403/404/500 → their own types, any other status → `ServerFailure` (if the body has a message) or `UnknownFailure`.
  - `DioException`: only `connectionTimeout` → `TimeoutFailure`, a response present → status mapping, everything else → `NetworkFailure`. `receiveTimeout` therefore becomes NetworkFailure.
  - Non-map error bodies are handled defensively.
- No token refresh and no retry.
- Global logout (`handle_unauthorized.dart`):
  - A re-entrancy flag protects the flow. It unsubscribes FCM topics, resets AppCubit, clears the technician timers, deletes the token from both stores, removes the cached user, and calls `context.go(login, extra: {'logout': true})`.
  - If the navigator context is null it retries on the next frame, up to 5 times.

### Local storage
- `SharedPreferencesManager`: a singleton with `init()` awaited in `main`. It has a dynamic `setValue` (String/int/bool/double/List<String>), an untyped `getValue`, `remove` and `clear`, and it silently no-ops if not initialized.
- `SecureStorageManager`: a singleton with `init()` that configures Android `encryptedSharedPreferences: true, resetOnError: true` and iOS `first_unlock`. Reads delete corrupted keys, writes retry after a delete, and there are clearAll fallbacks. This is a good wrapper.
- Keys live in `lib/core/utilities/constants/keys/shared_preferences_keys.dart` and are SCREAMING_CASE.
- The user password is stored in secure storage for the demo-account "register" flow.
- The splash screen wipes stale iOS keychain tokens after a reinstall (when `IS_FIRST_TIME` is unset but a token exists).

### Localization + RTL
- `easy_localization ^3.0.7`. Supported locales are `ar` and `en`; start and fallback are `ar`. Files are `assets/translations/{ar,en}.json` with nested keys (280 each, same key set). The `.tr()` extension is used in about 386 places.
- `MaterialApp.router` gets `key: ValueKey(locale)`, which forces a full rebuild on language change. A `Directionality` wrapper is driven by `languageCode == 'ar'`, which is redundant with the localization delegates.
- On language change, `SettingsCubit.changeLanguage` calls the backend, re-subscribes the FCM topics for the new language, and updates the `Accept-Language` header.
- `get_and_set_device_locale.dart` can set the app language from `Platform.localeName`. It is used once.
- Hardcoded strings: about 86 Arabic literal lines (managers home mock notifications/checklists, supervisor screens, priority enum), English dialog text in `NotificationService`, and a few `'Search...'` / `'Invalid date or format'`. Several keys used at root (`no_tasks`, `retry`, `take_a_photo`, `error_please_try_again`) do not appear as top-level JSON keys.
- RTL is mixed: 25 Directional usages vs 43 left/right (mostly `EdgeInsets.fromLTRB`). `AppBackButton` uses a fixed `Icons.arrow_forward_rounded`, which is designed for RTL and points the wrong way in LTR. `BlackYellowCard` uses `Positioned(right:/left:)`.

### Theming
- Light theme only (`lightTheme`, `useMaterial3: true`). `dark_theme.dart` is an empty file.
- `ColorScheme.fromSeed(primary)` with deprecated `background`/`onBackground`.
- Component themes: AppBar, BottomNavigationBar, legacy `ButtonThemeData`, `ElevatedButtonThemeData` (fixed size 343.w×52.h, asymmetric radius), `TextButtonThemeData`, `SnackBarThemeData`, `DialogThemeData`, `InputDecorationTheme` (filled, 8.r outline borders, error style), progress indicator.
- `AppColors`: primary/secondary/neutral/green/red scales (50–1000) plus task-status colors. There is also `newColor(int)`.
- `TextThemeLight` is a singleton holding a complete M3 `TextTheme` built from one base style (Alexandria, secondary600, height 1). Sizes are fixed px, not `.sp`.
- Theme objects are top-level `final`s that use `.w/.h/.r`. They are evaluated lazily after ScreenUtil init but frozen afterwards.
- Many widgets hardcode `Colors.*` (283 occurrences) and `Color(0x…)` (111).

### Responsive
- `flutter_screenutil ^5.9.3`, `ScreenUtilInit(designSize: Size(393, 852), minTextAdapt: true, splitScreenMode: true)`.
- `.w/.h/.r` are used heavily (276/464/140). `.sp` appears only 4 times; most font sizes are raw ints (126 `fontSize: N`).
- No breakpoints, no tablet layouts, no responsive helper class.

### Text scaling
- None. There is no `MediaQuery.textScaler` clamp in `MaterialApp.builder`, and fonts are not `.sp`, so system text scale applies unbounded.

### Env / flavors
- None. `ApiKeys` (`lib/core/utilities/constants/keys/api_keys.dart`) has `BASE_URL`/`BASE_IMAGE_URL` for live and testing, switched by commenting lines. Endpoints are constants or functions (`GET_CHECKLIST_DETAILS(int id)`).
- One Firebase project is wired via `firebase_options.dart`.
- Android signing reads `key.properties` correctly. If the file is missing, the `as String` casts crash the release config.

### Logging
- `talker_flutter` with a global `talker`, `TalkerDioLogger`, `TalkerRouteObserver`.
- Mixed with `print` (15: bloc observer, BaseCubit, geofence, request models) and `debugPrint` (60, emoji-prefixed). The FCM token is logged in several places. There is no Talker UI screen.

### Analytics / crash
- `firebase_crashlytics`: `FlutterError.onError = recordFlutterFatalError` plus `runZonedGuarded → recordError(fatal: true)`. No `PlatformDispatcher.onError`, no analytics package.

### Push notifications
- `NotificationService` (static, `lib/core/services/notification_service.dart`):
  - Init sequence: permission (Android 13 check stubbed to always true; iOS via FCM), then local notifications init, then two Android channels, then FCM listeners.
  - In the foreground it shows a local notification and suppresses the FCM presentation.
  - `onMessageOpenedApp`/`getInitialMessage` and local tap handling are TODOs, so there is no navigation.
- Bug: channels are created on a new `AndroidFlutterLocalNotificationsPlugin()` instance. `resolvePlatformSpecificImplementation` is referenced as an expression statement but never invoked.
- A background handler is registered in `main.dart`. Init is called from `MainApp.initState` post-frame with the context, for the permission dialog.
- `NotificationTopicHandler` / `NotificationTopics` build `{all|role}_topic_{ar|en}` topic names from the `UserRole` enum. Topics are subscribed on login/language change and all are unsubscribed on logout.

### IAP / payments
- None.

### Permissions
- `permission_handler ^12`, used inline. Notifications are handled in NotificationService. Camera/photos are gated on iOS only (Android relies on system pickers) with an "open settings" dialog. Location when-in-use then always is handled in `geofence_service.dart`. Microphone and storage are requested in the voice recorder.
- There is no central permission service.

### Deep links
- None: no app_links/uni_links, go_router paths are not deep-link-safe because of `extra` casts, and notification taps do not navigate.

### Other notable infra
- Geofencing: a native MethodChannel bridge (Kotlin `GeofenceHelper`/`GeofenceBroadcastReceiver`, Swift `GeofencingManager.swift`) plus `geolocator` current position and a Haversine check. It is used for attendance check-in/out (`features/bottom_nav/presentation/widgets/attendance_dialog.dart`).
- `DeletedAccountsService` stores the "deleted" emails of demo accounts in a Firestore collection, with a local-prefs fallback. This is a store-review workaround, not real deletion.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/services/api_service.dart | Dio wrapper | `ApiServiceBase` iface; `get/post/put/patch/delete(NetworkRequestParams)`, `updateHeaders({token, customHeaders})` | dio, talker_dio_logger, SharedPreferencesManager, UnauthorizedInterceptor | generic (minus prefs token read) |
| lib/core/services/unauthorized_interceptor.dart | 401 → global logout | `UnauthorizedInterceptor.onError` | ApiKeys, handle_unauthorized | generic pattern |
| lib/core/services/logging_interceptors.dart | debugPrint request/response logger (chunked) | `LoggingInterceptor` | dio | generic (unused) |
| lib/core/services/di_container.dart | get_it setup + global talker | `sl`, `talker`, `diContainerSetup()` | everything | app-specific |
| lib/core/services/shared_preferences_manager.dart | prefs singleton | `init, setValue, getValue, remove, clear` | shared_preferences | generic |
| lib/core/services/secure_storage_manager.dart | secure storage singleton w/ recovery | `init, read, write, delete, clearAll, containsKey, readAll` | flutter_secure_storage | generic |
| lib/core/services/notification_service.dart | FCM + local notifications | `init(ctx), showLocalNotification, showGeofenceNotification, cancelNotification, cancelAllNotifications, subscribeToTopic, unsubscribeFromTopic` | firebase_messaging, flutter_local_notifications, permission_handler | mostly generic (has bugs) |
| lib/core/services/notification_topic_handler.dart | role/lang topic naming + bulk (un)subscribe | `NotificationTopics.all/roleTopic`, `NotificationTopicHandler.handleNotificationsSubscriptions/unsubscribeAll` | UserRole, NotificationService | app-specific pattern |
| lib/core/services/image_picker_service.dart | pick + permission + compression + lost data | `pickImage(context, source)`, `retrieveLostData()`, `getImageSizeKB`, `getFormattedImageSize` | image_picker, flutter_image_compress, path_provider, permission_handler, easy_localization | generic |
| lib/core/services/pending_capture_service.dart | process-death photo recovery marker | `markPending, pendingTaskId, clearPending, saveRecovered, takeRecoveredFor, clearRecovered` | SharedPreferencesManager | generic (rename taskId→ownerId) |
| lib/core/services/toast_manager.dart | overlay toast + `context.showToast` | `ToastManager.showToast`, `BuildContext.showToast` | AnimatedCustomToast | generic |
| lib/core/services/show_loading_dialog.dart | blocking loader | `showLoadingDialog(context, message, barrierDismissible)` | material | generic |
| lib/core/services/app_validator.dart | form validators | `isNotEmpty, isValidEmail, isValidPhone, isValidSaudiPhone, isValidPassword, confirmPassword, isNumeric, isNumericInRange, isNotEmptyImage, ibanValidator, customValidator` | easy_localization | generic |
| lib/core/services/bloc_observer.dart | log bloc lifecycle | `AppBlocObserver` | flutter_bloc | generic (uses print) |
| lib/core/services/debounce.dart | debouncer | `Debounce(ms).run/cancel` | dart:async | generic |
| lib/core/services/get_and_set_device_locale.dart | set app locale from device | `setAppLanguageToDeviceLanguage(ctx)`, `getDeviceLocale()` | easy_localization, dart:io | generic |
| lib/core/services/language_flags_service.dart | locale → flag emoji | `LanguageService.getFlagEmoji(locale)` | – | generic |
| lib/core/services/get_percentage.dart | safe percent | `getPercentage(completed, total)` | – | generic |
| lib/core/services/phone_handeler_service.dart | leading-zero phone | `ensureStartsWithZero` | – | generic (trivial) |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | request + error mapping | `handleRequest<T>(path, method, parser, data, queryParameters)` | ApiService via sl, Failure, talker | generic |
| lib/core/base_architecture/data/repository/base_repo.dart | Failure → Either | `handleNetworkCall<T>(call)` | dartz | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart | cubit request helper | `handleRequest<T>(loadingState, call, onSuccess, onError, showLoading)` | flutter_bloc, dartz | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart | single-state cubit helper | `handleRequest<T>(call, onNotDefaultSuccess, onNotDefaultFailure, onNotDefaultLoading)` | flutter_bloc, dartz | generic |
| lib/core/base_architecture/data/models/base_response_model/base_success_response.dart | `{status,message,data}` envelope | `fromJson(json, fromJsonT)`, `toJson` | – | generic |
| lib/core/base_architecture/data/models/base_request_model/network_request_model.dart | request params DTO | `NetworkRequestParams` | dio | generic |
| lib/core/utilities/failures/failure.dart | Failure hierarchy | 10 subclasses + `displayMessage` | easy_localization | generic |
| lib/core/utilities/failures/error_details_model.dart | field error | `ErrorDetail.fromJson(field, list)` | – | generic |
| lib/core/utilities/helpers/handle_unauthorized.dart | logout flow | `triggerUnauthorizedLogout()`, `handleUnauthorizedFailure(ctx)` | AppCubit, router, storage, topics, technician cubit | app-specific (pattern generic) |
| lib/core/utilities/helpers/role_navigation.dart | role → landing route + nav | `routeForRole`, `applyRoleNavigation` | AppCubit, BottomNavCubit | app-specific |
| lib/core/utilities/formatters/date_formatter.dart | date formatting | `formatDateString, formatDate, isMorning, isToday` | intl | generic |
| lib/core/utilities/constants/icons.dart | svg paths + `AppIcons.svg()` (asset or network) | `svg(assetName, w, h, color)` | flutter_svg, ApiKeys | generic pattern |
| lib/core/utilities/constants/images.dart / temp_images.dart | asset paths + `image()` helper | – | – | generic pattern |
| lib/core/extensions/context_extensions.dart | `context.theme/textTheme/colorScheme/isAr` | – | – | generic |
| lib/core/extensions/list_extensions.dart | `isNullOrEmpty()` on `List?` | – | – | generic |
| lib/core/enums/app_roles_enum.dart | backend role enum | `value, code, tryFromString, fromString` | – | app-specific (good pattern) |
| lib/core/enums/fetch_data_status_enum.dart, http_method_enum.dart, toast_state_enum.dart | infra enums | – | – | generic |
| lib/geofence_service.dart | native geofence + distance | `GeofencingService.instance.initialize/addGeofence/removeGeofence/getCurrentLocation/isInsideGeofence/checkGeofenceStatusOnStart`, `ensureLocationPermission`, `registerGeofencingService` | MethodChannel, geolocator, permission_handler | semi-generic (needs native side) |
| lib/features/maintenance_technician_feature/.../task_timer_service.dart | persisted per-id start time | `startTask, clearTask, clearAllTasks, getStartTime, isTaskRunning, elapsedDuration` | SharedPreferences | generic |
| lib/features/settings/settings/data/repositories/delete_account_service.dart | Firestore "deleted emails" list | `addDeletedEmail, emailExists` | cloud_firestore | app-specific hack |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/buttons/app_default_button.dart | Primary button, loading → circular spinner, optional svg icon, double-tap lock (ineffective for async) | onTap, text, textStyle, child, height, width, radius, margin, padding, isLoading, backgroundColor, textColor, enabled, svgIconPath, svgIconColor, borderColor, blockMultipleClicks | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart | `AppIconButton` (square icon btn on AppDefaultButton), `AppBackButton` | child, onTap, height, width, radius, backgroundColor / onTap | y / partly |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart | Titled TextFormField, unfocus on tap outside | title, controller, hintText, onTap, onChanged, enabled, readOnly, obscureText, keyboardType, validator, inputFormatters, prefixIcon, suffixIcon, titleStyle, textStyle, hintTextStyle, maxLength, maxLines, prefix/suffixIconConstraints, focusNode, textAlign, onSaved, onFieldSubmitted, onEditingComplete | y |
| lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart | Password + eye toggle | controller, isConfirmPassword, confirmPasswordValidator (unused), title, hintText, isLogin, onChanged | y (buggy) |
| lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart | Email field with icon + validator | controller, title, hintText, readOnly (unused), onChanged | y |
| lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart | Read-only field → bottom-sheet string picker | title, hintText, controller, items, validator, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart | Generic `<T>` popup-menu dropdown w/ search | controller, options, displayText, title, onOptionSelected, hintText, showSearch, isLoading | y |
| lib/core/utilities/widgets/default_screen.dart | Base scaffold w/ custom header (title + back button), body padding, FAB | body, appbar, pageTitle, pageTitleWidget, hasAppBar, hasBackButton, hasBottomBorder, hasBottomMargin, onBackPressed, floatingActionButton(+Location), topMargin, appBarPadding, bodyPadding, backgroundColor | y |
| lib/core/utilities/widgets/base_fetching_widget.dart | `GenericFetchWidget<B,S,T>` status switch; `BaseLoadingWidget`; `BaseErrorWidget` (retry) | successBuilder, loadingWidget, failureWidget, onRetry / message, onRetry | y |
| lib/core/utilities/widgets/base_list_view_widget.dart | Separated list with empty-state | items, itemBuilder, emptyWidget | y |
| lib/core/utilities/widgets/toasts/animated_custom_toast.dart | Slide/fade overlay toast (success/failure/warning) | message, state, duration, location | y |
| lib/core/utilities/widgets/toasts/custom_toast.dart | Static toast | message, state, duration | y (redundant) |
| lib/core/services/show_loading_dialog.dart | Loading dialog function | context, message, barrierDismissible | y |
| lib/core/utilities/widgets/image_picker_bottom_sheet.dart | Camera/gallery chooser sheet → ImagePickerService | context, onFilePicked | y |
| lib/core/utilities/widgets/container_with_shadow.dart | Tappable rounded shadow card | child, width, height, image, backgroundColor, border, margin, padding, radius, onTap, boxShadow, shadowBlurRadius | y |
| lib/core/utilities/widgets/app_divider.dart | Divider wrapper | height, thickness, color, indent, endIndent, widthFactor | y |
| lib/core/utilities/widgets/app_tab_switcher.dart | Pill-shaped TabBar | tabController, selectedIndex, tabs, onTabChanged, margin | y |
| lib/core/utilities/widgets/custom_chip.dart | Title/description chip | title, description, bgColor, borderColor, radius, titleColor, titleFontSize, descColor, descFontSize, padding, crossAxisAlignment, spacing | y |
| lib/core/utilities/widgets/selection_chip_widget.dart | Selectable chip | isSelected, title, onTap | y |
| lib/core/utilities/widgets/custom_radio_group_widget.dart | `CustomRadioGroup<T>` + animated `CustomSizeRadio<T>` | options, selectedValue, onChanged, prefixText, label / value, groupValue, onChanged, size, activeColor, inactiveColor, animationDuration | y |
| lib/core/utilities/widgets/expandable_container.dart | Animated expand card | title, image, collapsedContent, collapsedHeight, expandedHeight, description, expandedContent, onToggle | partly |
| lib/core/utilities/widgets/linear_progress_indicator.dart | Percent bar | percent, minHeight | y |
| lib/core/utilities/widgets/voice_recorder_player_widget.dart | Voice record (1 min max) + playback local/remote | onFileSaved, voicePath | y (needs cleanup) |
| lib/core/utilities/widgets/black_yellow_card.dart | Branded dark header card | child, borderRadius, circleShapeBottomPosition, padding | n |
| lib/features/shared/widgets/image_Widget.dart | `ImageViewerWidget`: asset/file/network by path prefix, placeholder on error | image, imageWidth, imageHeight, radius, color, margin, stackedWidget, onTap, fit, border | y |
| lib/features/shared/screens/image_viewer.dart | Full-screen image | imagePath | y |
| lib/features/splash/presentation/screens/splash_screen.dart → `AnimatedImageViewer` | Animated logo | image, imageHeight, imageWidth, radius | y |
| lib/features/bottom_nav/presentation/widgets/navigation_widget.dart | Nav item (svg + label, theme colors) | navItem, isSelected, onTapItem | y |
| lib/features/settings/settings/presentation/widgets/settings_item_widget.dart | Settings row with icon bubble + trailing widget | navigationItemModel, widget | y |
| lib/features/settings/settings/presentation/widgets/logout_section.dart | Logout row with AuthCubit listener | – | n |
| lib/features/*/presentation/widgets/* (maintenance_card, task_card, checklist_card, notifications_card, performance_card, priority_selection_widget, ...) | Domain cards | various | n |

## 6. Packages (`pubspec.yaml`)

- **State:** flutter_bloc ^9.1.1, equatable ^2.0.7, hydrated_bloc ^10.1.1 (unused)
- **DI:** get_it ^8.0.3
- **Routing:** go_router ^16.2.1
- **Network:** dio ^5.7.0, dartz ^0.10.1, talker_dio_logger ^5.0.0
- **Storage:** shared_preferences ^2.3.3, flutter_secure_storage ^9.2.4, path_provider ^2.1.5, path ^1.9.1
- **L10n:** easy_localization ^3.0.7, intl ^0.20.2, flutter_localizations (sdk)
- **UI:** flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, skeletonizer ^2.1.0+1 (3 uses), flutter_native_splash ^2.4.3, dotted_border ^3.1.0, percent_indicator ^4.2.5, fl_chart ^0.68.0, cupertino_icons. Unused: flutter_html ^3.0.0, flutter_animate ^4.5.2, animate_do ^4.2.0, country_picker ^2.0.2, cached_network_image ^3.4.1
- **Firebase:** firebase_core ^4.1.0, firebase_messaging ^16.0.1, firebase_crashlytics ^5.0.5, cloud_firestore ^6.1.3
- **Notifications:** flutter_local_notifications ^19.4.1
- **Media:** image_picker ^1.2.2, flutter_image_compress ^2.4.0, flutter_sound ^9.2.13, just_audio ^0.10.0
- **Location:** geolocator ^14.0.2, google_maps_flutter ^2.3.2 (unused in Dart)
- **Utils:** permission_handler ^12.0.1, url_launcher ^6.3.1, package_info_plus ^8.3.0, device_info_plus ^12.3.0, talker_flutter ^5.0.0
- **Dev:** flutter_test, flutter_lints ^6.0.0. flutter_launcher_icons ^0.14.4 is wrongly listed under dependencies.

## 7. Quality notes

- **Null safety:** yes (Dart 3.7). There are many `!` force-unwraps (`response.user!`, `response.token!`, `appCubit.state.user!.employeeCode`) and unchecked `state.extra as X` casts.
- **Lints:** `analysis_options.yaml` only includes `package:flutter_lints/flutter.yaml` with no extra rules. `avoid_print` would fire (15 prints).
- **Tests:** 1 file, the default counter test, which would fail because it pumps `MainApp` without its dependencies and expects counter text. Effectively zero tests.
- **Duplication:**
  - Two cubit base classes, two toast widgets, two logging interceptors.
  - `managers_feature/managers_checklists/data/models/**` (task_clones_models ×6, stuff_model, category_items, main_task_model, tasks_model, task_clone_images_comments, main_data_item_models) is a near-verbatim copy of `supervisor_branch_manager_feature/tasks/data/models/**`.
  - Two `MaintenanceTaskCard`/`priority_selection_widget` variants across the supervisor and technician features.
  - Two `home_local_data_source` / `home_checklists_view`.
- **God files:** `attendance_dialog.dart` (790 lines, geofence + check-in UI + logic), `complete_data_on_item_screen.dart` (792), `complete_data_task_screen.dart` (691), `maintenance_details_screen.dart` (689), `voice_recorder_player_widget.dart` (1142, about 63% commented out).
- **Layering violations:** `core` imports `features`. This happens in `di_container.dart`, `handle_unauthorized.dart` (technician cubit), `app_cubit.dart` (UserModel, UserAttendanceModel), `constant_lists.dart` (settings LanguageModel) and `expandable_container.dart` (shared ImageViewerWidget). `lib/geofence_service.dart` sits at the lib root.
- **Deprecated APIs:**
  - `ColorScheme.background/onBackground` in `light_color_scheme.dart`
  - `withOpacity` ×8
  - `WillPopScope` ×1 (`attendance_dialog.dart`)
  - legacy `ButtonThemeData`
  - `MediaQuery.of(context).size` ×7 (prefer `sizeOf`)
  - No `textScaleFactor`/`MaterialStateProperty` usages.
- **Hardcoded values:**
  - About 86 Arabic literal lines and English dialog strings.
  - `Colors.*` ×283, `Color(0x…)` ×111.
  - Role strings compared as raw `"supervisor"`/`"branchManager"` in `bottom_nav_screen.dart` despite the `UserRole` enum.
  - 5-minute Dio timeouts.
  - Base URLs switched by comments.
- **Security:**
  - Hardcoded demo-account credentials and role-override logic in `lib/features/auth/data/repositories/auth_repo.dart`, plus a related magic employee code check in `settings_screen.dart`.
  - The user password is persisted (secure storage).
  - `TalkerDioLogger(printRequestHeaders: true)` logs bearer tokens, and the FCM token is printed.
  - A Google Maps API key is committed in `android/app/src/main/AndroidManifest.xml`, `ios/Runner/AppDelegate.swift` and `ios/Runner/Info.plist`.
  - Secret files that exist on disk: `lib/firebase_options.dart` and `android/app/google-services.json` (both tracked in git), and `android/app/upload-keystore.jks` (not tracked).
- **Bugs spotted:**
  - `diContainerSetup()` is not awaited.
  - `sl<TechnicianMaintenancesCubit>()` in the logout flow creates a fresh factory instance, so the live cubit's ticker keeps running.
  - The `AppDefaultButton` tap lock releases synchronously.
  - `PasswordTextFormField` ignores its confirm validator and always validates with login rules.
  - Android notification channels are never created on the real plugin instance.
  - `ToastManager`'s delayed removal can dismiss a newer toast.
  - `showImagePickerSheet` uses the popped sheet's context.
  - `AppBackButton` has no default pop and a fixed forward arrow.
  - `_handleDioError` treats receive/send timeouts as `NetworkFailure`.
  - The `BaseSingleClassStateCubit` default-success path is commented out.
- **Good parts worth keeping:**
  - the global 401 design
  - the `Failure` + `displayMessage` split
  - `SecureStorageManager`
  - `ImagePickerService` (permission UX, compression, lost data)
  - `PendingCaptureService`
  - `UserRole` enhanced enum
  - `role_navigation.dart` as the single source of truth
  - `AppValidator` (IBAN mod-97)
  - `TaskTimerService` (persisted wall-clock timers)
  - `AppTextFormField`'s `onTapOutside` unfocus
  - the iOS reinstall keychain wipe in splash
