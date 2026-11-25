// Renames the template into a new app: Dart package, display name and the
// Android / iOS application id, in every file that carries them.
//
// Source: petrobe copy_feature.dart (patch files in place with string
//         replacements and print each step) — applied to project identity.
// Merged: new (reads the CURRENT values from the files, so it can be re-run;
//         validates inputs; --dry-run; moves MainActivity to the new package
//         folder; iOS ids get `-` instead of `_`, which bundle ids forbid).
// See docs/NEW_PROJECT_CHECKLIST.md.
//
// Usage (from the project root):
//   dart run tool/rename_app.dart --package <dart_package_name> --name "<Display Name>" --id <application.id> [--dry-run]
//   dart run tool/rename_app.dart --package shop_app --name "Shop" --id com.company.shop --dry-run
//
// Changes:
//   pubspec.yaml                         name: (+ "AppName" in description)
//   lib/ test/ tool/ integration_test/   package:<old>/ imports
//   android/app/build.gradle.kts         namespace + applicationId
//   android/app/src/main/kotlin/...      MainActivity package + folder
//   android/app/src/main/AndroidManifest.xml  android:label
//   ios/Runner.xcodeproj/project.pbxproj PRODUCT_BUNDLE_IDENTIFIER (+ .RunnerTests)
//   ios/Runner/Info.plist                CFBundleDisplayName + CFBundleName
//   assets/translations/{en,ar}.json     app.name, only while it is the placeholder
//   .env.example                         store URL id
//
// Pure Dart (no Flutter imports) so it runs with `dart run`.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Placeholder values of the template.
const String placeholderDisplayName = 'AppName';
const Set<String> placeholderAppNames = {'AppName', 'اسم التطبيق'};

final Set<String> _dartReserved = {
  ...('abstract as assert async await base break case catch class const continue covariant default deferred do '
          'dynamic else enum export extends extension external factory false final finally for function get hide if '
          'implements import in interface is late library mixin new null of on operator part required rethrow return '
          'sealed set show static super switch sync this throw true try type typedef var void when while with yield')
      .split(' '),
};

final Set<String> _jvmReserved = {
  ...('abstract as assert boolean break byte case catch char class const continue default do double else enum '
          'extends false final finally float for fun goto if implements import in instanceof int interface is long '
          'native new null object package private protected public return short static strictfp super switch '
          'synchronized this throw throws transient true try typealias typeof val var void volatile when while')
      .split(' '),
};

/// Null when [name] is a valid Dart package name, else the reason.
String? validatePackageName(String name) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
    return 'Package name "$name" must be lowercase letters, digits and _, starting with a letter.';
  }
  if (_dartReserved.contains(name)) return 'Package name "$name" is a Dart reserved word.';
  if (const {'flutter', 'flutter_test', 'test'}.contains(name)) {
    return 'Package name "$name" clashes with an SDK package.';
  }
  return null;
}

/// Null when [id] is a valid reverse-DNS application id, else the reason.
String? validateAppId(String id) {
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$').hasMatch(id)) {
    return 'Application id "$id" must be reverse-DNS with at least two segments (e.g. com.company.app); '
        'each segment starts with a letter and uses letters, digits or _.';
  }
  final reserved = id.split('.').where(_jvmReserved.contains).toList();
  if (reserved.isNotEmpty) return 'Application id "$id" uses Java/Kotlin keywords: ${reserved.join(', ')}.';
  return null;
}

/// Null when [name] can be a display name, else the reason.
String? validateDisplayName(String name) {
  if (name.trim().isEmpty) return 'Display name must not be empty.';
  if (name.contains('\n')) return 'Display name must be one line.';
  return null;
}

/// iOS bundle ids allow letters, digits, `-` and `.` only.
String iosBundleId(String appId) => appId.replaceAll('_', '-');

String _xmlEscape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// One planned change (relative paths, `/` separators).
class FileChange {
  const FileChange(this.path, this.description, {this.content, this.moveTo});

  final String path;
  final String description;

  /// New content (null = content unchanged).
  final String? content;

  /// New path (null = stays).
  final String? moveTo;

  @override
  String toString() => moveTo == null ? '$path — $description' : '$path → $moveTo — $description';
}

class RenamePlan {
  RenamePlan({required this.oldPackage, required this.oldAppId});

  final String oldPackage;
  final String? oldAppId;
  final List<FileChange> changes = [];
  final List<String> notes = [];
}

