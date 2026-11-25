// Blocking "please wait" dialog around a Future: always closes, re-entrancy
// safe, never pops someone else's route.
//
// Source: petrobe lib/core/services/show_loading_dialog.dart (blocking dialog
//         that keeps its OWN route/context to close itself; ignores a second
//         show while one is visible; back button disabled).
// Merged: run<T>() wraps the future in try/finally so the dialog can't be left
//         open by an exception, nested runs share one dialog, and the route is
//         removed by identity even if another route was pushed above it (new).
// Prefer an in-place busy state (AppButton.busy, AppScaffold.busy); use this
// only when the whole screen must be blocked.
// See docs/WIDGETS.md#feedback.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_spacing.dart';

/// Shows a modal progress dialog while a future runs.
///
/// ```dart
/// final result = await LoadingOverlay.run(context, repository.submit(form));
/// ```
abstract final class LoadingOverlay {
  static int _depth = 0;
  static Route<void>? _route;
  static NavigatorState? _navigator;

  /// Whether the overlay is currently visible.
  static bool get isShowing => _route != null;

  /// Shows the overlay, awaits [future] and closes the overlay — also when
  /// [future] throws (the error is rethrown). Nested calls share one overlay,
  /// which closes when the outermost call finishes.
  ///
  /// [message] is an optional, already-translated line under the spinner.
  static Future<T> run<T>(BuildContext context, Future<T> future, {String? message}) async {
    if (_depth++ == 0) _show(context, message);
    try {
      return await future;
    } finally {
      if (--_depth == 0) _hide();
    }
  }

  static void _show(BuildContext context, String? message) {
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (navigator == null) return;
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LoadingDialog(message: message),
    );
    _navigator = navigator;
    _route = route;
    navigator.push(route).ignore();
  }

  static void _hide() {
    final route = _route;
    final navigator = _navigator;
    _route = null;
    _navigator = null;
    if (route == null || navigator == null || !navigator.mounted || !route.isActive) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      // Something was pushed above it: remove exactly our route.
      navigator.removeRoute(route);
    }
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return PopScope(
      canPop: false,
      child: Center(
        child: Semantics(
          label: text ?? LocaleKeys.common_loading.tr(),
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth / 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (text != null) ...[
                      AppSpacing.gapLg,
                      Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
