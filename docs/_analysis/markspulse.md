# markspulse — analysis report

## Summary for comparison

```
PROJECT: markspulse | path: My Apps/My Teacher Student App/markspulse | stack: Flutter 3.44.0 (CI pin), Dart ^3.12.0; functions/: Node 22 + TypeScript ^5.5, firebase-functions ^7.3.2, firebase-admin ^13.10 | last commit: 2026-10-24 | source files: 477 Dart in lib/ (+2 generated l10n), 27 TS in functions/src (+12 TS tests)
ARCH: clean-arch, layer-first with per-feature subfolders inside each layer — features/ (widgets) -> managers/ (Cubits) -> domain/ (pure use cases, models, repo interfaces, sealed Failure; no Flutter import, enforced by a test) -> data/ (Firestore/Functions/Storage repos); app/ = composition root (env, DI, router)
STATE: flutter_bloc Cubits + Equatable states; NO BaseCubit (each cubit hand-rolls try/catch -> FailureMessages.describe into state.message). Use-case ladder with @nonVirtual call() + protected execute(): UseCase / TenantUseCase / PermissionUseCase / AdminUseCase / StaffReadUseCase (lib/domain/usecases/*.dart, shared guards in guards.dart)
DI: none (no service locator, by design) — flutter_bloc MultiRepositoryProvider in lib/app/di/app_repositories.dart (lazy create:, test overrides); use cases assembled per route from context.read() in lib/app/router/app_router.dart
ROUTING: go_router ^18 — lib/app/router/app_router.dart (1814 lines) + routes.dart (path constants/builders) + redirect.dart (pure computeRedirect) + session_status_notifier.dart (refreshListenable) — guards? y (session-status redirect, role-shell bounce, RoleGate widget, per-route capability gates) | deep links? only internal go_router paths from notification taps (PendingDeepLink); no app_links/universal links
NETWORK: Firebase only (cloud_firestore w/ offline persistence, cloud_functions pinned to region, firebase_storage); no dio/http in app — interceptors: none | token refresh: n/a (Firebase Auth) | retry: y (session read backoff 3s/8s/20s/60s, pure: lib/domain/session/backoff.dart) | error mapping: FirebaseException + callable reason strings -> sealed Failure (lib/core/failures/failure_messages.dart asFailure, lib/data/functions/callable_refusal.dart) | files: lib/data/**, lib/data/firestore/{paths,live_only,pagination,firestore_decode}.dart
RESULT_TYPE: exceptions — use cases THROW a sealed `Failure implements Exception` (ValidationFailure/NotAuthorisedFailure/DataFailure/SubscriptionFailure/ProvisioningFailure; string code + cause + args/field) — lib/domain/failures/failure.dart; mapped centrally to one localized sentence in lib/core/failures/failure_messages.dart
STORAGE: shared_preferences — lib/core/settings/settings_store.dart (theme mode, selected child), lib/data/drafts/shared_prefs_draft_repository.dart (unsaved form drafts as JSON); Firestore offline cache (unlimited) in lib/main.dart; no secure storage
L10N: easy_localization ^3.0.8 + generated CodegenLoader/LocaleKeys (lib/core/l10n/*.g.dart) — ar, en; fallback/default ar; assets/i18n/{ar,en}.json (~1640 keys) — hardcoded UI strings: few (~2, language names)
RTL: Directional=239 vs LeftRight=6 (4 real: gradient begin/end Alignment.topLeft/bottomRight; 2 false positives: a translation string and a comment)
THEME: lib/core/theme/app_theme.dart — dark mode y (ThemeMode persisted, light/dark/system) | component themes in ThemeData y (appBar, navigationBar, tabBar, card, listTile, divider, bottomSheet, dialog, popupMenu, menu, snackBar, inputDecoration, filled/outlined/text/elevated/segmented buttons, FAB, chip, switch, checkbox, radio, progress, tooltip) | colors class: Palette (palette.dart) + StatusColors ThemeExtension (status_colors.dart) | text styles class: AppTypography (typography.dart) | fonts: Cairo variable font (local asset, explicit fontVariations wght)
RESPONSIVE: none (no screenutil, no breakpoints helper; 4 ad-hoc LayoutBuilders in feature pages) — breakpoints: none
TEXT_SCALING: none (no TextScaler clamp anywhere)
ENV/FLAVORS: flavors + --dart-define — Android productFlavors dev/prod (dev = applicationIdSuffix .dev, per-flavor google-services.json under src/<flavor>/); iOS configs Debug/Release/Profile-{dev,prod} + schemes dev/prod with MARKSPULSE_FLAVOR build setting and a "Copy Firebase plist for flavor" build phase that FAILS a flavorless build; Dart `AppEnvironment` enum from --dart-define=APP_ENV (default dev, unknown value throws) picks firebase_options_{dev,prod}.dart — lib/app/environment.dart, android/app/build.gradle.kts, ios/Runner.xcodeproj, .vscode/launch.json, .idea/runConfigurations/*.xml; functions: per-project .env.<project> read via defineString
LOGGING: none (zero print/debugPrint/logger in lib/)
ANALYTICS/CRASH: none
PUSH: FCM (data-only messages, rendered locally in the reader's language, incl. background isolate) + flutter_local_notifications (also on-device scheduled reminders with timezone/flutter_timezone) — lib/data/notifications/{push_receiver,fcm_token_registrar,local_reminder_scheduler}.dart, lib/main.dart (showPushInBackground), lib/managers/notifications/notification_binding.dart
PAYMENTS/IAP: in_app_purchase ^3.2.3 (iOS subscription only) behind SubscriptionStoreGateway — lib/data/iap/iap_subscription_store_gateway.dart; server-side receipt verification in functions/src/apple_subscriptions.ts (@apple/app-store-server-library); per-platform StorePolicy (lib/app/store_policy.dart)
PERMISSIONS: no permission_handler — notification permission via flutter_local_notifications/firebase_messaging (LocalReminderScheduler.hasPermission/requestPermission); image_picker gallery only
DEEP_LINKS: none external (no app_links/uni_links/dynamic links); notification-tap go_router paths held by PendingDeepLink until session resolves (lib/domain/notifications/{pending_deep_link,notification_route}.dart)
MEDIA/FILES: image_picker (logo), path_provider, share_plus, pdf, excel, archive, url_launcher; offscreen widget->PNG renderer (lib/core/render/widget_image.dart); no cached_network_image
TESTS: 239 test files in test/ (~2050 test/testWidgets cases) + 3 integration_test + 12 functions node:test files — domain/use cases incl. guard ladder (72), core incl. a test per core widget + l10n parity (46), feature widget tests (43), Firestore+Storage RULES via pure-Dart emulator REST harness (34), managers/cubits (22), data repos on fake_cloud_firestore (17), app/router redirect cross-product (5); integration: studentCode race on emulator, record browser, store-screenshot camera; hand-written fakes, no mockito/mocktail
LINTS: flutter_lints ^6.0.0 + analyzer strict-casts + strict-raw-types + `invalid_override_of_non_virtual_member: error` + 4 extra rules (always_declare_return_types, avoid_dynamic_calls, prefer_final_locals, unawaited_futures; prefer_initializing_formals disabled); CI runs `flutter analyze --fatal-infos --fatal-warnings`
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/domain/usecases/{use_case,tenant_use_case,permission_use_case,admin_use_case,staff_read_use_case,guards,params}.dart — guarded use-case ladder: @nonVirtual call() runs guard then protected execute(); guards are free functions (siblings, not a hierarchy); TenantScoped/GroupScoped param interfaces make an unguardable use case not compile — quality 5 — coupling: low (SessionReader/SessionSnapshot/Capability are app-shaped; the pattern is fully generic)
- lib/domain/failures/failure.dart — sealed `Failure implements Exception` (code, cause) + 5 subtypes (ValidationFailure has field+args; DataFailure has indexUrl; ProvisioningFailure has orphanUid) — quality 5 for the hierarchy (FailureCodes list is app-specific) — coupling: none (pure Dart + meta)
- lib/core/failures/failure_messages.dart — the ONE error->sentence mapper: asFailure (FirebaseException -> DataFailure, unavailable/permission-denied/missing-index URL extraction) + describe (code switch -> LocaleKeys.tr, typed fallback naming the code) — quality 4 — coupling: medium (easy_localization LocaleKeys, firebase_core; ~150-case string switch)
- lib/app/environment.dart — compile-time APP_ENV enum -> FirebaseOptions, safe default dev, StateError on unknown value — quality 5 — coupling: low (firebase_options files)
- .github/workflows/ci.yml + .github/workflows/release.yml + tool/bump_build_number.sh — CI gate (pinned Flutter, analyze fatal-infos, test) + merge-to-main release (bump +N, commit back, Play upload + App Store upload with manual signing on the runner) — quality 4 — coupling: medium (hardcoded bundle id, team id, pbxproj object id)
- lib/app/router/redirect.dart + lib/app/router/session_status_notifier.dart + lib/app/router/routes.dart — pure, context-free redirect over (status x role x location) with a "one hop settles" test; one ChangeNotifier that is both go_router refreshListenable and the domain SessionReader; route constants + path builders + isWithin() — quality 5 — coupling: low-medium (role/shell model)
- lib/domain/session/{session_machine,backoff,session_events,session_effects,session_snapshot,session_status}.dart + lib/data/session/session_controller.dart — auth session as a pure reducer (state, event) -> (state, effects); cache-sourced answers never sign out, unavailable holds and retries on backoff — quality 5 — coupling: medium (profile shape is app-specific)
- lib/data/firestore/pagination.dart + lib/domain/common/page.dart — fetchPage(query, limit, map) does limit+1 -> Page<T>(items, hasMore) — quality 4 — coupling: low (cloud_firestore)
- lib/data/firestore/live_only.dart + lib/domain/common/soft_delete.dart — `query.liveOnly` soft-delete extension + SoftDelete.liveFields()/deletedFields() — quality 4 — coupling: low
- lib/domain/common/parse.dart — defensive asString/asInt/asBool/asDateTime/asStringList/asMap/asMapList parsers for untyped maps — quality 4 — coupling: none
- lib/core/theme/{app_theme,palette,typography,app_radii,app_insets,app_motion,status_colors,contrast}.dart — full M3 ThemeData with ~25 component themes, token classes (radii, directional insets, motion that respects disableAnimations), StatusColors ThemeExtension, WCAG contrast picker — quality 5 — coupling: low (brand values only)
- test/rules/support/emulator.dart (+ fixtures.dart, storage_emulator.dart) — pure-Dart Firestore security-rules test harness over the emulator REST API (unsigned JWT per uid, per-suite project id, owner seed bypassing rules, get/list/query/collection-group/commit) — quality 5 — coupling: low
- test/domain/architecture_test.dart + test/core/l10n/translations_test.dart — static layering test (lib/domain may not import flutter/bloc/firebase/go_router/easy_localization/shared_prefs) + ar/en key, placeholder, plural and "every failure code has a sentence" parity — quality 5 — coupling: none
- lib/core/l10n/{l10n,counted,isolate_translations,reading_language,egyptian_material_localizations}.dart + lib/core/format/{app_format,input_formatters}.dart + lib/domain/format/digits.dart — locale config, plural helper, tr() in a background isolate, Western-digit + Saturday-first Material localizations, Western-digit formatters — quality 4 — coupling: low (easy_localization)
- lib/data/notifications/{push_receiver,fcm_token_registrar}.dart + lib/domain/notifications/pending_deep_link.dart — data-only FCM shown via local notifications, token attach/detach with APNs wait loop, cold-start tap held until session resolves — quality 4 — coupling: medium (payload model)
GENERIC_WIDGETS (every reusable widget):
- lib/core/widgets/layout/app_scaffold.dart — base scaffold — title, child, message (auto-SnackBar once per change, post-frame), busy (2px LinearProgressIndicator under AppBar), actions, floatingActionButton — quality 5 — generic? y
- lib/core/widgets/feedback/message_on_screen.dart — InheritedWidget contract so an error already rendered in the body is not also toasted — claims — quality 4 — generic? y
- lib/core/widgets/feedback/error_view.dart — error state (claims its message via MessageOnScreen) — message, centered — quality 4 — generic? y
- lib/core/widgets/feedback/empty_state.dart — empty state — message, centered, icon, action — quality 4 — generic? y
- lib/core/widgets/feedback/app_skeleton.dart — static card-shaped skeleton loader (no shimmer) — rows — quality 4 — generic? y
- lib/core/widgets/feedback/app_snackbar.dart — snackbar helper — show/showOn(messenger)/showUndo/showUndoOn (5s undo window, clears queue) — quality 4 — generic? y
- lib/core/widgets/feedback/confirm_sheet.dart — confirm + notice bottom sheets on root navigator — showConfirmSheet(title, confirmLabel, cancelLabel, body, destructive) / showNoticeSheet(title, body, okLabel) — quality 5 — generic? y
- lib/core/widgets/feedback/dirty_guard.dart — unsaved-changes PopScope guard + confirmDiscard() — dirty, thing, child, onDiscard — quality 5 — generic? y
- lib/core/widgets/feedback/form_sheet.dart — showFormSheet<T>(builder): keyboard-aware, scroll-controlled, root-navigator sheet — quality 4 — generic? y
- lib/core/widgets/feedback/notice_banner.dart — inline status banner — message, tone, icon, prominent, action, onDismiss, margin — quality 4 — generic? y
- lib/core/widgets/feedback/teacher_note_sheet.dart — teacher note sheet + TeacherNoteMark — quality 3 — generic? n
- lib/core/widgets/input/app_text_field.dart — text field — controller, label, hint, helper, suffixText, validator, keyboardType, textInputAction, onSubmitted, onChanged, focusNode, autofocus, enabled, obscure (show/hide toggle), maxLines, maxValue, dense, outlined, textAlign; validate-on-blur, Western-digit folding — quality 5 — generic? y
- lib/core/widgets/input/app_form.dart — Form wrapper (AppForm/AppFormState) that registers AppTextFields for submit-time validation — child — quality 4 — generic? y
- lib/core/widgets/input/app_dropdown.dart — dropdown<T> — value, items, onChanged, label, dense, expanded, errorText — quality 4 — generic? y
- lib/core/widgets/input/busy_button.dart — primary/outlined button with spinner that keeps its width + ButtonSpinner — busy, onPressed, child, variant, style — quality 5 — generic? y
- lib/core/widgets/input/date_field.dart — read-only date-picker field — label, value, firstDate, lastDate, onChanged, placeholder, icon, onClear — quality 4 — generic? y
- lib/core/widgets/input/form_sheet_body.dart — form-in-a-sheet frame with DirtyGuard, title, submit/cancel, inline error — formKey, title, thing, dirty, submitLabel, cancelLabel, onSubmit, children, busy, error — quality 4 — generic? y
- lib/core/widgets/input/note_sheet.dart — free-text note sheet with quick-pick chips + showNoteSheet — title, initial, picks(NotePick) — quality 3 — generic? y
- lib/core/widgets/input/location_fields.dart — Egypt governorate/city/area pickers — geo, governorate, city, area, onGovernorate, onCity, onAreaChanged, enabled — quality 3 — generic? n
- lib/core/widgets/layout/form_page.dart — full-page form frame + pushFormPage<T>() — formKey, title, thing, dirty, submitLabel, onSubmit, children, busy, error — quality 4 — generic? y
- lib/core/widgets/layout/action_footer.dart — sticky bottom action bar — action, secondary, caption — quality 4 — generic? y
- lib/core/widgets/layout/app_nav_bar.dart — NavigationBar wrapper — selectedIndex, onDestinationSelected, destinations — quality 3 — generic? y
- lib/core/widgets/layout/app_section.dart — titled section block — title, children, help, icon, trailing — quality 4 — generic? y
- lib/core/widgets/layout/record_header.dart — detail header with overline + facts row — title, overline, facts (RecordFact icon/text), trailing, margin — quality 4 — generic? y
- lib/core/widgets/cards/app_card.dart — hairline card with optional leading-edge accent stripe — child, padding, margin, onTap, accent — quality 4 — generic? y
- lib/core/widgets/cards/nav_tile.dart — navigation list tile with chevron — title, onTap, icon, subtitle, trailing, contentPadding — quality 4 — generic? y
- lib/core/widgets/data/paged_list_view.dart — pagination list with "load more" button row + stagger — itemCount, itemBuilder, hasMore, loadingMore, onLoadMore, loadMoreLabel, header, separated, padding — quality 4 — generic? y
- lib/core/widgets/data/person_row.dart — person row (avatar, name, code tag, subtitle, footer) — name, code, subtitle, subtitleColor, trailing, leading, footer, onTap, semanticsLabel, margin — quality 4 — generic? y
- lib/core/widgets/data/initials_avatar.dart — initials avatar + initialsOf() (Arabic-aware) — name, radius, background, foreground, presence — quality 4 — generic? y
- lib/core/widgets/data/stat_tile.dart — KPI tile (+ row variant ctor) — label, value (int?, null = unavailable), onTap, suffix, unavailableLabel, hint, icon, tone — quality 4 — generic? y
- lib/core/widgets/data/status_chip.dart — status pill (+ neutral ctor) — label, tone, icon, showDot, dense, animated, minWidth — quality 4 — generic? y
- lib/core/widgets/data/display_code.dart — large tabular code display (copyable) — code, onTap, semanticsLabel, color — quality 3 — generic? y
- lib/core/widgets/motion/staggered_list.dart — StaggerScope + StaggeredItem list entrance (max 8 items, reduced-motion aware) — child, stateKey / index, child, arriving — quality 4 — generic? y
- lib/core/widgets/motion/state_switcher.dart — AnimatedSwitcher keyed on state (loading/data/empty/error) — stateKey, child — quality 4 — generic? y
- lib/core/widgets/settings/language_choice.dart — ar/en SegmentedButton bound to easy_localization — onSaved — quality 3 — generic? y
- lib/core/branding/pulse_mark.dart, lib/core/branding/animated_pulse_mark.dart — painted logo + animated splash mark — quality 4 — generic? n
NOTABLE_IDEAS: (1) @nonVirtual call()/protected execute() use-case bases + analyzer `invalid_override_of_non_virtual_member: error` so a guard cannot be bypassed (lib/domain/usecases/, analysis_options.yaml); (2) param marker interfaces TenantScoped/GroupScoped so the type system forces every privileged use case to name its tenant/scope (lib/domain/usecases/params.dart); (3) sealed Failure + single central mapper with typed fallback that names the unmapped code (lib/domain/failures/failure.dart, lib/core/failures/failure_messages.dart) + test "every failure code has a sentence" (test/core/l10n/translations_test.dart); (4) callable refusal = transport code + reason string, mapped per-callable to Failure (lib/data/functions/callable_refusal.dart); (5) compile-time env enum that throws on unknown APP_ENV + iOS build phase that fails flavorless builds (lib/app/environment.dart, ios/Runner.xcodeproj "Copy Firebase plist for flavor"); committed IDE run configs carrying --flavor + APP_ENV (.vscode/launch.json, .idea/runConfigurations/); (6) pure session reducer with effects + backoff ladder (lib/domain/session/session_machine.dart); (7) pure go_router redirect tested over the full status x role x location cross product (lib/app/router/redirect.dart, test/app/router/redirect_test.dart); (8) architecture test enforcing a pure domain (test/domain/architecture_test.dart); (9) pure-Dart rules-test harness on the emulator REST API, skip-with-reason when no emulator (test/rules/support/emulator.dart); (10) AppScaffold + MessageOnScreen contract: a refusal on state is always shown, never twice (lib/core/widgets/layout/app_scaffold.dart); (11) DirtyGuard + drafts repo for unsaved forms (lib/core/widgets/feedback/dirty_guard.dart, lib/data/drafts/); (12) AppMotion.scaled() returns Duration.zero under disableAnimations (lib/core/theme/app_motion.dart); (13) MaterialApp keyed by locale so easy_localization language switch applies in place (lib/app/app.dart); (14) EgyptianMaterialLocalizations: Western digits + Saturday week start (lib/core/l10n/egyptian_material_localizations.dart); (15) tr() inside FCM background isolate (lib/core/l10n/isolate_translations.dart); (16) merge-to-main release workflow with build-number bump committed back + concurrency queue (.github/workflows/release.yml, tool/bump_build_number.sh); (17) tool/check_indexes.dart: replays every query shape with limit 1 against a real project to catch missing composite indexes; tool/support/firestore_rest.dart for service-account REST scripts; (18) store screenshots taken by an integration test (integration_test/store_screenshots_test.dart); (19) Functions split into pure *_logic/*_rules/*_format.ts modules tested with node:test, and app.ts holding the single initializeApp + setGlobalOptions(region) (functions/src/app.ts); (20) docs-driven agent workflow: CLAUDE.md + docs/00_CONTEXT.md + docs/phases/phase-NN-*.md + docs/PROGRESS.md (also seeded in scaffold/)
SMELLS: app_router.dart is a 1814-line god composition root that `new`s every use case per route, repeating FixedSessionReader(session.session) dozens of times; no BaseCubit — ~40 cubits repeat the same try/on Object catch/emit(message: FailureMessages.describe(e)) block and store a localized String in state; FailureMessages.asFailure is documented as "repositories call this" but no repository does — raw FirebaseException reaches cubits and is normalized only in describe() (doc/code drift); describe() is a ~150-case string switch, not compile-time exhaustive (only the type fallback is sealed); FailureCodes is a 100+ constant god list; guard functions are `async` with nothing awaited; very large pages/cubits (fee_board_page.dart 650 lines, guardian_home_cubit.dart 514); hardcoded bundle id / Apple team id / pbxproj object id in release.yml and a default ASC key id in tool/asc/asc.py; signing material sits in the working tree (gitignored, never committed per git log): root AuthKey_*.p8, dist.p12, play-service-account.json, *.mobileprovision, android/app/upload-keystore.jks; functions/.env.<project> files are tracked (Firebase defineString params, not opened); CI runs neither rules tests, integration tests nor functions `npm test` (documented gap); no crash reporting, no logging, no text-scale clamp, no responsive helper; 5.6 MB firestore-debug.log at root (gitignored); comments are long phase-history narratives (great context, heavy for a template); level-key logic mirrored between Dart and TS. Deprecated APIs: none found (0 WillPopScope / withOpacity / MaterialStateProperty / textScaleFactor; uses PopScope, withValues, WidgetStateProperty)
```

