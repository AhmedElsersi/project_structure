# tebbr: analysis report

## Summary for comparison

```
PROJECT: tebbr | path: Freelance/tebbr | stack: Flutter, Dart SDK ^3.10.7 (uses null-aware elements `?x`, wildcard `_`) | last commit: 2026-10-31 (68 commits since 2026-02-27) | source files: 557
ARCH: clean-arch feature-first, no domain layer — features/<f>/{data/{data_sources,models,repo},presentation/{managers/<x>_cubit,screens,widgets}}; RemoteDataSource extends BaseRemoteDataSource -> Repository extends BaseRepository (Either<Failure,T>) -> Cubit extends BaseCubit/BaseSingleStateCubit; 21 features + shared lib/core
STATE: flutter_bloc 9 Cubits (+1 HydratedBloc CartBloc) — BaseCubit.handleRequest(loadingState, call, onSuccess, onError) (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart, 17 cubits); BaseSingleStateCubit.handleRequest(call, onNotDefault*) + BaseSingleClassState{status enum, failure, success} (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/, 29 cubits); 11 plain Cubits; BaseBloc unused
DI: get_it 9, manual, global `diService` — lib/core/services/di_container.dart (644 lines, every feature registered in one file; data sources/repos lazySingleton, cubits factory)
ROUTING: go_router 17 — lib/core/app_router/app_router.dart (873 lines) + app_routes_names.dart — guards: no auth guard (redirect only bounces cold-start deep links through splash via `hasAppInitialized`); ShellRoute (not StatefulShellRoute) for bottom nav — deep links: y (app_links + normalizeDeepLink(), /products/:productId)
NETWORK: dio 5 — interceptors: TalkerDioLogger only (LoggingInterceptor defined + registered in DI but never attached) | token refresh: n | retry: n | error mapping: BaseRemoteDataSource maps HTTP 400/401/403/404/408/504/500(+HTML timeout sniff)/default and DioExceptionType -> typed Failure; 401 handled only for the profile fetch in bottom_nav_screen.dart | lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart
RESULT_TYPE: Either (dartz 0.10) — lib/core/utilities/failures/failure.dart (abstract Failure implements Exception {message, code, errors}; 11 subclasses, not sealed) + error_details_model.dart
STORAGE: shared_preferences + flutter_secure_storage (token) + hydrated_bloc (cart) + cloud_firestore (cart sync) — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart
L10N: easy_localization 3.0.7 — ar, en; start/fallback ar; assets/translations/{ar,en}.json (935 lines each, 963 .tr() calls) — hardcoded UI strings: few (English defaults in Failure classes, cubit success messages, BaseEmptyWidget/InfiniteScrollScreen; Arabic literals in studio config)
RTL: Directional=139 vs LeftRight=85 (plus a Directionality wrapper in MaterialApp.builder driven by locale; AppBackButton/AppTextFormField pick direction via context.isAr)
THEME: lib/core/theme/light_theme/light_theme.dart (+ light_widget_themes/*) — dark mode n (dark_theme.dart is an empty file) | component themes in ThemeData y (appBar, elevated/text/legacy button, input, dialog, snackBar, bottomNav, progress, M3) | AppColors lib/core/utilities/constants/colors.dart (primary/secondary/neutral ramps) | TextThemeLight singleton light_widget_themes/text_theme.dart (M3 names, .sp) | fonts Cairo (+ ArefRuqaa, Amiri, ReemKufi display faces)
RESPONSIVE: flutter_screenutil 5.9 (design 393x852, minTextAdapt, splitScreenMode) + context.isTablet in lib/core/extensions/context_extensions.dart — breakpoints: 600 on shortestSide (18 uses)
TEXT_SCALING: AppTextScale (lib/core/utilities/constants/app_text_scale.dart) applied in MaterialApp.builder (lib/main.dart): system scale damped to 35% of the increase, clamped 1.0–1.15, per font size (respects Android 14 nonlinear); AppDefaultButton adds MediaQuery.withClampedTextScaling(max 1.15); covered by test/core/widgets/text_scale_test.dart
ENV/FLAVORS: hardcoded constants — lib/core/utilities/constants/keys/api_keys.dart (base URL, image URL, endpoints, a third-party API key); socket host/key hardcoded in lib/core/services/reverb_socket_client.dart; no flavors, no --dart-define
LOGGING: talker_flutter 5 (global `talker` in di_container.dart, TalkerRouteObserver, TalkerDioLogger) + 69 debugPrint + 17 print (BaseCubit, AppBlocObserver)
ANALYTICS/CRASH: firebase_crashlytics (release only: FlutterError.onError + PlatformDispatcher.onError + runZonedGuarded) — no analytics
PUSH: fcm + flutter_local_notifications — lib/core/services/notification_service.dart (static class) + lib/core/services/notification_router.dart (tap routing w/ pending payload); FCM token sent with login, onTokenRefresh is a TODO
PAYMENTS/IAP: in_app_purchase 3.3 (+ _android 0.5, _storekit 0.4) — lib/core/iap/ (IapService w/ sealed IapEvent stream + backend receipt verify; manage_subscription.dart); legacy web checkout via webview_flutter / flutter_inappwebview
PERMISSIONS: permission_handler 12 (notifications), geolocator 14 (location), image_picker camera/gallery
DEEP_LINKS: app_links 6 — lib/core/services/deep_link_service.dart + normalizeDeepLink() in lib/core/app_router/app_router.dart (https App Links + custom scheme, auth callback + product links, de-duped, cold start bounced via splash?redirect=)
MEDIA/FILES: image_picker, flutter_image_compress, cached_network_image, gal, share_plus, path_provider, flutter_svg, lottie, skeletonizer, carousel_slider, flutter_html, webview_flutter, flutter_inappwebview, google_maps_flutter, agora_rtc_engine
TESTS: 21 test files (+1 fake repo), 126 test/testWidgets cases — deep-link normalization, text scaling, studio image layout math, models (complaints, orders, config/version compare), products cubit/filters/query params, a few widget tests; nothing on base_architecture / ApiService
LINTS: flutter_lints 6 (package:flutter_lints/flutter.yaml), 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/utilities/constants/app_text_scale.dart — damped + clamped TextScaler, extra()/isEnlarged() helpers — quality 5 — coupling: none
- lib/core/services/connectivity_service.dart — dependency-free connectivity monitor (DNS probe of 2 hosts, adaptive 15s/4s polling, offline confirm re-probe, re-check on resume) — quality 4.5 — coupling: none
- lib/core/utilities/timing/request_limiters.dart — Debouncer (with flush) + Throttler — quality 4.5 — coupling: none
- lib/core/app_cubit/connectivity_cubit.dart + lib/core/utilities/widgets/no_internet/no_internet_gate.dart — cubit with min retry feedback + overlay gate that keeps the tree alive — quality 4 — coupling: low (NoInternetScreen uses app DefaultScreen/AppImages)
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — handleRequest<T>(path, method, parser, data, query, options, cancelToken) with HTTP/Dio -> Failure mapping — quality 3.5 — coupling: high (resolves ApiService via global GetIt, uses global talker + easy_localization)
- lib/core/utilities/widgets/shared/widgets/image_Widget.dart — ImageViewerWidget (asset/file/network chosen by String extension, memCacheWidth capped to box size, skeleton placeholder) + String.imageProvider — quality 4 — coupling: low (StudioImage, AppColors)
- lib/core/utilities/widgets/shared/screens/image_viewer.dart — swipeable zoom gallery with animated double-tap zoom — quality 4 — coupling: low (AppIconButton)
- lib/core/models/translation_model.dart — tolerant bilingual {en,ar} field parser + localized(context) fallback — quality 4 — coupling: low
- lib/core/services/app_validator.dart — localized validators (email, phone, UAE phone, password, confirm, IBAN mod-97, composable customValidator) — quality 3.5 — coupling: low (easy_localization keys); isNumeric is buggy
- lib/core/utilities/failures/failure.dart — Failure hierarchy with code + field errors — quality 3 — coupling: none
- lib/core/theme/light_theme/light_theme.dart (+ light_widget_themes/) — ThemeData getter rebuilt only when ScreenUtil scale changes; one file per component theme — quality 3.5 — coupling: low
- lib/core/services/notification_router.dart — notification-tap router holding a pending payload until splash flushes it — quality 3.5 — coupling: high (order routes, AppCubit)
- lib/core/iap/iap_service.dart — IAP singleton: one purchaseStream listener, sealed IapEvent stream, backend verify, safe completePurchase — quality 3.5 — coupling: high (MySubscriptionModel, IapApi)
- lib/core/services/url_handler.dart — url / tel / mailto / sms / WhatsApp launcher — quality 3.5 — coupling: none
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart (+ base_single_class_state.dart) — status-enum single-state cubit base — quality 2.5 — coupling: low (concept worth keeping, implementation needs rework, see report §3.1)
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/default_screen.dart — base scaffold — body, pageTitle/pageTitleWidget, hasBackButton, onBackPressed, titleActions, appbar, drawer/endDrawer, FAB(+location), topMargin/bottomMargin, appBarPadding/bodyPadding, backgroundColor/backgroundImage, scaffoldKey — quality 3.5 — generic? y (defaults to an app background asset)
- lib/core/utilities/widgets/buttons/app_default_button.dart (AppDefaultButton) — primary button — text, onTap, isLoading, enabled, child, iconData/iconSize, width/height/minWidth/maxWidth (hug-label mode), fixedHeight, radius, margin/padding, backgroundColor/backgroundImage/hasBackgroundImage, gradient, boxShadow, borderColor/borderWidth, textStyle/textColor/textAlign, loadingColor — quality 4 — generic? y (default bg image asset is app-specific)
- lib/core/utilities/widgets/buttons/app_default_button.dart (AppSecondaryButton) — raised 3D secondary button with press-sink animation — same params subset — quality 3.5 — generic? partly (hardcoded gradient colors)
- lib/core/utilities/widgets/buttons/app_default_button.dart (AppTextButton) — text button — text, onTap, enabled, textStyle/textColor/textAlign, width/height, radius, isLoading — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart (AppIconButton, AppBackButton) — circular icon button + RTL-aware back chevron — child, onTap, width/height, radius, backgroundColor, borderColor, padding, margin — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — labeled text field — controller, title, iconData, titleSuffixWidget, hintText, validator, inputFormatters, prefix/suffixIcon(+constraints), obscureText, maxLines/maxLength, focusNode, textInputAction, onSaved/onFieldSubmitted/onEditingComplete, borderRadius, backgroundColor, borderColor, contentPadding, minHeight, textDirection — quality 3.5 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password with visibility toggle — controller, isConfirmPassword, title, hintText, onChanged, focusNode, textInputAction, onFieldSubmitted (isLogin + confirmPasswordValidator ignored) — quality 2.5 — generic? y
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart — email field — controller, title, hintText, onChanged, focusNode, textInputAction, onFieldSubmitted — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart — phone with fixed country-code prefix + Arabic-Indic digit normalizer — same params — quality 3 — generic? n (country hardcoded; the formatter is generic)
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart — read-only field opening a bottom-sheet string list — title, hintText, controller, items, validator, onChanged, prefixIconData — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart (DynamicDropdownFormField<T>) — popup-menu dropdown — options, displayText, onOptionSelected, title, hintText, showSearch, enabled, isLoading, initialValue, selectedDisplayText, borderRadius — quality 2.5 — generic? y (search does not refilter the open menu)
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart + lib/core/services/toast_manager.dart — overlay toast (success/failure/warning) + context.showToast — message, state, duration, location — quality 3 — generic? y (stale timer can remove a newer toast)
- lib/core/utilities/widgets/toasts/custom_toast.dart — static toast — message, state, duration — quality 2 — generic? y (unused)
- lib/core/services/show_loading_dialog.dart — blocking loading dialog + context.showLoading — message, barrierDismissible — quality 2.5 — generic? y (no hide helper)
- lib/core/utilities/widgets/base_fetching_widget.dart (BaseLoadingWidget, BaseErrorWidget, BaseEmptyWidget) — loading / error+retry / empty states — message, onRetry; icon, iconSize, iconColor — quality 3.5 — generic? y
- lib/core/utilities/widgets/base_fetching_widget.dart (GenericFetchWidget<B,S,T>) — BlocBuilder switch on status — successBuilder, loadingWidget, failureWidget, onRetry — quality 3 — generic? y (unused)
- lib/core/utilities/widgets/base_list_view_widget.dart (BaseListView<T>) — list with empty text — items, itemBuilder, emptyWidget, emptyWidgetText — quality 2.5 — generic? y (unused)
- lib/core/utilities/widgets/shared/screens/paginated_list_screen.dart (InfiniteScrollScreen<TModel,TCubit,TState>) — infinite scroll + pull-to-refresh — title, cubit, onFetchData, itemBuilder, getItems, isLoading, hasReachedMax, getError, emptyWidget, errorBuilder, loadingWidget, padding, separator, physics — quality 2.5 — generic? y (unused; demo cubit/model shipped in lib)
- lib/core/utilities/widgets/app_bottom_sheet.dart — sheet body with handle, optional icon + title, keyboard inset — child, title, icon — quality 3.5 — generic? y
- lib/core/utilities/widgets/show_app_bottom_sheet.dart — draggable sheet with title + primary/cancel actions — sheetTitle, sheetContent, primaryBtnText, onTapPrimaryBtn, *ChildSize (ignored) — quality 2 — generic? y (unused, 'Cancel' hardcoded)
- lib/core/utilities/widgets/bottom_action_buttons.dart — primary + secondary button row — primaryBtnText, secondBtnText, onTapPrimaryBtn, onTapSecondBtn — quality 3 — generic? y
- lib/core/utilities/widgets/image_picker_bottom_sheet.dart (showImagePickerSheet) — camera/gallery chooser — context, onFilePicked — quality 3 — generic? y
- lib/core/utilities/widgets/app_main_card.dart — card container — child, padding, margin, hasShadow, height, width, radius, borderRadius, color, imageUrl, border, boxShadow, clipBehavior — quality 3.5 — generic? y
- lib/core/utilities/widgets/container_with_shadow.dart — shadow container — child, margin, padding, radius, width, height, image, backgroundColor, border, onTap, boxShadow, shadowBlurRadius — quality 2.5 — generic? y (unused)
- lib/core/utilities/widgets/custom_appbar.dart (CustomAppBar) — PreferredSize app bar with back button + divider — pageTitle, actions — quality 2 — generic? y (unused)
- lib/core/utilities/widgets/app_tab_switcher.dart — segmented tab switcher — tabController, selectedIndex, tabs, onTabChanged, margin — quality 3 — generic? y
- lib/core/utilities/widgets/app_check_box.dart — styled checkbox — value, onChanged, size, radius — quality 3 — generic? y
- lib/core/utilities/widgets/custom_radio_group_widget.dart (CustomRadioGroup<T>, CustomSizeRadio) — radio list — options, selectedValue, onChanged, prefixText, label — quality 2.5 — generic? partly (unused)
- lib/core/utilities/widgets/app_divider.dart — divider — height, thickness, color, indent, endIndent, widthFactor — quality 3 — generic? y
- lib/core/utilities/widgets/custom_chip.dart — chip — title, titleStyle, bgColor, borderColor, txtColor, radius, fontSize, padding, onSelect — quality 3 — generic? y
- lib/core/utilities/widgets/selection_chip_widget.dart — selectable chip — isSelected, title, fontSize, padding, onTap — quality 3 — generic? y
- lib/core/utilities/widgets/status_pill.dart — status pill — label, color, maxWidth — quality 3.5 — generic? y
- lib/core/utilities/widgets/linear_progress_indicator.dart (LinearPercentIndicator) — percent bar colored by value — percent, minHeight — quality 2.5 — generic? y (unused)
- lib/core/utilities/widgets/animated_indicator.dart (IndicatorWidget) — animated step dot — index, currentStep — quality 3 — generic? y (unused)
- lib/core/utilities/widgets/no_internet/no_internet_gate.dart + no_internet_screen.dart — offline overlay + retry screen — child — quality 4 — generic? y (styling app-specific)
- lib/core/utilities/widgets/shared/widgets/image_Widget.dart (ImageViewerWidget) — network/asset/file image — image, width, height, radius, borderRadius, color, margin, stackedWidget(+alignment), onTap, fit, border, studioFit, studioInsets, fullResolution — quality 4 — generic? y
- lib/core/utilities/widgets/shared/screens/image_viewer.dart (ImageViewerScreen + ImageViewerArgs) — zoomable gallery — imagePath, images, initialIndex, heroTag — quality 4 — generic? y
- lib/core/utilities/widgets/shared/screens/html_screen.dart (HtmlScreen + HtmlItemModel) — HTML content page — htmlItem{title, htmlContent, icon, serviceName} — quality 3 — generic? partly (embeds an app-specific guest sign-in banner)
- lib/features/orders/presentation/widgets/order_modification/order_sheet_frame.dart (OrderSheetFrame) — bottom-sheet frame with tinted icon/title/subtitle — icon, iconColor, iconBackground, title, subtitle, child — quality 3.5 — generic? y (lives in a feature)
- lib/features/splash/presentation/widgets/upgrade_dialog.dart (UpgradeDialog + isVersionBehind/isAppBehind/getInstalledAppVersion) — optional/forced update dialog + semver compare — latestVersion, storeUrl, notes — quality 3.5 — generic? y
- lib/features/splash/presentation/screens/force_update_screen.dart, maintenance_screen.dart — full-screen takeovers — policy, notes / reads AppCubit — quality 3 — generic? partly
- lib/features/products/presentation/widgets/loading_grid.dart — skeleton grid — quality 3 — generic? partly
NOTABLE_IDEAS: AppTextScale damped/clamped TextScaler at app root (lib/core/utilities/constants/app_text_scale.dart, lib/main.dart) | _SystemConfigGate in lib/main.dart: maintenance takeover + forced-update full-screen takeover + optional upgrade dialog parked until splash leaves; config re-fetched on resume (throttled 1 min) | theme getter rebuilt only when ScreenUtil scale changes (light_theme.dart) | ConnectivityService + NoInternetGate overlay that keeps the tree alive | cold-start deep links bounced via splash?redirect= + normalizeDeepLink() (app_router.dart) + DeepLinkService de-dupe | NotificationRouter pending payload flushed by splash | clear secure storage on first launch (iOS keychain survives reinstall) (features/splash/presentation/screens/splash_screen.dart) | ImageViewerWidget memCacheWidth decode cap + String.imageType extension | AppDefaultButton loading->circle morph with OverflowBox layoutBuilder fix + hug-label mode | Arabic-Indic digit normalizer formatter (phone_text_form_field.dart) | TranslationModel.tryParse | BaseRemoteDataSource handles HTML/plain-text 5xx bodies, timeout-body sniffing, CancelledFailure, logs (not shows) parse errors | Debouncer.flush/Throttler | create_feature.dart scaffold script (idea good, implementation thin) | IapService sealed events + single global listener | ReverbSocketClient (pusher-protocol client on dart:io WebSocket) | COMMON_STRUCTURE.md / PROJECT_STRUCTURE.md documenting the feature template
SMELLS: god files (di_container.dart 644 lines, app_router.dart 873, main.dart 447) | BaseCubit uses print, puts stack trace into user-facing UnknownFailure message, no isClosed guards in either base cubit | BaseSingleStateCubit `as State` / `data as BaseSuccessModel` casts; 28 states use `failure ?? this.failure` so failure can never be cleared; default path barely used (47 onNotDefaultSuccess overrides for 42 calls) | BaseState props [] so field-carrying states compare equal unless overridden | BaseRepository catches only Failure (TypeError from `response.data!` escapes) | BaseRemoteDataSource: service-locator coupling, 204 treated as error, 422 unmapped, field errors read from top-level keys instead of `errors` | ApiService: async init not awaited in ctor, updateHeaders(token:) ignores the arg (re-reads storage), 5-min timeouts, no auth interceptor/refresh/retry, TalkerDioLogger printRequestHeaders in all builds (logs bearer token), FCM token debugPrinted | GoRouter debugLogDiagnostics:true, messy redirect leftovers, ShellRoute loses tab state | dead code: BaseBloc, GenericFetchWidget, BaseListView, InfiniteScrollScreen (+demo AlertsCubit in lib), CustomToast, CustomAppBar, ContainerWithShadow, CustomRadioGroup, LinearPercentIndicator, IndicatorWidget, showAppBottomSheet, SelectLocationScreen stub, LoggingInterceptor, LanguageService, AuthHelper, ensureStartsWithZero, setAppLanguageToDeviceLanguage, empty dark_theme.dart + price_converter.dart | withOpacity x94 (withValues x96) | 138 Color(0x..) + 331 Colors.* in features | plain-text password persisted at login (secure storage); AuthLocalDataSource extends BaseRemoteDataSource | inconsistent naming (repo/repository/repositories, data/model, home/presentation/home_cubit, image_Widget.dart, Change_Language_Section.dart, base64ImageService.dart, phone_handeler_service.dart) | 12-level relative import in app_icon_button.dart | ToastManager stale timer, PasswordTextFormField ignores isLogin/confirmPasswordValidator, DynamicDropdown search broken, AppValidator.isNumeric regex `\$` + missing .tr(), CacheFailure drops its message | NotificationService no-op statement, un-awaited channel creation on a fresh plugin instance, _isAndroid13OrHigher always true | fixed 3.35 s splash delay
```

