// Tests for ItemsListCubit: first page, next page, debounced search that
// cancels the previous request and drops its stale result.
//
// Source: new (bloc_test + a mocktail fake of the ItemsRepository interface).
import 'dart:async';

import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/pagination/page.dart';
import 'package:app_template/core/pagination/paginated_cubit.dart';
import 'package:app_template/core/result/result.dart';
import 'package:app_template/features/sample_feature/domain/entities/item.dart';
import 'package:app_template/features/sample_feature/domain/repositories/items_repository.dart';
import 'package:app_template/features/sample_feature/presentation/managers/items_list_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'support/fake_items_repository.dart' show sampleItem;

class _MockItemsRepository extends Mock implements ItemsRepository {}

Page<Item> _page(int page, List<int> ids, {bool hasMore = true}) =>
    Page(items: [for (final id in ids) sampleItem(id)], page: page, hasMore: hasMore);

void main() {
  late _MockItemsRepository repository;

  void answer(int page, Result<Page<Item>> result, {String? query}) => when(
    () => repository.fetchPage(
      page,
      query: query,
      cancelToken: any(named: 'cancelToken'),
    ),
  ).thenAnswer((_) async => result);

  setUp(() => repository = _MockItemsRepository());

  group('paging', () {
    blocTest<ItemsListCubit, PaginatedState<Item>>(
      'loadFirstPage: loading → items of page 1',
      setUp: () => answer(1, Ok(_page(1, [1, 2, 3]))),
      build: () => ItemsListCubit(repository),
      act: (cubit) => cubit.loadFirstPage(),
      expect: () => [
        const PaginatedState<Item>(status: PageStatus.loadingFirst),
        PaginatedState<Item>(items: [sampleItem(1), sampleItem(2), sampleItem(3)], status: PageStatus.success, page: 1),
      ],
      verify: (_) => verify(
        () => repository.fetchPage(
          1,
          cancelToken: any(named: 'cancelToken', that: isA<CancelToken>()),
        ),
      ).called(1),
    );

    blocTest<ItemsListCubit, PaginatedState<Item>>(
      'loadNextPage appends page 2 (duplicates dropped) and stops at the end',
      setUp: () {
        answer(1, Ok(_page(1, [1, 2])));
        answer(2, Ok(_page(2, [2, 3], hasMore: false)));
      },
      build: () => ItemsListCubit(repository),
      act: (cubit) async {
        await cubit.loadFirstPage();
        await cubit.loadNextPage();
        await cubit.loadNextPage(); // no more pages: ignored
      },
      skip: 2,
      expect: () => [
        isA<PaginatedState<Item>>().having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        PaginatedState<Item>(
          items: [sampleItem(1), sampleItem(2), sampleItem(3)],
          status: PageStatus.success,
          page: 2,
          hasMore: false,
        ),
      ],
      verify: (_) => verify(() => repository.fetchPage(2, cancelToken: any(named: 'cancelToken'))).called(1),
    );

    blocTest<ItemsListCubit, PaginatedState<Item>>(
      'a failed first page is a full-screen failure',
      setUp: () => answer(1, const Err(NetworkFailure())),
      build: () => ItemsListCubit(repository),
      act: (cubit) => cubit.loadFirstPage(),
      skip: 1,
      expect: () => [const PaginatedState<Item>(status: PageStatus.failure, failure: NetworkFailure())],
    );
  });

  group('search', () {
    blocTest<ItemsListCubit, PaginatedState<Item>>(
      'waits 400 ms after the LAST keystroke, then reloads page 1 for the query',
      setUp: () => answer(1, Ok(_page(1, [10, 11], hasMore: false)), query: 'item 1'),
      build: () => ItemsListCubit(repository),
      act: (cubit) async {
        cubit
          ..search('it')
          ..search('item');
        await Future<void>.delayed(const Duration(milliseconds: 300));
        cubit.search(' item 1 '); // resets the timer; trimmed
        await Future<void>.delayed(const Duration(milliseconds: 300));
        // 300 ms after the last keystroke: still nothing sent.
        verifyNever(
          () => repository.fetchPage(
            any(),
            query: any(named: 'query'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const PaginatedState<Item>(),
        const PaginatedState<Item>(status: PageStatus.loadingFirst),
        PaginatedState<Item>(
          items: [sampleItem(10), sampleItem(11)],
          status: PageStatus.success,
          page: 1,
          hasMore: false,
        ),
      ],
      verify: (cubit) {
        expect(cubit.query, 'item 1');
        verify(
          () => repository.fetchPage(
            1,
            query: 'item 1',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    blocTest<ItemsListCubit, PaginatedState<Item>>(
      'the same query again does nothing',
      setUp: () => answer(1, Ok(_page(1, [1]))),
      build: () => ItemsListCubit(repository, searchDelay: Duration.zero),
      act: (cubit) async {
        await cubit.loadFirstPage();
        cubit.search('   ');
      },
      wait: const Duration(milliseconds: 20),
      skip: 2,
      expect: () => const <PaginatedState<Item>>[],
    );

    test('a new query cancels the request in flight and drops its stale result', () async {
      final slow = Completer<Result<Page<Item>>>();
      CancelToken? firstToken;
      when(() => repository.fetchPage(1, cancelToken: any(named: 'cancelToken'))).thenAnswer((invocation) {
        firstToken = invocation.namedArguments[#cancelToken] as CancelToken?;
        return slow.future;
      });
      answer(1, Ok(_page(1, [20], hasMore: false)), query: 'x');

      final cubit = ItemsListCubit(repository, searchDelay: Duration.zero);
      addTearDown(cubit.close);
      unawaited(cubit.loadFirstPage());
      cubit.search('x');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(firstToken?.isCancelled, isTrue);
      expect(cubit.state.items, [sampleItem(20)]);

      // The old response arrives late: ignored.
      slow.complete(Ok(_page(1, [1, 2, 3])));
      await pumpEventQueue();
      expect(cubit.state.items, [sampleItem(20)]);
    });
  });

  test('upsertLocal puts a created item on top without a reload', () async {
    answer(1, Ok(_page(1, [1, 2])));
    final cubit = ItemsListCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadFirstPage();
    cubit.upsertLocal(sampleItem(99));
    expect(cubit.state.items.map((i) => i.id), ['99', '1', '2']);
    verify(() => repository.fetchPage(1, cancelToken: any(named: 'cancelToken'))).called(1);
  });
}
