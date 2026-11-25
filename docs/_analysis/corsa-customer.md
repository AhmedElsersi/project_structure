## Summary for comparison

```
PROJECT: corsa-customer | path: D-index/Corsa/customer | stack: Flutter, Dart SDK ^3.12.0 (go_router 17, flutter_bloc 9, dio 5, get_it 9) | last commit: 2026-10-14 | source files: 338
ARCH: clean-arch feature-first (the "Tebbr house style", ported and improved) — lib/core/ (base_architecture data+presentation, services, theme, router, shared widgets) + lib/features/<f>/{data(data_sources, models, repo), domain(use_cases, only for multi-repo flows), presentation(managers, screens, widgets)}
STATE: flutter_bloc Cubits — BaseSingleStateCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart) on BaseSingleClassState{status,failure,success}; BaseCubit.handleRequest multi-class (…/managers/base_cubit/base_cubit.dart); both have safeEmit, a per-cubit Dio CancelToken cancelled in close(), debounce()
DI: get_it (manual, no codegen) — lib/core/services/di_container.dart (core) + lib/core/services/features_di.dart (feature registrations; lazy singletons for services/repos/app-level cubits, registerFactory/FactoryParam for screen cubits)
ROUTING: go_router — lib/core/app_router/app_router.dart (+ auth_routes.dart, shell_routes.dart = StatefulShellRoute.indexedStack with shared sub-routes mounted under every tab, route_builders.dart) — guards: global redirect only bounces a cold start through splash (?redirect=); guest gate is imperative requireAuth() (lib/core/utilities/helpers/auth_helper.dart); errorBuilder screen — deep links: app_links → ActionHandler (custom scheme + https paths), pending until router ready
NETWORK: dio — interceptors: _CorsaInterceptor (QueuedInterceptorsWrapper: 401 shared refresh + retry, GET network-error retry, 426/503 system-override callback), TalkerDioLogger (Authorization hidden), MockApiInterceptor (last, when USE_MOCKS) | token refresh: y (one queued refresh on a second bare Dio, then onSessionExpired) | retry: y (idempotent GETs, 2x, 400/800 ms) | error mapping: BaseRemoteDataSource.failureFromResponse maps HTTP status → Failure subclasses keeping statusCode + backend `code` + field errors (HTML/plain 5xx bodies safe); repos wrap in Either; Idempotency-Key helper | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/base_architecture/data/repository/base_repo.dart
RESULT_TYPE: Either (dartz) — lib/core/utilities/failures/failure.dart (+ error_details_model.dart)
STORAGE: shared_preferences + flutter_secure_storage (tokens) — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart
L10N: easy_localization — en, ar; start locale from prefs, fallback en, useOnlyLangCode; assets/translations/{en,ar}.json (~430 lines each) — hardcoded UI strings: few (sort-option fallbacks, Android channel names, default Failure messages)
RTL: Directional=31 vs LeftRight=17 (14 of the 17 are in custom_curved_navigation_bar.dart, which mirrors itself explicitly; rest are full-width left:0/right:0)
THEME: lib/core/theme/light_theme/light_theme.dart (lightThemeFor(lang), cached per screenutil scale) — dark mode n | component themes in ThemeData y (appBar, elevated/outlined/text buttons, inputs, switch, chip, bottomSheet, dialog, divider, progress) | AppColors (lib/core/utilities/constants/colors.dart, 100–800 ramps) | TextThemeLight (light_widget_themes/text_theme.dart, M3 slots in .sp) | Inter (en) / Cairo (ar), bundled
RESPONSIVE: flutter_screenutil, design 375×812 computed from the real screen so the factor stays 0.85–1.15 (lib/core/utilities/screen_util_config.dart) + context.windowClass / context.responsive() (lib/core/extensions/context_extensions.dart) — breakpoints: 600 / 840 on width (Material window classes); isPhoneSized = shortestSide < 600; AdaptiveShell swaps bottom nav for NavigationRail
TEXT_SCALING: MaterialApp.builder → MediaQuery.withClampedTextScaling(0.85–1.5) (AppTextScale, lib/core/utilities/constants/app_text_scale.dart); local 1.2 clamp for fixed slots (nav, titles, chips); AdaptiveRow stacks above 1.3; AppDimens.extent() grows fixed-height slots with text
ENV/FLAVORS: --dart-define-from-file=env/<dev|staging|prod>.json (git-ignored; *.example.json committed) read by AppEnv in lib/core/utilities/constants/keys/api_keys.dart; no native flavors; USE_MOCKS defaults to true when BASE_URL undefined; maps keys via Gradle property / git-ignored local xcconfig
LOGGING: talker_flutter (global `talker` in di_container.dart) + TalkerDioLogger + TalkerRouteObserver + AppBlocObserver; 3 debugPrint left
ANALYTICS/CRASH: firebase_crashlytics (release only: FlutterError.onError, PlatformDispatcher.onError, runZonedGuarded); no analytics
PUSH: fcm + flutter_local_notifications — lib/core/services/notification_service.dart (Android channels, iOS/Android 13 permission, POST/DELETE device registration, token refresh, foreground display, tap → ActionHandler)
PAYMENTS/IAP: gateway-agnostic hosted payment page in webview_flutter (return-URL prefix intercept) + payment-status polling (2 s, max 60 s) + Idempotency-Key on order POST — lib/features/checkout/; no IAP
PERMISSIONS: permission_handler (camera, notifications) + geolocator flow (service disabled / denied / denied forever / open settings) in lib/core/services/location_service.dart
DEEP_LINKS: app_links — lib/core/services/deep_link_service.dart → ActionHandler.fromUri (custom scheme + web paths); go_router paths
MEDIA/FILES: image_picker + flutter_image_compress (MediaService, ≤1600 px JPEG q80), cached_network_image (AppNetworkImage with thumb/full variant by size×dpr), flutter_svg, lottie, skeletonizer, share_plus, url_launcher, path_provider, webview_flutter; multipart upload with progress (UploadService)
TESTS: 20 test files (~92 cases) — cubits (bloc_test + mocktail), failure mapping, mock API + fixture validity, enum fallbacks, widget matrix (4 text scales × 5 screen sizes × en/ar), splash goldens, system gate
LINTS: flutter_lints (package:flutter_lints/flutter.yaml), 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/services/api_service.dart — Dio wrapper: queued single refresh + retry, GET retry, 426/503 override hook, onSessionExpired, header redaction, Idempotency-Key helper, mock slot — quality 5 — coupling: low (ApiKeys auth paths, SharedPreferencesKeys, global talker)
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — handleRequest<T> + status→Failure mapping (field errors, HTML 5xx, timeout bodies, cancel) — quality 5 — coupling: low (diService<ApiService>, l10n keys)
- lib/core/utilities/failures/failure.dart — Failure hierarchy with statusCode / backend code / field errors, fieldError(), Cancelled/Permission/Timeout — quality 5 — coupling: none
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart (+ base_single_class_state.dart) — single-state cubit with handleRequest, safeEmit, CancelToken, debounce — quality 4 — coupling: low (talker)
- lib/core/services/mock/ (mock_api_interceptor.dart, mock_route_table.dart, mock_settings.dart) — asset-driven mock backend: routes.json, fixtures, latency, failNext/failAll, MOCK_FAIL define, stateful handlers — quality 5 — coupling: low (ApiKeys.API_PREFIX, AppEnv)
- lib/core/base_architecture/data/models/base_response_model/base_success_response.dart — envelope + PaginationModel (flat or nested meta) + raw meta accessors + parseList — quality 4 — coupling: none (envelope-shape specific)
- lib/core/utilities/converters/json_helpers.dart — defensive Json.toInt/boolOr/str/map/listOf/date — quality 5 — coupling: none
- lib/core/utilities/screen_util_config.dart + lib/core/utilities/constants/app_text_scale.dart + lib/core/extensions/context_extensions.dart — clamped design size, text-scale policy, window classes — quality 5 — coupling: none
- lib/core/services/connectivity_service.dart + lib/core/app_cubit/connectivity_cubit.dart + lib/core/utilities/widgets/no_internet/no_internet_gate.dart — DNS-probe connectivity with adaptive polling, banner-vs-fullscreen gate — quality 4 — coupling: none
- lib/core/app_cubit/app_cubit.dart — session cubit (restore, startSession, reset) with session start/end hooks, cached bootstrap, system override — quality 4 — coupling: medium (imports features/auth UserModel, BootstrapModel)
- lib/core/services/notification_service.dart — FCM + local notifications, channels, device registration, tap routing — quality 4 — coupling: medium (SharedRepository, ActionHandler, AppActionModel); cold-start pendingAction never consumed
- lib/core/services/location_service.dart — permission states + current position with timeout/last-known fallback + stream — quality 4 — coupling: none (GeoPointModel, Failure)
- lib/core/services/socket_service.dart — Pusher/Laravel Reverb private channels via dart_pusher_channels, reconnect, connectionStream — quality 3 — coupling: low (ApiKeys) — on() before connect() returns an empty stream
- lib/core/services/deep_link_service.dart — app_links with pending-until-router-ready + de-dupe — quality 4 — coupling: low (ActionHandler)
- lib/core/theme/light_theme/ (light_theme.dart + light_widget_themes/*.dart) — per-widget theme files, locale-dependent font, scale-aware cache — quality 4 — coupling: low (AppColors, AppDimens)
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/default_screen.dart — base scaffold (DefaultScreen) — body, pageTitle/pageTitleWidget, titleActions, hasBackButton, overlayHeader, maxContentWidth, bottomAction (sticky), safeAreaTop/Bottom, showBackgroundDecoration — quality 5 — generic? y
- lib/core/utilities/widgets/buttons/app_default_button.dart — primary button + AppSecondaryButton + AppTextButton — text, onTap, style: AppButtonStyle{primary,gold,danger,small,outlined,goldOutlined,text}, isLoading, enabled, leading/trailingIcon, trailingArrow, expand, minHeight, child, semanticLabel — quality 5 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart — icon button (AppIconButton, .svg ctor) + AppBackButton (RTL-mirrored) — child/asset, onTap, round, badge, tooltip, shadow — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — text field (AppTextFormField) + AppTextArea + DigitsOnlyFormatter — title, hintText, validator, errorText, autofillHints, textInputAction, inputFormatters, prefix/suffix, minHeight, textDirection — quality 5 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password field with toggle + confirm — controller, isConfirmPassword, confirmAgainst, isLogin — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart — email field — controller, title, errorText — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart — E.164 phone field with country picker — controller, countries, initialCountry, onCountryChanged — quality 4 — generic? y (default country from config)
- lib/core/utilities/widgets/text_form_fields/otp_form_field.dart — OTP boxes, autofill, paste, auto-submit — length, controller, onCompleted, hasError — quality 5 — generic? y
- lib/core/utilities/widgets/app_search_field.dart — search field with debounce/clear + SortDropdownChip — controller, onChanged, debounce, compact, readOnly, trailing — quality 4 — generic? y
- lib/core/utilities/widgets/base_fetching_widget.dart — state renderer GenericFetchWidget<B,S,T> + BaseLoadingWidget + BaseErrorWidget + BaseEmptyWidget — successBuilder, skeletonBuilder, isEmpty/emptyBuilder, onRefresh, hasData (keep data while refreshing), onRetry — quality 5 — generic? y
- lib/core/utilities/widgets/shared/screens/paginated_list_view.dart — pagination list/grid — items, itemBuilder, onLoadMore (80 %), hasReachedMax, isLoadingMore, loadMoreFailure (inline retry), gridDelegate, header/footer, onRefresh — quality 5 — generic? y
- lib/core/utilities/widgets/show_app_bottom_sheet.dart — showAppBottomSheet (sheet on phone, dialog on tablet, keyboard-safe, 90 % max) + AppBottomSheet + showAppConfirmDialog — builder, title, isDismissible, maxHeightFraction / title, message, confirmText, danger — quality 5 — generic? y
- lib/core/utilities/widgets/skeletons/app_skeletons.dart — shimmer (skeletonizer) AppSkeleton, SkeletonBox, ProductCardSkeleton, TileSkeleton, ListTileSkeleton, SkeletonList, SkeletonGrid(item) — quality 4 — generic? y (ProductCardSkeleton app-shaped)
- lib/core/utilities/widgets/shared/widgets/app_image.dart — network/asset/file image (AppNetworkImage, AppAssetImage, String.imageProvider) — url or ImageRefModel, radius, heroTag, memCacheWidth, skeleton placeholder, logo fallback — quality 4 — generic? y
- lib/core/utilities/widgets/app_svg_icon.dart — SVG icon with tint + RTL mirroring — asset, size, color, matchTextDirection — quality 5 — generic? y
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart + lib/core/services/toast_manager.dart — overlay toast (context.showToast) with screen-reader announce, de-dupe — message, state, duration, location — quality 4 — generic? y
- lib/core/utilities/widgets/no_internet/no_internet_gate.dart + no_internet_screen.dart — offline gate/banner — child — quality 4 — generic? y
- lib/core/utilities/widgets/app_result_view.dart — success/failure/empty result screen — title, message, illustration, infoLabel/Value, primary/secondary actions, isLoading — quality 4 — generic? y
- lib/core/utilities/widgets/app_main_card.dart — base card (AppMainCard) + AppMenuTile (settings row) — padding, radius, borderColor, hasShadow, onTap / label, icon, trailingText, danger — quality 4 — generic? y
- lib/core/utilities/widgets/custom_chip.dart — chip with tone + StatusBadgeLike (CustomChip.status) — title, tone, selected, outlined, small, onSelect, onDelete — quality 4 — generic? y
- lib/core/utilities/widgets/app_tab_switcher.dart — tabs, underline/pill, counts, scrolls at large text — tabs, selectedIndex, onTabChanged, counts, style — quality 4 — generic? y
- lib/core/utilities/widgets/adaptive_row.dart — row that stacks at large text / narrow width — children, spacing, forceColumn, minRowWidth — quality 4 — generic? y (driver copy is better)
- lib/core/utilities/widgets/adaptive_shell.dart — AdaptiveShell (bottom nav ↔ NavigationRail) + AppBottomNav + AppNavItem — items, currentIndex, onTap, child — quality 4 — generic? y
- lib/core/utilities/widgets/custom_curved_navigation_bar.dart — curved notched bottom bar, RTL-aware — items, index, onTap, colors, height, buttonSize, isSvgIcons — quality 3 — generic? y (465 lines, hardcoded shadow colour)
- lib/core/utilities/widgets/app_avatar.dart — AppAvatar (initials fallback) + StoreLogo — image, initials, size, circle — quality 4 — generic? y
- lib/core/utilities/widgets/app_divider.dart — divider — height, color, indent — quality 3 — generic? y
- lib/core/utilities/widgets/app_switch.dart — adaptive switch with semantics — value, onChanged, semanticLabel — quality 3 — generic? y (driver adds isLoading)
- lib/core/utilities/widgets/section_header.dart — section title + "View all" — title, onViewAll — quality 4 — generic? y
- lib/core/utilities/widgets/timeline_stepper.dart — horizontal/vertical server-driven stepper — steps, vertical — quality 4 — generic? y (uses OrderStepModel)
- lib/core/utilities/widgets/image_picker_tile.dart — image pick tile with upload progress — file, onPick, onRemove, progress — quality 4 — generic? y
- lib/core/utilities/widgets/language_option_card.dart — language choice card — name, nativeName, flagAsset, selected — quality 4 — generic? y
- lib/core/utilities/widgets/simple_html_view.dart — minimal HTML (h1/h2/p/li) renderer — html — quality 3 — generic? y
- lib/core/utilities/widgets/cms_blocks_view.dart — server CMS blocks renderer — blocks — quality 4 — generic? partly (CmsBlockModel contract)
- lib/core/utilities/widgets/shared/screens/image_viewer_screen.dart — full-screen zoom gallery — ImageViewerArgs(images, initialIndex, heroTag) — quality 4 — generic? y
- lib/core/utilities/widgets/shared/screens/html_screen.dart — HTML page screen — HtmlPageArgs(title, html) — quality 3 — generic? y
- lib/core/utilities/widgets/price_text.dart — server-formatted price + compare-at — price, compareAtPrice, style — quality 4 — generic? partly (MoneyModel)
- lib/core/utilities/widgets/price_summary_card.dart — server price lines card — summary — quality 4 — generic? partly
- lib/core/utilities/widgets/quantity_stepper.dart — +/- stepper with delete at min — quantity, onChanged, onDelete, min, max, isLoading — quality 4 — generic? y
- lib/core/utilities/widgets/rating_stars.dart — rating stars + count — rating, reviewsCount, size — quality 3 — generic? y
- lib/core/utilities/widgets/heart_toggle.dart — favourite toggle — isFavorite, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/selectors.dart — ColorSwatchSelector / SizeSelector — options, selectedId, onChanged — quality 3 — generic? y (e-commerce)
- lib/core/utilities/widgets/cards/product_card.dart, catalog_cards.dart, promo_banner.dart (barrel app_cards.dart) — ProductCard, CategoryCircle/Card, BrandTile, FeaturedStoreCard, StoreListTile, PromoBanner(style) — quality 4 — generic? n (catalog-specific)
NOTABLE_IDEAS: asset-driven mock backend as the last Dio interceptor with route table, stateful handlers and forced failures, wired to a dev kitchen sink (lib/core/services/mock/, lib/features/dev/presentation/screens/kitchen_sink_screen.dart); USE_MOCKS defaults on only when BASE_URL is undefined (api_keys.dart); queued shared token refresh on a bare Dio (api_service.dart); 403 never logs out; Failure carries backend `code` + fieldError(field) for form errors (failure.dart); 426/503 → SystemConfigGate above the router for force update / maintenance / soft update once per version (lib/features/splash/presentation/widgets/system_config_gate.dart); session start/end hooks on AppCubit so core never imports feature cubits (main.dart _wireSessionHooks); computed screenutil design size clamped 0.85–1.15 (screen_util_config.dart) + window classes; global text-scale clamp + AppDimens.extent() + AdaptiveRow; test helper pumping widgets across scale×size×locale matrix (test/helpers/pump_at_scale.dart, test/core/widgets/text_scale_matrix_test.dart); StatefulShellRoute with shared sub-routes under every tab + context.pushTab() (app_router.dart, shell_routes.dart); scoped ShellRoute to share a cubit across a multi-screen flow (auth_routes.dart reset-password, checkout); showAppBottomSheet → dialog on tablets; server-driven ActionHandler used by banners, pushes and deep links (action_handler.dart); enum fromValue → unknown on every wire enum (app_enums.dart); TrackOrderUseCase = Stream combining initial GET + socket events + polling fallback while socket is down (lib/features/orders/domain/use_cases/track_order_use_case.dart); runtime-rendered SVG map markers + polyline decoder (map_service.dart); feature scaffolder (create_feature.dart, --use-cases); Figma asset export tool (tool/export_figma_assets.dart); docs/CONVENTIONS.md records deviations from the source template
SMELLS: AppInfoService.headers (X-App, X-App-Version, X-Platform, X-Device-Id, X-Timezone) is built but never applied to Dio although ApiService's doc says it is; NotificationService.pendingAction is set on a cold-start push tap but consumePendingAction() is never called, so terminated-state taps are lost; SocketService.on() returns Stream.empty() while not connected and connect() wipes channels, so NotificationBadgeCubit's users.<id> subscription made at login is dead (only TrackOrderUseCase connects before subscribing); /dev/kitchen-sink (with mock-failure toggles) registered in release builds (the driver copy gates it with kDebugMode); BaseSingleStateCubit's loading emit uses copyWith(failure: null), which cannot clear the failure (features add clearFailure ad hoc); BaseCubit logs the literal '\$runtimeType' and surfaces 'Unexpected error: $e' to the UI; retried requests go through the bare Dio, so a 426/503 on a retry skips the override hook; no-op assert in AppNetworkImage; CartCubit's appCubit.stream.listen never cancelled; core/ imports features (AppCubit → features/auth UserModel, router, features_di) and holds customer-only widgets (product/catalog cards, selectors, quantity stepper, ProductListArgs in action_handler.dart) despite the README rule; English channel names and Failure defaults; Google brand colours hardcoded in social_auth_buttons.dart; comments say phones lock portrait but main.dart never sets orientations; 38 `// ignore:` (mostly discarded_futures, a lint that isn't even enabled); no dark theme; flutter_lints only. No deprecated APIs found (0 WillPopScope / withOpacity / MaterialStateProperty / MediaQuery.textScaleFactor; uses withValues, TextScaler, PopScope).
```

---

## 1. Architecture pattern

Clean architecture, feature-first, explicitly modelled on the user's earlier "Tebbr" project
(`Freelance/tebbr`) and recorded in `docs/CONVENTIONS.md` (what was copied, what was dropped,
19 numbered improvements to Tebbr's core, and every place Tebbr's code differed from the build
prompt).

- **data/**: `data_sources/<f>_remote_data_source.dart` extends `BaseRemoteDataSource` and calls
  `handleRequest(path, method, parser)`. Data sources **throw** `Failure`s. Local data sources
  wrap `SharedPreferencesManager`. `models/` are hand-written (`fromJson`/`toJson`, Equatable via
  `BaseSuccessModel`, no codegen), using the defensive `Json.*` helpers. `repo/<f>_repo.dart`
  extends `BaseRepository` and turns every call into `Either<Failure, T>` through
  `handleNetworkCall` (the only `try/catch` for Failures).
- **domain/use_cases/**: only where a flow combines several repositories/services (sign-in session
  start, resolve current location, place order with idempotency key, confirm payment by polling,
  courier quote with uploads, track order as a `Stream`). No entities layer, no repository
  interfaces: use cases depend on concrete repositories.
- **presentation/managers/<x>_cubit/**: one cubit + `part` state per folder. Most cubits extend
  `BaseSingleStateCubit<State extends BaseSingleClassState>` (single state class with
  `status/failure/success` + extra fields + `copyWith`). App-level cubits (cart, wishlist,
  delivery location, notification badge, splash) are lazy singletons provided at the root; screen
  cubits are factories provided per route in the router files.
- **presentation/screens, widgets/**: screens use `DefaultScreen`, `GenericFetchWidget`,
  `PaginatedListView` and the shared widgets in `core/utilities/widgets/`.

Rules enforced by convention (docs/CONVENTIONS.md section 6): no hard-coded colours/sizes/strings in features;
`core/` may import `features/` only from the DI files, `app_router/` and `AppCubit`; a feature
never imports another feature's cubit; money, totals, ETAs, button labels and statuses are
rendered exactly as the server sends them.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                         bootstrap (prefs → easy_localization → Firebase → DI → services → runZonedGuarded), root MultiBlocProvider, MaterialApp.router builder (text clamp, Directionality, NoInternetGate, SystemConfigGate)
├── firebase_options.dart             (exists; secret file, not opened)
├── core/
│   ├── app_cubit/                    AppCubit/AppState (session, config, system override, hooks), ConnectivityCubit/State
│   ├── app_router/                   app_router.dart (GoRouter, pushTab helpers), app_routes_names.dart, auth_routes.dart, shell_routes.dart (tabs + shared sub-routes + CorsaShell), route_builders.dart (fade/no-transition/splash-exit pages, RouteErrorScreen)
│   ├── app_routes_names_export.dart
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/         base_remote_data_source.dart
│   │   │   ├── models/               base_success_model.dart, base_request_model/network_request_model.dart, base_response_model/base_success_response.dart
│   │   │   └── repository/           base_repo.dart
│   │   └── presentation/managers/
│   │       ├── base_cubit/           BaseCubit + BaseState/LoadingState/ErrorState (multi-class states)
│   │       └── base_single_class_state_bloc/  BaseSingleStateCubit + BaseSingleClassState
│   ├── enums/                        app_enums.dart (wire enums with fromValue→unknown), fetch_data_status_enum, http_method_enum, toast_state_enum
│   ├── exports/core_exports.dart     barrel: colors, dimens, shadows, text scale, icons, images, DefaultScreen, extensions + material, go_router, easy_localization, screenutil
│   ├── extensions/                   context (theme, isRtl, windowClass, responsive, insets), string (orNull, latinDigits), list (separated)
│   ├── models/                       shared wire models: AppAction, AppNotification, AuthTokens, Bootstrap (update, maintenance, currency, support, country codes, feature flags, CMS slugs, realtime, tracking), CmsPage, Faq, GeoPoint, ImageRef, Money, OrderStep, PriceSummary, StatusBadge, UploadedFile
│   ├── services/                     api_service, di_container, features_di, notification, socket, location, map, media, upload, launcher, share, social_auth, app_info, connectivity, deep_link, action_handler, toast_manager, app_validator, bloc_observer, secure_storage, shared_prefs, system_status, double_parser
│   │   ├── mock/                     MockApiInterceptor, MockRouteTable, MockSettings, mock_handlers (stateful cart/wishlist/orders)
│   │   └── shared_api/               SharedRemoteDataSource + SharedRepository (bootstrap, uploads, devices, CMS, FAQ, geo autocomplete/reverse/details), geo_models
│   ├── theme/light_theme/            light_theme.dart, my_light_themes_export.dart, light_widget_themes/ (color scheme, text, input, elevated/outlined/text btn, switch, chip, bottom sheet + dialog)
│   └── utilities/
│       ├── constants/                colors, app_dimens, app_text_scale, app_shadows, app_icons, app_images, app_lotties, keys/api_keys.dart (AppEnv + endpoints), keys/shared_preferences_keys.dart
│       ├── converters/json_helpers.dart
│       ├── failures/                 failure.dart, error_details_model.dart
│       ├── formatters/phone_formatter.dart  E.164 helpers
│       ├── helpers/auth_helper.dart  requireAuth() guest gate
│       ├── screen_util_config.dart
│       └── widgets/                  ~45 shared widgets (buttons/, text_form_fields/, cards/, skeletons/, toasts/, no_internet/, shared/screens|widgets/ …)
└── features/                         17 features
    ├── addresses   (saved addresses, delivery location, map picker with Places via backend /geo, coverage check)
    ├── auth        (sign in/up, email OTP, forgot/reset password, Google/Apple)
    ├── cart        (server cart, optimistic debounced stepper, coupon)
    ├── catalog     (categories, product list + filters, product details, reviews)
    ├── checkout    (checkout, payment WebView, result)
    ├── courier     (send-anything delivery form + checkout)
    ├── dev         (kitchen sink)
    ├── help        (help center, FAQ, CMS pages, feedback)
    ├── home        (server-driven sections feed, header)
    ├── notifications (list, badge cubit, bell)
    ├── orders      (list, details, live tracking)
    ├── profile     (profile, settings, edit, change password, delete account, saved cards)
    ├── search      (recent searches local + remote)
    ├── shop        (shop tab, reuses HomeCubit with a different feed)
    ├── splash      (animated splash, language, onboarding, SystemConfigGate)
    ├── stores      (stores list, store details)
    └── wishlist    (app-level ids cubit + list cubit)
```

