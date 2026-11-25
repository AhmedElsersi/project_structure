## Summary for comparison

```
PROJECT: corsa-driver | path: D-index/Corsa/driver | stack: Flutter, Dart SDK ^3.12.0 (go_router 17, flutter_bloc 9, dio 5, get_it 9) | last commit: 2026-10-14 | source files: 247
ARCH: clean-arch feature-first, same core as corsa-customer (copied, then diverged) — lib/core/ (base_architecture, services, theme, router, widgets) + lib/features/<f>/{data(data_sources, models, repo), domain(use_cases for multi-service flows: go online/offline/restore, accept offer, perform delivery action), presentation(managers, screens, widgets)}
STATE: flutter_bloc Cubits — BaseSingleStateCubit.handleRequest (lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart, identical to customer) + BaseCubit (…/base_cubit/base_cubit.dart); app-level AvailabilityCubit, OffersCubit, ActiveDeliveryCubit, NotificationBadgeCubit, SplashCubit
DI: get_it (manual) — lib/core/services/di_container.dart + lib/core/services/features_di.dart (also wires LocationTrackingService.uploader to the availability repo so core never imports a feature)
ROUTING: go_router — lib/core/app_router/app_router.dart (+ auth_routes.dart, shell_routes.dart: StatefulShellRoute.indexedStack with 4 tabs home/orders/tracking/profile, route_builders.dart identical) — guards: redirect bounces cold start through splash; approval status (DriverStatus) routed by SplashCubit → /application-status; no guest mode; /dev/kitchen-sink only in kDebugMode — deep links: app_links → ActionHandler (driver variant: order/orders/url only)
NETWORK: dio — identical to customer: _CorsaInterceptor (queued 401 refresh+retry, GET retry x2, 426/503 override), TalkerDioLogger, MockApiInterceptor (driver copy adds handler-driven `mock_status` failures) | token refresh: y | retry: y (GET network errors) | error mapping: BaseRemoteDataSource.failureFromResponse (status → Failure with backend code + field errors) | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/base_architecture/data/repository/base_repo.dart
RESULT_TYPE: Either (dartz) — lib/core/utilities/failures/failure.dart (identical to customer)
STORAGE: shared_preferences + flutter_secure_storage — lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart (identical); GPS queue persisted as JSON in prefs
L10N: easy_localization — en, ar; prefs start locale, fallback en; assets/translations/{en,ar}.json (~375 lines each) — hardcoded UI strings: few (Android foreground-service notification text, channel names, kitchen sink which is debug-only)
RTL: Directional=15 vs LeftRight=15 (10 in custom_curved_navigation_bar.dart which mirrors itself; splash text left/right symmetric)
THEME: lib/core/theme/light_theme/light_theme.dart (identical to customer) — dark mode n | component themes in ThemeData y | AppColors (lib/core/utilities/constants/colors.dart) | TextThemeLight (light_widget_themes/text_theme.dart) | Inter (en) / Cairo (ar)
RESPONSIVE: flutter_screenutil with computed 375×812 design size clamped 0.85–1.15 (lib/core/utilities/screen_util_config.dart) + context.windowClass (lib/core/extensions/context_extensions.dart) — breakpoints: 600 / 840 width; phones portrait-locked in main.dart via physical shortestSide < 600
TEXT_SCALING: MediaQuery.withClampedTextScaling 0.85–1.5 in MaterialApp.builder (AppTextScale, lib/core/utilities/constants/app_text_scale.dart); slot clamp 1.2; AdaptiveRow stacks above 1.3
ENV/FLAVORS: --dart-define-from-file=env/<dev|staging|prod>.json (git-ignored, *.example.json committed) → AppEnv in lib/core/utilities/constants/keys/api_keys.dart; USE_MOCKS defaults on without BASE_URL; no native flavors
LOGGING: talker_flutter + TalkerDioLogger + TalkerRouteObserver + AppBlocObserver; 3 debugPrint
ANALYTICS/CRASH: firebase_crashlytics (release only, same wiring as customer); no analytics
PUSH: fcm + flutter_local_notifications — lib/core/services/notification_service.dart (adds versioned `offers_v1` channel, Importance.max, custom raw sound + iOS .caf, channelForType()) + lib/core/services/offer_alert_service.dart (audioplayers sound + haptic in foreground, 2 s de-dupe)
PAYMENTS/IAP: none
PERMISSIONS: geolocator flow (LocationService) with a rationale sheet before the OS prompt and open-settings dialog (lib/features/availability/presentation/widgets/location_rationale_sheet.dart); permission_handler for camera/notifications; Android FOREGROUND_SERVICE_LOCATION + POST_NOTIFICATIONS, iOS UIBackgroundModes location; while-in-use only, no background permission
DEEP_LINKS: app_links — lib/core/services/deep_link_service.dart (identical) → lib/core/services/action_handler.dart (driver variant)
MEDIA/FILES: image_picker + flutter_image_compress (MediaService, proof-of-delivery photo), cached_network_image, flutter_svg, lottie, url_launcher (adds navigate(): Waze → Google Maps → Apple Maps → web), audioplayers; no share_plus
TESTS: 16 test files (~85 cases) — LocationTrackingService queue/flush, availability use cases, active delivery + orders cubits, orders repo, failure mapping, mock API/fixtures, enums, text-scale matrix, splash goldens, system gate, en/ar smoke
LINTS: flutter_lints, 0 extra rules (analysis_options.yaml identical to customer)
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/services/location_tracking_service.dart — online GPS tracking: Bootstrap-driven distance filter + heartbeat, persisted queue, batches ≤50, exponential backoff, drop >10 min, Android foreground service / iOS background updates on while-in-use, injectable LocationBatchUploader — quality 4 — coupling: low (TrackingConfigModel, prefs keys; English notification text)
- lib/core/services/api_service.dart — identical to customer (see corsa-customer) — quality 5 — coupling: low
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart — identical to customer — quality 5 — coupling: low
- lib/core/utilities/failures/failure.dart — identical — quality 5 — coupling: none
- lib/core/services/mock/mock_api_interceptor.dart — customer version + handler-driven failures via `mock_status` (better copy) — quality 5 — coupling: low
- lib/core/services/notification_service.dart — customer version + versioned offers channel with custom sound + channelForType() (better copy) — quality 4 — coupling: medium (SharedRepository, ActionHandler)
- lib/core/services/offer_alert_service.dart — foreground alert sound + haptic, ambient audio category respects iOS silent switch, de-dupe — quality 4 — coupling: none
- lib/core/services/launcher_service.dart — customer version + navigate(lat, lng) fallback chain (better copy) — quality 4 — coupling: none
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_cubit.dart — identical — quality 4 — coupling: low
- lib/core/utilities/screen_util_config.dart + lib/core/utilities/constants/app_text_scale.dart + lib/core/extensions/context_extensions.dart — identical — quality 5 — coupling: none
- lib/core/services/connectivity_service.dart + lib/core/app_cubit/connectivity_cubit.dart + lib/core/utilities/widgets/no_internet/no_internet_gate.dart — identical — quality 4 — coupling: none
- lib/core/services/socket_service.dart — identical; Pusher/Reverb client — quality 3 — coupling: low — subscribe-before-connect bug bites harder here
- lib/core/app_router/app_router.dart — debug-only kitchen sink route (better copy) — quality 4 — coupling: high (feature screens)
- lib/core/utilities/converters/color_parser.dart — defensive #RRGGBB/#AARRGGBB → Color? — quality 4 — coupling: none
- lib/core/services/map_service.dart — identical (runtime SVG markers, polyline decode, bounds) — quality 4 — coupling: low
GENERIC_WIDGETS (every reusable widget):
- Shared with customer, byte-identical (see corsa-customer for params): buttons/app_default_button.dart, buttons/app_icon_button.dart, text_form_fields/* (app_text_form_field, password, email, phone, otp), app_search_field.dart, show_app_bottom_sheet.dart, shared/widgets/app_image.dart, app_svg_icon.dart, toasts/animated_custom_toast.dart, no_internet/*, app_result_view.dart, app_main_card.dart, custom_chip.dart, adaptive_shell.dart, custom_curved_navigation_bar.dart, app_divider.dart, section_header.dart, timeline_stepper.dart, image_picker_tile.dart, language_option_card.dart, simple_html_view.dart, cms_blocks_view.dart, shared/screens/image_viewer_screen.dart, shared/screens/html_screen.dart, price_text.dart (all under lib/core/utilities/widgets/) — quality 3-5 — generic? y
- lib/core/utilities/widgets/adaptive_row.dart — row→column, unwraps Flexible/Expanded in column mode — children, spacing, forceColumn, minRowWidth — quality 5 — generic? y (better than customer)
- lib/core/utilities/widgets/app_switch.dart — switch with isLoading spinner, keeps size — value, onChanged, isLoading, semanticLabel — quality 4 — generic? y (better than customer)
- lib/core/utilities/widgets/app_tab_switcher.dart — tabs, pill style always scrolls — tabs, selectedIndex, onTabChanged, counts, style — quality 4 — generic? y
- lib/core/utilities/widgets/base_fetching_widget.dart — GenericFetchWidget + BaseEmptyWidget(dense) for in-page empty sections — quality 5 — generic? y (better than customer)
- lib/core/utilities/widgets/app_avatar.dart — AppAvatar + StoreLogo(initials, backgroundColor fallback) — quality 4 — generic? y (better than customer)
- lib/core/utilities/widgets/default_screen.dart — base scaffold, lacks customer's safeAreaTop and uses bottomPadding — quality 4 — generic? y (customer copy is better)
- lib/core/utilities/widgets/skeletons/app_skeletons.dart — lacks TileSkeleton and SkeletonGrid.item — quality 4 — generic? y (customer copy is better)
- lib/core/utilities/widgets/shared/screens/paginated_list_view.dart — same behaviour as customer — quality 5 — generic? y
- lib/core/utilities/widgets/map_preview.dart — GoogleMap card preview (lite mode on Android) or interactive map with pickup/drop-off pins + server polyline — pickup, dropoff, encodedPolyline, height, width, radius, onTap, interactive — quality 4 — generic? y
- lib/core/utilities/widgets/online_toggle.dart — online/offline pill with loading — isOnline, onlineLabel, offlineLabel, onChanged, isLoading — quality 4 — generic? y
- lib/core/utilities/widgets/route_mini_timeline.dart — pickup → drop-off two-stop rail — pickupText, dropoffText, pickup/dropoffTimeText, dense — quality 4 — generic? y
- lib/core/utilities/widgets/cards/driver_cards.dart — OverviewStatCard, EarningText, CurrentDeliveryCard, OfferTile, OutlinedCardAction, DriverOrderCard, StoreDetailsCard, CustomerDetailsCard, OrderItemTile, NotesCard (824 lines) — quality 3 — generic? n (OverviewStatCard/NotesCard reusable)
- lib/features/availability/presentation/widgets/location_rationale_sheet.dart — showLocationRationaleSheet / showOpenSettingsDialog — quality 4 — generic? y
- lib/features/orders/presentation/widgets/proof_sheets.dart — showProofPhotoSheet / showProofOtpSheet — quality 4 — generic? partly
- lib/features/orders/presentation/widgets/cancel_reason_sheet.dart, permission_banner.dart, offer_banner.dart — app-specific sheets/banners — quality 3-4 — generic? n
NOTABLE_IDEAS: LocationTrackingService with a typedef uploader injected from features_di so core stays feature-free, persisted point queue + batching + backoff + heartbeat for stationary drivers + foreground-service / iOS background config (lib/core/services/location_tracking_service.dart, lib/core/services/features_di.dart); GoOnlineUseCase starts tracking first and stops it again if the API refuses, so the app never streams location while the server thinks the driver is offline (lib/features/availability/domain/use_cases/availability_use_cases.dart); RestoreAvailabilityUseCase handles "OS killed the app while online" via a TRACKING_WAS_ONLINE flag; versioned Android notification channel id because a channel's sound can't change after creation (notification_service.dart); OfferAlertService uses the iOS ambient category so the silent switch is respected (offer_alert_service.dart); navigate() tries Waze → Google Maps → Apple Maps → web (launcher_service.dart); kitchen sink behind `if (kDebugMode)` in the route list (app_router.dart); mock handlers can fail a request by returning `mock_status` (mock_api_interceptor.dart); portrait lock on phones from the physical view size before any widget exists (main.dart); StatusBadgeModel implements CustomChip's StatusBadgeLike so core widgets don't import models; Emirates ID / passport validators (app_validator.dart); permission rationale shown once (LOCATION_RATIONALE_SHOWN); plus every shared-core idea listed in corsa-customer
SMELLS: core/ copied rather than shared: of 142 customer core files, 101 are byte-identical, 1 differs only by package name, 29 diverged, 11 are customer-only, and the driver adds 7. Fixes landed on one side only (DefaultScreen/skeletons better in customer; AdaptiveRow/AppSwitch/BaseEmptyWidget/notifications/mock/router better in driver); realtime is likely dead against a real backend: OffersCubit and ActiveDeliveryCubit call SocketService.on() when the session user changes (ApplicationStatusCubit in its constructor), before AvailabilityCubit._connectRealtime() (which only runs when going online), and on() returns Stream.empty() with no client while connect() wipes channels; OffersCubit's `_createdSub != null` guard then blocks re-subscribing (mocks never exercise sockets, so tests don't catch it; ActiveDelivery has 15 s polling, offers rely on push); application-status realtime never connects at all; same shared-core bugs as customer (AppInfoService.headers never sent, NotificationService.pendingAction never consumed, base-cubit failure not cleared, literal '\$runtimeType', raw exception text in UnknownFailure); LocationTrackingService rewrites the whole JSON queue into SharedPreferences on every fix and its flush assumes no age-pruning between read and write; hardcoded English foreground-service notification text and channel names; driver_cards.dart is an 824-line card god-file; README is still the Flutter boilerplate; 44 `// ignore:` lines; flutter_lints only; no dark theme. No deprecated APIs found.
```

---

This report covers what differs from **corsa-customer** (`docs/_analysis/corsa-customer.md`). Every
core file listed below as identical behaves as described there.

## 1. Architecture pattern

Same as corsa-customer: clean architecture, feature-first, Tebbr house style; data sources throw
`Failure`, repositories return `Either<Failure, T>`, use cases only for multi-service flows,
Cubits on `BaseSingleClassState`. The driver app uses use cases more than the customer app
does, because going online, restoring availability and performing delivery steps combine
location, tracking, the API and the session:

- `GoOnlineUseCase`: approved check → fresh GPS fix → `tracking.start(idle)` → `PATCH`
  availability → on failure `tracking.stop()`; on success `appCubit.setOnline()`.
- `GoOfflineUseCase`: the server refuses with 409 `has_active_delivery` while a delivery runs;
  tracking keeps going.
- `RestoreAvailabilityUseCase`: `GET /driver/me` says online but tracking isn't running →
  resume, or go offline when permission was lost.
- `AcceptOfferUseCase`, `PerformDeliveryActionUseCase` (fresh fix → upload proof photo → POST
  the server's `primary_action`; steps are never advanced locally).

Cubits never navigate or ask for permissions inside use cases; the AvailabilityCubit handles
permissions with the screen (rationale callback), and use cases return Failures.

## 2. Folder tree (`lib/`)

`lib/core/` has the same structure as corsa-customer (see that report), with these differences:

```
lib/core/
├── services/
│   ├── location_tracking_service.dart   (driver only) online GPS tracking + queued batch upload
│   ├── offer_alert_service.dart         (driver only) foreground sound + haptic for new offers
│   └── (no share_service.dart)
├── utilities/
│   ├── converters/color_parser.dart     (driver only) colorFromHex
│   ├── helpers/                         (absent: no guest gate, drivers are always signed in)
│   └── widgets/
│       ├── cards/driver_cards.dart      (driver only) replaces customer's product/catalog/promo cards
│       ├── map_preview.dart             (driver only)
│       ├── online_toggle.dart           (driver only)
│       ├── route_mini_timeline.dart     (driver only)
│       └── (no heart_toggle, price_summary_card, quantity_stepper, rating_stars, selectors)
```

```
lib/features/            9 features
├── auth            sign in, sign up (multi-step registration with RegistrationNavigator), email code, driver documents upload, application status, forgot/reset password, Google/Apple
├── availability    online/offline: remote data source (availability + location batches), models, repo, use cases, AvailabilityCubit, location rationale sheet
├── dev             kitchen sink (debug only)
├── help            help center, FAQ, CMS (no feedback screen)
├── home            driver home (overview grid, current delivery, new offers), header with OnlineToggle
├── notifications   list, badge, bell
├── orders          offers, orders list (tabs), order details, active delivery / tracking, proof sheets, cancel reasons, delivery done
├── profile         profile, edit profile, delete account
└── splash          splash animation, language, onboarding, SystemConfigGate, status-based destination
```

Representative feature fully expanded, `features/availability/`:

```
availability/
├── data/
│   ├── data_sources/availability_remote_data_source.dart   setAvailability(params), sendLocations(points, orderId)
│   ├── models/availability_models.dart                     AvailabilityModel (is_online, online_since, hours_online_today_text), params
│   └── repo/availability_repo.dart                          Either wrappers
├── domain/use_cases/availability_use_cases.dart            GoOnline / GoOffline / RestoreAvailability (+ RestoreOutcome enum)
└── presentation/
    ├── managers/availability_cubit/ (availability_cubit.dart, availability_state.dart)   AvailabilityState{offline, goingOnline, online, goingOffline}, PermissionIssue{none, location, locationForever, locationService, notifications}
    └── widgets/location_rationale_sheet.dart                showLocationRationaleSheet, showOpenSettingsDialog
