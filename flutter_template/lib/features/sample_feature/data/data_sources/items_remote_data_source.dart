// HTTP calls of the items feature. Throws Failure (via ApiClient).
//
// Source: corsa-customer lib/core/base_architecture/data/data_sources/
//         base_remote_data_source.dart (typed parser per call, cancel token,
//         endpoint constants instead of inline strings).
// Merged: corsa-customer lib/core/utilities/constants/keys/api_keys.dart
//         (relative endpoint constants — Dio already holds the base URL).
// See docs/SERVICES.md#apiclient.
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/pagination/page.dart';
import '../../domain/entities/create_item_input.dart';
import '../models/item_model.dart';

/// Relative API paths of the items feature.
abstract final class ItemsEndpoints {
  static const items = '/items';

  /// `GET /items/:id` with the id URL-encoded.
  static String item(String id) => '$items/${Uri.encodeComponent(id)}';
}

class ItemsRemoteDataSource {
  ItemsRemoteDataSource(this._api);

  final ApiClient _api;

  /// `GET /items?page=&q=` → `{data: [...], meta: {current_page, last_page, total}}`.
  /// Malformed rows are skipped.
  Future<Page<ItemModel>> fetchPage(int page, {String? query, CancelToken? cancelToken}) => _api.get(
    ItemsEndpoints.items,
    query: {'page': page, if (query != null && query.isNotEmpty) 'q': query},
    cancelToken: cancelToken,
    parser: (json) {
      final raw = Page.fromJson<ItemModel?>(json, ItemModel.tryParse);
      return Page<ItemModel>(
        items: raw.items.nonNulls.toList(),
        page: raw.page,
        hasMore: raw.hasMore,
        total: raw.total,
      );
    },
  );

  /// `GET /items/:id`.
  Future<ItemModel> byId(String id, {CancelToken? cancelToken}) =>
      _api.get(ItemsEndpoints.item(id), cancelToken: cancelToken, parser: ItemModel.fromResponse);

  /// `POST /items` → the created item (201).
  Future<ItemModel> create(CreateItemInput input) =>
      _api.post(ItemsEndpoints.items, data: ItemModel.createBody(input), parser: ItemModel.fromResponse);
}
