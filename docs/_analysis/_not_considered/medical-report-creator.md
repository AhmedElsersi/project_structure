## Summary for comparison

```
PROJECT: medical-report-creator | path: My Apps/medical_report_creator | stack: Flutter, Dart SDK ^3.10.0 | last commit: no git, mtime 2026-07-02 | source files: 51 (lib) + 1 test + 1 tool script
ARCH: feature-first "clean-arch-lite" — features/<x>/{data/{data_sources,models},presentation/{managers,screens,widgets}}; no domain/repo layer in practice (cubit talks to core DatabaseHelper directly); large core/ starter kit
STATE: flutter_bloc 9 Cubit — ReportCubit with Equatable states Initial/Loading/Loaded/Error/OperationSuccess (lib/features/medical_reports/presentation/managers/report_cubit.dart); HomeCubit empty stub; no base cubit; hydrated_bloc storage initialised but no HydratedCubit
DI: get_it — lib/core/services/di_container.dart (DatabaseHelper lazySingleton, cubits registerFactory; global `talker` also lives here)
ROUTING: go_router 16 — lib/core/app_router/app_router.dart + app_routes_names.dart — TalkerRouteObserver, CustomTransitionPage fade on splash; no guards; deep links: none; most navigation is Navigator.push(MaterialPageRoute) (14 vs 1 context.go)
NETWORK: none (offline app) — talker_dio_logger declared but no dio | interceptors: none | token refresh: n | retry: n | error mapping: catch-all -> ReportError('...: $e') string
RESULT_TYPE: exceptions caught in cubit -> error state string; Failure hierarchy exists but unused — lib/core/utilities/failures/failure.dart (+ error_details_model.dart)
STORAGE: sqflite lib/core/services/database_helper.dart (sections as JSON column); files lib/core/services/file_storage_helper.dart; hydrated_bloc (HydratedStorage in temp dir, unused)
L10N: none wired — assets/translations/{en,ar}.json exist but no localization package/delegates; app forced LTR via Directionality in main.dart — hardcoded UI strings: many (English; Arabic literals in date_picker_text_form_field.dart)
RTL: Directional=2 vs LeftRight=13
THEME: none — MaterialApp.router has no theme/darkTheme (default M3) | dark mode n | component themes in ThemeData n | colors class lib/core/utilities/constants/colors.dart (AppColors + AppGradients; features ignore it and hardcode teal 0xFF0F766E) | text styles class: none | fonts: default
RESPONSIVE: flutter_screenutil (design size 393x852, minTextAdapt, splitScreenMode) — used in core widgets, ~1 use in features — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: none (no dotenv/dart-define/flavors)
LOGGING: talker_flutter (only TalkerRouteObserver; global Talker in di_container.dart) + print-based AppBlocObserver (lib/core/services/bloc_observer.dart)
ANALYTICS/CRASH: none
PUSH: none
PAYMENTS/IAP: none
PERMISSIONS: permission_handler 12 — Permission.storage in lib/core/services/file_storage_helper.dart (manifest WRITE/READ_EXTERNAL_STORAGE + requestLegacyExternalStorage)
DEEP_LINKS: none
MEDIA/FILES: pdf + printing (generate/preview/share/print), open_filex, path_provider, flutter_native_splash, flutter_launcher_icons; Image.asset/file/network via ImageViewerWidget (no caching)
TESTS: 1 — default counter smoke test (fails; app has no counter)
LINTS: flutter_lints ^6.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/services/toast_manager.dart + lib/core/utilities/widgets/toasts/animated_custom_toast.dart — overlay toast (success/failure/warning) with slide+fade, context.showToast() extension, optional alignment — quality 3 — coupling: low (AppColors) — bug: delayed remove of an old toast can kill a newer one
- lib/core/services/debounce.dart — Timer-based Debounce(run/cancel) — quality 4 — coupling: none
- lib/core/utilities/widgets/buttons/app_default_button.dart — button that morphs into circular loader (AnimatedContainer + AnimatedSwitcher) — quality 3 — coupling: low (AppColors, screenutil; InkWell without Material, svgIconPath unused)
- lib/core/utilities/widgets/shared/widgets/image_Widget.dart — ImageViewerWidget: asset/file/network chosen by path prefix, radius, remove button, stacked badge (AlignmentDirectional) — quality 3 — coupling: low (no cache/error/loading builders)
- lib/core/utilities/failures/failure.dart — Failure hierarchy with HTTP codes + field ErrorDetail list — quality 3 — coupling: none (CacheFailure drops its message; never used)
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart — read-only field opening bottom-sheet list picker — quality 3 — coupling: low
- lib/core/services/input_formatters.dart — AppInputFormatters (alpha/num/alnum/decimal/no-whitespace/length) + image-extension check — quality 3 — coupling: none
- lib/core/extensions/context_extensions.dart — context.theme/textTheme/colorScheme/isAr — quality 3 — coupling: none
- lib/core/services/di_container.dart — get_it setup split into _initCubits — quality 2 — coupling: high (async fn not awaited)
- lib/core/services/database_helper.dart — sqflite singleton, single table, JSON column, onUpgrade stub — quality 3 — coupling: high
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart — titled TextFormField wrapper (~25 params, tap-outside unfocus) — quality 2 — coupling: low — BUG: default validator always returns an error
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart — generic <T> anchored showMenu dropdown with optional search — quality 2 — coupling: low (search never rebuilds menu; hardcoded always-failing validator)
- lib/core/services/pdf_color.dart — hexToPdfColor() — quality 3 — coupling: none
- lib/core/services/language_flags_service.dart — locale -> flag emoji — quality 3 — coupling: none
- tools/create_feature.dart — CLI feature scaffolder (dirs + data source/repo stubs) — quality 2 — coupling: medium (imports core/base_architecture/... which does not exist here; copied from another project)
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/buttons/app_default_button.dart AppDefaultButton — primary button w/ loading morph — text, onTap, child, isLoading, enabled, backgroundColor, textColor, borderColor, radius, height, width, margin, padding, loadingColor, textStyle — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart AppIconButton — square icon button over AppDefaultButton — child, onTap, height, width, radius, backgroundColor, isLoading — quality 3 — generic? y
- lib/core/utilities/widgets/buttons/app_icon_button.dart AppBackButton — RTL-aware back arrow (context.isAr) — onTap — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart AppTextFormField — titled text field — title, controller, hintText, validator, keyboardType, inputFormatters, prefix/suffixIcon, readOnly, obscureText, maxLines, focusNode, onTap/onChanged/onSaved — quality 2 — generic? y (fix default validator)
- lib/core/utilities/widgets/text_form_fields/date_picker_text_form_field.dart DateTimeTextFormField + pickDate()/pickTime() — date/time/month-year picker field — controller, title, hintText, isDate, readOnly, pickDay — quality 2 — generic? partly (Arabic literals, month picker lacks setState)
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart DropdownTextFormField — bottom-sheet string picker — title, hintText, controller, items, validator, onChanged — quality 3 — generic? y
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart DynamicDropdownFormField<T> — anchored menu picker w/ search — controller, options, displayText, onOptionSelected, showSearch, widgetBuilder, hintText — quality 2 — generic? y
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart AnimatedCustomToast — animated overlay toast — message, state, duration, location — quality 3 — generic? y
- lib/core/utilities/widgets/toasts/custom_toast.dart CustomToast — static toast (unused duplicate) — message, state, duration — quality 2 — generic? y
- lib/core/utilities/widgets/shared/widgets/image_Widget.dart ImageViewerWidget — asset/file/network image — image, width, height, radius, borderRadius, fit, color, border, margin, onTap, onTapRemove, stackedWidget — quality 3 — generic? y
- lib/core/utilities/widgets/shared/screens/image_viewer.dart ImageViewerScreen — full-screen image with close — imagePath — quality 2 — generic? y (no zoom)
- lib/core/services/show_loading_dialog.dart showLoadingDialog() — blocking loader dialog — context, message, barrierDismissible — quality 2 — generic? y (no hide helper)
- lib/features/splash/presentation/screens/splash_screen.dart AnimatedImageViewer — opacity/scale/shake logo animation (unused) — image, imageHeight, imageWidth, radius — quality 2 — generic? y
- lib/features/medical_reports/presentation/widgets/bullet_field.dart BulletField — bullet text row w/ delete — initialValue, onChanged, onDeleted, isSubBullet — quality 3 — generic? partly
- lib/features/medical_reports/presentation/widgets/section_card.dart SectionCard / section_editor_list.dart SectionEditorList — recursive section/bullet editor — section(s), many callbacks — quality 2 — generic? n
- lib/features/medical_reports/presentation/widgets/report_form_header.dart ReportFormHeader, report_form_actions.dart ReportFormActions — form header / 4 action buttons — controllers + callbacks — quality 2 — generic? n
NOTABLE_IDEAS: tools/create_feature.dart CLI to scaffold a feature folder (worth reviving against the template's real base classes); barrel file lib/core/exports/core_exports.dart re-exporting material/go_router/screenutil/colors; ToastState enum + overlay ToastManager + BuildContext.showToast extension (toast_manager.dart); AppDefaultButton loading-morph animation; ImageViewerWidget picking asset/file/network from the path string (String.imageType extension); FlutterNativeSplash.preserve -> remove handoff to an animated in-app splash (main.dart + splash_screen.dart); recursive SectionModel (bullets + subSections) persisted as a JSON column, with copyWith deep copy for cancellable edits; PDF building with pw.PageTheme buildBackground for watermark + double border and a separate cover page (report_cubit.dart generatePdfBytes); AppRoutesNames constants class
SMELLS: core widget kit is almost entirely unused by features (features use raw Material widgets + hardcoded teal colors); AppTextFormField default `validator ?? (v) => "enter any data"` always fails and DynamicDropdownFormField hardcodes the same failing validator; Permission.storage requested on every loadReports()/save — permanently denied on Android 13+, so "Save PDF to device" breaks there (app-specific dir needs no permission); no ThemeData at all; hydrated_bloc initialised (in temp dir!) but no hydrated cubit; diContainerSetup() is async and not awaited; unused deps (animate_do, talker_dio_logger); ~260-line PDF builder lives inside ReportCubit (374-line file) (UI-in-state god class); print() in AppBlocObserver and FileStorageHelper; withOpacity x8 (colors.dart, dynamic_drop_down_text_field.dart, home_screen.dart); DropdownButtonFormField `value:` (deprecated -> initialValue) in report_form_header.dart; SectionModel extends Equatable but has mutable `title` and mutated lists; CacheFailure ignores message; empty price_converter.dart and empty MedicalReportsLocalDataSource stub; HomeCubit empty; route '/reports' maps to ReportFormScreen and 'selectLocation' constant has no route; ridiculous relative imports ('../../../../../../../../../../../../core/exports/...') in app_icon_button.dart / image_viewer.dart / splash_screen.dart; FocusScope.of(context) after await before mounted check (splash); listSync on file folder; doctor names + phone numbers hardcoded in lib/core/utilities/constants/constant_lists.dart (personal data in source); default counter test; app is the successor of pelvic-floor-rehab (same domain/template) and its date_formatter.dart is duplicated in gym-tracker
```

