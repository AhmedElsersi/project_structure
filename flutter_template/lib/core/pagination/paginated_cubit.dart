// Generic infinite-scroll cubit + state: first page, next page, refresh.
//
// Source: chinaparts-seller lib/core/utilities/request_generation.dart (stale
//         responses dropped by ticket, appendUnique) and fill_viewport_paging.dart;
//         corsa-customer paginated_list_view.dart (inline load-more failure with
//         retry, hasReachedMax).
// Replaces the scroll-listener + page counter copy-pasted ~50 times in
// chinaparts-customer, petrobe, brgr, instaops.
// See docs/ARCHITECTURE.md#pagination.
import 'package:equatable/equatable.dart';

import '../errors/failure.dart';
import '../presentation/base_cubit.dart';
import '../result/result.dart';
import 'page.dart';

enum PageStatus { initial, loadingFirst, success, failure }

class PaginatedState<T> extends Equatable {
  const PaginatedState({
    this.items = const [],
    this.status = PageStatus.initial,
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final List<T> items;
  final PageStatus status;

  /// Last page successfully loaded (0 = none).
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// First-page failure. Full-screen error when [items] is empty; with items
  /// on screen it is a refresh failure (show a snackbar, keep the list).
  final Failure? failure;

  /// Next-page failure (inline retry at the list end).
  final Failure? loadMoreFailure;

  bool get isEmpty => status == PageStatus.success && items.isEmpty;
  bool get isRefreshing => status == PageStatus.loadingFirst && items.isNotEmpty;

  PaginatedState<T> copyWith({
    List<T>? items,
    PageStatus? status,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => PaginatedState<T>(
    items: items ?? this.items,
    status: status ?? this.status,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: clearFailure ? null : (failure ?? this.failure),
    loadMoreFailure: clearLoadMoreFailure ? null : (loadMoreFailure ?? this.loadMoreFailure),
  );

  @override
  List<Object?> get props => [items, status, page, hasMore, isLoadingMore, failure, loadMoreFailure];
}

abstract class PaginatedCubit<T> extends BaseCubit<PaginatedState<T>> {
  PaginatedCubit() : super(PaginatedState<T>());

  /// Fetches 1-based [page].
  Future<Result<Page<T>>> fetchPage(int page);

  /// Identity used to de-duplicate items across pages.
  Object itemKey(T item);

  /// Loads page 1 (initial load or pull-to-refresh). Keeps items on screen
  /// while refreshing.
  Future<void> loadFirstPage() => run<Page<T>>(
    () => fetchPage(1),
    onLoading: () => safeEmit(
      state.copyWith(
        status: PageStatus.loadingFirst,
        isLoadingMore: false,
        clearFailure: true,
        clearLoadMoreFailure: true,
      ),
    ),
    onSuccess: (page) => safeEmit(
      PaginatedState<T>(items: _unique(page.items), status: PageStatus.success, page: page.page, hasMore: page.hasMore),
    ),
    // With items already on screen a failed refresh keeps the list usable
    // (status success + failure for a snackbar); otherwise full-screen error.
    onFailure: (f) =>
        safeEmit(state.copyWith(status: state.items.isEmpty ? PageStatus.failure : PageStatus.success, failure: f)),
  );

  /// Alias for pull-to-refresh.
  Future<void> refresh() => loadFirstPage();

  /// Loads the next page if allowed. Safe to call on every scroll event.
  Future<void> loadNextPage() async {
    final s = state;
    if (!s.hasMore || s.isLoadingMore || s.status != PageStatus.success) return;
    await run<Page<T>>(
      () => fetchPage(s.page + 1),
      onLoading: () => safeEmit(s.copyWith(isLoadingMore: true, clearLoadMoreFailure: true)),
      onSuccess: (page) => safeEmit(
        state.copyWith(
          items: _unique([...state.items, ...page.items]),
          page: page.page,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      ),
      onFailure: (f) => safeEmit(state.copyWith(isLoadingMore: false, loadMoreFailure: f)),
    );
  }

  /// Replaces the item with the same key (after an edit) or removes it.
  void upsertLocal(T item) {
    final key = itemKey(item);
    final index = state.items.indexWhere((e) => itemKey(e) == key);
    final next = [...state.items];
    if (index >= 0) {
      next[index] = item;
    } else {
      next.insert(0, item);
    }
    safeEmit(state.copyWith(items: next));
  }

  void removeLocal(Object key) => safeEmit(state.copyWith(items: state.items.where((e) => itemKey(e) != key).toList()));

  List<T> _unique(List<T> items) {
    final seen = <Object>{};
    return [
      for (final item in items)
        if (seen.add(itemKey(item))) item,
    ];
  }
}
