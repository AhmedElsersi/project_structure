// ItemsRepository over the remote data source: Failure → Result, models →
// entities.
//
// Source: chinaparts-customer lib/core/base_architecture/data/repository/base_repo.dart
//         (one guard around every call; non-Failure throws are mapped and
//         reported) via the template's RepositoryGuard mixin.
// See docs/ARCHITECTURE.md#data-flow.
import 'package:dio/dio.dart';

import '../../../../core/data/repository_guard.dart';
import '../../../../core/pagination/page.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/create_item_input.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/items_repository.dart';
import '../data_sources/items_remote_data_source.dart';

class ItemsRepositoryImpl with RepositoryGuard implements ItemsRepository {
  ItemsRepositoryImpl(this._remote);

  final ItemsRemoteDataSource _remote;

  @override
  Future<Result<Page<Item>>> fetchPage(int page, {String? query, Object? cancelToken}) => guard(() async {
    final models = await _remote.fetchPage(page, query: query, cancelToken: _token(cancelToken));
    return Page<Item>(
      items: [for (final model in models.items) model.toEntity()],
      page: models.page,
      hasMore: models.hasMore,
      total: models.total,
    );
  });

  @override
  Future<Result<Item>> byId(String id, {Object? cancelToken}) =>
      guard(() async => (await _remote.byId(id, cancelToken: _token(cancelToken))).toEntity());

  @override
  Future<Result<Item>> create(CreateItemInput input) => guard(() async => (await _remote.create(input)).toEntity());

  /// The domain passes the cubit's token untyped; only a dio token is used.
  static CancelToken? _token(Object? token) => token is CancelToken ? token : null;
}
