# chinaparts-old-customer-v0 — Phase 1 analysis (short: near-duplicate)

> Earlier git-tracked version of `chinaparts-old-customer`. 328 of 338 `lib/` files are byte-identical, so this
> report has only the Summary and the differences. For architecture, infra, services, widgets and quality notes,
> see `chinaparts-old-customer.md`. Everything there applies here except what is listed below.

## Summary for comparison

```
PROJECT: chinaparts-old-customer-v0 | path: Chinaparts/Old Projects/china-parts-customer | stack: Flutter, Dart SDK ">=2.12.0 <3.0.0" (stale constraint; deps such as connectivity_plus 6 need Dart 3) | last commit: 2025-02-18 (54 commits since 2024-08-28) + uncommitted edits (pubspec/lock mtime 2025-06-29) | source files: 338
ARCH: layer-first MVC/MVVM-ish (6valley template) — identical to chinaparts-old-customer: lib/data (DioClient + 28 repos → ApiResponse) → lib/provider (43 ChangeNotifiers) → lib/view/screen + lib/view/basewidget
STATE: provider ChangeNotifier (no base class) — 33 ChangeNotifierProviders in lib/main.dart; repo → statusCode==200 check → parse → ApiChecker.checkApi
DI: get_it (`sl`) — lib/di_container.dart
ROUTING: Navigator 1.0 imperative MaterialPageRoute, global MyApp.navigatorKey — lib/main.dart — guards: no — deep links: no
NETWORK: dio 5 + http (multipart, Tap) — interceptors: LoggingInterceptor (print; logs path + headers incl. Bearer) | token refresh: n | retry: n | error mapping: ApiErrorHandler.getMessage + validateStatus<500 + per-provider statusCode checks | lib/data/datasource/remote/dio/dio_client.dart, logging_interceptor.dart, lib/data/datasource/remote/exception/api_error_handler.dart, lib/helper/api_checker.dart
RESULT_TYPE: wrapper ApiResponse(response, dynamic error) — lib/data/model/response/base/api_response.dart + error_response.dart (no Failure hierarchy)
STORAGE: shared_preferences raw in repos (token, plaintext password, cart, config) — no wrapper
L10N: custom JSON-asset LocalizationsDelegate + getTranslated — en, ar (479/475 keys), default en, assets/language/*.json — lib/localization/ — hardcoded UI strings: some (86 literal Text)
RTL: Directional=2 vs LeftRight=163
THEME: lib/theme/light_theme/light_theme.dart + lib/theme/dark_theme/dark_theme.dart — dark mode y (minimal) | component themes: partial (textButton/navBar/FAB/pageTransitions) | colors class: ColorResources (lib/utill/color_resources.dart) | text styles: lib/utill/font_styles.dart + lib/utill/custom_themes.dart | fonts: Cairo (+Ubuntu)
RESPONSIVE: none (MediaQuery fractions + lib/utill/dimensions.dart) — breakpoints: none
TEXT_SCALING: none (one TextScaler.linear(1) in home_screens.dart)
ENV/FLAVORS: hardcoded constants — lib/utill/app_constants.dart
LOGGING: print (164) + dart:developer log (44) + `logging` Logger (lib/utill/myLogger.dart)
ANALYTICS/CRASH: none (Firebase init commented out)
PUSH: fcm + flutter_local_notifications — lib/notification/my_notification.dart — not wired (same as primary)
PAYMENTS/IAP: Tap Payments direct REST from client + webview — lib/data/repository/payment_gateway_repo.dart (LIVE secret key in source) — ACTIVE in checkout here (lib/view/screen/checkout/checkout_screen.dart); offline/wallet via backend; no IAP
PERMISSIONS: permission_handler (storage, invoice download) + inline geolocator
DEEP_LINKS: none
MEDIA/FILES: image_picker, cached_network_image, photo_view, flutter_svg, flutter_downloader, google_maps_flutter + geolocator + geocoding + google_places_flutter, webview_flutter + flutter_inappwebview, url_launcher
TESTS: 1 — default counter smoke test (stale)
LINTS: includes flutter_lints/flutter.yaml without the dependency (unresolved), 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- same files and ratings as chinaparts-old-customer (byte-identical); lib/data/datasource/remote/dio/logging_interceptor.dart differs trivially (does not print baseUrl or err.error)
GENERIC_WIDGETS (every reusable widget):
- same as chinaparts-old-customer (lib/view/basewidget/* byte-identical except lib/view/basewidget/product_widget.dart, which is app-specific)
NOTABLE_IDEAS: none beyond chinaparts-old-customer; prefer the primary
SMELLS: same as chinaparts-old-customer, plus the stale `sdk: ">=2.12.0 <3.0.0"` constraint, a null-crash in product_widget.dart (`rating![0].average!`) and in product_provider.dart (assumes the list payload is always a List)
```