---

## 1. Architecture pattern

**Clean architecture, layer-first, with feature subfolders inside every layer.** CLAUDE.md
states it as: Presentation (widgets) → Managers (Cubits) → Domain (use cases, pure) → Data
(repositories own every query). The layering is real and enforced:

| Layer | Folder | Holds | Depends on |
|---|---|---|---|
| Composition root | `lib/app/` | `environment.dart` (APP_ENV), `di/app_repositories.dart` (MultiRepositoryProvider), `router/` (go_router + use-case assembly), `gates/role_gate.dart`, `store_policy.dart`, `app.dart` | everything |
| Presentation | `lib/features/<feature>/` | pages, sheets, feature-local widgets | managers, core widgets, domain models |
| Managers | `lib/managers/<feature>/` | Cubits + Equatable states; notification coordinators | domain use cases, `core/failures` |
| Domain | `lib/domain/` | models, repository **interfaces** (`domain/repositories/`), use cases (`domain/usecases/<feature>/`), sealed `Failure`, session machine, pure business logic (fees, schedule, search, export) | pure Dart + `meta` + `equatable` only |
| Data | `lib/data/<feature>/` | `Firestore*Repository`, `Functions*Gateway`, `Storage*Repository`, FCM/local notifications, IAP, drafts | domain interfaces, Firebase SDKs |
| Core | `lib/core/` | theme, widgets, l10n, failure mapper, formatting, settings store | Flutter, easy_localization |

