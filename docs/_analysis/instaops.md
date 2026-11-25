# instaops — analysis report

## Summary for comparison

```
PROJECT: instaops | path: Datum/InstaOps | stack: Flutter, Dart SDK ^3.7.2 (flutter_bloc 9, go_router 16.3, dio 5) | last commit: no git, mtime 2026-10-20 | source files: 279 (.dart in lib, ~29.6k lines, incl. generated firebase_options.dart)
ARCH: clean-arch-lite feature-first — features/<f>/data/{data_sources,models,repositories} + presentation/{managers|cubit,screens,widgets}; no domain layer/use cases; shared bases in core/base_architecture
STATE: bloc/cubit — BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart, 11 cubits, one class per state) + BaseSingleClassStateCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart, 8 cubits, single state + FetchDataStatusEnum); provider ChangeNotifier only for AppThemeNotifier; hydrated_bloc declared, unused
DI: get_it (manual, global `sl`; lazySingleton data sources/repos, factory cubits; async setup NOT awaited) — lib/core/services/di_container.dart
ROUTING: go_router 16.3 — lib/core/app_router/app_router.dart (+app_routes_names.dart, root_navigator_key.dart) — guards? no (no redirect; splash decides by token+role via lib/core/utilities/helpers/role_navigation.dart) — deep links? no; ShellRoute + BottomNavScreen, args via state.extra casts, TalkerRouteObserver
NETWORK: dio — interceptors: UnauthorizedInterceptor (global 401 -> logout, excluded auth paths), TalkerDioLogger (LoggingInterceptor registered in DI but never attached) | token refresh: n | retry: n | error mapping: BaseRemoteDataSource maps status 400(field errors)/401/403/404/500/other + connectionTimeout/no-response -> Failure subclasses; FailureDisplay.displayMessage hides UnknownFailure text | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/services/unauthorized_interceptor.dart, lib/core/utilities/helpers/handle_unauthorized.dart
RESULT_TYPE: Either (dartz) via BaseRepository.handleNetworkCall; data sources throw Failure (implements Exception) — lib/core/utilities/failures/failure.dart (+ error_details_model.dart)
STORAGE: shared_preferences + flutter_secure_storage (token, saved password) + cloud_firestore (deleted-accounts list) — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart; hydrated_bloc unused
L10N: easy_localization 3.0.7 — ar, en; start+fallback ar; assets/translations/{ar,en}.json (nested, 25 groups / 280 keys each; 11 keys used in code are missing) — hardcoded UI strings: some
RTL: Directional=25 vs LeftRight=39 (11 only(left/right)/Positioned left:/right: + 28 EdgeInsets.fromLTRB); plus forced Directionality wrapper in MaterialApp.builder
THEME: lib/core/theme/light_theme/light_theme.dart (lightTheme(context)) — dark mode n (dark_theme.dart is empty) | component themes in ThemeData y (appBar, bottomNav, text/elevated/button, input, snackBar, dialog, progress) | colors class: AppColors (lib/core/utilities/constants/colors.dart) — runtime white-label palette from backend hex (ColorShadeGenerator + AppThemeNotifier + context.watchColors) + static neutrals | text styles class: TextThemeLight singleton (light_widget_themes/text_theme.dart, M3 scale, no .sp) | fonts: Alexandria (used), Cairo (declared only)
RESPONSIVE: flutter_screenutil (design 393x852, minTextAdapt, splitScreenMode) — breakpoints: none
TEXT_SCALING: none (no textScaler clamp anywhere; theme font sizes are raw, not .sp)
ENV/FLAVORS: hardcoded constants (Testing/Live BASE_URL swapped by commenting) — lib/core/utilities/constants/keys/api_keys.dart; no flavors, no --dart-define, no dotenv
LOGGING: talker (global `talker` in di_container.dart) + talker_dio_logger + TalkerRouteObserver; also print x15 (AppBlocObserver, geofence_service, base_cubit) and debugPrint x59
ANALYTICS/CRASH: firebase_crashlytics only in runZonedGuarded handler (FlutterError.onError hook commented out); no analytics; NOTE Firebase.initializeApp is commented out in main.dart
PUSH: fcm + flutter_local_notifications — lib/core/services/notification_service.dart (static) + lib/core/services/notification_topic_handler.dart (role x language topics); tap navigation is TODO
PAYMENTS/IAP: none
PERMISSIONS: permission_handler (notification, camera/photos iOS-only gate with open-settings dialog, microphone/storage, location whenInUse/always) + geolocator permission APIs
DEEP_LINKS: none
MEDIA/FILES: image_picker + flutter_image_compress (size-tiered) + Android retrieveLostData recovery, flutter_svg, flutter_sound + just_audio (voice notes), path_provider, url_launcher (open maps), geolocator + native geofencing MethodChannel (Kotlin/Swift); cached_network_image & google_maps_flutter declared but unused (Image.network used)
TESTS: 1 — default counter smoke test (stale; would fail against MainApp)
LINTS: analysis_options: flutter_lints ^6.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — generic handleRequest<T>(path, method, parser, data, query) + status->Failure mapping, tolerant of non-Map error bodies — quality 4 — coupling: low (sl<ApiService>, global talker)
- lib/core/utilities/failures/failure.dart — Failure hierarchy (BadRequest w/ field errors, Unauthorized, Forbidden, NotFound, Server, Network, Timeout, Cache, Validation, Unknown) + displayMessage extension — quality 4 — coupling: low (one easy_localization key)
- lib/core/services/unauthorized_interceptor.dart — global 401 interceptor with excluded paths, passes error downstream — quality 4 — coupling: low (ApiKeys paths)
- lib/core/services/secure_storage_manager.dart — FlutterSecureStorage wrapper with corruption self-heal (resetOnError, delete+retry, readAll fallback) — quality 4 — coupling: none
- lib/core/services/image_picker_service.dart — pick + iOS permission gate/open-settings dialog + size-tiered JPEG compression + retrieveLostData — quality 4 — coupling: low (tr keys, SnackBar)
- lib/core/theme/color_shade_generator.dart (+ app_theme_notifier.dart, app_colors_extension.dart, utilities/constants/colors.dart) — runtime brand palette 50..1000 from one hex via HSL — quality 4 idea / 3 impl — coupling: low (provider)
- lib/core/utilities/helpers/handle_unauthorized.dart (+ app_router/root_navigator_key.dart) — context-free logout with re-entrancy guard and bounded post-frame retry — quality 3 — coupling: high (imports AppCubit, TechnicianMaintenancesCubit, topic handler)
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart (+ base_single_class_state.dart) — single-state cubit with status/failure/success + handleRequest hooks — quality 3 — coupling: none (casts `as State`; copyWith cannot clear failure)
- lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart — handleRequest(loadingState, call, onSuccess, onError) with catch-all -> UnknownFailure — quality 3 — coupling: low (talker, print)
- lib/core/base_architecture/data/repository/base_repo.dart — Future<Either<Failure,T>> handleNetworkCall — quality 3 — coupling: none (catches only Failure)
- lib/core/services/api_service.dart — Dio wrapper (ApiServiceBase interface, get/post/put/patch/delete with NetworkRequestParams, mutable headers/token) — quality 3 — coupling: low (prefs)
- lib/core/services/app_validator.dart — localized validators (email, phone, Saudi phone, password, confirm, numeric range w/ namedArgs, IBAN mod-97, combinator) — quality 3 — coupling: low (tr keys)
- lib/core/services/pending_capture_service.dart — persist "camera open for entity X" to recover photo after Android process death — quality 4 — coupling: low
- lib/features/maintenance_technician_feature/technician_maintenance/presentation/managers/task_timer_service.dart — persisted per-entity wall-clock timer (idempotent start, clearAll on logout) — quality 4 — coupling: none
- lib/core/services/toast_manager.dart (+ utilities/widgets/toasts/animated_custom_toast.dart) — overlay toast + context.showToast extension — quality 3 — coupling: low
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/buttons/app_default_button.dart — primary button (AppDefaultButton) — text, onTap, isLoading, enabled, svgIconPath, backgroundColor, textColor, borderColor, textStyle, child, height/width/radius, margin/padding, blockMultipleClicks — quality 3 (tap lock ineffective: sync VoidCallback) — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart — AppIconButton (child, onTap, height, width, radius, backgroundColor) + AppBackButton (onTap; hardcoded arrow_forward + grey) — quality 3/2 — generic? y
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — base text field with title label — title, controller, hintText, validator, prefix/suffixIcon, obscureText, keyboardType, inputFormatters, maxLines/maxLength, focusNode, readOnly, onTap/onChanged/onSaved/onFieldSubmitted, unfocus on tap outside — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password field with visibility toggle — controller, isConfirmPassword, title, hintText, isLogin, onChanged (confirmPasswordValidator ignored; validator logic inverted) — quality 2 — generic? y
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart — email field — controller, title, hintText, readOnly, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart — read-only field opening bottom-sheet list — title, hintText, controller, items(List<String>), validator, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — DynamicDropdownFormField<T> via showMenu — controller, options, displayText, onOptionSelected, title, hintText, showSearch, isLoading (search not reactive; hardcoded strings; withOpacity) — quality 2 — generic? y
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart — animated overlay toast — message, state(ToastState), duration, location — quality 3 — generic? y
- lib/core/utilities/widgets/toasts/custom_toast.dart — static toast — message, state, duration (unused) — quality 2 — generic? y
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget<B,S,T> (successBuilder, loadingWidget, failureWidget, onRetry; unused) + BaseLoadingWidget + BaseErrorWidget(message, onRetry) — quality 3 — generic? y
- lib/core/utilities/widgets/base_list_view_widget.dart — BaseListView<T> (items, itemBuilder, emptyWidget; unused; empty key missing) — quality 2 — generic? y
- lib/core/utilities/widgets/default_screen.dart — base scaffold — body, pageTitle/pageTitleWidget, appbar override, hasAppBar, hasBackButton, onBackPressed, hasBottomBorder, topMargin, appBarPadding, bodyPadding, backgroundColor, FAB — quality 3 — generic? y
- lib/core/utilities/widgets/container_with_shadow.dart — card container — child, onTap, padding, margin, radius, width, height, backgroundColor, border, image, boxShadow, shadowBlurRadius — quality 4 — generic? y
- lib/core/utilities/widgets/custom_chip.dart — chip with title/description — title, description, bgColor, borderColor, radius, title/desc color+size, padding, spacing — quality 3 — generic? y
- lib/core/utilities/widgets/selection_chip_widget.dart — selectable chip — isSelected, title, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/custom_radio_group_widget.dart — CustomRadioGroup<T> + animated CustomSizeRadio<T> — options, selectedValue, onChanged, prefixText, label / value, groupValue, size, colors (controller created in didChangeDependencies) — quality 2 — generic? y
- lib/core/utilities/widgets/expandable_container.dart — expandable card — title, image, collapsedContent, expandedContent, description, collapsed/expandedHeight, onToggle (fixed heights; imports features/shared) — quality 2 — generic? partly
- lib/core/utilities/widgets/linear_progress_indicator.dart — LinearPercentIndicator(percent 0-100, minHeight) — quality 3 — generic? y (name clashes with percent_indicator pkg)
- lib/core/utilities/widgets/app_divider.dart — themed divider — height, thickness, color, indent, endIndent, widthFactor — quality 3 — generic? y
- lib/core/utilities/widgets/image_picker_bottom_sheet.dart — showImagePickerSheet(context, onFilePicked) camera/gallery — quality 3 — generic? y
- lib/core/services/show_loading_dialog.dart — showLoadingDialog(context, message, barrierDismissible) — quality 3 — generic? y
- lib/features/shared/widgets/image_Widget.dart — ImageViewerWidget: auto asset/local/network by string prefix, radius, placeholder on error, stackedWidget badge — image, imageWidth/Height, radius, color, margin, onTap, fit, border — quality 3 — generic? y (uncached Image.network, BASE_IMAGE_URL prefix)
- lib/features/shared/screens/image_viewer.dart — full-screen image viewer (no zoom) — imagePath — quality 2 — generic? y
- lib/core/utilities/widgets/voice_recorder_player_widget.dart — VoiceRecorderPlayer record/play (local or remote URL, 1-min cap) — onFileSaved, voicePath — quality 2 — generic? partly
- lib/features/bottom_nav/presentation/widgets/navigation_widget.dart (+ models/navigation_item_model.dart) — custom bottom-nav item — navItem(assetName,label,routeName), isSelected, onTapItem — quality 3 — generic? y
- lib/features/splash/presentation/screens/splash_screen.dart (AnimatedImageViewer) — animated logo (fade/scale/shake) — image, imageHeight/Width, radius — quality 3 — generic? y
- lib/core/utilities/constants/icons.dart (AppIcons.svg) — SVG helper asset vs network with tint — assetName, width, height, color — quality 3 — generic? y
- lib/core/utilities/widgets/black_yellow_card.dart — branded header card with decorative shapes — child, borderRadius, circleShapeBottomPosition, padding — quality 2 — generic? n
NOTABLE_IDEAS: (1) runtime white-label theming: login response carries company primary/secondary hex -> AppThemeNotifier.applyBackendTheme -> ColorShadeGenerator builds 50..1000 HSL shades -> context.watchColors; ThemeData built from context (lib/core/theme/*, lib/core/utilities/constants/colors.dart, lib/features/auth/presentation/screens/login_screen.dart). (2) global 401 handling: Dio interceptor -> context-free logout through rootNavigatorKey with re-entrancy guard and bounded post-frame retries (unauthorized_interceptor.dart, handle_unauthorized.dart, root_navigator_key.dart). (3) iOS reinstall detection on splash: IS_FIRST_TIME pref missing but Keychain token present -> wipe secure storage (lib/features/splash/presentation/screens/splash_screen.dart). (4) secure storage self-heal (secure_storage_manager.dart). (5) size-tiered image compression + Android lost-photo recovery keyed by entity id (image_picker_service.dart, pending_capture_service.dart, main.dart _recoverLostImage). (6) enhanced role enum with backend value+code and tryFromString; single role->landing route + bottom-nav items mapping (app_roles_enum.dart, role_navigation.dart, bottom_nav_cubit.dart). (7) FCM topics per role x language, re-subscribed on language change (notification_topic_handler.dart, settings_cubit.dart). (8) persisted anti-reset task timer (task_timer_service.dart). (9) native geofencing via MethodChannel + haversine fallback (lib/geofence_service.dart, android/app/src/main/kotlin/<pkg>/Geofence*.kt, ios/Runner/GeofencingManager.swift). (10) defensive error-body parsing and "never show raw error" rule (base_remote_data_source.dart, failure.dart).
SMELLS: Firebase.initializeApp commented out in main.dart while FCM, Crashlytics (zone handler) and Firestore (DeletedAccountsService field init) are used; diContainerSetup() async and not awaited (inner _init* not awaited, TaskTimerService registered after an await -> race); route path clash managersHome == home == '/home' (brgr had '/managers_home') so ManagersHomeScreen route is shadowed; core imports feature code (di_container, app_cubit, handle_unauthorized, role_navigation, constant_lists, expandable_container); handle_unauthorized calls sl<TechnicianMaintenancesCubit>() which is a factory (new instance); backend brand colors not persisted (cold start reverts to defaults) and not reset on 401 logout; text_theme.dart discards its copyWith (no default text color), no .sp; ColorScheme.fromSeed with deprecated background/onBackground; withOpacity x7; WillPopScope x1 (attendance_dialog.dart); PasswordTextFormField validator inverted; CustomSizeRadio builds AnimationController in didChangeDependencies; NotificationService creates channels on a fresh AndroidFlutterLocalNotificationsPlugin() (resolvePlatformSpecificImplementation tear-off no-op), _isAndroid13OrHigher always true, hardcoded English dialog, FCM/device token logged; ToastManager delayed removal can remove a newer toast; only connectionTimeout mapped to TimeoutFailure, 5-minute timeouts; home_repo/managers_home_repo bypass BaseRepository and put raw '$e' in UnknownFailure; massive copy-paste between managers_feature and supervisor_branch_manager_feature (32 duplicate file names, identical task_clones_models) and two maintenance features; god files 600-800 lines (attendance_dialog.dart 790, complete_data_on_item_screen.dart 792); hardcoded fallback login credentials in auth_repo.dart (register flow logs into a shared account) and user password stored on device; unused deps (hydrated_bloc, cached_network_image, google_maps_flutter, flutter_animate, animate_do, country_picker, flutter_html) and unused helpers (GenericFetchWidget, BaseListView, Debounce, CustomRadioGroup, setAppLanguageToDeviceLanguage, LoggingInterceptor); empty files (dark_theme.dart, price_converter.dart); 11 missing translation keys; hardcoded Arabic mock data in managers_home widgets; print x15; very deep relative imports ('../../../../../../../../core/...'); README still titled after brgr; stale widget_test.dart
```

