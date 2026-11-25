# masnaay — Phase 1 analysis

## Summary for comparison

```
PROJECT: masnaay | path: Freelance/masnaay | stack: Flutter (created on stable rev f468f33 ~3.10.x), Dart SDK '>=3.0.5 <4.0.0'; uncommitted 2025 working-tree upgrade makes the lockfile need Flutter >=3.29.3 | last commit: 2024-01-10 (33 commits, first 2023-09-07) + uncommitted dependency/Gradle upgrade from Aug–Sep 2025 | source files: 102 (+3 generated l10n)
ARCH: layer-first MVC-ish ("business_logic / presentation / models / services / constants") — screens call global cubits, and cubits call the static DioHelper directly; no repository, data-source or domain layer
STATE: flutter_bloc Cubit (no base class) — 6 app-wide cubits in MultiBlocProvider (lib/main.dart); `static X get(context)`; empty marker states (no Equatable/data in states), data held in mutable public cubit fields; MyBlocObserver (lib/src/business_logic/bloc_observer.dart)
DI: none — static singletons (DioHelper, CacheHelper, NetworkCheckerHelper, NotificationService) + a global `navigatorKey` in lib/main.dart that cubits use to reach other cubits
ROUTING: Navigator 1.0 onGenerateRoute — lib/src/presentation/router/app_router.dart + app_router_names.dart + BuildContext extension lib/src/constants/navigator_extension.dart — guards: no (guest checks repeated inline) — deep links: no
NETWORK: dio (static) — interceptors: none | token refresh: partial (manual calls inside cubits, not awaited, unbounded recursive retry, BUGGY) | retry: n | error mapping: none (each cubit catches DioException, reads response!.data["Error"][0], toasts or logs, emits XFailure) | lib/src/services/dio_helper.dart, lib/src/constants/end_points.dart
RESULT_TYPE: exceptions (try/catch in every cubit method) — no Failure hierarchy
STORAGE: shared_preferences only (tokens stored in plain prefs) — lib/src/services/cache_helper.dart, keys in lib/src/constants/cache_keys.dart
L10N: flutter gen-l10n (intl ARB) — ar + en, default 'ar' (template app_ar.arb), lib/l10n/*.arb (at HEAD: lib/src/localization/l10n, imported via the removed `flutter_gen` synthetic package), 181 keys wrapped by a BuildContext extension in lib/src/localization/app_strings_extension.dart — hardcoded UI strings: few
RTL: Directional=0 vs LeftRight=82 (manual `context.isAr ? x : y` left/right swapping)
THEME: lib/src/constants/themes.dart — dark mode: wired in AppCubit but ThemeData is empty and toggle is never called (effectively n) | component themes in ThemeData: n | colors class: AppColors (lib/src/constants/colors.dart) | text styles class: none (DefaultText widget) | fonts: Roboto (en) / Cairo (ar), switched by locale in DefaultText; 'Montserrat' referenced but not bundled
RESPONSIVE: flutter_screenutil, designSize ScreenUtil.defaultSize (360x690), minTextAdapt + splitScreenMode — breakpoints: none; `.h` misused for widths/radii and leftover sizer-style defaults (6.h/7.h heights)
TEXT_SCALING: none (no textScaler clamp)
ENV/FLAVORS: hardcoded constants — lib/src/constants/end_points.dart (base URL), plus a second hardcoded base URL inside lib/src/services/dio_helper.dart; no flavors; release build signed with the debug config
LOGGING: debugPrint with ANSI-colour helpers logError/logSuccess/logWarning (lib/src/constants/const_methods.dart) + 4 raw print; full API responses including tokens are logged
ANALYTICS/CRASH: none (runZonedGuarded only logs)
PUSH: none (flutter_local_notifications init only, show methods never called; no FCM) — lib/src/services/notification_service.dart
PAYMENTS/IAP: none
PERMISSIONS: permission_handler — one inline Permission.locationWhenInUse.request() in lib/src/presentation/screens/select_location_screen.dart, result ignored; iOS Info.plist has NO usage descriptions
DEEP_LINKS: none (AndroidManifest <queries> only, for url_launcher)
MEDIA/FILES: image_picker (pickImage helper + PickImageBottomSheet), Image.network (no caching package), flutter_svg, carousel_slider, google_maps_flutter + geolocator + geocoding, syncfusion_flutter_charts, url_launcher
TESTS: 1 — default counter smoke test (stale; would fail)
LINTS: flutter_lints (HEAD ^2.0.0, working tree ^5.0.0), 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/src/constants/navigator_extension.dart — BuildContext nav extension (goTo/goToReplace/goToClearStack/back) — quality 3 — coupling: none
- lib/src/business_logic/bloc_observer.dart — ANSI-coloured BlocObserver — quality 3 — coupling: none
- lib/src/business_logic/app_cubit/app_cubit.dart — locale + theme-mode persistence + connectivity stream cubit — quality 2 — coupling: low (CacheHelper, NetworkCheckerHelper)
- lib/src/services/cache_helper.dart — static SharedPreferences wrapper with type-dispatch save — quality 2 — coupling: none (no List<String>, untyped getter)
- lib/src/constants/const_methods.dart (log*/toast extension/pickImage/formatDateString) — misc helpers — quality 2 — coupling: high (mixed with app-specific category switch functions and LayoutCubit)
- lib/src/services/network_checker_helper.dart — internet_connection_checker wrapper — quality 2 — coupling: none (package is outdated)
- lib/src/services/notification_service.dart — flutter_local_notifications init/show/cancel — quality 2 — coupling: none (placeholder channel IDs, no payload/tap handling)
- lib/src/presentation/router/app_router.dart — onGenerateRoute switch — quality 2 — coupling: high (all screens; unsafe argument casts)
- lib/src/localization/app_strings_extension.dart — context.xxx getters over AppLocalizations + isAr — quality 2 — coupling: low (181 lines of hand-written boilerplate)
- lib/src/services/dio_helper.dart — static Dio GET/POST/PUT/DELETE/download — quality 1 — coupling: low but unsafe (mutates shared headers per call, hardcoded URL, inconsistent headers)
GENERIC_WIDGETS (every reusable widget):
- lib/src/presentation/widgets/default_button.dart — primary button (Material+InkWell) — onTap, text, child, buttonColor, textColor, fontSize, fontWeight, height, width, radius, margin, boxShadow, border — quality 2 — generic? y (no loading/disabled state; default height 6.h is a bug)
- lib/src/presentation/widgets/default_text_field.dart — bordered text field in a Container — controller, hintText, prefix, suffix, obscureText, keyboardType, inputFormatters, maxLines, maxLength, readOnly, enabled, height, width, borderRadius, borderColor, bottomBorder, unfocusOnTapOutside, isCollapsed, … (30+ params) — quality 2 — generic? y (no validator/label/error display; hardcoded 'Montserrat')
- lib/src/presentation/widgets/default_text.dart — Text wrapper with locale-based font + optional onTap — text, textColor, fontSize, fontWeight, fontFamily, textAlign, maxLines, overflow, height, textDecoration, onTap — quality 2 — generic? y (always wraps in InkWell)
- lib/src/presentation/widgets/loading_indicator.dart — CircularProgressIndicator with app colour — color — quality 2 — generic? y
- lib/src/presentation/widgets/response_feedback.dart — success/failure result dialog (SimpleDialog, big icon + text) — text, isSuccess, icon, iconColor — quality 3 — generic? y
- lib/src/presentation/widgets/app_language_dialog.dart — ar/en language picker dialog — none — quality 2 — generic? mostly (AppCubit-coupled; hardcoded ar/en; deprecated RadioListTile groupValue)
- lib/src/presentation/widgets/pick_image_bottom_sheet.dart — gallery/camera picker sheet — selectImage(XFile) — quality 2 — generic? y
- lib/src/presentation/widgets/custom_country_picker_dialog.dart — searchable country/dial-code dialog (country_pickers) — onCountryPicked — quality 2 — generic? y
- lib/src/presentation/widgets/dot.dart — animated page-indicator dot — isActive, height, width, activeColor, color — quality 2 — generic? y (hardcoded right margin, not RTL-aware)
- lib/src/presentation/widgets/layout/ask_guest_login.dart — "login first" inline prompt — none — quality 2 — generic? n (route-coupled)
- lib/src/presentation/widgets/layout/component/bottom_navigation_item.dart — SVG bottom-nav tab with active dot — icon, isActive, onTap — quality 2 — generic? y (deprecated SvgPicture color:)
- lib/src/presentation/widgets/layout/component/contact_item.dart — icon + label tile — label, icon, onTap — quality 2 — generic? y (unused)
- lib/src/presentation/screens/home/drawer.dart (ActionPopUp) — icon + message confirm dialog — icon, color, message, onTap — quality 2 — generic? y (buried in a screen file)
NOTABLE_IDEAS: (1) context navigation extension (lib/src/constants/navigator_extension.dart); (2) String toast extensions `"msg".toToastError()/toToastSuccess()/toToastWarning()` + ToastState enum (lib/src/constants/const_methods.dart, enums.dart); (3) ANSI-coloured log helpers and BlocObserver; (4) locale-dependent font family (Cairo for ar, Roboto for en) chosen centrally in DefaultText; (5) double-back-to-exit on the root tab (lib/src/presentation/screens/layout_screen.dart, needs PopScope); (6) BuildContext l10n getters (context.login, context.isAr); (7) ResponseFeedback success/failure dialog. Nothing here is template-grade as written; these are patterns to re-implement.
SMELLS: OUTDATED — committed deps are Jan-2024 vintage (flutter_bloc 8.1, intl 0.18, flutter_lints 2, flutter_local_notifications 15, geolocator 9, permission_handler 10, carousel_slider 4, syncfusion 23, discontinued flutter_google_places 0.3) and l10n imported via the removed `package:flutter_gen/gen_l10n` synthetic package; an uncommitted 2025 upgrade bumps them but keeps internet_connection_checker 1.0.0+1 (superseded), multi_select_flutter 4.1.3 (unmaintained), and adds google_api_headers (unused). DEPRECATED APIs: WillPopScope x7, Color.withOpacity x21, url_launcher canLaunch/launch x2, Geolocator desiredAccuracy x1, BitmapDescriptor.fromAssetImage x1, SvgPicture color: x1, RadioListTile groupValue x4, `Key? key`/super(key: key) x11, Android Java 1.8 + Groovy Gradle. BUGS: unbounded recursive retry + non-awaited refreshesToken() on ANY error (dashboard_cubit.dart getViewsStatics/getCountsStatics; auth_cubit.dart getProfile on 401); DioHelper mutates shared dio.options.headers per call (races, wrong 'Accept: text/plain' and request 'content-encoding: br'); cubits reach other cubits via navigatorKey.currentState!.context (LayoutCubit even does it in a field initializer); LayoutCubit holds page widgets; mutable globals in const_variables.dart; tokens in SharedPreferences and full login/refresh responses logged with debugPrint (also prints in release); god screens (show_edit_add_service_screen.dart 1506 lines, home_page 783, profile_page 782; 67 setState); duplicated widget classes (SmallMachineComponent x3, CategorySection x2, MachineCard x2); empty ThemeData with all styling inline; 0 directional insets; screenutil `.h` used for horizontal sizes; stale default test; release signed with the debug key; iOS Info.plist missing camera/photo/location usage strings; Google Maps API key committed in platform files
```

