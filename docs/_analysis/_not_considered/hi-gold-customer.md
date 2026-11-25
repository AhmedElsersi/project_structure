# hi-gold-customer

## Summary for comparison

```
PROJECT: hi-gold-customer | path: Cleverness/hi-gold-customer | stack: Flutter, Dart sdk ^3.6.0 | last commit: 2025-03-19 | source files: 377
ARCH: clean-arch-lite, feature-first — features/<f>/{data/{data_sources/remote,models,repositories}, presentation/{blocs|cubit|manager,screens|pages,widgets}}; no domain layer (repos are concrete, return Either); shared base classes in core/base_architecture
STATE: flutter_bloc (Bloc + Cubit) — BaseSingleClassStateBloc.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart) + BaseSingleClassState{status,success,failure}; BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart); BaseSingleClassStateCubit; AppCubit is a HydratedCubit
DI: get_it (manual, everything registerLazySingleton incl. blocs) — lib/core/services/di_container.dart
ROUTING: go_router 14 — lib/core/app_router/app_router.dart + app_routes_names.dart — guards: no (no redirect; splash always goes to onboarding/login) | deep links: no | args via state.extra casts | TalkerRouteObserver
NETWORK: dio — interceptors: TalkerDioLogger only | token refresh: n | retry: n | error mapping: validateStatus<500, BaseRemoteDataSource maps status codes 400/401/403/404/422/5xx + DioException(timeout/network) to Failure subclasses, parses {errors:{field:[msgs]}} into ErrorDetail list | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/remote/base_remote_data_source.dart, lib/core/base_architecture/data/models/network_request_model.dart
RESULT_TYPE: Either (dartz) — lib/core/utilities/failures/failure.dart (+ error_details_model.dart); BaseRepository.handleNetworkCall (lib/core/base_architecture/data/repositories/base_repo.dart)
STORAGE: shared_preferences (token stored in plain prefs) + hydrated_bloc (AppCubit, CartCubit) — lib/core/services/shared_preferences_manager.dart, lib/core/utilities/constants/keys/shared_preferences_keys.dart
L10N: easy_localization — en, ar; default/start/fallback ar; assets/translations/{en,ar}.json (31 groups, 395 keys, nested dot keys) — hardcoded UI strings: some (~20 literal Text(), plus hardcoded 'Retry', 'Something went wrong', snackbar texts, mock data)
RTL: Directional=34 vs LeftRight=37
THEME: lib/core/theme/light_theme/light_theme.dart (+ light_widget_themes/*) — dark mode n (dark_theme.dart is empty) | component themes in ThemeData (appBar/buttons/inputs) y (appBar, elevated, text, button, input, snackBar, dialog, bottomNav, scrollbar, progress) | colors class AppColors (lib/core/utilities/constants/app_colors.dart) | text styles class TextThemeLight singleton + PoppinsTextStyles/CairoTextStyles | fonts Poppins (en) + Cairo (ar), switched per locale in main.dart
RESPONSIVE: flutter_screenutil (design size 376x812, minTextAdapt, splitScreenMode) — breakpoints: none
TEXT_SCALING: none (no textScaler clamp; only screenutil .sp)
ENV/FLAVORS: hardcoded constants (ApiKeys.BASE_URL in lib/core/utilities/constants/keys/api_keys.dart); no flavors, no dart-define, no dotenv
LOGGING: talker (TalkerDioLogger, TalkerRouteObserver, global `talker` in app_router.dart) + debugPrint in AppBlocObserver + print (18) + dart:developer log (32)
ANALYTICS/CRASH: none in code (firebase_analytics declared in pubspec, never used; no crashlytics/sentry)
PUSH: fcm + flutter_local_notifications — lib/features/home/data/datasources/local/local_notification_service.dart (initialized in main), lib/features/home/data/datasources/remote_datasource/firebase/notification_from_firebase.dart (never wired: NotificationRepository never instantiated)
PAYMENTS/IAP: none (cart/payment_options UI mock only)
PERMISSIONS: permission_handler + geolocator — lib/core/services/permission_helper.dart (location only); notifications via flutter_local_notifications requestNotificationsPermission
DEEP_LINKS: none
MEDIA/FILES: image_picker, cached_network_image, flutter_svg, google_maps_flutter + geocoding via Dio, palette_generator, carousel_slider, skeletonizer, shimmer, sms_autofill, pin_code_fields, flutter_colorpicker
TESTS: 0 — no test/ folder
LINTS: flutter_lints ^4.0.0 (include only, 0 extra rules)
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/base_architecture/data/data_sources/remote/base_remote_data_source.dart — base remote DS: handleRequest<T>(path, method, parser) + status/Dio error → Failure mapping + field-error parsing — quality 4 — coupling: low (pulls ApiService from serviceLocator inside base class)
- lib/core/utilities/failures/failure.dart — Failure hierarchy (BadRequest/Unauthorized/Forbidden/NotFound/Unprocessable/Server/Network/Timeout/Cache/Validation/Unknown) with code + errors + localized default messages — quality 4 — coupling: low (NotCompletedRegistrationFailure + MerchantStatus import are app-specific, strip)
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart — Bloc base with handleRequest (auto loading/success/failure emits, override hooks) — quality 4 — coupling: low (success must be BaseSuccessModel; `as State` casts)
- lib/core/utilities/widgets/base_fetching_data_widget.dart — BlocBuilder switch on FetchDataStatusEnum, Skeletonizer loading using a fake model, error+retry widget — quality 4 — coupling: low (hardcoded English 'Retry'/'Something went wrong')
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state.dart — abstract state {status, success, failure, copyWith} — quality 3 — coupling: none
- lib/core/services/api_service.dart — Dio wrapper with abstract ApiServiceBase, get/post/put/patch/delete(NetworkRequestParams), updateHeaders(token), updateLocale → Accept-Language — quality 3 — coupling: low (reads token from SharedPreferencesManager)
- lib/core/services/app_validator.dart — static validators (empty, email, phone, password strength, confirm, PIN, numeric, IBAN with mod-97 checksum, compose) with tr() messages — quality 4 — coupling: none (isNumeric regex bug)
- lib/core/base_architecture/data/repositories/base_repo.dart — handleNetworkCall → Either<Failure,T> — quality 3 — coupling: none (only catches Failure)
- lib/core/utilities/widgets/images/image_viewer_widget.dart — image from asset/local file/network auto-detected by string + precache + delete overlay; ImageType + String.imageProvider extensions — quality 4 — coupling: low (prefixes ApiKeys.BASE_URL)
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — labelled TextFormField with svg prefix/suffix (directional padding), unfocus on tap outside — quality 4 — coupling: low (AppIcons/AppColors)
- lib/core/services/bloc_observer.dart — BlocObserver that prints only changed fields when state has toJson — quality 3 — coupling: none
- lib/core/base_architecture/data/models/base_success_model.dart — factory registry BaseSuccessModel.register/create/createList + BaseSuccessModelWithData<T> wrapper — quality 3 — coupling: none (runtime registration via lib/core/services/register_models.dart)
- lib/core/services/shared_preferences_manager.dart — singleton prefs wrapper setValue(dynamic)/getValue/remove/clear — quality 3 — coupling: none
- lib/core/theme/light_theme/light_widget_themes/input_decoration_theme.dart — InputDecorationTheme + customInputDecorationTheme(context, radius, border sides) override helper — quality 3 — coupling: low
- lib/core/services/debounce.dart — Timer-based debouncer — quality 4 — coupling: none
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — base text field — title, controller, hintText, validator, svgPrefix/SuffixIconPath, prefix/suffixIcon, obscureText, readOnly, inputFormatters, maxLines, bottomMargin — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password field with visibility toggle — controller, isConfirmPassword, confirmPasswordValidator, isLogin — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/search_text_form_field.dart — debounced (500ms) search field + filter suffix — onChanged, onTapSuffix, bottomMargin — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/drop_down_text_form_field.dart — read-only field that expands inline list, shows loader by FetchDataStatusEnum — title, fetchStatus, dropDownList<IdTitleModel>, onTap, onTapItem, initialValue — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/multi_selection_text_form_field.dart — multi-select variant — title, controller, fetchStatus, dropDownList, selectedIds — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart — phone field with country code prefix — controller, countryCode, title, readOnly — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/number_text_form_field.dart — numeric field — title, suffixText, isInt — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/pick_date_text_form_field.dart — showDatePicker into controller — controller, title, hintText — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/pick_image_text_form_field.dart — field that opens image picker — controller, title, hintText, imageSource, onImageSelected — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/color_text_form_field.dart — color picker field (flutter_colorpicker) — colorNameController, colorHexController — quality 2 — generic? n
- lib/core/utilities/widgets/buttons/app_primary_button.dart — AppDefaultButton: ElevatedButton with loading spinner + trailing icon — content, onTap, isLoading, buttonStyle, textColor, icon — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_secondary_button.dart — outlined-look ElevatedButton — content, onTap — quality 2 — generic? y
- lib/core/utilities/widgets/buttons/app_text_button.dart — pill InkWell button — text, onTap, textStyle, width, height, backgroundColor, hasBorder, hasNoColor — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_third_button.dart — pill button title + svg icon, outline mode — title, svgIconPath, isOutlineBorder, btnColor, radius, height, width — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart — AppIconButton (circle svg button w/ loading) + AppBackButton (RTL-aware arrow, context.pop) — svgIconPath, onTap, radius, color, isLoading — quality 4 — generic? y
- lib/core/utilities/widgets/app_appbar.dart — CustomAppBarWidget + AppBarModel (title, title svg, back, suffix svg) — Row, not PreferredSizeWidget — quality 3 — generic? y
- lib/core/utilities/widgets/app_default_screen.dart — base scaffold: optional appBarModel, body, bottomSheet, onRefresh (RefreshIndicator), paddings — quality 3 — generic? y
- lib/core/utilities/widgets/base_fetching_data_widget.dart — BaseFetchingDataWidget<B,S,T> + BaseFetchingErrorWidget — child(model), loadingModel, loadingWidget, errorWidget, retryCallback — quality 4 — generic? y
- lib/core/utilities/widgets/base_list_view_widget.dart — BaseListViewWidget / BaseSliverListWidget with built-in empty state — models, childCard, noElements*, padding, physics — quality 3 — generic? y
- lib/core/utilities/widgets/no_elements_widget.dart — empty state (image, title, description) — quality 3 — generic? y
- lib/core/utilities/widgets/custom_alert_dialog.dart — image + title + content dialog with confirm/cancel (pops bool) — imageName, title, content, hasActions, onTapConfirm — quality 3 — generic? y
- lib/core/utilities/widgets/dashed_border_container.dart — dashed rounded border via CustomPainter — child, dashWidth, dashSpace, borderColor, borderRadius — quality 4 — generic? y
- lib/core/utilities/widgets/drop_down_list_widget.dart — list of IdTitleModel selections — selectionsList, onTapItem — quality 3 — generic? y
- lib/core/utilities/widgets/multi_selection_list_widget.dart — checkbox list — selectionsList, selectedIds, onTapItem — quality 3 — generic? y
- lib/core/utilities/widgets/rounded_colored_container.dart — decorated container — child, padding, margin, backgroundColor, radius, border — quality 3 — generic? y
- lib/core/utilities/widgets/images/cached_network_image_widget.dart — CachedNetworkImage with progress + broken icon — imageUrl, fit — quality 3 — generic? y
- lib/core/utilities/widgets/images/image_viewer_widget.dart — asset/local/network image tile + delete badge — image, width, height, radius, shape, isDeleteEnabled, onTap, onTapDelete, fit — quality 4 — generic? y
- lib/core/utilities/widgets/images/image_viewer_screen.dart — fullscreen image route — imagePath — quality 3 — generic? y
- lib/core/utilities/widgets/images/image_horizontal_list_view.dart — horizontal thumbnails — images, selectedIndex — quality 3 — generic? y
- lib/core/utilities/widgets/images/image_picker_widget.dart — avatar/box image picker — label, imagePath, size, placeholderSvgPath, imageSource — quality 3 — generic? y
- lib/core/utilities/widgets/images/image_picker_bottom_sheet.dart — showImagePickerSheet(camera/gallery or direct source) — onFilePicked, imageSource — quality 3 — generic? y
- lib/core/utilities/widgets/rating/rating_bar_widget.dart — RatingBarWidget (stars) + CustomRatingBarWidget (svg emotion icons) — initialRating, starCount, size, onRatingChanged — quality 3 — generic? y
- lib/core/utilities/widgets/rating/rating_indicator_widget.dart — read-only star indicator — rating, starCount, size, colors — quality 3 — generic? y
- lib/core/utilities/widgets/otp_code_screen.dart — OTP screen (pin_code_fields + sms_autofill) — OtpScreenParams — quality 3 — generic? n (auth-flow specific)
- lib/core/utilities/widgets/select_location_screen.dart — Google Map pick + reverse geocode — quality 3 — generic? n (needs GoogleMapsService)
- lib/core/utilities/widgets/texts_in_row_widget.dart — title/value row — titleValueModel — quality 2 — generic? n (imports products model)
NOTABLE_IDEAS: (1) status-driven single-class state + BaseFetchingDataWidget that renders Skeletonizer over the real child with a fake "loadingModel" (lib/core/utilities/widgets/base_fetching_data_widget.dart) — no hand-written skeletons; (2) Failure subclasses with localized default messages and field-level ErrorDetail parsing (lib/core/utilities/failures/failure.dart, base_remote_data_source.dart `_parseErrorDetails`); (3) ImageType detection extension on String → one widget for asset/file/network (lib/core/utilities/widgets/images/image_viewer_widget.dart); (4) BlocObserver logging only changed fields via toJson diff (lib/core/services/bloc_observer.dart); (5) IBAN mod-97 validator (lib/core/services/app_validator.dart); (6) RTL-aware AppBackButton (lib/core/utilities/widgets/buttons/app_icon_button.dart); (7) Accept-Language header kept in sync with locale via ApiService.updateLocale; (8) per-locale font family applied via textTheme.apply in main.dart; (9) main.dart split into _initUIComponents/_initSystemComponents/_initArchitectureComponents with Future.wait; (10) customInputDecorationTheme override helper
SMELLS: core barrel files (lib/core/exports/*.dart) export feature screens/blocs → core depends on features, everything imports core_exports.dart; MerchantStatus enum in core imports feature screens; blocs registered as lazy singletons in get_it and provided with BlocProvider.value/create from singletons (state leaks between screens), CartCubit() created inline in route; AppCubit connectivity check compares List<ConnectivityResult> to enum (connectivity_plus 6) → isConnected always false after first event; AppState.fromMap casts List<dynamic> as List<String> (hydration silently fails) and persists isConnected/isLoading; HydratedStorage in getTemporaryDirectory; token in plain SharedPreferences; no auth guard/redirect and no 401 → logout; ApiService `_executeRequest` catch blocks are no-ops; ResponseHandler/AppException hierarchy in lib/core/services/response_handeler.dart unused (dead duplicate of Failure); BaseCubit casts ErrorState as State (runtime cast error unless state type allows); isNullOrEmpty extensions use `this == null && this!.isEmpty` (wrong logic, NPE); AppValidator.isNumeric regex ends with `\$` (never matches); locale switch calls updateLocale with the old locale; PermissionHelper button labels swapped (open settings vs location settings) and calls requestPermission twice; GoogleMapsService and stock_details_screen hold a hardcoded Maps API key; hardcoded colors (101 raw Colors.x, 33 Color(0x..)); deprecated ColorScheme onBackground/background, DialogTheme (vs DialogThemeData), withOpacity x3; print x18; mock/example data used instead of API in ProductBloc (`productDetailsModelExample`) and CartCubit; duplicate select_location_screen in features/cart/presentation/pages; misspelt files (response_handeler.dart, inquires); unused packages (firebase_analytics, transparent_image, pin_code_text_field, gap); text strings in MerchantStatus.description English-only; customer app still uses merchant endpoints/flows copied from seller
```

