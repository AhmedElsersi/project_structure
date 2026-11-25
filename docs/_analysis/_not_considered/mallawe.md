# mallawe: analysis report

## Summary for comparison

```
PROJECT: mallawe | path: Freelance/mallawe/mallawe | stack: Flutter, Dart SDK '>=3.4.4 <4.0.0' | last commit: no git, mtime 2024-11-06 | source files: 92
ARCH: feature-first MVC-ish (no clean arch) — features/<name>/{cubit,screens,components}; cubits call static DioHelper directly; models in core/models or inline in screen files; no data/domain layers
STATE: flutter_bloc 8.1 (Cubit only) — no base cubit; per-feature Cubit + abstract State subclasses; 5 empty placeholder cubits; global AppCubit (locale/theme) + InternetCubit (lib/core/global_bloc/)
DI: none — MultiBlocProvider in lib/main.dart; static singletons DioHelper/CacheHelper/NotificationService
ROUTING: Navigator 1.0 named routes — lib/core/router/app_router.dart (onGenerateRoute switch) + route names in lib/core/constants/strings.dart (AppRouterNames) + lib/core/constants/navigator_extension.dart — guards: only initial-route choice by token presence in main.dart — deep links: none
NETWORK: dio 5.7 (static) — interceptors: none | token refresh: n | retry: n | error mapping: none (each cubit catches DioException and toasts response.data['message']) | lib/core/helpers/dio_helper.dart, lib/core/constants/end_points.dart
RESULT_TYPE: exceptions (try/catch in cubits, error states carry String) — no Failure hierarchy
STORAGE: shared_preferences (token stored here too) — lib/core/helpers/cache_helper.dart
L10N: flutter gen-l10n (intl arb via l10n.yaml, flutter_gen synthetic import) — ar, en (both arb files empty `{}`), default locale en (AppCubit), translations lib/core/localization/l10n/ — hardcoded UI strings: many (~130, mixed English/Arabic)
RTL: Directional=2 vs LeftRight=12 (+4 EdgeInsets.fromLTRB)
THEME: lib/core/constants/themes.dart — dark mode n (toggle exists in AppCubit, but no darkTheme) | component themes in ThemeData (appBar/buttons/inputs) partial: appBar+elevated/text buttons+chip, no inputDecorationTheme | colors class lib/core/constants/colors.dart (AppColors) | text styles class AppTextStyle/AppFontSize/AppFontWeight in themes.dart | fonts Poppins+Cairo declared but not bundled (pubspec `fonts:` misplaced at top level, wrong path)
RESPONSIVE: flutter_screenutil (design size 375x812, minTextAdapt, splitScreenMode) + custom Dimensions extension in lib/core/constants/const_methods.dart — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants — lib/core/constants/end_points.dart (base URL is a dev tunnel URL) — no flavors, no dart-define
LOGGING: debugPrint with ANSI colors (logError/logSuccess/logWarning in const_methods.dart) + MyBlocObserver; 1 print, some dart:developer log
ANALYTICS/CRASH: none (runZonedGuarded only logs to console; Firebase init commented out)
PUSH: flutter_local_notifications only (local) — lib/core/helpers/notification_service.dart; firebase_messaging declared but unused
PAYMENTS/IAP: none
PERMISSIONS: permission_handler declared but unused (manifest declares location incl. background, unused)
DEEP_LINKS: none
MEDIA/FILES: image_picker (pickImage helper + direct use), flutter_svg, lottie, carousel_slider, flutter_widget_from_html, url_launcher; no cached_network_image
TESTS: 1 — default counter smoke test (stale, would fail)
LINTS: flutter_lints ^3.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/global_bloc/internet_cubit/internet_cubit.dart — connectivity_plus 6 stream Cubit (connected/disconnected enum) — quality 3 — coupling: low (InternetState enum in core/constants/enums.dart)
- lib/core/constants/navigator_extension.dart — BuildContext goTo/goToReplace/goToClearStack/back — quality 3 — coupling: none
- lib/core/global_bloc/bloc_observer.dart — colored BlocObserver (create/change/error/close) — quality 3 — coupling: none
- lib/core/global_bloc/app_cubit/app_cubit.dart — persisted locale + ThemeMode cubit — quality 3 — coupling: low (CacheHelper, CacheKeys)
- lib/core/helpers/cache_helper.dart — static SharedPreferences wrapper (get/save by type/remove/clear) — quality 2 — coupling: none
- lib/core/constants/const_methods.dart — log helpers, String toast extension, AppValidators, pickImage, launch helpers, formatters — quality 2 — coupling: high (god file; hardcoded contact data; English-only messages)
- lib/core/helpers/notification_service.dart — static local-notifications wrapper (init/show/cancel, 2 channels) — quality 2 — coupling: none (uses deprecated onDidReceiveLocalNotification)
- lib/core/constants/themes.dart — AppFontWeight/AppFontSize/AppTextStyle tokens + light ThemeData — quality 2 — coupling: low (AppColors)
- lib/core/helpers/dio_helper.dart — static Dio wrapper get/post/put/delete/download — quality 1 — coupling: low (CacheHelper); mutates shared headers per call, token param ignored
- lib/core/localization/app_strings_extension.dart — supportedLocales/delegates aliases + context.isAr — quality 2 — coupling: low
- lib/core/imports.dart — barrel export of widgets/constants/helpers/packages — quality 2 — coupling: high (app-wide)
- lib/core/constants/strings.dart — asset path constants, CacheKeys, AppRouterNames — quality 2 — coupling: none (but copy-paste leftovers)
- lib/core/router/app_router.dart — onGenerateRoute switch with typed arguments — quality 2 — coupling: high (imports every screen)
- lib/core/constants/colors.dart — AppColors static palette — quality 2 — coupling: none
GENERIC_WIDGETS (every reusable widget):
- lib/features/widgets/default_text_field.dart — text field — controller, label/hint, prefix/suffix, validator, focusNode/nextNode, isPassword (built-in eye toggle), maxLines/maxLength, inputFormatters, borderRadius — quality 3 — generic? y
- lib/features/general/widgets/summaryRow.dart — label/value row (bold total variant) — label, value, isBold — quality 3 — generic? y
- lib/features/general/widgets/dash_divider.dart — dashed divider (LayoutBuilder) — dashWidth, dashHeight, color, dashSpacing, height — quality 3 — generic? y
- lib/features/auth/component/rich_text_widget.dart — two-part text with tappable link span — firstText, secondText, onTapSecondText — quality 3 — generic? y
- lib/features/widgets/default_button.dart — primary button — onTap, text, height, width, margin, borderRadius, isEnabled — quality 2 — generic? y
- lib/features/widgets/loading_dialog.dart — blocking loading dialog (AppLoading().showLoading/hideLoading) — context, text — quality 2 — generic? y
- lib/features/widgets/show_dialog_for_messages.dart — adaptive confirm dialog showMessageDialog + adaptiveAction helper — title, subTitle, confirmText, cancelText, onConfirmPressed — quality 2 — generic? y
- lib/features/general/widgets/custom_appbar.dart — buildCustomAppBar() function returning AppBar with back chevron + bottom divider — context, title, actions — quality 2 — generic? y
- lib/features/general/general_screens/no_internet_screen.dart — no-internet screen (PopScope, pops on reconnect) — none — quality 2 — generic? y (hardcoded Arabic)
- lib/features/widgets/No_component_view.dart — empty state (svg, text, optional button) — image, content, btnExists, buttonTitle, buttonOnTap — quality 2 — generic? y (unused, Arabic defaults)
- lib/features/widgets/lottie_text_widget.dart — Lottie animation + caption (success state) — image, content, controller — quality 2 — generic? y (unused)
- lib/features/widgets/custom_popup.dart — input dialog (SimpleDialog with text field, overridable title/content/action) — titleString, confirmButtonString, textFormFieldText, onTapConfirmButton, paddings — quality 2 — generic? y (unused)
- lib/features/widgets/settings_safety_iterm.dart — settings tile (svg icon, title, subtitle, chevron) — title, subTitle, icon, isSavedPlaces, onTap — quality 2 — generic? y
- lib/features/general/widgets/icon_text_widget.dart — svg icon + text row with IconTextModel — iconTextModel(svgIconPath, text, onTap) — quality 2 — generic? y
- lib/features/profile/components/profile_widget.dart — settings row svg+title+value+chevron that pushes a route — svgIcon, title, value, routeName — quality 2 — generic? partly
- lib/features/cart/components/horizontal_product_widget.dart (Counter) — quantity stepper — none (no initial value / callback) — quality 2 — generic? partly
- lib/features/widgets/change_views_arrow_widget.dart — circular prev/next arrow indicator — pageIndex, isBack, viewsCount, size — quality 2 — generic? y
- lib/features/widgets/location_dot.dart — dot marker — size, padding, outLineColor, coreColor, rightMarginExist — quality 2 — generic? n
- lib/features/cart/screens/order_details_screen.dart (TrackingProgressWidget) — step progress tracker — steps(List<TrackingStep>) — quality 2 — generic? n (hardcoded 0.333 = 4 steps)
- lib/features/widgets/on_board_widget.dart — onboarding page (svg/png + title + content) — image, title, content, extension — quality 1 — generic? y (unused)
- lib/features/widgets/bottom_selection_view.dart — bottom-sheet selection list with search — listItemTitle, data(List<SelectionModel>), enableSearch — quality 1 — generic? n (broken: empty item text, search not wired)
- lib/features/widgets/app_app_bar.dart — AppBar wrapper — title — quality 1 — generic? n (not PreferredSizeWidget, unused)
- lib/features/widgets/custom_country_picker_dialog.dart — country picker dialog — fully commented out — quality 1 — generic? n
NOTABLE_IDEAS: String toast extension `"msg".toToastError()/toToastSuccess()/toToastWarning()` (lib/core/constants/const_methods.dart); ANSI-colored log helpers + colored BlocObserver (const_methods.dart, lib/core/global_bloc/bloc_observer.dart); InternetCubit + NoInternetScreen pattern with PopScope(canPop:false) that auto-pops on reconnect (lib/core/global_bloc/internet_cubit/, lib/features/general/general_screens/no_internet_screen.dart); DefaultTextField with focus chaining (focusNode/nextNode), built-in password toggle and onTapOutside unfocus (lib/features/widgets/default_text_field.dart); AppValidators static class with generic validateAnyText(pattern, minLength) (const_methods.dart); adaptiveAction() platform-adaptive dialog actions (lib/features/widgets/show_dialog_for_messages.dart); AppTextStyle factory per weight mapped into ThemeData.textTheme (lib/core/constants/themes.dart); Accept-Language header from cached locale (dio_helper.dart); runZonedGuarded + FlutterNativeSplash.preserve/remove (lib/main.dart); barrel file lib/core/imports.dart
SMELLS: DioHelper mutates shared dio.options.headers per request (race-prone), ignores its `token` argument (default '' means auth header always attached), no timeouts/interceptors/error mapping; ProfileCubit passes Map where User is expected (runtime TypeError); Product.fromJson checks the field not the json so images never parse; RegisterRequestModel.toJson puts an un-awaited MultipartFile.fromFile Future + `avatarPath!`; core/constants/const_variables.dart imports feature screens and holds mock data; models declared inside screen files; 5 empty placeholder cubits; copy-paste leftovers (CacheKeys prefixed with another project's name, ride-hailing route names, commented country picker, UI-kit template_screen.dart in a folder with a space "new options"); pubspec `fonts:` outside `flutter:` with wrong path (fonts never bundled), `dio:` unconstrained, ~13 unused deps (firebase_core/messaging, socket_io_client, permission_handler, pin_code_fields, intl_phone_number_input, date_picker_plus, dots_indicator, radio_group_v2, search_page, searchable_listview, smooth_page_indicator, country_picker); empty arb files + Windows backslash arb-dir in l10n.yaml + deprecated flutter_gen import; ~130 hardcoded strings; deprecated APIs: MaterialStateProperty x3, withOpacity x7, WidgetsBinding.instance.window, SvgPicture color:, onDidReceiveLocalNotification; physical left/right paddings; token in plain SharedPreferences; logout calls clearData() (wipes language pref); hardcoded contact phone/email in const_methods.dart; WidgetsFlutterBinding.ensureInitialized twice; print/throw-string; stale counter test
```

