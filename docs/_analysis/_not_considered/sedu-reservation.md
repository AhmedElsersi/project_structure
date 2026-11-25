# sedu-reservation — Phase 1 analysis

## Summary for comparison

```
PROJECT: sedu-reservation | path: My Apps/Sedu/Sedu Reservation | stack: Flutter (CI pins 3.44.0), Dart '>=3.8.0 <4.0.0' | last commit: 2026-09-01 | source files: 118
ARCH: clean-arch-lite, feature-first — features/<f>/{data/{data_sources,models,repo}, presentation/{managers,screens,widgets}}; NO domain layer (repos are concrete, models double as entities); shared base classes, services, widgets and a barrel file in lib/core/
STATE: flutter_bloc (Cubit only) — BaseCubit<S>.executeCall/safeEmit (lib/core/base_architecture/presentation/managers/base_cubit.dart) + BaseSingleStateCubit<T> with generic SingleState<T>{FetchStatus,data,failure} (lib/core/base_architecture/presentation/managers/base_single_state_cubit.dart); sealed per-feature state hierarchies; 5 app-scoped cubits provided in main.dart
DI: get_it (manual, global `diService`) — lib/core/services/di_service.dart (lazy singletons for services/data sources/repos, factories for screen cubits, lazy singletons for app-scoped cubits)
ROUTING: go_router 17 (flat GoRoute list, path constants) — lib/core/app_router/app_router.dart + app_routes_names.dart — guards? no (no redirect; SplashCubit decides start vs home) — deep links? no (data routes require `state.extra! as X`)
NETWORK: firebase (cloud_firestore only; no REST/dio) — interceptors: n/a | token refresh: n | retry: n (30s timeout per call) | error mapping: BaseRemoteDataSource.handleRequest maps TimeoutException/SocketException/FirebaseException.code → sealed AppException; BaseRepository.handleNetworkCall returns Left(exception.failure) | files: lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/base_architecture/data/repository/base_repository.dart, lib/core/services/firestore_service.dart
RESULT_TYPE: Either (dartz) — sealed Failure with localizationKey: lib/core/utilities/failures/failures.dart (+ sealed AppException that knows its Failure: lib/core/utilities/failures/app_exceptions.dart)
STORAGE: shared_preferences — lib/core/services/cache_service.dart (getJson/saveJson + scoped clearSession) + lib/core/utilities/constants/cache_keys.dart
L10N: easy_localization — ar, en; start+fallback locale ar; assets/translations/{ar,en}.json (173 lines each, nested keys) — hardcoded UI strings: few (MaterialApp title, an Arabic list separator; an Arabic address list lives as data in AppConstants)
RTL: Directional=1 vs LeftRight=12 (all 12 are LinearGradient begin/end Alignment.topRight/bottomLeft; zero LTR-only paddings; drawerTheme uses BorderRadiusDirectional; chevrons flip via Directionality)
THEME: lib/core/theme/app_theme.dart — dark mode y (AppCubit.toggleTheme, persisted) | component themes y (appBar, card, input, elevated+outlined buttons, chip, dialog, drawer, divider, progress, snackBar) | colors class lib/core/utilities/constants/app_colors.dart | text styles class: none (GoogleFonts.cairoTextTheme + context.textTheme) | fonts: Cairo via google_fonts (runtime fetch, not bundled)
RESPONSIVE: screenutil (393x852, minTextAdapt) + custom breakpoint layer lib/core/presentation/responsive/{breakpoints,responsive_extensions,adaptive_container}.dart — breakpoints: 600 / 1024 on width (MediaQuery.sizeOf)
TEXT_SCALING: lib/main.dart MaterialApp.builder → _withResponsiveTextScale: textScaler.scale(1).clamp(0.85, 1.3) re-wrapped as TextScaler.linear; widgets add capped tablet bumps via context.responsive(mobile: 16.sp, tablet: 17)
ENV/FLAVORS: hardcoded constants (lib/core/utilities/constants/app_constants.dart); Firebase via native google-services.json (no firebase_options.dart); no flavors / dotenv / --dart-define; GitHub Actions CD in .github/workflows/flutter.yml
LOGGING: logger (static AppLogger wrapper lib/core/services/app_logger.dart, warning+ in release) + AppBlocObserver; zero print/debugPrint
ANALYTICS/CRASH: none (runZonedGuarded → AppLogger only)
PUSH: none — in-app derived notifications instead (pure diff engine lib/core/services/notification_engine.dart + NotificationsCubit + SharedPreferences "seen" snapshot)
PAYMENTS/IAP: none
PERMISSIONS: none (no permission_handler; AndroidManifest declares unused READ/WRITE_EXTERNAL_STORAGE)
DEEP_LINKS: none (no app_links/uni_links; routes need `extra`)
MEDIA/FILES: Image.asset only + url_launcher (store link); no image_picker / cached_network_image / file_picker
TESTS: 13 files (~124 tests) — NotificationEngine (45), SettingsRules (15), PlatformSettings parsing (14), ReservationRepository transaction with fake txn (9), AppGate/forcedUpdate (8), AppUpdateCubit (7), responsive + font-scaling + no-overflow widget tests (12), ConnectivityCubit debounce w/ fake_async (5), CacheService.clearSession, AppVersion, notifications local DS
LINTS: flutter_lints 6 (package:flutter_lints/flutter.yaml), 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/app_cubit/connectivity_cubit.dart — reachability cubit: immediate reconnect, debounced offline (delay + N re-checks), injectable InternetReachability test seam, custom 200/204 probe list — quality 5 — coupling: none
- lib/core/utilities/failures/failures.dart + lib/core/utilities/failures/app_exceptions.dart — sealed Failure (message + localizationKey) and sealed AppException exposing `.failure` (no mapping switch needed in repos) — quality 5 — coupling: none
- lib/core/base_architecture/data/repository/base_repository.dart — handleNetworkCall<T> → Either<Failure,T> with unknown-error logging — quality 4 — coupling: none
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — handleRequest<T>: timeout + Firebase error-code → typed exception — quality 4 — coupling: low (Firestore codes; swap the switch for Dio)
- lib/core/base_architecture/presentation/managers/base_single_state_cubit.dart — SingleState<T> + execute/emitLoading/emitSuccess/emitFailure/safeEmit — quality 4 — coupling: none (copyWith cannot null `data`)
- lib/core/base_architecture/presentation/managers/base_cubit.dart — executeCall(call,onLoading,onSuccess,onFailure) with isClosed guard + safeEmit — quality 4 — coupling: none
- lib/core/presentation/responsive/responsive_extensions.dart (+ breakpoints.dart, adaptive_container.dart, responsive.dart barrel) — ScreenType enum, context.responsive<T>(), isTablet, scale(), maxContentWidth, AdaptiveContainer — quality 4 — coupling: none
- lib/core/services/app_version.dart — package_info_plus wrapper: build number + display string, fail-open on error, debug test seam — quality 4 — coupling: low (AppConstants fallback name)
- lib/core/utilities/helpers/app_gate.dart — pure gate priority resolver (offline > maintenance > forced update) + forcedUpdateRequired (fail-open) — quality 4 — coupling: low (AppVersion)
- lib/core/theme/app_theme.dart — explicit M3 ColorScheme for light/dark + 11 component themes — quality 4 — coupling: low (AppColors; .r/.w/.h inside ThemeData)
- lib/core/services/app_logger.dart + lib/core/services/app_bloc_observer.dart — static logger facade + bloc observer — quality 4 — coupling: none
- lib/main.dart — bootstrap pattern: runZonedGuarded, ordered async init, MultiBlocProvider, MaterialApp.builder (text clamp + connectivity BlocListener + MaintenanceGate overlay) — quality 4 — coupling: high (app cubits)
- lib/core/services/cache_service.dart — SharedPreferences wrapper (bool/int/string/json) + scoped clearSession that preserves language/theme — quality 3 — coupling: low (session keys app-specific)
- lib/core/services/firestore_service.dart — Firestore facade (get/stream/set/query/transaction) + SDK-free FirestoreTransaction — quality 3 — coupling: low (Firestore only)
- .github/workflows/flutter.yml (+ release-notes/whatsnew-*) — CI: flutter test → signed AAB from base64 secrets → Play upload with localized release notes — quality 4 — coupling: low
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/default_app_button.dart — primary/outlined button — text, onTap, isLoading, enabled, icon, backgroundColor, outlined — quality 4 — generic? y
- lib/core/utilities/widgets/default_text_field.dart — label-above TextFormField — controller, label, hint, keyboardType, maxLength, onChanged, validator, prefixIcon, textInputAction, digitsOnly — quality 3 — generic? y (no obscureText/suffix/maxLines/enabled)
- lib/core/utilities/widgets/default_dropdown_field.dart — generic DropdownButtonFormField<T> — items, itemLabel, onChanged, value, label, hint, prefixIcon — quality 4 — generic? y
- lib/core/utilities/widgets/default_screen.dart — base scaffold (AppBar + SafeArea + padding + AdaptiveContainer) — body, title, titleWidget, actions, leading, endDrawer, scaffoldKey, showAppBar, automaticallyImplyLeading, padding, backgroundColor, extendBodyBehindAppBar, bottomBar — quality 4 — generic? y
- lib/core/presentation/responsive/adaptive_container.dart — tablet max-width centring wrapper — child, maxWidth — quality 4 — generic? y
- lib/core/utilities/widgets/empty_state_widget.dart — empty/error state — icon, title, subtitle — quality 4 — generic? y
- lib/core/utilities/widgets/shimmer_loading.dart — ShimmerCardList(itemCount, itemHeight) + ShimmerBox(height, width, radius) — quality 3 — generic? y (hardcoded hex shimmer colors)
- lib/core/utilities/widgets/app_toast.dart — showAppToast(message, {ToastState}) over fluttertoast — quality 3 — generic? y
- lib/core/utilities/widgets/animated_entrance.dart — staggered slide+fade entrance — child, delay — quality 4 — generic? y
- lib/core/utilities/widgets/comment_dialog.dart — read-only title/body dialog with static show() — title, comment — quality 3 — generic? y (fixed note icon)
- lib/core/utilities/widgets/no_internet_screen.dart — offline route that auto-pops on reconnect + reload button — (none) — quality 3 — generic? n (ConnectivityCubit, asset)
- lib/features/maintenance/presentation/widgets/maintenance_gate.dart — Stack overlay above the navigator driven by live settings — child — quality 4 — generic? n (pattern y)
- lib/features/maintenance/presentation/screens/maintenance_screen.dart — blocking maintenance page (PopScope) with remote message — (none) — quality 3 — generic? n
- lib/features/app_update/presentation/widgets/app_update_guard.dart — wraps a screen, shows forced-update dialog post-frame — child — quality 4 — generic? n (pattern y)
- lib/features/app_update/presentation/widgets/app_update_dialog.dart — non-dismissible update dialog, idempotent static show — cubit — quality 3 — generic? n
- lib/features/home/presentation/widgets/home_feature_card.dart — gradient-icon grid tile — icon, label, color, onTap — quality 4 — generic? y
- lib/features/start/presentation/widgets/start_action_card.dart — list action card with RTL-aware chevron — icon, iconColor, title, subtitle, onTap — quality 3 — generic? y
- lib/features/profile/presentation/widgets/profile_info_tile.dart — icon + label/value row — icon, label, value — quality 3 — generic? y
- lib/features/reservation/presentation/widgets/reservation_stepper_header.dart — 3-step progress header — currentStep (step keys hardcoded) — quality 3 — generic? n (easy to generalize)
- lib/features/home/presentation/widgets/home_hero_header.dart — gradient header + notification bell badge — student, onBellTap, badgeCount — quality 3 — generic? n
- lib/features/home/presentation/widgets/home_drawer.dart — end drawer (profile, theme toggle, logout) — (none) — quality 3 — generic? n
- (app-specific cards: exam_card, homework_card, attendance_card, fee_card, notification_card, notifications_section, profile_subject_card, subject_chips, reservation_success_view) — generic? n
NOTABLE_IDEAS: (1) debounced ConnectivityCubit with test seam + fake_async tests (lib/core/app_cubit/connectivity_cubit.dart, test/core/app_cubit/connectivity_cubit_test.dart); (2) sealed AppException carrying its own Failure + Failure.localizationKey so UI does `failure.localizationKey.tr()` (lib/core/utilities/failures/); (3) remote kill-switch trio driven by one live Firestore settings doc: maintenance overlay in MaterialApp.builder (features/maintenance/.../maintenance_gate.dart), forced update via BlocBuilder + addPostFrameCallback + idempotent `_isShowing` (features/app_update/.../app_update_guard.dart), and a pure priority resolver (core/utilities/helpers/app_gate.dart); (4) AppVersion read from package_info_plus with fail-open semantics instead of a hand-maintained constant (core/services/app_version.dart); (5) tolerant Firestore coercion helpers _asBool/_asInt/_asString + catching parse errors inside the stream onData so a bad doc can't freeze a cubit (core/models/platform_settings_model.dart, core/app_cubit/settings_cubit.dart); (6) scoped session clear that keeps language/theme (core/services/cache_service.dart clearSession) + remote sessionEpoch to invalidate all sessions (features/splash/.../splash_cubit.dart); (7) pure, fully unit-tested NotificationEngine diffing a cached "seen" snapshot to derive in-app notifications without push (core/services/notification_engine.dart); (8) transaction facade + ReservationTransactionContext interface so transactional logic is unit-testable with a fake (core/services/firestore_service.dart, features/reservation/data/data_sources/reservation_remote_data_source.dart); (9) text-scale clamp in MaterialApp.builder (lib/main.dart); (10) CI → Play upload with localized whatsnew files (.github/workflows/flutter.yml, release-notes/); (11) core barrel export file (lib/core/exports/core_exports.dart)
SMELLS: Play service-account JSON (android/app/playstore-key.json) and google-services.json are tracked in git (key.properties/*.jks are ignored); hardcoded brand title in MaterialApp, store URL with package id and a client address list in AppConstants; router uses `state.extra! as SubjectType` (crash on restore/deep link) and has no redirect guard; feature cubits (Exams/Homework/Attendance/Fees) are new'd in screens with StudentSessionCubit.get(context) instead of DI; cubit→cubit dependencies (SplashCubit←SettingsCubit, NotificationsCubit←Session+Settings); 12 gradient Alignment.topRight/bottomLeft not mirrored in RTL; hardcoded shimmer hex colors + Colors.white; GoogleFonts runtime fetch (no bundled font); AppTheme.light/dark are getters rebuilt every BlocBuilder pass; reservation_screen.dart 478 lines (whole 3-step form in one State); unused READ/WRITE_EXTERNAL_STORAGE + sms/tel queries in AndroidManifest; returning-student login compares father's phone client-side after reading the doc (security rests on Firestore rules); Firestore contract types (PlatformSettingsModel, LevelType/SubjectType, address list, AppColors) are hand-copied from sedu_control and already drift (no year-scoped docIds here). No deprecated APIs found (uses PopScope, withValues, TextScaler, DropdownButtonFormField.initialValue).
```

