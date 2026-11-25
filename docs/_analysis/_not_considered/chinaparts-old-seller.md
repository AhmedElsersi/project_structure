# chinaparts-old-seller — Phase 1 analysis

> Legacy (2025) seller/vendor app, rewritten later in `Chinaparts/New Projects/seller`. It is a hybrid:
> 1. **Live app:** a customised copy of the 6valley seller app. Provider + GetIt + `DioClient`/`ApiResponse`,
>    with `lib/data`, `lib/provider`, `lib/features/screens`, `lib/features/base`, `lib/utils`.
> 2. **Dormant clean-architecture scaffold:** `lib/core` (79 files) and `lib/core_features` (70 files, 45 of them
>    stubs under 400 bytes). Cubit/Bloc base classes, `Either<Failure,T>`, `ApiService`, talker, screenutil,
>    easy_localization, secure storage, go_router. It is **never bootstrapped**: `diContainerSetup()` is never
>    called, and there is no BlocProvider, ScreenUtilInit, EasyLocalization or MaterialApp.router. The live app
>    uses only its constants (images, icons, language list, pref keys) and `config_model.dart`.
>
> For the template, the dormant `lib/core` layer is the interesting part. It looks like an early cut of the
> user's own starter. Features are covered briefly.

## Summary for comparison