---

## 1. Architecture pattern

Feature-first folders with a thin MVC-like split. There is no clean architecture: no repositories, data sources, use cases or domain entities.

- **Presentation**: `features/<feature>/screens/*.dart` holds StatefulWidgets that use `BlocConsumer` / `BlocBuilder`, plus `components/` for feature widgets.
- **State/logic**: `features/<feature>/cubit/` holds a Cubit and its state classes. Cubits call the static `DioHelper` directly, parse JSON into models, write to `CacheHelper`, and show toasts. UI side effects inside cubits are common.
- **Models**: `core/models/` (`user.dart`, `requests/`, `responses/`). Several UI models are defined inline inside screen files: `ProductModel` and `OfferModel` in `home_view.dart`, `Review` in `product_details_screen.dart`, `AddressModel` in `address_screen.dart`, `Order` in `order_widget.dart`, `CategoryModel` in `search_view.dart`.
- **Shared**: `core/` holds constants, helpers, global blocs, router and localization. `features/widgets/` and `features/general/` hold shared widgets.

The project is an early-stage e-commerce UI. Only auth (login/register/logout/delete) and profile fetch are wired to the API. Every other screen uses static mock data (`core/constants/const_variables.dart`, `TempImages`). The home, cart, offer, search and notifications cubits are empty placeholders that use the `State().init()/clone()` template pattern.

