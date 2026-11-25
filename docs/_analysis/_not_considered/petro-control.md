# petro-control: analysis report

## Summary for comparison

```
PROJECT: petro-control | path: Chinaparts/New Projects/petro_control | stack: Flutter (CI pins 3.38.3), Dart SDK ^3.7.2 | last commit: 2026-05-04 | source files: 343
ARCH: clean-arch-lite feature-first, no domain layer: features/<f>/{data/{data_sources,models,repo},presentation/{managers,screens,widgets}}, with shared base classes in core/base_architecture (data source -> repo(Either) -> cubit)
STATE: flutter_bloc 9 (Cubits only). Two base classes: BaseCubit.handleRequest for sealed multi-class states (lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart, 12 cubits) and BaseSingleClassStateCubit.handleRequest for one state class + FetchDataStatusEnum + copyWith (.../base_single_class_state_bloc/base_single_class_state_bloc.dart, 20 cubits). hydrated_bloc storage is set up but nothing uses it
DI: get_it, manual, no injectable: lib/core/services/di_container.dart (services/data sources/repos are lazy singletons, cubits are factories; all 33 cubits provided at the root in main.dart)
ROUTING: go_router 16: lib/core/app_router/app_router.dart + app_routes_names.dart. Flat list of ~45 GoRoutes, args passed as `state.extra as X`. Guards: none (splash checks the token and does go(login|home)). Deep links: none. TalkerRouteObserver; notification taps push through the global appRouter
NETWORK: dio 5. Interceptors: TalkerDioLogger only (custom LoggingInterceptor is registered in DI but never attached) | token refresh: n | retry: n | error mapping: BaseRemoteDataSource.handleRequest maps DioExceptionType and HTTP 400/401/403/404/422/500 to typed Failures and parses Laravel `errors` (list or field map) into ErrorDetail; 401 is handled per screen (BlocListener -> go(login)) | files: lib/core/services/api_service.dart, lib/core/base_architecture/data/data_sources/base_remote_data_source.dart, lib/core/base_architecture/data/repository/base_repo.dart
RESULT_TYPE: Either (dartz). Failure implements Exception; data source throws it, BaseRepository.handleNetworkCall catches it: lib/core/utilities/failures/failure.dart (+ error_details_model.dart)
STORAGE: shared_preferences (singleton SharedPreferencesManager, dynamic setValue/getValue) + flutter_secure_storage (SecureStorageManager: token, saved password) + hydrated_bloc (set up, unused): lib/core/services/shared_preferences_manager.dart, lib/core/services/secure_storage_manager.dart
L10N: easy_localization 3: ar, en; default/start + fallback = ar; assets/translations/{ar,en}.json (nested keys, ~741 .tr() calls). Hardcoded UI strings: many (162 Arabic literal lines in 35 files, 94 Text('English') literals)
RTL: Directional=17 vs LeftRight=86
THEME: lib/core/theme/light_theme/light_theme.dart (+ light_widget_themes/*). Dark mode: n (dark_theme.dart is empty) | component themes in ThemeData: y (appBar, elevated/text/legacy button, input, dialog, snackBar, bottomNav, progress) | colors class: AppColors + AppGradients (lib/core/utilities/constants/colors.dart) | text styles class: TextThemeLight singleton (light_widget_themes/text_theme.dart) | fonts: Alexandria (UI) + Cairo (PDF), bundled
RESPONSIVE: flutter_screenutil (design size 393x852, minTextAdapt, splitScreenMode). Breakpoints: none (1 LayoutBuilder in the whole app; ~1,120 .w/.h/.r uses)
TEXT_SCALING: none (no textScaler clamp; TextTheme sizes are raw ints, only the base style uses .sp; 77 raw fontSize literals)
ENV/FLAVORS: hardcoded constants: lib/core/utilities/constants/keys/api_keys.dart (one {{BASE_URL}} + commented alternates, every endpoint is a full-URL constant). No flavors, no --dart-define, no dotenv. CI: .github/workflows/flutter.yml (signed AAB -> Play upload)
LOGGING: talker_flutter (global `talker` in di_container.dart) + talker_dio_logger + TalkerRouteObserver; also 32 print + 45 debugPrint; AppBlocObserver prints every change
ANALYTICS/CRASH: none
PUSH: FCM + flutter_local_notifications + flutter_foreground_task (alarm service). In use: lib/core/services/notification_service.dart. Dead duplicate: lib/core/services/notifications/*. Alarm: alarm_service.dart, alarm_task_handler.dart, alarm_manager.dart, silent_bypass_manager.dart
PAYMENTS/IAP: none
PERMISSIONS: permission_handler 12 + geolocator: lib/core/services/permisssions_helper.dart (location dialogs), lib/features/home/presentation/services/permissions_service.dart (multi-permission rationale sheet + settings fallback), lib/core/services/silent_bypass_manager.dart (Android DND access / iOS critical alerts)
DEEP_LINKS: none (no app_links, no URL intent filters; notification payload -> appRouter.push)
MEDIA/FILES: image_picker (+ video_compress), video_player, image_gallery_saver_plus, share_plus, screenshot, qr_flutter, pdf + printing, path_provider, google_maps_flutter + geolocator; cached_network_image is declared but never used (Image.network)
TESTS: 1. Default counter widget_test.dart; it does not match the app and would fail
LINTS: flutter_lints ^6.0.0, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- lib/core/base_architecture/data/data_sources/base_remote_data_source.dart: generic handleRequest<T>(path, method, parser), Dio/HTTP -> Failure mapping, Laravel errors parser (list or map) | quality 4 | coupling: low (looks up ApiService through global diService)
- lib/core/utilities/failures/failure.dart (+ error_details_model.dart): Failure hierarchy with code + field errors | quality 4 | coupling: none (CacheFailure drops its message, a bug)
- lib/features/home/presentation/services/permissions_service.dart: explain -> request -> permanently-denied -> settings -> recheck flow for several permissions at once | quality 4 | coupling: low (permission list hardcoded and private; easy to parameterize)
- lib/core/services/silent_bypass_manager.dart: opt-in manager for "sound even when silent" (Android DND policy / iOS critical alerts) with asked/skipped persistence + status stream | quality 4 | coupling: medium (Arabic dialog text hardcoded, FCM dependency)
- lib/core/services/alarm_service.dart + alarm_task_handler.dart: foreground service playing a looping alarm on STREAM_ALARM, configurable from the FCM background isolate | quality 4 | coupling: low (asset path + channel id)
- lib/core/services/url_manager.dart: tel / mailto / external URL / maps by coords or address | quality 4 | coupling: none
- lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart + base_single_class_state.dart: single-state cubit with status enum and overridable loading/failure hooks | quality 3 | coupling: none
- lib/core/base_architecture/data/repository/base_repo.dart: Either wrapper | quality 3 | coupling: none (catches only Failure; other exceptions escape)
- lib/core/services/api_service.dart: Dio wrapper with header management (token, Accept-Language, custom headers, null removes) | quality 3 | coupling: low (reads token from SecureStorageManager; headers are set asynchronously from the constructor)
- lib/core/services/app_validator.dart: tr()-based validators (email, phone, Saudi phone, password, confirm, IBAN mod-97, employee no., combinator) | quality 3 | coupling: low (easy_localization keys; isNumeric regex bug)
- lib/core/services/show_loading_dialog.dart: LoadingDialogService.show/hide; stores the dialog's own context and guards against double show | quality 3 | coupling: low (AppColors)
- lib/core/services/toast_manager.dart + lib/core/utilities/widgets/toasts/animated_custom_toast.dart: overlay toast + context.showToast extension | quality 3 | coupling: low (failure toast is teal, see smells)
- lib/core/services/secure_storage_manager.dart: thin flutter_secure_storage wrapper | quality 3 | coupling: none
- lib/core/services/shared_preferences_manager.dart: singleton prefs wrapper (init in main) | quality 3 | coupling: none (dynamic, untyped API)
- lib/core/services/image_picker_service.dart: single/multi image, video, multi-media picker with size-based video compression | quality 3 | coupling: high (Arabic SnackBars, needs BuildContext, talker)
GENERIC_WIDGETS (every reusable widget):
- lib/core/utilities/widgets/buttons/app_default_button.dart: primary button | text, onTap, isLoading (morphs to circle), enabled, svgIconPath, background/text/border/loading color, gradient, height/width/radius, margin/padding, child, blockMultipleClicks | quality 3 | generic? y (enabled/disabled text colors are swapped; tap lock cannot await a VoidCallback)
- lib/core/utilities/widgets/buttons/app_icon_button.dart: AppIconButton (square icon button built on AppDefaultButton) + AppBackButton (picks arrow by isAr) | child, onTap, height/width/radius, backgroundColor, isLoading | quality 3 | generic? y
- lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart: titled TextFormField | title, controller, hint, validator, externalError (server error wins), prefix/suffix + constraints, formatters, maxLines/maxLength, focusNode, onTapOutside unfocus | quality 4 | generic? y
- lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart: password field with visibility toggle | controller, isConfirmPassword, confirmPasswordValidator, title, hint, isLogin (ignored) | quality 3 | generic? y
- lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart: email field with icon + validator | controller, title, hint, readOnly (ignored), onChanged | quality 3 | generic? y
- lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart: read-only field that opens a bottom-sheet list of strings | title, hintText, controller, items, validator, onChanged | quality 3 | generic? y
- lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart: DynamicDropdownFormField<T> using showMenu anchored to the field, optional search | controller, options, displayText, onOptionSelected, widgetBuilder, showSearch, hintText | quality 3 | generic? y (search does not rebuild the open menu; always applies the isNotEmpty validator)
- lib/core/utilities/widgets/text_form_fields/date_picker_text_form_field.dart: DateTimeTextFormField + top-level pickDate/pickTime (+ month/year dialog) | controller, isDate, pickDay, readOnly, title, hint | quality 2 | generic? partly (hardcoded Arabic; month/year dropdowns never update, no StatefulBuilder)
- lib/core/utilities/widgets/default_screen.dart: base Scaffold with title row + back button + body padding | body, pageTitle/pageTitleWidget, appbar, hasAppBar/hasBackButton/hasBottomBorder/hasBottomMargin, onBackPressed, FAB, paddings, backgroundColor | quality 3 | generic? y (only 2 call sites)
- lib/core/utilities/widgets/custom_appbar.dart: PreferredSize AppBar with boxed back button + bottom divider | pageTitle, actions | quality 2 | generic? y (unused; arrow_back_ios not mirrored for RTL)
- lib/core/utilities/widgets/base_fetching_widget.dart: GenericFetchWidget<B,S,T> (status switch) + BaseLoadingWidget + BaseErrorWidget(retry) | successBuilder, loadingWidget, failureWidget, onRetry | quality 3 | generic? y (unused)
- lib/core/utilities/widgets/base_list_view_widget.dart: BaseListView<T> with empty state | items, itemBuilder, emptyWidget | quality 2 | generic? y (default empty text key is 'no_tasks'; unused)
- lib/core/utilities/widgets/failure_widget.dart: error message + retry link | errorMessage, onTapRetry | quality 2 | generic? n (prefix key is 'messages.failed_fetch_categories')
- lib/core/utilities/widgets/toasts/animated_custom_toast.dart: animated overlay toast (fade + slide) | message, state, duration, location | quality 3 | generic? y
- lib/core/utilities/widgets/toasts/custom_toast.dart: static toast | message, state, duration | quality 2 | generic? y (unused duplicate)
- lib/core/utilities/widgets/container_with_shadow.dart: card container | child, width/height, padding/margin, radius, backgroundColor, border, image, boxShadow, shadowBlurRadius, onTap | quality 3 | generic? y
- lib/core/utilities/widgets/app_divider.dart: themed Divider | height, thickness, color, indent, endIndent | quality 3 | generic? y
- lib/core/utilities/widgets/custom_chip.dart: pill chip | title, titleStyle, bg/border/txt color, radius, fontSize, padding, onSelect | quality 3 | generic? y
- lib/core/utilities/widgets/selection_chip_widget.dart: selectable chip | isSelected, title, onTap, selected/unselected color | quality 3 | generic? y
- lib/core/utilities/widgets/title_value_widget.dart: "label: value" row | title, value, valueStyle | quality 3 | generic? y
- lib/core/utilities/widgets/expandable_widget.dart: ExpandableContainer (animated height + rotating arrow) | title, description, expandedContent, expandedHeight | quality 2 | generic? y (fixed heights)
- lib/core/utilities/widgets/linear_progress_indicator.dart: LinearPercentIndicator (rounded, green at 100%) | percent, minHeight | quality 3 | generic? y
- lib/core/utilities/widgets/animated_indicator.dart: IndicatorWidget, animated page-dot | index, currentStep | quality 3 | generic? y
- lib/core/utilities/widgets/custom_radio_group_widget.dart: CustomRadioGroup<T> + CustomSizeRadio<T> (animated) | options, selectedValue, onChanged, prefixText, label / size, colors, duration | quality 2 | generic? y (AnimationController created in didChangeDependencies)
- lib/core/utilities/widgets/image_picker_bottom_sheet.dart: showImagePickerSheet (camera/gallery) | context, onFilePicked | quality 3 | generic? y
- lib/core/utilities/widgets/image_picker_widget.dart: SingleImagePickerWidget (placeholder or preview + remove) | title, imagePath, onPickImage, onRemoveImage, size, radius | quality 3 | generic? y
- lib/core/utilities/widgets/shared/widgets/image_Widget.dart: ImageViewerWidget (asset/file/network chosen by string prefix) + download/share/remove overlays with progress | image, width/height, radius/borderRadius, fit, border, margin, onTap, onTapRemove, hasDownloadBtn, hasShareBtn, stackedWidget | quality 3 | generic? y (Image.network uncached, no loading/error builder, English messages)
- lib/core/utilities/widgets/shared/widgets/video_widget.dart: VideoViewerWidget (asset/file/network) | video, size, radius, fit, autoPlay, loop, onTap, onTapRemove | quality 3 | generic? y
- lib/core/utilities/widgets/shared/screens/image_viewer.dart: full-screen image route | imagePath | quality 2 | generic? y (no zoom; Positioned right:)
- lib/core/utilities/widgets/shared/screens/video_viewer.dart: FullScreenVideoPlayer | video, autoPlay, loop | quality 3 | generic? y
- lib/core/utilities/widgets/shared/screens/select_location_screen.dart: Google Map center-pin picker + reverse geocode + manual lat,lng entry | none | quality 2 | generic? n (inline Maps key service, todo branches)
- lib/core/utilities/widgets/custom_qr_widget.dart: CustomQrWidget + QrCodeService (save/share QR through screenshot) | data, stationCode, size, colors, padding, hasDownloadBtn, hasShareBtn, shareText/subject | quality 3 | generic? mostly (example class left in the file)
- lib/core/utilities/widgets/question_answer_widget.dart: Q/A row | question, answer, highlight | quality 2 | generic? n (colors by matching "Yes"/Arabic yes)
- lib/core/utilities/widgets/user_selection_widget.dart: user dropdown bound to UsersCubit | title, hasAll, userController, onOptionSelected | quality 2 | generic? n
- lib/core/utilities/widgets/silent_bypass_disabled_widget.dart: SilentBypassDisabledBanner (stream-driven, rechecks on resume) | margin | quality 3 | generic? n (Arabic text, app feature)
NOTABLE_IDEAS: (1) Feature generators in the project root: create_feature.dart scaffolds data/presentation folders with BaseRemoteDataSource/BaseRepository subclasses; copy_feature.dart clones a whole feature with name replacements and patches app_router.dart, app_routes_names.dart, di_container.dart and api_keys.dart. Worth making a template tool/ CLI. (2) AppTextFormField.externalError shows a server-side error before the local validator; pairs with Failure.errors parsed from 422 by base_remote_data_source.dart (_parseErrorDetails handles list and map shapes). (3) Paginated cubit pattern (page counter + hasReachedMax from pagination.lastPage + forceLoading reset): lib/features/notices/presentation/managers/notices_cubit/notices_cubit.dart. (4) LoadingDialogService keeps the dialog's own context so hide() pops the right route: lib/core/services/show_loading_dialog.dart. (5) Permission rationale/settings flow with locationWhenInUse requested before locationAlways: lib/features/home/presentation/services/permissions_service.dart. (6) Critical-alarm stack: FCM data message -> flutter_foreground_task service playing looping audio with AndroidAudioUsage.alarm / AVAudioSessionCategory.playback (alarm_service.dart, alarm_task_handler.dart); versioned notification channels (_v2) that delete old IDs (notification_service.dart); SilentBypassManager explainer + stream + resume-refresh banner. (7) Notification taps navigate through the global GoRouter (no BuildContext); handles both getInitialMessage and getNotificationAppLaunchDetails with a delayed push. (8) Changing the locale also updates Dio's Accept-Language header (profile_screen.dart); MaterialApp keyed by locale. (9) AppIcons.svg chooses asset or network SVG and applies colorFilter: lib/core/utilities/constants/icons.dart. (10) String.imageType extension (asset/local/network) used by the image widget. (11) GitHub Actions workflow builds a signed AAB from repo secrets and uploads to Play: .github/workflows/flutter.yml. (12) Native Android geofencing over a MethodChannel (lib/geofence_service.dart + Kotlin GeofenceService) for attendance.
SMELLS: Equatable bug: all 12 sealed state families extend BaseState (props = []) and none override props, so two states of the same type with different payloads compare equal and emit drops the second. NotificationService/NotificationHandler call diService<TasksCubit>() / diService<FireAlarmsCubit>(), which are factories, so they refresh a new instance and not the one in the tree. Two notification stacks (notifications/ folder is dead). Dead infra: LoggingInterceptor never attached; GenericFetchWidget, BaseListView, CustomAppBar, CustomToast unused; DefaultScreen used 2x vs 43 raw Scaffolds; hydrated_bloc initialised but unused; empty files (dark_theme.dart, price_converter.dart, get_tasks_params.dart, settings data stubs). Unused deps: cached_network_image, animate_do, country_picker, flutter_html, pretty_qr_code, package_info_plus; pdf_service imports package:http, which pubspec does not declare. 33 global BlocProviders in main.dart; TextEditingControllers held in AuthCubit; "remember me" stores the plain password in secure storage. Brand change red->teal left semantic colors wrong: errorBorder and failure toast use AppColors.accentGreen. Copy-paste bugs: NoticeCubit.deleteNotice emits GetNotice* states; PermissionsHelper settings buttons swapped; AppValidator.isNumeric regex ends in a literal `\$` and returns an untranslated key; month/year picker never updates; addNotice/removeNotice mutate the state list in place; image picker sheet shows SnackBars on a popped context. Deprecated: WillPopScope (attendance_dialog.dart), withOpacity x57, ColorScheme background/onBackground. Hardcoded: 162 Arabic literal lines, 94 English Text literals, 'Failed to fetch ...' copied 17x, default Accept-Language 'ar', 317 Material Colors.* uses, 16 Color(0x..) outside AppColors. Pagination scroll listener copy-pasted in 9 views. print x32 + debugPrint x45, emoji BlocObserver logs in release. Relative imports like '../../../../../../../../../../../../core/exports/core_exports.dart'. Typos in file names (permisssions_helper, phone_handeler_service, image_Widget, confirmation_dailog, employee_indentification_pdf). Google Maps key hardcoded in Dart; Play service-account JSON + Firebase config committed to git.
```