## 1. Architecture pattern

Feature-first "clean-arch-lite" built on BLoC. There is no real domain layer: each feature has
`data/` (remote data source extending `BaseRemoteDataSource`, models extending `BaseSuccessModel`,
concrete repository extending `BaseRepository` that returns `Either<Failure, T>`) and
`presentation/` (blocs/cubits, screens/pages, widgets, sometimes local `models/` and `exports/`).
Only `features/requests/domain/entities` exists as a domain folder, holding a plain entity.

Request flow: Screen → `context.read<XBloc>().add(event)` → Bloc extends
`BaseSingleClassStateBloc` and calls `handleRequest(call: () => repo.getX())` → Repository
`handleNetworkCall(call: () => remoteDataSource.getX())` → `BaseRemoteDataSource.handleRequest<T>(path, method, parser)`
→ `serviceLocator<ApiService>().get/post(...)` (Dio). Errors are thrown as `Failure` subclasses in the data source,
converted to `Left` in the repository, and emitted as `state.copyWith(status: failure, failure: f)` in the bloc.
The UI reads state with `BaseFetchingDataWidget<B, S, Model>`.

The customer app is a fork of the seller app (hi-gold-seller). Its `core/` is the more evolved copy
(uses `withValues`, more widget params, 422 handling, `BaseSliverListWidget`, shared widgets moved
from `features/shared` into `core/utilities/widgets`). Several flows (auth login/register, merchant status,
`/api/merchant/*` endpoints) are still merchant-oriented leftovers.

