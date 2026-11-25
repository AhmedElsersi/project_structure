// Scaffolds a new feature folder that follows the sample feature's layers
// (data / domain / presentation), adds its title translation and prints the
// lines to wire it into main.dart and app_router.dart.
//
// Source: corsa-customer create_feature.dart (folder tree per feature,
//         `--use-cases` flag for an optional domain/use_cases layer, refuses to
//         overwrite an existing feature).
// Merged: petrobe copy_feature.dart (patching idea: the generator also edits
//         shared files — here only the translation JSON; the router / DI lines
//         are printed so you choose where they go).
// See docs/ARCHITECTURE.md#features.
//
// Usage (from the project root):
//   dart run tool/create_feature.dart <feature_name> [--use-cases]
//   dart run tool/create_feature.dart order_history --use-cases
//
// Pure Dart (no Flutter imports) so it runs with `dart run`; the generator is
// the importable [createFeature] function (tested in test/tool/).
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Raised when the feature can't be created (bad name, already exists...).
class FeatureException implements Exception {
  const FeatureException(this.message, {this.exitCode = 1});
  final String message;
  final int exitCode;
  @override
  String toString() => message;
}

/// What [createFeature] did.
class FeatureResult {
  const FeatureResult({
    required this.name,
    required this.files,
    required this.translationsUpdated,
    required this.nextSteps,
  });

  final String name;

  /// Created files, relative to the project root.
  final List<String> files;

  /// Locales whose JSON got the `<name>.title` key.
  final List<String> translationsUpdated;

  /// Instructions to print (wiring lines for main.dart / app_router.dart).
  final String nextSteps;
}

/// Dart keywords plus names that would read badly as `lib/features/<name>`.
final Set<String> _reserved = {
  ...('abstract as assert async await break case catch class const continue default do else enum export extends '
          'false final finally for if import in is new null return super switch this throw true try var void while '
          'with core shared features')
      .split(' '),
};

/// Null when [name] is a usable feature name (snake_case), else the reason.
String? validateFeatureName(String name) {
  if (!RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$').hasMatch(name)) {
    return 'Feature name "$name" must be snake_case: lowercase letters and digits, words joined by single _ '
        '(e.g. order_history).';
  }
  if (_reserved.contains(name)) return 'Feature name "$name" is reserved.';
  return null;
}

/// `order_history` → `OrderHistory`.
String pascalCase(String snake) => snake.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join();

/// `order_history` → `Order history` (default English title).
String sentenceCase(String snake) {
  final words = snake.split('_').join(' ');
  return words[0].toUpperCase() + words.substring(1);
}

/// Creates `lib/features/<name>/` under [root] and adds `<name>.title` to the
/// translation files. Throws [FeatureException] without writing anything when
/// the name is invalid or the feature folder already exists.
FeatureResult createFeature(String name, {required Directory root, bool useCases = false}) {
  final error = validateFeatureName(name);
  if (error != null) throw FeatureException(error, exitCode: 64);
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    throw FeatureException('No pubspec.yaml in ${root.path} — run from the project root.');
  }
  final featureDir = Directory('${root.path}/lib/features/$name');
  if (featureDir.existsSync()) {
    throw FeatureException('lib/features/$name already exists — refusing to overwrite it.');
  }

  final files = _templates(name, useCases: useCases);
  final written = <String>[];
  files.forEach((relative, content) {
    final file = File('${featureDir.path}/$relative');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    written.add('lib/features/$name/$relative');
  });
  // Keep empty layer folders in git.
  for (final empty in ['presentation/widgets']) {
    final keep = File('${featureDir.path}/$empty/.gitkeep');
    keep.parent.createSync(recursive: true);
    keep.writeAsStringSync('');
    written.add('lib/features/$name/$empty/.gitkeep');
  }

  final updated = <String>[];
  for (final locale in const ['en', 'ar']) {
    if (_addTitleKey(File('${root.path}/assets/translations/$locale.json'), name)) updated.add(locale);
  }

  return FeatureResult(
    name: name,
    files: written..sort(),
    translationsUpdated: updated,
    nextSteps: _nextSteps(name, translations: updated),
  );
}

