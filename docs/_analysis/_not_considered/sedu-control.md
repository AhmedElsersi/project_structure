# sedu-control — Phase 1 analysis

Sibling of `sedu-reservation` (same Firestore database; this is the teacher/admin app, that one the student
app). See `docs/_analysis/sedu-reservation.md`. **No core file is byte-identical between the two apps** — every
parallel file was rewritten/diverged; see section 8 for the file-by-file comparison and which side is better.

## Summary for comparison

```
PROJECT: sedu-control | path: My Apps/Sedu/sedu_control | stack: Flutter, Dart '>=3.5.0 <4.0.0' | last commit: 2026-08-26 | source files: 114
ARCH: clean-arch-lite, feature-first (same skeleton as sedu-reservation) — features/<f>/{data/{data_sources,models,repo}, presentation/{managers,screens,widgets}}; NO domain layer; core/ holds base classes, services, widgets and a barrel; app-scoped cubits are get_it singletons handed to routes via BlocProvider.value
STATE: flutter_bloc (Cubit only) — BaseCubit<S>.handleRequest(call,onLoading,onSuccess,onFailure?)+safeEmit and BaseSingleStateCubit<S extends BaseSingleState>.execute(loadingState,successState,failureState) (lib/core/base_architecture/presentation/managers/base_cubit.dart); feature states are Equatable classes implementing BaseSingleState{status,failure} with copyWith; FetchStatus in lib/core/enums/enums.dart
DI: get_it (manual, global `diService`, constructor args resolved by inference `diService()`) — lib/core/services/di_container.dart
ROUTING: go_router 17 (19 named GoRoutes, goNamed/pushNamed, pop-with-result) — lib/core/app_router/app_router.dart + app_routes_names.dart + typed arg classes lib/core/models/route_args.dart — guards? no (splash reads a prefs bool) — deep links? no (13 routes cast `state.extra! as X`)
NETWORK: firebase (cloud_firestore + firebase_auth anonymous sign-in; no REST) — interceptors: n/a | token refresh: n | retry: n (per-call timeout param, default 30s) | error mapping: BaseRemoteDataSource.handleRequest maps FirebaseException.code (incl. 'unauthenticated')/Timeout/Socket → Failure wrapped in FailureException; BaseRepository.handleNetworkCall → Left(e.failure) and logs | files: lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/base_architecture/data/repository/base_repository.dart, lib/core/services/firestore_service.dart
RESULT_TYPE: Either (dartz) — abstract Failure{messageKey, details} + FailureException transport: lib/core/utilities/failures/failures.dart
STORAGE: shared_preferences — lib/core/services/storage_service.dart (StorageService + StorageKeys); path_provider only for export files
L10N: easy_localization — ar, en; start+fallback ar; assets/translations/{ar,en}.json (311 lines each); shared widgets take translation KEYS (labelKey/messageKey/titleKey) — hardcoded UI strings: few (MaterialApp title, Arabic default maintenance message in platform_settings_model.dart, address list in add_student_screen.dart)
RTL: Directional=5 vs LeftRight=7 (4 gradient Alignment.topRight/bottomLeft, 1 symmetric left+right padding pair, 1 Positioned right: badge); RTL-aware TrailingChevron widget
THEME: lib/core/theme/app_theme.dart — dark mode y (AppCubit.toggleTheme, persisted) | component themes y (appBar, card, input, filled/outlined/text buttons, chip, switch via WidgetStateProperty, divider, dialog, FAB, snackBar, listTile, progress) | colors class lib/core/utilities/constants/app_colors.dart | text styles class: none (GoogleFonts.cairoTextTheme) | fonts: Cairo via google_fonts (runtime fetch)
RESPONSIVE: screenutil (393x852, minTextAdapt, splitScreenMode) with tablet cap in lib/core/presentation/responsive/responsive_scope.dart + helpers lib/core/presentation/responsive/responsive.dart — breakpoints: 600 / 1024 on width (MediaQuery.sizeOf); scale() = width/393 clamped to ≤1.3
TEXT_SCALING: lib/core/presentation/responsive/responsive_scope.dart (MaterialApp.builder) — mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3)
ENV/FLAVORS: hardcoded — FirebaseOptions literal in lib/main.dart + constants in lib/core/utilities/constants/firestore_constants.dart; no flavors / dotenv / --dart-define; no CI workflow
LOGGING: logger (static AppLogger lib/core/services/logger_service.dart: debug/info/warning/error(msg,[error,stack])); no BlocObserver; no print (avoid_print enforced)
ANALYTICS/CRASH: none (runZonedGuarded → AppLogger)
PUSH: none
PAYMENTS/IAP: none
PERMISSIONS: none (no permission_handler; AndroidManifest declares unused READ/WRITE_EXTERNAL_STORAGE)
DEEP_LINKS: none
MEDIA/FILES: excel (xlsx build) + path_provider (app documents dir) + share_plus (share sheet) + url_launcher (tel/sms); no image picking / network images
TESTS: 19 files (~164 tests) — PlatformSettingsModel rules (43) + settings migration (17), StudentIdentity scheme (15), students/exams/counters data sources on fake_cloud_firestore, studentKey backfill, StudentsListCubit, homework/attendance/exam lookup rules, ASCII date storage, chunked/nested-map utils, responsive + DefaultScreen widget tests, 1 sanity test
LINTS: flutter_lints 6 + 3 extra rules (avoid_print, prefer_single_quotes, require_trailing_commas)
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/presentation/responsive/responsive_scope.dart — app-root wrapper that re-configures ScreenUtil with a capped size (≤1.3× design) so .w/.h/.sp stop blowing up on tablets, and clamps textScaler 0.85–1.3 — quality 5 — coupling: none (side effect: ScreenUtil.configure inside build)
- lib/core/presentation/responsive/responsive.dart — Breakpoints (600/1024, designWidth, maxSizeFactor), DeviceSize, context.responsive<T>(), capped scale(), contentMaxWidth — quality 4 — coupling: none
- lib/core/utilities/widgets/default_screen.dart — base scaffold with built-in offline banner, modal loading overlay, tablet width cap, FAB/bottom bar, title-as-key — quality 4 — coupling: low (ConnectivityCubit, easy_localization)
- lib/core/base_architecture/presentation/managers/base_cubit.dart — BaseCubit.handleRequest + BaseSingleState contract + BaseSingleStateCubit.execute with state-builder lambdas (works with any copyWith state) — quality 4 — coupling: none
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — handleRequest with overridable timeout, Firebase code mapping, diagnostic `details` — quality 4 — coupling: low (Firestore)
- lib/core/utilities/failures/failures.dart — Failure(messageKey, details) hierarchy + FailureException carrier — quality 4 — coupling: none (abstract, not sealed)
- lib/core/base_architecture/data/repository/base_repository.dart — handleNetworkCall → Either, logs every failure — quality 4 — coupling: none
- lib/core/utilities/widgets/app_button.dart — button with variants filled/tonal/outlined/danger + loading + expanded — quality 4 — coupling: low (labelKey.tr())
- lib/core/utilities/widgets/confirm_dialog.dart — showConfirmDialog(...) → Future<bool>, destructive style — quality 4 — coupling: low (keys)
- lib/core/utilities/timing/debouncer.dart — Debouncer(run/dispose) — quality 4 — coupling: none
- lib/core/utilities/formatters/date_formatter.dart — locale-proof ASCII storage date + canonical/sameDate comparison — quality 4 — coupling: none
- lib/core/extensions/string_extensions.dart + lib/core/extensions/list_extensions.dart — normalizedDigits (Eastern-Arabic → ASCII), isNumeric; chunked(n) for 500-op batches — quality 4 — coupling: none
- lib/core/utilities/helpers/nested_map.dart — dotted field paths → nested maps for Firestore merge writes — quality 4 — coupling: none
- lib/core/theme/app_theme.dart — ColorScheme.fromSeed + overrides, 14 component themes, WidgetStateProperty switch — quality 4 — coupling: low (AppColors, .sp in theme)
- lib/core/services/logger_service.dart + lib/core/services/storage_service.dart — logger facade; SharedPreferences wrapper with keys class — quality 3 — coupling: none
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/app_button.dart — primary button (variants) — labelKey, onPressed, variant{filled,tonal,outlined,danger}, icon, isLoading, expanded — quality 4 — generic? y
- lib/core/utilities/widgets/app_text_field.dart — floating-label TextFormField — controller, labelKey, hintKey, keyboardType, obscureText, onChanged, validator, prefixIcon, suffix, textAlign, maxLines, maxLength, enabled, digitsOnly, textInputAction, onSubmitted — quality 4 — generic? y
- lib/core/utilities/widgets/confirm_dialog.dart — confirm dialog function — titleKey, messageKey, confirmKey, cancelKey, isDestructive — quality 4 — generic? y
- lib/core/utilities/widgets/default_screen.dart — base scaffold — body, title(key), titleWidget, actions, floatingActionButton, floatingActionButtonLocation, bottomBar, isLoading, padding, appBarVisible, maxContentWidth — quality 4 — generic? y
- lib/core/utilities/widgets/default_screen.dart (private _ConnectivityBanner, _ContentConstraint) — offline banner / width cap — — — quality 4 — generic? y (extract)
- lib/core/utilities/widgets/empty_state.dart — empty / error state — icon, messageKey, subtitleKey — quality 4 — generic? y
- lib/core/utilities/widgets/shimmer_list.dart — list skeleton — itemCount=8, itemHeight — quality 3 — generic? y (hardcoded hex colors)
- lib/core/utilities/widgets/app_toast.dart — showAppToast(message, {ToastState}) via fluttertoast (center) — quality 3 — generic? y
- lib/core/utilities/widgets/trailing_chevron.dart — RTL-aware forward chevron — (none) — quality 3 — generic? y
- lib/core/presentation/responsive/responsive_scope.dart — root responsive/text-scale wrapper — child — quality 5 — generic? y
- lib/features/platform_settings/presentation/screens/platform_settings_screen.dart (private _Dim) — opacity + IgnorePointer disabler — dimmed, child — quality 3 — generic? y (private)
- lib/features/students/presentation/screens/student_profile_screen.dart (private _SectionCard, _CallButton) — icon tile / translucent action button — icon, labelKey, color, onTap — quality 3 — generic? semi (private)
- lib/features/students/presentation/widgets/student_card.dart — student list row — student, onTap — quality 3 — generic? n
- lib/features/exams/presentation/widgets/exam_entry_card.dart, exam_history_card.dart — mark entry / history cards — quality 3 — generic? n
- lib/features/platform_settings/presentation/widgets/{app_control_section, academic_year_section, fee_reminders_section, session_maintenance_section}.dart — admin settings sections — quality 3 — generic? n
NOTABLE_IDEAS: (1) ResponsiveScope capping ScreenUtil on tablets without touching call sites + textScaler.clamp (lib/core/presentation/responsive/responsive_scope.dart); (2) shared widgets take translation KEYS, never raw strings (AppButton.labelKey, EmptyState.messageKey, DefaultScreen.title, showConfirmDialog) — enforces l10n; (3) DefaultScreen with built-in offline banner + modal loading overlay + per-screen maxContentWidth override (lib/core/utilities/widgets/default_screen.dart); (4) BaseSingleState interface + execute(loadingState/successState/failureState builders) (lib/core/base_architecture/presentation/managers/base_cubit.dart); (5) typed route-argument classes (lib/core/models/route_args.dart); (6) optimistic update with rollback + saveFailed flag (features/platform_settings/presentation/managers/platform_settings_cubit/platform_settings_cubit.dart `_optimisticUpdate`); (7) idempotent read-time schema migration `fetchOrMigrate` with `_ensureX` steps (features/platform_settings/data/data_sources/platform_settings_remote_data_source.dart); (8) chunked(500) WriteBatch backfill with progress callback (features/platform_settings/data/data_sources/student_key_backfill_remote_data_source.dart); (9) transactional, self-healing sequential-id counter with a write callback (features/students/data/data_sources/counters_remote_data_source.dart assignNextId); (10) locale-proof ASCII storage dates + Arabic digit normalization (core/utilities/formatters/date_formatter.dart, core/extensions/string_extensions.dart); (11) Excel export: pure ExcelWorkbookBuilder + app documents dir + share_plus sheet, no storage permission (features/excel_export/data/); (12) list screen keeps scroll on return: silent refresh + targeted in-memory update/remove from pop result (features/students/presentation/managers/students_list_cubit/students_list_cubit.dart, screens/students_screen.dart); (13) app-scoped singleton cubits passed to routes via BlocProvider.value(diService<X>()); (14) data-source tests on fake_cloud_firestore
SMELLS: FirebaseOptions literal (API key, app id, project id) hardcoded and committed in lib/main.dart, google-services.json also tracked; auth downloads the whole Users collection (incl. password field) after anonymous sign-in and compares credentials client-side, session = one SharedPreferences bool, no route guard; 13 routes cast `state.extra! as X`; ConnectivityCubit has no offline debounce/re-check (prefer sedu-reservation's) and a backend probe where 404 counts as online; ResponsiveScope mutates global ScreenUtil config in build(); god files: platform_settings_screen.dart 657, platform_settings_model.dart 614, platform_settings_cubit.dart 508, subject_homework_screen.dart 460, platform_settings_remote_data_source.dart 357, student_profile_screen.dart 345; hardcoded address list (duplicated in sedu-reservation AppConstants), Arabic default maintenance text in a model, location names/codes in constants; AppColors.examGradeColor hex literals, shimmer hex, 17 raw Colors.*; Subject.fromDbKey/Level.fromNumber silently default to physics/first; FirestoreService leaks raw SDK types (CollectionReference/Transaction/WriteBatch) so data sources build queries on the SDK; no BlocObserver / crash reporting; `http` dependency used only for a type; unused storage permissions; pre-3.7 formatter style with `(_, __)` params; Firestore contract hand-copied with sedu-reservation and drifting (year-scoped doc ids/counters exist only here). No deprecated APIs found (WidgetStateProperty, withValues, CardThemeData/DialogThemeData).
```