## 2. Folder tree (`lib/`, 4 levels)

```
lib/
├── main.dart                         bootstrap: native splash, hydrated storage, Firebase, EasyLocalization, prefs, local notifs, DI, BlocObserver, ScreenUtilInit, MaterialApp.router
├── firebase_options.dart             (FlutterFire generated; secret file, not opened)
├── core/
│   ├── app_cubit/                    AppCubit (HydratedCubit) + AppState (locale, guest, connectivity, flags)
│   ├── app_router/                   go_router config (app_router.dart) + route path constants (app_routes_names.dart)
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/remote/  BaseRemoteDataSource
│   │   │   ├── models/               BaseSuccessModel registry, NetworkRequestParams, GeoCodingAddressDetails
│   │   │   └── repositories/         BaseRepository (Either wrapper)
│   │   └── presentation/managers/
│   │       ├── base_cubit/                       BaseCubit + BaseState/LoadingState/ErrorState
│   │       ├── base_single_class_state_bloc/     BaseSingleClassStateBloc + BaseSingleClassState
│   │       └── base_single_class_state_cubit/    BaseSingleClassStateCubit
│   ├── base_enum/                    FetchDataStatusEnum, FormStatusEnum, HttpMethod, MerchantStatus (app-specific, routes+screens), ProductPropertyTypeEnum
│   ├── exports/                      barrel files (core_exports, packages_exports, screens_export, bloc_exports, ...) — export features too
│   ├── extensions/                   BuildContext (isAr, theme, textTheme), String (toColor, toDouble), List, int (lineHeight)
│   ├── services/                     ApiService, DI container, register_models, prefs manager, validators, BlocObserver, debounce, permissions, image picker/viewer, Google geocoding, ResponseHandler (unused)
│   ├── theme/
│   │   ├── dark_theme/               dark_theme.dart (empty file)
│   │   └── light_theme/              lightTheme + light_widget_themes/ (appBar, bottomNav, buttons, dialog, input, colorScheme, snackBar, text theme)
│   └── utilities/
│       ├── common_models/            IdTitleModel
│       ├── constants/                AppColors, AppConstantVariables, ConstantLists (app data), assets/ (AppIcons, AppImages, temp images), keys/ (ApiKeys endpoints, SharedPreferencesKeys), styles/ (Poppins/Cairo TextStyles)
│       ├── converters/               price_converter.dart (empty)
│       ├── failures/                 Failure hierarchy, ErrorDetail
│       ├── formatters/               DateFormatter
│       └── widgets/                  shared widgets: app bar, default screen, fetching/list bases, dialog, dashed border, dropdowns, OTP screen, select-location screen
│           ├── buttons/              primary/secondary/text/third/icon(+back) buttons
│           ├── images/               cached image, viewer widget/screen, picker widget + bottom sheet, horizontal list
│           ├── rating/               rating bar, rating indicator
│           └── text_form_fields/     AppTextFormField + password/search/phone/number/date/image/color/dropdown/multi-select fields
└── features/
    ├── auth/            login, register stepper, OTP, PIN, follow-up track, subscription, blocked (merchant-style flow)
    ├── bottom_nav/      BottomNavScreen, NavigationWidget, guest FAB
    ├── cart/            CartCubit (hydrated, mock data), cart item cubit, cart/address/select-location pages
    ├── home/            home tabs, banners, categories, branches, notifications (local + FCM + server data sources)
    ├── merchant/        merchant profile (MerchantBloc)
    ├── more/            contact_and_support, inquires, invoices, more_presentation, my_balance, profile, settings/{language,privacy,settings_presentation,terms_and_conditions}, statistics, stock, zakat_calculation
    ├── orders/          OrdersBloc, order list/details/actions/image screens
    ├── products/        (expanded below)
    ├── requests/        RequestsBloc (+customer sub-bloc), domain/entities
    └── splash/          splash + onboarding
```

