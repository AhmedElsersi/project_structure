// Policy: layering. core ↛ shared/features, shared ↛ features, features don't
// import each other, domain stays pure, getIt only in composition code.
//
// Source: markspulse test/domain/architecture_test.dart (scan imports line by
//         line: the domain layer imports no Flutter and no state management —
//         the rule autocomplete breaks most easily).
// Merged: corsa-customer lib/core/services/di_container.dart + features_di.dart
//         (core and features split: core never imports a feature); new
//         (relative imports resolved to their lib/ path; package name read
//         from pubspec.yaml so a rename keeps working; getIt only in DI and
//         route files).
// See docs/ARCHITECTURE.md#layers.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_scan.dart';

/// Packages the domain layer must not depend on.
const _domainBannedPackages = [
  'package:flutter/',
  'package:dio/',
  'package:flutter_bloc/',
  'package:bloc/',
  'package:go_router/',
  'package:get_it/',
];

/// Composition code that may resolve dependencies with `getIt`.
bool _mayUseGetIt(String path) =>
    path.endsWith('_di.dart') ||
    path.endsWith('_routes.dart') ||
    path.startsWith('lib/core/di/') ||
    const {'lib/main.dart', 'lib/bootstrap.dart', 'lib/app.dart', 'lib/app_router.dart'}.contains(path);

String _packageName() =>
    RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;

/// An import of [file] with its target resolved to `lib/...` (null for
/// other packages and dart: libraries).
typedef Import = ({int offset, String uri, String? target});

List<Import> importsOf(SourceFile file, String package) {
  final imports = <Import>[];
  final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
  for (final match in directive.allMatches(file.code)) {
    final uri = match[1]!;
    String? target;
    if (uri.startsWith('package:$package/')) {
      target = 'lib/${uri.substring('package:$package/'.length)}';
    } else if (!uri.contains(':')) {
      // Relative: resolve against the importing file.
      target = Uri.parse(file.path).resolve(uri).path;
    }
    imports.add((offset: match.start, uri: uri, target: target));
  }
  return imports;
}

/// `lib/features/<name>/...` → `<name>`.
String? _featureOf(String path) => RegExp(r'^lib/features/([^/]+)/').firstMatch(path)?.group(1);

List<Violation> layering(SourceFile file, String package) {
  final violations = <Violation>[];
  final path = file.path;
  final feature = _featureOf(path);
  final inDomain = feature != null && path.startsWith('lib/features/$feature/domain/');
  final inData = feature != null && path.startsWith('lib/features/$feature/data/');

  for (final import in importsOf(file, package)) {
    final target = import.target;
    void add(String rule) => violations.add(file.violation(import.offset, rule, import.uri));

    if (target != null) {
      if (path.startsWith('lib/core/') && target.startsWith('lib/shared/')) add('core → shared');
      if (path.startsWith('lib/core/') && target.startsWith('lib/features/')) add('core → features');
      if (path.startsWith('lib/shared/') && target.startsWith('lib/features/')) add('shared → features');
      final targetFeature = _featureOf(target);
      if (feature != null && targetFeature != null && targetFeature != feature) {
        add('feature $feature → feature $targetFeature');
      }
      if (inDomain && targetFeature == feature) {
        if (target.startsWith('lib/features/$feature/data/')) add('domain → data');
        if (target.startsWith('lib/features/$feature/presentation/')) add('domain → presentation');
      }
      if (inData && target.startsWith('lib/features/$feature/presentation/')) add('data → presentation');
    }
    if (inDomain) {
      for (final banned in _domainBannedPackages) {
        if (import.uri.startsWith(banned)) add('domain → $banned');
      }
    }
  }

  if (!_mayUseGetIt(path)) {
    for (final match in RegExp(r'\bgetIt\b').allMatches(file.code)) {
      violations.add(file.violation(match.start, 'getIt outside DI / route files (inject via constructor)', 'getIt'));
    }
  }
  return violations;
}

void main() {
  final package = _packageName();

  test('lib/ respects the layering rules', () {
    final violations = dartFiles().expand((file) => layering(file, package)).toList();
    expect(violations, isEmpty, reason: report(violations));
  });

  test('features have the data / domain / presentation layout', () {
    final features = Directory('lib/features').listSync().whereType<Directory>().toList();
    final missing = <String>[
      for (final dir in features)
        for (final layer in const ['data', 'domain', 'presentation'])
          if (!Directory('${dir.path}/$layer').existsSync()) '${dir.path}/$layer',
    ];
    expect(missing, isEmpty, reason: 'Missing layer folders: $missing');
  });

  group('rule', () {
    List<String> rules(String path, String code) => layering(SourceFile(path, code), 'app').map((v) => v.rule).toList();

    test('catches forbidden directions (package and relative imports)', () {
      expect(rules('lib/core/a.dart', "import 'package:app/shared/w.dart';"), ['core → shared']);
      expect(rules('lib/core/x/a.dart', "import '../../features/f/f.dart';"), ['core → features']);
      expect(rules('lib/shared/a.dart', "import '../features/f/f.dart';"), ['shared → features']);
      expect(rules('lib/features/a/x.dart', "import '../b/y.dart';"), ['feature a → feature b']);
      expect(rules('lib/features/a/domain/e.dart', "import 'package:flutter/material.dart';"), [
        'domain → package:flutter/',
      ]);
      expect(rules('lib/features/a/domain/e.dart', "import 'package:dio/dio.dart';"), ['domain → package:dio/']);
      expect(rules('lib/features/a/domain/r.dart', "import '../data/m.dart';"), ['domain → data']);
      expect(rules('lib/features/a/domain/r.dart', "import '../presentation/c.dart';"), ['domain → presentation']);
      expect(rules('lib/features/a/data/r.dart', "import '../presentation/c.dart';"), ['data → presentation']);
      expect(rules('lib/features/a/presentation/s.dart', 'final c = getIt<C>();'), [
        'getIt outside DI / route files (inject via constructor)',
      ]);
    });

    test('accepts allowed directions', () {
      expect(rules('lib/features/a/presentation/s.dart', "import '../../../core/x.dart';"), isEmpty);
      expect(rules('lib/features/a/presentation/s.dart', "import '../../../shared/w.dart';"), isEmpty);
      expect(rules('lib/features/a/data/r.dart', "import '../domain/e.dart';"), isEmpty);
      expect(rules('lib/features/a/domain/e.dart', "import 'package:equatable/equatable.dart';"), isEmpty);
      expect(rules('lib/shared/a.dart', "import '../core/x.dart';"), isEmpty);
      expect(rules('lib/features/a/a_di.dart', 'getIt.registerFactory(C.new);'), isEmpty);
      expect(rules('lib/features/a/presentation/s.dart', '/// getIt<C>() is for DI files'), isEmpty);
    });
  });
}
