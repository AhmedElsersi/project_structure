// Infinite list/grid over a PaginatedState<T>: first-page skeleton, empty and
// error views, pull-to-refresh, load-more near the end, inline retry, and
// auto-load when the first page doesn't fill the viewport.
//
// Source: corsa-customer lib/core/utilities/widgets/shared/screens/paginated_list_view.dart
//         (load more at 80 % scroll, inline error row with retry, end-of-list
//         text, list or grid in one CustomScrollView, header sliver).
// Merged: chinaparts-seller lib/core/utilities/widgets/fill_viewport_paging.dart
//         (keep loading while the list doesn't fill its viewport — tablets,
//         landscape, split view — but never after a failure, so no loops);
//         grid columns from LayoutBuilder width via columnsForWidth (new).
// See docs/WIDGETS.md#lists.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/pagination/paginated_cubit.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../states/app_skeleton.dart';
import '../states/empty_view.dart';
import '../states/error_view.dart';
import '../states/loading_view.dart';

/// A paginated, pull-to-refresh list (or grid) driven by a `PaginatedCubit`.
///
/// ```dart
/// BlocBuilder<ItemsCubit, PaginatedState<Item>>(
///   builder: (context, state) => PaginatedListView<Item>(
///     state: state,
///     onLoadMore: cubit.loadNextPage,
///     onRefresh: cubit.refresh,
///     onRetry: cubit.loadFirstPage,
///     gridColumns: context.isPhone ? null : columnsForWidth,
///     itemBuilder: (context, item, index) => ItemTile(item),
///   ),
/// )
/// ```
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    this.onRetry,
    this.gridColumns,
    this.gridChildAspectRatio = 1,
    this.gridItemExtent,
    this.empty,
    this.loading,
    this.padding,
    this.header,
    this.controller,
  });

  final PaginatedState<T> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Called near the end of the list; safe to call repeatedly (the cubit
  /// guards). Also the inline "Try again" after a failed next page.
  final VoidCallback onLoadMore;

  /// Pull-to-refresh.
  final Future<void> Function() onRefresh;

  /// Retries the first page after a full-screen error. Defaults to
  /// [onRefresh].
  final VoidCallback? onRetry;

  /// Grid mode: column count for the available width (e.g. `columnsForWidth`).
  final int Function(double width)? gridColumns;

  /// Grid cell aspect ratio (ignored when [gridItemExtent] is set).
  final double gridChildAspectRatio;

  /// Fixed grid cell height; prefer this when cells contain text.
  final double? gridItemExtent;

  /// Shown when the first page is empty; defaults to [EmptyView].
  final Widget? empty;

  /// First-page placeholder; defaults to a [SkeletonList].
  final Widget? loading;

  /// Padding around the items; defaults to page gutters + vertical spacing.
  final EdgeInsetsGeometry? padding;

  /// Scrolls with the list, above the items (filters, summary).
  final Widget? header;
  final ScrollController? controller;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  /// Load more within this many pixels of the end...
  static const double _loadMoreExtent = 300;

  /// ...or past this share of the scroll extent.
  static const double _loadMoreFraction = 0.8;

  ScrollController? _ownController;

  ScrollController get _controller => widget.controller ?? (_ownController ??= ScrollController());

  bool get _canLoadMore {
    final s = widget.state;
    return s.status == PageStatus.success && s.hasMore && !s.isLoadingMore && s.loadMoreFailure == null;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _fillViewportIfNeeded();
  }

  @override
  void didUpdateWidget(PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onScroll);
      _controller.addListener(_onScroll);
    }
    if (oldWidget.state != widget.state) _fillViewportIfNeeded();
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _ownController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_canLoadMore || !_controller.hasClients) return;
    final position = _controller.position;
    final nearEnd =
        position.extentAfter <= _loadMoreExtent || position.pixels >= position.maxScrollExtent * _loadMoreFraction;
    if (nearEnd) widget.onLoadMore();
  }

  /// A first page shorter than the viewport can't be scrolled, so the scroll
  /// trigger would never fire: load the next page right away.
  void _fillViewportIfNeeded() {
    if (!_canLoadMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_canLoadMore || !_controller.hasClients) return;
      if (_controller.position.maxScrollExtent <= 0) widget.onLoadMore();
    });
  }

  EdgeInsetsGeometry _padding(BuildContext context) =>
      widget.padding ?? EdgeInsetsDirectional.symmetric(horizontal: context.pageGutter, vertical: AppSpacing.md);

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final firstLoad = s.items.isEmpty && (s.status == PageStatus.initial || s.status == PageStatus.loadingFirst);
    if (firstLoad) return widget.loading ?? SkeletonList(padding: _padding(context));

    final List<Widget> slivers;
    if (s.items.isEmpty && s.status == PageStatus.failure) {
      slivers = [_fill(ErrorView(failure: s.failure, onRetry: widget.onRetry ?? widget.onRefresh))];
    } else if (s.items.isEmpty) {
      slivers = [_fill(widget.empty ?? const EmptyView())];
    } else {
      slivers = [
        SliverPadding(padding: _padding(context), sliver: _items()),
        SliverToBoxAdapter(child: _footer(context)),
      ];
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        controller: _controller,
        // Always scrollable so pull-to-refresh works on short lists.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          ...slivers,
        ],
      ),
    );
  }

  Widget _fill(Widget child) => SliverFillRemaining(hasScrollBody: false, child: child);

  Widget _items() {
    final items = widget.state.items;
    Widget build(BuildContext context, int index) => widget.itemBuilder(context, items[index], index);

    final columns = widget.gridColumns;
    if (columns == null) {
      return SliverList.separated(
        itemCount: items.length,
        itemBuilder: build,
        separatorBuilder: (_, _) => AppSpacing.gapSm,
      );
    }
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid.builder(
        itemCount: items.length,
        itemBuilder: build,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns(constraints.crossAxisExtent),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: widget.gridChildAspectRatio,
          mainAxisExtent: widget.gridItemExtent,
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final s = widget.state;
    if (s.loadMoreFailure != null) {
      return ErrorView(failure: s.loadMoreFailure, onRetry: widget.onLoadMore, compact: true);
    }
    if (s.isLoadingMore) return const LoadingView(compact: true);
    if (!s.hasMore) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Text(
          LocaleKeys.states_end_of_list.tr(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    return AppSpacing.gapLg;
  }
}
