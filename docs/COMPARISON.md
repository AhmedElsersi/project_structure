# COMPARISON — what to keep, merge and drop

> Phase 2 output. **Scope (your selection):** brgr, tebbr, baytna, markspulse, lexa
> (lexa-control + lexa-student), chinaparts-customer, chinaparts-seller, corsa-customer,
> corsa-driver, instaops, petrobe. That is 12 projects, analysed in `docs/_analysis/*.md`.
> Reports for the other 25 projects are kept for reference in
> `docs/_analysis/_not_considered/` and are **not** used for any decision below.
> Quality scores (q1–q5) come from the reports. **Status: waiting for approval before Phase 3.**
>
> Notes on the selection:
> - "brge" was read as `Datum/brgr`, the current app, not the old copies.
> - petrobe's report is a diff against `_not_considered/petro-aman.md`. Every petrobe file cited
>   here is byte-identical in petro-aman, so it makes no difference which of the two is used.

## 0. Inventory (in scope)

| Project | Path | Backend | Last commit | Dart files |
|---|---|---|---|---|
| baytna | My Apps/Baytna | Firestore | 2026-11-05 | 313 |
| tebbr | Freelance/tebbr | REST (Dio) | 2026-10-31 | 557 |
| chinaparts-customer | Chinaparts/New Projects/customer | REST | 2026-10-26 | 521 |
| chinaparts-seller | Chinaparts/New Projects/seller | REST | 2026-10-25 | 519 |
| markspulse | My Apps/My Teacher Student App/markspulse | Firestore + Functions (TS) | 2026-10-24 | 477 + 27 TS |
| instaops | Datum/InstaOps | REST | no git (2026-10-20) | 279 |
| corsa-customer | D-index/Corsa/customer | REST | 2026-10-14 | 338 |
| corsa-driver | D-index/Corsa/driver | REST | 2026-10-14 | 247 |
| lexa-control | My Apps/<lexa folder>/lexa_control | Firestore | 2026-09-08 | 153 |
| lexa-student | My Apps/<lexa folder>/lexa_student | Firestore | 2026-09-08 | 138 |
| petrobe | Chinaparts/New Projects/petrobe | REST | 2026-08-20 | 449 |
| brgr | Datum/brgr | REST | 2026-07-14 | 276 |

All 12 are Flutter. markspulse also has Firebase Cloud Functions in TypeScript. There's no
React or Laravel in scope, so there will be **no `react_template` or `laravel_template`**.

They fall into two families:
- **A. "House style" REST apps** (brgr, tebbr, cp-customer, cp-seller, corsa ×2, instaops,
  petrobe): Cubit, get_it, go_router, Dio, easy_localization, dartz Either and
  `core/base_architecture` with BaseRemoteDataSource → BaseRepository → BaseCubit. Corsa is the
  most evolved version (2026-10).
- **B. Firebase clean-architecture apps** (baytna, markspulse, lexa ×2): no base cubit; sealed
  Failures; pure, tested router redirects; dark mode; design tokens; the strongest tests and RTL.

---

## 1. Matrix — infrastructure

Legend: **CA-F** clean-arch feature-first, no domain layer · **CA-FD** with a domain layer ·
**GR** go_router · **EL** easy_localization · **SU** flutter_screenutil · **2B** two parallel base
cubits · **E** dartz Either · **ex** thrown sealed Failure · `–` none.
RTL = `Directional` count / physical left-right count.

