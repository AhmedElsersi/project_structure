# Conventions

The rules every project made from `flutter_template` follows. Tests, lints and CI enforce most of
them. [CLAUDE.md](../CLAUDE.md) is the condensed, imperative version for AI agents. The decisions
behind them are in [COMPARISON.md §6 and §9](COMPARISON.md#9-approved-decisions-2026-11-05).

Contents: [Naming](#naming) · [File headers](#file-headers) · [Responsive](#responsive) ·
[Foldables](#foldables) · [Text scaling](#text-scaling) · [RTL](#rtl) ·
[Localization](#localization) · [Theming](#theming) ([Theme](#theme), [Typography](#typography)) · [Error handling](#error-handling) ·
[Environment](#environment) · [State](#state) · [Dependency injection](#dependency-injection) ·
[Testing](#testing) · [Lints and banned APIs](#lints-and-banned-apis) ([Deprecated APIs](#deprecated-apis)) · [Git and CI](#git-and-ci)

---

## Naming

| Thing | Rule | Example |
|---|---|---|
| Files, folders | `snake_case.dart` | `item_details_screen.dart` |
| One public widget per file | file named after the widget | `item_tile.dart` → `ItemTile` |
| Screens | `<name>_screen.dart` → `<Name>Screen` | `items_screen.dart` |
| Cubits / states | `<name>_cubit.dart`, `<name>_state.dart` | `item_form_cubit.dart` |
| Feature DI | `<feature>_di.dart` → `register<Feature>Feature()` | `items_di.dart` → `registerItemsFeature()` |
| Feature routes | `<feature>_routes.dart` → `abstract final class <Feature>Routes` | `items_routes.dart` → `ItemsRoutes` |
| Data | `<name>_remote_data_source.dart`, `<name>_model.dart`, `<name>_repository_impl.dart` | |
| Domain | `<name>.dart` (entity), `<name>_repository.dart` (interface), `<verb>_<noun>_use_case.dart` | `create_item_use_case.dart` |
| Classes / enums | `UpperCamelCase`; enum values `lowerCamelCase` | `ItemStatus.inProgress` |
| Private members | leading `_` | |
| Translation keys | `feature.snake_case`; generated `LocaleKeys.feature_snake_case` | `items.empty_title` → `LocaleKeys.items_empty_title` |
| Storage keys | `scope.snake_case` in `StorageKeys` | `app.theme_mode` |
| Route paths | lowercase, kebab-case segments, IDs as path params | `/items/:id`, `/items/new` |
| Tests | mirror `lib/` + `_test.dart` | `test/features/sample_feature/items_list_cubit_test.dart` |

Imports: `package:app_template/...` (renamed with the package) or relative inside `lib/`.
`directives_ordering` is on (dart, package, relative). Page width is 120: run
`dart format lib test tool`.

## File headers

Every file (Dart and others) starts with a header comment. `SOURCES.md` is generated from the
`Source:` / `Merged:` lines, so keep them accurate when you copy code in.

```dart
// <One-line purpose>.
//
// Source: <project-slug> <relative/path.dart> (<what was taken>).
// Merged: <project-slug> <relative/path.dart> (<idea>).          (optional, repeatable)
// See docs/WIDGETS.md#<anchor> | docs/SERVICES.md#<anchor>.      (optional)
```

- Use `// Source: new (<reason>)` for code with no single origin. In a client project, `Source:`
  can name the ticket or the template file it grew from.
- Use `//` for the header and `///` doc comments on public classes and methods.
- Name source projects by **slug** and relative path. Never write absolute paths, client names,
  person names or real domains.
- A `See docs/...#anchor` must point at an existing heading. The checker in
  [README.md](../README.md#keeping-the-docs-honest) verifies this.

## Responsive

`lib/core/responsive/breakpoints.dart`. Approved decision: the **form factor** comes from the
**shortest side of the window** (`MediaQuery.sizeOf(context).shortestSide`).

| `FormFactor` | shortestSide | `pageGutter` | `maxContentWidth` | Type scale |
|---|---|---|---|---|
| `phone` | < 600 | 16 | ∞ | 1.00 |
| `tablet` | 600–839 | 24 | 720 | 1.06 |
| `largeTablet` | ≥ 840 | 32 | 840 | 1.10 |

`MediaQuery.sizeOf` is the **window**, so Split View, multi-window and fold/unfold are classified
correctly, and the value is re-evaluated on every change.

| API | Use |
|---|---|
| `context.formFactor`, `isPhone`, `isTablet`, `isLargeTablet`, `isTabletOrLarger`, `isLandscape` | Device-level decisions: navigation style, sheet vs dialog, type scale |
| `context.responsive<T>(phone:, tablet:, largeTablet:)` | Pick a value. Missing values fall back to the next smaller form factor |
| `context.pageGutter`, `context.maxContentWidth` | Page padding and content cap (`AppScaffold` and `MaxWidthBody` apply them) |
| `columnsForWidth(width, {minTileWidth = 160, maxColumns = 6})` | Grid columns from the **available** width. Call it inside `LayoutBuilder` / `SliverLayoutBuilder`, never on the device size |
| `Breakpoints.tablet` (600), `Breakpoints.largeTablet` (840) | The only breakpoint numbers in the app |

Rules:
- **No flutter_screenutil** (decision C2). No `.w`, `.h`, `.sp`, no design-size scaling. Use fixed
  logical pixels from `AppSpacing` / `AppRadii` / `AppSizes`. Tablets get more room, not bigger
  pixels.
- **Never cache sizes** (in fields, singletons or `initState`). Read `MediaQuery.sizeOf(context)`
  or `context.formFactor` in `build`.
- **Local layout comes from constraints.** Grids, two panes and row↔column switches use the
  parent's `LayoutBuilder` (a pane or rail changes the available width, not the device).
- **No orientation lock.** A lock decided at launch is wrong after a foldable unfolds. Every
  screen must work in landscape (`kLayoutMatrix` includes `landscape_phone` 852×393).
- Navigation: `AdaptiveNavigationShell` (bar on phones, rail on tablets). Sheets:
  `showAppBottomSheet` (dialog on tablets). Lists: `PaginatedListView(gridColumns:)` on tablets.
- Use `Flexible`/`Expanded`, `maxLines` + `overflow`, `Wrap` and `AdaptiveRow` instead of fixed
  widths for text.

```dart
final columns = context.responsive(phone: 1, tablet: 2, largeTablet: 3); // device-level choice

LayoutBuilder(builder: (context, c) => GridView.count(        // local choice
  crossAxisCount: columnsForWidth(c.maxWidth, minTileWidth: 220),
  children: tiles,
));
```

## Foldables

`lib/core/responsive/display_features.dart` reads `MediaQuery.displayFeaturesOf` (Android Jetpack
WindowManager data).

| API | Meaning |
|---|---|
| `context.separatingHinge` → `Hinge?` | The hinge or half-opened fold that splits the window now, else null (phones, tablets, a closed or flat foldable) |
| `Hinge.bounds` | Window coordinates; zero-width for a fold |
| `Hinge.isVertical` | Splits left/right (book posture) |
| `Hinge.isOccluding` | A physical hinge that **hides pixels** (dual-screen devices). A fold has continuous pixels |
| `context.isTabletop` | Horizontal half-opened fold: content on top, controls below |

How the template handles them:
- **Folded** is a phone and **unfolded** is a tablet, automatically, through `shortestSide`.
- `AdaptiveNavigationShell` keeps rail + body on one screen only for an **occluding** vertical
  hinge. On a fold it uses the full width.
- `AdaptiveTwoPane` splits **exactly at the hinge**: book posture gives start pane | gap | end
  pane (the start pane is on the right in Arabic), and tabletop gives top / bottom. With no hinge
  it uses the normal width rule.
- Dialogs and bottom sheets avoid the hinge by themselves (`DisplayFeatureSubScreen`).

Rule: never place content that must be read or tapped across `separatingHinge.bounds`. For
list/detail screens use `AdaptiveTwoPane`. `test/core/responsive/display_features_test.dart` and
`test/shared/widgets/layout/adaptive_layout_test.dart` show how to fake a hinge in tests.

## Text scaling

`lib/core/responsive/app_text_scale.dart`. The system font-size setting has a **small, damped**
effect. A `DampedTextScaler` applies **50 %** of the user's increase **per font size** (so Android
14's non-linear scaling is respected) and clamps the result to **1.0–1.3**. `MaterialApp.builder`
applies it once (`AppTextScale.wrap`), so every route, dialog and sheet gets it.

| System setting | App text |
|---|---|
| ≤ 1.0 | 1.00 |
| 1.15 | 1.075 |
| 1.3 | 1.15 |
| 1.5 | 1.25 |
| ≥ 1.6 (up to 2.0) | 1.30 |

| API | Use |
|---|---|
| `AppTextScale.min` / `max` / `damping` | 1.0 / 1.3 / 0.5 |
| `AppTextScale.extra(context, fontSize, {lineHeight = 1.2, lines = 1})` | Extra height that `lines` of text need at the current scale. Use it for **fixed-height slots** (chips, tab bars, fixed grid cells) so they grow with the text |
| `AppTextScale.isEnlarged(context)` | The user enlarged text; switch to a stacked layout |
| `MediaQuery.textScalerOf(context).scale(size)` | Scale an icon with its label (`StatusChip` does this) |

Rules:
- **Never** use `TextScaler.noScaling`, `textScaleFactor` or `MediaQuery.withNoTextScaling`.
  `textScaleFactor` is deprecated and banned. Text must always scale within 1.0–1.3.
- Layouts must survive the max app scale (1.3) at **320 px** width, in Arabic and English. Test
  with `pumpApp(..., textScale: 2.0, size: kLayoutMatrix['small_phone']!)`.
- Prefer intrinsic heights (`minHeight` constraints, padding) over fixed heights. When a height
  must be fixed, add `AppTextScale.extra(...)`.

```dart
SizedBox(height: 40 + AppTextScale.extra(context, 14), child: tabs)
```

## RTL

Arabic is the start locale, so every layout is RTL-first.

| Use | Never |
|---|---|
| `EdgeInsetsDirectional.only(start:, end:)`, `.fromSTEB`, `.symmetric` | `EdgeInsets.only(left:/right:)`, `EdgeInsets.fromLTRB` with left ≠ right |
| `AlignmentDirectional.centerStart`, `topEnd`… | `Alignment.centerLeft`, `topRight`… |
| `PositionedDirectional(start:, end:)` / `Positioned.directional` | `Positioned(left:, right:)` |
| `BorderRadiusDirectional.only(topStart:)`, `BorderRadiusDirectional.horizontal(start:)` | `BorderRadius.only(topLeft:...)`, `BorderRadius.horizontal(left:/right:)` (`BorderRadius.circular/all/vertical` are fine) |
| `TextAlign.start` / `end` | `TextAlign.left` / `right` |
| `Icons.arrow_back`, `Icons.chevron_right`, `Icons.arrow_forward` (they mirror) | Custom arrow images without `matchTextDirection: true` |

- Symmetric `EdgeInsets.all` / `symmetric` / `zero` / `only(top:, bottom:)` are fine.
  `test/policy/rtl_directional_test.dart` fails on every physical left/right form in `lib/`.
- Force LTR **only** for emails, phones, numbers, codes, IBANs and URLs:
  `AppTextField(forceLtr: true)`, `Text(value, textDirection: TextDirection.ltr)`, or the Unicode
  isolates `⁦…⁩` inside a sentence (`SettingsScreen` does this for the version).
- `context.isRtl` exists for the rare case that needs it (custom painters). Layout code should not
  branch on direction.

## Localization

`lib/core/localization/app_languages.dart`, `assets/translations/{ar,en}.json`, easy_localization.

- **Arabic is the start locale. English is always the second language and the fallback** for
  missing keys. The user's choice is saved (`saveLocale: true`). `useOnlyLangCode: true`.
- `AppLanguages` is the one table: locale, native name («العربية»), direction, start and fallback
  locales, translations path. To add a language, add an entry there, add `<code>.json`, and add it to
  `CFBundleLocalizations` in `ios/Runner/Info.plist`.
- **No hardcoded user-facing text.** Use `LocaleKeys.feature_key.tr()`, with imports
  `package:easy_localization/easy_localization.dart` and
  `package:app_template/core/localization/generated/locale_keys.g.dart`. Shared widgets take
  already-translated `String`s. The only exception is `ConfigErrorApp`, which runs before
  localization.
- `LocaleKeys` is **generated**. After editing the JSON, run `./tool/gen_locale_keys.sh`. CI fails
  if the generated file is stale. A key `items.empty_title` becomes `LocaleKeys.items_empty_title`.
- Every key exists in **both** files, with natural text (real Arabic, not transliteration).
  `dart run tool/check_translations.dart` checks parity, keys used in code but missing from JSON,
  and literal strings in `Text(...)`.
- Namespaces: one top-level object per feature (`items.*`). Shared ones are `app`, `common`,
  `errors`, `states`, `settings`, `nav`, `not_found`, `config_error`, `app_gate`, `validation`,
  `format`, `permissions` and `widgets`. Reuse `common.*` ("Save", "Cancel", "Try again") before
  adding new keys.
- Placeholders: positional `{}` with `tr(args: [...])`, or named `{name}` with
  `tr(namedArgs: {...})`.
- **Plurals**: `ignorePluralRules: false` is set so Arabic gets its CLDR forms (zero, one, two,
  few, many, other). Write all six forms in `ar.json` and use `.plural(count, args: [...])`:

```json
"count": {"zero": "لا عناصر", "one": "عنصر واحد", "two": "عنصران", "few": "{} عناصر", "many": "{} عنصرًا", "other": "{} عنصر"}
```

```dart
// items.count → LocaleKeys.items_count
Text(LocaleKeys.items_count.plural(count, args: [AppFormat.number(count)]))
```

- **Digits policy**: Western digits (0-9) by default (`AppFormat.digits = DigitsPolicy.western`).
  An app that wants ٠-٩ sets `DigitsPolicy.arabicIndic` once, which then applies to Arabic output
  only. Format every number and date with `AppFormat`, never with `toString()` or string
  interpolation of a `double`. Parse user input with `AppFormat.parseNumber` /
  `DecimalInputFormatter.tryParse`, which accept ٠-٩ and `٫`.
- Keep values and units apart when the unit position depends on direction
  (`AppFormat.fileSize` returns `(value:, unit:)`).
- The backend gets `Accept-Language` from `CurrentLocale` on every request, and server messages
  (`Failure.serverMessage`) are shown as sent.
- Code without a `BuildContext` (interceptors, formatters) reads `CurrentLocale.languageCode`. The
  app root keeps it in sync.

## Theming

`lib/core/theme/`. **Text sizes and button styles live in `ThemeData` only.** Colours come only
from the theme. `test/policy/color_literals_test.dart` and `test/policy/font_size_test.dart`
enforce this.

### Theme

| File | Holds |
|---|---|
| `app_colors.dart` | `AppColors.brandSeed` (`{{BRAND_PRIMARY}}`) + semantic tones (success/warning/info, light and dark) + `scrim`. **The only file with colour literals** |
| `app_typography.dart` | `AppTypography.fontFamily` (`{{FONT_FAMILY}}`, null = platform font) and the full Material 3 type scale with explicit heights (Arabic needs them). `scaleFor(FormFactor)` |
| `app_theme.dart` | `AppTheme.light()` / `dark()`: `ColorScheme.fromSeed`, every component theme (app bar, buttons, inputs, card, dialog with a 560 cap, bottom sheet with a 640 cap, snackbar, chip, navigation bar/rail, list tile...). `adaptTo(theme, formFactor)` |
| `app_palette.dart` | `AppPalette` ThemeExtension: `success`, `warning`, `info`, `danger`, `neutral` as `ToneColors(container, onContainer)`; `context.palette`; `StatusTone` |
| `app_spacing.dart` | `AppSpacing` (2–48 + `gapXs…gapXl`), `AppRadii` (8–24, pill, `mdAll`, `xlTop`), `AppSizes` (`minTouch` 48, `buttonHeight` 52, icons, dialog/sheet caps) |
| `app_motion.dart` | Durations/curves; `AppMotion.of(context, d)` returns zero under reduced motion |
| `theme_cubit.dart` | Persisted `ThemeMode` (system/light/dark), read synchronously at startup |

Colour rules:
- **Colours** only from `Theme.of(context).colorScheme` and `context.palette`. **No `Color(0x…)`
  and no `Colors.xxx` outside `lib/core/theme/`.** `Colors.transparent` is the one exception. Pick
  container/on-container **pairs** so contrast holds in both themes (tested by
  `test/core/theme/theme_contrast_test.dart`).
- **Dark mode** is always supported. Never assume a white background.
- **Spacing/radii/sizes** come from tokens, not magic numbers. Touch targets are ≥ 48.
- Animations use `AppMotion` durations through `AppMotion.of(context, ...)`.
- Branding a new project: set `AppColors.brandSeed`. If the brand has a fixed secondary or
  tertiary colour, add it to `AppColors` and `.copyWith(...)` the scheme in `AppTheme._build`.

```dart
final palette = context.palette.toneColors(StatusTone.warning);
DecoratedBox(decoration: BoxDecoration(color: palette.container, borderRadius: AppRadii.mdAll),
  child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: palette.onContainer)));
```

### Typography

- Text styles come from `Theme.of(context).textTheme.<role>` (`titleMedium`, `bodyLarge`,
  `labelSmall`...), optionally `.copyWith(color: ...)`. **Never** write `fontSize:` or
  `fontWeight:` in widgets. A missing style means a missing role in `AppTypography.base`: add it
  there, never inline.
- The type scale is defined once in `AppTypography.base`. It grows slightly on tablets
  (`scaleFor`: 1.06 / 1.10 via `AppTheme.adaptTo`), and the user's font setting is damped
  separately ([Text scaling](#text-scaling)).
- To size an icon with its label, use `MediaQuery.textScalerOf(context).scale(style.fontSize!)` or
  `FittedBox`, not a new literal.
- Font: one family that covers Arabic and Latin (Cairo, Tajawal, IBM Plex Sans Arabic, Noto Sans
  Arabic...). Set it with files in `assets/fonts/` + `fonts:` in `pubspec.yaml` +
  `AppTypography.fontFamily`.

### Buttons

`AppButton`, or themed `FilledButton` / `OutlinedButton` / `TextButton` / `IconButton` **without**
`style:`. Sizes, shapes, padding and text styles come from the button themes in `AppTheme`. The
only per-widget overrides are documented variants (`AppButtonVariant.danger`, the snackbar action
colour).

## Error handling

The flow is data source → repository → cubit → UI. See
[ARCHITECTURE.md#data-flow](ARCHITECTURE.md#data-flow) and [SERVICES.md#failures](SERVICES.md#failures).

1. **Data sources throw `Failure`.** `ApiClient` does it for HTTP. Local sources map exceptions with
   `ErrorMapper.fromObject` or throw a specific `Failure`.
2. **Repositories return `Result<T>`** through `guard(() => ...)`. They never throw and never return
   null for errors.
3. **Cubits** call `run(...)` and store the `Failure` in state. `CancelledFailure` never reaches
   `onFailure`.
4. **UI** shows `failure.displayMessage`: through `ErrorView` (full screen), `AppSnackBar.error`
   (transient), or the inline `PaginatedListView` footer.
5. **Forms**: on `ValidationFailure`, map `fieldError('field')` into each input's `errorText`. The
   field clears the server error once edited. Show `displayMessage` (or nothing, if every error is
   under a field) in a snackbar.
6. **Never show** `debugMessage`, `toString()`, exception text, stack traces or raw response
   bodies. `UnknownFailure.displayMessage` is always the generic sentence.
7. Branch on **types and codes**, never on message text: `failure is NotFoundFailure`,
   `failure.code == 'email_taken'`.
8. Unexpected errors (parser crashes, `TypeError`) are reported automatically through
   `RepositoryGuard.onUnexpectedError` and `ErrorReporter`. Don't catch-and-ignore.
9. 401 → `SessionCubit.expire` → redirect. 426/503 → app gate. Features don't handle these
   themselves.

## Environment

`.env` → `--dart-define-from-file=.env` → `String.fromEnvironment` constants in `AppEnv`
(`lib/core/config/app_env.dart`). It is compile-time and is **not** an asset.

| Variable | Values | Notes |
|---|---|---|
| `APP_FLAVOR` | `dev` \| `staging` \| `prod` | Unknown values fail |
| `BASE_URL` | `https://api.example.com/v1` | Empty in dev means the mock backend |
| `USE_MOCKS` | `true` \| `false` | Default: true when `BASE_URL` is empty |
| `ANDROID_STORE_URL`, `IOS_STORE_URL` | store links | Update-gate fallback |
| `VERBOSE_LOGS` | `true` \| `false` | Debug builds only |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | path **or** base64 | **Tooling and CI only**, never read by the app |

```bash
cp .env.example .env                                   # once; .env is gitignored
flutter run --dart-define-from-file=.env               # dev (mocks if BASE_URL is empty)
flutter run --dart-define-from-file=.env.staging       # staging
flutter build appbundle --release --dart-define-from-file=.env.prod
flutter build ipa --release --dart-define-from-file=.env.prod
```

Rules:
- **`.env.example` is committed** (placeholders, comments). `.env` and `.env.*` are gitignored.
  Every new variable goes into `.env.example` in the same change.
- **Flavors fail closed.** `AppEnv.validate()` rejects staging/prod builds with mocks on or a
  non-https `BASE_URL`, and the app then shows `ConfigErrorApp` instead of quietly using mocks.
- **No secrets in the app.** Everything compiled into the binary can be extracted. API keys
  restricted by package or bundle id (Maps) are acceptable; server secrets, payment secret keys and
  service accounts never are. Put them behind your backend.
- **JSON credentials** (service accounts for Play upload or Firestore scripts) are given as a file
  path or as base64, through `tool/json_credential.dart`, in `tool/` scripts and CI only (see
  [SERVICES.md#jsoncredential](SERVICES.md#jsoncredential)).
- IDE run configurations must pass `--dart-define-from-file=.env` too (VS Code `toolArgs`, Android
  Studio "Additional run args").

## State

- Cubits extend **`BaseCubit<S>`**. Single fetches use **`DataCubit<T>` + `DataState<T>`**, lists
  use **`PaginatedCubit<T>` + `PaginatedState<T>`**. Never add a second base class.
- Every request goes through `run(...)`. Pass `cancelToken` to `ApiClient` calls. Emit only with
  `safeEmit`.
- States are immutable `Equatable`s with a `copyWith`. Clear nullable fields with explicit flags
  (`clearFailure: true`), never with `x ?? this.x`.
- One cubit per screen concern, provided with `BlocProvider(create: (_) => getIt<XCubit>()..load())`.
  App-wide cubits (`SessionCubit`, `ThemeCubit`, `ConnectivityCubit`, `AppConfigCubit`) are
  singletons provided at the root.
- No navigation inside cubits. Expose state (`created: item`) and navigate from a `BlocListener`.
  Sign-in and sign-out navigation is done by the router redirect.
- Use cases are optional (decision C5). Add one only when it holds logic (combines repositories,
  enforces a rule). Never add a pass-through use case.

## Dependency injection

- One container: `getIt` (`lib/core/di/injector.dart`). Core is registered by
  `registerCoreDependencies()` and `registerServicesModule()`. Each feature has
  `register<X>Feature()` in `<feature>_di.dart`, added to `main.dart`'s `modules` list.
- **Constructor injection only.** `getIt<T>()` appears only in `*_di.dart`, `*_routes.dart`,
  `lib/core/di/` and the composition root (`main.dart`, `bootstrap.dart`, `app.dart`,
  `app_router.dart`). `test/policy/architecture_test.dart` enforces this.
- Services and repositories use `registerLazySingleton`. Cubits use `registerFactory` (or
  `registerFactoryParam` for an id). Registrations are awaited and make no platform calls.
- Core never imports features; shared never imports features. Features register their own mock
  routes, notification links and session hooks.

Details: [ARCHITECTURE.md#dependency-injection](ARCHITECTURE.md#dependency-injection).

## Testing

The bar for "done" (CI runs all of it):

| Check | Command |
|---|---|
| Format | `dart format --output=none --set-exit-if-changed lib test tool` |
| Locale keys up to date | `./tool/gen_locale_keys.sh && git diff --exit-code lib/core/localization/generated/` |
| Translations | `dart run tool/check_translations.dart` |
| Analyze | `flutter analyze --fatal-infos --fatal-warnings` → **zero** issues |
| Tests | `flutter test` |

What to test for every feature:
- **Repository** against `MockInterceptor` routes (success, 404, 422 field errors) through a real
  `ApiClient`, so the real interceptors and error mapping run and no socket opens:

```dart
final mock = MockInterceptor(latency: Duration.zero);
final api = ApiClient(
  baseUrl: 'https://mock.local/api',
  tokens: AuthTokenStore(MemorySecureStore()),
  logger: AppLogger(enabled: false),
  languageCode: () => 'en',
  appHeaders: () => const {},
  onSessionExpired: () {},
  onAppStatus: (_, _) {},
  mock: mock,
);
registerItemsMockApi(mock); // the same routes the app uses in USE_MOCKS builds
final repository = ItemsRepositoryImpl(ItemsRemoteDataSource(api));
```
- **Cubit** with `bloc_test` + mocktail fakes of the repository interface: loading → success,
  failure, stale result dropped, and pagination when it applies.
- **Screens** in the **layout matrix**: `pumpApp(tester, screen, size: kLayoutMatrix[...], locale: ...,
  textScale: 2.0)` for `small_phone`, `phone`, `tablet`, `large_tablet` and `landscape_phone`, in
  `ar` and `en`, then `expect(tester.takeException(), isNull)`.
- Pure logic (validators, mappers, policies) gets plain unit tests.

Helpers: `test/helpers/pump_app.dart` provides `pumpApp`, `pumpRouterApp` and `kLayoutMatrix`, with
real translations, the app theme, the damped text scaler and a chosen window size and locale. Pass
`settle: false` for widgets that animate forever.

Policy tests (`test/policy/`) scan `lib/` and guard the conventions repo-wide:

| Test | Fails on |
|---|---|
| `architecture_test.dart` | Forbidden imports (`core → shared/features`, `shared → features`, feature → feature, domain → Flutter/dio/bloc/go_router/get_it/data/presentation), `getIt` outside composition code, a feature without `data/domain/presentation` |
| `no_hardcoded_strings_test.dart` | String literals in `Text(...)` and in text parameters (`tooltip`, `hintText`, `labelText`, `label`...) |
| `l10n_parity_test.dart` | en/ar key, placeholder or plural-form mismatches, empty values, a `Failure` without a sentence in both languages |
| `color_literals_test.dart` | `Color(0x…)` / `Colors.x` outside `lib/core/theme/` |
| `font_size_test.dart` | `fontSize:` / `fontWeight:` outside `lib/core/theme/` |
| `rtl_directional_test.dart` | `EdgeInsets.only(left/right)`, `fromLTRB` with left ≠ right, `Alignment.*Left/*Right`, `Positioned(left/right)`, `TextAlign.left/right`... |
| `deprecated_api_test.dart` | [Deprecated APIs](#deprecated-apis), screenutil, dartz |

Related checks live next to their code: `test/core/theme/theme_contrast_test.dart` (WCAG contrast
of every palette pair) and `test/core/errors/failure_l10n_test.dart`. **Never weaken a policy test
or extend its allowlist to make a change pass.** Fix the code.

## Lints and banned APIs

`analysis_options.yaml` is strict: `strict-casts`, `strict-inference`, `strict-raw-types`,
`avoid_dynamic_calls`, `unawaited_futures`, `prefer_final_locals`, `require_trailing_commas`,
`prefer_single_quotes`, `directives_ordering`, `avoid_print`, `use_build_context_synchronously`,
`cancel_subscriptions`, `close_sinks`, and more. Overriding `BaseCubit.run` (`@nonVirtual`) is an
**error**. Every `// ignore:` needs a comment that explains why.

### Deprecated APIs

Banned in `lib/`. `test/policy/deprecated_api_test.dart` fails on `WillPopScope`, `withOpacity`,
`textScaleFactor`, `MaterialState*`, `ColorScheme.background/onBackground`, screenutil and dartz.
Its only allowlisted use is the override the framework requires
(`DampedTextScaler.textScaleFactor`). The `avoid_print` lint catches `print`. Review catches the
rest.

| Banned | Use |
|---|---|
| `WillPopScope` | `PopScope` / `DirtyGuard` |
| `color.withOpacity(x)` | `color.withValues(alpha: x)` |
| `MaterialStateProperty`, `MaterialState` | `WidgetStateProperty`, `WidgetState` |
| `textScaleFactor`, `TextScaler.noScaling` | the damped `TextScaler` (nothing to do) |
| `ColorScheme.background` / `onBackground` | `surface` / `onSurface` |
| `RadioListTile.groupValue` | `RadioGroup` |
| `DropdownButtonFormField.value` | `initialValue` |
| `state.extra as X` in routes | IDs in the path |
| `print`, `debugPrint` | `AppLogger` |
| `flutter_screenutil`, `dartz`, overlay toasts | tokens + breakpoints, `Result`, `AppSnackBar` |

## Git and CI

- Branches: `main` (releasable) and `dev`. Feature branches merge through PRs. CI
  (`.github/workflows/ci.yml`) runs on pushes to `main`/`dev` and on every PR.
- CI pins Flutter (`3.44.0`). Bump it in one PR, together with any code changes it needs.
- Commit messages are imperative and scoped: `items: map 422 errors to fields`.
- **Never commit**: `.env*` (except `.env.example`), keystores (`*.jks`, `*.keystore`),
  `key.properties`, `*.p8`/`*.p12`/`*.pem`, `google-services.json`, `GoogleService-Info.plist`,
  `lib/firebase_options*.dart`, `service-account*.json`. The template's `.gitignore` already covers
  them.
- Release builds read secrets from CI (base64 keystore, JSON service account as base64). See
  [NEW_PROJECT_CHECKLIST.md](NEW_PROJECT_CHECKLIST.md#11-ci-secrets).
- Build numbers only go up (`version: x.y.z+N`). The update gate compares `N`.
