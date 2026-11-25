// Tests for lib/core/app_config/app_config_cubit.dart. Source: new
//
// Fake repository + real AppStatusBus + MemoryKeyValueStore.
import 'package:app_template/core/app_config/app_config.dart';
import 'package:app_template/core/app_config/app_config_cubit.dart';
import 'package:app_template/core/app_config/app_config_repository.dart';
import 'package:app_template/core/app_config/update_policy.dart';
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/network/app_status_bus.dart';
import 'package:app_template/core/network/interceptors/app_status_interceptor.dart';
import 'package:app_template/core/result/result.dart';
import 'package:app_template/core/storage/key_value_store.dart';
import 'package:app_template/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements AppConfigRepository {
  final List<Result<AppConfig>> responses = [];
  AppConfig? cache;
  int fetches = 0;

  @override
  Future<Result<AppConfig>> fetch() async {
    fetches++;
    return responses.isEmpty ? const Err(NetworkFailure()) : responses.removeAt(0);
  }

  @override
  AppConfig? cached() => cache;
}

AppConfig _android({bool maintenance = false, int? min, int? latest, Map<String, String> message = const {}}) =>
    AppConfig(
      maintenance: maintenance,
      maintenanceMessage: message,
      android: PlatformUpdatePolicy(minBuild: min, latestBuild: latest, storeUrl: 'https://store.example/app'),
    );

void main() {
  late _FakeRepository repo;
  late AppStatusBus bus;
  late MemoryKeyValueStore store;
  late DateTime now;

  AppConfigCubit build({int installedBuild = 10}) => AppConfigCubit(
    repository: repo,
    statusBus: bus,
    store: store,
    installedBuild: installedBuild,
    platform: 'android',
    clock: () => now,
  );

  setUp(() {
    repo = _FakeRepository();
    bus = AppStatusBus();
    store = MemoryKeyValueStore();
    now = DateTime(2026, 1, 1, 12);
  });

  tearDown(() => bus.dispose());

  test('starts with no gate', () async {
    final cubit = build();
    expect(cubit.state.decision, GateDecision.none);
    expect(cubit.state.hasLoaded, isFalse);
    await cubit.close();
  });

  test('a live config below min → forceUpdate; storeUrl comes from the config', () async {
    repo.responses.add(Ok(_android(min: 11, latest: 12)));
    final cubit = build();
    await cubit.load();
    expect(cubit.state.decision, GateDecision.forceUpdate);
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.storeUrl, 'https://store.example/app');
    await cubit.close();
  });

  test('a live maintenance config → maintenance (message read per language by the view)', () async {
    repo.responses.add(Ok(_android(maintenance: true, message: {'en': 'Soon'})));
    final cubit = build();
    await cubit.load();
    expect(cubit.state.decision, GateDecision.maintenance);
    expect(cubit.state.message, isNull);
    expect(cubit.state.config?.maintenanceMessageFor('en'), 'Soon');
    await cubit.close();
  });

  test('failed fetch with no cache → none', () async {
    repo.responses.add(const Err(ServerFailure(statusCode: 500)));
    final cubit = build();
    await cubit.load();
    expect(cubit.state.decision, GateDecision.none);
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.isLoading, isFalse);
    await cubit.close();
  });

  test('a cached config never forces or maintains on its own', () async {
    repo.cache = _android(maintenance: true, min: 99, latest: 99);
    final cubit = build();
    await cubit.load(); // fails (no responses queued)
    expect(cubit.state.decision, GateDecision.none);
    await cubit.close();
  });

  test('a cached config may still offer the optional prompt', () async {
    repo.cache = _android(min: 1, latest: 20);
    final cubit = build();
    await cubit.load();
    expect(cubit.state.decision, GateDecision.optionalUpdate);
    expect(cubit.state.shouldShowOptionalPrompt, isTrue);
    await cubit.close();
  });

  test('426 on the status bus → forceUpdate with the server message, and it sticks', () async {
    final cubit = build();
    bus.add(AppStatusSignal.upgradeRequired, 'Please update');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.decision, GateDecision.forceUpdate);
    expect(cubit.state.message, 'Please update');

    // A later config that says "fine" can't un-force a binary the API rejected.
    repo.responses.add(Ok(_android(min: 1, latest: 10)));
    await cubit.load();
    expect(cubit.state.decision, GateDecision.forceUpdate);
    await cubit.close();
  });

  test('503 on the status bus → maintenance; a successful load clears it', () async {
    final cubit = build();
    bus.add(AppStatusSignal.maintenance, 'Back at 5');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.decision, GateDecision.maintenance);
    expect(cubit.state.message, 'Back at 5');

    // Retry while the backend is still unreachable keeps the live gate.
    repo.responses.add(const Err(NetworkFailure()));
    await cubit.load();
    expect(cubit.state.decision, GateDecision.maintenance);

    repo.responses.add(Ok(_android(min: 1, latest: 10)));
    await cubit.load();
    expect(cubit.state.decision, GateDecision.none);
    expect(cubit.state.message, isNull);
    await cubit.close();
  });

  test('a 503 / 426 failure from the config endpoint itself raises the gate', () async {
    repo.responses.add(const Err(MaintenanceFailure(serverMessage: 'Down')));
    final cubit = build();
    await cubit.load();
    expect(cubit.state.decision, GateDecision.maintenance);
    expect(cubit.state.message, 'Down');

    repo.responses.add(const Err(UpgradeRequiredFailure()));
    await cubit.load();
    expect(cubit.state.decision, GateDecision.forceUpdate);
    await cubit.close();
  });

  test('optional prompt shows once per latest build', () async {
    repo.responses.add(Ok(_android(min: 1, latest: 12)));
    final cubit = build();
    await cubit.load();
    expect(cubit.state.shouldShowOptionalPrompt, isTrue);

    await cubit.markOptionalPromptShown();
    expect(cubit.state.shouldShowOptionalPrompt, isFalse);
    expect(cubit.state.decision, GateDecision.optionalUpdate, reason: 'the decision itself stays true');
    expect(store.getInt(StorageKeys.lastOptionalUpdatePrompt), 12);

    // Same latest build on the next launch: no prompt.
    repo.responses.add(Ok(_android(min: 1, latest: 12)));
    final next = build();
    await next.load();
    expect(next.state.shouldShowOptionalPrompt, isFalse);

    // A newer release prompts again.
    repo.responses.add(Ok(_android(min: 1, latest: 13)));
    await next.load();
    expect(next.state.shouldShowOptionalPrompt, isTrue);
    await cubit.close();
    await next.close();
  });

  test('refreshIfStale fetches at most once per interval', () async {
    final cubit = build();
    await cubit.load();
    expect(repo.fetches, 1);

    now = now.add(const Duration(seconds: 30));
    await cubit.refreshIfStale();
    expect(repo.fetches, 1);

    now = now.add(const Duration(seconds: 31));
    await cubit.refreshIfStale();
    expect(repo.fetches, 2);
    await cubit.close();
  });

  test('unknown installed build never gates', () async {
    repo.responses.add(Ok(_android(min: 50, latest: 60)));
    final cubit = build(installedBuild: 0);
    await cubit.load();
    expect(cubit.state.decision, GateDecision.none);
    await cubit.close();
  });
}