| Concern | brgr | tebbr | baytna | markspulse | lexa-ctl | lexa-stu | cp-cust | cp-sell | corsa-c | corsa-d | instaops | petrobe |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Architecture | CA-F | CA-F | CA-FD | CA, pure domain (test-enforced) | CA-FD | CA-F | CA-F | CA-F | CA-F + opt. use cases | same | CA-F | CA-F |
| State | Cubit | Cubit + HydratedBloc | Bloc + Cubit | Cubit | Cubit | Cubit (sealed states) | Cubit + Hydrated cart | Cubit | Cubit | Cubit | Cubit | Cubit |
| Base classes | 2B | 2B | none (`_run` per bloc) | guarded use cases (`@nonVirtual`) | guarded use cases | none | 2B + epoch guard | 2B + close guard | 2B + safeEmit + CancelToken | same | 2B | 2B |
| DI | get_it | get_it | get_it + injectable | RepositoryProvider | RepositoryProvider | AccountGraph | get_it | get_it | get_it, core + features files | same | get_it | get_it |
| Router | GR16 ShellRoute | GR17 ShellRoute | GR17 StatefulShell | GR18 | GR17 StatefulShell | GR17 StatefulShell | GR16 StatefulShell | GR16 StatefulShell | GR17 StatefulShell | same | GR16 ShellRoute | GR17 flat |
| Guards | – | cold-start bounce | **status redirect** | **pure redirect, tested** | pure redirect + gate widgets | pure redirect | 401 service | per-route extra checks | cold-start bounce + requireAuth | same | – | – |
| Interceptors / transport | 401 → logout | logger | Firebase SDK | Firebase SDK | Firebase SDK | Firebase SDK | 401 → logout + X-App headers | 401 → logout | **queued refresh, GET retry, 426/503, mock** | same | 401 → logout | logger (PII filter) |
| Token refresh | n | n | SDK | SDK | SDK | SDK | n | n | **y** | y | n | n |
| Result | E | E | E | ex | ex | ex | E | E | E | E | E | E |
| Failure model | typed + displayMessage q4 | typed q3 | **sealed, translation key q5** | **sealed + central mapper q5** | sealed + mapper q5 | own Failure type | typed + `errors.*` keys q4 | typed + 7-shape parser q4 | **code + fieldError q5** | same | typed q4 | typed q4 |
| Storage | prefs + secure (self-heal) | prefs, secure, hydrated | Hive behind interface | prefs | prefs | prefs stores | prefs, secure, keychain wipe | prefs, secure | prefs, secure | same | prefs + secure (self-heal) | prefs + secure |
| L10n (default) | EL (ar) | EL (ar) | EL + plurals (device) | EL + LocaleKeys (ar) | EL + LocaleKeys (en) | EL codegen (ar) | EL ar/en/zh×2 (device) | EL ar/en/zh×2 (en) | EL (en) | EL (en) | EL (ar) | EL (ar) |
| String guards | – | – | 0 literal `Text` | parity + failure-code tests | – | – | regex test + parity test | CI `check_translations` | – | – | – | – |
| RTL | 25/43 | 139/85 | **266/5** | **239/6** | 16/4 | 5/2 | **225/13** | 153/16 | 31/17 | 15/15 | 25/39 | 125/84 |
| Dark mode | n | n | y | y | y | y | n | n | n | n | n | n |
| Theme tokens | – | – | **palette ThemeExtension, spacing, motion** | **25 component themes, StatusColors, radii, motion** | semantic ThemeExtension | ColorScheme extension | dialog width cap | – | AppDimens | same | runtime brand palette | – |
| Responsive | SU | SU + shortestSide 600 | tokens only | – | width 600/1100 | width 600/905 | **SU + 600/1024 width kit** | SU + 600/1024 width | SU clamped + **600/840 width** | same + portrait lock (shortestSide) | SU | SU |
| Text-scale clamp | – | damped 1.0–1.15 | 0.85–1.4 | – | 0.9–1.3 | **1.0–1.3** | **1.0–1.3** | ≤1.3 | 0.85–1.5 | same | – | – |
| Env | hardcoded | hardcoded | dev dart-defines | **flavors + APP_ENV enum** | hardcoded | 1 define | hardcoded | hardcoded | **define-from-file** | same | hardcoded | hardcoded + key header |
| Logging | talker + print | talker + print | debugPrint | none | dev.log | log sink + SessionTrail | talker (debug only) | talker (filtered) | talker (redacted) | same | talker + print | talker + print |
| Crash | crashlytics | crashlytics | crashlytics + analytics | – | – | – | **crashlytics facade** | (dependency unused) | crashlytics | crashlytics | partial | – |
| Push | FCM topics | FCM + local | in-app | FCM data-only + local | local reminders | in-app | FCM + **pure link resolver** | FCM + pending link + permission gate | FCM | FCM, versioned channels | FCM topics | FCM + alarm |
| IAP / payments | – | IAP | IAP | IAP (server verify) | – | – | webview gateway | – | webview gateway | – | – | – |
| Deep links | – | app_links | scheme + Flutter deep linking | pending notification link | pending notification link | – | notification only | notification, pending | app_links | app_links | – | notification router |
| Connectivity | – | **DNS probe + gate** | probe + offline banner | – | – | – | – | – | DNS probe + gate | same | – | – |
| Config / update gate | – | ✓ | **AppGate q5** | – | ✓ | ✓ (fail-closed) | ✓ | ✓ above router | ✓ (426/503) | ✓ | – | – |
| Pagination | copied | unused generic | – | `Page<T>` (limit+1) | – | – | copied ×10 | **RequestGeneration + FillViewport q5** | **PaginatedListView q5** | same | copied | copied ×36 |
| Tests | 1 | 21 | 56 + rules | **239 + rules** | 53 + rules | 27 | **65** | 30 | 20 | 16 | 1 | 1 |
| Lints | default | default | default | **strict + 4 rules** | default | default | default | default | default | default | default | default |
| CI | – | – | build bump | ci + release | – | ci + release | GH CI | GH CI + translation check | – | – | – | Play upload |
| Scaffolder | – | create_feature | add_strings.py | tool/ scripts | – | – | create_feature | create_feature | create_feature (`--use-cases`) | same | – | create + copy_feature |

