# acme-portal — analysis report

## Summary for comparison

```
PROJECT: acme-portal | path: ACME/portal | stack: Flutter WEB-only (dart:html everywhere), Dart SDK '>=3.3.4 <4.0.0' (Dockerfile builds with Flutter 3.29.2); app + 6 local path packages (no melos.yaml) | last commit: 2025-06-01 | source files: 939 (lib 42 = main.dart + 41-file unused vendored flutter_bootstrap5 copy; packages 897: aci 204, core 74, dex 63, dit 106, manifest 195, pam 255; ~129k LOC)
ARCH: clean-arch feature-first, split into local packages — each feature = data(data_source/model/repository) / domain(entities/repository/usecase) / presentation(controller/screens/widgets|components); `core` package = shared infra + widgets; app shell (75 routes + root MultiBlocProvider) lives in lib/main.dart. Every package path-depends on every other (circular), core's DI/AppBloc import feature packages
STATE: flutter_bloc Cubit only (25 cubits, 0 Blocs/events) — no base cubit/handleRequest; per-action XLoading/XSuccess/XError state classes; god "AppBloc" (packages/core/lib/core/util/cubit/cubit.dart) holds lang/theme/translations/session/file-picking; all cubits are get_it lazy singletons provided at the root
DI: get_it (manual, 269 registerLazySingleton, 0 factories) — packages/core/lib/core/di/injection.dart (985 lines; also opens the Hive box)
ROUTING: go_router ^14.6.1 — lib/main.dart (75 inline GoRoutes, each with duplicated builder+pageBuilder) + path constants packages/core/lib/core/util/resources/routes_manager.dart — guards: one top-level redirect (dashboard requires token) | deep links: web path URLs (usePathUrlStrategy, path params like :aciRequestId), no errorBuilder/404, no ShellRoute
NETWORK: dio ^5.7.0 — interceptors: none (headers rebuilt inside every method; token passed per call) | token refresh: n | retry: n | error mapping: private request() extension unwraps {code,message,data} envelope, maps DioException + 422-style `errors` map -> ServerFailure(code,message,data) and global fieldsFormErrors; messages translated via AppBloc.translationData | files: packages/core/lib/core/network/remote/dio_helper.dart, api_endpoints.dart, servies.dart
RESULT_TYPE: Either (dartz) — packages/core/lib/core/error/failures.dart (abstract Failure extends Equatable; only ServerFailure{code,message,data}); UseCase<Type,Params>+NoParams in packages/core/lib/core/usecase/use_case.dart
STORAGE: raw window.sessionStorage/localStorage (dart:html) for session + translation cache (gzip + XOR "encryption") inside AppBloc; Hive JSON k/v wrapper CacheImpl (packages/core/lib/core/network/local/cache_helper.dart); sqflite DBImpl wrapper unused (data_base_helper.dart); shared_preferences declared, unused
L10N: custom server-driven key/value translations — fetched per module ('home','login','aci','dit','dex','manifest','validations'...) by TranslationsUseCase, merged into AppBloc.translationData and cached in localStorage with a langVersion bust — ar/en, default ar — used as translationData['key'] (3,721 call sites); assets/translations/{ar,en}.json present but unused — hardcoded UI strings: some (~170 Arabic literal lines + a few English, mostly manifest/aci screens)
RTL: Directional=29 vs LeftRight=118 (64 in packages, 54 in the unused vendored lib/src copy); MaterialApp locale pinned to 'ar'; English handled by 91 manual Directionality wrappers + ‎ LTR-mark helpers
THEME: used ThemeData is inline in lib/main.dart (BootstrapTheme.toTheme(ThemeData(primarySwatch, fontFamily, scrollbarTheme))) — dark mode: n (AppBloc.changeTheme builds light/dark ThemeData with appBar/bottomNav/colorScheme/textTheme but they are never applied; isDark toggle is a no-op) | component themes in ThemeData: n (only scrollbar in the applied theme) | colors class: ColorsManager (packages/core/lib/core/util/resources/colors_manager.dart, 50-950 tonal scales) | text styles class: none (CustomText/BodyText/TitleText... widgets with GoogleFonts.cairo; FontConstants/FontWeightManager in font_manager.dart) | fonts: bundled Helvetica Neue, Cairo, Poppins, Antonio + google_fonts cairo/lato
RESPONSIVE: flutter_bootstrap5 grid (FB5Container/FB5Row/FB5Col with Bootstrap classNames, ~950 uses) + custom ScreenSizes num extensions .w/.h/.rw/.rh/.rSp (design 375x812) in packages/core/lib/core/util/resources/extensions_manager.dart — breakpoints: Bootstrap 576/768/992/1200/1400 on width; widgets use LayoutBuilder maxWidth <768 (mobile) / <992 (tablet -> drawer); pagination <600
TEXT_SCALING: none (no TextScaler clamp; ScaleSize.textScaleFactor/getResponsiveFontSize helpers exist but are unused; FlutterBootstrap5(fontSize: state.defaultFontSize=16) changeable via AppBloc.defaultFontSizeChanged)
ENV/FLAVORS: runtime host detection — isAppLocal/isAppSecured from Uri.base in lib/main.dart pick one of 4 hardcoded URLs per microservice (~10 base URLs) in packages/core/lib/core/network/remote/api_endpoints.dart; no dotenv/--dart-define/flavors; Dockerfile (Flutter -> nginx) + .gitlab-ci.yml (sonar, docker build, flutter.js?v=$TAG cache-bust)
LOGGING: localPrint() (debugPrint in 800-char chunks, only when host contains localhost; 127 calls) + MyBlocObserver; 23 raw print()
ANALYTICS/CRASH: none (custom ErrorWidget.builder only)
PUSH: none (in-app notifications fetched by AccountManagementCubit.notification + NotificationWidget badge)
PAYMENTS/IAP: none
PERMISSIONS: permission_handler + permission_handler_web declared, never imported
DEEP_LINKS: go_router web paths (usePathUrlStrategy, optionURLReflectsImperativeAPIs) incl. external set-new-password link parsed from Uri.base in main(); no app_links
MEDIA/FILES: file_picker (AppBloc.pickFiles with extension + 10 MB checks), syncfusion_flutter_pdfviewer, archive (gzip), flutter_svg, HtmlElementView iframe (USB-token signing); declared-but-unused: flutter_dropzone, excel, lottie, fwfh_cached_network_image, image_picker_for_web
TESTS: 3 meaningful files (packages/pam/test/login: use case, repository, remote data source; mockito) — plus a broken counter template test/widget_test.dart and 6 empty/commented stubs
LINTS: flutter_lints ^4.0.0 default in root and in every package, 0 extra rules
BEST_GENERIC_FILES (top ≤15 reusable infra files, best first):
- packages/core/lib/core/util/widgets/dialogs/system_dialog.dart — SystemDialog.show() facade: status (success/error/warning/info, auto-close) / action (confirm) / form dialogs via per-type builders — quality 3 — coupling: low (default labels from AppBloc.translationData; form type uses DynamicForm)
- packages/core/lib/core/error/failures.dart + packages/core/lib/core/usecase/use_case.dart — Failure/ServerFailure(code,message,data) + UseCase<T,P>/NoParams — quality 3 — coupling: none
- packages/core/lib/core/network/local/cache_helper.dart — CacheHelper interface + Hive CacheImpl (JSON encode/decode, CacheException) — quality 3 — coupling: none
- packages/core/lib/core/network/remote/dio_helper.dart — DioHelper interface (get/post/put/patch/delete with base, token, cancelToken, progress, multipart) + envelope/validation-error mapper — quality 2 — coupling: high (globals token/isArabic/fieldsFormErrors/validationError, sl<AppBloc>, shared mutable Dio options, catch-all bug)
- packages/core/lib/core/util/widgets/dropDown/drop_list_pagination.dart — searchable single/multi dropdown with lazy paginated dataFetcher({filter, skip, take}) on dropdown_search — quality 3 — coupling: medium (AppBloc, bootstrap, translations)
- packages/core/lib/core/util/widgets/app_form/custom_dynamic_form_widget.dart — FormItem + DynamicForm: declarative List<List<FormItem>> rows (text/dropdown/checkbox/custom) laid out with Bootstrap classNames — quality 3 — coupling: medium (flutter_bootstrap5, AppBloc)
- packages/core/lib/core/util/widgets/pagination.dart — CustomPagination (mobile prev/next vs desktop numbered with ellipsis) — quality 3 — coupling: low (hardcoded English 'Page x of y')
- packages/core/lib/core/util/resources/extensions_manager.dart — DateTime/num/String?/List? extensions, ScreenSizes, Arabic->Latin digits, TextInputFormatters (digits-with-dashes, Arabic decimal, IMO), Map.addIfNotNullOrEmpty, localPrint — quality 3 — coupling: medium (also hosts showUSBToken dialog helper)
- packages/core/lib/core/util/resources/animated_navigation.dart — SlideFromRightPageRoute (go_router CustomTransitionPage fade+slide) + browser-history "no back" helpers — quality 3 (transition) / 1 (history hacks) — coupling: low / dart:html
- packages/core/lib/core/util/resources/colors_manager.dart — tonal palette primary/neutral/error/warning/successful 50-950 + misc — quality 3 — coupling: none
- packages/core/lib/core/util/resources/debounce.dart — Debounce.run(VoidCallback) — quality 3 — coupling: none
- packages/core/lib/core/util/resources/date_formatter.dart — null-safe DateFormatter.format / formatStringDate ('-' fallback) — quality 3 — coupling: none
- packages/core/lib/core/util/resources/bloc_observer_manager.dart — MyBlocObserver logging create/change/error/close — quality 3 — coupling: low (localPrint)
- packages/core/lib/core/util/widgets/tables/main_table_widget.dart — ResponsiveTable: column-map data table with per-column text/dropdown filters, tri-state sort, pagination, per-row action popup menus, advanced-search form (+ legacy MainTableWidget "Will Remove") — quality 2 — coupling: high (1,086 lines, AppBloc, app icons)
- packages/core/lib/core/util/resources/validations.dart — form validators returning caller-supplied messages (email, mobile, national ID, passport, tax number, password, dates, IMO) — quality 2 — coupling: high (country-specific rules, AppBloc/SystemDialog)
GENERIC_WIDGETS (every reusable widget):
- packages/core/lib/core/util/widgets/buttons/custom_button.dart — primary button (GestureDetector+Container, static 150 ms throttle) — onPressed, title, icon/iconWidget, iconFirst, buttonColor, textColor, borderColor/Width/Radius, width, height, fontSize, shadowColor, widget, margin, padding — quality 2 — generic? y
- packages/core/lib/core/util/widgets/buttons/custom_text_button.dart — text/link button with optional icon — onPressed, title, icon, iconFirst, textColor, fontSize, fontWeight, align, mainAxisSize, padding — quality 3 — generic? y
- packages/core/lib/core/util/widgets/buttons/custom_icon_button.dart — circular icon button with tooltip — onPressed, icon, svg, color, toolTip — quality 2 — generic? y (default tooltip from translations)
- packages/core/lib/core/util/widgets/buttons/lang_btn.dart — language toggle that refetches all translation modules — isInDrawer — quality 2 — generic? n
- packages/core/lib/core/util/widgets/back_button.dart — back button — function — quality 2 — generic? y
- packages/core/lib/core/util/widgets/texts/custom_text_field.dart — labelled TextFormField (required asterisk, tooltip, error text, read-only fill, Semantics label) — controller, hint, title, isRequired, validate, errorMessage, suffix, maxLines, maxLength, inputFormatters, keyboardType, readOnly, obscureText, onChanged, onTap, onSubmitted, toolTibMessage, toolTibBesideField, borderRadiusValue, transparentBorderColor, disableColor... — quality 3 — generic? y
- packages/core/lib/core/util/widgets/texts/custom_attachment_text_field.dart — read-only field that opens file picker, shows file name + delete — title, hint, suffix, isRequired, toolTibMessage, onSelectedDoc — quality 2 — generic? y
- packages/core/lib/core/util/widgets/texts/custom_text.dart — text family: CustomText, DefaultHeadlineText1-6 (bootstrap H1-H6), HeaderText, BodyText, TitleText, DisplayText, LabelText — title, align, color, fontSize, fontWeight, maxLines, lineHeight, decoration, shadowColor, softWrap — quality 2 — generic? y (each wraps a BlocBuilder<AppBloc>)
- packages/core/lib/core/util/widgets/texts/custom_selectable_text.dart — SelectableText variant — same params as CustomText — quality 3 — generic? y
- packages/core/lib/core/util/widgets/texts/main_title.dart — title + subtitle header — title, subTitle — quality 2 — generic? y
- packages/core/lib/core/util/widgets/check_box.dart — Checkbox with Semantics — value, onChange, title — quality 3 — generic? y
- packages/core/lib/core/util/widgets/customListCheckbox.dart — ParentChildCheckbox tri-state parent/children list — parent, children, onParentSelect, onChildSelect, parentValue, childrenValue, isExpanded, colors/scales, gap — quality 3 — generic? y
- packages/core/lib/core/util/widgets/dropDown/drop_list_pagination.dart — searchable lazy-paginated dropdown, single or multi — items, values, selectedValue, onChanged, onMultiSelectChanged, dataFetcher, onDropdownOpened, validate, multiSelectionValidate, title, withTitle, required, isMultiSelection, searchByNameOrCode, shouldShowSearch, styling... — quality 3 — generic? y
- packages/core/lib/core/util/widgets/app_form/custom_dynamic_form_widget.dart — DynamicForm (declarative form builder) — formStructure, title, buttonTitle, onPressedButton, dismissTitle, dismissPressed, isDialog, withContainer, withDismissButton, withPressButton, svgPath — quality 3 — generic? y
- packages/core/lib/core/util/widgets/dialogs/system_dialog.dart — SystemDialog.show status/action/form dialog — context, dialogStatus, description, title, contentWidget, formStructure, submitText, dismissTitle, hasCancelButton, onSubmit, onDismiss, autoCloseSeconds, svgImagePath, width, isScrollable — quality 3 — generic? y
- packages/core/lib/core/util/widgets/dialogs/progress_dialog.dart — ProgressDialog + loadingPage() + PulsingLogo (pulsing app logo loader) — message — quality 2 — generic? y (logo path hardcoded)
- packages/core/lib/core/util/widgets/dialogs/custom_show_full_model_dialog.dart — read-only details dialog of titled cards/columns — title, cardsTitles, cardsColumnsTitles, cardsColumnsData, cardsNumberOfColumns, additionalWidget — quality 2 — generic? y
- packages/core/lib/core/util/widgets/dialogs/check_usb_token.dart — USB-token digital-signature dialog (iframe + postMessage via LoginCubit) — successFun, failureFun, buttonText, withoutToken — quality 2 — generic? n
- packages/core/lib/core/util/loading_files/main_loading.dart — skeleton list (card_loading + staggered animation) — none — quality 3 — generic? y
- packages/core/lib/core/util/widgets/pagination.dart — CustomPagination/MobilePagination/DesktopPagination — currentPage, totalPages, onChanged — quality 3 — generic? y
- packages/core/lib/core/util/widgets/tables/main_table_widget.dart — ResponsiveTable (+ legacy MainTableWidget, ActionDataModel, ActionIconEnum) — columns, searchControllers, dropdownsItems, dynamicSearchFilter*, dataFetcher, actions, customActionWidget, currentPage, totalPages, onPageChanged, allColumnsWidthsFactor, advancedSearchPressed, advansedSearchFormStructure... — quality 2 — generic? partly
- packages/core/lib/core/util/widgets/menus/popup_menu_widget.dart — CustomPopupMenuWidget + NestedPopupMenuItem (hover sub-menus) — title, widgets, icon, titleWidget, tableRowIndex, children, isNested, nestedMenuWidth — quality 2 — generic? y
- packages/core/lib/core/util/widgets/containers/custom_default_container.dart — titled card/section with optional back button, tooltip, suffix — title, widget, titleSize, toolTibMessage, titleRowSuffixWidget, imagePath, onTapBackButton, height, width, paddings, isDialog — quality 2 — generic? y
- packages/core/lib/core/util/widgets/containers/custom_shadow.dart — shadowed card container — child, blurRadius, offsetX/Y, spreadRadius, borderRadius, color, height, width, padding, margin — quality 3 — generic? y
- packages/core/lib/core/util/widgets/containers/custom_expansion_container.dart — expandable section with optional count badge — title, child, widget, onChange, isEnabled, isExpanded, titleColor, withManifestNumber, totalNum — quality 2 — generic? mostly
- packages/core/lib/core/util/widgets/containers/custom_containers_list.dart + custom_container_item_builder.dart — grid of service tiles (icon + title, active state, tooltip) — mainTitle, titleList, icons, ids, isActiveButton, selectItem, withDialog, tooltip / onTap, icon, title — quality 2 — generic? y
- packages/core/lib/core/util/widgets/custom_expantion_tile.dart — "advanced search" expansion tile hosting a DynamicForm — title, advancedButtonPressed, advancedFormStructure, initOpenExpansionPressed, closeExpansionPressed, canOpen — quality 2 — generic? y
- packages/core/lib/core/util/widgets/custom_padding.dart — Padding with LTRB defaults 36/20 — left, top, right, bottom, child — quality 1 — generic? y (not RTL-aware)
- packages/core/lib/core/util/widgets/custom_tooltip.dart — info-icon tooltip (just_the_tooltip) — message, height, child — quality 3 — generic? y
- packages/core/lib/core/util/widgets/steppers/custom_stepper_widget.dart — horizontal numbered step indicator — currentStep, titles, alignString — quality 3 — generic? y
- packages/core/lib/core/util/widgets/steppers/secondary_stepper_widget.dart — segmented tabs — titles, currentIndex, selectTap, classNames — quality 3 — generic? y
- packages/core/lib/core/util/widgets/stepper.dart — StepperWidget tied to RegisterCubit/ManifestCubit — route, stepsTitles — quality 1 — generic? n
- packages/core/lib/core/util/widgets/success_widget.dart — success result view (big check icon + texts) — title, body, additionalText — quality 2 — generic? y
- packages/core/lib/core/util/widgets/notification.dart — notification bell badge opening notifications panel — notificationNumber, colorIcon — quality 2 — generic? n
- packages/core/lib/core/util/widgets/navs/default_scaffold.dart — CustomScaffold (drawer under 992 px, scrollable body) — body — quality 2 — generic? n (imports pam drawer)
- packages/core/lib/core/util/widgets/navs/main_design.dart — web page shell: navbar + breadcrumb title + min-height content + footer in FB5 grid — titles, routes, widget, titleWidgetReplacement, aciRequestId, invoiceId — quality 2 — generic? partly
- packages/core/lib/core/util/widgets/navs/navigation_bar.dart — CustomNavigationBar, CustomAppBar, CustomDrawer, HoverPopupMenu (top nav with hover menus built from user services) — route / isArabic, navigateTo / isLoggedIn — quality 2 — generic? n
- packages/core/lib/core/util/widgets/navs/nav_title_widget.dart — breadcrumb from titles/routes — titles, routes, aciRequestId, invoiceId — quality 2 — generic? partly
- packages/core/lib/core/util/widgets/navs/page_title_footer.dart — page footer title — title, subTitle — quality 2 — generic? y
- packages/core/lib/core/util/widgets/footer/footer.dart — site footer — none — quality 2 — generic? n
NOTABLE_IDEAS: (1) SystemDialog.show single entry for status/confirm/form dialogs (packages/core/lib/core/util/widgets/dialogs/system_dialog.dart); (2) server field-validation errors collected per field into a map and shown through CustomTextField.errorMessage (dio_helper.dart -> fieldsFormErrors) — worth keeping, but on a per-request object instead of a global; (3) API message keys translated client-side through the translation map (dio_helper.dart); (4) server-driven translations per module cached in localStorage with version bust (AppBloc.translation/getLang); (5) lazy paginated dropdown fetch signature ({filter, skip, take}) shared by dropdowns, forms and table filters (drop_list_pagination.dart, custom_dynamic_form_widget.dart, main_table_widget.dart); (6) declarative DynamicForm reused for dialogs and table advanced search; (7) CustomButton double-tap throttle; (8) Semantics label+identifier on inputs + SemanticsBinding.instance.ensureSemantics() in main for web test automation; (9) TextInputFormatters for Arabic-digit decimals and LTR marks for numbers inside RTL (extensions_manager.dart); (10) runtime environment pick by host so one web build serves local/staging/prod (api_endpoints.dart + main.dart); (11) go_router CustomTransitionPage fade+slide (animated_navigation.dart); (12) custom ErrorWidget.builder in main; (13) Dockerfile multi-stage Flutter web -> nginx + GitLab CI cache-busting of flutter.js; (14) domains split into local packages (good idea, but needs a one-way dependency graph)
SMELLS: circular path deps (every package depends on all others; core imports pam/aci) and no barrel files; god files (lib/main.dart 1,327 lines with 75 routes each repeating builder+pageBuilder; injection.dart 985; cubits 1.1k-1.7k lines; screens 1.2k-1.5k); god AppBloc (theme+lang+translations+session+file picker+dialogs+TextEditingControllers); mutable globals in constants_manager.dart (token, userID, isArabic, fieldsFormErrors, validationError...) plus leftovers from an unrelated fitness app (coach/bodyFat/social-link fields); all cubits lazy singletons -> state survives logout/navigation; mixed sl<AppBloc>() (262) and AppBloc.get(context) (102); CustomText wraps every Text in BlocBuilder<AppBloc> and prefixes ‎; dio_helper: shared Dio options mutated per call (race), timeouts never reset, 5 copy-pasted method bodies, final catch(e) swallows ServerFailures thrown inside try and turns them into 500/'Something went wrong'; repositories copy-paste try/on ServerFailure per method and drop Failure.data; session token in sessionStorage with XOR + hardcoded key (obfuscation only); MyHttpOverrides trusts all certificates; SystemDialog auto-close pops after 2 s even if the dialog is gone; CustomButton has no ripple/focus/disabled/loading and a static shared throttle flag; CustomPadding/EdgeInsets.fromLTRB not RTL-aware; deprecated APIs: withOpacity x30, ColorScheme background/onBackground, dart:html x28 + js package (block Wasm); hardcoded colors (Colors.* 98, Color(0x..) 43 outside ColorsManager) and Arabic strings in manifest/aci screens; Transform.rotate(angle: 45) in radians; dead code: vendored lib/src flutter_bootstrap5 copy (41 files, not imported), TranslationModel (522 lines), commented location_service.dart, unused sqflite helper, unused assets/translations, commented routes; ~24 declared-but-unused deps; awesome_dialog used next to SystemDialog (8 files); typo dir `presentaion`; a filename containing a space (`add_company_representative _entity.dart`)
```