```
PROJECT: chinaparts-old-seller | path: Chinaparts/Old Projects/Chinaparts Seller | stack: Flutter, Dart SDK ^3.5.1; .fvmrc pins Flutter 3.19.0 (stale: core code uses Column.spacing / Color.withValues → needs ≥3.27) | last commit: 2025-06-23 (86 commits since 2024-08-28) + uncommitted build artefacts | source files: 391 (+ root copy_feature.dart)
ARCH: hybrid — LIVE: layer-first 6valley MVC (lib/data repos → ApiResponse → lib/provider ChangeNotifiers → lib/features/screens/<feature>); DORMANT: clean-arch feature-first lib/core_features/<f>/{data/{data_sources,models,repositories},presentation/{managers,screens,widgets}} on lib/core/base_architecture (mostly empty stubs, never wired)
STATE: LIVE provider ChangeNotifier (27 in MultiProvider, lib/main.dart, no base class); DORMANT flutter_bloc — BaseCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart), BaseBloc.handleRequest + BaseSingleClassState{status,failure,success} (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/), AppCubit (lib/core/app_cubit/)
DI: get_it — LIVE lib/di_container.dart (`sl`); DORMANT lib/core/services/di_container.dart (`diService`, diContainerSetup() never called)
ROUTING: Navigator 1.0 imperative MaterialPageRoute (128 Navigator.* calls), MyApp.navigatorKey — lib/main.dart — guards: no — deep links: no; DORMANT empty GoRouter + TalkerRouteObserver (lib/core/app_router/app_router.dart, app_routes_names.dart)
NETWORK: dio 5 (+http in 6 files) — LIVE: DioClient lib/data/datasource/remote/dio/dio_client.dart + LoggingInterceptor (print) + ApiErrorHandler + ApiChecker (401 detected by string compare → clear prefs + push AuthScreen); DORMANT: ApiService/ApiServiceBase (lib/core/services/api_service.dart) + TalkerDioLogger(printRequestHeaders), BaseRemoteDataSource.handleRequest status→Failure mapping | token refresh: n | retry: n | error mapping: live = message strings / ErrorResponse; dormant = typed Failures (400/401/403/404/5xx/timeout/network)
RESULT_TYPE: LIVE ApiResponse(response, dynamic error) (lib/data/model/response/base/api_response.dart); DORMANT Either<Failure,T> (dartz) via BaseRepository.handleNetworkCall — lib/core/utilities/failures/failure.dart + error_details_model.dart
STORAGE: LIVE shared_preferences raw in repos (token, plaintext password+phone) + static SharedPrefsManager (lib/data/datasource/local/shared_preferences.dart, init not awaited); DORMANT SharedPreferencesManager singleton + SecureStorageManager (lib/core/services/)
L10N: custom JSON-asset delegate + getTranslated (null→key) — en, ar (866/862 keys), default en (ConstantLists.languagesList[0]), assets/language/*.json — lib/localization/ — hardcoded UI strings: few (35 literal Text); DORMANT easy_localization `.tr()` with 'validation.*'/'auth.*' keys missing from the JSON
RTL: Directional=20 vs LeftRight=37 (AppBackButton flips arrow via context.isAr; isLtr ×5)
THEME: LIVE lib/theme/light_theme/light_theme.dart (Cairo, orange primary) + lib/theme/dark_theme/dark_theme.dart — dark mode n in practice (ThemeProvider has no UI toggle) | component themes: LIVE partial (textButton, navigationBar); DORMANT full M3 set in lib/core/theme/light_theme/ (appBar, elevated/text button, input, snackbar, dialog, bottomNav, progress) | colors class: LIVE ColorResources (lib/utils/color_resources.dart); DORMANT AppColors tonal scales 50–1000 (lib/core/utilities/constants/colors.dart) | text styles: LIVE lib/utils/font_styles.dart + lib/utils/styles.dart (Ubuntu); DORMANT TextThemeLight ('Alexandria', not bundled) | fonts: Cairo, Ubuntu
RESPONSIVE: LIVE none (lib/utils/dimensions.dart constants); DORMANT flutter_screenutil .w/.h/.r/.sp in core widgets/themes but no ScreenUtilInit (no design size) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants — lib/utils/app_constants.dart (baseUrl + commented alternate) and DORMANT lib/core/utilities/constants/keys/api_keys.dart (BASE_URL, BASE_IMAGE_URL); no flavors/dotenv
LOGGING: print (92) + debugPrint (10) + `logging` Logger with ANSI colours (lib/utils/myLogger.dart); DORMANT talker (global `talker` in lib/core/services/di_container.dart) + AppBlocObserver (print)
ANALYTICS/CRASH: none
PUSH: none (no firebase packages; backend FCM-token endpoint unused)
PAYMENTS/IAP: none (wallet/withdraw via backend only)
PERMISSIONS: permission_handler + geolocator — lib/helper/permissions_helper.dart (location permission with open-settings dialogs)
DEEP_LINKS: none
MEDIA/FILES: image_picker (13 files), cached_network_image, flutter_svg, google_maps_flutter + geolocator + Google Geocoding REST via raw Dio (lib/helper/location_helper.dart, key hardcoded), flutter_colorpicker, DioClient.downloadImage (path_provider), url_launcher, skeletonizer loading lists
TESTS: 1 — default counter smoke test (stale)
LINTS: flutter_lints ^4.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/utilities/failures/failure.dart (+ error_details_model.dart) — sealed-ish Failure hierarchy implements Exception, with code + per-field ErrorDetail list — quality 4 — coupling: none
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — handleRequest<T>(path, method, parser, data, query) + status→Failure + field-error parsing — quality 3 — coupling: low (global diService<ApiService>, only connectionTimeout handled, only 200/201 = success)
- lib/core/base_architecture/data/repository/base_repo.dart — handleNetworkCall → Either<Failure,T> — quality 3 — coupling: none (only catches Failure)
- lib/core/services/api_service.dart — ApiServiceBase interface + Dio impl with NetworkRequestParams, updateHeaders(token, customHeaders incl. removal) — quality 3 — coupling: low (TalkerDioLogger always on, logs headers)
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart (+ base_single_class_state.dart, lib/core/enums/fetch_data_status_enum.dart) — BaseBloc.handleRequest over one copyWith state {status, failure, success} — quality 3 — coupling: none
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget<B,S,T> switching on FetchDataStatusEnum + BaseLoadingWidget/BaseErrorWidget(retry) — quality 3 — coupling: low (screenutil, easy_localization)
- lib/core/services/toast_manager.dart + lib/core/utilities/widgets/toasts/animated_custom_toast.dart + lib/core/enums/toast_state_enum.dart — Overlay toast with success/failure/warning + context.showToast() — quality 3 — coupling: none
- lib/core/services/app_validator.dart — validators (email, phone, Saudi phone, password rules, confirm, numeric, IBAN mod-97, customValidator combinator) — quality 3 — coupling: low (easy_localization keys missing; isNumeric regex bug)
- lib/core/services/secure_storage_manager.dart — FlutterSecureStorage write/read/delete/clearAll/containsKey — quality 3 — coupling: none
- lib/core/theme/light_theme/light_theme.dart + light_widget_themes/* — M3 ThemeData with component themes split one-per-file — quality 3 — coupling: low (screenutil at top-level, unbundled font)
- lib/core/utilities/constants/colors.dart — AppColors tonal palettes (primary/secondary/neutral/green/red 50–1000) — quality 3 — coupling: none
- lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart (+ base_state.dart) — BaseCubit.handleRequest(loadingState, call, onSuccess, onError) — quality 2 — coupling: low (unsafe `ErrorState as State` cast, print, talker)
- lib/features/base/paginated_list_view.dart — scroll-end offset paginator (page size 10) — quality 3 — coupling: none
- lib/core/services/shared_preferences_manager.dart — singleton typed setValue/getValue/remove/clear — quality 2 — coupling: none (silently no-ops before init)
- lib/core/services/debounce.dart — Timer debounce run/cancel — quality 3 — coupling: none
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/buttons/app_default_button.dart — primary button with isLoading morph-to-circle (AnimatedContainer) — onTap, text, textStyle, child, height, width, radius, margin, padding, isLoading, backgroundColor, textColor, enabled, svgIconPath, borderColor — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart — AppIconButton + AppBackButton (RTL-aware arrow) — onTap, child, radius, height, width, backgroundColor — quality 3 — generic? y
- lib/core/utilities/widgets/default_screen.dart — base scaffold with title row + back button + paddings — body, appbar, pageTitle, pageTitleWidget, hasAppBar, hasBackButton, hasBottomBorder, hasBottomMargin, onBackPressed, floatingActionButton(+Location), topMargin, appBarPadding, bodyPadding, backgroundColor — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — titled TextFormField, unfocus on tap-outside — title, controller, hintText, onTap, onChanged, enabled, readOnly, obscureText, keyboardType, validator, inputFormatters, prefixIcon, suffixIcon, titleStyle, textStyle, hintTextStyle, maxLength, maxLines, prefix/suffixIconConstraints, focusNode, textAlign, onSaved, onFieldSubmitted, onEditingComplete — quality 4 — generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart — password field + toggle + validator — controller, isConfirmPassword, title, hintText, onChanged (confirmPasswordValidator/isLogin unused) — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart — email field + validator — controller, title, hintText, readOnly, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart — read-only field opening bottom-sheet list — title, hintText, controller, items, validator, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — DynamicDropdownFormField<T> with optional search — controller, options, displayText, title, onOptionSelected, hintText, showSearch — quality 3 — generic? y
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget / BaseLoadingWidget / BaseErrorWidget — successBuilder, loadingWidget, failureWidget, onRetry / message — quality 3 — generic? y
- lib/core/utilities/widgets/base_list_view_widget.dart — BaseListView<T> separated list + empty state — items, itemBuilder, emptyWidget — quality 2 — generic? y (default 'no_tasks' text)
- lib/core/utilities/widgets/container_with_shadow.dart — tappable card container — child, margin, padding, radius, width, height, image, backgroundColor, border, onTap, boxShadow, shadowBlurRadius — quality 3 — generic? y
- lib/core/utilities/widgets/custom_chip.dart — pill label — title, bgColor, borderColor, txtColor, radius, fontSize, padding — quality 3 — generic? y
- lib/core/utilities/widgets/selection_chip_widget.dart — selectable chip — isSelected, title, onTap — quality 2 — generic? y
- lib/core/utilities/widgets/custom_radio_group_widget.dart — CustomRadioGroup<T> + CustomSizeRadio<T> — options, selectedValue, onChanged, prefixText, label — quality 3 — generic? y
- lib/core/utilities/widgets/image_picker_bottom_sheet.dart — showImagePickerSheet camera/gallery (+ lib/core/services/image_picker_service.dart) — context, onFilePicked — quality 3 — generic? y
- lib/core/utilities/widgets/linear_progress_indicator.dart — LinearPercentIndicator — percent, minHeight — quality 2 — generic? y
- lib/core/utilities/widgets/shared/widgets/image_Widget.dart — ImageViewerWidget (asset/file/network by String.imageType) — image, imageWidth, imageHeight, radius, color, margin, stackedWidget, onTap, fit, border — quality 3 — generic? y (Image.network, no caching)
- lib/core/utilities/widgets/shared/screens/image_viewer.dart — full-screen image viewer — imagePath — quality 2 — generic? y (no zoom)
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart / custom_toast.dart — overlay toast — message, state, duration, location — quality 3 — generic? y
- lib/core/services/show_loading_dialog.dart — blocking loading dialog — context, message, barrierDismissible — quality 2 — generic? y
- lib/core/utilities/widgets/shared/screens/select_location_screen.dart — placeholder stub — none — quality 1 — generic? n
- lib/features/base/paginated_list_view.dart — offset paginator wrapper — scrollController, onPaginate, totalSize, offset, itemView, enabledPagination, reverse — quality 3 — generic? y
- lib/features/base/custom_button.dart — primary button — onTap, btnTxt, isColor, btnBorder, backgroundColor, fontSize, fontColor, fontWeight, borderRadius, height, width, horizontalMargin — quality 2 — generic? y
- lib/features/base/textfeild/custom_text_field.dart — multi-mode text field (title, required star, amount/phone/password/description) — ~35 params (title, controller, hintText, textInputType, maxLine, focusNode, nextNode, isPhoneNumber, isAmount, isPassword, requiredField, prefixIconImage, suffixIcon, inputFormatters…) — quality 2 — generic? y
- lib/features/base/textfeild/custom_pass_textfeild.dart — password field — controller, hintTxt, focusNode, nextNode, textInputAction, border, prefixIconImage — quality 2 — generic? y
- lib/features/base/custom_dialog.dart — showAnimatedDialog + Rotation3DTransition — context, dialog, isFlip, dismissible — quality 3 — generic? y
- lib/features/base/custom_snackbar.dart — showCustomSnackBar (snackbar or toast) — message, context, isError, isToaster — quality 2 — generic? y
- lib/features/base/custom_loader.dart — SpinKitCircle in primary box — height — quality 2 — generic? y
- lib/features/base/no_data_screen.dart — empty state (image + translated title) — title, image — quality 3 — generic? y
- lib/features/base/custom_date_picker.dart — date field look-alike — title, text, requiredField, selectDate — quality 2 — generic? y
- lib/features/base/custom_drop_down_item.dart — titled dropdown container — title, widget — quality 2 — generic? y
- lib/features/base/custom_image.dart — FadeInImage with placeholder — image, height, width, fit, placeholder — quality 2 — generic? y
- lib/features/base/image_dialog.dart — image dialog — imageUrl — quality 2 — generic? y
- lib/features/base/custom_app_bar.dart — app bar with cart/filter/switch actions — title, isBackButtonExist, onBackPressed, isAction, filter, isSwitch, switchAction, isCart, … — quality 1 — generic? n (couples 5 providers)
- lib/features/base/custom_expanded_app_bar.dart — curved-header scaffold — title, child, bottomChild, isGuestCheck — quality 2 — generic? n
- lib/features/base/not_loggedin_widget.dart — login CTA — none — quality 2 — generic? n
NOTABLE_IDEAS: copy_feature.dart (repo root) — a `dart run` script that clones a feature folder and renames identifiers (Order→Chat), a crude mason-brick; GenericFetchWidget<Bloc,State,Success> + BaseSingleClassState/FetchDataStatusEnum (lib/core/utilities/widgets/base_fetching_widget.dart); typed Failure hierarchy with field-level ErrorDetail parsed from `{field:[msgs]}` (lib/core/utilities/failures/); ApiServiceBase interface + NetworkRequestParams object (lib/core/services/api_service.dart); overlay ToastManager + `context.showToast` extension (lib/core/services/toast_manager.dart); AppValidator.customValidator combinator + IBAN mod-97 (lib/core/services/app_validator.dart); AppDefaultButton loading morph (lib/core/utilities/widgets/buttons/app_default_button.dart); `String.imageType` asset/local/network switch (lib/core/utilities/widgets/shared/widgets/image_Widget.dart); AppIcons.svg helper with colorFilter + network fallback (lib/core/utilities/constants/icons.dart); one-file-per-component theme split (lib/core/theme/light_theme/light_widget_themes/); AppColors tonal scale; LanguageService.getFlagEmoji (lib/core/services/language_flags_service.dart); setAppLanguageToDeviceLanguage (lib/core/services/get_and_set_device_locale.dart); Skeletonizer loading lists in live screens (e.g. lib/features/screens/coupon/coupons_view.dart)
SMELLS: two parallel architectures, the clean one dormant (diContainerSetup/ScreenUtilInit/EasyLocalization/BlocProvider never set up → core widgets would throw if used; 45 stub files with empty repos/cubits and 'X Screen' placeholder screens); BaseCubit `ErrorState(...) as State` cast → TypeError for sealed feature states; BaseRemoteDataSource ignores receive/send timeouts and reaches ApiService through the global locator; TalkerDioLogger and LoggingInterceptor log Bearer headers; .fvmrc 3.19.0 incompatible with code; Google Maps key hardcoded (lib/helper/location_helper.dart); plaintext password in prefs (lib/data/repository/auth_repo.dart; dormant layer keeps it in secure storage); NetworkInfo.isConnected inverted; ApiChecker matches 401 by message string; SharedPrefsManager.init() not awaited; MyHttpOverrides misspelt `CreateHttpClient` (dead, and meant to accept all certs); AppIcons.email/password paths missing '/'; empty files (lib/core/theme/dark_theme/dark_theme.dart, lib/core/utilities/converters/price_converter.dart); 12-level relative imports ('../../../../../../../../../../../../core/exports/core_exports.dart'); registerUrl prefixes baseUrl onto a Dio path; god files (add_update_product_screen.dart 1288, config_model.dart 842); withOpacity ×47, 293 Color(0x..) literals; copy_feature.dart blind string replace would also hit substrings
```

