# CLAUDE.md — rules for this Flutter app

This app was created from `project_structure/flutter_template`. These rules are **mandatory**.
Enforce them in every change you make, and flag violations you find in code you touch. The details
behind each rule are in `docs/` (ARCHITECTURE, CONVENTIONS, SERVICES, WIDGETS, PACKAGES). When a
rule and a request conflict, say so and ask. Don't silently break the rule.

## Commands

```bash
flutter pub get
flutter run --dart-define-from-file=.env              # never run without the env file
./tool/gen_locale_keys.sh                             # after ANY change to assets/translations/*.json
dart run tool/check_translations.dart                 # en/ar parity, placeholders, plurals, literal Text
dart format lib test tool                             # page width 120
flutter analyze --fatal-infos --fatal-warnings        # must report ZERO issues
flutter test                                          # all green
dart run tool/create_feature.dart <name> [--use-cases]
```

## Finish means green

A task is done only when **all** of these pass, in this order. Run them yourself and report the
result.

1. `./tool/gen_locale_keys.sh` (if translations changed)
2. `dart run tool/check_translations.dart`
3. `dart format lib test tool` (no diff left)
4. `flutter analyze --fatal-infos --fatal-warnings` → `No issues found!`
5. `flutter test` → all passed

Never weaken, skip or delete a test, lint or policy check to get green. Fix the code. Don't add
`// ignore:` without a written reason, and never to silence a rule from this file.

## Architecture and layering

- Feature-first. Each feature lives in `lib/features/<feature>/` with `data/` (data_sources, models,
  repositories, mock), `domain/` (entities, repository interfaces, **optional** use_cases),
  `presentation/` (managers = cubits/states, screens, widgets), `<feature>_di.dart` and
  `<feature>_routes.dart`. Copy the pattern of `lib/features/sample_feature/` (items).
- Imports flow one way: presentation → managers → domain ← data. **Forbidden**: `core → shared`,
  `core → features`, `shared → features`, one feature importing another feature's internals, and
  domain importing `package:flutter`, `dio`, `bloc`/`flutter_bloc`, `go_router`, `get_it`, data or
  presentation (`test/policy/architecture_test.dart`).
- Add a use case only when it holds logic (a rule, or orchestrating several repositories). Never add
  pass-through use cases.
- Reuse before you create. Check `docs/WIDGETS.md` and `docs/SERVICES.md` before writing a widget
  or helper. Promote to `lib/shared/` or `lib/core/` only when a second feature needs it.
- One public widget per file. Files are `snake_case`: `<name>_screen.dart`, `<name>_cubit.dart`,
  `<name>_state.dart`, `<feature>_di.dart`, `<feature>_routes.dart`.
- Every new file starts with the header comment: purpose, `// Source:` (template file, ticket or
  `new (<reason>)`) and optional `// See docs/...#anchor`.

## State

- Cubits only, and only these bases: **`BaseCubit<S>`**, **`DataCubit<T>` + `DataState<T>`** (load
  one thing), **`PaginatedCubit<T>` + `PaginatedState<T>`** (lists). Never create another base
  class. Never use `Bloc` with events unless asked.
- Every async call goes through `run(call, onLoading:, onSuccess:, onFailure:)`. Emit with
  `safeEmit`. Pass `cancelToken` to network calls. Use `debounce` / `renewCancelToken` for search.
  Never override `run`.
- States are immutable `Equatable`s. Clear nullable fields with explicit flags or fresh states,
  never `x ?? this.x`.
- No navigation, `BuildContext` or UI in cubits. Expose state and react in `BlocListener`.
- Cubits are created in route builders: `BlocProvider(create: (_) => getIt<XCubit>()..load())`.

## Result and Failure

- Data sources **throw `Failure`** (`ApiClient` already does). Repositories **return `Result<T>`**
  through `guard(() => ...)` (`with RepositoryGuard`) and never throw.
- Consume `Result` with `switch` (`Ok` / `Err`), `fold`, `when` or `run`. No dartz, no `Either`, no
  nullable-as-error.
- UI shows only `failure.displayMessage`, never `debugMessage`, `toString()`, exceptions or raw
  bodies. Forms put `ValidationFailure.fieldError('field')` into the field's `errorText`.
- Branch on failure **types** and `code`, never on message text. `CancelledFailure` is never shown.
- New failure type → a subclass in `lib/core/errors/failure.dart` + an `errors.*` key in both JSON
  files.