---

## 1. Architecture pattern

**Clean architecture, feature-first, split across local path packages.** It is a Flutter **web-only** portal (it imports `dart:html` in 28 files: `window.sessionStorage`, `window.localStorage`, `window.history`, `HtmlElementView` iframes). There is no `melos.yaml`. The root app pulls the packages in with `path:` dependencies.

| Package | Role | Features |
|---|---|---|
| `packages/core` | shared infrastructure: DI, network, errors, use-case base, global AppBloc, resources (colors, routes, validators, extensions), all reusable widgets | — |
| `packages/pam` | auth + account management + home/dashboard | `auth/login`, `auth/register`, `account_management`, `dashboard`, `home` |
| `packages/aci` | ACI requests | `aci`, `invoice`, `shipment` |
| `packages/dit` | declarations | `dit_request`, `documents`, `invoice` |
| `packages/dex` | export requests | `dex_request` |
| `packages/manifest` | manifests | `bills`, `delivery_permissions`, `manifest`, `manifest_requests`, `shipping_permissions`, `sub_agents` |

**Per-feature layering** (the same in every package):

- `data/data_source/` — `XBaseRemoteDataSource` abstract + `XRemoteDataSource(Impl)`, which calls `DioHelper` with `base: <serviceBaseURL>` and `endPoint: <const>`
- `data/model(s)/` — `XModel extends XEntity` with `fromJson`
- `data/repository/` — `XRepository extends XBaseRepository`, wraps calls in `try { Right(..) } on ServerFailure { Left(..) }`
- `domain/entities/` — Equatable entities (several have `fromJson` too)
- `domain/repository/` — abstract repository returning `Future<Either<Failure, T>>`
- `domain/usecase(s)/` — one class per call, `extends/implements UseCase<T, Params>`, Params as Equatable
- `presentation/controller/` — `XCubit extends Cubit<XStates>` + `x_states.dart` (plain classes, no Equatable)
- `presentation/screens/` (+ `widgets/`, `components/`) — screens read the cubit through `sl<XCubit>()` or `XCubit.get(context)` and the translations through `appBloc.translationData['key']`