```

## 3. Infrastructure (only what differs from corsa-customer)

### State management
Same base cubits (byte-identical). App-level cubits provided at the root: `AppCubit`,
`ConnectivityCubit`, `SplashCubit`, `AvailabilityCubit`, `ActiveDeliveryCubit`, `OffersCubit`,
`NotificationBadgeCubit`. `AppCubit` holds a `DriverModel` instead of `UserModel` and adds
`status` (DriverStatus) and `setOnline()`. `AvailabilityCubit` and `OffersCubit` store and cancel
their `appCubit.stream` subscriptions (better than customer's CartCubit).

### DI
Same structure. `di_container.dart` registers `LocationTrackingService` and `OfferAlertService`
and drops `ShareService`. In `features_di.dart`, the tracking service's uploader is wired to the
repository:
```dart
di<LocationTrackingService>().uploader = (points, orderId) async {
  final result = await di<AvailabilityRepository>().sendLocations(
    points: points, orderId: orderId);
  return result.isRight();
};
```
56 lazy singletons, 15 factories.

### Routing
4 tabs (home, orders, tracking, profile). Auth routes add documents, application status and a
`/auth/sign-up/code` step. The splash decides the destination from `DriverStatus`
(pendingDocuments/pendingReview/rejected/suspended → application status; approved → home). The
kitchen sink is in the route list only `if (kDebugMode)`. No `requireAuth` because there is no
guest mode.

### Networking
`api_service.dart`, `base_remote_data_source.dart`, `base_repo.dart`, envelopes and failures are
byte-identical to customer. `ApiKeys` has a different per-app endpoint block (`/driver/*`,
availability, locations, offers, deliveries) and `appHeader = 'driver'`.
`mock_api_interceptor.dart` adds: a handler can return `{mock_status: 409, code, message}` to
reject a request (taken offer, active delivery).

### Local storage
Identical wrappers. Extra keys: `LOCATION_RATIONALE_SHOWN`, `QUEUED_LOCATION_POINTS`,
`TRACKING_WAS_ONLINE`.

### Localization / RTL
Same setup; en/ar ~375 lines each, 300 `.tr()` call sites. Hardcoded strings: the Android
foreground-service notification ("You're online …"), channel names, and the debug-only kitchen
sink (48 labels). RTL: 15 directional vs 15 left/right (mostly the self-mirroring curved nav bar).

### Theming / responsive / text scaling
Theme files, colors, text theme, `screen_util_config.dart`, `app_text_scale.dart` and
`context_extensions.dart` are byte-identical. `AppDimens` differs only in two product-card image
heights (customer trimmed them). `main.dart` locks phones to portrait before `runApp` using
`platformDispatcher.views.first.physicalSize / devicePixelRatio` (shortestSide < 600); the
customer app only documents this.

### Env / flavors, logging, crash
Identical mechanism (`env/*.json` via `--dart-define-from-file`, `AppEnv`, talker, release-only
Crashlytics).

### Push notifications
`notification_service.dart` adds a third channel `offers_v1` (Importance.max, raw resource
sound `new_offer`, iOS `new_offer.caf`). The id carries a version suffix because Android can't
change a channel's sound after it exists. `channelForType(type)` maps `new_order/offer` →
offers, `order*/pickup_reminder/delivery_completed` → orders, else general. `main.dart`
`_wirePushHooks()` sets `onForegroundMessage` to update the badge (`unread_count` or increment)
and silently reload the active delivery on `new_order` / `order_assigned`.
`OfferAlertService` plays `assets/sounds/new_offer.wav` with audioplayers (ambient category on
iOS so the silent switch is respected) plus `HapticFeedback.heavyImpact`, at most once per 2 s.
Same unconsumed `pendingAction` bug as customer.

### Permissions
Location: `AvailabilityCubit.goOnline()` checks access, shows the rationale sheet once (prefs
flag) via an `onNeedsRationale` callback, requests, and maps the result to `PermissionIssue`
(`locationForever` → settings dialog, `locationService` → location settings). Notification
permission is asked but never blocks going online. Manifest: fine location, foreground service
(location), post notifications; iOS: `UIBackgroundModes` location + remote-notification,
`LSApplicationQueriesSchemes` for waze/comgooglemaps. While-in-use permission only; no
`ACCESS_BACKGROUND_LOCATION`.

### Deep links
`DeepLinkService` is identical; the driver `ActionHandler` handles `order`, `orders` (with a tab
param), `url`, `none` and ignores customer-only action types, so a shared payload can't break it.

### Maps / location / realtime (driver focus)
- **LocationTrackingService** (`lib/core/services/location_tracking_service.dart`, 300 lines):
  `start(config, mode)`, `setMode(idle|active, orderId)`, `stop()` (flushes), `flush()`,
  `wasOnlineBeforeRestart`. Position stream with `AndroidSettings(foregroundNotificationConfig:
  …, enableWakeLock, setOngoing)` or `AppleSettings(allowBackgroundLocationUpdates,
  showBackgroundLocationIndicator, pauseLocationUpdatesAutomatically: false,
  automotiveNavigation)`. A heartbeat timer (idle/active interval from `Bootstrap.tracking`,
  defaults 30 s / 10 s, distance filter 20 m) re-records the last fix so a stationary driver
  still reports. Points go into a prefs-backed JSON queue (drops points older than 10 min) and
  are flushed in batches of 50 through the injected `uploader`; a failed batch stays queued with
  exponential backoff 5 s → 300 s. Active mode flushes on every fix. Has a dedicated test file.
  Weak spots: rewrites the whole queue in prefs on every fix; `flush()` drops
  `remaining.sublist(batch.length)`, which assumes no age-pruning happened in between; English
  notification text.
- **MapPreview** (`lib/core/utilities/widgets/map_preview.dart`): GoogleMap in lite mode on
  Android for cards, interactive on the tracking screen; markers and polyline from `MapService`.
- **LauncherService.navigate(lat, lng, label)**: Waze → `google.navigation:` → Apple Maps
  (iOS) → Google Maps web URL, via `canLaunchUrl` + `launchUrl`.
- **Realtime**: `SocketService` is byte-identical to customer. `AvailabilityCubit._connectRealtime()`
  connects (host/key from bootstrap) when the driver goes online or a restore resumes.
  `OffersCubit` (`drivers.<id>`: `offer.created` / `offer.removed`, merged into the list,
  alert played), `ActiveDeliveryCubit` (`order.assigned` / `order.updated` / `order.cancelled`,
  plus 15 s polling) subscribe when the session user appears, and `ApplicationStatusCubit`
  (`account.status_changed`) subscribes in its constructor. Both happen before `connect()`, which
  runs only when the driver goes online (so an unapproved driver never connects at all). With this `SocketService` those
  subscriptions get `Stream.empty()`, and `connect()` clears channels anyway, so realtime
  offers/status are likely never delivered against a real backend. The comment in
  AvailabilityCubit ("the feature cubits are already subscribed to it") shows the author assumed
  otherwise. Fix for the template: let `SocketService` keep a registry of desired
  `(channel, event)` bindings and re-bind them on every `establishedConnection`, returning a
  broadcast stream that outlives reconnects.

## 4. Services catalog

**Identical to corsa-customer (101 byte-identical core files)**: api_service.dart, app_info_service.dart,
bloc_observer.dart, connectivity_service.dart, deep_link_service.dart, double_parser.dart,
location_service.dart, map_service.dart, media_service.dart, secure_storage_manager.dart,
shared_preferences_manager.dart, social_auth_service.dart, socket_service.dart, system_status.dart,
toast_manager.dart, upload_service.dart, mock/mock_route_table.dart, mock/mock_settings.dart,
shared_api/* (3), all base_architecture/* (9), connectivity_cubit/state, route_builders.dart,
context/string/list extensions, fetch_data_status/http_method/toast_state enums, 12 of 14 core
models, all theme/* (10), utilities/constants (5 of 9), json_helpers.dart, failures/* (2),
phone_formatter.dart, screen_util_config.dart, 29 widget files. `core_exports.dart` differs only by
the package name.

**Diverged (29 core files)**, with the better side:

| File | Change in driver | Better copy |
|---|---|---|
| core/app_cubit/app_cubit.dart, app_state.dart | DriverModel, `status`, `setOnline()` | app-specific |
| core/app_router/app_router.dart | kitchen sink `if (kDebugMode)` | driver |
| core/app_router/app_routes_names.dart, auth_routes.dart, shell_routes.dart | driver routes/tabs | app-specific |
| core/enums/app_enums.dart | DriverStatus, TrackingMode, OfferRemovedReason, … | app-specific |
| core/models/bootstrap_model.dart | TrackingConfigModel has defaults (30 s / 10 s / 20 m) | driver |
| core/models/status_badge_model.dart | implements StatusBadgeLike | driver |
| core/services/action_handler.dart | driver actions only | app-specific |
| core/services/app_validator.dart | + isValidEmiratesId, isValidPassport | driver (region-specific) |
| core/services/di_container.dart, features_di.dart | driver registrations, uploader wiring | app-specific |
| core/services/launcher_service.dart | + navigate() | driver |
| core/services/mock/mock_api_interceptor.dart | + `mock_status` handler failures | driver |
| core/services/mock/mock_handlers.dart | driver fixtures state | app-specific |
| core/services/notification_service.dart | + offers channel, channelForType | driver |
| core/utilities/constants/app_dimens.dart | product card image heights | n/a |
| core/utilities/constants/app_images.dart, keys/api_keys.dart, keys/shared_preferences_keys.dart | per-app values | app-specific |
| core/utilities/widgets/adaptive_row.dart | unwraps Flexible in column mode | driver |
| core/utilities/widgets/app_avatar.dart | StoreLogo initials + colour fallback | driver |
| core/utilities/widgets/app_switch.dart | isLoading | driver |
| core/utilities/widgets/app_tab_switcher.dart | pill always scrolls | driver |
| core/utilities/widgets/base_fetching_widget.dart | BaseEmptyWidget.dense | driver |
| core/utilities/widgets/default_screen.dart | no safeAreaTop; bottomPadding vs bottomSafeArea | customer |
| core/utilities/widgets/skeletons/app_skeletons.dart | no TileSkeleton / SkeletonGrid.item | customer |
| core/utilities/widgets/shared/screens/paginated_list_view.dart | cosmetic | same |

**Driver-only core services**:

| File | Purpose | Public methods | Dependencies | Generic? |
|---|---|---|---|---|
| core/services/location_tracking_service.dart | online GPS tracking + queued batch upload | start(config, mode), setMode(mode, orderId), stop(), flush(), uploader, isRunning, mode, lastKnownPoint, wasOnlineBeforeRestart; TrackedPoint.fromPosition/fromJson/toJson | geolocator, SharedPreferencesManager, TrackingConfigModel | generic (courier/fleet apps) |
| core/services/offer_alert_service.dart | foreground alert sound + haptic | alert(), dispose() | audioplayers, HapticFeedback | generic |
| core/utilities/converters/color_parser.dart | hex → Color | colorFromHex(String?) | dart:ui | generic |

Feature use cases: `features/availability/domain/use_cases/availability_use_cases.dart`
(GoOnline, GoOffline, RestoreAvailability), `features/orders/domain/use_cases/orders_use_cases.dart`
(AcceptOffer, PerformDeliveryAction), `features/auth/domain/use_cases/auth_use_cases.dart`
(diverged from customer: driver session, registration, refresh driver).

## 5. Widgets catalog

Shared widgets are listed in corsa-customer; the byte-identical ones are named in the summary.
Driver-only or diverged:

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| core/utilities/widgets/map_preview.dart | map card / interactive route map | pickup, dropoff, encodedPolyline, height, width, radius, onTap, interactive | y |
| core/utilities/widgets/online_toggle.dart | online/offline pill | isOnline, onlineLabel, offlineLabel, onChanged, isLoading | y |
| core/utilities/widgets/route_mini_timeline.dart | two-stop route rail | pickupText, dropoffText, pickupTimeText, dropoffTimeText, dense | y |
| core/utilities/widgets/app_switch.dart | switch with loading | value, onChanged, isLoading, semanticLabel | y |
| core/utilities/widgets/adaptive_row.dart | row→column (flex-safe) | children, spacing, alignments, forceColumn, minRowWidth | y |
| core/utilities/widgets/base_fetching_widget.dart | BaseEmptyWidget(dense) | + dense | y |
| core/utilities/widgets/app_avatar.dart | StoreLogo(initials, backgroundColor) | image, size, onTap, initials, backgroundColor | y |
| core/utilities/widgets/cards/driver_cards.dart | OverviewStatCard(value, label, icon) | – | partly |
|  | EarningText(money, large) | – | n |
|  | CurrentDeliveryCard(orderNumber, pickupText, dropoffText, storeLogo/Initials/Color, pickupTimeText, pickup, dropoff, encodedPolyline, onTap) | – | n |
|  | OfferTile(orderNumber, detailsLabel, store*, distanceText, pickupTimeText, earning, countdownText, onDetails) | – | n |
|  | OutlinedCardAction(label, onTap) | – | y |
|  | DriverOrderCard(orderNumber, pickup/dropoffText, storeName, earning, times, timeLeftText, pickup, dropoff, encodedPolyline, onTap, primaryAction, secondaryAction) | – | n |
|  | StoreDetailsCard(name, logo, initials, avatarColor, tagsText, distanceText, phone, pickup/dropoffText, pickup, dropoff, encodedPolyline, onCall, onMapTap) | – | n |
|  | CustomerDetailsCard(name, avatar, phone, email, onCall) | – | partly |
|  | OrderItemTile(name, quantityLabel, subtitle, image, unitPrice) | – | partly |
|  | NotesCard(text, icon, tone) | – | y |
| features/availability/presentation/widgets/location_rationale_sheet.dart | showLocationRationaleSheet(context) → bool, showOpenSettingsDialog(context) | – | y |
| features/orders/presentation/widgets/proof_sheets.dart | showProofPhotoSheet → File?, showProofOtpSheet → String? | – | partly |
| features/orders/presentation/widgets/cancel_reason_sheet.dart | showCancelReasonSheet → CancelReasonResult | – | n |
| features/orders/presentation/widgets/permission_banner.dart | PermissionBanner + AppIconButtonClose | – | partly |
| features/orders/presentation/widgets/offer_banner.dart | in-app new-offer banner | – | n |
| features/home/presentation/widgets/driver_home_header.dart, overview_grid.dart | home header, stats grid | – | n |
| features/auth/presentation/widgets/registration_navigator.dart | multi-step registration stepper | – | partly |

## 6. Packages

Same as corsa-customer (see that report) except:
- **removed**: share_plus ^12.0.2
- **added**: audioplayers ^6.6.1 (offer alert)
- assets: `assets/sounds/`, `assets/mock/availability/`; no shop/catalog/stores/search/wishlist/cart/checkout/payment_methods/addresses mocks.

## 7. Quality notes

- **Null safety / language / deprecated APIs**: same as customer (Dart ^3.12, modern syntax, no
  deprecated APIs found).
- **Lints**: `analysis_options.yaml` identical to customer (flutter_lints, no extra rules); 44
  `// ignore:` lines.
- **Tests**: 16 test files (~85 cases), including `test/core/services/location_tracking_service_test.dart`,
  `test/features/availability/availability_use_cases_test.dart`, active delivery / driver orders
  cubits, orders repo, and the same shared-core tests (failure mapping, mock fixtures, enums,
  text-scale matrix, splash goldens, system gate). `test/widget_test.dart` is a real en/ar smoke
  test, not the counter template.
- **Docs**: `docs/` mirrors the customer docs (CONVENTIONS, FEATURES, PROGRESS, api/CONTRACT,
  design frames); the root `README.md` is still Flutter's boilerplate.
- **Feature files vs customer**: of the 61 feature files present in both apps (auth, dev, help,
  notifications, orders, profile, splash), 10 are byte-identical, 17 differ only by the package
  name, and 34 have diverged (profile 10, auth 9, splash 8, notifications 3, orders 2, help 1,
  dev 1).
- **Main risks**: the realtime subscription order (summary), core drift between the two copies,
  the prefs-backed GPS queue (fine at 50 points / 10 min, but it is a full JSON rewrite per fix),
  and the same shared-core bugs as customer.
