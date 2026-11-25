# chinaparts-customer — analysis

## Summary for comparison

```
PROJECT: chinaparts-customer | path: Chinaparts/New Projects/customer | stack: Flutter 3.44.0 (CI pin) / Dart SDK ^3.7.2 | last commit: 2026-10-26 | source files: 521
ARCH: clean-arch feature-first (light) — features/<f>/{data/{data_sources,models,repo(sitories)},presentation/{managers,screens,widgets}}; no domain layer/use-cases; shared bases in core/base_architecture
STATE: flutter_bloc 9 (cubits; 1 HydratedBloc for cart) — BaseSingleStateCubit.handleRequest (core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart, 39 users) + BaseCubit.handleRequest for sealed multi-class states (…/base_cubit/base_cubit.dart, 15 users); both have emit-after-close guard + session epoch
DI: get_it (manual, 114 registrations, lazy singletons for per-account cubits, factories for screen cubits) — lib/core/services/di_container.dart
ROUTING: go_router 16 — lib/core/app_router/app_router.dart (+ app_routes_names.dart) — StatefulShellRoute.indexedStack for tabs, errorBuilder not-found page, args via `extra` (int-or-string tolerant); guards: none (no redirect; 401 -> SessionExpiryService -> go(login)); deep links: notification payload -> route resolver only, no app_links/intent filters
NETWORK: dio 5 — interceptors: InterceptorsWrapper(401-with-token -> onUnauthorized), TalkerDioLogger (debug only, no headers) | token refresh: n | retry: n | error mapping: BaseRemoteDataSource maps status 400/401/403/404/409/422/5xx + DioExceptionType (timeouts/connectionError) to typed Failure with server message or `errors.*` key; parses `errors` list or field map | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/base_architecture/data/repository/base_repo.dart
RESULT_TYPE: Either (dartz) — lib/core/utilities/failures/failure.dart (Failure implements Exception; BadRequest/Unauthorized/Forbidden/NotFound/Conflict/Server/Network/Timeout/Cache/Validation/Translation/Unknown)
STORAGE: shared_preferences (singleton wrapper) + flutter_secure_storage (token) + hydrated_bloc (cart only) — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart
L10N: easy_localization 3 — en, ar, zh-Hans, zh-Hant (~790 keys each, parity enforced by test); fallback en, start locale derived from device (AppLanguages.forDevice); assets/translations/*.json; single source of truth lib/core/utilities/constants/app_languages.dart — hardcoded UI strings: few (regex guard test, 5 allowlisted files)
RTL: Directional=225 vs LeftRight=13 (all 13 are symmetric left==right or gradient begin/end — effectively zero RTL bugs)
THEME: lib/core/theme/light_theme/light_theme.dart (getter, rebuilt so .sp follows screenutil) — dark mode n (dark_theme.dart is an empty file) | component themes in ThemeData y (appBar, elevated/text buttons, input decoration, dialog (with width cap), snackbar, bottom nav, progress) | colors class AppColors (lib/core/utilities/constants/colors.dart) | text styles TextThemeLight (…/light_widget_themes/text_theme.dart, .sp with heading caps) | fonts Alexandria (Cairo declared but unused)
RESPONSIVE: flutter_screenutil (design size 393x852 phone, 834x1112 when width>=600, minTextAdapt+splitScreenMode) + custom helpers lib/core/utilities/responsive/{responsive.dart,max_width_body.dart,scrollable_form_body.dart} — breakpoints: tablet 600 / desktop 1024 on logical WIDTH (MediaQuery.sizeOf; ResponsiveLayout uses LayoutBuilder constraints); SurfaceWidths dialog 560 / bottomSheet 640
TEXT_SCALING: clamped once in MaterialApp.router builder (lib/main.dart) via mediaQuery.textScaler.clamp(min 1.0, max 1.3); context.textExtra(px) adds the scaled-text delta to fixed-height rails; matrix tests at 1.0/1.3
ENV/FLAVORS: hardcoded constants (ApiKeys.BASE_URL in lib/core/utilities/constants/keys/api_keys.dart, AppUrls) — no flavors/dart-define; Maps key injected natively from local.properties/env (Android manifestPlaceholders) and gitignored ios/Flutter/Secrets.xcconfig
LOGGING: talker_flutter (global `talker`, enabled only in kDebugMode) + TalkerRouteObserver + TalkerDioLogger (debug) + debugPrint in AppBlocObserver (debug only)
ANALYTICS/CRASH: firebase_crashlytics only (ErrorReporter facade, release only; FlutterError non-fatal, zone/platform fatal; CrashReportingBlocObserver) — no analytics
PUSH: fcm + flutter_local_notifications — lib/core/services/notification_service.dart (static; listeners attached before runApp, background isolate handler, channels, topic subscriptions persisted) + notification_link_handler.dart (pure sealed destination resolver) + chat_push_bus.dart
PAYMENTS/IAP: hosted payment gateway in webview_flutter (redirect-URL detection) — lib/features/checkout/presentation/widgets/payment_method_step.dart; wallet top-up with pending reconciliation; no IAP
PERMISSIONS: permission_handler (notifications, openAppSettings on media denial) + geolocator permission flow in location picker
DEEP_LINKS: none inbound (no app_links/uni_links/intent filters); go_router paths used for push-notification routing; share links generated (ProductShareService) but not handled
MEDIA/FILES: image_picker (ImagePickerService), file_picker (ticket attachments), share_plus, url_launcher, Image.network/Image.file with cacheWidth (cached_network_image declared but never imported), skeletonizer, google_maps_flutter + geolocator, google_mlkit_translation/language_id
TESTS: 65 test files (+1 fakes file) — size x text-scale x RTL layout matrices, locale key parity, hardcoded-string guard, Dio adapter error mapping, session teardown/401 dedupe, cubit races/pagination, model blank-field parsing, routing round-trips, notification routing; hand-written fakes (no mocktail/bloc_test)
LINTS: flutter_lints 6, 0 extra rules (CI: flutter analyze --no-fatal-infos + flutter test on GitHub Actions)
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/utilities/responsive/responsive.dart — Breakpoints, SurfaceWidths, DeviceFormFactor, context.responsive<T>() cascade, context.textExtra(), ResponsiveLayout — quality 4 — coupling: none (flutter/widgets only)
- lib/core/base_architecture/data/repository/base_repo.dart — handleNetworkCall -> Either, catches non-Failure throws, reports to Crashlytics — quality 5 — coupling: low (talker + ErrorReporter)
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart — handleRequest with default loading/success/failure emits, emit-after-close guard, resetSession epoch — quality 4 — coupling: low (BaseSingleClassState/FetchDataStatusEnum)
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — single handleRequest(path, method, parser) with status/DioException -> Failure mapping and `errors` parsing — quality 4 — coupling: medium (resolves ApiService via get_it inside)
- lib/core/utilities/failures/failure.dart — typed failures carrying `errors.*` keys translated lazily, server text passed through — quality 4 — coupling: low (easy_localization)
- lib/core/utilities/responsive/scrollable_form_body.dart — Spacer-pinned footer form that scrolls under keyboard/large text — quality 4 — coupling: none
- lib/core/utilities/responsive/max_width_body.dart — phone pass-through, tablet 600 / desktop 720 content cap — quality 4 — coupling: none
- lib/core/services/error_reporter.dart — Crashlytics facade (report/setUser/setLocale), release-only guard — quality 5 — coupling: low (firebase)
- lib/core/utilities/constants/app_languages.dart — locale table: supported locales, asset codes, direction, device-locale mapping (zh script split) — quality 5 — coupling: none
- lib/core/services/app_version_comparator.dart — null-safe dotted version compare (ignores +build/-pre, leading v) — quality 5 — coupling: none
- lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart — handleRequest for sealed per-state classes, epoch + close guard — quality 4 — coupling: low
- lib/core/services/toast_manager.dart (+ lib/core/utilities/widgets/toasts/animated_custom_toast.dart) — overlay toast, single timer, replaces previous, mounted-safe, context.showToast — quality 4 — coupling: none
- lib/core/services/session_expiry_service.dart — single-flight 401 teardown + redirect to login — quality 4 — coupling: high (AppCubit, AuthRepository, appRouter)
- lib/core/services/bloc_observer.dart — debug printing observer + release Crashlytics observer — quality 4 — coupling: low
- lib/core/services/url_handler.dart — launchUrl wrappers (url/tel/mailto/sms/WhatsApp) checking result instead of canLaunchUrl — quality 4 — coupling: none
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/buttons/app_default_button.dart — primary button — text, onTap, isLoading, enabled, svgIconPath, child, height(min), width, radius, colors, margin/padding — quality 4 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart — icon pill button + AppBackButton — child, onTap, size, radius, colors — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — labelled text field — title, titleSuffixWidget, controller, hint, validator, prefix/suffix, min/maxLines, constraints, colors, tap-outside unfocus — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password field w/ visibility toggle — controller, isConfirmPassword, title, hint — quality 2 — generic? y (confirm validator ignored)
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart — email field — controller, title, hint, readOnly, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart — phone field with country_picker prefix chip — controller, selectedCountry, onCountryChanged — quality 3 — generic? partial (hardcoded country filter)
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart — read-only field opening a bottom-sheet list — title, hint, controller, items, validator — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — generic <T> dropdown via showMenu with optional search — options, displayText, initialValue, selectedDisplayText, isLoading — quality 2 — generic? y (LTR-only positioning, 186 lines commented-out)
- lib/core/utilities/widgets/app_dialog.dart — info dialog — title, description, contentWidget, actionTitle, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/confirm_dialog.dart — showConfirmDialog -> Future<bool> — title, message, confirmLabel, cancelLabel, destructive — quality 5 — generic? y
- lib/core/utilities/widgets/show_app_bottom_sheet.dart — draggable sheet with title + primary/cancel footer — sheetTitle, sheetContent, primaryBtnText, onTapPrimaryBtn, child sizes — quality 3 — generic? y
- lib/core/utilities/widgets/bottom_action_buttons.dart — two-button sticky footer — primary/second text + callbacks — quality 3 — generic? y
- lib/core/utilities/widgets/image_picker_bottom_sheet.dart — showImagePickerSheet camera/gallery (+multi) — onFilePicked, onFilesPicked, pickLimit — quality 3 — generic? y
- lib/core/services/show_loading_dialog.dart — blocking loading dialog + context.showLoading — message, barrierDismissible — quality 2 — generic? y
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget<B,S,T> status switch + BaseLoadingWidget/BaseErrorWidget(retry)/BaseEmptyWidget — successBuilder, loadingWidget, failureWidget, onRetry — quality 3 — generic? y
- lib/core/utilities/widgets/base_list_view_widget.dart — list with empty state — items, itemBuilder, emptyWidget(Text) — quality 2 — generic? y
- lib/core/utilities/widgets/default_screen.dart — base scaffold with custom header row, back button, MaxWidthBody body — body, pageTitle(Widget), hasBackButton, bodyPadding, constrainBodyWidth, FAB — quality 3 — generic? y
- lib/core/utilities/widgets/custom_appbar.dart — PreferredSize app bar with back button + divider — pageTitle, actions — quality 3 — generic? y
- lib/core/utilities/widgets/shared/widgets/image_widget.dart — ImageViewerWidget network/asset/file image w/ placeholder, initials avatar, cacheWidth — image, user, size, radius, border, stackedWidget, onTap — quality 3 — generic? partial (depends on feature UserModel; no disk cache)
- lib/core/utilities/widgets/shared/screens/image_viewer.dart — full-screen image viewer — imagePath — quality 3 — generic? y
- lib/core/utilities/widgets/shared/screens/select_location_screen.dart — Google Maps center-pin location picker with geolocator — title, confirmLabel, initialLocation — quality 3 — generic? y (needs maps key)
- lib/core/utilities/widgets/container_with_shadow.dart — card container — child, padding, margin, radius, colors, shadow, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/custom_chip.dart — chip/badge — title, colors, radius, padding(Directional), onSelect — quality 3 — generic? y
- lib/core/utilities/widgets/selection_chip_widget.dart — selectable chip — isSelected, title, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/custom_radio_group_widget.dart — CustomRadioGroup<T> + animated CustomSizeRadio<T> — options, selectedValue, label, prefixText — quality 2 — generic? y (controller created in didChangeDependencies)
- lib/core/utilities/widgets/app_divider.dart — divider with widthFactor — height, thickness, color, indents — quality 3 — generic? y
- lib/core/utilities/widgets/linear_progress_indicator.dart — percent bar — percent, minHeight — quality 3 — generic? y
- lib/core/utilities/widgets/animated_indicator.dart — page/step dot indicator — index, currentStep — quality 3 — generic? y
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart — overlay toast UI (success/failure/warning/info) — message, state, duration, location — quality 4 — generic? y
- lib/core/utilities/responsive/max_width_body.dart — width-cap wrapper — child, tabletMaxWidth, desktopMaxWidth, alignment — quality 4 — generic? y
- lib/core/utilities/responsive/scrollable_form_body.dart — scroll-safe form body — child, padding — quality 4 — generic? y
- lib/core/utilities/responsive/responsive.dart (ResponsiveLayout) — per-breakpoint builder — phone, tablet, desktop builders — quality 4 — generic? y (defined, unused in app)
- lib/features/app_config/presentation/widgets/app_config_gate.dart — root overlay gate for maintenance / force update / optional update sheet — child — quality 4 — generic? y (with its cubit/screens)
- lib/features/checkout/presentation/widgets/step_indicator.dart — checkout step bar — currentStep — quality 3 — generic? n (fixed steps)
- lib/features/home/presentation/widgets/section_header_widget.dart — two-tone section header with "see all" — titles, subtitle, actionTitle, onActionTap — quality 3 — generic? partial
- lib/features/products/presentation/widgets/product_grid_view.dart — masonry grid (sliver/box) with responsive columns 2/3/4 — products, isSliver — quality 3 — generic? n (ProductCard)
NOTABLE_IDEAS: (1) Responsive kit lib/core/utilities/responsive/* + CLAUDE.md "Responsive & text scaling" rules + test/core/adaptive_surfaces_matrix_test.dart (320/393/600/1180 x scale 1.0/1.3, asserts no exception + SurfaceWidths caps) — best-documented adaptive system seen; (2) context.textExtra(px) for fixed-height rails (base.h + textExtra(textPortion)); (3) dialog width cap via dialogTheme.constraints (lib/core/theme/light_theme/light_widget_themes/dialog_theme.dart) instead of per-widget wrappers; (4) theme + TextTheme as getters so .sp re-evaluates on rotation/split view; screenutil design size picked per breakpoint in main.dart; (5) single text-scale clamp in MaterialApp.builder; (6) AppLanguages table driving supportedLocales/direction/picker + test/core/app_languages_test.dart key-parity test; (7) test/core/no_hardcoded_ui_strings_test.dart regex guard; (8) cubit session epoch + emit-after-close guard in base cubits; (9) SessionExpiryService single-flight 401 teardown, interceptor only fires when request carried a token; (10) clear Keychain on first launch (iOS keeps it after uninstall) in main.dart _clearStaleSessionOnFirstLaunch; (11) X-Platform / X-App-Version / X-Build-Number + Accept-Language global headers; (12) AppConfigGate overlay (maintenance/force/optional update, cached config never gates, refresh on resume if stale) in lib/features/app_config/; (13) pure sealed NotificationDestination resolver (testable) in lib/core/services/notification_link_handler.dart; FCM listeners attached before runApp; (14) Maps key via local.properties/env -> manifestPlaceholders and gitignored Secrets.xcconfig with Secrets.example.xcconfig; (15) Crashlytics: FlutterError non-fatal, zone/platform fatal, talker disabled in release; (16) String/Int/DoubleParserService for tolerant JSON; (17) tool/create_feature.dart scaffold; docs/BUGS.md + docs/IMPROVEMENTS.md audit log referenced by test names; GitHub Actions CI
SMELLS: two parallel base cubits (BaseCubit vs BaseSingleStateCubit) and many cubits (pagination ones) bypass handleRequest and re-implement page/isBusy/loadMore logic (~10 copies of ScrollController 0.9 threshold); BaseState props [] so sealed states with fields compare equal (e.g. consecutive LoginFailure(error) deduped); copyWith sentinel pattern hand-written per state; ApiService._initializeDio is async from constructor (interceptors added after an await -> early requests may miss them); no token refresh/retry; BASE_URL hardcoded, no flavors; ShareService hardcodes web host/scheme; DI container 655 lines importing every feature; AppCubit.logout reaches into 6 feature singletons; MaterialApp keyed by locale (full tree rebuild on language change) and ApiService.setLanguage called inside build; DefaultScreen double-counts bottom safe area (padding + viewPadding SizedBox); showAppBottomSheet ignores DraggableScrollableSheet scrollController; MaxWidthBody wraps scrollables so tablet side gutters don't scroll; PasswordTextFormField ignores isConfirmPassword/confirmPasswordValidator/isLogin; CustomSizeRadio creates AnimationController in didChangeDependencies; DynamicDropdownFormField positions menu with LTRB offsets (not RTL-aware) + 186 commented lines; AppDialog close calls context.pop(context); AppValidator.isNumeric regex has escaped `\$` (never matches) and returns untranslated key; CacheFailure drops its message; AppIconButton/ImageViewerScreen import via absurd `../../../../../../../../../../../../core/...` relative paths; Radio groupValue API (deprecated in 3.32+) 15 uses; 191 raw `Colors.*` + 63 `Color(0x..)` outside AppColors; 78 raw `fontSize:` literals; empty files (dark_theme.dart, price_converter.dart); unused deps (cached_network_image, dotted_border, font_awesome_flutter, animate_do) and unused Cairo font; .DS_Store files inside lib/; mocks folder in lib/features/products/data/mocks; firebase config files (google-services.json, GoogleService-Info.plist, firebase_options.dart) committed to git; upload-keystore.jks present in android/app (gitignored, not committed)
```

