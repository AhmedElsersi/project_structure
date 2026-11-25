// DataStateBuilder: every DataState branch.
//
// Source: new (tests for lib/shared/widgets/states/data_state_builder.dart).
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/presentation/data_state.dart';
import 'package:app_template/shared/widgets/states/data_state_builder.dart';
import 'package:app_template/shared/widgets/states/empty_view.dart';
import 'package:app_template/shared/widgets/states/error_view.dart';
import 'package:app_template/shared/widgets/states/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

Widget _builder(DataState<List<String>> state, {VoidCallback? onRetry, Widget Function(BuildContext)? loading}) =>
    DataStateBuilder<List<String>>(
      state: state,
      isEmpty: (list) => list.isEmpty,
      onRetry: onRetry,
      loading: loading,
      builder: (context, data) => Text('data:${data.join(',')}'),
    );

void main() {
  const failure = NetworkFailure();

  testWidgets('initial and loading without data show the loading view', (tester) async {
    await pumpApp(tester, _builder(const DataState.initial()), settle: false);
    expect(find.byType(LoadingView), findsOneWidget);

    await pumpApp(tester, _builder(const DataState<List<String>>().loading()), settle: false);
    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('custom loading builder (skeleton) is used', (tester) async {
    await pumpApp(tester, _builder(const DataState.initial(), loading: (_) => const Text('skeleton')));
    expect(find.text('skeleton'), findsOneWidget);
    expect(find.byType(LoadingView), findsNothing);
  });

  testWidgets('failure without data shows ErrorView with retry', (tester) async {
    var retried = 0;
    await pumpApp(
      tester,
      _builder(const DataState<List<String>>().failed(failure), onRetry: () => retried++),
      locale: const Locale('en'),
    );
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('No internet connection. Check your connection and try again.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('failure or loading WITH data keeps the data', (tester) async {
    final loaded = const DataState<List<String>>().success(['a', 'b']);
    await pumpApp(tester, _builder(loaded.failed(failure)));
    expect(find.text('data:a,b'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);

    await pumpApp(tester, _builder(loaded.loading()));
    expect(find.text('data:a,b'), findsOneWidget);
    expect(find.byType(LoadingView), findsNothing);
  });

  testWidgets('empty success shows EmptyView; success shows data', (tester) async {
    await pumpApp(tester, _builder(const DataState<List<String>>().success(const [])));
    expect(find.byType(EmptyView), findsOneWidget);

    await pumpApp(tester, _builder(const DataState<List<String>>().success(['x'])));
    expect(find.text('data:x'), findsOneWidget);
  });
}
