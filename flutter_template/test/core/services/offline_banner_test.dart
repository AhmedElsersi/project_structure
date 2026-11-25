// Widget tests for lib/shared/widgets/states/offline_banner.dart. Source: new
//
// A real ConnectivityCubit over a ConnectivityService with a scripted probe.
import 'package:app_template/core/services/connectivity/connectivity_cubit.dart';
import 'package:app_template/core/services/connectivity/connectivity_service.dart';
import 'package:app_template/shared/widgets/states/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/l10n_app.dart';

/// Counts its builds and keeps state, to prove the banner doesn't rebuild or
/// remount the app below it.
class _Counter extends StatefulWidget {
  const _Counter();

  static int builds = 0;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    _Counter.builds++;
    return Center(
      child: TextButton(onPressed: () => setState(() => taps++), child: Text('taps $taps')),
    );
  }
}

void main() {
  setUpAll(setUpL10n);

  late bool online;
  late ConnectivityService service;
  late ConnectivityCubit cubit;

  Future<void> pumpBanner(WidgetTester tester, {Locale locale = const Locale('en')}) {
    online = true;
    service = ConnectivityService(
      probe: () async => online,
      offlineConfirmDelay: Duration.zero,
      listenToLifecycle: false,
      alwaysOnline: false,
    );
    cubit = ConnectivityCubit(service, offlineDelay: Duration.zero);
    _Counter.builds = 0;
    return pumpL10nApp(
      tester,
      locale: locale,
      home: const Scaffold(body: _Counter()),
      wrap: (app) => BlocProvider.value(value: cubit, child: app),
      builder: (context, child) => OfflineBanner(backOnlineDuration: const Duration(seconds: 2), child: child!),
    );
  }

  tearDown(() async {
    await cubit.close();
    service.dispose();
  });

  Future<void> setOnline(WidgetTester tester, bool value) async {
    online = value;
    await tester.runAsync(service.check);
    await tester.pumpAndSettle();
  }

  testWidgets('offline shows the banner; recovery shows "back online" briefly; the app keeps its state', (
    tester,
  ) async {
    await pumpBanner(tester);
    expect(find.text("You're offline. Some features may not work."), findsNothing);

    await tester.tap(find.text('taps 0'));
    await tester.pumpAndSettle();
    final buildsBefore = _Counter.builds;

    await setOnline(tester, false);
    expect(find.text("You're offline. Some features may not work."), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

    await setOnline(tester, true);
    expect(find.text("You're back online."), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text("You're back online."), findsNothing);

    expect(find.text('taps 1'), findsOneWidget, reason: 'the app below kept its state');
    expect(_Counter.builds, buildsBefore, reason: 'the app below never rebuilt');
  });

  testWidgets('Arabic text and RTL layout', (tester) async {
    await pumpBanner(tester, locale: const Locale('ar'));
    await setOnline(tester, false);
    expect(find.text('أنت غير متصل بالإنترنت. قد لا تعمل بعض الميزات.'), findsOneWidget);

    final icon = tester.getTopLeft(find.byIcon(Icons.cloud_off_rounded));
    final text = tester.getTopLeft(find.text('أنت غير متصل بالإنترنت. قد لا تعمل بعض الميزات.'));
    expect(icon.dx, greaterThan(text.dx), reason: 'the icon leads on the right in RTL');
  });
}