---

## 1. Architecture pattern

**Pattern:** feature-first "clean architecture lite". Each feature has `data/` and `presentation/` but **no domain layer** (no entities, no use cases, no abstract repository interfaces). Models are hand-written `fromJson`/`toJson`/`toFormData` classes (no json_serializable, freezed or build_runner).

**Layer flow (same in every feature):**

1. `XRemoteDataSource extends BaseRemoteDataSource`. Each method calls `handleRequest(path: ApiKeys.X, method: HttpMethod.get, parser: (res) => Model.fromJson(res.data), data/queryParameters)`. Failures are **thrown**.
2. `XRepository extends BaseRepository`. Each method returns `handleNetworkCall(call: () => remote.x())` and so produces `Either<Failure, T>`. Auth repo side effects (saving the token, updating ApiService headers) also live here.
3. A cubit in one of two styles:
   - `BaseCubit<S extends BaseState>`: sealed multi-class states (`GetNoticeLoading/Success/Failure`, `CreateNotice...`). Used for "single entity / action" cubits (`NoticeCubit`, `AuthCubit`, ...).
   - `BaseSingleClassStateCubit<S extends BaseSingleClassState>`: one immutable state with `FetchDataStatusEnum status`, `Failure? failure`, `copyWith`. Used for list and paginated cubits (`NoticesCubit`, `TasksCubit`, `UsersCubit`, ...) and for `AppCubit`.
