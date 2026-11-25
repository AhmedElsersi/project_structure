// Tests for lib/core/router/router_refresh_stream.dart. Source: new
import 'dart:async';

import 'package:app_template/core/router/router_refresh_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notifies on events from every stream and stops after dispose', () async {
    final a = StreamController<int>.broadcast();
    final b = StreamController<String>();
    final refresh = RouterRefreshStream([a.stream, b.stream]);
    var notifications = 0;
    refresh.addListener(() => notifications++);

    a.add(1);
    b.add('x');
    a.add(2);
    await pumpEventQueue();
    expect(notifications, 3);

    refresh.dispose();
    a.add(3);
    await pumpEventQueue();
    expect(notifications, 3);

    await a.close();
    await b.close();
  });

  test('dispose releases the source streams', () async {
    final source = StreamController<int>.broadcast();
    final refresh = RouterRefreshStream([source.stream]);
    expect(source.hasListener, isTrue);
    refresh.dispose();
    await pumpEventQueue();
    expect(source.hasListener, isFalse);
    await source.close();
  });
}
