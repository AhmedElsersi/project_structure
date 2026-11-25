# Shared widgets and screens

Everything in `flutter_template/lib/shared/`. Each entry gives the purpose, the key parameters
(from the real constructors), a usage example and the source projects. Before you write a new
widget, check here: a feature should compose these, not re-create them.

Rules that apply to every widget here ([CONVENTIONS.md](CONVENTIONS.md)):
- **Texts come in already translated.** Callers pass `LocaleKeys.x.tr()`. Built-in defaults
  ("Cancel", "Try again") come from `common.*`, `states.*` and `widgets.*`.
- Styles come from the theme. Colours come from `colorScheme` / `context.palette`. Spacing comes
  from `AppSpacing` / `AppRadii` / `AppSizes`. Layout is RTL-safe and survives the 1.3 app text
  scale at 320 px. `test/shared/widgets/layout/overflow_matrix_test.dart` checks this in Arabic and
  English across `kLayoutMatrix`.

| Group | Widgets |
|---|---|
| [Buttons](#buttons) | `AppButton` |
| [Inputs](#inputs) | `AppTextField`, `AppPasswordField`, `AppEmailField`, `AppOtpField`, `AppSearchField`, `AppDropdown<T>`, `AppDateField`, input formatters |
| [Feedback](#feedback) | `AppSnackBar`, `showConfirmDialog`, `showTypedConfirmDialog`, `showAppBottomSheet`, `LoadingOverlay` |
| [States](#states) | `DataStateBuilder<T>`, `LoadingView`, `EmptyView`, `ErrorView`, `StateMessage`, `AppSkeleton`, `SkeletonList`, [`OfflineBanner`](#offline-banner) |
| [Layout](#layout) | `AppScaffold`, `MaxWidthBody`, `ScrollableFormBody`, `AdaptiveRow`, `SectionHeader`, `AdaptiveNavigationShell`, `AdaptiveTwoPane` |
| [Lists](#lists) | `PaginatedListView<T>`, `NavTile` |
| [Media](#media) | `AppNetworkImage`, `ImageViewerScreen`, `showImageSourceSheet` |
| [Display](#display) | `AppCard`, `StatusChip`, `AppAvatar` |
| [Guards](#guards) | `DirtyGuard` |
| [Settings](#settings) | `LanguageSelector`, `ThemeModeSelector` |
| [Screens](#screens) | `SplashScreen`, `HomeShell`, `SettingsScreen`, `NotFoundScreen`, `ConfigErrorApp` |
| [App gate](#app-gate) | `AppConfigGate`, `MaintenanceView`, `ForceUpdateView`, `OptionalUpdateSheet`, `GateLayout` |
| [Permissions flow](#permissions-flow) | `ensurePermission`, `SettingsPromptThrottle`, `AppPermissionText` |

Dropped on purpose (COMPARISON §2, D2–D4, D13): custom app bars and back buttons (use `AppBar` from
`appBarTheme`), overlay toasts, `DynamicDropdownFormField`, `ContainerWithShadow`, `CustomChip`,
`CustomRadioGroup`, `ExpandableContainer` and similar. Use themed Material widgets instead.

---

## Buttons

### AppButton

`buttons/app_button.dart` — the app's button: a thin wrapper over the **themed** Material buttons,
with a busy state that keeps the button's size and blocks repeat taps.

| Param | Type | Default | Notes |
|---|---|---|---|
| `label` | `String` | required | Translated. Up to 2 lines, then ellipsis |
| `onPressed` | `VoidCallback?` | required | `null` disables |
| `variant` | `AppButtonVariant` | `filled` | `filled`, `tonal`, `outlined`, `text`, `danger` (error colours: the only per-widget style override) |
| `icon` | `IconData?` | | Leading icon |
| `busy` | `bool` | `false` | Spinner inside the same button. The label keeps its space and taps are ignored. Screen readers hear "Loading…" |
| `expand` | `bool` | `false` | Full width (form submit) |

```dart
AppButton(
  label: LocaleKeys.common_save.tr(),
  onPressed: state.isValid ? cubit.submit : null,
  busy: state.isSaving,
  expand: true,
)
AppButton(label: LocaleKeys.common_delete.tr(), variant: AppButtonVariant.danger, icon: Icons.delete_outline, onPressed: _delete)
```

You may also use `FilledButton` / `OutlinedButton` / `TextButton` directly. They are themed. Never
pass `style:` except for a documented variant.

Sources: markspulse `core/widgets/input/busy_button.dart` (busy keeps width); lexa-control
`app_primary_button.dart` (icon, destructive, expand); corsa-customer `app_default_button.dart`
(one widget + variant enum).

---

## Inputs

All inputs read `inputDecorationTheme`, take translated `label` / `hint` / `helper`, and accept a
server `errorText` (e.g. `failure.fieldError('email')`) that is shown **before** the local
validator until the user edits the field.

### AppTextField

`inputs/app_text_field.dart` — the one text field for every form.

| Param | Notes |
|---|---|
| `controller` / `initialValue`, `focusNode` | |
| `label`, `hint`, `helper` | Translated |
| `validator` | `FormFieldValidator<String>`. Runs **on blur** once the user has typed, then on every edit while an error is visible. `Form.validate()` still works |
| `errorText` | Server error for this field |
| `keyboardType`, `textInputAction`, `textCapitalization`, `autofillHints` | |
| `obscureText` | Adds a show/hide button on the **end** side (left in Arabic). The revealed state is never remembered |
| `prefixIcon` (`IconData?`), `suffix` (`Widget?`) | `suffix` is ignored when `obscureText` |
| `maxLines` (1), `minLines`, `maxLength` | `maxLength` without a counter |
| `inputFormatters` | Applied after digit folding |
| `enabled`, `readOnly`, `autofocus`, `onTap`, `onChanged`, `onSubmitted` | |
| `forceLtr` | Typed text is LTR (emails, phones, codes, numbers). The label follows the UI |
| `normalizeDigits` (`bool?`) | Fold ٠-٩ / ۰-۹ to 0-9. `null` = automatic for number/phone keyboards and `forceLtr` |
| `textAlign` | `TextAlign.start` |

Tapping outside closes the keyboard. Autocorrect and suggestions are off for passwords and emails.
`GlobalKey<AppTextFieldState>().currentState!.validate()` validates a single field.

```dart
AppTextField(
  controller: _title,
  label: LocaleKeys.items_title.tr(),
  textInputAction: TextInputAction.next,
  validator: Validators.compose([Validators.required(), Validators.maxLength(80)]),
  errorText: failure is ValidationFailure ? failure.fieldError('title') : null,
)
AppTextField(
  label: LocaleKeys.profile_phone.tr(),
  keyboardType: TextInputType.phone,
  forceLtr: true,
  validator: Validators.phone(),
)
```

Sources: corsa-customer `app_text_form_field.dart` (one field, autofill, actions); markspulse
`app_text_field.dart` (validate on blur, reveal toggle on the end side, digit folding); petrobe
(`externalError` → `errorText`); lexa-student (`forceLtr`).

### AppPasswordField

`inputs/app_password_field.dart` — an `AppTextField` preset: obscured, reveal toggle, lock icon,
`visiblePassword` keyboard, `password` autofill hint.

| Param | Notes |
|---|---|
| `controller`, `focusNode`, `label`, `hint`, `helper`, `validator`, `errorText`, `textInputAction`, `onChanged`, `onSubmitted`, `enabled` | Same as `AppTextField` |
| `isNewPassword` | `newPassword` autofill hint (sign-up / change password) so password managers offer to generate one |
| `prefixIcon` | `Icons.lock_outline` |

```dart
AppPasswordField(
  controller: _password,
  label: LocaleKeys.auth_password.tr(),
  isNewPassword: true,
  validator: Validators.compose([Validators.required(), Validators.password()]),
)
```

Sources: markspulse `app_text_field.dart`; corsa-customer (autofill).

### AppEmailField

`inputs/app_email_field.dart` — an `AppTextField` preset: email keyboard, `forceLtr`, digits folded,
`email` autofill, no autocorrect. Params are like `AppPasswordField`, plus `readOnly`.
`textInputAction` defaults to `next` and `prefixIcon` to `Icons.alternate_email`.

```dart
AppEmailField(controller: _email, label: LocaleKeys.auth_email.tr(), validator: Validators.compose([Validators.required(), Validators.email()]))
```

Sources: lexa-student (`forceLtr`); markspulse (no autocorrect); corsa-customer (autofill).

### AppOtpField

`inputs/app_otp_field.dart` — N digit boxes over one invisible native `TextField`, so SMS autofill
(`oneTimeCode`), paste and the keyboard all work natively. It is always LTR, folds digits, and the
boxes shrink to fit narrow widths and grow with the text scale.

| Param | Default | Notes |
|---|---|---|
| `length` | `6` | |
| `controller`, `onChanged` | | |
| `onCompleted` | | Fires when all boxes are filled |
| `autofocus` | `true` | |
| `enabled` | `true` | |
| `errorText` | | Translated; boxes turn red |
| `semanticLabel` | "Verification code" | |

```dart
AppOtpField(length: 6, onCompleted: cubit.verify, errorText: state.failure?.displayMessage)
```

Sources: corsa-customer `otp_form_field.dart`; tebbr (digit folding).

### AppSearchField

`inputs/app_search_field.dart` — a search input with a debounced `onChanged` and a clear button.

| Param | Default | Notes |
|---|---|---|
| `onChanged` | | Debounced. Clearing calls it with `''` immediately |
| `debounce` | 350 ms | `Duration.zero` = no debounce |
| `onSubmitted` | | Immediate (cancels the pending debounce) |
| `hint` | "Search" | |
| `readOnly` + `onTap` | | Turns it into a button ("open the search screen") |
| `trailing` | | Shown while empty (e.g. a filter button) |
| `controller`, `focusNode`, `autofocus` | | |

```dart
AppSearchField(hint: LocaleKeys.items_search_hint.tr(), onChanged: context.read<ItemsListCubit>().search)
```

Sources: corsa-customer `app_search_field.dart` (Timer-based debounce cancelled on dispose is new).

### AppDropdown

`inputs/app_dropdown.dart` — `AppDropdown<T>` over `DropdownButtonFormField` (uses
`initialValue`, never the deprecated `value`).

| Param | Notes |
|---|---|
| `items` (`List<T>`), `labelOf` (`String Function(T)`), `onChanged` (`ValueChanged<T?>?`) | required. `onChanged: null` disables |
| `initialValue` | Read once; give the widget a new `key` to reset it from outside |
| `label`, `hint`, `helper`, `validator` (`FormFieldValidator<T>`), `errorText`, `prefixIcon`, `enabled` | |
| `isExpanded` | `true`: fill the width and ellipsize items |
| `itemBuilder` | Custom menu row |

```dart
AppDropdown<ItemStatus>(
  label: LocaleKeys.items_status.tr(),
  items: ItemStatus.values,
  labelOf: (s) => s.labelKey.tr(),
  initialValue: state.status,
  onChanged: (s) => cubit.setStatus(s!),
  validator: (s) => s == null ? LocaleKeys.validation_required.tr() : null,
)
```

Sources: lexa-control `app_dropdown.dart` (generic); markspulse (errorText, null disables).
Dropped: `DynamicDropdownFormField` (D3).

### AppDateField

`inputs/app_date_field.dart` — a read-only form field that opens `showDatePicker` and shows the
date with `DateFormat.yMMMd` in the current locale (Western digits).

| Param | Notes |
|---|---|
| `value` (`DateTime?`), `onChanged` (`ValueChanged<DateTime>`) | required |
| `firstDate`, `lastDate` | Default ±100 years |
| `label`, `hint` ("Choose a date"), `helper`, `helpText` (picker title) | |
| `validator` (`FormFieldValidator<DateTime>`), `errorText`, `enabled` | Validates the `DateTime`, not the text |
| `format` (`String Function(DateTime, String locale)?`), `selectableDayPredicate` | |

```dart
AppDateField(
  label: LocaleKeys.items_due_date.tr(),
  value: state.dueDate,
  firstDate: DateTime.now(),
  onChanged: cubit.setDueDate,
)
```

There is no shared time field. Use `showTimePicker` with an `AppTextField(readOnly: true, onTap:)`
following the same pattern.

Sources: lexa-control `app_date_picker_field.dart`; markspulse and chinaparts-seller date fields.

### Input formatters

`lib/core/utils/input_formatters.dart`:
- `DigitsNormalizerFormatter()` folds Arabic-Indic and Persian digits as typed or pasted. Put it
  first.
- `DecimalInputFormatter({decimalPlaces = 2, allowNegative = false})` allows one separator (`.`,
  `,` or `٫`) and rejects invalid edits. Parse with `DecimalInputFormatter.tryParse(text)`.

```dart
AppTextField(
  label: LocaleKeys.items_price.tr(),
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  forceLtr: true,
  inputFormatters: const [DecimalInputFormatter(decimalPlaces: 2)],
)
```

Sources: chinaparts-seller `decimal_input_formatter.dart`; tebbr phone digit folding; markspulse
`WesternDigitsFormatter`.

---

## Feedback

### AppSnackBar

`feedback/app_snackbar.dart` — themed snackbars, with or without a `BuildContext` (through the
global `AppSnackBar.messengerKey`, already wired into `MaterialApp.router`). Each call hides the
current bar first. Colours come from the tone's container/on-container pair.

| Method | Tone / duration |
|---|---|
| `show(message, {context, icon, duration})` | neutral (inverse surface), 4 s |
| `success(message, {context})` | success, 4 s |
| `info(message, {context})` | info, 4 s |
| `error(Failure, {context})` | danger, 6 s. Shows `failure.displayMessage`; **ignores `CancelledFailure`** |
| `errorMessage(message, {context})` | danger, 6 s |
| `undo(message, {required onUndo, context, duration = 8 s})` | Undo button + draining countdown line |
| `hide({context})` | |

```dart
BlocListener<CreateItemCubit, CreateItemState>(
  listenWhen: (a, b) => a.failure != b.failure && b.generalFailure != null,
  listener: (context, state) => AppSnackBar.error(state.generalFailure!, context: context),
  child: ...,
)
AppSnackBar.undo(LocaleKeys.items_deleted.tr(), onUndo: () => cubit.restore(item));
```

Sources: baytna `core/widgets/app_snackbar.dart` (one helper, Failure-aware, undo countdown);
lexa-control `app_snack_bar.dart` (container pairs, longer error durations). Dropped: overlay
`ToastManager` (D2).

### showConfirmDialog / ConfirmDialog

`feedback/confirm_dialog.dart` — a yes/no dialog that resolves to `bool`. It is `true` only when
confirm is pressed; the barrier and back give `false`. It opens on the root navigator, above the
tab shell.

| Param | Default |
|---|---|
| `title` | required |
| `message` | |
| `confirmLabel`, `cancelLabel` | "Confirm", "Cancel" |
| `destructive` | `false` (confirm becomes `AppButtonVariant.danger`) |
| `icon` | |

```dart
final ok = await showConfirmDialog(
  context,
  title: LocaleKeys.items_delete_title.tr(),
  message: LocaleKeys.items_delete_message.tr(),
  confirmLabel: LocaleKeys.common_delete.tr(),
  destructive: true,
);
if (ok) await cubit.delete(item.id);
```

Sources: chinaparts-customer `confirm_dialog.dart` q5; baytna `app_dialog.dart`; lexa.

### showTypedConfirmDialog / TypedConfirmDialog

`feedback/typed_confirm_dialog.dart` — for destructive actions with no undo (delete account, wipe
data). Confirm stays disabled until the user types `confirmWord` (trimmed, case-insensitive, any
digit script).

| Param | Default |
|---|---|
| `title`, `confirmWord` | required |
| `message` | |
| `consequence` | Plain-language box in the warning/danger tone ("All 42 items will be deleted for everyone") |
| `confirmLabel`, `cancelLabel` | "Confirm", "Cancel" |
| `destructive` | `true` |

```dart
final ok = await showTypedConfirmDialog(
  context,
  title: LocaleKeys.profile_delete_account.tr(),
  confirmWord: LocaleKeys.profile_delete_word.tr(),
  consequence: LocaleKeys.profile_delete_consequence.tr(),
);
```

Sources: baytna `typed_confirmation_dialog.dart`; lexa-control.

### showAppBottomSheet / AppSheetBody

`feedback/app_bottom_sheet.dart` — the one way to open a sheet. It is a modal bottom sheet on
phones and a centred dialog on tablets and unfolded foldables. It uses the root navigator, lifts
above the keyboard, is capped at 90 % of the height and at `sheetMaxWidth` / `dialogMaxWidth`
(640 / 560) from the theme, and shows a title row with a close button outside the scroll view.

| Param | Default | Notes |
|---|---|---|
| `builder` | required | Content |
| `title` | | Translated; shows the header with a close button |
| `isDismissible` | `true` | Also controls drag and the close button |
| `scrollable` | `true` | `false` when the content has its own scroll view |

`AppSheetBody({required child, title, showClose = true, scrollable = true})` is the layout, for
custom routes.

```dart
final status = await showAppBottomSheet<ItemStatus>(
  context,
  title: LocaleKeys.items_filter.tr(),
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final s in ItemStatus.values)
        ListTile(title: Text(s.labelKey.tr()), onTap: () => Navigator.of(context).pop(s)),
    ],
  ),
);
```

Sources: corsa-customer `show_app_bottom_sheet.dart` q5 (dialog on tablets, root navigator,
keyboard insets); baytna `app_bottom_sheet.dart` q5 (handle, title, pinned close); chinaparts-seller
(640 cap).

### LoadingOverlay

`feedback/loading_overlay.dart` — a blocking "please wait" dialog around a future. It always closes
(try/finally), nested calls share one overlay, back is disabled, and it removes exactly its own
route even if something was pushed above it.

| API | |
|---|---|
| `LoadingOverlay.run<T>(context, future, {message})` | Returns the future's value; rethrows its error |
| `LoadingOverlay.isShowing` | |

```dart
final result = await LoadingOverlay.run(context, repository.export(), message: LocaleKeys.items_exporting.tr());
```

Prefer an in-place busy state (`AppButton.busy`, `AppScaffold.busy`). Use this only when the whole
screen must be blocked.

Sources: petrobe `show_loading_dialog.dart` (own route/context, re-entrancy safe).

---

## States

### DataStateBuilder

`states/data_state_builder.dart` — renders a [`DataState<T>`](SERVICES.md#cubit-bases). Data stays
on screen while refreshing and after a failed refresh.

| State | Shows |
|---|---|
| initial / loading, no data | `loading` or `LoadingView` |
| failure, no data | `ErrorView` + retry |
| loading or failure **with** data | `builder` (old data stays) |
| success, `isEmpty(data)` or null | `empty` or `EmptyView` |
| success | `builder` |

| Param | |
|---|---|
| `state`, `builder` (`Widget Function(BuildContext, T)`) | required |
| `loading` (`WidgetBuilder?`) | e.g. `(_) => const SkeletonList()` |
| `isEmpty` (`bool Function(T)?`), `empty` (`Widget?`) | |
| `onRetry` | |

```dart
BlocBuilder<ItemDetailsCubit, DataState<Item>>(
  builder: (context, state) => DataStateBuilder<Item>(
    state: state,
    onRetry: context.read<ItemDetailsCubit>().load,
    loading: (_) => AppSkeleton(child: ItemDetailsView(item: Item.placeholder())),
    builder: (context, item) => ItemDetailsView(item: item),
  ),
)
```

Show a failed refresh with a snackbar from a `BlocListener`.

Sources: corsa-customer `base_fetching_widget.dart` (`GenericFetchWidget` q5); chinaparts-seller
(skeleton over the real layout).

### LoadingView

`states/loading_view.dart` — a centred spinner. `LoadingView({message, compact = false})`.
`compact` is a small spinner with no text (list footers).

```dart
const LoadingView(compact: true)
```

Sources: corsa-customer `BaseLoadingWidget`; markspulse, lexa (screen-reader label).

### EmptyView and StateMessage

`states/empty_view.dart` — the "Nothing here yet" view. It is centred, width-capped and scrolls, so
it never overflows.

| `EmptyView` param | Default |
|---|---|
| `icon` | `Icons.inbox_outlined` |
| `title`, `message` | `states.empty_title`, `states.empty_message` |
| `actionLabel` + `onAction` | Tonal button when both are set |
| `compact` | Smaller, for cards/sections |

`StateMessage({required icon, required title, message, actionLabel, onAction, actionIcon, compact, iconColor, iconBackground})`
is the shared layout behind `EmptyView` and `ErrorView`.

```dart
EmptyView(
  icon: Icons.inventory_2_outlined,
  title: LocaleKeys.items_empty_title.tr(),
  message: LocaleKeys.items_empty_message.tr(),
  actionLabel: LocaleKeys.items_create.tr(),
  onAction: () => context.push(ItemsRoutes.create),
)
```

Sources: baytna `app_empty_state.dart`; corsa-customer `BaseEmptyWidget` (scrolls, compact).

### ErrorView

`states/error_view.dart` — a full-area (or `compact` one-row) error with retry. It shows
`failure.displayMessage`, never raw text. The icon follows the failure type (offline, timeout, not
found, lock).

| Param | |
|---|---|
| `failure` | |
| `message` | Translated; wins over `failure` |
| `title` | "Couldn't load this" |
| `onRetry` | "Try again" button |
| `compact` | Row for list footers ("couldn't load more · Try again") |

```dart
ErrorView(failure: state.failure, onRetry: cubit.load)
```

Sources: corsa-customer `BaseErrorWidget`; baytna (shares the empty-state layout); markspulse
`error_view.dart`.

### AppSkeleton and SkeletonList

`states/app_skeleton.dart` — skeletons via skeletonizer in theme colours. Under reduced motion the
shimmer becomes a solid colour.

| Widget | Params |
|---|---|
| `AppSkeleton` | `child`, `enabled = true`. Best over the **real** widget built with placeholder data |
| `SkeletonList` | `itemCount = 6`, `itemBuilder` (skeletonize your real tile), `padding` |

```dart
AppSkeleton(enabled: state.isLoading, child: ItemTile(item: state.data ?? Item.placeholder()))
SkeletonList(itemBuilder: (_, _) => ItemTile(item: Item.placeholder()))
```

Sources: corsa-customer `app_skeletons.dart`; chinaparts-seller (skeleton over a mock model).
Rejected: shimmer (baytna), decision C8.

### Offline banner

`states/offline_banner.dart` — `OfflineBanner({required child, backOnlineDuration = 3 s})`, a slim
app-wide bar under the status bar while offline, then a brief "You're back online". It overlays
the app in a `Stack` and does not wrap it, so the router and screens never rebuild. It needs a
`ConnectivityCubit` above it. The app root already places it in `MaterialApp.builder`, so screens
do nothing.

```dart
// lib/app.dart (already wired)
AppConfigGate(onOpenStore: ..., child: OfflineBanner(child: child ?? const SizedBox.shrink()))
```

For a screen that can't work offline, read `ConnectivityCubit` and show an `ErrorView` (see
[SERVICES.md#connectivity](SERVICES.md#connectivity)).

Sources: baytna `offline_banner.dart` (one bar, cubit-driven); tebbr `no_internet_gate.dart` (Stack
over the app; tree stays alive).

---

## Layout

### AppScaffold

`layout/app_scaffold.dart` — the standard screen frame.

| Param | Default | Notes |
|---|---|---|
| `body` | required | Gets the full (capped) area |
| `title` | | Translated; one line with ellipsis |
| `actions`, `leading`, `floatingActionButton` | | |
| `bottomAction` | | Sticky area under the body (submit button), inside the safe area, above the keyboard |
| `busy` | `false` | 2 px progress bar under the app bar |
| `constrainWidth` | `true` | Centres body and bottom action at `context.maxContentWidth` (720 / 840 on tablets) |
| `padding` | horizontal `context.pageGutter` | |
| `showBackButton`, `showAppBar` | `true` | The back button is automatic and mirrors in RTL |

```dart
AppScaffold(
  title: LocaleKeys.items_create.tr(),
  busy: state.isSaving,
  bottomAction: AppButton(label: LocaleKeys.common_save.tr(), onPressed: _submit, busy: state.isSaving, expand: true),
  body: ScrollableFormBody(child: _fields()),
)
```

Sources: corsa-customer `default_screen.dart` q5 (max width, sticky action); markspulse
`app_scaffold.dart` q5 (busy bar, themed AppBar).

### MaxWidthBody

`layout/max_width_body.dart` — `MaxWidthBody({required child, maxWidth, alignment = topCenter})`
centres and caps width (default `context.maxContentWidth`). It is a pass-through on phones. Keep the
scrollable **inside** it.

```dart
MaxWidthBody(maxWidth: 560, child: ListView(children: ...))
```

Sources: chinaparts-customer `max_width_body.dart`; lexa `ContentWidthLimit`.

### ScrollableFormBody

`layout/scrollable_form_body.dart` — `ScrollableFormBody({required child, footer, padding, controller})`.
The content fills the viewport, the footer is pinned to the bottom when it fits, and everything
scrolls when it doesn't (keyboard, landscape, large text). Dragging dismisses the keyboard. Don't
put `Spacer`/`Expanded` directly in `child`.

```dart
ScrollableFormBody(
  child: Column(children: [AppEmailField(...), AppSpacing.gapMd, AppPasswordField(...)]),
  footer: AppButton(label: LocaleKeys.auth_sign_in.tr(), onPressed: _submit, expand: true),
)
```

Sources: chinaparts-customer `scrollable_form_body.dart` (a min-height Column instead of
IntrinsicHeight is new).

### AdaptiveRow

`layout/adaptive_row.dart` — a `Row` that becomes a `Column` when narrower than `minRowWidth` or
when the effective text scale reaches `stackAtTextScale` (1.2). Flexible children are unwrapped in
column mode.

| Param | Default |
|---|---|
| `children` | required |
| `spacing` | `AppSpacing.sm` |
| `minRowWidth` | `null` (text scale only) |
| `stackAtTextScale` | `1.2` |
| `forceColumn` | `false` |
| `mainAxisAlignment`, `crossAxisAlignment`, `columnCrossAxisAlignment` | `spaceBetween`, `center`, `stretch` |

```dart
AdaptiveRow(minRowWidth: 360, children: [
  Expanded(child: AppButton(label: LocaleKeys.common_cancel.tr(), variant: AppButtonVariant.outlined, onPressed: _cancel)),
  Expanded(child: AppButton(label: LocaleKeys.common_save.tr(), onPressed: _save)),
])
```

Sources: corsa-driver `adaptive_row.dart` q5.

### SectionHeader

`layout/section_header.dart` — `SectionHeader({required title, actionLabel, onAction, trailing, padding})`.
The title wraps to 2 lines and has heading semantics. The action is a `TextButton`, or pass a custom
`trailing`.

```dart
SectionHeader(title: LocaleKeys.home_recent.tr(), actionLabel: LocaleKeys.common_see_all.tr(), onAction: () => context.go(ItemsRoutes.list))
```

Sources: corsa-customer `section_header.dart`; markspulse `app_section.dart`.

### AdaptiveNavigationShell

`layout/adaptive_navigation_shell.dart` — top-level navigation that adapts to the window. Phones
get a bottom `NavigationBar`. Tablets get a `NavigationRail` on the **start** side (right in
Arabic). Large tablets in landscape get an extended rail. On an occluding vertical hinge the shell
stays on one screen.

| Param | |
|---|---|
| `currentIndex`, `onSelect` (`ValueChanged<int>`), `body` | required |
| `destinations` | `List<AdaptiveDestination>` (≥ 2): `AdaptiveDestination({required icon, required label, selectedIcon})` |

Used by `HomeShell` (see [Screens](#screens)). To add a tab, add a branch in `app_router.dart` and
a destination in `home_shell.dart` in the same order.

Sources: corsa-customer `adaptive_shell.dart` (bar ↔ rail, leading edge); decision C2 (foldables)
is new.

### AdaptiveTwoPane

`layout/two_pane.dart` — list/detail. One pane on phones and narrow widths; two panes when both can
be at least `minPaneWidth` wide (measured with `LayoutBuilder`, not the device). On a foldable it
splits exactly at the hinge: book posture gives start | end, tabletop gives top / bottom.

| Param | Default |
|---|---|
| `primary` (list), `secondary` (detail) | required |
| `minPaneWidth` | `320` |
| `primaryFraction` | `0.4` |

```dart
AdaptiveTwoPane(
  primary: ItemsList(onSelect: cubit.select),
  secondary: state.selectedId == null
      ? EmptyView(title: LocaleKeys.items_pick_one.tr())
      : ItemDetailsPane(id: state.selectedId!),
)
```

For list/detail, navigate to the details route when only one pane fits. The sample
`ItemDetailsScreen` stacks image and info on phones (`context.isPhone && context.separatingHinge == null`)
and otherwise uses `AdaptiveTwoPane(minPaneWidth: 260, primary: image, secondary: info)`. See
[CONVENTIONS.md#foldables](CONVENTIONS.md#foldables).

Sources: new (decision C2), using `display_features.dart`; corsa-customer adaptive shell idea.

---

## Lists

### PaginatedListView

`lists/paginated_list_view.dart` — `PaginatedListView<T>`: an infinite list or grid over a
[`PaginatedState<T>`](SERVICES.md#cubit-bases). It shows a first-page skeleton, empty and error
views, pull-to-refresh, loads more within 300 px or 80 % of the end, retries inline after a
failed next page, shows "You've reached the end", and **auto-loads when the first page doesn't fill
the viewport** (tablets, landscape), never after a failure.

| Param | Notes |
|---|---|
| `state`, `itemBuilder` (`(context, item, index)`), `onLoadMore`, `onRefresh` | required |
| `onRetry` | First-page retry (defaults to `onRefresh`) |
| `gridColumns` (`int Function(double width)?`) | Grid mode, e.g. `columnsForWidth` (from the sliver's width) |
| `gridChildAspectRatio` (1), `gridItemExtent` | Prefer `gridItemExtent` when cells hold text |
| `empty`, `loading` | Custom views (defaults `EmptyView`, `SkeletonList`) |
| `padding`, `header`, `controller` | `header` scrolls above the items (filters, summary) |

```dart
BlocBuilder<ItemsListCubit, PaginatedState<Item>>(
  builder: (context, state) {
    final cubit = context.read<ItemsListCubit>();
    return PaginatedListView<Item>(
      state: state,
      onLoadMore: cubit.loadNextPage,
      onRefresh: cubit.refresh,
      header: AppSearchField(onChanged: cubit.search),
      gridColumns: context.isPhone ? null : (w) => columnsForWidth(w, minTileWidth: 280),
      gridItemExtent: 120,
      itemBuilder: (context, item, _) => ItemTile(item: item, onTap: () => context.push(ItemsRoutes.details(item.id))),
    );
  },
)
```

Show a failed **refresh** (items still on screen) with `AppSnackBar.error` from a `BlocListener`
on `state.failure`.

Sources: corsa-customer `paginated_list_view.dart` q5; chinaparts-seller `fill_viewport_paging.dart` q5.

### NavTile

`lists/nav_tile.dart` — a settings/navigation row: tinted leading icon, title, subtitle, a trailing
widget and a chevron that **mirrors in RTL** (`Icons.chevron_right`).

| Param | Default |
|---|---|
| `title`, `onTap` | required |
| `icon`, `subtitle`, `trailing` | `trailing` sits before the chevron (badge, value, chip) |
| `showChevron` | `true` |
| `destructive` | `false` (error colours, for "Sign out" / "Delete account") |

```dart
NavTile(icon: Icons.logout, title: LocaleKeys.profile_sign_out.tr(), destructive: true, showChevron: false, onTap: _signOut)
```

Sources: markspulse `nav_tile.dart`; corsa-customer `AppMenuTile`.

---

## Media

### AppNetworkImage

`media/app_network_image.dart` — every remote image goes through here. It is cached
(cached_network_image), **decoded at display size** (`width × devicePixelRatio`) to save memory,
shows a skeleton placeholder, and falls back quietly to a broken-image icon. A missing URL is a
normal state, not an error.

| Param | Notes |
|---|---|
| `url` (`String?`) | required; null/blank → `fallback` |
| `width`, `height`, `fit` (`cover`), `borderRadius` | |
| `heroTag`, `onTap` | |
| `semanticLabel` | Translated; null = decorative |
| `placeholder`, `fallback` | Defaults: skeleton bone, `ImageFallback` |
| `fullResolution` | Skip the decode cap (zoomable viewers) |

```dart
AppNetworkImage(url: item.imageUrl, width: 72, height: 72, borderRadius: AppRadii.mdAll, heroTag: 'item-${item.id}')
```

Sources: corsa-customer `app_image.dart` (memCacheWidth from layout, skeleton); baytna
`remote_image.dart` (broken URL is normal); tebbr (`fullResolution`).

### ImageViewerScreen

`media/image_viewer_screen.dart` — a full-screen gallery: swipe between images, pinch and
double-tap zoom toward the tapped point, paging locked while zoomed, chrome hidden while zoomed, a
localized page counter, a close button and a dark surface from the app's dark theme.

| Param | |
|---|---|
| `urls` | required, non-empty |
| `initialIndex` | `0` |
| `heroTag` | Tag of the image at `initialIndex` |

```dart
Navigator.of(context).push(MaterialPageRoute<void>(
  fullscreenDialog: true,
  builder: (_) => ImageViewerScreen(urls: item.images, initialIndex: i, heroTag: 'item-${item.id}'),
));
```

Sources: tebbr `image_viewer.dart` (zoom, hero, full resolution); baytna `image_gallery_viewer.dart`
(counter, close).

### showImageSourceSheet

`media/image_source_sheet.dart` — `showImageSourceSheet(context, {title})` →
`Future<ImageSource?>`: "Take a photo / Choose from gallery" in the app sheet. It **only returns
the choice**. Picking and permissions belong to the caller and
[`ImagePickerService`](SERVICES.md#imagepickerservice).

```dart
final source = await showImageSourceSheet(context);
if (source != null) await cubit.pickImage(source);
```

Sources: chinaparts-seller, chinaparts-customer and brgr image picker sheets, rewritten. The
originals picked inside the sheet with a popped context.

---

## Display

### AppCard

`display/app_card.dart` — `AppCard({required child, onTap, onLongPress, padding = all(16), margin, color})`.
A themed `Card` (shape and colour from `cardTheme`). With `onTap` the ripple is clipped to the
card. Override `color` only with a theme or palette colour.

```dart
AppCard(onTap: () => context.push(ItemsRoutes.details(item.id)), child: ItemSummary(item: item))
```

Sources: baytna `app_card.dart`; markspulse `app_card.dart`.

### StatusChip

`display/status_chip.dart` — `StatusChip({required label, tone = StatusTone.neutral, icon})`. A pill
using the palette's container/on-container pair (contrast tested in light and dark). The icon grows
with the text.

```dart
StatusChip(label: item.status.labelKey.tr(), tone: item.status.tone, icon: Icons.schedule)
```

`StatusTone`: `neutral`, `info`, `success`, `warning`, `danger`. Map your domain enum to a tone in
the presentation layer.

Sources: lexa-control `status_pill.dart` q5; markspulse status colours.

### AppAvatar

`display/app_avatar.dart` — `AppAvatar({imageUrl, name, size = 40, semanticLabel})`. A circular
photo, or up to two **Arabic-aware initials** when there is no photo or it fails to load.
Honorifics («أ.», «د.», "Dr", "Eng") are skipped. `AppAvatar.initialsOf(name)` is pure and tested.

```dart
AppAvatar(imageUrl: user.photoUrl, name: user.fullName, size: 48)
```

Sources: baytna `app_avatar.dart`; markspulse `initials_avatar.dart`.

---

## Guards

### DirtyGuard

`guards/dirty_guard.dart` — `DirtyGuard({required dirty, required child, onDiscard})`. While
`dirty`, leaving the route (back button, swipe, `pop`) asks "Discard changes?" through
`showConfirmDialog`. A clean form closes silently. The pop result is forwarded.

```dart
DirtyGuard(
  dirty: state.isDirty && !state.isSaved,
  onDiscard: cubit.clearDraft,
  child: AppScaffold(title: LocaleKeys.items_edit.tr(), body: _form()),
)
```

Built on `PopScope` (never the removed `WillPopScope`).

Sources: markspulse `dirty_guard.dart` q5; chinaparts-seller `unsaved_changes_guard.dart`.

---

## Settings

### LanguageSelector

`settings/language_selector.dart` — `LanguageSelector({onChanged, contentPadding})`. A radio list of
`AppLanguages.all`, each written in itself («العربية», "English"). Selecting one calls
`context.setLocale` (persisted) and then `onChanged(locale)`, for example to sync the user's
profile. It uses `RadioGroup`, not the deprecated `groupValue`.

```dart
AppCard(padding: EdgeInsets.zero, child: LanguageSelector(onChanged: profileCubit.updateLanguage))
```

Sources: chinaparts-seller `app_language_sheet.dart`; markspulse `language_choice.dart`.

### ThemeModeSelector

`settings/theme_mode_selector.dart` — `const ThemeModeSelector()`. A full-width `SegmentedButton`
for system / light / dark, bound to the persisted `ThemeCubit` (provided by the app root).

Sources: baytna `settings_page.dart`; markspulse.

---

## Screens

`lib/shared/screens/` — app-level screens wired by `app_router.dart` and `bootstrap.dart`.

| Screen | Purpose | Notes |
|---|---|---|
| `SplashScreen()` | Shown only while the session is `unknown` | Text-free placeholder (`FlutterLogo`, marked `{{APP_LOGO}}`). Swap in the brand asset |
| `HomeShell({required navigationShell})` | The `StatefulShellRoute` shell | `AdaptiveNavigationShell` with Home and Settings. Re-tapping the current tab pops it to its first page |
| `SettingsScreen({required appInfo})` | Language, appearance, version | The version is shown as `version+build` isolated LTR inside Arabic text |
| `NotFoundScreen()` | `GoRouter.errorBuilder` | "Page not found" + "Go to home" |
| `ConfigErrorApp({details})` | Standalone app when `AppEnv.validate()` fails | Runs **before** localization starts, so its texts are const Arabic + English strings (the one documented exception to "no hardcoded strings"; keep them in sync with `config_error.*`). `details` only in debug |

```dart
// app_router.dart — adding a tab
StatefulShellBranch(routes: OrdersRoutes.routes(rootNavigatorKey: AppRoutes.rootNavigatorKey)),
// home_shell.dart — same position
AdaptiveDestination(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: LocaleKeys.nav_orders.tr()),
```

Sources: baytna `app_shell.dart` and `settings_page.dart`; corsa-customer `route_builders.dart`
(not-found page) and `adaptive_shell.dart`; chinaparts-seller (blocking screen above the app).
`SplashScreen` and `ConfigErrorApp` are new.

---

## App gate

`lib/shared/widgets/app_gate/` — the UI of the [app config gate](SERVICES.md#app-config). It sits
in `MaterialApp.builder` **above the router**: maintenance and force update replace the whole app,
so no deep link can bypass them.

| Widget | Params | Purpose |
|---|---|---|
| `AppConfigGate` | `child` (required), `onOpenStore` (`StoreOpener = Future<bool> Function(String? configStoreUrl)`; null hides store buttons), `navigatorKey` (defaults to `AppRoutes.rootNavigatorKey`) | Switches on `AppConfigCubit.decision`. Refreshes the config on resume (throttled). Shows the optional sheet once per latest build, after the splash has routed away |
| `MaintenanceView` | `message`, `isLoading`, `onRetry` | Full screen; the server message per language wins |
| `ForceUpdateView` | `message`, `onUpdate` | Full screen, store button |
| `OptionalUpdateSheet` | `onUpdate`; `OptionalUpdateSheet.show(context, onUpdate:)` | Dismissible "Update available" |
| `GateLayout` / `GateButtonProgress` | `icon`, `title`, `message`, `actions` | Shared layout |

```dart
// lib/app.dart (already wired)
AppConfigGate(
  onOpenStore: (url) => getIt<UrlService>().open(url ?? AppEnv.storeUrl),
  child: OfflineBanner(child: child ?? const SizedBox.shrink()),
)
```

Try it with mocks: set `"maintenance": true` or raise `min_build` / `latest_build` in
`assets/mocks/app_config.json`.

Sources: chinaparts-customer `app_config_gate.dart` + force update / maintenance screens; baytna
`app_gate.dart` (post-frame prompt, gate layout); corsa-customer `system_config_gate.dart` (426/503);
tebbr (refresh on resume).

---

## Permissions flow

`lib/shared/widgets/permissions/permission_flow.dart` — the permission UX in one call. If the
permission is already granted it returns `true`. Otherwise it shows the **rationale** (if
askable), then the system prompt. If the permission is permanently denied it offers **Settings**,
waits for the user to come back (5 min timeout), and re-checks.

| API | |
|---|---|
| `ensurePermission(context, permission, service, {required rationaleTitle, required rationaleMessage, throttle, settingsReturnTimeout})` | `Future<bool>`. `restricted` returns `false` at once |
| `SettingsPromptThrottle({interval = 1 day, clock})` | Pass it for **automatic** checks (on resume, tab switch) so the Settings prompt never nags. Leave it out for checks started by a tap |
| `AppPermissionText` on `AppPermission` | `label`, `rationaleTitle` ("Allow access to Camera"), `rationaleMessage` (generic default) |

```dart
final granted = await ensurePermission(
  context,
  AppPermission.notifications,
  getIt<PermissionService>(),
  rationaleTitle: AppPermission.notifications.rationaleTitle,
  rationaleMessage: LocaleKeys.orders_notifications_reason.tr(), // feature-specific "why"
  throttle: _throttle, // automatic check on resume
);
```

Platform setup (Podfile macros, Info.plist strings, manifest): see
[SERVICES.md#permissions](SERVICES.md#permissions).

Sources: petrobe `permissions_service.dart` (rationale → request → Settings → re-check);
chinaparts-seller `notification_permission_gate.dart` (throttled Settings prompt).