---

## 1. Architecture pattern

Feature-first "clean architecture lite": each feature has a **data** layer and a **presentation** layer.
There is **no domain layer** (no entities, no use cases, no repository interfaces). Repositories are
concrete classes that the cubits call directly.

Request flow (example: reviews):

```
ReviewsScreen / AddReviewSheet
   -> context.read<ProductReviewsCubit>().getProductReviews(id)
ProductReviewsCubit extends BaseSingleStateCubit<ProductReviewsState>
   -> handleRequest(call: () => repository.getProductReviews(id), onNotDefault...)
ReviewsRepository extends BaseRepository
   -> handleNetworkCall(call: () => remoteDataSource.getProductReviews(id))   // Either<Failure, T>
ReviewsRemoteDataSource extends BaseRemoteDataSource
   -> handleRequest(path: ApiKeys.X, method: HttpMethod.get, parser: (res) => BaseSuccessResponse.fromJson(res.data, (j) => parseList(j, ReviewModel.fromJson)))
BaseRemoteDataSource -> diService<ApiService>().get(NetworkRequestParams(...))  -> Dio
```

- Errors travel as **thrown `Failure`** objects from the data source, are caught in `BaseRepository`
  and become `Left(failure)`, then the cubit folds the `Either`.
- Models are hand-written `fromJson`/`toJson` (no json_serializable / freezed; 0 generated files).
- Response envelope: `BaseSuccessResponse<T>{success (status=="success"), message, data, pagination (from meta)}`
  plus a `parseList` helper.