---

## 1. Architecture pattern

Same **feature-first clean-arch-lite** layout as sedu-reservation (the same author refactored both; commit
history shows "Phase 1: clean-architecture core (base layers, DI, GoRouter, theme, l10n)").

```
Screen → Cubit (BaseCubit.handleRequest / BaseSingleStateCubit.execute)
       → Repository.handleNetworkCall(() => …)     // Either<Failure,T>
       → RemoteDataSource.handleRequest(() => …)   // throws FailureException(Failure)
       → FirestoreService (exposes SDK refs)
```

* No domain layer: concrete repositories, models are entities.
* Every feature cubit is a `registerFactory` in DI and provided by its screen
  (`BlocProvider(create: (_) => diService<StudentsListCubit>()..loadStudents(level: widget.level))`).
* App-scoped singletons (`AppCubit`, `ConnectivityCubit`, `PlatformSettingsCubit`) are `registerLazySingleton`
  and provided with `BlocProvider.value(value: diService<X>())` — at the root for App/Connectivity, per-route
  for PlatformSettings (home, level menu, add student, settings, excel export).
* Single-state pattern dominates here (vs sealed hierarchies in the student app): each state is an Equatable
  class `implements BaseSingleState` with `status`, `failure`, data fields and `copyWith`; many states carry a
  second `saveStatus` for mutations.

