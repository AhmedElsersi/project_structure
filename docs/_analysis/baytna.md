# baytna — analysis

## Summary for comparison

```
PROJECT: baytna | path: My Apps/Baytna | stack: Dart ^3.11.5 (lock: dart >=3.12, flutter >=3.44; CI pins Flutter 3.44.0 stable) | last commit: 2026-11-05 (111 commits since 2026-08-13; lib/main.dart has an uncommitted edit) | source files: 313
ARCH: clean-arch feature-first — features/<f>/{data(datasources,models,repositories) → domain(entities,repositories,usecases) → presentation(bloc|cubit,pages,widgets)}; app/ (router, session, theme, observers) + core/ (di, errors, network, services, utils, widgets); Firebase-only backend, no server, no Cloud Functions
STATE: flutter_bloc 9 / bloc 9 — 7 Bloc + 23 Cubit, no shared base class; each bloc has a private `_run` (loading → fold Either → success/failure), Equatable states with a status enum + copyWith(clearFailure:); live streams via StreamSubscription → add(XUpdated(result)); SessionCubit (lib/app/session/session_cubit.dart) is the router's single source of truth
DI: get_it 9 + injectable 3 (81 @injectable factories, 38 @LazySingleton(as:), 12 @lazySingleton, one @module for SDK singletons) — lib/core/di/injection.dart (+ generated injection.config.dart)
ROUTING: go_router 17 — lib/app/router/app_router.dart + routes.dart (path consts + to*() builders) + router_refresh_stream.dart — guards: yes (one redirect on SessionStatus: splash/onboarding/auth/space-gate/admin role, refreshListenable on SessionCubit.stream); StatefulShellRoute.indexedStack (4 tabs); deep links: yes (custom URL scheme + Flutter deep linking, legacy-path redirects)
NETWORK: firebase (cloud_firestore, firebase_auth, firebase_storage) + one dart:io HttpClient for Open Graph link previews; no dio/http — interceptors: none | token refresh: n (Firebase SDK) | retry: n | error mapping: FailureMapper.fromAuth/fromFirestore (error.code → sealed Failure) inside per-repository _guard/_wrapStream helpers | lib/core/errors/failure_mapper.dart, lib/core/network/network_info.dart, lib/core/network/connectivity_cubit.dart, lib/core/services/link_preview_service.dart
RESULT_TYPE: Either (dartz) — sealed Failure holding translationKey + args: lib/core/errors/failures.dart (sealed AppException in lib/core/errors/exceptions.dart)
STORAGE: hive (one untyped Box<dynamic> 'settings') + Firestore offline persistence (unlimited cache) — lib/core/services/settings_store.dart (SettingsStore interface + HiveSettingsStore)
L10N: easy_localization 3 — en, ar; fallback ar, device locale at start, useOnlyLangCode, CLDR plural rules ON — assets/translations/{en,ar}.json (~1,280 keys, ar covers all of en) — hardcoded UI strings: few (841 .tr() calls, 0 literal Text('…'))
RTL: Directional=266 vs LeftRight=5 (1 doc comment, 1 PDF builder, 2 full-bleed Positioned left:0/right:0, 1 Alignment.topLeft in a splash pattern)
THEME: lib/app/theme/app_theme.dart — dark mode y (ThemeCubit, persisted in Hive, defaults to system) | component themes in ThemeData y (appBar, card, input, filled/outlined/text/icon buttons, FAB, bottomSheet, dialog, snackBar, chip, switch, segmented, progress, slider, radio, checkbox, pageTransitions) | colors class: AppPalette ThemeExtension day/night (PaintSet fill/soft/ink/on) in app_colors.dart + legacy AppColors consts | text styles: AppTypography (TextTheme) + AppType (d48…t12, label16/14) in app_typography.dart | fonts: BalooBhaijaan2 (display) + ReadexPro (UI), both Arabic+Latin; Tajawal for the PDF only; plus app_spacing.dart (AppSpacing/AppRadii/AppBorders/AppSizes), app_motion.dart, app_shadows.dart
RESPONSIVE: none — fixed tokens, a few LayoutBuilder/ConstrainedBox; breakpoints: none
TEXT_SCALING: lib/app/app.dart MaterialApp.router builder → MediaQuery textScaler.clamp(minScaleFactor 0.85, maxScaleFactor 1.4)
ENV/FLAVORS: --dart-define dev flags only (USE_FIREBASE_EMULATOR, FIREBASE_EMULATOR_HOST, DEV_AUTO_LOGIN, DEV_INITIAL_ROUTE; each also needs kDebugMode) — lib/core/constants/dev_flags.dart; single Firebase env (lib/firebase_options.dart); no flavors; hardcoded constants in lib/core/constants/app_constants.dart
LOGGING: debugPrint (21 calls) + dart:developer log in AppBlocObserver; no logger package
ANALYTICS/CRASH: firebase_analytics (AnalyticsService + AnalyticsEvents consts, skipped on emulator) + firebase_crashlytics (release only: FlutterError.onError, PlatformDispatcher.onError, runZonedGuarded, BlocObserver.onError)
PUSH: none (no FCM, by design) — in-app banners from a live Firestore activity listener: lib/features/activity/presentation/widgets/activity_scope.dart + in_app_notification_banner.dart; lib/core/services/notification_service.dart is an interface that is mostly unused
PAYMENTS/IAP: in_app_purchase 3 + in_app_purchase_android 0.5 (one consumable pack + one non-consumable unlock, no subscriptions) — lib/core/services/purchase_service.dart (interface) + iap_purchase_service.dart; idempotent grant ledger written by the client (lib/features/purchases/), no server receipt check
PERMISSIONS: none (no permission_handler; image_picker and mobile_scanner show their own prompts)
DEEP_LINKS: go_router paths + custom URL scheme (Android intent-filter with flutter_deeplinking_enabled, iOS CFBundleURLSchemes + FlutterDeepLinkingEnabled); Android share-in through MethodChannel/EventChannel (lib/core/services/share_in_service.dart); home-widget `?quickAdd=1` link
MEDIA/FILES: image_picker, flutter_image_compress (tiered WebP, EXIF stripped), firebase_storage, cached_network_image, share_plus, pdf, archive (hand-written .xlsx), qr_flutter, mobile_scanner, youtube_player_iframe, home_widget, path_provider, flutter_svg, shimmer
TESTS: 56 Dart test files (unit tests for entities/utils/services/mappers, some widget tests, goldens for the storybook facade in day/night × LTR/RTL, a theme+RTL smoke test) + a Node security-rules suite (test/rules/rules.test.mjs, ~125 cases on the emulator); bloc_test + mocktail installed
LINTS: flutter_lints (package:flutter_lints/flutter.yaml), 0 extra rules, excludes build/**
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/errors/failures.dart — sealed Failure holding a translation key + args, never a message — quality 5 — coupling: low (strip the app-specific subclasses)
- lib/core/utils/formatters.dart — money/signed money/number/percent/date/time/bytes (value+unit returned apart for RTL), Eastern Arabic digits, relative-time → key — quality 5 — coupling: none
- lib/core/utils/extensions/stream_x.dart — switchMap with no rxdart (auth stream → user doc listener) — quality 5 — coupling: none
- lib/app/router/app_router.dart (+ routes.dart, router_refresh_stream.dart) — go_router with one status-based redirect, refreshListenable, shell branches, root/shell keys — quality 5 — coupling: medium (app routes and pages)
- lib/core/services/image_upload_service.dart + firebase_image_upload_service.dart + compression_plan.dart — pick → tiered WebP compress → stage on disk → upload with progress → safe delete of owned URLs — quality 5 — coupling: low (StoragePaths, Failure)
- lib/features/config/presentation/widgets/app_gate.dart + presentation/cubit/app_config_cubit.dart + domain/entities/app_config.dart + lib/core/services/app_info_service.dart — remote maintenance mode + per-platform forced/optional update compared by integer build number — quality 5 — coupling: medium (Firestore config doc, admin bypass reads SessionCubit)
- lib/app/theme/app_theme.dart + app_colors.dart + app_spacing.dart + app_typography.dart + app_motion.dart + app_shadows.dart — full token system, ThemeExtension palette, reduced-motion helpers — quality 5 — coupling: low (brand values; app_colors.dart imports the items entity for enum colours)
- lib/core/errors/failure_mapper.dart — FirebaseAuth/Firestore/GoogleSignIn/Apple error → Failure — quality 4 — coupling: medium (imports three auth SDKs)
- lib/app/session/session_cubit.dart — SessionStatus (unknown/unauthenticated/noSpace/inSpace) that drives the router — quality 4 — coupling: medium (AuthRepository, AppUser.hasSpace)
- lib/bootstrap.dart — runZonedGuarded, Crashlytics, emulator switch, Firestore persistence, Hive, EasyLocalization, DI, pre-first-frame config — quality 4 — coupling: high (≈200 lines of dev-only sheet demos importing many features)
- lib/core/utils/extensions/context_x.dart + widget_x.dart — theme/palette/media/RTL accessors; directional padding helpers + Gap — quality 4 — coupling: low
- lib/core/utils/extensions/plural_x.dart — CountedX.counted: CLDR plurals with a `.zero` sentence kept — quality 4 — coupling: none (easy_localization)
- lib/core/utils/validators.dart — FormField validators that return translation keys — quality 4 — coupling: low (invite-code rules)
- lib/core/services/url_service.dart — in-app browser view → external app fallback → false; tel:/mailto: go straight to external — quality 4 — coupling: low (SettingsStore toggle)
- lib/core/network/network_info.dart + connectivity_cubit.dart + lib/core/widgets/offline_banner.dart — connectivity hint, optimistic prime, app-wide offline bar — quality 4 — coupling: none
GENERIC_WIDGETS (every reusable widget):
- lib/core/widgets/app_button.dart — primary button (9 variants: primary/ink/secondary/text/danger/love/sun/basil/white; sticker press-drop) — label, onPressed, variant, icon, isLoading, expand, small; .secondary/.ink/.text — quality 4 — generic? y (brand look)
- lib/core/widgets/app_text_field.dart — text field (label above, focus halo, validator returns a translation key) — controller, labelKey, hintKey, helperKey, validator, keyboardType, obscureText, prefixIcon/prefix/suffix, maxLines, maxLength, inputFormatters, focusNode, readOnly, onTap, autofillHints — quality 4 — generic? y
- lib/core/widgets/app_dialog.dart — confirm dialog + one-button notice, static show() → bool, safe action first — titleKey, primaryLabelKey, bodyKey/bodyArgs, titleArgs, icon, secondaryLabelKey, destructive, content, barrierDismissible — quality 4 — generic? y
- lib/core/widgets/app_bottom_sheet.dart — modal sheet: pinned handle + title + close button, keyboard inset, max 88% height — show<T>(context, child, titleKey, isScrollable, isDismissible) — quality 5 — generic? y
- lib/core/widgets/app_snackbar.dart — snackbars: failure(Failure)/success(key)/info(key)/undo(message, onUndo, duration) with a draining countdown bar — quality 5 — generic? y (uses legacy AppColors)
- lib/core/widgets/app_loader.dart — shimmer: AppShimmer(+.block), AppListSkeleton, AppGridSkeleton, AppSkeleton.home/detail/wallet/rows/rooms, AppLoader spinner; still under reduced motion — itemCount, itemHeight, size — quality 4 — generic? partly (AppSkeleton screens are app-specific)
- lib/core/widgets/app_empty_state.dart — empty/error/offline state (.error, .offline) — titleKey, messageKey, art (EmptyArt), icon, actionLabelKey, onAction, actionIcon — quality 4 — generic? mostly (EmptyArt values app-specific)
- lib/core/widgets/app_card.dart — card raised/flat/lifted, InkWell + PressScale — child, onTap, onLongPress, padding, accented, style, clip — quality 4 — generic? y
- lib/core/widgets/app_chip.dart — AppChip (label pill / .filter) + AppChipRow<T> scrolling single-select — label, variant, icon, trailing, onTap, selected; values, labelOf, iconOf, selected, onSelected — quality 4 — generic? y
- lib/core/widgets/app_segmented.dart — AppSegmented<T> sliding-pill segmented control (2–4), RTL-safe — segments, value, onChanged, height — quality 4 — generic? y
- lib/core/widgets/app_switch.dart — AppSwitch (48dp target, directional) + AppSwitchTile — value, onChanged, semanticLabel; title, subtitle, icon — quality 4 — generic? y
- lib/core/widgets/app_avatar.dart — AppAvatar (photo → initials fallback) + AppAvatarStack (+N overflow, PositionedDirectional) — initials, photoUrl, size, showBorder, tone; avatars, size, maxVisible — quality 4 — generic? mostly
- lib/core/widgets/remote_image.dart — network image (URL check + CachedNetworkImage + BrokenImage fallback) — url, fit — quality 4 — generic? y
- lib/core/widgets/offline_banner.dart — app-wide offline bar over the child — child — quality 4 — generic? y (needs ConnectivityCubit)
- lib/core/widgets/press_scale.dart — spring press-scale wrapper — child, enabled, scale — quality 5 — generic? y
- lib/core/widgets/staggered_entrance.dart — list item fade + lift, capped stagger — index, child — quality 3 — generic? y (ignores reduced motion)
- lib/core/widgets/image_gallery_viewer.dart — full-screen pinch-zoom pager, open()/openUrls() — itemCount, initialIndex, itemBuilder, urls, caption — quality 4 — generic? y
- lib/core/widgets/progress_ring.dart — ProgressRing (two arcs, RTL sweep, fills on appear) + ProgressBar — progress, secondary, size, stroke, colors, child, animateOnAppear, semanticLabel — quality 4 — generic? y
- lib/core/widgets/confetti.dart — confetti with no dependency, reduced-motion aware — pieces, seed — quality 4 — generic? y
- lib/core/widgets/framed_box.dart — clip-then-paint-outline box (no cut corners) — borderRadius, borderColor, borderWidth, child, color, padding, width, height, alignment — quality 4 — generic? y
- lib/core/widgets/scrim_icon_button.dart — ScrimIconButton / ScrimBackButton / ScrimMenuButton<T> for app bars over photos — icon, tooltip, onPressed, onSelected — quality 4 — generic? y
- lib/core/widgets/storybook/circle_icon_button.dart — 44px round icon button with dot badge — icon, onPressed, tooltip, style, badge, badgeColor, flipInRtl, size — quality 4 — generic? y
- lib/core/widgets/storybook/story_viewer.dart — story player (segment bars, RTL tap zones, hold to pause) — slides (StorySlide), header, tapHint, onClose — quality 4 — generic? y
- lib/features/admin/presentation/widgets/typed_confirmation_dialog.dart — type-a-word-to-confirm destructive dialog with consequence preview + optional note — titleKey, messageKey, confirmWord, consequence, allowNote, noteLabelKey, isDestructive — quality 4 — generic? y
- lib/features/auth/presentation/widgets/password_strength.dart — PasswordStrengthMeter + PasswordStrength.of — password — quality 4 — generic? y
- lib/features/auth/presentation/widgets/social_sign_in_buttons.dart — Google + Apple buttons (Apple only on Apple platforms) + LabelledDivider — onGoogle, onApple, enabled; labelKey — quality 4 — generic? y
- lib/features/space/presentation/widgets/app_shell.dart — floating bottom nav with a raised centre action (FloatingNavBar, NavTabSpec) — shell; tabs, currentIndex, onTap, onAdd — quality 3 — generic? partly
- lib/features/media/presentation/widgets/image_picker_field.dart + presentation/cubit/image_editor_cubit.dart — multi-image field that stages picks and uploads on save — labelKey, maxImagesOverride — quality 4 — generic? partly
- lib/features/media/presentation/widgets/video_player_view.dart / video_link_field.dart / video_link_card.dart — lazy YouTube player, link list field, external-open card — url; urls, onChanged — quality 3 — generic? partly
- lib/core/widgets/evening_card.dart, storybook/sticker.dart, storybook/story_ring.dart — brand hero card / tilted tag / story bubble — quality 3 — generic? brand-specific
- lib/core/widgets/segmented_status.dart, priority_chip.dart, room_cover.dart, arch_divider.dart, storybook/arch_window.dart, door_mark.dart, home_facade.dart, split_bar.dart — domain/brand drawings — generic? n
- lib/core/widgets/phase_placeholder.dart — "feature not built yet" scaffold — dead code — generic? y
NOTABLE_IDEAS: Failure holds a translation key and AppSnackBar.failure(context, f) renders it (lib/core/errors/failures.dart, lib/core/widgets/app_snackbar.dart); validators return keys and AppTextField calls .tr() on them (lib/core/utils/validators.dart); status-based redirect with no navigation after sign-in (lib/app/session/session_cubit.dart + lib/app/router/app_router.dart); AppGate above the router for maintenance + integer-build-number version gate with per-platform policy (lib/features/config/); debug-only file command channel to drive a simulator for screenshots (lib/core/services/dev_command_watcher.dart, lib/core/constants/dev_flags.dart, tool/dev/shot.sh); "one SDK, one file" seams for storage/picker/IAP/home_widget behind interfaces; tiered WebP CompressionPlan + stage-until-save images (lib/core/services/compression_plan.dart, lib/features/media/presentation/cubit/image_editor_cubit.dart); textScaler clamp in MaterialApp.builder (lib/app/app.dart); AppMotion.of(context, d) gives zero under reduced motion (lib/app/theme/app_motion.dart); CLDR plurals for Arabic through CountedX (lib/core/utils/extensions/plural_x.dart); .xlsx with no dependency (lib/core/utils/xlsx_writer.dart); OG/JSON-LD link preview parser with no dependency (lib/core/services/link_preview_service.dart); Firestore/Storage rules tests on the emulator (test/rules/) and an emulator-only seed script (tool/seed/); CI workflow that bumps the build number on main (.github/workflows/bump-build-number.yml); tool/dev/add_strings.py merges keys into both JSON files; golden tests for day/night × LTR/RTL
SMELLS: stream-error bug: `.handleError((e) => Left(...))` in rooms/items/space/activity/moderation/budget repository impls drops errors (handleError ignores the callback's return), so failed listeners never reach the bloc; the correct StreamTransformer.fromHandlers version exists in lib/features/admin/data/repositories/admin_repository_impl.dart and brands_repository_impl.dart; _guard/_guardUnit/_wrapStream copied into every repository; god files (item_detail_page 1852 lines, room_detail_page 1718, items_remote_data_source 1348, home_page 1060); bootstrap.dart carries ≈200 lines of dev demo code; legacy AppColors still used 101× in 34 files next to AppPalette; 62 Color(0x…) in features + 29 in core/widgets; MaterialPageRoute ×4 against the project's own "go_router only" rule; dead code (PhasePlaceholder, ImageSourceService, NotificationService banner stream) and 21 empty scaffold dirs; core → features imports (app_colors, budget_counters, segmented_status, priority_chip, widget_snapshot_service); '[upload debug]' debugPrint logs bucket + uid on every upload; public site URL, support email and Android package name hardcoded; doc-comment drift; lints are only flutter_lints; shared_preferences dev-dep unused; IAP grants written by the client; StaggeredEntrance ignores reduced motion; 120 getIt<> calls inside feature widgets. No deprecated APIs found (0 withOpacity, WillPopScope, textScaleFactor, MaterialStateProperty, print).
```