- Two state styles coexist:
  - **Multi-class states** (`sealed class XState extends BaseState` + `XLoading/XSuccess/XFailure`), driven by `BaseCubit`.
  - **Single-class state** (`XState extends BaseSingleClassState` with `status`/`failure`/`success` + extra fields), driven by `BaseSingleStateCubit`.
- Global state: `AppCubit` (config, user, token, sellers, categories) and `ConnectivityCubit` at the root;
  ~13 more cubits are provided app-wide in `MainApp` (`lib/main.dart`); feature cubits are provided per
  route in `app_router.dart` (`BlocProvider(create: (_) => diService<X>())`), shell-scoped cubits in `ShellRoute` builders.
- Feature scaffolding: `dart run create_feature.dart <name>` (project root) creates the folders plus
  3 stub files (see §3.17).

## 2. Folder tree (`lib/`, 4 levels)

```
lib/
├── main.dart                         # bootstrap (prefs, l10n, splash, Firebase, Crashlytics, HydratedStorage, DI, IAP, deep links), MainApp, _SystemConfigGate (maintenance/force-update)
├── firebase_options.dart             # exists (secret-class file, not opened)
├── core/
│   ├── app_cubit/                    # AppCubit/AppState (config, user, token, sellers, categories), ConnectivityCubit/State
│   ├── app_router/                   # app_router.dart (GoRouter, redirect, normalizeDeepLink, rootNavigatorKey, hasAppInitialized), app_routes_names.dart
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/         # base_remote_data_source.dart
│   │   │   ├── models/               # base_success_model.dart, base_request_model/network_request_model.dart, base_response_model/base_success_response.dart
│   │   │   └── repository/           # base_repo.dart
│   │   └── presentation/managers/
│   │       ├── base_cubit/           # base_cubit.dart, base_state.dart
│   │       └── base_single_class_state_bloc/  # base_single_class_state.dart, ..._cubit.dart, ..._bloc.dart (unused)
│   ├── enums/                        # http_method, fetch_data_status, toast_state, app_roles, gold_enums (app)
│   ├── exports/                      # core_exports.dart barrel: material, go_router, easy_localization (hide TextDirection), screenutil, AppColors, DefaultScreen
│   ├── extensions/                   # context (theme/textTheme/colorScheme/isAr/isTablet), list/string isNullOrEmpty
│   ├── iap/                          # iap_service.dart, iap_api.dart, iap_constants.dart, manage_subscription.dart
│   ├── models/                       # selection_model.dart, translation_model.dart
│   ├── services/                     # di_container, api_service, storage wrappers, notification_service/router, deep_link_service, connectivity_service, toast_manager, show_loading_dialog, url_handler, share services, validators, socket client, misc helpers
│   ├── theme/
│   │   ├── dark_theme/               # dark_theme.dart (EMPTY)
│   │   └── light_theme/              # light_theme.dart, my_light_themes_export.dart, light_widget_themes/ (app_bar, bottom_nav, btn_txt, dialog, elevated_btn, input_decoration, light_color_scheme, snack_bar, text_theme)
│   └── utilities/
│       ├── constants/                # colors, images, icons, lotties, studio_images, app_text_scale, app_store_links, constant_lists, keys/{api_keys, shared_preferences_keys}
│       ├── converters/               # price_converter.dart (EMPTY)
│       ├── failures/                 # failure.dart, error_details_model.dart
│       ├── formatters/               # date_formatter.dart
│       ├── helpers/                  # auth_helper.dart (unused), uae_pass_clear_session.dart (app)
│       ├── timing/                   # request_limiters.dart (Debouncer, Throttler)
│       └── widgets/                  # shared widgets (see §5): buttons/, text_form_fields/, toasts/, no_internet/, shared/{screens,widgets}/, + ~20 loose widget files
└── features/                         # 21 features (file count): products 60, complaints 44, home 40, cart 30, profile 28, orders 28, auth 28,
                                      # studio 25, chat 23, sellers 18, addresses 18, settings 17, video_call 12, subscriptions 12, splash 12,
                                      # points 9, reviews 8, notifications 7, consultant_evaluation 6, bottom_nav 5, tools 2
```

Representative feature fully expanded (`notifications`, 7 files, 699 lines):

```
features/notifications/
├── data/
│   ├── data_sources/notifications_remote_data_source.dart   # extends BaseRemoteDataSource; get (paged), markAsRead, markAllAsRead, delete
│   ├── models/notification_model.dart                       # hand-written fromJson + copyWith
│   └── repo/notifications_repo.dart                         # extends BaseRepository -> Either<Failure, T>
└── presentation/
    ├── managers/notifications_cubit/
    │   ├── notifications_cubit.dart                         # extends BaseSingleStateCubit; manual paging (_currentPage, hasReachedMax), optimistic read/delete with rollback, permission check
    │   └── notifications_state.dart                         # part of; extends BaseSingleClassState (+ notifications, unreadCount, hasReachedMax, notificationsEnabled)
    ├── screens/notifications_screen.dart                     # DefaultScreen + BlocBuilder; own scroll-listener pagination; BaseLoading/Error/EmptyWidget
    └── widgets/notification_card.dart
```

Folder naming is not uniform across features: `data/repo` (most), `data/repository` (cart),
`data/repositories` (auth, home, splash), `data/model` (bottom_nav), `presentation/home_cubit` outside
`managers` (home), `presentation/image_search` (products), `presentation/utils` (auth), `data/mocks` (products).

## 3. Infrastructure

### 3.1 State management (and evaluation of `base_architecture`)

Packages: `flutter_bloc ^9.1.1`, `hydrated_bloc ^11.0.0`, `equatable ^2.0.7`, `dartz ^0.10.1`.

