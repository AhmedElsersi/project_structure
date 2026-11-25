## Summary for comparison

```
PROJECT: pelvic-floor-rehab | path: My Apps/pelvic_floor_rehab_app | stack: Flutter, Dart SDK ^3.10.1 | last commit: no git, mtime 2025-12-05 | source files: 5 (lib) + 1 test
ARCH: layer-first prototype — lib/{models,pages,services,widgets} + 506-line main.dart holding the whole form screen
STATE: setState only (StatefulWidget HomePage in lib/main.dart)
DI: none
ROUTING: Navigator — MaterialApp(home:) + Navigator.push(MaterialPageRoute) to PdfViewerPage — no guards, no deep links
NETWORK: none | interceptors: none | token refresh: n | retry: n | error mapping: try/catch -> SnackBar('$e') | —
RESULT_TYPE: exceptions (try/catch in UI) — no Failure hierarchy
STORAGE: none (PDF written to app documents dir; no persistence of report data)
L10N: none — English only — hardcoded UI strings: many
RTL: Directional=0 vs LeftRight=1
THEME: inline ThemeData in lib/main.dart — dark mode n | component themes in ThemeData: appBar + inputDecoration + elevatedButton y | colors class: none | text styles class: none | fonts: default (legacy primarySwatch)
RESPONSIVE: none — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: none
LOGGING: print
ANALYTICS/CRASH: none
PUSH: none
PAYMENTS/IAP: none
PERMISSIONS: none
DEEP_LINKS: none
MEDIA/FILES: pdf + printing (PdfPreview, layoutPdf, sharePdf), path_provider, open_filex
TESTS: 1 — default counter smoke test (fails)
LINTS: flutter_lints ^6.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/pages/pdf_viewer_page.dart — PdfPreview page with print + share actions from in-memory bytes — quality 3 — coupling: none
- lib/widgets/bullet_point_editor.dart — dynamic list-of-strings editor (add/remove rows, emits trimmed non-empty list) — quality 3 — coupling: none
- lib/services/pdf_service.dart — static PDF builder (header w/ logo, Table.fromTextArray info block, section/sub-section titles, bullet lists) — quality 2 — coupling: high (hardcoded field list)
GENERIC_WIDGETS (every reusable widget):
- lib/widgets/bullet_point_editor.dart BulletPointEditor — editable bullet list — title, initialItems, onItemsChanged, prefix — quality 3 — generic? y
- lib/pages/pdf_viewer_page.dart PdfViewerPage — PDF preview/print/share screen — pdfBytes, reportName — quality 3 — generic? y
- lib/main.dart _buildToggleableSection (private method) — collapsible Card section — title, isVisible, onToggle, child — quality 2 — generic? y if extracted
NOTABLE_IDEAS: nothing new for a template beyond PdfViewerPage (PdfPreview + print/share actions) and BulletPointEditor; this is the earlier prototype of medical-report-creator (same clinical section template and logo asset), which supersedes it
SMELLS: god main.dart (506 lines, form + PDF save logic); ReportData is a mutable class with ~30 hardcoded List<String> fields (no serialization); section visibility toggles only affect the form, not the PDF; duplicated "copy controllers into model" block in _generateAndPreviewPdf/_generateAndDownloadPdf; BuildContext used after await without mounted checks; print() in production; legacy `Key? key` + `super(key: key)` constructors and public `_BulletPointEditorState createState()`; primarySwatch theming; same logo asset bundled twice (assets/ADAA_logo.png and assets/images/logo.png); default counter test
```

---

## 1. Architecture pattern
This is a single-screen prototype with a layer-first layout: `models/`, `pages/`, `services/` and `widgets/`. `HomePage` (in `main.dart`) is a `StatefulWidget` that owns the text controllers and a mutable `ReportData`. It builds the PDF through the static `PdfService.generateReport(data)`, then either pushes `PdfViewerPage` or writes the file to the documents dir and offers "Open" via `OpenFilex`. No state management, DI, routing package or persistence.

## 2. Folder tree (`lib/`)
```
lib/
├── main.dart                 # MyApp (ThemeData) + HomePage form (doctor/patient fields, toggleable section cards, preview/download)
├── models/report_data.dart   # mutable ReportData with ~30 List<String> section fields
├── pages/pdf_viewer_page.dart# PdfPreview + print/share actions
├── services/pdf_service.dart # static PDF builder (MultiPage A4)
└── widgets/bullet_point_editor.dart  # dynamic bullet list editor
```

## 3. Infrastructure
- **State:** setState only.
- **DI:** none.
- **Routing:** `Navigator.push`.
- **Network:** none.
- **Storage:** none. The PDF is saved to `getApplicationDocumentsDirectory()`.
- **L10n/RTL:** none.
- **Theme:** an inline `ThemeData` with `primarySwatch: Colors.blue`, plus `AppBarTheme`, `InputDecorationTheme` (outlined, radius 8) and `ElevatedButtonThemeData`. No dark mode.
- **Responsive / text scaling / env / analytics / push / IAP / permissions / deep links:** none.
- **Logging:** `print`.

## 4. Services catalog
| File | Purpose | Public API | Deps | Generic? |
|---|---|---|---|---|
| lib/services/pdf_service.dart `PdfService` | build report PDF | `static Future<Uint8List> generateReport(ReportData)` | pdf, rootBundle | app-specific |

## 5. Widgets catalog
| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/widgets/bullet_point_editor.dart `BulletPointEditor` | add/remove string rows, emits cleaned list | title, initialItems, onItemsChanged, prefix | y |
| lib/pages/pdf_viewer_page.dart `PdfViewerPage` | preview/print/share PDF | pdfBytes, reportName='Report' | y |
| lib/main.dart `_buildToggleableSection` (method) | collapsible card section | title, isVisible, onToggle, child | y (extract) |

## 6. Packages
- **PDF / files:** pdf ^3.10.8, printing ^5.12.0, path_provider ^2.1.3, open_filex ^4.3.2
- **UI:** cupertino_icons ^1.0.8
- **Dev:** flutter_test, flutter_lints ^6.0.0

## 7. Quality notes
- **Language / lints:** null safe. `flutter_lints` with no extra rules.
- **Tests:** only the default counter test, which fails.
- **Legacy patterns:** constructors use `Key? key` instead of `super.key`.
- **Missing mounted checks:** `ScaffoldMessenger.of(context)` and `Navigator.push` are called after `await` without a `mounted` check.
- **Partial dead UI:** the section-visibility flags never reach the PDF.
- **Superseded:** `My Apps/medical_report_creator` replaces this app (dynamic sections, SQLite, branded PDF). Do not use this project as a template source except for `PdfViewerPage` and `BulletPointEditor`.