---

## 1. Architecture pattern

**Feature-first, two-layer "clean-ish" architecture.** Each of the 23 features under
`lib/features/` owns a vertical slice with `data/` and `presentation/`. There is **no
domain layer** (no entities, no use-cases, no repository interfaces): repositories are
concrete classes that extend `BaseRepository` and wrap a concrete `XRemoteDataSource`
(which extends `BaseRemoteDataSource`). Cubits depend directly on the concrete
repository.

Request flow:

```
Screen ──BlocProvider(diService<XCubit>())──► XCubit (BaseSingleStateCubit / BaseCubit)
   handleRequest(call: () => repo.foo())
        ▼
XRepository extends BaseRepository
   handleNetworkCall(call: () => remote.foo())   → Either<Failure, T>
        ▼
XRemoteDataSource extends BaseRemoteDataSource
   handleRequest(path: ApiKeys.FOO, method: HttpMethod.get, parser: (res) => BaseSuccessResponse.fromJson(res.data, Model.fromJson))
        ▼
diService<ApiService>()  (Dio wrapper; throws typed Failure on error)
```

- Responses are wrapped in `BaseSuccessResponse<T>` (`success`, `message`, `data`, `meta` →
  `PaginationModel`), parsed with `parseList` for lists.
- Two state styles coexist:
  - **Single-class state** (`BaseSingleClassState` with `status: FetchDataStatusEnum`,
    `failure`, `success`, plus feature fields, sentinel-based `copyWith`) driven by
    `BaseSingleStateCubit` — the dominant style (39 files).
  - **Sealed multi-class state** (`sealed class LoginState extends BaseState`) driven by
    `BaseCubit.handleRequest(loadingState:, onSuccess:, onError:)` — used by auth, home
    rails, splash, profile, order detail (15 files).
