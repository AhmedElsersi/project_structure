// Snackbars: message / success / info / error(Failure) / undo, with or without
// a BuildContext (via a global ScaffoldMessenger key).
//
// Source: baytna lib/core/widgets/app_snackbar.dart (one helper; error takes a
//         Failure so the text is localized; undo with a visible countdown;
//         hides the current bar before showing the next).
// Merged: lexa-control lib/core/ui/widgets/app_snack_bar.dart (background and
//         foreground always from the SAME container/on-container pair; longer
//         durations for errors and undo).
// Colours are resolved when the bar is BUILT (inside the Scaffold, under the
// app theme), so the context-free path gets the right palette too.
// See docs/WIDGETS.md#feedback.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/errors/failure.dart';
import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';

/// Shows themed snackbars.
///
/// Pass `context:` when you have one; otherwise the bar is shown through
/// [messengerKey], which must be given to `MaterialApp.router(scaffoldMessengerKey:)`.
///
/// ```dart
/// AppSnackBar.success(LocaleKeys.items_saved.tr(), context: context);
/// AppSnackBar.error(failure); // from a listener without a context
/// ```
abstract final class AppSnackBar {
  /// Wire into `MaterialApp.router(scaffoldMessengerKey: AppSnackBar.messengerKey)`.
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>(
    debugLabel: 'AppSnackBar',
  );

  static const Duration _short = Duration(seconds: 4);
  static const Duration _long = Duration(seconds: 6);
  static const Duration _undo = Duration(seconds: 8);

  /// A plain message in the neutral tone.
  static void show(String message, {BuildContext? context, IconData? icon, Duration duration = _short}) =>
      _show(context, message, tone: StatusTone.neutral, icon: icon, duration: duration);

  /// A confirmation ("Saved").
  static void success(String message, {BuildContext? context}) =>
      _show(context, message, tone: StatusTone.success, icon: Icons.check_circle_outline, duration: _short);

  /// Neutral information.
  static void info(String message, {BuildContext? context}) =>
      _show(context, message, tone: StatusTone.info, icon: Icons.info_outline, duration: _short);

  /// A failure's localized [Failure.displayMessage]. Cancelled requests are
  /// never shown.
  static void error(Failure failure, {BuildContext? context}) {
    if (failure is CancelledFailure) return;
    errorMessage(failure.displayMessage, context: context);
  }

  /// An already-translated error sentence.
  static void errorMessage(String message, {BuildContext? context}) =>
      _show(context, message, tone: StatusTone.danger, icon: Icons.error_outline, duration: _long);

  /// [message] with an Undo button and a draining countdown line; [onUndo]
  /// runs when tapped.
  static void undo(String message, {required VoidCallback onUndo, BuildContext? context, Duration duration = _undo}) {
    final messenger = _messenger(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _bar(
          duration: duration,
          content: _SnackContent(
            message: message,
            tone: StatusTone.neutral,
            icon: Icons.undo,
            countdown: duration,
            action: (label: LocaleKeys.common_undo.tr(), onPressed: onUndo),
            onAction: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }

  /// Hides the visible bar, if any.
  static void hide({BuildContext? context}) => _messenger(context)?.hideCurrentSnackBar();

  static ScaffoldMessengerState? _messenger(BuildContext? context) =>
      (context == null ? null : ScaffoldMessenger.maybeOf(context)) ?? messengerKey.currentState;

  static void _show(
    BuildContext? context,
    String message, {
    required StatusTone tone,
    required Duration duration,
    IconData? icon,
  }) {
    final messenger = _messenger(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _bar(
          duration: duration,
          content: _SnackContent(message: message, tone: tone, icon: icon),
        ),
      );
  }

  // The SnackBar itself is transparent; _SnackContent paints the themed
  // surface so its colours resolve under the app theme at build time.
  static SnackBar _bar({required Widget content, required Duration duration}) => SnackBar(
    content: content,
    duration: duration,
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    // Let _SnackContent's own shadow show.
    clipBehavior: Clip.none,
  );
}

class _SnackContent extends StatefulWidget {
  const _SnackContent({
    required this.message,
    required this.tone,
    this.icon,
    this.countdown,
    this.action,
    this.onAction,
  });

  final String message;
  final StatusTone tone;
  final IconData? icon;
  final Duration? countdown;
  final ({String label, VoidCallback onPressed})? action;
  final VoidCallback? onAction;

  @override
  State<_SnackContent> createState() => _SnackContentState();
}

class _SnackContentState extends State<_SnackContent> with SingleTickerProviderStateMixin {
  AnimationController? _countdown;

  @override
  void initState() {
    super.initState();
    final duration = widget.countdown;
    if (duration != null) _countdown = AnimationController(vsync: this, duration: duration)..forward();
  }

  @override
  void dispose() {
    _countdown?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Neutral uses the classic inverse surface; tones use their container pair.
    final colors = widget.tone == StatusTone.neutral
        ? ToneColors(scheme.inverseSurface, scheme.onInverseSurface)
        : context.palette.toneColors(widget.tone);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(color: colors.onContainer);
    final shape = theme.snackBarTheme.shape ?? const RoundedRectangleBorder(borderRadius: AppRadii.mdAll);
    final action = widget.action;
    final countdown = _countdown;

    return Material(
      color: colors.container,
      shape: shape,
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              end: action == null ? AppSpacing.lg : AppSpacing.xs,
              top: action == null ? AppSpacing.md : AppSpacing.xs,
              bottom: action == null ? AppSpacing.md : AppSpacing.xs,
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: AppSizes.icon, color: colors.onContainer),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(child: Text(widget.message, style: textStyle)),
                if (action != null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: scheme.inversePrimary),
                    onPressed: () {
                      widget.onAction?.call();
                      action.onPressed();
                    },
                    child: Text(action.label),
                  ),
              ],
            ),
          ),
          if (countdown != null && !MediaQuery.disableAnimationsOf(context))
            AnimatedBuilder(
              animation: countdown,
              builder: (context, _) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: 1 - countdown.value,
                  child: SizedBox(
                    height: AppSpacing.xxs,
                    child: ColoredBox(color: scheme.inversePrimary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
