// Cubit for "load one thing" screens: implement [fetch] and call [load].
//
// Source: corsa-customer BaseSingleStateCubit.handleRequest default branch
//         (loading → success/failure emits) without the per-feature state class.
import '../result/result.dart';
import 'base_cubit.dart';
import 'data_state.dart';

abstract class DataCubit<T> extends BaseCubit<DataState<T>> {
  DataCubit() : super(DataState<T>());

  /// The request to perform. Use [cancelToken] for network calls.
  Future<Result<T>> fetch();

  /// Loads (or reloads) the data, keeping old data visible while refreshing.
  Future<void> load() => run<T>(
    fetch,
    onLoading: () => safeEmit(state.loading()),
    onSuccess: (value) => safeEmit(state.success(value)),
    onFailure: (failure) => safeEmit(state.failed(failure)),
  );
}
