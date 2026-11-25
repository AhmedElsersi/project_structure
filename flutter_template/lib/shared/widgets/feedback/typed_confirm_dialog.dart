// Confirmation that requires typing a word, for destructive actions with no
// undo (delete account, close a workspace, wipe data).
//
// Source: baytna lib/features/admin/presentation/widgets/typed_confirmation_dialog.dart
//         (type-a-word gate; a plain-language consequence box as the loudest
//         thing in the dialog; confirm disabled until the word matches).
// Merged: lexa-control lib/core/ui/widgets/typed_confirmation_dialog.dart
//         (destructive tint on the confirm button); digit folding + case-
//         insensitive match (new).
// See docs/WIDGETS.md#feedback.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/input_formatters.dart';
import '../buttons/app_button.dart';
import '../inputs/app_text_field.dart';

/// Shows a dialog whose confirm button only enables once the user typed
/// [confirmWord] (trimmed, case-insensitive, any digit script). Resolves to
/// `true` when confirmed.
///
/// All texts are already translated. [consequence] describes in plain words
/// what will happen ("All 42 items will be deleted for everyone").
Future<bool> showTypedConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmWord,
  String? message,
  String? consequence,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => TypedConfirmDialog(
      title: title,
      confirmWord: confirmWord,
      message: message,
      consequence: consequence,
      confirmLabel: confirmLabel ?? LocaleKeys.common_confirm.tr(),
      cancelLabel: cancelLabel ?? LocaleKeys.common_cancel.tr(),
      destructive: destructive,
    ),
  );
  return result ?? false;
}

/// The dialog behind [showTypedConfirmDialog]; pops `true` / `false`.
class TypedConfirmDialog extends StatefulWidget {
  const TypedConfirmDialog({
    super.key,
    required this.title,
    required this.confirmWord,
    required this.confirmLabel,
    required this.cancelLabel,
    this.message,
    this.consequence,
    this.destructive = true,
  });

  final String title;
  final String confirmWord;
  final String? message;
  final String? consequence;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  State<TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<TypedConfirmDialog> {
  final TextEditingController _typed = TextEditingController();

  static String _normalize(String value) => DigitsNormalizerFormatter.normalizeDigits(value.trim()).toLowerCase();

  bool get _matches => _normalize(_typed.text) == _normalize(widget.confirmWord);

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_matches) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = context.palette.toneColors(widget.destructive ? StatusTone.danger : StatusTone.warning);
    final consequence = widget.consequence;

    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message != null) ...[Text(widget.message!), AppSpacing.gapMd],
          if (consequence != null) ...[
            DecoratedBox(
              decoration: BoxDecoration(color: tone.container, borderRadius: AppRadii.mdAll),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: tone.onContainer),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(consequence, style: theme.textTheme.bodyMedium?.copyWith(color: tone.onContainer)),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapLg,
          ],
          Text(
            LocaleKeys.widgets_typed_confirm_hint.tr(args: [widget.confirmWord]),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          AppSpacing.gapSm,
          AppTextField(
            controller: _typed,
            autofocus: true,
            hint: widget.confirmWord,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        AppButton(
          label: widget.cancelLabel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: widget.confirmLabel,
          variant: widget.destructive ? AppButtonVariant.danger : AppButtonVariant.filled,
          onPressed: _matches ? _confirm : null,
        ),
      ],
    );
  }
}
