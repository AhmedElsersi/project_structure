// Paginated, searchable items list.
//
// Source: chinaparts-seller lib/core/utilities/request_generation.dart idea
//         (a newer query drops older responses) through the template's
//         PaginatedCubit + BaseCubit.run generation guard.
// Merged: corsa-customer lib/core/base_architecture/presentation/managers/
//         base_single_class_state_bloc/base_single_class_state_cubit.dart (debounce helper,
//         renewCancelToken so the previous search request is cancelled).
// See docs/ARCHITECTURE.md#pagination.
import 'dart:async';

import '../../../../core/pagination/page.dart';
import '../../../../core/pagination/paginated_cubit.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/items_repository.dart';

class ItemsListCubit extends PaginatedCubit<Item> {
  ItemsListCubit(this._repository, {this.searchDelay = const Duration(milliseconds: 400)});

  final ItemsRepository _repository;

  /// Quiet time after the last keystroke before searching.
  final Duration searchDelay;

  String _query = '';

  /// The active (trimmed) search text; empty = no filter.
  String get query => _query;

  @override
  Future<Result<Page<Item>>> fetchPage(int page) =>
      _repository.fetchPage(page, query: _query.isEmpty ? null : _query, cancelToken: cancelToken);

  @override
  Object itemKey(Item item) => item.id;

  /// Searches [text] once the user stops typing for [searchDelay]. A new
  /// query cancels the request in flight and starts again from page 1 with an
  /// empty list (old results don't match the new query).
  void search(String text) {
    final next = text.trim();
    debounce(searchDelay, () {
      if (next == _query) return;
      _query = next;
      renewCancelToken();
      safeEmit(const PaginatedState<Item>());
      unawaited(loadFirstPage());
    });
  }
}
