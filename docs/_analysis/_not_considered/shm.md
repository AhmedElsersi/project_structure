# SHM (Smart Household Management): analysis report

## Summary for comparison

```
PROJECT: shm | path: D-index/SHM_Developer_Handover_2026-10-30 | stack: Dart ">=3.3.0 <4.0.0" (lock: dart >=3.12, flutter >=3.44; handover says Flutter 3.47 / Dart 3.13) | last commit: no git, mtime 2026-10-30 | source files: 84
ARCH: feature-first + ports/adapters (hexagonal) — core/ holds interfaces + Supabase/platform adapters; features/<f>/{domain,data,application,presentation}; legacy M1 prototype layer (data/screen_catalog + presentation/prototype_screen.dart 3076 lines) still renders most screens
STATE: setState + ChangeNotifier/ListenableBuilder (LocaleController, TaskOfflineSync); sealed ViewState<T> (lib/src/core/state/view_state.dart) + ViewStatePanel exist but are unused; no bloc/riverpod
DI: manual composition root — AppDependencies.local()/.supabase() factories (lib/src/core/di/app_dependencies.dart) exposed by InheritedWidget AppScope (lib/src/core/di/app_scope.dart); no get_it
ROUTING: Navigator 1.0 onGenerateRoute — lib/src/core/navigation/app_router.dart — guards: yes (per-route role check, fails closed to role login + SessionInactivityGuard auto-lock) — deep links: only Supabase auth-recovery custom scheme (PKCE) + notification-tap intents
NETWORK: supabase_flutter 2.17 (PostgREST, RPC, Edge Functions, Storage, Realtime .stream) + http for one recovery call — interceptors: none | token refresh: y (GoTrue built-in) | retry: n at transport (durable offline action queue, maxAttempts 8) | error mapping: per-repo _failure(code, error) -> AppFailure(kind, code, safeMessage) + allowlisted auth/edge error codes | files: lib/src/bootstrap.dart, core/auth/supabase_authentication_service.dart, core/repositories/supabase_identity_repositories.dart, features/*/data/supabase_*.dart
RESULT_TYPE: sealed AppResult<T> {Success, Failure} with fold (lib/src/core/result/app_result.dart) — AppFailure + FailureKind enum (lib/src/core/errors/app_failure.dart), no class hierarchy
STORAGE: flutter_secure_storage behind LocalStore interface (SecureLocalStore / MemoryLocalStore, prefix-scoped clearScope) — lib/src/core/persistence/local_store.dart; Supabase PKCE verifier in SharedPreferencesGotrueAsyncStorage
L10N: custom inline bilingual AppText.pick(en, ar) InheritedWidget + GlobalMaterialLocalizations (no ARB/intl/easy_localization) — en, ar; default en; strings inline in widgets + lib/src/data/screen_catalog.dart — hardcoded UI strings: few (12 English-only literals, mostly diagnostics; ~237 pick() calls; AppFailure.safeMessage English-only)
RTL: Directional=2 vs LeftRight=4 (all 4 are gradient Alignment.topLeft/bottomRight; also 8 symmetric EdgeInsets.fromLTRB); Directionality set explicitly in MaterialApp.builder; back icon flipped manually
THEME: lib/src/core/shm_theme.dart — dark mode n | component themes in ThemeData y (appBar, card, filled/outlined/text/icon buttons, checkbox, chip, input, snackbar, bottomSheet, navigationBar) | ShmColors (+ ShmSpacing, ShmRadii, ShmSizes) | no text-styles class (TextTheme overrides in buildShmTheme) | fonts: system 'sans-serif', no bundled/Arabic font
RESPONSIVE: none (no helper/screenutil) — inline LayoutBuilder breakpoints: 600/900 (page padding), 430|520/700 (action grid 1/2/3 cols), width<390 compact app bar; max content width 1050/1120; width-based
TEXT_SCALING: no global clamp; per-Text MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5–2.0) + layout switch to column when scale(16) >= 32 (lib/src/presentation/shm_widgets.dart, prototype_screen.dart)
ENV/FLAVORS: --dart-define / --dart-define-from-file (SHM_FLAVOR development|staging|production, SHM_BACKEND_URL, SHM_BACKEND_PUBLIC_KEY, SHM_SESSION_TIMEOUT_MINUTES, SHM_VERBOSE_LOGS, SHM_FIREBASE_*); no native flavors — lib/src/core/config/app_environment.dart, config/development.example.json, startup-mode resolver in lib/src/bootstrap.dart
LOGGING: custom AppLogger interface + DebugAppLogger (debugPrint, key-based PII redaction) — lib/src/core/logging/app_logger.dart; plus 20 raw debugPrint calls
ANALYTICS/CRASH: no third-party; local-only LocalCrashReporter (sanitized, bounded JSON file) + GlobalErrorCapture wired to FlutterError.onError / PlatformDispatcher.onError / runZonedGuarded — lib/src/core/observability/crash_reporter.dart
PUSH: firebase_messaging (FCM token source, opaque versioned intent envelope) + flutter_local_notifications (zonedSchedule, 2 channels, privacy-redacted lock-screen bodies) + Supabase installation registry/outbox — lib/src/core/notifications/{firebase_push,push_registration,notification_service,local_notification_coordinator,remote_push_envelope}.dart
PAYMENTS/IAP: none
PERMISSIONS: permission_handler behind DevicePermissionService (camera, microphone, photos, notifications -> 4-state enum) — lib/src/core/permissions/device_permission_service.dart; role/plan PermissionPolicy in permission_policy.dart
DEEP_LINKS: Supabase password-recovery custom scheme (Android intent-filter, hardcoded redirect const); no app_links/uni_links; routes are '/screen/<ScreenId>'
MEDIA/FILES: image_picker (iOS) + native Kotlin MethodChannel camera (Android), EXIF-stripping PNG re-encode via dart:ui; Supabase Storage private buckets + 300 s signed URLs; path_provider; no cached_network_image/file_picker
TESTS: 39 test files (~8.1k lines; handover reports 322 tests) — env/startup modes, auth (owner/staff PIN, recovery, diagnostics), route authorization, shared-device lock, push registration, local notifications, offline task sync, task photo, crash-reporter redaction, locale coordinator, screen catalog, a11y/UI; plus 21 pgTAP SQL files + Deno edge-function tests
LINTS: flutter_lints ^4.0.0 + 2 extra rules (prefer_single_quotes, use_super_parameters); analyzer excludes platform dirs
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/src/core/config/app_environment.dart — env from dart-defines, flavor validation, publishable-key + https guard, fail-closed local fallback — quality 5 — coupling: low (SHM_ prefix; sb_publishable_ check is Supabase-specific)
- lib/src/core/result/app_result.dart — sealed Result<T> Success/Failure with fold — quality 5 — coupling: none
- lib/src/bootstrap.dart — runZonedGuarded + error hooks + AppStartupMode (local/configured/configError) + Supabase.initialize(PKCE) — quality 4 — coupling: medium (Firebase options + diagnostic flags are app-specific)
- lib/src/core/persistence/local_store.dart — LocalStore interface, Secure + Memory impls, prefix-scoped clear — quality 4 — coupling: none
- lib/src/core/errors/app_failure.dart — AppFailure(kind, code, safeMessage, cause) + FailureKind — quality 4 — coupling: none (safeMessage not localized)
- lib/src/core/logging/app_logger.dart — logger interface + redacting debug impl — quality 4 — coupling: low (redaction key list is domain-flavored)
- lib/src/core/observability/crash_reporter.dart — CrashReporter port, bounded/sanitized local crash log, GlobalErrorCapture — quality 4 — coupling: low (dart:io File; no-op on web)
- lib/src/core/state/view_state.dart + lib/src/core/presentation/view_state_panel.dart — sealed ViewState + exhaustive switch panel — quality 4 — coupling: none (unused; 'Retry' hardcoded)
- lib/src/core/permissions/device_permission_service.dart — permission_handler facade + Disabled impl — quality 4 — coupling: none
- lib/src/core/notifications/notification_service.dart — local notification service, privacy policy, FNV stable ids, Noop impl — quality 4 — coupling: low (SHM channel names)
- lib/src/core/notifications/push_registration.dart — serialized token<->identity coordinator + Supabase RPC repo — quality 4 — coupling: medium (household fields)
- lib/src/core/di/app_scope.dart + app_dependencies.dart — InheritedWidget DI + dual composition roots — quality 3 — coupling: high (container lists ~30 SHM services; pattern is generic)
- lib/src/features/communication/application/offline_action_queue.dart + lib/src/core/sync/offline_sync_coordinator.dart — durable JSON action queue + sync dispositions — quality 4 — coupling: low (queue lives in a feature folder)
- lib/src/core/media/media_storage.dart + supabase_media_storage.dart — storage port, sanitized paths, signed URLs — quality 3 — coupling: medium (bucket names in switch)
- lib/src/core/localization/locale_controller.dart + lib/src/core/app_text.dart — ChangeNotifier locale/direction + bilingual pick() — quality 3 — coupling: low (exactly 2 languages hardwired)
GENERIC_WIDGETS (every reusable widget):
- lib/src/core/presentation/view_state_panel.dart ViewStatePanel<T> — loading/empty/error+retry/ready switcher — state, readyBuilder, emptyLabel, errorLabel — quality 4 — generic? y
- lib/src/core/auth/session_inactivity_guard.dart SessionInactivityGuard — inactivity/background auto-lock wrapper (Listener + AbsorbPointer) — authentication, timeout, navigatorKey, sharedDeviceData, ownerBackgroundGrace, child — quality 4 — generic? partly (ShmRoutes, identity roles)
- lib/src/presentation/shm_widgets.dart ShmDecisionBanner — action banner card, urgent variant — urgent, title, detail, actionLabel, onPressed — quality 3 — generic? mostly (ShmColors, AppText)
- lib/src/presentation/shm_widgets.dart _StatusPill (private) — tinted pill/badge with optional icon, clamped text scale — label, color, icon — quality 4 — generic? y if made public
- lib/src/presentation/shm_widgets.dart ShmItemCard — list card: icon tile, title/subtitle, status pill, checkbox, a11y reflow — item(PrototypeItem), simplified — quality 3 — generic? n (bound to PrototypeItem)
- lib/src/presentation/shm_widgets.dart TierLegend / ReplaceableDashboardPlaceholder — app-specific legend / artwork placeholder — none — quality 2 — generic? n
- lib/src/presentation/prototype_screen.dart _RoleNavigation + _NavigationDestination (private) — floating dark rounded bottom nav with Semantics — current, role, onDestination / icon, label, selected, onTap — quality 3 — generic? partly (destinations hardcoded per role)
- lib/src/presentation/prototype_screen.dart _Header (private) — icon + title + subtitle header with large-text column reflow — screen — quality 3 — generic? partly
- lib/src/presentation/prototype_screen.dart _ActionGrid (private) — responsive Wrap of tonal icon buttons (1/2/3 cols) — actions, onTap, simplified — quality 3 — generic? partly
- lib/src/app.dart ShmConfigurationErrorApp — fail-closed "not configured" app — none — quality 3 — generic? y (swap copy)
- lib/src/features/communication/presentation/real_conversation_panel.dart _Notice (private) — message + Retry button — message, onRetry — quality 2 — generic? y
NOTABLE_IDEAS: fail-closed startup (unknown flavor or staging/prod without backend -> configuration-error app, never silent mocks: bootstrap.dart resolveStartupMode + AppEnvironment.allowsLocalFallback); client refuses any backend key not prefixed sb_publishable_ and non-https URLs outside dev (app_environment.dart); null-object adapters for every port (Disabled*/Noop*) so the app and tests run without backend; dual composition roots AppDependencies.local()/.supabase(); Supabase.initialize with AuthFlowType.pkce + explicit SharedPreferencesGotrueAsyncStorage; user-scoped storage keys ('$userId:' cleared on lock, 'durable:$userId:' survives) via LocalStore.clearScope (core/privacy/shared_device_data_manager.dart); serialized async tail queue `_tail = _tail.then(...)` (push_registration.dart, crash_reporter.dart, task_offline_sync.dart); opaque single-key versioned push payload, validated before use (remote_push_envelope.dart); lock-screen privacy policy for notifications; conditional imports for platform splits (core/media/task_photo_capture.dart, features/communication/application/device_speech_engine.dart); logger + crash sanitizer regexes (JWT, API keys, emails, URLs, UUIDs); text-scale-aware layout reflow; Edge Functions take an injectable getEnv reader with a _shared/ module + *_test.ts per module, verify_jwt set per function; docs conventions: AGENTS.md permanent rules, docs/adr/NNNN-kebab-title.md (Status/Date/Milestone, Context, Decision, Alternatives considered, Consequences/Impact & rollout), per-milestone implementation records, atomic feature checklist, migrations YYYYMMDDNNNN_snake.sql with additive-intent header comments + pgTAP tests; Android release signing from 4 env vars, all-or-none `require`, unsigned instead of debug-signed; README "Verify" block (dart format --set-exit-if-changed, analyze, test)
SMELLS: god file lib/src/presentation/prototype_screen.dart (3076 lines, one State, 36 setState, login + all 31 screens + dialogs) and lib/src/data/screen_catalog.dart (1036 lines of inline bilingual mock content); presentation owns auth/task state; ViewState/ViewStatePanel, ConnectivityService, OfflineSyncCoordinator defined but unused by the app; ConnectionState enum in connectivity_service.dart shadows Flutter's ConnectionState; `_failure` helper copy-pasted in 5 Supabase repos (no central mapper); repository interfaces declared in data/ files rather than domain; core imports features (app_dependencies.dart, core/sync -> features/communication); duplicated UUIDv4 generator with different regexes (staff_login_context.dart, firebase_push.dart); env-specific constants hardcoded (dev-host allowlist in owner_password_recovery_transport.dart, recovery redirect URI in supabase_authentication_service.dart); dart:io in auth/crash/diagnostics code while web/PWA is a target; large temporary diagnostics code in production paths (owner_auth_diagnostics.dart 438 lines, staff PIN diag, storage probe); Timer.periodic 15 s polling in app.dart State; TaskPhotoCapture uses a const DebugAppLogger(enabled: true) that ignores env verbosity; no dark mode; no Arabic font; English-only safeMessage surfaced in UI; AppText.of uses `!`. No deprecated APIs found (WidgetStateProperty, withValues, TextScaler used; no WillPopScope/withOpacity/textScaleFactor/print)
```