`test/domain/architecture_test.dart` fails the build if any file under `lib/domain` imports
`package:flutter/`, `flutter_bloc`, `bloc`, `cloud_firestore`, `firebase_*`, `go_router`,
`easy_localization` or `shared_preferences`. Domain reads the viewer through
`SessionReader` (an interface), never through a Cubit.

**No service locator.** Repositories are provided once at the root (`AppRepositories`,
lazy `create:` callbacks so tests that never open a screen never touch
`FirebaseFirestore.instance`). Route builders in `app_router.dart` assemble use cases from
`context.read<Repo>()` and hand them to the Cubit constructor.

**Privilege ladder.** Every privileged use case extends one of four guarded bases whose
`call()` is `@nonVirtual`; subclasses implement `execute()`. `analysis_options.yaml` promotes
`invalid_override_of_non_virtual_member` to an error so a subclass cannot override the door.
Counts: 25 `TenantUseCase`, 27 `PermissionUseCase`, 44 `AdminUseCase`, 6
`StaffReadUseCase`, 25 plain `UseCase`, plus 1 hand-guarded owner use case
(`domain/usecases/tenant/activate_apple_subscription.dart`). The guards are explicitly UX:
`firestore.rules` is the security boundary, and the guards exist to produce a precise
sentence instead of a raw `permission-denied`.

**How a feature is organized (fees, end to end):**

```
lib/features/fees/fee_board_page.dart              # UI (650 lines)
lib/managers/fees/fee_board_cubit.dart             # FeeBoardCubit + FeeBoardState (phase enum, message)
lib/domain/usecases/fees/fee_usecases.dart         # ViewFeeBoard / RecordFeePayment / CorrectFee (PermissionUseCase)
lib/domain/usecases/fees/fees_params.dart          # FeeBoardParams etc. implement TenantScoped
lib/domain/fees/{fee_board,fee_month,fee_amount}.dart   # pure computation (academic month order, unpaid cells)
lib/domain/repositories/fees_repository.dart       # interface
lib/data/fees/firestore_fees_repository.dart       # Firestore impl (whereIn chunking at 30, liveOnly)
lib/app/router/app_router.dart  (~L1268)           # BlocProvider<FeeBoardCubit>(create: ... ViewFeeBoard(FixedSessionReader(...), context.read<FeesRepository>(), ...))
test/domain/usecases/fees/*, test/domain/fees/*, test/rules/fee_visibility_test.dart
```

A use case, shortened (`lib/domain/usecases/fees/fee_usecases.dart`):

```dart
class RecordFeePayment extends PermissionUseCase<void, RecordPaymentParams> {
  RecordFeePayment(SessionReader session, this._fees, this._enrollments, this._teachers)
      : super(session, Capability.collectFees);
  ...
  @override
  Future<void> execute(RecordPaymentParams params) async {
    if (params.month < 1 || params.month > 12) {
      throw const ValidationFailure(FailureCodes.feeMonthInvalid, field: 'month');
    }
    ...
  }
}
```

---

## 2. Folder tree (`lib/`, 4 levels)

```
lib/
├── main.dart                         # bootstrap: EasyLocalization, Firebase.initializeApp(AppEnvironment.current), Firestore persistence, SettingsStore, SessionController, router, notifications, FCM background handler
├── firebase_options_dev.dart         # (exists, not opened) per-env FirebaseOptions
├── firebase_options_prod.dart        # (exists, not opened)
├── app/                              # composition root
│   ├── app.dart                      # MarksPulseApp: AppRepositories + MultiBlocProvider(Settings, Auth) + MaterialApp.router keyed by locale
│   ├── environment.dart              # AppEnvironment enum from --dart-define=APP_ENV
│   ├── store_policy.dart             # per-platform store rules (iOS sells IAP, Android not)
│   ├── di/app_repositories.dart      # MultiRepositoryProvider of ~45 repositories/gateways
│   ├── gates/role_gate.dart          # RoleGate widget (renders refusal if role mismatch)
│   └── router/
│       ├── app_router.dart           # buildRouter(): every GoRoute + use-case/Cubit assembly (1814 lines)
│       ├── redirect.dart             # pure computeRedirect(session, location)
│       ├── routes.dart               # Routes: path constants, path builders, shells, isWithin()
│       └── session_status_notifier.dart  # ChangeNotifier + SessionReader
├── core/                             # shared, mostly generic
│   ├── branding/                     # pulse_mark.dart (painted logo), animated_pulse_mark.dart
│   ├── contact/contact_launcher.dart # tel:/WhatsApp launcher behind an interface
│   ├── failures/failure_messages.dart# Failure -> sentence (the only one)
│   ├── format/                       # app_format.dart (numbers/dates in Western digits), input_formatters.dart
│   ├── l10n/                         # l10n.dart, counted.dart, egyptian_material_localizations.dart, isolate_translations.dart, reading_language.dart, group_names.dart, level_names.dart, codegen_loader.g.dart, locale_keys.g.dart
│   ├── render/widget_image.dart      # renderWidgetToPng (offscreen)
│   ├── settings/settings_store.dart  # SharedPreferences wrapper
│   ├── theme/                        # app_theme, palette, typography, app_insets, app_radii, app_motion, status_colors, contrast, theme_set, tenant_brand, teacher_theme_scope
│   └── widgets/
│       ├── cards/                    # app_card, nav_tile
│       ├── data/                     # display_code, initials_avatar, paged_list_view, person_row, stat_tile, status_chip
│       ├── feedback/                 # app_skeleton, app_snackbar, confirm_sheet, dirty_guard, empty_state, error_view, form_sheet, message_on_screen, notice_banner, teacher_note_sheet
│       ├── input/                    # app_dropdown, app_form, app_text_field, busy_button, date_field, form_sheet_body, location_fields, note_sheet
│       ├── layout/                   # action_footer, app_nav_bar, app_scaffold, app_section, form_page, record_header
│       ├── motion/                   # staggered_list, state_switcher
│       └── settings/                 # language_choice
├── managers/                         # Cubits (≈45 files) + auth_cubit.dart, settings_cubit.dart
│   ├── account/ admin/(12) attendance/ enrollment/(3) family/(2) fees/ guardian/(4)
│   ├── marks/(2) notices/ notifications/(3: announcements_cubit, notification_binding, reminder_coordinator)
│   └── roster/(3) teacher/(6) tenant/
├── domain/                           # pure Dart
│   ├── failures/failure.dart         # sealed Failure + FailureCodes
│   ├── usecases/                     # use_case, tenant_use_case, permission_use_case, admin_use_case, staff_read_use_case, guards, params
│   │   └── account/ admin/(25) archive/ attendance/(3) catalog/ enrollment/(7) family/(5) fees/(2) guardian/ marks/(3) notifications/ roster/(7) teacher/(23) tenant/(2)
│   ├── repositories/(41)             # repository + gateway interfaces
│   ├── session/(9)                   # session_machine (reducer), backoff, events, effects, snapshot, status, profile, session_reader, fixed_session_reader
│   ├── model/(23) + model/records/(6)# entities with fromMap/toMap, enums, record keys
│   ├── permissions/capability.dart   # 15 delegable capabilities, fail-closed parse
│   ├── common/                       # page.dart, parse.dart, soft_delete.dart
│   ├── format/digits.dart            # toWesternDigits
│   ├── search/                       # arabic_folding.dart, roster_search.dart
│   ├── notifications/                # payload, route, pending_deep_link, reminder_plan, reminder_scheduler (interface), device_tokens
│   ├── time/wall_clock.dart          # WallClock interface
│   └── admin/ attendance/ auth/ dashboard/ discovery/ export/ family/ fees/ geo/ level/ marks/ phone/ schedule/ students/ subscriptions/ teacher/   # pure domain logic per area
├── data/
│   ├── firestore/                    # paths.dart (collection names + path builders), live_only.dart, pagination.dart, firestore_decode.dart
│   ├── functions/callable_refusal.dart  # callable error -> Failure
│   ├── session/                      # session_controller.dart, profile_gateway.dart, firestore_profile_gateway.dart
│   ├── auth/                         # auth_gateway (interface), firebase_auth_gateway, registration_repository, account_provisioner
│   ├── notifications/                # push_receiver, fcm_token_registrar, local_reminder_scheduler, firestore_announcements_repository
│   ├── iap/                          # iap_subscription_store_gateway, functions_apple_activation_gateway
│   ├── export/                       # xlsx_writer, pdf_writer, export_share, archive source/repo, purge gateway
│   ├── drafts/shared_prefs_draft_repository.dart
│   ├── time/tz_wall_clock.dart  geo/geo_repository.dart
│   └── account/ admin/(12) attendance/ dashboard/ enrollment/(4) family/ fees/ guardian/(3) marks/ notices/ roster/(3) teacher/(3)   # Firestore*/Functions*/Storage* implementations
└── features/                         # pages per area
    ├── account/ admin/(16) attendance/ auth/(4) discover/(3) export/(2) family/(5) fees/ guardian/(4)
    ├── marks/(6) notices/ notifications/(2) roster/(3 + student_hub/6) shells/(3) splash/ teacher/(14) unreachable/
```