## 2. Matrix — widgets (best quality in scope)

| Widget type | Best versions | Decision |
|---|---|---|
| Primary button | markspulse `BusyButton` q5 (keeps width while busy), lexa `AppPrimaryButton` q5, corsa `AppDefaultButton` q5 (variants) | **Keep**: `AppButton`, a thin wrapper over themed Filled/Outlined/Text buttons |
| Text field | corsa q5, markspulse q5 (validate on blur, digit folding), petrobe `externalError` q4, lexa `forceLtr`, baytna validator keys | **Keep (merged)**: `AppTextField` + password / email |
| OTP field | corsa `otp_form_field` q5 | **Keep** |
| Search field | corsa `app_search_field` q4 (debounce, clear) | **Keep** |
| Dropdown | markspulse q4, lexa `AppDropdown<T>` q4 | **Keep**. **Drop**: `DynamicDropdownFormField` (6 copies, LTR-only, broken search) |
| Date / time field | lexa date + time pickers q4, markspulse q4, cp-seller q4 | **Keep**: `AppDateField` (time: `showTimePicker` pattern documented in WIDGETS.md) |
| Base scaffold | corsa `DefaultScreen` q5 (maxContentWidth, sticky action), markspulse `AppScaffold` q5 (busy bar, one-shot message) | **Keep (merged)**: `AppScaffold` |
| App bar / back button | – (Material `AppBar` + `BackButton` already mirror in RTL) | **Drop**: use `appBarTheme` |
| Max-width / form body | cp-customer `MaxWidthBody`, `ScrollableFormBody` q4, lexa `ContentWidthLimit` q4 | **Keep** |
| Adaptive row | corsa-driver `AdaptiveRow` q5 | **Keep** |
| State switcher | corsa `GenericFetchWidget` q5 (skeleton, empty, retry, keep data while refreshing); cp-seller skeleton over a mock model | **Keep (merged)**: `DataStateBuilder` |
| Empty / error / loading views | baytna `AppEmptyState` q4, markspulse q4, lexa q4 | **Keep** |
| Skeleton | corsa `app_skeletons` (skeletonizer) q4 | **Keep** |
| Paginated list | corsa q5, cp-seller `FillViewportPaging` q5, markspulse `PagedListView` q4 | **Keep (merged)** |
| Network image | corsa `app_image` q4, baytna `RemoteImage` q4, tebbr memCacheWidth | **Keep**: `AppNetworkImage` |
| Image viewer | tebbr zoom gallery q4, baytna q4, corsa q4 | **Keep** |
| Confirm dialog | cp-customer `showConfirmDialog` q5, baytna `AppDialog` q4, lexa q4 | **Keep** |
| Typed confirmation dialog | baytna q4, lexa q4 | **Keep** (destructive actions) |
| Bottom sheet | corsa q5 (dialog on tablet), baytna q5 (handle, title, close), cp-seller 640 cap | **Keep (merged)** |
| Snackbar / toast | baytna `AppSnackBar` q5 (failure, undo), lexa q4, markspulse q4; overlay `ToastManager` q3–4 in 8 apps | **Keep**: `AppSnackBar`. **Drop**: overlay toasts |
| Loading dialog | petrobe `LoadingDialogService` q4 (keeps its own context) | **Keep**: `LoadingOverlay` |
| Offline banner | baytna `OfflineBanner` q4, tebbr / corsa gate q4 | **Keep** |
| Card | baytna `AppCard` q4, markspulse q4 | **Keep** (cardTheme) |
| Status pill | lexa `StatusPill` q5, markspulse q4 | **Keep**: `StatusChip` |
| Section header | corsa q4, markspulse `AppSection` q4 | **Keep** |
| Avatar with initials | baytna q4, markspulse q4 (Arabic-aware) | **Keep** |
| Unsaved-changes guard | markspulse `DirtyGuard` q5, cp-seller q4 | **Keep** |
| Image source sheet | brgr / cp-seller / cp-customer q3 | **Keep (rewritten)** |
| Maintenance / update views | cp-seller q4, lexa-student `BlockingScaffold` q4 | **Keep** |
| Language / theme selector | cp-seller sheet q4, markspulse | **Keep** |
| Nav / settings tile | markspulse `NavTile` q4, corsa `AppMenuTile` q4 | **Keep** |
| `ContainerWithShadow`, `CustomChip`, `LinearPercentIndicator`, `CustomRadioGroup`, `ExpandableContainer`, `AnimatedIndicator`, `ImageViewerWidget` (string-prefix) | house style, q2–3, mostly unused | **Drop**: themed Material widgets + `AppNetworkImage` |