4. Screens use `BlocBuilder`/`BlocListener` on globally provided cubits (`context.read<X>()`); navigation goes through `context.push(AppRoutesNames.x, extra: model)`.

The usual feature pair is a plural list cubit (`notices_cubit`) plus a singular CRUD cubit (`notice_cubit`); the list screen listens to the CRUD cubit to refresh.

UI permission gating uses permission strings from the API: `context.read<AppCubit>().state.user!.permissions!.contains("notices.create")` (42 call sites, no helper).

## 2. Folder tree (`lib/`)

```
lib/
├── main.dart                       # bootstrap (prefs, easy_localization, native splash, hydrated storage, Firebase, FG-task port, FCM bg handler, DI, BlocObserver, system UI, maps renderer) + MyApp (ScreenUtilInit -> 33 BlocProviders -> MaterialApp.router)
├── firebase_options.dart           # FlutterFire config (secret file, exists, not opened)
├── geofence_service.dart           # GeofencingService singleton: MethodChannel 'com.example.app/geofencing' + events stream + pure-Dart distance check
├── core/
│   ├── app_cubit/                  # AppCubit/AppState (current user, network flag) on BaseSingleClassState
│   ├── app_router/                 # app_router.dart (GoRouter, ~45 routes), app_routes_names.dart (path constants)
│   ├── base_architecture/
│   │   ├── data/
│   │   │   ├── data_sources/       # base_remote_data_source.dart (handleRequest + error mapping)
│   │   │   ├── models/             # base_request_model/network_request_model.dart (NetworkRequestParams), base_response_model/base_success_response.dart (generic envelope, unused), base_success_model.dart, pagination_model.dart
│   │   │   └── repository/         # base_repo.dart (handleNetworkCall -> Either)
│   │   └── presentation/managers/
│   │       ├── base_cubit/         # base_cubit.dart, base_state.dart (BaseState/LoadingState/ErrorState)
│   │       └── base_single_class_state_bloc/  # base_single_class_state.dart, base_single_class_state_bloc.dart
│   ├── enums/                      # app_roles_enum, fetch_data_status_enum, http_method_enum, toast_state_enum (part of toast_manager)
│   ├── exports/core_exports.dart   # barrel: material, go_router, easy_localization, screenutil, AppColors, DefaultScreen, AppCubit
│   ├── extensions/                 # context_extensions (theme/textTheme/colorScheme/isAr), list_extensions (isNullOrEmpty)
│   ├── models/                     # geocoding_address_details, selection_model
│   ├── services/                   # ~28 service files (API, storage, notifications, alarm, media, validators, permissions, url...)
│   │   └── notifications/          # fcm_service, local_notification_service, notification_handler, notification_router, notifications_bootstrap (dead, superseded by services/notification_service.dart)
│   ├── theme/
│   │   ├── dark_theme/             # dark_theme.dart (EMPTY)
│   │   └── light_theme/            # light_theme.dart, my_light_themes_export.dart
│   │       └── light_widget_themes/ # app_bar, bottom_nav, btn_txt, dialog, elevated_btn, input_decoration, light_color_scheme, snack_bar, text_theme
│   └── utilities/
│       ├── constants/              # colors.dart (AppColors, AppGradients), icons.dart (AppIcons + svg()), images.dart, temp_images.dart, constant_lists.dart
│       │   └── keys/               # api_keys.dart (BASE_URL + endpoints), shared_preferences_keys.dart
│       ├── converters/             # price_converter.dart (EMPTY)
│       ├── failures/               # failure.dart, error_details_model.dart
│       ├── formatters/             # date_formatter.dart
│       └── widgets/                # reusable widgets (see catalog)
│           ├── buttons/            # app_default_button, app_icon_button (+AppBackButton)
│           ├── shared/screens/     # image_viewer, video_viewer, select_location_screen
│           ├── shared/widgets/     # image_Widget (ImageViewerWidget), video_widget
│           ├── text_form_fields/   # app_text_form_field, password, email, dropdown, dynamic_drop_down, date_picker
│           └── toasts/             # animated_custom_toast, custom_toast
└── features/                       # 13 features
    ├── alerts/ auth/ client_reviews/ evaluations/ fire_alarm/ home/ maintenance/
    ├── notices/ quality_inspections/ settings/ splash/ stations/ users/
    └── (home/ also has presentation/services/: check_geofence.dart, permissions_service.dart)
```

