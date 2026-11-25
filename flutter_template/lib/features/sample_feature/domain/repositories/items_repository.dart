// Contract of the items data (implemented in data/repositories).
//
// Source: new (pattern example). Repositories never throw: every call returns
//         a Result (decision C1); data sources throw Failure and the
//         implementation converts it with RepositoryGuard.
// See docs/ARCHITECTURE.md#data-flow.
import '../../../../core/pagination/page.dart';
import '../../../../core/result/result.dart';
import '../entities/create_item_input.dart';
import '../entities/item.dart';

/// Items data access.
///
/// [cancelToken] is the caller's `BaseCubit.cancelToken`. It is typed
/// `Object?` on purpose: the domain layer never imports dio (enforced by
/// test/policy/architecture_test.dart); the data layer hands it to ApiClient.
abstract interface class ItemsRepository {
  /// 1-based [page] of items, optionally filtered by [query].
  Future<Result<Page<Item>>> fetchPage(int page, {String? query, Object? cancelToken});

  /// One item; `Err(NotFoundFailure)` when it doesn't exist.
  Future<Result<Item>> byId(String id, {Object? cancelToken});

  /// Creates an item; `Err(ValidationFailure)` with field errors when the
  /// backend rejects the input.
  Future<Result<Item>> create(CreateItemInput input);
}
