// App-wide gate state: maintenance / force update / optional update, from the
// remote config AND from live 426 / 503 responses on any endpoint.
//
// Source: chinaparts-customer lib/features/app_config/presentation/managers/
//         app_config_cubit/* (singleton; a cached config never raises a gate;
//         a failed refresh keeps a gate a live fetch raised; refreshIfStale on
//         resume; optional prompt remembered per version).
// Merged: corsa-customer system_config_gate.dart + api_service.dart (426 →
//         force update, 503 → maintenance, raised from any request);
//         tebbr lib/main.dart _SystemConfigGate (resume refresh throttled to
//         one per minute); baytna app_config_cubit.dart (installed build held
//         in the cubit so the gate never awaits a plugin while building).
// See docs/SERVICES.md#app-config.
import 'dart:async';

import 'package:equatable/equatable.dart';

import '../errors/failure.dart';
import '../network/app_status_bus.dart';
import '../network/interceptors/app_status_interceptor.dart';
import '../presentation/base_cubit.dart';
import '../storage/key_value_store.dart';
import '../storage/storage_keys.dart';
import 'app_config.dart';
import 'app_config_repository.dart';
import 'update_policy.dart';

class AppConfigState extends Equatable {
  const AppConfigState({
    this.decision = GateDecision.none,
    this.config,
    this.message,
    this.isLoading = false,
    this.hasLoaded = false,
    this.optionalPromptDue = false,
  });

  final GateDecision decision;

  /// Last live config, or the cached one before the first successful fetch.
  final AppConfig? config;

  /// Server text that came with a 426 / 503 response (already localized by
  /// the backend via Accept-Language). Null for config-driven gates.
  final String? message;

  final bool isLoading;

  /// True once a load finished (success or failure).
  final bool hasLoaded;

  /// The optional prompt hasn't been shown yet for the current latest build.
  final bool optionalPromptDue;

  bool get shouldShowOptionalPrompt => decision == GateDecision.optionalUpdate && optionalPromptDue;

  AppConfigState copyWith({
    GateDecision? decision,
    AppConfig? config,
    String? Function()? message,
    bool? isLoading,
    bool? hasLoaded,
    bool? optionalPromptDue,
  }) => AppConfigState(
    decision: decision ?? this.decision,
    config: config ?? this.config,
    message: message == null ? this.message : message(),
    isLoading: isLoading ?? this.isLoading,
    hasLoaded: hasLoaded ?? this.hasLoaded,
    optionalPromptDue: optionalPromptDue ?? this.optionalPromptDue,
  );

  @override
  List<Object?> get props => [decision, config, message, isLoading, hasLoaded, optionalPromptDue];
}

class AppConfigCubit extends BaseCubit<AppConfigState> {
  AppConfigCubit({
    required AppConfigRepository repository,
    required AppStatusBus statusBus,
    required KeyValueStore store,
    required int installedBuild,
    required String platform,
    this.refreshInterval = const Duration(minutes: 1),
    DateTime Function()? clock,
  }) : _repository = repository,
       _store = store,
       _installedBuild = installedBuild,
       _platform = platform,
       _now = clock ?? DateTime.now,
       super(AppConfigState(config: _safeCached(repository))) {
    _statusSub = statusBus.events.listen(_onStatus);
  }

  final AppConfigRepository _repository;
  final KeyValueStore _store;
  final int _installedBuild;
  final String _platform;
  final DateTime Function() _now;

  /// Minimum time between two [refreshIfStale] fetches.
  final Duration refreshInterval;

  late final StreamSubscription<AppStatusEvent> _statusSub;
  DateTime? _lastLoadAt;

  /// A 426 was received in this process: the binary is too old, and only a
  /// new install can change that, so it stays forced until restart.
  bool _upgradeRequired = false;

  /// Store listing from the config for this platform (null → caller's default).
  String? get storeUrl => state.config?.policyFor(_platform)?.storeUrl;