Representative feature fully expanded, `features/orders/`:

```
orders/
├── data/
│   ├── data_sources/orders_remote_data_source.dart   list, details, tracking, cancel, reorder… via handleRequest
│   ├── models/order_models.dart                      Order, OrderDetails, Tracking (merge() for realtime patches), TrackingEta, TrackingPoint
│   └── repo/orders_repo.dart                         Either wrappers
├── domain/use_cases/track_order_use_case.dart        Stream<List<Tracking>>: initial GET → socket order.updated / driver.location → 10 s polling while socket down → stop when finished
└── presentation/
    ├── managers/order_cubit/ (order_cubit.dart, order_state.dart)
    ├── managers/order_tracking_cubit/ (…)            subscribes to the use-case stream
    ├── managers/orders_cubit/ (…)                    paginated, tabbed list
    ├── screens/order_details_screen.dart, order_tracking_screen.dart, orders_screen.dart
    └── widgets/order_cards.dart
```

## 3. Infrastructure

### State management
`flutter_bloc` 9, Cubits only (no Blocs). Two bases:
- `BaseSingleStateCubit` (`core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart`):
  `handleRequest({call, onNotDefaultSuccess, onNotDefaultFailure, onNotDefaultLoading})` emits
  loading/success/failure into a `BaseSingleClassState` via `copyWith`, ignores
  `CancelledFailure`, guards `isClosed`, logs unexpected errors to talker. Adds `safeEmit`,
  `cancelToken`/`renewCancelToken()` (cancelled in `close()`), `debounce()`.
