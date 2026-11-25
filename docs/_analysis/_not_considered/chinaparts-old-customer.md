# chinaparts-old-customer — Phase 1 analysis

> Legacy (2025) customer app, rewritten later in `Chinaparts/New Projects/customer`. The code is a
> lightly-customised copy of the 6valley multi-vendor e-commerce customer app (Provider + GetIt +
> DioClient/ApiResponse pattern, `utill/`, `view/basewidget/`). The coverage below is mostly about infra and widgets;
> features get a short pass.

## Summary for comparison

```
PROJECT: chinaparts-old-customer | path: Chinaparts/Old Projects/Chinaparts Customer | stack: Flutter, Dart SDK ^3.5.1 (no FVM pin) | last commit: 2025-06-16 (1 commit, "initial commit" re-init copy) + uncommitted edits (pubspec mtime 2025-07-29) | source files: 338
ARCH: layer-first MVC/MVVM-ish (6valley template) — lib/data (DioClient + models + 28 repos returning ApiResponse) → lib/provider (43 ChangeNotifiers) → lib/view/screen/<feature> + lib/view/basewidget; one feature (home/car_selection) keeps its own repo/models/controller under view/
STATE: provider ChangeNotifier (no base class) — 33 ChangeNotifierProviders in lib/main.dart; each method: isLoading flag → repo → `statusCode == 200` check → parse → else ApiChecker.checkApi; results often returned via callback(bool, msg...)
DI: get_it (`sl`) — lib/di_container.dart (repos lazySingleton, providers registerFactory)
ROUTING: Navigator 1.0 imperative MaterialPageRoute (217 Navigator.* calls), global MyApp.navigatorKey — lib/main.dart — guards: no (inline isLoggedIn + GuestDialog) — deep links: no (notification-launch payload opens OrderDetailsScreen as home)
NETWORK: dio 5 + http (MultipartRequest in 3 repos, Tap Payments client) — interceptors: LoggingInterceptor (print, logs headers incl. Bearer) | token refresh: n | retry: n | error mapping: ApiErrorHandler.getMessage (DioException → String or ErrorResponse) + validateStatus <500 so 4xx arrive as "success" and providers check statusCode; ApiChecker swallows errors (print only) | lib/data/datasource/remote/dio/dio_client.dart, logging_interceptor.dart, lib/data/datasource/remote/exception/api_error_handler.dart, lib/helper/api_checker.dart
RESULT_TYPE: wrapper ApiResponse(response, dynamic error) — lib/data/model/response/base/api_response.dart + error_response.dart (no Failure hierarchy; dartz declared but unused)
STORAGE: shared_preferences only, used raw inside repos (token, plaintext user_password, cart, config, addresses) — no wrapper; flutter_secure_storage declared but unused
L10N: custom JSON-asset LocalizationsDelegate + getTranslated(key, context) — en, ar (479/475 keys), default en (AppConstants.languages[0]), assets/language/*.json — lib/localization/app_localization.dart, language_constrants.dart — hardcoded UI strings: some (86 literal Text('..') vs ~600 getTranslated)
RTL: Directional=2 vs LeftRight=163 (manual `isLtr` swaps ×10, arrow_back_ios hardcoded)
THEME: lib/theme/light_theme/light_theme.dart + lib/theme/dark_theme/dark_theme.dart — dark mode y (ThemeProvider toggle in settings; dark theme minimal, unbundled 'TitilliumWeb' font, different primary) | component themes in ThemeData: partial (textButton, navigationBar, FAB, pageTransitions; no appBar/elevated/input) | colors class: ColorResources (lib/utill/color_resources.dart, context→ThemeProvider light/dark pairs) + ColorScheme | text styles class: lib/utill/font_styles.dart (cairoRegular10…cairoBold57) + legacy lib/utill/custom_themes.dart | fonts: Cairo (+Ubuntu bundled)
RESPONSIVE: none (MediaQuery.size fractions ×106, Dimensions constants in lib/utill/dimensions.dart; flutter_screenutil declared but unused) — breakpoints: none
TEXT_SCALING: none (one Text with TextScaler.linear(1) in lib/view/screen/home/home_screens.dart)
ENV/FLAVORS: hardcoded constants — lib/utill/app_constants.dart (BASE_URL + commented alternates, IMAGE_BASE_URL, all endpoints, pref keys); no flavors/dotenv
LOGGING: print (165) + dart:developer log (45) + `logging` Logger with ANSI colours (lib/utill/myLogger.dart; package only transitive); talker declared but unused; auth token printed in DioClient ctor
ANALYTICS/CRASH: none (firebase_core present, Firebase.initializeApp commented out)
PUSH: fcm + flutter_local_notifications — lib/notification/my_notification.dart (NotificationService) — NOT wired (init commented in main, FCM token getter commented → backend receives "nothing")
PAYMENTS/IAP: Tap Payments via direct REST from the client (http) + webview_flutter redirect sniffing — lib/data/repository/payment_gateway_repo.dart (TapPaymentService, LIVE secret key in source); call site commented out in this copy's checkout; backend offline/wallet payment; 6valley payment WebView lib/view/screen/payment/payment_screen.dart; no IAP
PERMISSIONS: permission_handler (one Permission.storage.request in lib/view/screen/order/widget/order_details_widget.dart) + inline geolocator requests in lib/view/screen/address/add_new_address_screen.dart
DEEP_LINKS: none (manifest <queries> for url_launcher only)
MEDIA/FILES: image_picker, cached_network_image, FadeInImage, photo_view, flutter_svg, carousel_slider, flutter_downloader (invoice), google_maps_flutter + geolocator + geocoding + google_places_flutter, webview_flutter + flutter_inappwebview, flutter_html/flutter_widget_from_html, url_launcher
TESTS: 1 — default counter smoke test (stale, would fail)
LINTS: includes package:flutter_lints/flutter.yaml but flutter_lints is NOT a dependency (include unresolved), 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/view/basewidget/animated_custom_dialog.dart — showAnimatedDialog (scale-in or 3D flip) + Rotation3DTransition — quality 3 — coupling: none
- lib/localization/app_localization.dart + lib/localization/language_constrants.dart — JSON-asset LocalizationsDelegate + getTranslated (falls back to key) — quality 3 — coupling: low (AppConstants.languages)
- lib/utill/extensions/context_ex.dart — BuildContext theme/textTheme/colorScheme getters — quality 3 — coupling: none
- lib/theme/light_theme/light_text_theme.dart + lib/utill/font_styles.dart — M3 TextTheme roles mapped to named Cairo styles — quality 3 — coupling: none
- lib/helper/custom_delegate.dart — FallbackLocalizationDelegate (Material l10n for any locale) — quality 2 — coupling: none
- lib/data/datasource/remote/exception/api_error_handler.dart — DioExceptionType → message / ErrorResponse — quality 2 — coupling: low (6valley error JSON; badCertificate/connectionError cases return "")
- lib/data/model/response/base/error_response.dart — {errors:[{code,message}]} parser tolerating List or Map — quality 2 — coupling: low
- lib/data/model/response/base/api_response.dart — ApiResponse.withSuccess/withError — quality 2 — coupling: none (dynamic error)
- lib/data/datasource/remote/dio/dio_client.dart — Dio wrapper (get/post/put/delete, updateHeader token+lang) — quality 2 — coupling: low (reads prefs in ctor, lang header derived from country code, prints token)
- lib/provider/localization_provider.dart — persisted locale + isLtr + pushes lang header to DioClient — quality 2 — coupling: low (DioClient)
- lib/provider/theme_provider.dart — persisted dark-mode flag — quality 2 — coupling: none
- lib/utill/myLogger.dart — `logging` root listener with ANSI colours — quality 2 — coupling: none (undeclared dependency)
- lib/helper/date_converter.dart — intl format/parse helpers — quality 2 — coupling: none (`hh` without am/pm in parse = bug)
- lib/helper/network_info.dart — connectivity check + online/offline snackbar listener — quality 1 — coupling: low (isConnected compares List to enum → always true)
- lib/notification/my_notification.dart — FCM foreground→local notification service — quality 1 — coupling: none (not wired, private background handler without vm:entry-point, Android-only init)
GENERIC_WIDGETS (every reusable widget):
- lib/view/basewidget/button/custom_button.dart — primary button (TextButton+Container, 45 h, shadow) — onTap, buttonText, isBuy, isBorder, backgroundColor, foregroundColor, style, radius, border (borderRadius/horizontalMargin unused) — quality 2 — generic? y
- lib/view/basewidget/button/back_button.dart — back icon button — color (positional) — quality 2 — generic? y (shadows Material BackButton, not RTL-aware)
- lib/view/basewidget/textfield/custom_textfield.dart — text field (floating label, shadow, phone digits mode) + String.isValidEmail() — controller, hintText, textInputType, maxLine, focusNode, nextNode, textInputAction, isPhoneNumber, isValidator, validatorMessage, fillColor, capitalization, isBorder — quality 2 — generic? y
- lib/view/basewidget/textfield/custom_password_textfield.dart — password field with visibility toggle — controller, hintTxt, focusNode, nextNode, textInputAction — quality 2 — generic? y
- lib/view/basewidget/custom_search_text_field.dart — search text field — hintText, controller, focusNode, nextFocus, inputType, inputAction, isPassword, onChanged, onSubmit, isEnabled, maxLines, prefixIcon/suffixIcon (asset), fillColor — quality 2 — generic? y
- lib/view/basewidget/custom_search_widget.dart — AnimSearchBar (vendored anim_search_bar) — width, textController, onSuffixTap, rtl, autoFocus, style, helpText, color, prefix/suffixIcon, inputFormatters — quality 3 — generic? y
- lib/view/basewidget/search_widget.dart — search header bound to SearchProvider — hintText, onTextChanged, onClearPressed, onSubmit, isSeller — quality 1 — generic? n (controller created in build)
- lib/view/basewidget/app_bar.dart — CustomizedAppBar (PreferredSizeWidget) — title, isBackButtonExist, color, iconColor, textColor (height unused) — quality 2 — generic? y
- lib/view/basewidget/custom_app_bar.dart — Stack app bar over toolbar image — title, isBackButtonExist, icon, onActionPressed, onBackPressed, isHomeScreen — quality 2 — generic? n (ThemeProvider, asset)
- lib/view/basewidget/custom_expanded_app_bar.dart — scaffold with curved header + guest gate — title, child, bottomChild, isGuestCheck — quality 2 — generic? n (AuthProvider, SplashProvider)
- lib/view/basewidget/custom_image.dart — FadeInImage.assetNetwork with placeholder — image, height, width, fit, placeholder (fit/placeholder ignored) — quality 1 — generic? y
- lib/view/basewidget/custom_loader.dart — rotating-square spinner (SpinKit port) — color, size, itemBuilder, duration, controller — quality 3 — generic? y
- lib/view/basewidget/animated_custom_dialog.dart — animated dialog presenter — context, dialog, isFlip, dismissible — quality 3 — generic? y
- lib/view/basewidget/show_custom_modal_dialog.dart — Cupertino confirm dialog sliding from top — title, content, cancel/submit callbacks + texts — quality 3 — generic? y
- lib/view/basewidget/show_custom_snakbar.dart — snackbar/toast helper — message, context, isError, isToaster (toast always red) — quality 2 — generic? y
- lib/view/basewidget/my_dialog.dart — result dialog with floating icon badge + OK — isFailed, rotateAngle, icon, title, description — quality 3 — generic? y
- lib/view/basewidget/dialog/single_text_alertdialog.dart — one-line message dialog — message — quality 2 — generic? y
- lib/view/basewidget/dialog/alert_dialog.dart — PaymentStatusDialog — status, isSuccess — quality 2 — generic? n (English literals, double pop)
- lib/view/basewidget/guest_dialog.dart — "login required" dialog — none — quality 2 — generic? n (AuthScreen)
- lib/view/basewidget/image_diaglog.dart — zoomable image dialog (PhotoView + CachedNetworkImageProvider) — imageUrl — quality 3 — generic? y
- lib/view/basewidget/no_internet_screen.dart — empty / no-internet state with retry — isNoInternet, child — quality 2 — generic? y (connectivity check bug)
- lib/view/basewidget/not_loggedin_widget.dart — login/register CTA state — none — quality 2 — generic? n
- lib/view/basewidget/product_shimmer.dart — 2-col product grid shimmer — isEnabled, isHomePage (unused) — quality 2 — generic? partly
- lib/view/basewidget/shimmer_loading.dart — LoadingPage list shimmer — none — quality 2 — generic? y
- lib/view/basewidget/rating_bar.dart — read-only star bar with partial star — rating, size — quality 2 — generic? y (off-by-one `i < realNumber`)
- lib/view/basewidget/amount_widget.dart — label/value row — title, amount — quality 2 — generic? y
- lib/view/basewidget/title_row.dart — section header with countdown + "view all" — title, icon, onTap, eventDuration, isDetailsPage, isFlash — quality 2 — generic? n
- lib/view/basewidget/product_widget.dart — product card with add-to-cart — productModel — quality 2 — generic? n
- lib/view/screen/home/widget/marque_text.dart — MarqueeWidget auto-scroll — child, direction, durations — quality 3 — generic? y
- lib/view/screen/dashboard/widget/fancy_bottom_nav_bar.dart — vendored fancy_bottom_navigation — tabs, onTabChangedListener, colors, initialSelection — quality 2 — generic? y
- lib/view/screen/address/widget/custom_field_with_title.dart — title + required star wrapper — customTextField, title, requiredField, isPadding, limitSet… — quality 2 — generic? y
- lib/view/screen/tracking/painter/line_dashed_painter.dart — dashed line CustomPainter — none — quality 2 — generic? y
NOTABLE_IDEAS: 3D-flip dialog transition (lib/view/basewidget/animated_custom_dialog.dart); FallbackLocalizationDelegate for locales Material doesn't ship (lib/helper/custom_delegate.dart); locale change pushes the `lang` header into the HTTP client (lib/provider/localization_provider.dart → DioClient.updateHeader); ErrorResponse that accepts `errors` as List or Map (lib/data/model/response/base/error_response.dart); cold-start from a local-notification payload goes straight to OrderDetailsScreen (lib/main.dart); M3 TextTheme role table with size comments (lib/theme/light_theme/light_text_theme.dart); ThemeX context extension (lib/utill/extensions/context_ex.dart)
SMELLS: global HttpOverrides accepting every TLS certificate (lib/main.dart) + FlutterDownloader ignoreSsl:true; LIVE Tap secret key and direct Tap API calls in the client (lib/data/repository/payment_gateway_repo.dart); Google API keys hardcoded in 3 Dart files; plaintext password in SharedPreferences (lib/data/repository/auth_repo.dart); token and full headers/bodies printed (also in release); validateStatus<500 + scattered statusCode checks; ApiChecker swallows errors (print only); NetworkInfo List-vs-enum bug; CategoryProvider provided twice, and TabBarProviderHome (lazySingleton) holds a different FreeShippingProviderHome instance than the tree; god files (home_screens.dart 1243 lines, checkout_screen.dart 1068, cart_bottom_sheet.dart 841); barrel lib/utill/exports/home_screen_export.dart re-exports screens+providers+packages; WillPopScope ×6, withOpacity ×63, Provider.of ×695, 146 Color(0x..) literals; ~15 unused deps (go_router, flutter_bloc, dartz, talker*, easy_localization, screenutil, secure_storage, skeletonizer, freezed, pull_to_refresh, flutter_typeahead, searchable_listview, easy_logger) while `logging`/`intl` are used but undeclared, and rename_app is a runtime dep; enum `.index` shadowed (lib/utill/extensions/enums_ex.dart); empty JsonConverter; typos in folder/file names (utill, language_constrants, image_diaglog, show_custom_snakbar)
```

