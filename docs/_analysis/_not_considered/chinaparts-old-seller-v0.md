# chinaparts-old-seller-v0 — Phase 1 analysis (short: near-duplicate)

> Earlier version of `chinaparts-old-seller`. They share git history from 2024-08-28, and 184 `lib/` files are
> byte-identical. This report has only the Summary and the differences. For the live 6valley Provider layer
> (architecture, infra, services, widgets, quality), see `chinaparts-old-seller.md`. Everything said there about
> the **live** layer applies here. The dormant `lib/core` / `lib/core_features` clean-architecture layer does
> **not exist** in this project.

## Summary for comparison

```
PROJECT: chinaparts-old-seller-v0 | path: Chinaparts/Old Projects/china-parts-seller | stack: Flutter, Dart SDK ^3.5.1; .fvmrc pins Flutter 3.19.0 | last commit: 2025-02-25 (78 commits since 2024-08-28) + uncommitted edits (config_model, app_constants, code_picker_widget, Gradle) | source files: 258
ARCH: layer-first 6valley MVC — lib/data (DioClient + 22 repos → ApiResponse) → lib/provider (27 ChangeNotifiers) → lib/features/screens/<feature> + lib/features/base; no clean-arch layer
STATE: provider ChangeNotifier (27 in MultiProvider, lib/main.dart, no base class) — repo → statusCode==200 → parse → ApiChecker.checkApi
DI: get_it (`sl`) — lib/di_container.dart
ROUTING: Navigator 1.0 imperative MaterialPageRoute (126 Navigator.* calls), MyApp.navigatorKey — lib/main.dart — guards: no — deep links: no
NETWORK: dio 5 (+http MultipartRequest in 6 files) — interceptors: LoggingInterceptor (print, logs headers) | token refresh: n | retry: n | error mapping: ApiErrorHandler.getMessage → string / ErrorResponse; ApiChecker detects 401 by string compare | lib/data/datasource/remote/dio/dio_client.dart, logging_interceptor.dart, lib/data/datasource/remote/exception/api_error_handler.dart, lib/helper/api_checker.dart
RESULT_TYPE: wrapper ApiResponse(response, dynamic error) — lib/data/model/response/base/api_response.dart + error_response.dart (no Failure hierarchy)
STORAGE: shared_preferences raw in repos (token, plaintext password+phone) + static SharedPrefsManager (lib/data/datasource/local/shared_preferences.dart, init not awaited)
L10N: custom JSON-asset delegate + getTranslated (null→key) — en, ar (866/862 keys), default en (AppConstants.languages[0]), assets/language/*.json — lib/localization/ — hardcoded UI strings: few (17 literal Text)
RTL: Directional=14 vs LeftRight=41
THEME: lib/theme/light_theme/light_theme.dart (Cairo, orange primary) + lib/theme/dark_theme/dark_theme.dart — dark mode n in practice (no toggle) | component themes: partial (textButton, navigationBar) | colors class: ColorResources (lib/utils/color_resources.dart) | text styles: lib/utils/font_styles.dart + lib/utils/styles.dart | fonts: Cairo, Ubuntu
RESPONSIVE: none (lib/utils/dimensions.dart constants) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants — lib/utils/app_constants.dart
LOGGING: print (84) + `logging` Logger (lib/utils/myLogger.dart)
ANALYTICS/CRASH: none
PUSH: none
PAYMENTS/IAP: none
PERMISSIONS: permission_handler + geolocator — lib/helper/permissions_helper.dart
DEEP_LINKS: none
MEDIA/FILES: image_picker, cached_network_image, flutter_svg, google_maps_flutter + geolocator + Google Geocoding REST (lib/helper/location_helper.dart, key hardcoded), flutter_colorpicker, url_launcher, skeletonizer
TESTS: 1 — default counter smoke test (stale)
LINTS: flutter_lints ^4.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/features/base/paginated_list_view.dart — scroll-end offset paginator — quality 3 — coupling: none (identical to primary)
- lib/helper/permissions_helper.dart — location permission + settings dialogs — quality 2 — coupling: low (getTranslated) (identical)
- lib/data/datasource/local/shared_preferences.dart — static typed prefs manager — quality 2 — coupling: none (identical)
- lib/data/datasource/remote/dio/dio_client.dart — Dio wrapper + downloadImage — quality 2 — coupling: low (identical)
- lib/helper/price_converter.dart — currency conversion/discount helpers (only here) — quality 2 — coupling: high (SplashProvider config)
- all other infra files: same as chinaparts-old-seller live layer
GENERIC_WIDGETS (every reusable widget):
- lib/features/base/* — same 15 as chinaparts-old-seller (see that report), plus these defined-but-unused ones only here:
- lib/features/base/confirmation_dialog.dart — confirm dialog with optional note field — icon, title, description, onYesPressed, isLogOut, refund, color, note — quality 2 — generic? y
- lib/features/base/custom_divider.dart — dashed divider (LayoutBuilder) — height, color — quality 3 — generic? y
- lib/features/base/custom_field_with_title.dart — field + title + required star — customTextField, title, requiredField, isPadding, isSKU, limitSet, setLimitTitle, onTap, isCoupon — quality 2 — generic? y
- lib/features/base/custom_header.dart — tinted header with image + title — title, headerImage — quality 2 — generic? y
- lib/features/base/custom_search_field.dart — search row with filter action — controller, hint, prefix, iconPressed, onSubmit, onChanged, filterAction, isFilter — quality 2 — generic? y
- lib/features/base/custom_search_widget.dart — AnimSearchBar (vendored anim_search_bar) — width, textController, onSuffixTap, onChanged, rtl, autoFocus, helpText, color… — quality 3 — generic? y
- lib/features/base/rating_bar.dart — RatingBarIndicator (vendored flutter_rating_bar) — itemBuilder, rating, itemCount, itemSize, direction, unratedColor, textDirection — quality 3 — generic? y
- lib/features/base/product_shimmer.dart — product grid shimmer — isEnabled — quality 2 — generic? partly
- lib/features/base/custom_delegate.dart — SliverDelegate (pinned header) — child/height — quality 2 — generic? y
- lib/features/base/custom_bottom_sheet.dart — icon+title tile for bottom sheets — image, title, isProfile, onTap — quality 2 — generic? n
- lib/features/base/custom_edit_dialog.dart — withdraw-balance dialog — none — quality 1 — generic? n
- lib/features/base/see_more_button.dart — "see more" link — none — quality 1 — generic? n
NOTABLE_IDEAS: none beyond chinaparts-old-seller; the vendored RatingBarIndicator and dashed CustomDivider are the only extra reusable pieces
SMELLS: same as chinaparts-old-seller live layer, plus lib/utils/app_constants.dart importing providers (NotificationsSettingsProvider, QuestionsAnswersProvider) into constants, 12 dead base widgets, a 6valley leftover FCM TOPIC constant, Google Maps key hardcoded (lib/helper/location_helper.dart)
```

