# hi-gold-seller

Sibling of `hi-gold-customer` (same marketplace, seller/merchant side). The customer app was forked
from this one and its `core/` was then refactored further, so for most shared infrastructure the
customer copy is the newer and better one. This report catalogs the seller app fully but refers to
`docs/_analysis/hi-gold-customer.md` for descriptions of files that are identical or near-identical.

## Summary for comparison

```
PROJECT: hi-gold-seller | path: Cleverness/hi-gold-seller | stack: Flutter, Dart sdk ^3.5.4 | last commit: 2025-03-22 | source files: 354
ARCH: clean-arch-lite, feature-first — features/<f>/{data/{data_sources/remote,Models|models,repositories}, presentation/{blocs,screens|pages,widgets}}; core/base_architecture adds domain/{repositories/BaseRepository, use_cases/BaseUseCase} (one use case only); shared screens/widgets in features/shared
STATE: flutter_bloc (Bloc + Cubit) — BaseSingleClassStateBloc.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart, byte-identical to customer) + BaseSingleClassState extends BaseState; BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart); BaseSingleClassStateCubit (misspelt file base_single_class_state_cubi.dart); AppCubit plain Cubit (not hydrated)
DI: get_it (manual, all lazy singletons incl. blocs) — lib/core/services/di_container.dart
ROUTING: go_router 14 — lib/core/app_router/app_router.dart + app_routes_names.dart — guards: no | deep links: no | ~36 routes, args via state.extra | TalkerRouteObserver
NETWORK: dio — interceptors: TalkerDioLogger only | token refresh: n | retry: n | error mapping: same as customer minus 422 (no UnprocessableFailure) — status 400/401/403/404/else → Failure, Dio timeout/network → Failure, field errors → ErrorDetail | files: lib/core/services/api_service.dart (identical to customer), lib/core/base_architecture/data/data_sources/remote/base_remote_data_source.dart, multipart FormData uploads in lib/features/products/data/data_sources/remote/products_remote_data_source.dart
RESULT_TYPE: Either (dartz) — lib/core/utilities/failures/failure.dart (no UnprocessableFailure) + error_details_model.dart; BaseRepository in lib/core/base_architecture/domain/repositories/base_repo.dart
STORAGE: shared_preferences (token in plain prefs) — lib/core/services/shared_preferences_manager.dart (identical to customer); hydrated_bloc declared but unused
L10N: easy_localization — en, ar; default/start/fallback ar; assets/translations/{en,ar}.json (24 groups, 275 keys) + 255 hand-written typed getters in lib/core/extensions/context_extensions.dart (unused) — hardcoded UI strings: some (~26 literal Text())
RTL: Directional=28 vs LeftRight=32
THEME: lib/core/theme/light_theme/light_theme.dart (+ light_widget_themes/*, same as customer) — dark mode n | component themes in ThemeData (appBar/buttons/inputs) y | colors class AppColors in lib/core/utilities/constants/colors.dart (withOpacity) | text styles class TextThemeLight + PoppinsTextStyles/CairoTextStyles | fonts Poppins (en) + Cairo (ar)
RESPONSIVE: flutter_screenutil (design size 376x812, minTextAdapt, splitScreenMode) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants (ApiKeys.BASE_URL in lib/core/utilities/constants/keys/api_keys.dart); no flavors
LOGGING: talker (TalkerDioLogger, TalkerRouteObserver) + debugPrint (AppBlocObserver) + print (11) + dart:developer log (39)
ANALYTICS/CRASH: none in code (firebase_analytics declared, unused)
PUSH: fcm + flutter_local_notifications — lib/features/home/data/datasources/local/local_notification_service.dart (initialized in main), lib/features/home/data/datasources/remote_datasource/firebase/notification_from_firebase.dart (never wired)
PAYMENTS/IAP: none
PERMISSIONS: permission_handler + geolocator — lib/core/services/permission_helper.dart (location only, identical to customer)
DEEP_LINKS: none
MEDIA/FILES: image_picker, cached_network_image, flutter_svg, google_maps_flutter + Dio geocoding, Dio MultipartFile/FormData uploads, carousel_slider, skeletonizer, shimmer, sms_autofill, pin_code_fields, flutter_colorpicker
TESTS: 0 — no test/ folder
LINTS: flutter_lints ^4.0.0 (include only, 0 extra rules)
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart — Bloc base with handleRequest — quality 4 — coupling: low (byte-identical to customer)
- lib/core/base_architecture/data/data_sources/remote/base_remote_data_source.dart — base remote DS + error mapping — quality 3 — coupling: low (customer version better: adds 422)
- lib/core/utilities/widgets/base_fetching_data_widget.dart — status-driven builder with Skeletonizer fake-model loading — quality 4 — coupling: low (same as customer, better generic name SuccessType)
- lib/core/utilities/failures/failure.dart — Failure hierarchy with localized defaults — quality 3 — coupling: low (no 422 class; app-specific NotCompletedRegistrationFailure)
- lib/core/services/api_service.dart — Dio wrapper with token/locale headers — quality 3 — coupling: low (identical to customer modulo imports)
- lib/core/base_architecture/domain/use_cases/base_use_case.dart — BaseUseCase<Type, Params> + NoParams — quality 3 — coupling: none (seller-only)
- lib/core/app_cubit/app_cubit.dart — connectivity listener handling connectivity_plus 6 List results correctly — quality 3 — coupling: none (seller-only correct version; customer's is buggy)
- lib/core/services/app_validator.dart — validators incl. IBAN mod-97 — quality 4 — coupling: none (customer adds PIN validators)
- lib/core/services/bloc_observer.dart — diff-logging BlocObserver — quality 3 — coupling: none (identical to customer)
- lib/core/base_architecture/data/models/base_success_model.dart — factory registry + BaseSuccessModelWithData — quality 3 — coupling: none (identical modulo comments)
- lib/core/services/shared_preferences_manager.dart — prefs singleton — quality 3 — coupling: none (identical)
- lib/core/services/debounce.dart — debouncer — quality 4 — coupling: none (identical)
- lib/features/products/data/data_sources/remote/products_remote_data_source.dart — example of multipart FormData upload (images[] + nested maps) through handleRequest — quality 3 — coupling: high (feature code, pattern only)
- lib/core/theme/light_theme/light_widget_themes/text_theme.dart — M3 TextTheme with .sp — quality 3 — coupling: low (byte-identical)
- lib/core/extensions/context_extensions.dart — typed l10n getters on BuildContext (context.confirm etc.) — quality 2 — coupling: low (hand-maintained, 1 of 255 used)
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — base text field — same as customer minus titleStyle — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password toggle — identical to customer — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/search_text_form_field.dart — debounced search — identical — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/drop_down_text_form_field.dart — inline dropdown field — older (no didUpdateWidget sync) — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/multi_selection_text_form_field.dart — multi-select — byte-identical — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart — phone + country code — byte-identical — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/number_text_form_field.dart — number — byte-identical — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/pick_date_text_form_field.dart — date picker field — byte-identical — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/pick_image_text_form_field.dart — image picker field — byte-identical — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/color_text_form_field.dart — color picker field — byte-identical — quality 2 — generic? n
- lib/core/utilities/widgets/buttons/app_primary_button.dart — AppDefaultButton (loading, fixed arrow icon, no icon param) — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_secondary_button.dart — secondary button — identical — quality 2 — generic? y
- lib/core/utilities/widgets/buttons/app_text_button.dart — pill text button — identical — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_third_button.dart — pill title+icon (title & icon required, no btnColor/radius) — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart — circle svg button (no AppBackButton) — quality 3 — generic? y
- lib/core/utilities/widgets/app_appbar.dart — CustomAppBarWidget + AppBarModel (no title-centering spacer) — quality 3 — generic? y
- lib/features/shared/screens/app_default_screen.dart — base scaffold (RefreshIndicator wraps whole Scaffold, no backgroundColor) — quality 3 — generic? y
- lib/core/utilities/widgets/base_fetching_data_widget.dart — BaseFetchingDataWidget + BaseFetchingErrorWidget — quality 4 — generic? y
- lib/core/utilities/widgets/base_list_view_widget.dart — BaseListViewWidget only (no padding/physics, no sliver variant) — quality 3 — generic? y
- lib/features/shared/widgets/no_elements_widget.dart — empty state — quality 3 — generic? y
- lib/core/utilities/widgets/custom_alert_dialog.dart — image dialog with confirm/cancel (title optional, content required) — quality 3 — generic? y
- lib/core/utilities/widgets/dashed_border_container.dart — dashed border painter — byte-identical — quality 4 — generic? y
- lib/core/utilities/widgets/drop_down_list_widget.dart — selection list — byte-identical — quality 3 — generic? y
- lib/core/utilities/widgets/multi_selection_list_widget.dart — checkbox list — byte-identical — quality 3 — generic? y
- lib/features/shared/widgets/rounded_colored_container.dart — rounded box — quality 3 — generic? y
- lib/features/shared/widgets/cached_network_image_widget.dart — network image — quality 3 — generic? y
- lib/features/shared/widgets/image_viewer_widget.dart — asset/file/network tile + delete (stateless, no precache/onTap/shape/fit) — quality 3 — generic? y
- lib/features/shared/widgets/image_horizontal_list_view.dart — thumbnails strip — quality 3 — generic? y
- lib/features/shared/screens/image_viewer_screen.dart — fullscreen viewer — quality 3 — generic? y
- lib/core/utilities/widgets/image_picker_widget.dart — image picker box — identical to customer images/ version — quality 3 — generic? y
- lib/core/utilities/widgets/image_picker_bottom_sheet.dart — showImagePickerSheet — quality 3 — generic? y
- lib/features/shared/screens/otp_code_screen.dart — OTP screen (sms_autofill + pin_code_fields) — quality 3 — generic? n
- lib/features/shared/screens/select_location_screen.dart — map picker + reverse geocode — identical — quality 3 — generic? n
NOTABLE_IDEAS: same base trio as customer (BaseSingleClassState + BaseSingleClassStateBloc + BaseFetchingDataWidget with Skeletonizer fake model); BaseUseCase/NoParams (lib/core/base_architecture/domain/use_cases/base_use_case.dart); correct connectivity_plus 6 handling (lib/core/app_cubit/app_cubit.dart); typed l10n getters on BuildContext as an alternative to codegen LocaleKeys (lib/core/extensions/context_extensions.dart — idea only, should be generated); multipart product upload with images[] + grouped SKUs (lib/features/products/data/data_sources/remote/products_remote_data_source.dart); extract_strings.dart root script that scans lib/ for quoted strings to find untranslated text
SMELLS: everything listed for hi-gold-customer applies (core barrels export features, singleton blocs, plain-prefs token, no guards/refresh, unused ResponseHandler, buggy isNullOrEmpty/isNumeric, swapped permission buttons, hardcoded Maps key); plus: `BlocProvider.value(value: AppCubit())` in MainApp.build creates a new unclosed cubit on every rebuild; splash jumps straight to bottomNav (dev shortcut); no 422 mapping; withOpacity x19 (deprecated); 255 unused l10n getters; misspelt base_single_class_state_cubi.dart + empty base_single_class_state_cubit_state.dart; data/Models capitalised folders; lib/draft.dart scratch screen; stray root file named "-files --others --exclude-standard" (accidental git output); shared widgets split between core/utilities/widgets and features/shared; 87 byte-identical + ~89 identical-modulo-imports files copy-pasted with the customer app instead of a shared package
```

