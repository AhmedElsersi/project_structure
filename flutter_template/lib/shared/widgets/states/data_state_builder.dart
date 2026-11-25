// Renders a DataState<T>: loading / error / empty / data, keeping data on
// screen while refreshing or after a failed refresh.
//
// Source: corsa-customer lib/core/utilities/widgets/base_fetching_widget.dart
//         (GenericFetchWidget: skeleton or spinner on first load, keep data
//         while refreshing and after a failure, empty state, retry).
// Merged: chinaparts-seller base_fetching_widget.dart idea (skeleton over the
//         real layout via the `loading` builder); typed on the template's
//         DataState<T> instead of a per-feature bloc/state triple (new).
// See docs/WIDGETS.md#states.
import 'package:flutter/material.dart';

import '../../../core/presentation/data_state.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'loading_view.dart';

/// Switches on a [DataState]:
///
/// | state                               | shows                         |
/// |-------------------------------------|-------------------------------|
/// | initial / loading, no data          | [loading] or [LoadingView]    |
/// | failure, no data                    | [ErrorView] (+ retry)         |
/// | loading or failure WITH data        | [builder] (old data stays)    |
/// | success but [isEmpty] / null data   | [empty] or [EmptyView]        |
/// | success                             | [builder]                     |
///
/// On a failed refresh the data stays; show the failure with a snackbar
/// from a `BlocListener`.
///
/// ```dart
/// BlocBuilder<ItemCubit, DataState<Item>>(
///   builder: (context, state) => DataStateBuilder<Item>(
///     state: state,
///     onRetry: context.read<ItemCubit>().load,
///     builder: (context, item) => ItemDetails(item),
///   ),
/// )
/// ```
class DataStateBuilder<T> extends StatelessWidget {
  const DataStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.loading,
    this.isEmpty,
    this.empty,
    this.onRetry,
  });

  final DataState<T> state;
  final Widget Function(BuildContext context, T data) builder;

  /// First-load placeholder (e.g. an `AppSkeleton` / `SkeletonList`).
  final Widget Function(BuildContext context)? loading;

  /// Whether loaded data counts as empty (e.g. `(list) => list.isEmpty`).
  final bool Function(T data)? isEmpty;

  /// Shown for empty data; defaults to a generic [EmptyView].
  final Widget? empty;

  /// Retry for the full-screen error.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    if (data != null) {
      // Refreshing, failed refresh or success: the data stays on screen.
      if (isEmpty?.call(data) ?? false) return empty ?? const EmptyView();
      return builder(context, data);
    }
    return switch (state.status) {
      DataStatus.initial || DataStatus.loading => loading?.call(context) ?? const LoadingView(),
      DataStatus.failure => ErrorView(failure: state.failure, onRetry: onRetry),
      DataStatus.success => empty ?? const EmptyView(),
    };
  }
}
