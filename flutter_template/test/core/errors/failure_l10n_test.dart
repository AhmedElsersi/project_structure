// Tests for lib/core/errors/failure.dart. Source: new
//
// displayMessage with the real en/ar translations loaded.
import 'dart:convert';
import 'dart:io';

import 'package:app_template/core/errors/failure.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _errors(String lang) =>
    (jsonDecode(File('assets/translations/$lang.json').readAsStringSync()) as Map<String, dynamic>)['errors']
        as Map<String, dynamic>;

// Asset loading is real I/O: let it finish outside the fake-async zone.
Future<void> _loadTranslations(WidgetTester tester, Locale locale) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'assets/translations',
        startLocale: locale,
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        useOnlyLangCode: true,
        // The delegate (and so Localization.instance) only loads inside an app.
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableBuildModes = [];
    await EasyLocalization.ensureInitialized();
  });

  for (final lang in ['en', 'ar']) {
    testWidgets('$lang: displayMessage shows the localized sentence, never debug text', (tester) async {
      await _loadTranslations(tester, Locale(lang));
      final errors = _errors(lang);

      expect(const NetworkFailure(debugMessage: 'SocketException').displayMessage, errors['network']);
      expect(const ServerFailure(statusCode: 500, debugMessage: '<html>').displayMessage, errors['server']);
      expect(const UnknownFailure(debugMessage: 'TypeError: boom').displayMessage, errors['unknown']);
      expect(const ConflictFailure(serverMessage: 'From backend').displayMessage, 'From backend');
    });
  }
}