---

## 1. Architecture pattern

**Feature-first ports-and-adapters, built on a legacy prototype shell.** ADR 0001 sets the intent: a small shared `core/` holds framework-agnostic *ports* (abstract interface classes) plus Supabase and platform *adapters*. Each port also has a `Disabled*`/`Noop*`/`Local*`/`Memory*` null-object implementation. Features live in `features/<name>/` with up to four sublayers:

- `domain/`: plain Dart models and enums (e.g. `task_models.dart`: `RoutineRecurrence.occursOn`, `TaskStatus`, `DailyTask`).
- `data/`: the repository interface **and** its Supabase implementation in the same file (e.g. `TaskOperationsRepository` + `SupabaseTaskOperationsRepository`). All methods return `Future<AppResult<T>>`.
- `application/`: use-case/coordinator classes (e.g. `TaskOfflineSync extends ChangeNotifier`, `ConversationVoiceService`, `EndOfDayEvaluator`).
- `presentation/`: `StatefulWidget` panels that pull dependencies from `AppScope.of(context)` and manage state with `setState`.

The wiring is entirely manual. `bootstrap.dart` builds an `AppDependencies` (local or Supabase), and `ShmApp` puts it into `AppScope` (an `InheritedWidget`). Widgets read services from there.

Most of the UI still runs through the Milestone 1 prototype layer. `domain/prototype_models.dart` holds `ScreenId` (31 screens) and `ScreenDefinition`. `data/screen_catalog.dart` maps ids to bilingual mock content. `presentation/prototype_screen.dart` is a single StatefulWidget that renders every screen and switches on `ScreenId` to embed real feature panels (`OwnerTaskPanel`, `RealConversationPanel`). The handover README admits that "presentation widgets also own task/authentication/subscription state".

