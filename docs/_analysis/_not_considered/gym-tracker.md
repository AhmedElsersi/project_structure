## Summary for comparison

```
PROJECT: gym-tracker | path: My Apps/gym_tracker_app | stack: Flutter, Dart SDK ^3.10.1 | last commit: 2025-12-17 (single "initial commit"; large uncommitted rewrite, lib mtime 2026-07-02) | source files: 43 (lib) + 1 test
ARCH: feature-first, light layering — features/<x>/{data,presentation}; but ALL data (DatabaseHelper, GymRepository, models) lives in features/exercises/data and is shared by every feature; flat core/ for infra
STATE: flutter_bloc 8 Cubits, no base class — plain state classes with copyWith + `loading` flag (`part of` cubit), mutate-then-reload() pattern; ThemeCubit<ThemeMode> (lib/core/theme_cubit.dart)
DI: none (manual) — RepositoryProvider.value(GymRepository) + BlocProvider(ThemeCubit) at root in lib/main.dart; services are factory singletons (DatabaseHelper, SharedPreferencesManager, ProService, ExerciseVideoStorage)
ROUTING: go_router 17 — lib/core/app_router.dart — no guards, no redirects; int ids as path params (/program/:programId/workout/:workoutId/exercise/:exerciseId); Navigator.push(MaterialPageRoute) mixed in for archived/fullscreen/YouTube screens; no deep-link config
NETWORK: none (offline app) — raw `Dio().download` only for offline video download (CancelToken + progress) in lib/features/exercises/presentation/widgets/video_acquire.dart | interceptors: none | token refresh: n | retry: n | error mapping: DioException -> snackbar string
RESULT_TYPE: exceptions (mostly uncaught in cubits); FormatException for share-file parsing — no Failure hierarchy
STORAGE: sqflite (versioned migrations v1->v3) lib/features/exercises/data/database_helper.dart; shared_preferences lib/core/shared_preferences_manger.dart; files lib/core/exercise_video_storage.dart
L10N: none — English only, no intl arb / easy_localization — hardcoded UI strings: many (~110+ literals)
RTL: Directional=0 vs LeftRight=9
THEME: lib/core/app_theme.dart — dark mode y (default dark, persisted toggle) | component themes in ThemeData: appBar + FAB only (no buttons/inputs) | colors class: lib/core/app_colors.dart (AppColors, barely used) + kEmerald const | text styles class: none | fonts: default
RESPONSIVE: flutter_screenutil (design size 390x844) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants — lib/core/config/app_config.dart (AppConfig.forceProUnlocked = true)
LOGGING: none (no print/log)
ANALYTICS/CRASH: none
PUSH: none (TODO mentions flutter_local_notifications for rest alarm)
PAYMENTS/IAP: none — local entitlement gate lib/core/pro_service.dart + paywall sheet lib/features/paywall/presentation/paywall_sheet.dart (billing TODO, in_app_purchase not added)
PERMISSIONS: permission_handler 11 — camera / videos requested inline in video_acquire.dart
DEEP_LINKS: go_router paths only (no app_links, no intent filters / URL types)
MEDIA/FILES: image_picker (video), file_picker (JSON import), share_plus (export), video_player + chewie, youtube_player_flutter, url_launcher, audioplayers, vibration, path_provider, fl_chart
TESTS: 1 file — 4 model toMap/fromMap round-trip unit tests (test/widget_test.dart)
LINTS: flutter_lints ^6.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/features/exercises/data/database_helper.dart — sqflite singleton: onConfigure FK pragma, versioned onUpgrade with idempotent _tableExists/_columnExists guards, batch reorder — quality 4 — coupling: high (app schema; pattern is generic)
- lib/core/exercise_video_storage.dart — local media store: persists filename only, resolves against docs dir at runtime, import/copy, adopt temp download (rename->copy fallback), size, formatBytes() — quality 4 — coupling: low (domain naming only)
- lib/features/rest_timer/presentation/rest_timer_sheet.dart — countdown bottom sheet: presets, +/- adjust, progress ring, sound + vibration on finish — quality 4 — coupling: low (asset path)
- lib/features/exercises/presentation/screens/fullscreen_video_screen.dart — fullscreen route that reuses an already-initialized controller, unlocks landscape + immersive only here, restores on dispose — quality 4 — coupling: low
- lib/features/sharing/gym_share_service.dart — versioned JSON export/import (schemaVersion, type, data), validation via FormatException, share_plus temp-file share, safeFileName — quality 4 (pattern) — coupling: high (repo/models)
- lib/core/pro_service.dart + lib/core/config/app_config.dart — entitlement gate with build-time override that never writes prefs — quality 3 — coupling: low
- lib/features/paywall/presentation/paywall_sheet.dart — requirePro(context, feature:) gate + paywall bottom sheet — quality 3 — coupling: medium (hardcoded benefits, no billing)
- lib/core/archived_screen.dart — generic callback-driven archive list (restore / delete forever) — quality 3 — coupling: low
- lib/core/ui_helpers.dart — showConfirmDialog() + ColorSwatchPicker — quality 3 — coupling: low (screenutil; swatches bound to kProgramColors)
- lib/core/shared_preferences_manger.dart — prefs singleton, dynamic setValue/getValue — quality 3 — coupling: none (untyped, silent no-op before init, typo in filename)
- lib/core/theme_cubit.dart — persisted dark/light ThemeMode cubit — quality 3 — coupling: low (no "system" option)
- lib/features/exercises/presentation/widgets/video_acquire.dart — Dio download with cancel + ValueNotifier progress dialog; permission -> picker flow — quality 3 — coupling: high (Pro gate, repo, models)
- lib/features/exercises/presentation/widgets/video_url_utils.dart — classify URL (YouTube / direct media / other / none) — quality 3 — coupling: low
- lib/core/app_theme.dart — light/dark ThemeData — quality 2 — coupling: none (thin: no button/input/text themes)
- lib/core/date_formatter.dart — DateFormat wrappers — quality 2 — coupling: none (identical copy exists in medical-report-creator)
GENERIC_WIDGETS (every reusable widget):
- lib/core/ui_helpers.dart showConfirmDialog() — confirm dialog -> Future<bool> — title, message, confirmLabel='Delete', confirmColor — quality 3 — generic? y
- lib/core/ui_helpers.dart ColorSwatchPicker — color swatch picker — selected (ARGB int?), onSelected — quality 3 — generic? partly (fixed palette)
- lib/core/archived_screen.dart ArchivedScreen — archive list screen — title, loader, onRestore, onDeleteForever — quality 3 — generic? y
- lib/features/rest_timer/presentation/rest_timer_sheet.dart RestTimerSheet / showRestTimerSheet() — countdown timer bottom sheet — initialSeconds, autoStart — quality 4 — generic? y
- lib/features/paywall/presentation/paywall_sheet.dart showPaywallSheet() / requirePro() — paywall bottom sheet + gate — feature — quality 3 — generic? partly
- lib/features/exercises/presentation/widgets/video_acquire.dart _DownloadDialog (private) — download progress dialog with cancel — progress (ValueNotifier<double>), onCancel — quality 3 — generic? y if extracted
- lib/features/exercises/presentation/screens/fullscreen_video_screen.dart FullscreenVideoScreen — fullscreen player route — videoController | youtubeController — quality 4 — generic? y
- lib/features/exercises/presentation/widgets/exercise_video.dart openExerciseVideo() — YouTube in-app else external launch — context, url — quality 3 — generic? partly
- lib/features/exercises/presentation/widgets/exercise_video_card.dart ExerciseVideoCard — collapsible inline player (local/direct/YouTube), lifecycle-aware — exercise, repo, onChanged — quality 3 — generic? n
- lib/features/programs/presentation/widgets/motivation_header.dart MotivationHeader — greeting + streak + quote card — none — quality 3 — generic? n
- lib/features/exercises/presentation/widgets/exercise_form_sheet.dart showExerciseFormSheet() — create/edit form bottom sheet — existing, onSubmit — quality 3 — generic? n
NOTABLE_IDEAS: idempotent sqflite migrations with _tableExists/_columnExists guards + data-preserving table rename (database_helper.dart); persist only the filename of local media and resolve against the documents dir at runtime, which survives reinstall/OS path changes (exercise_video_storage.dart); versioned JSON share-file format with strict parse/validate and name-conflict "replace/rename" resolution (gym_share_service.dart + sharing_ui.dart); build-time `forceProUnlocked` override that never touches stored entitlement (app_config.dart + pro_service.dart); requirePro(context) gate helper that shows paywall and re-checks (paywall_sheet.dart); portrait lock in main + per-route landscape unlock for fullscreen video, sharing one controller across inline/fullscreen (fullscreen_video_screen.dart); generic ArchivedScreen driven by callbacks (archived_screen.dart); soft-delete + archive + orderIndex reorder via batch on every tier
SMELLS: lib/code.dart is a 684-line fully commented-out prototype (dead code); CLAUDE.md is stale (describes old main/small/weight tables and routes that were deleted); data layer for all features sits in features/exercises/data (cross-feature coupling); FutureBuilder futures created inside build() per card (programs_screen.dart:285, workouts_screen.dart:178, exercises_screen.dart:189, motivation_header.dart:88) => N+1 DB queries on every rebuild; cubits start load() in constructor and have no try/catch or error state; TextEditingControllers in showSetLogDialog never disposed (exercise_detail_screen.dart:514); duplicated _toast/_showError helpers (sharing_ui.dart, video_acquire.dart, exercise_video.dart) and repeated bottom-sheet shape (6x); splash navigates in Future.delayed without mounted check and has no const ctor/key; global `final db` in main.dart and non-const MyApp creating repo in field initializer; ~125 hardcoded Colors.*/Color(0x) and ~110 hardcoded English strings; Theme.primaryColor used as accent instead of colorScheme; 9 left/right paddings/alignments, 0 Directional; share_plus `Share.shareXFiles` (legacy API in newer share_plus); hidden long-press debug Pro toggle on the AppBar title ships in release; 1 git commit with everything else uncommitted. Modern APIs used correctly: withValues(alpha:), toARGB32(), no WillPopScope/textScaleFactor/MaterialStateProperty.
```