A representative feature (`auth`) looks like this:
```
features/auth/
  component/rich_text_widget.dart   # "Don't have an account? Register" link text
  cubit/auth_cubit.dart             # register/login/logout/deleteAccount via DioHelper, saves token to CacheHelper
  cubit/auth_state.dart             # part-of; Loading/Loaded/Error states (String message)
  screens/login_screen.dart         # Form + DefaultTextField + DefaultButton; BlocConsumer shows/hides AppLoading
  screens/register_screen.dart      # same pattern + date picker + image picker
```
Flow: the screen validates the Form, calls `BlocProvider.of<AuthCubit>(context).login(...)`, and the cubit emits `AuthLoginLoadingState`. The listener calls `AppLoading().showLoading`. The cubit then calls `DioHelper.postData`, saves the token and emits a loaded state, and the listener hides the loader. On login success the next step is still a TODO, so login never navigates.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                         # runZonedGuarded, splash preserve, init Notification/Cache/Dio, MultiBlocProvider, ScreenUtilInit, MaterialApp
├── core/
│   ├── imports.dart                  # barrel export (widgets, constants, helpers, material, screenutil, bloc, svg)
│   ├── constants/                    # colors, theme+text styles, endpoints, strings (assets/cache keys/routes), enums, extensions, const methods, mock data
│   │   ├── colors.dart               # AppColors
│   │   ├── themes.dart               # AppFontWeight, AppFontSize, AppTextStyle, AppThemes.arLightTheme
│   │   ├── theme_extension.dart      # context.theme (unused)
│   │   ├── const_methods.dart        # log*, String toast ext, showToast, Dimensions ext, pickImage, AppValidators, date/number formatters, phone/whatsapp/mail launchers
│   │   ├── const_variables.dart      # error msg constants, late fcmToken, horizontalPadding, mock product list
│   │   ├── end_points.dart           # EndPoints (hardcoded base URL + paths)
│   │   ├── enums.dart                # ToastState, InternetState
│   │   ├── navigator_extension.dart  # goTo/goToReplace/goToClearStack/back
│   │   ├── numbers_extension.dart    # num.pxToDp
│   │   └── strings.dart              # asset paths, AppImages/AppIcons/AppLottieFiles/TempImages, CacheKeys, AppRouterNames
│   ├── global_bloc/
│   │   ├── app_cubit/                # AppCubit (locale + ThemeMode persisted) + states
│   │   ├── internet_cubit/           # InternetCubit (connectivity_plus); internet_state.dart fully commented out
│   │   └── bloc_observer.dart        # MyBlocObserver
│   ├── helpers/                      # cache_helper (SharedPreferences), dio_helper (Dio), notification_service (local notifications)
│   ├── localization/
│   │   ├── app_strings_extension.dart  # supportedLocales/localizationDelegates aliases, context.isAr
│   │   └── l10n/app_ar.arb, app_en.arb # both empty {}
│   ├── models/                       # user.dart, selection_model.dart, requests/registerRequestModel.dart, responses/{register,category}_response_model.dart
│   ├── router/app_router.dart        # AppRouter.onGenerateRoutes switch
│   └── theme/text_theme.dart         # empty file (0 lines)
└── features/
    ├── auth/          {component, cubit, screens}            # login/register
    ├── cart/          {components, cubit, screens}           # cart, orders, order details (+TrackingProgressWidget, Counter)
    ├── general/       {general_screens, widgets}             # no-internet screen; custom app bar, dash divider, icon-text row, summary row
    ├── home/          {cubit, screens}                       # home, favorites, offer, product details (models inline)
    ├── navigation/    {screens}                              # bottom-nav IndexedStack shell
    ├── new options/   template_screen.dart                   # pasted UI-kit sample with inline SVG strings
    ├── notifications/ {components, cubit, screens}
    ├── offer/         {cubit, screens}
    ├── profile/       {components, cubit, screen, screen/profile_screens}  # account, profile, address, coupons, change name/email/gender/birthday/phone/password
    ├── search/        {cubit, screens}
    ├── settings/      {settings_screens}                     # settings, about (HTML widget)
    └── widgets/                                              # shared widgets (button, text field, dialogs, empty state, etc.)
