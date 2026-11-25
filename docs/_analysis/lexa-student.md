# lexa-student: analysis report

## Summary for comparison

```
PROJECT: lexa-student | path: My Apps/<client folder, redacted: contains a person's name>/lexa_student | stack: Flutter, Dart SDK ^3.11.5 (null-aware `?element` syntax), version 1.0.2+5 | last commit: 2026-09-08 (46 commits, clean tree) | source files: 138 (lib, excl. codegen_loader.g.dart + locale_keys.g.dart; ~17k LOC)
ARCH: feature-first, clean-arch-lite: features/<f>/{data (Firestore repos + local stores), domain (pure gates/outcomes/failures; optional), presentation/{managers, screens, widgets}}; lib/app/ = composition root (LexaApp, AccountGraph, theme); core/models byte-identical with lexa-control's core/domain. No use-case layer
STATE: flutter_bloc Cubits only (11), no base cubit. States are sealed class families (ExamsLoading/ExamsLoaded/ExamsFailed, SplashChecking/Login/Unavailable/Ready, SessionActive/SessionEnded) consumed with switch pattern-matching in BlocBuilder. App-lifetime SplashCubit/AccountsCubit/ThemeCubit live in lib/app/lexa_app.dart; per-session SessionCubit + NotificationsCubit live in features/session/presentation/widgets/session_providers.dart, keyed by studentKey
DI: none (manual) — composition root lib/app/account_graph.dart (AccountGraph.of(FirebaseScope) builds every repository for one FirebaseApp; swapped wholesale on an account switch) + RepositoryProvider.value list in lib/app/lexa_app.dart
ROUTING: go_router ^17.5.0 — lib/core/routing/{app_router.dart, app_routes.dart (paths + names + isSignedOutReachable/mustLeaveWhenReady), route_redirect.dart (pure computeRedirect(SplashState, location, hasSavedAccounts)), go_router_refresh_stream.dart (multi-stream Listenable)} — guards: global redirect on the app-lifetime SplashCubit + AccountsCubit; ShellRoute that provides one RegistrationCubit to a 5-step wizard; ShellRoute that builds SessionProvidersScope (keyed per student); StatefulShellRoute.indexedStack (5 tabs); version/maintenance gate rendered inside SessionTabShell | deep links: none
NETWORK: firebase (cloud_firestore + firebase_auth), every service from FirebaseAuth/FirebaseFirestore.instanceFor(app) via lib/core/firebase/{firebase_bootstrap.dart, account_scope.dart}; a CI script bans `.instance` elsewhere — interceptors: none | token refresh: y (explicit getIdToken(true) on account switch, features/auth/data/auth_repository.dart) | retry: user-driven (12s timeout per gate call -> GateUnavailable screen with Retry, features/session/domain/session_gate.dart) | error mapping: AuthRepository._translate -> LexaFailure subclasses; lib/core/error/error_messages.dart describeErrorMessage maps LexaFailure / Firebase codes / Socket / Timeout to translation keys, the fallback names the code; logging stays at catch sites (logAppError)
RESULT_TYPE: exceptions — LexaFailure implements Exception (lib/core/error/failures.dart) + per-feature subclasses (features/auth/domain/auth_failures.dart, features/registration/domain/registration_failures.dart, SettingsReadDenied, StudentLookupDenied), plus sealed outcome types (GateOutcome, AccountOutcome, PlatformStatus)
STORAGE: shared_preferences only — features/session/data/identity_cache.dart (per-uid keys + legacy migration), features/accounts/data/saved_account_store.dart (versioned JSON, max 5), features/registration/data/pending_registration_store.dart (crash-recovery), features/notifications/data/seen_notification_store.dart, features/settings/data/theme_store.dart, lib/core/error/session_trail.dart (diagnostic ring buffer). No secure storage, by an explicit decision
L10N: easy_localization ^3.0.8 with CodegenLoader (lib/core/l10n/codegen_loader.g.dart) + LocaleKeys — en, ar; start ar, fallback en; assets/translations/{en,ar}.json (388 lines each); mappers in lib/core/ui/l10n_format.dart (xTr() suffix naming); 79 raw 'key.path'.tr() calls bypass LocaleKeys — hardcoded UI strings: some (English LexaFailure/GateUnavailable messages, 'Show password' tooltip, English-only lib/core/utils/date_display.dart; language names are literal by design)
RTL: Directional=5 vs LeftRight=2 (both are gradient Alignment.topLeft/bottomRight; all 15 EdgeInsets.fromLTRB calls are symmetric left==right). AppTextField.forceLtr / DetailRow.forceLtrValue for phone/email; the wordmark forces LTR
THEME: lib/app/theme.dart (buildLexaTheme(Brightness), lexaOverlayStyle) + lib/core/theme/app_color_schemes.dart (same explicit M3 schemes as control) — dark mode y (default dark, persisted) | component themes y (appBar, card, filled/outlined buttons, input, listTile, divider, navigationBar, chip) | colors: ColorScheme extension getters AppSemanticColors on ColorScheme (brandGold...) + StatusTone.colorFor hex table | text styles: none in ThemeData — 97 inline TextStyle(fontSize: context.fontSize(n)) | fonts: platform default
RESPONSIVE: custom helper lib/core/responsive/breakpoints.dart — breakpoints: compact <600, medium >=600, expanded >=905 (width, MediaQuery.sizeOf); fontBump 0/1/2, gutter 16/24/32, maxContentWidth inf/720/900, ContentWidthLimit widget
TEXT_SCALING: MediaQuery.withClampedTextScaling in MaterialApp.router builder (lib/app/lexa_app.dart), range 1.0–1.3 (kMinTextScale/kMaxTextScale in lib/core/responsive/breakpoints.dart); the avatar letter uses TextScaler.noScaling
ENV/FLAVORS: no flavors/dotenv — one --dart-define bool LEXA_TRACE (lib/core/error/error_log.dart); constants in lib/core/branding/app_branding.dart (incl. public privacy/delete-account URLs); version gate via package_info_plus. CI/CD: .github/workflows/{ci,release,bump-build-number}.yml + tool/bump_build_number.sh
LOGGING: dart:developer through lib/core/error/error_log.dart (logAppError / logAppEvent / logAppTrace, pluggable sessionDiagnosticSink) + SessionTrail persisting the last 40 lines and replaying them on the next launch (lib/core/error/session_trail.dart); SplashCubit.onChange logs every transition
ANALYTICS/CRASH: none
PUSH: none (no FCM / local notifications) — in-app notification feed computed from Firestore streams (core/models/notification_engine.dart + features/notifications/presentation/managers/notifications_cubit.dart + SeenNotificationStore)
PAYMENTS/IAP: none
PERMISSIONS: none (no permission_handler; no permission-requiring plugins)
DEEP_LINKS: none (go_router paths only)
MEDIA/FILES: none beyond Image.asset + url_launcher (store/privacy links, lib/core/utils/store_launcher.dart)
TESTS: 27 test files — session gate/cubit/identity cache, the route redirect, account manager + saved-account store, registration rollback/availability, notifications clearing, combineLatest, session trail, l10n grade names/wall clock, phone validation, theme contrast. CI runs analyze --fatal-infos/--fatal-warnings, the tests, tool/check_no_firebase_singletons.sh and tool/check_shared_models.sh
LINTS: flutter_lints ^6.0.0 default include, 0 extra rules (identical file to lexa-control)
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/firebase/firebase_bootstrap.dart + account_scope.dart — FirebaseScope/AccountScope value objects, openNamedApp(), all services via instanceFor (no singletons) — quality 5 — coupling: low (firebase_options)
- lib/core/routing/go_router_refresh_stream.dart — Listenable over N streams for refreshListenable — quality 5 — coupling: none
- lib/core/utils/app_version.dart — parse/compare semver + build number, fail-closed isBelowRelease — quality 5 — coupling: none
- lib/core/error/session_trail.dart — persisted diagnostic ring buffer (40 lines) replayed at the next launch, chained async writes — quality 5 — coupling: low (shared_preferences)
- lib/core/error/error_log.dart — logAppError/logAppEvent/logAppTrace with a pluggable sink, pure Dart (usable from the domain) — quality 4 — coupling: none
- lib/core/error/error_messages.dart — describeErrorMessage(): app failures first, then Auth/Firestore code tables, a coded fallback — quality 3 — coupling: medium (imports feature failure types; string keys; matches on English message text)
- lib/core/routing/route_redirect.dart — pure, unit-tested redirect over a sealed splash state + saved-accounts flag — quality 4 — coupling: high (SplashState)
- lib/core/responsive/breakpoints.dart — Breakpoint enum (fontBump/gutter/maxContentWidth), context ext, text-scale consts, ContentWidthLimit — quality 4 — coupling: none
- lib/core/data/combine_latest.dart — combineLatest2 without rxdart (waits for both, forwards errors) — quality 4 — coupling: none
- lib/features/session/domain/session_gate.dart — launch gate behind a narrow SessionGateGateway interface, per-call timeout, fail-closed only on an answer — quality 4 (pattern) — coupling: high (student domain)
- lib/features/accounts/data/saved_account_store.dart — interface + versioned-JSON prefs implementation with a cap and a never-throw decode — quality 4 — coupling: low
- lib/features/accounts/data/firebase_app_registry.dart — named FirebaseApp lifecycle that never reuses a retired name — quality 4 — coupling: low
- lib/core/utils/platform_clock.dart — "now" in a configured IANA zone (timezone pkg) — quality 4 — coupling: low (hardcoded fallback zone)
- lib/features/settings/data/theme_store.dart + presentation/managers/theme_cubit.dart — persisted ThemeMode read before runApp — quality 4 — coupling: none
- lib/core/utils/validators.dart — form validators (email/password/confirm/required/phone) — quality 3 — coupling: low (raw string keys)
GENERIC_WIDGETS (every reusable widget):
- lib/core/widgets/buttons/app_filled_button.dart — primary FilledButton with busy spinner — label, onPressed, busy — quality 3 (spinner colour not bound; no icon/destructive) — generic? y
- lib/core/widgets/inputs/app_text_field.dart — labelled, icon-prefixed TextFormField — controller, label, icon, validator, keyboardType, textInputAction, textCapitalization, autocorrect, autofillHints, enabled, readOnly (lock suffix), forceLtr, autovalidateMode, onChanged, focusNode — quality 4 — generic? y
- lib/core/widgets/inputs/app_password_field.dart — password with a per-instance show/hide — controller, label, validator, textInputAction, autofillHints, onFieldSubmitted, enabled, autofocus, focusNode — quality 4 (English tooltip) — generic? y
- lib/core/widgets/feedback/loading_view.dart — centred spinner — none — quality 3 — generic? y
- lib/core/widgets/feedback/empty_view.dart — empty state — icon, title, message — quality 4 — generic? y
- lib/core/widgets/feedback/error_view.dart — error + translated retry — message, onRetry — quality 4 — generic? y
- lib/core/widgets/feedback/app_snackbar.dart — AppSnackBar.show(context, message, duration) — quality 3 — generic? y
- lib/core/widgets/feedback/confirm_dialog.dart — confirmDialog() → bool — context, title, message, confirmLabel, destructive — quality 3 (destructive sets bg only, not fg) — generic? y
- lib/core/widgets/layout/lexa_card.dart — padded Card with optional InkWell — child, padding, onTap — quality 4 — generic? y
- lib/core/widgets/layout/section_header.dart — section label + trailing — label, trailing — quality 3 — generic? y
- lib/core/widgets/layout/detail_row.dart — label/value row — label, value, icon, forceLtrValue — quality 4 — generic? y
- lib/core/widgets/layout/info_note.dart — info strip — text, icon — quality 4 — generic? y
- lib/core/widgets/layout/status_chip.dart — StatusChip + StatusTone.colorFor (hex table, alpha wash) — label, tone, icon — quality 3 (low-contrast wash; control's StatusPill is better) — generic? y
- lib/core/widgets/layout/group_schedule.dart — group's weekly schedule lines — group, dense, color — quality 3 — generic? n
- lib/core/widgets/branding/lexa_wordmark.dart — logo + name + slogan (forced LTR) — height, showSlogan — quality 3 — generic? n (pattern y)
- lib/core/responsive/breakpoints.dart — ContentWidthLimit — child — quality 4 — generic? y
- lib/features/session/presentation/widgets/blocking_scaffold.dart — undismissable full-screen blocker (PopScope canPop:false) — icon, title, message, actions, footer — quality 4 — generic? y (uses the wordmark)
- lib/features/session/presentation/screens/{maintenance_page,update_required_page,gate_unavailable_page,splash_page}.dart — blockers built on BlockingScaffold — message/storeUrl/onRetry/onSignOut — quality 4 — generic? y-ish
- lib/features/registration/presentation/widgets/registration_scaffold.dart — step-wizard scaffold with progress bar + RegistrationBottomBar — (step, title, child, subtitle, bottomBar) / (label, onPressed, busy, note) — quality 4 — generic? y (totalSteps const = 5)
- lib/features/accounts/presentation/widgets/account_avatar.dart — grapheme-cluster initial avatar — account, diameter, dimmed — quality 4 — generic? n (SavedAccount; the idea is generic)
- lib/features/accounts/presentation/widgets/account_tile.dart — AccountTile / AddAccountTile for the picker — account, isActive, busy, onTap, onRemove — quality 3 — generic? n
- lib/features/session/presentation/screens/session_tab_shell.dart — tab shell with app bar actions + platform-status gating — navigationShell — quality 3 — generic? n
NOTABLE_IDEAS: multi-account switching with one named FirebaseApp per account and no stored credentials (features/accounts/*, app/account_graph.dart, core/firebase/*); a sign-in staging FirebaseApp so logging in never evicts another session; AccountGraph composition root swapped wholesale, plus a ValueKey(studentKey) on the session scope to tear down all session state; a CI shell check banning Firebase singletons (tool/check_no_firebase_singletons.sh) and a byte-identity check for shared models across two repos (tool/check_shared_models.sh); SessionTrail (persisted diagnostics replayed next launch) + SplashCubit.onChange transition logging; launch gate behind a gateway interface with per-call timeouts (features/session/domain/session_gate.dart) and "answer vs non-answer" semantics; fail-closed version+build comparison (core/utils/app_version.dart); GoRouterRefreshStream over several streams; registration wizard sharing one cubit through a ShellRoute; a crash-recovery pending-registration record (features/registration/data/pending_registration_store.dart); per-uid identity cache with a legacy-key migration; combineLatest2 without rxdart; route builders deliberately non-const so .tr() rebuilds on a locale change (comment in app_router.dart); settings route reachable while signed out so the language can be switched before login; CodegenLoader so translations ship as Dart; release automation in .github/workflows + tool/bump_build_number.sh
SMELLS: no textTheme — 97 inline TextStyle(fontSize: context.fontSize(n)) across screens; StatusChip alpha-wash colours + a hex table (contrast); confirmDialog destructive sets only the background; error_messages.dart matches on English message text ('You are not signed in.') and regex-parses an English sentence (_levelNameFromMessage); 79 raw string-key .tr() calls next to generated LocaleKeys (two conventions); stale comment in core/utils/date_display.dart ("app has no localization layer") with English-only month names; English copy in GateUnavailable/LexaFailure ctors; core/error/error_messages.dart imports feature-layer types (core -> features dependency); "PHASE 0 DIAGNOSTIC" trace calls left on by default (LEXA_TRACE defaults true); god-ish files: account_manager.dart 533, profile_page.dart 580, home_page.dart 469, details_form_page.dart 445; theme lives in lib/app/ while colour schemes are in lib/core/theme/ (split); zero extra lint rules; no crash reporting
```