Backend: the `supabase/` folder holds 21 ordered migrations (RLS on 36 tables or statements, `security definer set search_path = ''` functions), 4 Deno Edge Functions (`staff-pin-login`, `owner-pin-login`, `push-outbox-processor`, `translate-message`) with a tested `_shared/` module, and 21 pgTAP SQL tests.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                         — `main() => bootstrapShm()`
└── src/
    ├── bootstrap.dart                — zone guard, error hooks, startup mode, Firebase + Supabase init, DI build
    ├── app.dart                      — ShmApp (MaterialApp, AppScope, AppText, timers, push/locale coordinators), ShmConfigurationErrorApp, startup gate
    ├── core/
    │   ├── ai/                       — AiService port + DisabledAiService
    │   ├── app_text.dart             — bilingual `pick(en, ar)` InheritedWidget
    │   ├── auth/                     — AuthenticationService/OwnerPinAuthentication ports; Local + Supabase adapters; recovery transport; device pairing; StaffLoginContextStore; SessionInactivityGuard
    │   ├── backend/                  — BackendPort (isConfigured, healthCheck) + SupabaseBackendPort
    │   ├── config/                   — AppEnvironment (dart-define parsing/validation)
    │   ├── connectivity/             — ConnectivityService (connectivity_plus), unused
    │   ├── di/                       — AppDependencies (composition roots), AppScope
    │   ├── errors/                   — AppFailure, FailureKind
    │   ├── feature_flags/            — FeatureFlagService (fail-closed premium flags)
    │   ├── identity/                 — UserIdentity, UserRole, PlanTier
    │   ├── localization/             — LocaleController, IdentityLocaleCoordinator
    │   ├── logging/                  — AppLogger, DebugAppLogger
    │   ├── media/                    — MediaStorage port, SupabaseMediaStorage, task photo capture (io/stub conditional export), TaskPhotoService, access check
    │   ├── navigation/               — ShmRoutes, AppRouter (role-guarded onGenerateRoute)
    │   ├── notifications/            — local notifications, FCM token source, push registration, envelope, coordinator, Supabase repo
    │   ├── observability/            — LocalCrashReporter, owner-auth diagnostics, recovery trace
    │   ├── permissions/              — DevicePermissionService, PermissionPolicy (role/plan)
    │   ├── persistence/              — LocalStore (secure/memory)
    │   ├── presentation/             — ViewStatePanel
    │   ├── privacy/                  — SharedDeviceDataManager (per-user cleanup on lock)
    │   ├── repositories/             — repository ports (household, staff, task, conversation) + Supabase identity repos
    │   ├── result/                   — AppResult (sealed)
    │   ├── shm_theme.dart            — ShmColors/Spacing/Radii/Sizes + buildShmTheme()
    │   ├── state/                    — ViewState (sealed)
    │   └── sync/                     — OfflineSyncCoordinator
    ├── data/                         — mock_household.dart, screen_catalog.dart (M1 bilingual prototype content)
    ├── domain/                       — prototype_models.dart (ScreenId, ScreenDefinition, PrototypeItem/Action)
    ├── features/
    │   ├── feature_registry.dart     — ShmFeature enum + FeatureManifest(minimumTier, roles)
    │   ├── childcare/domain/
    │   ├── communication/{application,data,domain,presentation}/
    │   ├── guide/{data,domain}/
    │   ├── operations/domain/
    │   ├── storage_diagnostics/{application,data,presentation}/
    │   └── tasks/                    — representative feature, expanded below
    │       ├── domain/               — task_models.dart (recurrence, statuses, DailyTask, RoutineTemplate), task_assignment.dart
    │       ├── data/                 — supabase_task_repository.dart (port + impl), task_assignment_repository.dart, supabase_task_sync_transport.dart
    │       ├── application/          — task_offline_sync.dart (ChangeNotifier cache + durable queue), task_policy.dart (alert policy, EndOfDayEvaluator)
    │       └── presentation/         — owner_task_panel.dart (StatefulWidget composer), owner_ready_tasks.dart (const template data)
    └── presentation/
        ├── prototype_screen.dart     — 3076-line god screen (login, all screens, dialogs, header, grid, nav)
        └── shm_widgets.dart          — ShmItemCard, ShmDecisionBanner, TierLegend, placeholder, _StatusPill
