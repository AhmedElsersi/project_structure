// Tests for lib/core/pagination/paginated_cubit.dart. Source: new
import 'dart:async';

import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/pagination/page.dart';
import 'package:app_template/core/pagination/paginated_cubit.dart';
import 'package:app_template/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Item = ({int id, String v});

_Item _item(int id, [String v = '']) => (id: id, v: v);

Result<Page<_Item>> _page(int page, List<int> ids, {bool hasMore = true}) =>
    Ok(Page(items: [for (final id in ids) _item(id)], page: page, hasMore: hasMore));

/// Serves pages from [responder]; records requested page numbers.
class _ItemsCubit extends PaginatedCubit<_Item> {
  _ItemsCubit(this.responder);

  FutureOr<Result<Page<_Item>>> Function(int page) responder;
  final List<int> requested = [];

  @override
  Future<Result<Page<_Item>>> fetchPage(int page) async {
    requested.add(page);
    return responder(page);
  }

  @override
  Object itemKey(_Item item) => item.id;
}

List<int> _ids(PaginatedState<_Item> s) => [for (final i in s.items) i.id];

void main() {
  late _ItemsCubit cubit;
  late List<PaginatedState<_Item>> emitted;
  late StreamSubscription<PaginatedState<_Item>> sub;

  void build(FutureOr<Result<Page<_Item>>> Function(int page) responder) {
    cubit = _ItemsCubit(responder);
    emitted = [];
    sub = cubit.stream.listen(emitted.add);
  }

  tearDown(() async {
    await sub.cancel();
    await cubit.close();
  });

  test('initial state', () {
    build((p) => _page(p, []));
    expect(cubit.state.status, PageStatus.initial);
    expect(cubit.state.page, 0);
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.items, isEmpty);
  });

  test('first page: loadingFirst → success', () async {
    build((p) => _page(p, [1, 2, 3]));
    await cubit.loadFirstPage();
    await pumpEventQueue();
    expect(emitted.map((s) => s.status), [PageStatus.loadingFirst, PageStatus.success]);
    expect(_ids(cubit.state), [1, 2, 3]);
    expect(cubit.state.page, 1);
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.requested, [1]);
  });

  test('duplicates inside one page are removed', () async {
    build((p) => _page(p, [1, 1, 2]));
    await cubit.loadFirstPage();
    expect(_ids(cubit.state), [1, 2]);
  });

  test('empty first page → isEmpty', () async {
    build((p) => _page(p, [], hasMore: false));
    await cubit.loadFirstPage();
    expect(cubit.state.isEmpty, isTrue);
  });

  test('next page appends uniquely (overlapping items dropped)', () async {
    build((p) => p == 1 ? _page(1, [1, 2, 3]) : _page(2, [3, 4]));
    await cubit.loadFirstPage();
    await cubit.loadNextPage();
    expect(_ids(cubit.state), [1, 2, 3, 4]);
    expect(cubit.state.page, 2);
    expect(cubit.state.isLoadingMore, isFalse);
    expect(cubit.requested, [1, 2]);
  });

  test('isLoadingMore is true while the next page loads', () async {
    final page2 = Completer<Result<Page<_Item>>>();
    build((p) => p == 1 ? _page(1, [1]) : page2.future);
    await cubit.loadFirstPage();
    final next = cubit.loadNextPage();
    expect(cubit.state.isLoadingMore, isTrue);
    page2.complete(_page(2, [2]));
    await next;
    expect(cubit.state.isLoadingMore, isFalse);
  });

  test('hasMore false stops paging', () async {
    build((p) => _page(p, [p], hasMore: false));
    await cubit.loadFirstPage();
    await cubit.loadNextPage();
    expect(cubit.requested, [1]);
    expect(cubit.state.hasMore, isFalse);
  });

  test('loadNextPage while a next page is loading is ignored', () async {
    final page2 = Completer<Result<Page<_Item>>>();
    build((p) => p == 1 ? _page(1, [1]) : page2.future);
    await cubit.loadFirstPage();
    final first = cubit.loadNextPage();
    await cubit.loadNextPage();
    await cubit.loadNextPage();
    page2.complete(_page(2, [2]));
    await first;
    expect(cubit.requested, [1, 2]);
    expect(_ids(cubit.state), [1, 2]);
  });

  test('loadNextPage before the first page / while it loads is ignored', () async {
    final page1 = Completer<Result<Page<_Item>>>();
    build((p) => page1.future);
    await cubit.loadNextPage();
    expect(cubit.requested, isEmpty);
    final first = cubit.loadFirstPage();
    await cubit.loadNextPage();
    page1.complete(_page(1, [1]));
    await first;
    expect(cubit.requested, [1]);
  });

  test('load-more failure keeps items and sets loadMoreFailure; a retry clears it', () async {
    var failPage2 = true;
    build((p) {
      if (p == 1) return _page(1, [1, 2]);
      return failPage2 ? const Err(NetworkFailure()) : _page(2, [3]);
    });
    await cubit.loadFirstPage();
    await cubit.loadNextPage();

    expect(cubit.state.loadMoreFailure, const NetworkFailure());
    expect(cubit.state.failure, isNull);
    expect(cubit.state.status, PageStatus.success);
    expect(cubit.state.isLoadingMore, isFalse);
    expect(_ids(cubit.state), [1, 2]);
    expect(cubit.state.page, 1);

    failPage2 = false;
    final retry = cubit.loadNextPage();
    expect(cubit.state.loadMoreFailure, isNull, reason: 'cleared while retrying');
    await retry;
    expect(_ids(cubit.state), [1, 2, 3]);
    expect(cubit.state.loadMoreFailure, isNull);
  });

  test('first-page failure → status failure; a reload clears it', () async {
    var fail = true;
    build((p) => fail ? const Err(ServerFailure()) : _page(1, [1]));
    await cubit.loadFirstPage();
    expect(cubit.state.status, PageStatus.failure);
    expect(cubit.state.failure, const ServerFailure());

    await cubit.loadNextPage();
    expect(cubit.requested, [1], reason: 'no next page after a failed first page');

    fail = false;
    await cubit.loadFirstPage();
    expect(cubit.state.status, PageStatus.success);
    expect(cubit.state.failure, isNull);
  });

  test('refresh replaces the items and keeps them visible while loading', () async {
    var round = 0;
    final refreshGate = Completer<void>();
    build((p) async {
      if (p == 2) return _page(2, [3, 4]);
      if (round++ == 0) return _page(1, [1, 2]);
      await refreshGate.future;
      return _page(1, [9]);
    });
    await cubit.loadFirstPage();
    await cubit.loadNextPage();
    expect(_ids(cubit.state), [1, 2, 3, 4]);

    final refreshing = cubit.refresh();
    expect(cubit.state.isRefreshing, isTrue);
    expect(_ids(cubit.state), [1, 2, 3, 4]);
    refreshGate.complete();
    await refreshing;

    expect(_ids(cubit.state), [9]);
    expect(cubit.state.page, 1);
    expect(cubit.state.isRefreshing, isFalse);
  });

  test('a next-page result that arrives after a refresh is dropped', () async {
    final page2 = Completer<Result<Page<_Item>>>();
    var round = 0;
    build((p) {
      if (p == 2) return page2.future;
      return round++ == 0 ? _page(1, [1, 2]) : _page(1, [10, 11]);
    });
    await cubit.loadFirstPage();
    final stale = cubit.loadNextPage();
    await cubit.refresh();
    page2.complete(_page(2, [3, 4]));
    await stale;

    expect(_ids(cubit.state), [10, 11]);
    expect(cubit.state.page, 1);
    expect(cubit.state.isLoadingMore, isFalse);
  });

  test('upsertLocal replaces in place or inserts at the top; removeLocal removes', () async {
    build((p) => _page(1, [1, 2, 3]));
    await cubit.loadFirstPage();

    cubit.upsertLocal(_item(2, 'edited'));
    expect(_ids(cubit.state), [1, 2, 3]);
    expect(cubit.state.items[1].v, 'edited');

    cubit.upsertLocal(_item(7, 'new'));
    expect(_ids(cubit.state), [7, 1, 2, 3]);

    cubit.removeLocal(1);
    expect(_ids(cubit.state), [7, 2, 3]);
    cubit.removeLocal(42);
    expect(_ids(cubit.state), [7, 2, 3]);
  });

  test('a cancelled first page leaves the loading state untouched (no error)', () async {
    build((p) => const Err(CancelledFailure()));
    await cubit.loadFirstPage();
    expect(cubit.state.status, PageStatus.loadingFirst);
    expect(cubit.state.failure, isNull);
  });

  test('PaginatedState.copyWith clear flags', () {
    const s = PaginatedState<int>(failure: NetworkFailure(), loadMoreFailure: TimeoutFailure());
    expect(s.copyWith().failure, const NetworkFailure());
    expect(s.copyWith(clearFailure: true).failure, isNull);
    expect(s.copyWith(clearLoadMoreFailure: true).loadMoreFailure, isNull);
    expect(s.copyWith(clearLoadMoreFailure: true).failure, const NetworkFailure());
  });
}
