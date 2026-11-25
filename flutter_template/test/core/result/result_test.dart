// Tests for lib/core/result/result.dart. Source: new
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const failure = NotFoundFailure(code: 'missing');
  const Result<int> ok = Ok(2);
  const Result<int> err = Err(failure);

  group('constructors and getters', () {
    test('factories build the right branch', () {
      expect(const Result<int>.ok(1), isA<Ok<int>>());
      expect(const Result<int>.err(failure), isA<Err<int>>());
    });

    test('isOk / isErr / valueOrNull / failureOrNull', () {
      expect(ok.isOk, isTrue);
      expect(ok.isErr, isFalse);
      expect(ok.valueOrNull, 2);
      expect(ok.failureOrNull, isNull);
      expect(err.isOk, isFalse);
      expect(err.isErr, isTrue);
      expect(err.valueOrNull, isNull);
      expect(err.failureOrNull, failure);
    });

    test('Ok can carry null for nullable T', () {
      const Result<int?> nullable = Ok(null);
      expect(nullable.isOk, isTrue);
      expect(nullable.valueOrNull, isNull);
    });
  });

  group('fold (dartz order: failure first)', () {
    test('calls onSuccess for Ok', () {
      expect(ok.fold((f) => 'failure', (v) => 'value $v'), 'value 2');
    });

    test('calls onFailure for Err', () {
      expect(err.fold((f) => 'failure ${f.code}', (v) => 'value $v'), 'failure missing');
    });
  });

  test('when routes named callbacks', () {
    expect(ok.when(ok: (v) => v * 10, err: (_) => -1), 20);
    expect(err.when(ok: (v) => v * 10, err: (_) => -1), -1);
  });

  group('map', () {
    test('transforms Ok', () => expect(ok.map((v) => '$v!'), const Ok('2!')));

    test('passes Err through without calling transform', () {
      var called = false;
      final mapped = err.map((v) {
        called = true;
        return '$v';
      });
      expect(called, isFalse);
      expect(mapped, const Err<String>(failure));
    });
  });

  group('flatMap', () {
    test('chains Ok into Ok', () => expect(ok.flatMap((v) => Ok(v + 1)), const Ok(3)));

    test('chains Ok into Err', () {
      const other = ConflictFailure();
      expect(ok.flatMap<int>((_) => const Err(other)), const Err<int>(other));
    });

    test('short-circuits Err', () {
      var called = false;
      final result = err.flatMap((v) {
        called = true;
        return Ok(v);
      });
      expect(called, isFalse);
      expect(result, const Err<int>(failure));
    });
  });

  group('andThen', () {
    test('awaits next step on Ok', () async {
      expect(await ok.andThen((v) async => Ok('async $v')), const Ok('async 2'));
    });

    test('short-circuits Err', () async {
      var called = false;
      final result = await err.andThen((v) async {
        called = true;
        return Ok(v);
      });
      expect(called, isFalse);
      expect(result, const Err<int>(failure));
    });
  });

  group('mapFailure', () {
    test('transforms Err', () {
      expect(err.mapFailure((_) => const ForbiddenFailure()), const Err<int>(ForbiddenFailure()));
    });

    test('leaves Ok untouched', () {
      var called = false;
      final result = ok.mapFailure((f) {
        called = true;
        return f;
      });
      expect(called, isFalse);
      expect(identical(result, ok), isTrue);
    });
  });

  test('getOrElse', () {
    expect(ok.getOrElse((_) => -1), 2);
    expect(err.getOrElse((f) => f is NotFoundFailure ? -1 : -2), -1);
  });

  group('equality', () {
    test('Ok compares by value', () {
      expect(const Ok(1), const Ok(1));
      expect(Ok([1].length), const Ok(1));
      expect(const Ok(1), isNot(const Ok(2)));
      expect(const Ok(1).hashCode, Ok([1].length).hashCode);
    });

    test('Err compares by failure', () {
      expect(const Err<int>(NotFoundFailure(code: 'a')), const Err<int>(NotFoundFailure(code: 'a')));
      expect(const Err<int>(NotFoundFailure(code: 'a')), isNot(const Err<int>(NotFoundFailure(code: 'b'))));
      expect(const Err<int>(NotFoundFailure()), isNot(const Err<int>(ForbiddenFailure())));
    });

    test('Ok is never equal to Err', () {
      expect(ok == err, isFalse);
    });

    test('toString', () {
      expect(const Ok(1).toString(), 'Ok(1)');
      expect(err.toString(), startsWith('Err(NotFoundFailure'));
    });
  });

  test('okUnit is a successful Result<Unit>', () {
    expect(okUnit, isA<Ok<Unit>>());
    expect(okUnit.valueOrNull, same(Unit.value));
    expect(Unit.value.toString(), 'unit');
  });

  test('switch is exhaustive over the sealed class', () {
    String describe(Result<int> r) => switch (r) {
      Ok(:final value) => 'ok $value',
      Err(:final failure) => 'err ${failure.code}',
    };
    expect(describe(ok), 'ok 2');
    expect(describe(err), 'err missing');
  });
}