## 1. Architecture pattern

**Layer-first, 6valley-style MVC/MVVM with Provider.** Every backend area has the same vertical slice spread over
three top-level folders:

| Layer | Folder | What it contains |
|---|---|---|
| Data | `lib/data/datasource/remote/` | `DioClient` (single shared Dio), `LoggingInterceptor`, `ApiErrorHandler` |
| Data | `lib/data/model/body`, `lib/data/model/response` | hand-written `fromJson`/`toJson` models (no codegen), private fields + getters (6valley style) |
| Data | `lib/data/repository/` | 28 `XRepo` classes; each method wraps one endpoint in `try { ApiResponse.withSuccess(resp) } catch (e) { ApiResponse.withError(ApiErrorHandler.getMessage(e)) }` |
| Presentation-logic | `lib/provider/` | 43 `ChangeNotifier`s (30 top-level + 13 under home/; 2 more live in view/screen/home/controller); hold lists/flags, call repos, parse JSON, notify; some take `BuildContext` and show snackbars |
| UI | `lib/view/screen/<feature>/` + `widget/` | Stateful/Stateless screens using `Provider.of`/`Consumer` |
| Shared UI | `lib/view/basewidget/` | buttons, fields, dialogs, shimmer, app bars |
| Cross-cutting | `lib/helper/`, `lib/utill/`, `lib/localization/`, `lib/theme/`, `lib/notification/` | converters, constants, l10n, theme |