---

## 0. Relationship with `Datum/brgr`

InstaOps is a **rebrand/fork of `Datum/brgr`** (README still titled "brgr", pubspec comment `##brgr-staging`,
geofencing MethodChannel name still uses the brgr prefix). It is the **newer** copy (lib mtime 2026-10-20 vs
brgr 2026-06-28).

Comparison of `lib/` (276 common paths; InstaOps has 279 files, brgr 277):

| Measure | Files |
|---|---|
| Byte-identical | 68 |
| Identical after normalizing `package:brgr/` vs `package:instaops/` | 96 |
| Identical ignoring also whitespace / CRLF / trailing commas (i.e. same code) | **203** (66 in `core/`, 137 in `features/`) |
| Real code differences | 73 (25 in `core/`, 48 in `features/`) |
| Only in InstaOps | `core/theme/app_colors_extension.dart`, `core/theme/app_theme_notifier.dart`, `core/theme/color_shade_generator.dart` |
| Only in brgr | `core/utilities/widgets/app_tab_switcher.dart` |

Almost all real differences are one change: InstaOps turned the static `AppColors.primary/secondaryNNN`
constants into **instance colors resolved at runtime** (`context.watchColors.primary`) so that the brand palette
can come from the backend (multi-tenant "Restaurants SaaS"). Other notable diffs: `app_routes_names.dart`
(`managersHome` changed from `/managers_home` to `/home`, which introduces a path clash) and `api_keys.dart`
(base URL and key order).

