// Submits the "create item" form through the use case.
//
// Source: corsa-customer lib/core/base_architecture/presentation/managers/
//         base_single_class_state_bloc/base_single_class_state_cubit.dart (handleRequest:
//         loading → success / failure) via the template's BaseCubit.run, which
//         also drops results that arrive after the screen closed.
// See docs/ARCHITECTURE.md#state.
import '../../../../core/presentation/base_cubit.dart';
import '../../domain/entities/create_item_input.dart';
import '../../domain/entities/item.dart';
import '../../domain/use_cases/create_item_use_case.dart';
import 'create_item_state.dart';

class CreateItemCubit extends BaseCubit<CreateItemState> {
  CreateItemCubit(this._createItem) : super(const CreateItemState());

  final CreateItemUseCase _createItem;

  /// Sends [input]. Ignored while a submit is already in flight.
  Future<void> submit(CreateItemInput input) async {
    if (state.isSubmitting) return;
    await run<Item>(
      () => _createItem(input),
      onLoading: () => safeEmit(const CreateItemState(isSubmitting: true)),
      onSuccess: (item) => safeEmit(CreateItemState(created: item)),
      onFailure: (failure) => safeEmit(CreateItemState(failure: failure)),
    );
  }
}
