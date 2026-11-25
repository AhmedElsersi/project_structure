// Wraps data-source calls into Result, mapping and reporting unexpected errors.
//
// Source: chinaparts-customer lib/core/base_architecture/data/repository/base_repo.dart
//         (catches non-Failure throws too and reports them — the house-style
//         versions only caught Failure, so TypeErrors escaped to the UI).
// See docs/ARCHITECTURE.md#data-flow.
import '../errors/error_mapper.dart';
import '../errors/failure.dart';
import '../result/result.dart';

/// Optional sink for unexpected errors (wired to ErrorReporter in DI).
typedef UnexpectedErrorSink = void Function(Object error, StackTrace stack);

/// Mix into repository implementations:
/// ```dart
/// class ItemsRepositoryImpl with RepositoryGuard implements ItemsRepository {
///   Future<Result<Item>> byId(String id) => guard(() => _remote.byId(id));
/// }
/// ```
mixin RepositoryGuard {
  /// Set once at startup (see bootstrap). Never shown to users.
  static UnexpectedErrorSink? onUnexpectedError;

  Future<Result<T>> guard<T>(Future<T> Function() call) async {
    try {
      return Ok<T>(await call());
    } on Failure catch (f) {
      return Err<T>(f);
    } on Object catch (e, stack) {
      final failure = ErrorMapper.fromObject(e);
      if (failure is UnknownFailure || failure is ServerFailure) {
        onUnexpectedError?.call(e, stack);
      }
      return Err<T>(failure);
    }
  }
}
