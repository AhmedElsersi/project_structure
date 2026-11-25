// Dependency-free internet reachability: DNS probe of two hosts, adaptive
// polling, offline confirmed by a second probe, re-check on app resume.
//
// Source: tebbr lib/core/services/connectivity_service.dart (DNS lookup with a
//         timeout over two hosts, 15 s online / 4 s offline polling, a fresh
//         offline result re-probed after a short delay so a suspension blip
//         never flips the UI, immediate re-check on resume).
// Merged: corsa-customer lib/core/services/connectivity_service.dart (same
//         design, trimmed); AppLifecycleListener instead of a binding
//         observer; injectable probe/timings for tests; web → always online.
// See docs/SERVICES.md#connectivity.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Returns true when the internet is reachable. Injected in tests.
typedef ReachabilityProbe = Future<bool> Function();

class ConnectivityService {
  ConnectivityService({
    ReachabilityProbe? probe,
    this.hosts = const ['one.one.one.one', 'google.com'],
    this.onlineInterval = const Duration(seconds: 15),
    this.offlineInterval = const Duration(seconds: 4),
    this.lookupTimeout = const Duration(seconds: 3),
    this.offlineConfirmDelay = const Duration(milliseconds: 1200),
    this.listenToLifecycle = true,
    bool? alwaysOnline,
  }) : _alwaysOnline = alwaysOnline ?? kIsWeb {
    _probe = probe ?? _dnsProbe;
  }

  /// Hosts tried in order; one answer is enough (a single CDN outage must not
  /// fake "offline").
  final List<String> hosts;
  final Duration onlineInterval;
  final Duration offlineInterval;
  final Duration lookupTimeout;

  /// Delay before the confirming re-probe of a fresh offline result.
  final Duration offlineConfirmDelay;

  /// Re-check immediately when the app returns to the foreground.
  final bool listenToLifecycle;

  /// Web has no DNS API (and browsers report reachability poorly): always online.
  final bool _alwaysOnline;

  late final ReachabilityProbe _probe;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  AppLifecycleListener? _lifecycle;
  Timer? _timer;
  bool? _last;
  bool _started = false;
  bool _disposed = false;
  Future<bool>? _inFlight;

  /// Emits only on changes (true = online).
  Stream<bool> get onStatusChange => _controller.stream;

  /// Last known status. Optimistic (true) until the first probe completes, so
  /// a cold start never flashes "offline".
  bool get isOnline => _last ?? true;

  /// Starts polling and the resume listener. Safe to call twice.
  Future<void> start() async {
    if (_started || _disposed || _alwaysOnline) return;
    _started = true;
    if (listenToLifecycle) {
      _lifecycle = AppLifecycleListener(onResume: () => unawaited(check()));
    }
    await check();
  }

  /// Probes now (coalescing concurrent calls), reschedules polling and
  /// returns the status. The stream is updated only if the status changed.
  Future<bool> check() {
    if (_alwaysOnline || _disposed) return Future.value(isOnline);
    return _inFlight ??= _runCheck().whenComplete(() {
      _inFlight = null;
      _schedule();
    });
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    unawaited(_controller.close());
  }

  void _schedule() {
    _timer?.cancel();
    if (_disposed || !_started) return;
    _timer = Timer(isOnline ? onlineInterval : offlineInterval, () => unawaited(check()));
  }

  Future<bool> _runCheck() async {
    var online = await _safeProbe();
    // A fresh online → offline transition is confirmed by a second probe, so a
    // momentary blip (returning from a browser / payment sheet) never flips
    // the banner. A real outage fails both.
    if (!online && (_last ?? true)) {
      if (offlineConfirmDelay > Duration.zero) await Future<void>.delayed(offlineConfirmDelay);
      if (_disposed) return isOnline;
      online = await _safeProbe();
    }
    if (_disposed) return isOnline;
    if (online != _last) {
      _last = online;
      if (!_controller.isClosed) _controller.add(online);
    }
    return online;
  }

  Future<bool> _safeProbe() async {
    try {
      return await _probe();
    } on Object {
      return false;
    }
  }

  Future<bool> _dnsProbe() async {
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host).timeout(lookupTimeout);
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) return true;
      } on Object {
        // SocketException / TimeoutException: try the next host.
      }
    }
    return false;
  }
}
