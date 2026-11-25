# dindex-quote — analysis report

## Summary for comparison

```
PROJECT: dindex-quote | path: D-index/dindex-quote (Flutter in app/, Cloud Functions in functions/) | stack: Flutter web-only, Dart sdk ">=3.8.0 <4.0.0" + Node 22 Cloud Functions (plain CommonJS JS, NOT TypeScript; firebase-functions 7.4 v2 onCall, firebase-admin 14.5) | last commit: no git, mtime 2026-10-25 | source files: 24 (18 Dart in app/lib incl. firebase_options.dart, 6 JS in functions/ incl. 1 test runner)
ARCH: layer-first, tiny (no clean-arch) — app/lib/{models, screens, services, widgets} + config.dart; screens call a static Api facade (and sometimes Firestore directly); all business logic lives server-side in functions/lib (engine/ai/stationery) behind callable functions
STATE: plain StatefulWidget + setState, StreamBuilder/FutureBuilder straight on Firebase streams — no base classes; stringly-typed status fields ('busy'|'ok'|'error')
DI: none — static singletons in Api (app/lib/services/api.dart); functions use a hand-rolled factory makeHandlers({db, auth, FieldValue, anthropic, aiModel, aiDailyLimit}) (functions/lib/handlers.js), wired in functions/index.js
ROUTING: Navigator 1.0 (MaterialPageRoute push/pushReplacement, 4 call sites) — app/lib/screens/auth_gate.dart (home) + app/lib/screens/home_shell.dart (IndexedStack + NavigationRail/Drawer) — guards: AuthGate role gate via custom claims, admin-only destinations filtered | deep links: none (hosting rewrites ** -> /index.html, URL never changes)
NETWORK: firebase (cloud_functions httpsCallable + cloud_firestore + firebase_auth) — interceptors: none | token refresh: n (SDK-managed; manual getIdToken(true) after role-claim change) | retry: n (only a review-screen autosave retry timer) | error mapping: FirebaseFunctionsException.code -> user-facing Arabic ApiError in Api._call/_messageFor; server AppError(code,msg) -> HttpsError in index.js wrap() | files: app/lib/services/api.dart, functions/index.js, functions/lib/handlers.js
RESULT_TYPE: exceptions — ApiError (app/lib/services/api.dart); server AppError (functions/lib/handlers.js); no Failure hierarchy
STORAGE: browser localStorage via package:web (form draft only) — app/lib/services/browser.dart; Firestore is the system of record
L10N: none (flutter_localizations Global* delegates only; locale fixed to ar, supported ar/en; option maps carry [ar, en] label pairs, en used only as tooltip) — default ar, no translations folder — hardcoded UI strings: many (~333 lines with Arabic literals, incl. error messages in api.dart)
RTL: Directional=10 vs LeftRight=0 (4 EdgeInsets.fromLTRB, all horizontally symmetric; 17 explicit TextDirection.ltr/rtl for emails/phones/English hints; web/index.html lang="ar" dir="rtl")
THEME: app/lib/config.dart buildTheme() — dark mode n | component themes y (appBar, card, inputDecoration, chip, filledButton; M3, ColorScheme.fromSeed) | colors: top-level const kPurple/kNavy/kLilac/kPaper/kRed... in config.dart (no class) | text styles: none (inline TextStyle everywhere) | fonts: Cairo Regular/Bold (assets/fonts)
RESPONSIVE: custom — ResponsiveRow (app/lib/widgets/form_widgets.dart, LayoutBuilder maxWidth < 640 stacks) + ad-hoc LayoutBuilder/MediaQuery width breakpoints 860/900/980/1000/1080 and ConstrainedBox maxWidth 420/460/1000/1150 — width-based, no shortestSide
TEXT_SCALING: none
ENV/FLAVORS: hardcoded constants (app/lib/config.dart kFunctionsRegion; firebase_options.dart from flutterfire) — functions: firebase-functions params defineSecret ANTHROPIC_API_KEY (Secret Manager), defineString AI_MODEL, defineInt AI_DAILY_LIMIT (non-secret params in functions/.env); CI secrets FIREBASE_SERVICE_ACCOUNT, FIREBASE_PROJECT_ID (.github/workflows/deploy.yml); no flavors
LOGGING: none in app (no print/debugPrint); functions console.error only
ANALYTICS/CRASH: none
PUSH: none
PAYMENTS/IAP: none
PERMISSIONS: none (web-only)
DEEP_LINKS: none
MEDIA/FILES: custom web file picker + Blob download via package:web/dart:js_interop (app/lib/services/browser.dart); Image.asset/Image.memory; server-side @napi-rs/canvas image compositing, docx + jszip Word generation with embedded TTF fonts
TESTS: Flutter 0 | functions 1 runner (functions/test/run-tests.js, ~34 assert checks, no framework) — every callable handler against in-memory Firestore/Auth doubles + fake Anthropic client: auth/role guards, estimate engine, price overrides, AI merge/parse, daily AI quota, docx export + font embedding, stationery compositing, first-admin claim, user admin CRUD
LINTS: app: flutter_lints ^5.0.0 include only, 0 extra rules | functions: none (no ESLint, no tsconfig, no type checking; "use strict" CommonJS)
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- functions/index.js + functions/lib/handlers.js — callable-functions skeleton: params (defineSecret/defineString/defineInt), setGlobalOptions(region,maxInstances), wrap() mapping AppError->HttpsError and hiding internals, makeHandlers(deps) factory free of firebase-functions so it is unit-testable, requireMember/requireAdmin custom-claim guards, parseJsonArg size/JSON guard — quality 4 — coupling: low for the pattern; handler bodies app-specific
- functions/lib/handlers.js (claimFirstAdmin, adminCreateUser/UpdateUser/DeleteUser) — Firebase Auth team/role management via custom claims: first-user admin bootstrap in a transaction, self-demote/self-delete protection, revokeRefreshTokens on role/disable/password change — quality 4 — coupling: low (only "users" + "settings/system" docs)
- firestore.rules — role-claim helpers signedIn/isAdmin/isMember/owns, owner-scoped documents, server-only collections — quality 4 — coupling: low
- functions/test/run-tests.js — zero-dependency test runner with in-memory Firestore (doc get/set/update/delete, runTransaction) and Auth doubles — quality 4 — coupling: medium (asserts are domain-specific; doubles are generic)
- .github/workflows/deploy.yml + firebase.json — CI: flutter build web, npm test functions, firebase deploy with service-account secret; hosting SPA rewrite + cache headers (no-cache index.html) — quality 4 — coupling: none
- app/lib/services/browser.dart — web-only helpers on package:web (no dart:html): Blob download, image file picker returning bytes+mime, localStorage draft get/set/clear — quality 4 — coupling: low (draft key name)
- app/lib/services/api.dart (_call/_messageFor, Session, ApiError) — callable wrapper with timeout + FirebaseFunctionsException code -> friendly message, Session from ID-token role claim — quality 3 — coupling: high (static god facade mixing auth, Firestore queries, all domain calls; Arabic strings hardcoded)
- functions/lib/ai.js (parseJson, analyze) — robust JSON extraction from an LLM reply (raw -> ```json fence -> outermost braces), max_tokens stop_reason check, injected client for tests, defensive merge of the reply into a model — quality 4 — coupling: high for prompt/merge, none for parseJson
- app/lib/screens/auth_gate.dart — authStateChanges -> FutureBuilder(Session) -> Login / NotActivated (with first-admin claim) / HomeShell; reload counter to force token refresh — quality 3 — coupling: medium
- app/lib/screens/home_shell.dart — adaptive shell: extended NavigationRail >= 980 px, NavigationDrawer + AppBar below, role-filtered destinations, IndexedStack keeps tab state — quality 3 — coupling: medium (destinations hardcoded)
- app/lib/widgets/form_widgets.dart — ResponsiveRow, showMessage snackbar, confirm dialog, Banner2 status banner, chip choice widgets — quality 3 — coupling: low/medium (config.dart colors, Arabic button labels)
- app/lib/config.dart buildTheme() — compact M3 ThemeData with input/card/chip/filled-button/appBar component themes — quality 3 — coupling: medium (brand colors + client contact defaults in same file)
- app/lib/screens/login_screen.dart — email/password sign-in with FirebaseAuthException code mapping, password reset, AutofillGroup + autofillHints, show/hide password — quality 3 — coupling: low
- functions/lib/engine.js finalizeDocx() — post-processes a docx Packer buffer with JSZip to embed TTF fonts (fontTable.xml, rels, content types, embedTrueTypeFonts) — quality 4 — coupling: low (niche)
GENERIC_WIDGETS (every reusable widget):
- app/lib/widgets/form_widgets.dart ResponsiveRow — responsive row/column switcher — children, breakpoint=640 — quality 4 — generic? y
- app/lib/widgets/form_widgets.dart showMessage() — floating snackbar helper — context, text, error — quality 3 — generic? y (colors from config.dart)
- app/lib/widgets/form_widgets.dart confirm() — confirm AlertDialog returning bool — context, title, body, ok, danger — quality 3 — generic? y (cancel label hardcoded Arabic)
- app/lib/widgets/form_widgets.dart Banner2 — inline status banner with spinner for busy — kind ('busy'|'ok'|'error'|'info' String), text, action — quality 3 — generic? y (stringly-typed kind, hardcoded colors)
- app/lib/widgets/form_widgets.dart SectionCard — numbered section card with title + subtitle — number, title, subtitle, children — quality 3 — generic? y
- app/lib/widgets/form_widgets.dart Question — form question label + hint + required badge + missing highlight — label, hint, required, missing, child, note — quality 3 — generic? y (badge text hardcoded Arabic)
- app/lib/widgets/form_widgets.dart SingleChoice — ChoiceChip single-select — options Map<String,List<String>>, value, onChanged — quality 3 — generic? y (options as [label, tooltip] lists, not typed)
- app/lib/widgets/form_widgets.dart MultiChoice — FilterChip multi-select — options, selected, onToggle — quality 3 — generic? y
- app/lib/widgets/form_widgets.dart FormText — TextFormField bound by initialValue/onChanged — initial, onChanged, hintText, maxLines, ltr — quality 2 — generic? y
- app/lib/screens/form_screen.dart _DateField (private) — OutlinedButton opening showDatePicker, ISO yyyy-MM-dd — value, onChanged — quality 3 — generic? y
- app/lib/screens/form_screen.dart _Toggle (private) — tappable checkbox + label — label, value, onChanged — quality 3 — generic? y
- app/lib/screens/form_screen.dart _Kpi / app/lib/screens/review_screen.dart _Kpi2 (private, duplicated) — label/value stat tile — label, value — quality 2 — generic? y
- app/lib/screens/auth_gate.dart _Splash (private) — full-screen spinner — none — quality 2 — generic? y
NOTABLE_IDEAS: (1) testable Cloud Functions: business logic in makeHandlers(deps) with all Firebase/LLM clients injected + thin index.js wrap() (functions/index.js, functions/lib/handlers.js) and a dependency-free in-memory Firestore/Auth double (functions/test/run-tests.js); (2) secrets via firebase-functions params — defineSecret for API key (bound only to the function that needs it: secrets:[ANTHROPIC_API_KEY] on analyze), defineString/defineInt with defaults for tunables, lazy SDK client creation; (3) first-user admin bootstrap with a Firestore transaction on settings/system + custom claims, and client refresh via getIdToken(true) (handlers.claimFirstAdmin, auth_gate.dart); (4) per-user daily LLM quota via transactional counter doc aiUsage/{uid}_{yyyymmdd} -> resource-exhausted (handlers.analyze); (5) role in custom claims enforced identically in firestore.rules and callable guards; (6) web-only interop via package:web + dart:js_interop instead of deprecated dart:html (app/lib/services/browser.dart); (7) debounced live server estimate (700 ms) + localStorage draft autosave (form_screen.dart) and debounced autosave with visible save state + retry timer (review_screen.dart); (8) 60 s in-memory cache of a Firestore settings doc inside a function instance (handlers.priceOverrides); (9) LLM reply hardening: parseJson fallback chain + stop_reason max_tokens check + schema-checked merge (functions/lib/ai.js); (10) GitHub Actions deploy of Flutter web + functions + rules in one job (.github/workflows/deploy.yml)
SMELLS: no l10n at all — every UI string and error message hardcoded Arabic (~333 lines); static god-class Api mixing auth/Firestore/functions and every domain call, screens also hit Api.db.collection(...) directly (users_screen.dart); no state-management/DI layer, logic inside widgets; untyped Map<String,dynamic> models passed everywhere (QuoteForm.values, quotation model), JSON round-trip _plain(); stringly-typed states (Banner2.kind, _aiKind, _saveState doubles as label); duplication: _Kpi vs _Kpi2, pill badge container repeated (Question, history status), option maps hand-mirrored from engine.js (engine_options.dart says GENERATED but is manual), Totals arithmetic duplicated client/server, default branding duplicated (config.dart + functions/lib/stationery.js), REGION duplicated (config.dart + index.js); 9 hardcoded Color(0x...) outside config.dart + widespread Colors.black54; client contact details (site/email/phones) hardcoded in app/lib/config.dart and functions/lib/stationery.js, agency name in the LLM prompt; silent catch (_) {} in Api.loadSession / Browser, adminAlreadyClaimed() returns true on error; analyze returns raw upstream e.message to client; quota consumed before the LLM call (failed calls still count); Image.memory(base64Decode(...)) inside build (settings_screen.dart); functions: plain JS with no ESLint/TS/type checking (assignment expected TS); functions/.env not in .gitignore (non-secret params, but risky pattern); app/firebase.json commits Firebase project/app identifiers; zero Flutter tests. No deprecated APIs found (no withOpacity, WillPopScope, textScaleFactor, MaterialStateProperty, print, dart:html).
```

---

## 1. Architecture pattern

A small internal tool: a **Flutter web-only** single-page app (team login, a long requirements form,
review/edit, history, team admin, branding/price-book admin) on top of **Firebase** (Auth, Firestore,
Hosting, Cloud Functions v2). It is not a mobile app; `app/` has only a `web/` platform folder.

- **Client (`app/lib`)**: layer-first with four folders: `models/` (map-backed form + totals +
  constant option maps), `screens/` (one StatefulWidget per page, holds its own state and logic),
  `services/` (`Api` static facade for Firebase; `Browser` web helpers), `widgets/` (one file of
  form/feedback widgets). There is no data/domain/presentation split, no repositories, no use cases,
  no state-management package and no DI. Screens call `Api.*` static methods; `users_screen.dart`
  queries `Api.db.collection('users')` directly.
- **Server (`functions/`)**: all business logic is server-side. `index.js` is a thin entry point that
  declares params/secrets and exposes 9 `onCall` endpoints; `lib/handlers.js` holds the endpoint logic
  inside a `makeHandlers(deps)` factory (dependency-injected so tests run without Firebase);
  `lib/engine.js` (UMD, runs in Node or browser) turns the form into a quotation model and the model
  into a `.docx`; `lib/ai.js` calls the LLM and merges its JSON answer; `lib/stationery.js` composes the
  letterhead PNG with `@napi-rs/canvas`.
- **Security model**: role (`admin` | `agent`) lives in Firebase Auth **custom claims**, set only by
  functions; the same role is enforced in `firestore.rules` and in the callable guards
  (`requireMember` / `requireAdmin`).
- **A "feature"** = one screen file under `screens/` plus the `Api` methods it uses plus a callable
  in `handlers.js`.

## 2. Folder tree

```
dindex-quote/
├── README.md                     setup/deploy guide (Firebase, secrets, first admin)
├── firebase.json                 functions (nodejs22), firestore rules/indexes, hosting (SPA rewrite + cache headers)
├── firestore.rules               role-claim rules (users, settings, quotations, aiUsage)
├── firestore.indexes.json        composite index quotations(createdBy asc, createdAt desc)
├── .firebaserc                   project alias (exists; contains project id — not quoted)
├── .github/workflows/deploy.yml  CI: build Flutter web, test functions, firebase deploy
├── app/                          Flutter web app
│   ├── pubspec.yaml / analysis_options.yaml / firebase.json (flutterfire config, ids not quoted)
│   ├── assets/images/            logo
│   ├── assets/fonts/             Cairo-Regular.ttf, Cairo-Bold.ttf
│   ├── web/                      index.html (lang="ar" dir="rtl"), manifest.json, favicon
│   └── lib/
│       ├── main.dart             Firebase.initializeApp, MaterialApp (locale ar, Global* delegates), home: AuthGate
│       ├── config.dart           functions region, brand colors, default footer branding, buildTheme()
│       ├── firebase_options.dart flutterfire-generated (exists; not opened)
│       ├── models/
│       │   ├── quote_form.dart       QuoteForm: map-backed form with defaults, required-field check
│       │   ├── totals.dart           Totals: client-side copy of server totals math + money formatting
│       │   ├── engine_options.dart   option maps mirrored from functions/lib/engine.js (OPT) + price keys
│       │   └── form_options.dart     single-choice option maps + Arabic price labels
│       ├── screens/
│       │   ├── auth_gate.dart        auth stream -> Login / NotActivated (first-admin claim) / HomeShell
│       │   ├── login_screen.dart     email/password sign-in, password reset
│       │   ├── home_shell.dart       NavigationRail (wide) / Drawer (narrow), IndexedStack of pages
│       │   ├── form_screen.dart      11-section requirements form, live debounced estimate, draft autosave
│       │   ├── review_screen.dart    edit generated quotation, run LLM analysis, autosave, export .docx
│       │   ├── history_screen.dart   Firestore stream list with search, download/duplicate/delete
│       │   ├── users_screen.dart     admin team management (add/role/disable/password/delete)
│       │   └── settings_screen.dart  admin branding (logo, watermark, footer, live preview) + price book tabs
│       ├── services/
│       │   ├── api.dart              Session, ApiError, Api static facade (functions + Firestore + Auth)
│       │   └── browser.dart          web download, image picker, localStorage draft (package:web)
│       └── widgets/
│           └── form_widgets.dart     SectionCard, Question, SingleChoice, MultiChoice, FormText,
│                                     ResponsiveRow, Banner2, showMessage(), confirm()
└── functions/                    Cloud Functions (Node 22, plain CommonJS JavaScript)
    ├── package.json              scripts: test, deploy; no lint/build step
    ├── .env                      exists (non-secret params AI_MODEL / AI_DAILY_LIMIT per README; not opened)
    ├── index.js                  params/secrets, setGlobalOptions, wrap(), 9 onCall exports
    ├── lib/
    │   ├── handlers.js           makeHandlers(deps): all endpoint logic, AppError, auth guards
    │   ├── engine.js             quotation engine (UMD): price book, buildModel, totals, buildDoc, finalizeDocx
    │   ├── ai.js                 LLM prompt, JSON parse, merge into model
    │   ├── stationery.js         letterhead PNG compositing with @napi-rs/canvas
    │   └── assets/               Cairo TTFs + stationery.png
    └── test/
        ├── run-tests.js          in-memory doubles + ~34 assert checks
        └── out/                  generated sample .docx/.png (gitignored)
