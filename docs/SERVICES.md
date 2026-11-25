# Services and infrastructure

Every core piece of `flutter_template/lib/core/` (plus the `tool/` helpers that belong with them):
what it does, its API, a usage example and the source projects it came from. File paths are
relative to `flutter_template/`. Source projects are named by slug (see [COMPARISON.md](COMPARISON.md)).

Related: [ARCHITECTURE.md](ARCHITECTURE.md) (how the pieces fit) · [WIDGETS.md](WIDGETS.md) (UI on
top of them) · [CONVENTIONS.md](CONVENTIONS.md) (rules) · [PACKAGES.md](PACKAGES.md) (dependencies).

| Area | Section |
|---|---|
| Results and errors | [Result](#result) · [Failures](#failures) · [Error mapping](#error-mapping) · [RepositoryGuard](#repositoryguard) |
| Networking | [ApiClient](#apiclient) (interceptors, refresh, retry, headers, 426/503, Idempotency-Key, redaction) · [Mock backend](#mock-backend) |
| State | [Cubit bases](#cubit-bases) |
| Persistence and session | [Storage](#storage) · [Session](#session) |
| App-wide | [AppEnv](#appenv) · [Logging](#logging) · [ErrorReporter](#errorreporter) · [App config](#app-config) · [AppInfo](#appinfo) · [Connectivity](#connectivity) |
| Device | [Push](#push) · [Permissions](#permissions) · [ImagePickerService](#imagepickerservice) · [UrlService](#urlservice) |
| Utilities | [Validators](#validators) · [Formatters](#formatters) (+ digits, input formatters) · [JSON helpers](#json-helpers) · [Debouncer](#debouncer) · [Extensions](#extensions) |
| Tooling | [JsonCredential](#jsoncredential) |
| Opt-in | [Optional recipes](#optional-recipes) (Crashlytics, FCM push, IAP, maps/location) |

---

## Result

`lib/core/result/result.dart` — a sealed `Result<T>` returned by every repository and use case.
Zero dependencies; replaces dartz `Either<Failure, T>` (approved decision C1).

| API | Meaning |
|---|---|
| `Ok<T>(value)` / `Err<T>(failure)` | The two branches (`Result.ok(...)`, `Result.err(...)` also work) |
| `isOk`, `isErr`, `valueOrNull`, `failureOrNull` | Queries |
| `fold(onFailure, onSuccess)` | dartz argument order, so old `result.fold((f) => ..., (v) => ...)` call sites read the same |
| `when(ok:, err:)` | Named-argument fold |
| `map`, `flatMap`, `andThen` (async), `mapFailure`, `getOrElse` | Combinators; failures short-circuit |
| `FutureResult<T>` | `Future<Result<T>>` alias |
| `Unit.value`, `okUnit` | Success without data (`Future<Result<Unit>> delete(id)`) |

```dart
switch (await repository.byId(id)) {
  case Ok(:final value):
    safeEmit(state.success(value));
  case Err(:final failure):
    safeEmit(state.failed(failure));
}

final label = result.fold((f) => f.displayMessage, (item) => item.title);
final total = await cart.load().andThen((c) => pricing.quote(c)); // chain fallible steps
```

Rules: repositories never throw, they return `Result`. Cubits consume it through
[`BaseCubit.run`](#cubit-bases), which already handles both branches and ignores
`CancelledFailure`.

Sources: new (no in-scope app had a sealed result). It replaces dartz in brgr, tebbr,
chinaparts-customer, chinaparts-seller, corsa-customer, corsa-driver, instaops, petrobe and baytna.

## Failures

`lib/core/errors/failure.dart` — a sealed `Failure` hierarchy (`implements Exception`, `Equatable`).
Data sources **throw** failures; repositories **return** them in `Err`; the UI shows
`failure.displayMessage`.

| Field / getter | Meaning |
|---|---|
| `serverMessage` | Message from the backend, already in the request's `Accept-Language`. Wins over the bundled sentence when not blank |
| `code` | Backend error code (`email_taken`) for branching in the UI |
| `debugMessage` | Developer detail for logs. **Never shown to users** |
| `messageKey` | Translation key of the generic sentence (`errors.*`) |
| `displayMessage` | `serverMessage` if any, else `messageKey.tr()`. `UnknownFailure` always shows the generic sentence |

| Subclass | When | Extra |
|---|---|---|
| `NetworkFailure` | No connection, DNS, socket closed, bad certificate | |
| `TimeoutFailure` | Connect/send/receive timeout, HTTP 408/504, "timed out" bodies | |
| `CancelledFailure` | Request cancelled (screen closed, newer search). **Never shown** | |
| `UnauthorizedFailure` | 401 after the refresh attempt | |
| `ForbiddenFailure` | 403 (never signs the user out) | |
| `NotFoundFailure` | 404 or a missing local record | |
| `ConflictFailure` | 409 / 410 | |
| `ValidationFailure` | 400 / 422 or local validation | `fieldErrors`, `fieldError(field)`, `hasFieldErrors` |
| `RateLimitedFailure` | 429 | `retryAfter` from the `Retry-After` header |
| `UpgradeRequiredFailure` | 426: the app gate shows force update | |
| `MaintenanceFailure` | 503: the app gate shows maintenance | |
| `ServerFailure` | Other 5xx, unreadable body, parser crash | `statusCode` |
| `StorageFailure` | Local storage read/write failed | |
| `PermissionFailure` | A device permission was denied | `permanentlyDenied` |
| `UnknownFailure` | Anything unexpected; text only in `debugMessage` | |

```dart
// Form: put server field errors under the right input.
final failure = state.failure;
AppTextField(
  label: LocaleKeys.items_title.tr(),
  errorText: failure is ValidationFailure ? failure.fieldError('title') : null,
);

// Branch on a backend code.
if (failure.code == 'email_taken') { ... }
```

Every `messageKey` exists in `assets/translations/en.json` and `ar.json` under `errors.*`
(tested by `test/core/errors/failure_l10n_test.dart`). Add a new subclass only together with its
key in both files.

Sources: baytna `core/errors/failures.dart` (translation key, never user text); corsa-customer
`core/utilities/failures/failure.dart` (status code, backend `code`, `fieldError`); brgr
`failure.dart` (never show raw errors); markspulse `failure_messages.dart` (every failure has a
sentence, enforced by a test). Rejected: English text inside failures (lexa), `CacheFailure` that
dropped its message (house style).

## Error mapping

`lib/core/errors/error_mapper.dart` — `ErrorMapper` turns anything thrown into a `Failure`.
`ApiClient` and `RepositoryGuard` call it for you; you rarely call it directly.

| Method | Input → output |
|---|---|
| `fromObject(Object)` | `Failure` passes through; `DioException` → `fromDio`; `SocketException`/`HttpException` → `NetworkFailure`; `TimeoutException` → `TimeoutFailure`; `FormatException` → `ServerFailure`; `PlatformException` and the rest → `UnknownFailure` |
| `fromDio(DioException)` | A `Failure` attached by an interceptor wins; timeouts → `TimeoutFailure`; `connectionError`/bad certificate → `NetworkFailure`; `cancel` → `CancelledFailure`; a response → `fromResponse` |
| `fromResponse(Response)` | Status table below. Reads the envelope `{message \| error, code, errors}` |
| `parseFieldErrors(Map)` | Validation shapes: `errors: {field: [..]}`, `errors: {field: ".."}`, `errors: [{field\|key\|param, message\|msg\|messages}]`, `data: {...}`, or field arrays at the top level |

| Status | Failure |
|---|---|
| 400, 422 | `ValidationFailure(fieldErrors, serverMessage, code)` |
| 401 | `UnauthorizedFailure` |
| 403 | `ForbiddenFailure` |
| 404 | `NotFoundFailure` |
| 408, 504 | `TimeoutFailure` |
| 409, 410 | `ConflictFailure` |
| 426 | `UpgradeRequiredFailure` |
| 429 | `RateLimitedFailure(retryAfter)` |
| 503 | `MaintenanceFailure` |
| other | `ServerFailure(statusCode)`. The server message is kept only below 500; an HTML/plain 5xx body goes to `debugMessage` (truncated to 300 chars), never parsed as JSON |

```dart
// Mapping a non-HTTP exception in a local data source:
try {
  return await _box.read(id);
} on Object catch (e) {
  throw ErrorMapper.fromObject(e); // or a specific StorageFailure(debugMessage: '$e')
}
```

Sources: corsa-customer `base_remote_data_source.dart` (status + backend code + field errors,
HTML 5xx bodies, timeout bodies, cancel); chinaparts-seller (seven validation-error shapes); brgr
(never show raw errors). Rejected: 401-only and 422-less variants.

## RepositoryGuard

`lib/core/data/repository_guard.dart` — a mixin that wraps a data-source call into `Result`.

```dart
class ItemsRepositoryImpl with RepositoryGuard implements ItemsRepository {
  ItemsRepositoryImpl(this._remote);
  final ItemsRemoteDataSource _remote;

  @override
  Future<Result<Item>> byId(String id) => guard(() => _remote.byId(id));
}
```

- A thrown `Failure` becomes `Err(failure)`.
- Anything else goes through `ErrorMapper.fromObject`. If the result is `UnknownFailure` or
  `ServerFailure`, it is also sent to `RepositoryGuard.onUnexpectedError`. DI wires that sink to
  `ErrorReporter.recordError(reason: 'repository')`, so a `TypeError` in a parser gets reported
  and is not swallowed.

Sources: chinaparts-customer `base_architecture/data/repository/base_repo.dart` (also catches
non-Failure throws and reports them). Rejected: house-style versions that caught only `Failure`.

## ApiClient

`lib/core/network/api_client.dart` — the **only** HTTP client features use. It throws `Failure`.
Repositories wrap its calls in `guard`.

```dart
// lib/features/sample_feature/data/data_sources/items_remote_data_source.dart (abridged)
class ItemsRemoteDataSource {
  ItemsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Page<ItemModel>> fetchPage(int page, {String? query, CancelToken? cancelToken}) => _api.get(
    ItemsEndpoints.items, // '/items'
    query: {'page': page, if (query != null && query.isNotEmpty) 'q': query},
    cancelToken: cancelToken,
    parser: (json) => Page.fromJson(json, ItemModel.fromJson),
  );

  Future<ItemModel> byId(String id, {CancelToken? cancelToken}) =>
      _api.get(ItemsEndpoints.item(id), cancelToken: cancelToken, parser: ItemModel.fromResponse);

  Future<ItemModel> create(CreateItemInput input) =>
      _api.post(ItemsEndpoints.items, data: ItemModel.createBody(input), parser: ItemModel.fromResponse);
}
```

| Method | Notes |
|---|---|
| `get<T>(path, {required parser, query, options, cancelToken})` | Retried on network errors (see below) |
| `post<T>(path, {required parser, data, query, options, cancelToken, onSendProgress})` | `data` may be a `FormData` for uploads |
| `put`, `patch`, `delete<T>(path, {required parser, data, options, cancelToken})` | |
| `parser: (Object? json) => T` | Runs on the decoded body. If it throws, you get a `ServerFailure` (logged) and no red screen |
| `ApiClient.idempotent(key)` / `ApiClient.newIdempotencyKey()` | `Idempotency-Key` header for money-moving POSTs; reuse the same key when retrying |
| `dio` | The configured `Dio`, for uploads/downloads that need it. Prefer the typed methods |

Paths are **relative**: app-level ones in `ApiEndpoints` (`lib/core/network/api_endpoints.dart`),
feature ones in the feature's data source (`ItemsEndpoints`). Dio already
holds the base URL, so never prefix `BASE_URL` (that was a house-style bug). Timeouts are 20 s
connect and 30 s receive/send. The house style used 5 minutes.

```dart
// Payment: one key per user intent, reused on retry.
final key = ApiClient.newIdempotencyKey();
await _api.post('/orders/$id/pay', data: body, options: ApiClient.idempotent(key), parser: Receipt.fromJson);
```

### Interceptors

Order on the main `Dio` (requests run top to bottom):

| # | Interceptor | File | Does |
|---|---|---|---|
| 1 | `AppHeadersInterceptor` | `interceptors/app_headers_interceptor.dart` | `Accept: application/json`, `Accept-Language` from `CurrentLocale` (read per request), `X-Platform`, `X-App-Version`, `X-Build-Number` from `AppInfo.headers` |
| 2 | `AuthInterceptor` | `interceptors/auth_interceptor.dart` | `Authorization: Bearer <token>` from `AuthTokenStore`; **one shared refresh** for concurrent 401s (a `QueuedInterceptorsWrapper`) |
| 3 | `RetryInterceptor` | `interceptors/retry_interceptor.dart` | Retries **GET only**, on `connectionError`/`connectionTimeout`/`receiveTimeout`, 2 times, 400 ms × attempt |
| 4 | `AppStatusInterceptor` | `interceptors/app_status_interceptor.dart` | 426 → `AppStatusSignal.upgradeRequired`, 503 → `maintenance`, sent to `AppStatusBus` |
| 5 | `TalkerDioLogger` | talker_dio_logger | Debug logs; `Authorization` and `Cookie` hidden; bodies only with `VERBOSE_LOGS=true`; never bodies of `/auth/` paths |
| 6 | `MockInterceptor` (when `AppEnv.useMocks`) | `mock/mock_interceptor.dart` | Answers before any socket opens (see [Mock backend](#mock-backend)) |

A second, "bare" `Dio` (headers + logger + mock only) does refresh calls and retries, so they never
deadlock behind the queued auth interceptor.

### Token refresh

`AuthInterceptor.onError` on a 401:

1. It skips the request if no token was sent, the path is in `ApiEndpoints.noRefreshPaths`
   (`/auth/login`, `/auth/refresh`) or the request was already retried.
2. If another queued request already refreshed (the token changed), it retries with the new token.
3. Otherwise it calls `TokenRefresher.refresh(refreshToken)`. On success it saves the tokens and
   retries on the bare `Dio`.
4. On failure it calls `tokens.clear()` and `onSessionExpired()` (wired to `SessionCubit.expire`)
   once. The router redirect then takes over.

| `TokenRefresher` | Use |
|---|---|
| `DioTokenRefresher` (default) | `POST /auth/refresh {refresh_token}`, reads `access_token` / `refresh_token` from `data` or the root |
| `NoTokenRefresher` | APIs without refresh tokens: a 401 always ends the session |
| your own | Implement `Future<AuthTokens?> refresh(String refreshToken)` and pass `refresher:` to `ApiClient` in `injector.dart` |

A 403 never signs the user out (corsa rule).

### 426 / 503

`AppStatusInterceptor` → `AppStatusBus.events` → `AppConfigCubit`, which raises the full-screen
force-update or maintenance gate from **any** endpoint. See [App config](#app-config). The
request still fails with `UpgradeRequiredFailure` / `MaintenanceFailure`.

### Logging redaction

Network logs go to `AppLogger.talker` (debug builds only). Headers `authorization` and `cookie`
are hidden, `/auth/` bodies are never printed, and every message through `AppLogger` passes
`AppLogger.redact` (see [Logging](#logging)).

Sources: corsa-customer `core/services/api_service.dart` (one Dio plus a bare Dio, queued single
refresh, GET retry, 426/503 hook, `onSessionExpired`, redacted Authorization, Idempotency-Key, mock
interceptor last); corsa-customer `base_remote_data_source.dart` (typed parse step); chinaparts-customer
(`X-Platform` / `X-App-Version` / `X-Build-Number` + `Accept-Language`; only a request that carried a
token can expire the session); petrobe (sensitive paths kept out of logs). Rejected: 5-minute
timeouts, a static API-key header (petrobe), absolute `$BASE_URL/...` paths.

## Mock backend

`lib/core/network/mock/mock_interceptor.dart` — an offline backend inside Dio. It is registered in
DI when `AppEnv.useMocks` is true (the default when `BASE_URL` is empty), so a fresh clone runs
with no server. The base URL is then `https://mock.local/api`, and nothing reaches the network.

| API | Meaning |
|---|---|
| `MockInterceptor({latency = 350 ms, bundle})` | Simulated latency |
| `on(method, pattern, handler)` | `pattern` is relative to the base URL; `:id` segments become `params['id']` |
| `serveAsset(pattern, assetPath)` | `GET pattern` answered with a JSON file from `assets/mocks/` |
| `loadJson(assetPath)` | Load a fixture inside a handler |
| `failNext([statusCode = 500])` | Next request fails (dev menus, tests) |
| `MockResponse(data, {statusCode, headers})` | Handler result; non-2xx becomes a `DioException.badResponse` |
| `MockResponse.error(status, message, {code, errors})` | Backend-style error body (`{message, code, errors}`) |

An unmatched request returns 404 `No mock for GET /x`. A handler that throws returns 500.

Register a feature's routes next to the feature, inside its `register<X>Feature()`. The sample
feature does it in `data/mock/items_mock_api.dart` (`registerItemsMockApi(mock)`: paging + search
over `assets/mocks/items.json`, 404, and 422 field errors in the request's language). A smaller
example:

```dart
// lib/features/orders/orders_di.dart
if (getIt.isRegistered<MockInterceptor>()) {
  final mock = getIt<MockInterceptor>();
  final store = <String, Map<String, Object?>>{};
  mock
    ..serveAsset('/orders', 'assets/mocks/orders_page_1.json')
    ..on('GET', '/orders/:id', (req, p) async =>
        store[p['id']] == null ? MockResponse.error(404, 'Not found') : MockResponse({'data': store[p['id']]}))
    ..on('POST', '/orders', (req, _) async {
      final body = asJsonMap(req.data) ?? const {};
      if ((body['title'] as String? ?? '').trim().isEmpty) {
        return MockResponse.error(422, 'Invalid data', errors: {'title': ['Title is required.']});
      }
      final id = '${store.length + 1}';
      store[id] = {...body, 'id': id};
      return MockResponse({'data': store[id]}, statusCode: 201);
    });
}
```

`registerServicesModule` serves `GET /app-config` from `assets/mocks/app_config.json`. Raise `min_build` or
set `maintenance: true` there to try the gate. The mock sits **last**, so headers and auth run
first and the response/error interceptors still see mocked 401/426/503 responses.

Turn mocks off with `USE_MOCKS=false` and a real `BASE_URL`. Staging and prod builds refuse to start
with mocks on (see [AppEnv](#appenv)).

Sources: corsa-driver `core/services/mock/mock_api_interceptor.dart` + `mock_route_table.dart`
(route table, asset fixtures, latency, forced failures). This is the better of the two corsa
copies.

## Cubit bases

The only allowed bases. Details and diagrams: [ARCHITECTURE.md#state](ARCHITECTURE.md#state).

### BaseCubit

`lib/core/presentation/base_cubit.dart` — `abstract class BaseCubit<S> extends Cubit<S>`.

| Member | Meaning |
|---|---|
| `run<T>(call, {onLoading, required onSuccess, required onFailure})` | `@nonVirtual`. Runs a `Future<Result<T>>`. A result that arrives after a newer `run`, after `invalidatePending()` or after `close()` is **dropped**. `CancelledFailure` is never passed to `onFailure`. A throw becomes `UnknownFailure` |
| `safeEmit(state)` | Emits only while open |
| `cancelToken` / `renewCancelToken()` | Pass to `ApiClient`; cancelled on `close()`; renew to cancel the previous search |
| `debounce(duration, action)` | Last call wins |
| `invalidatePending()` | Drop results of requests already in flight (e.g. on reset) |

```dart
// lib/features/sample_feature/presentation/managers/create_item_cubit.dart
class CreateItemCubit extends BaseCubit<CreateItemState> {
  CreateItemCubit(this._createItem) : super(const CreateItemState());
  final CreateItemUseCase _createItem;

  Future<void> submit(CreateItemInput input) async {
    if (state.isSubmitting) return;
    await run<Item>(
      () => _createItem(input),
      onLoading: () => safeEmit(const CreateItemState(isSubmitting: true)),
      onSuccess: (item) => safeEmit(CreateItemState(created: item)),
      onFailure: (failure) => safeEmit(CreateItemState(failure: failure)),
    );
  }
}
```

### DataCubit and DataState

`lib/core/presentation/data_cubit.dart`, `data_state.dart` — for "load one thing" screens with no
custom state class.

```dart
class ItemDetailsCubit extends DataCubit<Item> {
  ItemDetailsCubit(this._repository, {required this.id});
  final ItemsRepository _repository;
  final String id;

  @override
  Future<Result<Item>> fetch() => _repository.byId(id, cancelToken: cancelToken);
}
// route: BlocProvider(create: (_) => getIt<ItemDetailsCubit>(param1: id)..load(), child: ItemDetailsScreen(id: id))
```

`DataState<T>` has `status` (`initial | loading | success | failure`), `data` and `failure`, with
`isLoading`, `isRefreshing` (loading with data), `hasData`, and so on. `loading()` and `failed()`
**keep the previous data**, so a refresh never blanks the screen. Render it with
[`DataStateBuilder`](WIDGETS.md#states).

### PaginatedCubit and PaginatedState

`lib/core/pagination/paginated_cubit.dart`, `page.dart` — infinite lists. See
[ARCHITECTURE.md#pagination](ARCHITECTURE.md#pagination).

```dart
// lib/features/sample_feature/presentation/managers/items_list_cubit.dart (abridged)
class ItemsListCubit extends PaginatedCubit<Item> {
  ItemsListCubit(this._repository, {this.searchDelay = const Duration(milliseconds: 400)});
  final ItemsRepository _repository;
  final Duration searchDelay;
  String _query = '';

  @override
  Future<Result<Page<Item>>> fetchPage(int page) =>
      _repository.fetchPage(page, query: _query.isEmpty ? null : _query, cancelToken: cancelToken);

  @override
  Object itemKey(Item item) => item.id;

  void search(String text) {
    final next = text.trim();
    debounce(searchDelay, () {
      if (next == _query) return;
      _query = next;
      renewCancelToken();                     // cancel the old query's request
      safeEmit(const PaginatedState<Item>()); // old results don't match the new query
      unawaited(loadFirstPage());
    });
  }
}
```

| Member | Meaning |
|---|---|
| `loadFirstPage()` / `refresh()` | Page 1. Items stay on screen while refreshing; a failed refresh keeps them (`status: success` + `failure` for a snackbar) |
| `loadNextPage()` | Safe on every scroll event (guards `hasMore`, `isLoadingMore`, status) |
| `upsertLocal(item)` / `removeLocal(key)` | Patch the list after create/edit/delete without reloading |
| `PaginatedState` | `items`, `status` (`initial \| loadingFirst \| success \| failure`), `page`, `hasMore`, `isLoadingMore`, `failure`, `loadMoreFailure`, `isEmpty`, `isRefreshing` |
| `Page<T>` | `items`, `page` (1-based), `hasMore`, `total`. `Page.fromJson(json, Item.fromJson)` reads `{data, meta: {current_page, last_page, total}}`, the same keys at the root, `items`, or `has_more` |

Items are de-duplicated by `itemKey` across pages. Render with
[`PaginatedListView`](WIDGETS.md#lists).

Sources: corsa-customer `base_single_class_state_cubit.dart` (safeEmit, CancelToken, debounce) and
`paginated_list_view.dart` (inline load-more retry); chinaparts-customer (epoch guard: stale results
dropped); chinaparts-seller `request_generation.dart` + `fill_viewport_paging.dart` (stale-response
tickets, appendUnique, viewport fill); markspulse `domain/common/page.dart` (`Page<T>`, hasMore).
Rejected: a second base class (D1), `failure ?? this.failure` copyWith that could never clear a
failure, `as State` casts, and 46+ copy-pasted scroll listeners (D18).

## Storage

`lib/core/storage/` — interfaces with production and in-memory implementations. Features never
import `shared_preferences` or `flutter_secure_storage`.

| Type | File | Use for |
|---|---|---|
| `KeyValueStore` | `key_value_store.dart` | Non-sensitive settings: `get/setString`, `Bool`, `Int`, `Double`, `StringList`, `getJson/setJson`, `containsKey`, `remove`, `clear({keep})` |
| `SharedPrefsKeyValueStore.create()` | | Production, on `SharedPreferencesWithCache` (synchronous reads). A key reused with another type returns `null` instead of throwing |
| `MemoryKeyValueStore([initial])` | | Tests and previews |
| `SecureStore` | `secure_store.dart` | Tokens and secrets: `read`, `write`, `delete`, `deleteAll` |
| `FlutterSecureStore([storage])` | | Production. **Self-healing**: an unreadable entry is dropped, and a failed write wipes the store and retries once, so a corrupted Android keystore never bricks the app |
| `FlutterSecureStore.wipeOnFirstLaunch(prefs, secure)` | | iOS keeps Keychain items after uninstall; DI wipes them on the first run |
| `MemorySecureStore` | | Tests |
| `AuthTokenStore` / `AuthTokens` | `auth_token_store.dart` | Access and refresh tokens, cached in memory for the interceptor: `load`, `save`, `clear`, `accessToken`, `refreshToken`, `hasSession` |
| `StorageKeys` | `storage_keys.dart` | **Every** persisted key. `deviceScoped` lists keys that survive sign-out |

```dart
class OnboardingStore {
  OnboardingStore(this._store);
  final KeyValueStore _store;
  bool get seen => _store.getBool(StorageKeys.onboardingSeen) ?? false; // add the key to StorageKeys
  Future<void> markSeen() => _store.setBool(StorageKeys.onboardingSeen, true);
}

// On sign-out, keep device preferences:
await keyValueStore.clear(keep: StorageKeys.deviceScoped);
```

Never store passwords ("remember me" in brgr, instaops and tebbr stored the plain password).

Sources: baytna `core/services/settings_store.dart` (interface + fake); brgr / instaops
`secure_storage_manager.dart` (self-heal); chinaparts-customer `main.dart` (first-launch keychain
wipe); corsa-customer `api_service.dart` (tokens read once, kept in memory); chinaparts-seller
`shared_preferences_keys.dart` (central key registry).

## Session

`lib/core/session/session_cubit.dart` — `SessionCubit` is the single source of truth for "who is
signed in". The router redirect depends only on its status. Screens never navigate after sign-in or
sign-out. Diagram: [ARCHITECTURE.md#session](ARCHITECTURE.md#session).

| Member | Meaning |
|---|---|
| `SessionState.status` | `unknown` (before `restore`), `unauthenticated`, `authenticated` |
| `SessionState.generation` | Increments on every sign-in/out. Use as a `ValueKey` to rebuild per-user state |
| `SessionState.expired` | The session ended because the server rejected the token (show "please sign in again") |
| `restore()` | Called once in bootstrap: loads tokens and runs start hooks if signed in |
| `signedIn(AuthTokens)` | Call from your auth feature after a successful login |
| `signOut({expired})` | Single-flight. Runs end hooks, clears tokens, emits `unauthenticated` |
| `expire()` | Called by `AuthInterceptor` when refresh fails |
| `addHooks({onStart, onEnd})` | Features register work (clear caches, (un)register a push token, clear `PendingLink`) without core importing them. A failing hook never blocks sign-in/out |

```dart
// lib/features/auth/auth_di.dart
Future<void> registerAuthFeature() async {
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(AuthRemoteDataSource(getIt<ApiClient>())));
  getIt.registerFactory<SignInCubit>(() => SignInCubit(getIt<AuthRepository>(), getIt<SessionCubit>()));
  getIt<SessionCubit>().addHooks(
    onEnd: () async {
      getIt<PendingLink>().clear();
      await getIt<KeyValueStore>().clear(keep: StorageKeys.deviceScoped);
    },
  );
}

// SignInCubit.onSuccess:
await _session.signedIn(AuthTokens(accessToken: r.access, refreshToken: r.refresh)); // router redirects
```

Being offline never signs the user out. Only a failed refresh (`expire`) or an explicit `signOut`
does.

Sources: baytna `app/session/session_cubit.dart` (status drives the router); chinaparts-seller
`session_service.dart` (single-flight sign-out, generation counter); corsa-customer `main.dart`
(start/end hooks so core never imports feature cubits); lexa (offline never signs out). Rejected:
splash-decides navigation and per-screen 401 listeners.

## AppEnv

`lib/core/config/app_env.dart` — compile-time configuration from `.env` via
`--dart-define-from-file=.env`. Full rules: [CONVENTIONS.md#environment](CONVENTIONS.md#environment).

| Getter | From | Notes |
|---|---|---|
| `AppEnv.flavor` | `APP_FLAVOR` | `dev` (default) / `staging` / `prod`. An unknown value throws `AppEnvError` |
| `AppEnv.baseUrl` | `BASE_URL` | e.g. `https://api.example.com/v1` |
| `AppEnv.useMocks` | `USE_MOCKS` | Explicit `true`/`false`; when unset, `true` iff `BASE_URL` is empty |
| `AppEnv.effectiveBaseUrl` | | `baseUrl`, or `https://mock.local/api` in mock mode |
| `AppEnv.androidStoreUrl`, `iosStoreUrl`, `storeUrl` | `ANDROID_STORE_URL`, `IOS_STORE_URL` | Fallback store links for the update gate |
| `AppEnv.verboseLogs` | `VERBOSE_LOGS` | Bloc transitions and HTTP bodies in debug logs |
| `AppEnv.validate()` | | **Fails closed**: staging/prod with mocks on or a non-https `BASE_URL` throws. Bootstrap then shows `ConfigErrorApp` instead of the app |

Adding a variable: put it in `.env.example` (with a placeholder), add a
`static const x = String.fromEnvironment('X')` here, and validate it in `validate()` if a flavor
needs it. Anything compiled in is **public**: never put server secrets in `.env`.

Sources: corsa-customer `core/utilities/constants/keys/api_keys.dart` (`AppEnv`, define-from-file,
`USE_MOCKS` defaults on without `BASE_URL`); markspulse `app/environment.dart` (unknown env throws).
Rejected: hardcoded `ApiKeys.BASE_URL` (8 apps).

## Logging

`lib/core/logging/app_logger.dart` — `AppLogger`, a facade over Talker. It is enabled only in debug
builds and **redacts** secrets.

| API | |
|---|---|
| `debug`, `info`, `warning(msg, [error, stack])`, `error(msg, [error, stack])` | Leveled logs (message redacted) |
| `handle(error, [stack, context])` | Log an exception |
| `talker` | For `TalkerDioLogger`, `TalkerRouteObserver`, or a `TalkerScreen` in a debug menu (talker_flutter) |
| `AppLogger.redact(String)` | Hides `access_token`, `refresh_token`, `id_token`, `token`, `password`, `secret`, `api_key`, `authorization` values (JSON or `key=value`), `Bearer/Basic/Token` credentials, bare JWTs and email addresses |

`lib/core/logging/app_bloc_observer.dart` — `AppBlocObserver` logs transitions only with
`VERBOSE_LOGS=true` in debug, and sends every bloc error to `ErrorReporter`
(`reason: 'bloc:<Type>'`). Bootstrap installs it.

Rules: no `print` (lint `avoid_print`) and no `debugPrint` outside bootstrap's pre-DI fallback.
Never log tokens: tebbr logged bearer tokens and petrobe logged the API token at splash.

Sources: lexa-student `core/error/error_log.dart` (one pluggable facade); corsa-customer
(Authorization hidden); petrobe (path filters); chinaparts-customer (talker debug-only,
`bloc_observer.dart`). Rejected: print/debugPrint logging (brgr, tebbr, instaops, petrobe) and
release-mode bloc logging (D17).

## ErrorReporter

`lib/core/services/error_reporter.dart` — the crash/error reporting facade. The template ships
`ConsoleErrorReporter` (logs through `AppLogger`). Production apps plug in Crashlytics or Sentry by
implementing the interface. Firebase is opt-in (decision C7).

```dart
abstract interface class ErrorReporter {
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false, String? reason});
  Future<void> setUserId(String? id);
  void log(String message);
}
```

Already wired in `bootstrap.dart`:

| Hook | Fatal | `reason` |
|---|---|---|
| `FlutterError.onError` | no | `flutter` |
| `PlatformDispatcher.instance.onError` | yes | `platform` |
| `runZonedGuarded` | yes | `zone` |
| `RepositoryGuard.onUnexpectedError` | no | `repository` |
| `AppBlocObserver.onError` | no | `bloc:<Type>` |

### Crashlytics recipe (opt-in)

1. Add `firebase_core` and `firebase_crashlytics` (versions: [PACKAGES.md#opt-in-packages](PACKAGES.md#opt-in-packages)).
   Run `flutterfire configure`, which generates `lib/firebase_options.dart`, `google-services.json`
   and `GoogleService-Info.plist`. All three are gitignored by the template; in CI, restore them
   from secrets.
2. Add the reporter:

```dart
// lib/core/services/crashlytics_error_reporter.dart
// Crashlytics implementation of ErrorReporter (opt-in module).
//
// Source: chinaparts-customer lib/core/services/error_reporter.dart (facade, release-only).
import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';
import 'error_reporter.dart';

class CrashlyticsErrorReporter implements ErrorReporter {
  CrashlyticsErrorReporter(this._logger, [FirebaseCrashlytics? crashlytics])
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final AppLogger _logger;
  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false, String? reason}) async {
    _logger.error('${fatal ? 'FATAL' : 'Non-fatal'} ($reason)', error, stack);
    if (kDebugMode) return; // keep the dashboard for real users
    await _crashlytics.recordError(error, stack, fatal: fatal, reason: reason);
  }

  @override
  Future<void> setUserId(String? id) => _crashlytics.setUserIdentifier(id ?? '');

  @override
  void log(String message) => unawaited(_crashlytics.log(AppLogger.redact(message)));
}
```

3. Wire it in `bootstrap.dart`. Firebase must initialise **before** DI, and `registerCoreDependencies`
   already accepts an `errorReporter`:

```dart
await EasyLocalization.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode);

// The reporter gets its own AppLogger (debug console only); DI registers the app's logger separately.
await registerCoreDependencies(errorReporter: CrashlyticsErrorReporter(AppLogger()));
```

4. Set the user from your auth feature: `getIt<ErrorReporter>().setUserId(user.id)` after sign-in,
   and `setUserId(null)` in a session `onEnd` hook.
5. Android: add the Crashlytics Gradle plugin as the FlutterFire docs describe. iOS: add the dSYM
   upload run script. Test with a forced crash in a **release** build.

Sources: chinaparts-customer `core/services/error_reporter.dart` q5 (facade; FlutterError non-fatal,
zone/platform fatal, release only). brgr, tebbr, baytna, corsa ×2 and instaops used Crashlytics
directly.

## Push

`lib/core/services/push/` — push notifications behind an interface. The template ships
`NoopPushService`, so it builds and tests with no Firebase account. Firebase Messaging is an opt-in
recipe.

### PushService

```dart
abstract interface class PushService {
  Future<void> init();                                // channels, handlers; idempotent
  Future<bool> requestPermission();                   // OS prompt; true = may show
  Stream<String?> get tokenStream;                    // now + every refresh; null after deletion
  Stream<Map<String, dynamic>> get onMessageOpened;   // taps while running / backgrounded
  Future<Map<String, dynamic>?> initialMessage();     // the tap that cold-started the app
}
```

### NotificationLinkResolver

`notification_link_resolver.dart` maps a payload to a go_router location. It is **pure** and
unit-tested. Each feature registers its own destinations from its `<feature>_di.dart`, so core
never imports features.

```dart
// lib/features/sample_feature/items_di.dart
getIt<NotificationLinkResolver>().register('item', (payload) {
  final id = payload['id'];
  return id == null || '$id'.trim().isEmpty ? null : ItemsRoutes.details('$id');
});

getIt<NotificationLinkResolver>().fallbackLocation = '/notifications'; // optional
```

- `resolve(payload)` returns the location, or `fallbackLocation` for unknown types, incomplete
  payloads or a builder that throws. It never throws.
- `typeKey` (default `'type'`) is the payload key holding the destination type. Matching is
  case-insensitive.

### PendingLink

A tap on a cold start must not navigate before the session and router are ready (the redirect
would bounce it to the splash and lose it). `PendingLink` parks **one** location (the newest tap
wins) and releases it once.

| API | |
|---|---|
| `hold(location)` | Park (null/blank ignored) |
| `release({ready})` / `flush({ready, go})` | Hand it over once when `ready`; otherwise keep it |
| `clear()` | On sign-out, so one account's tap never opens inside another's session |

Wiring (in the FCM recipe below, or any `PushService`):

```dart
final resolver = getIt<NotificationLinkResolver>();
final pending = getIt<PendingLink>();
final session = getIt<SessionCubit>();

pending.hold(resolver.resolve(await push.initialMessage()));       // cold start
push.onMessageOpened.listen((p) => pending.hold(resolver.resolve(p))); // warm taps

void tryFlush() => pending.flush(
  ready: session.state.isAuthenticated &&
      router.routerDelegate.currentConfiguration.uri.path != AppRoutes.splash,
  go: router.go,
);
router.routerDelegate.addListener(tryFlush);
session.stream.listen((_) => tryFlush());
tryFlush();
```

### FCM + flutter_local_notifications recipe (opt-in)

1. Add `firebase_core`, `firebase_messaging` and `flutter_local_notifications`. Run
   `flutterfire configure`. iOS: enable Push Notifications and Background Modes → Remote
   notifications in Xcode, and upload the APNs key in the Firebase console. Android: add
   `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` (Android 13+).
2. Implement the interface:

```dart
// lib/core/services/push/fcm_push_service.dart
// FCM + local notifications implementation of PushService (opt-in module).
//
// Source: chinaparts-seller lib/core/services/push_notification_service.dart (init,
//         permission, token refresh, opened stream, initial message); corsa-driver
//         (versioned channel ids). Rejected: static service with a fresh plugin per call (D14).
import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_service.dart';

/// Must be top-level. Data-only messages arrive here when the app is in the background.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

class FcmPushService implements PushService {
  FcmPushService({FirebaseMessaging? messaging, FlutterLocalNotificationsPlugin? local})
    : _messaging = messaging ?? FirebaseMessaging.instance,
      _local = local ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local; // ONE instance for the app's lifetime
  final StreamController<Map<String, dynamic>> _opened = StreamController.broadcast();
  bool _ready = false;

  // Bump the id (general_v2) to change importance/sound: channels are immutable once created.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'general_v1',
    'General', // shown in system settings; translate if your app is single-language
    importance: Importance.high,
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false, // asked later via requestPermission()
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => _emit(r.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showInForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _opened.add(m.data));
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Stream<String?> get tokenStream async* {
    yield await _messaging.getToken();
    yield* _messaging.onTokenRefresh;
  }

  @override
  Stream<Map<String, dynamic>> get onMessageOpened => _opened.stream;

  @override
  Future<Map<String, dynamic>?> initialMessage() async {
    final remote = await _messaging.getInitialMessage();
    if (remote != null) return remote.data;
    final launch = await _local.getNotificationAppLaunchDetails(); // tap on a local notification
    final payload = (launch?.didNotificationLaunchApp ?? false) ? launch!.notificationResponse?.payload : null;
    return payload == null ? null : _decode(payload);
  }

  /// Android shows nothing for foreground FCM messages: mirror them locally.
  Future<void> _showInForeground(RemoteMessage m) async {
    final n = m.notification;
    if (n == null || defaultTargetPlatform != TargetPlatform.android) return; // iOS presents natively
    await _local.show(
      id: (m.messageId ?? '${DateTime.now().microsecondsSinceEpoch}').hashCode & 0x7fffffff,
      title: n.title,
      body: n.body,
      payload: jsonEncode(m.data),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(_channel.id, _channel.name, importance: Importance.high),
      ),
    );
  }

  void _emit(String? payload) {
    final data = payload == null ? null : _decode(payload);
    if (data != null) _opened.add(data);
  }

  static Map<String, dynamic>? _decode(String raw) {
    try {
      final v = jsonDecode(raw);
      return v is Map<String, dynamic> ? v : null;
    } on FormatException {
      return null;
    }
  }
}
```

3. Wire it: initialise Firebase in bootstrap (as in the Crashlytics recipe), then
   `registerServicesModule(pushService: FcmPushService())` in `main.dart`. In the app (for example
   in `App.initState`), call `push.init()`, wire `PendingLink` as shown above, and register the
   token from a session `onStart` hook (unregister in `onEnd`). Ask for permission with
   [`ensurePermission(AppPermission.notifications)`](WIDGETS.md#permissions-flow) at a moment that
   makes sense, never at launch.
4. Keep the payload contract `{"type": "...", "id": "..."}` (data fields) so
   `NotificationLinkResolver` can route it.

Sources: chinaparts-customer `notification_link_handler.dart` (pure resolver); chinaparts-seller
`push_notification_service.dart` (pending link until there is a session); markspulse
`pending_deep_link.dart` (hold a route, released once, cleared on sign-out); corsa-driver
(versioned channels). Rejected: the static `NotificationService` with a fresh plugin per call
(brgr, tebbr, instaops; D14).

## Connectivity

`lib/core/services/connectivity/` — internet reachability with no dependency.

| Type | API |
|---|---|
| `ConnectivityService({probe, hosts, onlineInterval = 15 s, offlineInterval = 4 s, lookupTimeout = 3 s, offlineConfirmDelay = 1.2 s, listenToLifecycle = true, alwaysOnline})` | DNS lookup of `one.one.one.one` then `google.com` (one answer is enough). Adaptive polling. A fresh offline result is **re-probed** before it counts. Re-checks on app resume. Web is always online. `start()`, `check()`, `isOnline` (optimistic until the first probe), `onStatusChange`, `dispose()` |
| `ConnectivityCubit(service, {offlineDelay = 2 s})` | App-wide `ConnectivityStatus.online/offline`. Going online is immediate; going offline is debounced, so a short drop never flashes the banner. `recheck()` probes now |

```dart
BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
  builder: (context, status) => status.isOffline
      ? ErrorView(failure: const NetworkFailure(), onRetry: context.read<ConnectivityCubit>().recheck)
      : const ItemsList(),
);
```

The app already shows [`OfflineBanner`](WIDGETS.md#offline-banner) above every route. Requests
still fail with `NetworkFailure` on their own; connectivity is a hint, not a gate.

Sources: tebbr `core/services/connectivity_service.dart` (DNS probe of two hosts, adaptive polling,
confirm offline, resume re-check); corsa-customer (same design, trimmed); baytna
`connectivity_cubit.dart` (app-wide cubit, optimistic start).

## UrlService

`lib/core/services/url_service.dart` — opens links, the dialer, mail, SMS, WhatsApp and maps.
**Never throws**: every method returns whether something opened, so the UI can say so.

| Method | Behaviour |
|---|---|
| `open(url, {inApp = false})` | `String` or `Uri`. Web links open in the external browser, or in the in-app browser view with `inApp` (external fallback). Other schemes go to `platformDefault` |
| `call(phone)` | Opens the dialer (`tel:`). Digits are normalised and a leading `+` is kept |
| `email(to, {subject, body})` | `mailto:` with `%20` spaces (not `+`) |
| `sms(phone, {body})` | `sms:` |
| `whatsapp(phone, {text})` | `https://wa.me/<digits>` |
| `maps(lat, lng, {label})` | Apple Maps (iOS) / `geo:` (Android) / Google Maps web |
| `navigate(lat, lng, {label})` | Waze → Google Maps → Apple Maps → web |

```dart
final opened = await getIt<UrlService>().open(AppLinks.privacyPolicy, inApp: true);
if (!opened && context.mounted) AppSnackBar.errorMessage(LocaleKeys.errors_unknown.tr(), context: context);
```

Platform setup is in the template: Android `<queries>` for https/tel/smsto/mailto/geo, and iOS
`LSApplicationQueriesSchemes` (https, tel, sms, mailto, whatsapp, comgooglemaps, maps). Add `waze`
to both if you rely on Waze detection.

Sources: chinaparts-customer `core/services/url_handler.dart` (check `launchUrl`'s result rather
than `canLaunchUrl`, which is false on Android 11+ without `<queries>`); baytna `url_service.dart`
(in-app view with external fallback); corsa-driver `launcher_service.dart` (WhatsApp digits,
navigate chain).

## Permissions

`lib/core/services/permission_service.dart` — runtime permissions behind an interface. The UI flow
(rationale, then the system prompt, then Settings) is
[`ensurePermission`](WIDGETS.md#permissions-flow).

| Type | |
|---|---|
| `AppPermission` | `camera`, `photos`, `location` (when-in-use), `notifications`, `microphone`. Add more here and map them in `PermissionHandlerService._map` |
| `AppPermissionStatus` | `granted`, `limited` (iOS limited photos / provisional notifications), `denied`, `permanentlyDenied`, `restricted`. `isUsable` = granted or limited |
| `PermissionService` | `status(p)`, `request(p)`, `openSettings()` |
| `PermissionHandlerService` | permission_handler implementation; a missing manifest entry or unsupported platform reads as `denied` |

```dart
final ok = await ensurePermission(
  context,
  AppPermission.camera,
  getIt<PermissionService>(),
  rationaleTitle: AppPermission.camera.rationaleTitle,
  rationaleMessage: LocaleKeys.items_camera_reason.tr(),
);
if (ok) await _pickFromCamera();
```

### Platform setup (keep all three in sync)

| `AppPermission` | iOS Podfile macro (`ios/Podfile` post_install) | iOS `Info.plist` key | Android `AndroidManifest.xml` |
|---|---|---|---|
| camera | `PERMISSION_CAMERA=1` | `NSCameraUsageDescription` | `android.permission.CAMERA` (+ `<uses-feature android:name="android.hardware.camera" android:required="false"/>`) |
| photos | `PERMISSION_PHOTOS=1` | `NSPhotoLibraryUsageDescription` | none for `image_picker` (Android 13+ photo picker). Add `READ_MEDIA_IMAGES` only if you request `AppPermission.photos` yourself |
| microphone | `PERMISSION_MICROPHONE=1` | `NSMicrophoneUsageDescription` | `android.permission.RECORD_AUDIO` |
| notifications | `PERMISSION_NOTIFICATIONS=1` | none (APNs entitlement for push) | `android.permission.POST_NOTIFICATIONS` (Android 13+) |
| location | `PERMISSION_LOCATION_WHENINUSE=1` | `NSLocationWhenInUseUsageDescription` | `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION` |

Template defaults: camera, photos, microphone and notifications are compiled in on iOS
(`PERMISSION_LOCATION_WHENINUSE=0`). The Info.plist has camera/photos/microphone usage strings. The
manifest has `INTERNET` and `CAMERA`. **Remove what your app does not use**: App Review rejects
usage strings for features that don't exist, and Play asks you to declare sensitive permissions.
Usage strings must say why, in the user's language. Localise them with `InfoPlist.strings` (ar/en)
if needed.

Sources: petrobe `features/home/presentation/services/permissions_service.dart` (status → request →
permanently denied → Settings → re-check; when-in-use first); chinaparts-seller
`notification_permission_gate.dart` (Settings prompt throttled). Rejected: `permisssions_helper.dart`
with swapped Settings buttons.

## ImagePickerService

`lib/core/services/image_picker_service.dart` — picks one image, shrinks it by size tier, and
recovers a capture lost when Android killed the app behind the camera. It returns `Result` and never
shows UI.

| API | |
|---|---|
| `pick(ImageSource source, {maxDimension = 1920})` | `Ok(XFile)`, `Ok(null)` = cancelled (or a second tap while open), `Err(PermissionFailure(permanentlyDenied: true))` = access is off in Settings |
| `retrieveLostData({maxDimension})` | Android only. Call at startup or when the capturing screen reopens |
| `optimize(XFile, {maxDimension})` | Applies the tier. Any compression problem returns the original, and the smaller of the two files wins |
| `CompressionTier.forBytes(bytes)` | Pure; tested |
| `ImageCompressor` / `FlutterImageCompressor` | Seam over flutter_image_compress (JPEG, EXIF stripped) |

| File size | Result |
|---|---|
| ≤ 300 KB | untouched |
| ≤ 2 MB | JPEG q85, ~1920 px |
| ≤ 5 MB | JPEG q75, ~1600 px |
| > 5 MB | JPEG q65, ~1280 px |

```dart
final source = await showImageSourceSheet(context);
if (source == null) return;
switch (await getIt<ImagePickerService>().pick(source)) {
  case Ok(value: final file?):
    cubit.attach(file);
  case Ok():
    break; // cancelled
  case Err(:final failure):
    if (failure is PermissionFailure && failure.permanentlyDenied && context.mounted) {
      final permission = source == ImageSource.camera ? AppPermission.camera : AppPermission.photos;
      await ensurePermission(context, permission, getIt<PermissionService>(),
          rationaleTitle: permission.rationaleTitle, rationaleMessage: permission.rationaleMessage);
    } else {
      AppSnackBar.error(failure);
    }
}
```

Sources: brgr `core/services/image_picker_service.dart` (size tiers, `retrieveLostData`); instaops
`pending_capture_service.dart` (recover at startup); baytna `compression_plan.dart` (pure plan).
Rejected: brgr's SnackBars on a popped context.

## App config

`lib/core/app_config/` — maintenance, force update and optional update, from a remote config
**and** from live 426/503 responses. The gate widget is
[`AppConfigGate`](WIDGETS.md#app-gate), which sits in `MaterialApp.builder` above the router, so no
deep link can bypass it.

| File | Role |
|---|---|
| `app_config.dart` | `AppConfig` (`maintenance`, `maintenanceMessage` per language or `*`, `android`/`ios` `PlatformUpdatePolicy {minBuild, latestBuild, storeUrl}`). `AppConfig.tryParse` is tolerant: `{data: ...}` envelope, snake or camel case, numbers as strings, `maintenance` as a bool or `{enabled, message}` |
| `update_policy.dart` | `UpdatePolicy.decide(config, installedBuild, platform)` → `GateDecision.none / optionalUpdate / forceUpdate / maintenance`. **Fail-open**: any doubt (no config, unknown build, `min > latest`) is `none` |
| `app_version.dart` | `AppVersion.parse/compare` (numeric per segment), `isBelow` (**fail-closed**, for security floors), `parseBuild`, `compareBuilds` |
| `app_config_repository.dart` | `AppConfigRepository.fetch()` (`GET /app-config`, cached best-effort) and `cached()` |
| `app_config_cubit.dart` | `AppConfigCubit` / `AppConfigState {decision, config, message, isLoading, hasLoaded, optionalPromptDue}`: `load()`, `refreshIfStale()` (at most once per minute, on resume), `markOptionalPromptShown()`, `storeUrl` |

Rules built in:
- Builds are compared as **integer build numbers** (`version: 1.2.0+42` → 42), never as semver
  strings.
- A **cached** config never raises a blocking gate on its own. It may only offer the optional
  prompt.
- A gate raised by a live response stays until a successful fetch clears it. A 426 keeps the app
  forced until restart, because only a new install can fix it.
- The optional prompt shows once per `latest_build`, not once per launch.
- Bootstrap starts `load()` without awaiting it, so a slow or failing config never delays launch.

Backend contract (`GET /app-config`):

```json
{
  "maintenance": false,
  "maintenance_message": {"ar": "...", "en": "..."},
  "android": {"min_build": 40, "latest_build": 42, "store_url": "https://play.google.com/store/apps/details?id=com.example.app"},
  "ios": {"min_build": 40, "latest_build": 42, "store_url": "https://apps.apple.com/app/id0000000000"}
}
```

The store URL falls back to `ANDROID_STORE_URL` / `IOS_STORE_URL` from `.env`.

Sources: chinaparts-customer `features/app_config/*` + `app_version_comparator.dart` (cubit,
cached config never gates, prompt once per version, gate above the router); baytna
`features/config/*` (AppGate, integer builds per platform, maintenance message per language);
corsa-customer (426/503 from any request); tebbr (refresh on resume, throttled); lexa-student
`app_version.dart` (fail-closed comparator).

## AppInfo

`lib/core/services/app_info_service.dart` — `AppInfo {version, buildNumber, packageName, platform}`,
read once at startup by `AppInfoService.load()` (it falls back to `AppInfo.unknown` instead of
throwing). `AppInfo.headers` gives the `X-Platform` / `X-App-Version` / `X-Build-Number` request
headers. `SettingsScreen` shows `version+build`. Registered as a singleton.

```dart
final info = getIt<AppInfo>();
final isOld = info.buildNumber < 40;
```

Sources: chinaparts-customer `core/services/app_version_service.dart`; lexa-student
`app_version.dart`.

## Validators

`lib/core/utils/validators.dart` — composable `FormFieldValidator<String>`s that return
**translated** messages (`validation.*`). Every rule except `required` accepts an empty value, so
optional fields work. Every rule takes an optional already-translated `message`.

| Rule | |
|---|---|
| `Validators.compose([...])` | First error wins |
| `required()` | Not blank |
| `email()` | `name@domain.tld` |
| `minLength(n)`, `maxLength(n)` | User-perceived characters (emoji count once) |
| `phone()` / `normalizePhone(v)` | Generic international: optional `+`, then 7–15 digits. Separators ignored, ٠-٩ accepted. Country rules belong in the app (D8) |
| `numeric()`, `range(min, max)` | Accepts ٠-٩ and the Arabic decimal mark |
| `match(() => other.text)` | Confirm password/email |
| `password({minLength = 8})` | Letter + digit + length |
| `url({httpsOnly})` | Absolute http(s) with a host |
| `iban()` / `isValidIban(v)` | ISO 13616 mod-97 |

```dart
AppTextField(
  label: LocaleKeys.items_price.tr(),
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  validator: Validators.compose([Validators.required(), Validators.range(1, 10000)]),
);
```

Sources: baytna `core/utils/validators.dart` (pure, translation keys); brgr `app_validator.dart`
(compose, range, IBAN). **Fixed**: the house-style `isNumeric` regex ended in a literal `\$` (brgr,
tebbr, chinaparts ×2, instaops, petrobe), so it only matched numbers followed by "$".

## Formatters

`lib/core/utils/formatters.dart` (`AppFormat`), `digits.dart` (`Digits`) and `input_formatters.dart`.
All user-visible numbers and dates go through `AppFormat`. Policy:
[CONVENTIONS.md#localization](CONVENTIONS.md#localization).

| `AppFormat` | Example (en) |
|---|---|
| `number(12500.5)` | `12,500.5` |
| `decimal(12.5, places: 2)` | `12.50` |
| `currency(amount, code: 'USD')` / `currency(amount, symbol: 'ر.س')` | `$12.50` |
| `percent(0.256, decimals: 1)` | `25.6%` |
| `compact(1200)` | `1.2K` |
| `parseNumber('١٢٬٥٠٠٫٥')` | `12500.5` |
| `date(d, pattern: 'yyyy-MM-dd')`, `time(d)`, `dateTime(d)` | `Nov 5, 2026`, `3:05 PM` |
| `relative(d)` / `relativeOf(d)` | "Just now", "5 minutes ago" (Arabic plural forms), "Yesterday", then a date after a week |
| `fileSize(bytes)` → `(value:, unit:)` | Value and translated unit returned **apart**, so RTL layouts place the unit |
| `applyDigits(text, digits:)` | Applies the digits policy to any text |
| `AppFormat.digits` | `DigitsPolicy.western` (default) or `arabicIndic` (applied to Arabic output only) |

Every method takes optional `locale:` (defaults to `CurrentLocale`, kept in sync by the app root)
and `digits:`.

| `Digits` | |
|---|---|
| `toWestern(s)` | ٠-٩ / ۰-۹ → 0-9, `٫` → `.`, `٬` → `,` |
| `toArabicIndic(s, {separators})` | 0-9 → ٠-٩ |
| `hasNonWesternDigits(s)` | |

| Input formatter | |
|---|---|
| `DigitsNormalizerFormatter` | Folds Arabic-Indic/Persian digits to ASCII as typed or pasted. Put it **first** in the list. `AppTextField` adds it automatically for number/phone keyboards and `forceLtr` |
| `DecimalInputFormatter({decimalPlaces = 2, allowNegative})` | One separator (`.` `,` `٫` → `.`). Invalid edits are rejected. Read with `DecimalInputFormatter.tryParse` |

```dart
Text(AppFormat.currency(item.price, code: item.currency));
Text(AppFormat.relative(item.createdAt));
final (:value, :unit) = AppFormat.fileSize(file.lengthSync());
```

Sources: baytna `core/utils/formatters.dart` q5 (locale formatters, value/unit apart, relative time
as a key, Eastern digits); markspulse (Western digits by default); chinaparts-seller
`double_parser_service.dart` + `decimal_input_formatter.dart`; tebbr (Arabic-Indic digit
normaliser).

## JSON helpers

`lib/core/utils/json_x.dart` — tolerant readers on `Map<String, dynamic>`. A sloppy payload degrades
to defaults instead of crashing.

| API | |
|---|---|
| `asJsonMap(Object?)` | Any decoded map → `Map<String, dynamic>?` |
| `json.string(key, [fallback])`, `stringOrNull` | Numbers/bools stringified; blank → null |
| `intOrNull`, `intOr`, `doubleOrNull`, `doubleOr` | From numbers or numeric strings |
| `boolOr`, `boolOrNull` | `true/false`, `1/0`, `"yes"/"no"` |
| `dateTime(key)` | ISO-8601 or epoch seconds/ms, returned in local time |
| `mapOrNull(key)` | Nested object |
| `listOf(key, mapper)` | Objects mapped. **Bad items are skipped**, not fatal |
| `stringList(key)` | Scalars as non-blank strings |

```dart
factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
  id: json.string('id'),
  title: json.string('title'),
  price: json.doubleOr('price'),
  isActive: json.boolOr('is_active'),
  createdAt: json.dateTime('created_at') ?? DateTime.now(),
  tags: json.stringList('tags'),
);
```

Sources: corsa-customer `core/utilities/converters/json_helpers.dart` q5; markspulse
`domain/common/parse.dart` (skip bad list items).

## Debouncer

`lib/core/utils/debouncer.dart` — `Debouncer` (last call wins after a quiet period) and `Throttler`
(leading edge, then at most once per interval).

| API | |
|---|---|
| `Debouncer(duration)` | `run(action)`, `flush()` (run the pending action **now**, e.g. on leaving a screen so the last edit is saved), `cancel()`, `isPending`, `dispose()` |
| `Throttler(interval, {clock})` | `run(action)` → `bool` ran; `reset()`; `dispose()` |

```dart
final _autosave = Debouncer(const Duration(milliseconds: 800));
onChanged: (text) => _autosave.run(() => cubit.saveDraft(text));
@override
void dispose() { _autosave.flush(); super.dispose(); }

final _refresh = Throttler(const Duration(seconds: 2));
onPressed: () => _refresh.run(cubit.refresh);
```

Inside cubits, prefer `BaseCubit.debounce`. For search fields, `AppSearchField` has its own
debounce.

Sources: tebbr `core/utilities/timing/request_limiters.dart` (flush, leading-edge throttler).

## Extensions

- `lib/core/extensions/context_x.dart` — `context.theme`, `textTheme`, `colorScheme`,
  `textDirection`, `isRtl`, `languageCode`, `hideKeyboard()` (baytna, corsa-customer).
- `lib/core/extensions/string_x.dart` — `String?.isBlank / isNotBlank / nullIfBlank`,
  `capitalize()` (grapheme-safe, never throws on empty strings), `withWesternDigits`.
- Responsive and foldable extensions are in `lib/core/responsive/`. See
  [CONVENTIONS.md#responsive](CONVENTIONS.md#responsive) and
  [CONVENTIONS.md#foldables](CONVENTIONS.md#foldables).
- `context.palette` is in `lib/core/theme/app_palette.dart`. See
  [CONVENTIONS.md#theming](CONVENTIONS.md#theming).

## JsonCredential

`tool/json_credential.dart` — reads a JSON credential (for example a Google service account for
Play publishing or Firestore admin scripts) from an environment variable that holds **either a
file path or the base64 of the JSON file**. It never prints the secret.

```bash
# Local: a path in .env (gitignored)
#   GOOGLE_SERVICE_ACCOUNT_JSON=./secrets/service-account.json
dart run tool/json_credential.dart GOOGLE_SERVICE_ACCOUNT_JSON --env-file .env

# CI: base64 in a secret, so there is no file on disk to leak
#   base64 -i service-account.json | tr -d "\n"   → paste into the CI secret
GOOGLE_SERVICE_ACCOUNT_JSON="$SECRET" dart run tool/json_credential.dart GOOGLE_SERVICE_ACCOUNT_JSON
# → GOOGLE_SERVICE_ACCOUNT_JSON (from process environment) resolved:
#     keys: client_email, private_key, project_id, type, ...
#     type: service_account
#     client_email: ci***@my***.iam.gserviceaccount.com
```

| Behaviour | |
|---|---|
| Lookup | The process environment first, then `--env-file <path>` (default `.env` if it exists) |
| Path | Absolute, `~/…`, or relative (to the env file's folder when read from it, else the current directory) |
| Base64 | Standard or URL-safe, padding optional, whitespace and line breaks ignored |
| Output | Only non-secret metadata: sorted keys, `type`, masked `client_email` |
| Exit codes | `0` resolved, `1` missing or unreadable, `64` usage error |

Library use from other `tool/` scripts (pure Dart, no Flutter):

```dart
import 'json_credential.dart';

final credential = resolveJsonCredential(Platform.environment['GOOGLE_SERVICE_ACCOUNT_JSON'] ?? '');
// also: parseEnvFile(content), describeCredential(json), maskEmail(email)
```

Rules: tooling and CI **only**. The app never reads it and it is never compiled into the binary.
Never commit the JSON (`.gitignore` covers `service-account*.json`).

Sources: approved convention K3; markspulse `tool/support/firestore_rest.dart`
(service-account scripts). Rejected: a committed service-account JSON (petrobe).

## Optional recipes

The template ships interfaces with no-op or console implementations (decision C7), so it builds,
analyses and tests with zero accounts. Real implementations are added per project:

| Module | Recipe | Packages |
|---|---|---|
| Crash reporting | [Crashlytics recipe](#crashlytics-recipe-opt-in) | firebase_core, firebase_crashlytics |
| Push | [FCM + flutter_local_notifications recipe](#fcm--flutter_local_notifications-recipe-opt-in) | firebase_core, firebase_messaging, flutter_local_notifications |
| In-app purchases | below | in_app_purchase |
| Maps / location | below | google_maps_flutter, geolocator |

### In-app purchases (IAP)

No IAP code is baked in. When an app needs it (baytna, markspulse and tebbr did):

1. Add `in_app_purchase`. Define `abstract interface class PurchaseService { Stream<PurchaseUpdate> get updates; Future<Result<List<Product>>> products(Set<String> ids); Future<Result<Unit>> buy(Product p); Future<void> restore(); }`
   in `lib/core/services/` and implement it on `InAppPurchase.instance`, so cubits and tests never
   touch the plugin.
2. Listen to `purchaseStream` **once**, from app start, so a purchase finished while the app was
   killed is still delivered.
3. **Verify on the server.** Send the receipt or purchase token to your backend (markspulse
   verified with the App Store Server Library in Cloud Functions), grant the entitlement there,
   and only then call `completePurchase`. The app reads entitlements from the API, never from
   local state alone.
4. Use `ApiClient.idempotent(key)` for the verification POST, and hash or obfuscate the account id
   you attach (baytna hashed purchase tokens with `crypto`).
5. Store setup: products in App Store Connect and Play Console, sandbox testers, and the "Restore
   purchases" button that App Review requires.

### Maps and location

No maps/location code is baked in (business logic, D15). When needed:

1. Add `geolocator` (position) and/or `google_maps_flutter` (map widget).
2. **API keys never go in Dart or committed native files** (brgr and petrobe had Maps keys in
   source). Android: put `MAPS_API_KEY` in `local.properties` or a CI secret and inject it with
   `manifestPlaceholders`. iOS: read it from a gitignored `.xcconfig` into `Info.plist` and call
   `GMSServices.provideAPIKey` from `AppDelegate`. Restrict the keys by package name / bundle id in
   the Google Cloud console.
3. Add `AppPermission.location` to the flow: `PERMISSION_LOCATION_WHENINUSE=1` in the Podfile,
   `NSLocationWhenInUseUsageDescription`, and `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`.
   Ask for "always" only after "when in use" is granted, and only if you truly need background
   location (Play requires a declaration).
4. Wrap the plugin: `abstract interface class LocationService { Future<Result<GeoPoint>> current(); Stream<GeoPoint> watch({Duration interval}); }`.
   Map plugin errors to `PermissionFailure` / `UnknownFailure`.
5. For "open in maps / directions", use `UrlService.maps` / `UrlService.navigate`. You don't need a
   map SDK for that.