Usage: 17 cubits extend `BaseCubit`, 29 extend `BaseSingleStateCubit`, 11 extend plain `Cubit`,
1 `HydratedBloc` (`CartBloc`, persisted + synced to Firestore by `features/cart/data/repository/cart_sync_service.dart`).
`BaseBloc` (`base_single_class_state_bloc.dart`) has 0 users.

**`BaseCubit<State extends BaseState>`** (`lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart`):

```dart
Future<void> handleRequest<T>({
  required State loadingState,
  required Future<Either<Failure, T>> Function() call,
  required Function(T) onSuccess,
  required Function(Failure) onError,
  bool showLoading = true,
}) async { ... emit(loadingState); final r = await call(); r.fold(onError, onSuccess); ... }
```

- Good: tiny, explicit, works well with sealed multi-class states; `showLoading` flag.
- Problems: `print(...)` in the success and catch paths; the catch builds
  `UnknownFailure(message: "Unexpected error $e, stack trace: $stackTrace")`, and that message reaches the UI
  (BaseErrorWidget even has a comment about "a stray stack trace"); no `isClosed` check before `emit`
  (cubits closed during an await will throw `StateError`); callbacks typed `Function(T)` (dynamic return)
  instead of `void Function(T)`; logs whole API results with `talker.info`.
- `BaseState` (`base_state.dart`) is `Equatable` with `props => []` typed `List<Object>` (non-nullable).
  States that carry data but don't override `props` (e.g. `AddProductReviewFailure`) compare equal to
  each other, so a second identical-type emit is silently dropped unless a loading state is emitted between.
  `LoadingState`/`ErrorState(String)` defined there are not used by features.

**`BaseSingleStateCubit<State extends BaseSingleClassState>`** (`.../base_single_class_state_cubit.dart`) +
**`BaseSingleClassState`** (`.../base_single_class_state.dart`: `status: FetchDataStatusEnum`, `failure`, `success: BaseSuccessModel?`, abstract `copyWith`):

- Default flow emits `status: loading` -> `failure` or `success: data as BaseSuccessModel`. Each step can be
  overridden with `onNotDefaultLoading/Success/Failure`.
- Good idea: one state class with a status enum + extra fields (pagination, counters) — the pattern most features actually need.
- Problems:
  - `emit(state.copyWith(...) as State)` relies on every subclass returning its own type (runtime cast).
  - `success: data as BaseSuccessModel` throws if `T` isn't a `BaseSuccessModel`; the throw is caught and
    turned into a failure "Unexpected error occurred $e" (again shown to users).
  - `copyWith(status: loading, failure: null)` does **not** clear the failure: 28 feature states implement
    `failure: failure ?? this.failure`. A few states use an `_unset` sentinel for other fields (59 occurrences of `_unset`/`clearFailure`), so the fix is known but not applied to `failure`.
  - In practice the default path is almost never used: 42 `handleRequest` calls in these cubits, with
    47 `onNotDefaultSuccess`, 41 `onNotDefaultFailure`, 32 `onNotDefaultLoading` overrides; only 1 UI read of `state.success`.
    The generic `success: BaseSuccessModel` slot and `GenericFetchWidget` that depends on it are effectively abandoned.
  - No `isClosed` guard.
- Verdict for the template: keep the *concept* (status enum + single state + overridable steps), rewrite it:
  generic `S extends BaseState<S>` with a typed `copyWith`, a sentinel/`clearFailure` flag, `isClosed` guards,
  no `BaseSuccessModel` cast, user-safe unknown-error message, logging through the logger.

**`AppBlocObserver`** (`lib/core/services/bloc_observer.dart`): prints every create/event/change/transition/close with `print` (no talker, no debug guard).

**`AppCubit`** (`lib/core/app_cubit/app_cubit.dart`): setters for config/user/token/sellers/categories, `isGuest()`, `reset()` that keeps config.
`AppState.copyWith` uses `??`, so `setToken(null)` cannot clear the token (logout uses `reset()`).

### 3.2 Dependency injection

`get_it ^9.0.5`, manual registration. `lib/core/services/di_container.dart` (644 lines) defines
`final diService = GetIt.instance;` and `final talker = Talker();` (the logger lives in the DI file).
`diContainerSetup()` calls `_initExternalServices/_initDioAndRemoteDataSource/_initRepo/_initBlocs/_initCubits`.
These are declared `Future<void> async` but nothing is awaited (works only because no step is truly async).
Data sources and repositories are lazy singletons; most cubits are factories; `AppCubit`, `CartBloc`,
`ConnectivityCubit`, `VideoCallCubit`, `ConversationsCubit`, `StudioHistoryCubit` are lazy singletons
(the comments explain providing singletons with `BlocProvider.value` so routes don't close them, though
`AppCubit`/`StudioHistoryCubit` are still provided with `create:`).
Remote data sources take no constructor dependencies; they reach `diService<ApiService>()` inside
`BaseRemoteDataSource` (service locator in the data layer, hard to unit test). Other classes
(AuthLocalDataSource, auth repo, splash screen, settings widgets) also call `diService<...>()` inline.

Template note: split registration per feature (`registerXFeature(GetIt)`), inject `ApiService` through constructors.

### 3.3 Routing

`go_router ^17.2.3`. `lib/core/app_router/app_router.dart` (873 lines) builds a top-level
`final GoRouter appRouter` with `navigatorKey: rootNavigatorKey` (public, so root overlays can find the navigator),
`observers: [TalkerRouteObserver(talker)]`, `debugLogDiagnostics: true` (not gated on debug), `initialLocation: '/'`.

- `redirect`: (1) `normalizeDeepLink(state.uri)` rewrites custom-scheme URIs (`scheme://auth/callback?...`,
  `scheme://products/<id>`) onto real routes; (2) while `hasAppInitialized == false` every location except
  splash is bounced to `/?redirect=<encoded>` so splash initializes first and then replays it;
  (3) a special case keeps the current location for an auth-resume link. The block contains leftover
  comments ("... existing /callback normalization + cold-start bounce unchanged") and broken indentation.
- No auth guard. Guest checks happen in screens (`AppCubit.isGuest()`), and a 401 on profile fetch in
  `bottom_nav_screen.dart` clears secure storage and goes to auth.
- `errorBuilder` shows a localized "page not found" with a go-home button (never a blank screen).
- Arguments passed via `state.extra` with casts (`state.extra as ImageViewerArgs`), some with `is` checks + defaults.
- Two `ShellRoute`s: the bottom-nav shell (provides 9 home cubits + `BottomNavScreen(child)`) and an inner
  shell for scoped cubits. Plain `ShellRoute` (not `StatefulShellRoute`) so tab stacks/state are not preserved.
- Route names: `lib/core/app_router/app_routes_names.dart` (`static const String` paths, `productDetailsPath(int)` builder).

### 3.4 Networking

Packages: `dio ^5.7.0`, `talker_dio_logger ^5.0.2`.

**`ApiService`** (`lib/core/services/api_service.dart`) implements `ApiServiceBase` (get/post/put/patch/delete taking `NetworkRequestParams`, `updateHeaders`).

- Constructor sets `baseUrl`, 5-minute connect/receive timeouts, default headers (`Content-Type`, `Accept`,
  `Accept-Language: ar`), reads the token from `SecureStorageManager` and adds `Authorization: Bearer`,
  then adds `TalkerDioLogger(printRequestHeaders: true)`. That init is `async` and **not awaited** from the
  constructor; requests sent before the secure-storage read finishes go out without the headers/logger
  (hidden in practice by a 3.35 s splash).
- `updateHeaders({token, customHeaders})` merges custom headers (null value removes a key) and rebuilds headers
  **by re-reading the token from secure storage**, so the `token` argument is effectively ignored (it works
  only because callers save/delete the token first). Signature differs from the interface (`Map<String,String?>` vs `Map<String,String>`).
- `_executeRequest` re-throws `SocketException`/`FormatException` as new generic instances (no value added).
- No auth interceptor, no 401 handling, no token refresh, no retry, no connectivity short-circuit.
- `TalkerDioLogger` with request headers in all builds logs the bearer token.
- `LoggingInterceptor` (`lib/core/services/logging_interceptors.dart`, chunked debugPrint) is registered in DI but never attached.

**`BaseRemoteDataSource.handleRequest<T>`** (`lib/core/base_architecture/data/data_sources/base_remote_data_source.dart`, 200 lines):

```dart
Future<T> handleRequest<T>({required String path, required HttpMethod method,
    required T Function(Response) parser, dynamic data,
    Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken})
// try { response = _executeRequest(...); return _handleResponse(response, parser); }
// on DioException catch (e) { throw _handleDioError(e); }
// catch (e, stack) { throw _handleGenericError(e, stack); }
```

- Error mapping: 400 -> `BadRequestFailure(errors)`, 401 -> `UnauthorizedFailure`, 403 -> `ForbiddenFailure`,
  404 -> `NotFoundFailure`, 408/504 -> `TimeoutFailure`, 500 -> `TimeoutFailure` if the HTML/plain body looks like a
  proxy timeout else `ServerFailure`, others -> `ServerFailure`; Dio timeouts -> `TimeoutFailure`, `connectionError`
  -> `NetworkFailure`, `cancel` -> `CancelledFailure` (UI ignores it); response body may be non-JSON (handled).
  Server `message` is used when it is a String.
- `_handleGenericError` logs parse/type errors to talker and returns a localized generic `UnknownFailure` — good: no internals shown.
- Weaknesses: only 200/201 count as success (204 No Content becomes a `ServerFailure`); 422 (the usual
  Laravel validation status) is not mapped and its field errors are lost; `_parseErrorDetails` iterates
  the **top-level** keys (so `message` becomes an `ErrorDetail` and a nested `errors` map is skipped);
  the 5 HTTP-method branches are copy-paste (could be one `dio.request` with `Options(method:)`);
  no upload progress parameters surfaced although `NetworkRequestParams` has them.

