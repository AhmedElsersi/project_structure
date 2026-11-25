# chinaparts-mobile-app: analysis report

## Summary for comparison

```
PROJECT: chinaparts-mobile-app | path: Chinaparts/New Projects/mobile_app | stack: Flutter, Dart SDK ^3.8.1 (CI pins Flutter 3.44.4) | last commit: 2026-07-11 (30 commits; many uncommitted platform changes) | source files: 31
ARCH: feature-first "screens + services" (no layers) — features/<name>/{screens,services,models}; services call Dio directly and return raw JSON/maps; no domain/repository layer
STATE: setState only (StatefulWidget + FutureBuilder/StatefulBuilder) — no base classes
DI: none — every service is created per call as `XService(context)`, and each one builds a new ApiClient/Dio
ROUTING: Navigator 1.0 named routes (5) + MaterialPageRoute pushes — lib/routes/app_routes.dart — guards: initialRoute picked from a token check in main.dart, role check after login → /not-allowed; deep links: none
NETWORK: dio — interceptors: one InterceptorsWrapper (Bearer token from prefs + error parsing + refresh) | token refresh: y (backend code 1005 → POST /auth/refresh-token, retry once, no lock/queue) | retry: n (refresh-retry only) | error mapping: backend {code,message,details,errors} → DioException.message plus GlobalErrorHandler SnackBar; force logout on 1006/2005/any 404 | lib/core/network/api_client.dart, lib/core/utils/error_handler.dart
RESULT_TYPE: exceptions (services `rethrow`) — no Failure hierarchy; ExceptionResponse DTO in lib/core/utils/error_handler.dart
STORAGE: shared_preferences used raw (15 getInstance calls; tokens stored in plain prefs) — no wrapper
L10N: easy_localization 3.0.8 — en, ar; startLocale ar, fallback en; assets/translations/{en,ar}.json (444 keys each, in sync) — hardcoded UI strings: some (~20: error fallbacks, 'Failed to load profile', 'Phone', 'Identity', 'General Appearance', validator messages)
RTL: Directional=0 vs LeftRight=33
THEME: inline ThemeData in lib/main.dart (primaryColor + fontFamily only) — dark mode n | component themes in ThemeData n | colors class lib/core/constants/app_colors.dart (4 colors) | text styles class none | fonts 'Cairo'/'Tajawal' referenced 22x but never bundled in pubspec
RESPONSIVE: none — ad-hoc MediaQuery.size.height fractions (0.48 / 0.7 / 0.85) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constant (AppConfig.baseUrl, alternates commented out) — lib/core/constants/app_config.dart; a .env file exists but nothing reads it (no dotenv package)
LOGGING: one print() (cleaning_form_screen.dart); no logger
ANALYTICS/CRASH: none
PUSH: none
PAYMENTS/IAP: none
PERMISSIONS: no permission_handler; image_picker camera/gallery; iOS Info.plist has NO NSCamera/NSPhotoLibrary usage descriptions
DEEP_LINKS: none
MEDIA/FILES: image_picker (camera, imageQuality 70), path_provider + open_filex (PDF download and open), Image.memory over authenticated Dio bytes, Image.network with Authorization header, month_picker_dialog, package_info_plus
TESTS: 0 — test/ folder is empty
LINTS: flutter_lints ^6.0.0 (default include), 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/utils/error_handler.dart — ExceptionResponse DTO + GlobalErrorHandler.handleError(context, e): decodes bytes/String/Map bodies, merges message+details, adds validation errors as de-duplicated bullets, falls back to no-connection, shows SnackBar — quality 3 — coupling: low-medium (AppColors, easy_localization keys errors.*, shows UI directly)
- lib/core/network/api_client.dart — Dio factory with auth header, refresh-on-1005 + retry, forced logout, error-message extraction — quality 2 — coupling: high (needs BuildContext, navigates, SharedPreferences, backend-specific codes, logs out on any 404, leaves the request hanging on logout)
- lib/features/reports/services/report_service.dart — download bytes → app docs dir → OpenFilex.open — quality 2.5 — coupling: medium (endpoint/prefs key hardcoded; pattern is generic)
- lib/features/task/services/task_service.dart — submitTask(): multipart with a JSON "data" part (application/json) + N "attachments" files (Spring @RequestPart style) — quality 2.5 — coupling: medium (endpoints)
- lib/features/home/screens/main_screen.dart — bottom-nav IndexedStack shell; pages keyed by locale; lazy tab activation through an isActive flag — quality 2.5 — coupling: medium (concrete pages)
- lib/core/constants/app_colors.dart — 4-color palette constants — quality 1.5 — coupling: none
- lib/routes/app_routes.dart — Map<String, WidgetBuilder> named routes — quality 1.5 — coupling: high (string paths, no constants)
GENERIC_WIDGETS (every reusable widget):
- (no shared widgets folder; every candidate below is a private method/class inside a screen)
- lib/features/auth/screens/login_screen.dart (_TealIconBox) — tinted rounded icon box used as a TextField prefixIcon — icon — quality 3 — generic? y (once the color is a param)
- lib/features/task/screens/forms/general_maintenance_screen.dart (_buildSelectionGroup) — segmented radio cards in a Row of Expanded — label, options, selected, onSelect (+ color resolver) — quality 3 — generic? y after extraction
- lib/features/task/screens/forms/general_maintenance_screen.dart (_buildTextArea) — 4-line, 300-char filled TextFormField with required validator — controller, hint, isRequired — quality 2.5 — generic? y
- lib/features/task/screens/forms/*_screen.dart (_buildSectionLabel ×5) + register_screen.dart (_buildLabel) — label with red " *" required marker — text, isRequired — quality 2.5 — generic? y (duplicated 6x)
- lib/features/task/screens/forms/cleaning_form_screen.dart, fuel_unloading_safety_form_screen.dart (_buildYesNoToggle), fuel_unloading_form_screen.dart (_buildBooleanToggle), periodic_inspection_screen.dart (_buildInspectionItem) — yes/no two-button toggle — key → bool? map — quality 2 — generic? y (duplicated 4x)
- lib/features/task/screens/forms/quality_management_report_screen.dart (_section) — card-styled ExpansionTile section (Material + clip + hidden divider) — titleKey, icon, children — quality 3 — generic? y
- lib/features/task/screens/forms/quality_management_report_screen.dart (_removableCard, _miniToggleFor/_chip, _addButton) — dynamic-list item card with delete; compact check/close chip toggle — quality 2.5 — generic? y
- lib/features/auth/screens/register_screen.dart (_buildTextField) — filled TextFormField with prefix icon, hidden counter, default required validator — controller, hint, icon, keyboardType, maxLength, validator — quality 2.5 — generic? y
- lib/features/home/screens/home_dashboard_screen.dart (_showStationSelector) — searchable bottom-sheet picker (StatefulBuilder + filter + keyboard inset) — quality 3 — generic? y after extraction (currently Station-typed)
- lib/features/home/screens/home_dashboard_screen.dart (_buildSecureImage) — authenticated image (Dio bytes → Image.memory, loading/broken placeholders) — filePath — quality 2 (Future created in build) — generic? y
- lib/features/archive/screens/archive_screen.dart (_showFullScreenImage) — full-screen InteractiveViewer image dialog with auth headers + close button — imageUrl, token — quality 2.5 — generic? y
- photo-attachment block (camera tile + horizontal thumbnail row with remove X) duplicated in 5 form screens — quality 2 — generic? y (duplicated 5x)
NOTABLE_IDEAS: (1) GlobalErrorHandler decodes List<int> (ResponseType.bytes) error bodies before parsing, so file-download errors still show backend messages (lib/core/utils/error_handler.dart). (2) Translate-if-exists, else humanize camelCase, used to render arbitrary backend form maps (archive_screen.dart _formatKey/_formatValue). (3) Multipart with a JSON part typed application/json plus file parts for Spring @RequestPart (task_service.dart, register_screen.dart). (4) Lazy tab loading in an IndexedStack: an isActive flag plus didUpdateWidget runs the fetch on first activation (archive_screen.dart + main_screen.dart). (5) Role check after login routes non-permitted roles to a dedicated /not-allowed screen (login_screen.dart, not_allowed_screen.dart). (6) GitHub Actions release-APK workflow decodes the keystore from a secret and writes signing props into gradle.properties (.github/workflows/android.yml). (7) Refresh runs on a separate Dio instance to avoid interceptor recursion (api_client.dart).
SMELLS: no shared widgets, services or DI; BuildContext stored in every service and in ApiClient; a new Dio + interceptor per service per call; ApiClient logs out on ANY 404 and wipes all prefs (including easy_localization's saved locale and the selected station); after a failed refresh/forced logout the interceptor `return`s without calling handler → caller Future never completes; no refresh lock (parallel 1005s → parallel refreshes); retry drops responseType and can't resend FormData; tokens in plain SharedPreferences; DioException parsing copy-pasted in 6 screens instead of GlobalErrorHandler (18 hardcoded English fallbacks); raw `List<dynamic>`/`Map` JSON in history/archive/details (no models); FutureBuilder futures created in build (refetch on every rebuild); 32 TextEditingControllers vs 2 dispose() overrides; 555 inline Colors.* + ad-hoc TextStyles; ThemeData nearly empty, so surfaceTintColor: transparent workarounds are scattered; fonts referenced but not bundled; 0 Directional insets, with manual isRtl ternaries for Positioned/Alignment; header forced to LTR; giant screens (quality form 1190 lines, dashboard 1027, task history 869); `try {…} catch (e) { rethrow; }` boilerplate in every service method; print() in production; iOS camera/photo usage descriptions missing (camera/gallery will crash on iOS); stray `flutter_lints` key inside the flutter_launcher_icons block of pubspec; Android cleartext allowed for a domain in network_security_config.xml; signing passwords committed in android/gradle.properties.
```

