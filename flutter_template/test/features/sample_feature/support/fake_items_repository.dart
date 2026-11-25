// In-memory ItemsRepository for widget and layout tests (no network, no
// images: every item has a null imageUrl so no cache plugin is touched).
//
// Source: new (test double of lib/features/sample_feature/domain/repositories/items_repository.dart).
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/pagination/page.dart';
import 'package:app_template/core/result/result.dart';
import 'package:app_template/features/sample_feature/domain/entities/create_item_input.dart';
import 'package:app_template/features/sample_feature/domain/entities/item.dart';
import 'package:app_template/features/sample_feature/domain/repositories/items_repository.dart';

/// A long title / description to stress layouts.
const String longTitle = 'A sample item with a deliberately long title that needs to ellipsize';
const String longDescription =
    'A long description that wraps over several lines so the layout tests can check that nothing '
    'overflows on small phones with the largest text, in Arabic and in English.';

Item sampleItem(int n, {String? title, String? description, ItemStatus? status}) => Item(
  id: '$n',
  title: title ?? 'Sample item ${n.toString().padLeft(2, '0')}',
  description: description ?? (n.isEven ? longDescription : ''),
  status: status ?? ItemStatus.values[n % ItemStatus.values.length],
  createdAt: DateTime.utc(2026, 10, 30).subtract(Duration(hours: n)),
);

class FakeItemsRepository implements ItemsRepository {
  FakeItemsRepository({int count = 40, this.pageSize = 15}) : items = [for (var n = 1; n <= count; n++) sampleItem(n)];

  final List<Item> items;
  final int pageSize;

  /// The next call fails with this failure (then it is cleared).
  Failure? failNext;

  final List<({int page, String? query})> pageCalls = [];
  final List<CreateItemInput> created = [];

  Result<T>? _takeFailure<T>() {
    final failure = failNext;
    if (failure == null) return null;
    failNext = null;
    return Err<T>(failure);
  }

  @override
  Future<Result<Page<Item>>> fetchPage(int page, {String? query, Object? cancelToken}) async {
    pageCalls.add((page: page, query: query));
    final failed = _takeFailure<Page<Item>>();
    if (failed != null) return failed;
    final q = query?.toLowerCase();
    final matches = q == null ? items : items.where((i) => i.title.toLowerCase().contains(q)).toList();
    final start = ((page - 1) * pageSize).clamp(0, matches.length);
    final end = (start + pageSize).clamp(0, matches.length);
    return Ok(
      Page(items: matches.sublist(start, end), page: page, hasMore: end < matches.length, total: matches.length),
    );
  }

  @override
  Future<Result<Item>> byId(String id, {Object? cancelToken}) async {
    final failed = _takeFailure<Item>();
    if (failed != null) return failed;
    for (final item in items) {
      if (item.id == id) return Ok(item);
    }
    return const Err(NotFoundFailure());
  }

  @override
  Future<Result<Item>> create(CreateItemInput input) async {
    final failed = _takeFailure<Item>();
    if (failed != null) return failed;
    if (input.title.toLowerCase() == 'taken') {
      return const Err(
        ValidationFailure(
          fieldErrors: {
            'title': ['This title is already used'],
          },
        ),
      );
    }
    created.add(input);
    final item = Item(
      id: '${items.length + 1}',
      title: input.title,
      description: input.description,
      status: input.status,
      createdAt: DateTime.utc(2026, 11, 5),
    );
    items.insert(0, item);
    return Ok(item);
  }
}