## Differences from chinaparts-old-seller

**Provenance.** Both share history from 2024-08-28. This copy stops at 2025-02-25 (78 commits, last ones
"sub sub category" for add-product/product-details) and has uncommitted edits. `Chinaparts Seller` continues to
2025-06-23 (86 commits: a merge of a separate repo's `dev`/`staging` branches, then a "hot fixes … coupon and order
details and profile" commit). So this is the **older** code.

**What this project lacks (vs primary):**
- `lib/core/` (79 files) and `lib/core_features/` (70 files): the whole dormant clean-architecture scaffold
  (BaseCubit/BaseBloc, BaseRemoteDataSource/BaseRepository, Failure hierarchy, ApiService, AppTextFormField family,
  AppDefaultButton, ToastManager, AppValidator, secure/shared storage managers, M3 component themes, AppColors,
  GoRouter stub, talker).
- Root `copy_feature.dart`.
- pubspec deps: easy_localization, flutter_screenutil, dartz, flutter_bloc, go_router, talker_flutter,
  talker_dio_logger, flutter_secure_storage. Everything else, including the SDK constraint and `.fvmrc` 3.19.0, is the same.

**What only this project has (16 files):**
- `lib/data/model/response/config_model.dart`. The primary moved it to `lib/core_features/splash/data/models/config_model.dart`.
- `lib/helper/price_converter.dart` (used once), `lib/helper/json_converter.dart`, `lib/helper/product_type.dart`.
- 12 base widgets in `lib/features/base/`, **all unused** (only their own definition references them):
  confirmation_dialog, custom_bottom_sheet, custom_delegate, custom_divider, custom_edit_dialog,
  custom_field_with_title, custom_header, custom_search_field, custom_search_widget (AnimSearchBar), product_shimmer,
  rating_bar (RatingBarIndicator), see_more_button. The primary deleted them as dead code.

**58 files differ.** Most are import moves (`utils/images.dart` → `core/utilities/constants/images.dart`,
`AppConstants.languages` → `ConstantLists.languagesList`). Substantive changes in the primary:
- `lib/data/model/response/order_details_model.dart`: model rewritten (~610 changed lines).
- `lib/features/screens/order/order_details_screen.dart` (~240 lines), `lib/features/screens/profile/profile_screen.dart`
  (~110 lines), `lib/features/screens/order/widget/order_widget.dart`: adapted to the new order model / profile API.
- `lib/utils/app_constants.dart`: in v0 it holds the `languages` list (with provider imports), currency image list,
  and a leftover 6valley `TOPIC`. The primary moved these out and switched `baseUrl`.
- `lib/utils/images.dart`: in v0 it holds `AppIcons` + `AppImages` (~240 lines). In the primary it is 1 line; the
  content moved to `lib/core/utilities/constants/`.
- `lib/helper/location_helper.dart`: the primary switched to a different hardcoded Google key and kept the old one
  commented. v0 has one hardcoded key.
- `main.dart`, `localization/app_localization.dart`, `provider/localization_provider.dart`: only the language-list source.

**Identical:** `lib/di_container.dart`, `lib/data/datasource/**`, `lib/helper/{api_checker,network_info,permissions_helper,validator,date_converter}.dart`,
`lib/features/base/{paginated_list_view,custom_button,custom_dialog,custom_snackbar,custom_loader,custom_date_picker,custom_drop_down_item,image_dialog}.dart`,
`lib/features/base/textfeild/*`, all providers except 8, and the theme folder. The same `MyHttpOverrides` typo
(`CreateHttpClient`, inert) is in `lib/main.dart`.

**Counts:** RTL Directional=14 / LeftRight=41 (primary 20/37; the extra Directional uses come from `lib/core`),
print 84, debugPrint 0, withOpacity 50, Color(0x 218, literal Text 17.

**Recommendation for the template:** nothing essential. If wanted, take `RatingBarIndicator`
(`lib/features/base/rating_bar.dart`) and the dashed `CustomDivider` (`lib/features/base/custom_divider.dart`) as
small extras. Otherwise prefer `chinaparts-old-seller` (and better, `New Projects/seller`).
