# Packages

Every dependency of `flutter_template/pubspec.yaml` with its exact constraint, its role, why it was
chosen, and which in-scope source projects used it. Then the packages that were **rejected**, and
the **opt-in** packages for the recipes.

Toolchain: Flutter **3.44** / Dart **^3.12.0** (pinned to `3.44.0` in CI). `pubspec.lock` is
committed (this is an app).

Policy:
- Add a package only when the platform or an existing package can't do the job in a few lines.
  Wrap a plugin behind an interface in `lib/core/services/` so features and tests never touch it
  (see `PermissionService`, `ImagePickerService`, `PushService`).
- Use caret constraints. Upgrade in a dedicated PR (`flutter pub outdated`,
  `flutter pub upgrade --major-versions`) with the full gate green.
- Build-time tools go in `dev_dependencies`. brgr, chinaparts ×2, instaops and tebbr listed
  `flutter_launcher_icons` / `flutter_native_splash` under `dependencies`.

## Dependencies

| Package | Constraint | Role in the template | Why | Used by (in scope) |
|---|---|---|---|---|
| `flutter` | sdk | | | all |
| `flutter_localizations` | sdk | Material/Cupertino localizations (ar, en) | Required for RTL widgets and date pickers | all |
| `flutter_bloc` | `^9.1.1` | `Cubit`, `BlocProvider`, `BlocBuilder`/`Listener`/`Consumer` | The state library of all 12 apps (decision C3) | all 12 |
| `equatable` | `^3.0.0` | Value equality for states, failures, config | No codegen; works with `bloc_test` | baytna, brgr, tebbr, chinaparts ×2, corsa ×2, instaops, lexa ×2, markspulse (all on ^2.x) |
| `get_it` | `^9.3.0` | DI container (`getIt`) | Manual, no codegen, familiar (decision C4) | baytna, brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe |
| `go_router` | `^18.1.3` | Routing, `StatefulShellRoute`, redirect, deep links | Declarative, URL-based, IDs in paths | all 12 (v16–18) |
| `dio` | `^5.11.1` | HTTP inside `ApiClient` | Interceptors (queued refresh, retry, mock), cancel tokens, `FormData` | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe |
| `easy_localization` | `^3.0.8` | Translations, `LocaleKeys` codegen, plurals, saved locale | The l10n library of all 12 apps (decision C9) | all 12 |
| `intl` | `^0.20.2` | `NumberFormat` / `DateFormat` behind `AppFormat` (re-exported by easy_localization) | Must match the version `flutter_localizations` pins | baytna, brgr, tebbr, chinaparts ×2, corsa ×2, instaops, lexa-control, markspulse |
| `shared_preferences` | `^2.5.6` | `SharedPrefsKeyValueStore` on `SharedPreferencesWithCache` | Synchronous reads after one async load (theme read before `runApp`) | 11 of 12 (baytna used Hive) |
| `flutter_secure_storage` | `^11.2.0` | `FlutterSecureStore` (tokens), with self-heal | Keychain / Keystore encryption | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe |
| `cached_network_image` | `^4.0.3` | `AppNetworkImage` (disk cache + `memCacheWidth`) | Memory-safe decoding at display size | baytna, tebbr, chinaparts-seller, corsa ×2 (brgr, chinaparts-customer and instaops declared it unused) |
| `skeletonizer` | `^3.0.0` | `AppSkeleton`, `SkeletonList` | Skeleton of the **real** widget, with no hand-drawn bones (decision C8) | brgr, tebbr, chinaparts ×2, corsa ×2, instaops |
| `image_picker` | `^1.2.4` | `ImagePickerService` | Official plugin; Android photo picker without a storage permission | baytna, brgr, tebbr, chinaparts ×2, corsa ×2, instaops, markspulse, petrobe |
| `flutter_image_compress` | `^2.5.1` | `FlutterImageCompressor` (size tiers) | Native JPEG re-encode, EXIF stripped | baytna, brgr, tebbr, chinaparts-seller, corsa ×2, instaops |
| `permission_handler` | `^12.0.1` | `PermissionHandlerService` | One API for every runtime permission; compile-time iOS macros. Pinned to 12: v13 requires Android compileSdk 37, while Flutter 3.44's default is 36 (upgrade together with `compileSdk`) | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe |
| `url_launcher` | `^6.3.3` | `UrlService` | Official; `inAppBrowserView` mode | all 12 |
| `package_info_plus` | `^10.2.2` | `AppInfoService` (version, build, request headers) | Build number for the update gate | baytna, brgr, tebbr, chinaparts ×2, corsa ×2, instaops, lexa ×2 |
| `talker` | `^5.2.0` | `AppLogger` backend | Leveled, structured, debug-only | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe |
| `talker_dio_logger` | `^5.2.0` | Network logs in `ApiClient` (hidden headers, filters) | Header hiding and request filters built in | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe |

## Dev dependencies

| Package | Constraint | Role | Used by (in scope) |
|---|---|---|---|
| `flutter_test` | sdk | Widget and unit tests | all |
| `flutter_lints` | `^6.0.0` | Base lint set, extended by the strict `analysis_options.yaml` (markspulse rules) | all 12 |
| `bloc_test` | `^10.0.0` | `blocTest` for cubits | baytna, chinaparts-customer, corsa-customer, lexa ×2 |
| `mocktail` | `^1.0.5` | Fakes and mocks without codegen | baytna, chinaparts-customer, corsa-customer, lexa ×2 |

## Rejected or removed

