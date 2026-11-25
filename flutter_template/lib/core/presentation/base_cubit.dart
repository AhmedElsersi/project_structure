// The one base class for cubits: safe emits, stale-result guard, cancel tokens.
//
// Source: corsa-customer lib/core/base_architecture/presentation/managers/
//         base_single_class_state_bloc/base_single_class_state_cubit.dart
//         (safeEmit, CancelToken cancelled in close, debounce helper).
// Merged: chinaparts-customer base cubits (session "epoch": results that arrive
//         after a newer request or a reset are dropped); chinaparts-seller
//         request_generation.dart (stale-response tickets).
// Replaces the two parallel bases (BaseCubit + BaseSingleStateCubit) found in
// brgr, tebbr, chinaparts-*, corsa-*, instaops, petrobe.
// See docs/ARCHITECTURE.md#state.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../errors/failure.dart';
import '../result/result.dart';

abstract class BaseCubit<S> extends Cubit<S> {
  BaseCubit(super.initialState);

  CancelToken _cancelToken = CancelToken();
  Timer? _debounce;
  int _generation = 0;

  /// Token to pass to ApiClient calls; cancelled when the cubit closes.
  CancelToken get cancelToken => _cancelToken;

  /// Cancels in-flight requests and returns a fresh token (e.g. new search).
  CancelToken renewCancelToken() {
    _cancelToken.cancel('renewed');
    return _cancelToken = CancelToken();
  }

  /// Emits only while the cubit is open.
  @protected
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }

  /// Runs [action] after [delay], cancelling the previous pending one.
  @protected
  void debounce(Duration delay, void Function() action) {
    _debounce?.cancel();
    _debounce = Timer(delay, action);
  }

  /// Invalidates results of requests started before this call.
  @protected
  void invalidatePending() => _generation++;

  /// Executes [call] and routes its result. A result that arrives after a newer
  /// [run] / [invalidatePending], or after close, is dropped. Cancelled
  /// requests are never reported as errors.
  @nonVirtual
  @protected
  Future<void> run<T>(
    Future<Result<T>> Function() call, {
    void Function()? onLoading,
    required FutureOr<void> Function(T value) onSuccess,
    required FutureOr<void> Function(Failure failure) onFailure,
  }) async {
    final ticket = ++_generation;
    onLoading?.call();
    final Result<T> result;
    try {
      result = await call();
    } on Object catch (e) {
      // Repositories return Result; reaching here is a programming error.
      if (isClosed || ticket != _generation) return;
      await onFailure(UnknownFailure(debugMessage: e.toString()));
      return;
    }
    if (isClosed || ticket != _generation) return;
    switch (result) {
      case Ok<T>(:final value):
        await onSuccess(value);
      case Err<T>(:final failure):
        if (failure is CancelledFailure) return;
        await onFailure(failure);
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _cancelToken.cancel('closed');
    return super.close();
  }
}