---

## 3. Decisions — infrastructure (keep → source → why → merged / rejected)

| # | Item | Chosen source(s) | Why | Merged in | Rejected |
|---|---|---|---|---|---|
| K1 | Bootstrap | baytna `lib/bootstrap.dart`; corsa `lib/main.dart` | runZonedGuarded + FlutterError + PlatformDispatcher hooks, ordered init, session hooks wired at startup | lexa-control ThemeMode read before runApp; cp-customer first-launch keychain wipe | ~200 lines of dev demos in baytna |
| K2 | AppEnv | corsa `core/utilities/constants/keys/api_keys.dart` (AppEnv); markspulse `lib/app/environment.dart` | `--dart-define-from-file`; an unknown env throws; USE_MOCKS on when BASE_URL is missing | – | hardcoded `ApiKeys.BASE_URL` (8 apps) |
| K3 | JsonCredential (path or base64) | your convention; markspulse `tool/support/firestore_rest.dart` (service-account scripts) | for `tool/` scripts and CI only; never in the app | – | committed service-account JSON (petrobe) |
| K4 | DI | corsa `core/services/di_container.dart` + `features_di.dart` | one file per feature; lazySingleton for services/repos, factory for cubits; awaited | – | not-awaited async setup (brgr, instaops, cp-seller); locator lookups inside base classes |
| K5 | ApiClient (Dio) | corsa `core/services/api_service.dart` q5 | queued single refresh, GET retry, 426/503 hook, onSessionExpired, Authorization redacted, Idempotency-Key | cp-customer X-Platform / X-App-Version / X-Build-Number + Accept-Language; petrobe log path filters | 5-minute timeouts; static key header (petrobe) |
| K6 | Mock API interceptor | corsa-driver `core/services/mock/*` (the better copy) | asset fixtures, latency, `mock_status`; the sample runs without a backend | – | – |
| K7 | Dio → Failure mapping | corsa `base_remote_data_source.dart` | status + backend code + field errors; HTML 5xx bodies; cancel | cp-seller 7-shape validation parser; brgr "never show raw error" | 401-only / 422-less variants |
| K8 | Result type | **new** (none of the 12 has one): sealed `Result<T>` with `fold` / `map` / `when` | see C1 | API mirrors dartz `fold` used by 9 apps | – |
| K9 | Failure hierarchy | baytna `core/errors/failures.dart` (translation key + args); corsa `core/utilities/failures/failure.dart` (statusCode, code, fieldError) | sealed; UI renders `failure.messageKey.tr()` | markspulse `core/failures/failure_messages.dart` + "every code has a sentence" test; lexa coded fallback | English text inside Failures (lexa); `CacheFailure` dropping its message (house style) |
| K10 | BaseRepository guard | cp-customer `base_repo.dart` | also catches non-Failure throws and reports them | – | catch-Failure-only versions |
| K11 | BaseCubit | corsa `base_single_class_state_cubit.dart`; cp-customer epoch guard | safeEmit, isClosed guard, CancelToken, debounce | one base instead of two | second base class; `failure ?? this.failure`; `as State` casts; `props => []` |
| K12 | `DataState<T>` + `DataCubit<T>` | house style `BaseSingleClassState{status, failure, success}` (corsa / cp-seller), made generic | no per-feature state class for simple screens | keep data while refreshing (corsa) | – |
| K13 | Pagination | cp-seller `core/utilities/request_generation.dart` + `widgets/fill_viewport_paging.dart`; markspulse `data/firestore/pagination.dart` + `domain/common/page.dart` | stale-response tickets, appendUnique, viewport fill, limit+1 | corsa inline load-more retry | 46+ copy-pasted scroll listeners |
| K14 | KeyValueStore (prefs) | baytna `core/services/settings_store.dart` (interface) | interface + memory fake for tests; `SharedPreferencesWithCache` | – | untyped `setValue(dynamic)` singletons |
| K15 | SecureStore | brgr / instaops `secure_storage_manager.dart` (self-heal) | corruption recovery | cp-customer iOS reinstall keychain wipe | plain password stored for "remember me" (brgr, instaops, tebbr) |
| K16 | Session + redirect | baytna `app/session/session_cubit.dart`; markspulse `app/router/redirect.dart` + `session_status_notifier.dart` | status-driven, no navigation after login; pure and tested | cp-seller single-flight logout + generation key; corsa start/end hooks; lexa offline never signs out | splash-decides + per-screen 401 listeners |
| K17 | Router | baytna `app/router/{app_router,routes,router_refresh_stream}.dart` | path constants + builders, StatefulShellRoute, refreshListenable | corsa errorBuilder + cold-start deep link via splash; lexa typed record args; lexa-student multi-stream refresh | `state.extra as X` casts; 873–1814-line routers |
| K18 | Locale registry | cp-customer `app_languages.dart`; cp-seller `app_locales.dart` | one table: locales, autonyms, direction, device mapping, Accept-Language | baytna `plural_x.dart` | – |
| K19 | Formatters + digits | baytna `core/utils/formatters.dart` q5 | locale digits, value/unit apart for RTL, relative time → key | markspulse Western-digit formatters; cp-seller `double_parser_service.dart` | – |
| K20 | Theme | baytna `app/theme/*`; markspulse `core/theme/*` | text sizes and button styles only in ThemeData (your rule); dark mode | cp-customer `dialog_theme.dart` width cap; lexa sync ThemeMode; lexa contrast test | empty `dark_theme.dart` (6 apps); `ColorScheme.background` |
| K21 | Responsive | cp-customer `core/utilities/responsive/*`; corsa `core/extensions/context_extensions.dart` | one helper, never cached | lexa `ContentWidthLimit`; corsa-driver `AdaptiveRow` | – |
| K22 | Text-scale clamp | cp-customer `main.dart` builder; lexa-student `withClampedTextScaling` | 1.0–1.3, exactly your convention | – | tebbr damping (noted only) |
| K23 | Logger | lexa-student `core/error/error_log.dart` (pluggable sink); talker as the debug sink (cp-customer debug-only) | redacts Authorization, tokens and emails; off in release | corsa header redaction; petrobe path filters | print / debugPrint (brgr, tebbr, instaops, petrobe); FCM / bearer token logging |
| K24 | ErrorReporter | cp-customer `core/services/error_reporter.dart` q5 | facade: non-fatal vs fatal, release only | – | – |
| K25 | Bloc observer | cp-customer `core/services/bloc_observer.dart` | debug print + release crash forwarding | – | release logging (brgr, petrobe) |
| K26 | Connectivity | tebbr / corsa `core/services/connectivity_service.dart` q4.5 | no dependency, DNS probe, adaptive polling, offline re-check | baytna `connectivity_cubit.dart` + `OfflineBanner` | – |
| K27 | Config / update gate | cp-customer `features/app_config/*` + `app_version_comparator.dart` q5; baytna `features/config/*` (AppGate) q5 | maintenance / force / optional update above the router; cached config never gates | lexa-student fail-closed `app_version.dart`; corsa 426/503 trigger; tebbr refresh on resume | – |
| K28 | Validators | baytna `core/utils/validators.dart` (returns keys); brgr `core/services/app_validator.dart` (compose, range, IBAN) | keys, not strings; composable | – | `isNumeric` regex with a literal `\$` (in brgr, tebbr, cp ×2, instaops, petrobe); Saudi / UAE / Egypt-only rules |
| K29 | Input formatters | tebbr Arabic-Indic digit normalizer; cp-seller `decimal_input_formatter.dart` | – | – | – |
| K30 | Debouncer / Throttler | tebbr `core/utilities/timing/request_limiters.dart` | flush support | – | plain debounce copies |
| K31 | JSON helpers | corsa `core/utilities/converters/json_helpers.dart` q5 | tolerant parsers | markspulse `domain/common/parse.dart` | – |
| K32 | UrlService | cp-customer `core/services/url_handler.dart` q4 | checks the launch result | baytna in-app → external fallback; corsa-driver `navigate()` | – |
| K33 | PermissionService | petrobe `features/home/presentation/services/permissions_service.dart` q4 | rationale → request → permanently denied → settings → recheck | cp-seller `notification_permission_gate.dart` (settings prompt at most once a day) | swapped settings buttons (`permisssions_helper.dart`) |
| K34 | ImagePickerService | brgr `core/services/image_picker_service.dart`; baytna `compression_plan.dart` | size-tiered compression, lost-data recovery | instaops `pending_capture_service.dart` | SnackBar shown on a popped context |
| K35 | Push (interface + link resolver) | cp-customer `notification_link_handler.dart`; cp-seller pending link until session | pure, testable routing | markspulse `PendingDeepLink`; corsa-driver versioned channels (documented) | static NotificationService with the fresh-plugin bug (brgr, tebbr, instaops) |
| K36 | AppInfo / version | cp-customer `core/services/app_version_service.dart` | package_info + request headers | lexa-student `app_version.dart` | – |
| K37 | Feature scaffolder | corsa `create_feature.dart` (`--use-cases`) | data/domain/presentation + DI + route stubs | petrobe `copy_feature.dart` idea (patch DI / router) | blind string replace |
| K38 | Translation checker | cp-seller `tool/check_translations.dart` q5 | parity, used-but-undefined keys, literal `Text` | – | – |
| K39 | Policy tests | cp-customer `no_hardcoded_ui_strings_test.dart`, `app_languages_test.dart`, `adaptive_surfaces_matrix_test.dart`; markspulse `architecture_test.dart`, `translations_test.dart`; corsa `test/helpers/pump_at_scale.dart`; lexa `theme_contrast_test.dart` | your conventions enforced by `flutter test` | new: RTL and colour-literal checks | – |
| K40 | Lints | markspulse `analysis_options.yaml` | strict-casts, strict-raw-types, unawaited_futures, avoid_dynamic_calls, prefer_final_locals | `avoid_print` | bare flutter_lints (11 apps) |
| K41 | CI | markspulse `.github/workflows/ci.yml`; lexa-student ci | pinned Flutter, format check, `analyze --fatal-infos`, test, translation check | petrobe signed-build-from-secrets (documented) | – |

