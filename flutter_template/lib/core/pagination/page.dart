// One page of results.
//
// Source: markspulse lib/domain/common/page.dart (items + hasMore; fetch limit+1
//         to know whether more exist) and corsa-customer base_success_response.dart
//         PaginationModel (flat or nested `meta`).
class Page<T> {
  const Page({required this.items, required this.page, required this.hasMore, this.total});

  final List<T> items;

  /// 1-based page number that produced [items].
  final int page;
  final bool hasMore;
  final int? total;

  static Page<T> empty<T>() => Page<T>(items: const [], page: 1, hasMore: false, total: 0);

  /// Reads `{data: [...], meta: {current_page, last_page, total}}` or the same
  /// keys at the root (Laravel-style paginators).
  static Page<T> fromJson<T>(Object? json, T Function(Map<String, dynamic>) item) {
    final body = json is Map ? Map<String, dynamic>.from(json) : const <String, dynamic>{};
    final rawList = body['data'] ?? body['items'] ?? const <dynamic>[];
    final list = rawList is List ? rawList : const <dynamic>[];
    final metaRaw = body['meta'];
    final meta = metaRaw is Map ? Map<String, dynamic>.from(metaRaw) : body;
    int? asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
    final current = asInt(meta['current_page']) ?? asInt(meta['page']) ?? 1;
    final last = asInt(meta['last_page']) ?? asInt(meta['total_pages']);
    final explicit = body['has_more'] ?? meta['has_more'];
    return Page<T>(
      items: [
        for (final e in list)
          if (e is Map) item(Map<String, dynamic>.from(e)),
      ],
      page: current,
      hasMore: explicit is bool ? explicit : (last != null ? current < last : list.isNotEmpty),
      total: asInt(meta['total']),
    );
  }
}