**`BaseRepository.handleNetworkCall<T>`** (`lib/core/base_architecture/data/repository/base_repo.dart`):
`try { Right(await call()) } on Failure catch (e) { Left(e) }`. Only `Failure` is caught. Repository closures
do extra work (`response.data!.token!`, secure-storage writes, Firestore checks in auth_repo.dart), and any
non-`Failure` exception there escapes to the cubit's catch-all. Needs a final `catch (e, s)` -> `UnknownFailure`.

**Models**: `NetworkRequestParams` (uri, data, query, options, cancelToken, onSend/ReceiveProgress);
`BaseSuccessResponse<T>.fromJson(json, fromJsonT)` + `parseList<T>()`; `PaginationModel` (current_page, per_page, total, total_pages from `meta`);
`BaseSuccessModel` (empty Equatable) / `BaseSuccessModelWithData<T>`.

### 3.5 Local storage

- `SharedPreferencesManager` (`lib/core/services/shared_preferences_manager.dart`): singleton factory, `init()` in `main`,
  `setValue(key, dynamic)` (String/int/bool/double/List<String>, else `UnsupportedError`), `getValue` (dynamic), `remove`, `clear`.
  Silently no-ops if not initialized. Untyped API.
- `SecureStorageManager` (`lib/core/services/secure_storage_manager.dart`): `write/read/delete/clearAll/containsKey`
  over a `const FlutterSecureStorage()`; each method wraps in `try { } catch { rethrow; }` (noise). No platform options.
- Keys: `lib/core/utilities/constants/keys/shared_preferences_keys.dart` (token, first-time flag, phone, email, password, etc.).
- Splash clears secure storage on the first launch after install (iOS keychain persistence) and on read errors.
- Auth stores the user's plain password in secure storage (`AuthLocalDataSource.saveUserPassword`); `AuthLocalDataSource` wrongly extends `BaseRemoteDataSource`.
- `HydratedBloc.storage` built in `main.dart` (application documents dir / web); only `CartBloc` uses it.
- Feature-level local data sources: gold price snapshot (prefs), studio history (prefs), deleted accounts (Firestore).

### 3.6 Localization and RTL

- `easy_localization ^3.0.7` (+ `flutter_localizations`, `intl ^0.20.2`). `EasyLocalization(supportedLocales: [ar, en], path: 'assets/translations', fallbackLocale: ar, startLocale: ar)` in `lib/main.dart`.
- `assets/translations/ar.json`, `en.json` (935 lines each, nested keys like `messages.something_went_wrong`). 963 `.tr()` call sites.
- `MaterialApp.router(key: ValueKey(locale))` rebuilds the whole app on language change; `Accept-Language` header is updated by
  the splash and the language switcher (`features/settings/presentation/widgets/Change_Language_Section.dart`).
- `setAppLanguageToDeviceLanguage()` (`lib/core/services/get_and_set_device_locale.dart`) exists but is unused.
- RTL: `Directionality` forced from `context.locale` in `MaterialApp.builder`; `context.isAr` helper; 139 directional
  vs 85 left/right usages (e.g. `AppBottomSheet` uses `EdgeInsets.only(left:, right:)`, `SelectLocationScreen` uses `fromLTRB`).
  `AppTextFormField` wraps each field in a `Directionality` by locale; `AppBackButton` swaps chevrons by `isAr` instead of relying on directionality-aware icons.
- Hardcoded strings: few. Failure default messages are English (`'Invalid request'`, ...), some cubits emit English success
  messages ("Review added successfully"), `BaseEmptyWidget` defaults to `'No Data found'`, `InfiniteScrollScreen` has `'Error'`/`'No items found'`,
  `showAppBottomSheet` has `'Cancel'`, `DynamicDropdownFormField` hint `'Select an option'`; ~66 Arabic literals mostly in studio config.

### 3.7 Theming

- `lib/core/theme/light_theme/light_theme.dart`: `ThemeData get lightTheme` caches the theme and rebuilds it only when
  `(ScreenUtil().scaleWidth, scaleHeight)` changes, so `.sp/.w/.r` values in component themes stay correct after rotation/split-screen.
- Component themes, one file each in `light_widget_themes/`: `appBarTheme`, `bottomNavTheme`, `textBtnTheme`, `elevatedBtnTheme`
  (fixed size 343.w x 52.h, pill shape), legacy `btnTheme`, `dialogTheme`, `snackBarTheme`, `inputDecorationTheme`
  (outline borders, fill, hint/error styles), `colorSchemeTheme` (`ColorScheme.fromSeed`), progress indicator; `useMaterial3: true`.
  Re-exported by `my_light_themes_export.dart`.
- `TextThemeLight` singleton (`text_theme.dart`): full M3 scale with Cairo, getters so `.sp` is re-read.
- `AppColors` (`lib/core/utilities/constants/colors.dart`): brand ramps primary100–800, secondary100–800, neutral100–1000,
  red/yellow/green, a few semantic names; `newColor(int)` helper. Some duplicated values (`primary` == `primary100`, `*10` aliases).
- Dark mode: none (`dark_theme.dart` is a 0-byte file, no `darkTheme:` on MaterialApp).
- Widgets frequently bypass the theme with literal colors: 138 `Color(0x..)` and 331 `Colors.*` in features.
- Asset constants: `AppImages`, `AppIcons`, `AppLotties` (with a `lottie()` helper), `StudioImages`.

### 3.8 Responsive helpers

`flutter_screenutil ^5.9.3`, `ScreenUtilInit(designSize: Size(393, 852), minTextAdapt: true, splitScreenMode: true)` in `lib/main.dart`.
`.w/.h/.sp/.r` everywhere. `context.isTablet` = `MediaQuery.sizeOf(context).shortestSide >= 600` (`lib/core/extensions/context_extensions.dart`), used 18 times.
No breakpoint system beyond that. `RESPONSIVE_TEXT_AUDIT.md` at the project root documents a text-overflow audit.

### 3.9 Text scaling

`AppTextScale` (`lib/core/utilities/constants/app_text_scale.dart`, 75 lines) is the best piece in the project:

```dart
static TextScaler apply(TextScaler system) => _AppTextScaler(system);
// _AppTextScaler.scale(fontSize):
final requested = system.scale(fontSize) / fontSize;          // per size -> Android 14 nonlinear OK
final factor = (1 + (requested - 1) * AppTextScale.growth)     // growth = 0.35
    .clamp(AppTextScale.min, AppTextScale.max);                // 1.0 .. 1.15
return fontSize * factor;
```

Applied once in `MaterialApp.builder` (so dialogs/sheets/toasts get it). Helpers: `AppTextScale.extra(context, fontSize, lineHeight, lines)`
for fixed-height boxes, `AppTextScale.isEnlarged(context)`. `AppDefaultButton` additionally clamps to 1.15 and adds vertical padding
only when text is enlarged. Tested in `test/core/widgets/text_scale_test.dart`. Overrides the deprecated `textScaleFactor` getter (required by the interface, ignore comment present).

### 3.10 Env / flavors

None. `lib/core/utilities/constants/keys/api_keys.dart` holds the base URL, image base URL, every endpoint (consts and
functions like `CATEGORY(slug)`), app name/version, and a third-party API key in source. Socket host, auth endpoint and app key are
consts in `lib/core/services/reverb_socket_client.dart`. Store links/app id in `lib/core/utilities/constants/app_store_links.dart`
(with a placeholder-ID check so share never hands out a dead link). Android has only debug/main/profile source sets.

### 3.11 Logging

`talker_flutter ^5.0.2` with a global `talker` (declared in di_container.dart), `TalkerRouteObserver`, `TalkerDioLogger`,
`talker.handle(e, stack, msg)` in the data layer (50 talker calls). Mixed with 69 `debugPrint` (notification service, splash, socket client)
and 17 `print` (BaseCubit, AppBlocObserver, create_feature.dart). No TalkerScreen in-app log viewer. No release gating.

### 3.12 Analytics / crash reporting

`firebase_crashlytics ^5.0.7`, release-only: `FlutterError.onError = recordFlutterFatalError`, `PlatformDispatcher.instance.onError` (fatal),
`runZonedGuarded` around `runApp`. No analytics package. `google-services.json` and `GoogleService-Info.plist` exist (not opened).

### 3.13 Push notifications

`firebase_messaging ^16.1.1`, `flutter_local_notifications ^21.0.0`. Background handler in `main.dart` only initializes Firebase.

`NotificationService` (`lib/core/services/notification_service.dart`, all static), started fire-and-forget from the splash:
- Order of init: local notifications (tap handler + launch details) first, then FCM listeners (`onMessage` -> shows a local
  notification with `jsonEncode(message.data)` payload; `onMessageOpenedApp` + `getInitialMessage` -> router), then permission request.
- Foreground FCM presentation disabled on iOS so the local notification is the only banner.
- Public API: `init`, `isPermissionGranted`, `requestPermission` (opens settings when permanently denied), `getFcmToken`,
  `showLocalNotification`, `cancelNotification`, `cancelAllNotifications`, `subscribeToTopic`, `unsubscribeFromTopic`.
- Problems: FCM token `debugPrint`ed; `onTokenRefresh` has a TODO (not sent to backend; token only goes with login);
  `_createNotificationChannels` contains a no-op statement and creates the channel on a fresh
  `AndroidFlutterLocalNotificationsPlugin()` without awaiting; `_isAndroid13OrHigher()` always returns true.