/// Adds `{"<name>": {"title": "<Sentence case>"}}` at the END of [file],
/// keeping every existing key in place. Returns whether it wrote.
bool _addTitleKey(File file, String name) {
  if (!file.existsSync()) return false;
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final existing = json[name];
  if (existing is Map<String, dynamic>) {
    if (existing.containsKey('title')) return false;
    existing['title'] = sentenceCase(name);
  } else if (existing == null) {
    json[name] = {'title': sentenceCase(name)};
  } else {
    return false;
  }
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(json)}\n');
  return true;
}

String _nextSteps(String name, {required List<String> translations}) {
  final type = pascalCase(name);
  return '''
Next steps:
  1. Regenerate the translation keys (the screen uses LocaleKeys.${name}_title):
       ./tool/gen_locale_keys.sh
  2. Translate "$name.title" in assets/translations/ar.json — it holds the English text for now.${translations.isEmpty ? '\n     (No translation file was changed: add "$name.title" to en.json and ar.json yourself.)' : ''}
  3. lib/main.dart — add the import and the module:
       import 'features/$name/${name}_di.dart';
       register${type}Feature,
  4. lib/app_router.dart — add the import:
       import 'features/$name/${name}_routes.dart';
     then EITHER a tab (keeps the navigation bar) in StatefulShellRoute(branches: [...]):
       StatefulShellBranch(routes: ${type}Routes.routes(rootNavigatorKey: AppRoutes.rootNavigatorKey)),
     plus a destination in lib/shared/screens/home_shell.dart (same order as the branches),
     OR a full-screen page in GoRouter(routes: [...]):
       ...${type}Routes.routes(rootNavigatorKey: AppRoutes.rootNavigatorKey),
  5. dart format lib/features/$name && flutter analyze
''';
}

/// The first layout whose lines all fit the 120-column page (what `dart format`
/// picks for these simple shapes), so typical names come out formatted.
String _fit(List<String> layouts) =>
    layouts.firstWhere((layout) => layout.split('\n').every((line) => line.length <= 120), orElse: () => layouts.last);