There is no domain layer, no use cases, no interfaces. Repos get `DioClient` (and sometimes `SharedPreferences`)
through GetIt. Providers are registered as factories in GetIt and created once by `ChangeNotifierProvider` in
`main.dart`.

One deviation: the car-selection feature that ChinaParts added has its own mini-slice inside the view tree
(`lib/view/screen/home/car_selection_screen/{models,repository}` + `lib/view/screen/home/controller/car_selection_provider.dart`).

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                 bootstrap: logger, HttpOverrides (accept-all certs), native splash, portrait lock,
│                             FlutterDownloader, GetIt init, notification-launch payload, MultiProvider(33), MaterialApp
├── di_container.dart         GetIt `sl`: NetworkInfo, TapPaymentService, DioClient, 28 repos, ~40 providers, prefs, Dio
├── data/
│   ├── datasource/remote/
│   │   ├── dio/              dio_client.dart, logging_interceptor.dart
│   │   └── exception/        api_error_handler.dart
│   ├── model/
│   │   ├── body/             8 request bodies (login, register, order_place, review, support ticket, userinfo…)
│   │   └── response/         ~36 response models + base/{api_response,error_response}.dart, response_model.dart
│   └── repository/           28 repos (auth, cart, order, product, splash/config, location, payment_gateway…)
├── helper/                   api_checker, custom_delegate, date_converter, email_checker, json_converter (empty),
│                             network_info, price_converter, product_type (enum)
├── localization/             app_localization.dart (JSON delegate), language_constrants.dart (getTranslated)
├── notification/             my_notification.dart (FCM + local notifications service, not wired)
├── provider/                 30 ChangeNotifiers (+13 under home/)
│   └── home/
│       ├── sub_cat_providers/   7 per-tab product providers (all/best/free-shipping/offers/top-rated…)
│       └── tab_bar_Providers/   6 home tab providers (all/coupons/discounts/free_shipping/popular + aggregator)
├── theme/
│   ├── light_theme/          light_theme.dart, light_color_scheme, light_text_theme, light_navbar_theme,
│   │                         floating_action_button_theme, light_page_transition
│   └── dark_theme/           dark_theme.dart, dark_color_scheme.dart
├── utill/                    app_constants, color_resources, custom_themes, dimensions, font_styles, images, myLogger
│   ├── constants/            icons.dart (AppIcons svg paths)
│   ├── exports/              home_screen_export.dart (60-line barrel: screens, providers, packages)
│   └── extensions/           context_ex.dart (ThemeX), enums_ex.dart (HomeTabBarIndex)
└── view/
    ├── basewidget/           22 widgets + button/ (2) + dialog/ (2) + textfield/ (2)
    └── screen/               31 feature folders