/// Builds the rename plan for the project at [root] without touching disk.
/// Throws [ArgumentError] for invalid inputs and [StateError] when [root]
/// isn't a Flutter project.
RenamePlan planRename(Directory root, {required String package, required String displayName, required String appId}) {
  for (final error in [validatePackageName(package), validateDisplayName(displayName), validateAppId(appId)]) {
    if (error != null) throw ArgumentError(error);
  }
  File file(String relative) => File('${root.path}/$relative');
  String? read(String relative) {
    final f = file(relative);
    return f.existsSync() ? f.readAsStringSync() : null;
  }

  final pubspec = read('pubspec.yaml');
  if (pubspec == null) throw StateError('No pubspec.yaml in ${root.path} — run from the project root.');
  final oldPackage = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspec)?.group(1);
  if (oldPackage == null) throw StateError('pubspec.yaml has no `name:`.');

  const gradlePath = 'android/app/build.gradle.kts';
  final gradle = read(gradlePath);
  final oldAppId = gradle == null ? null : RegExp(r'applicationId\s*=\s*"([^"]+)"').firstMatch(gradle)?.group(1);
  final plan = RenamePlan(oldPackage: oldPackage, oldAppId: oldAppId);
  void change(String path, String? before, String after, String description) {
    if (before != null && before != after) plan.changes.add(FileChange(path, description, content: after));
  }

  // pubspec.yaml
  change(
    'pubspec.yaml',
    pubspec,
    pubspec
        .replaceFirst(RegExp(r'^name:\s*\S+', multiLine: true), 'name: $package')
        .replaceFirstMapped(
          RegExp('^(description:.*?)$placeholderDisplayName', multiLine: true),
          (m) => '${m[1]}$displayName',
        ),
    'name: $oldPackage → $package',
  );

  // package: imports in Dart sources.
  if (oldPackage != package) {
    for (final dir in const ['lib', 'test', 'tool', 'integration_test']) {
      final directory = Directory('${root.path}/$dir');
      if (!directory.existsSync()) continue;
      final files =
          directory.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        final relative = f.path.substring(root.path.length + 1).replaceAll(r'\', '/');
        final before = f.readAsStringSync();
        change(relative, before, before.replaceAll('package:$oldPackage/', 'package:$package/'), 'imports');
      }
    }
  }

  // Android: namespace + applicationId.
  if (gradle != null) {
    change(
      gradlePath,
      gradle,
      gradle
          .replaceFirst(RegExp(r'namespace\s*=\s*"[^"]*"'), 'namespace = "$appId"')
          .replaceFirst(RegExp(r'applicationId\s*=\s*"[^"]*"'), 'applicationId = "$appId"'),
      'namespace + applicationId → $appId',
    );
  } else {
    plan.notes.add('No $gradlePath — Android id not changed.');
  }

  // Android: MainActivity package + folder.
  for (final lang in const ['kotlin', 'java']) {
    final srcDir = Directory('${root.path}/android/app/src/main/$lang');
    if (!srcDir.existsSync()) continue;
    for (final f in srcDir.listSync(recursive: true).whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name != 'MainActivity.kt' && name != 'MainActivity.java') continue;
      final relative = f.path.substring(root.path.length + 1).replaceAll(r'\', '/');
      final before = f.readAsStringSync();
      final after = before.replaceFirst(
        RegExp(r'^package\s+[\w.]+;?', multiLine: true),
        (name.endsWith('.java') ? 'package $appId;' : 'package $appId'),
      );
      final target = 'android/app/src/main/$lang/${appId.replaceAll('.', '/')}/$name';
      if (before != after || relative != target) {
        plan.changes.add(
          FileChange(
            relative,
            'package $appId',
            content: before == after ? null : after,
            moveTo: relative == target ? null : target,
          ),
        );
      }
    }
  }

  // Android label.
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  final manifest = read(manifestPath);
  if (manifest != null) {
    change(
      manifestPath,
      manifest,
      manifest.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="${_xmlEscape(displayName)}"'),
      'android:label → $displayName',
    );
  }

  // iOS bundle ids.
  final iosId = iosBundleId(appId);
  if (iosId != appId) plan.notes.add('iOS bundle ids cannot contain "_": using $iosId on iOS.');
  const pbxPath = 'ios/Runner.xcodeproj/project.pbxproj';
  final pbx = read(pbxPath);
  if (pbx != null) {
    change(
      pbxPath,
      pbx,
      pbx.replaceAllMapped(RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = "?([^";]+)"?;'), (m) {
        final tests = m[1]!.endsWith('.RunnerTests');
        return 'PRODUCT_BUNDLE_IDENTIFIER = ${tests ? '$iosId.RunnerTests' : iosId};';
      }),
      'PRODUCT_BUNDLE_IDENTIFIER → $iosId (+ .RunnerTests)',
    );
  }

  // iOS display name.
  const plistPath = 'ios/Runner/Info.plist';
  final plist = read(plistPath);
  if (plist != null) {
    var after = plist;
    for (final key in const ['CFBundleDisplayName', 'CFBundleName']) {
      after = after.replaceFirstMapped(
        RegExp('(<key>$key</key>\\s*<string>)[^<]*(</string>)'),
        (m) => '${m[1]}${_xmlEscape(displayName)}${m[2]}',
      );
    }
    change(plistPath, plist, after, 'CFBundleDisplayName + CFBundleName → $displayName');
  }

  // app.name while it is still the placeholder.
  for (final locale in const ['en', 'ar']) {
    final path = 'assets/translations/$locale.json';
    final text = read(path);
    if (text == null) continue;
    final json = jsonDecode(text) as Map<String, dynamic>;
    final app = json['app'];
    if (app is Map<String, dynamic> && placeholderAppNames.contains(app['name'])) {
      app['name'] = displayName;
      change(path, text, '${const JsonEncoder.withIndent('  ').convert(json)}\n', 'app.name → $displayName');
      if (locale != 'en') plan.notes.add('Translate app.name in $path (it now holds "$displayName").');
    }
  }

  // Store URL placeholder.
  const envPath = '.env.example';
  final env = read(envPath);
  if (env != null && oldAppId != null && oldAppId != appId) {
    change(envPath, env, env.replaceAll('id=$oldAppId', 'id=$appId'), 'store URL id → $appId');
  }
  return plan;
}