**Wiring problems:**
- Every feature package's `pubspec.yaml` lists **all** other packages as path dependencies, and `core` lists all five feature packages. `core/di/injection.dart` imports every feature's data source, repository, use case and cubit. `core/util/cubit/cubit.dart` imports `pam` (LoginCubit, ShowMainAccountUseCase) and `aci` (TranslationsUseCase). So the packages are just folders: none of them can be built or tested on its own.
- Packages have no barrel files. Imports are deep (`package:aci/features/aci/presentation/...`).
- `lib/main.dart` imports about 100 screens and cubits directly to build the router and the root `MultiBlocProvider`.

---

## 2. Folder tree

```
portal/
├── lib/
│   ├── main.dart                     # entry: web URL strategy, ErrorWidget.builder, env-by-host flags, di.init(),
│   │                                 # sessionStorage restore, GoRouter (75 routes inline), root MultiBlocProvider (17 cubits),
│   │                                 # FlutterBootstrap5 + MaterialApp(.router) once translations are loaded
│   ├── flutter_bootstrap5.dart       # `library flutter_bootstrap5;` — vendored copy of the pub package (NOT imported anywhere)
│   └── src/                          # parts of that vendored copy (unused; the app imports package:flutter_bootstrap5)
│       ├── content/                  # typography part
│       ├── layout/                   # bootstrap_theme, breakpoints (576/768/992/1200/1400), media_query_builder
│       │   └── fb5_style/            # class-name parsers: col size/offset, gutter, margin, padding, display, order, alignment
│       ├── utilities/                # borders, colors, helper, spacing
│       └── widgets/
│           ├── layout/               # div, fb5_col, fb5_container, fb5_grid, fb5_order, fb5_row
│           └── typography/           # display1-6, h1-h6
├── packages/
│   ├── core/lib/core/                # shared infrastructure (read fully)
│   │   ├── di/injection.dart         # get_it: 269 lazy singletons for all packages + Hive box
│   │   ├── error/                    # exceptions.dart (CacheException), failures.dart (Failure, ServerFailure, mapFailureToMessage)
│   │   ├── models/status_model.dart  # {status, message} model (fromJson logic inverted)
│   │   ├── network/
│   │   │   ├── repository.dart       # empty Repository / RepoImplementation(dioHelper, cacheHelper) — unused
│   │   │   ├── local/                # cache_helper.dart (Hive CacheImpl), data_base_helper.dart (sqflite DBImpl, unused)
│   │   │   └── remote/               # dio_helper.dart, api_endpoints.dart (env-by-host base URLs + endpoint consts),
│   │   │                             # servies.dart (MyHttpOverrides), location_service.dart (fully commented)
│   │   ├── usecase/use_case.dart     # UseCase<Type, Params>, NoParams
│   │   └── util/
│   │       ├── configuration_files/  # aci/dex business constants (type IDs, code lists)
│   │       ├── cubit/                # cubit.dart (AppBloc god-cubit), state.dart (AppState + ~40 marker states, CurrentContainer)
│   │       ├── enums/employees.dart  # Employees enum
│   │       ├── generalFunctions/     # custom_date_format.dart (date picker -> string), redirect_launch.dart (mailto)
│   │       ├── loading_files/        # main_loading.dart (skeleton list)
│   │       ├── resources/            # colors_manager, constants_manager (globals + helpers), extensions_manager,
│   │       │                         # routes_manager, animated_navigation, validations, translation_manager (legacy),
│   │       │                         # date_formatter, debounce, font_manager, app_assets, assets.gen.dart (flutter_gen),
│   │       │                         # bloc_observer_manager, setting_items
│   │       ├── theme/colors.dart     # 2 stray Color consts
│   │       └── widgets/              # every reusable widget (see §5)
│   │           ├── app_form/         # DynamicForm + FormItem
│   │           ├── buttons/          # CustomButton, CustomIconButton, CustomTextButton, LangBtn
│   │           ├── containers/       # CustomContainer, CustomShadow, CustomExpansionContainer, CustomContainersList, item builder
│   │           ├── dialogs/          # SystemDialog, ProgressDialog/PulsingLogo, CustomShowFullModelDialog, CheckUsbToken
│   │           ├── dropDown/         # CustomDropdownPagination
│   │           ├── footer/           # Footer
│   │           ├── menus/            # CustomPopupMenuWidget, NestedPopupMenuItem
│   │           ├── navs/             # CustomScaffold, MainDesign, CustomNavigationBar/AppBar/Drawer, breadcrumb, page footer
│   │           ├── steppers/         # CustomStepperWidget, SecondaryStepperWidget
│   │           ├── tables/           # ResponsiveTable (+ legacy MainTableWidget)
│   │           ├── texts/            # CustomText family, CustomTextField, CustomAttachmentTextField, CustomSelectableText, MainTitle
│   │           └── (root files)      # back_button, check_box, customListCheckbox, custom_expantion_tile, custom_padding,
│   │                                 # custom_tooltip, notification, pagination, stepper, success_widget
│   ├── pam/lib/features/             # auth/login (25 files), auth/register (48), account_management (176), dashboard (3), home (3)
│   ├── aci/lib/features/             # aci (107), invoice (81), shipment (16)
│   ├── dit/lib/features/             # dit_request (30), documents (20), invoice (56)
│   ├── dex/lib/features/             # dex_request (63; sub-cubits under presentation/screens/*/controller)
│   └── manifest/lib/features/        # bills (43), delivery_permissions (20), manifest (84), manifest_requests (23, "presentaion/bloc"),
│                                     # shipping_permissions (21), sub_agents (4, presentation only)
├── assets/                           # fonts/, images/{svg,svg/manifest,svg/aci,svg/dit,png,lotti}, json/ (countries), translations/ (unused)
├── test/                             # widget_test.dart (broken template), mocks.dart (commented), *.mocks.dart (generated)
├── web/                              # index.html, manifest.json, service-worker.js
├── Dockerfile, nginx.conf.example, server.js (commented Node proxy), .gitlab-ci.yml, sonar-project.properties
└── analysis_options.yaml             # flutter_lints default
```