---

## 1. Architecture pattern

The project is feature-first and nominally "clean-architecture-lite".

- **Data flow:** `Screen` -> `ReportCubit` -> `DatabaseHelper` (in `core/services`) -> sqflite.
  - `ReportCubit` also does file I/O (`FileStorageHelper`), PDF generation (`pdf`/`printing`) and sharing.
  - No repository class and no domain layer.
  - `data/data_sources/medical_reports_local_data_source.dart` is an empty stub left by the scaffolder.
- **Models:** `Report` (Equatable, `toMap/fromMap/copyWith`, sections JSON-encoded), recursive `SectionModel` and `Doctor`.
- **Cubits:**
  - `ReportCubit` and `HomeCubit` are both provided at the root via `MultiBlocProvider`, using `diService<...>()` factories. `HomeCubit` is an unused stub with `lazy: false`.
  - States are an Equatable class hierarchy: `ReportInitial`, `ReportLoading`, `ReportLoaded(reports, pdfFileCount)`, `ReportError(message)` and `ReportOperationSuccess(message)`.
  - Screens use `BlocConsumer` to show snackbars on success/error.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                         # native splash preserve, HydratedStorage, DI, BlocObserver, status bar style, ScreenUtilInit(393x852), MultiBlocProvider, MaterialApp.router (forced LTR)