Representative feature, fully expanded (`features/notices/`, 15 files):

```
notices/
├── data/
│   ├── data_sources/notices_remote_data_source.dart   # getNotices(page,status,createdBy,q), create/get/delete/update (multipart), changeNoticeStatus
│   ├── models/
│   │   ├── notice_model.dart                          # fields + fromJson + toFormData (images[] via MultipartFile)
│   │   ├── notice_status_enum.dart                    # enum with value/label (tr)
│   │   ├── notices_response_model.dart                # list + Pagination; NoticeDetailsResponseModel
│   │   └── requests/                                  # (empty)
│   └── repo/notices_repo.dart                         # NoticesRepository extends BaseRepository
└── presentation/
    ├── managers/
    │   ├── notice_cubit/{notice_cubit.dart, notice_state.dart}     # BaseCubit + sealed states (CRUD)
    │   └── notices_cubit/{notices_cubit.dart, notices_state.dart}  # BaseSingleClassStateCubit + pagination + filters
    ├── screens/{notices_screen.dart, add_notice_screen.dart, notice_details_screen.dart}
    └── widgets/{notices_view.dart (infinite scroll list), notice_card.dart, submit_notice_bottom_sheet.dart}
```

Feature sizes (files/lines): home 38/5410, evaluations 25/3980, stations 25/3370, auth 15/3358, alerts 20/2456, maintenance 19/2275, users 19/2206, settings 6/2173 (large screens: ID card, PDF), quality_inspections 15/1701, notices 15/1537, fire_alarm 9/1202, splash 8/1182, client_reviews 12/1114 (cloned from evaluations by copy_feature.dart).

## 3. Infrastructure

### State management
- `flutter_bloc ^9.1.1`, Cubits only (no Bloc events; `_initBlocs()` in DI is empty).
- **BaseCubit.handleRequest** (`lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart`): emits `loadingState` (optional), awaits `Either`, then calls `onSuccess` or `onError`; catches anything else as `UnknownFailure` with the stack trace in the message. Logs with talker and print.
- **BaseSingleClassStateCubit.handleRequest** (`.../base_single_class_state_bloc/base_single_class_state_bloc.dart`): by default emits `copyWith(status: loading)` and on failure `copyWith(status: failure, failure: f)`, with `onNotDefaultLoading` / `onNotDefaultFailure` hooks; success always goes through `onNotDefaultSuccess`. It relies on `copyWith(...) as State`.
- **Bug:** `BaseState` is Equatable with `props => []`. None of the 12 sealed state families override `props`, so `GetNoticeSuccess(a) == GetNoticeSuccess(b)` and `emit` drops repeated same-type states with new data. The single-class states do override props correctly.
- `copyWith(failure: null)` cannot clear a failure (uses `??`).
- `AppBlocObserver` (`lib/core/services/bloc_observer.dart`) prints every create/change/transition/error/close with emoji. It is not gated by kDebugMode.
- `hydrated_bloc` storage is built in `main.dart`, but no cubit extends HydratedCubit.

### DI
- `get_it ^8.0.3`, manual registration in `lib/core/services/di_container.dart` (343 lines). Global `diService = GetIt.instance` and global `talker = Talker()` live in the same file.
- Externals (prefs, secure storage, Dio, LoggingInterceptor), ApiService, data sources and repos are lazy singletons; all cubits are `registerFactory`.
- `diContainerSetup()` is `async` but not awaited (the bodies are synchronous, so it works).
- Data sources resolve `diService<ApiService>()` inside `BaseRemoteDataSource` (service locator, not constructor-injected), which makes them hard to test.
- All 33 cubits are created in one root `MultiBlocProvider` (main.dart). Code outside the tree (notification handlers) calls `diService<TasksCubit>()`, which creates a **new** factory instance, so those refreshes never reach the UI.

### Routing
- `go_router ^16.2.1`; `lib/core/app_router/app_router.dart` is a top-level `final GoRouter appRouter` with `observers: [TalkerRouteObserver(talker)]`.
- Flat routes, snake_case paths in `AppRoutesNames`. Arguments go through `state.extra as Model` (not deep-link safe). The splash route has a `CustomTransitionPage` fade and its own `BlocProvider(SplashCubit)`.
- No `redirect`/guards and no ShellRoute. Auth gating happens in the splash (token present → `go(home)` else `go(login)`) and in per-screen listeners that `go(login)` on `UnauthorizedFailure`.
- Three route names (`fireAlarmHistory`, `fireAlarmStatics`, ...) have no GoRoute.

### Networking
- `dio ^5.7.0`. `lib/core/services/api_service.dart`: `ApiServiceBase` interface with get/post/put/patch/delete taking `NetworkRequestParams` (uri, data, query, options, cancelToken, progress callbacks), plus `updateHeaders({token, customHeaders})` (a null value removes a header).
- Timeouts are 30 s. Default headers: JSON + `Accept-Language: ar`. Bearer token read from secure storage when headers are built.
- `_initializeDio()` is an async call from the constructor, so the first requests can race the header setup. The splash and login screens call `updateHeaders` again explicitly.
- Interceptors: `TalkerDioLogger(printRequestHeaders: true)`, which logs the Authorization header. `LoggingInterceptor` (`lib/core/services/logging_interceptors.dart`) is registered in DI but never added.
- No token refresh, no retry, no connectivity check (`hasNetworkConnection` in AppState is never updated).
- **Error mapping** (`base_remote_data_source.dart`): connection/send/receive timeout → `TimeoutFailure`; connectionError → `NetworkFailure`; response → status switch (400 BadRequest+errors, 401, 403, 404, 422 Validation+errors, 500, default Server with code); other → `UnknownFailure`. `_parseErrorDetails` accepts `errors` as a list of strings (field `general`) or a `{field: [msgs]}` map.
- Endpoints are full-URL constants in `api_keys.dart` (`"$BASE_URL/notices"`). Dio's baseUrl is therefore redundant.
- A few services build their own `Dio()` (image downloader, image share, Google geocoding) and bypass the logger.