Representative feature, `features/products/`:

```
products/
├── data/
│   ├── data_sources/remote/products_remote_data_source.dart   extends BaseRemoteDataSource; getMainCategories/getSubCategories/getProducts/searchProducts/getProductDetails; ProductsStatus enum with url getter
│   ├── models/request/          add_edit_review_params, change_product_status_params
│   ├── models/response/         product_model (BaseSuccessModel), product_details_model, main/sub category models
│   └── repositories/products_repo.dart                        extends BaseRepository; wraps lists in BaseSuccessModelWithData<List<T>>
├── presentation/
│   ├── blocs/categories_bloc/   Bloc + event + state (part files)
│   ├── blocs/product_bloc/      ProductBloc extends BaseSingleClassStateBloc; ProductState extends BaseSingleClassState with extra UI fields
│   ├── blocs/products_bloc/
│   ├── models/title_value_model.dart
│   ├── screens/                 products_screen, product_details_screen (AppDefaultScreen + BaseFetchingDataWidget), product_image_screen (palette_generator bg)
│   └── widgets/                 product_card, product_details_widgets/* (images, info, price, size, quantity, review sections)
└── products_exports/            per-file barrel exports (data_exports, presentation_exports/{blocs,screens,widgets})
```

## 3. Infrastructure

### State management
- `flutter_bloc ^8.1.6`, `equatable`, `hydrated_bloc ^9.1.5`.
- `BaseSingleClassState` (abstract, `status: FetchDataStatusEnum`, `success: BaseSuccessModel?`, `failure: Failure?`, abstract `copyWith`).
- `BaseSingleClassStateBloc<Event, State>.handleRequest<T>({call, onNotDefaultSuccessState, onNotDefaultErrorState, onNotDefaultLoading})`: emits loading, folds the `Either`, emits success/failure by default, any hook overrides the default emit. Catches everything into `UnknownFailure`. It calls the Bloc's own `emit` (marked `@visibleForTesting` in bloc 8) instead of the event handler's `Emitter`, which works but is discouraged; a template version should take the `Emitter` as a parameter.
- `BaseCubit<State extends BaseState>.handleRequest` emits a provided `loadingState` and `ErrorState(...) as State` — the cast fails if the cubit's state hierarchy does not include `ErrorState`.
- `BaseSingleClassStateCubit.handleCubitFetchingEmits(repoResult)`: same idea for cubits, using `.then/.catchError`.
- `AppCubit` (`lib/core/app_cubit/app_cubit.dart`): HydratedCubit holding locale, guest flag, connectivity and many unused flags (isDarkMode, biometricEnabled, forceUpdate...). Bugs: connectivity comparison (see smells), `fromMap` cast failure.
- `AppBlocObserver` logs events, state diffs (via `toJson` if present), errors, closes.
- Quality: the base trio (state/bloc/fetching widget) is the most reusable piece of the app. Weaknesses: success forced to `BaseSuccessModel` (lists need `BaseSuccessModelWithData` wrapper), casts everywhere, blocs registered as get_it singletons.

### DI
- `get_it ^8.0.3`, manual, `lib/core/services/di_container.dart`. `diContainerSetup()` registers: `SharedPreferencesManager`, `Dio`, `ApiService(ApiKeys.BASE_URL, ...)`, then every remote data source, repo, bloc and cubit as `registerLazySingleton`. The init functions are `async` but not awaited (harmless here). `lib/core/exports/di_container_exports.dart` is empty.
- Model factories registered separately in `lib/core/services/register_models.dart` (`BaseSuccessModel.register<T>(T.fromJson)`).
- Quality 2/5: blocs as singletons mean state survives navigation and `close()` from BlocProvider(create:) would kill the singleton.