---

## 1. Architecture pattern

Feature-first, clean-arch-lite. It is more pragmatic than lexa-control: there is **no use-case layer**.
- **data/**: concrete repositories over an injected `FirebaseFirestore`/`FirebaseAuth`, plus local stores over `shared_preferences`. Repositories mostly return `Stream<T>` from `snapshots()`.
- **domain/**: present only where there is real logic. It holds pure gates and outcomes (`session_gate.dart`, `gate_outcome.dart`, `platform_status.dart`), failure types, draft and availability value objects for registration, `account_manager.dart` (orchestration) and `fee_ledger.dart`. `exams`, `homework` and `settings` have no domain folder.
- **presentation/**: `managers/` (Cubit + sealed state), `screens/`, `widgets/`.
- **lib/app/**: the composition root.
  - `lexa_app.dart` builds the router and the app-lifetime cubits once, in `initState`.
  - `account_graph.dart` is a value object holding every repository bound to one `FirebaseApp`.
  - `theme.dart` holds the theme.
- **core/models/**: the shared data contract, byte-identical with lexa-control's `core/domain/`.

Flow: Screen → Cubit (subscribes to a repository stream) → Repository → Firestore. Session gating is a separate pipeline:
1. `SplashCubit.check()` runs `SessionGate.run()` through the `SessionGateGateway` interface, implemented by `FirebaseSessionGateway`.
2. The result is a `GateOutcome`, mapped to a `SplashState`.
3. The router redirect reacts to that state.
4. `SessionProvidersScope` creates `SessionCubit` and `NotificationsCubit` for one verified identity, keyed by studentKey. `SessionCubit` keeps re-validating through live listeners.

## 2. Folder tree (lib/)

```
lib/
├── main.dart                     SessionTrail.install, EasyLocalization (CodegenLoader, start ar), bootstrapFirebase + bootstrapSignInApp, PlatformClock init, PackageInfo, ThemeStore.read, runApp(LexaApp)
├── firebase_options.dart         flutterfire output (secret-class file; not opened)
├── app/
│   ├── lexa_app.dart             StatefulWidget root: builds AccountGraph(s), AccountManager, Accounts/Splash/Theme cubits, GoRouter once; _restore() cold start; _activate() account switch; MaterialApp.router + clamped text scale
│   ├── account_graph.dart        AccountGraph.of(FirebaseScope) — every repository for one FirebaseApp
│   └── theme.dart                buildLexaTheme(brightness), lexaOverlayStyle, AppSemanticColors on ColorScheme
├── core/
│   ├── branding/                 app_branding.dart (names, slogan, palette, public URLs, asset paths)
│   ├── data/                     combine_latest.dart, publication_filter.dart (whereIn-30 publish join)
│   ├── error/                    failures.dart (LexaFailure), error_messages.dart (describeErrorMessage), error_log.dart, session_trail.dart
│   ├── firebase/                 firebase_bootstrap.dart (only Firebase entry point), account_scope.dart (FirebaseScope/AccountScope)
│   ├── l10n/                     codegen_loader.g.dart, locale_keys.g.dart (generated)
│   ├── models/                   shared contract (13 files, identical to lexa-control core/domain)
│   ├── responsive/               breakpoints.dart
│   ├── routing/                  app_router.dart, app_routes.dart, route_redirect.dart, go_router_refresh_stream.dart
│   ├── schedule/                 next_session.dart (pure "next class" arithmetic)
│   ├── theme/                    app_color_schemes.dart (same values as control)
│   ├── ui/                       l10n_format.dart (domain → translated strings)
│   ├── utils/                    academic_year, app_version, date_display, platform_clock, store_launcher, validators
│   ├── validation/               egyptian_phone.dart (identical to control)
│   └── widgets/
│       ├── branding/             lexa_wordmark.dart
│       ├── buttons/              app_filled_button.dart
│       ├── feedback/             app_snackbar, confirm_dialog, empty_view, error_view, loading_view
│       ├── inputs/               app_text_field, app_password_field
│       └── layout/               detail_row, group_schedule, info_note, lexa_card, section_header, status_chip
└── features/
    ├── accounts/ (multi-account picker)  attendance/  auth/  exams/  fees/  home/  homework/
    ├── notifications/  profile/  registration/ (5-step wizard)  settings/  teacher_contact/
    └── session/                                      (representative, fully expanded)
        ├── data/
        │   ├── firebase_session_gateway.dart          implements SessionGateGateway over the repos + IdentityCache
        │   ├── identity_cache.dart                    per-uid {studentKey, authUid, sessionEpoch} in prefs, legacy migration
        │   ├── platform_settings_repository.dart      load() (server) / watch(); SettingsReadDenied
        │   ├── staff_repository.dart                  isStaffAccount(uid) (permission-denied == not staff)
        │   └── student_repository.dart                byKey / byAuthUid / reconcileEmail / watch; StudentLookupDenied
        ├── domain/
        │   ├── session_gate.dart                      SessionGateGateway interface + SessionGate.run() (12s bounded calls)
        │   ├── gate_outcome.dart                      sealed GateAllowed / GateToLogin / GateUnavailable + GateSignOutReason
        │   ├── session_starter.dart                   establish(uid) / adopt() after sign-in or registration
        │   ├── platform_status.dart                   sealed PlatformOk/UpdateRequired/Maintenance/UpdateAvailable + evaluatePlatformStatus
        │   └── cached_identity.dart
        └── presentation/
            ├── managers/splash_cubit.dart + splash_state.dart   app-lifetime outer gate; rebind(gate) on account switch; onChange logging
            ├── managers/session_cubit.dart + session_state.dart session-scoped live validation (settings, student doc, auth stream)
            ├── screens/                               splash, gate_unavailable, maintenance, update_required, session_tab_shell
            └── widgets/                               blocking_scaffold.dart, session_providers.dart (SessionProvidersScope)
```

A small feature, `exams/`, shows the typical shape:
- `data/exam_repository.dart`: `watchPublished(studentKey)` uses `asyncMap` with a publication join.
- `presentation/managers/exams_cubit.dart` with `exams_state.dart`: sealed Loading/Loaded/Failed states.
- `screens/exams_page.dart`: `BlocProvider(create: … ..start())`, then `switch (state)` choosing LoadingView, ErrorView, EmptyView or a list.

Outside lib:
- `tool/`: the CI checks, `bump_build_number.sh` and `make_upload_key.sh`.
- `.github/workflows/`: `ci`, `release` and `bump-build-number`.
- `hosting/`: static privacy and delete-account pages.
- `store/`: Play listing art.
- `docs/`: the shared contract (identical to control's) and the Play listing.

## 3. Infrastructure

### State management
`flutter_bloc` ^9.1.1, 11 Cubits, no base class.
- States are **sealed class families**, not one class with `copyWith`. Screens `switch` over them exhaustively, which avoids control's `clearError` flag boilerplate.
- Scoping is the interesting part:
  - `SplashCubit`, `AccountsCubit` and `ThemeCubit` live for the app's lifetime (`lexa_app.dart` `initState`).
  - `SplashCubit` survives account switches because the router's refresh listener is bound to its stream. Its gate is swapped instead, through `rebind(gate)`.
  - `SessionCubit` and `NotificationsCubit` are built by `SessionProvidersScope`, which the router keys with `ValueKey(studentKey)`. Switching accounts therefore destroys and rebuilds all session state.
- Per-tab cubits are created inside each page's `BlocProvider`.
- One-shot events such as `AccountsState.ready` and `reauth` are consumed through `consumeReady()`/`consumeReauth()` after a `BlocListener` acts on them.

### DI
Manual. `AccountGraph.of(FirebaseScope scope, {cache})` (`lib/app/account_graph.dart`) constructs `AuthRepository`, `StaffRepository`, `StudentRepository`, `PlatformSettingsRepository`, the attendance, exams, homework and fees repositories, `SessionStarter`, `RegistrationRepository` and `SessionGate` for one FirebaseApp.

`LexaApp.build` exposes the active graph with `RepositoryProvider.value`, and swaps it with `setState` on account activation. A separate `_signInGraph` (the staging app) backs the login and registration flows.

`IdentityCache` is passed by constructor into `SessionProvidersScope`. A comment explains why: a dropped provider once crashed the app at runtime.

### Routing
`lib/core/routing/`, go_router ^17.5.0.
- `buildAppRouter(...)` is built once. `refreshListenable` is `GoRouterRefreshStream([splashCubit.stream, accountsCubit.stream])`.
- `redirect` calls `computeRedirect(splashState, matchedLocation, hasSavedAccounts:)` (`route_redirect.dart`). This is a pure function that switches over the sealed `SplashState`:
  - Checking → `/splash`.
  - Unavailable → `/gate-unavailable`.
  - Login → stay if the location is signed-out reachable (login, accounts, settings, `/register/*`); otherwise go to `/accounts` when accounts are saved, else `/login`.
  - Ready → leave splash and the gate screen only.
  - Every non-null decision is logged with a stack trace.
- `AppRoutes` holds both paths and names, plus predicates.
- Structure:
  - top-level splash, login, accounts, gate-unavailable and settings routes;
  - a `ShellRoute` that provides one `RegistrationCubit` across 5 wizard steps (`extra` carries the `Stage`);
  - a `ShellRoute` that renders `SessionProvidersScope` only when the state is `SplashReady`;
  - inside it, a `StatefulShellRoute.indexedStack` with 5 tabs (home, attendance, exams, homework, fees) under `SessionTabShell`, plus profile, notifications and teacher-contact routes.
- Version floor and maintenance are rendered by `SessionTabShell` from `SessionCubit.state.status`. They are deliberately kept out of the redirect, and the comment explains the reasoning.
- Builders are intentionally non-const so that `.tr()` re-resolves after a language change.

### Networking
Firebase only. The key rule: all services are bound to an explicit app.
- `lib/core/firebase/firebase_bootstrap.dart`:
  - `bootstrapFirebase()` initializes the default app.
  - `openNamedApp(name)` uses `Firebase.app` with an `initializeApp` fallback.
  - `bootstrapSignInApp()` opens the `lexa_signin` staging app.
  - `scopeFor(app)` builds a `FirebaseScope` (app, auth, firestore via `instanceFor`).
- `AccountScope` adds a uid.
- `tool/check_no_firebase_singletons.sh`, run in CI, fails the build on any `.instance` read outside bootstrap.
- No HTTP client and no interceptors.
- Token refresh: `AuthRepository.refreshIdToken()` calls `getIdToken(true)` on every account switch before trusting a saved session.
- Timeouts: every gateway call in `SessionGate` uses `.timeout(12s)`, and a timeout is treated as unanswered, producing `GateUnavailable` (a retry screen that keeps the session).
- Error mapping:
  - `AuthRepository._translate` maps only the codes the app branches on to `LexaFailure` subclasses and rethrows everything else unchanged.
  - `describeErrorMessage(error)` (`lib/core/error/error_messages.dart`) maps app failures first, then Auth and Firestore code tables, then `Socket`/`Timeout`. The fallback `errors.genericWithCode` carries the code.
  - The mapper never logs, because it runs from `build`. Callers log at the catch site through `logAppError`.
- Firestore joins:
  - `publishedDocsIn` chunks `whereIn` lookups at 30 and fails closed on soft-deleted or unpublished documents.
  - `combineLatest2` joins two listeners.

### Local storage
`shared_preferences` only, with an explicit comment that secure storage would advertise a guarantee the app does not make, since nothing secret is stored.
- `IdentityCache`: per-uid keys `lexa.identity.<uid>.*`, with migration from single-slot legacy keys.
- `PrefsSavedAccountStore`: `lexa.accounts.saved.v1`, a versioned JSON payload with at most 5 accounts. It throws `TooManySavedAccounts` instead of evicting, and decoding never throws.
- `PendingRegistrationStore`: crash recovery between Auth account creation and the Firestore write.
- `SeenNotificationStore`: composite `studentKey + type + itemKey`.
- `ThemeStore`.
- `SessionTrail`.

Each store calls `SharedPreferences.getInstance()` itself; there is no injected instance.

### Localization + RTL
- `easy_localization` with `assetLoader: CodegenLoader()`, so translations are compiled into Dart. Locales are `en` and `ar`, with **startLocale `ar`** (control starts in `en`) and fallback `en`.
- The JSON files have 388 lines each.
- Language switch: `features/settings/presentation/screens/settings_page.dart` uses a `SegmentedButton<Locale>`, and the route is reachable while signed out.
- `lib/core/ui/l10n_format.dart` holds the `xTr()` mappers (`attendanceStatusLabelTr`, `levelDisplayNameTr`, `gateMessageTr`, `notificationTitleTr`…). This is the same idea as control's file with a different naming convention (control uses a `trX()` prefix).
- Two key styles coexist: generated `LocaleKeys` (232 usages) and raw `'errors.x'.tr()` strings (79), mostly in `error_messages.dart` and `validators.dart`.
- RTL: 5 Directional usages against 2 left/right ones (gradients). All 15 `fromLTRB` calls are symmetric. LTR is forced for email, phone and the brand wordmark.
- Leftover English: `LexaFailure` messages (most are mapped by type, but the fallback branch shows the English `.message`), `GateUnavailable` copy, the password tooltip, and `date_display.dart`'s English month names (the `xTr()` variants exist in `l10n_format.dart`).

### Theming
- `lib/app/theme.dart` `buildLexaTheme(Brightness)`: M3 with an explicit scheme from `lib/core/theme/app_color_schemes.dart` (same values as control). The app bar is surface-coloured, not the fixed brand bar control uses.
- Component themes: card, filled/outlined buttons (`Size.fromHeight(52)`, full width), input, listTile, divider, navigationBar and chip.
- **No textTheme customisation.** Sizes are set inline through `context.fontSize(baseline)` (baseline + breakpoint bump) in about 97 `TextStyle(...)` calls.
- Brand colours come from `extension AppSemanticColors on ColorScheme`, getters that branch on brightness. This is simpler than a ThemeExtension but cannot be lerped or overridden.
- `lexaOverlayStyle(brightness)` is shared by the AppBar theme and the app-wide `AnnotatedRegion`.
- Dark mode is the default (`ThemeStore.fallback`), read before `runApp`.
- `test/ui/theme_contrast_test.dart` checks contrast.

### Responsive helpers
`lib/core/responsive/breakpoints.dart`:
- `Breakpoint {compact, medium, expanded}` at widths 600 and 905, roughly the M3 window classes.
- Per breakpoint: `fontBump` 0/1/2, `gutter` 16/24/32, `maxContentWidth` ∞/720/900.
- `context.breakpoint`, `context.fontSize(n)`, `context.gutter`, `context.pagePadding`, and the `ContentWidthLimit` widget.
- No screenutil.

### Text scaling
`MediaQuery.withClampedTextScaling(minScaleFactor: 1.0, maxScaleFactor: 1.3)` in `MaterialApp.router(builder:)` (`lib/app/lexa_app.dart`). This uses the framework API, which is cleaner than control's hand-rolled version. The constants `kMinTextScale` and `kMaxTextScale` live in `breakpoints.dart`.

### Env / flavors
No flavors and no dotenv. `bool.fromEnvironment('LEXA_TRACE', defaultValue: true)` toggles diagnostic tracing. Constants, including public hosting URLs, live in `AppBranding`. Release automation uses GitHub Actions (`ci.yml`, `release.yml`, `bump-build-number.yml`) and `tool/bump_build_number.sh`. A Play service-account key is used in CI (it lives as a CI secret; the local file is gitignored).

### Logging
`lib/core/error/error_log.dart` is pure Dart:
- `logAppError(error, stack, context:)` logs under `lexa.error`.
- `logAppEvent(message, context:)` logs under `lexa.session`.
- `logAppTrace` is the same, gated by `kSessionTracing`.

Each forwards to the optional global `sessionDiagnosticSink`. `SessionTrail.install()` sets the sink, buffers lines in memory, and chains async writes of the last 40 to prefs. `takePrevious()` replays the previous run at startup. `SplashCubit.onChange` logs every transition, with a stack trace on transitions into Login.

### Analytics / crash reporting
None.

### Push / notifications
No OS push and no local notifications. `NotificationsCubit` combines the attendance, exam, homework and fee streams through the shared `notification_engine.dart` into an in-app feed with an unseen count. Seen state persists in `SeenNotificationStore`. Items clear per tab or per item (`markTabOpened`, `markItemSeen`).

### IAP / payments
None. The fees ledger is read-only Firestore data.

### Permissions
None.

### Deep links
None.

## 4. Services catalog

| File | Purpose | Public methods / members | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/firebase/firebase_bootstrap.dart | Only Firebase entry point | `bootstrapFirebase()`, `openNamedApp(name)`, `bootstrapSignInApp()`, `scopeFor(app)`, `defaultFirebaseAppName`, `signInAppName` | firebase_core/auth, cloud_firestore, firebase_options | generic |
| lib/core/firebase/account_scope.dart | Services bound to one app / account | `FirebaseScope(app, auth, firestore).forUid(uid)`, `AccountScope.uid` | firebase | generic |
| lib/core/error/failures.dart | Base failure | `LexaFailure(message, retryable)`, `LexaUnavailable`, `isPermissionDenied(error)` | cloud_firestore, branding | generic-ish |
| lib/core/error/error_messages.dart | Error → copy | `describeErrorMessage(error)`; re-exports `logAppError` | easy_localization, firebase_auth, feature failure types | semi (couples core → features) |
| lib/core/error/error_log.dart | Diagnostics | `logAppError`, `logAppEvent`, `logAppTrace`, `sessionDiagnosticSink`, `kSessionTracing` | dart:developer | generic |
| lib/core/error/session_trail.dart | Persisted diagnostic trail | `SessionTrail.install()`, `takePrevious()`, `resetForTest()` | shared_preferences | generic |
| lib/core/data/combine_latest.dart | Stream join | `combineLatest2(a, b, combine)` | dart:async | generic |
| lib/core/data/publication_filter.dart | Published-definition join | `publishedDocsIn(db, collection, keys)`, `publishedKeysIn(...)` | cloud_firestore | app-specific (whereIn-30 chunking generic) |
| lib/core/models/*.dart | Shared contract | models, parsing, soft delete (`liveOnly`), notification engine | cloud_firestore | app-specific (firestore_parsing/soft_delete generic) |
| lib/core/responsive/breakpoints.dart | Breakpoints + scale | `Breakpoint.of`, `fontBump`, `gutter`, `maxContentWidth`, `isTablet`; `context.breakpoint/fontSize/gutter/pagePadding`; `kMin/kMaxTextScale`; `ContentWidthLimit` | widgets | generic |
| lib/core/routing/app_router.dart | GoRouter | `buildAppRouter({splashCubit, accountsCubit, cache, buildVersion, buildNumber})` | go_router, features | app-specific |
| lib/core/routing/app_routes.dart | Paths + names + predicates | `AppRoutes.*`, `isSignedOutReachable`, `mustLeaveWhenReady` | — | app-specific (pattern generic) |
| lib/core/routing/route_redirect.dart | Pure redirect | `computeRedirect(splash, location, hasSavedAccounts:)` | splash_state | app-specific (pattern generic) |
| lib/core/routing/go_router_refresh_stream.dart | Streams → Listenable | `GoRouterRefreshStream(List<Stream>)` | foundation | generic |
| lib/core/schedule/next_session.dart | Next class from a weekly schedule | `nextSessionFor(group, now)` → `UpcomingSession` | models | app-specific |
| lib/core/ui/l10n_format.dart | Domain → translated strings | `genderLabelTr`, `weekdayShortNameTr`, `formatDayMonthYearTr`, `levelDisplayNameTr`, `groupNameTr`, `scheduleLinesTr`, `notificationTitleTr`, `gateMessageTr`… | easy_localization | app-specific |
| lib/core/utils/academic_year.dart | Academic-year window | `academicYearWindow`, `isInAcademicYear`, `academicYearLabel` | models | app-specific |
| lib/core/utils/app_version.dart | Version compare | `parseVersion`, `compareVersions`, `isBelowVersion`, `compareReleases`, `isBelowRelease` (fail-closed) | — | generic |
| lib/core/utils/date_display.dart | English date strings | `monthFullName`, `formatDayMonthYear`, `formatWithWeekday`, `formatMonthYear`, `formatClock` | models | app-specific (stale) |
| lib/core/utils/platform_clock.dart | Zone-aware now | `PlatformClock(tz).now()`, `today()`, `ensureInitialised()` | timezone | generic |
| lib/core/utils/store_launcher.dart | Open URL externally | `launchStoreUrl(url)` | url_launcher | generic |
| lib/core/utils/validators.dart | Form validators | `validateRequired`, `validateFullName`, `validateEmail`, `validatePassword`, `validatePasswordConfirmation`, `validateStudentPhone`, `validateParentPhone` | easy_localization, egyptian_phone | generic-ish |
| lib/core/validation/egyptian_phone.dart | Phone rules | same as lexa-control (byte-identical) | — | generic (Egypt) |
| lib/features/auth/data/auth_repository.dart | Firebase Auth email/password | `currentUser/Uid/Email`, `authStateChanges`, `normaliseEmail`, `signIn`, `createAccount`, `sendPasswordReset`, `changeEmail` (verifyBeforeUpdateEmail + reauth), `changePassword`, `appName`, `tokenEmail()`, `refreshIdToken()`, `signOut`, `deleteCurrentUser` | firebase_auth | generic (email/password auth) |
| lib/features/accounts/data/firebase_app_registry.dart | Named-app lifecycle | `appNameFor(uid)`, `freshAppNameFor(uid)`, `open({uid, appName})`, `dispose(scope)` | firebase_bootstrap | generic (multi-account) |
| lib/features/accounts/data/saved_account_store.dart | Account roster | `SavedAccountStore` (`getAll`, `upsert`, `remove`, `touch`, `getActiveUid`, `setActiveUid`), `PrefsSavedAccountStore`, `TooManySavedAccounts` | shared_preferences | generic |
| lib/features/accounts/domain/account_manager.dart | Switch / restore / sign-in orchestration | `accounts()`, `canAdd`, `activeUid`, `restore(uid)`, `switchTo(uid)`, `completeSignIn`, `adoptLegacySession`, `signOutAccount`, `removeAccount`; sealed `AccountOutcome` | registry, store, AccountGraph | app-specific (pattern generic) |
| lib/features/session/domain/session_gate.dart | Launch gate | `SessionGateGateway` interface, `SessionGate.run()` | models | app-specific (pattern generic) |
| lib/features/session/domain/session_starter.dart | Establish session after sign-in | `establish(uid)`, `adopt(...)` | repos, cache | app-specific |
| lib/features/session/data/identity_cache.dart | Per-account identity | `read(uid)`, `write(identity)`, `clear(uid)` | shared_preferences | app-specific (per-uid keying + migration generic) |
| lib/features/session/data/{platform_settings,student,staff}_repository.dart | Gate reads | `load()/watch()`; `byKey/byAuthUid/reconcileEmail/watch`; `isStaffAccount` | cloud_firestore | app-specific |
| lib/features/registration/data/registration_repository.dart | Registration with resume + rollback | `submit(draft)` | auth, writer, pending store, starter | app-specific |
| lib/features/settings/data/theme_store.dart | ThemeMode persistence | `read()`, `write(mode)`, `fallback` | shared_preferences | generic |
| lib/features/notifications/data/seen_notification_store.dart | Seen set | `read()`, write helpers | shared_preferences | app-specific |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/widgets/buttons/app_filled_button.dart | Primary button with busy spinner | label, onPressed, busy | y |
| lib/core/widgets/inputs/app_text_field.dart | Labelled icon text field (readOnly lock, forceLtr) | controller, label, icon, validator, keyboardType, textInputAction, textCapitalization, autocorrect, autofillHints, enabled, readOnly, forceLtr, autovalidateMode, onChanged, focusNode | y |
| lib/core/widgets/inputs/app_password_field.dart | Password + toggle | controller, label, validator, textInputAction, autofillHints, onFieldSubmitted, enabled, autofocus, focusNode | y |
| lib/core/widgets/feedback/loading_view.dart | Spinner | — | y |
| lib/core/widgets/feedback/empty_view.dart | Empty state | icon, title, message | y |
| lib/core/widgets/feedback/error_view.dart | Error + retry (translated) | message, onRetry | y |
| lib/core/widgets/feedback/app_snackbar.dart | `AppSnackBar.show` | context, message, duration | y |
| lib/core/widgets/feedback/confirm_dialog.dart | `confirmDialog` → bool | context, title, message, confirmLabel, destructive | y |
| lib/core/widgets/layout/lexa_card.dart | Card + optional tap | child, padding, onTap | y |
| lib/core/widgets/layout/section_header.dart | Section label | label, trailing | y |
| lib/core/widgets/layout/detail_row.dart | Label/value row | label, value, icon, forceLtrValue | y |
| lib/core/widgets/layout/info_note.dart | Info strip | text, icon | y |
| lib/core/widgets/layout/status_chip.dart | Status chip + `StatusTone` | label, tone, icon | y |
| lib/core/widgets/layout/group_schedule.dart | Schedule lines | group, dense, color | n |
| lib/core/widgets/branding/lexa_wordmark.dart | Brand mark | height, showSlogan | n |
| lib/core/responsive/breakpoints.dart | `ContentWidthLimit` | child | y |
| lib/features/session/presentation/widgets/blocking_scaffold.dart | Undismissable blocker | icon, title, message, actions, footer | y |
| lib/features/session/presentation/screens/maintenance_page.dart / update_required_page.dart / gate_unavailable_page.dart / splash_page.dart | Blocking pages | message / storeUrl, requiredVersion / message, onRetry, onSignOut / — | y-ish |
| lib/features/session/presentation/widgets/session_providers.dart | `SessionProvidersScope` (per-session providers + SessionEnded listener) | allowed, buildVersion, buildNumber, cache, child | n (pattern y) |
| lib/features/session/presentation/screens/session_tab_shell.dart | Tab shell + platform gating | navigationShell | n |
| lib/features/registration/presentation/widgets/registration_scaffold.dart | Wizard scaffold + bottom bar | step, title, child, subtitle, bottomBar / label, onPressed, busy, note | y |
| lib/features/accounts/presentation/widgets/account_avatar.dart | Grapheme-initial avatar | account, diameter, dimmed | n |
| lib/features/accounts/presentation/widgets/account_tile.dart | Picker tiles | account, isActive, busy, onTap, onRemove / (AddAccountTile) | n |

No shimmer, network image, pagination list, base app bar or text-field variants beyond the two inputs.

## 6. Packages (pubspec.yaml)

- **State**: flutter_bloc ^9.1.1, equatable ^2.1.0
- **DI**: none
- **Routing**: go_router ^17.5.0
- **Backend**: firebase_core ^4.13.0, firebase_auth ^6.5.7, cloud_firestore ^6.8.0
- **Storage**: shared_preferences ^2.5.5
- **L10n**: easy_localization ^3.0.8
- **Utils**: characters ^1.4.1 (grapheme-safe initials), uuid ^4.6.0, package_info_plus ^10.2.1, url_launcher ^6.3.2, timezone ^0.11.1, cupertino_icons ^1.0.8
- **Dev**: flutter_test, flutter_lints ^6.0.0, flutter_launcher_icons ^0.14.4, bloc_test ^10.0.0, mocktail ^1.0.5, flutter_native_splash ^2.4.7

Compared with lexa-control, this app has no notifications, excel, share or file-dialog packages, no intl pin, and no fake_cloud_firestore/firebase_auth_mocks. Its tests rely on fakes behind interfaces such as `SessionGateGateway` and `SavedAccountStore`.

## 7. Quality notes

- **Null safety / modern Dart**: full. Sealed classes, exhaustive switches, records, `?element`, `withValues` (8, no `withOpacity`), `PopScope`, `MediaQuery.withClampedTextScaling`, `TextScaler.noScaling`. No deprecated APIs found.
- **Lints**: stock `flutter_lints` with 0 extra rules, but CI runs `flutter analyze --fatal-infos --fatal-warnings`.
- **Tests**: 27 files, focused on the risky state machines: the gate, account switching, identity cache, the route redirect, registration rollback and notifications. There are fewer widget tests than in control.
- **Architecture quality**: the multi-account, Firebase-scope design is the standout. It is unusually rigorous, enforced by a CI script and backed by comments. Domain logic sits behind narrow interfaces (`SessionGateGateway`), so it is testable without Firebase.
- **Smells**:
  - No text theme, so typography is inline everywhere.
  - Two translation-key styles.
  - Error mapping that pattern-matches English message text and parses an English sentence with a regex.
  - `core/error/error_messages.dart` depends on feature layers.
  - A stale English-only `date_display.dart`.
  - `StatusChip` uses a low-contrast alpha wash with a hex table.
  - `confirmDialog` destructive styling is only half done.
  - Diagnostic tracing is on by default ("PHASE 0", marked temporary).
  - Theme code is split between `lib/app/theme.dart` and `lib/core/theme/`.
  - Several screen files of 450–580 lines.
- **Identical vs diverged with lexa-control** (see lexa-control.md for the control side):
  - **Byte-identical**:
    - `lib/core/models/{attendance_model, exam_model, fee_model, fee_status, firestore_parsing, group_model, homework_model, notification_engine, platform_settings_model, session_dates, soft_delete, stage_level, student_model}.dart` are identical to control's `lib/core/domain/*` (enforced by `tool/check_shared_models.sh`).
    - `lib/core/validation/egyptian_phone.dart`, `analysis_options.yaml` and `docs/00_SHARED_CONTRACT.md` are identical.
  - **Same values, cosmetic diff**: `lib/core/theme/app_color_schemes.dart` differs only in comments and explicit type annotations.
  - **Diverged (independent implementations)**:
    - theme: control's `core/ui/theme.dart` (ThemeExtension, per-breakpoint textTheme) vs `app/theme.dart` (ColorScheme extension, no textTheme);
    - responsive: control at 600/1100 with a font table vs this app at 600/905 with a fontBump;
    - text scaling: control's hand-rolled 0.9–1.3 vs `withClampedTextScaling` 1.0–1.3;
    - error mapper: control's `messageForError` (logs, LocaleKeys, debug assert) vs `describeErrorMessage` (no logging, string keys);
    - failures: control's sealed Equatable `Failure` vs `LexaFailure` subclasses;
    - widgets: control's richer `AppPrimaryButton`/`AppTextField`/`StatusPill` vs `AppFilledButton`/`AppTextField`/`StatusChip`;
    - version compare: control's `platform_use_cases.dart` is fail-open, this app's `core/utils/app_version.dart` is fail-closed;
    - theme persistence: control's `ThemeCubit(prefs)` vs `ThemeStore` + `ThemeCubit`;
    - routing: both use a pure `computeRedirect` + refresh-listenable pattern, but over different state types;
    - l10n_format: `trX()` vs `xTr()` naming over the same idea;
    - `app_branding.dart`: different app names and URL constants.
  - For a template, take control's theme/responsive/widgets/use-case base and this app's Firebase scoping, refresh stream, app_version, error_log/SessionTrail and the `withClampedTextScaling` approach.

---
Secret-class files present (not opened): `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `android/key.properties`, `android/app/upload-keystore.jks`, `android/app/play-service-account.json`. `.gitignore` lists `key.properties`, the keystore and `play-service-account.json`. No secret values were found in Dart/shell/YAML source.