```

## 3. Infrastructure

### State management
No package. Every screen is a `StatefulWidget` with `setState`. Live data uses `StreamBuilder` on
Firestore queries (`history_screen.dart`, `users_screen.dart`) and `FutureBuilder` for the session
(`auth_gate.dart`). Status is stringly typed: `_aiKind` = `'busy'|'ok'|'error'`, `_saveState` holds
the Arabic label itself. Debounce via `Timer` (700 ms estimate in `form_screen.dart`, 2 s autosave and
8 s retry in `review_screen.dart`). Workable at this size, not a template candidate.

### DI
None in the app (static `Api._fn`, `Api.db`, `Api.auth`). In functions, a manual constructor-injection
factory: `makeHandlers({ db, auth, FieldValue, anthropic, aiModel, aiDailyLimit })` in
`functions/lib/handlers.js`, wired in `functions/index.js` with lazily created clients
(`anthropic: () => ...` creates the SDK client on first use). Params are passed as thunks so they are
only read at request time (required by firebase-functions params). Good, simple pattern.

### Routing
`MaterialApp(home: AuthGate())`. `AuthGate` listens to `authStateChanges()`, then loads a `Session`
(ID-token claims + `users/{uid}` name) and shows `LoginScreen`, a private "not activated" page (with
first-admin claim) or `HomeShell`. `HomeShell` switches pages with an `IndexedStack`, destinations
filtered by `session.isAdmin`. Detail pages use `Navigator.push(MaterialPageRoute(...))`. No named
routes, no go_router, browser URL never changes, no deep links. Hosting rewrites `**` to `/index.html`.

### Networking
No REST client. Two channels:
- **Callable functions**: `Api._call(name, data, {timeoutSeconds})` uses
  `FirebaseFunctions.instanceFor(region: kFunctionsRegion).httpsCallable(...)`, deep-copies the
  response via `jsonDecode(jsonEncode(...))`, maps `FirebaseFunctionsException.code`
  (`unauthenticated`, `permission-denied`, `resource-exhausted`, `deadline-exceeded`, `unavailable`)
  to Arabic messages in `ApiError`. Any other exception becomes a generic "check your internet" error.
  Large payloads are passed as JSON strings (`formJson`, `modelJson`) and files come back base64.
- **Firestore direct**: quotations CRUD, branding, pricing writes, users list.
No interceptors, no retry (except the autosave timer), token refresh handled by the Firebase SDK plus
manual `getIdToken(true)` after a claim change.

Server side (`functions/index.js`): `wrap(fn)` normalises `{data, auth}`, rethrows `AppError` as
`HttpsError(code, message)` and converts anything else to `internal` with a generic message (logs with
`console.error`). Per-function options: `analyze` gets `secrets: [ANTHROPIC_API_KEY]`, 300 s,
512 MiB; `exportDocx` 120 s, 1 GiB; global `region` + `maxInstances: 10`.
Validation helpers in `handlers.js`: `parseJsonArg` (type, 900 KB cap, JSON parse), `assertModel`,
`requireMember`, `requireAdmin`.

### Local storage
Only `window.localStorage` for the unsent form draft, via `Browser.loadDraft/saveDraft/clearDraft`
(`app/lib/services/browser.dart`, package:web, errors swallowed). Everything else is in Firestore.

### Localization (+RTL)
No localization system. `main.dart` sets `locale: Locale('ar')`, `supportedLocales: [ar, en]` and
the three `Global*Localizations` delegates only (so Material widgets are Arabic). All UI text is
hardcoded Arabic (~333 source lines with Arabic literals, including `Api._messageFor`). Option maps
are `key -> [arabicLabel, englishLabel]`, the English one shown as a chip tooltip. The generated
document is bilingual (ar/en) server-side in `engine.js` (`fixed(lang)`, `L(ar, en)`).
RTL: app runs RTL from the locale; 10 `*Directional` usages, 0 left/right-specific paddings (4
`EdgeInsets.fromLTRB` with symmetric horizontal values), 17 explicit `TextDirection.ltr/rtl` for
email/phone/English hint fields. `web/index.html` sets `lang="ar" dir="rtl"`. RTL handling is clean.

### Theming
`buildTheme()` in `app/lib/config.dart`: M3, `ColorScheme.fromSeed(seedColor: kPurple, primary,
secondary, surface)`, `fontFamily: 'Cairo'`, component themes for `appBarTheme`, `cardTheme`
(`CardThemeData`, current API), `inputDecorationTheme` (filled, dense, outline r=10, focused color),
`chipTheme`, `filledButtonTheme`. Colors are top-level `const kPurple, kNavy, kLilac, kPaper, kBody,
kGreen, kRed, kRedSoft, kAmberSoft, kAmber` (no class/extension). No text-style class (inline
`TextStyle` and `textTheme.headlineSmall?.copyWith` in screens). No dark mode. 9 more hardcoded
`Color(0x...)` in screens/widgets, heavy `Colors.black54`. The same palette is duplicated as hex
strings in `engine.js buildDoc` for the Word output.

### Responsive helpers
`ResponsiveRow` (`form_widgets.dart`): `LayoutBuilder`, stacks children in a Column below
`breakpoint` (default 640), else a Row of `Expanded` with 16 px gaps. Elsewhere ad-hoc breakpoints:
`home_shell.dart` `MediaQuery.sizeOf(context).width >= 980` (rail vs drawer), `form_screen.dart`
1080 (side estimate panel), `review_screen.dart` 900/860, `settings_screen.dart` 1000. Content width
capped with `ConstrainedBox(maxWidth: 420/460/1000/1150)`. No screenutil, no breakpoint constants.

### Text scaling
None.

### Env / flavors
- App: hardcoded `kFunctionsRegion` in `config.dart` (must match `REGION` in `functions/index.js`),
  flutterfire `firebase_options.dart` (committed by design per the workflow comments). No flavors, no
  `--dart-define`, no dotenv.
- Functions (names only): `defineSecret("ANTHROPIC_API_KEY")` (Google Secret Manager, set with
  `firebase functions:secrets:set`, bound only to `analyze`), `defineString("AI_MODEL", {default})`,
  `defineInt("AI_DAILY_LIMIT", {default: 80})`; overrides for the two non-secret params live in
  `functions/.env` (file exists, not opened). No `process.env` reads in code.
- CI (names only): GitHub secrets `FIREBASE_SERVICE_ACCOUNT` (written to `$RUNNER_TEMP/sa.json`,
  exported as `GOOGLE_APPLICATION_CREDENTIALS`) and `FIREBASE_PROJECT_ID`.
- `.gitignore` covers `node_modules/`, `functions/test/out/`, `app/build/`, `app/.dart_tool/`,
  `app/pubspec.lock`, `.firebase/` — but not `functions/.env`.

### Logging
App: none (no `print`, `debugPrint`, logger). Functions: `console.error` in `wrap()` and `analyze`.

### Analytics / crash reporting
None.

### Push notifications
None.

### IAP / payments
None.

### Permissions
None (web only).

### Deep links
None.

### Functions-specific notes (structure, TS config, lint)
- **Language**: plain JavaScript, CommonJS, `"use strict"`. **No TypeScript** (no `tsconfig.json`,
  no `src/`/`lib/` build split, `main: index.js`).
- **Lint**: none (no ESLint config, no `lint` script, no `predeploy` hook in `firebase.json`).
- **Runtime**: `engines.node: "22"`, `firebase.json` `runtime: nodejs22`; deploy ignores `test`.
- **Deps**: firebase-functions 7.4 (v2 `onCall`, `params`), firebase-admin 14.5 (modular imports
  `firebase-admin/app|firestore|auth`), `@anthropic-ai/sdk` 1.3, `docx` 9.5.1 (pinned exact),
  `jszip` 3.10, `@napi-rs/canvas` 1.0.
- **Testing**: `npm test` -> `node test/run-tests.js`; also run in CI before deploy.
- **Endpoints**: `estimate`, `analyze`, `exportDocx`, `previewStationery`, `getPricing`,
  `claimFirstAdmin`, `adminCreateUser`, `adminUpdateUser`, `adminDeleteUser` (all `onCall`).

## 4. Services catalog

| File | Class / symbol | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|---|
| app/lib/services/api.dart | `Session` | signed-in user + role from claims | `uid, email, name, role, isAdmin, isMember` | — | generic pattern |
| app/lib/services/api.dart | `ApiError` | user-facing exception | `message, code, toString()` | — | generic |
| app/lib/services/api.dart | `Api` (static) | single backend facade | `_call`, `loadSession`, `adminAlreadyClaimed`, `claimFirstAdmin`, `estimate`, `analyze`, `exportDocx`, `previewStationery`, `getPricing`, `savePricing`, `createUser`, `updateUser`, `deleteUser`, `brandingStream`, `saveBranding`, `quotations`, `quotationsFor`, `saveQuotation`, `markExported`, `deleteQuotation`; fields `db`, `auth` | firebase_auth, cloud_firestore, cloud_functions, config.dart, models | app-specific (the `_call` + `_messageFor` part is generic) |
| app/lib/services/api.dart | `EstimateResult` | estimate response | `model, totals` | Totals | app-specific |
| app/lib/services/browser.dart | `Browser` (static) | web-only browser helpers | `docxMime`, `download(bytes, filename, {mime})`, `pickImage()`, `loadDraft()`, `saveDraft(json)`, `clearDraft()` | package:web, dart:js_interop | generic (web) |
| app/lib/config.dart | top-level consts + `buildTheme()` | region, palette, default footer branding, ThemeData | `kFunctionsRegion`, `k*` colors, `kDefaultBranding`, `buildTheme()` | material | pattern generic, values app-specific |
| app/lib/models/quote_form.dart | `QuoteForm` | map-backed requirements form | `values`, `defaults()`, `fromJsonString`, `copy`, `str/flag/list/set/toggle`, `toEngineJson`, `requiredLabels`, `missing()`, `canEstimate` | dart:convert | app-specific |
| app/lib/models/totals.dart | `Totals` | client copy of server totals math | `fromModel`, `money(num)`, `priceLabel`, `weeksLabel`, `currencyAr` | — | app-specific (`money` generic thousands separator) |
| app/lib/models/engine_options.dart | const maps | option keys/labels mirrored from engine.js | `kUserTypes, kIndustries, kFeatures, kPayMethods, kFinance, kIntegrations, kPriceKeys` | — | app-specific |
| app/lib/models/form_options.dart | const maps | single-choice options + price labels | `kQuoteLang, kCurrency, kProjectType, ... kPriceLabels` | — | app-specific |
| functions/index.js | module | entry: params, global options, error wrapper, exports | `wrap(fn)`, 9 `onCall` exports | firebase-functions v2, firebase-admin, handlers | generic pattern |
| functions/lib/handlers.js | `makeHandlers`, `AppError` + helpers | all endpoint logic, auth guards, user admin, AI quota, pricing cache | `makeHandlers(deps)` -> `{estimate, analyze, exportDocx, previewStationery, getPricing, claimFirstAdmin, adminCreateUser, adminUpdateUser, adminDeleteUser}`; internal `parseJsonArg`, `assertModel`, `requireMember`, `requireAdmin`, `dayKey` | docx, jszip, engine, ai, stationery, fs | mixed: guards/user admin generic, quotation logic app-specific |
| functions/lib/ai.js | module | LLM prompt, reply parsing, merge | `analyze(client, model, form, M)`, `buildPrompt`, `parseJson`, `merge` | injected Anthropic client, engine | `parseJson` generic, rest app-specific |
| functions/lib/engine.js | UMD `api` | quotation engine + docx builder | `buildModel, buildDoc, finalizeDocx, totals, fixed, fmtMoney, roundPrice, OPT, PRICE, RATES, CUR` | docx + JSZip injected | app-specific (`finalizeDocx` font embedding reusable) |
| functions/lib/stationery.js | module | letterhead PNG compositing | `composeStationery(branding)`, `DEFAULT_BRANDING`, `normalizeBranding` | @napi-rs/canvas | app-specific |
| functions/test/run-tests.js | script | in-memory doubles + checks | `fakeDb()`, `fakeAuth()`, `expectError()` | assert, jszip, handlers | doubles generic |

## 5. Widgets catalog

| Path | Widget | Purpose | Constructor params | Generic? |
|---|---|---|---|---|
| app/lib/widgets/form_widgets.dart | `SectionCard` | Card with number + title + LTR subtitle and spaced children | `number, title, subtitle, children` | y |
| app/lib/widgets/form_widgets.dart | `Question` | label + optional LTR hint + "required" pill, red background when missing, optional note | `label, hint?, required=false, missing=false, child, note?` | y (pill text Arabic) |
| app/lib/widgets/form_widgets.dart | `SingleChoice` | `ChoiceChip` group, no checkmark, tooltip | `options: Map<String,List<String>>, value, onChanged` | y |
| app/lib/widgets/form_widgets.dart | `MultiChoice` | `FilterChip` group | `options, selected: List<String>, onToggle` | y |
| app/lib/widgets/form_widgets.dart | `FormText` | uncontrolled `TextFormField` (initialValue + onChanged), optional LTR | `initial, onChanged, hintText?, maxLines=1, ltr=false` | y |
| app/lib/widgets/form_widgets.dart | `ResponsiveRow` | Row on wide, Column on narrow | `children, breakpoint=640` | y |
| app/lib/widgets/form_widgets.dart | `Banner2` | inline status banner (spinner when busy) | `kind: String ('busy'/'ok'/'error'/'info'), text, action?` | y |
| app/lib/widgets/form_widgets.dart | `showMessage()` | floating SnackBar, red on error | `context, text, {error=false}` | y |
| app/lib/widgets/form_widgets.dart | `confirm()` | confirm AlertDialog -> bool, danger style | `context, title, body, {ok, danger=false}` | y |
| app/lib/screens/form_screen.dart | `_DateField` (private) | date picker button, ISO yyyy-MM-dd | `value, onChanged` | y |
| app/lib/screens/form_screen.dart | `_Toggle` (private) | checkbox + label row | `label, value, onChanged` | y |
| app/lib/screens/form_screen.dart | `_Kpi` (private) | label/value stat | `label, value` | y (duplicate of `_Kpi2`) |
| app/lib/screens/review_screen.dart | `_Kpi2` (private) | label/value stat | `label, value` | y (duplicate) |
| app/lib/screens/auth_gate.dart | `_Splash` (private) | full-screen spinner | — | y |
| app/lib/screens/home_shell.dart | `HomeShell` | adaptive rail/drawer shell | `session` | partly (destinations hardcoded) |

Missing entirely: shimmer/skeleton, empty/error state widgets (inline `Center(Text(...))`), network
image, pagination, base scaffold, custom app bar, bottom sheets.

## 6. Packages

### Flutter (`app/pubspec.yaml`, resolved from pubspec.lock)
| Role | Package | Constraint | Resolved |
|---|---|---|---|
| firebase | firebase_core | ^4.0.0 | 4.15.2 |
| firebase | firebase_auth | ^6.0.0 | 6.7.1 |
| firebase | cloud_firestore | ^6.0.0 | 6.10.2 |
| firebase | cloud_functions | ^6.0.0 | 6.5.1 |
| l10n | flutter_localizations | sdk | — |
| web interop | web | ^1.1.0 | 1.1.1 |
| dev | flutter_test | sdk | — |
| dev | flutter_lints | ^5.0.0 | 5.0.0 |

No state, DI, routing, network, storage, UI, media or utils packages. SDK: Dart `>=3.8.0 <4.0.0`
(lock: dart >=3.10.0-0, flutter >=3.27.0). Fonts: Cairo (Regular, Bold 700).

### Functions (`functions/package.json`, resolved from package-lock.json)
| Role | Package | Constraint | Resolved |
|---|---|---|---|
| firebase | firebase-functions | ^7.4.0 | 7.4.0 |
| firebase | firebase-admin | ^14.5.0 | 14.5.0 |
| AI | @anthropic-ai/sdk | ^1.3.0 | 1.3.0 |
| documents | docx | 9.5.1 (exact) | 9.5.1 |
| documents | jszip | ^3.10.1 | 3.10.2 |
| image | @napi-rs/canvas | ^1.0.13 | 1.0.13 |

No devDependencies (no eslint, typescript, jest/mocha, firebase-functions-test).

## 7. Quality notes

- **Null safety**: full (Dart 3.8+), records and switch expressions used (`({String filename,
  List<int> bytes})`, `switch (kind) { ... }`).
- **Lints**: `app/analysis_options.yaml` is a single `include: package:flutter_lints/flutter.yaml`
  with no extra rules. Functions have no linter and no type checking.
- **Tests**: no Flutter tests (no `test/` folder). Functions have one solid, framework-free runner
  (`functions/test/run-tests.js`) exercising every handler with in-memory doubles; it runs in CI before
  deploy and writes sample outputs to `test/out/` (gitignored). Test fixtures contain realistic
  person/company names (not reproduced here).
- **Deprecated APIs**: none found (no `withOpacity`, `WillPopScope`, `textScaleFactor`,
  `MaterialStateProperty`, `dart:html`); uses `CardThemeData`, `MediaQuery.sizeOf`, `package:web`.
- **Smells**: listed in the summary. Biggest ones for a template: no l10n (all Arabic literals), static
  god-facade `Api`, untyped `Map<String, dynamic>` models, stringly-typed UI states, cross-language
  duplication (option maps, totals math, branding defaults, region) kept in sync by comments only,
  client contact data hardcoded in two files, functions without lint/TS.
- **Security**: role checks are consistent between rules and functions; refresh tokens revoked on role
  or status change; self-demotion/deletion blocked; first-admin claim is transactional. Weak spots:
  `analyze` forwards the upstream error message to the client; `adminAlreadyClaimed()` returns `true`
  on any read error (fails closed, fine); `functions/.env` not gitignored (holds only non-secret
  params per README). No secret values found in source.
- **What to take for the template**: the functions skeleton (`index.js` wrap + params +
  `makeHandlers` DI + in-memory test doubles), custom-claims role model with `firestore.rules`
  helpers and first-admin bootstrap, the CI deploy workflow and hosting headers, `Browser` web helpers
  on `package:web`, `ResponsiveRow`, `confirm()`/`showMessage()`, and the LLM `parseJson` hardening.
  The Flutter app structure itself is too small and too coupled to serve as a template base.