## 1. Architecture pattern

**Live layer (what the app runs):** 6valley seller-app layering, the same pattern as `chinaparts-old-customer`.
- `lib/data/datasource/remote/dio/dio_client.dart` is the shared Dio wrapper. `lib/data/repository/*_repo.dart`
  (22 repos) return `ApiResponse`.
- `lib/provider/*_provider.dart` (27 ChangeNotifiers) hold state, call repos, parse JSON and call
  `ApiChecker.checkApi(context, …)`.
- `lib/features/screens/<feature>/` holds screens plus `widget/`. `lib/features/base/` holds shared widgets.
- `lib/utils/`, `lib/helper/` and `lib/localization/` are cross-cutting.

**Dormant layer (template scaffold, not bootstrapped):**
```
lib/core/base_architecture/
  data/data_sources/base_remote_data_source.dart   handleRequest<T> → throws Failure
  data/repository/base_repo.dart                    handleNetworkCall → Either<Failure,T>
  data/models/…                                     NetworkRequestParams, BaseSuccessResponse<T>, BaseSuccessModel(WithData)
  presentation/managers/base_cubit/                 BaseCubit + BaseState(LoadingState/ErrorState)
  presentation/managers/base_single_class_state_bloc/  BaseBloc + BaseSingleClassState
lib/core_features/<feature>/
  data/{data_sources, models/{requests,responses}, repositories}
  presentation/{managers/<x>_cubit/{x_cubit.dart, x_state.dart (part, sealed)}, screens, widgets}
```
Only `auth` (login/register data source, repo, LoginCubit) and `splash` (`config_model.dart`) have real code.
`chat`, `coupons`, `offers`, `orders` and `products` are generated shells: an empty `XRemoteDataSource extends
BaseRemoteDataSource {}`, an empty repo, a Cubit with only `XInitial`, and `DefaultScreen(body: Text('X Screen'))`.
They were generated by `copy_feature.dart`.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                 Animate.restartOnHotReload, HttpOverrides (misspelt, inert), native splash,
│                             SharedPrefsManager.init (not awaited), portrait, logger, GetIt init, MultiProvider(27), MaterialApp
├── di_container.dart         LIVE GetIt `sl`: DioClient, 22 repos, 27 providers, prefs, Dio, LoggingInterceptor
├── core/                     DORMANT template layer (79 files)
│   ├── app_cubit/            AppCubit + AppState (network flag, user placeholder)
│   ├── app_router/           empty GoRouter + TalkerRouteObserver, AppRoutesNames
│   ├── base_architecture/    data/{data_sources,models,repository}, presentation/managers/{base_cubit,base_single_class_state_bloc}
│   ├── enums/                AppRoles, FetchDataStatusEnum, HttpMethod, ToastState
│   ├── exports/              core_exports.dart (colors, DefaultScreen, material, go_router, easy_localization, screenutil)
│   ├── extensions/           context_extensions (theme getters + isAr), list_extensions (isNullOrEmpty)
│   ├── models/               selection_model.dart
│   ├── services/             api_service, logging_interceptors, di_container, secure_storage_manager,
│   │                         shared_preferences_manager, toast_manager, show_loading_dialog, bloc_observer,
│   │                         debounce, image_picker_service, app_validator, get_and_set_device_locale,
│   │                         language_flags_service, phone_handeler_service
│   ├── theme/
│   │   ├── light_theme/      light_theme.dart, my_light_themes_export.dart,
│   │   │   └── light_widget_themes/  app_bar, bottom_nav, btn_txt, dialog, elevated_btn, input_decoration,
│   │   │                             light_color_scheme, snack_bar, text_theme
│   │   └── dark_theme/       dark_theme.dart (EMPTY)
│   └── utilities/
│       ├── constants/        colors, constant_lists (languages…), icons (AppIcons + svg()), images, temp_images,
│       │   └── keys/         api_keys.dart (base URLs + endpoints), shared_preferences_keys.dart
│       ├── converters/       price_converter.dart (EMPTY)
│       ├── failures/         failure.dart, error_details_model.dart
│       ├── formatters/       date_formatter.dart
│       └── widgets/          buttons/, text_form_fields/, toasts/, shared/{screens,widgets}/, base_fetching_widget,
│                             base_list_view_widget, container_with_shadow, custom_chip, custom_radio_group_widget,
│                             default_screen, image_picker_bottom_sheet, linear_progress_indicator, selection_chip_widget
├── core_features/            DORMANT clean-arch features (70 files): auth, chat, coupons, offers, orders, products, splash
├── data/                     LIVE
│   ├── datasource/local/     shared_preferences.dart (static SharedPrefsManager)
│   ├── datasource/remote/    dio/{dio_client, logging_interceptor}.dart, exception/api_error_handler.dart
│   ├── model/body/           11 request bodies
│   ├── model/response/       ~60 response models (+ base/api_response, base/error_response)
│   └── repository/           22 repos (+ a misplaced ratting_model.dart)
├── features/
│   ├── base/                 15 shared widgets (+ textfeild/)
│   └── screens/              22 feature folders (see below)
├── helper/                   api_checker, date_converter (25 helpers), location_helper (Google Geocoding), network_info,
│                             permissions_helper, validator (EmailChecker/PhoneChecker)
├── localization/             app_localization.dart, language_constants.dart
├── provider/                 27 ChangeNotifiers
├── theme/                    LIVE light_theme/ (theme, color scheme, text theme, navbar, page transition), dark_theme/
└── utils/                    app_constants (URLs, endpoints, keys), color_resources, dimensions, font_styles,
                              images (1 line), myLogger, styles, extensions/context_ex.dart