Representative cubit:

```dart
class AuthCubit extends BaseSingleStateCubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());
  final AuthRepository _repository;

  Future<void> login({required String phone, required String password}) =>
      execute(
        call: () => _repository.login(phone: phone, password: password),
        loadingState: () => state.copyWith(status: FetchStatus.loading),
        successState: (_) => state.copyWith(status: FetchStatus.success),
        failureState: (failure) =>
            state.copyWith(status: FetchStatus.failure, failure: failure),
      );
}
```

Screens switch on `state.status` with guards: `FetchStatus.success when students.isEmpty => EmptyState(...)`.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                         bootstrap: zone, EasyLocalization, Firebase (inline options), DI, SeduApp (ResponsiveScope builder)
├── core/
│   ├── app_cubit/                    AppCubit (+app_state: themeMode, isLoggedIn), ConnectivityCubit
│   ├── app_router/                   app_router.dart (19 named GoRoutes), app_routes_names.dart (route names)
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/         base_remote_data_source.dart
│   │   │   └── repository/           base_repository.dart
│   │   └── presentation/
│   │       └── managers/             base_cubit.dart (BaseCubit, BaseSingleState, BaseSingleStateCubit)
│   ├── enums/                        enums.dart (FetchStatus+ext, ToastState, Subject, Level, VisibilityScope)
│   ├── exports/                      core_exports.dart (barrel incl. go_router, equatable)
│   ├── extensions/                   context_extensions (ContextX + hideKeyboard), list_extensions (chunked), string_extensions (normalizedDigits)
│   ├── models/                       route_args.dart (typed route args), student_model.dart
│   ├── presentation/
│   │   └── responsive/               responsive.dart (Breakpoints, DeviceSize, ResponsiveContext), responsive_scope.dart
│   ├── services/                     di_container, firestore_service, logger_service, storage_service (+StorageKeys)
│   ├── theme/                        app_theme.dart
│   └── utilities/
│       ├── constants/                app_colors, app_images, firestore_constants
│       ├── failures/                 failures.dart (Failure hierarchy + FailureException)
│       ├── formatters/               date_formatter.dart
│       ├── helpers/                  nested_map.dart, student_identity.dart
│       ├── timing/                   debouncer.dart
│       └── widgets/                  app_button, app_text_field, app_toast, confirm_dialog, default_screen, empty_state, shimmer_list, trailing_chevron
└── features/
    ├── attendance/        data/{data_sources,models,repo}, presentation/{managers,screens}           per-subject roll call + per-student history
    ├── auth/              data/{data_sources,models,repo}, presentation/{managers,screens}           phone/password login
    ├── exams/             data/{data_sources,models,repo}, presentation/{managers,screens,widgets}   bulk mark entry + per-student edit
    ├── excel_export/      data/{data_sources,models,repo, excel_workbook_builder.dart}, presentation/{managers,screens}
    ├── fees/              data/{data_sources,repo}, presentation/{managers,screens}                  monthly fee toggles
    ├── home/              presentation/screens                                                       home + level menu hubs
    ├── homework/          data/{data_sources,models,repo}, presentation/{managers,screens}
    ├── platform_settings/ data/{data_sources,models,repo}, presentation/{managers,screens,widgets}   remote-config admin (visibility, reservation, version, maintenance, fee reminders, academic year, session epoch, backfill)
    ├── splash/            presentation/screens                                                       anon sign-in + route by prefs flag
    └── students/          data/{data_sources,repo}, presentation/{managers,screens,widgets}          list/search, add, edit, profile, delete
