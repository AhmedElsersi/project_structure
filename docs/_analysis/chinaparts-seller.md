# chinaparts-seller

## Summary for comparison

```
PROJECT: chinaparts-seller | path: Chinaparts/New Projects/seller | stack: Flutter (CI pins 3.44.0 stable), Dart SDK ^3.7.2 | last commit: 2026-10-25 | source files: 519
ARCH: clean-arch-lite feature-first — features/<f>/{data/{data_sources,models,repositories},presentation/{managers,screens,widgets}}; no domain layer (repos return Either straight to cubits); core/ = base_architecture, services, theme, app_router, utilities
STATE: flutter_bloc cubits (1 Bloc) — BaseSingleStateCubit.handleRequest + BaseSingleClassState{status,failure,success} (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/, 32 cubits) and BaseCubit.handleRequest + BaseState/LoadingState/ErrorState (lib/core/base_architecture/presentation/managers/base_cubit/, 10 cubits); both drop emits after close
DI: get_it (manual, global `diService`) — lib/core/services/di_container.dart (cubits = factory; app-wide AppConfigCubit/NotificationsCubit/DeliveryImagesCubit = lazySingleton)
ROUTING: go_router 16 — lib/core/app_router/app_router.dart + app_routes_names.dart — no auth redirect guard (splash decides; 401 -> SessionService -> go(login)); per-route `_requireExtra<T>` / `_requireIdParam` redirects; StatefulShellRoute.indexedStack tabs; id-in-path detail routes; onException -> home; deep links: none at OS level (push payload routed in-app)
NETWORK: dio — interceptors: InterceptorsWrapper(401 on token-bearing request -> onUnauthorized), TalkerDioLogger (hides Authorization, skips /auth/ bodies) | token refresh: n (401 = sign-out) | retry: n | error mapping: status code -> Failure subclass + 7-shape field-error parser -> ErrorDetail, BaseRepository.handleNetworkCall -> Either | lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/base_architecture/data/repository/base_repo.dart
RESULT_TYPE: Either (dartz) — lib/core/utilities/failures/failure.dart (+ error_details_model.dart); Failure implements Exception, 13 subclasses
STORAGE: shared_preferences + flutter_secure_storage (token); hydrated_bloc storage built in main.dart but no HydratedCubit uses it — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart, keys lib/core/utilities/constants/keys/shared_preferences_keys.dart
L10N: easy_localization — en, ar, zh-Hans, zh-Hant (1029 keys each, parity enforced by tool/check_translations.dart in CI), default+fallback en, assets/translations/*.json, locale registry lib/core/utilities/constants/app_locales.dart — hardcoded UI strings: few (~3)
RTL: Directional=153 vs LeftRight=16 (nearly all symmetric left:0/right:0 or gradient Alignment.topLeft; plus 19 symmetric EdgeInsets.fromLTRB)
THEME: lib/core/theme/light_theme/light_theme.dart (getter, rebuilt per MaterialApp build) — dark mode n (dark_theme.dart empty) | component themes y (appBar, elevated/text/legacy button, input, snackBar, dialog, bottomNav, progress) | AppColors lib/core/utilities/constants/colors.dart | TextThemeLight lib/core/theme/light_theme/light_widget_themes/text_theme.dart | fonts: Roboto used; Alexandria + Cairo bundled but unused
RESPONSIVE: screenutil (design 393x852 phone / 834x1112 tablet, picked by width in main.dart; minTextAdapt, splitScreenMode) + custom helper lib/core/utilities/responsive/responsive.dart (Breakpoints, ContentWidths, context.responsive, ResponsiveLayout) + MaxWidthBody — breakpoints: 600 / 1024 on logical width (explicitly not shortestSide)
TEXT_SCALING: MaterialApp.builder in lib/main.dart — textScaler.clamp(maxScaleFactor: 1.3), no lower bound; display/headline styles additionally clamped to [0.9x, 1.2x] of design size; app-bar title clamped [22, 28]
ENV/FLAVORS: hardcoded constants — lib/core/utilities/constants/keys/api_keys.dart (single {{BASE_URL}}, no flavors / dart-define / dotenv)
LOGGING: talker (talker_flutter + talker_dio_logger, enabled only in kDebugMode, global `talker` in di_container.dart, TalkerRouteObserver) + debugPrint (48) + debug-only AppBlocObserver
ANALYTICS/CRASH: none wired (firebase_crashlytics in pubspec but never imported; no FlutterError.onError)
PUSH: fcm + flutter_local_notifications — lib/core/services/push_notification_service.dart (+ notification_link_handler.dart, notification_permission_gate.dart)
PAYMENTS/IAP: none
PERMISSIONS: permission_handler (openAppSettings only) + FirebaseMessaging.requestPermission; image_picker PlatformException codes mapped to a "open settings" snackbar
DEEP_LINKS: none (no app_links/uni_links); go_router id paths + push-payload resolver lib/core/services/notification_link_handler.dart with pending-link-until-session
MEDIA/FILES: image_picker + flutter_image_compress (tiered compression in ImagePickerService), cached_network_image, flutter_svg, dotted_border, path_provider, skeletonizer (mock model as skeleton data)
TESTS: 30 test files (~220 cases) + test/helpers — layout matrix (phone/narrow/tablet/iPad/Split View x text scale 1.0/1.3/2.0), BaseCubit failure paths, pagination races, API contract parsing, session/401, notification permission, unsaved-changes guard
LINTS: flutter_lints ^6.0.0 default, 0 extra rules (CI: analyze --no-fatal-infos, translation check, tests, debug APK)
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — handleRequest<T>(path, method, parser) + status->Failure + 7-shape validation-error parser — quality 4 — coupling: low (diService<ApiService>, talker, 'errors.*' keys)
- lib/core/utilities/failures/failure.dart (+ error_details_model.dart) — Failure hierarchy with field/general error helpers (fieldError('email')) — quality 4 — coupling: none (TranslationFailure is app-specific, drop it)
- lib/core/utilities/responsive/responsive.dart — Breakpoints, ContentWidths, ScreenType, context.responsive<T>(), ResponsiveLayout — quality 5 — coupling: none
- lib/core/utilities/constants/app_locales.dart — single locale registry: autonyms, script-aware zh-Hans/zh-Hant, directionOf(), acceptLanguage() — quality 5 — coupling: none
- lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart — handleRequest with emit-after-close guard and non-throwing failure fallback — quality 4 — coupling: low (talker)
- lib/core/base_architecture/data/repository/base_repo.dart — handleNetworkCall -> Either, catches everything, logs unexpected — quality 4 — coupling: low
- lib/core/base_architecture/presentation/failure_ui_handler.dart — Failure extension: showSnackBar / showErrorDialog / buildErrorWidget / buildFieldErrorWidgets — quality 4 — coupling: none (hardcoded Colors.*, English default 'Error' title)
- lib/core/services/session_service.dart — single sign-out owner, coalesced concurrent calls, `generation` ValueNotifier that re-keys root BlocProviders — quality 4 — coupling: high (AuthLocalDataSource, NotificationsCubit, PushNotificationService, appRouter)
- lib/core/services/push_notification_service.dart (+ notification_link_handler.dart) — FCM init, iOS APNS polling, foreground banner via local notifications, pending cold-start link opened once a session exists — quality 4 — coupling: high (DeviceTokensRepository, NotificationsCubit, route names)
- lib/core/services/notification_permission_gate.dart — asks for push permission on every app entry, Settings dialog throttled to once/day — quality 4 — coupling: medium (push service, router, prefs)
- lib/features/app_config/presentation/widgets/app_config_gate.dart (+ app_config_cubit.dart, lib/core/services/app_version_service.dart, app_version_comparator.dart) — maintenance / force-update overlay above the router, optional-update sheet, cached config — quality 4 — coupling: medium (feature models)
- lib/core/services/double_parser_service.dart + lib/core/utilities/formatters/decimal_input_formatter.dart — tolerant numeric parsing incl. Arabic-Indic digits and `٫` — quality 5 — coupling: none
- lib/core/utilities/request_generation.dart + lib/core/utilities/widgets/fill_viewport_paging.dart — stale-response tickets, appendUnique, auto-load when first page doesn't fill viewport — quality 5 — coupling: none
- lib/core/services/api_service.dart — Dio wrapper (timeouts, header map, clearToken, 401 hook, log filtering) — quality 3 — coupling: low
- tool/check_translations.dart — CI script: locale key parity, used-but-undefined keys, untranslated Text('literal') — quality 5 — coupling: none (locale list hardcoded)
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/buttons/app_default_button.dart — primary button — text, onTap, isLoading (shrinks to spinner pill, blocks taps), enabled, svgIconPath, child, height/width/radius, colors, border — quality 4 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart — AppIconButton (icon button on AppDefaultButton) + AppBackButton (maybePop) — child, onTap, size, radius, bg, border — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/expandable_fab.dart — speed-dial FAB — fabActions — quality 3 — generic? n (reads BottomNavCubit)
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — labelled text field — title, titleSuffixWidget, controller, hint, validator, forceErrorText, formatters, prefix/suffix, min/maxLines, borderRadius/colors — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password + visibility toggle — controller, isConfirmPassword, confirmPasswordValidator, isLogin — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart — email field — controller, title, hint, forceErrorText — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart — phone + country_picker prefix — controller, selectedCountry, onCountryChanged — quality 3 — generic? partly (hardcoded country filter)
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart — read-only field -> bottom-sheet list — title, hintText, controller, items, validator, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — DynamicDropdownFormField<T> popup menu — options, displayText, onOptionSelected, showSearch, isLoading, initialValue, selectedDisplayText — quality 3 — generic? y
- lib/core/utilities/widgets/forms/form_date_field.dart — date picker field — label, placeholder, date, onPick, firstDate — quality 4 — generic? y
- lib/core/utilities/widgets/forms/form_status_toggle.dart — switch row with hint — title, hint, value, onChanged — quality 4 — generic? y
- lib/core/utilities/widgets/app_bottom_sheet.dart — showAppBottomSheet<T> (width cap 640, scroll-controlled, safe area) — context, builder, isDismissible, backgroundColor, shape — quality 4 — generic? y
- lib/core/utilities/widgets/app_dialog.dart — AppDialog (close btn, title, description, content, action) — title, description, actionTitle, contentWidget, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/dialogs/notification_permission_dialog.dart — permission rationale dialog, static show() -> bool — none — quality 4 — generic? y
- lib/core/utilities/widgets/unsaved_changes_guard.dart — PopScope discard-changes confirm — hasUnsavedChanges, child — quality 4 — generic? y
- lib/core/services/show_loading_dialog.dart — showLoadingDialog — context, message, barrierDismissible — quality 3 — generic? y
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget<B,S,T> (unused) + BaseLoadingWidget + BaseErrorWidget(message,onRetry) + BaseEmptyWidget(message) — quality 3 — generic? y
- lib/core/utilities/widgets/base_list_view_widget.dart — BaseListView<T> with empty state — items, itemBuilder, emptyWidget — quality 2 — generic? y (unused, missing 'no_tasks' key)
- lib/core/utilities/widgets/default_screen.dart — base scaffold: custom header, back button, MaxWidthBody body — body, pageTitle/pageTitleWidget, appbar, hasAppBar, hasBackButton, hasBottomBorder, onBackPressed, FAB, paddings, constrainBodyWidth — quality 3 — generic? y
- lib/core/utilities/widgets/custom_appbar.dart — CustomAppBar (back + title + divider) — pageTitle, actions, hasBackBtn — quality 3 — generic? y
- lib/core/utilities/widgets/max_width_body.dart — MaxWidthBody width cap — child, maxWidthTablet, maxWidthDesktop, alignment — quality 4 — generic? y
- lib/core/utilities/responsive/responsive.dart — ResponsiveLayout (LayoutBuilder per breakpoint) — phone, tablet, desktop — quality 5 — generic? y (unused)
- lib/core/utilities/widgets/container_with_shadow.dart — shadow card — child, margin, padding, radius, size, image, bg, border, onTap, boxShadow — quality 3 — generic? y
- lib/core/utilities/widgets/info_container.dart — nested card — child — quality 2 — generic? y
- lib/core/utilities/widgets/custom_chip.dart — chip/badge — title, colors, radius, padding, onSelect — quality 3 — generic? y
- lib/core/utilities/widgets/selection_chip_widget.dart — selectable chip — isSelected, title, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/custom_radio_group_widget.dart — CustomRadioGroup<T> / CustomSizeRadio<T> — options, selectedValue, onChanged, prefixText, label — quality 3 — generic? y
- lib/core/utilities/widgets/app_divider.dart — divider — height, thickness, color, indent, endIndent, widthFactor — quality 3 — generic? y
- lib/core/utilities/widgets/linear_progress_indicator.dart — LinearPercentIndicator — percent, minHeight — quality 2 — generic? y (unused)
- lib/core/utilities/widgets/animated_indicator.dart — IndicatorWidget step dot — index, currentStep — quality 3 — generic? y (unused)
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart (+ lib/core/services/toast_manager.dart) — overlay toast via ToastManager.showToast / context.showToast — message, state, duration, location, overlay — quality 4 — generic? y
- lib/core/utilities/widgets/toasts/custom_toast.dart — static toast — message, state — quality 2 — generic? y (unused duplicate)
- lib/core/utilities/widgets/shared/widgets/image_Widget.dart — ImageViewerWidget (asset/file/network picked by string prefix, placeholder, remove btn) — image, size, radius/borderRadius, fit, onTap, onTapRemove, stackedWidget, border — quality 3 — generic? y
- lib/core/utilities/widgets/shared/screens/image_viewer.dart — full-screen image (no zoom) — imagePath — quality 3 — generic? y
- lib/core/utilities/widgets/shared/screens/select_location_screen.dart — placeholder stub — none — quality 1 — generic? n
- lib/core/utilities/widgets/image_handelers/image_picker_bottom_sheet.dart — showImagePickerSheet camera/gallery — context, onFilePicked — quality 3 — generic? y
- lib/core/utilities/widgets/image_handelers/image_picker_widget.dart — SingleImagePickerWidget dotted upload box / preview — title, subTitle, imagePath, onPickImage, onRemoveImage, size — quality 3 — generic? y
- lib/core/utilities/widgets/doc_upload_tile.dart — document upload tile — label, file, onChanged, errorText, helperText, source (gallery/camera/ask), showPreview, onRemove — quality 4 — generic? y
- lib/core/utilities/widgets/fill_viewport_paging.dart — FillViewportPaging mixin — pagingController, loadNextPage — quality 5 — generic? y
- lib/features/profile/presentation/widgets/app_language_sheet.dart — showAppLanguageSheet (sets locale + Accept-Language) — context — quality 4 — generic? y (needs ApiService)
- lib/features/app_config/presentation/screens/maintenance_screen.dart + update_screens.dart — MaintenanceScreen, ForceUpdateScreen, OptionalUpdateSheet.show — quality 4 — generic? y (bound to AppConfig models)
NOTABLE_IDEAS: (1) session-keyed root providers: SessionService.generation ValueNotifier -> ValueKey on the root MultiBlocProvider so sign-out recreates per-user cubits (lib/main.dart, lib/core/services/session_service.dart); (2) 7-shape backend validation-error parser + Failure.fieldError() + FailureUIHandler extension (base_remote_data_source.dart, failure.dart, failure_ui_handler.dart); (3) AppConfigGate overlays maintenance/force-update ABOVE the router in MaterialApp.builder so deep links can't bypass it; cached config never gates on its own (lib/features/app_config/); (4) app version/platform headers X-Platform/X-App-Version/X-Build-Number via package_info (app_version_service.dart); (5) pending push link held until a session route is on screen, router-listener retry (push_notification_service.dart); (6) NotificationPermissionGate asks on each entry, Settings dialog throttled 1/day; (7) RequestGeneration + appendUnique + FillViewportPaging for race-safe pagination; (8) copyWith with `_unset` sentinel to clear nullable fields (notifications_state.dart, 12 states); (9) emit() override ignoring post-close emits in both base cubits; (10) theme/text theme as getters so screenutil units survive rotation/Split View; (11) breakpoint-aware screenutil design size; (12) Skeletonizer fed a mock model while loading (product_details_screen.dart); (13) CI translation linter tool/check_translations.dart + tool/create_feature.dart scaffolder; (14) layout test matrix helper test/helpers/pump_app.dart (kLayoutMatrix, useDevice, pumpLocalized); (15) money via context.money() with server currency config (lib/core/extensions/money_context.dart); (16) Talker logger filters /auth/ request/response bodies and hides Authorization. Sibling: lib/core has the same skeleton/file names as Chinaparts/New Projects/customer but 0 of 86 shared files are identical (72 differ by >10 lines); several helpers were re-invented under different names (seller session_service vs customer session_expiry_service, double_parser_service vs double_parser, app_bottom_sheet vs show_app_bottom_sheet, push_notification_service vs notification_service, app_locales vs app_languages) — pick one per concern when merging.
SMELLS: core depends on features (AppCubit -> features/home UserModel; push/session services -> notifications/auth; currency formatter -> app_config models; ExpandableFAB -> BottomNavCubit); service-locator lookups inside base classes and data sources instead of constructor injection; BaseState uses Equatable props [] so same-class states with different payloads compare equal (e.g. two LoginFailure in a row are deduped); BaseSingleClassState.copyWith(failure: null) can't clear failure unless the state uses the sentinel; BaseSingleStateCubit relies on `as S` casts; AuthLocalDataSource extends BaseRemoteDataSource; API endpoints are absolute "$baseUrl/..." strings while Dio also gets baseUrl; LoggingInterceptor registered in DI but never attached; diContainerSetup is async but not awaited; MaterialApp + ScreenUtilInit rebuilt on every AppCubit emit and re-keyed on locale; AppValidator.isNumeric regex ends in literal `\$` (always fails); DynamicDropdownFormField search never refilters an open menu; image_picker_service duplicates 3 compression routines; dead code (AppRoles, LanguageService, SelectionModel, ensureStartsWithZero, BaseSuccessModelWithData, CacheFailure, empty price_converter.dart and dark_theme.dart, fully commented app_router_exports.dart, unused GenericFetchWidget/BaseListView/ResponsiveLayout/CustomToast/IndicatorWidget/LinearPercentIndicator/SelectLocationScreen); unused deps (animate_do, flutter_animate, flutter_rating_bar, flutter_staggered_grid_view, flutter_slidable, flutter_colorpicker, geolocator, google_maps_flutter, firebase_crashlytics, hydrated_bloc storage only); flutter_launcher_icons in dependencies not dev_dependencies; ~3 MB of unused Alexandria/Cairo fonts plus 8.7 MB Roboto folder (all of assets/fonts/ is also globbed as a raw asset; weight 100 mapped to ExtraLight); folder naming drift (data/repo vs data/repositories, data/model vs models, home/presentation/home_cubit vs managers, image_handelers, image_Widget.dart, phone_handeler_service.dart); absurd relative imports ('../../../../../../../../../../../../core/...'); 165 raw Colors.* and 71 Color(0x..) outside AppColors; FailureUIHandler/AppDefaultButton etc. hardcode colors; reels/messages placeholder screens in bottom_nav_screen.dart; mock product data in lib/features/products/data/mocks; 2 hardcoded English labels in reserve_entry_card.dart; no crash reporting despite the dependency. No WillPopScope / textScaleFactor / MaterialStateProperty / withOpacity found (uses withValues, PopScope).
```