```

Live feature folders (file counts): Posts(2) auth(6) chat(9) coupon(3) dashboard(1) forgetPassword(5) home(2)
langulage(2) menu(6) more(1) notifications(1) offer(3) onboarding(1) order(10) product(5) profile(2) review(4)
sales(2) settings(5) splash(2) support(4) wallet(1).

Representative live slice, **coupon**:
```
lib/data/model/response/coupon_model.dart
lib/data/repository/coupon_repo.dart               DioClient get/post/delete → ApiResponse
lib/provider/coupon_provider.dart                  list + client-side search + add/update/delete, ApiChecker on error
lib/features/screens/coupon/coupons_view.dart      Consumer + Skeletonizer placeholder list + inline scroll-end paging (maxScrollExtent listener)
lib/features/screens/coupon/add_update_show_coupon_screen.dart
lib/features/screens/coupon/widget/coupon_card.dart
```
Representative dormant slice, **core_features/auth**: `data/data_sources/auth_remote_data_source.dart` (`handleRequest(path: ApiKeys.LOGIN, method: HttpMethod.post, parser: (r) => r.data['token'])`),
`auth_local_data_source.dart` (token/password in SecureStorage, phone in prefs), `data/repositories/auth_repo.dart`
(`handleNetworkCall`), `data/models/requests/{login,register}_params.dart`,
`presentation/managers/login_cubit/{login_cubit,login_state}.dart` (controllers kept inside the cubit, sealed
states). The `screens/` and `widgets/` folders are empty.

## 3. Infrastructure

### State management
- **Live:** `provider ^6.1.2` ChangeNotifiers, no base class. Pattern: `_isLoading=true; notify; ApiResponse r = await repo.x(); if (r.response?.statusCode == 200) {…} else ApiChecker.checkApi(context, r); notify`. 243 `Provider.of`.
- **Dormant (flutter_bloc ^8.1.6):**
  - `BaseCubit<State extends BaseState>.handleRequest<T>({loadingState, call, onSuccess, onError, showLoading})`
    emits loading, folds the `Either`, and calls `onError` or emits `ErrorState(_mapFailureToMessage) as State`.
    That cast fails for feature-sealed states, so `onError` is effectively mandatory. It uses talker + print.
  - `BaseBloc<Event, State extends BaseSingleClassState>.handleRequest<T>` works on one immutable state with
    `status: FetchDataStatusEnum`, `failure`, `success: BaseSuccessModel`, via `copyWith`, and has override hooks
    `onNotDefaultSuccess/Failure/Loading`. This is the cleaner design and pairs with `GenericFetchWidget`.
  - `AppBlocObserver` (print + emoji) exists but is never set as `Bloc.observer`.

### DI
- Live: `lib/di_container.dart` registers `sl` lazy singletons (repos) and factories (providers), the same as
  the customer app.
- Dormant: `lib/core/services/di_container.dart` defines a `diService` GetIt and a global `final talker = Talker()`,
  with `_initExternalServices/_initDioAndRemoteDataSource/_initRepo/_initBlocs/_initCubits`.
  `diContainerSetup()` is never called. Data sources resolve `diService<ApiService>()` internally (service
  locator inside classes).

### Routing
- Live: `Navigator.push(MaterialPageRoute)` only, plus `MyApp.navigatorKey`. Logout/401 does
  `pushAndRemoveUntil(AuthScreen)`.
- Dormant: `lib/core/app_router/app_router.dart` has `GoRouter(observers: [TalkerRouteObserver(talker)], routes: [])`,
  and `app_routes_names.dart` lists 5 paths. Some dormant code calls `context.pop()` (go_router).
- No guards, no deep links.

### Networking
- **Live client** `lib/data/datasource/remote/dio/dio_client.dart`: 60 s timeouts, `followRedirects=false`,
  `validateStatus < 500`, JSON + Bearer headers set once in the constructor from prefs (the token is printed in
  debug). It has `get/post/put/delete` and `downloadImage(url, fileName)` (path_provider docs dir).
  `LoggingInterceptor` is print-based and logs headers.
- `lib/data/datasource/remote/exception/api_error_handler.dart` is the same 6valley mapper as the customer app
  with null-safe `?.`.
- `lib/helper/api_checker.dart` treats `error == 'Failed to load data - status code: 401'` as unauthorized: it
  clears data and navigates to AuthScreen. Otherwise it shows a snackbar.
- `package:http` is used in 6 files for `MultipartRequest` uploads (registration in auth_repo, profile/shop images
  in profile_repo, bank info, delivery-man). These bypass Dio and its headers.
- `lib/helper/location_helper.dart` (`GoogleMapsService`) calls the Google Geocoding REST API with its own `Dio()`
  and a **hardcoded API key**.
- **Dormant client** `lib/core/services/api_service.dart`:
  - `abstract class ApiServiceBase { get/post/put/delete(NetworkRequestParams); updateHeaders({token, customHeaders}) }`.
  - `ApiService` builds headers from `_defaultHeaders` + token. `updateHeaders` can add, override or remove
    (null value) custom headers. `_executeRequest` maps Socket/Format exceptions.
  - `TalkerDioLogger(printRequestHeaders: true)` is always added, so the token gets logged.
  - The unused `LoggingInterceptor` duplicate lives in `lib/core/services/logging_interceptors.dart`.
- **Dormant error mapping** `BaseRemoteDataSource`: 200/201 → `parser(response)`. 400 → `BadRequestFailure(message, errors: field→messages)`.
  401/403/404/500/other → typed Failures. `DioException` connectionTimeout → `TimeoutFailure`, with a response →
  mapped, else `NetworkFailure`. Non-Failure exceptions → `UnknownFailure`. Receive/send timeouts fall into
  `NetworkFailure`.
- Token refresh: no. Retry: no.

### Local storage
- Live: raw `SharedPreferences` inside repos. `AuthRepo` stores the token, **password (plaintext)** and phone for
  remember-me. `lib/data/datasource/local/shared_preferences.dart` has a static `SharedPrefsManager` with typed
  `save`/`get(key, Type)`. Its `init()` is not awaited in `main.dart`.
- Dormant: `SharedPreferencesManager` (factory singleton, `setValue(dynamic)`/`getValue`, null-safe before init)
  and `SecureStorageManager` (thin `FlutterSecureStorage` wrapper with rethrow).
  `lib/core/utilities/constants/keys/shared_preferences_keys.dart` holds the keys.

### Localization (+RTL)
- Live: the same JSON delegate as the customer app (`lib/localization/app_localization.dart`), but `translate`
  returns `String?` and `getTranslated` falls back to the key (`lib/localization/language_constants.dart`). The
  language list is `ConstantLists.languagesList` in `lib/core/utilities/constants/constant_lists.dart` (en_US
  default, ar_SA). 866 en / 862 ar keys. No fallback Material delegate, so `GlobalMaterialLocalizations` covers
  en/ar.
- Dormant: `easy_localization` `.tr()` in validators, fetch/list widgets, image picker sheet and email/password
  fields, with `validation.*`, `auth.*`, `retry`, `loading_please_wait` keys. Those keys are **not in the JSON**,
  and there is no `EasyLocalization` root. `get_and_set_device_locale.dart` provides device-locale → `context.setLocale`.
- RTL: Directional=20 vs LeftRight=37. Most Directional usage is in core widgets (`EdgeInsetsDirectional`,
  `AlignmentDirectional.bottomEnd`). `AppBackButton` flips the arrow with `context.isAr`. `LocalizationProvider.isLtr`
  is used 5×. Hardcoded strings: few (35 literal `Text`).

### Theming
- Live `lib/theme/light_theme/light_theme.dart` matches the customer app: primary `0xFFfa660a`, Cairo,
  `lightColorScheme`, `lightTextTheme`, textButton, navigationBar, page transitions. `lib/theme/dark_theme/dark_theme.dart`
  is minimal (unbundled 'TitilliumWeb'). `ThemeProvider` exists but nothing toggles it.
  `lib/utils/color_resources.dart` (context + ThemeProvider getters) and `lib/utils/styles.dart` (Ubuntu
  `robotoRegular/Bold/Medium`, `ThemeShadow`) back it up.
- Dormant `lib/core/theme/light_theme/light_theme.dart` (`lightTheme`, `useMaterial3: true`) has
  `ColorScheme.fromSeed(AppColors.primary)`, `appBarTheme`, `bottomNavTheme`, `TextThemeLight.instance.txtTheme`
  (singleton, font 'Alexandria' not bundled, `.sp` evaluated at top level), `btnTheme`, `elevatedBtnTheme`
  (fixed 343×52 size, asymmetric radius), `textBtnTheme`, `snackBarTheme` (floating), `dialogTheme`,
  `inputDecorationTheme` (filled, outline borders for normal/focused/enabled/error, icon colours) and
  `progressIndicatorTheme`. Each component theme is its own file under `light_widget_themes/`, re-exported by
  `my_light_themes_export.dart`. `lib/core/utilities/constants/colors.dart` provides `AppColors` with tonal scales
  primary/secondary/neutral/green/red 50–1000 plus `newColor()`. The dark theme file is empty.

### Responsive helpers
Live: none (`lib/utils/dimensions.dart` constants; 20 MediaQuery uses). Dormant: `flutter_screenutil` `.w/.h/.r/.sp`
in every core widget and theme file, but there is no `ScreenUtilInit` and no design size. No breakpoints.

### Text scaling
None.

### Env / flavors
Hardcoded: `lib/utils/app_constants.dart` (`baseUrl` + one commented alternate, ~100 endpoint paths, pref keys)
and the dormant `lib/core/utilities/constants/keys/api_keys.dart` (`BASE_URL`, `BASE_IMAGE_URL`, seller endpoints,
function-style `PRODUCT_API(id)`). No flavors and no dotenv. `.fvmrc` pins Flutter 3.19.0.

### Logging
`print` (92), `debugPrint` (10, a few behind `kDebugMode`), `lib/utils/myLogger.dart` (`logging` + ANSI colours,
the same as customer). Dormant: talker (`talker.info` in BaseCubit, TalkerDioLogger, TalkerRouteObserver) and
`AppBlocObserver`.

### Analytics / crash reporting
None.

### Push notifications
None. There are no firebase/flutter_local_notifications packages, although `AppConstants` keeps a
`cm-firebase-token` endpoint. Notification settings are only a screen and provider (`notifications_settings_provider.dart`).

### IAP / payments
None (wallet/withdraw screens hit backend endpoints).

### Permissions
`lib/helper/permissions_helper.dart` → `PermissionHelper.checkLocationPermission(context)`: Geolocator request,
then a translated dialog to open location settings (denied) or app settings (deniedForever, via
`permission_handler.openAppSettings`). It is reasonably generic.

### Deep links
None.

## 4. Services catalog

| File | Purpose | Public methods | Dependencies | Generic / app-specific |
|---|---|---|---|---|
| lib/core/services/api_service.dart | Dio service + interface (dormant) | `get/post/put/delete(NetworkRequestParams)`, `updateHeaders({token, customHeaders})` | dio, talker_dio_logger, SharedPreferencesManager | generic |
| lib/core/base_architecture/data/models/base_request_model/network_request_model.dart | request params object | fields uri, data, queryParameters, options, cancelToken, onSend/onReceiveProgress | dio | generic |
| lib/core/base_architecture/data/models/base_response_model/base_success_response.dart | `{status,message,data}` envelope | `fromJson(json, fromJsonT)`, `toJson` | — | generic |
| lib/core/base_architecture/data/models/base_success_model.dart | success marker for BaseBloc | `BaseSuccessModel`, `BaseSuccessModelWithData<T>` | equatable | generic |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | request + Failure mapping | `handleRequest<T>({path, method, parser, data, queryParameters})` | ApiService via diService, Failure | generic |
| lib/core/base_architecture/data/repository/base_repo.dart | Either wrapper | `handleNetworkCall<T>({call})` | dartz | generic |
| lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart | cubit request helper | `handleRequest<T>({loadingState, call, onSuccess, onError, showLoading})` | flutter_bloc, dartz, talker | generic (cast bug) |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart | bloc request helper | `handleRequest<T>({call, onNotDefaultSuccess, onNotDefaultFailure, onNotDefaultLoading})` | flutter_bloc, dartz | generic |
| lib/core/utilities/failures/failure.dart | Failure hierarchy | BadRequest, Unauthorized, Forbidden, NotFound, Server, Network, Timeout, Cache, Validation, Unknown | ErrorDetail | generic |
| lib/core/services/di_container.dart | dormant GetIt setup | `diContainerSetup()`, `diService`, `talker` | get_it, talker | app-specific |
| lib/core/services/secure_storage_manager.dart | secure storage | `write`, `read`, `delete`, `clearAll`, `containsKey` | flutter_secure_storage | generic |
| lib/core/services/shared_preferences_manager.dart | prefs singleton | `init`, `setValue`, `getValue`, `remove`, `clear` | shared_preferences | generic |
| lib/core/services/toast_manager.dart | overlay toast | `ToastManager.showToast(...)`, `context.showToast(...)` | AnimatedCustomToast | generic |
| lib/core/services/show_loading_dialog.dart | loading dialog | `showLoadingDialog({context, message, barrierDismissible})` | — | generic |
| lib/core/services/app_validator.dart | form validators | `isNotEmpty`, `isValidEmail`, `isValidPhone`, `isValidSaudiPhone`, `isValidPassword(v, isLogin)`, `confirmPassword`, `isNumeric`, `isNotEmptyImage`, `ibanValidator`, `customValidator` | easy_localization | generic |
| lib/core/services/debounce.dart | debounce | `run(action)`, `cancel()` | dart:async | generic |
| lib/core/services/image_picker_service.dart | pick image → File | `pickImage({context, source})` | image_picker | generic (English snackbars) |
| lib/core/services/get_and_set_device_locale.dart | device locale → app locale | `setAppLanguageToDeviceLanguage(context)`, `getDeviceLocale()` | easy_localization, dart:io | generic |
| lib/core/services/language_flags_service.dart | locale → flag emoji | `LanguageService.getFlagEmoji(locale)` | — | generic |
| lib/core/services/bloc_observer.dart | bloc logging | AppBlocObserver overrides | flutter_bloc | generic |
| lib/core/services/logging_interceptors.dart | debugPrint interceptor (unused dup) | interceptor overrides | dio | generic |
| lib/core/services/phone_handeler_service.dart | prefix 0 | `ensureStartsWithZero(number)` | — | generic |
| lib/core/utilities/formatters/date_formatter.dart | date format helpers | `formatDateString`, `formatDate(date, fmt, locale)`, `isMorning` | intl | generic |
| lib/core/utilities/constants/icons.dart | asset paths + svg helper | `AppIcons.svg({assetName, width, height, color})` | flutter_svg, ApiKeys | generic-ish |
| lib/core/utilities/constants/colors.dart | palette | constants, `newColor` | — | generic structure |
| lib/core/extensions/context_extensions.dart | theme getters + `isAr` | getters | — | generic |
| lib/core/extensions/list_extensions.dart | `isNullOrEmpty()` | — | — | generic |
| lib/data/datasource/remote/dio/dio_client.dart | live Dio wrapper | `get/post/put/delete`, `downloadImage` | dio, path_provider, prefs | generic-ish |
| lib/data/datasource/remote/exception/api_error_handler.dart | live error → message | `getMessage(error)` | ErrorResponse | 6valley |
| lib/data/datasource/local/shared_preferences.dart | static prefs manager | `init`, `save`, `get(key, Type)`, `removeKey`, `clearAll` | shared_preferences | generic |
| lib/helper/api_checker.dart | live API error reaction | `checkApi(context, apiResponse)` | AuthProvider, AuthScreen | app-specific |
| lib/helper/network_info.dart | connectivity | `isConnected` (inverted), `checkConnectivity(context)` | connectivity_plus, SplashProvider | buggy |
| lib/helper/permissions_helper.dart | location permission flow | `checkLocationPermission(context)` | geolocator, permission_handler | generic |
| lib/helper/location_helper.dart | reverse geocoding | `getAddressFromLatLng(lat, lng)` | dio, Address | app-specific (hardcoded key) |
| lib/helper/date_converter.dart | 25 date helpers | `formatDateString`, `isFirstDateBeforeSecond`, `isDateBeforeToday`, `isoStringToLocal*`, `customTime`… | intl | generic |
| lib/helper/validator.dart | regex checks | `EmailChecker.isNotValid`, `PhoneChecker.isPhoneNotValid` | — | generic |
| lib/localization/app_localization.dart / language_constants.dart | JSON l10n | `translate`, `getTranslated` | rootBundle | generic |
| lib/utils/app_constants.dart | URLs/endpoints/keys | constants | — | app-specific |
| lib/utils/myLogger.dart | logging setup | `myLoggerInit`, `logger` | logging | generic |
| copy_feature.dart (repo root) | feature folder cloner | `main()` (hardcoded source/destination + replacements map) | dart:io | generic idea |

## 5. Widgets catalog

See `GENERIC_WIDGETS` in the summary for parameters and quality. Grouped:

| Group | Path | Generic? |
|---|---|---|
| Buttons | lib/core/utilities/widgets/buttons/app_default_button.dart, app_icon_button.dart (AppIconButton, AppBackButton); lib/features/base/custom_button.dart | y |
| Base scaffold | lib/core/utilities/widgets/default_screen.dart | y |
| Inputs | lib/core/utilities/widgets/text_form_fields/{app_text_form_field, password_text_form_field, email_text_form_field, dropdown_text_form_field, dynamic_drop_down_text_field}.dart; lib/features/base/textfeild/{custom_text_field, custom_pass_textfeild}.dart; lib/features/base/custom_date_picker.dart; lib/features/base/custom_drop_down_item.dart | y |
| Fetch/list states | lib/core/utilities/widgets/base_fetching_widget.dart (GenericFetchWidget, BaseLoadingWidget, BaseErrorWidget); base_list_view_widget.dart; lib/features/base/paginated_list_view.dart; lib/features/base/no_data_screen.dart; lib/features/base/custom_loader.dart | y |
| Feedback | lib/core/utilities/widgets/toasts/{animated_custom_toast, custom_toast}.dart + lib/core/services/toast_manager.dart; lib/core/services/show_loading_dialog.dart; lib/features/base/custom_snackbar.dart; lib/features/base/custom_dialog.dart (showAnimatedDialog) | y |
| Bottom sheets | lib/core/utilities/widgets/image_picker_bottom_sheet.dart; DropdownTextFormField's internal sheet | y |
| Chips/selection | lib/core/utilities/widgets/{custom_chip, selection_chip_widget, custom_radio_group_widget}.dart | y |
| Cards/containers | lib/core/utilities/widgets/container_with_shadow.dart; linear_progress_indicator.dart | y |
| Images | lib/core/utilities/widgets/shared/widgets/image_Widget.dart (ImageViewerWidget); shared/screens/image_viewer.dart; lib/features/base/custom_image.dart; lib/features/base/image_dialog.dart | y |
| App bars | lib/features/base/custom_app_bar.dart, custom_expanded_app_bar.dart | n |
| Auth gate | lib/features/base/not_loggedin_widget.dart | n |
| Stubs | lib/core/utilities/widgets/shared/screens/select_location_screen.dart | n |

Notes: the core widgets depend on `core_exports.dart` (go_router + easy_localization + screenutil) and on
`AppColors`. They would only work after adding `ScreenUtilInit`. None of them is used by the live screens.
The live screens use `features/base/*` with `ColorResources`, `Dimensions` and `getTranslated`.

## 6. Packages (pubspec.yaml)

| Role | Packages |
|---|---|
| State | provider ^6.1.2 (live); flutter_bloc ^8.1.6 (dormant), equatable ^2.0.5 |
| DI | get_it ^8.0.0 |
| Routing | go_router ^14.6.2 (empty router) |
| Network | dio ^5.7.0, http ^1.2.2, connectivity_plus ^6.0.5, talker_dio_logger ^4.6.0 (dormant), talker_flutter ^4.6.0 (dormant) |
| Result | dartz ^0.10.1 (dormant) |
| Storage | shared_preferences ^2.3.2, flutter_secure_storage ^9.2.4 (dormant), path_provider ^2.1.4, path ^1.9.0 |
| L10n | flutter_localizations (sdk), easy_localization ^3.0.7 (dormant, not initialised); intl transitive |
| UI | cupertino_icons ^1.0.8, flutter_svg ^2.0.10+1, flutter_spinkit ^5.2.1, flutter_animate ^4.5.0, skeletonizer ^1.4.2, shimmer ^3.0.0, fluttertoast ^8.2.8, flutter_colorpicker ^1.1.0, dotted_border ^2.1.0 (unused), flutter_widget_from_html ^0.15.2, flutter_screenutil ^5.9.3 (dormant), flutter_native_splash ^2.4.3, country_picker ^2.0.26, country_code_picker ^3.0.0, pin_code_fields ^8.0.1 |
| Auth | sms_autofill ^2.4.1, flutter_facebook_auth ^7.1.1 |
| Maps | google_maps_flutter ^2.9.0, geolocator ^13.0.1 |
| Media | image_picker ^1.1.2, cached_network_image ^3.4.1, url_launcher ^6.3.1 |
| Utils | logging ^1.2.0, permission_handler ^11.3.1 |
| Dev | flutter_test, flutter_lints ^4.0.0 |

## 7. Quality notes
- **Null safety:** yes. **Lints:** flutter_lints ^4.0.0, no extra rules. **Tests:** 1 default counter test (stale).
- **The core issue:** two architectures in one app. The clean one is half-built and unreachable, which suggests
  the rewrite started in place and then moved to `New Projects/seller`.
- **Dormant-layer bugs to fix before reusing in a template:**
  - `BaseCubit` `ErrorState as State` cast.
  - `BaseRemoteDataSource` treats only 200/201 as success, ignores receive/send timeouts, and uses the
    service locator inside the class.
  - `ApiService` always attaches `TalkerDioLogger(printRequestHeaders: true)`.
  - `AppValidator.isNumeric` regex ends in `\$` (never matches) and returns an untranslated key.
  - `AppIcons.email/password` are missing the `/` in their paths.
  - `TextThemeLight` uses `.sp` at static-init time and an unbundled font.
  - `ImageViewerWidget` uses `Image.network` (no cache).
  - The dark theme and `price_converter.dart` are empty.
  - `PasswordTextFormField` ignores `isLogin`/`confirmPasswordValidator`.
  - `.fvmrc` (3.19.0) is older than the APIs used (`Column.spacing`, `Color.withValues`).
- **Live-layer bugs:** `NetworkInfo.isConnected` returns true when offline. `ApiChecker` detects 401 by matching a
  message string. `SharedPrefsManager.init()` is not awaited. `registerUrl` includes `baseUrl`. `MyHttpOverrides`
  is misspelt (`CreateHttpClient`, so it never overrides).
- **Security:** Google Maps API key in `lib/helper/location_helper.dart` (+ `android/app/src/main/AndroidManifest.xml`).
  Plaintext password in SharedPreferences (`lib/data/repository/auth_repo.dart`). Bearer headers logged by
  both interceptors.
- **Smells:** absurd relative imports (12 levels of `../`). `copy_feature.dart` uses blind `replaceAll`.
  `ratting_model.dart` sits in `repository/`. God files: `add_update_product_screen.dart` 1288 lines,
  `config_model.dart` 842, `product_detail_screen.dart` 778. `withOpacity` ×47, `Color(0x…)` ×293. No
  `WillPopScope`.
- **Template value:** medium for the dormant `lib/core` set (Failure hierarchy, BaseRemoteDataSource/BaseRepository,
  BaseBloc + GenericFetchWidget, ApiServiceBase, AppTextFormField family, AppDefaultButton, ToastManager,
  AppValidator, SecureStorageManager, component-theme split, AppColors scale, copy_feature idea). It is
  probably superseded by the same code, matured, in `New Projects/seller`. Compare file-by-file before
  choosing. Low value for the live 6valley layer.