```

**Representative feature fully expanded — `features/students/`:**

```
students/
├── data/
│   ├── data_sources/counters_remote_data_source.dart   Ids/{key} counters: maxExistingStudentId, assignNextId<R>(write cb), getNextStudentId
│   ├── data_sources/students_remote_data_source.dart   fetchStudents(level), fetchStudent(docId), addStudent (dup-phone check + transactional id), updateStudent, deleteStudent
│   └── repo/students_repo.dart                         Either wrappers (Unit for void ops)
└── presentation/
    ├── managers/
    │   ├── students_list_cubit/{cubit,state}           load + debounced search + refreshSilently + applyStudentUpdate/removeStudent
    │   ├── add_student_cubit/{cubit,state}
    │   └── student_profile_cubit/{cubit,state}
    ├── screens/{students_screen, add_student_screen, edit_student_screen, student_profile_screen}.dart
    └── widgets/student_card.dart
```

## 3. Infrastructure

### 3.1 State management
* flutter_bloc ^9.1.1 + equatable ^2.0.8, Cubits only.
* `lib/core/base_architecture/presentation/managers/base_cubit.dart`:
  * `BaseCubit<S>`: `handleRequest<T>({call, onLoading, onSuccess, onFailure?})` (returns early if closed before
    and after the await), `safeEmit`.
  * `abstract class BaseSingleState { FetchStatus get status; Failure? get failure; }`.
  * `BaseSingleStateCubit<S extends BaseSingleState>`: `execute<T>({call, loadingState, successState, failureState})`.
* `FetchStatus` + `FetchStatusX` extension in `lib/core/enums/enums.dart`.
* No BlocObserver. Quality 4: flexible and type-safe; a generic `SingleState<T>` (as in reservation) is lighter
  for simple screens, while this contract scales better to multi-field states (both are worth keeping).

### 3.2 DI
`lib/core/services/di_container.dart` — get_it ^9.2.1, `final GetIt diService = GetIt.instance;`,
`diContainerSetup()`: `StorageService` as `registerSingleton` (awaited create), services/data sources/repos lazy
singletons, 3 app-scoped cubits lazy singletons, 11 screen cubits factories. Constructor args use type inference
(`AuthRemoteDataSource(diService())`) — compact but less explicit. Same core→features import direction as reservation.

### 3.3 Routing
* go_router ^17.3.0; `lib/core/app_router/app_router.dart` has 19 `GoRoute`s with `path` + `name`; navigation is
  name-based (`context.goNamed`, `context.pushNamed`), pop results used (`final result = await context.pushNamed(...)`;
  profile pops the deleted doc id).
* Typed args: `LevelMenuArgs`, `SubjectScreenArgs`, `StudentSubjectArgs` in `lib/core/models/route_args.dart`,
  but still passed through `state.extra!` casts (13 routes) → not deep-linkable / restorable.
* No `redirect`/guards; `SplashScreen` signs in anonymously then `goNamed(isLoggedIn ? home : login)`.
* `AppRoutesNames.studentFeesEdit` is declared but unused.

### 3.4 Networking (Firestore)
* cloud_firestore ^6.6.0, firebase_auth ^6.5.4 (anonymous sign-in to satisfy rules). `Firebase.initializeApp`
  is called with an inline `FirebaseOptions(...)` literal in `lib/main.dart` (secret-in-source; template must use
  `firebase_options.dart`/flavors instead).
* `lib/core/services/firestore_service.dart`: `collection`, `doc`, `getDoc`, `setDoc(merge)`, `updateDoc`, `deleteDoc`,
  `newId` (Firestore auto-id used as a stable key), `batch`, `runTransaction(TransactionHandler)`, `serverTimestamp`.
  It returns raw SDK types, so data sources compose queries on the SDK; testing uses `fake_cloud_firestore`.
* Error mapping (`BaseRemoteDataSource.handleRequest`, overridable timeout, e.g. 10 min for the backfill):

```dart
} on FailureException {
  rethrow;
} on FirebaseException catch (e) {
  throw FailureException(_mapFirebaseException(e)); // permission-denied|unauthenticated, not-found, unavailable|network-request-failed, deadline-exceeded, default Server
} on TimeoutException catch (e) {
  throw FailureException(TimeoutFailure(details: e.toString()));
} on SocketException catch (e) {
  throw FailureException(NetworkFailure(details: e.toString()));
}
```

* No retry, no token refresh (no user tokens).

### 3.5 Result type & failures
`lib/core/utilities/failures/failures.dart`: `abstract class Failure extends Equatable { messageKey; details; }`
with `NetworkFailure`, `TimeoutFailure`, `PermissionFailure`, `NotFoundFailure`, `ServerFailure`,
`UnknownFailure`, `ValidationFailure(messageKey)`; `FailureException(failure)` carries a Failure through throws.
Every failure has a fixed translation key (`errors.network`, …) and an optional diagnostic `details` string that
is logged, never shown. Not `sealed` (reservation's is).

### 3.6 Local storage
`lib/core/services/storage_service.dart` — `StorageService.create()`, `getBool/setBool/getString/setString/remove/clear`;
`StorageKeys` (`isLoggedIn`, `isDarkTheme`, `settingsMigrated`, legacy names preserved). No JSON helpers, no
secure storage. Export files written to `getApplicationDocumentsDirectory()` (path_provider).

### 3.7 Localization (+RTL)
* easy_localization ^3.0.8, `assets/translations/{ar,en}.json` (311 lines each), ar start/fallback, no language
  switcher. 249 `.tr()` call sites. Core widgets accept keys and translate internally (`AppButton(labelKey:)`,
  `EmptyState(messageKey:)`, `DefaultScreen(title:)` key, `showConfirmDialog(titleKey:, messageKey:)`), failures
  carry `messageKey`.
* The barrel hides easy_localization's `TextDirection` to avoid clashing with `dart:ui`.
* RTL: 5 Directional usages vs 7 left/right (gradient alignments, one symmetric padding, a badge
  `Positioned(right: -1)`); `TrailingChevron` flips by `Directionality`; Arabic digit normalization in search
  and date compare.

### 3.8 Theming
`lib/core/theme/app_theme.dart` — `ColorScheme.fromSeed(seedColor: AppColors.primary, ...)` with explicit
primary/secondary/error/surface overrides per brightness, Cairo text theme, component themes: appBar (title
`18.sp`), card, inputDecoration (filled, floating label), filledButton, outlinedButton, textButton, chip, switch
(`WidgetStateProperty.resolveWith`), divider, dialog, floatingActionButton, snackBar (floating), listTile,
progressIndicator. Colors in `lib/core/utilities/constants/app_colors.dart` (same indigo/teal/amber brand as
reservation, `lightX/darkX` naming, plus `examGradeColor()` with hex literals). Dark mode persisted via AppCubit.

### 3.9 Responsive helpers
* `ScreenUtilInit(designSize: Size(393, 852), minTextAdapt: true, splitScreenMode: true)`.
* `lib/core/presentation/responsive/responsive_scope.dart` (used as `MaterialApp.router(builder:)`) re-runs
  `ScreenUtil.configure` with the device size clamped to `designSize × 1.3`, so all `.w/.h/.sp` stop growing past
  1.3× on tablets while phones are unchanged; it also clamps text scaling (below).
* `lib/core/presentation/responsive/responsive.dart`: `Breakpoints.tablet = 600`, `largeTablet = 1024`,
  `designWidth = 393`, `maxSizeFactor = 1.3`; `DeviceSize` enum; `ResponsiveContext` extension with
  `screenWidth/Height`, `isLandscape`, `deviceSize`, `isMobile/isTablet`, `responsive<T>()`, `scale(value)`
  (width ratio, capped), `contentMaxWidth` (∞ / 640 / 820). Width-based.
* `DefaultScreen` applies `contentMaxWidth` via a private `_ContentConstraint` (overridable per screen).
* Tests: `test/core/responsive_test.dart`, `test/core/default_screen_responsive_test.dart`.

### 3.10 Text scaling
```dart
return MediaQuery(
  data: mq.copyWith(
    textScaler: mq.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: Breakpoints.maxSizeFactor, // 1.3
    ),
  ),
  child: child,
);
```
(`lib/core/presentation/responsive/responsive_scope.dart`) — the better of the two sibling implementations.

### 3.11 Env / flavors
None; no CI workflow in this repo. Firebase options inline in `main.dart`; database contract constants (collection
names, default location key/code, batch limit) in `lib/core/utilities/constants/firestore_constants.dart`.
`android/app/google-services.json` is present and tracked.

### 3.12 Logging
`lib/core/services/logger_service.dart` — class `AppLogger` (file name differs from reservation's
`app_logger.dart`), `logger ^2.7.0`, warning level in release, `error(message, [error, stackTrace])`. No observer.

### 3.13–3.17 Analytics / push / IAP / permissions / deep links
None of them. `url_launcher` opens `tel:`/`sms:` from the student profile; AndroidManifest declares storage
permissions that the share-sheet export does not need.

### 3.18 Remote config (admin side — notable)
`features/platform_settings/` writes the shared settings document the student app listens to: per-location
level/subject visibility and reservation flags, forced-update version + download URL (dual-written to a legacy
doc), maintenance toggle + localized message, monthly fee reminders, academic year (advance / start month),
`sessionEpoch` bump (log out every student), and a one-time `studentKey` backfill. The cubit applies changes
optimistically and rolls back on failure; the data source migrates older document shapes on read.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/services/di_container.dart | get_it container | `diService`, `diContainerSetup()` | get_it, all features | pattern generic |
| lib/core/services/firestore_service.dart | Firestore facade (raw refs) | `collection`, `doc`, `getDoc`, `setDoc`, `updateDoc`, `deleteDoc`, `newId`, `batch`, `runTransaction`, `serverTimestamp` | cloud_firestore | generic (Firestore) |
| lib/core/services/logger_service.dart | logging facade `AppLogger` | `debug`, `info`, `warning`, `error(msg,[err,stack])` | logger | generic |
| lib/core/services/storage_service.dart | prefs wrapper + `StorageKeys` | `create`, `getBool`, `setBool`, `getString`, `setString`, `remove`, `clear` | shared_preferences | generic |
| lib/core/app_cubit/app_cubit.dart | theme + login flag | `toggleTheme`, `setLoggedIn`, `logout` | StorageService | semi-generic |
| lib/core/app_cubit/connectivity_cubit.dart | reachability | `startWatching`, `close` | internet_connection_checker_plus, http | generic (weaker than reservation's) |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | request wrapper | `handleRequest<T>(request, {timeout})` | cloud_firestore, failures | generic |
| lib/core/base_architecture/data/repository/base_repository.dart | Either wrapper | `handleNetworkCall<T>` | dartz, AppLogger | generic |
| lib/core/base_architecture/presentation/managers/base_cubit.dart | base cubits | `handleRequest`, `safeEmit`, `BaseSingleState`, `execute` | flutter_bloc, dartz | generic |
| lib/core/utilities/failures/failures.dart | failures | 7 Failure subclasses, `FailureException` | equatable | generic |
| lib/core/utilities/formatters/date_formatter.dart | stored date format | `storageDate`, `today`, `canonical`, `sameDate`, `canonicalizeDate` | string_extensions | generic |
| lib/core/utilities/helpers/nested_map.dart | dotted-path maps | `nestedMapFromDottedPath`, `expandDottedPaths` | — | generic |
| lib/core/utilities/helpers/student_identity.dart | doc-id / counter scheme | `docName`, `countersDocId`, `counterKey`, `readCounter`, `hasCounter`, `zeroedCounters` | FirestoreConstants | app-specific |
| lib/core/utilities/timing/debouncer.dart | debounce | `run`, `dispose` | — | generic |
| lib/core/extensions/context_extensions.dart | `ContextX` | `theme`, `colorScheme`, `textTheme`, `isDarkMode`, `screenSize`, `hideKeyboard()` | flutter | generic |
| lib/core/extensions/list_extensions.dart | `ListX` | `chunked(size)` | — | generic |
| lib/core/extensions/string_extensions.dart | `StringX` | `isNumeric`, `normalizedDigits` | — | generic (Arabic) |
| lib/core/presentation/responsive/responsive.dart | breakpoints/ext | see 3.9 | flutter | generic |
| lib/core/presentation/responsive/responsive_scope.dart | root wrapper | `ResponsiveScope(child)` | flutter_screenutil | generic |
| lib/core/models/route_args.dart | typed route args | 3 arg classes | enums | app-specific (pattern generic) |
| lib/core/enums/enums.dart | FetchStatus (generic), ToastState (generic), Subject, Level, VisibilityScope (app) | — | — | mixed |
| lib/core/utilities/constants/{app_colors,app_images,firestore_constants}.dart | constants | static | — | shape generic, values app |
| lib/features/excel_export/data/excel_workbook_builder.dart | pure xlsx builder | `build(request, students)` | excel, easy_localization | app-specific (pattern generic) |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/app_button.dart | Filled/tonal/outlined/danger button with loader | `labelKey`, `onPressed`, `variant`, `icon`, `isLoading`, `expanded` | y |
| lib/core/utilities/widgets/app_text_field.dart | Floating-label text field | `controller`, `labelKey`, `hintKey`, `keyboardType`, `obscureText`, `onChanged`, `validator`, `prefixIcon`, `suffix`, `textAlign`, `maxLines`, `maxLength`, `enabled`, `digitsOnly`, `textInputAction`, `onSubmitted` | y |
| lib/core/utilities/widgets/confirm_dialog.dart | `showConfirmDialog()` → bool | `titleKey`, `messageKey`, `confirmKey`, `cancelKey`, `isDestructive` | y |
| lib/core/utilities/widgets/default_screen.dart | Base scaffold + offline banner + loading overlay + width cap | `body`, `title`, `titleWidget`, `actions`, `floatingActionButton`, `floatingActionButtonLocation`, `bottomBar`, `isLoading`, `padding`, `appBarVisible`, `maxContentWidth` | y |
| lib/core/utilities/widgets/empty_state.dart | Empty/error placeholder | `icon`, `messageKey`, `subtitleKey` | y |
| lib/core/utilities/widgets/shimmer_list.dart | List skeleton | `itemCount`, `itemHeight` | y |
| lib/core/utilities/widgets/app_toast.dart | `showAppToast()` | `message`, `state` | y |
| lib/core/utilities/widgets/trailing_chevron.dart | RTL chevron | — | y |
| lib/core/presentation/responsive/responsive_scope.dart | Root responsive wrapper | `child` | y |
| lib/features/students/presentation/widgets/student_card.dart | Student row | `student`, `onTap` | n |
| lib/features/exams/presentation/widgets/exam_entry_card.dart | Mark entry card (stateful) | `student`, … | n |
| lib/features/exams/presentation/widgets/exam_history_card.dart | Exam history row | `exam`, … | n |
| lib/features/platform_settings/presentation/widgets/*.dart | Admin sections (app control, academic year, fee reminders, session/maintenance) with private dialogs | settings models | n |
| private: _Dim (platform_settings_screen), _SectionCard/_CallButton (student_profile_screen), _ActionCard/_LevelCard (home_screen), _MenuTile (level_menu_screen) | small tiles / disabler | various | candidates to extract |

## 6. Packages (`pubspec.yaml`)

| Role | Packages |
|---|---|
| State | flutter_bloc ^9.1.1, equatable ^2.0.8 |
| DI | get_it ^9.2.1 |
| Routing | go_router ^17.3.0 |
| Backend / network | firebase_core ^4.11.0, firebase_auth ^6.5.4, cloud_firestore ^6.6.0, internet_connection_checker_plus ^3.1.1, http ^1.6.0 |
| Result / FP | dartz ^0.10.1 |
| Storage / files | shared_preferences ^2.5.5, path_provider ^2.1.6 |
| L10n | easy_localization ^3.0.8, intl ^0.20.2, flutter_localizations (sdk) |
| UI | flutter_screenutil ^5.9.3, google_fonts ^8.1.0, shimmer ^3.0.0, fluttertoast ^9.1.0, cupertino_icons ^1.0.8 |
| Export / sharing | excel ^4.0.6, share_plus ^13.2.0, url_launcher ^6.3.2 |
| Utils | logger ^2.7.0 |
| Dev | flutter_test, flutter_lints ^6.0.0, fake_cloud_firestore ^4.0.0, flutter_launcher_icons ^0.14.3 |

## 7. Quality notes

* **Null safety / SDK:** Dart `>=3.5.0`; uses switch expressions and `when` guards (no sealed state classes or
  records); older formatter style and `(_, __)` wildcards.
* **Lints:** `flutter_lints` + `avoid_print`, `prefer_single_quotes`, `require_trailing_commas`.
* **Tests:** 19 files / ~164 tests — strong on domain rules and data sources (fake_cloud_firestore), settings
  migration, identity scheme, date canonicalization, utilities, responsive layouts. `test/widget_test.dart` is a
  trivial sanity test. No golden/integration tests.
* **Deprecated APIs:** none found (`WidgetStateProperty`, `withValues`, `CardThemeData`, `DialogThemeData`).
* **Security:** inline Firebase config in `lib/main.dart`; login fetches all `Users` docs (including the password
  field) and compares in the client after anonymous auth; session is an unsigned prefs bool. The template must
  not copy this auth approach.
* **Size:** several 300–650 line files in `platform_settings`, `homework`, `exams`, `students`, `home`.
* **Duplication:** address list, Firestore contract enums/models, AppColors re-implemented in both apps with
  drifting details (e.g. year-scoped ids only here).

## 8. Identical vs diverged vs sedu-reservation

No pair of files is byte-identical (checked with `cmp`). Parallel files and which version a template should prefer:

| Concept | sedu-control | sedu-reservation | Prefer |
|---|---|---|---|
| Remote data-source base | `core/base_architecture/data/data_sources/base_remote_data_source.dart` — throws `FailureException(Failure)`, overridable timeout, maps `unauthenticated`, keeps `details` | same path — sealed `AppException` subclasses, fixed 30 s, logs Firebase errors | merge: reservation's sealed exceptions + control's timeout param/details |
| Repository base | `base_repository.dart` — logs every failure | logs only unexpected errors | equivalent |
| Cubit bases | one file: `BaseCubit.handleRequest` + `BaseSingleState` + `BaseSingleStateCubit.execute(builders)` | `base_cubit.dart` `executeCall` + `base_single_state_cubit.dart` generic `SingleState<T>` | keep both ideas (generic SingleState<T> for simple screens, builder-based execute for rich states) |
| Failures | abstract `Failure{messageKey, details}` + `FailureException` | sealed `Failure{message, localizationKey}` + sealed `AppException` | reservation (sealed) + add `details` |
| Firestore facade | exposes SDK refs, batch, newId | SDK-free facade incl. `FirestoreTransaction` | reservation for testability; add batch/newId from control |
| Logger | `services/logger_service.dart` (error+stack) | `services/app_logger.dart` (stack only) + `AppBlocObserver` | control's signature + reservation's observer |
| Storage | `StorageService` + `StorageKeys` | `CacheService` (+JSON, scoped `clearSession`) + `CacheKeys` | reservation |
| Connectivity | simple stream → status | debounced offline confirmation + test seam | reservation |
| Base screen | `DefaultScreen` with offline banner, loading overlay, FAB, title key, maxContentWidth | `DefaultScreen` with endDrawer/leading/scaffoldKey/extendBody + `AdaptiveContainer` | merge (control's banner/overlay + reservation's drawer/leading params) |
| Responsive | `ResponsiveScope` (ScreenUtil cap + text clamp) + `responsive.dart` | `breakpoints.dart` + `responsive_extensions.dart` + `adaptive_container.dart`; text clamp in `main.dart` | control's ResponsiveScope + reservation's split files/AdaptiveContainer |
| Text scaling | `textScaler.clamp(0.85, 1.3)` | `TextScaler.linear(scale(1).clamp(...))` | control |
| Theme | `fromSeed` + overrides, 14 component themes | explicit full ColorScheme, 11 component themes | either; control has more component coverage |
| Colors | `AppColors` lightX/darkX naming | `AppColors` xLight/xDark naming, more semantic light variants | reservation (richer), same brand |
| Buttons / fields | `AppButton` (variants, key-based), `AppTextField` (rich params) | `DefaultAppButton`, `DefaultTextField` (label above), `DefaultDropdownField<T>` | control's button/field + reservation's dropdown |
| Empty state / shimmer / toast | `EmptyState` (keys), `ShimmerList`, `showAppToast` (3 states, center) | `EmptyStateWidget`, `ShimmerCardList`+`ShimmerBox`, `showAppToast` (4 states, bottom) | equivalent; reservation's ShimmerBox extra |
| Dialogs | `showConfirmDialog` | `CommentDialog` | control |
| Context extensions | `ContextX` + `hideKeyboard()` | `ContextExtensions` + `viewInsets` | merge |
| Enums | single `enums.dart` | one file per enum, `FetchStatus` getters on enum | reservation layout |
| Router | named routes + typed arg classes | path constants, raw extras | control |
| App cubit | theme + `isLoggedIn` in state | theme + session keys | — |
| Shared-doc models | `features/platform_settings/data/models/platform_settings_model.dart` (614 lines, read+write) | `core/models/platform_settings_model.dart` (383 lines, read-only, tolerant coercers) | app-specific |