**Core files shared with brgr (same code; compare once, not twice):**
`app_cubit/*`, `app_router/app_router.dart`, `app_router/root_navigator_key.dart`, all of
`base_architecture/**`, all `enums/*`, `extensions/*`, `models/selection_model.dart`, **every file in
`core/services/`** (api_service, app_validator, bloc_observer, debounce, di_container, get_and_set_device_locale,
get_percentage, image_picker_service, language_flags_service, logging_interceptors, notification_service,
notification_topic_handler, pending_capture_service, phone_handeler_service, secure_storage_manager,
shared_preferences_manager, show_loading_dialog, toast_manager, unauthorized_interceptor),
`theme/dark_theme/dark_theme.dart`, `theme/light_theme/light_widget_themes/{app_bar_theme,dialog_theme}.dart`,
`theme/light_theme/my_light_themes_export.dart`, `utilities/constants/{constant_lists,icons,images,temp_images}.dart`,
`utilities/constants/keys/shared_preferences_keys.dart`, `utilities/converters/price_converter.dart`,
`utilities/failures/*`, `utilities/formatters/date_formatter.dart`, `utilities/helpers/*`,
`utilities/widgets/{base_list_view_widget,container_with_shadow,default_screen,expandable_container,image_picker_bottom_sheet}.dart`,
`utilities/widgets/text_form_fields/{dropdown,email,password}_text_form_field.dart`, `utilities/widgets/toasts/custom_toast.dart`.

**Core files that differ (InstaOps version = theme-aware):** `theme/light_theme/light_theme.dart` and the
light_widget_themes `bottom_nav_theme`, `btn_txt_theme`, `elevated_btn_theme`, `input_decoration_theme`,
`light_color_scheme`, `snack_bar_theme`, `text_theme`; `utilities/constants/colors.dart`; widgets `app_divider`,
`base_fetching_widget`, `black_yellow_card`, `buttons/app_default_button`, `buttons/app_icon_button`,
`custom_chip`, `custom_radio_group_widget`, `linear_progress_indicator`, `selection_chip_widget`,
`text_form_fields/app_text_form_field`, `text_form_fields/dynamic_drop_down_text_field`,
`toasts/animated_custom_toast`, `voice_recorder_player_widget`; plus `app_routes_names.dart`,
`exports/core_exports.dart`, `keys/api_keys.dart`.

For the template: take the infra (services, base_architecture, failures) from either copy (same code); take
the **theme layer from InstaOps** if a runtime/tenant palette is wanted, from brgr if static colors are enough.

---

## 1. Architecture pattern

**Feature-first, "clean-architecture-lite"** (data + presentation, no domain layer):

- `data/data_sources/*_remote_data_source.dart`: classes `extends BaseRemoteDataSource` and call
  `handleRequest(path:, method: HttpMethod.x, parser: (res) => Model.fromJson(res.data))`. They **throw** `Failure`.
- `data/models/`: hand-written `fromJson`/`toJson` classes, mostly with mutable nullable fields. No codegen
  (no freezed / json_serializable).
- `data/repositories/*_repo.dart`: classes `extends BaseRepository` that wrap every call in
  `handleNetworkCall(call: ...)` and return `Future<Either<Failure, T>>`. The repositories also hold some
  business logic (the auth repo swaps credentials and rewrites the user role, for example).
- `presentation/managers/<x>_cubit/` (sometimes `presentation/cubit/` or `presentation/<x>_cubit/`, so naming
  is not consistent): cubits extend either `BaseCubit<S extends BaseState>` (one class per state:
  `XLoading/XSuccess/XFailure`) or `BaseSingleClassStateCubit<S extends BaseSingleClassState>` (one state class
  with `status`, `failure`, `success` + feature fields + `copyWith`). States live in `part` files.
- `presentation/screens/`, `presentation/widgets/`.
- Wiring: everything is registered by hand in `core/services/di_container.dart`. Global cubits are provided in
  `main.dart` (MultiBlocProvider) and role-specific ones in the `ShellRoute` builder (`app_router.dart`).

The app is role-based (supervisor, branch manager, maintenance technician, area/operation managers, admin).
Each role group has its own feature folder, and those folders contain a lot of copy-pasted code.

## 2. Folder tree (`lib/`, 4 levels)