---

## 1. Architecture pattern

**Layer-first, MVC-style, no data/domain separation.** `lib/src/` is split by technical role:

- `business_logic/`: one Cubit per area (app, auth, layout/home, service, dashboard, content). Each cubit method builds the request inline, calls `DioHelper` statically, parses JSON into a model, keeps the result in a **mutable public field** on the cubit, and emits an empty marker state (`XLoading` / `XSuccess` / `XFailure`). The states carry no data, so the UI reads `cubit.field` after a rebuild.
- `models/`: hand-written `fromJson`/`toJson` classes with all-nullable fields (json_to_dart style). No codegen, no Equatable.
- `services/`: static helpers for Dio, SharedPreferences, connectivity and local notifications.
- `constants/`: colours, assets, endpoints, cache keys, enums, navigation extension, and a misc `const_methods.dart` (logging, toasts, image picking, date formatting, app-specific category switches).
- `presentation/`: `router/`, `screens/` (grouped by area), `widgets/` (shared widgets).

All six cubits are created at the root in `MultiBlocProvider` and live for the whole app session. There is no repository layer, no DI container and no error abstraction. A "feature" is spread across `business_logic/<x>_cubit/`, `models/` and `presentation/screens/<x>/`.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                         runZonedGuarded bootstrap, MultiBlocProvider (6 cubits), ScreenUtilInit, MaterialApp, global navigatorKey
├── l10n/                             ARB files (app_ar.arb template, app_en.arb) + generated app_localizations*.dart (untracked, generated)
└── src/
    ├── business_logic/               Cubits + states (part files)
    │   ├── bloc_observer.dart        MyBlocObserver (ANSI-coloured debugPrint)
    │   ├── app_cubit/                locale, theme mode, connectivity stream
    │   ├── auth_cubit/               verify phone, OTP, register, login, refresh token, logout, profile get/update
    │   ├── layout_cubit/             bottom-nav index, home sections, ads, featured suppliers, search, service detail; holds page widgets
    │   ├── service_cubit/            supplier, supplier items/reviews, like/unlike, favourites
    │   ├── dashboard_cubit/          seller stats, units/countries/cities/areas, add/edit/delete own service (multipart)
    │   └── content_cubit/            about, terms, contact-us, send request
    ├── constants/
    │   ├── assets.dart               AppAssets (icon/image paths)
    │   ├── cache_keys.dart           CacheKeys (prefs keys)
    │   ├── colors.dart               AppColors (≈35 constants, names like tColor1..7)
    │   ├── const_methods.dart        log helpers, toast extension, showToast, formatDateString, pickImage, app-specific switches
    │   ├── const_variables.dart      mutable globals (address, lat/lng, loading counters)
    │   ├── end_points.dart           EndPoints (base URL + paths)
    │   ├── enums.dart                ToastState
    │   ├── navigator_extension.dart  context.goTo / goToReplace / goToClearStack / back
    │   └── themes.dart               LightTheme / DarkTheme (bare ThemeData(brightness))
    ├── localization/
    │   └── app_strings_extension.dart  supportedLocales/delegates consts + `extension AppStrings on BuildContext` (181 getters, isAr)
    ├── models/                       31 json models (login, register, profile, service(s), supplier*, statics, countries/cities/areas, ...)
    ├── presentation/
    │   ├── router/                   app_router.dart (onGenerateRoute switch), app_router_names.dart
    │   ├── screens/
    │   │   ├── layout_screen.dart        bottom-nav shell + drawer + double-back-exit
    │   │   ├── dashboard_screen.dart     seller dashboard (stats)
    │   │   ├── select_location_screen.dart  Google Map + geolocator + geocoding picker
    │   │   ├── terms_and_conditions_screen.dart
    │   │   ├── start/                splash_screen, on_boarding_screen
    │   │   ├── auth/                 login, signup (phone), otp, register, forgot_password
    │   │   ├── home/                 home_page, suppliers_page, notifications_page, profile_page, drawer
    │   │   ├── service/              service_screen, service_provider_screen, renting_services_screen, add_review_screen
    │   │   ├── dashboard_screens/    my_services, prospective_clients, show_edit_add_service (1506 lines)
    │   │   └── drawer/               about, favorite, settings, help_support, help_screens/{contact_us, send_request}
    │   └── widgets/                  shared widgets (button, text, text field, dialogs, sheet, loader, dot)
    │       └── layout/               ask_guest_login.dart, component/{bottom_navigation_item, contact_item}
    └── services/                     dio_helper, cache_helper, network_checker_helper, notification_service
