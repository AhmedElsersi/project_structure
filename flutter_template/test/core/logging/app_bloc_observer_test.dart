// Tests for lib/core/logging/app_bloc_observer.dart. Source: new
import 'package:app_template/core/logging/app_bloc_observer.dart';
import 'package:app_template/core/logging/app_logger.dart';
import 'package:app_template/core/services/error_reporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';

class _RecordingReporter implements ErrorReporter {
  final List<(Object, String?)> errors = [];

  @override
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false, String? reason}) async =>
      errors.add((error, reason));

  @override
  Future<void> setUserId(String? id) async {}

  @override
  void log(String message) {}
}

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);
  void fail(Object error) => addError(error, StackTrace.current);
}

void main() {
  late BlocObserver previous;

  setUp(() => previous = Bloc.observer);
  tearDown(() => Bloc.observer = previous);

  test('bloc errors go to the logger and the error reporter', () async {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final reporter = _RecordingReporter();
    Bloc.observer = AppBlocObserver(
      logger: AppLogger(talker: talker),
      reporter: reporter,
    );

    final cubit = _CounterCubit();
    final error = StateError('cubit exploded');
    cubit.fail(error);
    await cubit.close();

    expect(reporter.errors, hasLength(1));
    expect(reporter.errors.single.$1, same(error));
    expect(reporter.errors.single.$2, contains('bloc:'));
    expect(talker.history, isNotEmpty);
  });

  test('state changes are not logged unless verbose', () async {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    Bloc.observer = AppBlocObserver(
      logger: AppLogger(talker: talker),
      reporter: _RecordingReporter(),
    );
    final cubit = _CounterCubit()..emit(1);
    await cubit.close();
    expect(talker.history, isEmpty);
  });
}