- Global, per-account state (cart, favorites, notifications, addresses, garage, profile,
  app config, AppCubit) are **GetIt lazy singletons** provided at the root with
  `BlocProvider.value`; `AppCubit.logout()` is the single choke point that resets them.
- Screen-scoped cubits are GetIt **factories** created in route builders (`app_router.dart`).

## 2. Folder tree (`lib/`, 4 levels)

```
lib/
├── main.dart                      bootstrap: prefs, l10n, Firebase, Crashlytics, Hydrated storage, DI, headers, FCM listeners, ScreenUtilInit, root providers, text-scale clamp, Directionality, AppConfigGate
├── firebase_options.dart          (exists; secret-class file, not opened)
├── core/
│   ├── app_cubit/                 AppCubit + AppState (token, user, logout teardown)
│   ├── app_router/                app_router.dart (GoRouter, StatefulShellRoute, route builders w/ BlocProviders), app_routes_names.dart
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/      base_remote_data_source.dart
│   │   │   ├── models/            base_success_model.dart, base_request_model/network_request_model.dart, base_response_model/base_success_response.dart (+PaginationModel, parseList)
│   │   │   └── repository/        base_repo.dart
│   │   └── presentation/managers/
│   │       ├── base_cubit/        base_cubit.dart, base_state.dart
│   │       └── base_single_class_state_bloc/  base_single_class_state.dart, base_single_class_state_cubit.dart
│   ├── enums/                     fetch_data_status, http_method, toast_state, app_roles (unused leftover)
│   ├── exports/core_exports.dart  barrel: material, go_router, easy_localization, screenutil, AppColors, DefaultScreen
│   ├── extensions/                context_extensions (theme/textTheme/colorScheme/isAr), list_extensions (isNullOrEmpty)
│   ├── models/                    selection_model.dart
│   ├── services/                  api_service, di_container, notification_service, notification_link_handler, chat_push_bus, session_expiry_service, error_reporter, bloc_observer, toast_manager, show_loading_dialog, image_picker_service, share_service, url_handler, app_validator, app_version_service, app_version_comparator, currency_formatter_service, debounce, int/double/string parsers, language_flags_service, phone_handeler_service, secure_storage_manager, shared_preferences_manager
│   ├── theme/
│   │   ├── dark_theme/            dark_theme.dart (EMPTY)
│   │   └── light_theme/           light_theme.dart, my_light_themes_export.dart
│   │       └── light_widget_themes/  app_bar, bottom_nav, btn_txt, dialog (width cap), elevated_btn, input_decoration, light_color_scheme, snack_bar, text_theme
│   └── utilities/
│       ├── constants/             app_languages.dart, colors.dart, icons.dart (+svg helper), images.dart, temp_images.dart, constant_lists.dart
│       │   └── keys/              api_keys.dart (BASE_URL + ~50 endpoints), app_urls.dart, shared_preferences_keys.dart
│       ├── converters/            price_converter.dart (EMPTY)
│       ├── failures/              failure.dart, error_details_model.dart
│       ├── formatters/            date_formatter.dart
│       ├── helpers/               auth_helper, currency_formatter (cents→money, context ext), image_cache_size
│       ├── responsive/            responsive.dart, max_width_body.dart, scrollable_form_body.dart
│       └── widgets/               app_dialog, confirm_dialog, show_app_bottom_sheet, bottom_action_buttons, base_fetching_widget, base_list_view_widget, default_screen, custom_appbar, container_with_shadow, custom_chip, selection_chip_widget, custom_radio_group_widget, app_divider, linear_progress_indicator, animated_indicator, image_picker_bottom_sheet
│           ├── buttons/           app_default_button, app_icon_button (+AppBackButton)
│           ├── shared/screens/    image_viewer.dart, select_location_screen.dart (maps picker)
│           ├── shared/widgets/    image_widget.dart (ImageViewerWidget)
│           ├── text_form_fields/  app_text_form_field, password, email, phone, dropdown, dynamic_drop_down
│           └── toasts/            animated_custom_toast.dart
└── features/  (23)               addresses, app_config, auth, banners, big_sales, bottom_nav, cart, chat, checkout, coupons, favorites, home, legal, my_garage, notifications, offers, orders, products, profile, returns, splash, support_tickets, wallet
```