### Local storage
- `SharedPreferencesManager` (`lib/core/services/shared_preferences_manager.dart`): singleton, `init()` in main, `setValue(key, dynamic)` dispatches by type, `getValue` returns dynamic, plus remove/clear.
- `SecureStorageManager` (`lib/core/services/secure_storage_manager.dart`): write/read/delete/clearAll/containsKey (default options; the try/rethrow wrappers add nothing).
- Keys live in `lib/core/utilities/constants/keys/shared_preferences_keys.dart`; it also holds the secure-storage TOKEN key.
- `AuthLocalDataSource` stores the token and the **user password** in secure storage, and email plus a "deleted emails" list in prefs. `SilentBypassManager` and `check_geofence.dart` call `SharedPreferences.getInstance()` directly and bypass the wrapper.

### Localization and RTL
- `easy_localization ^3.0.7` with `intl ^0.20.2`. `supportedLocales: [ar, en]`, `startLocale: ar`, `fallbackLocale: ar`, path `assets/translations` (ar.json 34 KB, en.json 27 KB, nested namespaces: buttons, auth, validation, messages, alerts, notices, stations, evaluations, screens.*, permissions...). No code-generated keys.
- `MaterialApp.router` is keyed by `ValueKey(context.locale.toString())` and wraps the child in a manual `Directionality` (rtl when ar). The manual Directionality is redundant because the locale already drives direction.
- Locale switching (`profile_screen.dart`) calls `context.setLocale` (twice) and also updates the Dio `Accept-Language` header. `get_and_set_device_locale.dart` can match the device locale (unused at boot).
- Hardcoded strings: many. Arabic literals in dialogs (SilentBypassManager, NotificationService DND dialog, date picker "cancel/save"), SnackBars in ImagePickerService, PDF labels and notification fallbacks, plus English literals ("Retry", "Failed to fetch tasks", "Permission Required", "Image downloaded successfully!").
- RTL: 17 Directional usages vs 86 left/right usages. Examples: `EdgeInsets.only(right:, left:)` in main_home_section, `Positioned(right: 20)` in image_viewer, `EdgeInsets.fromLTRB` in DefaultScreen's app-bar padding, `Alignment.centerLeft` in QuestionAnswerWidget. The `isAr` extension handles back-arrow mirroring in a few places (AppBackButton). `SilentBypassManager` forces `TextDirection.rtl` on its dialogs.

### Theming
- `lib/core/theme/light_theme/light_theme.dart`: `ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(AppColors.primary, background/onBackground deprecated), appBarTheme, bottomNavigationBarTheme, textTheme, buttonTheme, elevatedButtonTheme, textButtonTheme, snackBarTheme, dialogTheme, inputDecorationTheme, progressIndicatorTheme)`. Each component theme sits in its own file under `light_widget_themes/` and is re-exported by `my_light_themes_export.dart`.
- Component themes use ScreenUtil units (`343.w`, `52.h`, `8.r`) in top-level `final`s, evaluated on first access inside ScreenUtilInit's builder and never recomputed.
- Dark mode: none (`dark_theme.dart` is a 0-byte file and `theme:` only is set).
- `AppColors` (`lib/core/utilities/constants/colors.dart`): documented brand/neutral/status/button-state colors, a secondary0-10 and neutral100-600 ramp, gradients; `AppGradients` with background/card/accent. After the rebrand `primary = accentGreen` (teal), but error roles (input errorBorder, failure toast) still use it. Comments mention the old red identity.
- Text styles: `TextThemeLight.instance.txtTheme` (singleton). Base style is Alexandria, color secondary6, `height: 1`, 16.sp. The M3 slots override it with raw int sizes (57/45/36/32/26/20/22/18/16/16/14/12/14/12/10), so only the base is responsive. Widgets read the styles through `context.textTheme` (extension).
- Fonts: Alexandria 100-900 and Cairo 100-900 bundled in pubspec. The Cairo 100 entry points at the ExtraLight file. Cairo is used for the Arabic PDF.

### Responsive helpers
- `flutter_screenutil ^5.9.3`, `ScreenUtilInit(designSize: Size(393, 852), minTextAdapt: true, splitScreenMode: true)` in `MyApp`. Used everywhere (~1,120 `.w/.h/.r`, 148 `.sp`).
- No breakpoints, no tablet layouts, no custom helper.

### Text scaling
- None. No `MediaQuery.textScaler` clamp or `TextScaler` usage anywhere.

### Env / flavors
- Hardcoded `ApiKeys.BASE_URL` (`{{BASE_URL}}`) with commented alternates, plus `BASE_IMAGE_URL` and leftover app/company name constants from another project.
- No flavors (no `productFlavors` in `android/app/build.gradle.kts`), no `--dart-define`, no dotenv.
- `.github/workflows/flutter.yml`: on push to main, sets up Flutter 3.38.3 and Java 17, decodes keystore/key.properties/service-account from GitHub secrets, builds the AAB and uploads it to Google Play (tests are commented out).

### Logging
- `talker_flutter ^5.0.0` (global `talker` in di_container.dart; ~38 call sites), `talker_dio_logger`, `TalkerRouteObserver`. No TalkerScreen and no release gating.
- Also 32 `print` and 45 `debugPrint` calls, and the emoji `AppBlocObserver`.

### Analytics / crash reporting
- None. firebase_core is used for FCM; `cloud_firestore ^6.1.3` is used only by `lib/features/auth/data/repositories/delete_account_service.dart`, which keeps a Firestore collection of "deleted" emails to block login.