- `BaseCubit<State extends BaseState>` (`…/base_cubit/base_cubit.dart`): Tebbr's multi-class
  version (`loadingState`, `onSuccess`, `onError`), same guards.
Quality: good and small. Issue: the default loading emit `copyWith(failure: null)` cannot clear
the failure because subclasses' `copyWith` use `??`; features add `clearFailure` flags by hand.
`BaseCubit` logs `'\$runtimeType'` literally.

App-level cubits listen to `AppCubit.stream` and clear themselves on logout (CartCubit,
WishlistCubit, NotificationBadgeCubit, DeliveryLocationCubit).

### DI
`get_it` 9, manual. `core/services/di_container.dart` registers external services, `ApiService`
(with the mock interceptor when `AppEnv.useMocks`), shared API, notification service,
`AppCubit`, `ConnectivityCubit`; delegates feature registrations to
`core/services/features_di.dart` (`initFeatureDataSources/Repos/UseCases/Cubits`). 67 lazy
singletons, 30 factories, 2 `registerFactoryParam` (e.g. `HomeCubit(param1: SectionsFeed.home)`).
Splitting the feature list into its own file keeps the core file copyable between apps, which is
a nice idea; the global `talker` instance also lives in `di_container.dart`.

### Routing
`go_router` 17. `core/app_router/app_router.dart` defines `rootNavigatorKey`, `appRouter`
with `TalkerRouteObserver`, `errorBuilder` → `RouteErrorScreen`, and a redirect that sends any
location to `/splash?redirect=<uri>` until `hasAppInitialized` is set (deep links bounce
through splash). `shell_routes.dart`: `StatefulShellRoute.indexedStack` with five branches; a
`_sharedSubRoutes` list (product, store, search, cart, checkout, orders, location…) is mounted
under every branch, and `tabbedPath()` / `context.pushTab()` push into the current tab's stack.
Flow-scoped cubits are provided by plain `ShellRoute`s (reset-password flow, checkout + payment,
courier form + checkout). Full-screen routes (payment WebView, image viewer) use
`parentNavigatorKey: rootNavigatorKey`. Arguments are passed as typed `extra` objects
(`AuthArgs`, `CheckoutArgs`, `LocationScreenArgs`, …), which won't survive web/state restore but
is fine for mobile. **Guards**: no auth redirect; the guest gate is `requireAuth(context,
returnTo:)` (`core/utilities/helpers/auth_helper.dart`), a sheet that pushes sign-in and returns
`true` when signed in. Splash sends its first destination with a `SplashExit` extra so that
route plays the custom exit transition.

