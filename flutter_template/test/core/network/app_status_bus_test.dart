// Tests for lib/core/network/app_status_bus.dart. Source: new
import 'package:app_template/core/network/app_status_bus.dart';
import 'package:app_template/core/network/interceptors/app_status_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('broadcasts signals to every listener', () async {
    final bus = AppStatusBus();
    final a = <AppStatusSignal>[];
    final b = <String?>[];
    final subA = bus.events.listen((e) => a.add(e.signal));
    final subB = bus.events.listen((e) => b.add(e.message));

    bus
      ..add(AppStatusSignal.maintenance, 'Back soon')
      ..add(AppStatusSignal.upgradeRequired, null);
    await pumpEventQueue();

    expect(a, [AppStatusSignal.maintenance, AppStatusSignal.upgradeRequired]);
    expect(b, ['Back soon', null]);
    await subA.cancel();
    await subB.cancel();
    await bus.dispose();
  });
}