**Representative feature, fully expanded: `packages/dit/lib/features/documents/`** (20 files)

```
documents/
├── data/
│   ├── data_source/documents_remote_data_source.dart   # DocumentsBaseRemoteDataSource + impl; GET list with paging query,
│   │                                                    # multipart upload from PlatformFile.bytes, '_method':'PUT' override
│   ├── models/additional_document_model.dart, required_document_model.dart   # extend entities, fromJson
│   └── repository/documents_repository.dart            # 4 methods, each its own try / on ServerFailure -> Left
├── domain/
│   ├── entities/additional_document_entity.dart, required_document_entity.dart (incl. DocumentFile, pagination meta)
│   ├── repository/documents_base_repository.dart        # abstract Either-returning API
│   └── usecases/ get_required_documents_usecase.dart (+Params page/ditId/type), add_update_required_document_usecase.dart,
│                 add_additional_documents_usecase.dart, delete_required_document_usecase.dart
└── presentation/
    ├── controller/documents_cubit.dart (187 lines), documents_states.dart (Loading/Success/Error per action)
    ├── components/ add_required_document_dailog.dart, additional_documents_table.dart, required_documents_table.dart, save_button.dart
    └── screens/ required_documents_screen.dart (stepper + tabs + table), uploadOrEdit_additional_document.dart,
                 widgets/required_documents_widget.dart
```

Pattern in the screen: `BlocBuilder<AppBloc>` → `BlocBuilder<DocumentsCubit>` → `FB5Row/FB5Col` layout with `CustomStepperWidget` + `SecondaryStepperWidget` tabs. All labels come from `appBloc.translationData['...']`.

---

## 3. Infrastructure

### 3.1 State management
- **Packages:** `flutter_bloc ^8.1.6`, `bloc ^8.1.4`, `equatable`.
- **Cubits only:** 25 classes, all `extends Cubit<...>`. There are no event-driven Blocs, even where the class is named `*_bloc.dart`.
- **No base cubit or request helper.** Each method does the same thing by hand: `emit(Loading)` → `await useCase(params)` → `result.fold(emit(Error(mapFailureToMessage(f))), emit(Success))`. States are plain classes (no Equatable or sealed). Mutable data lives in cubit fields (lists, selected indexes, `TextEditingController`s), and states are mostly signals.
- **Global AppBloc** (`packages/core/lib/core/util/cubit/cubit.dart`, 857 lines). It handles:
  - language and translations
  - theme building (unused) and a dark toggle (no-op)
  - default font size and Bootstrap container (the only real `AppState` fields: `defaultFontSize`, `currentContainer`, `copyWidth`)
  - session save/restore in sessionStorage
  - user data
  - file picking with validation
  - the USB-token dialog
  - misc UI flags
- **Lifetime:** every cubit is a `registerLazySingleton`, and 17 of them are provided at the root. Screens use both `sl<X>()` and `X.get(context)`. State is never reset between screens or users (logout only clears globals).
- **Logging:** `MyBlocObserver` in `bloc_observer_manager.dart`.
- **Quality:** 2/5. The pattern is consistent, but there is a lot of boilerplate, the cubits are huge (up to 1,685 lines), and state is global.

### 3.2 Dependency injection
- `get_it ^7.7.0`, registered by hand in `packages/core/lib/core/di/injection.dart` (985 lines, 269 `registerLazySingleton`, no factories). `init()` also runs `Hive.initFlutter()` and opens `cacheBox`.
- Because the single file lives in `core`, `core` has to import every feature package (the root cause of the circular graph). A template should use per-package `registerXDependencies(GetIt)` functions called from the app.