---

## 1. Architecture pattern

**Feature-first "clean-arch-lite" with Cubits.** Each feature has a `data` layer (remote data source extending
`BaseRemoteDataSource`, plain models with `fromFirestore/toFirestore`, a concrete repository extending
`BaseRepository` that returns `Either<Failure, T>`) and a `presentation` layer (`managers/<name>_cubit/` with
`part`-file states, `screens/`, `widgets/`). There is **no domain layer**: no use cases, no abstract repository
interfaces, no separate entities; models are used directly by cubits and widgets.

Data flow:

```
Screen → Cubit (BaseCubit.executeCall / BaseSingleStateCubit.execute)
       → Repository.handleNetworkCall(() => …)            // Either<Failure,T>
       → RemoteDataSource.handleRequest(() => …)          // throws typed AppException
       → FirestoreService (thin SDK facade)
```

Two "flavours" of feature exist:

* **Request features** (reservation, tracking, app_update, splash) — call a repo through the base cubit.
* **Derived features** (exams, homework, attendance, fees, profile, notifications) — have *no* data source;
  their cubit subscribes to the app-scoped `StudentSessionCubit` (one live Firestore snapshot of the student
  document) and maps it to a feature state. This is an efficient pattern (one listener for the whole app) but
  the cubits are constructed inside screens (`ExamsCubit(StudentSessionCubit.get(context))..init(subject)`)
  rather than resolved from DI.

