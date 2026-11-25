// Tests for tool/json_credential.dart: path or base64 → JSON, never leaking
// the secret in errors.
//
// Source: new (convention "JSON credentials supported as file path or base64").
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/json_credential.dart';

const _credential = {
  'type': 'service_account',
  'project_id': 'demo-project',
  'private_key': '-----BEGIN PRIVATE KEY-----\nSECRET\n-----END PRIVATE KEY-----\n',
  'client_email': 'ci-bot@demo-project.iam.gserviceaccount.com',
};

void main() {
  late Directory dir;
  late String encoded;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('json_credential_');
    File('${dir.path}/sa.json').writeAsStringSync(jsonEncode(_credential));
    encoded = base64.encode(utf8.encode(jsonEncode(_credential)));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('reads a file path (absolute, or relative to baseDir)', () {
    expect(resolveJsonCredential('${dir.path}/sa.json'), _credential);
    expect(resolveJsonCredential('sa.json', baseDir: dir.path), _credential);
    expect(resolveJsonCredential('  ./sa.json \n', baseDir: dir.path), _credential);
  });

  test('decodes standard and URL-safe base64, with or without padding and line breaks', () {
    expect(resolveJsonCredential(encoded), _credential);
    final urlSafe = base64Url.encode(utf8.encode(jsonEncode(_credential))).replaceAll('=', '');
    expect(resolveJsonCredential(urlSafe), _credential);
    final wrapped = [
      for (var i = 0; i < encoded.length; i += 76) encoded.substring(i, (i + 76).clamp(0, encoded.length)),
    ].join('\n');
    expect(resolveJsonCredential(wrapped), _credential);
  });

  test('rejects anything else without echoing the value', () {
    void expectFormat(String value, Matcher message) => expect(
      () => resolveJsonCredential(value, baseDir: dir.path),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', message)),
    );

    expectFormat('', contains('empty'));
    expectFormat('missing.json', allOf(contains('No file at'), contains('missing.json')));
    const secret = 'not-a-path-and-not-base64!';
    expectFormat(secret, isNot(contains(secret)));
    // base64 of something that is not a JSON object
    final notObject = base64.encode(utf8.encode('[1, 2]'));
    expectFormat(notObject, isNot(contains(notObject)));
    File('${dir.path}/bad.json').writeAsStringSync('{oops');
    expectFormat('bad.json', contains('not valid JSON'));
  });

  test('parses .env files (export, quotes, comments)', () {
    final env = parseEnvFile('''
# comment
export A=1
B="two words"
C='x=y'
D=value # trailing comment
EMPTY=
''');
    expect(env, {'A': '1', 'B': 'two words', 'C': 'x=y', 'D': 'value', 'EMPTY': ''});
  });

  test('describes a credential with non-secret metadata only', () {
    final lines = describeCredential(_credential).join('\n');
    expect(lines, contains('type: service_account'));
    expect(lines, contains('client_email: ci***@de***.iam.gserviceaccount.com'));
    expect(lines, contains('private_key'));
    expect(lines, isNot(contains('SECRET')));
    expect(lines, isNot(contains('ci-bot')));
    expect(maskEmail('a@b'), '***@***');
  });

  test('CLI resolves a variable from an env file and never prints the secret', () async {
    File('${dir.path}/.env').writeAsStringSync('MY_CREDENTIAL=$encoded\n');
    final result = await Process.run('dart', [
      'run',
      '${Directory.current.path}/tool/json_credential.dart',
      'MY_CREDENTIAL',
      '--env-file',
      '${dir.path}/.env',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(result.stdout, contains('type: service_account'));
    expect(result.stdout, isNot(contains('SECRET')));
    expect(result.stdout, isNot(contains(encoded.substring(0, 20))));
  });
}
