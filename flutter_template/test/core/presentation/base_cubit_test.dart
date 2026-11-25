// Tests for lib/core/presentation/base_cubit.dart. Source: new
import 'dart:async';

import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/presentation/base_cubit.dart';
import 'package:app_template/core/result/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every routed callback as a string in its state.
class _LogCubit extends BaseCubit<List<String>> {
  _LogCubit() : super(const []);

  Future<void> load(Future<Result<String>> Function() call) => run<String>(
    call,
    onLoading: () => safeEmit([...state, 'loading']),
    onSuccess: (v) => safeEmit([...state, 'ok:$v']),
    onFailure: (f) => safeEmit([...state, 'err:${f.code ?? f.messageKey}']),
  );

  void push(String entry) => safeEmit([...state, entry]);
  void invalidate() => invalidatePending();
  void later(Duration delay, String entry) => debounce(delay, () => push(entry));
}

void main() {
  late _LogCubit cubit;

  setUp(() => cubit = _LogCubit());
  tearDown(() => cubit.close());

  test('success: loading then onSuccess', () async {
    await cubit.load(() async => const Ok('A'));
    expect(cubit.state, ['loading', 'ok:A']);
  });

  test('failure: loading then onFailure', () async {
    await cubit.load(() async => const Err(NotFoundFailure(code: 'missing')));
    expect(cubit.state, ['loading', 'err:missing']);
  });

  test('a stale result is dropped: slow A then fast B → only B is applied', () async {
    final slowA = Completer<Result<String>>();
    final a = cubit.load(() => slowA.future);
    final b = cubit.load(() async => const Ok('B'));
    await b;
    slowA.complete(const Ok('A'));
    await a;
    expect(cubit.state, ['loading', 'loading', 'ok:B']);
  });

  test('a stale failure is dropped too', () async {
    final slowA = Completer<Result<String>>();
    final a = cubit.load(() => slowA.future);
    await cubit.load(() async => const Ok('B'));
    slowA.complete(const Err(ServerFailure()));
    await a;
    expect(cubit.state, ['loading', 'loading', 'ok:B']);
  });

  test('invalidatePending drops the in-flight result', () async {
    final slow = Completer<Result<String>>();
    final a = cubit.load(() => slow.future);
    cubit.invalidate();
    slow.complete(const Ok('A'));
    await a;
    expect(cubit.state, ['loading']);
  });

  test('a result arriving after close is dropped without errors', () async {
    final slow = Completer<Result<String>>();
    final a = cubit.load(() => slow.future);
    await cubit.close();
    slow.complete(const Ok('A'));
    await a;
    expect(cubit.state, ['loading']);
  });

  test('CancelledFailure is never reported', () async {
    await cubit.load(() async => const Err(CancelledFailure()));
    expect(cubit.state, ['loading']);
  });

  test('a call that throws (programming error) is reported as UnknownFailure', () async {
    await cubit.load(() async => throw StateError('repository forgot to guard'));
    expect(cubit.state, ['loading', 'err:${const UnknownFailure().messageKey}']);
  });

  test('a stale throw is dropped', () async {
    final slow = Completer<Result<String>>();
    final a = cubit.load(() => slow.future);
    await cubit.load(() async => const Ok('B'));
    slow.completeError(StateError('late'));
    await a;
    expect(cubit.state, ['loading', 'loading', 'ok:B']);
  });

  test('safeEmit after close is a no-op', () async {
    cubit.push('before');
    await cubit.close();
    expect(() => cubit.push('after'), returnsNormally);
    expect(cubit.state, ['before']);
  });

  test('cancelToken is cancelled on close', () async {
    final token = cubit.cancelToken;
    expect(token.isCancelled, isFalse);
    await cubit.close();
    expect(token.isCancelled, isTrue);
  });

  test('renewCancelToken cancels the old token and returns a fresh one', () {
    final old = cubit.cancelToken;
    final fresh = cubit.renewCancelToken();
    expect(old.isCancelled, isTrue);
    expect(fresh.isCancelled, isFalse);
    expect(identical(cubit.cancelToken, fresh), isTrue);
    expect(old.cancelError?.type, DioExceptionType.cancel);
  });

  test('debounce keeps only the last action', () async {
    cubit
      ..later(const Duration(milliseconds: 30), 'first')
      ..later(const Duration(milliseconds: 30), 'second');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(cubit.state, ['second']);
  });

  test('close cancels a pending debounce', () async {
    cubit.later(const Duration(milliseconds: 20), 'never');
    await cubit.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state, isEmpty);
  });
}