---

## 1. Architecture pattern

- **Pattern:** feature-first folders, each holding `screens/`, `services/` and sometimes `models/`. There is no data/domain/presentation split, no repositories, and no state-management library. Screens are `StatefulWidget`s that create a service (`AuthService(context)`, `TaskService(context)`, …) inline, `await` it, and `setState` the result. Errors reach the screen as exceptions (`DioException`), and the screen either calls `GlobalErrorHandler.handleError(context, e)` or, in 6 screens, re-implements the parsing inline.
- **A feature looks like this** (`task`): `services/task_service.dart` wraps endpoints and returns `Map<String, dynamic>` / `void`. `screens/category_tasks_screen.dart` lists tasks. `screens/task_history_screen.dart` pages history and routes to the right form by matching `taskTitle` against string lists. `screens/forms/*` are six large form screens, each with its own private UI helpers.
- **Cross-feature coupling:** `home` uses the models and service in `dashboard` (the `dashboard` feature has no screens). `archive` embeds `reports/screens/reports_form_screen.dart` as a tab. `settings` uses `auth/services`.
- **App start:** `main.dart` reads `token` from SharedPreferences and sets `initialRoute` to `/home` or `/login`. Then `EasyLocalization` → `MaterialApp(routes: AppRoutes.getRoutes())`.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                         # bootstrap: EasyLocalization, token check → initialRoute, inline ThemeData
├── routes/
│   └── app_routes.dart               # Map<String, WidgetBuilder> of 5 named routes
├── core/
│   ├── constants/
│   │   ├── app_colors.dart           # AppColors: primaryBlue, primaryTeal, background, errorRed
│   │   └── app_config.dart           # AppConfig.baseUrl = '{{BASE_URL}}' (+ commented alternates)
│   ├── network/
│   │   └── api_client.dart           # ApiClient(context): Dio + auth/refresh/logout/error interceptor
│   └── utils/
│       └── error_handler.dart        # ExceptionResponse DTO + GlobalErrorHandler (SnackBar)
└── features/
    ├── auth/
    │   ├── screens/                  # login, register, forget_password, reset_password, not_allowed
    │   └── services/auth_service.dart# login/forgot/reset/change password/logout
    ├── dashboard/                    # data-only "feature" consumed by home
    │   ├── models/                   # station.dart, task_summary.dart (manual fromJson)
    │   └── services/dashboard_service.dart
    ├── home/
    │   └── screens/                  # main_screen.dart (bottom nav shell), home_dashboard_screen.dart (1027 lines)
    ├── archive/
    │   └── screens/archive_screen.dart # paginated submission history + details sheet; TabBar with reports tab
    ├── reports/
    │   ├── screens/reports_form_screen.dart # report type + month → download PDF
    │   └── services/report_service.dart
    ├── settings/
    │   └── screens/                  # settings_screen.dart, change_password_dialog.dart
    └── task/                         # representative feature, fully expanded
        ├── services/task_service.dart          # submitTask (multipart), getHistory, getSubmissionDetails, getTaskSpecificHistory
        └── screens/
            ├── category_tasks_screen.dart      # task list of a category with status colors/icons
            ├── task_history_screen.dart        # paginated history per task + routes to correct form
            └── forms/
                ├── general_maintenance_screen.dart        # 543 lines
                ├── cleaning_form_screen.dart              # 553
                ├── fuel_unloading_form_screen.dart        # 563
                ├── fuel_unloading_safety_form_screen.dart # 460
                ├── periodic_inspection_screen.dart        # 640
                └── quality_management_report_screen.dart  # 1190