Representative feature fully expanded — `features/wallet/` (21 files, ~2k lines):

```
wallet/
├── data/
│   ├── data_sources/wallet_remote_data_source.dart   extends BaseRemoteDataSource; getWalletSummary, getTransactions(page, perPage, type), createTopup, getTopupStatus
│   ├── models/
│   │   ├── requests/create_topup_request_model.dart
│   │   ├── responses/{create_topup_response, wallet_summary, wallet_topup, wallet_topup_payment, wallet_transaction}_model.dart
│   │   └── wallet_topup_status_enum.dart
│   └── repositories/wallet_repo.dart                 extends BaseRepository; thin handleNetworkCall pass-through returning BaseSuccessResponse<T>
└── presentation/
    ├── managers/
    │   ├── topup_cubit/{topup_cubit, topup_state}.dart
    │   ├── wallet_cubit/{wallet_cubit, wallet_state}.dart
    │   └── wallet_transactions_cubit/{…cubit, …state}.dart   BaseSingleStateCubit; page-1 load + loadMore with _isBusy, isLoadingMore flag, guest short-circuit, sentinel copyWith
    ├── screens/{top_up_screen, wallet_screen, wallet_transactions_screen}.dart   ScrollController 0.9 load-more trigger, RefreshIndicator, BaseLoading/Error/EmptyWidget, MaxWidthBody
    └── widgets/{topup_amount_field, wallet_balance_card, wallet_transaction_tile}.dart
```

Largest features: products (50 files / 8.1k lines), chat (35 / 4.8k, incl. on-device ML Kit
translation), support_tickets (30 / 3.9k), returns (28 / 3.8k), cart (16 / 3.7k, HydratedBloc
with guest/server merge + its own `README.md`).

## 3. Infrastructure

### State management
- `flutter_bloc ^9.1.1`, `bloc ^9.1.0`, `hydrated_bloc ^10.1.1` (only `CartBloc`).
- `BaseSingleStateCubit<S extends BaseSingleClassState>.handleRequest({call, onNotDefaultSuccess, onNotDefaultFailure, onNotDefaultLoading})`:
  emits `copyWith(status: loading, failure: null)`, awaits the Either, emits success/failure
  by default; casts `as S`. Default success path requires `T` to be a `BaseSuccessModel`.
- `BaseCubit<S extends BaseState>.handleRequest({loadingState, call, onSuccess, onError, showLoading})`.
- Both override `emit` to drop emits after close, and keep an `_epoch` bumped by
  `resetSession(initial)` so responses that started before logout are discarded — a very good
  idea worth keeping (tested in `test/core/session_teardown_test.dart`).
- Weaknesses: two base classes doing the same job; `BaseState.props => []` means sealed states
  with payloads are equal to each other unless they override props; pagination cubits
  (wallet transactions, returns, notifications, orders, products, tickets…) do not use
  `handleRequest` and each re-implement `_isBusy`/`isLoadingMore`/`canLoadMore`.
- `AppBlocObserver` (debug, debugPrint every transition) vs `CrashReportingBlocObserver`
  (release, only `onError` → Crashlytics) selected in `main.dart`.

### DI
- `get_it ^9.0.5`, manual registration in `lib/core/services/di_container.dart` (655 lines,
  imports every feature). `diContainerSetup()` → `_initExternalServices`, `_initDioAndRemoteDataSource`,
  `_initRepo`, `_initBlocs`, `_initCubits`. Note: these are `Future` functions that are not
  awaited (they are synchronous in practice).
- Lifetimes are deliberate and commented (AppCubit, AppConfigCubit, CartBloc, Favorites,
  Notifications, Profile, Addresses, Vehicles = lazy singletons; screen cubits = factories);
  a test asserts the singletons.
- The global `talker` instance lives here too (`Talker(settings: TalkerSettings(enabled: kDebugMode))`).

### Routing
- `go_router ^16.3.0`, `lib/core/app_router/app_router.dart` (765 lines) + `app_routes_names.dart`.
- Root `navigatorKey` exposed as `rootNavigatorContext` for UI started outside screens
  (permission prompt, update sheet). `TalkerRouteObserver`. `errorBuilder` renders a
  localized not-found page; detail routes validate `extra` via `_intExtra` (accepts int or
  numeric string, from notification data) and show not-found instead of a cast crash.
- `StatefulShellRoute.indexedStack` with 4 branches (home, chats, reels, profile) under a
  5-slot bottom bar (cart is pushed); `navIndexForBranch` / `branchForNavIndex` mapping is
  unit-tested; re-tapping a tab returns to its root.
- Route builders create screen cubits with `BlocProvider(create: (_) => diService<X>())`.
- No `redirect`/auth guard; unauthenticated users are handled per screen (guest states) and by
  `SessionExpiryService` on 401. Arguments are passed through `extra` (not URL-safe for real
  deep links).

### Networking
- `dio ^5.7.0`. `ApiService` (`lib/core/services/api_service.dart`) implements
  `ApiServiceBase` (get/post/put/patch/delete taking `NetworkRequestParams`, `updateHeaders`,
  `clearToken`) plus `setLanguage(tag)` for `Accept-Language`.
- Timeouts: connect 15 s, receive 30 s, send 60 s. Default headers JSON + Accept-Language;
  token read from secure storage (unreadable ciphertext → deleted, treated as signed out).
- Interceptors: one `InterceptorsWrapper.onError` that calls `onUnauthorized` only when the
  failed request carried an `Authorization` header (so a wrong-password 401 doesn't log the
  user out); `TalkerDioLogger` only in debug with `printRequestHeaders: false`.
- `onUnauthorized` is wired in DI to `SessionExpiryService.expire()` (single-flight,
  clears local session, `AppCubit.logout()`, `appRouter.go(login)` only if the user was
  signed in).
- `main.dart` adds global `X-Platform`, `X-App-Version`, `X-Build-Number` headers from
  `AppVersionService` (package_info_plus).
- Error mapping in `BaseRemoteDataSource._handleErrorResponse/_handleDioError`: status codes
  → typed failures with server message (already localized by Accept-Language) or `errors.*`
  key; `errors` field parsed as list or field map into `ErrorDetail`; timeouts → `TimeoutFailure`,
  connectionError → `NetworkFailure`; parser `TypeError` → `UnknownFailure` (logged).
- No token refresh, no retry, no connectivity check, no cancel-token plumbing from cubits
  (the epoch handles staleness instead).
- Issue: `_initializeDio()` is `async` and invoked from the constructor without await —
  options/interceptors are applied after `await _buildHeaders()`; `main.dart` later calls
  `updateHeaders`, which masks it, but a request fired in that window would miss the 401
  interceptor.

### Local storage
- `SharedPreferencesManager` — singleton, `init()` in main, dynamic `setValue/getValue/remove/clear`.
- `SecureStorageManager` — thin `FlutterSecureStorage` wrapper (try/rethrow noise), used for the token.
- `HydratedBloc.storage` (app documents dir) — only the cart is hydrated.
- Keys in `SharedPreferencesKeys` (SCREAMING_CASE with ignore_for_file). Passwords are no longer
  stored; legacy copies are deleted.
- First-launch Keychain wipe (`_clearStaleSessionOnFirstLaunch` in `main.dart`).

### Localization (+RTL)
- `easy_localization ^3.0.7`, `intl ^0.20.2`, JSON in `assets/translations/` (en, ar,
  zh-Hans, zh-Hant; ~790 keys each).
- `lib/core/utilities/constants/app_languages.dart`: `AppLanguage(locale, nameKey,
  nativeName, direction)`, `AppLanguages.supported/locales/fallback/byLocale/directionOf/isRtl/forDevice`.
  `MaterialApp.builder` wraps a `Directionality(textDirection: AppLanguages.directionOf(locale))`.
