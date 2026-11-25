// The one way to open a sheet: a modal bottom sheet on phones, a centred
// dialog on tablets / unfolded foldables.
//
// Source: corsa-customer lib/core/utilities/widgets/show_app_bottom_sheet.dart
//         (sheet on compact, dialog on larger; root navigator so the scrim
//         covers the tab bar; scroll-controlled with keyboard insets; 90 % cap).
// Merged: baytna lib/core/widgets/app_bottom_sheet.dart (handle + title + an
//         explicit close button pinned OUTSIDE the scroll view, so a tall form
//         can always be closed; SafeArea bottom); chinaparts-seller 640 width
//         cap (from bottomSheetTheme.constraints).
// See docs/WIDGETS.md#feedback.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';

/// Max share of the window height a sheet / sheet-dialog may take.
const double kSheetMaxHeightFraction = 0.9;

/// Opens [builder]'s content as a modal bottom sheet on phones and as a
/// centred dialog on tablets and larger (`context.isTabletOrLarger`).
///
/// [title] (already translated) is shown with a close button. With
/// [scrollable] the content scrolls when taller than the sheet; pass false
/// when the content has its own scroll view (e.g. a ListView).
/// Pop a result with `Navigator.of(context).pop(value)`.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  bool isDismissible = true,
  bool scrollable = true,
}) {
  final maxHeight = MediaQuery.sizeOf(context).height * kSheetMaxHeightFraction;

  if (context.isTabletOrLarger) {
    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: isDismissible,
      builder: (dialogContext) => Dialog(
        // Width cap comes from dialogTheme.constraints.
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: AppSheetBody(
            title: title,
            showClose: isDismissible,
            scrollable: scrollable,
            child: Builder(builder: builder),
          ),
        ),
      ),
    );
  }

  final sheetWidth = Theme.of(context).bottomSheetTheme.constraints?.maxWidth ?? AppSizes.sheetMaxWidth;
  return showModalBottomSheet<T>(
    context: context,
    // Root navigator: the sheet and its scrim slide over the bottom nav bar.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    constraints: BoxConstraints(maxWidth: sheetWidth, maxHeight: maxHeight),
    builder: (sheetContext) => Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsetsDirectional.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: AppSheetBody(
        title: title,
        showClose: isDismissible && title != null,
        scrollable: scrollable,
        child: Builder(builder: builder),
      ),
    ),
  );
}

/// Layout of a sheet: optional title row (with close button) pinned above
/// the content, page-gutter padding, bottom safe area.
class AppSheetBody extends StatelessWidget {
  const AppSheetBody({super.key, required this.child, this.title, this.showClose = true, this.scrollable = true});

  final Widget child;
  final String? title;
  final bool showClose;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    final contentPadding = EdgeInsetsDirectional.fromSTEB(gutter, 0, gutter, AppSpacing.xl);
    final hasHeader = title != null || showClose;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasHeader)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(gutter, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: title == null
                        ? const SizedBox.shrink()
                        : Semantics(header: true, child: Text(title!, style: Theme.of(context).textTheme.titleLarge)),
                  ),
                  if (showClose)
                    IconButton(
                      tooltip: LocaleKeys.common_close.tr(),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                ],
              ),
            ),
          Flexible(
            child: scrollable
                ? SingleChildScrollView(padding: contentPadding, child: child)
                : Padding(padding: contentPadding, child: child),
          ),
        ],
      ),
    );
  }
}
