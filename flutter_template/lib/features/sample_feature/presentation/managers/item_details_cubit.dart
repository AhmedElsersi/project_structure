// Loads one item by id.
//
// Source: corsa-customer lib/core/base_architecture/presentation/managers/
//         base_single_class_state_bloc/base_single_class_state_cubit.dart
//         (handleRequest default branch) via the template's DataCubit<T>
//         (no per-feature state class for a fetch).
// See docs/ARCHITECTURE.md#state.
import '../../../../core/presentation/data_cubit.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/items_repository.dart';

class ItemDetailsCubit extends DataCubit<Item> {
  ItemDetailsCubit(this._repository, {required this.id});

  final ItemsRepository _repository;

  /// The item to show (from the route path, never `state.extra`).
  final String id;

  @override
  Future<Result<Item>> fetch() => _repository.byId(id, cancelToken: cancelToken);
}