## 4. Drops (in scope)

| # | Dropped | Seen in | Reason |
|---|---|---|---|
| D1 | second parallel base cubit | brgr, tebbr, cp ×2, corsa ×2, instaops, petrobe | merged into `BaseCubit` + `DataCubit` |
| D2 | overlay `ToastManager` + `CustomToast` | same 8 | stale-timer bug; duplicates SnackBar |
| D3 | `DynamicDropdownFormField` | brgr, tebbr, cp ×2, instaops, petrobe | LTR placement, broken search |
| D4 | custom app bars / back buttons | house style | `appBarTheme` + `BackButton` |
| D5 | hydrated_bloc (unused) | brgr, cp-seller, instaops, petrobe | dead dependency |
| D6 | unused GenericFetchWidget / BaseListView copies | brgr, tebbr, cp-seller, instaops, petrobe | replaced by corsa's version |
| D7 | hardcoded base URLs / keys in Dart | 8 REST apps | replaced by AppEnv |
| D8 | country-specific validators | brgr, tebbr, corsa, lexa | app-specific |
| D9 | core → features imports / barrels | tebbr, cp ×2, instaops, petrobe, baytna, corsa | core must not know features |
| D10 | LoggingInterceptor registered but never attached | brgr, tebbr, cp-seller, instaops, petrobe | dead code |
| D11 | deprecated APIs (withOpacity, WillPopScope, `ColorScheme.background`, `Radio.groupValue`) | brgr, tebbr, instaops, petrobe, cp-customer | current APIs |
| D12 | empty `dark_theme.dart` / `price_converter.dart` | brgr, tebbr, cp ×2, instaops, petrobe | dead files |
| D13 | low-quality widgets (§2 last row) | house style | themed Material |
| D14 | static NotificationService (fresh-plugin bug) | brgr, tebbr, instaops | buggy; replaced by K35 |
| D15 | app-specific features: geofencing, alarm foreground service, Agora / AI studio, Reverb sockets, maps picker, location tracking, PDF / Excel export, voice recorder, QR, story viewer, multi-account FirebaseApp, runtime white-label palette | various | business logic; IAP / maps / sockets documented as optional recipes |
| D16 | `copy_feature.dart` blind replace | petrobe | superseded by `create_feature.dart` |
| D17 | release-mode BlocObserver logging | brgr, petrobe | noise, leaks data |
| D18 | hand-copied pagination listeners | cp-customer ×10, petrobe ×36, brgr, instaops | replaced by K13 |