---

## 1. Architecture pattern

Feature-first "clean architecture lite", two layers per feature:

- **data/**: `data_sources/` (remote classes extending `BaseRemoteDataSource`, plus the odd local data source), `models/` (hand-written `fromJson`/`toJson`, often split into `requests/` and `responses/`), `repositories/` (extending `BaseRepository`, returning `Future<Either<Failure, T>>`).
- **presentation/**: `managers/<name>_cubit/{x_cubit.dart, x_state.dart}` (state as a `part` file), `screens/`, `widgets/` (sub-grouped per screen when large).
- There is **no domain layer**: no use cases and no entity/model split. Cubits call repositories directly.

Data flow: Screen -> Cubit (`handleRequest`) -> Repository (`handleNetworkCall` -> Either) -> RemoteDataSource (`handleRequest(path, method, parser)`) -> `ApiService` (Dio).

Two state styles live side by side:
1. **Single-class state** (`BaseSingleClassState` with `status` / `failure` / `success`). 32 cubits use it, often with feature fields and a `_unset` sentinel `copyWith`.
2. **Sealed class-per-state** (`BaseState` subclasses such as `LoginLoading` and `LoginFailure`). 10 cubits use it.

The project ships `tool/create_feature.dart`, which scaffolds a feature skeleton (note: it creates `data/repo`, while most features use `data/repositories`).

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                      — bootstrap: Firebase, prefs, easy_localization, HydratedStorage, DI, version headers, push init, root providers, MaterialApp.router builder (text-scale cap, Directionality, gates)
├── firebase_options.dart          — (exists; not opened)
├── core/
│   ├── app_cubit/                 — AppCubit/AppState: global user + token (BaseSingleClassState)
│   ├── app_router/                — app_router.dart (GoRouter, rootNavigatorKey, redirect helpers), app_routes_names.dart, app_router_exports.dart (all commented out)
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/      — base_remote_data_source.dart (request + error parsing)
│   │   │   ├── models/            — base_request_model/network_request_model.dart, base_response_model/base_success_response.dart (+ PaginationModel, parseList), base_success_model.dart
│   │   │   └── repository/        — base_repo.dart (handleNetworkCall -> Either)
│   │   └── presentation/
│   │       ├── failure_ui_handler.dart — Failure -> snackbar/dialog/widget extension
│   │       └── managers/
│   │           ├── base_cubit/                    — BaseCubit + BaseState/LoadingState/ErrorState
│   │           └── base_single_class_state_bloc/  — BaseSingleStateCubit + BaseSingleClassState
│   ├── enums/                     — AppRoles (unused), FetchDataStatusEnum, HttpMethod, ToastState
│   ├── exports/core_exports.dart  — barrel: material, go_router, easy_localization, screenutil, AppColors, DefaultScreen, responsive, MaxWidthBody, showAppBottomSheet
│   ├── extensions/                — context_extensions (theme/textTheme/isAr), list_extensions (isNullOrEmpty), money_context (context.money())
│   ├── models/selection_model.dart — unused
│   ├── services/                  — api_service, di_container, session_service, push_notification_service, notification_link_handler, notification_permission_gate, app_version_service/comparator, secure_storage_manager, shared_preferences_manager, toast_manager, image_picker_service, app_validator, currency_formatter_service, double_parser_service, debounce, url_handler, bloc_observer, logging_interceptors (unused), show_loading_dialog, language_flags_service (unused), phone_handeler_service (unused)
│   ├── theme/
│   │   ├── dark_theme/dark_theme.dart — empty
│   │   └── light_theme/           — light_theme.dart (getter) + light_widget_themes/ (app_bar, bottom_nav, btn_txt, dialog, elevated_btn, input_decoration, light_color_scheme, snack_bar, text_theme)
│   └── utilities/
│       ├── constants/             — app_locales, colors, constant_lists, icons (AppIcons.svg helper), images, temp_images, keys/{api_keys, shared_preferences_keys}
│       ├── converters/price_converter.dart — empty
│       ├── failures/              — failure.dart, error_details_model.dart
│       ├── formatters/            — date_formatter, decimal_input_formatter
│       ├── responsive/responsive.dart
│       ├── request_generation.dart — RequestGeneration + appendUnique
│       └── widgets/               — shared widgets (see catalog): buttons/, dialogs/, forms/, image_handelers/, shared/{screens,widgets}/, text_form_fields/, toasts/, plus top-level widgets
└── features/                      — 19 features
    ├── app_config/      — maintenance / force & optional update / currency config gate
    ├── auth/            — login, multi-step register (5 steps)
    ├── bottom_nav/      — tab shell + custom painted bar (+ placeholder Reels/Messages screens)
    ├── chat/            — conversations, FCM-topic live gateway, on-device ML Kit translation
    ├── coupons/, offers/ — list/stats/form CRUD
    ├── home/            — dashboard (home_cubit lives at presentation/home_cubit/)
    ├── legal/, support/ — policies; support tickets
    ├── notifications/   — in-app list + device tokens
    ├── orders/, returns/ — orders, delivery-proof images, returns
    ├── products/        — largest (77 files): list, details, 4-step add/edit Bloc, reviews, vehicle attributes, mocks
    ├── profile/, shop/, shipping_origin/, wallet/, reports/ (custom-painted charts), splash/ (splash + onboarding)
```

Representative feature, fully expanded (`notifications`):

```
features/notifications/
├── data/
│   ├── data_sources/
│   │   ├── notifications_remote_data_source.dart   — list (paged, BaseSuccessResponse w/ meta), unread count (tolerant parse), mark read / read-all
│   │   └── device_tokens_remote_data_source.dart   — FCM token register/remove
│   ├── models/notification_model.dart              — hand-written fromJson/copyWith
│   └── repositories/
│       ├── notifications_repo.dart                 — handleNetworkCall wrappers -> Either
│       └── device_tokens_repo.dart
└── presentation/
    ├── managers/notifications_cubit/
    │   ├── notifications_cubit.dart   — app-wide lazySingleton; page load with RequestGeneration + session counter, optimistic mark-read with per-row rollback
    │   └── notifications_state.dart   — BaseSingleClassState + `_unset` sentinel copyWith, canLoadMore, preview
    ├── screens/notifications_screen.dart — uses FillViewportPaging mixin, Skeletonizer
    └── widgets/notification_card.dart
```

## 3. Infrastructure

### State management
- `flutter_bloc ^9.1.1`, `equatable`. Cubits almost everywhere. The one Bloc is `AddEditProductBloc` (multi-step form events).
- `BaseSingleStateCubit<S extends BaseSingleClassState>` (`lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart`): `handleRequest({call, onNotDefaultSuccess, onNotDefaultFailure, onNotDefaultLoading})`. By default it emits `status: loading/success/failure`, stores `success` as a `BaseSuccessModel` and catches unexpected errors into `UnknownFailure('errors.unexpected'.tr())`. It overrides `emit` to ignore emits after close. Weakness: everything goes through `state.copyWith(...) as S`, and `copyWith(failure: null)` only clears the failure when the concrete state uses a sentinel (12 states do).
- `BaseCubit<S extends BaseState>` (`.../base_cubit/base_cubit.dart`): `handleRequest({loadingState, call, onSuccess, onError, showLoading})`. It awaits `fold` so async callbacks are covered. When no `onError` is given it falls back to `ErrorState` and type-checks it (`if (fallback is S)`) rather than casting, which avoids a stuck spinner when the state is sealed. Well commented and the most robust of the two.
- `BaseState` is `Equatable` with `props => []`. Subclasses rarely override it, so two consecutive same-type states with different payloads are deduped by bloc.
- `AppBlocObserver` (`lib/core/services/bloc_observer.dart`) is installed only in `kDebugMode`.
- Provider scoping: `AppCubit` and `AppConfigCubit` sit above `MaterialApp`. Per-session cubits (BottomNav, Profile, Wallet, Transactions, Reserves, Notifications) sit in a `MultiBlocProvider` keyed on `SessionService.generation`. Feature cubits are provided per route in `app_router.dart`.
- `hydrated_bloc` storage is initialized in `main.dart`, but no cubit extends `HydratedCubit`, so it is dead weight.

### DI
- `get_it ^9.0.5`, manual registration in `lib/core/services/di_container.dart` (566 lines, about 100 imports). Global `diService = GetIt.instance` and global `talker`.
- Sections: `_initExternalServices`, `_initDioAndRemoteDataSource`, `_initRepo`, `_initBlocs`, `_initCubits`. Data sources, repos and services are lazySingletons. Cubits are factories, except `NotificationsCubit`, `AppConfigCubit` and `DeliveryImagesCubit`, which are lazySingletons, each with a comment explaining why.
- `ApiService.onUnauthorized` is wired lazily (`() => diService<SessionService>().onUnauthorized()`) to break a circular dependency.
- Smells: the functions are `async` without awaits and `diContainerSetup()` is not awaited in `main`. Base classes and data sources call `diService<...>()` internally (service locator), so they are hard to unit test without GetIt.

### Routing
- `go_router ^16.3.0`, one global `appRouter` in `lib/core/app_router/app_router.dart` (793 lines), with `rootNavigatorKey` exported so gates mounted above the Router can show dialogs.
- **No global auth `redirect` / `refreshListenable`.** The splash screen reads the token and routes to login or home. Expired sessions come through the Dio 401 hook, which calls `SessionService.onUnauthorized()`, which signs out, calls `appRouter.go(login)` and shows a toast.
- Route-level guards:
  - `_requireExtra<T>(fallback)` redirects when `state.extra` is not a `T`. This covers process restore and deep links that carry no extra.
  - `_requireIdParam(fallback)` redirects when the `:id` path param is not an int.
- Detail routes carry the id in the path (`AppRoutesNames.orderDetailsOf(id)` → `/order_details/42`).
- `StatefulShellRoute.indexedStack` drives the 5 bottom tabs (state is kept per tab). Extra `ShellRoute`s exist only to share providers (products and wallet).
- `onException: (_, __, router) => router.go(home)` and `observers: [TalkerRouteObserver(talker)]`.
- Change-password and change-email flows use nested `GoRoute`s whose paths start with `/`. The full path is built by string concatenation (`changePassword + forgotPassword`), which is fragile.

### Networking
- `dio ^5.7.0`. `lib/core/services/api_service.dart` implements `ApiServiceBase` with `get/post/put/patch/delete(NetworkRequestParams)`, `updateHeaders({token, customHeaders})` (a null value removes the header) and `clearToken()`.
- Timeouts: connect 30 s, receive 30 s, send 60 s (for document uploads).
- `Content-Type: application/json` is fixed; Dio switches to multipart for `FormData`. The comments explain earlier races caused by toggling it.
- Interceptors:
  1. `InterceptorsWrapper.onError` calls `onUnauthorized` on a 401, only if the request carried an `Authorization` header and is not an `/auth/` path.
  2. `TalkerDioLogger` with `hiddenHeaders: {'Authorization'}` and request/response/error filters that skip `/auth/` paths, so passwords, ID documents and tokens are never logged.
- **No retry, no token refresh** (a 401 signs the user out).
- Error mapping lives in `lib/core/base_architecture/data/data_sources/base_remote_data_source.dart`:
  - `DioExceptionType` maps to `TimeoutFailure` / `NetworkFailure` / `ServerFailure` / `UnknownFailure`, with localized messages.
  - Status codes map to failures: 400 BadRequest, 401 Unauthorized, 403 Forbidden, 404 NotFound, 409 Conflict, 422 Validation, 429 TooManyRequests, 5xx Server.
  - The message is taken from `message|detail|error|msg`.
  - Field errors are parsed from 7 shapes (DRF/Laravel `errors` map, top-level field map, string list, `non_field_errors`, string, `detail` list, nested `data.errors`) into `List<ErrorDetail>`.
  - Parser exceptions are logged and become `UnknownFailure('errors.unexpected')`.
- `BaseRepository.handleNetworkCall` converts everything into `Either`.
- Response envelope: `BaseSuccessResponse<T>.fromJson(json, fromJsonT)` with `success`, `message`, `data` and `meta` → `PaginationModel` (`current_page/per_page/total/last_page`, mutable), plus `parseList` helper.
- Endpoints live in `lib/core/utilities/constants/keys/api_keys.dart` as absolute `"$baseUrl/..."` strings, even though Dio already has `baseUrl` set.
- `ApiService._executeRequest` catches `SocketException` and `FormatException` only to rethrow the same type with a new message, which adds nothing.
- `logging_interceptors.dart` (a debugPrint interceptor) is registered in DI but never attached.

### Local storage
- `SharedPreferencesManager` (`lib/core/services/shared_preferences_manager.dart`) is a singleton wrapper with `init()`, a dynamic `setValue` (String/int/bool/double/List<String>), `getValue`, `remove` and `clear`. Untyped API.
- `SecureStorageManager` (`lib/core/services/secure_storage_manager.dart`) wraps `FlutterSecureStorage` with `write/read/delete/clearAll/containsKey`. The `try { } catch { rethrow }` blocks are no-ops.
- Keys are in `SharedPreferencesKeys`. The token is stored in secure storage under the `token` key. Phone, phone code and email go to prefs for the login prefill. The password is explicitly no longer stored (`clearUserPassword()` purges it from older builds).
- The splash clears secure storage on an iOS reinstall (first-launch flag in prefs plus a leftover keychain token). This is a good pattern.
- AppConfig JSON is cached in prefs and hydrated before the first network call.

### Localization (+RTL)
- `easy_localization ^3.0.7`, nested JSON files in `assets/translations/` for `en`, `ar`, `zh-Hans` and `zh-Hant`, 1029 keys each, with parity checked in CI. Start and fallback locale are `en`; the saved locale is restored by easy_localization.
- `AppLocales` (`lib/core/utilities/constants/app_locales.dart`) is the single registry:
  - `AppLocale{locale, nameKey, nativeName}`.
  - Script-aware `byLocale`, so `zh-Hans` and `zh-Hant` stay separate.
  - `rtlLanguageCodes` covers ar, fa, he, ur, ps, sd, ug and yi.
  - `directionOf(locale)` is used in `MaterialApp.builder`.
  - `acceptLanguage(locale)` returns `zh-Hant`, not plain `zh`.
- The `Accept-Language` header is set on splash and again when the user switches language (`showAppLanguageSheet`).
- `tool/check_translations.dart` fails CI on missing keys, `.tr()` keys used but not defined, and `Text('literal')` without `.tr()`. As a result only about 3 hardcoded English strings remain (`reserve_entry_card.dart`, the `select_location_screen.dart` stub).
- RTL discipline is strong: 153 directional usages against 16 left/right usages, nearly all symmetric. CLAUDE.md codifies the rule.
- `context.isAr` exists in `context_extensions.dart`.

### Theming
- `lightTheme` is a **getter** (`lib/core/theme/light_theme/light_theme.dart`), as are the sub-themes that use screenutil (`appBarTheme`, `elevatedBtnTheme`, `btnTheme`, `textBtnTheme`, `inputDecorationTheme`). `TextThemeLight.instance` returns a fresh instance each time. All of this is so `.sp`, `.h` and `.r` values are recomputed on rotation or Split View.
- `useMaterial3: true`, `ColorScheme.fromSeed(primary)`.
- Component themes: appBar, bottomNav (not used by the custom bar), text button, elevated button (`minimumSize: Size(0, 52.h)` rather than a fixed size), legacy buttonTheme, input decoration (filled, outline borders, min height 52.h), snackBar, dialog, progress indicator.
- `TextThemeLight`: Roboto, height 1.2 (to avoid clipping Arabic). Body, label and title styles use `.sp`; display and headline styles are clamped to [0.9x, 1.2x] by `_capped()`.
- `AppColors` (`lib/core/utilities/constants/colors.dart`): a flat palette (primary orange, red0..12, secondary0..10, neutral100..1000, grey…). The names are not semantic (`secondary6` is the text color).
- **No dark mode**: `dark_theme.dart` is empty and the status-bar style is hardcoded dark.
- Alexandria (1.8 MB) and Cairo (1.1 MB) font families are declared and bundled but never referenced; Roboto is 8.7 MB.
- Widgets still hardcode many colors: 165 raw `Colors.*` and 71 `Color(0x..)` outside `colors.dart`.

### Responsive helpers
- `flutter_screenutil ^5.9.3`. `ScreenUtilInit` in `main.dart` picks `designSize` by width: under 600 → 393×852, otherwise 834×1112. `minTextAdapt: true`, `splitScreenMode: true`.
- `lib/core/utilities/responsive/responsive.dart`:
  - `Breakpoints.tablet = 600` and `desktop = 1024` (logical width).
  - `ContentWidths` (form 600, dialog 560, sheet 640, wide 1200).
  - `ScreenType` with `deviceTypeForWidth`.
  - `context.screenWidth/deviceType/isPhone/isTablet/isLargeScreen/responsive<T>(phone:, tablet:, desktop:)`.
  - `ResponsiveLayout`, built on LayoutBuilder (defined but unused).
- `MaxWidthBody` (`lib/core/utilities/widgets/max_width_body.dart`) is applied automatically by `DefaultScreen` (`constrainBodyWidth`).
- `showAppBottomSheet` caps sheet width. `AppDialog` and `NotificationPermissionDialog` cap dialog width.
- CLAUDE.md sets the rules: never branch on `Platform` or `shortestSide`, don't put `.h` fixed heights around text, and let buttons grow with their text.

### Text scaling
`MaterialApp.builder` in `lib/main.dart` applies `MediaQuery.copyWith(textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3))`. There is no minimum. The scale is applied once, app-wide, and never per screen. Large typography is additionally capped in `text_theme.dart` (`_capped`), and the app-bar title is clamped to `24.sp.clamp(22, 28)`. Layout tests check scales 1.3 and 2.0.

### Env / flavors
None. A single hardcoded `ApiKeys.baseUrl` / `baseImageUrl` ({{BASE_URL}}) in `lib/core/utilities/constants/keys/api_keys.dart`, with no `--dart-define`, `.env` or Android/iOS flavors. `ApiKeys.appName` and `appVersion` are hardcoded (the real version comes from `AppVersionService`).

### Logging
- `talker_flutter ^5.0.2` with `Talker(settings: TalkerSettings(enabled: kDebugMode))`, a global in `di_container.dart`. It is used by the base cubits and repository (`talker.handle/info/error`), `TalkerDioLogger` and `TalkerRouteObserver`.
- There are also 48 `debugPrint` calls (push service, image picker, splash) and the emoji-heavy `AppBlocObserver` (debug only).
- There is no in-app Talker screen.

### Analytics / crash reporting
None. `firebase_crashlytics ^5.0.7` is a dependency but is never imported, and there is no `FlutterError.onError`, `PlatformDispatcher.onError` or `runZonedGuarded`.

### Push notifications
`firebase_messaging ^16.1.1` + `flutter_local_notifications ^19.5.0`. `lib/core/services/push_notification_service.dart` (lazySingleton):
- `firebaseMessagingBackgroundHandler` (`@pragma('vm:entry-point')`) is registered before `runApp`.
- `init()` creates the Android channel `high_importance_channel`, suppresses iOS foreground alerts (to avoid double banners), shows its own local notification on `onMessage` (skipping the conversation currently on screen), routes `onMessageOpenedApp` and the cold-start `getInitialMessage` through a `_pendingLink` that is opened only once a token exists and the route is not splash, login or register (it retries on every router change), and re-registers on `onTokenRefresh` only when signed in.
- `registerToken()` is bounded by a 10 s timeout and never throws. On iOS it calls `requestPermission` first and polls for the APNS token for up to 2.5 s.
- `unregisterToken()` and `deleteDeviceToken()` (which also drops FCM topic subscriptions) are called on sign-out.
- The payload map is flattened to a query string for the local-notification payload.

`lib/core/services/notification_link_handler.dart` routes notification taps:
- `handleNotificationLink({notificationType, linkType, linkValue, data, fromPush})` handles ticket, order/sub_order, chat, return, product, coupon, offer, wallet and url (https only).
- It tries multiple id keys and degrades to a list or fallback screen when an id is missing. Push opens use `go` for tab roots and `push` for everything else.

`lib/core/services/notification_permission_gate.dart` is a widget above the Router:
- It asks for permission on cold start and on every resume, but not over the splash.
- When the permission was denied, it shows `NotificationPermissionDialog`, offering to open Settings, at most once a day and only to signed-in users.
- When granted, it registers the token.

Chat live updates use `FcmConversationLiveGateway` (FCM topic per conversation, `features/chat/data/services/conversation_live_gateway.dart`).

### IAP / payments
None.

### Permissions
`permission_handler ^12.0.1` is used only for `openAppSettings()`. The OS prompts come from `FirebaseMessaging.requestPermission` and from image_picker. `ImagePickerService._reportFailure` maps `camera_access_denied` and `photo_access_denied` to a snackbar with an "open settings" action. There are no location permission flows, even though geolocator and google_maps_flutter are dependencies (unused).

### Deep links
There is no OS-level deep linking (no app_links or uni_links, and no intent filters were checked into lib). The router is deep-link-friendly: ids are in the path, and `_requireExtra` / `_requireIdParam` provide fallbacks. Push payloads are routed by `notification_link_handler.dart`.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/services/api_service.dart | Dio wrapper (`ApiServiceBase` / `ApiService`) | get/post/put/patch/delete(NetworkRequestParams), updateHeaders({token, customHeaders}), clearToken(), hasToken, onUnauthorized | dio, talker_dio_logger, talker | generic |
| lib/core/services/di_container.dart | get_it registrations, global `diService` + `talker` | diContainerSetup() | every feature | app-specific (pattern generic) |
| lib/core/services/session_service.dart | single sign-out owner | generation (ValueNotifier<int>), signOut({unregisterPush}), onUnauthorized() | push service, AuthLocalDataSource, ApiService, NotificationsCubit, AppCubit, appRouter, ToastManager | pattern generic, wiring app-specific |
| lib/core/services/push_notification_service.dart | FCM + local notifications | firebaseMessagingBackgroundHandler, init(), isRegistered, authorizationStatus(), requestSystemPermission(), registerToken(), unregisterToken(), deleteDeviceToken(), clearPendingLink(), forgetRegisteredToken(), activeConversationId | firebase_messaging, flutter_local_notifications, DeviceTokensRepository, NotificationsCubit, appRouter | mostly generic |
| lib/core/services/notification_link_handler.dart | push / in-app notification → route | handleNotificationLink({notificationType, linkType, linkValue, data, fromPush}) | appRouter, AppRoutesNames, UrlHandler | app-specific (pattern generic) |
| lib/core/services/notification_permission_gate.dart | NotificationPermissionGate widget | widget(child) | push service, ApiService, prefs, router, permission_handler | generic-ish |
| lib/core/services/app_version_service.dart | package_info + version headers | load(), applyHeaders(), version, buildNumber, platform, isLoaded | package_info_plus, ApiService | generic |
| lib/core/services/app_version_comparator.dart | dotted-version compare, null when unsure | static compare(a, b) | none | generic |
| lib/core/services/secure_storage_manager.dart | secure storage wrapper | write, read, delete, clearAll, containsKey | flutter_secure_storage | generic |
| lib/core/services/shared_preferences_manager.dart | prefs singleton | init, setValue, getValue, remove, clear | shared_preferences | generic (untyped) |
| lib/core/services/toast_manager.dart | overlay toast, single instance, timer-safe | static showToast({context or overlay, message, state, location, duration}); `context.showToast(...)` extension | AnimatedCustomToast | generic |
| lib/core/services/image_picker_service.dart | pick + tiered JPEG compression | pickImage, pickMultipleImages({limit}), pickVideo, getImageSizeKB, getFormattedImageSize | image_picker, flutter_image_compress, path_provider, permission_handler | generic |
| lib/core/services/app_validator.dart | form validators | isNotEmpty, isValidEmail, isValidPhone, isValidSaudiPhone, isValidPassword(value, isLogin), confirmPassword, isNumeric (buggy regex), isNotEmptyImage, ibanValidator (mod-97), nationalIdNumber, validateUpload({file, allowedExtensions}), fileExtension, customValidator | easy_localization | mostly generic |
| lib/core/services/currency_formatter_service.dart | money formatting from server config | format, formatNumber, label, fallbackCurrency, nullPlaceholder | CurrencyConfigModel (feature) | generic after decoupling |
| lib/core/services/double_parser_service.dart | tolerant number parsing | parse(value, fallback), parseOrNull, parseUserInput (Arabic-Indic digits, `٫`, comma) | none | generic |
| lib/core/services/debounce.dart | timer debounce | run(action), cancel() | none | generic |
| lib/core/services/url_handler.dart | url_launcher wrapper that throws on failure | static openUrl(url) | url_launcher | generic |
| lib/core/services/bloc_observer.dart | debug bloc logging | AppBlocObserver | flutter_bloc | generic |
| lib/core/services/logging_interceptors.dart | debugPrint Dio interceptor (unused) | LoggingInterceptor | dio | generic, dead |
| lib/core/services/show_loading_dialog.dart | blocking loader dialog | showLoadingDialog({context, message, barrierDismissible}) | material | generic |
| lib/core/services/language_flags_service.dart | locale → flag emoji (unused) | LanguageService.getFlagEmoji | none | generic, dead |
| lib/core/services/phone_handeler_service.dart | prefix a leading 0 (unused) | ensureStartsWithZero | none | dead |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | request + error mapping | handleRequest<T>({path, method, parser, data, queryParameters}) | ApiService, talker, easy_localization | generic |
| lib/core/base_architecture/data/repository/base_repo.dart | Either conversion | handleNetworkCall<T>({call}) | dartz, talker | generic |
| lib/core/base_architecture/data/models/base_response_model/base_success_response.dart | envelope + pagination | BaseSuccessResponse.fromJson(json, fromJsonT), parseList, PaginationModel | none | generic (API-shape specific) |
| lib/core/base_architecture/data/models/base_request_model/network_request_model.dart | request params | NetworkRequestParams{uri, data, queryParameters, options, cancelToken, progress callbacks} | dio | generic |
| lib/core/base_architecture/data/models/base_success_model.dart | Equatable base for success payloads | BaseSuccessModel, BaseSuccessModelWithData<T> (unused) | equatable | generic |
| lib/core/base_architecture/presentation/failure_ui_handler.dart | Failure → UI | showSnackBar, showErrorDialog({title, onRetry}), buildErrorWidget({onRetry}), buildFieldErrorWidgets, showSnackBarIfPresent | material, easy_localization | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/* | BaseCubit / BaseState / LoadingState / ErrorState | handleRequest({loadingState, call, onSuccess, onError, showLoading}) | flutter_bloc, dartz, talker | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/* | BaseSingleStateCubit / BaseSingleClassState | handleRequest({call, onNotDefaultSuccess, onNotDefaultFailure, onNotDefaultLoading}), copyWith contract | flutter_bloc, dartz | generic |
| lib/core/utilities/failures/failure.dart, error_details_model.dart | failure hierarchy | Failure{message, code, errors, hasErrors, fieldErrors, generalErrors, allMessages, joinedMessages, fieldError(name)}, ErrorDetail.fromDynamic/general | none | generic |
| lib/core/utilities/request_generation.dart | stale-response guard + dedupe | RequestGeneration.next/current/isCurrent, appendUnique(existing, incoming, idOf) | none | generic |
| lib/core/utilities/responsive/responsive.dart | breakpoints | Breakpoints, ContentWidths, ScreenType, deviceTypeForWidth, ResponsiveContext ext, ResponsiveLayout | material | generic |
| lib/core/utilities/constants/app_locales.dart | locale registry | AppLocale, AppLocales.supported/locales/fallback/byLocale/nativeNameOf/rtlLanguageCodes/acceptLanguage/directionOf | widgets | generic |
| lib/core/utilities/formatters/date_formatter.dart | date formatting | formatDateString (returns English 'Invalid date or format' on error), formatDate(date, fmt, locale), isMorning | intl | generic |
| lib/core/utilities/formatters/decimal_input_formatter.dart | numeric TextInputFormatter | DecimalInputFormatter({decimal}) | services | generic |
| lib/core/utilities/constants/icons.dart / images.dart / temp_images.dart | asset paths + AppIcons.svg (asset or network SVG) / AppImages.image | static consts, svg(), image() | flutter_svg, ApiKeys | app-specific (helper generic) |
| lib/core/utilities/constants/constant_lists.dart | onboarding slides, quick links | getters | features | app-specific |
| lib/core/utilities/constants/keys/api_keys.dart, shared_preferences_keys.dart | endpoints / pref keys | consts | none | app-specific |
| lib/core/extensions/context_extensions.dart | theme / textTheme / colorScheme / isAr | getters | material | generic |
| lib/core/extensions/list_extensions.dart | isNullOrEmpty() on List? | method | none | generic |
| lib/core/extensions/money_context.dart | context.money / moneyNumber / currencyLabel | getters | AppConfigCubit, CurrencyFormatterService | app-specific (pattern generic) |
| lib/core/app_cubit/app_cubit.dart | global user/token | setUser, setToken, clear | home UserModel | app-specific |
| lib/features/app_config/... (cubit + gate) | maintenance / force-update / optional update / currency | getAppConfig, refreshIfStale, dismissUpdate; AppConfigGate | prefs, AppVersionService | generic-ish module |
| tool/check_translations.dart, tool/create_feature.dart, tool/copy_feature.dart | CI translation lint; feature scaffold; clone a feature with name replacement (hardcoded paths) | CLI | dart:io | generic |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/buttons/app_default_button.dart | primary button; while loading it shrinks to a 48 px spinner pill and ignores taps; without `height` it sizes from padding so it grows with text | onTap, text, textStyle, child, height, width, radius, margin, padding, isLoading, backgroundColor, textColor, enabled, svgIconPath, borderColor, borderWidth | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart | AppIconButton (square icon button built on AppDefaultButton); AppBackButton (uses `Navigator.maybePop` so PopScope is respected) | child, onTap, height, width, radius, backgroundColor, padding, borderColor, borderWidth / onTap | y |
| lib/core/utilities/widgets/buttons/expandable_fab.dart | speed-dial FAB with FabAction | fabActions | n (BottomNavCubit) |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart | labelled TextFormField, unfocus on tap outside, errorMaxLines 3; re-declares borders already in the theme | title, titleSuffixWidget, controller, hintText, onTap, onChanged, enabled, readOnly, obscureText, keyboardType, validator, forceErrorText, inputFormatters, icon, prefixIcon, suffixIcon, titleStyle, textStyle, hintTextStyle, maxLength, maxLines, minLines, prefix/suffixIconConstraints, focusNode, textAlign, onSaved, onFieldSubmitted, onEditingComplete, borderRadius, backgroundColor, borderColor | y |
| lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart | password field with eye toggle and validator | controller, isConfirmPassword, confirmPasswordValidator, title, hintText, isLogin, forceErrorText, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart | email field | controller, title, hintText, readOnly, forceErrorText, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart | phone field with country_picker dial-code prefix (countryFilter hardcoded) | controller, selectedCountry, onCountryChanged, title, hintText, readOnly, forceErrorText, onChanged | partly |
| lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart | read-only field that opens a bottom sheet of strings | title, svgPrefixIconPath, hintText, controller, items, validator, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart | generic `showMenu` dropdown; the search field does not refilter an open menu; isNotEmpty validator is forced on | options, displayText, title, svgPrefixIconPath, onOptionSelected, hintText, showSearch, enabled, isLoading, initialValue, selectedDisplayText | y |
| lib/core/utilities/widgets/forms/form_date_field.dart | labelled date picker | label, placeholder, date, onPick, firstDate | y |
| lib/core/utilities/widgets/forms/form_status_toggle.dart | switch row | title, hint, value, onChanged | y |
| lib/core/utilities/widgets/app_bottom_sheet.dart | `showAppBottomSheet<T>`: max width 640, isScrollControlled, useSafeArea, rounded top | context, builder, isScrollControlled, isDismissible, backgroundColor, shape | y |
| lib/core/utilities/widgets/app_dialog.dart | dialog with close button, title, description, content and one action (max width 560) | title, description, actionTitle, contentWidget, onTap | y |
| lib/core/utilities/widgets/dialogs/notification_permission_dialog.dart | "notifications are off, open Settings?" dialog; `static show()` returns bool | — | y |
| lib/core/utilities/widgets/unsaved_changes_guard.dart | PopScope + discard confirm dialog | hasUnsavedChanges, child | y |
| lib/core/services/show_loading_dialog.dart | blocking loading dialog | context, message, barrierDismissible | y |
| lib/core/utilities/widgets/base_fetching_widget.dart | GenericFetchWidget<B,S,T> (status switch, unused); BaseLoadingWidget; BaseErrorWidget; BaseEmptyWidget | successBuilder, loadingWidget, failureWidget, onRetry / — / message, onRetry / message | y |
| lib/core/utilities/widgets/base_list_view_widget.dart | ListView.separated with empty text (`'no_tasks'` key is missing; unused) | items, itemBuilder, emptyWidget | y |
| lib/core/utilities/widgets/default_screen.dart | base scaffold: manual top/bottom safe padding, header row (AppBackButton + title), MaxWidthBody body | body, backgroundColor, appBarPadding, bodyPadding, topMargin, appbar, floatingActionButton(+Location), pageTitle, pageTitleWidget, hasAppBar, hasBottomBorder, hasBackButton, hasBottomMargin, constrainBodyWidth, onBackPressed | y |
| lib/core/utilities/widgets/custom_appbar.dart | `PreferredSize` AppBar with back button, title and divider (`Navigator.pop`, not maybePop) | pageTitle, actions, hasBackBtn, preferredSize | y |
| lib/core/utilities/widgets/max_width_body.dart | width cap on tablet/desktop | child, maxWidthTablet (600), maxWidthDesktop (720), alignment | y |
| lib/core/utilities/responsive/responsive.dart → ResponsiveLayout | per-breakpoint builder (unused) | phone, tablet, desktop | y |
| lib/core/utilities/widgets/container_with_shadow.dart | card with border and shadow (InkWell) | child, margin, padding, radius, width, height, image, backgroundColor, border, onTap, boxShadow, shadowBlurRadius | y |
| lib/core/utilities/widgets/info_container.dart | grey outer card with white inner card | child | y |
| lib/core/utilities/widgets/custom_chip.dart | pill chip | title, titleStyle, bgColor, borderColor, txtColor, height, width, radius, fontSize, padding, onSelect | y |
| lib/core/utilities/widgets/selection_chip_widget.dart | selectable chip (minHeight, not fixed) | isSelected, title, onTap | y |
| lib/core/utilities/widgets/custom_radio_group_widget.dart | CustomRadioGroup<T>, CustomSizeRadio<T> (animated radio) | options, selectedValue, onChanged, prefixText, label | y |
| lib/core/utilities/widgets/app_divider.dart | Divider with defaults | height, thickness, color, indent, endIndent, widthFactor | y |
| lib/core/utilities/widgets/linear_progress_indicator.dart | LinearPercentIndicator (unused) | percent, minHeight | y |
| lib/core/utilities/widgets/animated_indicator.dart | IndicatorWidget step dot (unused) | index, currentStep | y |
| lib/core/utilities/widgets/toasts/animated_custom_toast.dart | animated overlay toast (success/failure/warning) | message, state, duration, location | y |
| lib/core/utilities/widgets/toasts/custom_toast.dart | static toast (unused duplicate) | message, state, duration | y |
| lib/core/utilities/widgets/shared/widgets/image_Widget.dart | ImageViewerWidget: asset/file/network by string prefix (`/`, `assets`, else network), CachedNetworkImage with progress/error, delete button; `hasDownloadBtn` does nothing; uses Clip.antiAliasWithSaveLayer | image, width, height, margin, onTap, onTapRemove, hasDownloadBtn, stackedWidget, radius, borderRadius, fit, color, border | y |
| lib/core/utilities/widgets/shared/screens/image_viewer.dart | full-screen black image viewer (no zoom) | imagePath | y |
| lib/core/utilities/widgets/shared/screens/select_location_screen.dart | stub screen with hardcoded text | — | n |
| lib/core/utilities/widgets/image_handelers/image_picker_bottom_sheet.dart | `showImagePickerSheet` camera/gallery | context, onFilePicked | y |
| lib/core/utilities/widgets/image_handelers/image_picker_widget.dart | SingleImagePickerWidget dotted upload box → preview with remove | title, subTitle, imagePath, onPickImage, onRemoveImage, width, height, radius, iconSize | y |
| lib/core/utilities/widgets/doc_upload_tile.dart | document upload tile (gallery/camera/ask, thumbnail preview, helper/error text) | label, file, onChanged, errorText, helperText, source, showPreview, onRemove | y |
| lib/core/utilities/widgets/fill_viewport_paging.dart | mixin: load next page while the list doesn't fill the viewport | pagingController, loadNextPage | y |
| lib/features/profile/presentation/widgets/app_language_sheet.dart | language picker sheet (autonyms, radio) that sets locale and Accept-Language | context | y (needs ApiService) |
| lib/features/app_config/presentation/screens/maintenance_screen.dart, update_screens.dart | MaintenanceScreen (server-clock-skew-safe countdown), ForceUpdateScreen, OptionalUpdateSheet.show(context, update) | — / update | y (feature models) |
| lib/features/bottom_nav/presentation/widgets/bottom_navigation_bar_view.dart | custom-painted bottom bar | app nav model | n |
| lib/features/reports/presentation/widgets/charts/* | CustomPainter line chart, pie chart, legend (no chart package) | report data | partly |

## 6. Packages (`pubspec.yaml`)

- **State:** flutter_bloc ^9.1.1, hydrated_bloc ^10.1.1 (storage only), equatable ^2.0.7
- **DI:** get_it ^9.0.5
- **Routing:** go_router ^16.3.0
- **Network / result:** dio ^5.7.0, dartz ^0.10.1
- **Storage:** shared_preferences ^2.3.3, flutter_secure_storage ^9.2.4, path_provider ^2.1.5, path ^1.9.1
- **L10n:** easy_localization ^3.0.7, intl ^0.20.2, flutter_localizations (sdk)
- **UI:** flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, cupertino_icons ^1.0.8, font_awesome_flutter ^11.0.0, skeletonizer ^2.1.0+1, dotted_border ^3.1.0, pinput ^5.0.2, country_picker ^2.0.2, flutter_html ^3.0.0 with html pinned to 0.15.6 (build-fix comment), flutter_native_splash ^2.4.3. Unused: flutter_animate ^4.5.2, animate_do ^4.2.0, flutter_rating_bar ^4.0.1, flutter_staggered_grid_view ^0.7.0, flutter_slidable ^4.0.3, flutter_colorpicker ^1.0.3
- **Firebase / push / ML:** firebase_core ^4.4.0, firebase_messaging ^16.1.1, firebase_crashlytics ^5.0.7 (unused), flutter_local_notifications ^19.5.0, google_mlkit_translation ^0.15.1, google_mlkit_language_id ^0.15.1
- **Media:** image_picker ^1.2.2, flutter_image_compress ^2.4.0, cached_network_image ^3.4.1
- **Maps / location (unused):** google_maps_flutter ^2.3.2, geolocator ^14.0.1
- **Utils:** permission_handler ^12.0.1, url_launcher ^6.3.1, package_info_plus ^9.0.0
- **Logging:** talker_flutter ^5.0.2, talker_dio_logger ^5.0.2
- **Misplaced:** flutter_launcher_icons ^0.14.4 (in dependencies; belongs in dev)
- **Dev:** flutter_test, flutter_lints ^6.0.0
- **Fonts:** Alexandria, Cairo, Roboto (only Roboto is used). **Assets:** icons, images, temp_images (1.9 MB), fonts (12 MB), translations, sounds.

## 7. Quality notes

- **Null safety:** full (Dart 3.7). Uses switch expressions, sealed classes, `withValues(alpha:)` and `PopScope`. No WillPopScope, `textScaleFactor`, `MaterialStateProperty` or `withOpacity` found.
- **Lints:** `include: package:flutter_lints/flutter.yaml` with no extra rules. CI (`.github/workflows/ci.yml`) runs `flutter analyze --no-fatal-infos`, `dart run tool/check_translations.dart`, `flutter test` and `flutter build apk --debug`.
- **Tests:** 30 test files with about 220 `test`/`testWidgets` cases, plus `test/helpers/pump_app.dart` (layout matrix, `useDevice`, `pumpLocalized` with a test asset loader for JSON over 50 KB) and `test/fixtures/reports_fixture.dart`. Coverage spans layout/overflow across six device/scale combos, BaseCubit failure fallback, pagination races, API contract parsing (notifications, reports, shipping origin, product save, delivery-image multipart), session/401 handling, notification permission, tab shell and the unsaved-changes guard. This is unusually good for this portfolio.
- **Documentation:** `README.md` (architecture, setup, known gaps), `CLAUDE.md` (responsive/text-scale/RTL conventions), and `docs/BUGS.md` + `docs/IMPROVEMENTS.md` (numbered backlog). Comments throughout explain *why* a change was made, often referencing a past bug. They are valuable but verbose.
- **Smells:**
  - core → features imports (AppCubit → home UserModel, services → notifications/auth/app_config, ExpandableFAB → BottomNavCubit).
  - Service locator inside base classes.
  - Two parallel base cubit/state systems.
  - `BaseState` has empty Equatable props.
  - The default single-class `copyWith` cannot clear `failure`.
  - Absolute endpoint strings combined with Dio `baseUrl`.
  - Dead files and widgets (listed in the summary).
  - Unused heavy dependencies and fonts.
  - Inconsistent folder names (`repo` vs `repositories`, `model` vs `models`, `home_cubit` vs `managers`) and misspellings (`image_handelers`, `phone_handeler_service`, `image_Widget.dart`).
  - Absurdly deep relative imports (`'../../../../../../../../../../../../core/...'`).
  - Raw colors scattered in widgets.
  - The `isNumeric` regex bug.
  - `DynamicDropdownFormField` search never updates an open menu.
  - Image compression code is duplicated three times.
  - `di_container.dart` and `app_router.dart` are large single files (over 560 and about 790 lines).
  - Placeholder Reels/Messages screens and product mocks ship in `lib/`.
  - Crashlytics is a dependency but not wired.
  - Hydrated storage is initialized but unused.
- **Secret-bearing files present (contents not opened):** `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` (none of the three is gitignored), `android/app/upload-keystore.jks` (`*.jks` is gitignored). No API keys or tokens were found in Dart, test or tool sources.
- **Sibling divergence:** `lib/core` mirrors `Chinaparts/New Projects/customer/lib/core` file-for-file in layout, but none of the 86 shared files is identical after renaming the package (14 differ by 10 lines or fewer, 72 by more). Each app also has its own differently named helpers for the same concerns (session expiry, double parsing, bottom-sheet helper, push service, language registry, MaxWidthBody location). The two cores forked from one template and evolved independently. The seller copy is the more hardened one for networking errors, session teardown, the push/permission flow and the responsive conventions.
