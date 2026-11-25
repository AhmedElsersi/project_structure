# project_structure

A reusable **Flutter starter template**, extracted from twelve production apps, plus the
documentation, rules and Claude Code commands to start new projects from it and keep them
consistent.

- `flutter_template/` is a runnable app (package `app_template`, Flutter 3.44 / Dart 3.12). It
  builds, analyses and tests with **no backend and no accounts**: a mock backend serves the sample
  feature.
- `docs/` explains what is in the template, how it fits together, and why each piece was chosen.
- `CLAUDE.md` is the rule set that Claude Code enforces in every project made from the template.
- `.claude/commands/` holds `/new-project` and `/new-feature`.

## What's inside

```
project_structure/
├── README.md                     this file
├── CLAUDE.md                     rules for AI agents, copied into every new project
├── .claude/commands/
│   ├── new-project.md            /new-project <folder> <package> "<Name>" <app.id>
│   └── new-feature.md            /new-feature <name> [with use cases]
├── docs/
│   ├── ARCHITECTURE.md           layers, data flow, state, startup, routing, session, DI (Mermaid diagrams)
│   ├── FOLDER_STRUCTURE.md       annotated tree, what goes where, naming rules
│   ├── SERVICES.md               every core service: API, usage, sources; opt-in recipes (Crashlytics, FCM, IAP, maps)
│   ├── WIDGETS.md                every shared widget and screen: params, usage, sources
│   ├── PACKAGES.md               every dependency, the rejected ones, the opt-in ones
│   ├── CONVENTIONS.md            responsive, foldables, text scaling, RTL, l10n, theming, errors, env, testing, CI
│   ├── NEW_PROJECT_CHECKLIST.md  ordered steps from copy to store release
│   ├── COMPARISON.md             the comparison of the 12 apps and the approved decisions
│   ├── SOURCES.md                where every file came from (generated from the `// Source:` headers)
│   └── _analysis/                one report per source project (input to COMPARISON.md)
└── flutter_template/
    ├── lib/core/                 infrastructure: ApiClient, Result/Failure, cubit bases, storage, session,
    │                             theme, responsive, l10n, services (connectivity, push, permissions, ...)
    ├── lib/shared/               ~40 widgets and app-level screens
    ├── lib/features/sample_feature/   "items": paginated list + search, details (AdaptiveTwoPane),
    │                                  create form with 422 field errors, mock backend
    ├── test/                     unit, widget, layout-matrix and policy tests
    ├── tool/                     create_feature, rename_app, check_translations, json_credential, gen_locale_keys
    └── .github/workflows/ci.yml  format, locale keys, translations, analyze --fatal-infos, test
```

## How it was built

1. **Phase 1 — analysis.** Each of the 12 in-scope Flutter apps was read and reported in
   `docs/_analysis/<slug>.md`: baytna, brgr, tebbr, markspulse, lexa-control, lexa-student,
   chinaparts-customer, chinaparts-seller, corsa-customer, corsa-driver, instaops and petrobe. The
   reports cover architecture, infrastructure, services, widgets, packages and quality notes.
2. **Phase 2 — comparison.** [docs/COMPARISON.md](docs/COMPARISON.md) puts them side by side,
   picks the best version of every infrastructure piece (K1–K41) and widget type (31), lists what
   was dropped (D1–D18), and records the approved decisions (§9): `shortestSide` breakpoints,
   sealed `Result`, no screenutil, damped text scale 1.0–1.3, Arabic first with English fallback,
   and opt-in Firebase.
3. **Phase 3 — template.** The chosen pieces were merged into `flutter_template`, with generic
   names, no secrets, client names, brands or real domains, and current Flutter APIs. Every file
   starts with `// Source:` / `// Merged:` lines naming the project slug and path it came from
   ([docs/SOURCES.md](docs/SOURCES.md)).

## Quick start

```bash
# 1. Copy the template (without build output, local config or Pods)
rsync -a --exclude build --exclude .dart_tool --exclude .env --exclude 'ios/Pods' \
  flutter_template/ ../my_app/
cp CLAUDE.md ../my_app/
cd ../my_app

# 2. Rename package, display name and application id
dart run tool/rename_app.dart --package my_app --name "My App" --id com.example.myapp --dry-run
dart run tool/rename_app.dart --package my_app --name "My App" --id com.example.myapp

# 3. Environment (BASE_URL empty = built-in mock backend)
cp .env.example .env

# 4. Run
flutter pub get
flutter run --dart-define-from-file=.env
```

Then work through [docs/NEW_PROJECT_CHECKLIST.md](docs/NEW_PROJECT_CHECKLIST.md): brand colours and
font, Arabic app name, icons and splash, signing, permissions, flavors, store listing, CI secrets,
replacing the sample feature, and the opt-in modules.

The gate every change must pass (also run in CI):

```bash
./tool/gen_locale_keys.sh && dart run tool/check_translations.dart && \
dart format --output=none --set-exit-if-changed lib test tool && \
flutter analyze --fatal-infos --fatal-warnings && flutter test
```

