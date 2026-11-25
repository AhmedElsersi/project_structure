// Tests for lib/core/services/connectivity/connectivity_service.dart and
// connectivity_cubit.dart. Source: new
//
// The DNS probe is replaced by a scripted one; polling intervals are long so
// only explicit check() calls probe.
import 'package:app_template/core/services/connectivity/connectivity_cubit.dart';
import 'package:app_template/core/services/connectivity/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers probes from a script (last answer repeats).
class _ScriptedProbe {
  _ScriptedProbe(this.answers);
  final List<bool> answers;
  int calls = 0;

  Future<bool> call() async {
    final answer = answers[calls < answers.length ? calls : answers.length - 1];
    calls++;
    return answer;
  }
}

ConnectivityService _service(_ScriptedProbe probe) => ConnectivityService(
  probe: probe.call,
  onlineInterval: const Duration(hours: 1),
  offlineInterval: const Duration(hours: 1),
  offlineConfirmDelay: Duration.zero,
  listenToLifecycle: false,
  alwaysOnline: false,
);

void main() {
  group('ConnectivityService', () {
    test('optimistic before the first probe', () {
      final service = _service(_ScriptedProbe([false]));
      expect(service.isOnline, isTrue);
      service.dispose();
    });

    test('a single failed probe is not enough: the confirming re-probe recovers', () async {
      final probe = _ScriptedProbe([true, false, true]);
      final service = _service(probe);
      final events = <bool>[];
      final sub = service.onStatusChange.listen(events.add);

      await service.start(); // probe 1: online
      expect(await service.check(), isTrue); // probe 2 fails, probe 3 confirms online
      expect(probe.calls, 3);
      expect(service.isOnline, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(events, [true], reason: 'no offline flash');

      await sub.cancel();
      service.dispose();
    });

    test('offline only after the confirming re-probe also fails', () async {
      final probe = _ScriptedProbe([true, false, false]);
      final service = _service(probe);
      final events = <bool>[];
      final sub = service.onStatusChange.listen(events.add);

      await service.start();
      expect(await service.check(), isFalse);
      expect(probe.calls, 3);
      await Future<void>.delayed(Duration.zero);
      expect(events, [true, false]);

      // Already offline: the next failed probe is not re-confirmed.
      await service.check();
      expect(probe.calls, 4);

      await sub.cancel();
      service.dispose();
    });

    test('recovery is reported immediately', () async {
      final probe = _ScriptedProbe([false, false, true]);
      final service = _service(probe);
      final events = <bool>[];
      final sub = service.onStatusChange.listen(events.add);

      await service.start(); // two probes: offline confirmed
      expect(service.isOnline, isFalse);
      expect(await service.check(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(events, [false, true]);

      await sub.cancel();
      service.dispose();
    });

    test('concurrent checks share one probe run', () async {
      final probe = _ScriptedProbe([true]);
      final service = _service(probe);
      await Future.wait([service.check(), service.check(), service.check()]);
      expect(probe.calls, 1);
      service.dispose();
    });

    test('a throwing probe counts as offline', () async {
      final service = ConnectivityService(
        probe: () => throw StateError('dns'),
        offlineConfirmDelay: Duration.zero,
        listenToLifecycle: false,
        alwaysOnline: false,
      );
      expect(await service.check(), isFalse);
      service.dispose();
    });

    test('web (alwaysOnline) never probes', () async {
      final probe = _ScriptedProbe([false]);
      final service = ConnectivityService(probe: probe.call, alwaysOnline: true, listenToLifecycle: false);
      await service.start();
      expect(await service.check(), isTrue);
      expect(probe.calls, 0);
      service.dispose();
    });
  });

  group('ConnectivityCubit', () {
    test('going offline is debounced; a quick recovery never shows offline', () async {
      final probe = _ScriptedProbe([true]);
      final service = _service(probe);
      final cubit = ConnectivityCubit(service, offlineDelay: const Duration(milliseconds: 60));
      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      probe.answers
        ..clear()
        ..addAll([false, false]);
      await service.check(); // offline confirmed by the service
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state, ConnectivityStatus.online, reason: 'still inside the debounce');

      probe.answers
        ..clear()
        ..add(true);
      await service.check(); // back before the delay elapsed
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state, ConnectivityStatus.online);
      expect(states.where((s) => s.isOffline), isEmpty);

      await sub.cancel();
      await cubit.close();
      service.dispose();
    });

    test('a lasting outage becomes offline after the delay; recovery is immediate', () async {
      final probe = _ScriptedProbe([false]);
      final service = _service(probe);
      final cubit = ConnectivityCubit(service, offlineDelay: const Duration(milliseconds: 30));

      await service.check();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(cubit.state, ConnectivityStatus.offline);

      probe.answers
        ..clear()
        ..add(true);
      await service.check();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, ConnectivityStatus.online);

      await cubit.close();
      service.dispose();
    });

    test('recheck() probes and applies the result', () async {
      final probe = _ScriptedProbe([false]);
      final service = _service(probe);
      final cubit = ConnectivityCubit(service, offlineDelay: Duration.zero);
      await cubit.recheck();
      expect(cubit.state, ConnectivityStatus.offline);
      await cubit.close();
      service.dispose();
    });
  });
}
