// "New item" form: client validation, server/domain field errors under the
// fields, unsaved-changes guard, busy submit, success → snackbar + pop with
// the created item.
//
// Source: chinaparts-customer lib/core/utilities/responsive/scrollable_form_body.dart
//         usage (footer pinned when it fits, scrolls under the keyboard).
// Merged: petrobe lib/core/utilities/widgets/text_form_fields/app_text_form_field.dart
//         (server `errorText` per field); markspulse
//         lib/core/widgets/feedback/dirty_guard.dart + lib/core/widgets/input/busy_button.dart
//         usage (ask before leaving an edited form; one in-flight submit).
// See docs/WIDGETS.md#inputs.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/generated/locale_keys.g.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/guards/dirty_guard.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../../../shared/widgets/layout/max_width_body.dart';
import '../../../../shared/widgets/layout/scrollable_form_body.dart';
import '../../domain/entities/create_item_input.dart';
import '../../domain/entities/item.dart';
import '../managers/create_item_cubit.dart';
import '../managers/create_item_state.dart';
import '../widgets/item_status_chip.dart';

/// Expects a [CreateItemCubit] above it (created in `ItemsRoutes`). Pops
/// with the created [Item].
class CreateItemScreen extends StatefulWidget {
  const CreateItemScreen({super.key});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  ItemStatus _status = ItemStatus.draft;

  /// Set on success so the guard lets the closing pop through.
  bool _saved = false;

  bool get _dirty =>
      !_saved && (_title.text.trim().isNotEmpty || _description.text.trim().isNotEmpty || _status != ItemStatus.draft);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _onEdited(String _) => setState(() {});

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CreateItemCubit>().submit(
      CreateItemInput(title: _title.text, description: _description.text, status: _status),
    );
  }

  void _onState(BuildContext context, CreateItemState state) {
    final created = state.created;
    if (created != null) {
      AppSnackBar.success(LocaleKeys.items_created.tr(), context: context);
      setState(() => _saved = true);
      // Pop after the rebuild, once the guard no longer blocks it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(created);
      });
      return;
    }
    final failure = state.generalFailure;
    if (failure != null) AppSnackBar.error(failure, context: context);
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<CreateItemCubit, CreateItemState>(
    listenWhen: (previous, current) => previous.created != current.created || previous.failure != current.failure,
    listener: _onState,
    builder: (context, state) => DirtyGuard(
      dirty: _dirty,
      child: AppScaffold(
        title: LocaleKeys.items_create_title.tr(),
        busy: state.isSubmitting,
        // Explicit MaxWidthBody below so the scroll view stays full width
        // (drag anywhere) while the fields are capped on tablets.
        constrainWidth: false,
        body: Form(
          key: _formKey,
          child: ScrollableFormBody(
            footer: MaxWidthBody(
              child: AppButton(
                label: LocaleKeys.items_add.tr(),
                icon: Icons.check,
                busy: state.isSubmitting,
                expand: true,
                onPressed: _submit,
              ),
            ),
            child: MaxWidthBody(child: _fields(state)),
          ),
        ),
      ),
    ),
  );

  Widget _fields(CreateItemState state) {
    final enabled = !state.isSubmitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _title,
          label: LocaleKeys.items_field_title.tr(),
          hint: LocaleKeys.items_field_title_hint.tr(),
          errorText: state.fieldError('title'),
          validator: Validators.required(),
          enabled: enabled,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: _onEdited,
        ),
        AppSpacing.gapLg,
        AppTextField(
          controller: _description,
          label: LocaleKeys.items_field_description.tr(),
          errorText: state.fieldError('description'),
          enabled: enabled,
          maxLength: 500,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          onChanged: _onEdited,
        ),
        AppSpacing.gapLg,
        AppDropdown<ItemStatus>(
          label: LocaleKeys.items_field_status.tr(),
          items: ItemStatus.selectable,
          labelOf: (status) => status.labelKey.tr(),
          initialValue: _status,
          errorText: state.fieldError('status'),
          enabled: enabled,
          onChanged: (status) => setState(() => _status = status ?? _status),
        ),
      ],
    );
  }
}