App-scoped state lives in `lib/core/app_cubit/`: `AppCubit` (theme + session persistence), `ConnectivityCubit`,
`SettingsCubit` (live `Settings/platform` doc), `StudentSessionCubit` (live student doc). `NotificationsCubit`
(feature) is also app-scoped. All are created in `main.dart`'s `MultiBlocProvider`.

Cross-cutting imports go through a barrel: `lib/core/exports/core_exports.dart` re-exports dartz (hiding
`State`, `id`), easy_localization, flutter_bloc, flutter_screenutil plus every core file.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                         bootstrap: zone, Firebase, date symbols, AppVersion, DI, EasyLocalization, app widget
├── core/
│   ├── app_cubit/                    app-scoped cubits: AppCubit(+app_state part), ConnectivityCubit, SettingsCubit, StudentSessionCubit
│   ├── app_router/                   app_router.dart (GoRouter), app_routes_names.dart (path constants)
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/         base_remote_data_source.dart (handleRequest + error mapping)
│   │   │   └── repository/           base_repository.dart (handleNetworkCall → Either)
│   │   └── presentation/
│   │       └── managers/             base_cubit.dart, base_single_state_cubit.dart (SingleState<T>)
│   ├── enums/                        fetch_status, level_type, subject_type, settings_visibility, notification_type, toast_state
│   ├── exports/                      core_exports.dart (barrel)
│   ├── extensions/                   context_extensions.dart (theme/colorScheme/textTheme/isDarkMode/screenSize/viewInsets)
│   ├── models/                       platform_settings_model.dart (shared remote-config doc), student_model.dart
│   ├── presentation/
│   │   └── responsive/               breakpoints, responsive_extensions, adaptive_container, responsive (barrel)
│   ├── services/                     di_service, cache_service, firestore_service, app_logger, app_bloc_observer, app_version, notification_engine
│   ├── theme/                        app_theme.dart
│   └── utilities/
│       ├── constants/                app_colors, app_constants, app_images, cache_keys, firestore_constants
│       ├── failures/                 failures.dart (sealed Failure), app_exceptions.dart (sealed AppException)
│       ├── formatters/               month_formatter.dart
│       ├── helpers/                  app_gate, grade_helper, settings_rules, student_doc_id
│       ├── timing/                   app_durations.dart
│       └── widgets/                  default_app_button, default_text_field, default_dropdown_field, default_screen,
│                                     empty_state_widget, shimmer_loading, app_toast, comment_dialog, animated_entrance, no_internet_screen
└── features/
    ├── app_update/      data/{data_sources,repo}, presentation/{managers,widgets}   forced-update guard + dialog (legacy fallback source)
    ├── attendance/      data/models, presentation/{managers,screens,widgets}        derived from session
    ├── exams/           data/models, presentation/{managers,screens,widgets}        derived from session
    ├── fees/            data/models, presentation/{managers,screens,widgets}        derived from session
    ├── home/            data/{data_sources,repo}, presentation/{screens,widgets}    student data source/repo shared via DI
    ├── homework/        data/models, presentation/{managers,screens,widgets}        derived from session
    ├── maintenance/     presentation/{screens,widgets}                              overlay gate
    ├── notifications/   data/{data_sources,models}, presentation/{managers,widgets} in-app notifications
    ├── profile/         presentation/{screens,widgets}
    ├── reservation/     data/{data_sources,models/{requests,responses},repo}, presentation/{managers,screens,widgets}
    ├── splash/          presentation/{managers,screens}                             session validation + routing
    ├── start/           presentation/{screens,widgets}                              reserve vs. track entry
    └── tracking/        data/repo, presentation/{managers,screens}                  returning-student login
