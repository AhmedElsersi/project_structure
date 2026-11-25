// PaginatedListView: load more near the end, fill the viewport, inline retry,
// first-page states, grid columns from width.
//
// Source: new (tests for lib/shared/widgets/lists/paginated_list_view.dart).
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/pagination/paginated_cubit.dart';
import 'package:app_template/core/responsive/breakpoints.dart';
import 'package:app_template/shared/widgets/lists/paginated_list_view.dart';
import 'package:app_template/shared/widgets/states/app_skeleton.dart';
import 'package:app_template/shared/widgets/states/empty_view.dart';
import 'package:app_template/shared/widgets/states/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

PaginatedListView<int> _list(PaginatedState<int> state, {VoidCallback? onLoadMore, int Function(double)? columns}) =>
    PaginatedListView<int>(
      state: state,
      onLoadMore: onLoadMore ?? () {},
      onRefresh: () async {},
      gridColumns: columns,
      gridItemExtent: columns == null ? null : 100,
      itemBuilder: (context, item, index) => SizedBox(height: 100, child: Text('item $item')),
    );

PaginatedState<int> _loaded(int count, {bool hasMore = true, Failure? loadMoreFailure}) => PaginatedState<int>(
  items: List<int>.generate(count, (i) => i),
  status: PageStatus.success,
  page: 1,
  hasMore: hasMore,
  loadMoreFailure: loadMoreFailure,
);

void main() {
  testWidgets('calls onLoadMore when scrolled near the end', (tester) async {
    var calls = 0;
    await pumpApp(tester, _list(_loaded(30), onLoadMore: () => calls++));
    expect(calls, 0, reason: 'the first page fills the viewport');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(calls, 0, reason: 'still far from the end');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    expect(calls, greaterThan(0));
  });

  testWidgets('loads the next page when the first one does not fill the viewport', (tester) async {
    var calls = 0;
    await pumpApp(tester, _list(_loaded(2), onLoadMore: () => calls++));
    expect(calls, 1);
  });

  testWidgets('does not auto-load after a load-more failure; shows inline retry', (tester) async {
    var calls = 0;
    await pumpApp(
      tester,
      _list(_loaded(2, loadMoreFailure: const ServerFailure()), onLoadMore: () => calls++),
      locale: const Locale('en'),
    );
    expect(calls, 0);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Something went wrong on our side. Please try again.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(calls, 1);
  });

  testWidgets('end of list text when there are no more pages', (tester) async {
    await pumpApp(tester, _list(_loaded(2, hasMore: false)), locale: const Locale('en'));
    expect(find.text("You've reached the end"), findsOneWidget);
  });

  testWidgets('first page: skeleton, then error or empty view', (tester) async {
    await pumpApp(tester, _list(const PaginatedState<int>(status: PageStatus.loadingFirst)), settle: false);
    expect(find.byType(SkeletonList), findsOneWidget);

    await pumpApp(tester, _list(const PaginatedState<int>(status: PageStatus.failure, failure: NetworkFailure())));
    expect(find.byType(ErrorView), findsOneWidget);

    await pumpApp(tester, _list(const PaginatedState<int>(status: PageStatus.success, hasMore: false)));
    expect(find.byType(EmptyView), findsOneWidget);
  });

  testWidgets('grid mode takes its column count from the available width', (tester) async {
    await pumpApp(tester, _list(_loaded(12, hasMore: false), columns: columnsForWidth), size: const Size(1024, 1366));
    // 1024 - 2 * 32 gutter = 960 → 6 columns of 160: items 0..5 share a row.
    final first = tester.getTopLeft(find.text('item 0'));
    final sixth = tester.getTopLeft(find.text('item 5'));
    final seventh = tester.getTopLeft(find.text('item 6'));
    expect(sixth.dy, first.dy);
    expect(seventh.dy, greaterThan(first.dy));
  });
}
