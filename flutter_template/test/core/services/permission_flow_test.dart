// Widget tests for lib/shared/widgets/permissions/permission_flow.dart with a
// fake PermissionService. Source: new
import 'dart:async';

import 'package:app_template/core/services/permission_service.dart';
import 'package:app_template/shared/widgets/permissions/permission_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/l10n_app.dart';

class _FakePermissions implements PermissionService {
  _FakePermissions(this.current, {this.afterRequest, this.afterSettings});

  AppPermissionStatus current;
  final AppPermissionStatus? afterRequest;
  final AppPermissionStatus? afterSettings;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<AppPermissionStatus> status(AppPermission permission) async => current;

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    requests++;
    return current = afterRequest ?? current;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    current = afterSettings ?? current;
    return true;
  }
}

void main() {
  setUpAll(setUpL10n);

  late BuildContext appContext;

  Future<void> pump(WidgetTester tester) => pumpL10nApp(
    tester,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          appContext = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  /// Starts the flow without awaiting it (dialogs need pumps in between).
  Future<bool> start(
    PermissionService service, {
    SettingsPromptThrottle? throttle,
    AppPermission permission = AppPermission.camera,
  }) => ensurePermission(
    appContext,
    permission,
    service,
    rationaleTitle: 'Why camera',
    rationaleMessage: 'To scan receipts',
    throttle: throttle,
  );

  Future<void> returnFromSettings(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  testWidgets('already granted → true, no dialogs', (tester) async {
    await pump(tester);
    final service = _FakePermissions(AppPermissionStatus.granted);
    expect(await start(service), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.requests, 0);
  });

  testWidgets('limited counts as granted; restricted is false with no dialogs', (tester) async {
    await pump(tester);
    expect(await start(_FakePermissions(AppPermissionStatus.limited)), isTrue);
    expect(await start(_FakePermissions(AppPermissionStatus.restricted)), isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('denied → rationale → Continue → system prompt → granted', (tester) async {
    await pump(tester);
    final service = _FakePermissions(AppPermissionStatus.denied, afterRequest: AppPermissionStatus.granted);
    final result = start(service);
    await tester.pumpAndSettle();

    expect(find.text('Why camera'), findsOneWidget);
    expect(find.text('To scan receipts'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(service.requests, 1);
  });

  testWidgets('rationale "Not now" → false without asking the OS', (tester) async {
    await pump(tester);
    final service = _FakePermissions(AppPermissionStatus.denied, afterRequest: AppPermissionStatus.granted);
    final result = start(service);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(service.requests, 0);
  });

  testWidgets('denied again but still askable → false, no settings dialog', (tester) async {
    await pump(tester);
    final service = _FakePermissions(AppPermissionStatus.denied);
    final result = start(service);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(find.text('Turn on access in Settings'), findsNothing);
  });

  testWidgets('permanently denied → settings dialog → open → re-checked on return', (tester) async {
    await pump(tester);
    final service = _FakePermissions(AppPermissionStatus.permanentlyDenied, afterSettings: AppPermissionStatus.granted);
    final result = start(service);
    await tester.pumpAndSettle();

    expect(find.text('Turn on access in Settings'), findsOneWidget);
    expect(find.text('Camera access is turned off for this app. You can turn it on in Settings.'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(service.settingsOpened, 1);

    await returnFromSettings(tester);
    expect(await result, isTrue);
  });

  testWidgets('request turns permanently denied → settings dialog follows; dismiss → false', (tester) async {
    await pump(tester);
    final service = _FakePermissions(AppPermissionStatus.denied, afterRequest: AppPermissionStatus.permanentlyDenied);
    final result = start(service);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Turn on access in Settings'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    expect(service.settingsOpened, 0);
  });

  testWidgets('settings prompt is throttled per permission', (tester) async {
    await pump(tester);
    var now = DateTime(2026);
    final throttle = SettingsPromptThrottle(interval: const Duration(hours: 1), clock: () => now);
    final service = _FakePermissions(AppPermissionStatus.permanentlyDenied);

    final first = start(service, throttle: throttle);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(await first, isFalse);

    // Within the interval: silently false.
    expect(await start(service, throttle: throttle), isFalse);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    // Another permission is not throttled by the camera prompt.
    final mic = start(service, throttle: throttle, permission: AppPermission.microphone);
    await tester.pumpAndSettle();
    expect(find.text('Microphone access is turned off for this app. You can turn it on in Settings.'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(await mic, isFalse);

    now = now.add(const Duration(hours: 2));
    unawaited(start(service, throttle: throttle));
    await tester.pumpAndSettle();
    expect(find.text('Turn on access in Settings'), findsOneWidget);
  });

  testWidgets('default texts per permission are translated', (tester) async {
    await pump(tester);
    expect(AppPermission.location.label, 'Location');
    expect(AppPermission.camera.rationaleTitle, 'Allow access to Camera');
    expect(AppPermission.notifications.rationaleMessage, "Allow notifications so you don't miss important updates.");
  });
}