### Routing
- `go_router ^14.6.2`, `lib/core/app_router/app_router.dart` (379 lines, ~45 routes), path constants in `app_routes_names.dart`.
- Splash route `/` with nested onboarding; custom fade `CustomTransitionPage` for splash; bottomNav route with nested request details and `MultiBlocProvider` wrapping; arguments passed through `state.extra as T` (int ids, models, param objects).
- `observers: [TalkerRouteObserver(talker)]`; global `final talker = Talker()` lives in the router file.
- No `redirect`, no auth guard, no `errorBuilder`, no deep links. Splash does `Future.delayed(2s)` → onboarding → login. Guest mode decided ad hoc in screens (`context.read<AppCubit>().state.userIsGuest ? push(login) : ...`).

### Networking
- `dio ^5.7.0`, `talker_dio_logger`.
- `lib/core/services/api_service.dart`: `ApiServiceBase` interface + `ApiService(baseUrl, dioClient, sharedPreferencesManager)`. Sets base URL, 30 s connect/receive timeouts, `validateStatus: 200..499` (4xx returned as responses, not exceptions), default JSON headers, `Authorization: Bearer <token>` read once from prefs, `Accept-Language` from `updateLocale`. `updateHeaders(token:, customHeaders:)` used after login/registration.
- `lib/core/base_architecture/data/data_sources/remote/base_remote_data_source.dart`: `handleRequest<T>({path, method, parser, data, queryParameters})` and `genericHandleRequest<T extends BaseSuccessModel>` (uses the factory registry, returns `dynamic`). Error mapping: 400 → BadRequestFailure(message, errors), 401 → Unauthorized, 403 → Forbidden, 404 → NotFound, 422 → Unprocessable(message, errors), else → ServerFailure; `DioException.connectionTimeout` → TimeoutFailure, Dio with response → status mapping, otherwise NetworkFailure; non-Failure exceptions → UnknownFailure.
- No token refresh, no retry, no 401 global handler, no connectivity pre-check, no cancel tokens used by features (supported by `NetworkRequestParams`).
- `lib/core/services/response_handeler.dart`: an alternative `ResponseHandler.handle` + `AppException` hierarchy — unused.
- `lib/core/services/google_maps_services.dart`: reverse geocoding through a second raw `Dio()`; API key hardcoded (secret in source).
- Some data sources bypass the base class (auth `login` calls `ApiService.post` directly and builds its own `Either`; `savePinCode` returns an un-awaited Future inside `Right`).

### Local storage
- `shared_preferences` via singleton `SharedPreferencesManager` (`init()` in main, `setValue(key, dynamic)`, `getValue`, `remove`, `clear`). Keys in `SharedPreferencesKeys` (isFirstTime, isLoggedIn, token, temp_token).
- Auth token and temporary registration token are stored in plain prefs (no flutter_secure_storage).
- `hydrated_bloc` storage built in `getTemporaryDirectory()` (OS may clear it) for AppCubit and CartCubit.

### Localization and RTL
- `easy_localization ^3.0.7` (+ `flutter_localizations`, `intl ^0.19.0`). Supported `en`, `ar`; `startLocale` and `fallbackLocale` = `ar`. Translations at `assets/translations/{en,ar}.json`, nested groups (`validations.*`, `failures.*`, `actions.*`, `auth.*`, `placeholders.*`...), 395 keys each, keys in sync. Usage via `'key'.tr()` (302 call sites); no generated LocaleKeys.
- `flutter: generate: true` set but no l10n.yaml/arb files.
- RTL: `MaterialApp.router` wrapped in an explicit `Directionality` driven by `AppCubit.state.locale` (while MaterialApp itself uses `context.locale` — two sources of truth). `MaterialApp` gets `key: ValueKey(locale)` to rebuild on change. Back arrow chosen by locale. 34 directional vs 37 left/right usages — mixed.
- Language switch (`features/more/settings/language/presentation/widgets/change_language_dialog.dart`) calls `ApiService.updateLocale(context.locale)` before switching (sends the old language), then `AppCubit.setLocale` and `context.setLocale`.
- Failures carry localized default messages; validators return `tr()` strings.

### Theming
- `lib/core/theme/light_theme/light_theme.dart`: `ThemeData(useMaterial3: true)` with colorScheme `fromSeed`, appBarTheme, bottomNavigationBarTheme, `TextThemeLight.instance.txtTheme` (M3 scale using `.sp`), buttonTheme, elevatedButtonTheme (fixed 343x52 size, asymmetric radius), textButtonTheme, snackBarTheme (floating), dialogTheme, inputDecorationTheme (filled, 26 r radius), progressIndicatorTheme, scrollbarTheme (WidgetStateProperty).
- `main.dart` applies `fontFamily` Cairo for Arabic and Poppins otherwise via `textTheme.apply`.
- Colors: `AppColors` static constants (accent gold-ish, neutrals, alpha variants via `withValues`, success/error/warning). Text styles: `PoppinsTextStyles`, `CairoTextStyles` (weights only), `text_styles.dart` duplicates a `CairoTextStyles` class name.
- Dark mode: not implemented (`dark_theme.dart` empty, `isDarkMode` flag unused).
- Assets: `AppIcons.svg(assetName, width, height, color)` helper and `AppImages.image(...)` helper over path constants.

### Responsive helpers
- `flutter_screenutil ^5.9.3`, `ScreenUtilInit(designSize: Size(376, 812), minTextAdapt: true, splitScreenMode: true)`. `.w/.h/.r/.sp` everywhere, including inside theme definitions. No breakpoints, no tablet layout.

### Text scaling
- None. No `textScaler`/`MediaQuery` clamp; only screenutil `.sp` (`minTextAdapt`).

### Env / flavors
- None. `ApiKeys.BASE_URL` constant (`{{BASE_URL}}`) and endpoint constants in `lib/core/utilities/constants/keys/api_keys.dart`; app name in `AppConstantVariables`. Android `build.gradle.kts` has no productFlavors; release uses debug signing config.