## Claude Code commands

Run Claude Code from this folder (or copy `.claude/commands/` into `~/.claude/commands/` to have
them everywhere):

| Command | Does |
|---|---|
| `/new-project <target_folder> <dart_package> "<Display Name>" <application.id>` | Copies `flutter_template` (without build/, .dart_tool/, .env, ios/Pods), runs `rename_app.dart`, copies `CLAUDE.md` and the docs, creates `.env`, sets brand colour, font and Arabic name, optionally sets up icons/splash, runs `git init` (no commit), then `pub get`, locale keys, analyze and test, and walks the checklist |
| `/new-feature <name> [with use cases]` | Runs `tool/create_feature.dart`, implements entity → model → data source → mock API → repository → (use case) → cubit → screens following the items pattern, adds ar + en translations, wires `main.dart` / `app_router.dart`, writes repository, cubit and layout-matrix tests, and runs the full gate |

## Documentation map

| Question | Read |
|---|---|
| How is the app put together? | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Where does this file go? What do I name it? | [docs/FOLDER_STRUCTURE.md](docs/FOLDER_STRUCTURE.md) |
| Which service or helper exists, and how do I call it? | [docs/SERVICES.md](docs/SERVICES.md) |
| Which widget should I use? | [docs/WIDGETS.md](docs/WIDGETS.md) |
| Why this package, and why not that one? | [docs/PACKAGES.md](docs/PACKAGES.md) |
| What are the rules (responsive, RTL, text scale, l10n, theming, env, tests)? | [docs/CONVENTIONS.md](docs/CONVENTIONS.md), condensed in [CLAUDE.md](CLAUDE.md) |
| How do I start a new app? | [docs/NEW_PROJECT_CHECKLIST.md](docs/NEW_PROJECT_CHECKLIST.md) |
| Why was X chosen over Y? Which app did it come from? | [docs/COMPARISON.md](docs/COMPARISON.md), [docs/SOURCES.md](docs/SOURCES.md) |

## What was intentionally NOT included

| Not included | Why | Instead |
|---|---|---|
| Firebase (core, Crashlytics, Messaging), push and crash reporting as code | The template must build, analyse and test with zero accounts (decision C7) | Interfaces with no-op/console implementations (`ErrorReporter`, `PushService`) plus copy-paste recipes in [SERVICES.md](docs/SERVICES.md#optional-recipes) |
| In-app purchases, maps, location | Business-specific, and they need store/API keys | [IAP](docs/SERVICES.md#in-app-purchases-iap) and [maps/location](docs/SERVICES.md#maps-and-location) recipes |
| `flutter_screenutil` | `.sp` stacks with the system text scale, and pixel-scaling a phone design doesn't make it work on tablets or foldables (decision C2) | Tokens, `shortestSide` form factors, `LayoutBuilder` grids, hinge-aware panes, the damped text scale |
| `dartz` | Unmaintained; a whole FP library for one type (decision C1) | Sealed `Result<T>` with the same `fold` order |
| `hydrated_bloc`, overlay toasts, a second base cubit, custom app bars, `DynamicDropdownFormField` | Dead code or known bugs in the source apps (D1–D5, D13) | `KeyValueStore`, `AppSnackBar`, one `BaseCubit`, themed `AppBar`, `AppDropdown` |
| App-specific features (auth screens, geofencing, sockets, PDF/Excel export, video, QR, white-label palettes...) | Business logic, not infrastructure (D15) | `SessionCubit` + `RedirectConfig` are ready for an auth feature; build features with `/new-feature` |
| A React or Laravel template, a Firebase Functions template | No React or Laravel project was in scope. The Functions template wasn't requested (COMPARISON §7, §9) | None |
| Secrets, base URLs, bundle ids, brand colours, logos, client or person names from the source apps | Never copied | Placeholders: `AppName`, `com.example.app`, `api.example.com`, `{{BRAND_PRIMARY}}`, `{{FONT_FAMILY}}`, `{{APP_LOGO}}` |

## Keeping the docs honest

Code headers point at doc anchors (`// See docs/SERVICES.md#apiclient`). After editing headings or
headers, check that every anchor still resolves:

```bash
python3 - <<'EOF'
import pathlib, re
root = pathlib.Path('.')
def slug(text):
    return re.sub(r'[^\w\- ]', '', text.strip().lower()).replace(' ', '-')
anchors = {}
for md in (root / 'docs').glob('*.md'):
    body = re.sub(r'```.*?```', '', md.read_text(), flags=re.S)  # ignore '#' inside code blocks
    anchors[md.name] = {slug(h) for h in re.findall(r'^#{1,6}\s+(.+)$', body, flags=re.M)}
missing = [
    f'{path}: docs/{doc}#{anchor}'
    for path in (root / 'flutter_template').rglob('*.dart')
    for doc, anchor in re.findall(r'docs/([A-Z_]+\.md)#([a-z0-9_-]+)', path.read_text())
    if anchor not in anchors.get(doc, set())
]
print('\n'.join(missing) or 'All doc anchors resolve.')
EOF
```