## Relationship to hi-gold-customer (identical vs diverged)

Comparison of `lib/` (259 common relative paths). "Normalized" means imports/exports, blank lines,
comments and the package name (`hi_gold_seller` vs `hi_gold_customer`) are ignored.

- **Byte-identical: 87 files.** In `core/`: `base_single_class_state_bloc.dart`, all of `base_enum/` except
  `merchant_status_enum.dart`, `exports/packages_exports.dart`, `extensions/int_extension.dart`,
  `services/{image_picker_service, image_viewer_service, permission_helper, response_handeler}.dart`,
  `theme/dark_theme/dark_theme.dart` (empty), `theme/light_theme/light_widget_themes/{bottom_nav_theme, btn_txt_theme, dialog_theme, text_theme}.dart`,
  `utilities/common_models/id_title_model.dart`, `utilities/constants/keys/shared_preferences_keys.dart`,
  `utilities/converters/price_converter.dart`, `utilities/failures/error_details_model.dart`,
  `utilities/formatters/date_formatter.dart`, `utilities/widgets/{dashed_border_container, drop_down_list_widget, multi_selection_list_widget}.dart`,
  `utilities/widgets/text_form_fields/{color, multi_selection, number, phone, pick_date, pick_image}_text_form_field.dart`.
  Plus 55 feature files (auth models/events/states, privacy cubits, profile data source, products events/states, requests blocs...).
