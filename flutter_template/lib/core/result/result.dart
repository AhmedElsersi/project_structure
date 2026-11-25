// Sealed success/failure result returned by every repository and use case.
//
// Source: new (approved decision C1). Replaces dartz `Either<Failure, T>` used by
//         brgr, tebbr, chinaparts-customer/seller, corsa, instaops, petrobe, baytna.
//         `fold(onFailure, onSuccess)` keeps dartz's argument order so old call
//         sites (`result.fold((f) => ..., (data) => ...)`) read the same.
// See docs/SERVICES.md#result.
import '../errors/failure.dart';

/// The outcome of an operation that can fail with a [Failure].
///
/// Use `switch` for exhaustive handling:
/// ```dart
/// switch (await repo.fetch()) {
///   case Ok(:final value): ...
///   case Err(:final failure): ...
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// A successful result holding [value].
  const factory Result.ok(T value) = Ok<T>;

  /// A failed result holding [failure].
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value, or `null` on failure.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure, or `null` on success.
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// Collapses both branches into one value (dartz-compatible order).
  R fold<R>(R Function(Failure failure) onFailure, R Function(T value) onSuccess) => switch (this) {
    Ok<T>(:final value) => onSuccess(value),
    Err<T>(:final failure) => onFailure(failure),
  };

  /// Named-argument variant of [fold].
  R when<R>({required R Function(T value) ok, required R Function(Failure failure) err}) => fold(err, ok);

  /// Transforms the success value; failures pass through.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// Chains another fallible step; failures short-circuit.
  Result<R> flatMap<R>(Result<R> Function(T value) next) => switch (this) {
    Ok<T>(:final value) => next(value),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// Async variant of [flatMap].
  Future<Result<R>> andThen<R>(Future<Result<R>> Function(T value) next) async => switch (this) {
    Ok<T>(:final value) => next(value),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// Transforms the failure; successes pass through.
  Result<T> mapFailure(Failure Function(Failure failure) transform) => switch (this) {
    Ok<T>() => this,
    Err<T>(:final failure) => Err<T>(transform(failure)),
  };

  /// The value, or [fallback] on failure.
  T getOrElse(T Function(Failure failure) fallback) => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>(:final failure) => fallback(failure),
  };
}

/// Success branch of [Result].
final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// Failure branch of [Result].
final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}

/// Convenience alias for async results.
typedef FutureResult<T> = Future<Result<T>>;

/// The unit value for operations that succeed without data.
final class Unit {
  const Unit._();
  static const Unit value = Unit._();
  @override
  String toString() => 'unit';
}

/// `Result<Unit>` success constant.
const Result<Unit> okUnit = Ok<Unit>(Unit.value);