`NotificationRouter` (`lib/core/services/notification_router.dart`): parses data/JSON payload; order-type notifications open order
details for signed-in users; if the app isn't initialized yet the payload is held and `flushPending()` is called by splash after it
navigates (post-frame). Pattern is reusable; routing table is app-specific.

### 3.14 IAP / payments

`in_app_purchase ^3.3.0` (+ `_android ^0.5.0`, `_storekit ^0.4.11`). `lib/core/iap/`:
- `IapService` (303 lines): one global `purchaseStream` subscription (`init()` from main after DI), `events` broadcast stream of
  sealed `IapEvent` (`IapPurchasing/IapVerified/IapCancelled/IapError`), `loadProducts(ids)`, `buy(...)` with Android offer tokens,
  `restore()`, backend receipt verification via `IapApi` (extends BaseRemoteDataSource), `_safeComplete`.
- `manage_subscription.dart`: opens the store's subscription management page.
- Legacy hosted-payment checkout via WebView still present (comment in main.dart: kept until callers migrate).

### 3.15 Permissions

`permission_handler ^12.0.1` for notifications (Android) with settings fallback; FCM `requestPermission` on iOS;
`geolocator ^14.0.1` for location (addresses); `image_picker` camera/gallery. No central permission service.

### 3.16 Deep links

`app_links ^6.4.0`. `DeepLinkService` (`lib/core/services/deep_link_service.dart`): handles initial link + stream, de-dupes by last
handled URI, routes the auth callback and product links (`/products/<id>` App Link or custom-scheme fallback) with `appRouter.go()`;
ignores anything that doesn't resolve to a product route. Flutter's built-in deep linking is disabled, so this is the only path.
`normalizeDeepLink()` in app_router.dart is unit-tested (`test/core/app_router/deep_link_normalization_test.dart`).
`ProductShareService` (`lib/core/services/share_service.dart`) builds the matching share links (host hardcoded).

### 3.17 Scaffolding script `create_feature.dart` (project root, 115 lines)

Run: `dart run create_feature.dart <feature_name>`. It:
1. lowercases the name, builds a PascalCase class name by splitting on `_`;
2. exits if `lib/features/<name>` exists;
3. creates `data/{data_sources,models,repo}` and `presentation/{managers,screens,widgets}`;
4. writes three files: `<name>_remote_data_source.dart` (empty class extending `BaseRemoteDataSource`),
   `<name>_local_data_source.dart` (empty class), `<name>_repo.dart` (`<Name>Repository extends BaseRepository` with a
   `remoteDataSource` field).

Assessment (quality 2/5 as-is, idea 4/5):
- Generated repo imports `dartz`, `base_success_response.dart` and `failure.dart` without using them -> 3 `unused_import` warnings on every new feature.
- Generates nothing for presentation: no cubit/state, no screen, no model; no DI registration, no route constant/route.
- No name validation (`Video-Call` or `a__b` -> bad class name / `RangeError` on `word[0]`), no `--force`/dry-run, uses `print` with emoji.
- Doc comment says `dart run tool/create_feature.dart` but the file is at the root; the example tree mentions `garage_*`/`auth_repo.dart` (copy-paste).
- Relative imports (`../../../../core/...`) are correct for the generated depth, but the project mostly uses `package:` imports.
- Template recommendation: keep the command, extend it (or replace with a mason brick) to generate: model, remote DS with one sample
  `handleRequest`, repo method, cubit + state (single-state style), screen on the base scaffold, plus print the DI and route snippets to paste
  (or append to a per-feature DI file). Validate snake_case names.

## 4. Services catalog