Other top-level folders: `functions/` (Cloud Functions, TS), `tool/` (Dart/sh/py ops scripts),
`test/`, `integration_test/`, `docs/` (00_CONTEXT, BRAND, PROGRESS, 64 phase docs, store
listing docs), `scaffold/` (a seed copy of the CLAUDE/docs workflow), `store/` (listing
assets + HTML sources), `web_site/` (hosted account/delete-account pages), `marketing/`,
`firestore.rules` (1389 lines), `storage.rules`, `firestore.indexes.json`, `firebase.json`
(emulators: firestore 8080, storage 9199, auth 9099).

---

## 3. Infrastructure

### 3.1 State management
- **flutter_bloc ^9.1.1 Cubits** + `equatable`. States are `final class XState extends
  Equatable` with a `phase` enum (`pickLevel/loading/loaded/error`), `message` (already
  localized sentence), `saving` flag and `copyWith` (with explicit `clearX` booleans for
  nullable resets). Example: `lib/managers/fees/fee_board_cubit.dart`.
- **No BaseCubit / handleRequest.** Every async method repeats:
  ```dart
  try { ...; emit(state.copyWith(phase: X.loaded, ...)); }
  on Object catch (error) {
    emit(state.copyWith(phase: X.error, message: FailureMessages.describe(error)));
  }
  ```
  39 files call `FailureMessages.describe`. A template should add a mixin/base that does this.
- Root blocs: `SettingsCubit` (theme mode + theme-set preview, `lib/managers/settings_cubit.dart`),
  `AuthCubit` (`lib/managers/auth_cubit.dart`). Feature cubits are created per route in
  `app_router.dart` and call `..load()` immediately.
- Session state is **not** a Cubit: `SessionController` (`lib/data/session/session_controller.dart`)
  runs the pure reducer `reduce(state, event)` (`lib/domain/session/session_machine.dart`) and
  pushes snapshots into `SessionStatusNotifier`, which is both go_router's
  `refreshListenable` and the domain `SessionReader`.
- Quality: 4. Clean and testable (22 cubit tests), but boilerplate-heavy and a localized
  string in state means a locale change would show stale text if the cubit survived (it
  does not, because `MaterialApp.router` is keyed by locale).