├── core/
│   ├── app_router/                   # app_router.dart (GoRouter + TalkerRouteObserver), app_routes_names.dart
│   ├── enums/                        # toast_state_enum.dart (part of toast_manager)
│   ├── exports/                      # core_exports.dart barrel (material, go_router, screenutil, colors)
│   ├── extensions/                   # context_extensions.dart, list_extensions.dart
│   ├── services/                     # bloc_observer, database_helper, debounce, di_container, file_storage_helper,
│   │                                 # input_formatters, language_flags_service, pdf_color, show_loading_dialog, toast_manager
│   └── utilities/
│       ├── constants/                # colors.dart (AppColors, AppGradients), constant_lists.dart (doctors, section template), images.dart
│       ├── converters/               # price_converter.dart (EMPTY)
│       ├── failures/                 # failure.dart, error_details_model.dart
│       ├── formatters/               # date_formatter.dart
│       └── widgets/
│           ├── buttons/              # app_default_button.dart, app_icon_button.dart (AppIconButton, AppBackButton)
│           ├── shared/               # screens/image_viewer.dart, widgets/image_Widget.dart
│           ├── text_form_fields/     # app_text_form_field, date_picker_text_form_field, dropdown_text_form_field, dynamic_drop_down_text_field
│           └── toasts/               # animated_custom_toast.dart, custom_toast.dart
└── features/
    ├── home/presentation/            # managers/home_cubit(+state, empty), screens/home_screen.dart (dashboard)
    ├── medical_reports/              # (representative)
    │   ├── data/
    │   │   ├── data_sources/         # medical_reports_local_data_source.dart (empty stub)
    │   │   └── models/               # doctor_model.dart, medical_report_model.dart, section_model.dart
    │   └── presentation/
    │       ├── managers/             # report_cubit.dart (CRUD + PDF + share + save), report_state.dart
    │       ├── screens/              # report_form_screen.dart (create/edit + PdfPreview route), reports_screen.dart (list, OpenFilex)
    │       └── widgets/              # bullet_field, report_form_actions, report_form_header, section_card, section_editor_list
    └── splash/presentation/screens/  # splash_screen.dart (+ unused AnimatedImageViewer)