### 3.3 Routing
- `go_router ^14.6.1`. `lib/main.dart` builds one `GoRouter` with 75 flat `GoRoute`s (6 more are commented out). Each route defines both `builder` and `pageBuilder` with identical bodies (`pageBuilder` wins). Arguments come from `state.pathParameters` (e.g. `:aciRequestId`, `:invoiceId`, `:dexId`, `:userID`) or `state.extra as Map`.
- **Paths:** `abstract class Routes` in `packages/core/lib/core/util/resources/routes_manager.dart` (141 constants). Paths are built hierarchically by string interpolation, e.g. `'$importer/exporter-data'`. Some are non-const because they embed runtime values (`resetID`).
- **Guard:** one `redirect`. If the path contains `/dashboard` and the global `token == null`, it sends the user to `/`. There is no role or permission guard, no `refreshListenable`, no `errorBuilder`/404 page (`Routes.notFound` exists but no route uses it), and no `ShellRoute`. Each page builds its own `MainDesign` shell.
- **Transitions:** `SlideFromRightPageRoute extends CustomTransitionPage` (250 ms fade + 5 % slide) in `animated_navigation.dart`. The same file has `navigateAndFinish`, which calls `window.history.replaceState` and adds an `onPopState` listener that pushes the route back to disable the browser back button. `stopListening()` is called from `navigateTo()` in constants_manager.
- **Web URLs:** `usePathUrlStrategy()` and `GoRouter.optionURLReflectsImperativeAPIs = true`. The external "set new password" link is detected in `main()` by parsing `Uri.base`.
- **Quality:** 2/5 (one huge file, duplication, no 404, a weak guard).

### 3.4 Networking
- **Files:** `packages/core/lib/core/network/remote/dio_helper.dart` (496 lines), `api_endpoints.dart` (366 lines), `servies.dart`.
- **API:** `abstract class DioHelper` with `get/post/put/patch/delete({String? base, required String endPoint, data, query, String? token, ProgressCallback?, CancelToken?, Duration? timeOut, bool isMultipart})`. `DioImpl` holds one `Dio`.
- **No interceptors.** Each method resets `fieldsFormErrors`, mutates the shared `dio.options` (`baseUrl`, `headers`, `connectTimeout`), adds `Accept-Language` from the global `isArabic` and `Authorization: Bearer` when a token is passed, fixes `'??'` in endpoints, logs URL, headers, body and query with `localPrint`, then calls the private `request()` extension. The five method bodies are copy-pasted. Data sources pass `token: token` (the global) themselves (118 call sites).
- **Response/error mapping in `request()`:**
  - status ≥ 300 → stores `validationError`, throws `ServerFailure`
  - body `{code}` not 200/201 → throws `ServerFailure` with the message translated through `sl<AppBloc>().translationData[message]`
  - body `{data, message, code}` → returns a new `Response` with only `data` (envelope unwrapping)
  - localization responses are returned as-is
  - `DioException` with a response: walks `errors` (a field → list-of-keys map), translates each message, fills the global `fieldsFormErrors[field]`, and throws `ServerFailure(code, message, data)`
  - no response → `ServerFailure(500, translated e.message)`

  Pattern worth keeping, reduced (placeholders):
  ```dart
  // server returns { "errors": { "email": ["emailTaken."] } }
  for (final key in errors.keys) {
    fieldsFormErrors[key] = (errors[key] as List)
        .map((e) => translations[(e as String).replaceAll('.', '')] ?? e)
        .join('\n');
  }
  throw ServerFailure(code: statusCode, message: fieldsFormErrors.values.first, data: body);
  ```
- **Bugs:**
  - The final `catch (e)` also catches the `ServerFailure`s thrown inside the `try` (the ≥ 300 and custom-code branches). It rethrows them as a generic failure with code from the empty `dataMap` (→ 500, "Something went wrong"), so the real status code is lost.
  - Mutating the shared options is racy when requests run concurrently. A custom `timeOut` sticks for every later call.
- **No retry, no token refresh, no connectivity check** (`connectivity_plus` is declared but unused).
- **Env:** base URLs (`authBaseURL`, `accountManagementBaseURL`, `ditBaseURL`, `aciURL`, `aciShipmentURL`, `tokenURL`, `manifestBaseURL`, `cuscarBaseURL`, `translationBaseURL`, `notificationBaseURL`) are top-level `String`s. Each picks one of 4 hardcoded hosts with `isAppLocal ? (isAppSecured ? {{BASE_URL}} : …) : …`. Both flags are set in `main()` from `Uri.base`.
- `MyHttpOverrides` (`servies.dart`) sets `badCertificateCallback = (_, __, ___) => true`. It has no effect on web, but it is dangerous to copy.
- **Quality:** 2/5. The error and validation mapping ideas are good. The implementation is not.

### 3.5 Local storage
- **Session:** after login, `AppBloc.setUserDataInCookie` gzip-compresses, base64-encodes and XOR-"encrypts" (`encrypt_decrypt_plus` `XOR` with a key hardcoded in `constants_manager.dart`) the token, user id, tax number, identity, name and the services/permissions JSON. It writes them to `window.sessionStorage`, with services split into 2,500-char chunks. `getUserDataInCookie` restores them on startup. This is obfuscation, not security. sessionStorage is also used for navbar indexes and the language.
- **Translations cache:** `window.localStorage['ar.json'|'en.json']`, cleared when `langVersion` (constant `"0.3.0"`) changes (the check in main.dart is logically broken: `a == null || (a == null && …)`).
- **Hive:** `CacheHelper`/`CacheImpl` in `packages/core/lib/core/network/local/cache_helper.dart`. It is a clean small JSON k/v wrapper with `has/get/put/clear` and a `CacheException` wrapper (quality 3). It is only used by `LangBtn`.
- **sqflite:** `DBHelper`/`DBImpl` in `data_base_helper.dart`, the same interface over a `db` table. Never registered or used.
- `shared_preferences`, `hive_generator` and `path_provider` are declared but unused.

### 3.6 Localization (+RTL)
- **No ARB or easy_localization.** Translations are server-driven: `AppBloc.translation(route:)` calls `TranslationsUseCase` (it lives in the **aci** package) at `GET {{BASE_URL}}/<translationURL>/<lang>/<module>`. The result is merged into `translationData` (`Map<String, dynamic>`) and persisted to localStorage. Each module sets an `isTranslatedX` flag. `MaterialApp.router` is only built once `home/register/login/aci/dit/dex/manifest` are all loaded; until then a plain `MaterialApp` shows the pulsing-logo loader.
- **Usage:** `appBloc.translationData['key']` (3,721 sites). Missing keys give `null`, often passed straight into `String` params. `localised()`/`displayTranslatedText()` choose between inline ar/en strings.
- **Languages:** ar (default) and en. `LangBtn` flips `isArabic`, clears the caches and refetches every module.
- **Leftovers:** `assets/translations/{ar,en}.json` exist but nothing loads them. `translation_manager.dart` (`TranslationModel`, 522 `late String` fields) is a dead earlier approach.
- **RTL:**
  - `MaterialApp.router` pins `locale: Locale('ar')` with only `ar` supported, so the app is always RTL at the root. English pages rely on about 91 manual `Directionality(textDirection: appBloc.isArabic ? rtl : ltr)` wrappers.
  - Directional APIs are used 29 times, against 118 left/right usages (64 in packages).
  - `CustomPadding` uses `EdgeInsets.fromLTRB`. `CustomText` prefixes every line with `‎` (LRM) through `addLtrMarkText`. `CustomTextField` forces LTR alignment once text is entered in Arabic mode.
  - Formatters strip and add LRM around numbers.
- **Hardcoded strings:** some. About 170 lines contain Arabic literals (top files: `manifest/.../policy_table_widget.dart`, `bills_cubit.dart`, `auto_insert_manifest.dart`, `aci/.../extend_acid_widget.dart`), plus a few English ones ("No Data Found", "Policies", "Page x of y").

### 3.7 Theming
- **Applied theme** (`lib/main.dart`): `BootstrapTheme.of(context).toTheme(theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Helvetica Neue', scrollbarTheme: …WidgetStatePropertyAll…))`. Most of the look comes from widget-level styling.
- `AppBloc.changeTheme` builds full `lightTheme`/`darkTheme` objects (appBar, bottomNavigationBar, timePicker, a full `ColorScheme` that uses the deprecated `background`/`onBackground`, and a 10-style `textTheme` with a font `'Sofia'` that is not bundled). Nothing reads them. `isDark` toggling only changes `themeMode`, which has no dark theme to use, so dark mode is effectively off.
- **Colors:** `ColorsManager` (`colors_manager.dart`): primary/neutral/error/warning/successful in 50…950 steps, plus about 40 ad-hoc named colors (`mainColor`, `tableBorderColor`, …). This is a good token base. Separately, `util/theme/colors.dart` has 2 stray consts.
- **Text:** there is no TextStyle class. Text widgets (`CustomText`, `BodyText`, `TitleText`, `HeaderText`, `DisplayText`, `LabelText`, `DefaultHeadlineText1-6`) build `GoogleFonts.cairo(...)` inline. Inputs use `GoogleFonts.lato`. `font_manager.dart` has `FontConstants` (asset family names) and `FontWeightManager`.
- **Fonts:** bundled Helvetica Neue (11 files), Cairo bold, Poppins, Antonio. `google_fonts` fetches Cairo and Lato at runtime.
- Hardcoded colors outside ColorsManager: `Colors.*` 98 times, `Color(0x…)` 43 times. `withOpacity` 30 times (one `withValues` in CustomShadow).

