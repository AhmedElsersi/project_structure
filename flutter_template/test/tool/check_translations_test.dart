// Tests for tool/check_translations.dart: source scanning and a whole-project
// run on a temp copy.
//
// Source: new (locale comparison is also covered by
//         test/policy/l10n_parity_test.dart).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_translations.dart';

void main() {
  const keys = {'common.ok', 'items.title', 'format.days_ago'};

  group('scanSource', () {
    List<String> scan(String source, {String path = 'lib/x.dart'}) => scanSource(path, source, keys);

    test('flags untranslated Text literals in any script', () {
      expect(scan("const Text('Hello')"), [contains('untranslated Text')]);
      expect(scan('Text("مرحبا")'), [contains('untranslated Text')]);
    });

    test('flags .tr() / tr() on unknown keys', () {
      expect(scan("Text('items.missing'.tr())"), [contains('undefined key "items.missing"')]);
      expect(scan("tr('nope.key')"), [contains('undefined key "nope.key"')]);
    });

    test('accepts known keys, groups, interpolation and the allowlisted file', () {
      expect(scan("Text('items.title'.tr())"), isEmpty);
      expect(scan("'format.days_ago'.plural(2)"), isEmpty);
      expect(scan("'items'.tr()".replaceAll("'items'", "'items.title'")), isEmpty);
      expect(scan(r"Text('$count')"), isEmpty);
      expect(scan("// Text('Hello')"), isEmpty);
      expect(scan("Text('Config error')", path: 'lib/shared/screens/config_error_app.dart'), isEmpty);
    });
  });

  group('checkProject', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('check_translations_');
      Directory('${root.path}/assets/translations').createSync(recursive: true);
      Directory('${root.path}/lib').createSync();
    });

    tearDown(() => root.deleteSync(recursive: true));

    void write(String path, Object content) =>
        File('${root.path}/$path').writeAsStringSync(content is String ? content : jsonEncode(content));

    test('passes for the template itself', () {
      expect(checkProject(Directory.current), isEmpty);
    });

    test('reports locale drift and source problems together', () {
      write('assets/translations/en.json', {
        'a': {'title': 'Title {}', 'other': 'x'},
      });
      write('assets/translations/ar.json', {
        'a': {'title': 'عنوان'},
      });
      write('lib/screen.dart', "Text('Hard coded');\nText('a.missing'.tr());\n");
      final problems = checkProject(root);
      expect(problems, contains('ar is missing "a.other"'));
      expect(problems, contains('"a.title" has 1 "{}" in en but 0 in ar'));
      expect(problems.where((p) => p.startsWith('lib/screen.dart:1')), hasLength(1));
      expect(problems.where((p) => p.startsWith('lib/screen.dart:2')), hasLength(1));
    });

    test('CLI exits 1 on problems', () async {
      write('assets/translations/en.json', {'a': 'x'});
      write('assets/translations/ar.json', {'a': ''});
      final result = await Process.run('dart', [
        'run',
        '${Directory.current.path}/tool/check_translations.dart',
      ], workingDirectory: root.path);
      expect(result.exitCode, 1);
      expect(result.stdout, contains('ar: "a" is empty'));
    });
  });
}