```

**Representative feature fully expanded — `features/reservation/`:**

```
reservation/
├── data/
│   ├── data_sources/reservation_remote_data_source.dart   ReservationTransactionContext (abstract) + ReservationRemoteDataSource
│   │                                                      (isStudentPhoneTaken, maxExistingStudentId, runReservationTransaction)
│   │                                                      + private Firestore-backed transaction context
│   ├── models/requests/reservation_request_model.dart     form → StudentModel mapping
│   ├── models/responses/reservation_result_model.dart     docId, assignedId, studentKey (Equatable)
│   └── repo/reservation_repo.dart                         reserve(): dup-phone check → recovery max id → transaction
│                                                          (re-validate settings, read counter, write counter + student)
└── presentation/
    ├── managers/reservation_cubit/{reservation_cubit.dart, reservation_state.dart}
    │      BaseCubit<ReservationState>; sealed Initial/Loading/Success(result)/Failure(failure)
    ├── screens/reservation_screen.dart                    BlocProvider(diService<ReservationCubit>) + 3-step form
    └── widgets/{reservation_stepper_header, reservation_success_view, subject_chips}.dart
```

Cubit pattern (verbatim, short):

```dart
class ReservationCubit extends BaseCubit<ReservationState> {
  ReservationCubit(this._repository) : super(const ReservationInitial());
  final ReservationRepository _repository;

