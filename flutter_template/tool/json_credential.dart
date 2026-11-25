// Reads a JSON credential (service account, API key file...) given either as a
// FILE PATH or as BASE64 of the JSON — the convention for tool/ scripts and CI
// secrets. Never prints the secret.
//
// Source: new (approved convention: "JSON credentials supported as file path
//         or base64"; .env.example GOOGLE_SERVICE_ACCOUNT_JSON).
// See docs/CONVENTIONS.md#environment.
//
// Usage (from the project root):
//   dart run tool/json_credential.dart <ENV_VAR> [--env-file .env]
//   dart run tool/json_credential.dart GOOGLE_SERVICE_ACCOUNT_JSON
//
// In other tool scripts:
//   import 'json_credential.dart';
//   final json = resolveJsonCredential(Platform.environment['GOOGLE_SERVICE_ACCOUNT_JSON'] ?? '');
//
// Pure Dart (no Flutter imports) so it runs with `dart run`.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Resolves [value] to a JSON object:
///
/// 1. a path to an existing file (absolute, or relative to [baseDir] /
///    the current directory) → the file is read and decoded;
/// 2. otherwise base64 (standard or URL-safe, padding optional, whitespace
///    and line breaks ignored) of a JSON object → decoded.
///
/// Throws [FormatException] otherwise. Messages never contain the value.
Map<String, dynamic> resolveJsonCredential(String value, {String? baseDir}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) throw const FormatException('The credential is empty.');

  final file = _existingFile(trimmed, baseDir);
  if (file != null) {
    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException {
      throw FormatException('The file ${file.path} is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) throw FormatException('The file ${file.path} does not hold a JSON object.');
    return decoded;
  }

  final fromBase64 = _decodeBase64Json(trimmed);
  if (fromBase64 != null) return fromBase64;

  if (_looksLikePath(trimmed)) {
    // A path is not a secret: naming it helps fix typos.
    final resolved = _resolvePath(trimmed, baseDir);
    throw FormatException('No file at $resolved (and the value is not base64 of a JSON object).');
  }
  throw const FormatException(
    'The credential is neither a path to an existing JSON file nor base64 of a JSON object. '
    'Encode a file with: base64 -i credentials.json | tr -d "\\n"',
  );
}

String _resolvePath(String path, String? baseDir) {
  var expanded = path;
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (expanded.startsWith('~/') && home != null) expanded = '$home${expanded.substring(1)}';
  final isAbsolute = expanded.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(expanded);
  if (isAbsolute || baseDir == null) return expanded;
  return '$baseDir/$expanded';
}

File? _existingFile(String value, String? baseDir) {
  // Base64 of a real credential is far longer than any sane path.
  if (value.length > 1024 || value.contains('\n')) return null;
  try {
    final file = File(_resolvePath(value, baseDir));
    return file.existsSync() ? file : null;
  } on Object {
    return null;
  }
}

bool _looksLikePath(String value) =>
    value.endsWith('.json') ||
    value.startsWith('./') ||
    value.startsWith('../') ||
    value.startsWith('~/') ||
    (value.startsWith('/') && !value.contains('='));

Map<String, dynamic>? _decodeBase64Json(String value) {
  var compact = value.replaceAll(RegExp(r'\s'), '');
  if (compact.isEmpty || !RegExp(r'^[A-Za-z0-9+/_-]+={0,2}$').hasMatch(compact)) return null;
  compact = compact.replaceAll('-', '+').replaceAll('_', '/').replaceAll('=', '');
  final padded = compact.padRight((compact.length + 3) ~/ 4 * 4, '=');
  try {
    final decoded = jsonDecode(utf8.decode(base64.decode(padded)));
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Parses a `.env` file: `KEY=value`, `export KEY=value`, `#` comments,
/// optional single/double quotes around the value.
Map<String, String> parseEnvFile(String content) {
  final result = <String, String>{};
  for (final raw in const LineSplitter().convert(content)) {
    var line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('export ')) line = line.substring(7).trimLeft();
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim();
    var value = line.substring(eq + 1).trim();
    final quoted = value.length >= 2 && (value[0] == '"' || value[0] == "'") && value.endsWith(value[0]);
    if (quoted) {
      value = value.substring(1, value.length - 1);
    } else {
      final comment = value.indexOf(' #');
      if (comment >= 0) value = value.substring(0, comment).trimRight();
    }
    result[key] = value;
  }
  return result;
}

/// Masks an email so it can be logged: `ci-bot@my-project.iam.gserviceaccount.com`
/// → `ci***@my***.iam.gserviceaccount.com`.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return '***';
  String mask(String part) => part.length <= 2 ? '***' : '${part.substring(0, 2)}***';
  final domain = email.substring(at + 1);
  final dot = domain.indexOf('.');
  final maskedDomain = dot <= 0 ? mask(domain) : '${mask(domain.substring(0, dot))}${domain.substring(dot)}';
  return '${mask(email.substring(0, at))}@$maskedDomain';
}

/// Non-secret summary of a credential: its keys, `type` and a masked
/// `client_email`.
List<String> describeCredential(Map<String, dynamic> json) {
  final keys = json.keys.toList()..sort();
  final type = json['type'];
  final email = json['client_email'];
  return [
    'keys: ${keys.join(', ')}',
    if (type is String) 'type: $type',
    if (email is String) 'client_email: ${maskEmail(email)}',
  ];
}

const String _usage = '''
Resolves a JSON credential from an environment variable that holds either a
file path or base64 of the JSON, and prints non-secret metadata only.

Usage: dart run tool/json_credential.dart <ENV_VAR> [--env-file .env]

  <ENV_VAR>          Variable name, e.g. GOOGLE_SERVICE_ACCOUNT_JSON.
  --env-file <path>  .env file to read when the variable is not in the
                     process environment (default: .env if it exists).
  -h, --help         Show this help.

Exit codes: 0 resolved, 1 missing / unreadable, 64 usage error.
''';

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    print(_usage);
    if (args.isEmpty) exit(64);
    return;
  }
  String? name;
  String? envFile;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--env-file') {
      if (i + 1 >= args.length) {
        stderr.writeln('--env-file needs a path.\n\n$_usage');
        exit(64);
      }
      envFile = args[++i];
    } else if (arg.startsWith('--env-file=')) {
      envFile = arg.substring('--env-file='.length);
    } else if (arg.startsWith('-') || name != null) {
      stderr.writeln('Unexpected argument: $arg\n\n$_usage');
      exit(64);
    } else {
      name = arg;
    }
  }
  if (name == null) {
    stderr.writeln(_usage);
    exit(64);
  }

  var value = Platform.environment[name];
  var source = 'process environment';
  String? baseDir;
  if (value == null || value.trim().isEmpty) {
    final path = envFile ?? '.env';
    final file = File(path);
    if (file.existsSync()) {
      value = parseEnvFile(file.readAsStringSync())[name];
      source = path;
      baseDir = file.absolute.parent.path;
    } else if (envFile != null) {
      stderr.writeln('No env file at $path.');
      exit(1);
    }
  }
  if (value == null || value.trim().isEmpty) {
    stderr.writeln(
      '$name is not set (looked in the process environment${envFile == null ? ' and .env' : ' and $envFile'}).',
    );
    exit(1);
  }

  try {
    final json = resolveJsonCredential(value, baseDir: baseDir);
    print('$name (from $source) resolved:');
    for (final line in describeCredential(json)) {
      print('  $line');
    }
  } on FormatException catch (e) {
    stderr.writeln('$name: ${e.message}');
    exit(1);
  }
}