### Logging
- talker: `TalkerDioLogger` interceptor (request headers printed), `TalkerRouteObserver`, a few `talker.debug`. `AppBlocObserver` uses `debugPrint` with emojis. Plus `print` (18) and `dart:developer log` (32).

### Analytics / crash reporting
- None wired. `firebase_analytics ^11.4.0` and `firebase_core` in pubspec; only `Firebase.initializeApp` is called.

### Push notifications
- `firebase_messaging ^15.2.0` + `flutter_local_notifications ^18.0.1`.
- `LocalNotificationService` (static; init with Android/iOS settings, requests Android notification permission at startup, `showNotification`, cancel/cancelAll; tap handler only prints).
- `NotificationFromFirebase` (getToken, requestPermission, onMessage → local notification, background handler stub) and `NotificationRepository` exist but are never instantiated; `getDeviceToken` in main is commented out. FCM is effectively not active.

### IAP / payments
- None (cart `payment_options.dart` is UI only).

### Permissions
- `permission_handler ^11.3.1` (only `openAppSettings`) and `geolocator ^13.0.2` (`requestPermission`). `PermissionHelper.checkLocationPermission(context)` shows dialogs on denied / deniedForever. Manifest declares internet, notifications, network state, storage, fine/coarse/background location, SMS receive.