/// File contents keyed by path relative to `lib/features/<name>/`.
Map<String, String> _templates(String name, {required bool useCases}) {
  final type = pascalCase(name);
  final title = sentenceCase(name);
  final path = '/${name.replaceAll('_', '-')}';
  String header(String purpose) =>
      '// $purpose\n//\n// Source: generated by tool/create_feature.dart (pattern: lib/features/sample_feature).\n';

  final dependency = useCases ? 'Get${type}UseCase' : '${type}Repository';
  final dependencyImport = useCases
      ? "import '../../domain/use_cases/get_${name}_use_case.dart';"
      : "import '../../domain/repositories/${name}_repository.dart';";
  final dependencyField = useCases ? '_get$type' : '_repository';
  final routeBuilder = _fit([
    '      builder: (context, state) => BlocProvider(create: (_) => getIt<${type}Cubit>()..load(), child: const ${type}Screen()),',
    '      builder: (context, state) =>\n          BlocProvider(create: (_) => getIt<${type}Cubit>()..load(), child: const ${type}Screen()),',
    '      builder: (context, state) => BlocProvider(\n        create: (_) => getIt<${type}Cubit>()..load(),\n        child: const ${type}Screen(),\n      ),',
  ]);
  final remoteRegistration = _fit([
    '    ..registerLazySingleton<${type}RemoteDataSource>(() => ${type}RemoteDataSource(getIt<ApiClient>()))',
    '    ..registerLazySingleton<${type}RemoteDataSource>(\n      () => ${type}RemoteDataSource(getIt<ApiClient>()),\n    )',
  ]);
  final fetchMethod = _fit([
    '  Future<${type}Model> fetch({CancelToken? cancelToken}) =>\n'
        '      _api.get(${type}Endpoints.root, cancelToken: cancelToken, parser: ${type}Model.fromResponse);',
    '  Future<${type}Model> fetch({CancelToken? cancelToken}) => _api.get(\n'
        '    ${type}Endpoints.root,\n    cancelToken: cancelToken,\n    parser: ${type}Model.fromResponse,\n  );',
  ]);
  final fetchCall = useCases
      ? '$dependencyField(cancelToken: cancelToken)'
      : '$dependencyField.fetch(cancelToken: cancelToken)';

  return {
    'domain/entities/$name.dart':
        '''
${header('$type entity (pure Dart, no Flutter).')}import 'package:equatable/equatable.dart';

class $type extends Equatable {
  const $type({required this.id, required this.title});

  final String id;
  final String title;

  @override
  List<Object?> get props => [id, title];
}
''',
    'domain/repositories/${name}_repository.dart':
        '''
${header('Contract of the $title data (implemented in data/repositories).')}import '../../../../core/result/result.dart';
import '../entities/$name.dart';

abstract interface class ${type}Repository {
  /// [cancelToken] is the caller's `BaseCubit.cancelToken`, untyped because
  /// the domain layer never imports dio.
  Future<Result<$type>> fetch({Object? cancelToken});
}
''',
    if (useCases)
      'domain/use_cases/get_${name}_use_case.dart':
          '''
${header('Loads $title. Use cases are optional: keep this one only for a rule or a multi-repository flow.')}import '../../../../core/result/result.dart';
import '../entities/$name.dart';
import '../repositories/${name}_repository.dart';

class Get${type}UseCase {
  Get${type}UseCase(this._repository);

  final ${type}Repository _repository;

  Future<Result<$type>> call({Object? cancelToken}) => _repository.fetch(cancelToken: cancelToken);
}
''',
    'data/models/${name}_model.dart':
        '''
${header('JSON shape of $title and its mapping to the entity.')}import '../../../../core/utils/json_x.dart';
import '../../domain/entities/$name.dart';

class ${type}Model {
  const ${type}Model({required this.id, required this.title});

  factory ${type}Model.fromJson(Map<String, dynamic> json) =>
      ${type}Model(id: json.string('id'), title: json.string('title'));

  /// Unwraps `{data: {...}}` envelopes, then parses.
  static ${type}Model fromResponse(Object? json) {
    final body = asJsonMap(json) ?? const <String, dynamic>{};
    return ${type}Model.fromJson(body.mapOrNull('data') ?? body);
  }

  final String id;
  final String title;

  $type toEntity() => $type(id: id, title: title);
}
''',
    'data/data_sources/${name}_remote_data_source.dart':
        '''
${header('HTTP calls of $title. Throws Failure (via ApiClient).')}import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/${name}_model.dart';

/// Relative API paths (Dio already has the base URL).
abstract final class ${type}Endpoints {
  static const root = '$path';
}

class ${type}RemoteDataSource {
  ${type}RemoteDataSource(this._api);

  final ApiClient _api;

$fetchMethod
}
''',
    'data/repositories/${name}_repository_impl.dart':
        '''
${header('${type}Repository over the remote data source (Failure → Result).')}import 'package:dio/dio.dart';

import '../../../../core/data/repository_guard.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/$name.dart';
import '../../domain/repositories/${name}_repository.dart';
import '../data_sources/${name}_remote_data_source.dart';

class ${type}RepositoryImpl with RepositoryGuard implements ${type}Repository {
  ${type}RepositoryImpl(this._remote);

  final ${type}RemoteDataSource _remote;

  @override
  Future<Result<$type>> fetch({Object? cancelToken}) => guard(() async {
    final model = await _remote.fetch(cancelToken: cancelToken is CancelToken ? cancelToken : null);
    return model.toEntity();
  });
}
''',
    'data/mock/${name}_mock_api.dart':
        '''
${header('Mock endpoint of $title for USE_MOCKS builds and tests.')}import '../../../../core/network/mock/mock_interceptor.dart';
import '../data_sources/${name}_remote_data_source.dart';

void register${type}MockApi(MockInterceptor mock) {
  mock.on(
    'GET',
    ${type}Endpoints.root,
    (_, _) async => const MockResponse({
      'data': {'id': '1', 'title': '$title'},
    }),
  );
}
''',
    'presentation/managers/${name}_cubit.dart':
        '''
${header('Loads $title for its screen.')}import '../../../../core/presentation/data_cubit.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/$name.dart';
$dependencyImport

class ${type}Cubit extends DataCubit<$type> {
  ${type}Cubit(this.$dependencyField);

  final $dependency $dependencyField;

  @override
  Future<Result<$type>> fetch() => $fetchCall;
}
''',
    'presentation/screens/${name}_screen.dart':
        '''
${header('$title screen.')}import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/generated/locale_keys.g.dart';
import '../../../../core/presentation/data_state.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../../../shared/widgets/states/data_state_builder.dart';
import '../../domain/entities/$name.dart';
import '../managers/${name}_cubit.dart';

/// Expects a [${type}Cubit] above it (created in `${type}Routes`).
class ${type}Screen extends StatelessWidget {
  const ${type}Screen({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: LocaleKeys.${name}_title.tr(),
    body: BlocBuilder<${type}Cubit, DataState<$type>>(
      builder: (context, state) => DataStateBuilder<$type>(
        state: state,
        onRetry: context.read<${type}Cubit>().load,
        builder: (context, data) =>
            ListView(children: [Text(data.title, style: Theme.of(context).textTheme.titleMedium)]),
      ),
    ),
  );
}
''',
    '${name}_routes.dart':
        '''
${header('Routes of $title (ids in the path, never state.extra).')}import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injector.dart';
import 'presentation/managers/${name}_cubit.dart';
import 'presentation/screens/${name}_screen.dart';

abstract final class ${type}Routes {
  static const path = '$path';

  /// Same shape as ItemsRoutes: full-screen sub-routes (forms, viewers) set
  /// `parentNavigatorKey: rootNavigatorKey` to open above the tab shell.
  static List<RouteBase> routes({required GlobalKey<NavigatorState> rootNavigatorKey}) => [
    GoRoute(
      path: path,
$routeBuilder
    ),
  ];
}
''',
    '${name}_di.dart':
        '''
${header('DI registrations of $title (add register${type}Feature to main.dart).')}import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/network/mock/mock_interceptor.dart';
import 'data/data_sources/${name}_remote_data_source.dart';
import 'data/mock/${name}_mock_api.dart';
import 'data/repositories/${name}_repository_impl.dart';
import 'domain/repositories/${name}_repository.dart';
${useCases ? "import 'domain/use_cases/get_${name}_use_case.dart';\n" : ''}import 'presentation/managers/${name}_cubit.dart';

Future<void> register${type}Feature() async {
  // getIt() infers each dependency from the constructor parameter type.
  getIt
$remoteRegistration
    ..registerLazySingleton<${type}Repository>(() => ${type}RepositoryImpl(getIt()))
${useCases ? '    ..registerLazySingleton<Get${type}UseCase>(() => Get${type}UseCase(getIt()))\n' : ''}    ..registerFactory<${type}Cubit>(() => ${type}Cubit(getIt()));

  if (getIt.isRegistered<MockInterceptor>()) register${type}MockApi(getIt<MockInterceptor>());
}
''',
  };
}