| File | Class / symbol | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|---|
| lib/core/services/api_service.dart | ApiServiceBase, ApiService | Dio wrapper, headers, token | get/post/put/patch/delete(NetworkRequestParams), updateHeaders({token, customHeaders}) | dio, talker_dio_logger, SecureStorageManager, SharedPreferencesKeys | generic (needs fixes) |
| lib/core/services/di_container.dart | diService, talker, diContainerSetup | GetIt registrations + global logger | diContainerSetup() | get_it, talker, every feature | app-specific |
| lib/core/services/secure_storage_manager.dart | SecureStorageManager | secure KV | write, read, delete, clearAll, containsKey | flutter_secure_storage | generic |
| lib/core/services/shared_preferences_manager.dart | SharedPreferencesManager | prefs singleton | init, setValue, getValue, remove, clear | shared_preferences | generic |
| lib/core/services/connectivity_service.dart | ConnectivityService | internet reachability monitor | start, dispose, recheck, onStatusChanged, isOnline | dart:io, WidgetsBindingObserver | generic |
| lib/core/services/notification_service.dart | NotificationService (static) | FCM + local notifications | init, isPermissionGranted, requestPermission, getFcmToken, showLocalNotification, cancelNotification, cancelAllNotifications, subscribeToTopic, unsubscribeFromTopic | firebase_messaging, flutter_local_notifications, permission_handler, NotificationRouter | mostly generic |
| lib/core/services/notification_router.dart | NotificationRouter (static) | payload -> navigation, pending until splash | handle, handlePayload, flushPending | appRouter, AppCubit, talker | pattern generic, routes app-specific |
| lib/core/services/deep_link_service.dart | DeepLinkService | app_links -> GoRouter | init, dispose | app_links, appRouter, auth callback model | app-specific |
| lib/core/services/toast_manager.dart | ToastManager, CustomToastExtension | overlay toast | showToast(context,…), context.showToast | AnimatedCustomToast | generic (timer bug) |
| lib/core/services/show_loading_dialog.dart | showLoadingDialog, CustomLoadingDialogExtension | modal loader | showLoadingDialog, context.showLoading | screenutil | generic |
| lib/core/services/url_handler.dart | UrlHandler (static) | external launches | openUrl, makeCall, sendEmail, sendSMS, openWhatsApp | url_launcher | generic |
| lib/core/services/share_service.dart | ProductShareService | product share + copy link | productLink, productSchemeLink, shareProduct, copyProductLink | share_plus, easy_localization | app-specific |
| lib/core/services/app_share_service.dart | AppShareService | share the app store link | shareApp | share_plus, AppStoreLinks | generic-ish |
| lib/core/services/app_validator.dart | AppValidator (static) | form validators | isNotEmpty, isValidEmail, isValidPhone, isValidUAEPhone, isValidPassword(value, isLogin), confirmPassword, isNumeric (buggy), isNotEmptyImage, ibanValidator, customValidator | easy_localization | generic |
| lib/core/services/image_picker_service.dart | ImagePickerService | pick image with snackbar on cancel/error | pickImage(context, source) | image_picker | generic (UI in service) |
| lib/core/services/base64ImageService.dart | Base64ImageService | base64 -> bytes/file (isolate decode) | decode, toBytes, toFile | path_provider | generic |
| lib/core/services/double_parser.dart | DoubleParserService | tolerant num parsing | parse(dynamic) | none | generic |
| lib/core/services/get_and_set_device_locale.dart | setAppLanguageToDeviceLanguage, getDeviceLocale | match device language | functions | easy_localization, dart:io | generic (unused) |
| lib/core/services/language_flags_service.dart | LanguageService | locale -> flag emoji | getFlagEmoji | none | generic (unused) |
| lib/core/services/phone_handeler_service.dart | ensureStartsWithZero | phone prefix | function | none | generic (unused) |
| lib/core/services/logging_interceptors.dart | LoggingInterceptor | chunked debugPrint Dio logger | interceptor overrides | dio | generic (unused) |
| lib/core/services/bloc_observer.dart | AppBlocObserver | print bloc lifecycle | observer overrides | flutter_bloc | generic (should use talker) |
| lib/core/services/availability_service.dart | AvailabilityWindow, AvailabilityStatus | opening-hours windows incl. overnight | fromModel, contains, windowsOf, check | config model | app-specific (logic reusable) |
| lib/core/services/reverb_socket_client.dart | ReverbSocketClient | pusher-protocol websocket client with private-channel auth | connect(token, channels, onEvent), disconnect | dart:io WebSocket, hardcoded host/key | semi-generic |
| lib/core/iap/iap_service.dart | IapService, IapEvent (sealed) | store purchases + backend verify | events, products, init, dispose, loadProducts, buy, restore | in_app_purchase(+android), IapApi, MySubscriptionModel | semi-generic |
| lib/core/iap/iap_api.dart | IapApi | verify receipt / my subscription | verify, mySubscription | BaseRemoteDataSource | app-specific |
| lib/core/iap/manage_subscription.dart | openManageSubscriptions | open store subscription page | function | url_launcher, IapConstants | generic-ish |
| lib/core/app_cubit/app_cubit.dart | AppCubit, AppState | global session/config | setAppConfig, setUser, setToken, setSellers, setCategories, isGuest, reset | feature models | app-specific |
| lib/core/app_cubit/connectivity_cubit.dart | ConnectivityCubit, ConnectivityState | online state + retry | retry | ConnectivityService | generic |
| lib/core/app_router/app_router.dart | appRouter, rootNavigatorKey, hasAppInitialized, normalizeDeepLink | routing | — | everything | app-specific |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | BaseRemoteDataSource | request + error mapping | handleRequest<T> | ApiService (via GetIt), talker, easy_localization | generic (template core) |
| lib/core/base_architecture/data/repository/base_repo.dart | BaseRepository | Failure -> Either | handleNetworkCall<T> | dartz | generic |
| lib/core/base_architecture/data/models/base_response_model/base_success_response.dart | BaseSuccessResponse<T>, parseList, PaginationModel | envelope parsing | fromJson, toJson | none | generic (backend-shape specific) |
| lib/core/base_architecture/data/models/base_request_model/network_request_model.dart | NetworkRequestParams | request params | fields | dio | generic |
| lib/core/base_architecture/data/models/base_success_model.dart | BaseSuccessModel, BaseSuccessModelWithData<T> | success marker | — | equatable | generic (mostly unused) |
| lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart | BaseCubit<S> | multi-state request helper | handleRequest<T> | flutter_bloc, dartz, talker | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/base_state.dart | BaseState, LoadingState, ErrorState | Equatable state base | — | equatable | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state.dart | BaseSingleClassState | status/failure/success state | copyWith (abstract) | equatable, FetchDataStatusEnum | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart | BaseSingleStateCubit<S> | single-state request helper | handleRequest<T> | flutter_bloc, dartz | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart | BaseBloc<E,S> | Bloc variant | handleRequest<T> | flutter_bloc | generic (unused) |
| lib/core/utilities/failures/failure.dart | Failure + 11 subclasses | error types | message, code, errors | ErrorDetail | generic |
| lib/core/utilities/failures/error_details_model.dart | ErrorDetail | field errors | fromJson(field, list) | none | generic |
| lib/core/utilities/timing/request_limiters.dart | Debouncer, Throttler | rate limiting | run, flush, cancel, reset, dispose | dart:async | generic |
| lib/core/utilities/formatters/date_formatter.dart | DateFormatter | date formatting | formatDateString, formatDate, isMorning | intl | generic (English error string) |
| lib/core/utilities/helpers/auth_helper.dart | AuthHelper | auth checks from AppCubit | isAuthenticated, getUserId | AppCubit | app (unused) |
| lib/core/utilities/helpers/uae_pass_clear_session.dart | clearUaePassSession | clear identity-provider cookies | function | flutter_inappwebview | app-specific |
| lib/core/utilities/constants/app_text_scale.dart | AppTextScale | text scaling policy | apply, extra, isEnlarged | flutter | generic |
| lib/core/utilities/constants/app_store_links.dart | AppStoreLinks | store URLs per platform | currentPlatform | dart:io | generic pattern |
| lib/core/utilities/constants/colors.dart, images.dart, icons.dart, lotties.dart, studio_images.dart | AppColors, AppImages, AppIcons, AppLotties, StudioImages | design/asset constants | consts + small render helpers | lottie, flutter_svg | app values |
| lib/core/utilities/constants/constant_lists.dart | ConstantLists | onboarding list | onboardingList | splash model | app-specific |
| lib/core/utilities/constants/keys/api_keys.dart, shared_preferences_keys.dart | ApiKeys, SharedPreferencesKeys | endpoints, storage keys | consts | none | app values |
| lib/core/extensions/context_extensions.dart | ContextExtensions | theme/textTheme/colorScheme/isAr/isTablet | getters | flutter | generic |
| lib/core/extensions/list_extensions.dart, string_extensions.dart | ListExtensions, StringExtensions | isNullOrEmpty() | method | none | generic |
| lib/core/models/translation_model.dart | TranslationModel | bilingual field | fromJson, tryParse, toJson, localized(context) | context_extensions | generic |
| lib/core/models/selection_model.dart | SelectionModel | option tile data | fields | dart:ui | generic |
| lib/core/enums/*.dart | HttpMethod, FetchDataStatusEnum, ToastState, AppRoles, Gold* | enums | — | none | first three generic |
| lib/core/exports/core_exports.dart | barrel | re-exports material, go_router, easy_localization (hide TextDirection), screenutil, AppColors, DefaultScreen | — | — | generic pattern |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/default_screen.dart (DefaultScreen) | base scaffold: background image/color, top safe padding, title row with back button + actions, body padding, bottom inset | body*, scaffoldKey, appbar, pageTitle, pageTitleWidget, titleAlign, titleActions, hasBackButton, onBackPressed, drawer, endDrawer, floatingActionButton(+Location), topMargin, bottomMargin, appBarPadding, bodyPadding, backgroundColor, backgroundImage | y (default bg asset app-specific; used by 57 files) |
| lib/core/utilities/widgets/buttons/app_default_button.dart (AppDefaultButton) | primary button, loading morph to circle, hug-label mode, text-scale aware | text*, onTap, isLoading, enabled, child, iconData, iconSize, height, width, minWidth, maxWidth, fixedHeight, radius, margin, padding, backgroundColor, backgroundImage, hasBackgroundImage, gradient, boxShadow, borderColor, borderWidth, textStyle, textColor, textAlign, loadingColor | y (62 users) |
| same file (AppSecondaryButton) | raised secondary button with press animation | text*, onTap, iconData, iconSize, enabled, textStyle, backgroundColor, textColor, borderColor, child, margin, padding, height, width, radius, isLoading, loadingColor | partly |
| same file (AppTextButton) | text-only button | text*, onTap, enabled, textAlign, textStyle, textColor, height, width, radius, isLoading | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart (AppIconButton, AppBackButton) | round icon button; RTL back chevron | child*, onTap, height, width, radius, backgroundColor, padding, margin, borderColor / onTap | y |
| lib/core/utilities/widgets/buttons/image_search_icon_button.dart (ImageSearchIconButton, ImageSearchGlyph) | custom-painted feature icon | onTap, size, filled, isLoading, semanticLabel, padding / size, colors | n |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart (AppTextFormField) | titled TextFormField with outline borders, tap-outside unfocus | controller*, title, iconData, titleSuffixWidget, hintText, onTap, onChanged, enabled, readOnly, obscureText, keyboardType, validator, inputFormatters, icon, prefixIcon, suffixIcon, titleStyle, textStyle, hintTextStyle, maxLength, maxLines, bottomMargin (unused), prefix/suffixIconConstraints, focusNode, textAlign, onSaved, onFieldSubmitted, onEditingComplete, textInputAction, borderRadius, backgroundColor, borderColor, contentPadding, minHeight, textDirection | y |
| lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart | password + eye toggle | controller*, isConfirmPassword, confirmPasswordValidator (ignored), title, hintText, isLogin (ignored), onChanged, focusNode, textInputAction, onFieldSubmitted | y |
| lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart | email field | controller*, title, hintText, readOnly (ignored), onChanged, focusNode, textInputAction, onFieldSubmitted | y |
| lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart | phone with fixed country prefix, digit normalizer, max 10 | controller*, title, hintText, readOnly (ignored), onChanged, focusNode, textInputAction, onFieldSubmitted | n (formatter y) |
| lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart | read-only field -> bottom-sheet list | title*, hintText*, controller*, items*, validator, onChanged, prefixIconData | y |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart (DynamicDropdownFormField<T>) | showMenu-based dropdown | options*, displayText*, title, prefixIconData, onOptionSelected, hintText, showSearch, enabled, isLoading, initialValue, selectedDisplayText, borderRadius | y (search broken) |
| lib/core/utilities/widgets/toasts/animated_custom_toast.dart | animated overlay toast body | message*, state*, duration*, location | y |
| lib/core/utilities/widgets/toasts/custom_toast.dart | static toast body | message*, state*, duration | y (unused) |
| lib/core/services/show_loading_dialog.dart | loading dialog | context*, message, barrierDismissible | y |
| lib/core/utilities/widgets/base_fetching_widget.dart (GenericFetchWidget<B,S,T>) | status switch builder | successBuilder*, loadingWidget, failureWidget, onRetry | y (unused) |
| same file (BaseLoadingWidget) | spinner + "loading" text | — | y |
| same file (BaseErrorWidget) | icon + message + retry button | message*, onRetry* | y (26 users) |
| same file (BaseEmptyWidget) | empty state | icon, message, iconSize, iconColor | y (15 users) |
| lib/core/utilities/widgets/base_list_view_widget.dart (BaseListView<T>) | separated list with empty text | items*, itemBuilder*, emptyWidget, emptyWidgetText | y (unused) |
| lib/core/utilities/widgets/shared/screens/paginated_list_screen.dart (InfiniteScrollScreen<TModel,TCubit,TState>, PaginatedState<T>) | infinite list screen | title*, cubit*, onFetchData*, itemBuilder*, getItems*, isLoading*, hasReachedMax*, getError*, emptyWidget, errorBuilder, loadingWidget, floatingActionButton, itemsPerPage, initialPage, padding, separator, physics | y (unused; ships demo AlertsState/AlertModel/AlertsCubit/AlertsScreenExample) |
| lib/core/utilities/widgets/app_bottom_sheet.dart (AppBottomSheet) | sheet container with handle, icon, title | child*, title, icon | y |
| lib/core/utilities/widgets/show_app_bottom_sheet.dart (showAppBottomSheet, MainView) | draggable sheet with actions | context, sheetTitle*, sheetContent*, primaryBtnText*, onTapPrimaryBtn*, initial/min/maxChildSize (ignored) | y (unused) |
| lib/core/utilities/widgets/bottom_action_buttons.dart | two-button row | primaryBtnText*, secondBtnText*, onTapPrimaryBtn*, onTapSecondBtn* | y |
| lib/core/utilities/widgets/image_picker_bottom_sheet.dart (showImagePickerSheet) | camera/gallery sheet | context*, onFilePicked* | y |
| lib/core/utilities/widgets/app_main_card.dart | card with shadow/border/bg image | child*, padding, margin, hasShadow, height, width, radius, borderRadius, color, imageUrl, border, boxShadow, clipBehavior | y (64 users) |
| lib/core/utilities/widgets/container_with_shadow.dart | tappable shadow container | child*, margin, padding, radius, width, height, image, backgroundColor, border, onTap, boxShadow, shadowBlurRadius | y (unused) |
| lib/core/utilities/widgets/custom_appbar.dart (CustomAppBar, CustomAppBarTitle) | AppBar with back + divider | pageTitle*, actions, preferredSize | y (unused) |
| lib/core/utilities/widgets/app_tab_switcher.dart | segmented tabs | tabController*, selectedIndex*, tabs*, onTabChanged*, margin | y |
| lib/core/utilities/widgets/app_check_box.dart | checkbox | value*, onChanged*, size, radius | y |
| lib/core/utilities/widgets/custom_radio_group_widget.dart (CustomRadioGroup<T>, CustomSizeRadio<T>) | radio list | options*, selectedValue*, onChanged*, prefixText*, label* | partly (unused) |
| lib/core/utilities/widgets/app_divider.dart | divider | height, thickness, color, indent, endIndent, widthFactor | y |
| lib/core/utilities/widgets/custom_chip.dart | chip | title*, titleStyle, bgColor, borderColor, txtColor, radius, fontSize, padding, onSelect | y |
| lib/core/utilities/widgets/selection_chip_widget.dart | selectable chip | isSelected*, title*, onTap*, fontSize, padding | y |
| lib/core/utilities/widgets/status_pill.dart | colored status label | label*, color*, maxWidth | y |
| lib/core/utilities/widgets/linear_progress_indicator.dart (LinearPercentIndicator) | progress bar | percent*, minHeight | y (unused) |
| lib/core/utilities/widgets/animated_indicator.dart (IndicatorWidget) | step dot | index*, currentStep* | y (unused) |
| lib/core/utilities/widgets/availability_hours_dialog.dart | opening-hours dialog | (windows from config) | n |
| lib/core/utilities/widgets/no_internet/no_internet_gate.dart, no_internet_screen.dart | offline overlay + retry | child* | y |
| lib/core/utilities/widgets/shared/widgets/image_Widget.dart (ImageViewerWidget, ImageType, ImageTypeExtension) | universal image | image*, width, height, radius, borderRadius, color, margin, stackedWidget, stackedWidgetAlignment, onTap, fit, border, studioFit, studioInsets, fullResolution | y (39 users) |
| lib/core/utilities/widgets/shared/widgets/studio_image.dart (StudioImage) | painter for fixed-ratio product renders | provider*, placeholder*, error*, insets, legacyFit | n |
| lib/core/utilities/widgets/shared/screens/image_viewer.dart (ImageViewerScreen, ImageViewerArgs) | zoomable gallery | imagePath, images, initialIndex, heroTag | y |
| lib/core/utilities/widgets/shared/screens/html_screen.dart (HtmlScreen, HtmlItemModel) | HTML page | htmlItem* {title, htmlContent, icon, serviceName} | partly |
| lib/core/utilities/widgets/shared/screens/select_location_screen.dart | placeholder stub | — | n |
| lib/features/orders/presentation/widgets/order_modification/order_sheet_frame.dart (OrderSheetFrame) | sheet frame | icon*, iconColor*, iconBackground*, title*, subtitle*, child* | y |
| lib/features/splash/presentation/widgets/upgrade_dialog.dart (UpgradeDialog) + version helpers | update prompt, semver/build compare, installed version | show(context, latestVersion, storeUrl, notes) | y |
| lib/features/splash/presentation/screens/force_update_screen.dart, maintenance_screen.dart | forced update / maintenance takeovers | policy*, notes / (AppCubit config) | partly |
| lib/features/products/presentation/widgets/loading_grid.dart (LoadingGrid) | skeleton grid | — | partly |

## 6. Packages (pubspec.yaml)

- **State**: flutter_bloc ^9.1.1, hydrated_bloc ^11.0.0, equatable ^2.0.7
- **DI**: get_it ^9.0.5
- **Routing / deep links**: go_router ^17.2.3, app_links ^6.4.0
- **Network / result**: dio ^5.7.0, dartz ^0.10.1, talker_dio_logger ^5.0.2
- **Storage**: shared_preferences ^2.3.3, flutter_secure_storage ^10.0.0, path_provider ^2.1.5 (+ hydrated_bloc, cloud_firestore)
- **L10n**: easy_localization ^3.0.7, flutter_localizations (sdk), intl ^0.20.2
- **UI**: flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, cupertino_icons ^1.0.8, font_awesome_flutter ^11.0.0, dotted_border ^3.1.0, flutter_rating_bar ^4.0.1, skeletonizer ^2.1.0+1, cached_network_image ^3.4.1, flutter_animate ^4.5.2, carousel_slider ^5.1.2, lottie ^3.3.3, flutter_html ^3.0.0, country_picker ^2.0.2
- **Firebase / push**: firebase_core ^4.4.0, firebase_messaging ^16.1.1, cloud_firestore ^6.1.3, firebase_crashlytics ^5.0.7, flutter_local_notifications ^21.0.0 (firebase_auth commented out)
- **Media / files / share**: image_picker ^1.1.2, flutter_image_compress ^2.3.0, gal ^2.3.2, share_plus ^12.0.2
- **Web / payments**: webview_flutter ^4.13.1, flutter_inappwebview ^6.1.5, in_app_purchase ^3.3.0, in_app_purchase_android ^0.5.0, in_app_purchase_storekit ^0.4.11
- **Device / utils**: permission_handler ^12.0.1, url_launcher ^6.3.1, package_info_plus ^9.0.0, geolocator ^14.0.1, google_maps_flutter ^2.3.2
- **Realtime**: agora_rtc_engine ^6.6.4 (sockets via dart:io, no package)
- **Logging**: talker_flutter ^5.0.2
- **Build-time (listed under dependencies)**: flutter_native_splash ^2.4.3, flutter_launcher_icons ^0.14.4 (config in pubspec + flutter_launcher_icons.yaml)
- **Dev**: flutter_test (sdk), flutter_lints ^6.0.0

## 7. Quality notes

- **Null safety / SDK**: Dart ^3.10.7; uses modern syntax (null-aware collection elements `?titleActions`, wildcard `_` params, `switch` expressions, `sealed` states in newer code).
- **Lints**: `analysis_options.yaml` is the stock template (`include: package:flutter_lints/flutter.yaml`), no extra rules, nothing excluded.
- **Tests**: 21 test files + 1 fake repository, 126 cases. Focus on pure logic (deep-link normalization, version compare, models, filters/query params,
  image-layout math, text scaling) and a few widget tests. No tests for BaseRemoteDataSource/BaseRepository/base cubits, ApiService, DI.
- **Docs**: CLAUDE.md, COMMON_STRUCTURE.md, PROJECT_STRUCTURE.md (root and docs/), docs/FEATURES.md, RESPONSIVE_TEXT_AUDIT.md, STORE_LISTING.md, a backend hand-off note.
- **Duplication**: pagination is re-implemented per screen/cubit (scroll listener + `_currentPage` + `hasReachedMax`) while `InfiniteScrollScreen` sits unused;
  `AppTextFormField` re-declares all borders that `inputDecorationTheme` already defines (with different radii: 100.r vs 8.r);
  5 near-identical method branches in `BaseRemoteDataSource._executeRequest` and `ApiService`; two toast widgets; two share services.
- **Dead code**: listed in SMELLS (about 20 unused classes/functions plus 2 empty files).
- **Deprecated / outdated APIs**: `withOpacity` 94 occurrences (new code uses `withValues`, 96); no `WillPopScope` (uses `PopScope`); no `MaterialStateProperty`;
  `textScaleFactor` only as the required override in `_AppTextScaler`; `MediaQuery.of(context).size` 2 places.
- **Hardcoded values**: 138 `Color(0x..)` and 331 `Colors.*` in features; English fallback strings in core; `Accept-Language: ar` default; country code in phone field.
- **Bugs spotted while reading**: ToastManager's `Future.delayed(duration, _removeToast)` removes a newer toast early; `PasswordTextFormField` ignores `isLogin` and
  `confirmPasswordValidator` (always login rules); `DynamicDropdownFormField` search can't refilter an open `showMenu`; `showAppBottomSheet` ignores size params and
  never uses the scroll controller; `showImagePickerSheet` shows snackbars with the popped sheet's context; `AppValidator.isNumeric` regex ends with `\$` (literal `$`)
  and returns an untranslated key; `CacheFailure(message)` passes `''` to super; `NotificationsCubit.markAllAsRead` rollback restores the already-modified list;
  `AppState.copyWith` can't null the token.
- **Security**: bearer token logged by TalkerDioLogger and FCM token printed, in all builds; user password persisted at login; a third-party API key and a socket app key are
  committed in Dart source (api_keys.dart, reverb_socket_client.dart); `google-services.json` and `firebase_options.dart` are tracked in git (normal for Firebase, noted only);
  `key.properties` and `tebbr.jks` exist locally and are not in git history.
- **Template takeaways**: take `AppTextScale`, `ConnectivityService`+`NoInternetGate`, `request_limiters.dart`, `ImageViewerWidget`/`ImageViewerScreen`, `TranslationModel`,
  the system-config gate (maintenance / forced update) idea, the cold-start deep-link bounce, the notification pending-payload pattern, and the error-mapping logic of
  `BaseRemoteDataSource` (after decoupling from GetIt, adding 204/422 handling and Laravel `errors` parsing). Rewrite `BaseRepository` (catch-all), both base cubits
  (isClosed, typed copyWith, clearable failure, no print/stack traces), `ApiService` (awaited init, auth interceptor with 401 hook/refresh, debug-only logging),
  and `create_feature.dart` (generate cubit/state/screen/model, DI + route snippets, name validation, no unused imports).
