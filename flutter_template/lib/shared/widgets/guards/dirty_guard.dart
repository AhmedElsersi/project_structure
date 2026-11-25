// Asks before leaving a form with unsaved changes (back button, swipe, pop).
//
// Source: markspulse lib/core/widgets/feedback/dirty_guard.dart (PopScope with
//         canPop: !dirty; ask on a blocked pop; once confirmed, let the
//         follow-up pop through and forward the pop result; onDiscard hook).
// Merged: chinaparts-seller lib/core/utilities/widgets/unsaved_changes_guard.dart
//         (same guard for seller forms); asks through the shared
//         showConfirmDialog with the common.unsaved_changes_* texts (new).
// See docs/WIDGETS.md#guards.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../feedback/confirm_dialog.dart';

/// Wraps a route's content: while [dirty], leaving the route asks "Discard
/// changes?" first. A clean form closes silently.
class DirtyGuard extends StatefulWidget {
  const DirtyGuard({super.key, required this.dirty, required this.child, this.onDiscard});

  final bool dirty;
  final Widget child;

  /// Runs after the user confirms discarding, before the route pops (e.g.
  /// delete a saved draft).
  final VoidCallback? onDiscard;

  @override
  State<DirtyGuard> createState() => _DirtyGuardState();
}

class _DirtyGuardState extends State<DirtyGuard> {
  /// Set once discarding is confirmed so the follow-up pop goes through.
  bool _leaving = false;
  bool _asking = false;

  Future<void> _ask(Object? result) async {
    if (_asking) return;
    _asking = true;
    final discard = await showConfirmDialog(
      context,
      title: LocaleKeys.common_unsaved_changes_title.tr(),
      message: LocaleKeys.common_unsaved_changes_message.tr(),
      confirmLabel: LocaleKeys.common_discard.tr(),
      cancelLabel: LocaleKeys.common_keep_editing.tr(),
      destructive: true,
    );
    _asking = false;
    if (!discard || !mounted) return;
    widget.onDiscard?.call();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !widget.dirty || _leaving,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      unawaited(_ask(result));
    },
    child: widget.child,
  );
}