  Future<void> reserve(ReservationRequestModel request) {
    return executeCall<ReservationResultModel>(
      call: () => _repository.reserve(request),
      onLoading: () => safeEmit(const ReservationLoading()),
      onSuccess: (result) => safeEmit(ReservationSuccess(result)),
      onFailure: (failure) => safeEmit(ReservationFailure(failure)),
    );
  }
}
```

Screens consume sealed states with Dart 3 pattern matching:
`return switch (state) { ExamsLoading() => const ShimmerCardList(), ExamsEmpty() => EmptyStateWidget(...), ExamsError(:final failure) => ..., ExamsLoaded(:final exams) => ListView.separated(...) };`

## 3. Infrastructure

### 3.1 State management
* **Package:** flutter_bloc ^9.1.1, equatable ^2.0.7. Cubits only, no Blocs/events.
* **Base classes:**
  * `lib/core/base_architecture/presentation/managers/base_cubit.dart` — `BaseCubit<S>` with
    `executeCall<T>({call, onSuccess, onFailure, onLoading})` (checks `isClosed` after the await) and `safeEmit`.
  * `lib/core/base_architecture/presentation/managers/base_single_state_cubit.dart` — `SingleState<T>`
    (`status`, `data`, `failure`, `copyWith`) and `BaseSingleStateCubit<T>` with `execute`, `emitLoading`,
    `emitSuccess`, `emitFailure`, `safeEmit`. Used by `StudentSessionCubit` and `AppUpdateCubit`.
    Note: `copyWith` keeps `data` when null is passed (cannot clear data) and always resets `failure` unless passed.
* **Status enum:** `lib/core/enums/fetch_status.dart` (`initial/loading/success/failure` + `isX` getters on the enum).
* **Observer:** `lib/core/services/app_bloc_observer.dart` logs state type transitions and errors.
* **Accessors:** each app-scoped cubit has `static X get(BuildContext context) => context.read<X>()`.
* **Quality:** good, consistent, null-safe, emissions are guarded. Two base classes is a reasonable split
  (multi-state sealed hierarchies vs single-state). Weakness: cubits depend on other cubits (constructor-injected
  `SettingsCubit`, `StudentSessionCubit`) instead of repositories/streams.

### 3.2 Dependency injection
* **Package:** get_it ^9.2.1, manual registration in `lib/core/services/di_service.dart`; global `final GetIt diService = GetIt.instance;` and `Future<void> diContainerSetup()`.
* Convention: core services/data sources/repos = `registerLazySingleton`; screen cubits = `registerFactory`;
  app-scoped cubits = `registerLazySingleton` (resolved once in `main.dart`). `CacheService` is created async
  (`await CacheService.create()`) before registration.
* Typed generic resolution (`diService<StudentRepository>()`), readable. No modules/feature split; the core
  file imports every feature (core → features dependency inversion).

### 3.3 Routing
* **Package:** go_router ^17.3.0. `lib/core/app_router/app_router.dart` exposes a top-level `final GoRouter appRouter`
  with 11 flat `GoRoute`s; paths in `lib/core/app_router/app_routes_names.dart` (`'/'`, `'/start'`, `'/home'`, …).
* Arguments via `state.extra! as SubjectType` (exams/homework/attendance) — not deep-link safe and crashes on
  process restoration.
* **Guards:** none. `SplashCubit` decides home vs start; the no-internet screen is pushed imperatively from a
  `BlocListener<ConnectivityCubit>` in `MaterialApp.builder` via `appRouter.push(...)`; maintenance is an overlay,
  not a route.
* Navigation calls: `context.go` / `context.push` / `context.pop`.

### 3.4 Networking (Firestore)
* **No HTTP client.** Backend = Cloud Firestore (`cloud_firestore ^6.6.0`), initialized with
  `Firebase.initializeApp()` (native config files).
* **Facade:** `lib/core/services/firestore_service.dart` — `getDocument`, `documentStream`, `setDocument(merge)`,
  `queryWhereEqual`, `queryWhereEquals(filters map)`, `runTransaction` (exposes an SDK-free
  `FirestoreTransaction` with `get/set/serverTimestamp`), `documentReference`.
* **Error mapping:** `BaseRemoteDataSource.handleRequest` (30 s timeout):

```dart
} on async.TimeoutException {
  throw const TimeoutException();
} on SocketException {
  throw const NetworkException();
} on FirebaseException catch (error) {
  throw switch (error.code) {
    'permission-denied' => const PermissionException(),
    'not-found' => const NotFoundException(),
    'unavailable' || 'network-request-failed' => const NetworkException(),
    'deadline-exceeded' => const TimeoutException(),
    _ => ServerException(error.message ?? 'Server error'),
  };
}
```

  `BaseRepository.handleNetworkCall` then does `on AppException catch (e) { return Left(e.failure); }`.
* **Retry:** none (Firestore SDK retries internally). **Token refresh:** n/a (no auth at all — students are
  identified by a cached document id + key).
* Streams (`studentStream`) bypass `handleRequest`; errors are handled in the cubit's `onError`.

### 3.5 Result type & failures
* `dartz ^0.10.1` `Either<Failure, T>`.
* `lib/core/utilities/failures/failures.dart`: `sealed class Failure extends Equatable { message; String get localizationKey; }`
  with `ServerFailure`, `NetworkFailure`, `PermissionFailure`, `NotFoundFailure`, `TimeoutFailure`,
  `UnknownFailure`, `ValidationFailure(messageKey)` (domain errors carry a ready translation key).
* `lib/core/utilities/failures/app_exceptions.dart`: `sealed class AppException implements Exception` with a
  `Failure get failure` per subclass, plus `ValidationException(messageKey)` thrown from repositories for
  business rules (`'reservation.errors.phone_exists'`).
* UI: `showAppToast(state.failure.localizationKey.tr(), state: ToastState.error)`. Clean and template-worthy.

### 3.6 Local storage
* `shared_preferences ^2.5.3` wrapped by `lib/core/services/cache_service.dart` (`create()`, `getBool/getString/getInt/getJson`,
  `saveBool/saveString/saveInt/saveJson`, `remove`, `clear`, `clearSession`). Keys in `lib/core/utilities/constants/cache_keys.dart`.
* `clearSession()` removes only session keys (+ per-student snapshot) and keeps language/theme — a good pattern.
* No secure storage (no tokens to protect), no Hive/sqflite.

### 3.7 Localization (+RTL)
* `easy_localization ^3.0.8` with `assets/translations/ar.json` / `en.json` (173 lines each, nested keys:
  `reservation.errors.phone_exists`, `errors.network`, …). `supportedLocales: [ar, en]`, `startLocale` and
  `fallbackLocale` = `ar`. `initializeDateFormatting('ar'/'en')` in `main`. No in-app language switcher.
* 136 `.tr()` call sites; hardcoded UI strings are rare (MaterialApp `title`, a `'، '` join separator).
* RTL: essentially no LTR-only layout: the only left/right hits are 12 gradient `Alignment.topRight/bottomLeft`.
  `AlignmentDirectional.centerEnd` used in dialogs, `BorderRadiusDirectional` in drawer theme, chevron flips with
  `Directionality.of(context)`. Arabic-first app with good RTL hygiene.

### 3.8 Theming
* `lib/core/theme/app_theme.dart` — `AppTheme.light` / `AppTheme.dark` getters → `_build(Brightness)` producing a
  fully specified Material 3 `ColorScheme` (every role set explicitly from `AppColors`) and component themes:
  `appBarTheme` (centered, flat, overlay style per brightness), `cardTheme`, `inputDecorationTheme` (filled,
  outlined, focused/error borders), `elevatedButtonTheme`, `outlinedButtonTheme` (full-width 52.h min),
  `chipTheme`, `dialogTheme`, `drawerTheme`, `dividerTheme`, `progressIndicatorTheme`, `snackBarTheme` (floating).
* Typography: `GoogleFonts.cairoTextTheme(...)` applied with onSurface colors. No custom TextStyles class —
  widgets use `context.textTheme.titleMedium?.copyWith(...)`.
* Colors: `lib/core/utilities/constants/app_colors.dart` (brand, semantic + light variants, light/dark surfaces &
  text, hero gradient, subject colors).
* Dark mode: `AppCubit` holds `ThemeMode`, persisted in prefs (`CacheKeys.isDarkTheme`), toggled from the drawer.
* Quality 4: complete and consistent; minor issues: ScreenUtil units (`16.r`, `52.h`) inside ThemeData, ThemeData
  rebuilt on every builder pass (getters), fonts fetched at runtime.

### 3.9 Responsive helpers
* `flutter_screenutil ^5.9.3`, `ScreenUtilInit(designSize: Size(393, 852), minTextAdapt: true)`.
* Breakpoint layer `lib/core/presentation/responsive/`:
  * `breakpoints.dart` — `enum ScreenType { mobile, tablet, largeTablet }`, `Breakpoints.tablet = 600`, `largeTablet = 1024`, `fromWidth()`.
  * `responsive_extensions.dart` — `extension ResponsiveContext on BuildContext`: `screenWidth/Height`,
    `orientation`, `isLandscape`, `screenType`, `isMobile/isTablet/isLargeTablet`,
    `responsive<T>({mobile, tablet, largeTablet})`, `scale(value, {tablet: 1.15, largeTablet: 1.3})`,
    `maxContentWidth` (∞ / 640 / 880).
  * `adaptive_container.dart` — centres + caps width on tablets; identity on phones.
* Breakpoints are on **width** (`MediaQuery.sizeOf`). Used in `DefaultScreen`, buttons (`responsive(mobile: 16.sp, tablet: 17)`),
  and home grid (`crossAxisCount: responsive(mobile: 2, tablet: 3, largeTablet: 4)`).
* Tested by `test/core/presentation/responsive/*` (breakpoints, font sizes per device, no-overflow renders).

### 3.10 Text scaling
`lib/main.dart`:

```dart
MediaQueryData _withResponsiveTextScale(MediaQueryData media) {
  final factor = media.textScaler.scale(1).clamp(0.85, 1.3);
  return media.copyWith(textScaler: TextScaler.linear(factor));
}
```

Applied in `MaterialApp.router(builder: ...)`. Works; `textScaler.clamp(minScaleFactor:, maxScaleFactor:)`
(as in sedu-control) would preserve non-linear OS scaling.

### 3.11 Env / flavors
None. Constants in `lib/core/utilities/constants/app_constants.dart` (marketing version fallback, store URL
(contains package id → use `com.example.app` in template), Arabic address list, local phone regex). Firebase
configured natively (`android/app/google-services.json`, iOS plist). Single Android signing config reading
`android/key.properties`. CI at `.github/workflows/flutter.yml`: Flutter 3.44.0 → `flutter pub get` →
`flutter test` → decode keystore + key.properties + Play service account from GitHub secrets → `flutter build
appbundle --release` → `r0adkll/upload-google-play` with `release-notes/whatsnew-{en-US,ar}`.

### 3.12 Logging
`logger ^2.6.0` wrapped by `lib/core/services/app_logger.dart` (`AppLogger.debug/info/warning/error(msg, [stack])`,
level `warning` in release, `debug` otherwise). `AppBlocObserver` and `runZonedGuarded` route to it. No print.

### 3.13 Analytics / crash reporting
None. Uncaught zone errors are only logged.

### 3.14 Push notifications
None (no FCM / local notifications). Instead an **in-app notification engine**:
`lib/core/services/notification_engine.dart` (pure static functions: `generate`, `initialSnapshot`,
`markExamsSeen/markHomeworkSeen/markAttendanceSeen/markFeesSeen`, `reconcileCounts`, `reconcilePaidMonths`)
diffs the live student doc against a per-student "seen" snapshot persisted by
`features/notifications/data/data_sources/notifications_local_data_source.dart`; `NotificationsCubit`
recomputes on session/settings stream events. Domain-specific but the "derived notification from a cached
snapshot" pattern is clean and heavily tested (45 tests).

### 3.15 IAP / payments
None.

### 3.16 Permissions
No runtime permission handling. AndroidManifest declares `INTERNET`, `READ_EXTERNAL_STORAGE`,
`WRITE_EXTERNAL_STORAGE` (the storage ones are unused) and `<queries>` for `sms`/`tel` schemes.

### 3.17 Deep links
None. go_router paths exist but data routes require `extra`.

### 3.18 Remote config / gates (bonus — notable)
* `SettingsCubit` (`lib/core/app_cubit/settings_cubit.dart`) keeps a live listener on one Firestore settings doc,
  falls back to `PlatformSettingsModel.allOpen()` on missing doc, stream error or parse error (parse errors are
  caught *inside* `onData`, with a comment explaining why `onError` would not see them).
* `lib/core/utilities/helpers/app_gate.dart` encodes priority `offline → maintenance → update` and a fail-open
  `forcedUpdateRequired`.
* `MaintenanceGate` (Stack overlay in `MaterialApp.builder`) and `AppUpdateGuard` (wraps Start/Home) consume it;
  `AppVersion` (package_info_plus) supplies the local build number.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/services/di_service.dart | get_it container | `diService`, `diContainerSetup()` | get_it, all repos/cubits | pattern generic, content app-specific |
| lib/core/services/cache_service.dart | SharedPreferences wrapper | `create()`, `getBool/getString/getInt/getJson`, `saveBool/saveString/saveInt/saveJson`, `remove`, `clear`, `clearSession()` | shared_preferences, CacheKeys | generic (except clearSession keys) |
| lib/core/services/firestore_service.dart | Firestore facade + `FirestoreTransaction` | `getDocument`, `documentStream`, `setDocument`, `queryWhereEqual`, `queryWhereEquals`, `runTransaction`, `documentReference`; txn: `get`, `set`, `serverTimestamp` | cloud_firestore | generic (Firestore apps) |
| lib/core/services/app_logger.dart | logging facade | `debug`, `info`, `warning`, `error(msg,[stack])` | logger | generic |
| lib/core/services/app_bloc_observer.dart | BlocObserver | `onChange`, `onError` | flutter_bloc, AppLogger | generic |
| lib/core/services/app_version.dart | installed version | `init()`, `buildNumber`, `versionName`, `displayVersion`, `debugSetBuildNumber()` | package_info_plus, AppConstants | generic |
| lib/core/services/notification_engine.dart | derived in-app notifications | `generate`, `initialSnapshot`, `markExamsSeen`, `markHomeworkSeen`, `markAttendanceSeen`, `markFeesSeen`, `reconcileCounts`, `reconcilePaidMonths` | models, SettingsRules, MonthFormatter | app-specific (pattern reusable) |
| lib/core/app_cubit/app_cubit.dart | theme mode + session persistence | `get(ctx)`, `isStudent`, `studentDocId`, `toggleTheme()`, `saveSession(...)`, `logout()` | CacheService | semi-generic (theme part generic) |
| lib/core/app_cubit/connectivity_cubit.dart | internet reachability | `get(ctx)`, `startWatching()`, `hasConnection()`, `close()`; `InternetReachability` interface | internet_connection_checker_plus | generic |
| lib/core/app_cubit/settings_cubit.dart | live remote-config doc | `get(ctx)`, `startWatching()`, `fetchSessionEpoch()` | FirestoreService, PlatformSettingsModel | app-specific (pattern generic) |
| lib/core/app_cubit/student_session_cubit.dart | live current-user doc | `get(ctx)`, `watch(docId)`, `stop()`, `studentDocId` | StudentRepository, BaseSingleStateCubit | app-specific (pattern generic) |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | request wrapper | `handleRequest<T>()` (@protected) | cloud_firestore, AppException | generic |
| lib/core/base_architecture/data/repository/base_repository.dart | Either wrapper | `handleNetworkCall<T>()` (@protected) | dartz, Failure | generic |
| lib/core/base_architecture/presentation/managers/base_cubit.dart | base cubit | `executeCall<T>()`, `safeEmit()` | flutter_bloc, dartz | generic |
| lib/core/base_architecture/presentation/managers/base_single_state_cubit.dart | single-state cubit | `SingleState<T>`, `execute`, `emitLoading/Success/Failure`, `safeEmit` | flutter_bloc, equatable, dartz | generic |
| lib/core/utilities/failures/failures.dart | Failure hierarchy | 7 sealed subclasses, `localizationKey` | equatable | generic |
| lib/core/utilities/failures/app_exceptions.dart | exception hierarchy | 7 sealed subclasses, `failure` getter | failures.dart | generic |
| lib/core/utilities/helpers/app_gate.dart | gate priority + update check | `AppGate` enum, `resolveAppGate()`, `forcedUpdateRequired()` | AppVersion | generic |
| lib/core/utilities/helpers/settings_rules.dart | visibility/reservation rules | `isLevelVisible`, `isSubjectVisible`, `isReservationOpen`, `visibleLevels`, `visibleSubjects`, `visibleEnrolledSubjects` | models, enums | app-specific |
| lib/core/utilities/helpers/grade_helper.dart | grade bucket + color | `gradeKey(percent)`, `scoreColor(percent, attended)` | AppColors | app-specific |
| lib/core/utilities/helpers/student_doc_id.dart | doc-id builder | `buildStudentDocId(level, studentId, locationCode)` | FirestoreConstants | app-specific |
| lib/core/utilities/formatters/month_formatter.dart | month names | `englishMonths`, `monthNumber()`, `localizedMonthName()` | intl | semi-generic |
| lib/core/utilities/timing/app_durations.dart | animation durations | `splashDelay`, `fast`, `medium`, `slow` | — | generic |
| lib/core/utilities/constants/app_colors.dart | palette | static colors | flutter | generic shape |
| lib/core/utilities/constants/app_constants.dart | app constants | version name, store URL, addresses, phone regex | — | app-specific |
| lib/core/utilities/constants/app_images.dart | asset paths | static strings | — | generic shape |
| lib/core/utilities/constants/cache_keys.dart | pref keys | static strings | — | generic shape |
| lib/core/utilities/constants/firestore_constants.dart | collection/doc names | static strings | — | app-specific |
| lib/core/extensions/context_extensions.dart | BuildContext sugar | `theme`, `colorScheme`, `textTheme`, `isDarkMode`, `screenSize`, `viewInsets` | flutter | generic |
| lib/core/presentation/responsive/breakpoints.dart | breakpoints | `ScreenType`, `Breakpoints.tablet/largeTablet/fromWidth` | — | generic |
| lib/core/presentation/responsive/responsive_extensions.dart | responsive context ext | see 3.9 | flutter | generic |
| lib/core/enums/*.dart | FetchStatus (generic), ToastState (generic), LevelType/SubjectType/SettingsVisibility/NotificationType (app) | — | — | mixed |
| lib/core/models/platform_settings_model.dart | remote-config doc model (+ `_asBool/_asInt/_asString` coercers) | `fromFirestore`, `allOpen`, `resolveLocation`, `enabledLocations`, `isMaintenanceEnabled`, … | equatable | app-specific (coercers generic) |
| lib/core/models/student_model.dart | student doc model | `fromFirestore`, `toFirestore`, `marksOf/homeworksOf/attendancesOf`, … | equatable | app-specific |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/default_app_button.dart | Elevated/Outlined button with loader + icon, capped tablet font | `text`, `onTap`, `isLoading=false`, `enabled=true`, `icon`, `backgroundColor`, `outlined=false` | y |
| lib/core/utilities/widgets/default_text_field.dart | Label-above TextFormField, autovalidate on interaction | `controller`, `label`, `hint`, `keyboardType`, `maxLength`, `onChanged`, `validator`, `prefixIcon`, `textInputAction`, `digitsOnly` | y (limited) |
| lib/core/utilities/widgets/default_dropdown_field.dart | Generic dropdown form field | `items`, `itemLabel`, `onChanged`, `value`, `label`, `hint`, `prefixIcon` | y |
| lib/core/utilities/widgets/default_screen.dart | Base scaffold (AppBar, SafeArea, padding, AdaptiveContainer) | `body`, `title`, `titleWidget`, `actions`, `leading`, `endDrawer`, `scaffoldKey`, `showAppBar`, `automaticallyImplyLeading`, `padding`, `backgroundColor`, `extendBodyBehindAppBar`, `bottomBar` | y |
| lib/core/presentation/responsive/adaptive_container.dart | Tablet max-width centring | `child`, `maxWidth` | y |
| lib/core/utilities/widgets/empty_state_widget.dart | Empty / error placeholder | `icon`, `title`, `subtitle` | y |
| lib/core/utilities/widgets/shimmer_loading.dart | `ShimmerCardList`, `ShimmerBox` skeletons | `itemCount=4`, `itemHeight` / `height`, `width`, `radius` | y |
| lib/core/utilities/widgets/app_toast.dart | `showAppToast()` fluttertoast helper | `message`, `state` | y |
| lib/core/utilities/widgets/animated_entrance.dart | Slide+fade entrance with delay | `child`, `delay` | y |
| lib/core/utilities/widgets/comment_dialog.dart | Read-only text dialog + `CommentDialog.show()` | `title`, `comment` | y |
| lib/core/utilities/widgets/no_internet_screen.dart | Offline route, auto-pop on reconnect | — | n |
| lib/features/maintenance/presentation/widgets/maintenance_gate.dart | Maintenance overlay over the navigator | `child` | n (pattern y) |
| lib/features/maintenance/presentation/screens/maintenance_screen.dart | Maintenance page | — | n |
| lib/features/app_update/presentation/widgets/app_update_guard.dart | Forced-update guard | `child` | n (pattern y) |
| lib/features/app_update/presentation/widgets/app_update_dialog.dart | Forced-update dialog (PopScope, non-dismissible) | `cubit` | n |
| lib/features/home/presentation/widgets/home_feature_card.dart | Grid tile with gradient icon | `icon`, `label`, `color`, `onTap` | y |
| lib/features/start/presentation/widgets/start_action_card.dart | Action list card w/ RTL chevron | `icon`, `iconColor`, `title`, `subtitle`, `onTap` | y |
| lib/features/profile/presentation/widgets/profile_info_tile.dart | Icon + label/value info row | `icon`, `label`, `value` | y |
| lib/features/reservation/presentation/widgets/reservation_stepper_header.dart | Step progress header | `currentStep` | n (hardcoded step keys) |
| lib/features/reservation/presentation/widgets/subject_chips.dart | Selectable subject chips | `availableSubjects`, `selectedSubjects`, `closedSubjects`, … | n |
| lib/features/reservation/presentation/widgets/reservation_success_view.dart | Success summary | `result`, `onContinue` | n |
| lib/features/home/presentation/widgets/home_hero_header.dart | Gradient header + bell badge | `student`, `onBellTap`, `badgeCount` | n |
| lib/features/home/presentation/widgets/home_drawer.dart | End drawer | — | n |
| lib/features/notifications/presentation/widgets/notification_card.dart, notifications_section.dart | Notification UI | `notification` | n |
| lib/features/{exams,homework,attendance,fees}/presentation/widgets/*_card.dart | Record cards | model | n |
| lib/features/profile/presentation/widgets/profile_subject_card.dart | Subject card | `subject` | n |

## 6. Packages (`pubspec.yaml`)

| Role | Packages |
|---|---|
| State | flutter_bloc ^9.1.1, equatable ^2.0.7 |
| DI | get_it ^9.2.1 |
| Routing | go_router ^17.3.0 |
| Backend / network | firebase_core ^4.11.0, cloud_firestore ^6.6.0, internet_connection_checker_plus ^3.1.1 |
| Result / FP | dartz ^0.10.1 |
| Storage | shared_preferences ^2.5.3 |
| L10n | easy_localization ^3.0.8, intl ^0.20.2, flutter_localizations (sdk) |
| UI | flutter_screenutil ^5.9.3, google_fonts ^8.1.0, shimmer ^3.0.0, fluttertoast ^9.1.0, cupertino_icons ^1.0.8 |
| Utils | logger ^2.6.0, uuid ^4.5.1, package_info_plus ^10.2.1, url_launcher ^6.3.2 |
| Dev | flutter_test, flutter_lints ^6.0.0, fake_async ^1.3.3, flutter_launcher_icons ^0.14.4 |

## 7. Quality notes

* **Null safety / SDK:** Dart `>=3.8.0`; uses sealed classes, pattern matching, records
  (`({String docId, String? studentKey})`), wildcard `_` params, new tall formatter style.
* **Lints:** `analysis_options.yaml` = default `flutter_lints` include with no custom rules. Code nonetheless
  follows `avoid_print`, single quotes and trailing commas.
* **Tests:** 13 files / ~124 tests, focused on pure logic and infra (connectivity debounce with `fake_async`,
  notification engine, settings rules, gate/update logic, transactional id assignment using a fake transaction
  context, cache session clearing, responsive layouts without overflow at 4 device sizes). No golden tests, no
  integration tests, no feature-screen widget tests.
* **Deprecated APIs:** none found — `PopScope` (not WillPopScope), `withValues(alpha:)` (not withOpacity),
  `TextScaler` (not textScaleFactor), `DropdownButtonFormField.initialValue`, `CardThemeData/DialogThemeData`.
* **Docs:** unusually rich doc comments explaining *why* (e.g. `app_version.dart`, `settings_cubit.dart`,
  `app_update_guard.dart`).
* **Smells / risks:**
  * Secrets hygiene: `android/app/playstore-key.json` (Play service account) and `android/app/google-services.json`
    are committed in git history (CI also regenerates the service account from secrets, so the committed copy is
    unnecessary). `android/key.properties` and `upload-keystore.jks` exist locally but are git-ignored.
  * Router: `state.extra!` casts, no `redirect`, no typed routes; no-internet is a pushed route from a global
    listener.
  * DI inconsistency: derived feature cubits instantiated in widgets; cubit-to-cubit constructor dependencies.
  * Hardcoded: brand title, store URL with package id, client address list, local phone regex, shimmer hex colors.
  * `reservation_screen.dart` (478 lines) and `tracking_screen.dart` (247) hold whole multi-step forms.
  * Security: returning-student login reads the document by a computed id and compares the parent's phone in
    the client; protection depends entirely on Firestore rules.
  * Cross-app duplication: Firestore contract types are hand-copied from sedu-control and already drift
    (sedu-control supports year-scoped document ids and per-year counter docs; this app does not).
  * Unused Android permissions (storage) and `<queries>` entries.