**Counts:** kept **41** infrastructure items and **31** widget types. They're picked from ~110
duplicate variants across the 12 apps. Dropped **18** item groups.

---

## 5. Core choices where projects disagree — recommendations

| # | Choice | Recommendation | Alternative | Why |
|---|---|---|---|---|
| C1 | Result type | **sealed `Result<T>`** with `fold` / `map` / `when` | dartz `Either` (9 apps; unmaintained) or fpdart; or thrown sealed Failures (markspulse, lexa) | zero dependency, exhaustive `switch`, same `fold` call sites |
| C2 | Sizing | **No flutter_screenutil.** Tokens + breakpoints + clamped text scale (baytna, markspulse, lexa) | screenutil with corsa's clamped design size | `.sp` stacks with system text scale; tebbr / cp rebuild ThemeData per scale; corsa had to clamp it |
| C3 | State base | **one `BaseCubit<S>` + generic `DataCubit<T>`** | two bases (house style) | 8 apps mix both |
| C4 | DI | **get_it, manual, one file per feature**; constructor injection only | injectable (baytna) or no locator (markspulse / lexa) | familiar, no codegen |
| C5 | Domain layer | **data + presentation required; domain with optional use cases** (corsa rule) | guarded use cases everywhere (markspulse / lexa); documented as the pattern for role-based apps | no pass-through use cases |
| C6 | Feedback UI | **`AppSnackBar`** | overlay toast | accessible, themed |
| C7 | Firebase / push / crash / IAP | **opt-in modules**: interfaces + no-op in the template, real implementations as recipes | bake Firebase in | template runs, analyzes and tests with zero accounts |
| C8 | Skeletons | **skeletonizer** over the real widget | shimmer (baytna) | no hand-drawn skeletons |
| C9 | L10n keys | **easy_localization + generated `LocaleKeys`** + parity / used-key checks | raw `'key'.tr()` | compile-time safety |