- Server-side strings follow UI language via `Accept-Language`; Crashlytics gets a locale key.
- `Failure.message` translates `errors.*` keys lazily.
- RTL hygiene is excellent: 225 directional usages vs 13 left/right, all symmetric.
- Tests: key parity across locale files, every language named in every file, Chinese files
  really Simplified/Traditional, iOS usage descriptions translated, no hardcoded English in UI slots.
- Weakness: `MaterialApp.router` keyed by `ValueKey(locale)` rebuilds the whole tree on
  language change; `DynamicDropdownFormField` menu position is LTR-only.

### Theming
- Light only (`dark_theme.dart` is empty). `ThemeData get lightTheme` (Material 3) with
  `ColorScheme.fromSeed(primary)`, component themes for app bar (title clamped `24.sp.clamp(20, 26)`),
  elevated/text/legacy buttons, input decoration (borders, fill, hint/error styles),
  dialog (`constraints: BoxConstraints(minWidth: 280, maxWidth: SurfaceWidths.dialog)`),
  snackbar, bottom nav, progress indicator.
- Getter-based theme/text theme so `.sp`/`.h` re-evaluate after rotation / split view / design
  size switch (explicitly documented).
- `TextThemeLight`: all M3 roles in Alexandria; body/label/title `.sp`, display/headline
  `.sp.clamp(0.9x, 1.1x)`; body line height 1.3 for Arabic diacritics.
- `AppColors`: primary, secondary/neutral/grey ramps (naming inconsistent: `neutral900` is
  lighter than `neutral1000`; `darkGrey` is light). Raw `Colors.*` (191) and `Color(0x…)` (63)
  still appear in widgets despite the README rule. `AppTextFormField` re-declares all borders
  that the theme already sets.

### Responsive helpers (template candidates — evaluated in detail)

**`lib/core/utilities/responsive/responsive.dart`** (109 lines, depends only on `flutter/widgets`)
- `Breakpoints.tablet = 600`, `Breakpoints.desktop = 1024` (600 matches the Material compact/medium
  boundary; 1024 is custom — M3 "expanded" is 840).
- `SurfaceWidths.dialog = 560`, `bottomSheet = 640` — named caps; dialog enforced app-wide via
  `dialogTheme.constraints`, bottom sheet relies on the M3 default (documented, tested).
- `DeviceFormFactor` + `formFactorForWidth(width)`; `ResponsiveContext` extension:
  `screenWidth` (`MediaQuery.sizeOf` → rebuilds only on size changes), `formFactor`, `isPhone/isTablet/isDesktop/isLargeScreen`,
  `responsive<T>(phone:, tablet:, desktop:)` with fallback to the next smaller value, and
  `textExtra(textHeightAtScale1)` = `textScaler.scale(h) - h` (0 at scale 1.0).
- `ResponsiveLayout(phone:, tablet:, desktop:)` uses `LayoutBuilder` constraints (falls back
  to screen width when unbounded).
- Strengths: tiny, no package dependency, correct API choices (`sizeOf`, `textScalerOf`),
  `textExtra` is a genuinely useful idea for fixed-height carousels, cascade defaults keep call
  sites short.
- Weaknesses: (a) the extension reads **screen** width while `ResponsiveLayout` reads
  **constraints** — two sources of truth inside one file; (b) width-only classification means a
  phone in landscape (e.g. 852 dp) is a "tablet" — this switches screenutil to the 834×1112
  design size, caps buttons at 480 and bodies at 600; it is intentional and tested (820×390
  case) but should be a documented choice in a template (alternatively expose `shortestSide`
  for device class); (c) desktop is just "wide tablet"; (d) `ResponsiveLayout`, `isTablet`,
  `isLargeScreen` are unused in this app (4 call sites of `context.responsive`).
- Verdict: **adopt**, merging both readings into one (e.g. `context.formFactor` and a
  `LayoutBuilder`-based variant), keep `SurfaceWidths` and `textExtra`.

**`lib/core/utilities/responsive/max_width_body.dart`** (44 lines)
- Phone: returns child untouched. Tablet/desktop: `Align(topCenter) + ConstrainedBox(maxWidth 600/720)`.
  Used 30× (and by default in `DefaultScreen` via `constrainBodyWidth: true`, and inside
  `BottomActionButtons`).
- Weaknesses: decides by screen width, not available width (inside a split pane it may cap
  needlessly); when wrapped around a `ListView` (as in `wallet_transactions_screen.dart`) the
  side gutters on tablets are not scrollable and the scrollbar sits at the content edge — the
  doc comment itself is ambiguous about where the scrollable goes. A template version should
  offer a sliver/padding variant (`SliverConstrainedCrossAxis` or computed horizontal padding)
  so the scroll area stays full-width.
- Verdict: **adopt with a scroll-friendly variant**.

**`lib/core/utilities/responsive/scrollable_form_body.dart`** (37 lines)
- `LayoutBuilder → SingleChildScrollView → ConstrainedBox(minHeight: maxHeight) → IntrinsicHeight → Padding → child`.
  Lets a `Column` with `Spacer()` + footer button fill the viewport, and scroll under keyboard,
  landscape or 1.3× text. Used by 4 password/OTP/email screens.
- Weaknesses: `IntrinsicHeight` costs an extra layout pass and fails for children that can't
  report intrinsics (`LayoutBuilder`, lazy lists); throws if placed under unbounded height
  (minHeight = ∞); no `keyboardDismissBehavior`/`physics`/`controller` passthrough. The
  `CustomScrollView + SliverFillRemaining(hasScrollBody: false)` form achieves the same without
  `IntrinsicHeight`.
- Verdict: **adopt the API, consider the sliver implementation**.

**Supporting pieces**
- `main.dart` picks the screenutil design size by `Breakpoints.tablet` before `ScreenUtilInit`
  (`minTextAdapt: true`, `splitScreenMode: true`). The same expression is duplicated in three
  test hosts — a template should expose `designSizeFor(width)` from `responsive.dart`.
- `AppDefaultButton` uses `minHeight` (not fixed height) so labels grow with text scale, and caps
  default width to 480 on tablets; `AppIconButton` explains why icon buttons stay fixed.
- `ProductGridView` adds columns via `context.responsive<int>(phone: 2, tablet: 3, desktop: 4)`.
- CLAUDE.md codifies the rules (never `Platform.is*` for layout, no orientation locks, no
  per-widget dialog wrappers, `.w/.h` not for text containers, minimum widths 320 dp).

**`test/core/adaptive_surfaces_matrix_test.dart`** (190 lines) — the template test
- Sizes 320×800, 393×852, 600×960, 1180×820 × text scales 1.0 / 1.3 (24 cases) for
  `AppDialog`, `showConfirmDialog`, `showAppBottomSheet`; sets `tester.view.physicalSize` and
  `platformDispatcher.textScaleFactorTestValue` with tear-downs, pumps the real `lightTheme` under
  `ScreenUtilInit`, asserts `tester.takeException()` is null and the inner `Material` width ≤
  `SurfaceWidths.*`.
- Siblings: `text_scale_overflow_matrix_test.dart` (buttons, app bar, home headers),
  `phase5_layout_matrix_test.dart` (adds RTL × 820×390 landscape for chat tile, order card,
  step indicator, ticket chips), `features/cart/cart_screen_layout_test.dart`.
- Gaps: matrix host doesn't go through `MainApp.builder` (so the clamp itself isn't under test),
  no RTL in the surfaces test, design-size logic duplicated. Still the best reusable adaptive
  test pattern in the set.

### Text scaling
- One clamp in `MaterialApp.router.builder`: `mediaQuery.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3)`
  (modern `TextScaler` API; `textScaleFactor` is absent from the codebase).
- Floor 1.0 (ignores "smaller text" settings) and ceiling 1.3 are product decisions; 1.3 is low
  by accessibility standards (iOS/Android allow 2×+), so a template should make the range a
  constant and justify it.
