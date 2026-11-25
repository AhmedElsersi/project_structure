// Offline backend for the items feature (USE_MOCKS builds and tests): paging,
// search, 404 and 422 validation errors, from assets/mocks/items.json plus the
// items created during the session.
//
// Source: corsa-driver lib/core/services/mock/mock_route_table.dart (handlers
//         registered next to the feature that owns the endpoint; fixtures from
//         JSON assets; handler-driven error statuses).
// See docs/SERVICES.md#mock-backend.
import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../../../../core/network/mock/mock_interceptor.dart';
import '../../../../core/utils/json_x.dart';
import '../data_sources/items_remote_data_source.dart';

/// Seed data for the mock backend.
const String itemsMockAsset = 'assets/mocks/items.json';

/// Registers `GET /items`, `GET /items/:id` and `POST /items` on [mock].
///
/// * `GET /items?page=&q=` — [pageSize] per page, newest created first, `q`
///   matches title or description (case-insensitive);
///   `{data, meta: {current_page, last_page, total}}`.
/// * `GET /items/:id` — `{data: item}` or 404.
/// * `POST /items` — 422 `{errors: {title: [...]}}` for a title shorter than
///   3 characters or the title `taken`; otherwise 201 `{data: item}`.
///
/// Messages follow the request's `Accept-Language` (ar / en), like a real
/// backend would.
void registerItemsMockApi(MockInterceptor mock, {int pageSize = 15}) {
  final api = _ItemsMockApi(mock, pageSize);
  mock
    ..on('GET', ItemsEndpoints.items, api.list)
    ..on('GET', '${ItemsEndpoints.items}/:id', api.byId)
    ..on('POST', ItemsEndpoints.items, api.create);
}

class _ItemsMockApi {
  _ItemsMockApi(this._mock, this._pageSize);

  final MockInterceptor _mock;
  final int _pageSize;

  /// Items created in this session, newest first.
  final List<Map<String, dynamic>> _created = [];
  Future<List<Map<String, dynamic>>>? _seed;

  Future<List<Map<String, dynamic>>> _all() async {
    final seed = await (_seed ??= _loadSeed());
    return [..._created, ...seed];
  }

  Future<List<Map<String, dynamic>>> _loadSeed() async {
    final json = asJsonMap(await _mock.loadJson(itemsMockAsset)) ?? const <String, dynamic>{};
    final rows = json['items'];
    return [
      if (rows is List)
        for (final row in rows)
          if (asJsonMap(row) case final Map<String, dynamic> map) map,
    ];
  }

  Future<MockResponse> list(RequestOptions request, Map<String, String> params) async {
    final query = '${request.queryParameters['q'] ?? ''}'.trim().toLowerCase();
    final page = math.max(1, int.tryParse('${request.queryParameters['page'] ?? 1}') ?? 1);
    final all = await _all();
    final matches = query.isEmpty
        ? all
        : all.where((item) {
            final title = item.string('title').toLowerCase();
            final description = item.string('description').toLowerCase();
            return title.contains(query) || description.contains(query);
          }).toList();
    final lastPage = math.max(1, (matches.length / _pageSize).ceil());
    final start = math.min((page - 1) * _pageSize, matches.length);
    final end = math.min(start + _pageSize, matches.length);
    return MockResponse({
      'data': matches.sublist(start, end),
      'meta': {'current_page': page, 'last_page': lastPage, 'total': matches.length},
    });
  }

  Future<MockResponse> byId(RequestOptions request, Map<String, String> params) async {
    final id = params['id'];
    for (final item in await _all()) {
      if (item.string('id') == id) return MockResponse({'data': item});
    }
    // No `message`: the app shows its own localized "not found" sentence.
    return const MockResponse({'code': 'item_not_found'}, statusCode: 404);
  }

  Future<MockResponse> create(RequestOptions request, Map<String, String> params) async {
    final body = asJsonMap(request.data) ?? const <String, dynamic>{};
    final title = body.string('title').trim();
    final arabic = '${request.headers['Accept-Language'] ?? ''}'.toLowerCase().startsWith('ar');

    String? titleError;
    if (title.runes.length < 3) {
      titleError = arabic ? 'يجب ألا يقل العنوان عن 3 أحرف' : 'The title must be at least 3 characters';
    } else if (title.toLowerCase() == 'taken') {
      titleError = arabic ? 'هذا العنوان مستخدم بالفعل' : 'This title is already used';
    }
    if (titleError != null) {
      return MockResponse({
        'code': 'validation_failed',
        'errors': {
          'title': [titleError],
        },
      }, statusCode: 422);
    }

    final all = await _all();
    final nextId = all.fold<int>(0, (max, item) => math.max(max, item.intOr('id'))) + 1;
    final item = <String, dynamic>{
      'id': '$nextId',
      'title': title,
      'description': body.string('description').trim(),
      'status': body.string('status', 'draft'),
      'image_url': 'https://picsum.photos/seed/$nextId/400/300',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _created.insert(0, item);
    return MockResponse({'data': item}, statusCode: 201);
  }
}