### Deep links
- None (no intent filters for VIEW, no app_links/uni_links, no go_router deep-link config).

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/services/api_service.dart | Dio HTTP wrapper | `ApiServiceBase`, `ApiService(baseUrl, dioClient, sharedPreferencesManager)`, `get/post/put/patch/delete(NetworkRequestParams)`, `updateHeaders`, `updateLocale` | dio, talker_dio_logger, SharedPreferencesManager | generic |
| lib/core/base_architecture/data/data_sources/remote/base_remote_data_source.dart | Base remote DS + error mapping | `handleRequest<T>`, `genericHandleRequest<T extends BaseSuccessModel>` | ApiService via serviceLocator, Failure, ErrorDetail | generic |
| lib/core/base_architecture/data/repositories/base_repo.dart | Either wrapper | `handleNetworkCall<T>({call})` | dartz, Failure | generic |
| lib/core/base_architecture/data/models/base_success_model.dart | Model base + factory registry | `fromMap`, `register<T>`, `create<T>`, `createList<T>`; `BaseSuccessModelWithData<T>` | — | generic |
| lib/core/base_architecture/data/models/network_request_model.dart | Request params DTO | `NetworkRequestParams(uri, data, queryParameters, options, cancelToken, progress cbs)` | dio | generic |
| lib/core/base_architecture/data/models/geocoding_address_details.dart | Google geocode result model | `GeoCodingAddressDetails.fromJson` | equatable | generic (maps-specific) |
| lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart | Cubit base | `handleRequest<T>({loadingState, call, onSuccess, onError, showLoading})` | dartz, flutter_bloc | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/base_state.dart | Base states | `BaseState`, `LoadingState`, `ErrorState(message)` | equatable | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state.dart | Single-class state base | `status`, `success`, `failure`, `copyWith` | equatable | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart | Bloc base | `handleRequest<T>({call, onNotDefaultSuccessState, onNotDefaultErrorState, onNotDefaultLoading})` | flutter_bloc, dartz | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_cubit/base_single_class_state_cubit.dart | Cubit base for single-class state | `handleCubitFetchingEmits({repoResult})` | bloc, dartz | generic |
| lib/core/app_cubit/app_cubit.dart (+ app_state.dart) | Global app state (locale, guest, connectivity) | `setUserAsGuest`, `setLocale`, hydration | hydrated_bloc, connectivity_plus | mostly generic (buggy) |
| lib/core/services/di_container.dart | get_it registrations | `serviceLocator`, `diContainerSetup()` | get_it, all features | app-specific |
| lib/core/services/register_models.dart | Registers model factories | `registerModels()` | feature models | app-specific |
| lib/core/services/shared_preferences_manager.dart | Prefs singleton | `init`, `setValue`, `getValue`, `remove`, `clear` | shared_preferences | generic |
| lib/core/services/app_validator.dart | Form validators | `isNotEmpty`, `isValidEmail`, `isValidPhone`, `isValidPassword(value, isLogin)`, `confirmPassword`, `isValidPin`, `validateNewPin`, `isNumeric`, `isNotEmptyImage`, `ibanValidator`, `customValidator` | easy_localization | generic |
| lib/core/services/bloc_observer.dart | Bloc logging | `AppBlocObserver` | flutter_bloc | generic |
| lib/core/services/debounce.dart | Debouncer | `Debounce(milliseconds).run(action)`, `cancel` | dart:async | generic |
| lib/core/services/google_maps_services.dart | Reverse geocoding | `getAddressFromLatLng(lat, lng)` | dio (own instance), hardcoded key | app-specific (needs key from env) |
| lib/core/services/image_picker_service.dart | Pick image to File | `pickImage({context, source})` (SnackBar on cancel/error) | image_picker | generic |
| lib/core/services/image_viewer_service.dart | Push image viewer route | `viewImage({context, imagePath})` | go_router | generic |
| lib/core/services/permission_helper.dart | Location permission + settings dialogs | `checkLocationPermission(context)` | geolocator, permission_handler | generic (location only) |
| lib/core/services/response_handeler.dart | Status → exception (unused) | `ResponseHandler.handle(response)`, `AppException` + 8 subclasses | dio | generic, dead |
| lib/core/utilities/failures/failure.dart | Failure hierarchy | `Failure(message, code, errors)` + 11 subclasses, `NotCompletedRegistrationFailure.fromJson` | easy_localization, MerchantStatus | generic core + app-specific tail |
| lib/core/utilities/failures/error_details_model.dart | Field validation errors | `ErrorDetail(field, messages)`, `fromJson` | — | generic |
| lib/core/utilities/formatters/date_formatter.dart | Date string reformat | `formatDateString(dateStr, format)` | intl | generic |
| lib/core/utilities/common_models/id_title_model.dart | Dropdown item model | `IdTitleModel(id, title, value)` | — | generic |
| lib/core/utilities/constants/app_colors.dart | Color palette | static colors | flutter | app-specific values |
| lib/core/utilities/constants/app_constant_variables.dart | App name, translations path, font names | constants | — | generic shape |
| lib/core/utilities/constants/app_constant_lists.dart | Static app lists (merchant types, more items...) | `ConstantLists.*` | features | app-specific |
| lib/core/utilities/constants/assets/icons.dart | SVG paths + `AppIcons.svg()` helper | `svg({assetName, width, height, color})` | flutter_svg | generic helper |
| lib/core/utilities/constants/assets/images.dart | Image paths + `AppImages.image()` | `image({assetName, width, height})` | flutter | generic helper |
| lib/core/utilities/constants/assets/temp_images.dart | Mock image paths | constants | — | app-specific |
| lib/core/utilities/constants/keys/api_keys.dart | Base URL + endpoints | constants + functions | — | app-specific |
| lib/core/utilities/constants/keys/shared_preferences_keys.dart | Prefs keys | constants | — | generic |
| lib/core/utilities/constants/styles/poppins_text_styles.dart, cairo_text_styles.dart, text_styles.dart | Weight presets per font | static TextStyles | flutter | generic |
| lib/core/extensions/context_extensions.dart | `isAr`, `theme`, `textTheme` | getters | easy_localization | generic |
| lib/core/extensions/string_extensions.dart | `isNullOrEmpty` (buggy), `toColor`, `toDouble` | getters/methods | flutter | generic |
| lib/core/extensions/list_extensions.dart | `isNullOrEmpty` (buggy), `isNotNullNorEmpty` | getters | — | generic |
| lib/core/extensions/int_extension.dart | Figma line height → height factor | `lineHeight({fontSize})` | — | generic |
| lib/core/base_enum/*.dart | FetchDataStatusEnum, FormStatusEnum, HttpMethod, ProductPropertyTypeEnum, MerchantStatus (route/screen/step mapping) | enums + extensions | features (MerchantStatus) | generic except MerchantStatus |
| lib/core/theme/light_theme/light_widget_themes/text_theme.dart | M3 TextTheme with .sp | `TextThemeLight.instance.txtTheme` | screenutil | generic |
| lib/core/theme/light_theme/light_widget_themes/input_decoration_theme.dart | Input theme + override helper | `inputDecorationTheme`, `customInputDecorationTheme(...)` | screenutil | generic |
| lib/features/home/data/datasources/local/local_notification_service.dart | Local notifications | `initialize`, `requestNotificationPermission`, `showNotification`, `cancelNotification`, `cancelAllNotifications` | flutter_local_notifications | generic |
| lib/features/home/data/datasources/remote_datasource/firebase/notification_from_firebase.dart | FCM token + foreground display | `getDeviceToken`, `initFirebaseNotification` | firebase_messaging | generic (unwired) |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/app_appbar.dart | In-body app bar row + `AppBarModel` | appBarModel{title, titleSvgPath, titleSvgColor, suffixSvgPath, suffixSvgColor, onTapBack, onTapSuffix} | y |
| lib/core/utilities/widgets/app_default_screen.dart | Base scaffold | backgroundColor, appBarModel, body, bottomSheet, onRefresh, appBarPadding, bodyPadding | y |
| lib/core/utilities/widgets/base_fetching_data_widget.dart | Status-driven builder with skeleton loading; `BaseFetchingErrorWidget` | child(model), loadingModel, loadingWidget, errorWidget, retryCallback / message, onFailure, isHorizontal | y |
| lib/core/utilities/widgets/base_list_view_widget.dart | Separated list / sliver list with empty state | models, childCard, noElementsImage/Title/Description, padding, physics / itemPadding | y |
| lib/core/utilities/widgets/no_elements_widget.dart | Empty state | imageName, title, description, imageHeight, imageWidth, padding | y |
| lib/core/utilities/widgets/custom_alert_dialog.dart | Image dialog with confirm/cancel | imageName, imageHeight, imageWidth, title, titleColor, content, contentStyle, hasActions, onTapConfirm | y |
| lib/core/utilities/widgets/dashed_border_container.dart | Dashed border container + painter | child, height, width, padding, dashWidth, dashSpace, borderColor, borderRadius | y |
| lib/core/utilities/widgets/rounded_colored_container.dart | Rounded decorated box | child, padding, margin, backgroundColor, radius, borderRadius, height, width, border | y |
| lib/core/utilities/widgets/drop_down_list_widget.dart | Selection list + `SelectionItemWidget` | selectionsList, onTapItem, bottomMargin | y |
| lib/core/utilities/widgets/multi_selection_list_widget.dart | Checkbox list + item | selectionsList, selectedIds, onTapItem, bottomMargin | y |
| lib/core/utilities/widgets/texts_in_row_widget.dart | Title/value row | titleValueModel | n |
| lib/core/utilities/widgets/otp_code_screen.dart | OTP verification screen + `OtpScreenParams` | otpScreenParams{verifiableDataTitle, verifiableData, onVerifyLoading, ...} | n |
| lib/core/utilities/widgets/select_location_screen.dart | Map location picker | — (returns via pop) | n |
| lib/core/utilities/widgets/buttons/app_primary_button.dart | `AppDefaultButton` | content, onTap, isLoading, buttonStyle, textColor, icon | y |
| lib/core/utilities/widgets/buttons/app_secondary_button.dart | Secondary button | content, onTap | y |
| lib/core/utilities/widgets/buttons/app_text_button.dart | Pill text button | text, onTap, textStyle, width, height, padding, margin, backgroundColor, hasBorder, hasNoColor | y |
| lib/core/utilities/widgets/buttons/app_third_button.dart | Pill title+icon button | title, onTap, titleStyle, width, height, horizontalPadding, svgIconPath, iconSize, iconColor, btnColor, radius, bottomMargin, isOutlineBorder | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart | Circle svg button + `AppBackButton` | svgIconPath, onTap, iconSize, radius, color, svgIconColor, margin, padding, isLoading / onTapBack, radius, color, svgIconColor | y |
| lib/core/utilities/widgets/images/cached_network_image_widget.dart | Network image | imageUrl, fit | y |
| lib/core/utilities/widgets/images/image_viewer_widget.dart | Asset/file/network image tile + delete | image, imageWidth, imageHeight, radius, margin, shape, isDeleteEnabled, onTap, onTapDelete, fit | y |
| lib/core/utilities/widgets/images/image_viewer_screen.dart | Fullscreen viewer | imagePath | y |
| lib/core/utilities/widgets/images/image_horizontal_list_view.dart | Thumbnails strip | images, selectedIndex | y |
| lib/core/utilities/widgets/images/image_picker_widget.dart | Image picker box | label, imagePath, size, backgroundColor, placeholderSvgPath, borderRadius, imageSource, bottomMargin, callback | y |
| lib/core/utilities/widgets/images/image_picker_bottom_sheet.dart | `showImagePickerSheet()` camera/gallery | context, onFilePicked, imageSource | y |
| lib/core/utilities/widgets/rating/rating_bar_widget.dart | Interactive stars / svg emotion rating | initialRating, starCount, size, onRatingChanged / padding, svgIcons | y |
| lib/core/utilities/widgets/rating/rating_indicator_widget.dart | Read-only stars | rating, starCount, size, filledColor, emptyColor | y |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart | Base field | see summary (25 params) | y |
| lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart | Password | controller, isConfirmPassword, confirmPasswordValidator, title, hintText, isLogin | y |
| lib/core/utilities/widgets/text_form_fields/search_text_form_field.dart | Debounced search | onChanged, onTapSuffix, bottomMargin | y |
| lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart | Phone + country code | controller, countryCode, title, initialValue, hintText, readOnly, onTap, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/number_text_form_field.dart | Number | controller, title, initialValue, hintText, suffixText, onTap, onChanged, readOnly, isInt | y |
| lib/core/utilities/widgets/text_form_fields/pick_date_text_form_field.dart | Date picker field | controller, title, initialValue, hintText, onTap | y |
| lib/core/utilities/widgets/text_form_fields/pick_image_text_form_field.dart | Image picker field | controller, title, hintText, imageSource, onImageSelected, onTap | y |
| lib/core/utilities/widgets/text_form_fields/drop_down_text_form_field.dart | Inline dropdown field | title, fetchStatus, dropDownList, initialValue, hintText, onTap, onTapItem, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/multi_selection_text_form_field.dart | Multi-select field | title, controller, fetchStatus, dropDownList, selectedIds, hintText, onTap | y |
| lib/core/utilities/widgets/text_form_fields/color_text_form_field.dart | Color picker field | colorNameController, colorHexController | n |
| lib/features/bottom_nav/presentation/widgets/navigation_widget.dart | Bottom nav bar item renderer | app nav items | n |
| lib/features/cart/presentation/widgets/cart_notification_overlay.dart | Positioned cart-count badge | none | n |

No shimmer widget in core (Skeletonizer is used through BaseFetchingDataWidget; one feature placeholder uses `shimmer`), no snackbar/toast helper, no pagination list, no connectivity banner.

## 6. Packages (pubspec.yaml)

- State: flutter_bloc ^8.1.6, hydrated_bloc ^9.1.5, equatable ^2.0.7
- DI: get_it ^8.0.3
- Routing: go_router ^14.6.2
- Network: dio ^5.7.0, connectivity_plus ^6.1.3
- Result/FP: dartz ^0.10.1
- Storage: shared_preferences ^2.3.3, path_provider ^2.1.5
- L10n: easy_localization ^3.0.7, intl ^0.19.0, flutter_localizations (sdk)
- UI: flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, gap ^3.0.1 (unused), flutter_native_splash ^2.4.3, flutter_animate ^4.5.2, animate_do ^3.3.4, skeletonizer ^1.4.2, shimmer ^3.0.0, carousel_slider ^5.0.0, flutter_colorpicker ^1.1.0, palette_generator ^0.3.3+6, transparent_image ^2.0.1 (unused)
- Firebase: firebase_core ^3.10.0, firebase_messaging ^15.2.0, firebase_analytics ^11.4.0 (unused), flutter_local_notifications ^18.0.1
- Maps/location: google_maps_flutter ^2.10.0, geolocator ^13.0.2, permission_handler ^11.3.1
- Media: image_picker ^1.1.2, cached_network_image ^3.4.1
- Auth/OTP: sms_autofill ^2.4.1, pin_code_fields ^8.0.1, pin_code_text_field ^1.8.0 (unused)
- Logging: talker_flutter ^4.6.0, talker_dio_logger ^4.6.0
- Dev: flutter_test, flutter_lints ^4.0.0
- Config: flutter_launcher_icons.yaml present (package not in pubspec), flutter_native_splash config in pubspec, fonts Poppins + Cairo (Cairo w100 maps to ExtraLight file).

## 7. Quality notes

- Null safety: yes (Dart 3.6). Heavy use of `!` on nullable state fields (`state.quantity!`, `productSizes![0]`).
- Lints: `analysis_options.yaml` only includes `package:flutter_lints/flutter.yaml`; `constant_identifier_names` is violated everywhere (SCREAMING_CASE constants) without being disabled.
- Tests: none.
- Coupling: the barrel system (`lib/core/exports/core_exports.dart` → screens_export, bloc_exports, models_entities_exports...) makes `core` import every feature; a template must cut this.
- Duplication: two select-location screens (core + cart), two exception hierarchies (Failure vs AppException), three base state managers (BaseCubit, BaseSingleClassStateBloc, BaseSingleClassStateCubit), `CairoTextStyles` declared twice (styles/cairo_text_styles.dart and styles/text_styles.dart), the whole app duplicated in hi-gold-seller.
- Deprecated APIs: ColorScheme `background`/`onBackground` (light_color_scheme.dart), `DialogTheme` const for ThemeData.dialogTheme, `withOpacity` x3, connectivity_plus v5-style API use. No WillPopScope/textScaleFactor/MaterialStateProperty.
- Bugs worth not copying: connectivity check, AppState.fromMap cast, `isNullOrEmpty` logic, `isNumeric` regex, `updateLocale` ordering, swapped permission buttons, singleton blocs, `savePinCode` returning a Future inside Right.
- Hardcoded strings/colors: ~20 literal `Text('...')`, English fallbacks in widgets, `MerchantStatus.description` English, 101 raw `Colors.*`, mock data lists in cubits/blocs.
- Secrets: Google Maps API key hardcoded in `lib/core/services/google_maps_services.dart` and `lib/features/more/stock/presentation/pages/stock_details_screen.dart` (also in AndroidManifest.xml and ios/Runner/AppDelegate.swift); `lib/firebase_options.dart` exists (not opened).