- `context.textExtra()` used in 7 places to grow fixed-height rails/sections.

### Env / flavors
- None. `ApiKeys.BASE_URL` / `BASE_IMAGE_URL` and full endpoint strings are compile-time
  constants (`{{BASE_URL}}/…`); `AppUrls` holds payment return pages; share link host/scheme
  hardcoded in `share_service.dart`. No `--dart-define`, no flavors.
- Native secrets are handled well: Maps API key from `android/local.properties` or the
  `MAPS_API_KEY` env var → `manifestPlaceholders`; iOS `Secrets.xcconfig` (gitignored) with a
  committed `Secrets.example.xcconfig`; release signing only when `key.properties` exists.

### Logging
- `talker_flutter ^5.0.2` global instance, disabled in release; `TalkerRouteObserver`,
  `TalkerDioLogger` (debug only). Base cubits log loading/response via `talker.info`.
  `debugPrint` only in the debug bloc observer, chat cubit, and push bus. One `print` in a
  commented block.

### Analytics / crash reporting
- `firebase_crashlytics ^5.0.7` via `ErrorReporter` (`report`, `setUser`, `setLocale`; no-op
  unless `kReleaseMode && Firebase.apps.isNotEmpty`). `FlutterError.onError = recordFlutterError`
  (non-fatal), `PlatformDispatcher.onError` + `runZonedGuarded` fatal, repository and bloc
  errors non-fatal. No analytics package.

### Push notifications
- `firebase_messaging ^16.1.1` + `flutter_local_notifications ^19.5.0`,
  `lib/core/services/notification_service.dart` (630 lines, all static).
- `attachMessageListeners()` called from `main()` before `runApp` (documented reason: pushes
  arriving before the first screen were dropped). `init()` runs once after the splash routes
  (permission request with Android 13 check, "open settings" dialog shown once, channels whose
  id must match the manifest default, initial-message handling).
- Background isolate handler posts local notifications for data-only pushes; stable per-message
  notification ids; topic subscribe/unsubscribe with persisted topic list for logout cleanup;
  token register/remove with backend only when authenticated.
- `notification_link_handler.dart`: pure `notificationDestination()` → sealed
  `NotificationRoute | NotificationUrl`, then `handleNotificationLink` pushes via `appRouter`.
  Unit-tested. The `link_type` contract is app-specific, the pattern is generic.

### IAP / payments
- No IAP. Hosted payment gateway opened in `webview_flutter`; completion detected from the
  gateway's redirect URL (`payment_method_step.dart`), with server-side confirmation and a
  pending top-up id persisted for reconciliation (`SharedPreferencesKeys.PENDING_TOPUP_ID`).

### Permissions
- `permission_handler ^12.0.1`: notification permission in `NotificationService`,
  `openAppSettings` action in `ImagePickerService` failure snackbar. Location via
  `Geolocator.checkPermission/requestPermission/openAppSettings` in the maps picker.

### Deep links
- No inbound deep links (no `app_links`/`uni_links`, no `VIEW` intent filters, no associated
  domains). Push notification taps route through go_router paths. `ProductShareService` builds
  web and custom-scheme product links that the app cannot open yet.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/services/api_service.dart | Dio wrapper (headers, token, 401 hook, logging) | `ApiServiceBase`; `ApiService(baseUrl, dioClient:, secureStorageManager:)`; get/post/put/patch/delete(NetworkRequestParams); updateHeaders(token, customHeaders); setLanguage; clearToken; onUnauthorized | dio, talker_dio_logger, SecureStorageManager | generic |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | request execution + HTTP/Dio → Failure mapping | `handleRequest<T>(path, method, parser, data, queryParameters, options)` | ApiService via get_it, Failure | generic |