```

Outside `lib/`: `config/development.example.json` holds non-secret defines; `supabase/{migrations,functions,tests,config.toml}`; `tool/` holds Python/Node backup and schema-test scripts; `docs/` holds ADRs and milestone records; `test/` has 39 files.

## 3. Infrastructure

### State management
There is no state-management package. Screens are `StatefulWidget`s using `setState` (`prototype_screen.dart` has 36 calls). Cross-cutting state uses `ChangeNotifier` + `ListenableBuilder`: `LocaleController` (rebuilds MaterialApp) and `TaskOfflineSync` (cached tasks and pending actions). A sealed `ViewState<T>` (`Initial/Loading/Empty/Ready/Failed(safeMessage, retry)`) and an exhaustive-switch `ViewStatePanel<T>` exist in core, but nothing in the app uses them. They are still a clean, dependency-free pattern to reuse.

### DI
`lib/src/core/di/app_dependencies.dart` is an immutable bag of about 30 services with two factories:
- `AppDependencies.local()` uses MemoryLocalStore, LocalAuthenticationService, UnconfiguredBackendPort, Disabled media/AI, and Noop notifications.
- `AppDependencies.supabase(client: …)` builds every Supabase adapter and coordinator by hand.

It is exposed with `AppScope` (`InheritedWidget`, `of`/`maybeOf`). There is no service locator and no codegen (ADR 0001 rejected "a large state-management/DI framework"). The pattern is easy to test, since tests construct `AppDependencies(...)` with fakes. The downside: the container is SHM-specific, and `core/di` imports `features/*`.

### Routing
`lib/src/core/navigation/app_router.dart` uses Navigator 1.0 `onGenerateRoute` with the scheme `'/screen/${ScreenId.name}'` (`ShmRoutes.forScreen/parse`). Every non-login route is wrapped in `_ScreenRoute`, which resolves `currentIdentity()` (5 s timeout), listens to `watchIdentity()`, and renders the role's login screen when the identity's role does not match the screen's role. The guard fails closed, and Staff can fall back to a cached offline identity. `SessionInactivityGuard` (in `MaterialApp.builder`) locks the session on inactivity timeout or when the app goes to background. Staff lock immediately; Owners get a 30 s grace. Both `_OwnerSessionStartupGate` and the guard force-navigate through a global `navigatorKey`. There is no go_router and no URL deep linking beyond the auth-recovery scheme.

### Networking (Supabase)
**Client setup** (`lib/src/bootstrap.dart`):
```dart
final pkceStorage = SharedPreferencesGotrueAsyncStorage();
final supabase = await Supabase.initialize(
  url: environment.backendUrl.toString(),
  publishableKey: environment.backendPublicKey!,
  authOptions: FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
    pkceAsyncStorage: pkceStorage,
  ),
);
return AppDependencies.supabase(environment: environment, client: supabase.client,
    recoveryPkceStorage: pkceStorage, /* push, crash, diagnostics */);