| Package | Seen in | Why it is not in the template | Instead |
|---|---|---|---|
| `flutter_screenutil` | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe | `.sp` stacks with the system text scale. tebbr and chinaparts rebuilt `ThemeData` per scale, and corsa had to clamp the design size. Pixel-scaling a phone design also doesn't make it work on tablets or foldables (decision C2) | Fixed tokens (`AppSpacing`...), `shortestSide` form factors, `LayoutBuilder` grids, the damped `TextScaler` |
| `dartz` | baytna, brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe | Unmaintained, and a whole FP library for one type (decision C1) | Sealed `Result<T>` with the same `fold` order |
| `hydrated_bloc` | brgr, chinaparts-seller, instaops, petrobe (unused); tebbr, chinaparts-customer | Dead dependency in four apps (D5). Implicit persistence of whole states is hard to migrate | Explicit `KeyValueStore` reads/writes of what must survive |
| `internet_connection_checker` / `connectivity_plus` | connectivity_plus: baytna | `connectivity_plus` reports the network **interface**, not reachability (Wi-Fi with no internet reads as online). The checker packages add a dependency for what is a few lines of DNS lookup | `ConnectivityService` (DNS probe of two hosts, adaptive polling, confirm before offline) |
| `talker_flutter` (in-app log screen) | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe | Not used by the template (no debug menu); removed to keep the dependency list lean | Add it back for a debug menu: `TalkerScreen(talker: getIt<AppLogger>().talker)` |
| `bloc` (direct) | baytna, chinaparts-customer | `flutter_bloc` re-exports everything the template uses | — |
| Overlay toasts (`ToastManager`/`CustomToast`, fluttertoast-style packages) | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe | A stale-timer bug removed newer toasts, they aren't accessible, and they duplicate SnackBar (D2, C6) | `AppSnackBar` (themed, context-free, undo) |
| `injectable` + `injectable_generator` | baytna | Codegen for a few dozen registrations (decision C4) | Manual `register<X>Feature()` per feature |
| `shimmer` | baytna (markspulse used a static skeleton) | Needs hand-drawn placeholder shapes (C8) | `skeletonizer` over the real widget |
| `provider` | instaops (theme only) | A second state approach | `ThemeCubit` |
| `pinput` | chinaparts ×2 | `AppOtpField` covers OTP with native autofill and paste | `AppOtpField` |
| `hive` / `hive_flutter` | baytna | Not needed for settings and tokens | `KeyValueStore` / `SecureStore` interfaces (add a DB per project behind an interface if needed) |
| `flutter_animate`, `animate_do`, `flutter_html`, `country_picker`, `dotted_border`, `percent_indicator`, `fl_chart`, `font_awesome_flutter`, `carousel_slider`, `lottie` | various (often declared but unused) | App-specific or unused | Add per project when a screen needs it |
| `device_info_plus`, `path_provider` | various | The template doesn't need them | `AppInfo` covers version headers |

Also not included but commonly added per project: `flutter_svg` (if the design ships SVGs, use
`matchTextDirection: true` for directional icons), `cupertino_icons`, `freezed` /
`json_serializable` (the template uses hand-written models with [JSON helpers](SERVICES.md#json-helpers);
codegen is fine if the team prefers it), `app_links` (custom-scheme or universal links beyond
go_router's built-in deep linking), `share_plus`, `webview_flutter`.

## Opt-in packages

For the [optional recipes](SERVICES.md#optional-recipes). The template ships interfaces and no-op
implementations, so none of these are needed to build, analyse or test (decision C7). Versions are
the latest seen across the source projects and pub cache when the template was cut. Check pub.dev
when you adopt one.

| Package | Constraint | Recipe | Notes | Used by (in scope) |
|---|---|---|---|---|
| `firebase_core` | `^4.15.0` | Crashlytics, FCM | `flutterfire configure` → `lib/firebase_options.dart` + native configs (all gitignored by the template; restore them in CI) | baytna, brgr, tebbr, chinaparts ×2, corsa ×2, instaops, lexa ×2, markspulse, petrobe |
| `firebase_crashlytics` | `^5.4.0` | [Crashlytics recipe](SERVICES.md#crashlytics-recipe-opt-in) | Implements `ErrorReporter`; collection on in release only | baytna, brgr, tebbr, chinaparts-customer, corsa ×2, instaops (chinaparts-seller declared it unused) |
| `firebase_messaging` | `^16.7.0` | [FCM recipe](SERVICES.md#fcm--flutter_local_notifications-recipe-opt-in) | Implements `PushService` | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, markspulse, petrobe |
| `flutter_local_notifications` | `^22.3.0` | FCM recipe | Android foreground display, channels (versioned ids), local reminders. ONE plugin instance per app | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, lexa-control, markspulse, petrobe |
| `in_app_purchase` | `^3.3.1` | [IAP recipe](SERVICES.md#in-app-purchases-iap) | Behind a `PurchaseService`; **server-side verification** | baytna, markspulse, tebbr |
| `google_maps_flutter` | `^2.18.0` | [Maps recipe](SERVICES.md#maps-and-location) | Keys from local.properties/xcconfig, never committed | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe (several unused) |
| `geolocator` | `^14.0.2` | Maps recipe | Behind a `LocationService`; when-in-use first | brgr, tebbr, chinaparts ×2, corsa ×2, instaops, petrobe |
| `flutter_launcher_icons` (dev) | `^0.14.4` | [Checklist: icons](NEW_PROJECT_CHECKLIST.md#5-app-icons-and-splash) | dev_dependency | baytna, brgr, tebbr, chinaparts ×2, corsa-customer, instaops, lexa ×2 |
| `flutter_native_splash` (dev) | `^2.4.8` | [Checklist: splash](NEW_PROJECT_CHECKLIST.md#5-app-icons-and-splash) | dev_dependency | baytna, brgr, tebbr, chinaparts ×2, corsa-customer, instaops, lexa ×2 |