### Networking
`dio` 5. `core/services/api_service.dart`:
- `ApiServiceBase` interface (get/post/put/patch/delete with `NetworkRequestParams`,
  `updateHeaders`).
- Two Dio instances: the main one with interceptors, a bare one for refresh and retries so they
  never deadlock behind the queued interceptor.
- `_CorsaInterceptor extends QueuedInterceptorsWrapper`:
  - 426 / 503 → `onSystemOverride(SystemOverride(forceUpdate|maintenance, message, storeUrl,
    retryAfterSeconds))`.
  - 401 on non-auth paths → if another request already refreshed, retry with the new token;
    else one `_refreshToken()` (refresh token from secure storage, `POST /auth/refresh`), retry,
    or `_endSession()` → `onSessionExpired` (latched so it fires once).
  - Network errors on GET → up to 2 retries with 400 ms × attempt backoff.
- `TalkerDioLogger` with `hiddenHeaders: {authorization}`.
- `MockApiInterceptor` added **last** so logging and refresh logic also run against mocks.
- `ApiService.idempotent(key)` / `newIdempotencyKey()` (uuid v4) for money-moving POSTs.
- `setLanguage()` updates `Accept-Language`.
`BaseRemoteDataSource.handleRequest` maps `DioException` types (timeouts → `TimeoutFailure`,
connection → `NetworkFailure`, cancel → `CancelledFailure`) and HTTP status → `BadRequest` (400,
409, 410, 422, 429 with field errors), `Unauthorized` (401), `Forbidden` (403, never logs out),
`NotFound`, `Timeout` (408/504, or a 500 whose HTML body says "timeout"), `Server` (426/503/5xx
with backend `code`); any parsing exception → `UnknownFailure` with the details to talker only.
Gaps: `AppInfoService.headers` (app/version/build/platform/device id/timezone) is never sent;
retries via bare Dio skip the 426/503 hook.

