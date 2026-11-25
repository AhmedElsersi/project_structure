---
description: Scaffold and implement a new feature following the template's items pattern (layers, translations, wiring, mocks, tests, green gate)
argument-hint: <feature_name> [with use cases]
---

Create the feature described by: **$ARGUMENTS**

You are working in a Flutter app created from `flutter_template`. Follow `CLAUDE.md` strictly.
The reference implementation is `lib/features/sample_feature/` ("items"). Mirror its structure,
naming and patterns, not just the scaffold.

## 0. Parse the arguments

- The **feature name** is the first word of the arguments, in `snake_case` (`order_history`). If it
  is missing or not snake_case, convert it (`Order History` → `order_history`) and tell the user.
  If you can't tell what it is, ask.
- **Use cases**: on only if the arguments contain "with use cases", "use cases" or `--use-cases`.
  Even then, keep a use case only where there is a rule or several repositories to orchestrate. No
  pass-through use cases.
- If the user described screens, fields or endpoints, use them. Otherwise build a minimal list
  (paginated) + details flow like items, and ask before inventing business fields.

## 1. Read before writing

1. `CLAUDE.md`, plus `docs/ARCHITECTURE.md` (sections Features, Use cases, Data flow, State,
   Routing, Dependency injection) if present.
2. The items feature: `items_di.dart`, `items_routes.dart`, `data/` (data source + `ItemsEndpoints`,
   model, mock API, repository impl), `domain/` (entity, repository interface, use case),
   `presentation/` (cubits, states, screens, widgets).
3. `lib/main.dart`, `lib/app_router.dart`, `lib/shared/screens/home_shell.dart`,
   `test/helpers/pump_app.dart`, and the existing items tests under `test/features/sample_feature/`
   (if present).
4. Confirm `lib/features/<name>/` does not exist yet.

## 2. Scaffold

```bash
dart run tool/create_feature.dart <name>              # or: ... <name> --use-cases
```

Keep its printed "Next steps" output; you will apply them in step 5. It creates the entity,
repository interface, model, remote data source + `<Name>Endpoints`, mock API, repository impl,
`DataCubit`, screen, `<name>_routes.dart` and `<name>_di.dart`, and adds `<name>.title` to both
translation files (English text in `ar.json` too, so translate it).

## 3. Implement the layers (items pattern)

Work from the inside out:

1. **Entity** (`domain/entities/`): pure Dart `Equatable`. Wire enums get an `unknown` fallback and
   `fromValue`, as `ItemStatus` does. No Flutter or JSON here.
2. **Repository interface** (`domain/repositories/`): every method returns `Future<Result<T>>`.
   `cancelToken` is typed `Object?` (the domain never imports Dio). Lists return `Result<Page<T>>`
   for a 1-based page.
3. **Model** (`data/models/`): `fromJson` with the `json_x` helpers, `tryParse` (bad rows are
   skipped), `fromResponse` (unwraps `{data: ...}`), request bodies (`createBody`), `toEntity()`.
4. **Data source** (`data/data_sources/`): `<Name>Endpoints` with relative paths and builders, and
   calls through `ApiClient` with `parser:` and `cancelToken:`. It throws `Failure` (via
   `ApiClient`). Never use a raw Dio.
5. **Mock API** (`data/mock/<name>_mock_api.dart`, `register<Name>MockApi`): add it when there is no
   backend yet, or keep it for tests. Seed data goes in `assets/mocks/<name>.json` (fake data only).
   Support paging (`{data, meta: {current_page, last_page, total}}`), `q` search if relevant, 404
   for unknown ids, and **422** `{code, errors: {field: [msg]}}` for invalid input (messages
   follow `Accept-Language`).
6. **Repository impl** (`data/repositories/`): `with RepositoryGuard`, every method
   `guard(() async => ...)`, models mapped to entities, `CancelToken` narrowed from `Object?`.
7. **Use case** (only if justified): `call(...)` returns `Result`. It enforces the rule (field errors
   as `ValidationFailure`), then delegates.
8. **Cubits** (`presentation/managers/`):
   - list → `PaginatedCubit<T>` (`fetchPage`, `itemKey`; search with `debounce` +
     `renewCancelToken` + fresh state + `loadFirstPage`);
   - details → `DataCubit<T>` with the id as a constructor parameter;
   - form → `BaseCubit<XState>` with an immutable state (`isSubmitting`, `failure`, `created`,
     `fieldError(field)`, `generalFailure`). Every call goes through `run(...)`.
