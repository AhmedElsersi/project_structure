// Base screen: themed AppBar, busy bar, width-capped padded body and a sticky
// bottom action that stays above the keyboard.
//
// Source: corsa-customer lib/core/utilities/widgets/default_screen.dart (max
//         content width on tablets, sticky bottom action above the keyboard,
//         safe-area handling, one place for page padding).
// Merged: markspulse lib/core/widgets/layout/app_scaffold.dart (thin 2 px
//         progress bar under the app bar while an action is in flight; the
//         Material AppBar from the theme, never a custom title row).
// See docs/WIDGETS.md#layout.
import 'package:flutter/material.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import 'max_width_body.dart';

/// The standard screen frame.
///
/// * [title] / [actions] / [leading] go into the theme's `AppBar`; the back
///   button is automatic (and mirrors in RTL) unless [showBackButton] is false.
/// * [busy] shows a 2 px progress bar under the app bar.
/// * The body is padded by [padding] (default: the page gutter left/right)
///   and, with [constrainWidth], centred at `context.maxContentWidth`.
/// * [bottomAction] (e.g. the submit `AppButton`) is pinned under the body,
///   inside the safe area, and rides above the keyboard.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomAction,
    this.busy = false,
    this.constrainWidth = true,
    this.padding,
    this.showBackButton = true,
    this.showAppBar = true,
  });

  final Widget body;

  /// Already-translated title.
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;

  /// Sticky action area under the body.
  final Widget? bottomAction;

  /// An action is in flight: thin progress bar under the app bar.
  final bool busy;

  /// Centre the body (and bottom action) at `context.maxContentWidth`.
  final bool constrainWidth;

  /// Body padding; defaults to horizontal `context.pageGutter`.
  final EdgeInsetsGeometry? padding;
  final bool showBackButton;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    // The body always gets the full (capped) area, so a Column with
    // crossAxisAlignment.start starts on the RIGHT in Arabic instead of
    // shrink-wrapping at offset 0 (the left edge).
    Widget content = Padding(
      padding: padding ?? EdgeInsetsDirectional.symmetric(horizontal: gutter),
      child: SizedBox.expand(child: body),
    );
    if (constrainWidth) content = MaxWidthBody(child: content);

    final action = bottomAction;
    if (action != null) {
      Widget bottom = Padding(
        padding: EdgeInsetsDirectional.fromSTEB(gutter, AppSpacing.md, gutter, AppSpacing.md),
        child: action,
      );
      if (constrainWidth) bottom = MaxWidthBody(alignment: AlignmentDirectional.bottomCenter, child: bottom);
      content = Column(
        children: [
          Expanded(child: content),
          SafeArea(top: false, child: bottom),
        ],
      );
    }

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: title == null ? null : Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis),
              leading: leading,
              automaticallyImplyLeading: showBackButton,
              actions: actions,
              bottom: busy
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(AppSpacing.xxs),
                      child: LinearProgressIndicator(minHeight: AppSpacing.xxs),
                    )
                  : null,
            )
          : null,
      floatingActionButton: floatingActionButton,
      body: SafeArea(top: !showAppBar, bottom: action == null, child: content),
    );
  }
}