### 3.8 Responsive helpers
- **flutter_bootstrap5 (pub):** `FlutterBootstrap5(fontSize:)` wraps the app. Layout uses `FB5Container.fluid`, `FB5Row`, `FB5Col(classNames: 'col-xs-12 col-lg-6 py-3 mx-1 …')` (about 950 uses). Breakpoints are Bootstrap's on **width**: xs < 576, sm 576–768, md 768–992, lg 992–1200, xl 1200–1400, xxl ≥ 1400.
- **Custom:** `ScreenSizes` singleton + `SizeExtension on num` (`.w` / `.h` as % of the screen, `.rw/.rh/.rSp` relative to a 375×812 design) in `extensions_manager.dart`. `ScreenSizes.screenWidth/Height` are assigned in the root `BlocBuilder` on every rebuild. Used only about 24 times.
- **Widget-level:** `LayoutBuilder` with `maxWidth < 768` for mobile and `< 992` for tablet (switches to `endDrawer`). `CustomPagination` switches at `< 600`.

### 3.9 Text scaling
- No `TextScaler`/`MediaQuery` clamp. `ScaleSize.textScaleFactor()` (width/1400 × max, clamped 1..2) and `getResponsiveFontSize()` (×1.1/1.3/1.5 at 768/992/1200) exist but are not used. The base font size is a Bootstrap root `fontSize` (16) held in `AppState.defaultFontSize`.

### 3.10 Env / flavors
- **Runtime host sniffing:**
  ```dart
  isAppLocal  = Uri.base.toString().contains("localhost") || /* LAN IP / local host name */;
  isAppSecured = Uri.base.scheme == "https";
  ```
  Every base URL is a nested ternary over these flags (4 variants each). There are no `--dart-define`, `.env` or flavors.
- **Deploy:** `Dockerfile` is multi-stage: `ghcr.io/cirruslabs/flutter:3.29.2` running `flutter build web --base-href="/"` as a non-root user, then `alpine` + nginx. `.gitlab-ci.yml` has stages for the SonarQube check, a DB backup job (credentials come from CI variables), docker build/push (with `sed` cache-busting `flutter.js?v=$TAG` in `web/index.html`) and deploy. `server.js` is a fully commented Node HTTPS proxy.

### 3.11 Logging
- `localPrint(String)` (`extensions_manager.dart`) prints through `debugPrintFullText` (800-char chunks) only when `Uri.base` contains `localhost`. It has 127 call sites and logs full request headers, including the bearer token, locally.
- `MyBlocObserver` logs onCreate/onChange/onError/onClose. There are also 23 raw `print()` calls and `dart:developer log` in places.

### 3.12 Analytics / crash reporting
- None. `main()` sets a custom `ErrorWidget.builder` (centered red "Error!\n<summary>" text) and nothing else.

### 3.13 Push notifications
- None. In-app notifications come from `AccountManagementCubit.notification(isRead: 0|1)`. `NotificationWidget` (core) shows a `Badge.count` bell that opens `NotificationScreen` (pam) in a dialog aligned to `AlignmentDirectional.topEnd`.

### 3.14 IAP / payments
- None.

### 3.15 Permissions
- `permission_handler` and `permission_handler_web` are in pubspec and never imported. The "permissions" the code talks about are server-side service permissions on `LoginService`/`Permission` entities (`pam/.../log_in_entity.dart`), used to build the navbar.

### 3.16 Deep links
- Web path URLs only, through go_router (`usePathUrlStrategy`). Shareable entry points include `/set-new-password/<id>`, `/token/:tokenType`, `/verify-otp/:userID`, `/activate-invitation/:userID`. There is no `app_links`/`uni_links`.

### 3.17 Domain-specific web integration (FYI)
- **USB-token digital signature:** `LoginCubit.loginWithToken()` registers an `IFrameElement` view factory (`ui.platformViewRegistry`) pointing at `tokenURL`. `showIframeDialog` shows it in an `AlertDialog`, and `listenerToken` subscribes to `html.window.onMessage` to receive the signed result. `CheckUsbToken` (core) and `AppBloc.showUSBToken` / the `showUSBToken` helper wrap this flow. It is niche, but it is a clean example of the iframe + postMessage pattern.

---

## 4. Services catalog

| File path | Purpose | Public API | Dependencies | Generic? |
|---|---|---|---|---|
| packages/core/lib/core/di/injection.dart | get_it container for whole app | `sl`, `init()` | all packages, Hive | app-specific |
| packages/core/lib/core/error/failures.dart | failure types | `Failure`, `ServerFailure{code,message,data}`, `mapFailureToMessage()` (unsafe cast) | equatable | generic |
| packages/core/lib/core/error/exceptions.dart | cache exception | `CacheException(error)` | — | generic |
| packages/core/lib/core/usecase/use_case.dart | use-case base | `UseCase<Type,Params>.call`, `NoParams` | dartz, equatable | generic |
| packages/core/lib/core/models/status_model.dart | `{status,message}` DTO | `StatusModel.fromJson` (condition inverted) | equatable | generic (buggy) |
| packages/core/lib/core/network/repository.dart | empty repo base | `Repository`, `RepoImplementation(dioHelper, cacheHelper)` | — | unused |
| packages/core/lib/core/network/remote/dio_helper.dart | HTTP client | `DioHelper.get/post/put/patch/delete`, `DioImpl` | dio, AppBloc, globals | semi-generic |
| packages/core/lib/core/network/remote/api_endpoints.dart | base URLs (env-by-host) + ~150 endpoint consts | top-level strings | constants_manager | app-specific |
| packages/core/lib/core/network/remote/servies.dart | trust-all-certs HttpOverrides | `MyHttpOverrides` | dart:io | do not reuse |
| packages/core/lib/core/network/remote/location_service.dart | Google Places/Directions (fully commented out) | — | — | dead |
| packages/core/lib/core/network/local/cache_helper.dart | Hive JSON k/v cache | `CacheHelper.get/has/put/clear`, `CacheImpl(Box)` | hive | generic |
| packages/core/lib/core/network/local/data_base_helper.dart | sqflite JSON k/v cache | `DBHelper.get/has/put/clear`, `DBImpl(Database)` | sqflite | generic (unused) |
| packages/core/lib/core/util/cubit/cubit.dart | global AppBloc | `setThemes, changeDarkMode, changeTheme, translation(route), updateArFile/updateEnFile, compressString/decompressString, setUserData, setUserDataInCookie, getUserDataInCookie, getUserData, getUserServicesInCookie, clearData, getLang, showUSBToken, pickFiles, checkIfSelectedFilesMeetsExtensions, changePaginatedValue, getMainAccountData, defaultFontSizeChanged, currentContainerChanged...` | pam, aci, archive, file_picker, dart:html | app-specific |
| packages/core/lib/core/util/cubit/state.dart | AppState + ~40 marker states, `CurrentContainer` enum | `copyWidth()` | aci, pam entities | app-specific |
| packages/core/lib/core/util/resources/constants_manager.dart | mutable globals (session, flags), XOR cipher, `navigateTo/navigateToPush/navigateBack`, `defaultAppBar`, `svgImage`, `verticalSpace/horizontalSpace/borderRadius`, `localised/displayTranslatedText`, `debugPrintFullText`, `showLoadingDialog`, upload extension lists, years/months/days lists | top-level functions/vars | go_router, flutter_svg, encrypt_decrypt_plus, dart:html | mixed (helpers generic, globals not) |
| packages/core/lib/core/util/resources/extensions_manager.dart | extensions + helpers | `DateTime.yMd/d/dayOfWeek/dateAndTime/isSameDay`, `num.toPrecision/.w/.h/.rw/.rh/.rSp`, `String.toIconData()/toNormalizedDate()`, `String?/List?.isNullOrEmpty`, `Iterable.mapIndexed`, `Map.addIfNotNullOrEmpty`, `ScreenSizes`, `ScaleSize`, `getResponsiveFontSize`, `replaceArabicNumbers`, `CustomTextInputFormatter.numbersWithDashesFormatterWithLTR/fractionsWithArabicSupport/formattedIMO/decimalWithArabicSupport/numbersWithSlashesAndYearFormatter/usNumberFormatter/uppercaseLettersAndDigitsFormatter`, `addLtrMarkText`, `parseDouble`, `localPrint`, `showUSBToken` | intl, AppBloc | mostly generic |
| packages/core/lib/core/util/resources/validations.dart | validators | `emptyValidation, validateEmail, validateMobileNumber, validateFullName, validateNationalID, validateExpiryDate, validatePassportNumber, validateFactoryNumber, validateUsername, validatePassword, validatePasswordConfirmation, validateTaxNumber(NoInput), validateCaptainName, dateMissPartValidation, dateBeforeNowValidation, dateBeforeDateValidation(WithHours), getDaysInMonth, validateDayMonthMismatch, validateEmptyField, validateIMO, validationErrorMessageWith(out)CamelCases` | intl, AppBloc, SystemDialog | semi (country rules) |
| packages/core/lib/core/util/resources/routes_manager.dart | route path constants | `Routes.*` (141) | constants_manager | app-specific |
| packages/core/lib/core/util/resources/animated_navigation.dart | page transition + history control | `SlideFromRightPageRoute`, `navigateAndFinish`, `startListening`, `stopListening` | go_router, dart:html | transition generic |
| packages/core/lib/core/util/resources/colors_manager.dart | color tokens | `ColorsManager.*` | — | generic |
| packages/core/lib/core/util/resources/font_manager.dart | font families/weights | `FontConstants`, `FontWeightManager` | — | generic |
| packages/core/lib/core/util/resources/date_formatter.dart | date formatting | `DateFormatter.format`, `formatStringDate` | intl | generic |
| packages/core/lib/core/util/resources/debounce.dart | debouncer | `Debounce.run` | dart:async | generic |
| packages/core/lib/core/util/resources/bloc_observer_manager.dart | bloc logging | `MyBlocObserver` | bloc | generic |
| packages/core/lib/core/util/resources/app_assets.dart | SVG path constants | `AppAssets.*` | — | app-specific |
| packages/core/lib/core/util/resources/assets.gen.dart | flutter_gen output (generated) | `Assets.images...` | — | generated |
| packages/core/lib/core/util/resources/translation_manager.dart | legacy TranslationModel (522 lines) | fields | — | dead |
| packages/core/lib/core/util/resources/setting_items.dart | `SettingsItem(title, icon)` | — | equatable | generic (unused) |
| packages/core/lib/core/util/generalFunctions/custom_date_format.dart | date picker → formatted string | `getDateWithFormat`, `changeDateFormat` | intl | generic (locale fixed 'ar') |
| packages/core/lib/core/util/generalFunctions/redirect_launch.dart | mailto with clipboard fallback | `RedirectLaunch.launchMailClient` | url_launcher | generic |
| packages/core/lib/core/util/configuration_files/aci_configuration_file.dart, dex_configuration_file.dart | business IDs/code lists | consts | — | app-specific |
| packages/core/lib/core/util/enums/employees.dart | `Employees` enum | — | — | app-specific |
| packages/pam/lib/features/auth/login/presentation/controller/login_cubit.dart | auth + USB-token iframe/postMessage | `logIn, sendCode, resetPassword, sendUserName, loginWithToken, showIframeDialog, listenerToken, stopListening, show*Dialog, getLoginErrorMessage` | dart:html, ui_web | app-specific |