```

**Example feature, "auth":**
- `business_logic/auth_cubit/auth_cubit.dart` (333 lines) and `auth_state.dart` (≈35 empty state classes)
- `models/verify_phone_model.dart`, `login_model.dart`, `register_model.dart`, `profile_model.dart`, `industries_model.dart`, `interests_model.dart`, `update_profile_model.dart`
- `presentation/screens/auth/signup_screen.dart` (phone entry → `verifyPhone`) → `otp_screen.dart` (`sendOtp`/`verifyOTP`) → `register_screen.dart` (industries/interests multi-select → `register`) → `login_screen.dart` (`login`, saves tokens + `isGuest=false`)
- Screens are StatefulWidgets that own their controllers. They use `BlocConsumer<AuthCubit, AuthState>`: the listener reacts to `XSuccess`/`XFailure` by toasting or navigating, and the builder swaps the button for `LoadingIndicator` on `XLoading`.

## 3. Infrastructure

### State management
- `flutter_bloc` Cubits with no shared base class. Every cubit has `static XCubit get(BuildContext context) => BlocProvider.of(context);`.
- States are `@immutable abstract class XState {}` plus dozens of empty subclasses, with no Equatable and no payload. Data lives in mutable public fields, for example `LayoutCubit.machines` or `AuthCubit.user`.
- Every method repeats the same `emit(Loading) → try { await DioHelper.x().then(...) emit(Success) } on DioException {...} catch {...}` shape. Nothing factors it out, for example into a `handleRequest`.
- Cross-cubit calls go through the global `navigatorKey.currentState!.context`, for example `AuthCubit.get(navigatorKey.currentState!.context).refreshesToken()` in `dashboard_cubit.dart` and `layout_cubit.dart`. `LayoutCubit` even reads `navigatorKey.currentState!.context.all` in a **field initializer**, so it crashes if it is created before the navigator exists.
- `LayoutCubit` stores page widgets (`List<Widget> layoutPages`) and "reload" flags so tabs don't refetch.
- `lib/src/business_logic/bloc_observer.dart` logs onCreate/onChange/onError/onClose in cyan.
- Quality: 1–2/5. Not template material beyond the observer.

### DI
None. Services are static classes initialised in `main()` (`NotificationService.initialize()`, `CacheHelper.init()`, `NetworkCheckerHelper.init()`, `DioHelper.init()`). Cubits are provided globally in `lib/main.dart`.

### Routing
- `lib/src/presentation/router/app_router.dart`: `AppRouter.onGenerateRoutes` is a `switch` over `AppRouterNames` constants and returns `MaterialPageRoute`. Arguments use unchecked casts (`settings.arguments as int`). LoginScreen receives a `ValueKey<int>` through the arguments and reads it later to decide its back behaviour, which is a hack.
- `lib/src/presentation/router/app_router_names.dart`: route constants. Some are unused (`rAddService`, `rEditService`, `rWriteReview`).
- `lib/src/constants/navigator_extension.dart`: `context.goTo/goToReplace/goToClearStack/back`.
- No guards. Guest gating is repeated in screens: `CacheHelper.get(ckIsGuest)` appears in 6 places, followed by `goTo(rLogin)`. No deep links, no unknown-route fallback (`default: return null`).

### Networking
`lib/src/services/dio_helper.dart` is a static `Dio` with `getData`, `postData`, `putData`, `deleteData`, `postDataWithoutParameters`, `downloadMedia`, `verifyPhoneSocial`, `getDataWithBaseUrl` and `getCities`.
- **No interceptors** (no auth, logging, retry or error interceptor).
- Each call **overwrites `dio.options.headers`** on the shared instance. Concurrent requests race on the headers, and the headers are inconsistent: `postData` sends `Accept: text/plain` with Accept-Language commented out, and `putData` sends a request header `content-encoding: br`, which is wrong.
- Bearer token is read from SharedPreferences on every call.
- `getDataWithBaseUrl`/`getCities` build a new `Dio` with a **hardcoded base URL literal** (`{{BASE_URL}}`) that duplicates `EndPoints.baseUrl`.
- Token refresh: `AuthCubit.refreshesToken()` posts the refresh token and saves the new pair. It is called ad hoc:
  - from `SplashScreen` (not awaited, before navigation);
  - from `AuthCubit.getProfile` on 401, followed by an immediate recursive `getProfile()`;
  - from `DashboardCubit.getViewsStatics/getCountsStatics` on **any** exception, followed by an immediate recursive call. This is an **infinite loop when offline**.
- Error mapping: none. Some handlers do `dioError.response!.data["Error"][0]`, which crashes when `response` is null (timeouts or no network).
- `updateProfile` re-downloads the current avatar with a fresh `Dio()` so it can re-upload it when no new image is picked.
- Quality: 1/5. Do not reuse.

### Local storage
`lib/src/services/cache_helper.dart` is a static SharedPreferences wrapper:
- `getDataFromSharedPreference({key})` returns `dynamic`.
- `saveDataSharedPreference({key, value})` dispatches on bool/String/int and falls back to double, so a `List<String>` crashes.
- Also has `removeData` and `clearData`.

Keys are in `lib/src/constants/cache_keys.dart` (lang, dark flag, access/refresh token, firstTime, isGuest). Tokens sit in plain SharedPreferences; there is no secure storage.

### Localization (+RTL)
- Flutter gen-l10n: `l10n.yaml` sets `arb-dir: lib/l10n` (HEAD: `lib/src/localization/l10n`), `template-arb-file: app_ar.arb`, `output-localization-file: app_localizations.dart`. 181 keys in ar and en.
- At HEAD the import was `package:flutter_gen/gen_l10n/app_localizations.dart`. That synthetic package is deprecated and removed in recent Flutter. The uncommitted working tree switched to `package:masnaay/l10n/app_localizations.dart`.
- `lib/src/localization/app_strings_extension.dart` exports `supportedLocales`/`localizationDelegates` and adds one hand-written `context.<key>` getter per key plus `context.isAr`. This is convenient but is 200 lines of manual boilerplate, and it uses `AppLocalizations.of(this)!` each time.
- Locale is persisted by `AppCubit.changeAppLanguage` and defaults to `'ar'`. Dio sends `Accept-Language` from prefs on GET/DELETE only.
- RTL: **0** directional widgets against **82** left/right usages. Direction is flipped manually with `context.isAr ? a : b`, e.g. `EdgeInsets.only(right: context.isAr ? 0 : 8.w, left: context.isAr ? 8.w : 0)` in `login_screen.dart`, and drawer close-button positioning in `layout_screen.dart`. `Dot` has a hardcoded `right: 10` margin.
- Hardcoded UI strings: few (category titles in `home_page.dart`, " (AR)/(EN)" suffixes, placeholder demo data).

### Theming
- `lib/src/constants/themes.dart`: `ThemeData(brightness: light/dark)` with nothing else. No ColorScheme, no component themes, no TextTheme, and no explicit `useMaterial3` choice (so it gets the framework default).
- `AppCubit` persists a dark flag and exposes `toggleTheme()`, but nothing calls it, and every widget uses hardcoded `AppColors`, so dark mode is not functional.
- `lib/src/constants/colors.dart`: `AppColors` holds about 35 `Color` constants with weak names (`tColor1..7`, `yellow2/3`, `background2/3`).
- Typography is done per widget through `DefaultText(fontSize:, fontWeight:, textColor:)`. Font family is picked by locale in `DefaultText` (`Cairo` for ar, `Roboto` otherwise). `DefaultTextField` hardcodes `'Montserrat'`, which is not declared in pubspec.

### Responsive
`flutter_screenutil` 5.9 with `ScreenUtilInit(designSize: ScreenUtil.defaultSize /*360x690*/, minTextAdapt: true, splitScreenMode: true)` in `lib/main.dart`. There are no breakpoints or tablet layouts, and portrait is locked in `main()`. It is misused in places:
- `.h` for horizontal paddings and radii;
- `width: 1000.w, height: 1000.h` on the splash screen;
- default heights `6.h` (DefaultButton) and `7.h` (DefaultTextField). These look like leftovers from the `sizer` package, where `.h` meant percent of screen height; under screenutil they are about 6 logical px. Most callers pass an explicit height, which hides the bug.

### Text scaling
None. There is no `MediaQuery` `textScaler` clamp and no `builder:` on MaterialApp.

### Env / flavors
None. Base URL and image base URL are hardcoded constants in `lib/src/constants/end_points.dart` (`{{BASE_URL}}`), duplicated in `dio_helper.dart`. There is one Android build type, and release uses `signingConfig signingConfigs.debug`.

### Logging
`logError` (red), `logSuccess` (green) and `logWarning` (yellow) are `debugPrint` wrappers with ANSI codes in `lib/src/constants/const_methods.dart`, with 140 call sites, plus 4 raw `print`. The global error handler is `runZonedGuarded(..., (e, s) => logError(...))`. Cubits log complete response bodies, including login/refresh responses that contain tokens. `debugPrint` is not stripped in release builds.

### Analytics / crash reporting
None.

### Push notifications
`lib/src/services/notification_service.dart` wraps `flutter_local_notifications`:
- `initialize()` uses the default launcher icon and requests iOS permissions;
- two hardcoded `AndroidNotificationDetails` channels with placeholder IDs and names ("channelId"/"channelName");
- `showNotification`, `showOrderNotification`, `cancelNotification`.

Nothing calls the show methods, there is no tap/payload handling, and there is no FCM. The uncommitted change removed the `onDidReceiveLocalNotification` param for plugin v18, but the dead handler method is still in the file.

### IAP / payments
None.

### Permissions
`permission_handler` appears only as `await Permission.locationWhenInUse.request();` in `select_location_screen.dart`. The result is ignored, there is no denied/permanently-denied UX, and no check that the location service is enabled before `Geolocator.getCurrentPosition`.
- iOS `Info.plist` contains **no** `NS*UsageDescription` keys, although the app uses camera, photos and location, so App Store review rejects it and the app crashes at runtime.
- AndroidManifest declares location plus legacy READ/WRITE_EXTERNAL_STORAGE.

### Deep links
None. The AndroidManifest `<queries>` block only declares VIEW/DIAL/SEND/SMS intents for url_launcher.

## 4. Services catalog

| File path | Purpose | Public methods | Dependencies | Generic / app-specific |
|---|---|---|---|---|
| lib/src/services/dio_helper.dart | Static HTTP client | `init`, `getData`, `postData`, `putData`, `deleteData`, `postDataWithoutParameters`, `downloadMedia`, `verifyPhoneSocial`, `getDataWithBaseUrl`, `getCities` | dio, CacheHelper, CacheKeys, EndPoints | Mostly generic in shape, but unsafe; `getCities`/`verifyPhoneSocial` are app-specific |
| lib/src/services/cache_helper.dart | SharedPreferences wrapper | `init`, `getDataFromSharedPreference`, `saveDataSharedPreference`, `removeData`, `clearData` | shared_preferences | Generic |
| lib/src/services/network_checker_helper.dart | Connectivity check/stream | `init`, `isNetworkConnected`, `streamNetworkState` | internet_connection_checker 1.0.0+1 | Generic (outdated package) |
| lib/src/services/notification_service.dart | Local notifications | `initialize`, `notificationDetails`, `notificationDetailsForOrder`, `showNotification`, `showOrderNotification`, `cancelNotification`, `onDidReceiveLocalNotification` (dead) | flutter_local_notifications | Generic-ish (placeholder channels) |
| lib/src/business_logic/bloc_observer.dart | Bloc lifecycle logging | `onCreate`, `onChange`, `onError`, `onClose` | bloc | Generic |
| lib/src/business_logic/app_cubit/app_cubit.dart | Locale/theme/connectivity | `initAppCubit`, `changeAppLanguage`, `toggleTheme`, `startNetworkStream`; getters `locale`, `themeMode`, `isDark` | CacheHelper, NetworkCheckerHelper | Generic |
| lib/src/constants/const_methods.dart | Misc helpers | `logError`, `logSuccess`, `logWarning`, `String.isValidEmail`, `String.toToastError/Success/Warning`, `showToast`, `formatDateString`, `pickImage`, plus app-specific `cateName`, `cateNameByEnTitle`, `requestTypeName`, `arabicDayNames`, `cateList` | fluttertoast, image_picker, intl, LayoutCubit, AppStrings | Mixed (generic helpers next to app logic) |
| lib/src/constants/navigator_extension.dart | Navigation sugar on BuildContext | `back`, `goTo`, `goToReplace`, `goToClearStack` | flutter | Generic |
| lib/src/constants/cache_keys.dart | Prefs key constants | (consts) | — | Generic pattern |
| lib/src/constants/end_points.dart | Base URL + endpoint paths | (consts) | — | App-specific |
| lib/src/constants/colors.dart | `AppColors` palette | (consts) | flutter | App-specific values |
| lib/src/constants/assets.dart | `AppAssets` paths | (consts) | — | App-specific |
| lib/src/constants/themes.dart | Light/Dark ThemeData | `LightTheme.lightTheme`, `DarkTheme.darkTheme` | flutter | Generic but empty |
| lib/src/constants/enums.dart | `ToastState` | — | — | Generic |
| lib/src/constants/const_variables.dart | Mutable globals | (vars) | — | App-specific, anti-pattern |
| lib/src/localization/app_strings_extension.dart | l10n getters on BuildContext | `isAr` + 181 getters, `supportedLocales`, `localizationDelegates` | gen-l10n output | Pattern generic, content app-specific |
| lib/src/presentation/router/app_router.dart | Route factory | `onGenerateRoutes` | all screens | App-specific |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/src/presentation/widgets/default_button.dart | Filled/outlined button via Material+InkWell | `onTap`*, `text`*, `child`, `buttonColor`, `textColor`, `fontSize`, `fontWeight`, `textAlign`, `height` (default 6.h, a bug), `width` (default ∞), `radius` (10), `margin`, `boxShadow`, `border` | y (no loading/disabled) |
| lib/src/presentation/widgets/default_text_field.dart | Container-decorated TextFormField with all input borders off | `controller`*, `hintText`, `prefix`, `suffix`, `suffixIconConstraints`, `obscureText`, `keyboardType`, `textInputAction`, `inputFormatters`, `maxLines`, `maxLength`, `readOnly`, `enabled`, `onTap`, `onChanged`, `textAlign`, `textColor`, `fontSize`, `fontWeight`, `hintTextColor/FontSize/FontWeight`, `height` (7.h), `width`, `padding`, `margin`, `color`, `border`, `borderColor`, `borderRadius`, `bottomBorder`, `boxShadow`, `alignVertical`, `unfocusOnTapOutside`, `isCollapsed` | y (no validator, label or error text) |
| lib/src/presentation/widgets/default_text.dart | Text with defaults + locale font + tap | `text`*, `textColor`, `fontSize` (15), `fontWeight` (w500), `fontFamily`, `textAlign`, `textDirection`, `maxLines`, `overflow`, `height`, `textDecoration`, `onTap` | y |
| lib/src/presentation/widgets/loading_indicator.dart | Coloured spinner | `color` | y |
| lib/src/presentation/widgets/response_feedback.dart | Success/failure dialog | `text`*, `isSuccess`, `icon`, `iconColor` | y |
| lib/src/presentation/widgets/app_language_dialog.dart | Language picker dialog (ar/en radios + confirm) | — | partly (AppCubit/CacheHelper-coupled) |
| lib/src/presentation/widgets/pick_image_bottom_sheet.dart | Gallery/camera chooser sheet | `selectImage(XFile)`* | y |
| lib/src/presentation/widgets/custom_country_picker_dialog.dart | Searchable country + dial-code dialog | `onCountryPicked(Country)`* | y |
| lib/src/presentation/widgets/dot.dart | Animated pager dot | `isActive`*, `height`, `width`, `activeColor`, `color` | y (not RTL-aware) |
| lib/src/presentation/widgets/layout/ask_guest_login.dart | "You need to login first" + login link | — | n |
| lib/src/presentation/widgets/layout/component/bottom_navigation_item.dart | SVG tab with active dot | `icon`*, `onTap`*, `isActive`, `rotate` (unused) | y |
| lib/src/presentation/widgets/layout/component/contact_item.dart | Icon + label column | `label`*, `icon`*, `onTap`*, `rotate` (unused) | y (unused in app) |
| lib/src/presentation/screens/home/drawer.dart → `ActionPopUp` | Icon + message dialog | `message`*, `icon`, `color`, `onTap` | y (misplaced) |
| lib/src/presentation/screens/home/drawer.dart → `DrawerItemBuilder` | Drawer row | (app-specific) | n |
| lib/src/presentation/screens/dashboard_screens/show_edit_add_service_screen.dart → `ServiceTextField` | Titled read/edit field | `title`*, `editText`*, `height`*, `controller`, `hintText`, `readOnly`, `suffix`, `prefix`, `onTap`, `radius`, `maxLines`, `width`, `keyboardType` | partly |
| screens/home/home_page.dart, drawer/favorite_screen.dart, service/renting_services_screen.dart → `SmallMachineComponent` (x3), `CategorySection` (x2), `MachineCard` (x2) | Domain cards, duplicated across files | — | n |

There are no shimmer/skeleton, empty-state, error-state, network-image, pagination-list, app-bar, base-scaffold or snackbar widgets. Toasts go through `fluttertoast` via `showToast` and the String extensions.

## 6. Packages

Versions are shown as **HEAD (Jan 2024)** → **uncommitted working tree (2025)**. Lockfile-resolved versions are in parentheses where read.

| Role | Packages |
|---|---|
| State | flutter_bloc ^8.1.3 → ^9.1.1 (9.1.1); bloc ^8.1.2 → ^9.0.0 |
| DI | — |
| Routing | — (Navigator 1.0) |
| Network | dio ^5.3.2 (5.9.0); internet_connection_checker ^1.0.0+1 (**outdated**, superseded by v3 / `_plus`) |
| Storage | shared_preferences ^2.2.0 |
| L10n | flutter_localizations (sdk), intl ^0.18.0 → ^0.20.2 |
| UI | flutter_svg ^2.0.7, flutter_screenutil ^5.9.0 (5.9.3), fluttertoast ^8.2.2, pin_code_fields ^7.4.0 → ^8.0.1, carousel_slider ^4.1.1 → ^5.1.1, animated_bottom_navigation_bar ^1.2.0, flutter_rating_bar ^4.0.1, multi_select_flutter ^4.1.3 (**unmaintained**), country_pickers ^2.0.0 → ^3.0.1, syncfusion_flutter_charts ^23.1.36 → ^30.1.42 (commercial licence), cupertino_icons ^1.0.2 (unused) |
| Maps / location | google_maps_flutter ^2.5.0 (2.12.3), geolocator ^9.0.2 → ^14.0.1, geocoding ^2.0.5 → ^4.0.0, permission_handler ^10.2.0 → ^12.0.1; HEAD only: flutter_google_places ^0.3.0 (**discontinued**), maps_toolkit ^2.0.1; working tree only: google_api_headers ^4.4.2 (unused) |
| Firebase | — |
| Notifications | flutter_local_notifications ^15.1.0+1 → ^18.0.1 |
| Media | image_picker ^1.0.4 (1.2.0), url_launcher ^6.1.12 (6.3.2) |
| Dev | flutter_test, flutter_lints ^2.0.0 → ^5.0.0, flutter_launcher_icons ^0.13.1 → ^0.14.4 |

Fonts bundled: Roboto (12 static weights) and Cairo (variable).

## 7. Quality notes

- **Age / outdatedness (oldest project, flagged explicitly):**
  - Created on Flutter stable rev `f468f33` (~3.10.x, mid-2023). Last commit 2024-01-10.
  - The committed tree uses the removed `flutter_gen` synthetic l10n package and Jan-2024 majors of flutter_bloc/intl/geolocator/permission_handler/local_notifications/carousel/syncfusion, plus the discontinued `flutter_google_places`. It probably does not build on current Flutter without the uncommitted changes.
  - The uncommitted working tree (2025) bumps packages and the Android toolchain (AGP 8.6.0, Gradle 8.10.2, Kotlin 1.9.25, compile/target SDK 35, minSdk 24). It still targets Java 1.8, uses Groovy `build.gradle`, and the iOS Podfile has no platform set.
- **Deprecated APIs in source:**
  - `WillPopScope` ×7, should be `PopScope`
  - `Color.withOpacity` ×21, should be `withValues(alpha:)`
  - `canLaunch`/`launch` ×2 (`help_support_screen.dart`, `service_screen.dart`)
  - `Geolocator.getCurrentPosition(desiredAccuracy:)`, should use `locationSettings:`
  - `BitmapDescriptor.fromAssetImage`, should be `BitmapDescriptor.asset`
  - `SvgPicture.asset(color:)` in `bottom_navigation_item.dart`, should be `colorFilter`
  - `RadioListTile(groupValue:)` ×4, should be `RadioGroup` (Flutter 3.32+)
  - old `Key? key` + `super(key: key)` constructors ×11
  - dead `onDidReceiveLocalNotification` (iOS <10 API removed in plugin v18)
- **Null safety:** enabled (Dart 3). Heavy `!` use on `navigatorKey.currentState!`, `dioError.response!` and `AppLocalizations.of(this)!`. `isGuest = CacheHelper.get(...)` is assigned to a non-null `bool` without a default.
- **Lints:** `analysis_options.yaml` only includes `package:flutter_lints/flutter.yaml` and adds no rules.
- **Tests:** `test/widget_test.dart` is the untouched counter template and would fail.
- **Smells:**
  - Unbounded recursive retry loops and non-awaited token refresh.
  - Shared-header mutation in DioHelper.
  - Cubits reaching each other through `navigatorKey`.
  - Widgets stored in a cubit.
  - Mutable top-level globals.
  - Tokens in SharedPreferences, with full token responses logged.
  - God screens (1506/783/782 lines; 67 `setState`).
  - Duplicated card widgets across three files.
  - Empty ThemeData with every colour and style inline.
  - No directional insets.
  - screenutil axis misuse.
  - Release signed with debug key.
  - Missing iOS usage descriptions.
  - Unused deps (`google_api_headers`, `cupertino_icons`) and dead helpers (`downloadMedia`, `verifyPhoneSocial`, `postDataWithoutParameters`, `getDataWithBaseUrl`, `startNetworkStream`, `toggleTheme`, notification `show*`).
- **Secrets:** a Google Maps API key is committed in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`, and it is also present in git history. Value not reproduced here. None of the ignored secret files (`.env`, `google-services.json`, `key.properties`, keystores) exist in the project.
- **Template verdict:** low value as a source. Worth porting as ideas only: the navigation extension, the toast String-extension pattern, the coloured log helpers and BlocObserver, the locale-dependent font selection, and the ResponseFeedback / PickImageBottomSheet / CountryPicker dialogs. Rewrite them on top of a proper ThemeData and directional insets.
