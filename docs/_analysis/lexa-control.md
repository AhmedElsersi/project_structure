# lexa-control: analysis report

## Summary for comparison

```
PROJECT: lexa-control | path: My Apps/<client folder, redacted: contains a person's name>/lexa_control | stack: Flutter, Dart SDK ^3.11.5 (uses null-aware `?element` collection syntax) | last commit: 2026-09-08 (34 commits; 1 uncommitted change in dashboard_screen.dart) | source files: 153 (lib, excl. locale_keys.g.dart; ~29k LOC)
ARCH: clean-arch feature-first: features/<f>/{data (Firestore repositories), domain (use cases + pure helpers), presentation/{managers (cubit+state), screens, widgets}}. Shared core/ holds models (core/domain, byte-identical with lexa-student), session/RBAC, router, theme, error mapping, widgets
STATE: flutter_bloc Cubits only (15). No base cubit. Equatable state + copyWith(clearError/clearSaved flags); one-shot error/saved fields shown by a BlocConsumer listener and then cleared. Domain base classes in lib/core/usecase/use_case.dart: UseCase<P,R>, StaffUseCase / OwnerOnlyUseCase / DeveloperOnlyUseCase with a @nonVirtual call() that runs the role guard, then execute() (25 subclasses)
DI: none (manual constructor injection) — flutter_bloc MultiRepositoryProvider of ~20 repositories + BlocProvider.value(SessionCubit, ThemeCubit) in lib/main.dart; use-case bundles assembled inside route builders in lib/core/router/app_router.dart
ROUTING: go_router ^17.5.0 — lib/core/router/app_router.dart (+ app_routes.dart names-only constants) — guards: global redirect is a pure function computeRedirect(SessionStatus, location), re-run through a ChangeNotifier bridged from the SessionCubit stream; route-level OwnerGate/DeveloperGate widgets; ControlAppGate (version floor/maintenance) wraps the StatefulShellRoute.indexedStack (5 tabs); typed record `extra` args (GroupEditorArgs…) | deep links: local-notification payload -> pushNamed(attendance, query) held until the session resolves (lib/app.dart); no app_links
NETWORK: firebase (cloud_firestore + firebase_auth); no dio/http in lib (http only as a dev dep for tool/ REST scripts) — interceptors: none | token refresh: n (Firebase SDK) | retry: y (SessionCubit verification backoff 3/8/20/60s; StaffRepository.verify forces Source.server and falls back to cache only as "unreachable") | error mapping: repositories catch FirebaseException -> DataFailure(messageForError(...)); lib/core/error/error_messages.dart maps Failure / FirebaseAuthException / FirebaseException codes / SocketException / TimeoutException to LocaleKeys, the fallback always names the code, and a debug assert fires on non-platform errors
RESULT_TYPE: exceptions — sealed Failure extends Equatable implements Exception (NotAuthorisedFailure, ValidationFailure, AuthFailure, ProvisioningFailure, DataFailure) in lib/core/error/failures.dart
STORAGE: shared_preferences only (theme mode in lib/core/theme/theme_cubit.dart; reminder per-device mute in features/reminders/data/reminder_scheduler.dart) + the Firestore offline cache. No secure storage, no hive/sqflite
L10N: easy_localization ^3.0.8 + generated LocaleKeys (lib/core/l10n/locale_keys.g.dart; JSON loaded at runtime) — en, ar; start/fallback en; assets/translations/{en,ar}.json (783 lines each) — enum->string mappers in lib/core/ui/l10n_format.dart — hardcoded UI strings: some (no literal Text('...') in screens, but English copy inside Failure ctors, repository context strings, SessionState.message, field defaults 'Email'/'Password'/'Search'/'Try again', 'Show password' tooltip)
RTL: Directional=16 vs LeftRight=4 (all 4 are gradient Alignment.topLeft/bottomRight; the 6 EdgeInsets.fromLTRB calls all have left==right). Email/phone fields force LTR
THEME: lib/core/ui/theme.dart (AppTheme.light/dark(Breakpoint)) + lib/core/theme/app_color_schemes.dart (explicit M3 ColorSchemes, not seeded) — dark mode y (default dark, persisted ThemeMode) | component themes y (appBar, card, input, filled/outlined/text/segmented buttons, chip, divider, listTile, snackBar, dialog) | colors: ColorScheme + AppSemanticColors ThemeExtension (context.brandColors) + AppBranding consts | text styles: textTheme sized per breakpoint from AppFontSizes (lib/core/ui/responsive.dart) | fonts: platform default (no fontFamily)
RESPONSIVE: custom helper lib/core/ui/responsive.dart — breakpoints: phone <600, tablet >=600, wide >=1100 (width: MediaQuery.sizeOf for context.breakpoint, LayoutBuilder maxWidth for ResponsiveBuilder); discrete font table per breakpoint, AppSpacing scale + pagePadding(b), ContentBounds max widths 1200/560
TEXT_SCALING: ClampedTextScale in MaterialApp.router builder (lib/app.dart), clamp 0.9–1.3 (lib/core/ui/responsive.dart); StatTile/QuickAction compute heights from the TextScaler
ENV/FLAVORS: none — hardcoded constants (lib/core/branding/app_branding.dart), flutterfire firebase_options.dart; no dotenv, no --dart-define, no flavors
LOGGING: dart:developer log (name 'lexa.error', level 1000) + debugPrint in debug, only inside messageForError (lib/core/error/error_messages.dart)
ANALYTICS/CRASH: none
PUSH: flutter_local_notifications + timezone + flutter_timezone, local scheduled reminders only (no FCM) — lib/features/reminders/data/reminder_scheduler.dart (+ pure plan in features/reminders/domain/reminder_plan.dart)
PAYMENTS/IAP: none (fees are tracked as Firestore records, no payment SDK)
PERMISSIONS: no permission_handler — notification permission requested in context via flutter_local_notifications; flutter_file_dialog (SAF) avoids the storage permission
DEEP_LINKS: notification payload 'attendance:<groupId>:<dateKey>' + go_router paths; no app_links/uni_links
MEDIA/FILES: excel (real .xlsx roster export), path_provider, share_plus, flutter_file_dialog (lib/features/students/data/student_export_file.dart); Image.asset only, no network images
TESTS: 53 Dart test files (test/: core, domain, usecase, features, ui, tool, support) + 1 integration_test (student-code race, emulator) + a Node Firestore-rules suite (test/rules/rules.test.mjs, 112 it() cases, @firebase/rules-unit-testing on the emulator) — covers the session cubit, the router redirect, owner-only refusals, error mapping, phone validation, Arabic search, the soft-delete, reminder plan, promotion, fee board, theme contrast, RTL widget tests, CLI tools
LINTS: flutter_lints ^6.0.0 default include, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/usecase/use_case.dart — UseCase + role-guarded StaffUseCase/OwnerOnlyUseCase/DeveloperOnlyUseCase with @nonVirtual call() (a subclass cannot skip the guard) — quality 5 — coupling: low (SessionReader interface only)
- lib/core/error/error_messages.dart — one mapper from any thrown object to user copy: Failure, Auth/Firestore code tables, Socket/Timeout, a coded fallback, logging, isDuplicateEmail() — quality 5 — coupling: low (LocaleKeys + Failure; Firebase-specific tables)
- lib/core/ui/responsive.dart — Breakpoint enum + context ext, discrete AppFontSizes, AppSpacing, ClampedTextScale, ContentBounds, ResponsiveBuilder — quality 4 — coupling: none
- lib/core/ui/theme.dart — ThemeData builder per brightness+breakpoint, full component themes, ThemeExtension with lerp/copyWith, textTheme colour bound before sizing — quality 4 — coupling: low (AppBranding colours)
- lib/core/session/session_cubit.dart — auth+authorisation session: server-forced verify, offline "unverified" hold, retry backoff, live revocation listener that ignores cache snapshots, stale-verification token — quality 5 (pattern) — coupling: high (Staff model/repo)
- lib/core/router/app_router.dart (computeRedirect + _SessionRefreshListenable) — pure, unit-tested redirect with loop-free convergence — quality 4 — coupling: high (imports every feature; the pattern is what to keep)
- lib/core/auth/account_provisioner.dart — creates Firebase Auth users on a secondary FirebaseApp so the admin stays signed in; serialised, always signs out in finally — quality 5 — coupling: low (firebase_options)
- lib/core/error/failures.dart — sealed Failure hierarchy with typed reasons/codes — quality 4 — coupling: none (but English messages baked in)
- lib/core/theme/theme_cubit.dart — persisted ThemeMode cubit, sync loadInitial() before runApp (no flash) — quality 5 — coupling: none
- lib/core/ui/widgets/app_snack_bar.dart — ScaffoldMessengerState extension: showError/showInfo/showUndo with container/on-container pairs — quality 4 — coupling: none
- lib/core/text/search_text.dart — Arabic-aware search fold (hamza/alef/teh-marbuta/yeh folds, tashkeel/bidi drop, Arabic-Indic digits) + word-wise matchesSearch — quality 5 — coupling: low (toAsciiDigits from egyptian_phone)
- lib/core/validation/egyptian_phone.dart — pure-Dart normalise/validate (+20/0020, Arabic digits, typed error enum) — quality 5 — coupling: none (Egypt-specific)
- lib/core/domain/firestore_parsing.dart — tolerant Firestore readers (asString/asInt/asDateTime...) + date/month keys — quality 4 — coupling: low (cloud_firestore Timestamp)
- lib/core/domain/soft_delete.dart — soft-delete value + Query.liveOnly extension — quality 4 — coupling: low (Firestore)
- lib/core/session/staff_session.dart — StaffSession + SessionReader interface + requireOwner/requireDeveloper/requireStaff — quality 4 — coupling: low (role enum)
GENERIC_WIDGETS (every reusable widget):
- lib/core/widgets/buttons/app_primary_button.dart — primary FilledButton — label, onPressed, isLoading, icon, destructive, expand — quality 5 — generic? y
- lib/core/widgets/buttons/app_secondary_button.dart — outlined button — label, onPressed, icon, destructive, expand — quality 4 — generic? y
- lib/core/widgets/buttons/app_text_button.dart — text button — label, onPressed, icon, destructive — quality 4 — generic? y
- lib/core/widgets/buttons/app_icon_button.dart — IconButton with a required tooltip — icon, tooltip, onPressed, color — quality 4 — generic? y
- lib/core/widgets/inputs/app_text_field.dart — base TextFormField — label, hint, helperText, controller, focusNode, validator, onChanged, onFieldSubmitted, keyboardType, textInputAction, inputFormatters, maxLines, enabled, obscureText, autocorrect, autofillHints, textCapitalization, prefixIcon, suffixIcon, isDense, autofocus, enableSuggestions — quality 4 — generic? y
- lib/core/widgets/inputs/app_email_field.dart — forced-LTR email field + defaultValidator — controller, label, helperText, focusNode, validator, onFieldSubmitted, textInputAction, enabled, autofillHints — quality 3 (English default label/validator) — generic? y
- lib/core/widgets/inputs/app_password_field.dart — password field with visibility toggle — controller, label, focusNode, validator, helperText, onFieldSubmitted, textInputAction, autofillHints — quality 4 (English tooltip) — generic? y
- lib/core/widgets/inputs/app_phone_field.dart — forced-LTR phone field + EgyptianPhoneInputFormatter (normalises on paste, cap applied after normalising) — controller, label, helperText, focusNode, validator, textInputAction, enabled — quality 4 — generic? partly (Egypt rules)
- lib/core/widgets/inputs/app_search_field.dart — live search TextField — hint, helperText, controller, onChanged — quality 3 (no clear button) — generic? y
- lib/core/widgets/feedback/app_loading.dart — centred spinner — none — quality 3 — generic? y
- lib/core/widgets/feedback/app_empty_state.dart — empty placeholder — message, icon — quality 3 — generic? y
- lib/core/widgets/feedback/app_error_state.dart — error + retry — message, title, icon, onRetry, retryLabel — quality 4 — generic? y
- lib/core/widgets/layout/app_card.dart — themed Card wrapper — child, padding — quality 3 — generic? y
- lib/core/widgets/layout/app_section_header.dart — section title (Directional padding) — title — quality 3 — generic? y
- lib/core/widgets/selection/app_chip.dart — AppFilterChip<T> (popup single-choice: label, value, entries, onSelected, enabled), AppChoiceChip (label, selected, onSelected, enabled, tooltip), AppActionChip (label, onPressed, icon) — quality 4 — generic? y
- lib/core/widgets/selection/app_dropdown.dart — AppDropdown<T> over DropdownButtonFormField (initialValue API) — label, value, items, onChanged, validator, helperText, isExpanded, enabled — quality 4 — generic? y
- lib/core/widgets/selection/app_date_picker_field.dart — tap-to-pick date field — label, date, onDateSelected, firstDate, lastDate, helperText, helpText, trailing, dateFormatter, selectableDayPredicate — quality 4 — generic? y
- lib/core/widgets/selection/app_time_picker_field.dart — tap-to-pick time field — label, time, onTimeSelected, helpText, timeFormatter — quality 4 — generic? y
- lib/core/ui/widgets/confirmation_dialog.dart — showConfirmationDialog() — context, title, message, confirmLabel, cancelLabel, destructive, icon — quality 4 — generic? y
- lib/core/ui/widgets/typed_confirmation_dialog.dart — showTypedConfirmationDialog() type-the-word confirm for destructive actions — context, title, message, confirmationWord, confirmLabel, cancelLabel, extraContent — quality 4 (uses RichText) — generic? y
- lib/core/ui/widgets/status_pill.dart — StatusPill badge + StatTone container/on-container pairs — label, tone, icon — quality 5 — generic? y
- lib/core/ui/widgets/app_snack_bar.dart — snackbar extension (see above) — message / label+onPressed — quality 4 — generic? y
- lib/core/ui/widgets/owner_gate.dart, developer_gate.dart — route-level role gate with a refusal scaffold — child, title — quality 4 — generic? n (SessionCubit-bound; pattern y; the two files duplicate each other)
- lib/core/ui/responsive.dart — ContentBounds (child, maxWidth), ResponsiveBuilder (builder), ClampedTextScale (child) — quality 4 — generic? y
- lib/features/dashboard/presentation/widgets/dashboard_cards.dart — StatTile (label, value, icon, tone, caption, onTap; static heightFor), SectionHeader (title, subtitle, trailing), DashboardPanel (child, padded), QuickAction (icon, label, onTap; heightFor) — quality 4 — generic? y (lives in a feature)
- lib/features/shell/presentation/widgets/main_shell.dart — NavigationBar shell for StatefulNavigationShell, re-tap pops to root — navigationShell — quality 4 — generic? y (pattern; tabs enum app-specific)
- lib/features/shell/presentation/screens/{splash,unreachable,not_found}_screen.dart — branded splash / offline-retry / 404 — none — quality 3 — generic? partly
- lib/features/platform/presentation/widgets/control_app_gate.dart — version-floor/maintenance gate around the shell + _BlockingScreen — child — quality 3 (creates its stream inside build) — generic? n
- lib/features/groups/presentation/widgets/schedule_editor.dart — weekly slot editor — schedule, onChanged — quality 3 — generic? n
- lib/features/students/presentation/widgets/{student_list_tile,email_unconfirmed_chip}.dart, features/developer/presentation/widgets/* — app-specific tiles/sheets — generic? n
NOTABLE_IDEAS: @nonVirtual guarded use cases (lib/core/usecase/use_case.dart) = an RBAC layer that cannot be bypassed by a subclass; three-layer enforcement (route gate widget + use-case guard + Firestore rules with a Node rules-test suite, test/rules/); sealed "answer vs non-answer" lookup (StaffFound/StaffDenied/StaffUnreachable in lib/core/session/staff_repository.dart) so offline never signs a user out; pure computeRedirect + refreshListenable bridge, unit-tested (test/core/router/app_router_test.dart); secondary-FirebaseApp user provisioning (lib/core/auth/account_provisioner.dart); deep link held until the session resolves (lib/app.dart _AppLifecycle); AppLifecycleListener onResume re-verify; theme read synchronously before runApp; per-breakpoint discrete font table baked into ThemeData; StatTone container/on-container pairs + a theme contrast test (test/ui/theme_contrast_test.dart); typed-confirmation dialog; Arabic search fold; ScaffoldMessengerState snackbar extension; xlsx export instead of CSV for Arabic; deterministic 31-bit notification ids with schedule-then-cancel escalation (features/reminders/domain/reminder_plan.dart); test/support/translation_pump.dart (settleTranslations polls until easy_localization has loaded the locale); targeted dotted-path Firestore writes with id validation (lib/core/data/platform_repository.dart); shared-contract files kept byte-identical across two apps
SMELLS: two widget dirs (lib/core/widgets vs lib/core/ui/widgets); SectionHeader duplicated (dashboard_cards.dart vs core AppSectionHeader); OwnerGate/DeveloperGate near-duplicates; StreamBuilder(stream: repo.watch()) created inside build() in control_app_gate.dart, fee_config_screen.dart, platform_control_screen.dart, student_detail_screen.dart, staff_screen.dart (resubscribes on every rebuild, and bypasses cubits); English copy in the domain/data layers (Failure ctors, repository 'Could not load…' strings, StaffRepository 'Removed staff', SessionState.message, PlatformRepository._messageFor); compareVersions in features/platform/domain/platform_use_cases.dart treats an unparseable version as 0 (fail-open, unlike lexa-student's lib/core/utils/app_version.dart); ClampedTextScale wraps a redundant MediaQuery.withNoTextScaling; RichText in the typed dialog ignores the text scaler; hardcoded hex colours in features/students/presentation/widgets/email_unconfirmed_chip.dart; god files: students_screen.dart 869, student_editor_screen.dart 751, students_repository.dart 709, exam_marks_screen.dart 670, platform_settings_model.dart 841 lines; `collection` declared but unused in lib; zero extra lint rules; no crash reporting (the comment says so)
```