### Push notifications
- **In use:** `lib/core/services/notification_service.dart` (static class, ~490 lines, well commented). Main parts:
  - `init(BuildContext)`: called from the splash. Requests permission, initialises local notifications, configures FCM, handles a closed-app local-tap launch.
  - `initializeForBackground()`: for the background isolate.
  - Versioned Android channels `fire_alarm_channel_v2` / `custom_channel_id_v2` with `AudioAttributesUsage.alarm`; the old v1 IDs are deleted.
  - `setForegroundNotificationPresentationOptions(false...)` and a manual foreground display.
  - `start_alarm` / `stop_alarm` data types drive `AlarmService`; `task_creation`/`task_reminder` refresh tasks.
  - Tap → `appRouter.push(stationDetails | fireAlarm)`.
  - iOS critical alerts (`InterruptionLevel.critical`).
  - FCM token is only debug-printed; registration happens in AuthCubit.login (`registerFCM` when the token is not yet in the user's `fcmTokens`).
- **Background handler:** top-level `@pragma('vm:entry-point')` in `main.dart`; it re-initialises Firebase and notifications and starts/stops `AlarmService`.
- **Alarm audio:** `alarm_service.dart` (FlutterForegroundTask init/start/stop), `alarm_task_handler.dart` (TaskHandler looping `assets/sounds/fire_alarm.mp3` with an alarm audio session), `alarm_manager.dart` (in-isolate just_audio singleton; its only callers are in the dead `notifications/` stack).
- **Dead duplicate:** `lib/core/services/notifications/` (NotificationBootstrap → LocalNotificationService + FCMService + NotificationHandler + NotificationRouter). It is imported by the splash but never invoked. It is a cleaner split (router injected, handler separated) and is the better shape for a template.
- Android native side: `AlarmActivity.kt` (full-screen alarm), geofence service/receivers, boot receiver.

### IAP / payments
- None.

### Permissions
- `permission_handler ^12.0.1`, `geolocator ^14.0.2`, `local_auth ^2.3.0` (BiometricService, uses the old `AuthenticationOptions` API).
- `lib/core/services/permisssions_helper.dart`: location request with denied/denied-forever dialogs (translated). The two "open settings" button actions are swapped.
- `lib/features/home/presentation/services/permissions_service.dart`: `ensureAttendancePermissions(context)` handles locationWhenInUse, locationAlways and notification with a rationale bottom sheet (i18n keys + icons), a permanently-denied dialog → app settings, and a re-check afterwards. It is the best permission UX in the project; it should be parameterised with a `List<PermissionItem>`.
- `lib/core/services/silent_bypass_manager.dart`: Android `Permission.accessNotificationPolicy` + `requestNotificationPolicyAccess()`, iOS `criticalAlert` through FCM; explainer dialog, asked/skipped flags, `statusStream`, `refresh()` on resume (used by `SilentBypassDisabledBanner`).
- `splash_screen.dart` has its own `requestLocationPermissions` (a third location-permission implementation).

### Deep links
- None. AndroidManifest only has share/geo intent queries; no URL schemes or associated domains in iOS.

## 4. Services catalog

| File | Purpose | Public API | Dependencies | Generic / app-specific |
|---|---|---|---|---|
| lib/core/services/api_service.dart | Dio HTTP client wrapper (`ApiServiceBase` + `ApiService`) | get/post/put/patch/delete(NetworkRequestParams), updateHeaders({token, customHeaders}) | dio, talker_dio_logger, SecureStorageManager | Generic |
| lib/core/base_architecture/data/data_sources/base_remote_data_source.dart | Request executor + response/error → Failure mapping | handleRequest<T>({path, method, parser, data, queryParameters}) | ApiService (via diService), Failure | Generic |
| lib/core/base_architecture/data/repository/base_repo.dart | Either wrapper | handleNetworkCall<T>({call}) | dartz | Generic |
| lib/core/base_architecture/presentation/managers/base_cubit/base_cubit.dart | Multi-state cubit base | handleRequest<T>({loadingState, call, onSuccess, onError, showLoading}) | flutter_bloc, dartz, talker | Generic |
| lib/core/base_architecture/presentation/managers/base_single_class_state_bloc/base_single_class_state_bloc.dart | Single-state cubit base | handleRequest<T>({call, onNotDefaultSuccess, onNotDefaultFailure, onNotDefaultLoading}) | flutter_bloc, dartz | Generic |
| lib/core/base_architecture/data/models/base_request_model/network_request_model.dart | Request params DTO | NetworkRequestParams(uri, data, queryParameters, options, cancelToken, onSend/ReceiveProgress) | dio | Generic |
| lib/core/base_architecture/data/models/base_response_model/base_success_response.dart | Generic `{status,message,data}` envelope | fromJson(json, fromJsonT), toJson | none | Generic (unused) |
| lib/core/base_architecture/data/models/pagination_model.dart | Laravel pagination meta | Pagination.fromJson/toJson | none | Generic |
| lib/core/utilities/failures/failure.dart | Failure hierarchy | BadRequest/Unauthorized/Forbidden/NotFound/Server/Network/Timeout/Cache/Validation/Unknown | error_details_model | Generic |
| lib/core/services/di_container.dart | get_it registrations + global talker | diContainerSetup() | every feature | App-specific |
| lib/core/services/shared_preferences_manager.dart | Prefs singleton | init, setValue, getValue, remove, clear | shared_preferences | Generic |
| lib/core/services/secure_storage_manager.dart | Secure storage wrapper | write, read, delete, clearAll, containsKey | flutter_secure_storage | Generic |
| lib/core/services/logging_interceptors.dart | Chunked debugPrint Dio interceptor | onRequest/onResponse/onError | dio | Generic (unused) |
| lib/core/services/bloc_observer.dart | Logs bloc lifecycle | AppBlocObserver | flutter_bloc | Generic |
| lib/core/services/app_validator.dart | Form validators (tr keys) | isNotEmpty, isValidEmail, isValidPhone, isValidSaudiPhone, isValidPassword(v, isLogin), confirmPassword, isNumeric, isValidEmployeeNumber, isNotEmptyImage, ibanValidator, customValidator | easy_localization | Generic (Saudi/employee bits app-specific) |
| lib/core/services/input_formatters.dart | TextInputFormatters + image-ext check | onlyAlphabets, onlyNumbers, alphanumeric, decimalNumber, noWhitespace, numberCounts(max), isSupportedImageFormat | flutter/services | Generic |
| lib/core/services/debounce.dart | Timer debounce | Debounce(milliseconds).run(cb), cancel | dart:async | Generic |
| lib/core/services/toast_manager.dart | Overlay toast + `context.showToast` | ToastManager.showToast({context, message, state, location, duration}) | AnimatedCustomToast | Generic |
| lib/core/services/show_loading_dialog.dart | Blocking loading dialog | LoadingDialogService.show({context, message, barrierDismissible}), hide() | AppColors, screenutil | Generic |
| lib/core/services/url_manager.dart | url_launcher helpers | UrlManagerService.makeCall, sendMail, openLink, openMapLocation, openMapByAddress | url_launcher | Generic |
| lib/core/services/biometric_service.dart | local_auth wrapper | isBiometricAvailable, getAvailableBiometrics, authenticate({reason}) | local_auth | Generic |
| lib/core/services/get_and_set_device_locale.dart | Match device language to supported locales | setAppLanguageToDeviceLanguage(ctx), getDeviceLocale() | easy_localization, dart:io | Generic |
| lib/core/services/language_flags_service.dart | Locale → flag emoji | LanguageService.getFlagEmoji(locale) | none | Generic |
| lib/core/services/image_picker_service.dart | Pick image(s)/video(s)/media with compression | pickImage, pickMultiImage, pickVideo, pickMultipleMedia, pickMultiVideo | image_picker, video_compress, talker | Generic logic, app-coupled UI (Arabic SnackBars) |
| lib/core/services/image_downloader_service.dart | Download URL → gallery with SDK-aware permission | downloadImage(url, {onProgress}) | dio, permission_handler, image_gallery_saver_plus, device_info_plus | Generic |
| lib/core/services/image_share_service.dart | Share local/remote image | shareImage(path, {text, subject, onProgress}) | dio, path_provider, share_plus | Generic |
| lib/core/services/pdf_service.dart | Arabic RTL alert report PDF | generateAndSaveAlerts({alert}) | pdf, http (undeclared), path_provider | App-specific (pattern reusable) |
| lib/core/services/permisssions_helper.dart | Location permission + dialogs | checkLocationPermission(ctx) | geolocator, permission_handler | Generic (button bug) |
| lib/core/services/google_maps_services.dart | Reverse geocoding via Google API | getAddressFromLatLng(lat, lng) | dio | Generic logic, **hardcoded API key** |
| lib/core/services/notification_service.dart | FCM + local notifications + alarm routing | init(ctx), initializeForBackground, showLocalNotification, showAlarmNotification, cancel/cancelAll, subscribe/unsubscribeFromTopic | firebase_messaging, flutter_local_notifications, permission_handler, appRouter, cubits | App-specific |
| lib/core/services/notifications/*.dart | Split notification stack (bootstrap, FCM, local, handler, router) | NotificationBootstrap.init(router), FCMService.init, LocalNotificationService.init/showAlarm, NotificationHandler.handle, NotificationRouter.navigate | same | App-specific, dead |
| lib/core/services/alarm_service.dart | Foreground-service alarm control | initCommunicationPort, configure, start({title, body}), stop | flutter_foreground_task | Generic-ish |
| lib/core/services/alarm_task_handler.dart | FG TaskHandler playing looping alarm | startAlarmCallback, AlarmTaskHandler | just_audio, audio_session | Generic-ish |
| lib/core/services/alarm_manager.dart | In-isolate alarm player singleton | startAlarm, stopAlarm, isPlaying | just_audio, audio_session | Generic-ish (only used by the dead stack) |
| lib/core/services/silent_bypass_manager.dart | DND / critical-alert opt-in | instance.init, requestPermission(ctx, {force}), refresh, wasSkipped, statusStream, isEnabled | permission_handler, firebase_messaging, flutter_local_notifications, shared_preferences | Generic idea, app-coupled text |
| lib/core/services/random_color.dart | Random color + role → color | getRandomColor, getRoleColor(user) | UserModel | Mixed |
| lib/core/services/phone_handeler_service.dart | Leading-zero helper | ensureStartsWithZero | none | Generic (trivial) |
| lib/core/utilities/formatters/date_formatter.dart | intl formatting | formatDateString, formatDate, isMorning | intl | Generic |
| lib/core/utilities/converters/price_converter.dart | (empty file) | none | none | none |
| lib/core/utilities/constants/icons.dart | Icon paths + svg() helper (asset vs network) | AppIcons.svg({assetName, width, height, color, fit}) | flutter_svg, ApiKeys | Generic helper |
| lib/core/utilities/constants/images.dart | Image paths + image() helper | AppImages.image(...) | none | App-specific paths |
| lib/core/extensions/context_extensions.dart | theme/textTheme/colorScheme/isAr | extension getters | material | Generic |
| lib/core/extensions/list_extensions.dart | isNullOrEmpty on List? | isNullOrEmpty() | none | Generic |
| lib/geofence_service.dart | Native geofencing bridge | instance.initialize, addGeofence, removeGeofence, isInsideGeofence, checkGeofenceStatusOnStart, onGeofenceEvent | MethodChannel, geolocator | App-specific (native Kotlin) |
| lib/features/home/presentation/services/permissions_service.dart | Multi-permission rationale flow | ensureAttendancePermissions(ctx) | permission_handler | Generic idea |
| lib/features/home/presentation/services/check_geofence.dart | Attendance check-in/out logic with geofence + dialogs | handleAttendanceCheck(...), getStoredManagerLocation, clearManagerLocation | geolocator, prefs, cubits | App-specific |
| lib/features/auth/data/repositories/delete_account_service.dart | "Deleted accounts" list in a Firestore collection | DeletedAccountsService.addDeletedEmail, emailExists | cloud_firestore | App-specific |

## 5. Widgets catalog

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| lib/core/utilities/widgets/buttons/app_default_button.dart | Primary button, loading morph, tap lock | text*, onTap, isLoading, enabled, blockMultipleClicks, svgIconPath, svgIconColor (unused), textStyle, backgroundColor, textColor, loadingColor, borderColor, gradient, child, margin, padding, height, width, radius | y |
| lib/core/utilities/widgets/buttons/app_icon_button.dart | AppIconButton + AppBackButton | child*, onTap, height, width, radius, backgroundColor, padding, margin, isLoading, loadingColor / onTap | y |
| lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart | Titled text field | controller*, title, hintText, onTap, onChanged, enabled, readOnly, obscureText, keyboardType, validator, inputFormatters, icon, prefixIcon, suffixIcon, titleStyle, textStyle, hintTextStyle, maxLength, maxLines, bottomMargin (unused), prefix/suffixIconConstraints, focusNode, textAlign, onSaved, onFieldSubmitted, onEditingComplete, externalError | y |
| lib/core/utilities/widgets/text_form_fields/password_text_form_field.dart | Password + eye toggle | controller*, isConfirmPassword, confirmPasswordValidator, title, hintText, isLogin, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/email_text_form_field.dart | Email field | controller*, title, hintText, readOnly, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/dropdown_text_form_field.dart | String list in bottom sheet | hintText*, controller*, items*, title, validator, onChanged | y |
| lib/core/utilities/widgets/text_form_fields/dynamic_drop_down_text_field.dart | Generic T dropdown via showMenu + search | controller*, options*, displayText*, title, onOptionSelected, hintText, showSearch, widgetBuilder | y |
| lib/core/utilities/widgets/text_form_fields/date_picker_text_form_field.dart | Date/time field + pickDate/pickTime/month-year | controller*, title, hintText, isDate, readOnly, pickDay | partly |
| lib/core/utilities/widgets/default_screen.dart | Base scaffold | body*, appbar, pageTitle, pageTitleWidget, hasAppBar, hasBottomMargin, hasBackButton, hasBottomBorder, onBackPressed, floatingActionButton(+Location), topMargin, appBarPadding, bodyPadding, backgroundColor | y |
| lib/core/utilities/widgets/custom_appbar.dart | PreferredSize app bar | pageTitle*, actions, preferredSize | y (unused) |
| lib/core/utilities/widgets/base_fetching_widget.dart | GenericFetchWidget<B,S,T>, BaseLoadingWidget, BaseErrorWidget | successBuilder*, loadingWidget, failureWidget, onRetry / message, onRetry | y (unused) |
| lib/core/utilities/widgets/base_list_view_widget.dart | List with empty state | items*, itemBuilder*, emptyWidget | y (unused) |
| lib/core/utilities/widgets/failure_widget.dart | Error + retry | errorMessage*, onTapRetry | n |
| lib/core/utilities/widgets/toasts/animated_custom_toast.dart | Overlay toast | message*, state*, duration*, location | y |
| lib/core/utilities/widgets/toasts/custom_toast.dart | Static toast | message*, state*, duration | y (unused) |
| lib/core/utilities/widgets/container_with_shadow.dart | Shadow card | child*, width, height, image, backgroundColor, border, margin, padding, radius, onTap, boxShadow, shadowBlurRadius | y |
| lib/core/utilities/widgets/app_divider.dart | Divider | height, thickness, color, indent, endIndent | y |
| lib/core/utilities/widgets/custom_chip.dart | Pill chip | title*, titleStyle, bgColor, borderColor, txtColor, radius, fontSize, padding, onSelect | y |
| lib/core/utilities/widgets/selection_chip_widget.dart | Selectable chip | isSelected*, title*, onTap*, unSelectedColor, selectedColor | y |
| lib/core/utilities/widgets/title_value_widget.dart | Label: value row | title*, value*, valueStyle | y |
| lib/core/utilities/widgets/expandable_widget.dart | Expandable card | title*, description, expandedContent, expandedHeight | y |
| lib/core/utilities/widgets/linear_progress_indicator.dart | Progress bar | percent*, minHeight | y |
| lib/core/utilities/widgets/animated_indicator.dart | Page dot | index*, currentStep* | y |
| lib/core/utilities/widgets/custom_radio_group_widget.dart | Radio group + animated radio | options*, selectedValue*, onChanged*, prefixText*, label* / value, groupValue, onChanged, size, activeColor, inactiveColor, animationDuration | y |
| lib/core/utilities/widgets/image_picker_bottom_sheet.dart | Camera/gallery sheet (function) | context*, onFilePicked* | y |
| lib/core/utilities/widgets/image_picker_widget.dart | Single image picker tile | imagePath*, onPickImage*, onRemoveImage*, title, width, height, radius | y |
| lib/core/utilities/widgets/shared/widgets/image_Widget.dart | Universal image + download/share/remove | image*, width, height, margin, onTap, onTapRemove, hasDownloadBtn, hasShareBtn, stackedWidget, radius, borderRadius, fit, color, border | y |
| lib/core/utilities/widgets/shared/widgets/video_widget.dart | Universal video tile | video*, width, height, margin, onTap, radius, borderRadius, fit, color, border, autoPlay, loop, onTapRemove | y |
| lib/core/utilities/widgets/shared/screens/image_viewer.dart | Full-screen image | imagePath* | y |
| lib/core/utilities/widgets/shared/screens/video_viewer.dart | Full-screen video | video*, autoPlay, loop | y |
| lib/core/utilities/widgets/shared/screens/select_location_screen.dart | Map location picker | none | n |
| lib/core/utilities/widgets/custom_qr_widget.dart | QR + save/share (+QrCodeService, QrCodeExample) | data*, stationCode, size, backgroundColor, foregroundColor, padding, hasDownloadBtn, hasShareBtn, shareText, shareSubject | mostly |
| lib/core/utilities/widgets/question_answer_widget.dart | Q/A row | question*, answer*, highlight | n |
| lib/core/utilities/widgets/user_selection_widget.dart | User picker (UsersCubit) | userController*, title, hasAll, onOptionSelected | n |
| lib/core/utilities/widgets/silent_bypass_disabled_widget.dart | DND-disabled banner | margin | n |
| lib/core/services/show_loading_dialog.dart | Loading dialog (service-style) | show({context, message, barrierDismissible}) / hide() | y |
| lib/features/home/presentation/widgets/confirmation_dailog.dart | showLogoutConfirmationDialog (feature-local function) | context, ... | n (logout-specific; could be generalized) |

Adoption: AppDefaultButton 60 call sites, AppTextFormField 52, showToast 49, LoadingDialogService 8, DefaultScreen 2; GenericFetchWidget, BaseListView and CustomAppBar have 0. Each list screen hand-rolls its own failure/loading/empty switch and infinite-scroll listener (9 copies).

## 6. Packages (`pubspec.yaml`)

- **State:** flutter_bloc ^9.1.1, hydrated_bloc ^10.1.1 (unused), equatable ^2.0.7
- **DI:** get_it ^8.0.3
- **Routing:** go_router ^16.2.1
- **Network:** dio ^5.7.0, talker_dio_logger ^5.0.0, dartz ^0.10.1 (Either); http (transitive, imported directly by pdf_service)
- **Storage:** shared_preferences ^2.3.3, flutter_secure_storage ^9.2.4, path_provider ^2.1.5
- **L10n:** easy_localization ^3.0.7, intl ^0.20.2, flutter_localizations (sdk)
- **UI:** flutter_screenutil ^5.9.3, flutter_svg ^2.0.16, skeletonizer ^2.1.0+1 (3 uses), flutter_animate ^4.5.2, animate_do ^4.2.0 (unused), flutter_html ^3.0.0 (unused), country_picker ^2.0.2 (unused), cupertino_icons ^1.0.8, flutter_native_splash ^2.4.3, flutter_launcher_icons ^0.14.4 (in dependencies, should be dev)
- **Firebase:** firebase_core ^4.1.0, firebase_messaging ^16.0.1, cloud_firestore ^6.1.3
- **Notifications / background:** flutter_local_notifications ^19.4.1, flutter_foreground_task ^9.2.2, just_audio ^0.10.0, audio_session ^0.2.3
- **Media:** image_picker ^1.2.1, video_player ^2.9.2, video_compress ^3.1.4, cached_network_image ^3.4.1 (unused), image_gallery_saver_plus ^4.0.1, screenshot ^3.0.0, share_plus ^12.0.2, qr_flutter ^4.1.0, pretty_qr_code ^3.5.0 (unused), pdf ^3.11.0, printing ^5.11.0
- **Location / maps:** google_maps_flutter ^2.13.1, geolocator ^14.0.2
- **Device / utils:** permission_handler ^12.0.1, local_auth ^2.3.0, device_info_plus ^12.3.0, package_info_plus ^8.3.0 (unused), url_launcher ^6.3.1, talker_flutter ^5.0.0
- **Dev:** flutter_test (sdk), flutter_lints ^6.0.0
- Versioning comment shows separate Android/iOS build numbers toggled by hand (`version: 1.0.1+18 # android`, `#version: 1.0.0+3 # ios`).

## 7. Quality notes

- **Null safety:** yes (Dart ^3.7.2). Heavy use of `!` on API models (`state.user!.permissions!.contains(...)`, `success.data!.user!`), so a single missing field will crash.
- **Lints:** `include: package:flutter_lints/flutter.yaml` with 0 extra rules; `avoid_print` is effectively ignored (32 prints). One `ignore_for_file`.
- **Tests:** a single default counter `test/widget_test.dart`. It references a "+" button and "0" text that do not exist, so it would fail. CI has tests commented out.
- **Tooling:** `create_feature.dart` and `copy_feature.dart` at the project root (feature scaffolding/cloning); `.github/workflows/flutter.yml` CI/CD.
- **Duplication:** two notification stacks; three location-permission implementations (PermissionsHelper, splash `requestLocationPermissions`, `permissions_service.dart`); pagination scroll logic and failure/retry UI copy-pasted across 9 list views ("Failed to fetch tasks" text even in notices); AlarmManager vs AlarmTaskHandler; CustomToast vs AnimatedCustomToast; image download/share logic duplicated inside `QrCodeService`.
- **Bugs found while reading:**
  - Equatable `BaseState` props: sealed-state cubits silently drop repeated same-type states.
  - Factory cubits resolved from notification handlers update orphan instances.
  - `AppDefaultButton` text colors are inverted (enabled → `buttonTextDisabled`).
  - `AppValidator.isNumeric` regex `^-?\d+(\.\d+)?\$` requires a literal `$`, so it always fails; it also returns an untranslated key.
  - `CacheFailure(message)` ignores the message.
  - `NoticeCubit.deleteNotice` emits `GetNotice*` states.
  - `PermissionsHelper` "open settings" vs "open location settings" are swapped.
  - Month/year picker dropdowns never repaint (no StatefulBuilder).
  - `CustomSizeRadio` creates its AnimationController in `didChangeDependencies` (leak/assert on second call).
  - `showImagePickerSheet` uses the sheet's context after `Navigator.pop` for SnackBars.
  - `NoticesCubit.addNotice/removeNotice` mutate the existing list, so Equatable sees no change.
  - The ApiService constructor fires async header init without awaiting.
  - `TalkerDioLogger(printRequestHeaders: true)` logs bearer tokens.
- **Deprecated APIs:** `WillPopScope` (lib/features/home/presentation/widgets/attendance_dialog.dart), `withOpacity` x57, `ColorScheme.fromSeed(background:, onBackground:)`, local_auth v2 `AuthenticationOptions`. No `textScaleFactor` or `MaterialStateProperty`.
- **Hardcoding:**
  - 317 Material `Colors.*` uses and 16 `Color(0x...)` outside AppColors (e.g. `AppBackButton` uses `Color(0xFFE2E2E2)`).
  - 77 raw `fontSize:` literals.
  - 162 Arabic and 94 English string literals in UI.
  - Default `Accept-Language: ar`.
  - Leftover constants from another app in `api_keys.dart` (app/company name).
- **Structure smells:** 33 root BlocProviders; controllers inside cubits; plain password persisted for "remember me"; 12-level relative imports; misspelled file names (`permisssions_helper.dart`, `phone_handeler_service.dart`, `image_Widget.dart`, `confirmation_dailog.dart`, `employee_indentification_pdf.dart`); empty files and empty directories (settings managers/models, several `models/requests/`).
- **Secrets hygiene (names only):**
  - Google Maps API key hardcoded in `lib/core/services/google_maps_services.dart`; Maps keys also in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`.
  - `android/app/playstore-key.json` (Play service-account JSON), `android/app/google-services.json` and `lib/firebase_options.dart` are tracked in git.
  - `android/key.properties` and `android/app/upload-keystore.jks` exist on disk but are git-ignored. `ios/Runner/GoogleService-Info.plist` exists.