```
- The single `SupabaseClient` is passed by constructor to every adapter. Nothing calls `Supabase.instance` inside repositories, so they are testable.
- Calls used: `client.from(...).select/insert/upsert` with embedded joins (`households!inner(plan_tier)`), `client.rpc(...)` for privileged writes (`create_household`, `set_owner_pin`, `register_push_installation`), `client.functions.invoke('staff-pin-login', body:)` followed by `auth.verifyOTP(tokenHash:, type: magiclink)`, `client.storage.from(bucket).uploadBinary/createSignedUrl`, and Realtime via `.stream(primaryKey: ['id'])`. For Realtime, each change re-fetches through the repository (`hydrateConversationChanges`).
- No interceptors, since there is no dio. Token refresh is GoTrue's own. No HTTP retry. Offline Staff task responses go to a durable queue (`OfflineActionQueue` in secure storage, with `attemptCount` and a `SyncDisposition` of accepted/retryable/permanent/conflict). The server operations are idempotent (`operationId`).
- Error mapping: each repo has a private `_failure(code, error)` that returns `Failure(AppFailure(kind: network, code: 'x_failed', safeMessage: '…', cause: error))`. Auth and Edge Function errors are reduced to allowlisted codes (`ownerAuthDiagnosticCode`, `staffPinBackendErrorCode`), and provider messages are never surfaced. `PostgrestException` is special-cased in 3 places.
- The one non-Supabase HTTP call is `OwnerPasswordRecoveryTransport` (package `http`), which sends a recovery request with its own PKCE challenge. It contains a hardcoded dev-host allowlist (`{{BACKEND_HOST}}`), which should not be copied.

### Local storage
`lib/src/core/persistence/local_store.dart` defines `LocalStore { writeString, readString, delete, clearScope(prefix) }`. `SecureLocalStore` wraps `FlutterSecureStorage(aOptions: AndroidOptions(migrateWithBackup: false))`, and `MemoryLocalStore` is used for local/dev. Key conventions:
- `'$userId:…'` keys are wiped on lock.
- `'durable:$userId:…'` keys survive lock (offline actions).
- `'device:…'` keys are per installation.

`SharedDeviceDataManager.clearUserSession` applies these rules. Shared preferences are used only indirectly, for the GoTrue PKCE verifier.

### Localization and RTL
There is no ARB or easy_localization. `AppText` (an InheritedWidget, `lib/src/core/app_text.dart`) exposes `isArabic`, `setArabic`, and `pick(en, ar)`, and every string is inlined as an EN/AR pair (about 237 call sites). `MaterialApp` gets `supportedLocales` [en, ar] plus `GlobalMaterialLocalizations.delegates`. `LocaleController` (ChangeNotifier) provides `locale`/`textDirection`, and the app wraps the child in an explicit `Directionality`. `IdentityLocaleCoordinator` applies the Staff profile language on login and stores the Owner's choice under a user-scoped key, so one user's locale never leaks to the next user of a shared device.

RTL hygiene is good: only 2 Directional usages are needed. The 4 left/right hits are gradient alignments, and the 8 `fromLTRB` paddings are symmetric. The back icon is flipped manually (`arrow_forward` in Arabic) instead of using `BackButton`. The approach does not scale past two languages, and `AppFailure.safeMessage` strings are English only.

### Theming
`lib/src/core/shm_theme.dart`:
- Token classes: `ShmColors` (19 named colors), `ShmSpacing` (4 to 40), `ShmRadii` (12/16/20/24), `ShmSizes` (48 tap target, 60 staff tap target, 1120 max width).
- `buildShmTheme()` builds an M3 light `ColorScheme.light(...)` with TextTheme overrides and full component themes: appBar, card, filled/outlined/text/icon buttons (48 min size), checkbox, chip, input (outline borders), snackbar (floating), bottomSheet (drag handle), and navigationBar. It uses `WidgetStateProperty` and `withValues(alpha:)`, so it is current API.

There is no dark theme, the font is the system `'sans-serif'`, and widgets still use `ShmColors.*` directly in many places instead of reading `Theme.of`.

### Responsive
There is no helper. Breakpoints are inline: page padding 16/24/40 at width <600/≥600/≥900; action grid at 1/2/3 columns (≥430 or 520 for staff, ≥700); compact app bar at width <390 or large text; content constrained to 1050 (screens), 520 (chat bubbles), and 440 (login).

### Text scaling
Nothing is clamped globally in MaterialApp. Individual Text widgets clamp with `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5–2.0)`. Cards and headers switch from Row to Column when `textScaler.scale(16) >= 32`, which is a good accessibility pattern to keep.

### Env / flavors
Everything goes through compile-time defines, read in `AppEnvironment.fromDefines()`. A separate `fromValues()` factory makes it testable.
- `SHM_FLAVOR`: development, staging, or production. An unknown value sets `hasValidFlavor=false`.
- `SHM_BACKEND_URL`, `SHM_BACKEND_PUBLIC_KEY`: the backend counts as configured only if the key starts with `sb_publishable_` (and not `sb_secret_`) and the URL has a host. Outside development the URL must be https.
- `SHM_SESSION_TIMEOUT_MINUTES` (default 15, minimum 1) and `SHM_VERBOSE_LOGS` (defaults to true in development).
- `bootstrap.dart` resolves the startup mode: `configuredBackend`, `localDevelopment` (development flavor without a backend only), or `configurationError` (shows `ShmConfigurationErrorApp`).
- Android Firebase options come from `SHM_FIREBASE_*` defines, not `firebase_options.dart`.
- `config/development.example.json` contains only the flavor and verbose flag.
- There are no native flavors or schemes. Android release signing reads 4 env vars (all or none) in `android/app/build.gradle.kts`.
- `supabase/functions/.env.example` exists (variable names only; not opened). Edge Functions read `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEYS` (a JSON map), and `SHM_*` server secrets through an injected `getEnv`.

### Logging
`AppLogger` interface (`debug/warning/error` with a `context` map) and `DebugAppLogger(enabled)`. It writes `[SHM][LEVEL] message {context}` through `debugPrint` and redacts any context key containing pin, password, token, authorization, message, signedurl, etc. Errors log only `runtimeType`. There are 20 additional raw `debugPrint` calls (auth and PIN diagnostics).

### Analytics / crash reporting
No Firebase Crashlytics, Analytics, or Sentry. `LocalCrashReporter` appends sanitized entries to `<appSupport>/diagnostics/crashes-v1.json`, capped at 20 entries and 64 KB, with writes serialized. The sanitizer redacts paths, JWTs, API-key shapes, bearer tokens, `key=value` secrets, UUIDs, emails, URLs, 4–8 digit numbers, and capitalised name pairs. `GlobalErrorCapture` forwards errors from `FlutterError.onError`, `PlatformDispatcher.onError`, and `runZonedGuarded`. The `CrashReporter` interface makes a Sentry/Crashlytics adapter easy to add.

### Push notifications
- `PlatformLocalNotificationService` (flutter_local_notifications 22) handles lazy init, timezone setup, 2 Android channels (standard/urgent), iOS time-sensitive interruption level, `zonedSchedule` with inexact-allow-while-idle, and stable int ids via an FNV hash. `NotificationPrivacyPolicy` replaces sensitive bodies with generic lock-screen text.
- `FirebasePushTokenSource` waits for the APNs token on iOS and keeps a per-install UUID in secure storage. `PushRegistrationCoordinator` serializes associate/deactivate whenever the identity changes or the token refreshes. Tokens are registered through Supabase RPCs, and server delivery runs through a PostgreSQL outbox and the `push-outbox-processor` function.
- `RemotePushEnvelope.verifiedIntent` accepts only a single `shm_intent` key holding a versioned JSON intent. No route or content is ever in the push data.
- `LocalNotificationCoordinator` handles taps. On a cold start it locks the shared device before routing.
- Weakness: in-app polling uses `Timer.periodic(15 s)`.

### IAP / payments
None. The Premium tier is modeled only as `PlanTier`, with fail-closed feature flags.

### Permissions
`DevicePermissionService` maps permission_handler statuses (granted/limited → granted; permanentlyDenied/restricted → restricted) to a 4-state enum for camera, microphone, photos, and notifications, plus `openSystemSettings`. `DisabledDevicePermissionService` is the default. The separate `PermissionPolicy` is the role/plan authorization matrix (`ShmPermission` enum). The UI uses it only for hints, and RLS is the real boundary.

### Deep links
Only the Supabase password-recovery redirect: a custom scheme declared in the Android intent-filter, with `ownerRecoveryRedirectUri` hardcoded as `com.example.app://auth/recovery`-style in `supabase_authentication_service.dart`. `watchOwnerPasswordRecovery()` listens to `onAuthStateChange` for `passwordRecovery`. There is no app_links/uni_links.