---

## 1. Architecture pattern

Feature-first clean architecture, applied consistently but pragmatically:

- **data/**: concrete Firestore repositories (no abstract repository interfaces, no data sources/DTO split). They take a `FirebaseFirestore` handle by constructor, parse via the model's `fromMap`/`fromSnapshot`, and translate `FirebaseException` into `DataFailure`.
- **domain/**: use cases (classes extending `StaffUseCase`/`OwnerOnlyUseCase`/`DeveloperOnlyUseCase` from `lib/core/usecase/use_case.dart`) plus pure helper functions and value types (for example `findGroupConflicts`, `ratesByStudent`, `summariseSessions` in `features/attendance/domain/attendance_use_cases.dart`). Use cases depend on `SessionReader` (an interface), not on the cubit.
- **presentation/**: `managers/` (Cubit + Equatable State), `screens/`, `widgets/`.
- **core/domain/**: the shared data contract. Models, the notification engine and the parsing helpers are **byte-identical** with lexa-student's `lib/core/models/` (lexa-student's `tool/check_shared_models.sh` enforces this).

Some features skip a layer. `auth` and `profile` have only presentation. `reminders` has data + domain only. `platform` has domain + presentation. A few screens read repositories directly through `StreamBuilder` and bypass a cubit.

Flow: Screen → Cubit (subscribes to repo streams, calls use cases) → UseCase (role guard → validation → repository) → Firestore. Errors are thrown `Failure`s, caught in the cubit (`on Failure catch`), and stored as `state.error` (String). A `BlocConsumer` listener shows them with `ScaffoldMessenger.showError` and then calls `cubit.clearError()`.

Security model: three layers. (1) A route-level widget gate: `OwnerGate`/`DeveloperGate` in `lib/core/ui/widgets/`. (2) The use-case guard: `@nonVirtual call()`. (3) `firestore.rules`, at the project root and 23 KB, tested by `test/rules/rules.test.mjs`.

## 2. Folder tree (lib/)

```
lib/
├── main.dart                 bootstrap: EasyLocalization, Firebase, SharedPreferences, SessionCubit, router, ThemeCubit, MultiRepositoryProvider (~20 repos)
├── app.dart                  LexaControlApp (MaterialApp.router, ResponsiveBuilder→theme per breakpoint, AnnotatedRegion, ClampedTextScale) + _AppLifecycle (session start, resume re-verify, reminders init, notification deep link)
├── firebase_options.dart     flutterfire output (secret-class file; not opened)
├── core/
│   ├── auth/                 account_provisioner.dart — secondary FirebaseApp user creation
│   ├── branding/             app_branding.dart — brand strings, palette, asset paths
│   ├── data/                 platform_repository.dart — Settings/platform doc (targeted dotted-path writes)
│   ├── domain/               shared contract models: attendance, exam, fee, fee_status, group, homework, platform_settings, session_dates, stage_level, staff, student, notification_engine, soft_delete, firestore_parsing
│   ├── error/                failures.dart (sealed Failure), error_messages.dart (messageForError)
│   ├── l10n/                 locale_keys.g.dart (generated)
│   ├── router/               app_router.dart (GoRouter + computeRedirect + typed extra args), app_routes.dart (route names)
│   ├── session/              session_cubit.dart, staff_repository.dart (StaffLookup sealed), staff_session.dart (SessionReader, require* guards)
│   ├── text/                 search_text.dart — Arabic search folding
│   ├── theme/                app_color_schemes.dart (explicit M3 schemes), theme_cubit.dart
│   ├── ui/                   theme.dart (AppTheme + AppSemanticColors), responsive.dart (breakpoints/fonts/spacing/text-scale), l10n_format.dart (enum→translated string)
│   │   └── widgets/          app_snack_bar, confirmation_dialog, typed_confirmation_dialog, status_pill, owner_gate, developer_gate
│   ├── usecase/              use_case.dart — UseCase + role-guarded bases
│   ├── validation/           egyptian_phone.dart (shared contract)
│   └── widgets/
│       ├── buttons/          app_primary/secondary/text/icon_button
│       ├── feedback/         app_loading, app_empty_state, app_error_state
│       ├── inputs/           app_text_field, app_email_field, app_password_field, app_phone_field, app_search_field
│       ├── layout/           app_card, app_section_header
│       └── selection/        app_chip, app_dropdown, app_date_picker_field, app_time_picker_field
└── features/
    ├── assessments/  attendance/  auth/  dashboard/  developer/  fees/  groups/
    ├── platform/  profile/  registration/  reminders/  shell/  staff/  students/
    └── attendance/                                   (representative, fully expanded)
        ├── data/attendance_repository.dart           forDate / saveRoster (chunked batch ≤400) / recordedDates / history (collectionGroup + liveOnly)
        ├── domain/attendance_use_cases.dart          SaveAttendance (StaffUseCase), GroupConflict, AttendanceRate, GroupSessionSummary
        └── presentation/
            ├── managers/attendance_cubit.dart        subscribes PlatformRepository.watch(), loads roster+existing, save() cancels reminders
            ├── managers/attendance_state.dart        Equatable state, copyWith(clearError, clearSaved), derived getters
            └── screens/attendance_screen.dart        BlocConsumer: snackbars from state.error/savedCount; selectors, banners, roster, save bar
```

Feature notes: `developer/` is a records console (soft-delete restore, audit log, diagnostics) behind DeveloperGate. `platform/` holds version/maintenance control and the `ControlAppGate`. `shell/` holds MainShell, splash, unreachable and not-found. `students/` holds the roster, editor, detail, stage browser, year promotion and the xlsx export.

Outside lib: `tool/` holds about 4.5k LOC of pure-Dart CLI scripts: seed, backfill and migration scripts, index checker, phone audit, a Firestore REST client and admin credentials. `test/rules/` is a Node rules suite. `integration_test/` holds an emulator race test. `docs/` holds the spec and the shared contract (identical to the student copy). `firestore.rules` and `firestore.indexes.json` sit at the root.

## 3. Infrastructure

### State management
- `flutter_bloc` ^9.1.1, Cubits only (15). No shared base cubit or status enum. Each state is a hand-written Equatable class with `copyWith` and `clearX` boolean flags for nullable resets.
- One-shot UI effects (errors, "saved N") are modelled as nullable state fields. A `BlocConsumer.listenWhen` shows them and the screen calls `clearError()`/`clearSaved()`. This works, but it is boilerplate in every cubit.
- Cubits subscribe to Firestore streams in the constructor and cancel in `close()`, guarding emits with `isClosed`.
- App-lifetime cubits (`SessionCubit`, `ThemeCubit`) are created in `main()` and provided with `BlocProvider.value`. Screen cubits are created inside the go_router route builders.
- Domain layer: `lib/core/usecase/use_case.dart`. `UseCase<P,R>.call` is the base. `StaffUseCase`, `OwnerOnlyUseCase` and `DeveloperOnlyUseCase` implement `call` as `@nonVirtual async { requireX(session.current); return execute(params); }`. Overriding `call` is therefore an analyzer error, so a subclass cannot skip the guard. `async` makes refusals surface as rejected Futures. There are 25 subclasses.

### DI
There is no container. `main.dart` builds `MultiRepositoryProvider` with about 20 `RepositoryProvider`s, either as `.value` or with `create: (_) => XRepository(firestore)`. Router builders assemble use-case bundles from `context.read`, for example the `_studentUseCases(context)` helper. Testability comes from constructor injection plus fakes (`fake_cloud_firestore`, `firebase_auth_mocks`, `mocktail`).

### Routing
`lib/core/router/app_router.dart`, go_router ^17.5.0.
- `buildAppRouter(sessionCubit)` is called once in `main()`, never inside `build`.
- `redirect` calls `computeRedirect(SessionStatus, matchedLocation)`. This is a pure function, and each status maps to exactly one stable location: unknown/checking → `/splash`, unreachable → `/unreachable`, signedOut → `/auth/*`, authorised → leaves splash, auth and unreachable for `/dashboard`. It is unit-tested for loop-freedom.
- `_SessionRefreshListenable` (a ChangeNotifier) listens to the cubit stream so that the redirect re-runs.
- `StatefulShellRoute.indexedStack` holds 5 branches (dashboard, students, learning, fees, profile). It is wrapped by `ControlAppGate` (the app's own version floor and maintenance mode) and `MainShell` (a NavigationBar; re-tapping a tab returns to its root).
- Full-screen pushes sit outside the shell. Object payloads are passed through `state.extra` as Dart record typedefs (`GroupEditorArgs`, `StudentEditorArgs`, …), cast with `state.extra! as X`.
- Route names live in `app_routes.dart` (`AppRoutes.dashboard` = 'dashboard'). Paths are declared only in the router, and call sites use `goNamed`/`pushNamed`.
- Role guards are applied at page level (`OwnerGate`/`DeveloperGate` wrap the page), so they still hold after a deep link or a live demotion.
- `errorBuilder` shows `NotFoundScreen`.
- The deep link comes from local notifications (`lib/app.dart`): `_openFromPayload` parses `attendance:<groupId>:<date>`. If the session is not yet authorised, it subscribes to the session stream and fires `pushNamed` only after `authorised`, or drops the link on `signedOut`.

### Networking
Firebase only: `cloud_firestore` ^6.8.0, `firebase_auth` ^6.5.7, `firebase_core` ^4.13.0. There is no HTTP client in `lib` and no interceptors.
- **Verification/retry**: `StaffRepository.verify(uid)` reads with `GetOptions(source: Source.server)`. `permission-denied` → `StaffDenied`. Any other error → `StaffUnreachable(cached)`, with a best-effort read from `Source.cache`. `SessionCubit` holds the session on "unreachable" and flags it as `unverified`. Retries back off at 3/8/20/60 s, and a `_verificationToken` discards stale results. A live `snapshots()` listener ignores `fromCache` deletions and signs out only on a server-backed revoke.
- **Error mapping**: `lib/core/error/error_messages.dart`, `messageForError(error, [stack, context])`. Order: `Failure.message` → `FirebaseAuthException` codes (matched before `FirebaseException`, its supertype) → Firestore codes → `SocketException` / `TimeoutException` → unknown. The fallback is `errors_unknown` with the code embedded. In debug, a non-platform error (TypeError and the like) throws a `StateError` through an `assert`, so programming bugs are not dressed up as friendly copy. Every call logs first. `isDuplicateEmail` matches on codes, never on message text.
- Repositories wrap errors: `throw DataFailure(messageForError(e, st, 'Could not load …'), code: e.code)`. The context prefix is English and not localized. Some repositories add special copy, such as `failed-precondition` → "needs an index; run firebase deploy".
- Batches are chunked at 400 operations (`saveRoster`), and `whereIn` lookups are chunked at 30 (`resolveNames`).

### Local storage
`shared_preferences` ^2.5.5 only:
- `ThemeCubit` (`lib/core/theme/theme_cubit.dart`, key `theme.mode`). `loadInitial(prefs)` is synchronous, so `main` passes the stored mode before `runApp`.
- `ReminderScheduler` keeps a per-device mute flag.

No secure storage. The Firestore offline cache is used intentionally.

### Localization + RTL
- `easy_localization` ^3.0.8 with locales `en` and `ar`. `startLocale` and `fallbackLocale` are both `en`, with `useFallbackTranslations: true`. The path is `assets/translations`, holding JSON files of 783 lines each. Generated keys are in `lib/core/l10n/locale_keys.g.dart`, with 764 LocaleKeys usages and 694 `.tr()` calls.
- The language switch is in `features/profile/presentation/screens/profile_screen.dart` (`context.setLocale`).
- `lib/core/ui/l10n_format.dart` is the bridge layer. Domain and shared-contract files must not import easy_localization, so every enum → string mapping (`trStageFull`, `trAttendanceStatus`, `trGroupName`, `trScheduleLines`, `trReminderTitle`…) lives here and is called only from widgets.
- RTL: 16 Directional usages against 4 left/right ones (all gradient alignments). Every `EdgeInsets.fromLTRB` call is symmetric. Email and phone fields wrap themselves in `Directionality(ltr)`. `test/ui/stage_browser_rtl_test.dart` covers RTL.
- Remaining English: messages inside `Failure` constructors (`NotAuthorisedFailure.ownerOnly()` etc.), `SessionState.message`, repository context strings, `ValidationFailure` texts in use cases, field defaults ('Email', 'Password', 'Search', 'Try again'), and the "Show/Hide password" tooltip.

### Theming
- `lib/core/theme/app_color_schemes.dart` defines explicit `ColorScheme` constants `kDreamDark` and `kDreamLight`, filling all M3 roles including the surfaceContainer* tiers. They are deliberately not seeded.
- `lib/core/ui/theme.dart`:
  - `AppTheme.light/dark(Breakpoint)` builds `ThemeData(useMaterial3)` with a `copyWith` of appBar (a fixed brand-ink bar with a gold title, plus `systemOverlayStyle`), card, inputDecoration, filled/outlined/text/segmented buttons, chip, divider, listTile, snackBar and dialog themes.
  - The textTheme is coloured first (`apply(bodyColor/displayColor)`) and then sized from the `AppFontSizes` table for the current breakpoint.
  - `AppSemanticColors extends ThemeExtension`, holding brand ink/gold/goldLight/marble and a gradient, with proper `copyWith` and `lerp`. It is read through `context.brandColors`. Light mode substitutes a darker gold for WCAG AA.
- `lib/app.dart` wraps MaterialApp in `ResponsiveBuilder` so that the ThemeData is rebuilt per breakpoint. A global `AnnotatedRegion<SystemUiOverlayStyle>` is resolved from the themeMode.
- Dark mode is the default (brand). The mode is persisted and can be switched from the profile screen.
- No custom fonts.
- `test/ui/theme_contrast_test.dart` checks contrast.

### Responsive helpers
`lib/core/ui/responsive.dart`:
- `Breakpoint {phone, tablet, wide}`; `Breakpoints.of(width)` at 600 and 1100.
- `context.breakpoint` uses `MediaQuery.sizeOf(this).width`. `ResponsiveBuilder` uses `LayoutBuilder` `constraints.maxWidth`.
- `AppFontSizes` holds discrete per-breakpoint sizes. The contract explicitly forbids proportional scaling.
- `AppSpacing` has xs 4 through xxl 32, `pagePadding(b)` of 16/24/32, `maxContentWidth` 1200 and `maxFormWidth` 560. `ContentBounds` centres and constrains content.
- No screenutil.

### Text scaling
`ClampedTextScale` is installed in `MaterialApp.router(builder:)`. It applies `MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3)`. The inner `MediaQuery.withNoTextScaling` wrapper is redundant, because the next MediaQuery overrides it. Dashboard tiles compute their height from the TextScaler (`StatTile.heightFor`, `QuickAction.heightFor`) instead of using a fixed aspect ratio.

### Env / flavors
None. Branding and asset paths are constants in `lib/core/branding/app_branding.dart`, and Firebase config is in `firebase_options.dart`. There is no `--dart-define`, no `.env` and no flavors. The CLI tools in `tool/` hardcode the project id and the client API key (see the final note).

### Logging
`dart:developer` `log(name: 'lexa.error', level: 1000)`, plus `debugPrint` in debug builds. Both run only inside `messageForError`. There is no logger package and no `print`.

### Analytics / crash reporting
None. The comment in `error_messages.dart` names `messageForError` as the single hook point if Crashlytics is ever added.

### Push / notifications
`lib/features/reminders/data/reminder_scheduler.dart` provides **local** scheduled reminders. There is no FCM and no backend, which keeps the project on the free tier.
- Uses `flutter_local_notifications` ^22.3.0, `timezone` and `flutter_timezone`.
- `initialise(onTap)` sets an Android drawable icon. iOS permission is not requested at init. `launchPayload()` covers cold starts.
- `requestPermission()` is per platform. `reschedule(settings)` cancels everything and rebuilds a rolling window from the pure `buildReminderPlan` (`features/reminders/domain/reminder_plan.dart`), within a platform budget (`ReminderBudget.ios`/`android`).
- `cancelEscalation` is called on attendance save ("schedule-then-cancel"). It uses `inexactAllowWhileIdle`, which avoids the SCHEDULE_EXACT_ALARM permission.
- Notification ids are deterministic 31-bit hashes.
- Titles and bodies are translated at schedule time through `l10n_format.dart`.
- Rescheduling runs on start and on resume (`lib/app.dart`).

### IAP / payments
None.

### Permissions
No `permission_handler`. Notification permission is requested in context, when reminders are enabled. File saving uses `flutter_file_dialog`, the system picker (SAF), so no storage permission is needed.

### Deep links
There are only the notification-payload deep links described under Routing, which go to `/attendance?groupId&date`. No `app_links`, `uni_links` or dynamic links.

## 4. Services catalog

| File | Purpose | Public methods / members | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/auth/account_provisioner.dart | Create Auth users without signing the admin out (secondary FirebaseApp `provisioner`) | `createAccount({email,password})→uid`, `sendPasswordReset(email)`, `appName` | firebase_core, firebase_auth, firebase_options, error_messages | generic (Firebase admin-style apps) |
| lib/core/branding/app_branding.dart | Brand strings, palette, asset paths | consts | flutter/widgets | app-specific |
| lib/core/data/platform_repository.dart | `Settings/platform` singleton doc | `watch()`, `fetch()`, `updateFields(map)`, `createGroup`, `renameGroup`, `setGroupActive`, `setGroupDefaultGender`, `setGroupSchedule`, `deleteGroup` | cloud_firestore, models, failures | app-specific (dotted-path writes plus path-segment validation are a reusable idea) |
| lib/core/domain/firestore_parsing.dart | Tolerant readers + date keys | `asString`, `asInt`, `asNum`, `asStringOrNull`, `asNumOrNull`, `asDateTime`, `formatDateKey`, `parseDateKey`, `formatMonthKey` | cloud_firestore (Timestamp) | generic |
| lib/core/domain/soft_delete.dart | Soft-delete value + query filter | `SoftDelete.fromMap/creating/removing/restoring`, `isDeleted`, `Query.liveOnly` | cloud_firestore | generic-ish |
| lib/core/domain/*_model.dart, notification_engine.dart, session_dates.dart, stage_level.dart, fee_status.dart | Shared data contract (students, groups, attendance, exams, homework, fees, platform settings, staff) | fromMap/toMap/copyWith, domain helpers | firestore_parsing | app-specific |
| lib/core/error/failures.dart | Sealed failure hierarchy | `Failure.message`; `NotAuthorisedFailure(.ownerOnly/.developerOnly/.notStaff/.revoked/.selfTarget)`, `ValidationFailure(field)`, `AuthFailure(code; isEmailAlreadyInUse…)`, `ProvisioningFailure(pendingUid)`, `DataFailure(code; isPermissionDenied)` | equatable | generic (English messages) |
| lib/core/error/error_messages.dart | Thrown object → localized copy + logging | `messageForError(error,[stack,context])`, `isDuplicateEmail(error)` | easy_localization, firebase_auth, LocaleKeys | generic (Firebase) |
| lib/core/router/app_router.dart | GoRouter + redirect | `buildAppRouter(cubit)`, `computeRedirect(status, location)`, `rootNavigatorKey`, Args typedefs | go_router, every feature | app-specific (pattern generic) |
| lib/core/router/app_routes.dart | Route name constants | `AppRoutes.*` | — | app-specific |
| lib/core/session/session_cubit.dart | Session/authorisation state machine | `start()`, `refresh()`, `signOut()`, `sendPasswordResetToSelf()`, `acknowledgeMessage()`; `SessionState` (status, staff, reason, unverified, isOwner, isDeveloper); `CubitSessionReader` | firebase_auth, StaffRepository | app-specific (pattern generic) |
| lib/core/session/staff_repository.dart | `Staff/{uid}` reads/writes | `watch(uid)→StaffReading`, `verify(uid)→StaffLookup`, `stampLastSignIn`, `listAll`, `watchAll`, `findByEmail`, `create`, `setActive`, `rename`, `resolveNames(uids)` | cloud_firestore | app-specific |
| lib/core/session/staff_session.dart | Acting user + guards | `StaffSession.fromModel`, `isOwner/isDeveloper/isAuthorised`; `SessionReader`, `StaticSessionReader`; `requireOwner/requireDeveloper/requireStaff` | equatable, failures | generic (RBAC) |
| lib/core/text/search_text.dart | Arabic-aware search | `foldForSearch(s)`, `matchesSearch(text, query)` | egyptian_phone (`toAsciiDigits`) | generic |
| lib/core/theme/app_color_schemes.dart | Explicit M3 schemes | `kDreamDark`, `kDreamLight` | material | app-specific values |
| lib/core/theme/theme_cubit.dart | Persisted ThemeMode | `ThemeCubit.loadInitial(prefs)`, `setThemeMode(mode)` | flutter_bloc, shared_preferences | generic |
| lib/core/ui/theme.dart | ThemeData factory + ThemeExtension | `AppTheme.light(b)`, `AppTheme.dark(b)`, `AppSemanticColors`, `context.brandColors` | responsive.dart, branding | generic structure |
| lib/core/ui/responsive.dart | Breakpoints, sizes, spacing, text scale | `Breakpoint`, `Breakpoints.of`, `context.breakpoint/isPhone/isTabletOrWider`, `AppFontSizes.*`, `AppSpacing.*`, `clampedTextScaler`, `ClampedTextScale`, `ContentBounds`, `ResponsiveBuilder` | material | generic |
| lib/core/ui/l10n_format.dart | Enum/domain → translated strings | `trStageFull`, `trLevelDisplayName`, `trAttendanceStatus`, `trGender`, `trStaffRole`, `trWeekdayShort/Full`, `trMonthShortName`, `trGroupName`, `trScheduleLines`, `trReminderTitle/Body`… | easy_localization, models | app-specific (pattern generic) |
| lib/core/usecase/use_case.dart | Use-case bases with role guards | `NoParams`, `UseCase.call`, `OwnerOnlyUseCase/DeveloperOnlyUseCase/StaffUseCase.execute` | meta, staff_session | generic |
| lib/core/validation/egyptian_phone.dart | Phone normalise/validate | `toAsciiDigits`, `normaliseEgyptianPhone(OrNull)`, `isValidEgyptianPhone`, `egyptianPhoneError(raw, required:)`, `EgyptianPhoneError` | — | generic (Egypt) |
| lib/features/reminders/data/reminder_scheduler.dart | Local notification scheduler | `initialise(onTap)`, `launchPayload()`, `isMutedOnThisDevice()`, `setMutedOnThisDevice`, `requestPermission()`, `reschedule(settings)`, `cancelEscalation`, `pending()`, `cancelAll()` | flutter_local_notifications, timezone, shared_preferences | app-specific (wrapper reusable) |
| lib/features/students/data/student_export_file.dart | .xlsx writer + share/save | `share(...)`, `write(...)`, save via system dialog | excel, share_plus, flutter_file_dialog, path_provider | reusable pattern |
| lib/features/platform/domain/platform_use_cases.dart | Version gate + platform control | `parseVersion`, `compareVersions`, `compareReleases`, `evaluateAppGate`, `AppGateVerdict`, `BumpSessionEpoch` (DeveloperOnlyUseCase) | models | semi-generic (version compare is fail-open) |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/widgets/buttons/app_primary_button.dart | Filled primary; built-in loading spinner coloured `onPrimary`/`onError`; destructive tint; full width | label, onPressed, isLoading, icon, destructive, expand | y |
| lib/core/widgets/buttons/app_secondary_button.dart | Outlined button | label, onPressed, icon, destructive, expand | y |
| lib/core/widgets/buttons/app_text_button.dart | Text button | label, onPressed, icon, destructive | y |
| lib/core/widgets/buttons/app_icon_button.dart | IconButton, required tooltip | icon, tooltip, onPressed, color | y |
| lib/core/widgets/inputs/app_text_field.dart | Base TextFormField; labels passed already translated | label, hint, helperText, controller, focusNode, validator, onChanged, onFieldSubmitted, keyboardType, textInputAction, inputFormatters, maxLines, enabled, obscureText, autocorrect, autofillHints, textCapitalization, prefixIcon, suffixIcon, isDense, autofocus, enableSuggestions | y |
| lib/core/widgets/inputs/app_email_field.dart | LTR email field + `defaultValidator` | controller, label, helperText, focusNode, validator, onFieldSubmitted, textInputAction, enabled, autofillHints | y (English defaults) |
| lib/core/widgets/inputs/app_password_field.dart | Password with show/hide | controller, label, focusNode, validator, helperText, onFieldSubmitted, textInputAction, autofillHints | y |
| lib/core/widgets/inputs/app_phone_field.dart | LTR phone + `EgyptianPhoneInputFormatter` | controller, label, helperText, focusNode, validator, textInputAction, enabled | partly |
| lib/core/widgets/inputs/app_search_field.dart | Search TextField | hint, helperText, controller, onChanged | y |
| lib/core/widgets/feedback/app_loading.dart | Centred spinner | — | y |
| lib/core/widgets/feedback/app_empty_state.dart | Empty placeholder | message, icon | y |
| lib/core/widgets/feedback/app_error_state.dart | Error + retry | message, title, icon, onRetry, retryLabel | y |
| lib/core/widgets/layout/app_card.dart | Themed Card | child, padding | y |
| lib/core/widgets/layout/app_section_header.dart | Section title | title | y |
| lib/core/widgets/selection/app_chip.dart | `AppFilterChip<T>`, `AppChoiceChip`, `AppActionChip` | (label, value, entries, onSelected, enabled) / (label, selected, onSelected, enabled, tooltip) / (label, onPressed, icon) | y |
| lib/core/widgets/selection/app_dropdown.dart | `AppDropdown<T>` | label, value, items, onChanged, validator, helperText, isExpanded, enabled | y |
| lib/core/widgets/selection/app_date_picker_field.dart | Date picker field | label, date, onDateSelected, firstDate, lastDate, helperText, helpText, trailing, dateFormatter, selectableDayPredicate | y |
| lib/core/widgets/selection/app_time_picker_field.dart | Time picker field | label, time, onTimeSelected, helpText, timeFormatter | y |
| lib/core/ui/widgets/app_snack_bar.dart | `ScaffoldMessengerState.showError/showInfo/showUndo` | (context, message) / (message) / (message, label, onPressed) | y |
| lib/core/ui/widgets/confirmation_dialog.dart | `showConfirmationDialog` → bool | context, title, message, confirmLabel, cancelLabel, destructive, icon | y |
| lib/core/ui/widgets/typed_confirmation_dialog.dart | `showTypedConfirmationDialog` → bool (type the word) | context, title, message, confirmationWord, confirmLabel, cancelLabel, extraContent | y |
| lib/core/ui/widgets/status_pill.dart | `StatusPill` + `StatTone` (contrast-safe pairs) | label, tone, icon | y |
| lib/core/ui/widgets/owner_gate.dart / developer_gate.dart | Route-level role gate | child, title | n (pattern y) |
| lib/core/ui/responsive.dart | `ContentBounds`, `ResponsiveBuilder`, `ClampedTextScale` | (child, maxWidth) / (builder) / (child) | y |
| lib/features/dashboard/presentation/widgets/dashboard_cards.dart | `StatTile` KPI, `SectionHeader`, `DashboardPanel`, `QuickAction` | (label, value, icon, tone, caption, onTap) / (title, subtitle, trailing) / (child, padded) / (icon, label, onTap) | y |
| lib/features/shell/presentation/widgets/main_shell.dart | Bottom-nav shell over StatefulNavigationShell | navigationShell | y (pattern) |
| lib/features/shell/presentation/screens/splash_screen.dart / unreachable_screen.dart / not_found_screen.dart | Branded splash, offline retry/sign-out, 404 | — | partly |
| lib/features/platform/presentation/widgets/control_app_gate.dart | Version/maintenance gate + `_BlockingScreen` | child | n |
| lib/features/groups/presentation/widgets/schedule_editor.dart | Weekly schedule slot editor + dialog | schedule, onChanged | n |
| lib/features/students/presentation/widgets/student_list_tile.dart | Roster tile | student, group, pastUnpaid, useCases, onReturn | n |
| lib/features/students/presentation/widgets/email_unconfirmed_chip.dart | Warning chip (hardcoded colours) | — | n |
| lib/features/developer/presentation/widgets/{audit_log_list,delete_impact_sheet,platform_diagnostics,record_actions,record_tile,scope_filter_bar}.dart | Developer console pieces (bottom sheet for removal reason) | various | n |

No shimmer, no network image wrapper, no paginated list and no base scaffold widget.

## 6. Packages (pubspec.yaml)

- **State**: flutter_bloc ^9.1.1, equatable ^2.1.0
- **DI**: none (flutter_bloc RepositoryProvider)
- **Routing**: go_router ^17.5.0
- **Backend/network**: firebase_core ^4.13.0, firebase_auth ^6.5.7, cloud_firestore ^6.8.0
- **Storage**: shared_preferences ^2.5.5
- **L10n**: easy_localization ^3.0.8, intl 0.20.2 (pinned exactly to match flutter_localizations)
- **Notifications**: flutter_local_notifications ^22.3.0, timezone ^0.11.1, flutter_timezone ^5.1.0
- **Files/media**: excel ^4.0.6, path_provider ^2.1.6, share_plus ^13.3.0, flutter_file_dialog ^3.0.3
- **Utils**: uuid ^4.6.0, package_info_plus ^10.2.1, collection ^1.19.1 (unused in lib), meta ^1.17.0 (for @nonVirtual), url_launcher ^6.3.2, cupertino_icons ^1.0.8
- **Dev**: flutter_test, integration_test, flutter_lints ^6.0.0, flutter_launcher_icons ^0.14.4, flutter_native_splash ^2.4.4, bloc_test ^10.0.0, mocktail ^1.0.5, fake_cloud_firestore ^4.0.0, firebase_auth_mocks ^0.15.1, http ^1.2.2 (tools), googleapis_auth ^2.0.0 (tools; deliberately dev-only)
- **Node (test/rules/package.json)**: @firebase/rules-unit-testing ^4.0.1, firebase ^11.0.0; runs with `firebase emulators:exec … "node --test rules.test.mjs"`

## 7. Quality notes

- **Null safety**: full (Dart ^3.11.5). Modern syntax throughout: sealed classes, switch expressions, pattern matching, records, null-aware collection elements `?x`, `withValues(alpha:)` (21 uses, 0 `withOpacity`), `DropdownButtonFormField.initialValue`, `PopScope`, `TextScaler`, `MediaQuery.sizeOf`. There are no deprecated APIs: `WillPopScope`, `MaterialStateProperty` and `textScaleFactor` do not appear.
- **Lints**: `analysis_options.yaml` is the stock template, `include: package:flutter_lints/flutter.yaml` with no extra rules. It is identical to lexa-student's.
- **Tests**: strong for a client app. There are 53 Dart test files:
  - unit tests on pure domain functions, the session cubit, the router redirect, owner-only refusals, the error mapper, phone and search logic, and the CLI tools;
  - widget tests for layout, RTL, controller disposal and theme contrast;
  - a `translation_pump.dart` helper.
  - Separately, there is a 1,183-line Node security-rules suite (112 cases) against the Firestore emulator and an integration test for the student-code race.
- **Documentation**: almost every class carries a long rationale comment that references a contract section (§). This is very high signal but also verbose, and the template should keep the "why" comments short.
- **Smells**:
  - Two widget directories.
  - Duplicated section headers and duplicated owner/developer gates.
  - `StreamBuilder(stream: repo.watch())` inside `build()` in five places.
  - English strings in the domain/data layer, so error copy is half-localized.
  - Large screen files (several over 600 lines).
  - A fail-open `compareVersions`.
  - A redundant `withNoTextScaling`.
  - `RichText` ignores the text scale.
  - Cubit state boilerplate (`copyWith` with clearX flags in every state).
  - No Crashlytics.
  - Uncommitted change in `dashboard_screen.dart`.
- **Duplication with lexa-student**: 13 model files plus `egyptian_phone.dart` and `docs/00_SHARED_CONTRACT.md` are byte-identical by design. `app_color_schemes.dart` has the same values with only comments differing. Everything else (theme, responsive, error mapper, widgets, routing) diverged independently (see lexa-student.md).

---
Secret-class files present (not opened): `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`. `.gitignore` covers keystores, `key.properties` and service-account JSON (`tool/keys/`). A Firebase client API key and the project id are hardcoded in `tool/firestore_rest.dart`, and the comment says it is a public client identifier.