---

## 1. Architecture pattern

Feature-first with a light data/presentation split. There is no domain layer, no use cases, no abstract repositories.

- **Data flow:** `Screen` -> per-screen `Cubit` (created in a `BlocProvider` inside the screen) -> `GymRepository` (thin async facade) -> `DatabaseHelper` (sqflite singleton) -> SQLite.
- **Hierarchy:** Program -> Workout -> Exercise -> SetLog (4 tables, FK cascade, soft-delete `isDeleted`, `isArchived`, `orderIndex`).
- **Shared data:** every feature (programs, workouts, exercises, sharing) imports `features/exercises/data/...`, so the "exercises" feature is really the app's data module.
- **Cubit pattern:** the constructor calls `load()`. Mutations call the repo and then `await load()` (no optimistic updates), except `reorder()`, which emits the reordered list first and then persists it with a batch.
- **State classes:** plain classes with `copyWith` and a `loading` bool, declared as `part of` the cubit file. No Equatable, no sealed states, no error state.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                     # portrait lock, prefs init, root providers, ScreenUtilInit(390x844), MaterialApp.router
├── code.dart                     # DEAD: 684-line commented-out single-file prototype
├── core/                         # flat shared infra
│   ├── app_colors.dart           # AppColors (5 consts, mostly unused)
│   ├── app_theme.dart            # appLightTheme / appDarkTheme + kEmerald
│   ├── theme_cubit.dart          # ThemeCubit<ThemeMode>, persisted 'is_dark_theme'
│   ├── app_router.dart           # GoRouter (splash, home, program/workout/exercise ids)
│   ├── shared_preferences_manger.dart  # SharedPreferencesManager singleton
│   ├── pro_service.dart          # local Pro entitlement gate
│   ├── exercise_video_storage.dart     # on-device video file store + formatBytes
│   ├── date_formatter.dart       # DateFormat helpers
│   ├── ui_helpers.dart           # showConfirmDialog, ColorSwatchPicker, kProgramColors
│   ├── archived_screen.dart      # generic archive list screen
│   └── config/
│       └── app_config.dart       # AppConfig.forceProUnlocked
└── features/
    ├── exercises/                # (representative + shared data module)
    │   ├── data/
    │   │   ├── database_helper.dart      # sqflite schema, migrations, all CRUD
    │   │   ├── gym_repo.dart             # GymRepository facade
    │   │   └── models/                   # program, workout, exercise, set_log (toMap/fromMap/copyWith)
    │   └── presentation/
    │       ├── managers/
    │       │   ├── exercises_cubit/      # ExercisesCubit + state (part of)
    │       │   └── set_logs_cubit/       # SetLogsCubit + state
    │       ├── screens/
    │       │   ├── exercises_screen.dart       # list for a workout (reorderable)
    │       │   ├── exercise_detail_screen.dart # stats, fl_chart line chart, history, showSetLogDialog
    │       │   └── fullscreen_video_screen.dart
    │       └── widgets/
    │           ├── exercise_form_sheet.dart
    │           ├── exercise_video.dart         # openExerciseVideo (YouTube/in-app or external)
    │           ├── exercise_video_card.dart    # inline collapsible player
    │           ├── video_acquire.dart          # download/attach/remove offline video
    │           └── video_url_utils.dart        # VideoKind classification
    ├── programs/presentation/    # ProgramsCubit, ProgramsScreen (home), MotivationHeader
    ├── workouts/presentation/    # WorkoutsCubit, WorkoutsScreen
    ├── paywall/presentation/     # paywall_sheet.dart (requirePro, showPaywallSheet)
    ├── rest_timer/presentation/  # rest_timer_sheet.dart
    ├── sharing/                  # gym_share_service.dart + presentation/sharing_ui.dart (export/import flows)
    └── splash/presentation/      # splash.dart (800 ms then go('/home'))