9. **Screens** (`presentation/screens/`), one public widget per file:
   - `AppScaffold`. Lists use `PaginatedListView` (grid via `LayoutBuilder` + `columnsForWidth`
     when ≥ 2 tiles fit), an empty state vs a "no results" state, and a refresh failure → snackbar
     in a `BlocListener`.
   - Details use `DataStateBuilder`. On tablets and unfolded foldables use `AdaptiveTwoPane` (see
     `ItemDetailsScreen`).
   - Forms use `Form` + `ScrollableFormBody` + `AppTextField` / `AppDropdown` / `AppDateField`
     with `Validators`, `errorText: state.fieldError('x')`, `DirtyGuard`, a busy `AppButton`,
     `AppSnackBar.error(state.generalFailure!)`, and pop with the result (the list calls
     `upsertLocal`).
   - Only theme text styles, `colorScheme` / `context.palette`, spacing tokens and Directional
     insets. No literals, no hardcoded strings, no `fontSize`.
10. **Routes** (`<name>_routes.dart`): path constants plus builders like `details(id)`, ids in the
    path, cubits created in `BlocProvider(create: (_) => getIt<...>()..load())`. Full-screen
    sub-routes take `parentNavigatorKey: rootNavigatorKey` (add a
    `routes({required rootNavigatorKey})` parameter, as `ItemsRoutes` does). Never use
    `state.extra`.
11. **DI** (`<name>_di.dart`): lazySingletons against interfaces for the data source, repository and
    use case. Factories / `registerFactoryParam` for cubits. Mock API only
    `if (getIt.isRegistered<MockInterceptor>())`. Register a notification link
    (`NotificationLinkResolver.register('<type>', ...)`) if pushes can open this feature.

## 4. Translations (Arabic + English)

- Add every user-facing string under the `<name>.*` namespace in **both**
  `assets/translations/ar.json` (natural Arabic) and `en.json`. Reuse `common.*`, `errors.*` and
  `states.*` instead of duplicating.
- Plurals need all Arabic forms (`zero`, `one`, `two`, `few`, `many`, `other`). Placeholders must
  match between the two files.
- Run `./tool/gen_locale_keys.sh`, then use `LocaleKeys.<name>_<key>.tr()` everywhere.

## 5. Wire it

- `lib/main.dart`: import `features/<name>/<name>_di.dart` and add `register<Name>Feature,` to
  `modules`.
- `lib/app_router.dart`: import the routes. Either add a `StatefulShellBranch(routes: <Name>Routes.routes(...))`
  **and** an `AdaptiveDestination` in `lib/shared/screens/home_shell.dart` at the same index (a new
  tab, with `nav.<name>` keys in both JSON files), or add the routes at the root / nested under an
  existing route.
- If the route needs a session, add its prefix to `RedirectConfig.protectedPrefixes` (only once the
  app has a sign-in route).

## 6. Tests (under `test/features/<name>/`)

1. **Repository**: a real `ApiClient` + `MockInterceptor(latency: Duration.zero)` +
   `register<Name>MockApi(mock)`, with `AuthTokenStore(MemorySecureStore())` and
   `AppLogger(enabled: false)` (copy `test/features/sample_feature/items_repository_test.dart`
   and the harness in `test/core/network/api_client_test.dart`).
   Cover success, paging/search, 404 → `NotFoundFailure`, and 422 → `ValidationFailure` with
   `fieldError`.
2. **Cubits**: `bloc_test` + a mocktail fake or an in-memory fake of the repository interface
   (see `test/features/sample_feature/support/fake_items_repository.dart`). Cover
   loading → success, failure, a stale or cancelled result being dropped, `loadNextPage`, search
   resetting the list, and form field errors vs general failure.
3. **Screens (layout matrix)**: for every `kLayoutMatrix` entry × `Locale('ar')` / `Locale('en')`,
   `pumpApp(tester, BlocProvider.value(value: cubit, child: const <Name>Screen()), size: ..., locale: ..., textScale: 2.0, wrapInScaffold: false)`,
   then `expect(tester.takeException(), isNull)`. Also add one interaction test (tap → navigation
   or submit → error under the field).
4. The use case, if any: rule rejected without calling the repository, then delegated when valid.

## 7. Finish means green

Run, fix and re-run until everything passes:

```bash
./tool/gen_locale_keys.sh
dart run tool/check_translations.dart
dart format lib test tool
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

Then report: the files created and changed, translation keys added, the wiring lines applied, any
mocked endpoints the backend must provide (method, path, request/response shape, 422 fields), and
anything left for the user to decide. Don't commit unless asked.