## 6. Where your conventions and these projects differ

1. **Breakpoints by `shortestSide`.** The in-scope apps all use **width** for layout. cp-customer's
   CLAUDE.md says so on purpose (rotation and Split View). corsa uses width 600/840 (your exact
   numbers, which are Material 3 *window-width* classes) and keeps `shortestSide` only for the
   phone portrait lock; lexa uses width as well. With `shortestSide`, an iPad in Split View
   (≈400 px wide) still counts as a tablet.
   **Proposal:** your thresholds; `windowClass` (width) drives layout and `context.responsive()`;
   `deviceClass` (`shortestSide`) is for device decisions. **(Q1)**
2. **Text scaling 1.0–1.3.** Kept; it matches cp-customer and lexa-student.
3. **`.env` + `.env.example`.** Kept, via `--dart-define-from-file=.env` (verified in Flutter 3.44;
   compile-time, no asset). JSON credentials (path or base64) are for `tool/` and CI only.
4. **easy_localization en / ar.** Kept, plus generated LocaleKeys, parity tests and the translation
   checker.
5. **RTL-first.** Kept and enforced by a test. Added: `forceLtr` for email / phone / number fields
   (lexa) and a digits policy, Western by default (markspulse).
6. **Theme-centralised text and buttons.** Kept. Added: semantic ThemeExtension (baytna /
   markspulse), dialog / sheet width caps in the theme (cp-customer), and a colour-literal test.