```
lib/
├── main.dart                     bootstrap: runZonedGuarded, prefs init, EasyLocalization, DI, BlocObserver,
│                                 AppCubit + AppThemeNotifier providers, ScreenUtilInit, global BlocProviders,
│                                 MaterialApp.router, lost-photo recovery
├── geofence_service.dart         GeofencingService (MethodChannel + geolocator + haversine), permission helper
├── firebase_options.dart         FlutterFire generated (exists; not opened)
├── core/
│   ├── app_cubit/                AppCubit/AppState (user, attendance, role) — global session state
│   ├── app_router/               app_router.dart (GoRouter), app_routes_names.dart, root_navigator_key.dart
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/     base_remote_data_source.dart
│   │   │   ├── models/           base_request_model/network_request_model.dart, base_response_model/
│   │   │   │                     base_success_response.dart, base_success_model.dart, id_title_model.dart
│   │   │   └── repository/       base_repo.dart
│   │   └── presentation/managers/
│   │       ├── base_cubit/       base_cubit.dart, base_state.dart
│   │       └── base_single_class_state_bloc/  base_single_class_state(.dart|_bloc.dart)
│   ├── enums/                    app_roles, fetch_data_status, http_method, task_status, task_type, toast_state
│   ├── exports/                  core_exports.dart barrel (material, go_router, easy_localization, screenutil,
│   │                             AppColors, AppColorsContext, DefaultScreen)
│   ├── extensions/               context_extensions (theme, textTheme, colorScheme, isAr), list_extensions
│   ├── models/                   selection_model.dart
│   ├── services/                 api, DI, prefs, secure storage, notifications/topics, image picker,
│   │                             pending capture, validators, toast, loading dialog, interceptors, misc helpers
│   ├── theme/
│   │   ├── app_colors_extension.dart, app_theme_notifier.dart, color_shade_generator.dart
│   │   ├── dark_theme/           dark_theme.dart (EMPTY)
│   │   └── light_theme/          light_theme.dart, my_light_themes_export.dart,
│   │       └── light_widget_themes/  app_bar, bottom_nav, btn_txt, dialog, elevated_btn, input_decoration,
│   │                                 light_color_scheme, snack_bar, text_theme
│   └── utilities/
│       ├── constants/            colors.dart, icons.dart (AppIcons + svg helper), images.dart, temp_images.dart,
│       │   └── keys/             api_keys.dart (base URL + endpoints), shared_preferences_keys.dart
│       ├── converters/           price_converter.dart (EMPTY)
│       ├── failures/             failure.dart, error_details_model.dart
│       ├── formatters/           date_formatter.dart
│       ├── helpers/              handle_unauthorized.dart, role_navigation.dart
│       └── widgets/              14 widgets + buttons/ (2), text_form_fields/ (5), toasts/ (2)
└── features/
    ├── auth/                     data/{data_sources(remote+local),models,repositories}; presentation/
    │                             managers/{auth,login,register}_cubit, screens/{login,register}
    ├── bottom_nav/               models/, presentation/{cubit,screens/bottom_nav_screen,widgets/
    │                             {navigation_widget,attendance_dialog(790 lines, geofence + check-in/out)}}
    ├── splash/                   presentation/{config_cubit,screens/splash_screen}
    ├── settings/settings/        data/{data_sources,models,repositories(+delete_account_service: Firestore)},
    │                             presentation/{screens,settings_cubit,widgets}
    ├── notifications/            (fully expanded below)
    ├── shared/                   screens/{image_viewer,select_location(stub)}, widgets/image_Widget.dart
    ├── supervisor_branch_manager_feature/
    │   ├── home/                 data/{data_sources(remote+local),models,repositories}, presentation/
    │   │                         {attendances_cubit,home_cubit,screens,widgets}
    │   ├── maintenance/          data/…, presentation/{managers/maintenances_cubit,screens,widgets}
    │   ├── supervisors/          data/…, presentation/{managers/{supervisors,supervisors_attendance}_cubit,…}
    │   └── tasks/                data/{…,models/{requests,task_clones_models}}, presentation/
    │                             {checklist_cubit(checklist+tasks cubits),screens(6 task-completion screens),widgets}
    ├── maintenance_technician_feature/technician_maintenance/
    │                             data/{…,models/requests}, presentation/{managers/{maintenances_cubit,
    │                             task_timer_service.dart},screens(5),widgets}
    └── managers_feature/
        ├── managers_home/        data/…, presentation/{managers/{home_cubit,home_statics_cubit},screens,widgets}
        ├── managers_checklists/  data/{…,models/{responses,task_clones_models}}, presentation/
        │                         {managers/{checklist,checklists,checklists_statics}_cubit,screens,widgets/checklist_details}
        └── managers_reports/     presentation/screens/reports_screen.dart (fl_chart); data/ & cubit/ empty
```

Representative feature, fully expanded:

```
features/notifications/
├── data/
│   ├── data_sources/notifications_remote_data_source.dart   extends BaseRemoteDataSource; GET ApiKeys.NOTIFICATIONS
│   ├── models/notifications_response_model.dart            NotificationsResponseModel.fromJson(List) + NotificationModel/Payload
│   └── repositories/notifications_repo.dart                extends BaseRepository -> Either<Failure, NotificationsResponseModel>
└── presentation/
    ├── managers/notifications_cubit/
    │   ├── notifications_cubit.dart                        BaseSingleClassStateCubit; getNotifications() via handleRequest hooks
    │   └── notifications_state.dart (part)                 status/success/failure + notifications list, copyWith
    ├── screens/notifications_screen.dart                   DefaultScreen + BlackYellowCard header + RefreshIndicator
    ├── screens/notification_screen.dart                    details (route extra: NotificationModel)
    └── widgets/notifications_view.dart, notifications_card.dart
```

Feature sizes: supervisor_branch_manager_feature 76 files / 10.8k lines; managers_feature 46 / 5.5k;
maintenance_technician 13 / 2.0k; auth 15 / 1.5k; bottom_nav 6 / 1.2k; settings 11 / 0.9k; notifications 9 / 0.7k.

## 3. Infrastructure

### 3.1 State management
- `flutter_bloc ^9.1.1` cubits only (no `Bloc` with events). `equatable` for states.
- `BaseCubit` (`core/base_architecture/presentation/managers/base_cubit/base_cubit.dart`): `handleRequest<T>({loadingState, call, onSuccess, onError, showLoading})`
  emits the loading state, folds the Either, and turns any thrown exception into `UnknownFailure` (logged with talker).
  It has a stray `print`. 11 cubits use it.
- `BaseSingleClassStateCubit` (`…/base_single_class_state_bloc/base_single_class_state_bloc.dart`): `handleRequest<T>({call, onNotDefaultSuccess, onNotDefaultFailure?, onNotDefaultLoading?})`.
  By default it emits `copyWith(status: loading/failure)` cast `as State`. The success path is always custom
  (the default success emit is commented out). 8 cubits use it. `BaseSingleClassState.copyWith` uses the
  `failure ?? this.failure` pattern, so an old failure can never be cleared back to null.
- `AppCubit` (`core/app_cubit/`) holds the global session (user, attendance, role). It extends BaseSingleClassState fields it never uses.
- `AppBlocObserver` (`core/services/bloc_observer.dart`) `print`s every create/change/close, including in release builds.
- `provider ^6.1.5` is used only for `AppThemeNotifier`. `hydrated_bloc` is declared but never used.

### 3.2 DI
- `get_it ^8.0.3`, manual registration in `core/services/di_container.dart` (global `sl` plus the global `talker`).
  Data sources and repos are lazy singletons; cubits are factories.
