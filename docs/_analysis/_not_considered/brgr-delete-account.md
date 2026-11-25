# brgr-delete-account — analysis report (short)

## Summary for comparison

```
PROJECT: brgr-delete-account | path: Datum/brgr delete account | stack: Flutter web, Dart >=3.0.0 <4.0.0, flutter >=3.10.0 | last commit: 2026-03-26 | source files: 1
ARCH: single-file page — lib/main.dart (MaterialApp → DeleteAccountPage StatefulWidget + private sub-widgets)
STATE: setState — none
DI: none — none
ROUTING: Navigator (single `home:` page) — lib/main.dart — guards? n, deep links? n
NETWORK: none (mailto: via url_launcher) — interceptors: none | token refresh: n | retry: n | error mapping: try/catch → inline error text | lib/main.dart
RESULT_TYPE: exceptions (try/catch) — none
STORAGE: none — none
L10N: none — en only, hardcoded — hardcoded UI strings: many (all)
RTL: Directional=0 vs LeftRight=0
THEME: lib/main.dart (inline ThemeData, ColorScheme.dark) — dark mode y (dark only) | component themes n | colors class AppColors (local copy of brgr palette) | text styles none (inline GoogleFonts) | fonts: google_fonts DM Sans + Syne (runtime fetch)
RESPONSIVE: none (ConstrainedBox maxWidth 520, centered) — breakpoints: none
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constant (support email const in lib/main.dart)
LOGGING: none
ANALYTICS/CRASH: none
PUSH: none
PAYMENTS/IAP: none
PERMISSIONS: none
DEEP_LINKS: none
MEDIA/FILES: url_launcher (mailto), Image.asset logo
TESTS: 1 — default counter smoke test (broken)
LINTS: flutter_lints/flutter.yaml, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/main.dart — self-contained "request account deletion" web page that opens a pre-filled mailto: — quality 3 — coupling: low (brand colors, logo, support email const)
GENERIC_WIDGETS (every reusable widget):
- lib/main.dart (_FormView, _StyledDropdown, _InfoBox, _SuccessView, _TopBar, _Footer) — private form/info/success sections — email/reason/comments/confirm, onSubmit — quality 3 — generic? y (as a template page, not as library widgets)
NOTABLE_IDEAS: store-compliance account-deletion page with no backend: email + reason + comments + "I understand" checkbox gate → mailto: with encoded subject/body; compiled web output is committed in docs/ (GitHub-Pages-style hosting); max-width 520 centered layout
SMELLS: everything in one 708-line file; hardcoded English strings and colors; withOpacity x4 (deprecated); Text widgets with inline GoogleFonts styles instead of a TextTheme; email validation is just contains('@'); footer copyright year hardcoded; build output (docs/) committed to the repo; default counter widget test references UI that does not exist
```

## Notes

- **What it is:** a one-page Flutter **web** app, used as the "delete your account" URL that Google Play and the App Store require for the brgr app. It does not delete anything itself. The user enters an email, picks a reason, adds optional comments and ticks a confirmation box. The page then launches a `mailto:` link to the support address, with the subject and body pre-filled and URL-encoded. After that it shows a success card, or an inline error if no mail client opens.
- **Layout:** top bar (logo on a primary-colored chip), centered `ConstrainedBox(maxWidth: 520)` scroll view, and a footer. Dark palette copied from brgr's `AppColors` (bg/bg2/bg3/border/primary/red/green).
- **Hosting:** `docs/` contains a committed `flutter build web` output (`main.dart.js`, canvaskit, service worker), so it can be served directly as a static site. There are 5 commits, all on 2026-03-26.
- **Dependencies:** only `url_launcher` and `google_fonts`. `google_fonts` fetches fonts at runtime unless they are bundled.
- **Reusable for the template:** worth keeping as an optional `tools/account_deletion_page/` (or a static HTML equivalent). The parts to parameterize are the support email, app name, brand colors, logo, the deleted-data bullet list and the reasons list. Better still, add an `--dart-define`/config for those and real l10n (ar/en + RTL), since the main apps are Arabic-first.
- **Not reusable:** there is no infrastructure (no state management, DI, routing, theming system or networking). The private widgets are tied to this page.
- **Secrets:** none in source. The support email is a hardcoded constant in `lib/main.dart`; it is client contact data and is not reproduced here.