## Differences from chinaparts-old-customer

**Provenance.** This folder has the real git history: 54 commits from 2024-08-28 to 2025-02-18 (the last few are
category/sub-sub-category screen work). `Chinaparts Customer` is a single-commit re-init dated 2025-06-16, with
later uncommitted edits. So `Chinaparts Customer` is the *newer* code and this is the predecessor.

**pubspec.yaml**
- `environment.sdk: ">=2.12.0 <3.0.0"` here, `^3.5.1` in the primary.
- No unused "template block" at the end of `dependencies`. The primary adds easy_localization,
  flutter_screenutil, dartz, flutter_bloc, go_router, talker_flutter, talker_dio_logger, flutter_secure_storage
  and moves `flutter_native_splash` to ^2.4.3. Here it is `flutter_native_splash ^2.4.1`, and the rest is the same.

**lib/ — 10 files differ, none added or removed**

| File | v0 (this project) | Primary |
|---|---|---|
| lib/data/datasource/remote/dio/logging_interceptor.dart | logs `METHOD path` only, no `err.error` line | also logs baseUrl and `err.error` |
| lib/utill/app_constants.dart | different active `BASE_URL` (one fewer commented alternate) | switched base URL |
| lib/provider/product_provider.dart | brand/category products: `data.forEach(Product.fromJson)`, assumes a List | handles `data['data']` as List or Map |
| lib/provider/splash_provider.dart | loop variable `currencyList` | renamed to `currency` (no behaviour change) |
| lib/view/basewidget/product_widget.dart | `rating![0].average!` (can throw) | `average ?? "0"` |
| lib/view/screen/auth/widget/code_picker_widget.dart | formatting only | formatting only |
| lib/view/screen/auth/widget/sign_in_widget.dart | one hardcoded URL literal differs | — |
| lib/view/screen/checkout/checkout_screen.dart | **Tap card flow active**: `createCustomerTappyOrder()` then `createTappyOrder(... placeOrderCallback: placeOrder)` | Tap flow commented out; `placeOrder` is called directly; extra logs |
| lib/view/screen/product/product_details_screen.dart | also loads the seller's product list (`initSellerProductList`) after details | removed |
| lib/view/screen/product/widget/bottom_cart_view.dart | always shows the seller/chat section | only when `product.addedBy == 'seller'` |

**Same secrets and security issues as the primary:** the Tap live key is in
`lib/data/repository/payment_gateway_repo.dart` (byte-identical), and Google API keys are in
`lib/data/repository/location_repo.dart`, `lib/view/screen/address/select_location_screen.dart`,
`lib/view/screen/address/widget/location_search_dialog.dart` and `android/app/src/main/AndroidManifest.xml`.
Here the Tap secret key is actually used at checkout. Secret files exist by name:
`android/app/upload-keystore.jks`, `ios/Runner/GoogleService-Info.plist`.

**Counts:** RTL Directional=2 / LeftRight=163, print 164, log 44, withOpacity 63, WillPopScope 6,
Color(0x 146. All within ±1 of the primary.

**Recommendation for the template:** nothing unique to take. Use `chinaparts-old-customer`, which has the
slightly safer parsing and null handling.