- Problems: `diContainerSetup()` is `async` but main calls it without `await`, and its inner `_init*` calls are
  not awaited either. `TaskTimerService` is registered after `await SharedPreferences.getInstance()`, so it is
  only registered by the time it is first needed because prefs were already warmed in main (works by luck).
  `SecureStorageManager.init()` assigns a `late final`. The file imports about 45 feature files, so core
  depends on features.

### 3.3 Routing
- `go_router 16.3.0`, one top-level `appRouter` with `navigatorKey: rootNavigatorKey` and
  `observers: [TalkerRouteObserver(talker)]`.
- Splash uses a `CustomTransitionPage` fade. A `ShellRoute` wraps the role tab routes in `BottomNavScreen` and
  creates the role cubits (`lazy: false`). Every other screen is a top-level route that gets its typed
  arguments through `state.extra as X`. No path params, no `redirect`/guards, no deep links. `onExit` is used to
  refresh the checklist cubit.
- The landing route is chosen in `splash_screen.dart`: read the token from secure storage, read the role from
  prefs, then `applyRoleNavigation()` (`core/utilities/helpers/role_navigation.dart`).
- Bug: `AppRoutesNames.managersHome` and `AppRoutesNames.home` are both `'/home'`, so the managers-home GoRoute
  is shadowed by the supervisor HomeScreen route (first match wins). brgr uses `/managers_home`.
- Navigation from the bottom-nav cubit is done in a `BlocConsumer` listener calling `context.go(route)`.

### 3.4 Networking
- `dio ^5.7.0`, wrapped by `ApiService implements ApiServiceBase` (`core/services/api_service.dart`). The base URL
  comes from `ApiKeys.BASE_URL` (`{{BASE_URL}}`). Connect and receive timeouts are both 5 minutes. Default JSON
  headers, Bearer token read from prefs at construction, and `updateHeaders(token:, customHeaders:)` (a null
  value removes the header; used for `Accept-Language` and to drop `Content-Type` for multipart requests).
- Interceptors: `UnauthorizedInterceptor` (401 not on login/config/logout paths → `triggerUnauthorizedLogout()`,
  then the error is passed on) and `TalkerDioLogger(printRequestHeaders: true)`, which logs the Bearer token.
  `LoggingInterceptor` is registered in get_it but never added to Dio.
- No token refresh, no retry, no connectivity check (`hasNetworkConnection` in AppState is never updated).
- Error mapping in `BaseRemoteDataSource`: a 200/201 response goes to `parser`. Anything else goes through
  `_handleErrorResponse` (400 → BadRequestFailure with per-field `ErrorDetail`s, 401/403/404/500, default →
  ServerFailure(message) or UnknownFailure). Only `DioExceptionType.connectionTimeout` becomes `TimeoutFailure`;
  receive/send timeouts without a response become `NetworkFailure`. Unexpected errors become `UnknownFailure`.
  Non-Map error bodies are handled defensively.
- `handle_unauthorized.dart`: unsubscribes all FCM topics, resets AppCubit, clears timers through
  `sl<TechnicianMaintenancesCubit>()` (a factory, so this is a new instance), deletes the token from secure
  storage and prefs, removes the cached user, then `context.go(login, extra: {'logout': true})`. It has a
  re-entrancy flag and retries up to 5 post-frame times when the navigator context is null. It does not reset
  AppThemeNotifier (the settings logout does).

### 3.5 Local storage
- `SharedPreferencesManager` (singleton; `init()` in main; untyped `setValue(dynamic)` / `getValue`) — `core/services/shared_preferences_manager.dart`.
- `SecureStorageManager` (singleton; Android encryptedSharedPreferences + resetOnError, iOS first_unlock; every
  operation try/catch with self-heal) — `core/services/secure_storage_manager.dart`. Stores the token and, in the
  register flow, the user's password.
- Keys: `core/utilities/constants/keys/shared_preferences_keys.dart` (SCREAMING_CASE constants).
- Cached `UserModel` JSON in prefs (`AuthLocalDataSource.saveUser`); per-task timers (`TaskTimerService`);
  pending/recovered photo capture (`PendingCaptureService`).
- `cloud_firestore` holds a "deleted accounts" collection, with a prefs fallback
  (`features/settings/settings/data/repositories/delete_account_service.dart`).

### 3.6 Localization (+RTL)
- `easy_localization ^3.0.7`. `supportedLocales: [ar, en]`, `startLocale` and `fallbackLocale` are `ar`, path
  `assets/translations`, nested JSON keys (`'validation.empty_email'.tr()`). Each file has 25 groups and 280 leaf
  keys, and ar/en are in sync. 11 keys used in code are missing from the JSON: `auth.confirm_password`,
  `auth.confirm_password_hint`, `common.no_tasks`, `error_please_try_again`, `home.managers_checklists`,
  `logout`, `messages.delete_account_success`, `no_tasks`, `retry`, `take_a_photo`, `upload_from_gallery`.
- `intl ^0.20.2` through easy_localization's re-export, used by `DateFormatter`.
- Changing language: `context.setLocale` + `ApiService.updateHeaders({'Accept-Language'})` + a backend
  change-language call + FCM topic resubscription (`settings_cubit.dart`). `MaterialApp.router` is keyed by
  locale, so the whole tree rebuilds.
- RTL: easy_localization already sets directionality through the locale, but `main.dart` also wraps the app in
  `Directionality(ar ? rtl : ltr)`, which is redundant. Directional APIs: 25 uses. Left/right-specific: 39
  (28 `EdgeInsets.fromLTRB`, plus `EdgeInsets.only(left/right)` and `Positioned(left/right)` in black_yellow_card,
  image_viewer, supervisors cards, notifications_card, maintenance_details_screen). `AppBackButton` always uses
  `Icons.arrow_forward_rounded` (mirrors, but is the wrong glyph in LTR).
- `context.isAr` extension (`core/extensions/context_extensions.dart`). `getDeviceLocale/setAppLanguageToDeviceLanguage` are unused.
- Hardcoded strings (some): NotificationService permission dialog (English), `'Search...'`,
  `'Select an option'`, `"Wrong Password"`, `"Email Already Deleted"`, `'Invalid date or format'`, the default
  messages of the Failure classes, and Arabic mock content in `managers_home/presentation/widgets/{notifications_view,home_checklists_view}.dart`.

### 3.7 Theming
- `lightTheme(BuildContext)` (`core/theme/light_theme/light_theme.dart`): M3, `ColorScheme.fromSeed(seed: primary)`
  (uses the deprecated `background`/`onBackground`), and component themes for appBar, bottomNavigationBar,
  textButton, elevatedButton (fixed 343.w x 52.h), legacy buttonTheme, input decoration (outline, filled,
  neutral200 fill), snackBar (floating), dialog, and progress indicator.
- **Runtime palette** (InstaOps only): `AppColors` is an instance class with `primary/primary50..1000` and
  `secondary/secondary50..1000`, generated by `ColorShadeGenerator.generateShades(base)` (HSL lightness offsets;
  the base is treated as shade 600), plus static `neutral*`, `green*`, `red*`, task-status colors.
  `AppThemeNotifier` (ChangeNotifier) has `applyBackendTheme(primaryHex, secondaryHex)` (called after login from
  `company.primaryColor/secondaryColor`) and `reset()`. `context.watchColors` / `context.appColors` come from
  `core/theme/app_colors_extension.dart`. Gaps: the palette is not persisted, so a returning user (splash path)
  sees the default colors. Not reset on 401 logout. `watch` is also called outside `build` (in CustomSizeRadio.didChangeDependencies).