- **Identical after normalization (logic same, imports differ): ~89 more files.** In `core/`:
  `base_success_model.dart`, `network_request_model.dart`, `base_cubit.dart`, `list_extensions.dart`,
  `string_extensions.dart`, `api_service.dart`, `bloc_observer.dart`, `debounce.dart`, `google_maps_services.dart`,
  `shared_preferences_manager.dart`, `light_theme.dart`, `app_bar_theme.dart`, `elevated_btn_theme.dart`,
  `light_color_scheme.dart`, `snack_bar_theme.dart`, the three `styles/*_text_styles.dart`,
  `app_secondary_button.dart`, `app_text_button.dart`, `password_text_form_field.dart`, `search_text_form_field.dart`,
  all `exports/*` barrels (content mirrors each app's own files). Relocated but identical:
  `features/shared/screens/{select_location_screen, image_viewer_screen}.dart`,
  `core/utilities/widgets/image_picker_widget.dart`, `base_single_class_state_cubi.dart` (= customer `base_single_class_state_cubit.dart`),
  `domain/repositories/base_repo.dart` (= customer `data/repositories/base_repo.dart`).
- **Diverged (customer is newer unless noted):** `base_remote_data_source.dart` + `failure.dart` (customer adds 422/UnprocessableFailure),
  `base_state.dart` / `base_single_class_state.dart` (seller: BaseSingleClassState extends BaseState, `List<Object?>` props — slightly cleaner),
  `app_cubit.dart` / `app_state.dart` (seller: plain Cubit, correct connectivity; customer: Hydrated, adds locale/guest, buggy connectivity),
  `app_validator.dart` (customer adds PIN validators), `context_extensions.dart` (seller adds 255 typed l10n getters),
  `input_decoration_theme.dart` (customer adds `customInputDecorationTheme`), `colors.dart` vs `app_colors.dart` (seller `withOpacity`, customer `withValues`),
  `constant_variables.dart` vs `app_constant_variables.dart` (renamed constants), widgets `app_appbar`, `app_primary_button`,
  `app_icon_button` (customer adds AppBackButton), `app_third_button`, `custom_alert_dialog`, `drop_down_text_form_field`,
  `app_text_form_field`, `base_list_view_widget` (customer adds sliver variant), `base_fetching_data_widget` (seller has the better generic name),
  `features/shared/widgets/image_viewer_widget.dart` (customer's version is much richer), `app_default_screen.dart`, `otp_code_screen.dart` (customer shows a loading dialog),
  `di_container.dart`, `register_models.dart`, `app_router.dart`, `app_routes_names.dart`, `api_keys.dart`, asset constants, `main.dart`.
- **Customer-only core:** rating widgets, `texts_in_row_widget.dart`, `BaseSliverListWidget`, `AppBackButton`, `customInputDecorationTheme`, `UnprocessableFailure`.
- **Seller-only core:** `domain/use_cases/base_use_case.dart`, typed l10n getters, `features/shared/` location of shared screens.

Recommendation for the template: take the customer versions of the shared core, but take the seller's
`AppCubit._checkInternet` (List-aware) and `BaseSingleClassState extends BaseState` with `List<Object?>` props,
and the `SuccessType` generic naming from the seller's `base_fetching_data_widget.dart`.

## 1. Architecture pattern

Same as customer (see that report): feature-first, BLoC, `data/` + `presentation/` per feature, no real domain layer.
The seller keeps a `core/base_architecture/domain/` folder holding `BaseRepository` and `BaseUseCase<Type, Params>`;
only `features/requests/domain/usecases/requests_usecase.dart` implements a use case. Repositories are still concrete
classes in `data/repositories` extending `BaseRepository`.

Seller-specific features are form-heavy: add/edit product (multi-image, SKUs per branch, categories), add/edit
branch with map location, documents upload, stolen-gold reports. They use `BaseSingleClassStateBloc` with large
single-class states (one event per field change).

## 2. Folder tree (`lib/`, 4 levels)

```
lib/
├── main.dart              bootstrap (no HydratedStorage); MaterialApp.router inside ScreenUtilInit + Directionality(context.isAr)
├── draft.dart             scratch "Draft" screen
├── firebase_options.dart  (FlutterFire generated; secret file, not opened)
├── core/
│   ├── app_cubit/         AppCubit (plain Cubit, connectivity) + AppState
│   ├── app_router/        go_router config + route names
│   ├── base_architecture/
│   │   ├── data/          data_sources/remote/BaseRemoteDataSource, models/{BaseSuccessModel, NetworkRequestParams, GeoCodingAddressDetails}
│   │   ├── domain/        repositories/BaseRepository, use_cases/BaseUseCase + NoParams
│   │   └── presentation/managers/  base_cubit/, base_single_class_state_bloc/, base_single_class_state_cubit/ (base_single_class_state_cubi.dart + empty state file)
│   ├── base_enum/         FetchDataStatusEnum, FormStatusEnum, HttpMethod, MerchantStatus, ProductPropertyTypeEnum
│   ├── exports/           barrel files (export features too)
│   ├── extensions/        context (isAr, theme, 255 l10n getters), string, list, int
│   ├── services/          ApiService, DI, register_models, prefs, validators, BlocObserver, debounce, permissions, image picker/viewer, geocoding, ResponseHandler (unused)
│   ├── theme/             dark_theme (empty), light_theme + light_widget_themes/
│   └── utilities/
│       ├── common_models/ IdTitleModel
│       ├── constants/     colors.dart (AppColors), constant_lists.dart, constant_variables.dart, assets/, keys/ (ApiKeys, SharedPreferencesKeys), styles/
│       ├── converters/    empty price_converter.dart
│       ├── failures/      Failure hierarchy, ErrorDetail
│       ├── formatters/    DateFormatter
│       └── widgets/       app bar, fetching/list bases, dialog, dashed border, dropdown lists, image picker widget + sheet, buttons/, text_form_fields/
└── features/
    ├── auth/              login, OTP, register stepper (basic info, documents, branch), PIN, follow-up, subscription, blocked
    ├── bottom_nav/        BottomNavScreen
    ├── home/              home tabs (my requests, special, customer views), branch cards, notifications (local/FCM/server data sources)
    ├── more/              branches, contact_and_support, documents, inquires, invoices, more_presentation, my_balance, profile, settings/{language,privacy,settings_presentation,terms_and_conditions}, statistics, stolen_gold
    ├── products/          (expanded below)
    ├── requests/          RequestsBloc, domain/{entities,usecases}
    ├── shared/            screens/{app_default_screen, otp_code_screen, select_location_screen, image_viewer_screen}, widgets/{cached_network_image, image_viewer, image_horizontal_list_view, rounded_colored_container, no_elements}
    └── splash/            splash (goes straight to bottomNav) + onboarding
```

Representative feature, `features/products/`:

```
products/
├── data/
│   ├── Models/request/      add_edit_product_params, branch_grouped_sku_model (groupSkusByBranchId), change_product_status_params
│   ├── Models/response/     product_model, product_details_model, main/sub category models
│   ├── data_sources/local/local.dart (empty)
│   ├── data_sources/remote/products_remote_data_source.dart  handleRequest calls + FormData/MultipartFile builder for add/edit
│   └── repositories/products_repo.dart
├── presentation/
│   ├── blocs/add_edit_product_bloc/  AddEditProductBloc (17 events: per-field changes, SKU add/remove, add/edit/init/clear)
│   ├── blocs/{categories_bloc, product_bloc, products_bloc}/
│   ├── models/title_value_model.dart
│   ├── screens/add_edit_product_screen/ add_edit_product_screen.dart + *_widget_functions_compl.dart (extracted builder functions)
│   ├── screens/{product_details_screen, products_screen}.dart
│   └── widgets/{add_edit_products_widgets (SKU table), product_details_widgets, products_widget/product_card}
└── products_exports/products_screen_exports.dart
```

## 3. Infrastructure

Only differences from hi-gold-customer are described; everything else is as in that report.

- **State management:** same base classes. `BaseSingleClassState extends BaseState` (customer extends Equatable directly). `AppCubit` is a plain `Cubit` with only connectivity and placeholder flags (no locale/guest), constructed in `MainApp.build` as `BlocProvider.value(value: AppCubit())` (new instance per rebuild, never closed). `hydrated_bloc` unused.
- **DI:** `lib/core/services/di_container.dart`, 44 lazy singletons (data sources, repos, blocs: AddEditProductBloc, AddEditBranchBloc, BranchesBloc, StolenGoldBloc, DocumentsCubit, Home*ViewBloc, ...). AppCubit not registered.
- **Routing:** `lib/core/app_router/app_router.dart`, ~36 routes, same patterns (MultiBlocProvider with singleton blocs, `state.extra` casts, TalkerRouteObserver). No redirect/guards. Splash `Future.delayed` → `bottomNav` directly (onboarding/login path commented out).
- **Networking:** `api_service.dart` identical. `base_remote_data_source.dart` lacks the 422 case (falls into ServerFailure) and keeps a commented-out older `genericHandleRequest`. Multipart uploads build `FormData.fromMap` with `MultipartFile.fromFile` lists (`images[]`) and nested maps; the ApiService default `Content-Type: application/json` header is still set globally.
- **Local storage:** identical prefs wrapper and keys; no hydrated storage.
- **Localization:** easy_localization, en/ar, start+fallback `ar`, 275 keys (24 groups). `pubspec` has no `generate: true`. `context_extensions.dart` adds a `LocalizationExtensions` on BuildContext with 255 getters (`context.confirm`, `context.pleaseSelectImage(title)`...) mapping to keys — only one is referenced, so strings are still called with `'key'.tr()` (291 call sites). Directionality from `context.isAr` (single source of truth, unlike customer). Root script `extract_strings.dart` prints every double-quoted string in lib/ to help find untranslated text.
- **RTL:** 28 directional vs 32 left/right.
- **Theming:** same files; `AppColors` lives in `lib/core/utilities/constants/colors.dart` and uses deprecated `withOpacity`; input theme has an unused focus color and no `customInputDecorationTheme`. No dark mode.
- **Responsive / text scaling / env / logging / analytics / push / permissions / deep links / payments:** same as customer (screenutil 376x812; no clamp; hardcoded `ApiKeys.BASE_URL` = `{{BASE_URL}}`; talker + print/log; no analytics; FCM code present but unwired, local notifications initialized; location permission helper; no deep links; no payments). `main.dart` keeps an un-called `getDeviceToken()` that logs the FCM token.
- **Android/iOS:** `android/app/google-services.json` exists (not opened), `firebase.json` exists (FlutterFire config, not opened), Groovy `build.gradle` with no flavors and debug signing for release; launcher icons via `flutter_launcher_icons` dev dependency.

## 4. Services catalog

All files under `lib/core/services/`, `lib/core/base_architecture/`, `lib/core/utilities/` and `lib/core/extensions/`
have the same purpose and public API as the customer table in `hi-gold-customer.md`, with these differences:

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/base_architecture/domain/use_cases/base_use_case.dart | Use case contract | `BaseUseCase<Type, Params>.call(params)`, `NoParams` | dartz, equatable | generic (seller-only) |
| lib/core/base_architecture/domain/repositories/base_repo.dart | Either wrapper (moved to domain/) | `handleNetworkCall<T>({call})` | dartz | generic |
| lib/core/base_architecture/data/data_sources/remote/base_remote_data_source.dart | Base remote DS | `handleRequest<T>`, `genericHandleRequest<T>` (no 422) | ApiService via serviceLocator | generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_cubit/base_single_class_state_cubi.dart | Cubit base (misspelt filename) | `handleCubitFetchingEmits` | bloc, dartz | generic |
| lib/core/app_cubit/app_cubit.dart | Connectivity state | constructor listener only | connectivity_plus | generic |
| lib/core/services/app_validator.dart | Validators (no PIN validators) | `isNotEmpty`, `isValidEmail`, `isValidPhone`, `isValidPassword`, `confirmPassword`, `isNumeric`, `isNotEmptyImage`, `ibanValidator`, `customValidator` | easy_localization | generic |
| lib/core/extensions/context_extensions.dart | `isAr`, `theme`, 255 typed l10n getters | getters/methods | easy_localization | generic idea, app-specific keys |
| lib/core/utilities/failures/failure.dart | Failure hierarchy (no Unprocessable) | as customer | easy_localization, MerchantStatus | generic + app tail |
| lib/core/utilities/constants/colors.dart | AppColors (withOpacity) | static colors | flutter | app values |
| lib/core/utilities/constants/constant_variables.dart | translationPath, font family names | constants | — | generic |
| lib/core/utilities/constants/constant_lists.dart | Static app lists | `ConstantLists.*` | features | app-specific |
| lib/core/services/di_container.dart | get_it registrations | `serviceLocator`, `diContainerSetup()` | all features | app-specific |
| lib/core/services/register_models.dart | Model factories (Product, Branch, City, Documents, Invoice, Profile, StolenGold) | `registerModels()` | features | app-specific |
| lib/features/products/data/Models/request/branch_grouped_sku_model.dart | Group SKUs by branch for API payload | `groupSkusByBranchId(skus)` | — | app-specific |

Identical services (see customer report): api_service, shared_preferences_manager, bloc_observer, debounce,
google_maps_services (hardcoded key), image_picker_service, image_viewer_service, permission_helper,
response_handeler (unused), date_formatter, id_title_model, error_details_model, string/list/int extensions,
all theme files except input_decoration_theme, text style classes, `AppIcons.svg` / `AppImages.image` helpers.
`lib/features/home/data/datasources/local/local_notification_service.dart` and `.../firebase/notification_from_firebase.dart` match the customer's.

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/app_appbar.dart | In-body app bar + AppBarModel | appBarModel{title, titleSvgPath, titleSvgColor, suffixSvgPath, suffixSvgColor, onTapBack, onTapSuffix} | y |
| lib/features/shared/screens/app_default_screen.dart | Base scaffold | appBarModel, body, bottomSheet, onRefresh, appBarPadding, bodyPadding | y |
| lib/core/utilities/widgets/base_fetching_data_widget.dart | Status-driven builder + error widget | child, loadingModel, loadingWidget, errorWidget, retryCallback | y |
| lib/core/utilities/widgets/base_list_view_widget.dart | List with empty state | models, childCard, noElementsImage/Title/Description | y |
| lib/features/shared/widgets/no_elements_widget.dart | Empty state | imageName, title, description, sizes, padding | y |
| lib/core/utilities/widgets/custom_alert_dialog.dart | Image dialog with confirm/cancel | imageName, imageHeight, imageWidth, title?, titleColor, content, hasActions, onTapConfirm | y |
| lib/core/utilities/widgets/dashed_border_container.dart | Dashed border | child, height, width, padding, dashWidth, dashSpace, borderColor, borderRadius | y |
| lib/features/shared/widgets/rounded_colored_container.dart | Rounded box | child, padding, margin, backgroundColor, radius, height, width | y |
| lib/core/utilities/widgets/drop_down_list_widget.dart | Selection list | selectionsList, onTapItem, bottomMargin | y |
| lib/core/utilities/widgets/multi_selection_list_widget.dart | Checkbox list | selectionsList, selectedIds, onTapItem | y |
| lib/core/utilities/widgets/image_picker_widget.dart | Image picker box | label, imagePath, size, backgroundColor, placeholderSvgPath, borderRadius, imageSource, bottomMargin | y |
| lib/core/utilities/widgets/image_picker_bottom_sheet.dart | Camera/gallery sheet | context, onFilePicked, imageSource | y |
| lib/features/shared/widgets/cached_network_image_widget.dart | Network image | imageUrl, fit | y |
| lib/features/shared/widgets/image_viewer_widget.dart | Asset/file/network tile + delete | image, imageWidth, imageHeight, radius, margin, isDeleteEnabled, onTapDelete | y |
| lib/features/shared/widgets/image_horizontal_list_view.dart | Thumbnails | images, selectedIndex | y |
| lib/features/shared/screens/image_viewer_screen.dart | Fullscreen viewer | imagePath | y |
| lib/features/shared/screens/otp_code_screen.dart | OTP screen | OtpScreenParams | n |
| lib/features/shared/screens/select_location_screen.dart | Map picker | — | n |
| lib/core/utilities/widgets/buttons/app_primary_button.dart | AppDefaultButton | content, onTap, isLoading, buttonStyle, textColor | y |
| lib/core/utilities/widgets/buttons/app_secondary_button.dart | Secondary | content, onTap | y |
| lib/core/utilities/widgets/buttons/app_text_button.dart | Pill text button | text, onTap, textStyle, width, height, padding, margin, backgroundColor, hasBorder, hasNoColor | y |
| lib/core/utilities/widgets/buttons/app_third_button.dart | Pill title+icon | title, svgIconPath, onTap, titleStyle, width, height, horizontalPadding, iconSize, iconColor, bottomMargin, isOutlineBorder | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart | Circle svg button | svgIconPath, onTap, iconSize, radius, color, margin, padding, isLoading | y |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart | Base field | as customer minus titleStyle | y |
| lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart | Password | controller, isConfirmPassword, confirmPasswordValidator, title, hintText, isLogin | y |
| lib/core/utilities/widgets/text_form_fields/search_text_form_field.dart | Debounced search | onChanged, onTapSuffix, bottomMargin | y |
| lib/core/utilities/widgets/text_form_fields/drop_down_text_form_field.dart | Inline dropdown | title, fetchStatus, dropDownList, initialValue, hintText, onTap, onTapItem | y |
| lib/core/utilities/widgets/text_form_fields/multi_selection_text_form_field.dart | Multi-select | title, controller, fetchStatus, dropDownList, selectedIds, hintText, onTap | y |
| lib/core/utilities/widgets/text_form_fields/phone_text_form_field.dart | Phone | controller, countryCode, title, initialValue, hintText, readOnly, onTap, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/number_text_form_field.dart | Number | controller, title, initialValue, hintText, suffixText, onTap, onChanged, readOnly, isInt | y |
| lib/core/utilities/widgets/text_form_fields/pick_date_text_form_field.dart | Date | controller, title, initialValue, hintText, onTap | y |
| lib/core/utilities/widgets/text_form_fields/pick_image_text_form_field.dart | Image field | controller, title, hintText, imageSource, onImageSelected, onTap | y |
| lib/core/utilities/widgets/text_form_fields/color_text_form_field.dart | Color picker | colorNameController, colorHexController | n |
| lib/features/products/presentation/widgets/add_edit_products_widgets/product_skus_widget.dart | SKU table editor | app-specific | n |

No rating widgets, no sliver list, no back-button widget, no snackbar/toast helper, no pagination.

## 6. Packages (pubspec.yaml)

Same as hi-gold-customer except: Dart sdk `^3.5.4`; no `transparent_image`, no `palette_generator`;
`flutter_launcher_icons ^0.14.3` in dev_dependencies; no `flutter: generate: true`.

- State: flutter_bloc ^8.1.6, hydrated_bloc ^9.1.5 (unused), equatable ^2.0.7
- DI: get_it ^8.0.3 | Routing: go_router ^14.6.2 | Network: dio ^5.7.0, connectivity_plus ^6.1.3 | FP: dartz ^0.10.1
- Storage: shared_preferences ^2.3.3, path_provider ^2.1.5
- L10n: easy_localization ^3.0.7, intl ^0.19.0
- UI: flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, gap ^3.0.1 (unused), flutter_native_splash ^2.4.3, flutter_animate ^4.5.2 (unused), animate_do ^3.3.4, skeletonizer ^1.4.2, shimmer ^3.0.0, carousel_slider ^5.0.0, flutter_colorpicker ^1.1.0
- Firebase: firebase_core ^3.10.0, firebase_messaging ^15.2.0, firebase_analytics ^11.4.0 (unused), flutter_local_notifications ^18.0.1
- Maps/location: google_maps_flutter ^2.10.0, geolocator ^13.0.2, permission_handler ^11.3.1
- Media: image_picker ^1.1.2, cached_network_image ^3.4.1
- OTP: sms_autofill ^2.4.1, pin_code_fields ^8.0.1, pin_code_text_field ^1.8.0 (unused)
- Logging: talker_flutter ^4.6.0, talker_dio_logger ^4.6.0
- Dev: flutter_test, flutter_lints ^4.0.0, flutter_launcher_icons ^0.14.3

## 7. Quality notes

- Null safety yes; lints = plain `flutter_lints` include; no tests.
- Older copy of the shared core: deprecated `withOpacity` (19), ColorScheme `background`/`onBackground`, `DialogTheme`.
- Same structural smells as customer: core barrels export features, singleton blocs from get_it provided via `BlocProvider.value`, token in plain prefs, no auth guard / refresh / retry, unused `ResponseHandler`, buggy `isNullOrEmpty` and `isNumeric`.
- Seller-specific: AppCubit instantiated in `build`, splash dev shortcut to bottomNav, 255 dead l10n getters, misspelt/empty base files, `Models` vs `models` folder casing, shared widgets split between `core/utilities/widgets` and `features/shared`, scratch `lib/draft.dart`, stray root file `-files --others --exclude-standard`.
- Hardcoded: ~26 literal `Text()` strings, 70 raw `Colors.*`, 31 `Color(0x..)`.
- Secrets: Google Maps API key hardcoded in `lib/core/services/google_maps_services.dart` and `lib/features/more/branches/presentation/pages/branch_details_screen.dart` (also AndroidManifest.xml, ios/Runner/AppDelegate.swift). `lib/firebase_options.dart`, `android/app/google-services.json` and `firebase.json` exist (not opened).
- Duplication across apps: ~176 of 259 common files are identical or identical-modulo-imports; the two apps should share a package (or the template) instead of copy-paste.
