// Tests for lib/core/data/repository_guard.dart. Source: new
//
// Lives under test/core/errors/ because it is about mapping/reporting errors.
import 'dart:io';

import 'package:app_template/core/data/repository_guard.dart';
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo with RepositoryGuard {}

void main() {
  final repo = _Repo();
  final reported = <Object>[];

  setUp(() {
    reported.clear();
    RepositoryGuard.onUnexpectedError = (error, _) => reported.add(error);
  });

  tearDown(() => RepositoryGuard.onUnexpectedError = null);

  test('returns Ok with the value on success', () async {
    expect(await repo.guard(() async => 42), const Ok(42));
    expect(reported, isEmpty);
  });

  test('a thrown Failure becomes Err without reporting', () async {
    const failure = NotFoundFailure(code: 'item_missing');
    final result = await repo.guard<int>(() async => throw failure);
    expect(result, const Err<int>(failure));
    expect(reported, isEmpty);
  });

  test('an unknown error becomes Err(UnknownFailure) and is reported', () async {
    final error = StateError('bug in parser');
    final result = await repo.guard<int>(() async => throw error);
    expect(result.failureOrNull, isA<UnknownFailure>());
    expect(result.failureOrNull!.debugMessage, contains('bug in parser'));
    expect(reported, [error]);
  });

  test('a synchronous throw inside the call is caught too', () async {
    final result = await repo.guard<int>(() => throw TypeError());
    expect(result.failureOrNull, isA<UnknownFailure>());
    expect(reported, hasLength(1));
  });

  test('FormatException maps to ServerFailure and is reported', () async {
    final result = await repo.guard<int>(() async => throw const FormatException('bad json'));
    expect(result.failureOrNull, isA<ServerFailure>());
    expect(reported, hasLength(1));
  });

  test('expected platform errors are mapped but not reported', () async {
    final result = await repo.guard<int>(() async => throw const SocketException('offline'));
    expect(result.failureOrNull, isA<NetworkFailure>());
    expect(reported, isEmpty);
  });

  test('works without a sink', () async {
    RepositoryGuard.onUnexpectedError = null;
    final result = await repo.guard<int>(() async => throw StateError('x'));
    expect(result.isErr, isTrue);
  });
}