  /// Fetches the config and recomputes the gate. Call at startup; the
  /// maintenance view's retry calls it too.
  Future<void> load() {
    _lastLoadAt = _now();
    return run<AppConfig>(
      _repository.fetch,
      onLoading: () => safeEmit(state.copyWith(isLoading: true)),
      onSuccess: (config) => safeEmit(_fromLiveConfig(config)),
      onFailure: (failure) => safeEmit(_afterFailure(failure)),
    );
  }

  /// For app resume: fetches only if the last load is older than
  /// [refreshInterval], so quick app switches don't hammer the endpoint.
  Future<void> refreshIfStale() async {
    if (state.isLoading) return;
    final last = _lastLoadAt;
    if (last != null && _now().difference(last) < refreshInterval) return;
    await load();
  }

  /// Records that the optional prompt was shown for the current latest build,
  /// so it appears once per release, not once per launch.
  Future<void> markOptionalPromptShown() async {
    safeEmit(state.copyWith(optionalPromptDue: false));
    final latest = state.config?.policyFor(_platform)?.latestBuild;
    if (latest != null) await _store.setInt(StorageKeys.lastOptionalUpdatePrompt, latest);
  }

  AppConfigState _fromLiveConfig(AppConfig config) {
    var decision = UpdatePolicy.decide(config: config, installedBuild: _installedBuild, platform: _platform);
    if (_upgradeRequired && decision != GateDecision.maintenance) decision = GateDecision.forceUpdate;
    return AppConfigState(
      decision: decision,
      config: config,
      message: _upgradeRequired && decision == GateDecision.forceUpdate ? state.message : null,
      hasLoaded: true,
      optionalPromptDue: decision == GateDecision.optionalUpdate && _promptDue(config),
    );
  }

  AppConfigState _afterFailure(Failure failure) {
    if (failure is UpgradeRequiredFailure) {
      _upgradeRequired = true;
      return _blocked(GateDecision.forceUpdate, failure.serverMessage);
    }
    if (failure is MaintenanceFailure) return _blocked(GateDecision.maintenance, failure.serverMessage);

    // A gate a live response raised stays until a successful fetch clears it.
    if (state.decision.isBlocking) return state.copyWith(isLoading: false, hasLoaded: true);

    // No live config: the cache may only offer the optional prompt.
    final cached = _safeCached(_repository);
    final fromCache = UpdatePolicy.decide(config: cached, installedBuild: _installedBuild, platform: _platform);
    final decision = fromCache == GateDecision.optionalUpdate ? fromCache : GateDecision.none;
    return AppConfigState(
      decision: decision,
      config: cached ?? state.config,
      hasLoaded: true,
      optionalPromptDue: decision == GateDecision.optionalUpdate && cached != null && _promptDue(cached),
    );
  }

  void _onStatus(AppStatusEvent event) {
    switch (event.signal) {
      case AppStatusSignal.upgradeRequired:
        _upgradeRequired = true;
        // Maintenance still wins while it lasts; the force screen follows.
        if (state.decision != GateDecision.maintenance) {
          safeEmit(_blocked(GateDecision.forceUpdate, event.message));
        }
      case AppStatusSignal.maintenance:
        safeEmit(_blocked(GateDecision.maintenance, event.message));
    }
  }

  AppConfigState _blocked(GateDecision decision, String? message) => state.copyWith(
    decision: decision,
    message: () => message ?? (state.decision == decision ? state.message : null),
    isLoading: false,
    hasLoaded: true,
    optionalPromptDue: false,
  );

  bool _promptDue(AppConfig config) {
    final latest = config.policyFor(_platform)?.latestBuild;
    return latest != null && _store.getInt(StorageKeys.lastOptionalUpdatePrompt) != latest;
  }

  static AppConfig? _safeCached(AppConfigRepository repository) {
    try {
      return repository.cached();
    } on Object {
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _statusSub.cancel();
    return super.close();
  }
}