```

## 3. Infrastructure

### State management
- `flutter_bloc ^8.1.2`. Cubits: `ProgramsCubit`, `WorkoutsCubit`, `ExercisesCubit`, `SetLogsCubit`, `ThemeCubit`.
- No base cubit and no request-handling helper. Errors are not caught: a failing DB call leaves `loading: true` forever.
- Each screen creates its own cubit with `RepositoryProvider.of<GymRepository>(context)`.

### DI
- None. `GymRepository(db)` is created in a `MyApp` field initializer (with `db` a top-level global in `main.dart`) and exposed through `RepositoryProvider.value`.
- Other services are factory singletons (`ProService()`, `ExerciseVideoStorage()`, `SharedPreferencesManager()`), called directly from widgets.

### Routing
- `go_router ^17.0.1`, `lib/core/app_router.dart`: a single top-level `GoRouter appRouter`.
- Routes are `/`, `/home`, `/program/:programId`, `/program/:programId/workout/:workoutId` and `/.../exercise/:exerciseId`. They are parsed with `int.parse(state.pathParameters[...]!)`, with no validation.
- No guards, redirects, error page, shell routes or named routes.
- Archived screens, the fullscreen video and the YouTube player use `Navigator.push(MaterialPageRoute)`.

### Networking
- No API client. `dio ^5.7.0` is used once, as `Dio().download(url, tempPath, cancelToken:, onReceiveProgress:)` in `video_acquire.dart`.
- `CancelToken.isCancel` is handled. Partial files are cleaned up in `finally`.
- No interceptors, retry, timeouts or logging.

### Local storage
- **sqflite**, in `features/exercises/data/database_helper.dart`. Database `gym_tracker.db` in the app documents dir, `_dbVersion = 3`, and `onConfigure` enables `PRAGMA foreign_keys = ON`.
  - `_migrateV1toV2` turns FKs off, creates the new tables, copies the old `main_exercises/small_exercises/weight_entries` rows across keeping their ids, drops the old tables and turns FKs back on.
  - `_migrateV2toV3` adds a column, guarded by `_columnExists`.
  - Reorder uses `batch.update` and `commit(noResult: true)`.
  - Good, real-world migration code. No transaction wraps the v1->v2 copy, though.
- **shared_preferences**, in `core/shared_preferences_manger.dart`: a singleton with `init()`, a type-switching `setValue(key, dynamic)`, `getValue(key) -> dynamic`, `remove` and `clear`. It is untyped and returns null silently before `init()`.
- **Files**, in `core/exercise_video_storage.dart`. See Services.

### Localization / RTL
- None. All strings are English literals. Directional=0, Left/Right=9.

### Theming
- `core/app_theme.dart` defines top-level `appDarkTheme` and `appLightTheme`.
  - Each sets brightness, scaffold background, `primaryColor = kEmerald`, `cardColor`, a minimal `ColorScheme.dark/light`, `AppBarTheme` (transparent, no elevation, title style) and `FloatingActionButtonThemeData`.
  - No elevatedButton, input, text, card or dialog themes. No custom font.
- `ThemeCubit` persists the choice (default dark). There is no `ThemeMode.system` option.
- Widgets use `theme.primaryColor` and `theme.cardColor` heavily, plus many hardcoded `Colors.*` (about 125).

### Responsive helpers
- `flutter_screenutil ^5.8.4`, `ScreenUtilInit(designSize: Size(390, 844))`, without `minTextAdapt`. `.w/.h/.sp/.r` are used everywhere. No breakpoints and no tablet handling.

### Text scaling
- None.

### Env / flavors
- None. `lib/core/config/app_config.dart` holds `static const bool forceProUnlocked = true` (a temporary pre-launch override).

### Logging
- None.

### Analytics / crash reporting
- None.

### Push notifications
- None. There is a TODO for `flutter_local_notifications` (background rest alarm).

### IAP / payments
- `ProService.isPro => AppConfig.forceProUnlocked || prefs['is_pro']`. `maxFreePrograms = 2`.
- `requirePro(context, feature:)` shows the paywall and then re-checks.
- The paywall "Upgrade" button only shows a "Billing coming soon" snackbar.
- A hidden long-press on the "My Programs" title toggles Pro (debug).

### Permissions
- `permission_handler ^11.3.1`: `Permission.camera` or `Permission.videos` is requested before `ImagePicker().pickVideo` (`limited` is accepted). The manifest declares CAMERA, READ_MEDIA_VIDEO and a legacy READ_EXTERNAL_STORAGE. iOS has the camera and photo usage strings.

### Deep links
- None, beyond go_router paths.

## 4. Services catalog

| File | Purpose | Public API | Deps | Generic? |
|---|---|---|---|---|
| lib/core/shared_preferences_manger.dart `SharedPreferencesManager` | prefs singleton | `init()`, `setValue(k, dynamic)`, `getValue(k)`, `remove(k)`, `clear()` | shared_preferences | generic |
| lib/core/theme_cubit.dart `ThemeCubit` | persisted ThemeMode | `toggleTheme()` | flutter_bloc, prefs manager | generic |
| lib/core/pro_service.dart `ProService` | entitlement gate | `isPro`, `setPro(bool)`, `maxFreePrograms` | prefs manager, AppConfig | semi-generic |
| lib/core/config/app_config.dart `AppConfig` | build switches | `forceProUnlocked` | — | generic pattern |
| lib/core/exercise_video_storage.dart `ExerciseVideoStorage` | on-device media store | `resolve(name)`, `fileNameFor(id, ext)`, `importFrom(File, id)`, `adoptTempFile(File, id, ext)`, `deleteByName`, `sizeBytes`, `tempDownloadPath(id)`; top-level `formatBytes(int)` | path_provider, path, dart:io | generic (rename) |
| lib/core/date_formatter.dart `DateFormatter` | date formatting | `formatDateString(str, fmt)`, `formatDate(dt, fmt, locale)`, `isMorning(dt)` | intl | generic |
| lib/core/ui_helpers.dart | dialog + palette | `showConfirmDialog(...)`, `kProgramColors`, `ColorSwatchPicker` | screenutil | generic |
| lib/core/app_router.dart | GoRouter config | `appRouter` | go_router | app-specific |
| lib/core/app_theme.dart / app_colors.dart | themes, colors | `appLightTheme`, `appDarkTheme`, `kEmerald`, `AppColors` | — | app-specific |
| lib/features/exercises/data/database_helper.dart `DatabaseHelper` | SQLite gateway | `db`, CRUD for programs/workouts/exercises/set_logs, `reorder*`, `count*`, `lastTrainedForProgram`, `getAllSetLogTimestamps`, `close()` | sqflite, path_provider, path | app-specific (pattern generic) |
| lib/features/exercises/data/gym_repo.dart `GymRepository` | repo facade | load/add/update/softDelete/archive/deleteForever/reorder per tier, set-log ops, `setExerciseVideoFile` | DatabaseHelper, ExerciseVideoStorage | app-specific |
| lib/features/sharing/gym_share_service.dart `GymShareService` | JSON export/import | `exportProgram/Workout/Exercise`, `prettyJson`, `safeFileName`, `share(json, name)`, `parse(raw)`, `nameExists`, `replaceExisting`, `importProgram/Workout/Exercise` | share_plus, path_provider, repo | app-specific (pattern generic) |
| lib/features/sharing/presentation/sharing_ui.dart | share/import UI flows | `shareProgram/Workout/Exercise`, `runImport` | file_picker, service | app-specific |
| lib/features/exercises/presentation/widgets/video_acquire.dart | offline-video acquisition | `downloadForOffline`, `attachLocalVideo`, `removeOfflineVideo` | dio, image_picker, permission_handler, storage, paywall | app-specific |
| lib/features/exercises/presentation/widgets/video_url_utils.dart | URL classification | `VideoKind`, `isYoutubeUrl`, `isDirectVideoUrl`, `extensionForUrl`, `classifyUrl` | youtube_player_flutter | generic |
| lib/features/exercises/data/models/set_log.dart | formatting helper | `setLogSummary(log, unit:)` | — | app-specific |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/ui_helpers.dart `showConfirmDialog` | yes/no AlertDialog -> bool | context, title, message, confirmLabel='Delete', confirmColor=redAccent | y |
| lib/core/ui_helpers.dart `ColorSwatchPicker` | circular color swatches | selected (int?), onSelected | partly |
| lib/core/archived_screen.dart `ArchivedScreen` | list with Restore / Delete forever | title, loader, onRestore, onDeleteForever | y |
| lib/features/rest_timer/presentation/rest_timer_sheet.dart `RestTimerSheet` + `showRestTimerSheet` | countdown sheet with presets 60/90/120/180, +/- adjust, sound + vibrate | initialSeconds, autoStart | y |
| lib/features/paywall/presentation/paywall_sheet.dart `showPaywallSheet` / `requirePro` | paywall sheet with benefit list | feature | partly |
| lib/features/exercises/presentation/widgets/video_acquire.dart `_DownloadDialog` | progress dialog with cancel | progress (ValueNotifier<double>), onCancel | y (private) |
| lib/features/exercises/presentation/screens/fullscreen_video_screen.dart `FullscreenVideoScreen` | fullscreen chewie/YouTube with orientation unlock | videoController?, youtubeController? | y |
| lib/features/exercises/presentation/widgets/exercise_video.dart `openExerciseVideo` / `_YoutubeVideoScreen` | YouTube player route or external launch | context, url | partly |
| lib/features/exercises/presentation/widgets/exercise_video_card.dart `ExerciseVideoCard` | collapsible inline video player | exercise, repo, onChanged | n |
| lib/features/programs/presentation/widgets/motivation_header.dart `MotivationHeader` | greeting + streak + quote | — | n |
| lib/features/exercises/presentation/widgets/exercise_form_sheet.dart `showExerciseFormSheet` | exercise create/edit sheet | existing, onSubmit | n |
| lib/features/exercises/presentation/screens/exercise_detail_screen.dart `_StatCard`, `_ChartCard`, `_HistoryRow`, `showSetLogDialog` | stats card, fl_chart line chart, swipe row, log dialog | private | n |
| lib/features/*/screens `_ProgramCard`, `_WorkoutCard`, `_ExerciseCard`, `_*Menu` | list cards + popup menus | private | n |

No shared button, text field, loader, empty-state, network image or snackbar widget. Empty states are inline `Center(Text(...))`, loaders are bare `CircularProgressIndicator`, and snackbars are raw `ScaffoldMessenger` calls.

## 6. Packages (`pubspec.yaml`)

- **State:** flutter_bloc ^8.1.2
- **Routing:** go_router ^17.0.1
- **Network:** dio ^5.7.0 (download only)
- **Storage:** sqflite ^2.2.8, shared_preferences ^2.2.0, path_provider ^2.0.15, path ^1.8.3
- **L10n / format:** intl ^0.20.2
- **UI:** flutter_screenutil ^5.8.4, flutter_animate ^4.5.2, fl_chart ^1.1.1, cupertino_icons ^1.0.8
- **Media:** video_player ^2.9.2, chewie ^1.8.5, youtube_player_flutter ^9.1.1, image_picker ^1.1.2, file_picker ^8.1.6, audioplayers ^6.1.0, vibration ^2.0.0
- **Utils:** url_launcher ^6.3.1, share_plus ^10.1.2, permission_handler ^11.3.1
- **Dev:** flutter_test, flutter_lints ^6.0.0, flutter_launcher_icons ^0.13.1 (adaptive icon configured)
- **Firebase:** none

## 7. Quality notes

- **Null safety:** full (SDK ^3.10.1). Uses records (`typedef ArchivedItem = ({int id, String name})`, benefit tuples), `withValues(alpha:)` and `toARGB32()`. No deprecated Material APIs found.
- **Lints:** `flutter_lints` with no extra rules.
- **Tests:** `test/widget_test.dart` holds 4 pure-Dart model round-trip tests. CLAUDE.md still says it is the failing counter test, which is outdated. No cubit, repo or widget tests.
- **Docs:** CLAUDE.md and README describe the old 3-tier schema (`main_exercises`, `/main/:id` routes). The code is now 4-tier with migrations, so the docs are stale.
- **Smells:**
  - Dead `lib/code.dart`.
  - Data layer misplaced under one feature.
  - `FutureBuilder(future: repo...)` created in `build()` inside list cards (re-queries on each rebuild, N+1).
  - No error handling in cubits.
  - Undisposed controllers in `showSetLogDialog`.
  - Duplicated toast helpers and sheet shapes.
  - A Future.delayed navigation without a mounted check.
  - Heavy hardcoded strings and colors. No l10n or RTL.
  - A hidden debug Pro toggle reachable in release.
- **Strengths:**
  - Carefully commented code.
  - Real migrations.
  - Robust file-path handling for local media.
  - Context-mounted checks after awaits in the video and share flows.
  - Clean separation of share-format logic from UI.