| lib/core/base_architecture/data/repository/base_repo.dart | Either wrapper | `handleNetworkCall<T>(call)` | dartz, talker, ErrorReporter | generic |
| lib/core/base_architecture/data/models/base_response_model/base_success_response.dart | envelope + pagination | `BaseSuccessResponse<T>.fromJson(json, fromJsonT)`, `parseList`, `PaginationModel` | equatable | generic (envelope shape is backend-specific) |
| lib/core/base_architecture/data/models/base_success_model.dart | marker base for success payloads | `BaseSuccessModel`, `BaseSuccessModelWithData<T>` | equatable | generic |
| lib/core/base_architecture/data/models/base_request_model/network_request_model.dart | request params DTO | `NetworkRequestParams(uri, data, queryParameters, options, cancelToken, progress)` | dio | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart | cubit base for sealed states | `handleRequest(loadingState, call, onSuccess, onError, showLoading)`, `resetSession`, guarded `emit` | flutter_bloc, dartz | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/base_state.dart | Equatable base + LoadingState/ErrorState | — | equatable | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state.dart | status/failure/success state base | abstract `copyWith` | equatable | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart | cubit base for single-class states | `handleRequest(call, onNotDefaultSuccess/Failure/Loading)`, `resetSession`, guarded `emit` | flutter_bloc, dartz | generic |
| lib/core/app_cubit/app_cubit.dart (+app_state.dart) | session (token/user), logout fan-out | setUser, setToken, isGuest, logout | ~6 feature singletons, ErrorReporter | app-specific (pattern generic) |
| lib/core/app_router/app_router.dart | GoRouter config | `appRouter`, `rootNavigatorContext`, `navIndexForBranch`, `branchForNavIndex` | all screens/cubits | app-specific |
| lib/core/app_router/app_routes_names.dart | path constants | static strings | — | app-specific |
| lib/core/services/di_container.dart | GetIt registrations, global talker | `diService`, `talker`, `diContainerSetup()` | everything | app-specific |
| lib/core/services/session_expiry_service.dart | single-flight 401 teardown | `expire()` | AppCubit, AuthRepository, appRouter | app-specific (pattern generic) |
| lib/core/services/notification_service.dart | FCM + local notifications | attachMessageListeners, init, handleBackgroundMessage, registerTokenIfAuthenticated, removeTokenFromBackend, resetDeviceToken, showLocalNotification, cancel*, subscribe/unsubscribeFromTopic, conversation topic helpers, logRemoteMessage | firebase_messaging, flutter_local_notifications, permission_handler, prefs, repos | mostly generic, chat topics app-specific |
| lib/core/services/notification_link_handler.dart | push payload → destination | `handleNotificationLink(...)`, `notificationDestination(...)`, sealed `NotificationDestination` | appRouter, ChatPushMessage, UrlHandler | pattern generic, contract app-specific |
| lib/core/services/chat_push_bus.dart | parse chat pushes, broadcast to open chat | `ChatPushMessage.tryParse/topicFor`, bus stream | — | app-specific |
| lib/core/services/error_reporter.dart | Crashlytics facade | report, setUser, setLocale | firebase_crashlytics | generic |
| lib/core/services/bloc_observer.dart | bloc logging / crash forwarding | `AppBlocObserver`, `CrashReportingBlocObserver` | flutter_bloc, ErrorReporter | generic |
| lib/core/services/toast_manager.dart | overlay toast manager | `ToastManager.showToast(...)`, `context.showToast(...)` | AnimatedCustomToast | generic |
| lib/core/services/show_loading_dialog.dart | blocking loader | `showLoadingDialog(...)`, `context.showLoading(...)` | material | generic (hardcoded white/size) |
| lib/core/services/image_picker_service.dart | pick image/video/multi with localized failure + settings action | pickImage, pickVideo, pickMultipleImages | image_picker, permission_handler, easy_localization | generic |
| lib/core/services/share_service.dart | product share text + links, copy link | `ProductShareService.productLink/productSchemeLink/shareProduct/copyProductLink` | share_plus, CurrencyFormatter | app-specific |
| lib/core/services/url_handler.dart | launch url/tel/mailto/sms/WhatsApp | openUrl, makeCall, sendEmail, sendSMS, openWhatsApp | url_launcher | generic |
| lib/core/services/app_validator.dart | form validators (localized) | isNotEmpty, isValidEmail, isValidPhone, isValidSaudiPhone, isValidPassword(value, isLogin), confirmPassword, isNumeric (buggy), isNotEmptyImage, ibanValidator (mod-97), customValidator | easy_localization | generic |
| lib/core/services/app_version_service.dart | running version/build/platform | version, buildNumber, platform, init() | package_info_plus | generic |
| lib/core/services/app_version_comparator.dart | version compare | `compare(a, b) → int?` | — | generic |
| lib/core/services/currency_formatter_service.dart | money formatting from server currency config | `format(amount, currency:, keepZeroDecimals:)`, fallbackCurrency | app_config models | semi-generic |
| lib/core/utilities/helpers/currency_formatter.dart | cents/major → string using live config | `CurrencyFormatter.formatCents/formatAmount`, `context.formatCents/formatAmount` | AppConfigCubit via get_it | app-specific |
| lib/core/services/debounce.dart | timer debounce | `Debounce(milliseconds).run/cancel` | — | generic |
| lib/core/services/int_parser.dart / double_parser.dart / string_parser.dart | tolerant JSON field parsing | `IntParserService.parse`, `DoubleParserService.parse`, `StringParserService.parse` (blank/"null" → null) | — | generic |
| lib/core/services/language_flags_service.dart | locale → flag emoji | `LanguageService.getFlagEmoji` | — | generic |
| lib/core/services/phone_handeler_service.dart | prefix 0 | `ensureStartsWithZero` | — | generic (trivial, misspelled file) |
| lib/core/services/secure_storage_manager.dart | secure storage wrapper | write, read, delete, clearAll, containsKey | flutter_secure_storage | generic |
| lib/core/services/shared_preferences_manager.dart | prefs singleton | init, setValue, getValue, remove, clear | shared_preferences | generic |
| lib/core/utilities/failures/failure.dart | Failure hierarchy | see summary | easy_localization | generic |
| lib/core/utilities/failures/error_details_model.dart | field error | `ErrorDetail(field, messages)` | — | generic |
| lib/core/utilities/constants/app_languages.dart | language table | see §3 | flutter/widgets | generic |
| lib/core/utilities/constants/colors.dart | palette | `AppColors.*`, `newColor` | material | app-specific values |
| lib/core/utilities/constants/icons.dart / images.dart / temp_images.dart | asset paths, `AppIcons.svg(...)` helper | static paths | flutter_svg | app-specific |
| lib/core/utilities/constants/keys/api_keys.dart / app_urls.dart / shared_preferences_keys.dart | endpoint/storage keys | static constants | — | app-specific |
| lib/core/utilities/constants/constant_lists.dart | onboarding items, currency image codes | static lists | — | app-specific |
| lib/core/utilities/formatters/date_formatter.dart | date formatting | formatDateString (returns hardcoded English error text), formatDate, isMorning | intl | generic (weak) |
| lib/core/utilities/helpers/auth_helper.dart | auth checks from context | isAuthenticated, getUserId | AppCubit | app-specific |
| lib/core/utilities/helpers/image_cache_size.dart | decode width for thumbnails | `thumbnailCacheWidth(context, side)` | — | generic |
| lib/core/utilities/responsive/responsive.dart | responsive kit | see §3 | — | generic |
| lib/core/extensions/context_extensions.dart | theme shortcuts | theme, textTheme, colorScheme, isAr | material | generic |
| lib/core/extensions/list_extensions.dart | null/empty check | `isNullOrEmpty()` | — | generic |
| lib/core/enums/*.dart | FetchDataStatusEnum, HttpMethod, ToastState, AppRoles (unused) | — | — | generic |
| lib/core/models/selection_model.dart | selection item DTO | fields | — | generic |
| lib/features/app_config/** | remote config: maintenance / force / optional update / currency | `AppConfigCubit.getAppConfig/refreshIfStale/dismissUpdate`, `AppConfigGate`, `showOptionalUpdateSheet` | prefs, AppVersionService/Comparator | generic feature (contract-specific JSON) |
| tool/create_feature.dart / tool/copy_feature.dart | scaffold feature folders / clone a feature with renames | CLI | dart:io | generic |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/buttons/app_default_button.dart | primary/filled button with loading morph, svg icon, min height, tablet width cap 480 | onTap, text, textStyle, child, height, width, radius, margin, padding, isLoading, backgroundColor, textColor, enabled, svgIconPath, borderColor | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart | `AppIconButton` fixed-size icon pill; `AppBackButton` (uses `Navigator.pop`, `arrow_back_ios` auto-mirrors) | child, onTap, height, width, radius, backgroundColor, padding, margin, borderColor / onTap | y |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart | titled TextFormField | title, titleSuffixWidget, controller, hintText, onTap, onChanged, enabled, readOnly, obscureText, keyboardType, validator, inputFormatters, prefix/suffixIcon, styles, maxLength, min/maxLines, icon constraints, focusNode, textAlign, onSaved, onFieldSubmitted, onEditingComplete, borderRadius, colors, textInputAction, contentPadding, constraints | y |
| …/text_form_fields/password_text_form_field.dart | password with toggle | controller, isConfirmPassword, confirmPasswordValidator (unused), title, hintText, isLogin (unused), onChanged | y (buggy) |
| …/text_form_fields/email_text_form_field.dart | email field | controller, title, hintText, readOnly (unused), onChanged | y |
| …/text_form_fields/phone_text_form_field.dart | phone + country code picker chip (Semantics, 48 dp target) | controller, selectedCountry, onCountryChanged, title, hintText, readOnly, onChanged | partial |
| …/text_form_fields/dropdown_text_form_field.dart | string picker via bottom sheet | title, svgPrefixIconPath, hintText, controller, items, validator, onChanged | y |
| …/text_form_fields/dynamic_drop_down_text_field.dart | `DynamicDropdownFormField<T>` popup menu w/ search | title, svgPrefixIconPath, onOptionSelected, options, hintText, displayText, showSearch, enabled, isLoading, initialValue, selectedDisplayText | y (LTR positioning) |
| lib/core/utilities/widgets/app_dialog.dart | info dialog, scrollable body | title, description, actionTitle, contentWidget, onTap | y |
| lib/core/utilities/widgets/confirm_dialog.dart | `showConfirmDialog` → bool | context, title, message, confirmLabel, cancelLabel, destructive | y |
| lib/core/utilities/widgets/show_app_bottom_sheet.dart | `showAppBottomSheet` + `MainView` (title, content, footer) | sheetTitle, sheetContent, primaryBtnText, onTapPrimaryBtn, initial/min/maxChildSize | y |
| lib/core/utilities/widgets/bottom_action_buttons.dart | primary + secondary footer, keyboard-inset aware | primaryBtnText, secondBtnText, onTapPrimaryBtn, onTapSecondBtn | y |
| lib/core/utilities/widgets/image_picker_bottom_sheet.dart | `showImagePickerSheet` camera / gallery / multi | context, onFilePicked, onFilesPicked, pickLimit | y |
| lib/core/services/show_loading_dialog.dart | blocking loading dialog | context, message, barrierDismissible | y |
| lib/core/utilities/widgets/base_fetching_widget.dart | `GenericFetchWidget<B,S,T>`, `BaseLoadingWidget`, `BaseErrorWidget`, `BaseEmptyWidget` | successBuilder, loadingWidget, failureWidget, onRetry / message, onRetry / message | y |
| lib/core/utilities/widgets/base_list_view_widget.dart | `BaseListView<T>` separated list + empty | items, itemBuilder, emptyWidget, emptyWidgetText | y |
| lib/core/utilities/widgets/default_screen.dart | base screen (header row + width-capped body) | body, appbar, pageTitle, pageTitleWidget, hasAppBar, hasBottomMargin, hasBackButton, hasBottomBorder, onBackPressed, floatingActionButton(+Location), topMargin, appBarPadding, bodyPadding, backgroundColor, constrainBodyWidth | y |
| lib/core/utilities/widgets/custom_appbar.dart | `CustomAppBar` (PreferredSize) + `CustomAppBarTitle` | pageTitle, actions | y |
| lib/core/utilities/widgets/shared/widgets/image_widget.dart | `ImageViewerWidget` unified image/avatar | image, user, width, height, radius, borderRadius, color, margin, stackedWidget, onTap, fit, border | partial |
| lib/core/utilities/widgets/shared/screens/image_viewer.dart | `ImageViewerScreen` | imagePath | y |
| lib/core/utilities/widgets/shared/screens/select_location_screen.dart | `LocationPickerScreen` (maps, center pin, my-location) | title, confirmLabel, initialLocation | y |
| lib/core/utilities/widgets/container_with_shadow.dart | shadowed card | child, margin, padding, radius, width, height, image, backgroundColor, border, onTap, boxShadow, shadowBlurRadius | y |
| lib/core/utilities/widgets/custom_chip.dart | chip/badge | title, titleStyle, bgColor, borderColor, txtColor, radius, fontSize, padding, onSelect | y |
| lib/core/utilities/widgets/selection_chip_widget.dart | selected/unselected chip | isSelected, title, onTap | y |
| lib/core/utilities/widgets/custom_radio_group_widget.dart | `CustomRadioGroup<T>`, `CustomSizeRadio<T>` | options, selectedValue, onChanged, prefixText, label / value, groupValue, onChanged, size, colors, animationDuration | y (bug) |
| lib/core/utilities/widgets/app_divider.dart | divider | height, thickness, color, indent, endIndent, widthFactor | y |
| lib/core/utilities/widgets/linear_progress_indicator.dart | `LinearPercentIndicator` | percent, minHeight | y |
| lib/core/utilities/widgets/animated_indicator.dart | `IndicatorWidget` dot→pill | index, currentStep | y |
| lib/core/utilities/widgets/toasts/animated_custom_toast.dart | toast visuals | message, state, duration, location | y |
| lib/core/utilities/responsive/max_width_body.dart | width cap | child, tabletMaxWidth, desktopMaxWidth, alignment | y |
| lib/core/utilities/responsive/scrollable_form_body.dart | scroll-safe form | child, padding | y |
| lib/core/utilities/responsive/responsive.dart | `ResponsiveLayout` | phone, tablet, desktop (WidgetBuilder) | y |
| lib/features/app_config/presentation/widgets/app_config_gate.dart (+screens/force_update_screen.dart, maintenance_screen.dart) | root gate overlay + update sheet | child | y |
| lib/features/home/presentation/widgets/section_header_widget.dart | two-tone section header + action | firstTitleSyllable, secondTitleSyllable, subtitle, actionTitle, onActionTap | partial |
| lib/features/checkout/presentation/widgets/step_indicator.dart | checkout steps | currentStep | n |
| lib/features/checkout/presentation/widgets/payment_failed_view.dart | payment failure state | onReturnToPayment, onViewOrder | n |
| lib/features/products/presentation/widgets/product_grid_view.dart | masonry product grid (responsive columns) | products, isSliver, bottomPadding | n |
| lib/features/bottom_nav/presentation/screens/bottom_nav_screen.dart (+widgets/navigation_widget.dart) | floating 5-slot bottom bar host for StatefulNavigationShell | child, selectedNavIndex, onNavTap | n |

Loading skeletons use `skeletonizer` inline in 15 screens/rails (no shared shimmer widget).
No shared pagination list widget (each screen wires its own `ScrollController`).

## 6. Packages (`pubspec.yaml`)

- **State:** flutter_bloc ^9.1.1, bloc ^9.1.0, hydrated_bloc ^10.1.1, equatable ^2.0.7, meta ^1.18.0
- **DI:** get_it ^9.0.5
- **Routing:** go_router ^16.3.0
- **Network / FP:** dio ^5.7.0, dartz ^0.10.1, talker_dio_logger ^5.0.2
- **Storage:** shared_preferences ^2.3.3, flutter_secure_storage ^9.2.4, path_provider ^2.1.5
- **L10n:** easy_localization ^3.0.7, intl ^0.20.2, flutter_localizations (sdk)
- **UI:** flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, skeletonizer ^2.1.0+1, flutter_animate ^4.5.2, flutter_staggered_grid_view ^0.7.0, flutter_slidable ^4.0.3, flutter_rating_bar ^4.0.1, pinput ^5.0.2, cupertino_icons ^1.0.8; unused: cached_network_image ^3.4.1, dotted_border ^3.1.0, font_awesome_flutter ^10.12.0, animate_do ^4.2.0
- **Firebase:** firebase_core ^4.4.0, firebase_messaging ^16.1.1, firebase_crashlytics ^5.0.7, flutter_local_notifications ^19.5.0
- **Media / device:** image_picker ^1.2.2, file_picker ^11.0.3, permission_handler ^12.0.1, url_launcher ^6.3.1, webview_flutter ^4.10.0, share_plus ^12.0.1, package_info_plus ^9.0.0, country_picker ^2.0.2
- **Maps / ML:** google_maps_flutter ^2.3.2 (+ _android ^2.18.4, _platform_interface ^2.14.0), geolocator ^14.0.1, google_mlkit_translation ^0.15.1, google_mlkit_language_id ^0.15.1
- **Utils:** collection ^1.19.0, uuid ^4.5.2, clock ^1.1.2 (testable now)
- **Build tooling (in dependencies):** flutter_native_splash ^2.4.3, flutter_launcher_icons ^0.14.4 (configs in pubspec / flutter_launcher_icons.yaml)
- **Dev:** flutter_test, flutter_lints ^6.0.0

## 7. Quality notes

- **Null safety:** full (Dart 3.7, uses wildcard `_` params and pattern matching/sealed classes).
- **Lints:** `include: package:flutter_lints/flutter.yaml`, no extra rules. CI
  (`.github/workflows/ci.yml`) runs `flutter analyze --no-fatal-infos` and `flutter test` on
  push/PR to dev/main with Flutter 3.44.0. `docs/IMPROVEMENTS.md` tracks remaining analyzer
  infos (Radio API migration, naming).
- **Tests:** 65 `_test.dart` files — unusually strong for this portfolio. Coverage targets
  silent-failure areas: layout matrices (sizes × scale × RTL), translation parity, hardcoded
  string guard, Dio error mapping through a fake `HttpClientAdapter`, 401/session teardown,
  cubit race conditions (epoch), pagination append, model parsing of blank/`"null"` fields,
  router branch mapping, notification routing. Fakes are hand-written; no mocktail/bloc_test.
- **Documentation:** CLAUDE.md (responsive/text-scaling/RTL rules), README (architecture,
  conventions, l10n procedure), `docs/BUGS.md` (722 lines) and `docs/IMPROVEMENTS.md` (261
  lines) with IDs referenced from test names, `lib/features/cart/README.md`.
- **Smells / duplication:** see SMELLS line. Biggest structural ones: two base cubits; per-cubit
  pagination copies; hand-written sentinel `copyWith` in every state; 655-line DI file and
  765-line router importing every feature; `AppCubit` knowing about 6 feature cubits; hardcoded
  base URL with no environment separation; theme-vs-widget duplication in `AppTextFormField`;
  `ImageViewerWidget` coupled to `UserModel` and not disk-caching network images.
- **Deprecated APIs:** none of `WillPopScope`, `textScaleFactor`, `MaterialStateProperty`,
  `withOpacity` remain (uses `PopScope`, `TextScaler`, `withValues`). Remaining: `Radio`
  `groupValue/onChanged` (15 uses, deprecated in favor of `RadioGroup`), legacy `ButtonThemeData`.
- **Secrets hygiene:** no API keys/tokens found in Dart/native source. `google-services.json`,
  `GoogleService-Info.plist` and `lib/firebase_options.dart` are committed (standard but worth a
  template rule); `android/app/upload-keystore.jks` exists locally and is gitignored (never committed);
  `ios/Flutter/Secrets.xcconfig` is gitignored with an example file committed.