const String _usage = '''
Creates lib/features/<feature_name>/ following the sample feature's layers.

Usage: dart run tool/create_feature.dart <feature_name> [--use-cases]

  <feature_name>  snake_case, e.g. order_history.
  --use-cases     Also create domain/use_cases/get_<name>_use_case.dart and
                  inject it into the cubit (only when there are rules or
                  several repositories to combine).
  -h, --help      Show this help.

Creates: entity, model, remote data source + endpoints, mock endpoint,
repository interface + implementation (RepositoryGuard), DataCubit, screen
(AppScaffold + DataStateBuilder), <name>_di.dart and <name>_routes.dart, and
adds "<name>.title" to assets/translations/en.json and ar.json. Refuses to
overwrite an existing feature. Prints the lines to add to lib/main.dart and
lib/app_router.dart.
''';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    print(_usage);
    return;
  }
  final flags = args.where((a) => a.startsWith('-')).toSet();
  final names = args.where((a) => !a.startsWith('-')).toList();
  final unknown = flags.difference({'--use-cases'});
  if (unknown.isNotEmpty || names.length != 1) {
    stderr.writeln('${unknown.isNotEmpty ? 'Unknown option(s): ${unknown.join(', ')}\n\n' : ''}$_usage');
    exit(64);
  }
  try {
    final result = createFeature(names.single, root: Directory.current, useCases: flags.contains('--use-cases'));
    print('Created feature "${result.name}":');
    for (final file in result.files) {
      print('  $file');
    }
    for (final locale in result.translationsUpdated) {
      print('  assets/translations/$locale.json (+ ${result.name}.title)');
    }
    print('\n${result.nextSteps}');
  } on FeatureException catch (e) {
    stderr.writeln(e.message);
    exit(e.exitCode);
  }
}
