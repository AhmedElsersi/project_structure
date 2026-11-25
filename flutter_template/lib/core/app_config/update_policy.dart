// Pure decision: given the config and the installed build, what does the app
// show — nothing, an optional update prompt, a forced update or maintenance?
//
// Source: chinaparts-customer app_config_state.dart `gate` (resolution order:
//         maintenance, then the hard floor, then the optional prompt; "can't
//         tell" never blocks).
// Merged: baytna lib/features/config/domain/entities/app_config.dart
//         (UpdatePolicy.requirementFor on integer builds; a policy whose
//         minimum is above the latest build "bricks every install" and is
//         treated as invalid).
// See docs/SERVICES.md#app-config.
import 'app_config.dart';

enum GateDecision {
  none,
  optionalUpdate,
  forceUpdate,
  maintenance;

  /// Maintenance and force update replace the whole app.
  bool get isBlocking => this == GateDecision.forceUpdate || this == GateDecision.maintenance;
}

abstract final class UpdatePolicy {
  /// Any doubt — no config, unknown platform, unknown installed build (≤ 0),
  /// missing or inconsistent numbers — resolves to [GateDecision.none]: a bad
  /// config must never lock users out.
  static GateDecision decide({AppConfig? config, required int installedBuild, required String platform}) {
    if (config == null) return GateDecision.none;
    if (config.maintenance) return GateDecision.maintenance;

    final policy = config.policyFor(platform);
    if (policy == null || installedBuild <= 0) return GateDecision.none;

    final min = policy.minBuild;
    final latest = policy.latestBuild;
    // min > latest would force an update to a build that doesn't exist yet.
    if (min != null && latest != null && min > latest) return GateDecision.none;

    if (min != null && installedBuild < min) return GateDecision.forceUpdate;
    if (latest != null && installedBuild < latest) return GateDecision.optionalUpdate;
    return GateDecision.none;
  }
}