### Media
Capture is split by conditional export (`task_photo_capture.dart` → `_io`/`_stub`). Android uses a custom Kotlin MethodChannel camera; iOS uses `image_picker`. Both re-encode to a PNG of at most 1024 px through `dart:ui`, which drops EXIF/GPS, then zero the raw bytes and delete the temp file. `SupabaseMediaStorage` uploads to private buckets with sanitized, nonce-based paths and returns 300 s signed URLs, and hard delete is disabled. Voice messages use a native MethodChannel (`PlatformConversationVoiceDevice`). Text-to-speech uses MethodChannel on native and `speechSynthesis` on web.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/src/core/config/app_environment.dart | Env/flavor from dart-defines + validation | `AppEnvironment.fromDefines/fromValues`, `hasBackendConfiguration`, `hasSafePublicBackendKey`, `allowsLocalFallback`, `sessionTimeout` | none | Generic (rename prefix) |
| lib/src/bootstrap.dart | App startup | `bootstrapShm()`, `resolveStartupMode()`, `AppStartupMode`, `shmFirebaseBackgroundHandler` | firebase_core/messaging, supabase_flutter | Mostly generic |
| lib/src/core/di/app_dependencies.dart | Composition roots | `AppDependencies.local/.supabase`, ~30 service fields, `sharedDeviceData` | everything | App-specific (pattern generic) |
| lib/src/core/di/app_scope.dart | InheritedWidget DI | `AppScope.of/maybeOf` | flutter | Generic |
| lib/src/core/result/app_result.dart | Sealed result | `AppResult.fold`, `Success`, `Failure` | none | Generic |
| lib/src/core/errors/app_failure.dart | Error value | `AppFailure(kind, code, safeMessage, cause)`, `FailureKind` | none | Generic |
| lib/src/core/state/view_state.dart | UI state union | `Initial/Loading/Empty/Ready/Failed` | none | Generic |
| lib/src/core/logging/app_logger.dart | Logging | `AppLogger.debug/warning/error`, `DebugAppLogger` | flutter foundation | Generic |
| lib/src/core/persistence/local_store.dart | KV storage | `LocalStore.writeString/readString/delete/clearScope`; `SecureLocalStore`, `MemoryLocalStore` | flutter_secure_storage | Generic |
| lib/src/core/connectivity/connectivity_service.dart | Online/offline | `current()`, `watch()` | connectivity_plus | Generic (unused) |
| lib/src/core/backend/backend_port.dart / supabase_backend_port.dart | Backend health | `isConfigured`, `healthCheck()` | supabase_flutter | Generic-ish (health query hits an app table) |
| lib/src/core/auth/authentication_service.dart | Auth ports | `watchIdentity`, `currentIdentity`, `signInOwner`, `signInStaff`, `signOut`, `lockSharedDevice`; `OwnerPinAuthentication` | identity, result | App-specific shape |
| lib/src/core/auth/supabase_authentication_service.dart | Supabase auth (password, PIN via Edge Function + verifyOTP, recovery, device lock) | as above + diagnostic code mappers | supabase_flutter, LocalStore, diagnostics | App-specific (791 lines) |
| lib/src/core/auth/local_authentication_service.dart | In-memory auth for prototype | as above | none | Generic-ish |
| lib/src/core/auth/owner_password_recovery_transport.dart | PKCE recovery HTTP request | `request(email, redirectUri, publishableKey)` | http, crypto | App-specific (hardcoded host) |
| lib/src/core/auth/session_inactivity_guard.dart | Inactivity/background lock widget | widget | auth, router, privacy | Semi-generic |
| lib/src/core/auth/staff_login_context.dart | Device pairing context + install UUID | `load`, `pairToHousehold`, `inspectPresence`, `changeHouseholdAfterOwnerConfirmation`, `removePairingAfterOwnerConfirmation` | LocalStore | App-specific |
| lib/src/core/auth/staff_device_pairing_service.dart | Pairing workflow | `loadState`, `pairToHousehold`, `changeHousehold`, `removePairing` | auth, household repo | App-specific |
| lib/src/core/identity/user_identity.dart | Identity model | `UserIdentity`, `UserRole`, `PlanTier` | none | App-specific |
| lib/src/core/permissions/device_permission_service.dart | OS permissions | `status`, `request`, `openSystemSettings` | permission_handler | Generic |
| lib/src/core/permissions/permission_policy.dart | Role/plan authorization matrix | `allows`, `canAccessStaffRecord` | identity | App-specific (pattern generic) |
| lib/src/core/feature_flags/feature_flag_service.dart | Premium flags (fail closed) | `isEnabled` | identity | Pattern generic |
| lib/src/core/localization/locale_controller.dart | Locale + direction | `locale`, `isArabic`, `textDirection`, `setArabic`, `setLanguageCode` | flutter | Generic (2 langs) |
| lib/src/core/localization/identity_locale_coordinator.dart | Per-identity locale | `start`, `applyIdentity`, `userSelected`, `dispose` | auth, LocalStore | Semi-generic |
| lib/src/core/app_text.dart | Inline bilingual strings | `AppText.of`, `pick(en, ar)` | flutter | Generic (2 langs only) |
| lib/src/core/navigation/app_router.dart | Routes + guard | `ShmRoutes.forScreen/parse`, `AppRouter.onGenerateRoute/push` | prototype catalog | App-specific |
| lib/src/core/media/media_storage.dart | Storage port | `upload`, `createReadUri`, `delete`; `MediaUpload`, `MediaPurpose` | result | Generic-ish |
| lib/src/core/media/supabase_media_storage.dart | Supabase Storage adapter | same | supabase_flutter | Semi-generic (bucket map) |
| lib/src/core/media/task_photo_capture(_io/_stub).dart | Camera capture + EXIF strip | `capture(languageCode)` | image_picker, MethodChannel, dart:ui | Semi-generic (re-encode logic) |
| lib/src/core/media/task_photo_service.dart | Capture → check → upload flow | `take(taskId, active)` → `TaskPhotoOutcome` | auth, storage | App-specific |
| lib/src/core/media/supabase_task_photo_access.dart | Upload permission check | `canUpload` | supabase_flutter | App-specific |
| lib/src/core/notifications/notification_service.dart | Local notifications | `schedule`, `cancel`, `cancelAllForUser`, `initializeInteractions`; `NotificationPrivacyPolicy` | flutter_local_notifications, timezone | Generic |
| lib/src/core/notifications/firebase_push.dart | FCM token + tap source | `currentRegistration`, `tokenRefreshes`, `initializeInteractions` | firebase_messaging, LocalStore | Generic |
| lib/src/core/notifications/push_registration.dart | Token↔identity registry | `start`, `identityChanged`, `tokenRefreshed`, `dispose`; `SupabasePushInstallationRepository` | supabase_flutter | Semi-generic |
| lib/src/core/notifications/remote_push_envelope.dart | Push payload validation | `verifiedIntent(data)` | coordinator | Pattern generic |
| lib/src/core/notifications/local_notification_coordinator.dart | Notification sync + tap routing | `receive`, `sync`, `suspend`, `dispose`; `TaskNotificationIntent.encode/decode` | auth, repo, store | App-specific |
| lib/src/core/notifications/task_notification_repository.dart | Pending task notifications | `pending`, `find` | supabase_flutter | App-specific |
| lib/src/core/observability/crash_reporter.dart | Local crash log | `record`, `readDiagnostics`; `GlobalErrorCapture.flutter/platform/zone` | path_provider, package_info_plus, dart:io | Generic |
| lib/src/core/observability/owner_auth_diagnostics.dart | Temporary auth diagnostics | `beginAttempt`, `record`, code mappers | path_provider | App-specific / temporary |
| lib/src/core/observability/owner_recovery_trace.dart | In-memory recovery trace | `OwnerRecoveryTrace`, `OwnerRecoveryTraceSource` | foundation | App-specific |
| lib/src/core/privacy/shared_device_data_manager.dart | Per-user cleanup on lock | `clearUserSession(userId)` | LocalStore, notifications | Semi-generic |
| lib/src/core/repositories/repository_ports.dart | Repo ports + summaries | Household/StaffIdentity/Task/Conversation repos | result | App-specific |
| lib/src/core/repositories/supabase_identity_repositories.dart | Household/staff Supabase repos | `getHousehold`, `getOwnedHouseholds`, `createHousehold`, `getStaff`, `archiveStaff`, `setStaffPin` | supabase_flutter | App-specific |
| lib/src/core/sync/offline_sync_coordinator.dart | Generic offline sync run | `synchronize(userScope, now)` → `SyncRunSummary` | OfflineActionQueue | Generic (unused by app) |
| lib/src/core/ai/ai_service.dart | AI port (disabled) | `ask`, `teach` | result | Pattern only |
| lib/src/features/communication/application/offline_action_queue.dart | Durable JSON action queue | `read`, `enqueue`, `complete`, `replace`, `clearUser` | LocalStore | Generic |
| lib/src/features/communication/application/language_services.dart | Translation/TTS ports | `translate`, `speak` | result | Generic ports |
| lib/src/features/communication/application/device_speech_engine*.dart | TTS engine (native channel / web speechSynthesis) | `speak`, `stop` | MethodChannel, package:web | Generic |
| lib/src/features/communication/application/device_speech_playback_service.dart | TTS service | `speak`, `stop` | engine | Generic |
| lib/src/features/communication/application/conversation_voice_service.dart | Voice note record/upload/play | start/stop/send/play | MethodChannel, storage, repo | App-specific |
| lib/src/features/communication/data/supabase_communication_repository.dart | Chat repo + realtime | conversations, messages, `watchMessages`, `sendText`, `sendToAll`, acknowledge, `requestTranslation`, `sendVoice` | supabase_flutter | App-specific |
| lib/src/features/tasks/application/task_offline_sync.dart | Offline task cache + queue | `remember`, `flush`, `lock`, `cachedIdentity`, `cachedTasks`, `pendingResponse` | queue, transport | App-specific |
| lib/src/features/tasks/application/task_policy.dart | Alert policy, end-of-day evaluation | `EndOfDayEvaluator.evaluate` | domain | App-specific |
| lib/src/features/tasks/data/*.dart | Task repos/transport | createRoutine, getToday, respond, requestDeferral, send, apply | supabase_flutter | App-specific |
| lib/src/features/guide/data/supabase_guide_repository.dart | Guide reference | `allowedItems`, `search` | supabase_flutter | App-specific |
| lib/src/features/storage_diagnostics/** | Owner storage access probe | `run()` | supabase_flutter | App-specific / diagnostic |
| lib/src/features/feature_registry.dart | Feature manifest | `ShmFeatureRegistry.all` | identity | Pattern generic |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/src/core/presentation/view_state_panel.dart `ViewStatePanel<T>` | Loading / empty / error+retry / ready switch | `state`, `readyBuilder`, `emptyLabel`, `errorLabel` | y ('Retry' hardcoded) |
| lib/src/core/auth/session_inactivity_guard.dart `SessionInactivityGuard` | Inactivity + background auto-lock, blocks input while locking | `authentication`, `timeout`, `navigatorKey`, `sharedDeviceData`, `ownerBackgroundGrace`, `child` | partly |
| lib/src/presentation/shm_widgets.dart `ShmDecisionBanner` | Decision/urgent banner with action | `urgent`, `title`, `detail`, `actionLabel`, `onPressed` | mostly |
| lib/src/presentation/shm_widgets.dart `_StatusPill` | Tinted badge with icon | `label`, `color`, `icon` | y (private) |
| lib/src/presentation/shm_widgets.dart `ShmItemCard` | Icon/title/subtitle/status/checkbox card with a11y reflow | `item`, `simplified` | n (PrototypeItem) |
| lib/src/presentation/shm_widgets.dart `TierLegend` | Essential/Premium/backend legend | none | n |
| lib/src/presentation/shm_widgets.dart `ReplaceableDashboardPlaceholder` | Artwork placeholder | none | n |
| lib/src/presentation/prototype_screen.dart `_RoleNavigation` / `_NavigationDestination` | Floating rounded dark bottom nav with Semantics | `current`, `role`, `onDestination` / `icon`, `label`, `selected`, `onTap` | partly |
| lib/src/presentation/prototype_screen.dart `_Header` | Screen header (icon tile + title + subtitle) | `screen` | partly |
| lib/src/presentation/prototype_screen.dart `_ActionGrid` | Responsive tonal-button grid | `actions`, `onTap`, `simplified` | partly |
| lib/src/presentation/prototype_screen.dart `_OwnerCredentialsSheet`, `_OwnerNewPasswordDialog`, `_OwnerPinEnrollmentDialog`, `_StaffPinResetDialog` | Auth sheets/dialogs | various | n |
| lib/src/app.dart `ShmConfigurationErrorApp` | Fail-closed misconfiguration screen | none | y (swap copy) |
| lib/src/features/communication/presentation/real_conversation_panel.dart `RealConversationPanel` (+ `_Notice`) | Chat with realtime, voice, translation | `repository`, `authentication`, `expectedRole`, `staffIdentity`, `voiceMessages`, `devicePermissions` | n (`_Notice` y) |
| lib/src/features/tasks/presentation/owner_task_panel.dart `OwnerTaskPanel` | Task composer/assignment | none | n |
| lib/src/features/storage_diagnostics/presentation/owner_storage_probe_panel.dart `OwnerStorageProbePanel` | Diagnostic dialog | `probe` | n |

There is no shared app-bar widget, text field, network image, shimmer, pagination list, or toast helper. Inputs rely on `inputDecorationTheme`, and snackbars use `ScaffoldMessenger` directly.

## 6. Packages (`pubspec.yaml`, resolved versions from lock)

- **State / DI / routing:** none (Flutter SDK only)
- **Backend / network:** `supabase_flutter ^2.0.0` (2.17.2; gotrue 2.27.2), `http ^1.6.0`, `crypto ^3.0.7`, `connectivity_plus ^7.3.1`
- **Storage:** `flutter_secure_storage ^11.0.0`, `path_provider ^2.1.6` (shared_preferences 2.5.5 transitive)
- **L10n:** `flutter_localizations` (sdk)
- **Firebase / push:** `firebase_core ^4.14.0`, `firebase_messaging ^16.6.0`, `flutter_local_notifications ^22.3.0`, `timezone ^0.11.1`
- **Media / permissions:** `image_picker ^1.2.3`, `permission_handler ^13.0.1` (+ `permission_handler.yaml` at root)
- **Utils / platform:** `package_info_plus ^10.2.1`, `web ^1.1.1`, `cupertino_icons ^1.0.8`
- **Dev:** `flutter_test`, `flutter_lints ^4.0.0`
- **Non-Dart:** Deno Edge Functions (TypeScript), pgTAP SQL tests, Python/Node backup and schema tooling in `tool/`

## 7. Quality notes

- **Null safety / language:** Dart 3 throughout: sealed classes, `switch` expressions with patterns, records (`(ScreenId, IconData, String, String)`), `abstract interface class`, `final class`. No deprecated Flutter APIs were found (`WidgetStateProperty`, `withValues`, `TextScaler`, `CardThemeData`).
- **Lints:** `analysis_options.yaml` = `flutter_lints` + `prefer_single_quotes`, `use_super_parameters`. Excludes build and platform dirs.
- **Tests:** 39 Flutter test files (~8.1k lines). They exercise security behavior well (fail-closed startup, route authorization, shared-device lock, PIN flows, push identity switching, offline sync, redaction). Fakes implement the port interfaces, and no mocking package is used. The backend has 21 pgTAP files and Deno unit tests per `_shared` module. The handover reports 322 Flutter, 47 Edge, and 21 SQL tests passing on the original workspace; not re-run here, per the read-only rules.
- **Smells:**
  - `prototype_screen.dart` (3076 lines) and `screen_catalog.dart` (1036 lines) are god files, with UI holding auth/task state.
  - Unused infrastructure: `ViewState`, `ViewStatePanel`, `ConnectivityService`, `OfflineSyncCoordinator`.
  - `ConnectionState` name clash.
  - Copy-pasted `_failure` helpers in 5 repos.
  - Repository ports live in `data/`, and core imports features.
  - Duplicated UUIDv4 code.
  - Hardcoded dev host and redirect scheme, which breaks the project's own AGENTS.md rule.
  - `dart:io` in code that also targets web.
  - Large temporary diagnostics code shipped in production paths.
  - 15 s polling timers in `app.dart`.
  - No dark mode or Arabic font, and user-visible failure messages are English only.
- **Docs conventions worth reusing:**
  - `AGENTS.md` holds permanent rules: spec as source of truth, an ADR is required for major architecture changes, checklist and plan are updated on scope changes, format/analyze/test are run and reported before handoff, and secrets/URLs are never hardcoded.
  - `docs/adr/NNNN-kebab-title.md` with Status / Date / Milestone, Context, Decision, Alternatives considered, Consequences or Impact & rollout (including rollback).
  - `docs/M<N>_IMPLEMENTATION_RECORD.md` per milestone; `docs/SHM_FEATURE_CHECKLIST.md` as an atomic checkbox inventory; `docs/SHM_IMPLEMENTATION_PLAN.md` with numbered sections and milestones.
  - Migrations named `YYYYMMDDNNNN_snake_name.sql` with an intent header comment; pgTAP tests in `supabase/tests/`.
  - README "Verify" block.
  - Handover integrity via `SOURCE_MANIFEST.json` + `SHA256SUMS`.
- **Secrets:** none committed in source. `supabase/functions/.env.example` exists (not opened). Test files contain synthetic key-shaped strings used to check redaction, and the PEM in the Edge test is generated at runtime. `supabase/config.toml` uses a placeholder project id.