## Networking

- All HTTP goes through **`ApiClient`** (`get/post/put/patch/delete<T>(path, parser: ...)`). Never
  create a `Dio`, never use `http`, never prefix `BASE_URL`. Paths are relative constants
  (`<Feature>Endpoints`).
- Parse with the `parser:` callback + `json_x` helpers (`json.string`, `intOr`, `listOf`...). A
  parser that throws becomes a `ServerFailure`.
- Don't handle 401, 426 or 503 in features. The auth interceptor, `SessionCubit` and the app gate
  own them. Money-moving POSTs use `ApiClient.idempotent(ApiClient.newIdempotencyKey())`.
- Without a backend, add mock routes in `data/mock/<feature>_mock_api.dart`
  (`register<Feature>MockApi`), registered only `if (getIt.isRegistered<MockInterceptor>())`.
- Never log tokens, passwords or personal data. Use `AppLogger` (it redacts). No `print` or
  `debugPrint`.

## Dependency injection

- `getIt` from `lib/core/di/injector.dart`. Only `*_di.dart`, `*_routes.dart`, `lib/core/di/` and
  the composition root (`main.dart`, `bootstrap.dart`, `app.dart`, `app_router.dart`) call
  `getIt<T>()`. Every other class takes its dependencies through its **constructor**.
- Services, data sources, repositories and use cases → `registerLazySingleton` (against the
  **interface** type). Cubits → `registerFactory` / `registerFactoryParam`. Registration functions
  are `Future<void> register<Feature>Feature()`, awaited, and added to `main.dart`'s `modules`.
- Plugins sit behind interfaces in `lib/core/services/` so tests can fake them.

## Routing

- go_router. **IDs in the path** (`/items/:id`), read with `state.pathParameters['id']!`. Never
  pass objects through `state.extra`, and never cast `state.extra as X`.
- Each feature exposes `abstract final class <Feature>Routes` (paths, path builders, `routes()`).
  Tabs need a `StatefulShellBranch` in `app_router.dart` **and** a destination in `home_shell.dart`.
- The redirect (`computeRedirect`) stays **pure**: no context, no async, no side effects, and it is
  unit-tested. Sign-in and sign-out navigation happens through `SessionCubit` status. Never
  `context.go` after login or logout.

## Responsive (phones, tablets, foldables)

- Form factor = `MediaQuery.sizeOf(context).shortestSide`: phone < 600, tablet 600–839, large
  ≥ 840. Use `context.formFactor`, `context.responsive(phone:, tablet:, largeTablet:)`,
  `context.pageGutter` and `context.maxContentWidth`. Never cache sizes.
- **No flutter_screenutil** (`.w/.h/.sp`). Fixed logical pixels from `AppSpacing` / `AppRadii` /
  `AppSizes`.
- Grids and panes size from the parent: `LayoutBuilder` + `columnsForWidth(width)`. List/detail and
  hinge-aware layouts use `AdaptiveTwoPane`. Never put content across `context.separatingHinge`.
- **No orientation lock.** Every screen must work in landscape.
- Use `AppScaffold`, `MaxWidthBody`, `ScrollableFormBody`, `AdaptiveRow`, `showAppBottomSheet`
  (dialog on tablets) and `PaginatedListView(gridColumns:)`.

## Text scaling

- The system font size is **damped** globally: 50 % of the increase, clamped to **1.0–1.3**. Don't
  add your own clamp.
- **Never** use `TextScaler.noScaling`, `textScaleFactor` or `MediaQuery.withNoTextScaling`.
- Every layout must survive the 1.3 app scale at **320 px** width, in Arabic and English. Avoid
  fixed heights around text. When one is unavoidable, add `AppTextScale.extra(context, fontSize)`.
  Use `maxLines` + `overflow`, `Flexible`/`Expanded` and `Wrap`.

## RTL-first

- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`,
  `BorderRadiusDirectional` and `TextAlign.start/end`.
- **Never** use `EdgeInsets.only(left:/right:)`, `EdgeInsets.fromLTRB` with left ≠ right,
  `Alignment.*Left/*Right`, `Positioned(left:/right:)`, `BorderRadius.only(topLeft:…)` or
  `TextAlign.left/right`.
- Directional icons must mirror (`Icons.arrow_back`, `Icons.chevron_right` do; set
  `matchTextDirection: true` on images/SVGs).
- Force LTR **only** for emails, phones, numbers, codes, IBANs and URLs (`AppTextField(forceLtr: true)`,
  `textDirection: TextDirection.ltr`).

## Theming

- Text sizes and button styles exist **only in ThemeData** (`lib/core/theme/`). Use
  `Theme.of(context).textTheme.x` (+ `.copyWith(color:)`). **Never** write `fontSize:` or
  `fontWeight:` in widgets.
- Buttons: `AppButton` or `FilledButton` / `OutlinedButton` / `TextButton` / `IconButton` without
  `style:`. Destructive = `AppButtonVariant.danger`.
- Colours only from `Theme.of(context).colorScheme` and `context.palette` (`StatusTone` pairs).
  **No** `Color(0x…)` or `Colors.x` outside `lib/core/theme/` (`Colors.transparent` is allowed).
  Brand = `AppColors.brandSeed`.
- Dark mode must always work. Animations use `AppMotion.of(context, ...)`. Touch targets are ≥ 48.

## Localization

- **Arabic is the start locale; English is the second language and the fallback.** No hardcoded
  user-facing strings: use `LocaleKeys.<feature>_<key>.tr()` (`package:easy_localization/easy_localization.dart`
  + `core/localization/generated/locale_keys.g.dart`). Shared widgets take already-translated
  strings.
- Every key goes in **both** `assets/translations/ar.json` (real Arabic) and `en.json`, under the
  feature's namespace. Reuse `common.*` first. Then run `./tool/gen_locale_keys.sh`. Never edit
  `locale_keys.g.dart`.
- Plurals: `.plural(count, args: [...])` with all Arabic forms (zero, one, two, few, many, other).
- Numbers and dates go through `AppFormat` (Western digits by default, `DigitsPolicy`). Parse input
  with `AppFormat.parseNumber` / `DecimalInputFormatter` (they accept ٠-٩).

## Environment and secrets

- Config comes from `.env` via `--dart-define-from-file` → `AppEnv`. Every new variable goes into
  `.env.example` in the same change. Never read config any other way.
- **No secrets in the app or the repo**: everything compiled in is public. Never commit `.env*`
  (except `.env.example`), keystores, `key.properties`, Firebase configs or service accounts.
- Staging and prod must keep `USE_MOCKS=false` and an https `BASE_URL` (`AppEnv.validate()` fails
  closed). JSON credentials (path or base64) are for `tool/` and CI only, via
  `tool/json_credential.dart`.

## Testing bar

For every feature or behaviour change, add or update:
- **Repository** tests against `MockInterceptor` through a real `ApiClient` (success, 404, 422
  field errors).
- **Cubit** tests with `bloc_test` + mocktail fakes of the repository interface (loading → success,
  failure, stale result dropped, pagination when it applies).
- **Layout matrix** for new screens: `pumpApp(tester, screen, size: kLayoutMatrix[k]!, locale: ar|en,
  textScale: 2.0)` for every `kLayoutMatrix` entry, then `expect(tester.takeException(), isNull)`.
- Unit tests for pure logic (validators, mappers, policies, redirect rules).

Policy tests (`test/policy/`) guard layering, translations, literals, colours and RTL. Never relax
them.

## Banned APIs and packages

`WillPopScope` (use `PopScope`/`DirtyGuard`) · `withOpacity` (use `withValues(alpha:)`) ·
`MaterialStateProperty`/`MaterialState` (use `WidgetState*`) · `textScaleFactor` ·
`ColorScheme.background/onBackground` (use `surface/onSurface`) · `RadioListTile.groupValue` (use
`RadioGroup`) · `DropdownButtonFormField.value` (use `initialValue`) · `state.extra as X` · `print`
/ `debugPrint` · `flutter_screenutil` · `dartz` · `hydrated_bloc` · overlay toasts (use
`AppSnackBar`) · custom app bars/back buttons (use the themed `AppBar`). Don't add a dependency
without saying why and checking `docs/PACKAGES.md`. Firebase, push, crash reporting, IAP and maps
are opt-in recipes (`docs/SERVICES.md#optional-recipes`).

## Workflow

- New feature: `/new-feature <name>` (or `dart run tool/create_feature.dart <name> [--use-cases]`),
  then follow the items pattern.
- Read the files you change and their tests first. Keep diffs focused. Don't reformat unrelated
  code.
- Ask before: adding packages, changing `lib/core/` contracts, changing CI, or anything that touches
  signing, store or secrets.
- Don't commit or push unless asked. Never commit secrets or generated build output.
