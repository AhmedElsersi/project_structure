// Generic load/success/failure state for screens that show one piece of data.
//
// Source: corsa-customer base_single_class_state.dart + chinaparts-seller
//         BaseSingleClassState{status, failure, success} — made generic so no
//         feature needs its own state class for a simple fetch.
// Fixes: the house-style `failure ?? this.failure` copyWith that could never
//        clear a failure (tebbr, brgr, instaops, petrobe).
import 'package:equatable/equatable.dart';

import '../errors/failure.dart';

enum DataStatus { initial, loading, success, failure }

class DataState<T> extends Equatable {
  const DataState({this.status = DataStatus.initial, this.data, this.failure});

  const DataState.initial() : this();

  final DataStatus status;
  final T? data;
  final Failure? failure;

  bool get isInitial => status == DataStatus.initial;
  bool get isLoading => status == DataStatus.loading;
  bool get isSuccess => status == DataStatus.success;
  bool get isFailure => status == DataStatus.failure;
  bool get hasData => data != null;

  /// Loading while previous data is still on screen (pull-to-refresh).
  bool get isRefreshing => isLoading && hasData;

  DataState<T> loading() => DataState<T>(status: DataStatus.loading, data: data);

  DataState<T> success(T value) => DataState<T>(status: DataStatus.success, data: value);

  /// Keeps the previous [data] so the screen can show it with an error banner.
  DataState<T> failed(Failure value) => DataState<T>(status: DataStatus.failure, data: data, failure: value);

  @override
  List<Object?> get props => [status, data, failure];
}