---

## 5. Widgets catalog

All reusable widgets live in `packages/core/lib/core/util/widgets/` (feature packages only contain screen-specific widgets; the only generic-looking one is `packages/dit/lib/features/documents/presentation/components/save_button.dart`).

| Path | Purpose | Constructor params | Generic? |
|---|---|---|---|
| buttons/custom_button.dart | primary filled button, icon before/after, 150 ms static throttle | onPressed*, title, icon, iconSize, iconWidget, iconFirst, iconColor, textColor, buttonColor, borderColor, borderWidth, borderRadius, height, width, fontSize, shadowColor, widget, margin, padding | y |
| buttons/custom_text_button.dart | text/link button | onPressed*, title*, textColor, icon, iconFirst, iconSize, fontSize, fontWeight, align, mainAxisSize, padding | y |
| buttons/custom_icon_button.dart | round icon button + tooltip | onPressed*, icon, svg, color, toolTip | y |
| buttons/lang_btn.dart | ar/en switch (flag + label) | isInDrawer | n |
| back_button.dart | back button | function* | y |
| texts/custom_text.dart | text family (CustomText, DefaultHeadlineText1-6, HeaderText, BodyText, TitleText, DisplayText, LabelText) | title*, align, color, letterSpacing, fontWeight, fontSize, maxLines, decoration, decorationColor, shadowColor, softWrap, lineHeight | y |
| texts/custom_selectable_text.dart | selectable text | as CustomText | y |
| texts/custom_text_field.dart | labelled form field with required mark, tooltip, server error, Semantics | controller*, hint*, title, isRequired, validate, errorMessage, suffix, maxLines, maxLength, hideMaxLength, inputFormatters, keyboardType, readOnly, obscureText, onChanged, onTap, onSubmitted, toolTibMessage, toolTibBesideField, toolTipIconHeight, inputBorder, borderRadius(Value), contentPadding, padding, fontSize, hintColor, disableColor, titleColor, titleFontWeight, titleHeightSpace, transparentBorderColor | y |
| texts/custom_attachment_text_field.dart | file-attach field (picker, name, delete) | onSelectedDoc*, title, hint, suffix, isRequired, toolTibMessage, toolTibBesideField | y |
| texts/main_title.dart | title + subtitle | title*, subTitle* | y |
| check_box.dart | checkbox + Semantics | value*, onChange*, title* | y |
| customListCheckbox.dart | tri-state parent/children checkbox list | parent*, children*, onParentSelect*, onChildSelect*, parentValue, childrenValue, isExpanded, onCheckedParent, onCheckedChild, parent/childrenCheckboxColor, parent/childrenCheckboxScale, gap | y |
| dropDown/drop_list_pagination.dart | searchable, lazy-paginated single/multi dropdown | items*, title*, values, selectedValue, onChanged, onMultiSelectChanged, onSearchChange, dataFetcher, onDropdownOpened, onMultiSelectionDropdownOpened, validate, multiSelectionValidate, withTitle, required, isMultiSelection, searchByNameOrCode, shouldShowSearch, initializeSelectedValue, withBorder, toolTibMessage, colors, paddings, height, borderRadius, alignmentCenterValue | y |
| app_form/custom_dynamic_form_widget.dart | declarative form (FormItem rows, FieldType textField/dropdown/checkbox/widget) | formStructure*, title*, buttonTitle, onPressedButton, dismissTitle, dismissPressed, isDialog, withContainer, withDismissButton, withPressButton, withMargin, svgPath, iconWidget, suffix | y |
| dialogs/system_dialog.dart | status / action (confirm) / form dialogs, auto-close for status | static `show(context*, dialogStatus*, description, title, contentWidget, formStructure, submitText, dismissTitle, hasCancelButton, onSubmit, onDismiss, submitBtnColor, svgImagePath, svgColor, svgBackColor, autoCloseSeconds, width, isScrollable, padding)` | y |
| dialogs/progress_dialog.dart | full-screen loader dialog, `loadingPage()`, `PulsingLogo` | message | y |
| dialogs/custom_show_full_model_dialog.dart | read-only detail cards dialog | title*, cardsTitles*, cardsColumnsTitles*, cardsColumnsData*, cardsNumberOfColumns*, additionalWidget | y |
| dialogs/check_usb_token.dart | USB-token signing dialog | successFun*, failureFun*, buttonText, withoutToken | n |
| ../loading_files/main_loading.dart | 3-card skeleton list (card_loading + staggered scale/fade) | — | y |
| pagination.dart | pagination (mobile/desktop with ellipsis) | currentPage*, totalPages*, onChanged* | y |
| tables/main_table_widget.dart | ResponsiveTable: filters, sort, pagination, row actions, advanced search; legacy MainTableWidget | see summary (columns* + ~25 optional) | partly |
| menus/popup_menu_widget.dart | popup + nested hover sub-menus | title, widgets*, icon, titleWidget*, tableRowIndex*, children*, isNested*, nestedMenuWidth | y |
| containers/custom_default_container.dart | titled section card with back button/tooltip/suffix | title*, widget*, titleSize, toolTibMessage, titleRowSuffixWidget, imagePath, onTapBackButton, backPageButton, backButtonRadius, containerMargin, titlePadding, titleTextPadding, widgetPadding, clipBehavior, height, width, isDialog | y |
| containers/custom_shadow.dart | shadow card | child*, blurRadius, offsetX, offsetY, spreadRadius, borderRadius, color, height, width, padding, margin | y |
| containers/custom_expansion_container.dart | expandable section (+count) | title*, child*, widget, onChange, isEnabled, isExpanded, titleColor, withManifestNumber, totalNum | mostly |
| containers/custom_containers_list.dart | grid of selectable service tiles | mainTitle*, titleList*, isActiveButton*, icons, ids, withDialog, selectItem, listAlignment, titleClassNames, tooltip | y |
| containers/custom_container_item_builder.dart | single service tile | onTap*, isActiveButton*, icon*, title*, tooltip | y |
| custom_expantion_tile.dart | advanced-search expansion tile | title*, advancedButtonPressed*, advancedFormStructure*, initOpenExpansionPressed, closeExpansionPressed, canOpen | y |
| custom_padding.dart | LTRB padding helper | left, top, right, bottom, child* | y (not RTL) |
| custom_tooltip.dart | info tooltip | message*, height, child | y |
| steppers/custom_stepper_widget.dart | numbered step indicator | currentStep*, titles*, alignString | y |
| steppers/secondary_stepper_widget.dart | segmented tab bar | titles*, currentIndex*, selectTap, classNames | y |
| stepper.dart | register/manifest stepper | route*, stepsTitles* | n |
| success_widget.dart | success result block | title*, body*, additionalText | y |
| notification.dart | notification badge bell | notificationNumber*, colorIcon | n |
| navs/default_scaffold.dart | scaffold with responsive end drawer | body* | n |
| navs/main_design.dart | web page shell (nav + breadcrumb + body + footer) | titles*, routes*, widget*, titleWidgetReplacement, aciRequestId, invoiceId | partly |
| navs/navigation_bar.dart | top nav bar, app bar, drawer, hover menu | route / isArabic*, navigateTo* / isLoggedIn | n |
| navs/nav_title_widget.dart | breadcrumb | titles*, routes*, aciRequestId, invoiceId | partly |
| navs/page_title_footer.dart | page footer title | title*, subTitle* | y |
| footer/footer.dart | site footer | — | n |
| constants_manager.dart `defaultAppBar()` | simple AppBar builder | title*, context*, actions, color, fontColor, onPressed | y |