### Local storage
`SharedPreferencesManager` (singleton, `init()` in main, typed getters, `setJson/getJson`,
`setInstance` test hook) and `SecureStorageManager` (thin wrapper over
`flutter_secure_storage`, injectable). Tokens are in secure storage, user/bootstrap cache in
prefs. Keys in `core/utilities/constants/keys/shared_preferences_keys.dart`. No database.

### Localization and RTL
`easy_localization` 3, `en`/`ar`, JSON in `assets/translations/`, keys namespaced
(`messages.*`, `buttons.*`, `validation.*`, `nav.*`, `system.*`…), 455 `.tr()` call sites, no
`Text('literal')` in lib. `MaterialApp` is keyed by language code (full rebuild on change), the
font switches Inter ↔ Cairo by locale, and `Directionality` is set explicitly in the builder.
RTL handling is deliberate: `EdgeInsetsDirectional`/`PositionedDirectional` (31 uses),
`matchTextDirection` on arrow/chevron SVGs, a mirrored back button, the curved nav bar mirrors
itself. `StringX.latinDigits` converts Arabic-Indic digits for inputs.

### Theming
Light only. `lightThemeFor(languageCode)` builds `ThemeData(useMaterial3: true)` from
`TextThemeLight.forLanguage()` and per-widget theme files under
`core/theme/light_theme/light_widget_themes/` (color scheme from seed + explicit roles, text
theme, input decoration with outline borders and 3-line errors, elevated/outlined/text buttons
with min height, switch, chip, bottom sheet, dialog), caches per screenutil scale.
`AppColors` = numbered ramps (`primary100…800`, `secondary100…800`, `neutral100…1000`, status
colours, `scrim`). `AppDimens` = spacing/radius/min-size tokens + `extent()` + `screenInsets`.
`AppShadows`, `AppIcons` (SVG paths), `AppImages`, `AppLotties` constants.

