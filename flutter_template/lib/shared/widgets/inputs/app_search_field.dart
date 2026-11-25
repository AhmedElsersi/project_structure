// Search input with debounce and a clear button.
//
// Source: corsa-customer lib/core/utilities/widgets/app_search_field.dart
//         (debounced onChanged, clear button only when there is text, search
//         keyboard action, readOnly + onTap for "open search screen" fields).
// Merged: Timer-based debounce cancelled on dispose (new; the source used
//         Future.delayed stamps that could fire after dispose).
// See docs/WIDGETS.md#inputs.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';

/// A search field. [onChanged] is debounced by [debounce]; clearing and
/// submitting call through immediately.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.debounce = const Duration(milliseconds: 350),
    this.trailing,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Already-translated hint; defaults to "Search".
  final String? hint;

  /// Debounced query callback.
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// With [readOnly], turns the field into a button (e.g. open a search page).
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final Duration debounce;

  /// Shown at the end while the field is empty (e.g. a filter button).
  final Widget? trailing;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _ownController;
  Timer? _timer;

  TextEditingController get _controller => widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void dispose() {
    _timer?.cancel();
    _ownController?.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final callback = widget.onChanged;
    if (callback == null) return;
    _timer?.cancel();
    if (widget.debounce == Duration.zero) {
      callback(value);
      return;
    }
    _timer = Timer(widget.debounce, () {
      if (mounted) callback(_controller.text);
    });
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onChanged?.call('');
  }

  void _submit(String value) {
    _timer?.cancel();
    widget.onSubmitted?.call(value);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: _controller,
    builder: (context, value, _) => TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      onChanged: _onChanged,
      onSubmitted: _submit,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hint ?? LocaleKeys.common_search.tr(),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: value.text.isEmpty || widget.readOnly
            ? widget.trailing
            : IconButton(
                tooltip: LocaleKeys.widgets_clear_search.tr(),
                icon: const Icon(Icons.close),
                onPressed: _clear,
              ),
      ),
    ),
  );
}