tools/create_feature.dart             # feature scaffolder CLI (outside lib)
assets/translations/{en,ar}.json      # unused translation files
```

## 3. Infrastructure

### State management
- `flutter_bloc ^9.1.1` with `equatable`. No base cubit or request wrapper. Each method follows try/catch -> `emit(ReportError('Failed to ...: $e'))`.
- `hydrated_bloc ^10.1.1` storage is built in `main.dart` (with `getTemporaryDirectory()`, which is wrong for persistence), but no cubit uses `HydratedMixin`.
- `AppBlocObserver` logs every lifecycle event with `print` and emojis.

### DI
- `get_it ^8.0.3`, `lib/core/services/di_container.dart`: `diService = GetIt.instance`. `DatabaseHelper` is a lazySingleton and the cubits are factories.
- It also defines a global `talker = Talker()`.
- `diContainerSetup()` is `Future<void>` but is called without `await` (it works only because the body is synchronous).

### Routing
- `go_router ^16.2.1`, `lib/core/app_router/app_router.dart`, with the paths centralised in `AppRoutesNames`.
- The splash route uses a `CustomTransitionPage` fade. The `imageViewer` route passes its path via `state.extra as String`.
- `TalkerRouteObserver(talker)` is attached.
- No guards or error builder.
- Most real navigation uses `Navigator.of(context).push(MaterialPageRoute(...))` (home -> form/list, list -> form, form -> PdfPreview), so the router is underused.

### Networking
- None. `talker_dio_logger` is declared without `dio`.

### Local storage
- `DatabaseHelper` is a singleton using `getDatabasesPath()/medical_reports.db`, version 1, with one `reports` table. Sections are stored as a JSON string, bullets inside are joined with `'|||'`, and the `onUpgrade` body is a commented example. CRUD uses `ConflictAlgorithm.replace` on insert.
- `FileStorageHelper` (static):
  - It requests `Permission.storage` before every call. On Android it then uses `getExternalStorageDirectory()/reports_adaa`, on iOS the documents dir, and on other platforms it returns null.
  - On Android 13+ the storage permission is always denied, so saving and counting PDFs fail.
  - It uses `print` and `listSync`.

### Localization / RTL
- No l10n package and no delegates. `en.json`/`ar.json` exist (validation messages, app name) but nothing loads them.
- `MaterialApp.builder` wraps everything in `Directionality(textDirection: TextDirection.ltr)`.
- Some core widgets are RTL-aware: `AppBackButton` flips its arrow via `context.isAr`, `ImageViewerWidget` uses `AlignmentDirectional.bottomEnd`, and `DateTimeTextFormField` uses `EdgeInsetsDirectional`.
- Directional=2 vs Left/Right=13. Four of the Left/Right hits are `pw.EdgeInsets` in the PDF code.

### Theming
- No `ThemeData`, so the default Material 3 seed is used.
- `AppColors` (brand dark blue, accent red, neutrals, status colors, button state colors, gradients, a `secondary0..10` scale) and `AppGradients` exist but are used only by the core widgets.
- Feature screens hardcode `Color(0xFF0F766E)` teal, `0xFF1D4ED8`, `0xFFD97706` and others (about 85 color literals).
- No dark mode and no text-style class.

### Responsive helpers
- `ScreenUtilInit(designSize: Size(393, 852), minTextAdapt: true, splitScreenMode: true)`. Used in the core widgets; features mostly use raw doubles.

### Text scaling
- None.

### Env / flavors
- None.

### Logging
- `talker_flutter ^5.0.0`: only the route observer. Otherwise `print`.

### Analytics / crash / push / IAP
- None.

### Permissions
- `permission_handler ^12.0.1`, storage only (see above).

### Deep links
- None.

## 4. Services catalog

| File | Purpose | Public API | Deps | Generic? |
|---|---|---|---|---|
| lib/core/services/di_container.dart | get_it setup | `diService`, `talker`, `diContainerSetup()` | get_it, talker_flutter | app-specific |
| lib/core/services/bloc_observer.dart `AppBlocObserver` | bloc logging | onCreate/onEvent/onChange/onTransition/onError/onClose | flutter_bloc | generic (swap print for logger) |
| lib/core/services/database_helper.dart `DatabaseHelper` | sqflite gateway | `database`, `insertReport`, `getReports`, `getReportById`, `updateReport`, `deleteReport` | sqflite, path | app-specific |
| lib/core/services/file_storage_helper.dart `FileStorageHelper` | app folder for PDFs | `getAppSpecificDownloadDirPath()`, `getPdfFilesInAdaaFolder()` | path_provider, permission_handler, path | semi-generic (buggy) |
| lib/core/services/toast_manager.dart `ToastManager` + `CustomToastExtension` | overlay toasts | `ToastManager.showToast(context, message, state, location, duration)`, `context.showToast(...)` | AnimatedCustomToast | generic |
| lib/core/services/debounce.dart `Debounce` | debouncer | `run(cb)`, `cancel()` | dart:async | generic |
| lib/core/services/input_formatters.dart `AppInputFormatters` | input formatters | `onlyAlphabetsFormatter`, `onlyNumbersFormatter`, `alphanumericFormatter`, `decimalNumberFormatter`, `noWhitespaceFormatter`, `numberCountsFormatter(n)`, `isSupportedImageFormat(path)` | flutter/services | generic |
| lib/core/services/language_flags_service.dart `LanguageService` | flag emoji | `getFlagEmoji(locale)` | — | generic |
| lib/core/services/pdf_color.dart | hex -> PdfColor | `hexToPdfColor(hex)` | pdf | generic |
| lib/core/services/show_loading_dialog.dart | loader dialog | `showLoadingDialog(context, message, barrierDismissible)` | material | generic |
| lib/core/extensions/context_extensions.dart | context sugar | `theme`, `textTheme`, `colorScheme`, `isAr` | material | generic |
| lib/core/extensions/list_extensions.dart | list helper | `isNullOrEmpty()` | — | generic |
| lib/core/utilities/formatters/date_formatter.dart `DateFormatter` | date formatting | `formatDateString(str, fmt, locale)`, `formatDate(dt, fmt, locale)`, `isMorning(dt)` | intl | generic |
| lib/core/utilities/failures/failure.dart | Failure hierarchy | `Failure(message, code, errors)`, BadRequest/Unauthorized/Forbidden/NotFound/Server/Network/Timeout/Cache/Validation/Unknown | error_details_model | generic |
| lib/core/utilities/failures/error_details_model.dart `ErrorDetail` | field errors | `fromJson(field, list)` | — | generic |
| lib/core/utilities/constants/colors.dart `AppColors`, `AppGradients` | palette | consts | material | app-specific |
| lib/core/utilities/constants/images.dart `AppImages` | asset paths | `logo`, `image(...)` | widgets | generic pattern |
| lib/core/utilities/constants/constant_lists.dart `ConstantLists` | doctors + section template | `doctors`, `sections` | models | app-specific (contains personal data) |
| lib/core/app_router/app_routes_names.dart `AppRoutesNames` | route paths | consts | — | generic pattern |
| lib/core/exports/core_exports.dart | barrel export | — | material, go_router, screenutil | generic pattern |
| lib/features/medical_reports/presentation/managers/report_cubit.dart `ReportCubit` | CRUD + PDF + share | `loadReports`, `saveReport`, `deleteReport`, `generatePdfBytes`, `savePdfToDevice`, `sharePdf` | DatabaseHelper, FileStorageHelper, pdf, printing | app-specific |
| tools/create_feature.dart | scaffolder CLI | `dart run tools/create_feature.dart <name>` | dart:io | generic idea, broken imports |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/buttons/app_default_button.dart `AppDefaultButton` | primary button, loading morph to circle | onTap, text, textStyle, child, height, width, radius, margin, padding, isLoading, backgroundColor, textColor, enabled, svgIconPath (unused), borderColor, loadingColor | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart `AppIconButton` | icon button | onTap, child, height, width, radius, backgroundColor, padding, margin, isLoading, loadingColor | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart `AppBackButton` | RTL-aware back button | onTap | y |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart `AppTextFormField` | titled text field | title, controller, hintText, onTap, onChanged, enabled, readOnly, obscureText, keyboardType, validator, inputFormatters, icon (unused), prefixIcon, suffixIcon, titleStyle, textStyle, hintTextStyle, maxLength, maxLines, bottomMargin (unused), prefix/suffixIconConstraints, focusNode, textAlign, onSaved, onFieldSubmitted, onEditingComplete | y (validator bug) |
| lib/core/utilities/widgets/text_form_fields/date_picker_text_form_field.dart `DateTimeTextFormField`, `pickDate`, `pickTime` | date/time picker field; month-year dialog | controller, title, hintText, isDate, readOnly, pickDay | partly |
| lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart `DropdownTextFormField` | bottom-sheet picker field | title, hintText, controller, items, validator, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart `DynamicDropdownFormField<T>` | anchored popup picker with search | controller, options, displayText, title, onOptionSelected, hintText, showSearch, widgetBuilder | y (buggy) |
| lib/core/utilities/widgets/toasts/animated_custom_toast.dart `AnimatedCustomToast` | animated toast body | message, state, duration, location | y |
| lib/core/utilities/widgets/toasts/custom_toast.dart `CustomToast` | static toast body (unused) | message, state, duration | y |
| lib/core/utilities/widgets/shared/widgets/image_Widget.dart `ImageViewerWidget` | universal image | image, width, height, margin, onTap, onTapRemove, stackedWidget, radius, borderRadius, fit, color, border | y |
| lib/core/utilities/widgets/shared/screens/image_viewer.dart `ImageViewerScreen` | full-screen image | imagePath | y |
| lib/core/services/show_loading_dialog.dart `showLoadingDialog` | loader dialog | context, message, barrierDismissible | y |
| lib/features/splash/presentation/screens/splash_screen.dart `AnimatedImageViewer` | animated logo (unused) | image, imageHeight, imageWidth, radius | y |
| lib/features/medical_reports/presentation/widgets/bullet_field.dart `BulletField` | editable bullet row | initialValue, onChanged, onDeleted, isSubBullet | partly |
| lib/features/medical_reports/presentation/widgets/section_card.dart `SectionCard` | section editor card | section, onTitleChanged, onAddBullet, onBulletDeleted, onBulletChanged, onAddSubsection, onDeleteSection, isSubSection, children | n |
| lib/features/medical_reports/presentation/widgets/section_editor_list.dart `SectionEditorList` | recursive section list | sections, callbacks, parentSection | n |
| lib/features/medical_reports/presentation/widgets/report_form_header.dart `ReportFormHeader` | doctor/patient/date header | selectedDoctor, controllers, genderValue, selectedDate, callbacks | n |
| lib/features/medical_reports/presentation/widgets/report_form_actions.dart `ReportFormActions` | 4 action buttons w/ loading | isSaving, onSaveAndClose, onSharePdf, onSavePdfToDevice, onPreviewPdf | n |

## 6. Packages (`pubspec.yaml`)

- **State:** flutter_bloc ^9.1.1, hydrated_bloc ^10.1.1 (unused), equatable ^2.0.7
- **DI:** get_it ^8.0.3
- **Routing:** go_router ^16.2.1
- **Storage:** sqflite ^2.3.0, path ^1.8.3, path_provider ^2.1.5
- **L10n:** intl ^0.20.2 (no localization package)
- **UI:** flutter_screenutil ^5.9.3, flutter_animate ^4.5.2, animate_do ^4.2.0 (unused), flutter_native_splash ^2.4.3, flutter_launcher_icons ^0.14.4 (listed in dependencies, not dev), cupertino_icons ^1.0.8
- **Logging:** talker_flutter ^5.0.0, talker_dio_logger ^5.0.0 (unused, no dio)
- **PDF / files:** pdf ^3.10.0, printing ^5.10.0, open_filex ^4.3.2, permission_handler ^12.0.1
- **Dev:** flutter_test, flutter_lints ^6.0.0
- **Config:** `flutter_launcher_icons.yaml` still has template placeholder paths for web/windows/macos.

## 7. Quality notes

- **Null safety:** full. **Lints:** `flutter_lints` with no extra rules.
- **Tests:** only the default counter test, which would fail.
- **Validator bug:** `AppTextFormField`'s default validator returns `"enter any data"` for every value, so any form that relies on the default can never validate. `DynamicDropdownFormField` hardcodes the same validator.
- **Picker bugs:** the month-year picker dialog mutates locals without `StatefulBuilder`/`setState`, so the dropdowns do not visually update. The `showMenu` search updates the field widget's state, not the open menu route.
- **Toast bug:** `ToastManager` removes `_overlayEntry` after a fixed delay, so a second toast shown within that window is removed early.
- **Storage permission:** `Permission.storage` on Android 13+ is denied. Saving is broken there, and the prompt is re-requested on every list load.
- **Deprecated / dated APIs:** `withOpacity` (8 uses), `DropdownButtonFormField.value`, and `print` in production code.
- **Separation of concerns:** about 260 lines of PDF layout inside the cubit. Context is used across async gaps in places (splash `FocusScope.of(context)` before the `mounted` check; form `setState` after `await` without `mounted`).
- **Dead / unused code:** most of core/ (buttons, text fields, toasts, failures, debounce, formatters, LanguageService), `AnimatedImageViewer`, the empty `price_converter.dart`, the empty data-source stub, `HomeCubit`, the hydrated storage and two packages.
- **Personal data in source:** `lib/core/utilities/constants/constant_lists.dart` hardcodes real-looking doctor names and contact numbers (values intentionally not reproduced).
- **Lineage:** this app is the evolved version of `My Apps/pelvic_floor_rehab_app` (same report template and logo asset). The core kit appears to be copied from the user's common starter (same `DateFormatter` as gym-tracker; scaffolder references a `core/base_architecture` that exists in other projects).
