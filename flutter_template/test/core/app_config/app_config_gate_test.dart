// Widget tests for lib/shared/widgets/app_gate/app_config_gate.dart. Source: new
//
// The gate sits in MaterialApp.builder (as in app.dart) with a real
// AppConfigCubit fed by a fake repository and a real AppStatusBus.
import 'dart:async';

import 'package:app_template/core/app_config/app_config.dart';
import 'package:app_template/core/app_config/app_config_cubit.dart';
import 'package:app_template/core/app_config/app_config_repository.dart';
import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/network/app_status_bus.dart';
import 'package:app_template/core/network/interceptors/app_status_interceptor.dart';
import 'package:app_template/core/result/result.dart';
import 'package:app_template/core/storage/key_value_store.dart';
import 'package:app_template/core/storage/storage_keys.dart';
import 'package:app_template/shared/widgets/app_gate/app_config_gate.dart';
import 'package:app_template/shared/widgets/app_gate/force_update_view.dart';
import 'package:app_template/shared/widgets/app_gate/maintenance_view.dart';
import 'package:app_template/shared/widgets/app_gate/optional_update_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/support/l10n_app.dart';

class _FakeRepository implements AppConfigRepository {
  final List<Result<AppConfig>> responses = [];
  int fetches = 0;

  @override
  Future<Result<AppConfig>> fetch() async {
    fetches++;
    return responses.isEmpty ? const Err(NetworkFailure()) : responses.removeAt(0);
  }

  @override
  AppConfig? cached() => null;
}

const _homeKey = Key('home');

void main() {
  setUpAll(setUpL10n);

  late _FakeRepository repo;
  late AppStatusBus bus;
  late MemoryKeyValueStore store;
  late AppConfigCubit cubit;
  late List<String?> storeRequests;
  late bool storeOpens;
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() {
    repo = _FakeRepository();
    bus = AppStatusBus();
    store = MemoryKeyValueStore();
    storeRequests = [];
    storeOpens = true;
    navigatorKey = GlobalKey<NavigatorState>();
  });

  tearDown(() async {
    await cubit.close();
    await bus.dispose();
  });

  // The cubit is created inside the test body so its bus subscription lives
  // in the fake-async zone that pump() drives.
  Future<void> pumpGate(WidgetTester tester, {Locale locale = const Locale('en')}) {
    cubit = AppConfigCubit(repository: repo, statusBus: bus, store: store, installedBuild: 10, platform: 'android');
    return pumpL10nApp(
      tester,
      locale: locale,
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('home', key: _homeKey)),
      wrap: (app) => BlocProvider.value(value: cubit, child: app),
      builder: (context, child) => AppConfigGate(
        navigatorKey: navigatorKey,
        onOpenStore: (url) async {
          storeRequests.add(url);
          return storeOpens;
        },
        child: child!,
      ),
    );
  }

  testWidgets('no gate → the app is shown', (tester) async {
    await pumpGate(tester);
    expect(find.byKey(_homeKey), findsOneWidget);
    expect(find.byType(MaintenanceView), findsNothing);
    expect(find.byType(ForceUpdateView), findsNothing);
  });

  testWidgets('503 → maintenance view with the server message; retry reloads', (tester) async {
    await pumpGate(tester);
    bus.add(AppStatusSignal.maintenance, 'Back at five');
    await tester.pumpAndSettle();

    expect(find.byType(MaintenanceView), findsOneWidget);
    expect(find.byKey(_homeKey), findsNothing);
    expect(find.text("We'll be right back"), findsOneWidget);
    expect(find.text('Back at five'), findsOneWidget);

    repo.responses.add(const Ok(AppConfig()));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repo.fetches, 1);
    expect(find.byKey(_homeKey), findsOneWidget, reason: 'a successful load ends maintenance');
  });

  testWidgets('config maintenance: the message in the UI language wins, else the bundled one', (tester) async {
    repo.responses.add(
      const Ok(AppConfig(maintenance: true, maintenanceMessage: {'ar': 'نعود قريبًا', 'en': 'Servers upgrading'})),
    );
    await pumpGate(tester, locale: const Locale('ar'));
    unawaited(cubit.load());
    await tester.pumpAndSettle();
    expect(find.text('نعود قريبًا'), findsOneWidget);

    repo.responses.add(const Ok(AppConfig(maintenance: true)));
    unawaited(cubit.load());
    await tester.pumpAndSettle();
    expect(find.text('نُجري بعض أعمال الصيانة المجدولة. يُرجى المحاولة مرة أخرى بعد قليل.'), findsOneWidget);
  });

  testWidgets('force update → store button passes the config store URL; failure shows a snackbar', (tester) async {
    repo.responses.add(
      const Ok(AppConfig(android: PlatformUpdatePolicy(minBuild: 11, storeUrl: 'https://store.example/app'))),
    );
    await pumpGate(tester);
    unawaited(cubit.load());
    await tester.pumpAndSettle();

    expect(find.byType(ForceUpdateView), findsOneWidget);
    expect(find.text('Update required'), findsOneWidget);

    storeOpens = false;
    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(storeRequests, ['https://store.example/app']);
    expect(find.text("We couldn't open the store. Please update the app from your app store."), findsOneWidget);
  });

  testWidgets('optional update → sheet once per latest build, over the app', (tester) async {
    repo.responses.add(const Ok(AppConfig(android: PlatformUpdatePolicy(minBuild: 1, latestBuild: 12))));
    await pumpGate(tester);
    unawaited(cubit.load());
    await tester.pumpAndSettle();

    expect(find.byType(OptionalUpdateSheet), findsOneWidget);
    expect(find.byKey(_homeKey), findsOneWidget, reason: 'the app stays usable underneath');
    expect(store.getInt(StorageKeys.lastOptionalUpdatePrompt), 12);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionalUpdateSheet), findsNothing);

    // A refresh with the same latest build doesn't prompt again.
    repo.responses.add(const Ok(AppConfig(android: PlatformUpdatePolicy(minBuild: 1, latestBuild: 12))));
    unawaited(cubit.load());
    await tester.pumpAndSettle();
    expect(find.byType(OptionalUpdateSheet), findsNothing);
  });

  testWidgets('optional sheet "Update now" closes the sheet and opens the store', (tester) async {
    repo.responses.add(const Ok(AppConfig(android: PlatformUpdatePolicy(latestBuild: 12, storeUrl: 'market://x'))));
    await pumpGate(tester);
    unawaited(cubit.load());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionalUpdateSheet), findsNothing);
    expect(storeRequests, ['market://x']);
  });
}