- Text styles: `TextThemeLight` singleton (`light_widget_themes/text_theme.dart`), Alexandria family, full
  M3 scale (57…10). Bug: `_textStyle.copyWith(color: …)` result is discarded, so there is no default text
  color. Sizes are raw (not `.sp`).
- Dark theme: none (`dark_theme/dark_theme.dart` is 0 bytes).
- Fonts: Alexandria 100–900 and Cairo (declared; Cairo weight 100 points at the ExtraLight file).
- Colors are still hardcoded in places: `Color(0xFFE2E2E2)`, `AppColors.newColor(0xFFF6F6F6)`, `Colors.grey[300]`, `Colors.red`.

### 3.8 Responsive helpers
- `flutter_screenutil ^5.9.3`. `ScreenUtilInit(designSize: Size(393, 852), minTextAdapt: true, splitScreenMode: true)`.
  `.w/.h/.r` are used widely, `.sp` almost never. No breakpoints and no tablet layouts.

### 3.9 Text scaling
- None. No `MediaQuery.textScaler` clamp. Fixed font sizes in the theme and widgets.

### 3.10 Env / flavors
- None. `ApiKeys` holds a "Testing" and a "Live" `BASE_URL`/`BASE_IMAGE_URL`, switched by commenting lines.
  No Android productFlavors and only the default `Runner` iOS scheme. Firebase config files exist
  (`android/app/google-services.json`, `firebase.json`, `lib/firebase_options.dart`; not opened).

### 3.11 Logging
- `talker_flutter ^5.0.0` (global `final talker = Talker()` in di_container.dart; used in BaseCubit,
  BaseRemoteDataSource, router observer, Firestore service), `talker_dio_logger ^5.0.0`. No TalkerScreen exposed.
- Mixed with `print` (15) and `debugPrint` (59). Nothing is stripped in release builds.

### 3.12 Analytics / crash reporting
- `firebase_crashlytics ^5.0.5`: only `FirebaseCrashlytics.instance.recordError(..., fatal: true)` in the
  `runZonedGuarded` handler. `FlutterError.onError` is commented out. No analytics package.
- **`Firebase.initializeApp` and `onBackgroundMessage` are commented out in `main.dart`**, so in the current
  state Crashlytics, FCM and Firestore calls will fail at runtime (`[core/no-app]`). The background handler
  function is still defined.

### 3.13 Push notifications
- `firebase_messaging ^16.0.1` + `flutter_local_notifications ^19.4.1`. `NotificationService.init(context)` runs
  from `MainApp` after the first frame. It requests permission (Android: permission_handler with a
  permanently-denied dialog; iOS: FCM requestPermission), initializes local notifications, creates the `default`
  and `geofence` channels, disables FCM's own foreground presentation, shows foreground messages as local
  notifications, and handles onMessageOpenedApp/getInitialMessage (navigation is TODO). The token-refresh hook
  is TODO. The device token is sent at login (LoginParams.deviceToken).
- Topic model (`notification_topic_handler.dart`): `all_topic_<lang>` + `<role>_topic_<lang>`. Subscribed at
  login, all unsubscribed at logout, swapped on language change.
- Bugs: channels are created on `AndroidFlutterLocalNotificationsPlugin()` (a new instance; the
  `resolvePlatformSpecificImplementation` lines are tear-off no-ops). `_isAndroid13OrHigher()` always returns
  true. The token is logged.

### 3.14 IAP / payments
- None.

### 3.15 Permissions
- `permission_handler ^12.0.1`: notifications (Android), camera/photos (iOS only; Android relies on system
  pickers), microphone/storage (voice recorder), location whenInUse → always (geofence). `geolocator ^14.0.2`
  also checks and requests permission in `attendance_dialog.dart`, with dialogs that open location or app settings.

### 3.16 Deep links
- None (no app_links/uni_links; routes rely on `extra` objects, so they cannot be deep-linked).

### 3.17 Other platform features
- Geofencing: Dart `GeofencingService` (`lib/geofence_service.dart`, singleton, MethodChannel
  `'<app>/geofencing'`, event stream, haversine `isInsideGeofence`, `checkGeofenceStatusOnStart`). Native side:
  Android `android/app/src/main/kotlin/<pkg>/{MainActivity,GeofenceHelper,GeofenceBroadcastReceiver}.kt`, iOS
  `ios/Runner/{AppDelegate,GeofencingManager}.swift`. Used for attendance check-in/out rules (`attendance_dialog.dart`).
- Voice notes: `flutter_sound` (record) + `just_audio` (remote playback), in `voice_recorder_player_widget.dart`.
- `device_info_plus` provides the device id for login. `package_info_plus` shows the version in settings.
  `url_launcher` opens maps. `fl_chart` and `percent_indicator` drive the managers' dashboards. `skeletonizer`
  covers loading states on two screens. `dotted_border` is used.

## 4. Services catalog