---

## 1. Architecture pattern

**Clean architecture, organised by feature**, with rules written down in `docs/claude.md` (state is flutter_bloc only, routing goes through one go_router, zero hardcoded strings, directional insets only, presentation never imports `data/`, repositories return `Either<Failure, T>`, no Cloud Functions, no FCM).

- **data/**: `datasources/` (abstract `XRemoteDataSource` + `@LazySingleton(as:)` impl talking to Firestore; it *throws*), `models/` (Firestore mappers: freezed for `AppUserModel`, hand-written `fromDoc`/`toFirestore` elsewhere), `repositories/` (`XRepositoryImpl` that catches and maps through `FailureMapper` into `Either`).
- **domain/**: `entities/` (Equatable, pure Dart; two import `flutter/foundation`), `repositories/` (abstract contracts), `usecases/` (`UseCase<T,P>` / `StreamUseCase<T,P>` from `lib/core/usecases/usecase.dart`, one `@injectable` class per action, often several per file, e.g. `auth_usecases.dart`).
- **presentation/**: `bloc/` or `cubit/` (with `part` files for event/state), `pages/`, `widgets/`.
- I checked the layer rules with grep: no presentation file imports `data/`, and no domain file imports `cloud_firestore`. `core/` and `app/` do import features in a few places (see smells).
- App-wide "scopes" sit **above the router** in `MaterialApp.builder`: `AppGate` → `OfflineBanner` → `ActivityScope` → `ShareInScope` → `PurchasesScope` → `QuickAddLinkScope`.
- Offline-first: Firestore persistence is on with an unlimited cache. Counters are moved with `FieldValue.increment` inside the same `WriteBatch` as the mutation, never in transactions (`lib/core/utils/budget_counters.dart`, `storage_counters.dart`), so writes queue while offline.

A representative feature is `auth` (expanded below). The flow: `SignInPage` provides `getIt<AuthBloc>()` → the bloc calls the `SignInWithEmail` use case → `AuthRepository.signInWithEmail` → `_guard(() => _remote.signInWithEmail(...))` → `FailureMapper.fromAuth`. The page never navigates. `SessionCubit` sees the auth change and the router redirect moves the user.

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                       # void main() => bootstrap(BaytnaApp.new)
├── bootstrap.dart                  # zone guard, Firebase, Crashlytics, emulator, Firestore settings, Hive, EasyLocalization, DI, dev command channel
├── firebase_options.dart           # FlutterFire config (exists; not opened)
├── app/
│   ├── app.dart                    # MultiBlocProvider (session, theme, connectivity, config, purchases) + MaterialApp.router + text-scale clamp + scopes
│   ├── observers/app_bloc_observer.dart   # dev.log transitions in debug; Crashlytics on error in release
│   ├── router/                     # app_router.dart (GoRouter + guard), routes.dart (paths/builders, AppTab), router_refresh_stream.dart
│   ├── session/session_cubit.dart  # SessionStatus for the redirect guard
│   └── theme/                      # app_theme, app_colors (AppPalette ThemeExtension, RoomTint, legacy AppColors), app_typography (AppTypography/AppType), app_spacing (AppSpacing/AppRadii/AppBorders/AppSizes), app_motion, app_shadows, theme_cubit
├── core/
│   ├── constants/                  # app_constants (AppConstants, AppLinks, AppLocales), dev_flags, firebase_collections (collections/docs/fields), storage_paths
│   ├── di/                         # injection.dart (+ injection.config.dart generated)
│   ├── errors/                     # exceptions.dart (sealed AppException), failures.dart (sealed Failure), failure_mapper.dart
│   ├── localization/               # (empty)
│   ├── network/                    # network_info.dart, connectivity_cubit.dart
│   ├── quota/quota_gate.dart       # pluggable "may I add one more?" policy (paywall gate)
│   ├── services/                   # analytics, app_info, compression_plan, dev_command_watcher, firebase_image_upload, iap_purchase, image_source, image_upload, link_preview, notification, purchase, settings_store, share_in, share, url, video_link, widget_snapshot
│   ├── usecases/usecase.dart       # UseCase / StreamUseCase / NoParams
│   ├── utils/                      # budget_counters, storage_counters, formatters, validators, image_fetcher, room_visibility, thousands_input_formatter, timestamp_converter, xlsx_writer
│   │   └── extensions/             # context_x, widget_x (+Gap), stream_x (switchMap), plural_x (counted)
│   └── widgets/                    # app_* design system + domain drawings
│       └── storybook/              # brand pieces: arch_window, circle_icon_button, door_mark, home_facade, split_bar, sticker, story_ring, story_viewer
└── features/                       # 17 features
    ├── activity/     # live activity feed, in-app banner scope
    ├── admin/        # admin panel (spaces, brands, storage, ledger, settings, reports) — cubits only
    ├── auth/         # email/Google/Apple sign-in, onboarding, splash
    ├── brands/       # admin-curated brand suggestions
    ├── budget/       # shared wallet, contributions, ledger, export
    ├── categories/   # entity + manager sheet only (empty data/ dirs)
    ├── config/       # remote app settings: maintenance, version gate, upload switch
    ├── home_book/    # PDF + XLSX "home book" export
    ├── items/        # the core: items, decide (swipe), quick add, purchases, invoices, comments (44 files)
    ├── media/        # image picker field + editor cubit, video links/player
    ├── moderation/   # report/block content
    ├── profile/      # Us tab + settings (presentation only)
    ├── purchases/    # IAP grant pipeline, paywall, quota policy
    ├── rooms/        # rooms list/detail/board/showroom
    ├── search/       # local item search
    ├── space/        # the shared "space": create/join/invite, home, milestones, recap, app shell
    └── widgets/      # Android home-screen widget snapshot publisher
```

Representative feature expanded, `features/auth/`:

```
auth/
├── data/
│   ├── datasources/auth_remote_data_source.dart   # FirebaseAuth + users doc; Google v7 authenticate(), Apple; throws
│   ├── models/app_user_model.dart                 # @freezed + json_serializable, fromDoc/toEntity/toFirestore (strips uid/role/createdAt)
│   └── repositories/auth_repository_impl.dart     # watchCurrentUser via switchMap(authStateChanges → user doc snapshots); _guard → FailureMapper
├── domain/
│   ├── entities/app_user.dart                     # AppUser, UserRole.fromWire (fails closed)
│   ├── repositories/auth_repository.dart
│   └── usecases/auth_usecases.dart                # SignInWithEmail, SignUpWithEmail, SignInWithGoogle, SignInWithApple, SendPasswordReset, SignOut
└── presentation/
    ├── bloc/auth_bloc.dart (+ auth_event.dart, auth_state.dart)   # status enum, failure, _run helper
    ├── pages/ splash, onboarding, auth_landing, sign_in, sign_up, forgot_password
    └── widgets/ auth_header, password_strength, social_sign_in_buttons
```

## 3. Infrastructure

### State management
- `flutter_bloc ^9.1.1`, `bloc ^9.2.1`, `equatable`. 7 `Bloc`s (auth, rooms, room_detail, items, item_detail, activity, space) and 23 `Cubit`s.
- There is no `BaseCubit`/`BaseState`. The pattern repeats per bloc: `emit(state.copyWith(status: loading, clearFailure: true))` → await use case → `result.fold(failure → state.copyWith(status: failure, failure: f), data → …)`. `AuthBloc._run` is the cleanest example.
- One-shot statuses (`created`, `deleted`) are cleared with an explicit `XStatusReset` event.
- Streams: the bloc keeps a `StreamSubscription<Either<Failure,T>>`, re-dispatches each event as `XUpdated(result)` and cancels in `close()`. It does not use `emit.forEach`.
- App-lifetime singletons (`SessionCubit`, `ThemeCubit`, `ConnectivityCubit`, `AppConfigCubit`, `PurchasesCubit`, `ActivityBloc`) are `@lazySingleton` and provided with `BlocProvider.value`. Screen blocs are `@injectable` factories created in `BlocProvider(create: (_) => getIt<X>())`.
- `AppBlocObserver` (`lib/app/observers/app_bloc_observer.dart`): `developer.log` of transitions in debug, `FirebaseCrashlytics.recordError(reason: 'bloc: …')` in release.
- Quality: consistent and readable. Every bloc writes the same boilerplate by hand, so a template should add a small `BaseState`/`runEither` helper.

### DI
- `get_it ^9.2.1` + `injectable ^3.0.0` (+ `injectable_generator`). `lib/core/di/injection.dart`: `@InjectableInit(initializerName: 'init', asExtension: true, preferRelativeImports: true)`, `configureDependencies()` is called from bootstrap after `Hive.openBox`.
- `RegisterModule` registers `FirebaseAuth`, `FirebaseFirestore`, `Connectivity`, `Uuid` and the opened Hive `Box`. `FirebaseStorage` and `ImagePicker` are left out **on purpose**, so that only `FirebaseImageUploadService` touches them (documented in the module).
- No environments (`@Environment`) and no test overrides module. 120 `getIt<…>()` calls inside feature widgets make it a service locator in practice.

### Routing
- `go_router ^17.5.0`. `lib/app/router/app_router.dart` is an `@lazySingleton AppRouter(SessionCubit, SettingsStore)` that exposes `late final GoRouter router`, a static `rootNavigatorKey` (used by widgets above the router) and a shell key.
- `refreshListenable: GoRouterRefreshStream(_session.stream)` (`router_refresh_stream.dart`, a stream → ChangeNotifier adapter).
- Guard `_guard`:
  - unresolved → splash
  - unauthenticated → onboarding (if not yet seen, from Hive) → `/auth/*`
  - signed in, no space → `/space-gate` (an admin goes to `/admin` instead)
  - signed in with a space → bounce off the pre-auth screens to `/home` (or `DevFlags.takeInitialRoute()`), and keep any other location so deep links survive
  - non-admins are kept out of `/admin`
- `StatefulShellRoute.indexedStack` holds 4 branches (home, rooms, budget, us). Detail routes use `parentNavigatorKey: _rootKey`. Legacy paths `/profile` and `/profile/settings` redirect. `/items/add` is declared before `/items/:itemId`, and a comment explains the match order.
- `routes.dart`: `abstract final class Routes` holds path constants plus `toRoom()`, `toItem()` and `toActivityTarget()` builders, and `enum AppTab`.
- Platform deep links: custom URL scheme on Android (intent-filter + `flutter_deeplinking_enabled`) and iOS (`CFBundleURLSchemes`, `FlutterDeepLinkingEnabled`). No universal/app links.
- Quality: excellent. A template could reuse it almost unchanged by swapping the status enum.

### Networking
- No REST client. The data layer is Firestore, Auth and Storage directly. Repositories map errors:
  - `_guard<T>(action)` → `Right` or `Left(FailureMapper.fromFirestore(e))`; `SpaceFailureException` lets a data source throw a domain `Failure` directly.
  - `_wrapStream<T>(stream)` turns a stream into `Stream<Either>`.
  - **Bug:** in 6 repositories `_wrapStream` uses `.handleError((e) => Left(...))`. `handleError` ignores what its callback returns, so errors are swallowed instead of being emitted as `Left`. `admin_repository_impl.dart` and `brands_repository_impl.dart` already use the correct `StreamTransformer.fromHandlers(handleError: (e, st, sink) => sink.add(Left(...)))`, with a comment explaining why. **Use that version in a template.**
- `lib/core/errors/failure_mapper.dart`: `fromAuth` maps FirebaseAuthException codes (wrong-password, invalid-credential → `WrongCredentialsFailure`, requires-recent-login, too-many-requests…), `GoogleSignInException` (canceled → quiet `SignInCancelledFailure`, client/provider configuration errors → `GoogleSignInUnavailableFailure`), Apple cancel, and app `AuthException.code`. `fromFirestore` maps permission-denied, not-found and unavailable.
- `lib/core/network/network_info.dart` (`NetworkInfo` over connectivity_plus, `.distinct()`) and `connectivity_cubit.dart` (starts optimistic `true`, then primes with the real value so the banner never flashes on a healthy start).
- `lib/core/services/link_preview_service.dart`: `HttpLinkPreviewService` uses dart:io `HttpClient` with a 5 s timeout, a 1 MB cap and redirects, and a separate pure `LinkPreviewParser` (regex og:/twitter:/itemprop/JSON-LD offers). It is unit-tested.
- `lib/core/utils/image_fetcher.dart`: batched, concurrency-limited byte fetch with size caps (for the PDF).
- No retry and no interceptors. Token refresh is handled by the Firebase SDK.

### Local storage
- `hive ^2.2.3` + `hive_flutter`. One `Box<dynamic>` named `settings` is opened in bootstrap and injected.
- `lib/core/services/settings_store.dart`: `abstract class SettingsStore` + `HiveSettingsStore` with typed getters and setters (themeMode, useArabicNumerals, onboardingSeen, openLinksInApp, recentSearches with dedupe and cap, per-space celebrated milestones, recap dismissal, per-room view mode). Keys live in `AppConstants`.
- No secure storage. Auth persistence is handled by Firebase.
- Firestore offline persistence: `Settings(persistenceEnabled: true, cacheSizeBytes: CACHE_SIZE_UNLIMITED)`.
- Quality 4. It is a clean interface; the `as bool` casts are fine because the store is the only writer.

### Localization and RTL
- `easy_localization ^3.0.8`, set up in bootstrap: `supportedLocales [en, ar]`, `path: assets/translations`, `fallbackLocale: ar`, `useOnlyLangCode: true`, **`ignorePluralRules: false`** (real Arabic few/many forms). No `startLocale`, so the device locale is used. The chosen locale is mirrored onto the user document.
- JSON files: `assets/translations/en.json` (~1,279 keys), `ar.json` (~1,306), grouped by feature. Arabic contains every English key.
- `lib/core/utils/extensions/plural_x.dart`: `'key'.counted(n)` keeps a `.zero` sentence when one exists and otherwise uses `plural()`.
- Keys flow through the code: `Failure.translationKey`, validator return values, `AppTextField(labelKey:)`, `AppDialog.show(titleKey:)`, `AppBottomSheet.show(titleKey:)`, and `Formatters.relativeTimeKey` returning `(key, value)`. Hardcoded strings are close to zero (841 `.tr(` calls, 0 `Text('literal')`).
- RTL: 266 directional usages vs 5 left/right, and none of the 5 is a real problem. `WidgetX.paddedOnly(start:, end:)`. Components flip themselves: segmented pill and switch use `AlignmentDirectional`, the progress ring sweeps anticlockwise in RTL, stickers lean the other way, story tap zones mirror, `CircleIconButton.flipInRtl`. `Formatters.bytes` returns value and unit separately so the order can follow the direction. `AppTheme.light/dark(isArabic:)` is rebuilt on locale change.
- Eastern Arabic digits are a user setting (`ThemeCubit.useArabicNumerals`) and are passed explicitly to every `Formatters.*` call.
- `tool/dev/add_strings.py` merges dotted keys into both files.

### Theming
- `lib/app/theme/app_theme.dart`: `AppTheme.light/dark({required bool isArabic})` → one `_build(palette)`. Material 3, a `ColorScheme` built from the palette, the `AppPalette` registered as a `ThemeExtension`, `InkSparkle`, and full component themes: AppBar (flat), Card, InputDecoration (filled, outline borders, focus/error states), Filled/Outlined/Text/Icon buttons (stadium, 52 high), FAB, BottomSheet, Dialog, SnackBar (floating, inset above the nav), Chip, Switch/Radio/Checkbox via `WidgetStateProperty`, SegmentedButton, ProgressIndicator, Slider, and PageTransitions (FadeForwards on Android, Cupertino on iOS).
- `app_colors.dart`:
  - `PaintSet{fill, soft, ink, on}` and `AppPalette extends ThemeExtension` with `day`/`night` consts (surfaces whitewash/plaster/card/card2, ink 1–3, line, 6 room paints + danger, shadow colours, facade colours). Read through `context.palette`.
  - `lerp` snaps at t = 0.5 instead of interpolating.
  - Also holds the legacy `AppColors` consts (marked for removal but still used 101 times), `RoomTint`, and extensions that colour domain enums (`ItemPriority`, `ItemStatus`, `ItemReaction`). Those extensions are what couple the theme to the items feature.
- `app_typography.dart`: `AppTypography.textTheme()` (Material slots) and `AppType` (board-named styles `d48…d18`, `t18…t12`, `label16/14`, `num()` tabular figures). Two families that both cover Arabic, so no font swap per locale.
- `app_spacing.dart`: `AppSpacing` (4-pt scale, gutter 20, minTouchTarget 48, navClearance), `AppRadii` (+ BorderRadius consts), `AppBorders`, `AppSizes`. Re-exports `app_motion.dart`.
- `app_motion.dart`: durations, curves, `SpringDescription`s, `AppMotion.reduced(context)` and `AppMotion.of(context, d)` (zero under reduced motion).
- `app_shadows.dart`: `sticker(p)` (hard, no blur) and `float(p)` (one soft shadow), plus legacy getters.
- `theme_cubit.dart`: ThemeMode, Arabic numerals and the in-app-browser toggle, persisted in `SettingsStore`.
- Quality 5 as a token system. A template should drop the legacy `AppColors` and the domain-enum extensions.

### Responsive helpers
- None. No screenutil and no breakpoints; layouts rely on fixed tokens, `Expanded` and `LayoutBuilder` in a few places. The latest commits fix label truncation on 390–411 dp wide phones by hand. It is phone-only.

### Text scaling
- `lib/app/app.dart`, inside `MaterialApp.router(builder:)`: `media.copyWith(textScaler: media.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.4))`. This is the modern API.

### Env / flavors
- No flavors and no dotenv. `lib/core/constants/dev_flags.dart` reads `bool/String.fromEnvironment` and each flag also requires `kDebugMode`:
  - `USE_FIREBASE_EMULATOR`, `FIREBASE_EMULATOR_HOST` (Auth 9099, Firestore 8080)
  - `DEV_AUTO_LOGIN=email:password` (sign in before the first frame)
  - `DEV_INITIAL_ROUTE` (read once by the guard)
- `lib/core/services/dev_command_watcher.dart`: debug + emulator only. It polls `Documents/dev_cmd.txt` every 600 ms for `go:`, `login:`, `logout`, `locale:`, `theme:`, `onboarding:` and `sheet:` commands; the callbacks are wired in bootstrap. `tool/dev/shot.sh` uses it to script simulator screenshots.
- Remote config comes from a Firestore document (`config/appSettings`) watched by `AppConfigCubit`, not from Firebase Remote Config.

### Logging
- `debugPrint` (21 calls, mostly in catch blocks) and `dart:developer.log` in the bloc observer. No logger/talker. One leftover debug line in `FirebaseImageUploadService.upload` prints bucket, uid and byte count on every upload.

### Analytics / crash reporting
- `firebase_crashlytics ^5.2.7`: collection enabled only when `!kDebugMode`; `FlutterError.onError → recordFlutterFatalError`; `PlatformDispatcher.instance.onError`; `runZonedGuarded` handler; bloc errors from the observer.
- `firebase_analytics ^12.4.6`: `lib/core/services/analytics_service.dart` has `AnalyticsService.log(name, params)` + `AnalyticsEvents` constants (paywall/purchase funnel). It is skipped when running against emulators and never throws.

### Push notifications
- None, by design (no-server rule). `lib/core/services/notification_service.dart` defines `NotificationService` (`supportsPush=false`, banner stream, tap stream), but only `supportsPush` is read (settings page). The real in-app banner path is `features/activity/presentation/widgets/activity_scope.dart`, a singleton `ActivityBloc` on a live Firestore listener that shows `InAppNotificationBanner` (slide-in + haptic) above the router.

### IAP / payments
- `in_app_purchase ^3.3.1`, `in_app_purchase_android ^0.5.5` (Billing 8+).
- `lib/core/services/purchase_service.dart` defines `PurchaseService`, `StoreProduct` (store-localized price string) and `StorePurchase`.
- `iap_purchase_service.dart` (the only file that imports the plugin):
  - turns the purchase stream into a broadcast of `StorePurchase`
  - keeps open deliveries keyed by token
  - `buyConsumable(autoConsume: false)`, so the ledger is written before consume
  - `complete()` consumes on Android, or calls `completePurchase` otherwise
  - re-queues the delivery if completing fails
  - detects cancellation heuristically
- `features/purchases/` holds the grant pipeline: hash the token → `grant()` checks whether the ledger document exists, then one `WriteBatch` writes the ledger document and the space entitlements. The ledger is create-only in the rules.
- `PurchasesScope` and `PaywallSheet`. `lib/core/quota/quota_gate.dart` is a static `QuotaGate.policy` that bootstrap swaps for `EntitlementQuotaPolicy`; every entry point that creates an item asks before showing its form.
- Caveat: there is no server-side receipt validation (client-trusted grants).

### Permissions
- No permission_handler. Camera and gallery prompts come from `image_picker` and `mobile_scanner` (QR join code).

### Deep links
- go_router paths with the custom scheme, described above. Android text share-in arrives through `PlatformShareInService` (MethodChannel `getInitialShare` + EventChannel stream, Android only; platform side in MainActivity.kt) and is consumed by `ShareInScope`. Android home-screen widgets (`home_widget`) open `?quickAdd=1`, which `QuickAddLinkScope` handles by watching the router.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| lib/core/services/analytics_service.dart | Analytics facade + event names | `AnalyticsService.log(name,[params])`; `AnalyticsEvents.*` | firebase_analytics, DevFlags | generic |
| lib/core/services/app_info_service.dart | Build number / version name, testable | `load()`, `buildNumber`, `versionName` | package_info_plus | generic |
| lib/core/services/settings_store.dart | Local prefs over Hive | theme, numerals, onboarding, openLinksInApp, recent searches, milestones, recap, room view | Hive Box | generic shape, app keys |
| lib/core/services/url_service.dart | Open URLs (in-app → external), display host | `open(url) → bool`, `displayHost(url)` | url_launcher, SettingsStore | generic |
| lib/core/services/share_service.dart | Share sheet | `shareText`, `shareInvite`, `shareImage(bytes)`, `shareFile(bytes, mime)` | share_plus | generic |
| lib/core/services/share_in_service.dart | Receive shared text (Android) | `takeInitialShare()`, `shares` stream | MethodChannel/EventChannel | generic (needs native side) |
| lib/core/services/image_upload_service.dart | Upload contract + PendingImage/UploadedImage/MultiImagePickResult | `pickAndPrepare`, `pickMultipleAndPrepare`, `upload(onProgress)`, `deleteByUrl`, `isManagedUrl` | dartz, Failure | generic |
| lib/core/services/firebase_image_upload_service.dart | Implementation: pick, compress WebP (2-pass), stage in temp, upload with progress, owned-bucket check | as above | firebase_storage, image_picker, flutter_image_compress, path_provider, uuid | generic |
| lib/core/services/compression_plan.dart | Size/quality tiers by bytes and pixels; photo vs invoice | `CompressionPlan.forImage`, `targetSize` | — | generic |
| lib/core/services/image_source_service.dart | Old paste-a-URL image source | `supportsUpload`, `readUrlFromClipboard`, `normalizeUrl` | Clipboard, Validators | generic, **unused** |
| lib/core/services/link_preview_service.dart | OG/JSON-LD product preview | `fetch(url) → Either<Failure, LinkPreview>`; `LinkPreviewParser.parse` | dart:io HttpClient | generic |
| lib/core/services/video_link_service.dart | Classify video URLs (YouTube id, file, embed providers) | `parse(raw) → VideoLink?`, `supportedFileFormats` | — | generic |
| lib/core/services/notification_service.dart | In-app notification contract | `supportsPush`, `show`, `onNotificationTapped`, `dispose` | — | generic, mostly unused |
| lib/core/services/purchase_service.dart | Store contract | `products(ids)`, `purchases`, `buy(product, consumable)`, `restore()`, `complete(p, consume)` | dartz | generic |
| lib/core/services/iap_purchase_service.dart | in_app_purchase implementation | as above | in_app_purchase(+_android) | generic |
| lib/core/services/widget_snapshot_service.dart | Write Android home-widget data + render Flutter widgets to PNG | `publish(snapshot, images)` | home_widget | app-specific (provider names, package name) |
| lib/core/services/dev_command_watcher.dart | Debug file command channel | `start()`, `stop()` | path_provider, DevFlags | generic (dev tooling) |
| lib/core/network/network_info.dart | Connectivity hint | `isConnected`, `onConnectivityChanged` | connectivity_plus | generic |
| lib/core/network/connectivity_cubit.dart | App-wide online state | `Cubit<bool>` | NetworkInfo | generic |
| lib/core/quota/quota_gate.dart | Pluggable gate before create flows | `QuotaGate.run(context, onAllowed)`, `QuotaPolicy.check` | — | generic pattern |
| lib/core/errors/exceptions.dart | Sealed data-layer exceptions | Server/Network/Permission/NotFound/Cache/Auth(code) | — | generic |
| lib/core/errors/failures.dart | Sealed Failure (translation key) + ~35 subclasses | — | equatable | generic base, app subclasses |
| lib/core/errors/failure_mapper.dart | Error → Failure | `fromAuth`, `fromFirestore` | firebase_auth, google_sign_in, sign_in_with_apple | generic for Firebase apps |
| lib/core/usecases/usecase.dart | Use-case bases | `UseCase<T,P>.call`, `StreamUseCase<T,P>.call`, `NoParams` | dartz | generic |
| lib/core/di/injection.dart | DI init + module | `getIt`, `configureDependencies()`, `RegisterModule` | get_it, injectable | generic |
| lib/core/constants/app_constants.dart | AppConstants / AppLinks / AppLocales | consts | — | app-specific values |
| lib/core/constants/dev_flags.dart | dart-define dev switches | `useEmulator`, `emulatorHost`, `autoLogin`, `takeInitialRoute()` | — | generic |
| lib/core/constants/firebase_collections.dart | Collection/doc/field names | consts | — | pattern generic |
| lib/core/constants/storage_paths.dart | Storage object path builders | `roomImage`, `itemImage`, `itemInvoice` | — | pattern generic |
| lib/core/utils/formatters.dart | Locale-aware formatting + Eastern digits | `money`, `signedMoney`, `parseMoney`, `number`, `bytes`, `percent`, `date`, `dateTime`, `time`, `relativeTimeKey`, `toEasternDigits` | intl | generic |
| lib/core/utils/validators.dart | Validators → translation keys | `email`, `password`, `confirmPassword`, `required`, `displayName`, `imageUrl`, `isValidHttpUrl`, `inviteCode`, `price`, `requiredPrice`, `quantity` | AppConstants | generic (mostly) |
| lib/core/utils/thousands_input_formatter.dart | Live thousands grouping in money fields | `TextInputFormatter` | intl | generic |
| lib/core/utils/timestamp_converter.dart | Firestore Timestamp ↔ DateTime JsonConverters (nullable + required) | — | cloud_firestore, json_annotation | generic (Firestore) |
| lib/core/utils/xlsx_writer.dart | Minimal .xlsx writer (inline strings, bold headers, RTL sheets, widths) | `XlsxWriter.write(sheets)`, `XlsxSheet` | archive | generic |
| lib/core/utils/image_fetcher.dart | Batched capped image byte fetch | `fetchAll(urls, limit, concurrency, maxBytes, timeout)` | dart:io | generic |
| lib/core/utils/budget_counters.dart | Wallet counters into a WriteBatch | static apply methods | Firestore, items entities | app-specific |
| lib/core/utils/storage_counters.dart | Storage byte/file counters into a WriteBatch | `apply(batch, …)` | Firestore | pattern generic |
| lib/core/utils/room_visibility.dart | Rule-provable "shared or mine" queries | `visibleTo`, `shared` | Firestore | app-specific (pattern useful) |
| lib/core/utils/extensions/context_x.dart | Context accessors | `theme`, `text`, `colors`, `media`, `screenSize`, `isDark`, `palette`, `reducedMotion`, `direction`, `isRtl`, `isArabic`, `localeCode` | theme | generic |
| lib/core/utils/extensions/widget_x.dart | Directional padding + Gap | `paddedAll/Symmetric/Only`, `gutter`, `sliver`, `Gap.xs…xxxl` | AppSpacing | generic |
| lib/core/utils/extensions/stream_x.dart | switchMap | `switchMap(mapper)` | — | generic |
| lib/core/utils/extensions/plural_x.dart | Plural helper | `counted(n)` | easy_localization | generic |
| lib/app/session/session_cubit.dart | Session status for routing | `state.status/user/spaceId/isAdmin`, `signOut()` | AuthRepository | semi-generic |
| lib/app/theme/theme_cubit.dart | Theme mode + local toggles | `setMode`, `toggleArabicNumerals`, `toggleOpenLinksInApp` | SettingsStore | generic |
| lib/app/observers/app_bloc_observer.dart | Bloc logging/crash | — | crashlytics | generic |
| lib/app/router/router_refresh_stream.dart | Stream → Listenable | `GoRouterRefreshStream(stream)` | — | generic |
| lib/features/config/presentation/cubit/app_config_cubit.dart | Live remote config + version gate state | `start()`, `markOptionalUpdateShown()`, `state.requirement/shouldPromptUpdate` | ConfigRepository, AppInfoService | generic pattern |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/widgets/app_button.dart | Primary button, 9 variants, press-drop shadow, loading | label, onPressed, variant, icon, isLoading, expand, small; `.secondary/.ink/.text` | y |
| lib/core/widgets/app_text_field.dart | Text field, label above, focus halo, key-based validator | controller, labelKey, hintKey, helperKey, validator, keyboardType, obscureText, textInputAction, onSubmitted, onChanged, prefixIcon, prefix, suffix, maxLines, maxLength, enabled, autofillHints, inputFormatters, textCapitalization, autofocus, focusNode, textAlign, style, readOnly, onTap | y |
| lib/core/widgets/app_dialog.dart | Confirm dialog / notice | show(titleKey, primaryLabelKey, bodyKey, bodyArgs, titleArgs, icon, secondaryLabelKey, destructive, content, barrierDismissible); notice(titleKey, bodyKey, icon, buttonKey) | y |
| lib/core/widgets/app_bottom_sheet.dart | Modal bottom sheet | show<T>(context, child, titleKey, isScrollable, isDismissible) | y |
| lib/core/widgets/app_snackbar.dart | Snackbars incl. undo with countdown | failure(ctx, Failure), success(ctx, key), info(ctx, key), undo(ctx, message, onUndo, duration) | y |
| lib/core/widgets/app_loader.dart | Shimmer + skeletons + spinner | AppShimmer(child)/.block(height,width,radius); AppListSkeleton(itemCount,itemHeight); AppGridSkeleton(itemCount); AppSkeleton.home/detail/wallet/rows/rooms; AppLoader(size) | y (screen skeletons app-specific) |
| lib/core/widgets/app_empty_state.dart | Empty / error / offline states | titleKey, messageKey, art, icon, actionLabelKey, onAction, actionIcon; `.error`, `.offline` | y (EmptyArt enum app-specific) |
| lib/core/widgets/app_card.dart | Card raised/flat/lifted | child, onTap, onLongPress, padding, accented, style, clip; `.lifted`, `.flat` | y |
| lib/core/widgets/app_chip.dart | Label/filter chip + chip row | AppChip(label, variant, icon, trailing, onTap, selected, filter, semanticLabel, iconColor), `.filter`; AppChipRow<T>(values, labelOf, iconOf, selected, onSelected, padding) | y |
| lib/core/widgets/app_segmented.dart | Sliding segmented control | segments (AppSegment value/label/icon), value, onChanged, height | y |
| lib/core/widgets/app_switch.dart | Switch + settings tile | AppSwitch(value, onChanged, semanticLabel); AppSwitchTile(title, subtitle, icon, value, onChanged) | y |
| lib/core/widgets/app_avatar.dart | Avatar + stack | AppAvatar(initials, photoUrl, size, showBorder, tone); AppAvatarStack(avatars, size, maxVisible) | y (tone semantics app-ish) |
| lib/core/widgets/remote_image.dart | Network image + broken fallback | RemoteImage(url, fit); BrokenImage() | y |
| lib/core/widgets/offline_banner.dart | App-wide offline bar | child | y |
| lib/core/widgets/press_scale.dart | Spring press scale | child, enabled, scale | y |
| lib/core/widgets/staggered_entrance.dart | Staggered list entrance | index, child | y |
| lib/core/widgets/image_gallery_viewer.dart | Full-screen zoomable gallery | itemCount, initialIndex, itemBuilder, urls, caption; static open()/openUrls() | y |
| lib/core/widgets/progress_ring.dart | Ring + bar progress | ProgressRing(progress, secondary, size, stroke, color, secondaryColor, trackColor, child, animateOnAppear, semanticLabel); ProgressBar(progress, secondary, height, colors, semanticLabel) | y |
| lib/core/widgets/confetti.dart | Confetti burst | pieces, seed | y |
| lib/core/widgets/framed_box.dart | Outline painted over clipped content | borderRadius, borderColor, borderWidth, child, color, padding, width, height, alignment | y |
| lib/core/widgets/scrim_icon_button.dart | Icon/back/menu buttons over photos | ScrimIconButton(icon, tooltip, onPressed); ScrimBackButton(); ScrimMenuButton<T>(tooltip, onSelected, …) | y |
| lib/core/widgets/evening_card.dart | Bold hero card (white content) | child, onTap, padding, pattern, heroTag | brand |
| lib/core/widgets/phase_placeholder.dart | Placeholder screen | titleKey, phaseKey, showAppBar, showBackButton | y (dead) |
| lib/core/widgets/segmented_status.dart | Item status pill + selector | status, onChanged, showLabels; StatusPill(status, compact) | n |
| lib/core/widgets/priority_chip.dart | Priority chip + selector | priority, selected, onTap, compact; PrioritySelector(value, onChanged) | n |
| lib/core/widgets/room_cover.dart | Room cover / swatch | tint, imageUrl, child, height, borderRadius, scrim, heroTag, padding; RoomSwatch(tint, icon, size, imageUrl) | n |
| lib/core/widgets/arch_divider.dart | Brand arch divider | width, muted | n |
| lib/core/widgets/storybook/circle_icon_button.dart | Round icon button + badge | icon, onPressed, tooltip, style, badge, badgeColor, flipInRtl, size | y |
| lib/core/widgets/storybook/story_viewer.dart | Story player | slides (StorySlide background/foreground/builder/advance), header, tapHint, onClose | y |
| lib/core/widgets/storybook/story_ring.dart | Story bubble | label, child, seen, background, onTap | semi |
| lib/core/widgets/storybook/sticker.dart | Tilted tag | label, tone, icon, degrees, small, pop | brand |
| lib/core/widgets/storybook/arch_window.dart, door_mark.dart, home_facade.dart, split_bar.dart | Brand/domain drawings (CustomPainter) | — | n |
| lib/features/admin/presentation/widgets/typed_confirmation_dialog.dart | Type-to-confirm dialog | titleKey, messageKey, confirmWord, consequence, allowNote, noteLabelKey, isDestructive; static show() → String? | y |
| lib/features/auth/presentation/widgets/password_strength.dart | Strength meter | password | y |
| lib/features/auth/presentation/widgets/social_sign_in_buttons.dart | Google/Apple buttons + labelled divider | onGoogle, onApple, enabled; LabelledDivider(labelKey) | y |
| lib/features/auth/presentation/widgets/auth_header.dart | Auth page header | titleKey, subtitleKey | semi |
| lib/features/space/presentation/widgets/app_shell.dart | Shell + floating nav with centre action | AppShell(shell); FloatingNavBar(tabs, currentIndex, onTap, onAdd); NavTabSpec | semi |
| lib/features/config/presentation/widgets/app_gate.dart | Maintenance / forced-update / optional-update gate | child | y (pattern) |
| lib/features/activity/presentation/widgets/in_app_notification_banner.dart | Slide-in banner | activity, onTap, onDismissed | semi |
| lib/features/media/presentation/widgets/image_picker_field.dart | Multi-image picker field (staged) + PhotoSourceSheet | labelKey, maxImagesOverride | semi |
| lib/features/media/presentation/widgets/video_player_view.dart / video_link_field.dart / video_link_card.dart | Video playback / link list / link card | url; urls, onChanged | semi |

## 6. Packages (pubspec.yaml)

- **State:** flutter_bloc ^9.1.1, bloc ^9.2.1, equatable ^2.1.0
- **DI:** get_it ^9.2.1, injectable ^3.0.0
- **Routing:** go_router ^17.5.0
- **FP / codegen:** dartz ^0.10.1, freezed_annotation ^3.1.0, json_annotation ^4.12.0
- **Firebase:** firebase_core ^4.13.0, firebase_auth ^6.5.7, cloud_firestore ^6.8.0, firebase_storage ^13.4.6, firebase_crashlytics ^5.2.7, firebase_analytics ^12.4.6
- **Auth providers:** google_sign_in ^7.2.0, sign_in_with_apple ^8.1.0, crypto ^3.0.7 (hashes IAP purchase tokens)
- **Storage:** hive ^2.2.3, hive_flutter ^1.1.0, path_provider ^2.1.6
- **L10n:** easy_localization ^3.0.8, intl ^0.20.2, characters ^1.4.1
- **Network / device:** connectivity_plus ^7.3.1, url_launcher ^6.3.2, package_info_plus ^10.2.1, share_plus ^13.3.0, home_widget ^0.10.0
- **IAP:** in_app_purchase ^3.3.1, in_app_purchase_android ^0.5.5
- **Media / UI:** cached_network_image ^3.4.1, image_picker ^1.2.3, flutter_image_compress ^2.5.1, flutter_svg ^2.3.0, shimmer ^3.0.0, qr_flutter ^4.1.0, mobile_scanner ^7.1.4, youtube_player_iframe ^6.0.2, cupertino_icons ^1.0.8
- **Docs / export:** pdf ^3.13.1, archive ^4.5.2 (hand-written xlsx; a comment explains why the excel package was dropped)
- **Utils:** uuid ^4.6.0
- **Dev:** flutter_test, flutter_lints ^6.0.0, build_runner ^2.15.1, freezed ^3.2.5, json_serializable ^6.14.1, injectable_generator ^3.0.2, flutter_launcher_icons ^0.14.4, flutter_native_splash ^2.4.7, bloc_test ^10.0.0, mocktail ^1.0.5, shared_preferences ^2.5.5 (unused)

Other tooling in the repo:
- `.github/workflows/` (ci.yml: Android + iOS builds with secrets restored from CI; release.yml; bump-build-number.yml)
- `tool/` (bump_build_number.sh, make_upload_key.sh (interactive, no committed secrets), prepare_screenshots.py, tool/store/* Play/App Store Connect listing scripts, tool/dev/*)
- `hosting/` (static landing, privacy, terms, delete-account pages)
- `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `docs/` (claude.md rules, release/IAP/store docs)

**test/rules/** (Node): `package.json` with `@firebase/rules-unit-testing ^4` + `firebase ^11`. `pretest` copies the root `firestore.rules`/`storage.rules` in, and `npm test` runs `firebase emulators:exec --only firestore,storage "node --test rules.test.mjs"`. About 125 `it()` cases with positive and negative checks (seeded users/spaces including an admin and an outsider), using `node:test` + `assert/strict`. It is a strong pattern for any Firebase template.

**tool/seed/** (Node): `firebase-admin ^13`. `seed.mjs` (336 lines) creates emulator Auth users and a furnished space (rooms, items, contributions, activities) for screenshots and manual QA. It **refuses to run unless `FIRESTORE_EMULATOR_HOST` and `FIREBASE_AUTH_EMULATOR_HOST` are set**. It uses dummy emulator-only credentials.

## 7. Quality notes

- **Null safety / language:** Dart 3.11+, sound null safety. Wide use of `final class`, `sealed`, records, switch expressions and patterns, `abstract final class` for constant holders, and explicit type annotations everywhere. The code is very well commented: nearly every class explains *why* it exists.
- **Lints:** `analysis_options.yaml` = `include: package:flutter_lints/flutter.yaml` with 0 extra rules; it excludes `build/**`. The code style is much stricter than the lint set enforces (`always_specify_types`, `prefer_final`, and so on would pass), so a template should turn those lints on.
- **Tests:** 56 Dart test files under `test/`:
  - unit tests: formatters, validators, stream_x, plural_x, compression plan, link-preview parser, video link service, url service, budget/storage counters, and most domain entities (items, budget, space, rooms, activity, config mapper, entitlements)
  - widget tests: app_gate, design system, framed_box, story viewer, invoice viewer, option sheet, moderation sheets, split editor, activity scope
  - goldens: `test/core/widgets/preview/storybook_{6,8}_{day,night}_{ltr,rtl}.png`
  - `test/app/theme_rtl_smoke_test.dart`: builds both themes in both directions and avoids EasyLocalization's global state on purpose
  - cubit tests: decide_cubit_test, quick_add_cubit_test
  - plus the Node rules suite above. Coverage of repositories and data sources is thin.
- **Smells:**
  1. **Stream error swallowing:** `.handleError((e) => Left(...))` in `lib/features/{rooms,items,space,activity,moderation,budget}/data/repositories/*_impl.dart`. A permission-denied or network error on a listener never reaches the bloc. The fix already exists in `admin_repository_impl.dart`/`brands_repository_impl.dart`.
  2. Repository helpers (`_guard`, `_guardUnit`, `_wrapStream`) are copied into every impl. They should be one mixin or base.
  3. God files: `features/items/presentation/pages/item_detail_page.dart` (1852), `features/rooms/presentation/pages/room_detail_page.dart` (1718), `features/items/data/datasources/items_remote_data_source.dart` (1348), `features/space/presentation/pages/home_page.dart` (1060), `features/profile/presentation/pages/settings_page.dart` (889).
  4. `lib/bootstrap.dart` mixes production boot with ≈200 lines of debug sheet demos that import many feature widgets and stand-in entities.
  5. Design-token migration is half done: legacy `AppColors` is used 101 times in 34 files, `AppShadows.of()` is keyed on brightness rather than the palette, and there are 62 raw `Color(0x…)` in features (mostly celebration screens) and 29 in core/widgets. The snackBar theme hardcodes colours.
  6. The project's own rule "no MaterialPageRoute" is broken in `lib/core/widgets/image_gallery_viewer.dart`, `features/items/presentation/widgets/invoice_viewer.dart`, `features/media/presentation/widgets/video_player_view.dart` and `lib/bootstrap.dart` (all full-screen viewers or dev code), and the comment in `app_router.dart` still claims there are none.
  7. Dead code and scaffolding: `PhasePlaceholder`, `ImageSourceService`/`UrlImageSourceService` (registered, never injected), the unused `NotificationService` banner/tap streams, and 21 empty directories (`core/localization`, and data/domain folders under `profile`, `search`, `categories`).
  8. `core` imports features: `lib/app/theme/app_colors.dart` (items entity, for enum colour extensions), `lib/core/utils/budget_counters.dart`, `lib/core/widgets/segmented_status.dart`, `priority_chip.dart`, `lib/core/services/widget_snapshot_service.dart`.
  9. A debug log in `FirebaseImageUploadService.upload` prints bucket, uid and bytes on every upload.
  10. Hardcoded production values: the public site base URL and support email in `AppLinks` (`app_constants.dart`), the Android package name in `widget_snapshot_service.dart` (as `com.example.app.widgets.*`), the share-in channel names, and the HTTP user agent.
  11. Doc-comment drift: `AppCard.lifted` is documented as "A flat card"; `SpaceFullFailure` still says "at most two members".
  12. Client-trusted IAP grants (ledger + entitlements written by the client; the rules make the ledger create-only). This is acceptable without a backend but is not a reference implementation for paid apps.
  13. `StaggeredEntrance` does not honour reduced motion, unlike every other animated widget.
  14. `AppPalette.lerp` snaps instead of interpolating (theme changes don't animate colours).
  15. 120 `getIt<>()` calls inside widgets and pages; DI is mostly a service locator from the UI.
- **Deprecated APIs:** none found. 0 `withOpacity` (uses `withValues(alpha:)`), 0 `WillPopScope`, 0 `textScaleFactor` (uses `TextScaler.clamp`), 0 `MaterialStateProperty` (uses `WidgetStateProperty`), 0 `print`. Google Sign-In v7 `authenticate()` API and `SharePlus.instance.share(ShareParams)` are current.
- **Secrets:** `lib/firebase_options.dart` is committed (standard FlutterFire; not opened). `google-services.json`, `GoogleService-Info.plist`, `key.properties` and keystores are gitignored and restored in CI from secrets. The only credentials in source are dummy emulator-only test accounts: `tool/seed/seed.mjs`, the doc comments of `lib/core/constants/dev_flags.dart` and `lib/core/services/dev_command_watcher.dart`, and `tool/dev/shot.sh`.