```

Feature folders (file counts): address(12) auth(13) brand(1) cart(2) category(1) chat(8) checkout(6) dashboard(2)
featureddeal(1) flashdeal(1) helpcenter(1) home(36) loyaltyPoint(4) maintenance(1) more(6) notification(2) offer(1)
onboarding(1) order(13) payment(1) product(20) profile(2) search(3) seller(1) setting(3) splash(2) support(4)
topSeller(2) tracking(3) wallet(3) wishlist(2).

Representative slice, **wishlist** (spread across the layers):
```
lib/data/model/response/wishlist_model.dart
lib/data/repository/wishlist_repo.dart          → dioClient.get/post(AppConstants.WISH_LIST_GET_URI …) → ApiResponse
lib/provider/wishlist_provider.dart             → WishListProvider(wishListRepo, productDetailsRepo)
lib/view/screen/wishlist/wishlist_screen.dart
lib/view/screen/wishlist/widget/wishlist_widget.dart
```
`home/` is the largest feature: `home_screens.dart` (1243 lines), `widget/` (26 section widgets: banners, brands,
flash deals, tab bar views…), `categories_list_screen/`, `products_list_screen/`, `car_selection_screen/`, `controller/`.

## 3. Infrastructure

### State management
- `provider ^6.0.3`, plain `ChangeNotifier` (`with ChangeNotifier`), no base class or state objects.
- Typical method (`lib/provider/auth_provider.dart`): set `_isLoading`, `notifyListeners()`, `await repo.x()`, then
  `if (apiResponse.response != null && statusCode == 200) { parse map; callback(true, …) } else { error is String ? … : ErrorResponse.errors[0].message; callback(false, …) }`.
  Parsing uses `try { token = map['token']; } catch (e) {}`.
- Providers often take `BuildContext` and call `ApiChecker.checkApi` or `showCustomSnackBar` from inside.
- 695 `Provider.of<…>` calls and 150 `Consumer`/`context.read/watch` calls. Rebuilds are coarse.
- `flutter_bloc`, `equatable` and `dartz` are declared, but only `equatable` is used, in 1 model.

### DI
- `get_it ^7.2.0`, `lib/di_container.dart`, global `sl`. Repos are `registerLazySingleton`, providers are
  `registerFactory` (each `ChangeNotifierProvider(create: (_) => sl<X>())` makes one instance).
- Problems: `CategoryProvider` is provided twice in `main.dart`. `DiscountsProviderHome` and `TabBarProviderHome`
  are lazy singletons, but `TabBarProviderHome` gets a *new* factory `FreeShippingProviderHome` that is not the one
  in the widget tree. `TapPaymentService` is registered next to "Core" infra.

### Routing
- Navigator 1.0 only: `Navigator.push(context, MaterialPageRoute(builder: …))` throughout (217 calls). No named
  routes, no route table.
- `MyApp.navigatorKey` is global. `home:` is `SplashScreen`, or `OrderDetailsScreen` when the app was launched from
  a local-notification tap (`getNotificationAppLaunchDetails` payload = order id).
- Guards: none. Screens check `AuthProvider.isLoggedIn()` inline and show `GuestDialog` / `NotLoggedInWidget`.
- `go_router ^14.6.2` is declared but unused.

### Networking
- **Client:** `lib/data/datasource/remote/dio/dio_client.dart`, `DioClient(baseUrl, Dio, loggingInterceptor, sharedPreferences)`.
  The constructor reads the token and country code from prefs and sets JSON headers, `Authorization: Bearer`
  and a `lang` header (country `US` → `en`, else the lower-cased country code). It sets 30 s timeouts,
  `followRedirects=false`, and `validateStatus: status < 500`, so 4xx responses come back as normal responses.
  `get/post/put/delete` only re-throw. `updateHeader(token, countryCode)` replaces the whole header map and drops
  `Accept`. `AuthRepo.saveAuthToken` writes `dio.options.headers` directly and also drops the `lang` header.
- **Interceptors:** `LoggingInterceptor` (print-based, chunked at 200 chars) logs method, base URL+path, all
  headers (Bearer token included) and full bodies. It is not gated by `kDebugMode`.
- **Second HTTP stack:** `package:http` handles `MultipartRequest` uploads in `profile_repo.dart`, `order_repo.dart`
  (refund) and `product_details_repo.dart` (review), and the Tap Payments REST calls. These requests bypass Dio
  headers and logging and rebuild the auth header by hand.
- **Error mapping:** `lib/data/datasource/remote/exception/api_error_handler.dart` turns `DioExceptionType` into an
  English string. For `badResponse` it returns `statusMessage` (404/500/503) or a parsed `ErrorResponse`.
  `badCertificate`/`connectionError` are TODO and return `""`. Because of `validateStatus`, most 4xx never get here.
  Providers check `statusCode == 200` themselves.
- `lib/helper/api_checker.dart`: if `errors[0].message == 'Unauthorized.'` it clears addresses and auth data (the
  navigation is commented out). Otherwise it only prints, because the snackbar is commented out.
- Token refresh: no. Retry: no. Cancel tokens: passed through but unused.
- Security: `MyHttpOverrides` in `main.dart` sets `badCertificateCallback = (…) => true` globally, and
  `FlutterDownloader.initialize(ignoreSsl: true)`.

### Local storage
- `shared_preferences` is used raw inside repos and providers. Keys are in `AppConstants`: token, user,
  user_email, **user_password (plaintext, remember-me in `auth_repo.dart`)**, cart_list, config, guest_mode,
  currency, lang, intro, theme, addresses, plus `tap_customer_id`.
- There is no wrapper class. `flutter_secure_storage` is declared but unused.

### Localization (+RTL)
- Custom delegate `lib/localization/app_localization.dart` loads `assets/language/{languageCode}.json` into a
  `Map<String,String>`. `translate` falls back to the key. `getTranslated(key, context)` is in
  `lib/localization/language_constrants.dart`.
- Languages come from `AppConstants.languages`: en_US (default) and ar_SA. Keys: en 479, ar 475.
- `FallbackLocalizationDelegate` (`lib/helper/custom_delegate.dart`) returns `DefaultMaterialLocalizations` for any locale.
- `LocalizationProvider` persists language/country codes, exposes `isLtr` (`!= 'ar'`) and calls
  `dioClient.updateHeader(null, countryCode)`.
- RTL: Directional=2 vs LeftRight=163. Arabic layout depends on Flutter's automatic mirroring plus about 10
  `isLtr ? … : …` swaps. Many `EdgeInsets.only(left:)`, `Alignment.centerRight` and `Icons.arrow_back_ios`
  are hardcoded.
- Hardcoded strings: ~86 literal `Text('…')` (payment dialog, error handler messages, debug text) vs ~600
  `getTranslated` calls.
- `easy_localization` is declared but unused.

### Theming
- Light: `lib/theme/light_theme/light_theme.dart` sets primary `0xFFfa660a`, font Cairo, `lightColorScheme`
  (custom slots such as `inverseSurface=grey` and `onSecondaryContainer=coupon colour`), `lightTextTheme`
  (`light_text_theme.dart`, every M3 role mapped to a named Cairo style from `lib/utill/font_styles.dart`),
  `TextButtonThemeData`, `NavigationBarThemeData`, `FloatingActionButtonThemeData` and Zoom page transitions.
  There are no AppBar, ElevatedButton or InputDecoration themes, so widgets style themselves.
- Dark: `lib/theme/dark_theme/dark_theme.dart` is minimal: a different primary (`0xFFEE3923`), font `'TitilliumWeb'`
  (not bundled) and `ColorScheme.dark`. It is toggled by `ThemeProvider.toggleTheme()` in `settings_screen.dart`.
- `lib/utill/color_resources.dart` (343 lines) has ~60 `static Color getX(BuildContext)` returning light/dark pairs
  via `Provider.of<ThemeProvider>`. `lib/utill/custom_themes.dart` holds the legacy `titilliumRegular`/`robotoBold`
  constants, all with the Cairo family.
- `withOpacity` ×63, 146 `Color(0x…)` literals.

### Responsive helpers
None. Sizes come from `lib/utill/dimensions.dart` constants and `MediaQuery.of(context).size` fractions (106 uses).
`flutter_screenutil` is declared but unused. No breakpoints. Portrait is locked in `main.dart`.

### Text scaling
No global clamp. One `textScaler: TextScaler.linear(1)` in `lib/view/screen/home/home_screens.dart`.

### Env / flavors
Hardcoded in `lib/utill/app_constants.dart`: `BASE_URL` (with commented alternates), `IMAGE_BASE_URL`,
`IMAGE_BASE_CAR_URL`, ~130 endpoint constants, pref keys, order-status strings. No flavors and no dotenv. The
Tap base URL and keys are hardcoded in `payment_gateway_repo.dart`.

### Logging
`print` (165), `dart:developer log` (45), and `logger` from `lib/utill/myLogger.dart` (`package:logging` root
listener with ANSI colour per level; `logging` is only a transitive dependency). `talker_flutter` and
`talker_dio_logger` are declared but unused. The auth token is printed in the `DioClient` constructor.

### Analytics / crash reporting
None. `firebase_core` is a dependency, but `Firebase.initializeApp()` is commented out. Config files exist by
name only: `ios/Runner/GoogleService-Info.plist`, `.firebaserc`, `firebase.json`.

### Push notifications
`lib/notification/my_notification.dart` has a `NotificationService` with static `initialize()` (Android-only
init, `requestPermission`, `onMessage` → `flutterLocalNotificationsPlugin.show`, `onBackgroundMessage`,
`getInitialMessage`). Two older versions are left commented out below it. It is **not wired**: the initialize
calls in `main.dart` are commented, and `AuthRepo._getDeviceToken` has the FCM calls commented out, so the
backend receives `"nothing"`. The background handler is private and has no `@pragma('vm:entry-point')`.
Tapping a local notification is handled in `main.dart`.

### IAP / payments
- `lib/data/repository/payment_gateway_repo.dart` → `TapPaymentService`: calls the Tap Payments REST API
  directly from the app with `package:http`. It creates/verifies a customer (id cached in prefs as
  `tap_customer_id`, country dial code hardcoded), creates a charge, opens the redirect URL in a
  `webview_flutter` page, sniffs `redirectUrl`, retrieves the charge status and shows `PaymentStatusDialog`.
  **A live secret key is embedded in the client.**
- In this copy the checkout call (`createCustomerTappyOrder`/`createTappyOrder`) is commented out and orders
  are placed directly. Offline payment and wallet payment use backend endpoints. The 6valley digital-payment
  WebView is in `lib/view/screen/payment/payment_screen.dart`. No IAP.

### Permissions
`permission_handler`: a single `Permission.storage.request()` before the invoice download in
`lib/view/screen/order/widget/order_details_widget.dart`. Location permission is handled inline with
`Geolocator` in `lib/view/screen/address/add_new_address_screen.dart`. No helper class.

### Deep links
None. `AndroidManifest.xml` has `<queries>` for https/tel/sms (url_launcher) and the Facebook login scheme.

## 4. Services catalog

| File | Purpose | Public methods | Dependencies | Generic / app-specific |
|---|---|---|---|---|
| lib/data/datasource/remote/dio/dio_client.dart | Dio wrapper | `get`, `post`, `put`, `delete`, `updateHeader(token, countryCode)`, fields `dio`, `token`, `countryCode` | dio, SharedPreferences, AppConstants, LoggingInterceptor | generic-ish (6valley headers) |
| lib/data/datasource/remote/dio/logging_interceptor.dart | print logger | `onRequest/onResponse/onError` | dio | generic (unsafe: logs tokens) |
| lib/data/datasource/remote/exception/api_error_handler.dart | error → message | `static getMessage(error)` | dio, ErrorResponse | generic-ish |
| lib/data/model/response/base/api_response.dart | result wrapper | `withSuccess`, `withError` | dio | generic |
| lib/data/model/response/base/error_response.dart | backend error model | `fromJson`, `toJson`, `errors` | — | 6valley-specific shape |
| lib/data/model/response/response_model.dart | (message, isSuccess) | getters | — | generic |
| lib/data/repository/payment_gateway_repo.dart | Tap Payments client (`TapPaymentService`) | `getOrCreateCustomer`, `createCustomer`, `createCharge`, `retrievePaymentStatus`, `clearCustomerId`, `storedCustomerId` | http, webview_flutter, SharedPreferences, OrderProvider, dialogs | app-specific; insecure |
| lib/helper/api_checker.dart | central API error reaction | `static checkApi(context, apiResponse)` | ProfileProvider, AuthProvider | app-specific |
| lib/helper/network_info.dart | connectivity | `isConnected`, `static checkConnectivity(context)` | connectivity_plus, getTranslated | generic (buggy) |
| lib/helper/custom_delegate.dart | Material l10n fallback | `FallbackLocalizationDelegate` | — | generic |
| lib/helper/date_converter.dart | date formatting | `formatDate`, `estimatedDate`, `convertStringToDatetime`, `isoStringToLocalDate`, `localDateToIsoStringAMPM`, `isoStringToLocalTimeOnly`, `isoStringToLocalDateOnly`, `localDateToIsoString`, `isoStringToLocalDateAndTime` | intl | generic |
| lib/helper/price_converter.dart | currency conversion + discount math | `convertPrice(context, price, {discount, discountType})`, `convertWithDiscount`, `calculation`, `percentageCalculation` | SplashProvider (currencies), LocalizationProvider | app-specific (6valley config) |
| lib/helper/email_checker.dart | email regex | `static isNotValid(email)` | — | generic |
| lib/helper/product_type.dart | enum of product lists | — | — | app-specific |
| lib/helper/json_converter.dart | empty class | — | — | dead |
| lib/localization/app_localization.dart | JSON LocalizationsDelegate | `of(context)`, `load()`, `translate(key)`, `delegate` | rootBundle, AppConstants.languages | generic |
| lib/localization/language_constrants.dart | translate helper | `getTranslated(key, context)` | AppLocalization | generic |
| lib/notification/my_notification.dart | FCM + local notifications | `static initialize()`, `onNotificationTap` | firebase_messaging, flutter_local_notifications | generic (unwired) |
| lib/provider/localization_provider.dart | locale state | `setLanguage(locale, index)`, `locale`, `isLtr`, `languageIndex` | SharedPreferences, DioClient | generic-ish |
| lib/provider/theme_provider.dart | dark-mode flag | `toggleTheme()`, `darkTheme` | SharedPreferences | generic |
| lib/utill/app_constants.dart | URLs, endpoints, pref keys, statuses, languages | constants | LanguageModel | app-specific |
| lib/utill/color_resources.dart | light/dark colour getters | ~60 `static getX(context)` + constants | ThemeProvider | app-specific |
| lib/utill/dimensions.dart | font/padding/margin/icon sizes | constants | — | generic |
| lib/utill/font_styles.dart | named Cairo TextStyles (10–57) | constants | Dimensions | generic |
| lib/utill/custom_themes.dart | legacy titillium*/roboto* styles (Cairo) | constants | Dimensions | legacy |
| lib/utill/images.dart, lib/utill/constants/icons.dart | asset paths | constants | — | app-specific |
| lib/utill/myLogger.dart | logging setup | `myLoggerInit()`, `logger`, `formatLog` | logging | generic |
| lib/utill/extensions/context_ex.dart | `context.theme/textTheme/colorScheme` | getters | — | generic |
| lib/utill/extensions/enums_ex.dart | HomeTabBarIndex + `.index` override | — | — | app-specific (smell) |
| lib/utill/exports/home_screen_export.dart | barrel file | — | ~60 exports | app-specific (smell) |
| lib/di_container.dart | GetIt registrations | `init()`, `sl` | everything | app-specific |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/view/basewidget/button/custom_button.dart | primary button | onTap, buttonText, isBuy, isBorder, border, backgroundColor, foregroundColor, style, radius, borderRadius*, horizontalMargin* (*unused) | y |
| lib/view/basewidget/button/back_button.dart | back icon | color | y |
| lib/view/basewidget/textfield/custom_textfield.dart | text field + email ext | controller, hintText, textInputType, maxLine, focusNode, nextNode, textInputAction, isPhoneNumber, isValidator, validatorMessage, fillColor, capitalization, isBorder, textAlign | y |
| lib/view/basewidget/textfield/custom_password_textfield.dart | password field | controller, hintTxt, focusNode, nextNode, textInputAction | y |
| lib/view/basewidget/custom_search_text_field.dart | search field | hintText, controller, focusNode, nextFocus, inputType, inputAction, isPassword, onChanged, onSubmit, isEnabled, maxLines, capitalization, prefixIcon, suffixIcon, suffix, fillColor | y |
| lib/view/basewidget/custom_search_widget.dart | animated expanding search bar | width, textController, onSuffixTap, suffixIcon, prefixIcon, helpText, color, animationDurationInMilli, rtl, autoFocus, style, closeSearchOnSuffixTap, inputFormatters | y |
| lib/view/basewidget/search_widget.dart | search header | hintText, onTextChanged, onClearPressed, onSubmit, isSeller | n |
| lib/view/basewidget/app_bar.dart | simple AppBar | title, isBackButtonExist, color, height, iconColor, textColor | y |
| lib/view/basewidget/custom_app_bar.dart | image-backed app bar | title, isBackButtonExist, icon, onActionPressed, onBackPressed, isHomeScreen | n |
| lib/view/basewidget/custom_expanded_app_bar.dart | curved header scaffold + guest gate | title, child, bottomChild, isGuestCheck | n |
| lib/view/basewidget/custom_image.dart | network image + placeholder | image, height, width, fit, placeholder | y |
| lib/view/basewidget/custom_loader.dart | custom spinner | color, size, itemBuilder, duration, controller | y |
| lib/view/basewidget/animated_custom_dialog.dart | `showAnimatedDialog` + `Rotation3DTransition` | context, dialog, isFlip, dismissible | y |
| lib/view/basewidget/show_custom_modal_dialog.dart | Cupertino confirm dialog | title, content, cancelOnPressed, submitOnPressed, cancelButtonText, submitButtonText | y |
| lib/view/basewidget/show_custom_snakbar.dart | snackbar/toast | message, context, isError, isToaster | y |
| lib/view/basewidget/my_dialog.dart | result dialog | isFailed, rotateAngle, icon, title, description | y |
| lib/view/basewidget/dialog/single_text_alertdialog.dart | message dialog | message | y |
| lib/view/basewidget/dialog/alert_dialog.dart | payment result dialog | status, isSuccess | n |
| lib/view/basewidget/guest_dialog.dart | login-required dialog | — | n |
| lib/view/basewidget/image_diaglog.dart | zoom image dialog | imageUrl | y |
| lib/view/basewidget/no_internet_screen.dart | no-internet / no-data state | isNoInternet, child | y |
| lib/view/basewidget/not_loggedin_widget.dart | not-logged-in state | — | n |
| lib/view/basewidget/product_shimmer.dart | grid shimmer | isEnabled, isHomePage | partly |
| lib/view/basewidget/shimmer_loading.dart | list shimmer | — | y |
| lib/view/basewidget/rating_bar.dart | star rating | rating, size | y |
| lib/view/basewidget/amount_widget.dart | label/value row | title, amount | y |
| lib/view/basewidget/title_row.dart | section header + countdown | title, icon, onTap, eventDuration, isDetailsPage, isFlash | n |
| lib/view/basewidget/product_widget.dart | product card | productModel | n |
| lib/view/screen/home/widget/marque_text.dart | marquee scroller | child, direction, animationDuration, backDuration, pauseDuration | y |
| lib/view/screen/dashboard/widget/fancy_bottom_nav_bar.dart | animated bottom nav (vendored) | tabs, onTabChangedListener, colors, initialSelection, key | y |
| lib/view/screen/address/widget/custom_field_with_title.dart | field + title + required star | customTextField, title, requiredField, isPadding, isSKU, limitSet, setLimitTitle, onTap | y |
| lib/view/screen/checkout/widget/custom_check_box.dart | payment-method radio row | index, isDigital, icon | n |
| lib/view/screen/tracking/painter/line_dashed_painter.dart | dashed line painter | — | y |
| lib/view/screen/auth/widget/code_picker_widget.dart | vendored country-code picker | many (country_code_picker port) | y |
| lib/view/screen/chat/widget/message_bubble.dart | chat bubble | message | n |

## 6. Packages (pubspec.yaml)

| Role | Packages |
|---|---|
| State | provider ^6.0.3; flutter_bloc ^8.1.6 (unused); equatable ^2.0.7 (1 use) |
| DI | get_it ^7.2.0 |
| Routing | go_router ^14.6.2 (unused) |
| Network | dio ^5.4.3+1, http ^1.2.2, connectivity_plus ^6.0.5, talker_dio_logger ^4.6.0 (unused) |
| Result | dartz ^0.10.1 (unused), freezed ^2.0.3+1 (listed as runtime dep, unused, no build_runner) |
| Storage | shared_preferences ^2.0.5, flutter_secure_storage ^9.2.4 (unused), path_provider ^2.0.1 |
| L10n | flutter_localizations (sdk), easy_localization ^3.0.7 (unused); intl only transitive |
| UI | cupertino_icons, fancy_bottom_navigation ^0.3.3, carousel_slider ^5.0.0, flutter_staggered_grid_view ^0.7.0, staggered_grid_view_flutter ^0.0.4, shimmer ^3.0.0, skeletonizer ^1.4.3 (unused), flutter_svg ^2.0.9, marquee ^2.2.1, flutter_rating_bar ^4.0.0, flutter_spinkit ^5.2.1, badges ^3.1.2, flutter_search_bar ^3.0.0, searchable_listview ^2.15.2 (unused), dropdown_search ^5.0.6, flutter_typeahead ^5.2.0 (unused), pull_to_refresh 2.0.0 (unused), gap ^3.0.1, flutter_animate ^4.5.0, fluttertoast ^8.0.9, flutter_screenutil ^5.9.3 (unused), pin_code_fields ^8.0.1, country_code_picker ^3.0.0, country_currency_pickers ^3.0.0, phone_number ^2.1.0, flutter_native_splash ^2.4.3 |
| HTML/Web | flutter_html ^3.0.0-beta.2, flutter_html_table ^3.0.0-alpha.3, flutter_widget_from_html ^0.15.0, flutter_widget_from_html_core ^0.15.1, webview_flutter ^4.10.0, flutter_inappwebview ^6.0.0 |
| Firebase / push | firebase_core ^3.8.1, firebase_messaging ^15.1.6 (init disabled), flutter_local_notifications ^17.1.1 |
| Auth | google_sign_in ^6.2.2, flutter_facebook_auth ^7.0.1, sms_autofill ^2.4.1 |
| Maps | google_maps_flutter ^2.6.1, geocoding ^3.0.0, geolocator ^12.0.0, google_places_flutter ^2.0.8 |
| Media | image_picker ^1.1.1, cached_network_image ^3.4.1, photo_view ^0.15.0, flutter_downloader ^1.11.8, url_launcher ^6.0.2 |
| Utils | permission_handler ^11.3.1, universal_platform ^1.0.0+1, easy_logger ^0.0.2 (unused), talker_flutter ^4.6.0 (unused), rename_app ^1.6.1 (dev tool as runtime dep) |
| Overrides | modal_bottom_sheet (git fork) |
| Dev | flutter_test, icons_launcher ^2.0.6 (flutter_lints missing) |

The block from easy_localization to flutter_secure_storage at the end of `dependencies` looks like it was
pasted from the user's starter template. None of it is used.

## 7. Quality notes
- **Null safety:** yes (SDK ^3.5.1), but `!` is used heavily (`configModel!`, `error.response!`, `errors![0]`), and
  JSON is parsed with `try { … } catch (e) {}`.
- **Lints:** `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`, but `flutter_lints` is not in
  `dev_dependencies` or the lockfile, so the include does not resolve. No extra rules.
- **Tests:** 1 default counter test that would fail.
- **Security (critical):** accept-all TLS `HttpOverrides`; live Tap Payments secret key and direct Tap API calls
  in `lib/data/repository/payment_gateway_repo.dart`; Google API keys in 3 Dart files plus the manifest; plaintext
  password in prefs; tokens and headers printed in release builds. Secret files exist by name:
  `android/app/upload-keystore.jks`, `ios/Runner/GoogleService-Info.plist`.
- **Bugs:** `NetworkInfo.isConnected` and `NoInternetOrDataScreen` compare `List<ConnectivityResult>` to
  `ConnectivityResult.none` (always "connected"). `RatingBar` draws one star short. `DateConverter.formatDate`
  and `convertStringToDatetime` use `hh` without `a`. `CustomImage` ignores `fit` and `placeholder`.
  `updateHeader`/`saveAuthToken` drop the `Accept`/`lang` headers. `HomeTabBarIndex` redefines `.index`.
- **Duplication:** three app-bar widgets, two search fields plus `AnimSearchBar`, `custom_themes.dart` vs
  `font_styles.dart`, `ColorResources` vs `ColorScheme`, light/dark primary constants defined twice.
- **God files:** `home_screens.dart` 1243 lines, `product_model.dart` 1142, `checkout_screen.dart` 1068,
  `config_model.dart` 946, `cart_bottom_sheet.dart` 841.
- **Deprecated APIs:** `WillPopScope` ×6, `withOpacity` ×63. `Color(0x…)` literals ×146.
- **Dependency hygiene:** ~15 unused packages. `logging` and `intl` are imported but only transitive.
  `freezed` and `rename_app` sit in runtime dependencies.
- **Template value:** low. Worth keeping as ideas: `showAnimatedDialog` / `Rotation3DTransition`,
  `FallbackLocalizationDelegate`, the JSON delegate concept and `light_text_theme.dart`. The networking and
  state layers should not be reused.