### Responsive helpers
`flutter_screenutil` with `corsaDesignSize(MediaQuery.sizeOf(context))`: the design size is
derived from the real screen so `.w/.h` scale by at most 0.85–1.15 (tablets don't blow up 2×);
`splitScreenMode: false`, `minTextAdapt: true`. `ContextExtensions.windowClass` (compact < 600,
medium < 840, expanded) on width, `responsive<T>(compact:, medium:, expanded:)`, `isTablet`,
`isPhoneSized` (shortestSide). `AdaptiveShell` swaps the curved bottom bar for a
`NavigationRail` on non-compact widths; forms/details are centred at 560 / 840 px via
`DefaultScreen.maxContentWidth`; `showAppBottomSheet` becomes a dialog on tablets.

### Text scaling
`MaterialApp.builder` wraps everything in `MediaQuery.withClampedTextScaling(minScaleFactor:
0.85, maxScaleFactor: 1.5)`. Fixed slots clamp locally to 1.2 (`AppTextScale.slotMax`: nav
labels, screen titles, chips). `AdaptiveRow` stacks rows above 1.3. `AppDimens.extent(fixed:,
text:)` sizes carousel cells/grid tiles so text grows without clipping. Buttons use a minimum
height and 2-line labels. Tested by a widget matrix (`test/core/widgets/text_scale_matrix_test.dart`).

### Env / flavors
Compile-time only: `--dart-define-from-file=env/<flavor>.json`. Keys (names only):
`FLAVOR, BASE_URL, SOCKET_HOST, SOCKET_KEY, MAPS_API_KEY_ANDROID, MAPS_API_KEY_IOS,
GOOGLE_SERVER_CLIENT_ID, USE_MOCKS` (+ `MOCK_FAIL`). Real files git-ignored, `*.example.json`
committed. `AppEnv.useMocks` defaults to `!bool.hasEnvironment('BASE_URL')`, so a plain `flutter
run` uses mocks and a flavoured build never silently ships them. `AppEnv.baseUrl` has the
production URL as its default (`{{BASE_URL}}`). Android maps key from a Gradle property into
`manifestPlaceholders`; iOS from a git-ignored `Corsa.local.xcconfig`. No native
productFlavors/schemes; the release build uses the debug signing config.

### Logging
`talker_flutter` 5: global `talker` (console logs on), `TalkerDioLogger`,
`TalkerRouteObserver`, `AppBlocObserver` (debug on change, `handle` on error). No `print`;
3 `debugPrint` (Firebase init, session hooks).

### Analytics / crash reporting
Firebase initialised only when `DefaultFirebaseOptions.isConfigured`. In release:
`FlutterError.onError = recordFlutterFatalError`, `PlatformDispatcher.onError`,
`runZonedGuarded` → Crashlytics + talker. No analytics package.

### Push notifications
`core/services/notification_service.dart`: local notifications init with two Android channels
(`orders` high, `general` default), permission request (Android 13 via permission_handler, iOS
via FCM settings, opens settings when permanently denied), `registerDevice(locale)` → `POST
/devices` with platform/app/device id/version, `unregisterDevice()` on session end,
`onTokenRefresh` re-registers, foreground messages shown locally with JSON payload,
`onMessageOpenedApp` and local taps → `ActionHandler.handle(AppActionModel)`. Background handler
in main initialises Firebase only. Bug: `pendingAction` (cold-start tap) is never consumed.

### IAP / payments
No IAP. Checkout: `PlaceOrderUseCase` sends `POST /orders` with an `Idempotency-Key` per
attempt (reused on retry); the server returns a hosted payment URL opened in
`PaymentWebViewScreen` (webview_flutter), which intercepts the return-URL prefix; then
`ConfirmPaymentUseCase` polls the payment status every 2 s for up to 60 s and reports `pending`
rather than failing. Saved cards are listed/removed server-side (`saved_cards_cubit`).

### Permissions
`permission_handler` for camera (MediaService) and notifications; location through
`geolocator` in `LocationService` (`LocationAccess.granted/denied/deniedForever/serviceDisabled`,
`PermissionFailure(permanentlyDenied)`, `openAppSettings/openLocationSettings`).

### Deep links
`app_links` in `DeepLinkService`: initial link + stream, de-dupes, holds a `pending` link until
splash calls `markRouterReady()`, then `ActionHandler.fromUri()` maps
`{{APP_SCHEME}}://product/12`, `…/store/3`, `…/orders/45`, `…/search?q=` and the equivalent
https paths to `AppActionModel`s. Flutter's built-in deep linking is disabled.

### Maps / location / realtime
- `MapService` (`core/services/map_service.dart`): loads a muted JSON map style, renders pickup /
  drop-off / driver markers at runtime from SVG icons into `BitmapDescriptor.bytes` (cached per
  dpr), decodes Google encoded polylines, computes padded `LatLngBounds`, default camera.
- `CorsaMap` (`features/addresses/presentation/widgets/corsa_map.dart`): GoogleMap wrapper with
  draggable centre pin, fit-to-points, lite mode.
- Places autocomplete, reverse geocode and place details go through the backend
  (`SharedRemoteDataSource` `/geo/*`), so no Places key in the app; coverage check endpoint.
- `SocketService` (`core/services/socket_service.dart`): Pusher protocol (`dart_pusher_channels`)
  for Laravel Reverb, private channels authorised against `/broadcasting/auth` with the bearer
  token, auto-reconnect (2 s min), `connectionStream` so features fall back to polling,
  `on(channel, event) → Stream<Map>`, `leave()`, `pause()/resume()`. Host/key come from the
  bootstrap's `realtime` block. Weakness: `on()` before `connect()` returns `Stream.empty()`, and
  `connect()` with new params calls `disconnect()`, which drops existing channels. Only
  `TrackOrderUseCase` connects before subscribing; the badge cubit's subscription is dead.
- `TrackOrderUseCase` (`features/orders/domain/use_cases/track_order_use_case.dart`): the cleanest
  realtime pattern in the project (see summary).

## 4. Services catalog

| File | Purpose | Public methods | Dependencies | Generic? |
|---|---|---|---|---|
| core/services/api_service.dart | Dio wrapper (ApiServiceBase, ApiService, _CorsaInterceptor) | get/post/put/patch/delete(NetworkRequestParams), init(), updateHeaders(token, clearToken, customHeaders), setLanguage(), idempotent(key), newIdempotencyKey(), sessionStarted(), onSessionExpired, onSystemOverride, dio, token | dio, talker_dio_logger, uuid, SecureStorageManager, ApiKeys, MockApiInterceptor | generic (auth path list per app) |
| core/base_architecture/data/data_sources/base_remote_data_source.dart | request + error mapping | handleRequest<T>(path, method, parser, data, query, options, cancelToken, onSendProgress), static failureFromResponse(Response) | ApiService via get_it, easy_localization | generic |
| core/base_architecture/data/repository/base_repo.dart | throw → Either | handleNetworkCall<T>(call) | dartz | generic |
| core/base_architecture/data/models/base_response_model/base_success_response.dart | envelope, pagination | BaseSuccessResponse.fromJson(json, fromJsonT), metaInt(), metaMap(), parseList(), PaginationModel.fromMeta/hasReachedMax | – | generic (envelope shape) |
| core/base_architecture/data/models/base_success_model.dart | Equatable base, WithData, EmptySuccessModel | – | equatable | generic |
| core/base_architecture/data/models/base_request_model/network_request_model.dart | NetworkRequestParams | – | dio | generic |
| core/base_architecture/presentation/managers/base_cubit/*.dart | multi-state cubit | handleRequest(loadingState, call, onSuccess, onError), safeEmit, debounce, cancelToken, renewCancelToken | flutter_bloc, dio | generic |
| core/base_architecture/presentation/managers/base_single_class_state_bloc/*.dart | single-state cubit + state | handleRequest(call, onNotDefault*), safeEmit, debounce, cancelDebounce, cancelToken, renewCancelToken; isLoading/isSuccess/isFailure | flutter_bloc, dio | generic |
| core/app_cubit/app_cubit.dart (+app_state.dart) | session, config, override | restoreSession, startSession(user, tokens), reset(), setUser, setToken, setAppConfig, setSystemOverride, isGuest, configFetchedAt, addSessionStart/EndHook | Secure/SharedPrefs, UserModel (feature), BootstrapModel | mostly generic (user model per app) |
| core/app_cubit/connectivity_cubit.dart | online state | retry() | ConnectivityService | generic |
| core/services/connectivity_service.dart | DNS-probe monitor, adaptive polling, resume recheck | start, recheck, dispose, onStatusChanged, isOnline | dart:io, WidgetsBindingObserver | generic |
| core/services/di_container.dart | GetIt setup + global talker | diContainerSetup() | get_it, talker | generic skeleton |
| core/services/features_di.dart | feature registrations | initFeatureDataSources/Repos/UseCases/Cubits, mockHandlers() | all features | app-specific |
| core/services/secure_storage_manager.dart | secure storage wrapper | write, read, delete, clearAll, containsKey | flutter_secure_storage | generic |
| core/services/shared_preferences_manager.dart | prefs singleton | init, setInstance, setValue, getValue, getString/Bool/Int/StringList, setJson/getJson, remove, clear | shared_preferences | generic |
| core/services/notification_service.dart | FCM + local notifications | init, isPermissionGranted, requestPermission, getToken, registerDevice(locale), unregisterDevice, consumePendingAction, showLocalNotification, onForegroundMessage | firebase_messaging, flutter_local_notifications, permission_handler, SharedRepository, ActionHandler, AppInfoService | mostly generic |
| core/services/socket_service.dart | Pusher/Reverb client | connect(host, key, token, language), on(channel, event), leave, disconnect, resume, pause, isConnected, connectionStream | dart_pusher_channels, ApiKeys | generic (Pusher protocol) |
| core/services/location_service.dart | location permission + position | checkAccess, requestAccess, currentPosition(timeout), positionStream(distanceFilter), openAppSettings, openLocationSettings, distanceMeters | geolocator | generic |
| core/services/map_service.dart | map style, markers, polyline, bounds | mapStyle, marker(kind, dpr), decodePolyline, boundsOf, toLatLng, defaultCenter | google_maps_flutter, flutter_svg | generic (marker kinds app-flavoured) |
| core/services/media_service.dart | pick + compress image | pick(MediaSource), compress(File), openSettings | image_picker, flutter_image_compress, path_provider, permission_handler | generic |
| core/services/upload_service.dart | multipart upload with progress | upload(file, purpose, onProgress, cancelToken) | SharedRepository | generic |
| core/services/launcher_service.dart | external intents | openUrl(external), call, email, whatsapp, openStore | url_launcher | generic |
| core/services/share_service.dart | OS share sheet + clipboard | shareLink(url, title), copy | share_plus | generic |
| core/services/social_auth_service.dart | Google + Apple sign-in | signIn(SocialProvider), signOut, isAppleAvailable | google_sign_in 7, sign_in_with_apple | generic |
| core/services/app_info_service.dart | version, build, device id, timezone | init, platform, timezone, headers, bootstrapQuery | package_info_plus, device_info_plus, uuid | generic |
| core/services/deep_link_service.dart | app_links listener | init, markRouterReady, dispose, pending | app_links, ActionHandler | generic |
| core/services/action_handler.dart | AppAction → navigation; ProductListArgs | handle(AppActionModel), fromUri(Uri) | appRouter, LauncherService | app-specific |
| core/services/toast_manager.dart | overlay toast + context.showToast | showToast(context, message, state, location, duration) | AnimatedCustomToast | generic |
| core/services/app_validator.dart | form validators | isNotEmpty, isValidEmail, isValidPhone, isValidPassword, confirmPassword, isValidFullName, minLength, otp, customValidator | easy_localization, PhoneFormatter | generic |
| core/services/bloc_observer.dart | bloc logging | onChange, onError | talker | generic |
| core/services/system_status.dart | SystemOverride model | – | equatable | generic |
| core/services/double_parser.dart | legacy parser shim | parse | Json | generic (redundant) |
| core/services/mock/mock_api_interceptor.dart | serves fixtures as HTTP | onRequest, registerHandler | dio, MockRouteTable, MockSettings | generic |
| core/services/mock/mock_route_table.dart | routes.json loader + matcher | ensureLoaded, match(method, path, query), fixture(name), setRoutes | rootBundle | generic |
| core/services/mock/mock_settings.dart | forced failures/latency | failNext, failAll, clearFailures, takeFailure, min/maxLatency | AppEnv | generic |
| core/services/mock/mock_handlers.dart | stateful mock cart/wishlist/orders | buildMockHandlers() | Json | app-specific |
| core/services/shared_api/shared_remote_data_source.dart + shared_repository.dart | cross-feature endpoints | getBootstrap, upload, registerDevice, unregisterDevice, getPage, getFaqs, reverseGeocode, autocomplete, placeDetails | BaseRemoteDataSource | app-specific contract, generic idea |
| core/utilities/converters/json_helpers.dart | defensive JSON | toInt, intOr, toDouble, doubleOr, boolOr, str, strOr, map, list, listOf, strings, date | – | generic |
| core/utilities/formatters/phone_formatter.dart | E.164 | toE164, toNational, isValid | CountryCodeModel | generic |
| core/utilities/helpers/auth_helper.dart | guest gate | requireAuth(context, returnTo) | AppCubit, router, sheet | generic pattern |
| core/utilities/failures/failure.dart, error_details_model.dart | Failure hierarchy | fieldError, hasFieldErrors, isCode; ErrorDetail.first | – | generic |
| core/utilities/screen_util_config.dart | computed design size | corsaDesignSize(Size) | – | generic |
| core/utilities/constants/app_text_scale.dart | text-scale policy | min, max, slotMax, stackAbove, factorOf, extra, isEnlarged, shouldStack | – | generic |
| core/utilities/constants/app_dimens.dart | tokens | extent(context, fixed, text), screenInsets | screenutil | generic shape, app values |
| core/utilities/constants/colors.dart, app_shadows.dart, app_icons.dart, app_images.dart, app_lotties.dart | design tokens / asset paths | AppLotties builder | – | app-specific values |
| core/utilities/constants/keys/api_keys.dart | AppEnv + endpoints | constants + path functions | – | app-specific |
| core/extensions/context_extensions.dart | theme/locale/window helpers | theme, textTheme, isAr, isRtl, windowClass, responsive, isTablet, isPhoneSized, textScaler, insets | – | generic |
| core/extensions/string_extensions.dart, list_extensions.dart | helpers | isNullOrEmpty, orNull, capitalized, latinDigits, separated | – | generic |
| core/enums/*.dart | enums | fromValue → unknown | – | pattern generic |
| core/models/*.dart | shared wire models | fromJson/toJson/maybe | Json | app contract |
| core/theme/light_theme/** | ThemeData | lightThemeFor(lang) | AppColors, AppDimens | generic structure |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| core/utilities/widgets/default_screen.dart | base scaffold with title row, sticky bottom action, tablet centring, keyboard dismiss | body, pageTitle, pageTitleWidget, titleActions, leading, hasBackButton, onBackPressed, showTitleRow, overlayHeader, bodyPadding, appBarPadding, maxContentWidth, bottomAction, bottomActionPadding, backgroundColor, showBackgroundDecoration, floatingActionButton(+Location), resizeToAvoidBottomInset, scaffoldKey, safeAreaTop, safeAreaBottom | y |
| core/utilities/widgets/buttons/app_default_button.dart | AppDefaultButton / AppSecondaryButton / AppTextButton | text, onTap, style, enabled, isLoading, leadingIcon, trailingIcon, trailingArrow, iconColor, width, minHeight, expand, textStyle, textColor, backgroundColor, borderColor, radius, padding, margin, semanticLabel, child | y |
| core/utilities/widgets/buttons/app_icon_button.dart | AppIconButton(.svg), AppBackButton | child/asset, onTap, size, round, radius, backgroundColor, borderColor, shadow, tooltip, badge, color, iconSize, matchTextDirection / onTap, transparent | y |
| core/utilities/widgets/text_form_fields/app_text_form_field.dart | AppTextFormField, AppTextArea, DigitsOnlyFormatter | controller, title, titleSuffixWidget, hintText, validator, inputFormatters, prefix/suffixIcon, maxLength, maxLines, textInputAction, autofillHints, textCapitalization, minHeight, textDirection, errorText, helperText, autovalidateMode, fillColor, showShadow, radius, semanticLabel … | y |
| core/utilities/widgets/text_form_fields/password_text_form_field.dart | password + confirm | controller, isConfirmPassword, confirmAgainst, title, hintText, isLogin, errorText … | y |
| core/utilities/widgets/text_form_fields/email_text_form_field.dart | email | controller, title, hintText, errorText, enabled … | y |
| core/utilities/widgets/text_form_fields/phone_text_form_field.dart | E.164 phone with country | controller, countries, initialCountry, onCountryChanged, title, errorText … | y |
| core/utilities/widgets/text_form_fields/otp_form_field.dart | OTP boxes | length, controller, onChanged, onCompleted, autofocus, enabled, hasError | y |
| core/utilities/widgets/app_search_field.dart | search + SortDropdownChip | controller, hintText, onChanged, onSubmitted, onTap, readOnly, autofocus, compact, debounce, focusNode, showShadow, trailing | y |
| core/utilities/widgets/base_fetching_widget.dart | GenericFetchWidget, BaseLoadingWidget, BaseErrorWidget, BaseEmptyWidget | successBuilder, loadingWidget, skeletonBuilder, failureWidget, onRetry, isEmpty, emptyBuilder, onRefresh, hasData / message, compact / failure, onRetry / title, message, actionText, onAction, illustration | y |
| core/utilities/widgets/shared/screens/paginated_list_view.dart | infinite list/grid | items, itemBuilder, onLoadMore, onRefresh, hasReachedMax, isLoadingMore, loadMoreFailure, gridDelegate, padding, separator, header, footer, emptyWidget, scrollController, shrinkWrap, physics, endOfListText | y |
| core/utilities/widgets/show_app_bottom_sheet.dart | showAppBottomSheet, AppBottomSheet, showAppConfirmDialog | builder, title, isDismissible, scrollable, maxHeightFraction / child, title, showHandle, padding / title, message, confirmText, cancelText, danger | y |
| core/utilities/widgets/skeletons/app_skeletons.dart | shimmer placeholders | AppSkeleton(child, enabled), SkeletonBox(width, height, radius), ProductCardSkeleton, TileSkeleton, ListTileSkeleton, SkeletonList(count, itemHeight), SkeletonGrid(count, columns, extent, item) | y |
| core/utilities/widgets/shared/widgets/app_image.dart | AppNetworkImage, AppAssetImage | image (ImageRefModel) or url, width, height, fit, radius, borderRadius, backgroundColor, border, onTap, heroTag, semanticLabel | y |
| core/utilities/widgets/app_svg_icon.dart | tinted SVG | asset, size, width, height, color, matchTextDirection, semanticLabel, fit | y |
| core/utilities/widgets/toasts/animated_custom_toast.dart | toast view | message, state, duration, location | y |
| core/utilities/widgets/no_internet/no_internet_gate.dart, no_internet_screen.dart | offline gate + banner | child | y |
| core/utilities/widgets/app_result_view.dart | result/empty screen | title, message, illustration, illustrationWidget, infoLabel, infoValue, primaryActionText, onPrimaryAction, secondaryActionText, onSecondaryAction, isLoading, footer | y |
| core/utilities/widgets/app_main_card.dart | AppMainCard, AppMenuTile | child, padding, margin, radius, color, borderColor, borderWidth, hasShadow, width, height, onTap / label, icon, onTap, trailingText, trailing, danger, showChevron | y |
| core/utilities/widgets/custom_chip.dart | toned chip, CustomChip.status | title, tone, selected, outlined, small, onSelect, onDelete, radius, padding, colours, leading, minWidth | y |
| core/utilities/widgets/app_tab_switcher.dart | tab switcher | tabs, selectedIndex, onTabChanged, counts, style (underline/pill), margin | y |
| core/utilities/widgets/adaptive_row.dart | row→column | children, spacing, alignments, forceColumn, minRowWidth | y |
| core/utilities/widgets/adaptive_shell.dart | AdaptiveShell, AppBottomNav, AppNavItem | items, currentIndex, onTap, child | y |
| core/utilities/widgets/custom_curved_navigation_bar.dart | curved notched nav bar | items (NavigationItemsModel), index, colours, onTap, animationCurve/Duration, height, maxWidth, buttonSize, isSvgIcons | y |
| core/utilities/widgets/app_avatar.dart | AppAvatar, StoreLogo | image, initials, size, circle, borderColor, onTap | y |
| core/utilities/widgets/app_divider.dart | divider | height, color, indent, endIndent, thickness | y |
| core/utilities/widgets/app_switch.dart | switch | value, onChanged, semanticLabel | y |
| core/utilities/widgets/section_header.dart | section title + view all | title, onViewAll, viewAllText, padding | y |
| core/utilities/widgets/timeline_stepper.dart | order steps | steps, vertical | y (OrderStepModel) |
| core/utilities/widgets/image_picker_tile.dart | pick + progress tile | file, onPick, onRemove, progress, label, width, height | y |
| core/utilities/widgets/language_option_card.dart | language card | name, nativeName, flagAsset, selected, onTap | y |
| core/utilities/widgets/simple_html_view.dart | tiny HTML renderer | html | y |
| core/utilities/widgets/cms_blocks_view.dart | CMS blocks | blocks | partly |
| core/utilities/widgets/shared/screens/image_viewer_screen.dart | zoom gallery | ImageViewerArgs(images, initialIndex, heroTag) | y |
| core/utilities/widgets/shared/screens/html_screen.dart | HTML page | HtmlPageArgs(title, html) | y |
| core/utilities/widgets/price_text.dart | price + compare-at | price, compareAtPrice, style, textStyle, maxLines, clampScale | partly |
| core/utilities/widgets/price_summary_card.dart | price lines | summary, padding, showBorder | partly |
| core/utilities/widgets/quantity_stepper.dart | stepper | quantity, onChanged, onDelete, min, max, isLoading, compact | y |
| core/utilities/widgets/rating_stars.dart | stars | rating, reviewsCount, starCount, size, textStyle, showValue | y |
| core/utilities/widgets/heart_toggle.dart | favourite | isFavorite, onChanged, size, background, padding | y |
| core/utilities/widgets/selectors.dart | colour/size selectors | options (SelectableOption), selectedId, onChanged | y (e-commerce) |
| core/utilities/widgets/cards/product_card.dart | product card | name, price, brandName, image, rating, width, imageHeight, onTap, onAdd, favoriteButton, dimmed, inStock | n |
| core/utilities/widgets/cards/catalog_cards.dart | CategoryCircle, CategoryCard, BrandTile, FeaturedStoreCard, StoreListTile | name, image/logo/cover, onTap, typeLabel, tagsText, etaText, isVerified, isOpen, favoriteButton | n |
| core/utilities/widgets/cards/promo_banner.dart | banner (hero/cardLight/cardDark/campaign) | style, image, eyebrow, title, subtitle, ctaText, onTap, height, width | partly |
| features/addresses/presentation/widgets/corsa_map.dart | styled GoogleMap with centre pin | initialPoint, onPointChanged, markers, polylines, showCenterPin, interactive, height, borderRadius, fitPoints, onMapCreated, liteMode | y |
| features/cart/presentation/widgets/cart_icon_button.dart, features/notifications/presentation/widgets/notification_bell_button.dart, features/wishlist/presentation/widgets/favorite_button.dart | badge-wired app-bar actions | – | n |
| features/auth/presentation/widgets/social_auth_buttons.dart, auth_header.dart | social buttons, auth header | – | partly |

## 6. Packages (pubspec.yaml)

- **State**: flutter_bloc ^9.1.1, equatable ^2.0.7
- **DI**: get_it ^9.0.5
- **Routing**: go_router ^17.2.3
- **Network**: dio ^5.7.0, dartz ^0.10.1, dart_pusher_channels ^1.3.1, uuid ^4.6.0
- **Storage**: shared_preferences ^2.3.3, flutter_secure_storage ^10.0.0, path_provider ^2.1.5
- **L10n**: easy_localization ^3.0.7, intl ^0.20.2, flutter_localizations (sdk)
- **UI**: flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, skeletonizer ^2.1.0+1, cached_network_image ^3.4.1, lottie ^3.3.3, smooth_page_indicator ^3.0.0, cupertino_icons ^1.0.8, flutter_native_splash ^2.4.3, webview_flutter ^4.13.1
- **Firebase / push / auth**: firebase_core ^4.4.0, firebase_messaging ^16.1.1, firebase_crashlytics ^5.0.7, flutter_local_notifications ^21.0.0, google_sign_in ^7.2.0, sign_in_with_apple ^8.2.0
- **Maps / location**: google_maps_flutter ^2.3.2, geolocator ^14.0.1
- **Media**: image_picker ^1.1.2, flutter_image_compress ^2.3.0, share_plus ^12.0.2
- **Utils**: url_launcher ^6.3.1, app_links ^6.4.0, permission_handler ^12.0.1, package_info_plus ^9.0.0, device_info_plus ^12.4.0
- **Logging**: talker_flutter ^5.0.2, talker_dio_logger ^5.0.2
- **Dev**: flutter_test, flutter_lints ^6.0.0, flutter_launcher_icons ^0.14.4, bloc_test ^10.0.0, mocktail ^1.0.5, image ^4.10.1 (for tool/make_splash_mark.dart)

## 7. Quality notes

- **Null safety / language**: Dart ^3.12, sound null safety, modern syntax (switch expressions,
  records, null-aware elements `?x` in collections, `spacing:` on Row/Column, wildcard `_`
  params). No deprecated APIs found (uses `withValues`, `TextScaler`,
  `MediaQuery.withClampedTextScaling`, `PopScope`, `BitmapDescriptor.bytes`, google_sign_in 7
  API).
- **Lints**: default `flutter_lints` with no extra rules; 38 `// ignore:` lines, most for
  `discarded_futures`, which isn't enabled, so they're noise. README says `flutter analyze` must
  be clean.
- **Tests**: 20 test files, ~92 cases (README says 84): cubit tests with bloc_test/mocktail,
  failure mapping, mock API and "every fixture parses" tests, enum fallback tests, a text-scale ×
  screen-size × locale widget matrix, splash animation + 4 golden frames, system gate tests. Good
  coverage for a project of this size.
- **Docs**: unusually thorough: `docs/CONVENTIONS.md`, `docs/api/CONTRACT.md` (every endpoint
  shape), `docs/FEATURES.md` (screen → route → endpoint), `docs/PROGRESS.md`, exported Figma
  frames. Doc comments reference spec sections (§x.y) throughout.
- **Smells / bugs** (details in the summary): unsent app headers; cold-start push action never
  consumed; socket subscribe-before-connect; kitchen sink in release; base-cubit failure not
  cleared on reload; raw exception text in UnknownFailure; `core/` imports features and holds
  customer-only widgets, which works against the "copy core into the driver app" plan (30 core
  files have already diverged, see corsa-driver.md); an un-cancelled stream subscription in
  CartCubit; hardcoded English channel names; a large hand-rolled curved nav bar (465 lines);
  `catalog_cards.dart` 430 lines.
- **Duplication**: `DoubleParserService` duplicates `Json.toDouble`; `BaseCubit` and
  `BaseSingleStateCubit` duplicate the token/debounce/safeEmit plumbing (could be a mixin).
