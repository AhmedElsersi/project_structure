// Debouncer (last call wins after a quiet period) and Throttler (leading edge,
// then at most once per interval).
//
// Source: tebbr lib/core/utilities/timing/request_limiters.dart (Debouncer with
//         flush so a pending action is never lost on dispose; leading-edge
//         Throttler with reset).
// Merged: the pending action is stored, so flush() needs no argument; the
//         Throttler takes a clock for deterministic tests.
// See docs/SERVICES.md#debouncer.
import 'dart:async';

/// Runs the latest action once [duration] has passed without another [run].
///
/// ```dart
/// final _search = Debouncer(const Duration(milliseconds: 400));
/// onChanged: (q) => _search.run(() => cubit.search(q)),
/// dispose: _search.dispose();
/// ```
class Debouncer {
  Debouncer(this.duration);

  final Duration duration;
  Timer? _timer;
  void Function()? _pending;

  /// Whether an action is waiting to run.
  bool get isPending => _timer?.isActive ?? false;

  /// Schedules [action], replacing any pending one.
  void run(void Function() action) {
    _timer?.cancel();
    _pending = action;
    _timer = Timer(duration, _fire);
  }

  /// Runs the pending action now (if any). Use when leaving a screen so the
  /// last change is still saved / sent.
  void flush() {
    if (!isPending) return;
    _timer?.cancel();
    _fire();
  }

  /// Drops the pending action without running it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  void dispose() => cancel();

  void _fire() {
    final action = _pending;
    _pending = null;
    _timer = null;
    action?.call();
  }
}

/// Runs the first call immediately, then ignores calls until [interval] has
/// passed (typing indicators, "refresh" taps, scroll-end loads).
class Throttler {
  Throttler(this.interval, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final Duration interval;
  final DateTime Function() _now;
  DateTime? _lastRun;

  /// Runs [action] unless one ran within [interval]. Returns whether it ran.
  bool run(void Function() action) {
    final now = _now();
    final last = _lastRun;
    if (last != null && now.difference(last) < interval) return false;
    _lastRun = now;
    action();
    return true;
  }

  /// Forgets the last run so the next [run] fires immediately.
  void reset() => _lastRun = null;

  void dispose() => reset();
}
