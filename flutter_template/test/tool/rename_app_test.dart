// Tests for tool/rename_app.dart on a temp copy of the template's real
// platform files.
//
// Source: new (the rename core is the importable planRename()/applyRename()).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/rename_app.dart';

/// Files copied from the template into the temp project.
const _copied = [
  'pubspec.yaml',
  'android/app/build.gradle.kts',
  'android/app/src/main/AndroidManifest.xml',
  'ios/Runner.xcodeproj/project.pbxproj',
  'ios/Runner/Info.plist',
  '.env.example',
];

void main() {
  late Directory root;
  late String oldPackage;
  late String oldActivity;

  File file(String relative) => File('${root.path}/$relative');

  setUp(() {
    root = Directory.systemTemp.createTempSync('rename_app_');
    for (final relative in _copied) {
      file(relative).parent.createSync(recursive: true);
      File(relative).copySync(file(relative).path);
    }
    oldPackage = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(file('pubspec.yaml').readAsStringSync())![1]!;
    // MainActivity wherever it currently lives.
    final activity = Directory(
      'android/app/src/main/kotlin',
    ).listSync(recursive: true).whereType<File>().firstWhere((f) => f.path.endsWith('MainActivity.kt'));
    oldActivity = activity.path.replaceAll(r'\', '/');
    file(oldActivity).parent.createSync(recursive: true);
    activity.copySync(file(oldActivity).path);

    file('lib/main.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync("import 'package:$oldPackage/app.dart';\nimport 'package:other/x.dart';\n");
    file('test/a_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync("import 'package:$oldPackage/core/a.dart';\n");
    // Translation fixtures with the template placeholders.
    file('assets/translations/en.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({
          'app': {'name': 'AppName'},
          'common': {'ok': 'OK'},
        })}\n',
      );
    file('assets/translations/ar.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
        'app': {'name': 'اسم التطبيق'},
        'common': {'ok': 'حسنًا'},
      })}\n',
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  RenamePlan rename({String id = 'com.company.shop', String name = 'Shop & Co'}) {
    final plan = planRename(root, package: 'shop_app', displayName: name, appId: id);
    applyRename(root, plan);
    return plan;
  }

  test('renames package, imports, Android and iOS ids, labels and app.name', () {
    rename();

    expect(file('pubspec.yaml').readAsStringSync(), contains('name: shop_app\n'));
    expect(
      file('lib/main.dart').readAsStringSync(),
      "import 'package:shop_app/app.dart';\nimport 'package:other/x.dart';\n",
    );
    expect(file('test/a_test.dart').readAsStringSync(), contains('package:shop_app/core/a.dart'));

    final gradle = file('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('namespace = "com.company.shop"'));
    expect(gradle, contains('applicationId = "com.company.shop"'));

    final activity = file('android/app/src/main/kotlin/com/company/shop/MainActivity.kt');
    expect(activity.existsSync(), isTrue);
    expect(activity.readAsStringSync(), startsWith('package com.company.shop\n'));
    expect(file(oldActivity).existsSync(), isFalse);
    // Empty old package folders are cleaned up; kotlin/ stays.
    expect(
      Directory(
        '${root.path}/android/app/src/main/kotlin',
      ).listSync().map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last),
      ['com'],
    );

    expect(
      file('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains('android:label="Shop &amp; Co"'),
    );

    final pbx = file('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);').allMatches(pbx).map((m) => m[1]).toSet();
    expect(ids, {'com.company.shop', 'com.company.shop.RunnerTests'});

    final plist = file('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>CFBundleDisplayName</key>\n\t<string>Shop &amp; Co</string>'));
    expect(plist, contains('<key>CFBundleName</key>\n\t<string>Shop &amp; Co</string>'));

    final en = jsonDecode(file('assets/translations/en.json').readAsStringSync()) as Map<String, dynamic>;
    final ar = jsonDecode(file('assets/translations/ar.json').readAsStringSync()) as Map<String, dynamic>;
    expect(en['app'], {'name': 'Shop & Co'});
    expect(ar['app'], {'name': 'Shop & Co'});
    expect(ar['common'], {'ok': 'حسنًا'});
  });

  test('a real app.name is never overwritten', () {
    file('assets/translations/ar.json').writeAsStringSync('{\n  "app": {\n    "name": "متجري"\n  }\n}\n');
    final plan = rename();
    expect(file('assets/translations/ar.json').readAsStringSync(), contains('متجري'));
    expect(plan.changes.map((c) => c.path), isNot(contains('assets/translations/ar.json')));
  });

  test('iOS gets - instead of _ (bundle ids forbid _); Android keeps _', () {
    final plan = rename(id: 'com.company.my_shop');
    expect(file('android/app/build.gradle.kts').readAsStringSync(), contains('applicationId = "com.company.my_shop"'));
    expect(file('android/app/src/main/kotlin/com/company/my_shop/MainActivity.kt').existsSync(), isTrue);
    expect(file('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(), contains('= com.company.my-shop;'));
    expect(plan.notes.join(), contains('com.company.my-shop'));
  });

  test('can run again: a second rename starts from the current values', () {
    rename();
    rename(id: 'org.example.store', name: 'Store');
    expect(file('android/app/src/main/kotlin/org/example/store/MainActivity.kt').existsSync(), isTrue);
    expect(file('android/app/src/main/kotlin/com').existsSync(), isFalse);
    expect(file('lib/main.dart').readAsStringSync(), contains('package:shop_app/'));
    expect(file('ios/Runner/Info.plist').readAsStringSync(), contains('<string>Store</string>'));
  });

  test('planRename alone writes nothing (dry run)', () {
    final before = file('pubspec.yaml').readAsStringSync();
    final plan = planRename(root, package: 'shop_app', displayName: 'Shop', appId: 'com.company.shop');
    expect(plan.changes, isNotEmpty);
    expect(file('pubspec.yaml').readAsStringSync(), before);
    expect(file(oldActivity).existsSync(), isTrue);
  });

  test('validates inputs', () {
    expect(validatePackageName('shop_app'), isNull);
    for (final bad in ['Shop', 'shop-app', '1shop', 'class', 'flutter']) {
      expect(validatePackageName(bad), isNotNull, reason: bad);
    }
    expect(validateAppId('com.company.shop'), isNull);
    expect(validateAppId('com.company.my_shop2'), isNull);
    for (final bad in [
      'shop',
      'com..shop',
      'com.company.1shop',
      'com.my-company.shop',
      'com.new.shop',
      'com.company.',
    ]) {
      expect(validateAppId(bad), isNotNull, reason: bad);
    }
    expect(validateDisplayName(' '), isNotNull);
    expect(
      () => planRename(root, package: 'Bad-Name', displayName: 'X', appId: 'com.company.x'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