```

Other notable root items: `assets/translations/{en,ar}.json`, `assets/images/*`, `assets/icon/*`, `flutter_launcher_icons.yaml`, `.github/workflows/android.yml`, and an empty `test/`. Secret or private files exist by name only (not opened): `.env`, `notes.txt`, `android/app/my-release-key.jks`, `my-release-key-old.jks`, `my-release-key.jks.base64`. All of these are git-ignored.

## 3. Infrastructure

### State management
- None. Everything uses `setState`, plus `FutureBuilder` for the profile dialog and the secure image, and `StatefulBuilder` for the station-search bottom sheet.
- Loading flags (`_isLoading`) and `mounted` checks are repeated by hand in every screen. `mounted` checks after async gaps are applied fairly consistently.

### DI
- None. Services are constructed at the call site with a `BuildContext`, and each one constructs `ApiClient(context)`, which creates a new `Dio`.

### Routing
- `lib/routes/app_routes.dart` returns `{'/login', '/forget-password', '/reset-password', '/home', '/not-allowed'}`. Every other navigation uses `Navigator.push(MaterialPageRoute(...))` with constructor args.
- **Guard:** the initial route depends on token presence (`main.dart`). After login, a role check (`role == 'ROLE_SUPERVISOR'`) goes to `/home`, otherwise to `/not-allowed`.
- Route names are string literals scattered across screens and `ApiClient`; there are no constants.
- No `onUnknownRoute`. No deep links.

### Networking — `lib/core/network/api_client.dart`
- `Dio(BaseOptions(baseUrl: AppConfig.baseUrl))` has no timeouts and no default headers beyond auth.
- **onRequest:** reads `token` from SharedPreferences on every request and sets `Authorization: Bearer`.
- **onError:**
  - Decodes a String body to JSON.
  - If the body is a Map:
    - `code == 1005` (expired): `_refreshToken()` runs on a separate Dio (`POST /auth/refresh-token`), saves the new token and refreshToken, and re-issues the request via `dio.request(path, options: Options(method, headers), data, queryParameters)`. The interceptor re-applies the new token. If the refresh fails, it calls `_forceLogout` (clears all prefs, shows a SnackBar, `pushNamedAndRemoveUntil('/login')`) and then `return`s **without calling the handler**.
    - `code == 1006 || code == 2005 || statusCode == 404` (except the reset/forgot-password paths): clears prefs and navigates to login, again without calling the handler.
    - Otherwise it copies `message`/`error` into `e.copyWith(message: …)`.
- **Quality issues:**
  - The constructor needs a BuildContext.
  - There is no refresh mutex.
  - The retry loses `responseType`/`contentType` and cannot replay `FormData`.
  - Returning without `handler.next/reject` leaves the awaiting Future pending forever.
  - Treating every 404 as "user not found → logout" is dangerous.
  - `prefs.clear()` also wipes easy_localization's persisted locale.
- **Error mapping:** `lib/core/utils/error_handler.dart`.
  - `ExceptionResponse.fromJson` reads `{code, message, details, errors}`. `displayMessage` returns `"message: details"`.
  - `GlobalErrorHandler.handleError(context, e)` decodes `List<int>` bodies (from `ResponseType.bytes` downloads), then String, then Map. It appends each validation error as a `• bullet` if it isn't already in the message, falls back to `errors.no_connection` when there is no response, and shows a red SnackBar.
  - It is used in 9 places. Six screens (register and 5 forms) duplicate a variant inline with hardcoded English fallbacks.

### Local storage
- `shared_preferences` is used directly everywhere (15 `getInstance()` calls).
- Keys: `token`, `refreshToken`, `name`, `role`, `selectedStationCode`, `selectedStationName`, `selectedCarrier`, `selectedCarrierId`, `selectedDistributor`, `selectedDistributorId`.
- No wrapper and no key constants. Tokens are not in secure storage. Logout uses `prefs.clear()`.

### Localization (+RTL)
- easy_localization 3.0.8. `supportedLocales: [en, ar]`, `startLocale: ar`, `fallbackLocale: en`, path `assets/translations`.
- The JSON files are nested by screen (`login`, `errors`, `nav`, `dashboard`, `settings`, `tasks`, `archive`, `reportsPage`, `reportTypes`, `form`, `maintenance`, `history`, `auth`, `quality`, …). Both files have 444 leaf keys, in sync.
- 257 `.tr()` calls. Language toggles in login and settings via `context.setLocale`.
- `main_screen.dart` keys each tab page with `ValueKey('home_$localeCode')` to force a rebuild on locale change (a workaround).
- Backend enum values become keys dynamically (`'tasks.${value.toLowerCase()}'.tr()`, `'maintenance.$option'.tr()`).
- **RTL:** 0 Directional widgets and 33 left/right usages. Some are flipped by hand with `isRtl ? … : …` (login). Most `EdgeInsets.only(right: 10)` and `Positioned(right: -5)` in the photo rows are not flipped. The dashboard header is forced to `TextDirection.ltr`.
- About 20 hardcoded user-facing English strings remain (see SMELLS).

### Theming
- `ThemeData(primaryColor: Color(0xFF003366), fontFamily: 'Cairo')` inline in `main.dart`. No colorScheme, no component themes, no dark theme.
- `AppColors` has 4 constants.
- Styling is all inline: 555 `Colors.*` usages, ad-hoc `TextStyle`s, and repeated `OutlineInputBorder(borderRadius 10/16, grey.shade200)` decorations.
- `fontFamily: 'Tajawal'` appears in 21 places and `'Cairo'` once, but no fonts are declared in pubspec and there is no google_fonts, so both silently fall back to the system font.
- Uses the modern `withValues(alpha:)` (43 uses, 0 `withOpacity`).

### Responsive / text scaling
- No helper and no screenutil. Some fixed heights (`55`, `120`) and `MediaQuery.size.height * 0.48 / 0.7 / 0.85`.
- `FittedBox(scaleDown)` and `maxLines/ellipsis` are used defensively in the quality form.
- No text-scale clamp.

### Env / flavors
- `AppConfig.baseUrl` is a hardcoded constant, with dev/local alternates left as comments.
- No flavors and no `--dart-define`. A `.env` exists (git-ignored) but no package reads it.
- Android signing reads `MYAPP_*` from `android/gradle.properties` via `properties[...]`.
- CI: `.github/workflows/android.yml` builds a release APK on push/PR to main and decodes the keystore from a secret.

### Logging / analytics / crash / push / payments
- One `print()`. No analytics, crash reporting, push or payments.

### Permissions
- No permission_handler; image_picker requests access implicitly.
- Android manifest: only `INTERNET`, plus `networkSecurityConfig` that permits cleartext for one domain.
- iOS `Info.plist` has **no** `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription`, so iOS will crash when the camera or gallery opens.

### Deep links
- None. The reset-password flow asks the user to type the emailed token by hand.

## 4. Services catalog

| File | Purpose | Public methods | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/network/api_client.dart — `ApiClient` | Dio + auth header + refresh + forced logout + error message extraction | `ApiClient(BuildContext)`, field `dio` | dio, shared_preferences, easy_localization, AppConfig, AppColors, Navigator | Semi (pattern generic, impl app-specific) |
| lib/core/utils/error_handler.dart — `ExceptionResponse` | Backend error DTO | `fromJson`, `displayMessage` | easy_localization | Generic for a `{code,message,details,errors}` backend |
| lib/core/utils/error_handler.dart — `GlobalErrorHandler` | Error → localized SnackBar | `static handleError(BuildContext, Object)` | dio, easy_localization, AppColors | Mostly generic |
| lib/core/constants/app_config.dart — `AppConfig` | Base URL constant | `baseUrl` | — | Generic (placeholder) |
| lib/core/constants/app_colors.dart — `AppColors` | Palette | 4 static colors | — | App-specific values |
| lib/routes/app_routes.dart — `AppRoutes` | Named routes map | `static getRoutes()` | screens | App-specific |
| lib/features/auth/services/auth_service.dart — `AuthService` | Auth endpoints + persisting tokens/role/name | `login(workId, password) → role`, `forgetPassword`, `resetPassword(token, newPassword)`, `changePassword(old,new)`, `logout()` | ApiClient, shared_preferences | App-specific (shape reusable) |
| lib/features/dashboard/services/dashboard_service.dart — `DashboardService` | Station lookup + station dashboard | `getStationDashboard(code)`, `getStations()` | ApiClient, models | App-specific |
| lib/features/task/services/task_service.dart — `TaskService` | Submit form (multipart JSON + images), paged history, details | `submitTask({stationCode, taskTitle, formDataPayload, imagePaths})`, `getHistory(code, page, size)`, `getSubmissionDetails(id)`, `getTaskSpecificHistory(code, title, page, size)` | ApiClient, dio FormData | App-specific; multipart pattern generic |
| lib/features/reports/services/report_service.dart — `ReportService` | Download a PDF report and open it natively | `downloadAndOpenReport(type, yearMonth)` | ApiClient, path_provider, open_filex, shared_preferences | Pattern generic |
| lib/features/dashboard/models/station.dart — `Station` | Model | `fromJson` | — | App-specific |
| lib/features/dashboard/models/task_summary.dart — `TaskSummary` | Model | `fromJson` | — | App-specific |

## 5. Widgets catalog

There is no `widgets/` or `components/` folder. Every reusable candidate is a private builder inside a screen, and most are copy-pasted between forms.

| Path | Purpose | Constructor / params | Generic? |
|---|---|---|---|
| auth/screens/login_screen.dart `_TealIconBox` | Tinted rounded icon used as a TextField prefix | `icon` | y |
| task/screens/forms/general_maintenance_screen.dart `_buildSelectionGroup` | Row of selectable radio cards with a per-option color | `label, options, selectedValue, onSelect` | y (extract color resolver) |
| task/screens/forms/general_maintenance_screen.dart `_buildTextArea` | Multi-line counted text field with required validator | `controller, hint, isRequired` | y |
| task/screens/forms/{general_maintenance,cleaning,fuel_unloading,fuel_unloading_safety,periodic_inspection}_screen.dart `_buildSectionLabel`; auth/screens/register_screen.dart `_buildLabel` | Field label with red `*` | `text, isRequired` | y (6 copies) |
| task/screens/forms/{cleaning,fuel_unloading_safety}_form_screen.dart `_buildYesNoToggle`; fuel_unloading_form_screen.dart `_buildBooleanToggle`; periodic_inspection_screen.dart `_buildInspectionItem` | Yes/No two-option toggle bound to a `Map<String,bool?>` | `key` | y (4 variants) |
| task/screens/forms/fuel_unloading_form_screen.dart `_buildReadOnlyField`, `_buildTextField` | Read-only display field / standard text field | `value, icon` / `controller, …` | y |
| task/screens/forms/quality_management_report_screen.dart `_section` | Card-styled ExpansionTile section | `titleKey, icon, children` | y |
| task/screens/forms/quality_management_report_screen.dart `_removableCard`, `_addButton` | Dynamic repeating-item card with delete; dashed "add" button | `index, onRemove, title, children` / `labelKey, onTap` | y |
| task/screens/forms/quality_management_report_screen.dart `_chip`, `_miniToggle(For)`, `_statusRow`, `_boolRow(For)`, `_pressureSelector`, `_fireEquipmentCard` | Compact check/close chip toggles and domain rows | various | chip/toggle y; rest n |
| auth/screens/register_screen.dart `_buildTextField` | Filled TextFormField with prefix icon and default required validator | `controller, hint, icon, keyboardType, maxLength, validator` | y |
| home/screens/home_dashboard_screen.dart `_showStationSelector` | Searchable bottom-sheet list picker (keyboard-aware) | — (Station-typed) | y after generics |
| home/screens/home_dashboard_screen.dart `_buildSecureImage` | Auth-protected image via Dio bytes → `Image.memory` with loading/broken states | `filePath` | y (fix future caching) |
| home/screens/home_dashboard_screen.dart `_buildCategoryCard`, `_buildProfileRow`, `_showUserProfile` | Dashboard category tile with stats; icon/label/value row; profile dialog with FutureBuilder | various | profile row y; others n |
| archive/screens/archive_screen.dart `_showFullScreenImage` | Full-screen zoomable image dialog | `imageUrl, token` | y |
| archive/screens/archive_screen.dart `_buildDetailsSheet` | Renders an arbitrary form map as key/value rows + attachment grid | `details, token` | semi |
| settings/screens/change_password_dialog.dart `ChangePasswordDialog` | Old/new/confirm password AlertDialog with loading | none | semi (calls AuthService) |
| auth/screens/not_allowed_screen.dart `NotAllowedScreen` | Role-denied screen with logout | none | semi |
| Photo attachment tile + horizontal thumbnail list with remove (inline in 5 forms) | Camera capture + preview | — | y (5 copies) |

## 6. Packages (`pubspec.yaml` constraint → locked)

| Role | Package |
|---|---|
| State / DI / Routing | none (Flutter Navigator) |
| Network | dio ^5.9.2 → 5.10.0 |
| Storage | shared_preferences ^2.5.3 → 2.5.5 |
| L10n | easy_localization ^3.0.8 → 3.0.8; flutter_localizations (sdk); intl 0.20.2 (transitive, via easy_localization's DateFormat export) |
| UI | cupertino_icons ^1.0.8; month_picker_dialog ^6.7.2 |
| Media / files | image_picker ^1.2.1 → 1.2.3; path_provider ^2.1.6; open_filex ^4.7.0 |
| Utils | package_info_plus ^10.2.0 |
| Firebase | none |
| Dev | flutter_lints ^6.0.0; flutter_launcher_icons ^0.14.4; flutter_test |

Pubspec oddity: a stray `flutter_lints: ^5.0.0` sits inside the `flutter_launcher_icons:` config block (copy-paste). `fonts:` is commented out, though Cairo/Tajawal are referenced in code.

## 7. Quality notes

- **Null safety:** yes (Dart ^3.8.1). Many `!` and unchecked casts on dynamic JSON (`response['content']`, `item['submittedAt'].toString().substring(0,10)`, `token!`).
- **Lints:** `include: package:flutter_lints/flutter.yaml` with no custom rules.
- **Tests:** none; `test/` is empty.
- **Duplication:**
  - Inline DioException parsing in 6 screens.
  - Section label ×6, yes/no toggle ×4, photo picker + thumbnails ×5.
  - Filled-input decoration repeated in nearly every form.
  - Pagination via `NotificationListener` (`pixels == maxScrollExtent`) in 2 screens.
  - Status → color mapping in 3 screens.
- **God classes:** quality_management_report_screen.dart (1190 lines), home_dashboard_screen.dart (1027), task_history_screen.dart (869).
- **Lifecycle:** 32 `TextEditingController`s but only 2 `dispose()` overrides. `FutureBuilder(future: ApiClient(context).dio.get(...))` is created inside `build`, so it refetches on every rebuild. Errors are swallowed silently in archive/history pagination (`catch (e) { /* quietly */ }`).
- **Deprecated APIs:** none found (no `WillPopScope`, `textScaleFactor`, `MaterialStateProperty` or `withOpacity`). Material 3 tint is suppressed manually with `surfaceTintColor: Colors.transparent`.
- **Hardcoded strings:** `'Failed to load profile'`, `'Phone'`, `'Identity'`, `'No tasks available'`, `'Select Rating'`, `'General Appearance'`, `'Safety & Security'`, `'Invalid email format'`, a Saudi-phone validator message, `'Error: ${e}'`, and 18 English error fallbacks.
- **Security / config:**
  - Tokens are stored in plain SharedPreferences.
  - Cleartext traffic is permitted for one domain (`network_security_config.xml`).
  - Release signing values are committed in `android/gradle.properties`, which is tracked by git. Keystore files are present locally but git-ignored.
  - The CI workflow appends the same keys again from secrets.
- **Platform:** iOS lacks camera/photo usage strings. The Android package uses the default `com.example.app`-style path. Many platform files (icons, gradle, manifest, Xcode project) have uncommitted changes.
- **Verdict for the template:** low reuse value overall. The ideas worth harvesting:
  - `GlobalErrorHandler`'s byte/String/Map body decoding and validation-bullet merging.
  - The multipart JSON-part pattern.
  - Download-and-open for files.
  - Translate-or-humanize key formatting.
  - Lazy tab activation.
  - The CI keystore-from-secret workflow.

  Do not copy `ApiClient` as-is: it depends on BuildContext, logs out on any 404, leaves requests hanging, and has no refresh lock.
