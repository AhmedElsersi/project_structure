// App-wide online/offline state for the offline banner and screens.
// Going online is immediate; going offline is debounced so a brief drop never
// flashes the banner.
//
// Source: baytna lib/core/network/connectivity_cubit.dart (app-wide cubit fed by
//         a connectivity stream, optimistic initial state so a healthy cold
//         start never shows the banner).
// Merged: offline debounce is new (asymmetric: recoveries show at once).
// See docs/SERVICES.md#connectivity.
import 'dart:async';

import '../../presentation/base_cubit.dart';
import 'connectivity_service.dart';

enum ConnectivityStatus {
  online,
  offline;

  bool get isOnline => this == ConnectivityStatus.online;
  bool get isOffline => this == ConnectivityStatus.offline;
}

class ConnectivityCubit extends BaseCubit<ConnectivityStatus> {
  ConnectivityCubit(this._service, {this.offlineDelay = const Duration(seconds: 2)})
    : super(_service.isOnline ? ConnectivityStatus.online : ConnectivityStatus.offline) {
    _subscription = _service.onStatusChange.listen(_onChange);
  }

  final ConnectivityService _service;

  /// How long the service must keep reporting offline before the UI says so.
  final Duration offlineDelay;

  late final StreamSubscription<bool> _subscription;
  Timer? _offlineTimer;

  /// Forces a probe now (e.g. a "Retry" button on an offline screen).
  Future<void> recheck() async {
    final online = await _service.check();
    _onChange(online);
  }

  void _onChange(bool online) {
    if (online) {
      _offlineTimer?.cancel();
      _offlineTimer = null;
      safeEmit(ConnectivityStatus.online);
      return;
    }
    if (state.isOffline || (_offlineTimer?.isActive ?? false)) return;
    if (offlineDelay <= Duration.zero) {
      safeEmit(ConnectivityStatus.offline);
      return;
    }
    _offlineTimer = Timer(offlineDelay, () {
      _offlineTimer = null;
      if (!_service.isOnline) safeEmit(ConnectivityStatus.offline);
    });
  }

  @override
  Future<void> close() async {
    _offlineTimer?.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
