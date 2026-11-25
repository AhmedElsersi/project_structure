// Tests for lib/core/presentation/data_cubit.dart. Source: new
//
// Also covers data_state.dart.
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/presentation/data_cubit.dart';
import 'package:app_template/core/presentation/data_state.dart';
import 'package:app_template/core/result/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

class _ItemCubit extends DataCubit<String> {
  _ItemCubit(this.responses);

  /// Answers for successive fetch() calls.
  final List<Result<String>> responses;
  int fetches = 0;

  @override
  Future<Result<String>> fetch() async => responses[fetches++];
}

// Works around the DataState<Never> initial-state bug (see the skipped test
// below) so the load() logic itself is still covered.
DataState<String> _typedInitial() => const DataState<String>();

void main() {
  const failure = NetworkFailure();

  group('DataCubit initial state', () {
    test('is a DataState<T>, so load() from a fresh cubit can emit success', () async {
      final cubit = _ItemCubit([const Ok('A')]);
      await cubit.load();
      expect(cubit.state, const DataState<String>(status: DataStatus.success, data: 'A'));
      await cubit.close();
    });
  });

  group('DataCubit.load (seeded with a typed initial state)', () {
    blocTest<_ItemCubit, DataState<String>>(
      'loading → success',
      build: () => _ItemCubit([const Ok('A')]),
      seed: _typedInitial,
      act: (c) => c.load(),
      expect: () => const [
        DataState<String>(status: DataStatus.loading),
        DataState<String>(status: DataStatus.success, data: 'A'),
      ],
    );

    blocTest<_ItemCubit, DataState<String>>(
      'loading → failure without data',
      build: () => _ItemCubit([const Err(failure)]),
      seed: _typedInitial,
      act: (c) => c.load(),
      expect: () => const [
        DataState<String>(status: DataStatus.loading),
        DataState<String>(status: DataStatus.failure, failure: failure),
      ],
    );

    blocTest<_ItemCubit, DataState<String>>(
      'refresh keeps old data while loading (isRefreshing) and replaces it on success',
      build: () => _ItemCubit([const Ok('A'), const Ok('B')]),
      seed: _typedInitial,
      act: (c) async {
        await c.load();
        await c.load();
      },
      expect: () => [
        const DataState<String>(status: DataStatus.loading),
        const DataState<String>(status: DataStatus.success, data: 'A'),
        isA<DataState<String>>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.data, 'data', 'A')
            .having((s) => s.isRefreshing, 'isRefreshing', isTrue),
        const DataState<String>(status: DataStatus.success, data: 'B'),
      ],
    );

    blocTest<_ItemCubit, DataState<String>>(
      'a failed refresh keeps the old data next to the failure',
      build: () => _ItemCubit([const Err(failure)]),
      seed: () => const DataState<String>(status: DataStatus.success, data: 'A'),
      act: (c) => c.load(),
      expect: () => const [
        DataState<String>(status: DataStatus.loading, data: 'A'),
        DataState<String>(status: DataStatus.failure, data: 'A', failure: failure),
      ],
    );

    blocTest<_ItemCubit, DataState<String>>(
      'a success after a failure clears the failure',
      build: () => _ItemCubit([const Err(failure), const Ok('B')]),
      seed: _typedInitial,
      act: (c) async {
        await c.load();
        await c.load();
      },
      skip: 2,
      expect: () => const [
        DataState<String>(status: DataStatus.loading),
        DataState<String>(status: DataStatus.success, data: 'B'),
      ],
      verify: (c) => expect(c.state.failure, isNull),
    );

    blocTest<_ItemCubit, DataState<String>>(
      'a cancelled fetch emits only loading',
      build: () => _ItemCubit([const Err(CancelledFailure())]),
      seed: _typedInitial,
      act: (c) => c.load(),
      expect: () => const [DataState<String>(status: DataStatus.loading)],
    );
  });

  group('DataState', () {
    test('initial', () {
      const s = DataState<int>.initial();
      expect(s.isInitial, isTrue);
      expect(s.hasData, isFalse);
      expect(s.isRefreshing, isFalse);
    });

    test('status getters', () {
      const s = DataState<int>();
      expect(s.loading().isLoading, isTrue);
      expect(s.loading().isRefreshing, isFalse, reason: 'first load has no data');
      expect(s.success(1).isSuccess, isTrue);
      expect(s.success(1).hasData, isTrue);
      expect(s.failed(failure).isFailure, isTrue);
      expect(s.success(1).loading().isRefreshing, isTrue);
    });

    test('success/loading drop the previous failure', () {
      final failed = const DataState<int>().success(1).failed(failure);
      expect(failed.failure, failure);
      expect(failed.data, 1);
      expect(failed.loading().failure, isNull);
      expect(failed.success(2).failure, isNull);
    });
  });
}