```

## 3. Infrastructure

### State management
- `flutter_bloc ^8.1.5` (resolved 8.1.6). Cubits only, no Blocs/events.
- No base cubit and no `handleRequest` helper. Every cubit method repeats the same `try { emit(Loading) ... } on DioException {...} catch {...}` block with `kDebugMode ? debugMessage : serverErrorMsg`.
- States are hand-written `abstract class XState {}` subclasses with no Equatable. `AuthState` uses `part of`; `ProfileState` is a separate import.
- Global: `AppCubit` (lib/core/global_bloc/app_cubit/app_cubit.dart) holds `locale`, `themeMode` and `isDark`, persisted via CacheHelper. It exposes `changeAppLanguage(Locale)` and `toggleTheme()`. `initAppCubit()` calls async methods without awaiting them. `_themeMode` is `late`, and the first build would throw if `_initDarkTheme` were not effectively synchronous.
- `InternetCubit` (lib/core/global_bloc/internet_cubit/internet_cubit.dart) uses the `List<ConnectivityResult>` API (connectivity_plus 6) and emits an enum `InternetState {initial, connected, disconnected}`. It cancels its subscription in `close()`. It is provided in main, but nothing navigates to `rNoInternet`, so it is only half-wired.
- `MyBlocObserver` logs create/change/error/close in cyan.
- Placeholder cubits (`HomeCubit`, `CartCubit`, `OfferCubit`, `SearchCubit`, `NotificationsCubit`) are empty. `HomeCubit.get` is an instance method, so it cannot be used as a static accessor.

### DI
None. Cubits are created in `MultiBlocProvider` in `lib/main.dart` (AppCubit with lazy:false, InternetCubit, AuthCubit, ProfileCubit). Services are static classes.

### Routing
- Navigator 1.0. `MaterialApp.onGenerateRoute: AppRouter.onGenerateRoutes` in `lib/core/router/app_router.dart` is a single switch over `AppRouterNames` constants (in `lib/core/constants/strings.dart`). Arguments are passed with casts (`settings.arguments as ProductModel`), and unknown routes return `null`.
- `lib/core/constants/navigator_extension.dart` provides `context.goTo`, `goToReplace`, `goToClearStack` and `back`.
- Guard: `_MyAppState.initState` picks `initialRoute` as login or navigation based on whether a cached token exists. There is no redirect logic and no deep links.
- Bottom navigation: `features/navigation/screens/navigation_screen.dart` uses an `IndexedStack` with 5 tabs and hardcoded English labels.

### Networking
- `dio` is unconstrained in pubspec (`dio: null`) and resolved to 5.7.0. `lib/core/helpers/dio_helper.dart` is a static class: `init()`, `getData`, `postData` (with `isForm` to get FormData), `putData`, `deleteData`, `downloadMedia`, `verifyPhoneSocial`.
- Headers are rebuilt on every call by **overwriting the shared `dio.options.headers`**: Accept, Accept-Language from cached lang, and `Authorization: Bearer <cached token>`. Concurrent requests can race on these headers. The `token` parameter is never used as a value in get/post/put; only its null-ness matters, and it defaults to `''`, so the header is always attached. `ProfileCubit` passes `"Bearer ..."` as the token, which is ignored.
- No interceptors, LogInterceptor, timeouts, retry, token refresh, 401 handling or error mapping. Each cubit catches `DioException` and reads `dioError.response?.data['message']`.
- Endpoints live in `lib/core/constants/end_points.dart`. The base URL is a hardcoded dev-tunnel URL (`{{BASE_URL}}`).
- `socket_io_client` is declared but unused.

### Local storage
- `lib/core/helpers/cache_helper.dart` is a static `SharedPreferences` wrapper: `init`, `getDataFromSharedPreference({key})` returning dynamic, `saveDataSharedPreference({key, value})` which dispatches on type and writes an empty string for unknown types, `removeData`, `clearData`.
- Keys are in `CacheKeys` (strings.dart) and are prefixed with another project's name, a copy-paste leftover.
- The auth token is stored in plain SharedPreferences. There is no secure storage.
- Logout calls `clearData()`, which also wipes the language preference.

### Localization (+RTL)
- `flutter: generate: true` and `l10n.yaml`: arb-dir `lib\core\localization\l10n` uses Windows backslashes, template `app_ar.arb`. Both arb files are empty `{}`, so nothing is actually translated.
- `lib/core/localization/app_strings_extension.dart` re-exports `AppLocalizations.supportedLocales` and `localizationsDelegates` through the deprecated `package:flutter_gen/gen_l10n` synthetic import, and adds `context.isAr`.
- The locale comes from `AppCubit.locale` (default `en`, persisted).
- About 130 hardcoded UI strings, mixed English and Arabic (no-internet screen, empty-state defaults, loading texts). Validators return English strings.
- RTL: 2 directional usages (`EdgeInsetsDirectional` in default_text_field and profile_screen) against 12 physical left/right usages plus 4 `fromLTRB`. Fonts include Cairo for Arabic, but they are not bundled (see Theming). There is no RTL-specific handling.

### Theming
- `lib/core/constants/themes.dart`:
  - `AppFontWeight` (w300–w800) and `AppFontSize` (s10–s40) constants.
  - `AppTextStyle.textStyleLight/Regular/Medium/SemiBold/Bold/ExtraBold({fontSize})`, using Poppins and `AppColors.textColor`.
  - `AppThemes().arLightTheme(context)`: M3, `ColorScheme.light(primary)`, `elevatedButtonTheme`/`textButtonTheme` built with `MaterialStateProperty` and `Theme.of(context)` inside ThemeData construction, a full `textTheme` mapped from AppTextStyle, `appBarTheme` (overlay style, titleSpacing 0), `chipTheme`. There is no `inputDecorationTheme`; DefaultTextField styles itself.
- `lib/core/constants/colors.dart` (`AppColors`) is a flat palette with about 30 colors, several unused or leftover.
- Dark mode: `themeMode` comes from AppCubit, but no `darkTheme` is provided, so the dark toggle has no effect.
- `lib/core/theme/text_theme.dart` is empty.
- **Fonts bug**: the `fonts:` block in pubspec.yaml sits at top level instead of under `flutter:`, and it points to `fonts/...` while the files are in `assets/fonts/`. Poppins and Cairo are therefore never bundled and the platform default font is used.
- Only 17 raw `Colors.*` usages; most use AppColors. 23 `Color(0x..)` literals sit in `template_screen.dart`.

### Responsive helpers
- `flutter_screenutil ^5.9.0`: `ScreenUtilInit(designSize: Size(375, 812), minTextAdapt: true, splitScreenMode: true)` in main. `.w/.h/.sp` are used widely (about 160 hits).
- `Dimensions` extension on BuildContext in const_methods.dart (`screenHeight(context)`, `widthPercentage(context, %)`, etc.) has a redundant `context` parameter.
- `num.pxToDp` in numbers_extension.dart uses the deprecated `WidgetsBinding.instance.window`.
- No breakpoints and no tablet layouts.

### Text scaling
None. There is no `MediaQuery` textScaler clamp; only screenutil `minTextAdapt`.

### Env / flavors
None. Constants are hardcoded in `end_points.dart`. Android has no productFlavors, and nothing uses `--dart-define`.

### Logging
`logError/logSuccess/logWarning` (ANSI red/green/yellow via `debugPrint`) in `lib/core/constants/const_methods.dart`, plus `MyBlocObserver`. There is one `print` (getTimePeriod) and a few `dart:developer log` calls. `runZonedGuarded` sends errors to `logError` only. There is no `FlutterError.onError` hook.

### Analytics / crash reporting
None. Firebase init and the FCM token call are commented out in main.dart.

### Push notifications
- `lib/core/helpers/notification_service.dart` is a static `FlutterLocalNotificationsPlugin` wrapper (resolved 17.2.3): `initialize()` with Android icon and Darwin permission requests, `showNotification` and `showOrderNotification` on two hardcoded channels, `cancelNotification` (cancelAll).
- It uses `onDidReceiveLocalNotification`, which is deprecated and removed in v18. There is no tap handler (`onDidReceiveNotificationResponse`) and no Android 13 permission request.
- `firebase_messaging` and `firebase_core` are declared but unused. No Firebase config files exist in the project.

### IAP / payments
None.

### Permissions
`permission_handler ^11.3.1` is declared but never imported. AndroidManifest declares INTERNET plus coarse, fine and **background** location, none of which are used.

### Deep links
None. The manifest only has sms/tel `queries` for url_launcher.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/helpers/dio_helper.dart (`DioHelper`) | HTTP client wrapper | `init()`, `getData`, `postData(isForm)`, `putData`, `deleteData`, `downloadMedia`, `verifyPhoneSocial` | dio, CacheHelper, CacheKeys, EndPoints | Generic in intent; implementation unsafe (shared header mutation, ignored token param) |
| lib/core/helpers/cache_helper.dart (`CacheHelper`) | SharedPreferences wrapper | `init`, `getDataFromSharedPreference`, `saveDataSharedPreference`, `removeData`, `clearData` | shared_preferences | Generic |
| lib/core/helpers/notification_service.dart (`NotificationService`) | Local notifications | `initialize`, `notificationDetails`, `notificationDetailsForOrder`, `showNotification`, `showOrderNotification`, `cancelNotification` | flutter_local_notifications | Generic (order channel app-specific) |
| lib/core/global_bloc/app_cubit/app_cubit.dart (`AppCubit`) | Locale + theme mode | `get(ctx)`, `locale`, `themeMode`, `isDark`, `initAppCubit`, `changeAppLanguage`, `toggleTheme` | CacheHelper | Generic |
| lib/core/global_bloc/internet_cubit/internet_cubit.dart (`InternetCubit`) | Connectivity stream | `get(ctx)`, state enum | connectivity_plus | Generic |
| lib/core/global_bloc/bloc_observer.dart (`MyBlocObserver`) | Bloc logging | overrides | bloc | Generic |
| lib/core/router/app_router.dart (`AppRouter`) | Route factory | `onGenerateRoutes(settings)` | all screens | App-specific |
| lib/core/constants/const_methods.dart (top-level) | Logging | `logError`, `logSuccess`, `logWarning` | flutter | Generic |
| lib/core/constants/const_methods.dart (`StringExtension`) | Email check + toasts | `isValidEmail()`, `toToastError()`, `toToastSuccess()`, `toToastWarning()` | fluttertoast, AppColors | Generic |
| lib/core/constants/const_methods.dart (top-level) | Toast | `showToast(text, ToastState)` | fluttertoast | Generic |
| lib/core/constants/const_methods.dart (`Dimensions` ext) | MediaQuery sizing | `screenHeight`, `screenWidth`, `heightPercentage`, `widthPercentage`, `fontSize`, `radius` | flutter | Generic (awkward API) |
| lib/core/constants/const_methods.dart (top-level) | Image picking | `pickImage({source, onImageSelect})` (1024px max, quality 50) | image_picker | Generic |
| lib/core/constants/const_methods.dart (`AppValidators`) | Form validation | regex constants, `validateEmail`, `validatePhone`, `validatePw`, `validateRePw`, `validateAnyText(v, title, pattern, minLength)` | none | Generic (English messages hardcoded) |
| lib/core/constants/const_methods.dart (top-level) | Formatting | `dateTimeFormat`, `formatDateString`, `getTimePeriod`, `removeTrailingZeros`, `formatNumber` (K/M/B), `formatTime` | intl | Generic |
| lib/core/constants/const_methods.dart (top-level) | URL launching | `makePhoneCall`, `whatsapp()` (hardcoded number), `sendingMails()` (hardcoded address) | url_launcher | Phone generic; whatsapp/mail app-specific |
| lib/core/constants/navigator_extension.dart (`NavigatorExtension`) | Navigation sugar | `back`, `goTo`, `goToReplace`, `goToClearStack` | flutter | Generic |
| lib/core/constants/numbers_extension.dart (`NumberExtension`) | px → dp | `pxToDp` | flutter (deprecated window) | Generic |
| lib/core/constants/theme_extension.dart (`ThemeExtension`) | Theme shortcut | `context.theme` | flutter | Generic (unused) |
| lib/core/localization/app_strings_extension.dart | l10n aliases | `supportedLocales`, `localizationDelegates`, `context.isAr` | gen-l10n | Generic |
| lib/core/constants/themes.dart | Typography + ThemeData | `AppFontWeight`, `AppFontSize`, `AppTextStyle.*`, `AppThemes().arLightTheme(ctx)` | AppColors, screenutil (import only) | Generic pattern |
| lib/core/constants/colors.dart (`AppColors`) | Palette | static colors | flutter | App-specific values |
| lib/core/constants/strings.dart | Assets/cache keys/routes | `AppImages`, `AppIcons`, `AppLottieFiles`, `TempImages`, `CacheKeys`, `AppRouterNames` | none | Pattern generic |
| lib/core/constants/end_points.dart (`EndPoints`) | API paths | constants | none | App-specific |
| lib/core/constants/enums.dart | Enums | `ToastState`, `InternetState` | none | Generic |
| lib/core/constants/const_variables.dart | Globals + mock data | `unknownErrorMsg`, `serverErrorMsg`, `fcmToken`, `horizontalPadding`, `flashSaleList` | imports feature screens | App-specific (layer inversion) |
| lib/core/models/* | DTOs | `User`, `SelectionModel`, `RegisterRequestModel`, `RegisterResponseModel`, `CategoryResponseModel/Subcategories/Product` (hand-written fromJson/toJson) | dio (MultipartFile) | App-specific |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/features/widgets/default_button.dart (`DefaultButton`) | Primary filled button; InkWell sits outside the decorated Container, so no ripple; `isEnabled` only changes color and does not block taps; no loading state | onTap*, text*, height(55), width(inf), margin, borderRadius(5), isEnabled | y |
| lib/features/widgets/default_text_field.dart (`DefaultTextField`) | TextFormField with outline borders per state, built-in password eye toggle, focus chaining on save, unfocus on tap outside, directional content padding | controller*, labelText, hintText, prefix, suffix, onTap, onChanged, readOnly, enabled, keyboardType, textInputAction, obscureText (unused), maxLines, maxLength, inputFormatters, validator, focusNode, nextNode, isPassword, borderRadius | y |
| lib/features/widgets/loading_dialog.dart (`AppLoading`) | Non-dismissible loading dialog; hide uses `Navigator.pop`, which is fragile | `showLoading(context, text)`, `hideLoading(context)` | y |
| lib/features/widgets/show_dialog_for_messages.dart (`showMessageDialog`, `adaptiveAction`) | Adaptive confirm/cancel dialog using DefaultButtons; height fixed at screen/5 | context, title, subTitle, confirmText, cancelText, onConfirmPressed, width (unused) | y |
| lib/features/widgets/custom_popup.dart (`CustomPopup`) | SimpleDialog with input field + cancel/save; title/content/action overridable; hardcoded "cancel"/"Save"/"Address Title"; controller not disposed; unused | title, titlePadding, content, contentPadding, action, titleString, confirmButtonString, textFormFieldText, onTapConfirmButton | y |
| lib/features/widgets/No_component_view.dart (`NoComponentView`) | Empty state: svg + text + optional button; Arabic defaults; unused | image, content, btnExists, buttonTitle, buttonOnTap | y |
| lib/features/widgets/lottie_text_widget.dart (`LottieTextWidget`) | Lottie + caption success view; unused | image, content*, controller* | y |
| lib/features/widgets/bottom_selection_view.dart (`BottomSelectionView`) | Bottom sheet list with search; broken (items render `DefaultButton(text: "")`, search not wired, Expanded inside a min-size column) | listItemTitle*, data*, enableSearch | n |
| lib/features/widgets/app_app_bar.dart (`AppAppBar`) | AppBar wrapper; not a PreferredSizeWidget; unused | title* | n |
| lib/features/widgets/change_views_arrow_widget.dart (`ChangeViewArrowWidget`) | Circular prev/next arrow, greyed at bounds | pageIndex*, isBack*, viewsCount*, size | y |
| lib/features/widgets/location_dot.dart (`LocationDot`) | Ringed dot marker | size, padding, outLineColor, coreColor, rightMarginExist | n |
| lib/features/widgets/on_board_widget.dart (`OnBoardWidget`) | Onboarding page; unused | image*, title*, content*, extension | y |
| lib/features/widgets/settings_safety_iterm.dart (`SettingsSafetyItem`) | Bordered settings tile with chevron (deprecated SvgPicture `color:`) | title*, subTitle*, onTap*, icon, isSavedPlaces | y |
| lib/features/widgets/custom_country_picker_dialog.dart | Country picker; fully commented out | none | n |
| lib/features/general/widgets/custom_appbar.dart (`buildCustomAppBar`) | Function returning AppBar: back chevron, bold title, bottom divider, toolbarHeight 82 | context*, title*, actions | y |
| lib/features/general/widgets/dash_divider.dart (`DashDivider`) | Dashed horizontal line (uses `.h` on width) | dashWidth, dashHeight, color, dashSpacing, height | y |
| lib/features/general/widgets/icon_text_widget.dart (`IconTextRow`, `IconTextModel`) | Tappable svg icon + text row | iconTextModel*(svgIconPath, text, onTap) | y |
| lib/features/general/widgets/summaryRow.dart (`SummaryRow`) | Label/value row for price summaries | label*, value*, isBold | y |
| lib/features/general/general_screens/no_internet_screen.dart (`NoInternetScreen`) | Blocking offline screen; pops + shows snackbar on reconnect | none | y |
| lib/features/auth/component/rich_text_widget.dart (`RichTextWidget`) | Text + tappable link span (recognizer not disposed) | firstText*, secondText*, onTapSecondText | y |
| lib/features/profile/components/profile_widget.dart (`ProfileWidget`) | svg + title … value + chevron row that pushes a named route | svgIcon*, title*, value*, routeName* | partly |
| lib/features/cart/components/horizontal_product_widget.dart (`Counter`) | Quantity stepper (min 1); no initial value or onChanged | none | partly |
| lib/features/cart/components/horizontal_product_widget.dart (`HorizontalProductWidget`) | Cart item card | product-specific | n |
| lib/features/cart/components/order_widget.dart (`OrderWidget`) | Order summary card | order | n |
| lib/features/cart/screens/order_details_screen.dart (`TrackingProgressWidget`, `TrackingStep`) | Horizontal order-step tracker (progress hardcoded 0.333/step) | steps* | n |
| lib/features/notifications/components/notification_widget.dart | Notification list item | order model | n |
| lib/features/home/screens/home_view.dart (`HomeSectionView`, `ProductWidget`) | Section title + "See More" + horizontal product list; product card | title, products, onTapSeeMore / product | n |
| lib/features/home/screens/product_details_screen.dart (`ReviewCard`) | Review card with rating bar | review | n |
| lib/features/profile/screen/profile_screens/change_gender_screen.dart (`GenderDropdown`) | Gender dropdown | app-specific | n |
| lib/features/profile/screen/profile_screens/change_birthday_screen.dart (`CalenderView`) | Calendar date selector | app-specific | n |
| lib/features/new options/template_screen.dart (`IconBtnWithCounter`, `SearchField`, `SectionTitle`, `ProductCard`, `DiscountBanner`) | Pasted UI-kit sample with inline SVG strings and raw colors | various | n |

## 6. Packages (pubspec.yaml)

- **State**: flutter_bloc ^8.1.5 (`bloc` imported directly but not declared)
- **DI**: none
- **Routing**: none (Navigator 1.0)
- **Network**: dio (unconstrained, resolved 5.7.0); socket_io_client ^2.0.3+1 (unused); connectivity_plus ^6.0.3
- **Storage**: shared_preferences ^2.2.3
- **L10n**: flutter_localizations (sdk), intl ^0.19.0
- **UI**: flutter_screenutil ^5.9.0, flutter_svg ^2.0.10+1, lottie ^3.1.2, carousel_slider ^5.0.0, flutter_rating_bar ^4.0.1, flutter_widget_from_html ^0.15.2, fluttertoast ^8.2.5, cupertino_icons ^1.0.6; unused: dots_indicator ^3.0.0, smooth_page_indicator ^1.1.0, pin_code_fields ^8.0.1, radio_group_v2 ^3.1.1, search_page ^2.3.0, searchable_listview ^2.13.0, date_picker_plus ^4.0.0, intl_phone_number_input ^0.7.4, country_picker ^2.0.26
- **Firebase**: firebase_core ^2.27.0, firebase_messaging ^14.7.19 (both unused)
- **Notifications**: flutter_local_notifications ^17.2.1
- **Media / utils**: image_picker ^1.1.1, url_launcher ^6.2.6, permission_handler ^11.3.1 (unused)
- **Tooling (wrongly in dependencies)**: flutter_launcher_icons ^0.14.1, flutter_native_splash ^2.4.1 (splash preserve/remove is used at runtime)
- **Dev**: flutter_test, flutter_lints ^3.0.0

## 7. Quality notes

- **Null safety**: yes (Dart 3.4). Heavy `!` on nullable model fields and `late` globals (`late String? fcmToken` is never assigned).
- **Lints**: `analysis_options.yaml` is the stock template (`include: package:flutter_lints/flutter.yaml`, no extra rules).
- **Tests**: only `test/widget_test.dart`, the default counter smoke test. It is stale: the app has no counter, and `MyApp` needs `CacheHelper.init()`.
- **Bugs found**:
  - `ProfileCubit.getProfile` emits `ProfileLoadedState(model: res.data)`, a Map where a `User` is expected, which is a runtime TypeError.
  - `Product.fromJson` checks `if (images != null)` on the field rather than on the json, so images are never parsed.
  - `RegisterRequestModel.toJson` sets `avatar` to an un-awaited `Future<MultipartFile>` and force-unwraps `avatarPath`. The request is not sent as FormData because `isForm` defaults to false.
  - Login sends `password_confirmation`.
  - The login success branch is a TODO, so it never navigates.
  - `NavigationScreen` reuses `AuthLoginLoadingState` for logout and delete-account.
- **Smells**:
  - God file `const_methods.dart`.
  - `core` imports `features` (const_variables.dart).
  - Models are defined in screen files.
  - 5 empty placeholder cubits.
  - Copy-paste leftovers from other projects: cache-key prefix, ride-hailing route names, `template_screen.dart` in a folder with a space in its name, commented-out country picker, empty `theme/text_theme.dart`, fully commented `internet_state.dart`.
  - About 13 unused dependencies.
  - The pubspec `fonts:` block is misplaced, so the fonts are not bundled.
  - The arb files are empty, and about 130 UI strings are hardcoded in mixed languages.
  - Physical left/right paddings.
  - Contact phone and email are hardcoded in `const_methods.dart`.
  - The base URL is hardcoded.
  - The token is kept in plain SharedPreferences.
  - `WidgetsFlutterBinding.ensureInitialized()` is called twice and there is an unused `late String screen` in main.dart.
  - There is a `print` and `throw 'string'`.
- **Deprecated APIs**:
  - `MaterialStateProperty` (3, themes.dart)
  - `withOpacity` (7)
  - `WidgetsBinding.instance.window` (numbers_extension.dart)
  - `SvgPicture.asset(color:)` (settings_safety_iterm.dart)
  - `onDidReceiveLocalNotification` (notification_service.dart)
  - `package:flutter_gen` synthetic l10n import
  - The public `createState` returns a private type in `Counter`.
  - No WillPopScope; PopScope is used correctly.
- **Duplication**:
  - The try/catch/emit block is repeated in every cubit method.
  - Header-building code is repeated in each DioHelper method.
  - `notificationDetails` and `notificationDetailsForOrder` are near-identical.
  - The AppLoading show/hide listener is repeated in each screen.
- **Secrets**: no Firebase config, keystore, `.env` or key files are present in the project, and no API keys or tokens are committed in source.