| File | Purpose | Public API | Depends on | Generic? |
|---|---|---|---|---|
| core/services/api_service.dart | Dio wrapper | `ApiServiceBase`; `ApiService(baseUrl, dioClient, sharedPreferencesManager)`; `get/post/put/patch/delete(NetworkRequestParams)`; `updateHeaders(token, customHeaders)` | dio, talker_dio_logger, prefs, UnauthorizedInterceptor | generic |
| core/services/unauthorized_interceptor.dart | global 401 → logout | `UnauthorizedInterceptor.onError` | ApiKeys, handle_unauthorized | generic (paths configurable) |
| core/services/logging_interceptors.dart | debugPrint request/response logger | `LoggingInterceptor` | dio | generic (unused) |
| core/services/di_container.dart | get_it registrations | `sl`, `talker`, `diContainerSetup()` | everything | app-specific |
| core/services/shared_preferences_manager.dart | prefs singleton | `init`, `setValue`, `getValue`, `remove`, `clear` | shared_preferences | generic |
| core/services/secure_storage_manager.dart | secure storage singleton w/ self-heal | `init`, `read`, `write`, `delete`, `clearAll`, `containsKey`, `readAll` | flutter_secure_storage | generic |
| core/services/notification_service.dart | FCM + local notifications | static `init(context)`, `showLocalNotification`, `showGeofenceNotification`, `cancelNotification`, `cancelAllNotifications`, `subscribeToTopic`, `unsubscribeFromTopic` | firebase_messaging, flutter_local_notifications, permission_handler | generic-ish (buggy) |
| core/services/notification_topic_handler.dart | role/lang topic naming + (un)subscribe | `NotificationTopics.all/roleTopic`; `NotificationTopicHandler.handleNotificationsSubscriptions(context, role)`, `unsubscribeAll(context)` | UserRole, NotificationService | app-specific pattern |
| core/services/image_picker_service.dart | pick + compress + recover | `pickImage(context, source)`, `retrieveLostData()`, `getImageSizeKB`, `getFormattedImageSize` | image_picker, flutter_image_compress, path_provider, permission_handler, easy_localization | generic |
| core/services/pending_capture_service.dart | crash-safe capture marker | `markPending(id)`, `pendingTaskId`, `clearPending`, `saveRecovered`, `takeRecoveredFor`, `clearRecovered` | prefs manager | generic (rename task→entity) |
| core/services/app_validator.dart | form validators | static `isNotEmpty`, `isValidEmail`, `isValidPhone`, `isValidSaudiPhone`, `isValidPassword(value,isLogin)`, `confirmPassword`, `isNumeric`, `isNumericInRange`, `isNotEmptyImage`, `ibanValidator`, `customValidator` | easy_localization | generic |
| core/services/toast_manager.dart | overlay toast | `ToastManager.showToast(...)`, `BuildContext.showToast(...)` | AnimatedCustomToast | generic |
| core/services/show_loading_dialog.dart | blocking loader dialog | `showLoadingDialog(context, message, barrierDismissible)` | material | generic |
| core/services/bloc_observer.dart | bloc logging | `AppBlocObserver` | flutter_bloc (print) | generic |
| core/services/debounce.dart | debouncer | `Debounce(milliseconds).run/cancel` | dart:async | generic (unused) |
| core/services/get_and_set_device_locale.dart | device locale → app locale | `setAppLanguageToDeviceLanguage(context)`, `getDeviceLocale()` | easy_localization, dart:io | generic (unused) |
| core/services/language_flags_service.dart | locale → flag emoji | `LanguageService.getFlagEmoji(locale)` | — | generic |
| core/services/get_percentage.dart | safe percentage | `getPercentage(completed, total)` | — | generic |
| core/services/phone_handeler_service.dart | prefix 0 | `ensureStartsWithZero(number)` | — | generic (unused; typo in name) |
| core/utilities/failures/failure.dart | Failure hierarchy | 10 subclasses, `Failure.displayMessage` | easy_localization | generic |
| core/utilities/failures/error_details_model.dart | field errors | `ErrorDetail(field, messages)`, `fromJson` | — | generic |
| core/utilities/formatters/date_formatter.dart | date helpers | `formatDateString`, `formatDate`, `isMorning`, `isToday` | intl | generic |
| core/utilities/helpers/handle_unauthorized.dart | logout flow | `triggerUnauthorizedLogout()`, `handleUnauthorizedFailure(context)` | AppCubit, topics, TechnicianMaintenancesCubit, storage | app-specific (pattern generic) |
| core/utilities/helpers/role_navigation.dart | role → landing route | `routeForRole(role)`, `applyRoleNavigation(context, role)` | AppCubit, BottomNavCubit, UserRole | app-specific |
| core/utilities/constants/icons.dart | asset paths + svg helper | `AppIcons.*`, `AppIcons.svg(...)` | flutter_svg, ApiKeys | generic helper |
| core/utilities/constants/images.dart / temp_images.dart | asset paths + image helper | `AppImages.image(...)`, `TempImages.image(...)` | — | generic helper |
| core/utilities/constants/colors.dart | palette | `AppColors.fromBaseColors`, `AppColors.defaults`, static colors | ColorShadeGenerator | generic idea |
| core/utilities/constants/keys/api_keys.dart | base URL + endpoints | `ApiKeys.*` | — | app-specific |
| core/utilities/constants/keys/shared_preferences_keys.dart | pref keys | constants | — | generic-ish |
| core/utilities/constants/constant_lists.dart | language list | `ConstantLists.languagesList` | settings LanguageModel (feature import) | app-specific |
| core/theme/color_shade_generator.dart | shades from one color | `generateShades(Color)` | material | generic |
| core/theme/app_theme_notifier.dart | runtime palette holder | `colors`, `applyBackendTheme(primaryHex, secondaryHex)`, `reset()` | provider | generic |
| core/theme/app_colors_extension.dart | context accessors | `context.appColors`, `context.watchColors` | provider | generic |
| core/extensions/context_extensions.dart | theme shortcuts | `theme`, `textTheme`, `colorScheme`, `isAr` | material | generic |
| core/extensions/list_extensions.dart | null/empty | `isNullOrEmpty()` | — | generic |
| core/enums/app_roles_enum.dart | roles | `UserRole(value, code)`, `tryFromString`, `fromString` | — | app-specific (pattern generic) |
| core/enums/task_status_enum.dart | status → title/color/icon | `title`, `color`, `svgIconPath`, `fromString` | AppColors, AppIcons | app-specific |
| core/base_architecture/** | base data/presentation classes | see §3.1/3.4 | dio, dartz, flutter_bloc, equatable | generic |
| lib/geofence_service.dart | geofencing | `GeofencingService.instance`, `initialize`, `addGeofence`, `removeGeofence`, `getCurrentLocation`, `isInsideGeofence`, `checkGeofenceStatusOnStart`, `onGeofenceEvent`; `ensureLocationPermission()`, `registerGeofencingService(lat,long)` | geolocator, permission_handler, MethodChannel + native code | generic-ish (print, magic radii) |
| features/maintenance_technician_feature/…/task_timer_service.dart | persisted per-task timer | `startTask`, `clearTask`, `clearAllTasks`, `getStartTime`, `isTaskRunning`, `elapsedDuration` | shared_preferences | generic |
| features/settings/settings/data/repositories/delete_account_service.dart | Firestore deleted emails | `addDeletedEmail`, `emailExists` | cloud_firestore, AuthLocalDataSource | app-specific |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| core/utilities/widgets/buttons/app_default_button.dart | primary button with loading circle, disabled color, optional svg icon | onTap, text, textStyle, child, height, width, radius, margin, padding, isLoading, backgroundColor, textColor, enabled, svgIconPath, svgIconColor, borderColor, blockMultipleClicks | y |
| core/utilities/widgets/buttons/app_icon_button.dart | `AppIconButton` square icon button; `AppBackButton` | onTap, child, radius, height, width, backgroundColor / onTap | y |
| core/utilities/widgets/text_form_fields/app_text_form_field.dart | titled TextFormField | title, controller, hintText, onTap, onChanged, enabled, readOnly, obscureText, keyboardType, validator, inputFormatters, icon, prefixIcon, suffixIcon, titleStyle, textStyle, hintTextStyle, maxLength, maxLines, bottomMargin, prefix/suffixIconConstraints, focusNode, textAlign, onSaved, onFieldSubmitted, onEditingComplete | y |
| core/utilities/widgets/text_form_fields/password_text_form_field.dart | password + eye toggle | controller, isConfirmPassword, confirmPasswordValidator (ignored), title, hintText, isLogin, onChanged | y (fix validator) |
| core/utilities/widgets/text_form_fields/email_text_form_field.dart | email field | controller, title, hintText, readOnly, onChanged | y |
| core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart | bottom-sheet string picker | title, hintText, controller, items, validator, onChanged | y |
| core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart | generic popup-menu dropdown | controller, title, onOptionSelected, options, hintText, displayText, showSearch, isLoading | y |
| core/utilities/widgets/toasts/animated_custom_toast.dart | animated overlay toast | message, state, duration, location | y |
| core/utilities/widgets/toasts/custom_toast.dart | static toast | message, state, duration | y (unused) |
| core/utilities/widgets/base_fetching_widget.dart | `GenericFetchWidget<B,S,T>`, `BaseLoadingWidget`, `BaseErrorWidget` | successBuilder, loadingWidget, failureWidget, onRetry / — / message, onRetry | y |
| core/utilities/widgets/base_list_view_widget.dart | list with empty state | items, itemBuilder, emptyWidget | y (unused) |
| core/utilities/widgets/default_screen.dart | base scaffold with title row and back button | body, backgroundColor, appBarPadding, bodyPadding, topMargin, appbar, floatingActionButton, floatingActionButtonLocation, pageTitle, pageTitleWidget, hasAppBar, hasBottomBorder, hasBackButton, hasBottomMargin, onBackPressed | y |
| core/utilities/widgets/container_with_shadow.dart | tappable shadow card | child, margin, padding, radius, width, height, image, backgroundColor, border, onTap, boxShadow, shadowBlurRadius | y |
| core/utilities/widgets/custom_chip.dart | pill with title + description | title, description, bgColor, borderColor, titleColor, radius, titleFontSize, padding, descColor, descFontSize, crossAxisAlignment, spacing | y |
| core/utilities/widgets/selection_chip_widget.dart | selectable filter chip | isSelected, title, onTap | y |
| core/utilities/widgets/custom_radio_group_widget.dart | radio list + animated radio | options, selectedValue, onChanged, prefixText, label / value, groupValue, onChanged, size, activeColor, inactiveColor, animationDuration | y |
| core/utilities/widgets/expandable_container.dart | expandable card | title, image, collapsedContent, collapsedHeight, expandedHeight, description, expandedContent, onToggle | partly |
| core/utilities/widgets/linear_progress_indicator.dart | percent bar (green at 100) | percent, minHeight | y |
| core/utilities/widgets/app_divider.dart | divider | height, thickness, color, indent, endIndent, widthFactor | y |
| core/utilities/widgets/image_picker_bottom_sheet.dart | camera/gallery sheet | context, onFilePicked | y |
| core/utilities/widgets/black_yellow_card.dart | branded header card | child, borderRadius, circleShapeBottomPosition, padding | n |
| core/utilities/widgets/voice_recorder_player_widget.dart | record/play voice note | onFileSaved, voicePath | partly |
| core/services/show_loading_dialog.dart | loading dialog fn | context, message, barrierDismissible | y |
| features/shared/widgets/image_Widget.dart | universal image (asset/file/network) | image, imageWidth, imageHeight, margin, onTap, stackedWidget, radius, fit, color, border | y |
| features/shared/screens/image_viewer.dart | full-screen viewer | imagePath | y |
| features/bottom_nav/presentation/widgets/navigation_widget.dart | bottom-nav item | navItem, isSelected, onTapItem | y |
| features/splash/presentation/screens/splash_screen.dart (`AnimatedImageViewer`) | animated logo | image, imageHeight, imageWidth, radius | y |
| features/bottom_nav/presentation/widgets/attendance_dialog.dart | geofence/attendance dialogs + logic (790 lines) | functions + private widgets | n |

No shimmer widget (skeletonizer is used inline), no pagination list, no app-wide AppBar widget (DefaultScreen
draws its own title row), no confirmation dialog helper, no empty-state widget beyond BaseListView's text.

## 6. Packages (`pubspec.yaml`)

| Role | Packages |
|---|---|
| State | flutter_bloc ^9.1.1, equatable ^2.0.7, provider ^6.1.5+1 (theme only), hydrated_bloc ^10.1.1 (unused) |
| DI | get_it ^8.0.3 |
| Routing | go_router ^16.2.1 (resolved 16.3.0) |
| Network | dio ^5.7.0, dartz ^0.10.1, talker_dio_logger ^5.0.0 |
| Storage | shared_preferences ^2.3.3, flutter_secure_storage ^9.2.4, path_provider ^2.1.5, path ^1.9.1 |
| L10n | easy_localization ^3.0.7, intl ^0.20.2, flutter_localizations (sdk) |
| UI | flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, skeletonizer ^2.1.0+1, cupertino_icons ^1.0.8, flutter_native_splash ^2.4.3, dotted_border ^3.1.0, percent_indicator ^4.2.5, fl_chart ^0.68.0, flutter_animate ^4.5.2 (unused), animate_do ^4.2.0 (unused), flutter_html ^3.0.0 (unused), country_picker ^2.0.2 (unused) |
| Firebase | firebase_core ^4.1.0, firebase_messaging ^16.0.1, firebase_crashlytics ^5.0.5, cloud_firestore ^6.1.3 |
| Notifications | flutter_local_notifications ^19.4.1 |
| Media | image_picker ^1.2.2, flutter_image_compress ^2.4.0, cached_network_image ^3.4.1 (unused), just_audio ^0.10.0, flutter_sound ^9.2.13 |
| Location/maps | geolocator ^14.0.2, google_maps_flutter ^2.3.2 (unused), url_launcher ^6.3.1 |
| Device/utils | permission_handler ^12.0.1, package_info_plus ^8.3.0, device_info_plus ^12.3.0, talker_flutter ^5.0.0 |
| Build tooling (in dependencies!) | flutter_launcher_icons ^0.14.4 |
| Dev | flutter_test (sdk), flutter_lints ^6.0.0 |

## 7. Quality notes

- **Null safety**: sound (Dart ^3.7.2), but models are all nullable mutable fields, and `!` is used heavily
  (`response.user!`, `state.user.role!`, `ios.identifierForVendor!`).
- **Lints**: `include: package:flutter_lints/flutter.yaml` with 0 extra rules. Code style is inconsistent
  (mixed formatting, some CRLF files, very deep relative imports such as `'../../../../../../../../core/...'`).
- **Tests**: 1 file, the default counter smoke test, which would fail (no counter in MainApp). Nothing tests the
  base classes, validators or repos.
- **Security**: hardcoded fallback login credentials in `lib/features/auth/data/repositories/auth_repo.dart`
  (the "register" flow and a stored-email shortcut both log into one shared backend account, then rewrite the
  role locally). The user's chosen password is stored on device. "Deleted accounts" are tracked client-side in
  Firestore. TalkerDioLogger prints request headers (the Bearer token). FCM and device tokens are logged.
- **Runtime-risk bugs**: Firebase init commented out (§3.12); DI not awaited (§3.2); `/home` path clash (§3.3);
  inverted password validation (`password_text_form_field.dart`); text theme color discarded (§3.7);
  CustomSizeRadio controller re-creation; NotificationService channel creation; ToastManager timer removing a
  newer toast; theme palette not persisted or reset on 401.
- **Duplication**: managers_feature duplicates supervisor_branch_manager_feature (32 duplicate file names; the
  `task_clones_models` are identical; two `maintenance_details_screen.dart`, two `task_details_bottom_sheet.dart`,
  two `home_local_data_source.dart`, …). The supervisor and technician maintenance features are near copies.
  Six large task-completion screens (460–790 lines) share most of their logic. The whole project is also a
  ~73%-identical copy of brgr (§0).
- **God files**: `bottom_nav/presentation/widgets/attendance_dialog.dart` (790 lines of UI, geofence logic,
  attendance rules and a logout button), `tasks/presentation/screens/complete_data_on_item_screen.dart` (792),
  `complete_data_task_screen.dart` (691), `maintenance/presentation/screens/maintenance_details_screen.dart` (689).
  `BottomNavScreen` also does data loading, attendance fetching and geofence checks.
- **Layering leaks**: core imports features (di_container, app_cubit → UserModel/UserAttendanceModel,
  handle_unauthorized → TechnicianMaintenancesCubit, role_navigation → BottomNavCubit, constant_lists →
  LanguageModel, expandable_container → features/shared). Role strings are compared directly in UI
  (`"supervisor"`, `"branchManager"`) even though the `UserRole` enum exists.
- **Deprecated APIs**: `WillPopScope` (1, attendance_dialog.dart), `withOpacity` (7), `ColorScheme.fromSeed(background/onBackground)`,
  legacy `buttonTheme`. No `textScaleFactor` or `MaterialStateProperty`.
- **Dead code**: unused packages (hydrated_bloc, cached_network_image, google_maps_flutter, flutter_animate,
  animate_do, country_picker, flutter_html), unused helpers (GenericFetchWidget, BaseListView, Debounce,
  CustomRadioGroup, CustomToast, setAppLanguageToDeviceLanguage, ensureStartsWithZero, LoggingInterceptor,
  BaseSuccessResponse), empty files (dark_theme.dart, price_converter.dart), stub `select_location_screen.dart`,
  empty `managers_reports/data` and `cubit` folders, large commented-out blocks.
- **Hardcoded values**: UI strings (§3.6), colors (§3.7), geofence radii 100/200 m, 2-second artificial splash and
  post-login delays, 5-minute HTTP timeouts.