/// Writes [plan] to disk under [root]: new contents, moves, then removes
/// folders left empty by a move.
void applyRename(Directory root, RenamePlan plan) {
  for (final change in plan.changes) {
    final source = File('${root.path}/${change.path}');
    final content = change.content;
    if (content != null) source.writeAsStringSync(content);
    final moveTo = change.moveTo;
    if (moveTo == null) continue;
    final target = File('${root.path}/$moveTo');
    target.parent.createSync(recursive: true);
    source.renameSync(target.path);
    // Remove now-empty parents up to the source root (kotlin/ or java/).
    var dir = source.parent;
    while (!const ['kotlin', 'java'].contains(dir.uri.pathSegments.where((s) => s.isNotEmpty).last) &&
        dir.existsSync() &&
        dir.listSync().isEmpty) {
      dir.deleteSync();
      dir = dir.parent;
    }
  }
}

const String _usage = '''
Renames the template: Dart package, display name and application id.

Usage: dart run tool/rename_app.dart --package <dart_package_name> --name "<Display Name>" --id <application.id> [--dry-run]

  --package   New Dart package name (lowercase, digits, _), e.g. shop_app.
  --name      Display name shown under the app icon, e.g. "Shop".
  --id        Reverse-DNS application id, e.g. com.company.shop (iOS uses - for _).
  --dry-run   Print what would change without writing.
  -h, --help  Show this help.

Run from the project root, then: flutter clean && flutter pub get.
''';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    print(_usage);
    return;
  }
  final options = <String, String>{};
  var dryRun = false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--dry-run') {
      dryRun = true;
      continue;
    }
    final match = RegExp(r'^--(package|name|id)(?:=(.*))?$').firstMatch(arg);
    if (match == null) {
      stderr.writeln('Unknown argument: $arg\n\n$_usage');
      exit(64);
    }
    final value = match[2] ?? (i + 1 < args.length ? args[++i] : null);
    if (value == null) {
      stderr.writeln('--${match[1]} needs a value.\n\n$_usage');
      exit(64);
    }
    options[match[1]!] = value;
  }
  final package = options['package'];
  final name = options['name'];
  final id = options['id'];
  if (package == null || name == null || id == null) {
    stderr.writeln('--package, --name and --id are required.\n\n$_usage');
    exit(64);
  }

  final root = Directory.current;
  final RenamePlan plan;
  try {
    plan = planRename(root, package: package, displayName: name, appId: id);
  } on ArgumentError catch (e) {
    stderr.writeln(e.message);
    exit(64);
  } on StateError catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }

  if (plan.changes.isEmpty) {
    print('Nothing to change: the project already uses these values.');
    return;
  }
  print('${dryRun ? 'Would change' : 'Changing'} ${plan.changes.length} file(s):');
  final imports = plan.changes.where((c) => c.description == 'imports').length;
  for (final change in plan.changes.where((c) => c.description != 'imports')) {
    print('  $change');
  }
  if (imports > 0) print('  $imports Dart file(s) — package:${plan.oldPackage}/ → package:$package/');
  for (final note in plan.notes) {
    print('Note: $note');
  }
  if (dryRun) {
    print('\nDry run: nothing was written.');
    return;
  }
  applyRename(root, plan);
  if (imports > 0) _tidyImports(root);
  print('\nDone. Next: flutter clean && flutter pub get, then rebuild the app.');
}

/// A new package name changes where `package:<name>/` imports sort, which
/// `directives_ordering` (and CI's --fatal-infos) would flag: re-sort and format.
void _tidyImports(Directory root) {
  final dirs = ['lib', 'test', 'tool'].where((d) => Directory('${root.path}/$d').existsSync()).toList();
  // Resolve the renamed package first, or `dart fix` can't analyze the new imports.
  for (final cmd in [
    ['flutter', 'pub', 'get'],
    ['dart', 'fix', '--apply', '--code=directives_ordering', '.'], // takes one path
    ['dart', 'format', ...dirs],
  ]) {
    final result = Process.runSync(cmd.first, cmd.sublist(1), workingDirectory: root.path, runInShell: true);
    if (result.exitCode != 0) {
      print('Warning: `${cmd.join(' ')}` failed — run it yourself.\n${result.stderr}');
      return;
    }
  }
  print('Re-sorted imports and formatted ${dirs.join(', ')}.');
}
