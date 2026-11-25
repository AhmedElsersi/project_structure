// Broadcasts 426/503 signals from the network layer to the app-config gate,
// so core/network never imports the gate (and vice versa).
//
// Source: corsa-customer api_service.dart onSystemOverride callback, made a
//         stream so any number of listeners can react.
import 'dart:async';

import 'interceptors/app_status_interceptor.dart';

class AppStatusEvent {
  const AppStatusEvent(this.signal, this.message);
  final AppStatusSignal signal;
  final String? message;
}

class AppStatusBus {
  final StreamController<AppStatusEvent> _controller = StreamController<AppStatusEvent>.broadcast();

  Stream<AppStatusEvent> get events => _controller.stream;

  void add(AppStatusSignal signal, String? message) => _controller.add(AppStatusEvent(signal, message));

  Future<void> dispose() => _controller.close();
}