### 3.2 Dependency injection
- **None by design** (no get_it/injectable/riverpod). `lib/app/di/app_repositories.dart` is a
  `MultiRepositoryProvider` with ~45 `RepositoryProvider<Interface>(create: (_) => Impl(_db()))`.
  `_db()`, `_storage()`, `_functions()` resolve lazily with constructor overrides for tests;
  `FirebaseFunctions.instanceFor(region: functionsRegion)` is pinned (comment records a
  production bug where every callable hit `us-central1` and 404'd).
- Use cases are constructed in route builders with `context.read()`. Pro: explicit, compile-
  checked, test-friendly. Con: `app_router.dart` becomes an 1814-line wiring file.
- Quality: 4 for the provider file; 2 for the router-as-composition-root.

### 3.3 Routing
- **go_router ^18.0.1**, `buildRouter(session:, onRetrySession:, onSignOut:)` in
  `lib/app/router/app_router.dart`; `refreshListenable` = `SessionStatusNotifier`.
- `lib/app/router/routes.dart`: `abstract final class Routes` — every path as a const, path
  builders (`adminTeacherDetail(id)`), `shells` list, `homeFor(role)`, `isWithin(location,
  prefix)` (boundary-aware prefix match), query param names. "String literals never appear
  in a go call."
- `lib/app/router/redirect.dart`: `computeRedirect(SessionSnapshot, String location,
  {bool teacherSignUp})` — pure, no BuildContext. Rules: unknown → splash; signedOut → /auth
  subtree; unreachable → /unreachable (never sign-in); signedIn → home of role, bounce out
  of other roles' shells, keep deep links inside own shell. "Every branch returns null for
  the locations it is satisfied by" (prevents redirect ping-pong). Tested over the full cross
  product in `test/app/router/redirect_test.dart`.
- Guards: redirect (session/role), `RoleGate` widget (`lib/app/gates/role_gate.dart`, renders
  the refusal sentence rather than a frame of wrong data), `_teacherRoute(...)` helper for
  capability-gated teacher routes, StatefulShell-like role shells in `lib/features/shells/`.
- Deep links: no external links. Notification taps produce go_router paths
  (`lib/domain/notifications/notification_route.dart`), held in `PendingDeepLink` until the
  session resolves (cold start), then delivered at most once, only if signed in.
- Quality: 5 for redirect/routes; 2 for the god builder file.

### 3.4 Networking
- No HTTP client in the app (http/googleapis_auth are dev deps used by `tool/` only).
- Backend = Firebase: `cloud_firestore ^6.9.0` (offline persistence, unlimited cache set in
  `main.dart`), `cloud_functions ^6.4.0` callables (region-pinned), `firebase_storage
  ^13.5.0` (logo, archives).
- Firestore helpers (`lib/data/firestore/`):
  - `paths.dart` — `abstract final class Paths`: collection names + path builders (52 statics).
  - `live_only.dart` — `extension LiveOnly on Query<T> { Query<T> get liveOnly => where('deletedAt', isNull: true); }`
  - `pagination.dart` — `fetchPage<T>(query, limit:, map:)` does `limit + 1` → `Page<T>(items, hasMore)`.
  - `firestore_decode.dart` — `decodeFirestoreValue` (Timestamp → DateTime, recursive), `decodeSnapshot`.
- Callables: `lib/data/functions/callable_refusal.dart` — `transportRefusal(code)` maps
  gRPC code (`permission-denied/unauthenticated` → NotAuthorised, `unavailable/deadline-
  exceeded` → DataFailure unavailable, else `functions.<code>`), plus per-callable
  `purgeRefusal / promotionRefusal / childLoginRefusal` that read the Function's reason
  string (`countChanged:<found>:<expected>` carries args). Each `Functions*Gateway` catches
  `FirebaseFunctionsException` and throws these.
- Retry: only for the session read — `lib/domain/session/backoff.dart`
  (`sessionBackoff = [3s, 8s, 20s, 60s]`, `backoffFor(attempt)`, no jitter by design).
- Error mapping: Firestore repositories do **not** wrap errors; raw `FirebaseException`
  bubbles to the cubit and is normalized in `FailureMessages.describe` → `asFailure`.
- Conventions (from CLAUDE.md, visible in code): bulk writes chunk at 400; `whereIn`
  chunked at 30 (`firestore_fees_repository.dart`); counts via aggregate `count()`.
- Quality: 4.

### 3.5 Result type / failures
- **Exceptions, not Either.** `lib/domain/failures/failure.dart`:
  ```dart
  @immutable
  sealed class Failure implements Exception {
    const Failure(this.code, {this.cause});
    final String code;      // stable machine id, e.g. 'phone.invalid'; never shown
    final Object? cause;
    @override
    String toString() => '$runtimeType($code)${cause == null ? '' : ' <- $cause'}';
  }
  final class ValidationFailure extends Failure { /* field, args */ }
  final class NotAuthorisedFailure extends Failure { ... }
  final class DataFailure extends Failure { /* indexUrl */ }
  final class SubscriptionFailure extends Failure { ... }
  final class ProvisioningFailure extends Failure { /* orphanUid */ }
  ```
  `FailureCodes` is an `abstract final class` of ~110 string constants grouped by phase.
- `lib/core/failures/failure_messages.dart` — `FailureMessages.asFailure(Object)` (Failure
  passthrough; FirebaseException → DataFailure with `unavailable` / `permissionDenied` /
  `indexMissing` + extracted console URL; anything else → `data.unexpected`) and
  `FailureMessages.describe(Object)` (switch on `code` → `LocaleKeys.failure_*.tr()`, with
  `namedArgs` for args and `counted()` for plurals; then a sealed switch by type as a
  fallback that names the unmapped code so it is still actionable).
- Guards return `Future<Failure?>`; base classes `throw refusal`.
- Tests: `test/core/failures/failure_messages_test.dart` (mapping incl. index URL
  extraction and "every refusal a Function can throw has a sentence");
  `test/core/l10n/translations_test.dart` ("every failure code the app can raise has a
  sentence").
- Template verdict: keep the sealed hierarchy + single mapper + "no sentence = test fails"
  idea; consider making codes an enum (or per-type sealed codes) so the mapper switch is
  exhaustive, and make the data layer actually call `asFailure`.

### 3.6 Local storage
- `shared_preferences ^2.5.5` only.
  - `lib/core/settings/settings_store.dart` — `SettingsStore.load()` (read before `runApp`
    to avoid a theme flash), `themeMode` get/set, `selectedChild(uid)`/`setSelectedChild`.
  - `lib/data/drafts/shared_prefs_draft_repository.dart` implements
    `domain/repositories/draft_repository.dart` (Attendance/Marks/Homework drafts with
    `toJson/fromJson`, keyed per tenant; validates the draft's tenant on read).
- easy_localization persists `locale` itself.
- No secure storage (Firebase Auth persists its own session).
- Quality: 4.

### 3.7 Localization + RTL
- `easy_localization ^3.0.8` with generated `CodegenLoader` + `LocaleKeys`
  (`lib/core/l10n/*.g.dart`). `lib/core/l10n/l10n.dart`: `supported = [ar, en]`, `fallback =
  ar` (product is for Egypt), `path = 'assets/i18n'`, `ignorePluralRules = false` (so Arabic
  plural forms are actually selected), `other(locale)` toggle.
- ~1640 keys per file (ar has more leaves due to plural forms). ~1540 `.tr()` calls in lib;
  only ~2 hardcoded strings (language names in `language_choice.dart`).
- Helpers: `counted(key, count)` (plural + Western-digit number),
  `EgyptianMaterialLocalizations` (Material strings with Western digits and Saturday week
  start, registered before the stock delegate), `loadIsolateTranslations()` (makes `tr()`
  work in the FCM background isolate via easy_localization internals —
  `implementation_imports` ignored), `ReadingLanguage` (global current locale for code
  outside the tree), `level_names.dart` / `group_names.dart` (domain-key → label).
- `MaterialApp.router` is keyed by `context.locale` so a switch applies in place.
- RTL: 239 directional usages vs 4 real left/right (decorative gradients). `AppInsets` is
  all `EdgeInsetsDirectional.fromSTEB`; widgets default margins to
  `EdgeInsetsDirectional.only(...)`; `AppCard.accent` is drawn on the leading edge. Widget
  tests run in both locales via `test/support/localized.dart` (`pumpLocalized`,
  `bothLocales`, `directionOf`).
- Western digits everywhere: `lib/domain/format/digits.dart` `toWesternDigits`,
  `AppFormat` (`lib/core/format/app_format.dart`), `WesternDigitsFormatter` on inputs.
- Arabic search folding: `lib/domain/search/arabic_folding.dart` (`foldArabic`,
  `matchesName`).
- Quality: 5.

### 3.8 Theming
- `lib/core/theme/app_theme.dart` — `AppTheme.platformTheme(brightness)` and
  `AppTheme.teacherTheme(ThemeSet, brightness)` both go through `_build(seed, primary,
  brightness)`: `ColorScheme.fromSeed(...).copyWith(...)` pinning primary/onPrimary and the
  whole surface ladder; `surfaceTint = surface` kills M3 elevation tint; elevation 0 + 1px
  hairline borders everywhere; ~25 component themes (see summary); `extensions:
  [StatusColors]`; `minimumTouchTarget = 44`.
- Tokens: `Palette` (light/dark ladders: paper/raised/inset/high/hairline, night/...,
  `pulseFor(brightness)` etc.), `AppTypography` (Cairo variable font, explicit
  `FontVariation('wght', ...)`, tabular figures for metrics, `screenTitle/sectionHeading/
  body/label/caption/metric/displayCode`), `AppRadii` (control 8, input 10, card 16,
  cardInner 12, sheet 16, pill), `AppInsets` (page, pageWithFab, sheet), `AppMotion` (fast
  120ms, base 220ms, slow 340ms, `scaled(context, d)` → zero when animations disabled,
  stagger step/limit), `StatusColors` (`ThemeExtension`, `StatusTone` positive/caution/
  negative/neutral, `of(context)`, `colorFor(tone)`), `contrast.dart`
  (`relativeLuminance`, `contrastRatio`, `foregroundOn`).
- Per-tenant theming: `ThemeSet` enum (10 sets), `TenantBrand` (ValueNotifier of the
  signed-in teacher's set), `TeacherThemeScope`/`TenantThemed` nest a `Theme` inside the
  teacher section only (platform screens stay on the brand theme).
- Dark mode: yes; `ThemeMode` persisted via `SettingsStore`.
- Uses current APIs (`withValues(alpha:)`, `WidgetStateProperty`, `CardThemeData`,
  `InputDecorationThemeData`).
- Tests: `test/core/theme/theme_test.dart`, `tenant_brand_test.dart`.
- Quality: 5. Best-in-class token setup for a template (swap values, keep structure).

### 3.9 Responsive helpers
- None. No screenutil, no breakpoint helper; 4 `LayoutBuilder`s in feature pages
  (roster, student overview, admin home, today) for ad-hoc column switching.

### 3.10 Text scaling
- None. No `TextScaler` clamp in `MaterialApp.builder` or elsewhere.

### 3.11 Env / flavors
- **Dart side** — `lib/app/environment.dart`:
  ```dart
  enum AppEnvironment {
    dev('dev'), prod('prod');
    const AppEnvironment(this.id);
    final String id;
    static const String _fromDefine = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    static AppEnvironment get current => switch (_fromDefine) {
      'prod' => AppEnvironment.prod,
      'dev' => AppEnvironment.dev,
      _ => throw StateError('APP_ENV was "$_fromDefine". It must be exactly "dev" or "prod"'),
    };
    bool get isProd => this == AppEnvironment.prod;
    FirebaseOptions get firebaseOptions => switch (this) {
      AppEnvironment.dev => DevFirebaseOptions.currentPlatform,
      AppEnvironment.prod => ProdFirebaseOptions.currentPlatform,
    };
  }
  ```
  Default `dev` deliberately (a missing define reads the wrong project rather than writing
  to prod). Used in `main()` and the FCM background handler.
- **Android** — `android/app/build.gradle.kts`: `flavorDimensions += "environment"`,
  `dev { applicationIdSuffix = ".dev" }`, `prod {}`; per-flavor `google-services.json`
  under `android/app/src/{dev,prod}/` (tracked deliberately); signing from optional
  `android/key.properties` (falls back to debug key when absent so a fresh checkout and
  CI non-release jobs still build); core library desugaring for notifications.
- **iOS** — build configurations `Debug-dev/Release-dev/Profile-dev/Debug-prod/
  Release-prod/Profile-prod`, schemes `dev` and `prod`, user-defined `MARKSPULSE_FLAVOR`
  setting; `ios/Runner/Firebase/{dev,prod}/GoogleService-Info.plist` copied by a "Copy
  Firebase plist for flavor" run-script phase that exits 1 when the flavor is unset
  (a flavorless iOS build fails rather than guessing).
- **IDE** — `.vscode/launch.json` and `.idea/runConfigurations/MarksPulse_{dev,prod}.xml`
  are committed (`.gitignore` excludes `.idea/*` except run configurations) and carry
  `--flavor X --dart-define=APP_ENV=X`.
- **Functions** — `functions/.env.<project-id>` per Firebase project (tracked; not opened)
  consumed via `defineString("APPLE_BUNDLE_ID")` etc. in `functions/src/apple_subscriptions.ts`.
- Quality: 5. Strong template candidate; replace the project-specific variable name
  (`MARKSPULSE_FLAVOR`) with a generic one.

### 3.12 Logging
- None. No `print`, `debugPrint`, `dart:developer log`, logger or talker in `lib/`.

### 3.13 Analytics / crash reporting
- None (no firebase_analytics, crashlytics, sentry; no `FlutterError.onError` /
  `PlatformDispatcher.onError` / `runZonedGuarded`). A template should add this.

### 3.14 Push notifications
- `firebase_messaging ^16.6.0` + `flutter_local_notifications ^22.3.0` + `timezone`
  + `flutter_timezone`.
- Pushes are **data-only** (Functions send no `notification` block on Android); the app
  renders title/body from a typed `NotificationPayload` in the reader's language:
  - foreground: `PushReceiver` (`lib/data/notifications/push_receiver.dart`) — creates the
    Android channel, listens `onMessage` → `plugin.show`, `onMessageOpenedApp` and
    `getInitialMessage` → `onTap(route)`.
  - background/terminated: top-level `@pragma('vm:entry-point') showPushInBackground` in
    `lib/main.dart` — `Firebase.initializeApp`, `loadIsolateTranslations()`, render, show.
- Tokens: `FcmTokenRegistrar` (`lib/data/notifications/fcm_token_registrar.dart`) implements
  domain `DeviceTokens.attach(uid)/detach()`; waits up to 10 s for the APNs token on iOS;
  writes `arrayUnion`/`arrayRemove` on the account doc; listens to `onTokenRefresh`.
- Local scheduled reminders: `LocalReminderScheduler`
  (`lib/data/notifications/local_reminder_scheduler.dart`) implements
  `domain/notifications/reminder_scheduler.dart` (`initialize`, `hasPermission`,
  `requestPermission`, `replaceAll(plan)`, `cancelSession`, `launchTap`, `taps` stream),
  wall-clock `zonedSchedule` (DST-safe). Plan computed purely in
  `domain/notifications/reminder_plan.dart`. Boot receivers in AndroidManifest.
- Orchestration: `NotificationBinding` + `ReminderCoordinator` in
  `lib/managers/notifications/` (permission asked once signed in; launch tap held until
  session resolves).
- Server side: `functions/src/notifications.ts` (6 Firestore-trigger senders),
  `fees.ts` (overdue), `scheduled_announcements.ts`, strings in `push_strings.json`.
- Quality: 4 (well designed; app-specific payload model).

### 3.15 IAP / payments
- `in_app_purchase ^3.2.3`, iOS only (`StorePolicy.sellsSubscription`).
- Domain interface `lib/domain/repositories/subscription_store_gateway.dart`
  (`isAvailable`, `products(ids)`, `purchases` stream, `buy`, `restore`, `finish(token)`);
  impl `lib/data/iap/iap_subscription_store_gateway.dart`; activation by callable
  (`lib/data/iap/functions_apple_activation_gateway.dart` → `activateAppleSubscription`).
- Server verification + App Store Server Notifications in `functions/src/apple_subscriptions.ts`
  using `@apple/app-store-server-library` and Apple root certs in `functions/certs/`.
- Quality: 4. The gateway interface is a reusable shape.

### 3.16 Permissions
- No permission_handler. Notification permission through the plugins; image_picker
  gallery only (only NSPhotoLibraryUsageDescription needed, noted in pubspec).

### 3.17 Deep links
- None external. Internal route strings from notifications only (see 3.3, 3.14).

### 3.18 CI / release (.github/)
- `.github/workflows/ci.yml` — on push to `dev`/`main` and every PR: checkout,
  `subosito/flutter-action@v2` pinned `flutter-version: '3.44.0'` with cache,
  `flutter pub get`, `flutter analyze --fatal-infos --fatal-warnings`, `flutter test`.
  Comment explains why rules/integration tiers are excluded (emulator/device) and that this
  is a known gap.
- `.github/workflows/release.yml` — on push to `main` (merge `dev`→`main` = release) or
  `workflow_dispatch` with `platform: both|ios|android`; `concurrency: release`
  (queue, no cancel); `permissions: contents: write`.
  - `bump` job: `tool/bump_build_number.sh` (awk-based, BSD/GNU-safe, refuses a version
    with no `+N`, writes `previous/build/version` to `$GITHUB_OUTPUT`), commits
    `pubspec.yaml` with `[skip ci]`, pushes to `main`, fast-forwards `dev` (warns if it
    cannot).
  - `android` job (ubuntu, Java 17 Temurin): optional restore of google-services.json from
    a secret, restore upload keystore + write `key.properties` from secrets (umask 077),
    re-runs analyze + test, shrinks Gradle JVM args for the 7 GB runner, `flutter build
    appbundle --release --flavor prod --dart-define=APP_ENV=prod`, uploads with
    `r0adkll/upload-google-play@v1` (track production, status completed).
  - `ios` job (`macos-26`, `maxim-lobanov/setup-xcode@v1` Xcode 26): import dist cert
    (`apple-actions/import-codesign-certs@v3`), fetch App Store profile
    (`apple-actions/download-provisioning-profiles@v3` with ASC API key), analyze + test,
    patch only the Runner `Release-prod` build configuration to manual signing with an
    inline Python script (and verify it applied), write an ExportOptions.plist,
    `flutter build ipa --release --flavor prod --dart-define=APP_ENV=prod`, upload with
    `xcrun altool` (key written to `~/private_keys/AuthKey_<id>.p8`).
- Secrets used (names only): GOOGLE_SERVICES_JSON, ANDROID_KEYSTORE_BASE64,
  ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, PLAY_SERVICE_ACCOUNT_JSON,
  IOS_DIST_CERT_P12_BASE64, IOS_DIST_CERT_PASSWORD, APPSTORE_ISSUER_ID, APPSTORE_KEY_ID,
  APPSTORE_PRIVATE_KEY, IOS_PROFILE_NAME.
- Template verdict: quality 4. Excellent, battle-tested comments. To genericize: lift
  bundle id, team id, the pbxproj configuration object id, Flutter version and track into
  `env:`/inputs; the pbxproj patch should match by configuration name, not object id. Add
  jobs for `functions` (`npm test`) and the rules tier (`firebase emulators:exec`).

### 3.19 tool/ scripts
| Script | Purpose |
|---|---|
| `tool/bump_build_number.sh` | bump `+N` in pubspec (CI-aware outputs) — generic |
| `tool/make_upload_key.sh` | generate Play upload keystore + `android/key.properties` (git-ignored) — generic (dname is personal; parametrize) |
| `tool/ios_dist_cert_to_secrets.sh` | push dist cert .p12 + password into GitHub secrets as a matched pair — generic |
| `tool/make_app_icons.sh`, `tool/make_store_graphics.sh` | render icons/store graphics from HTML sources in `store/` (Arabic shaping via browser) — semi-generic |
| `tool/asc/asc.py`, `tool/asc/listing.py` | dependency-free App Store Connect API client (ES256 via openssl) + listing plan/apply — generic (has a hardcoded default key id) |
| `tool/support/firestore_rest.dart` | Firestore REST client authenticated by a service account (for `dart run` scripts) — generic |
| `tool/check_indexes.dart` | run every app query shape with limit 1 against a real project; non-zero on missing composite index (incl. sum() aggregations) — pattern generic, shapes app-specific |
| `tool/seed_platform.dart`, `tool/seed_demo.dart` | idempotent seeders — app-specific |
| `tool/backfill_soft_delete.dart` | add `deletedAt: null` to legacy docs (`--dry-run`) — pattern generic |
| `tool/audit_phones.dart`, `tool/reconcile_subscriptions.dart`, `tool/smoke_public_teacher.dart` | read-only audits / smoke test — app-specific |

### 3.20 Cloud Functions (`functions/`)
- TypeScript strict (`noUnusedLocals/Parameters`), commonjs, es2020, Node 22;
  `firebase-functions` v2 API (`onCall`, `onSchedule`, Firestore triggers), `firebase-admin`.
- `functions/src/app.ts`: the single `admin.initializeApp()` + `setGlobalOptions({ region })`
  + exported `db`, in its own module so import hoisting cannot run Firestore before init.
- `functions/src/index.ts`: re-exports every function + `expireSubscriptions` (daily
  `onSchedule`, `Africa/Cairo`, batch chunked at 400 with audit entry and mutation in one
  batch).
- Callables validate `request.auth`, `request.data` types, throw `HttpsError(code,
  reason)` where `reason` is a stable machine token the Dart gateway maps to a Failure.
- Pure logic is split out for unit tests: `apple_subscription_logic.ts`,
  `enrollment_gates.ts`, `enrollment_placement.ts`, `family_admin_rules.ts`,
  `child_login_format.ts`, `teacher_code_format.ts`, `discovery_keys.ts`, `push_text.ts`,
  `arabic_folding.ts`, `public_calendar.ts`; tests in `functions/src/test/*.test.ts`
  (`node:test` + `node:assert/strict`, `npm test` = `tsc && node --test lib/test/*.test.js`;
  injectable `Math.random` for determinism).
- Quality: 4. Good shape for a template's `functions/` skeleton (app.ts + index.ts +
  node:test), minus the domain code.

---

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| `lib/app/environment.dart` | compile-time environment | `AppEnvironment.current`, `.id`, `.isProd`, `.firebaseOptions` | firebase_core, firebase_options_* | generic |
| `lib/app/store_policy.dart` | per-store feature switches | `teacherSignUp`, `teacherSignUpOn(p)`, `sellsSubscription`, `sellsSubscriptionOn(p)` | foundation | pattern generic |
| `lib/app/di/app_repositories.dart` | root MultiRepositoryProvider | `AppRepositories(authGateway, registration, scheduler, reminders, child, geo?, firestore?, storage?, functions?, store?)`, `functionsRegion` | flutter_bloc, Firebase | pattern generic |
| `lib/app/router/app_router.dart` | GoRouter + per-route use-case/Cubit wiring | `buildRouter(session, onRetrySession, onSignOut)` | go_router, everything | app-specific |
| `lib/app/router/redirect.dart` | pure redirect | `computeRedirect(session, location, {teacherSignUp})` | domain session | generic pattern |
| `lib/app/router/routes.dart` | route constants | consts, builders, `shells`, `homeFor(role)`, `isWithin()` | domain enums | pattern generic |
| `lib/app/router/session_status_notifier.dart` | router listenable + SessionReader | `session`, `update(next)` | foundation | generic |
| `lib/app/gates/role_gate.dart` | role-gated widget | `RoleGate(allow, session, child)` | failure mapper | generic |
| `lib/core/failures/failure_messages.dart` | error → sentence | `FailureMessages.asFailure(e)`, `FailureMessages.describe(e)` | easy_localization, firebase_core | pattern generic, codes app-specific |
| `lib/core/format/app_format.dart` | Western-digit formatting | `number`, `amount`, `year`, `longDate`, `shortDate`, `weekdayName`, `monthName`, `monthNameShort`, `wallClock(minutes)` | intl | generic |
| `lib/core/format/input_formatters.dart` | input formatters | `WesternDigitsFormatter`, `MaxValueFormatter(max)` | services | generic |
| `lib/core/l10n/l10n.dart` | locale config | `arabic`, `english`, `supported`, `fallback`, `path`, `ignorePluralRules`, `other(locale)` | widgets | generic |
| `lib/core/l10n/counted.dart` | plural helper | `counted(key, count)` | easy_localization | generic |
| `lib/core/l10n/egyptian_material_localizations.dart` | Material l10n override | `EgyptianMaterialLocalizations()` delegate | flutter_localizations, intl | generic for Arabic apps |
| `lib/core/l10n/isolate_translations.dart` | tr() in background isolate | `loadIsolateTranslations()` | easy_localization internals, shared_prefs | generic (fragile: private imports) |
| `lib/core/l10n/reading_language.dart` | current locale global | `ReadingLanguage.locale/code/of()` | dart:ui | generic |
| `lib/core/l10n/level_names.dart`, `group_names.dart` | domain key → label | `levelName(key)`, group labels | easy_localization | app-specific |
| `lib/core/settings/settings_store.dart` | prefs wrapper | `load()`, `themeMode`, `setThemeMode`, `selectedChild`, `setSelectedChild` | shared_preferences | mostly generic |
| `lib/core/render/widget_image.dart` | offscreen widget → PNG | `renderWidgetToPng(context, widget, size, pixelRatio)` | rendering | generic |
| `lib/core/contact/contact_launcher.dart` | dial / WhatsApp | `ContactLauncher.dial/whatsApp`, `UrlContactLauncher`, `callUri`, `whatsAppUri` | url_launcher, EgyptianPhone | semi (country code) |
| `lib/core/theme/app_theme.dart` | ThemeData builder | `platformTheme(b)`, `teacherTheme(set, b)`, `minimumTouchTarget` | material | generic |
| `lib/core/theme/palette.dart` | color tokens | consts + `*For(brightness)` | dart:ui | generic structure |
| `lib/core/theme/typography.dart` | text styles | `fontFamily`, `screenTitle/sectionHeading/body/label/caption/metric/displayCode`, `textTheme(...)` | material | generic structure |
| `lib/core/theme/app_radii.dart`, `app_insets.dart`, `app_motion.dart` | tokens | consts, `AppMotion.scaled/disabled` | widgets | generic |
| `lib/core/theme/status_colors.dart` | status ThemeExtension | `StatusTone`, `StatusColors.light/dark/of/forBrightness/colorFor` | material | generic |
| `lib/core/theme/contrast.dart` | WCAG contrast | `relativeLuminance`, `contrastRatio`, `foregroundOn` | dart:math | generic |
| `lib/core/theme/theme_set.dart`, `tenant_brand.dart`, `teacher_theme_scope.dart` | per-tenant themes | `ThemeSet.parse`, `TenantBrand.seen/clear/listenable`, `TenantThemed`, `TeacherThemeScope` | material | pattern generic (white-label) |
| `lib/domain/usecases/use_case.dart` … `staff_read_use_case.dart` | use-case bases | `call(params)` @nonVirtual, `execute(params)` @protected | meta, session | generic |
| `lib/domain/usecases/guards.dart` | guard bodies | `guardTenantAccess`, `guardStaffRead`, `guardTenantOwner`, `guardCapability`, `guardAdminAccess` | session snapshot | app-shaped, pattern generic |
| `lib/domain/usecases/params.dart` | param markers | `NoParams`, `TenantScoped`, `GroupScoped`, `StudentKeyParams` | meta | generic |
| `lib/domain/failures/failure.dart` | failure hierarchy | 5 sealed subtypes, `FailureCodes` | meta | generic hierarchy |
| `lib/domain/session/session_machine.dart` | session reducer | `reduce(state, event)`, `SessionState`, `SessionTransition` | equatable | generic pattern |
| `lib/domain/session/backoff.dart` | backoff ladder | `sessionBackoff`, `backoffFor(attempt)` | — | generic |
| `lib/domain/session/session_reader.dart`, `fixed_session_reader.dart` | session read port | `SessionReader.session`, `FixedSessionReader(snapshot)` | — | generic |
| `lib/domain/permissions/capability.dart` | capability registry | `Capability.all/parse/parseAll`, `teacherOnly` | — | pattern generic |
| `lib/domain/common/parse.dart` | defensive parsing | `asString/asStringOr/asInt/asIntOr/asBool/asDateTime/asStringList/asMap/asMapList` | — | generic |
| `lib/domain/common/page.dart` | page result | `Page<T>(items, hasMore)`, `Page.empty()` | equatable | generic |
| `lib/domain/common/soft_delete.dart` | soft-delete fields | `SoftDelete.parse/liveFields/deletedFields`, `isDeleted` | — | generic |
| `lib/domain/format/digits.dart` | digit folding | `toWesternDigits(s)` | — | generic (Arabic/Persian) |
| `lib/domain/search/arabic_folding.dart` | Arabic search normalization | `foldArabic(s)`, `matchesName(name, q)` | — | generic for Arabic |
| `lib/domain/phone/egyptian_phone.dart` | phone normalize/validate | `EgyptianPhone.normalise(...)` | — | region-specific |
| `lib/domain/time/wall_clock.dart` + `lib/data/time/tz_wall_clock.dart` | clock port | `WallClock.now({timezone})`, `TzWallClock` | timezone | generic |
| `lib/domain/notifications/pending_deep_link.dart` | hold cold-start route | `hold`, `release({resolved, signedIn})`, `clear`, `isHeld` | — | generic |
| `lib/data/firestore/paths.dart` | collection/path constants | 52 statics | — | app-specific values, generic pattern |
| `lib/data/firestore/live_only.dart` | soft-delete filter | `query.liveOnly` | cloud_firestore | generic |
| `lib/data/firestore/pagination.dart` | limit+1 paging | `fetchPage(query, limit, map)` | cloud_firestore | generic |
| `lib/data/firestore/firestore_decode.dart` | Timestamp decode | `decodeFirestoreValue`, `decodeSnapshot` | cloud_firestore | generic |
| `lib/data/functions/callable_refusal.dart` | callable error → Failure | `transportRefusal`, `purgeRefusal`, `promotionRefusal`, `childLoginRefusal` | domain failures | generic core (`transportRefusal`) |
| `lib/data/session/session_controller.dart` | drives session machine | `start()`, `retry()`, `signOut()`, `dispose()` | auth gateway, profile gateway, notifier | pattern generic |
| `lib/data/auth/auth_gateway.dart` + `firebase_auth_gateway.dart` | auth port | `authStateChanges`, `signIn`, `signOut`, `sendPasswordReset`, `changePassword` | firebase_auth | generic |
| `lib/data/auth/registration_repository.dart`, `account_provisioner.dart` | self-registration / provisioning | `settled`, register flows | Auth + Firestore | app-specific |
| `lib/data/notifications/push_receiver.dart` | FCM foreground/tap | `start()`, `dispose()`, `channel` | firebase_messaging, local notifications | generic |
| `lib/data/notifications/fcm_token_registrar.dart` | token persistence | `attach(uid)`, `detach()` | firebase_messaging, Firestore | generic (field name) |
| `lib/data/notifications/local_reminder_scheduler.dart` | scheduled local notifications | `initialize`, `hasPermission`, `requestPermission`, `replaceAll`, `cancelSession`, `launchTap`, `taps`, `onRoute` | flutter_local_notifications, timezone | semi-generic |
| `lib/data/drafts/shared_prefs_draft_repository.dart` | form drafts | `attendance/saveAttendance/clearAttendance`, marks, homework | shared_preferences | pattern generic |
| `lib/data/iap/iap_subscription_store_gateway.dart` | store gateway | `isAvailable`, `products`, `purchases`, `buy`, `restore`, `finish` | in_app_purchase | generic |
| `lib/data/export/xlsx_writer.dart`, `pdf_writer.dart`, `export_share.dart` | exports | `XlsxWriter.encode(workbook)` (with RTL sheet patch), `PdfWriter.renderReportCard`, `ExportShare.share/shareText/safeFileName` | excel, pdf, share_plus, path_provider | semi-generic |
| `lib/data/geo/geo_repository.dart` | asset-backed catalog | `load()` (memoized) | rootBundle | app-specific data |

---

## 5. Widgets catalog

All under `lib/core/widgets/`; every one except `teacher_note_sheet`, `location_fields` and
`settings/language_choice` has a widget test in `test/core/widgets/`. All are theme-driven
(no color literals; status colors via `StatusColors.of(context)`), directional, and take
already-localized strings as parameters (only `dirty_guard`, `app_text_field`,
`app_skeleton`, `note_sheet`, `location_fields`, `teacher_note_sheet` read their own
`LocaleKeys`).

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| `layout/app_scaffold.dart` | base scaffold; shows `message` once as SnackBar post-frame, thin busy bar | `title, child, message, busy, actions, floatingActionButton` | y |
| `layout/app_section.dart` | titled section | `title, children, help, icon, trailing` | y |
| `layout/form_page.dart` | full-screen form + `pushFormPage<T>()` | `formKey, title, thing, dirty, submitLabel, onSubmit, children, busy, error` | y |
| `layout/action_footer.dart` | sticky bottom action area | `action, secondary, caption` | y |
| `layout/app_nav_bar.dart` | NavigationBar wrapper | `selectedIndex, onDestinationSelected, destinations` | y |
| `layout/record_header.dart` | detail header + `RecordFact` | `title, overline, facts, trailing, margin` | y |
| `cards/app_card.dart` | hairline card, leading accent stripe | `child, padding, margin, onTap, accent` | y |
| `cards/nav_tile.dart` | navigation tile | `title, onTap, icon, subtitle, trailing, contentPadding` | y |
| `data/paged_list_view.dart` | list + "load more" row + stagger | `itemCount, itemBuilder, hasMore, loadingMore, onLoadMore, loadMoreLabel, header, separated, padding` | y |
| `data/person_row.dart` | person row with code tag | `name, code, subtitle, subtitleColor, trailing, leading, footer, onTap, semanticsLabel, margin` | y |
| `data/initials_avatar.dart` | initials avatar + `initialsOf()` | `name, radius, background, foreground, presence` | y |
| `data/stat_tile.dart` | KPI tile (+ row ctor) | `label, value, onTap, suffix, unavailableLabel, hint, icon, tone` | y |
| `data/status_chip.dart` | status pill (+ neutral ctor) | `label, tone, icon, showDot, dense, animated, minWidth` | y |
| `data/display_code.dart` | big code display | `code, onTap, semanticsLabel, color` | y |
| `feedback/app_skeleton.dart` | static skeleton (first load) | `rows` | y |
| `feedback/app_snackbar.dart` | snackbar helpers | `show, showOn, showUndo, showUndoOn, undoWindow` | y |
| `feedback/confirm_sheet.dart` | confirm/notice bottom sheet | `showConfirmSheet(title, confirmLabel, cancelLabel, body, destructive)`, `showNoticeSheet(title, body, okLabel)` | y |
| `feedback/dirty_guard.dart` | unsaved-changes guard (PopScope) | `dirty, thing, child, onDiscard`; `confirmDiscard(context, thing)` | y |
| `feedback/empty_state.dart` | empty state | `message, centered, icon, action` | y |
| `feedback/error_view.dart` | error state | `message, centered` | y |
| `feedback/form_sheet.dart` | keyboard-aware sheet launcher | `showFormSheet<T>(context, builder)` | y |
| `feedback/message_on_screen.dart` | inherited "already shown" contract | `claims, child` | y |
| `feedback/notice_banner.dart` | inline banner | `message, tone, icon, prominent, action, onDismiss, margin` | y |
| `feedback/teacher_note_sheet.dart` | teacher note display | `showTeacherNote(...)`, `TeacherNoteMark()` | n |
| `input/app_text_field.dart` | text field (validate on blur, digits, obscure toggle) | `controller, label, hint, helper, suffixText, validator, keyboardType, textInputAction, onSubmitted, onChanged, focusNode, autofocus, enabled, obscure, maxLines, maxValue, dense, outlined, textAlign` | y |
| `input/app_form.dart` | Form that knows its fields | `child`; `AppFormState.validate()` | y |
| `input/app_dropdown.dart` | dropdown | `value, items, onChanged, label, dense, expanded, errorText` | y |
| `input/busy_button.dart` | loading button + `ButtonSpinner` | `busy, onPressed, child, variant, style` | y |
| `input/date_field.dart` | date picker field | `label, value, firstDate, lastDate, onChanged, placeholder, icon, onClear` | y |
| `input/form_sheet_body.dart` | form frame in a sheet | `formKey, title, thing, dirty, submitLabel, cancelLabel, onSubmit, children, busy, error` | y |
| `input/note_sheet.dart` | note entry sheet + quick picks | `title, initial, picks`; `showNoteSheet()` | y |
| `input/location_fields.dart` | governorate/city/area | `geo, governorate, city, area, onGovernorate, onCity, onAreaChanged, enabled` | n |
| `motion/staggered_list.dart` | staggered entrance | `StaggerScope(child, stateKey)`, `StaggeredItem(index, child, arriving)` | y |
| `motion/state_switcher.dart` | animated state swap | `stateKey, child` | y |
| `settings/language_choice.dart` | ar/en segmented toggle | `onSaved` | y |
| `../branding/pulse_mark.dart`, `animated_pulse_mark.dart` | logo | size etc. | n |

Missing for a template: network image with placeholder, shimmer (deliberately static
skeleton here), search field, generic dialog (sheets used instead), image picker sheet,
infinite-scroll trigger (uses an explicit "load more" button), responsive layout wrapper.

---

## 6. Packages (`pubspec.yaml`)

| Role | Packages |
|---|---|
| State | flutter_bloc ^9.1.1, equatable ^2.1.0 |
| DI | — (flutter_bloc RepositoryProvider) |
| Routing | go_router ^18.0.1 |
| Network / backend | firebase_core ^4.14.0, firebase_auth ^6.6.1, cloud_firestore ^6.9.0, firebase_storage ^13.5.0, cloud_functions ^6.4.0 |
| Push | firebase_messaging ^16.6.0, flutter_local_notifications ^22.3.0, timezone ^0.11.1, flutter_timezone ^5.1.0 |
| Storage | shared_preferences ^2.5.5, path_provider ^2.1.6 |
| L10n | flutter_localizations (sdk), easy_localization ^3.0.8, intl ^0.20.2 |
| UI | cupertino_icons ^1.0.8 (+ Cairo variable font asset) |
| Payments | in_app_purchase ^3.2.3 |
| Media / files / export | image_picker ^1.2.3, share_plus ^13.3.0, pdf ^3.12.0, excel ^4.0.6, archive ^3.6.1, url_launcher ^6.3.2 |
| Utils | uuid ^4.6.0, meta ^1.16.0 (for @nonVirtual in pure domain) |
| Dev | flutter_test, integration_test, flutter_lints ^6.0.0, googleapis_auth ^2.0.0 + http ^1.2.0 (tool/ only), fake_async ^1.3.1, fake_cloud_firestore ^4.2.0 |
| Functions (npm) | firebase-functions ^7.3.2, firebase-admin ^13.10.0, @apple/app-store-server-library ^3.1.0; dev: typescript ^5.5.4 |

Assets: `assets/i18n/`, `assets/geo/` (egypt.json), `assets/fonts/Cairo-Variable.ttf` (+ OFL).
Version `1.0.1+36`.

---

## 7. Quality notes

- **Null safety / language:** Dart ^3.12 (sound null safety), uses records, patterns,
  sealed classes, `final class`, `abstract interface class`, null-aware collection
  elements. `strict-casts` and `strict-raw-types` on.
- **Lints:** `package:flutter_lints/flutter.yaml` + `always_declare_return_types`,
  `avoid_dynamic_calls`, `prefer_final_locals`, `unawaited_futures`;
  `prefer_initializing_formals: false` (private named params); analyzer error promotion
  `invalid_override_of_non_virtual_member: error`; `build/**` excluded. CLAUDE.md and CI
  require zero warnings and zero infos.
- **Tests (very strong):** 239 test files / ~2050 cases + 3 integration + 12 TS.
  - Domain/use cases: every guard rung (`test/domain/usecases/guards_test.dart`,
    `staff_read_use_case_test.dart`), per-feature use-case suites with hand-written fakes in
    `test/domain/usecases/*/support/fakes.dart`; capability completeness
    (`test/domain/permissions/capability_refusals_test.dart`: a map of every capability →
    the use case that guards it, fails when a capability guards nothing) and scope
    (`capability_scope_test.dart`); golden vector fixtures in `test/fixtures/*.json`.
  - Session machine (`test/domain/session/session_machine_test.dart`, 24 tests) and
    controller with `fake_async`.
  - Router: redirect cross product (`test/app/router/redirect_test.dart`).
  - Core: every core widget, theme, l10n parity (`translations_test.dart`: same keys, no
    blanks, matching placeholders, Arabic plural coherence, "Arabic is Arabic", every
    failure code has a sentence), failure mapper.
  - Rules tier (`test/rules/`, 34 suites): pure-Dart harness over the emulator REST API,
    one emulator project per suite to avoid cross-suite wipes, seeds as owner (bypassing
    rules), asserts `denied` = HTTP 403 specifically (not any failure), covers list vs
    query vs collection-group authorization paths, and loads `firestore.rules` as the
    compile check. Skips with a reason when `FIRESTORE_EMULATOR_HOST` is absent.
  - Data: repositories on `fake_cloud_firestore`.
  - Integration: `student_code_race_test.dart` (real transaction contention on the
    emulator), `record_browser_test.dart`, `store_screenshots_test.dart` (camera).
  - Harness: `test/support/app_harness.dart`, `localized.dart` (pump in both locales),
    `fake_reminder_scheduler.dart`, `memory_drafts.dart`.
- **Smells:** see the SMELLS line in the summary. The main template-relevant ones: no
  BaseCubit (boilerplate in ~40 cubits), router as an 1814-line composition root,
  `asFailure` not used by repositories despite its doc comment, string-keyed failure switch
  that is not exhaustive, no logging/crash reporting, no text scaling/responsive helpers,
  hardcoded identifiers in release.yml, signing files present (git-ignored) in the working
  tree, functions `.env.<project>` files tracked.
- **Deprecated APIs:** none found (0 `WillPopScope`, `withOpacity`, `MaterialStateProperty`,
  `textScaleFactor`; uses `PopScope`, `withValues`, `WidgetStateProperty`,
  `CardThemeData`, `DialogThemeData`, `InputDecorationThemeData`).
- **Secrets hygiene:** gitignore explicitly covers service-account JSON, keystores,
  `key.properties`, `*.p8`, `*.p12`, `*.mobileprovision`, `play-service-account.json`; git
  history shows none of those were ever committed. Per-flavor Firebase client configs
  (google-services.json, GoogleService-Info.plist, firebase_options_{dev,prod}.dart) are
  tracked on purpose (client config, not secrets). No API-key/private-key patterns found in
  Dart/TS/JS/YAML/shell/Python/HTML sources outside those files.

### Template-candidate verdict (the five areas asked about)
1. **Use-case base classes** (`lib/domain/usecases/`) — adopt. Generic core: `UseCase<R,P>`
   with `@nonVirtual call()` / `@protected execute()`, an `AuthorizedUseCase` variant whose
   guard is a free function over a `SessionReader`, `NoParams`, and a `Scoped` marker
   interface, plus the analyzer error promotion. Drop tenant/capability specifics.
2. **Failure mapping** — adopt the sealed `Failure implements Exception` + single
   `FailureMessages` mapper + "every code has a translation" test. Improve: codes as enum,
   make the switch exhaustive, call `asFailure` at the repository boundary (or in a
   BaseCubit), and add a BaseCubit/mixin `guard(() async {...})` that emits the message.
3. **Flavor/env** — adopt nearly verbatim: `AppEnvironment` enum with throw-on-unknown,
   Android flavors with suffix, iOS configs + plist-copy phase that fails flavorless builds,
   committed IDE run configs. Rename `MARKSPULSE_FLAVOR` → `APP_FLAVOR`.
4. **CI workflows** — adopt `ci.yml` as is (pinned Flutter, fatal infos). Adopt
   `release.yml` + `tool/bump_build_number.sh` + `tool/make_upload_key.sh` +
   `tool/ios_dist_cert_to_secrets.sh` after parameterizing ids; add functions and rules
   jobs.
5. **Tests** — adopt `test/domain/architecture_test.dart`, `test/core/l10n/translations_test.dart`,
   `test/support/localized.dart`, the redirect cross-product test, and (for Firebase
   templates) `test/rules/support/emulator.dart` as the rules harness.