## 7. Templates to build

- **flutter_template**: runnable. Its `sample_feature` ("items": a paginated list, a detail page,
  and a create form that maps 422 field errors) runs on the mock interceptor with no backend.
- **functions_template** (optional, **Q3**): Firebase Functions in TypeScript from markspulse.
  Pure `*_logic` modules tested with node:test, one `app.ts` with initializeApp +
  setGlobalOptions(region), `defineString` / `defineSecret` params, JSON credentials from a path
  or base64.
- No react / laravel templates (none in scope).

## 8. Warnings found while scanning (values not read or copied)

In scope:
- **Tracked in git:** petrobe `android/app/playstore-key.json` (Play service account).
- **Credentials in source:**
  - hardcoded demo / fallback logins in brgr and instaops (`lib/features/auth/data/repositories/auth_repo.dart`)
  - static API-key header in petrobe `lib/core/services/api_service.dart`
  - third-party key in tebbr `lib/core/utilities/constants/keys/api_keys.dart` and `reverb_socket_client.dart`
  - lexa-control `tool/firestore_rest.dart`
- **Google Maps keys in native files / Dart:** brgr, petrobe.
- **Logging:** tebbr logs bearer tokens (TalkerDioLogger headers in all builds); petrobe logs the
  API token at splash.
- **Signing material in working trees:** markspulse has it, gitignored and never committed.

Other projects (not in scope, but urgent): a live Tap Payments secret key sits client-side in the
old Chinaparts customer apps (`lib/data/repository/payment_gateway_repo.dart`). Rotate it.

## 9. Approved decisions (2026-11-05)

- **Breakpoints:** form factor comes from **`shortestSide`** of the window: phone < 600, tablet
  600–839, large tablet ≥ 840, all in one helper. Correction to §6.1: `MediaQuery.sizeOf`
  returns the *window* size, so `shortestSide` already follows Split View, multi-window and
  fold / unfold; the "Split View still counts as tablet" objection was wrong. Local layout
  (grid columns, two panes) still uses the parent's `LayoutBuilder` constraints.
- **C1:** sealed `Result<T>`.
- **C2:** no flutter_screenutil. Responsiveness on phones, tablets and foldables comes from
  form-factor tokens (gutters, max content widths, type scale), an adaptive navigation shell
  (bottom bar ↔ rail), adaptive grids from constraints, and hinge-aware two-pane layouts
  (`MediaQuery.displayFeatures`).
- **Font size:** the system font-size setting has little effect. A damped `TextScaler` applies
  only **50%** of the user's increase and clamps the result to **1.0–1.3**, per font size, so it
  respects Android 14 non-linear scaling. It is tebbr's `AppTextScale` idea, kept within your
  1.0–1.3 bounds.
- **Language:** start in **Arabic**; **English** is always the second language and the fallback
  locale. A language the user chose is remembered.
- **C3–C9:** approved as recommended.
- **functions_template:** not requested, so not built.