(`*` = required)

There are no shimmer-on-image, network image, empty-state, toast/snackbar or pull-to-refresh widgets. Empty/no-data is handled inline in the tables (a hardcoded "No Data Found" and an `emptyListIcon` SVG).

---

## 6. Packages (root `pubspec.yaml`; every sub-package repeats nearly the same list)

| Role | Packages |
|---|---|
| State | flutter_bloc ^8.1.6, bloc ^8.1.4, equatable ^2.0.5 |
| DI | get_it ^7.7.0 |
| Routing | go_router ^14.6.1, flutter_web_plugins (sdk) |
| Network | dio ^5.7.0, connectivity_plus ^6.0.4 (unused), cookie_wrapper ^0.1.2 |
| Result/FP | dartz ^0.10.1 |
| Storage | hive ^2.2.3, hive_flutter ^1.1.0, sqflite ^2.4.0 (helper unused), shared_preferences ^2.3.2 (unused), path_provider ^2.1.4 (unused) |
| L10n | intl ^0.19.0, flutter_localizations (via MaterialApp delegates; not declared in pubspec), flutter_localization ^0.3.1 (unused) |
| UI / layout | flutter_bootstrap5 ^1.1.1+1, google_fonts ^6.2.1, flutter_svg ^2.0.10+1, font_awesome_flutter ^10.7.0, dotted_border ^2.1.0, just_the_tooltip ^0.0.12, awesome_dialog ^3.2.1, dropdown_search ^6.0.1, pin_code_fields ^8.0.1, card_loading ^0.3.2, flutter_staggered_animations ^1.1.1, cupertino_icons; unused: lottie, carousel_slider, dropdown_button2, multi_dropdown, easy_stepper, number_pagination, scroll_date_picker, syncfusion_flutter_sliders, loading_indicator, card_actions, material_color_gen |
| Tables | unused: data_table_2 ^2.5.15, pluto_grid_plus ^8.4.14, syncfusion_flutter_datagrid ^29.1.41 (custom ResponsiveTable used instead) |
| Media / files | file_picker ^8.1.2, syncfusion_flutter_pdfviewer ^29.1.41, archive ^3.6.1; unused: flutter_dropzone, image_picker_for_web, excel, fwfh_cached_network_image |
| Permissions | permission_handler ^11.0.1, permission_handler_web ^0.0.2 (both unused) |
| Utils | url_launcher ^6.3.0, encrypt_decrypt_plus ^1.5.0 (XOR), js ^0.7.1 (unused), flutter_gen ^5.7.0, icons_launcher ^2.1.7 (dev tool listed in dependencies) |
| Firebase | none |
| Dev | flutter_test, mockito ^5.4.4, test ^1.17.12, build_runner ^2.4.11, hive_generator ^2.0.1, flutter_lints ^4.0.0 |

About 24 direct dependencies are never imported from Dart code.

---

## 7. Quality notes

- **Null safety:** yes (Dart ≥ 3.3). Translation lookups (`translationData['x']`) return `dynamic`/null and are passed straight into non-null `String` params, so a missing key is a runtime error.
- **Lints:** `analysis_options.yaml` in the root and in each package only `include: package:flutter_lints/flutter.yaml`, with no extra rules. Only 2 `ignore_for_file`.
- **Tests:**
  - Real: `packages/pam/test/login/` (`login_use_case_test.dart`, `login_repo_implementation_test.dart`, `login_remote_data_source_test.dart`, mockito `Mock` subclasses).
  - Broken: `test/widget_test.dart` is the counter template pumped against `SizedBox()`, so it would fail.
  - Empty or commented out: `test/mocks.dart`, `packages/{aci,dex,dit,manifest}/test/*`, `packages/{core,pam}/test/pam_test.dart`.
  - `packages/pam/coverage/lcov.info` is committed.
- **Architecture smells:**
  - circular package graph; `core` knows every feature
  - one 985-line DI file and one 1,327-line `main.dart`
  - god `AppBloc` and global mutable state in `constants_manager.dart`, which also carries leftovers from an unrelated fitness app
  - all cubits are singletons
  - 1–1.7k-line cubits and screens
- **Network smells:** see §3.4 — shared mutable Dio options, the catch-all that swallows status codes, copy-pasted method bodies, no interceptors, a trust-all `HttpOverrides`.
- **Duplication:**
  - `builder` + `pageBuilder` repeated in all 75 routes
  - repository try/catch per method (about 15 repos)
  - the five Dio method bodies
  - two copies of `showUSBToken` (AppBloc and extensions_manager) and two `showIframeDialog`s (LoginCubit and check_usb_token.dart)
  - `awesome_dialog` used alongside `SystemDialog`
  - three unused table packages next to a custom table
- **Deprecated / legacy APIs:**
  - `Color.withOpacity` ×30
  - `ColorScheme.background/onBackground`
  - `dart:html` ×28 and the `js` package (both deprecated in favor of `package:web`/`dart:js_interop`; they block Wasm builds)
  - `ui.platformViewRegistry` from `dart:ui` (should come from `dart:ui_web`)
  - Already modern: `WidgetStatePropertyAll`, `PopScope` (2 uses), and `Row(spacing:)` (needs Flutter ≥ 3.27).
- **Hardcoded values:** colors outside the palette (141); some Arabic and English UI literals; a fixed `locale: Locale('ar')` in the date picker; a fixed logo asset path in `PulsingLogo`.
- **Security:**
  - The session token and user data sit in sessionStorage behind a reversible XOR whose key is a constant in source.
  - Request headers, including the bearer token, are logged on localhost.
  - A commented-out third-party API key remains in `location_service.dart`.
- **Dead code:**
  - vendored `lib/src` bootstrap copy (41 files)
  - `TranslationModel`
  - `RepoImplementation`
  - `DBImpl`
  - commented `LocationService`
  - `lightTheme`/`darkTheme`
  - unused `assets/translations`
  - many commented-out routes and functions
- **Naming:** folder `presentaion`; files `add_company_representative _entity.dart` (contains a space), `edti_dit_requests.dart`, `servies.dart`, `aci_base_rebository.dart`, `custom_expantion_tile.dart`; method `copyWidth` (should be `copyWith`).
- **Worth carrying into the template (after rework):**
  - SystemDialog facade
  - field-error mapping from the API `errors` map
  - translated API message keys
  - paginated dropdown fetch contract
  - DynamicForm
  - ColorsManager tonal scale
  - Semantics identifiers for web test automation
  - Arabic-digit / LTR input formatters
  - the CustomTransitionPage helper
  - the Docker/CI web deployment recipe
  - the per-domain package split, rebuilt with a one-way graph: `core` ← features ← app, with DI registration per package
