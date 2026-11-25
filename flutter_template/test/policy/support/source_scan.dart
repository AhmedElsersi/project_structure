// Tiny Dart-source scanner for the policy tests: lists lib/ files, blanks
// comments (keeping line numbers), extracts call arguments, reports file:line.
//
// Source: markspulse test/domain/architecture_test.dart (scan lib/ source text
//         line by line and report `path:line  code`).
// Merged: chinaparts-seller tool/check_translations.dart (skip comment lines);
//         new (call-argument extraction with nesting, so multi-line widget
//         constructors are checked as a whole).
import 'dart:io';

/// One rule violation, printed as `path:line  rule  snippet`.
class Violation {
  const Violation(this.path, this.line, this.rule, this.snippet);

  final String path;
  final int line;
  final String rule;
  final String snippet;

  @override
  String toString() => '$path:$line  $rule  ${snippet.replaceAll(RegExp(r'\s+'), ' ').trim()}';
}

/// A Dart file under lib/ with its path relative to the project root
/// (always `/`-separated) and its source with comments blanked.
class SourceFile {
  SourceFile(this.path, this.source) : code = stripComments(source);

  final String path;
  final String source;

  /// [source] with comments replaced by spaces (same offsets and lines).
  final String code;

  int lineOf(int offset) => '\n'.allMatches(code.substring(0, offset)).length + 1;

  Violation violation(int offset, String rule, String snippet) => Violation(path, lineOf(offset), rule, snippet);
}

/// Every hand-written Dart file under [dir] (generated `*.g.dart` and the
/// generated localization folder are skipped).
List<SourceFile> dartFiles([String dir = 'lib']) {
  if (!Directory(dir).existsSync()) throw StateError('No $dir/ — run the tests from the project root.');
  final files =
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
          .map((f) => SourceFile(f.path.replaceAll(r'\', '/'), f.readAsStringSync()))
          .where((f) => !f.path.contains('/generated/'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) throw StateError('No Dart files under $dir/.');
  return files;
}

/// Replaces `//` and `/* */` comments with spaces; strings are kept.
String stripComments(String source) {
  final out = StringBuffer();
  var i = 0;
  final n = source.length;
  while (i < n) {
    final c = source[i];
    if (c == '/' && i + 1 < n && source[i + 1] == '/') {
      while (i < n && source[i] != '\n') {
        out.write(' ');
        i++;
      }
      continue;
    }
    if (c == '/' && i + 1 < n && source[i + 1] == '*') {
      var depth = 0;
      do {
        if (source.startsWith('/*', i)) {
          depth++;
          out.write('  ');
          i += 2;
        } else if (source.startsWith('*/', i)) {
          depth--;
          out.write('  ');
          i += 2;
        } else {
          out.write(source[i] == '\n' ? '\n' : ' ');
          i++;
        }
      } while (i < n && depth > 0);
      continue;
    }
    if (c == "'" || c == '"') {
      final end = stringEnd(source, i);
      out.write(source.substring(i, end));
      i = end;
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// Index just after the string literal whose opening quote is at [start].
/// Handles raw strings (`r'...'`), triple quotes, escapes and `${...}`.
int stringEnd(String s, int start) {
  var i = start;
  final raw = start > 0 && s[start - 1] == 'r' && (start < 2 || !RegExp(r'[A-Za-z0-9_$]').hasMatch(s[start - 2]));
  final quote = s[i];
  final triple = s.startsWith(quote * 3, i);
  final closing = triple ? quote * 3 : quote;
  i += closing.length;
  while (i < s.length) {
    if (!raw && s[i] == r'\') {
      i += 2;
      continue;
    }
    if (!raw && s.startsWith(r'${', i)) {
      i = _blockEnd(s, i + 1);
      continue;
    }
    if (s.startsWith(closing, i)) return i + closing.length;
    if (!triple && s[i] == '\n') return i; // unterminated: stop at the line end
    i++;
  }
  return s.length;
}

/// Index just after the bracket that closes the one at [open] (`(`, `[`, `{`),
/// skipping strings.
int _blockEnd(String s, int open) {
  var depth = 0;
  var i = open;
  while (i < s.length) {
    final c = s[i];
    if (c == "'" || c == '"') {
      i = stringEnd(s, i);
      continue;
    }
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') {
      depth--;
      if (depth == 0) return i + 1;
    }
    i++;
  }
  return s.length;
}

/// The argument text of the call whose `(` is at [open] (without the
/// parentheses).
String argumentsAt(String code, int open) {
  final end = _blockEnd(code, open);
  return code.substring(open + 1, end - 1);
}

/// [args] with every nested bracket group and string replaced by spaces, so
/// only the call's own named arguments remain (`Positioned(left: 0, child:
/// Padding(padding: EdgeInsets.only(left: 4)))` → `left: 0, child: Padding  `).
String topLevel(String args) {
  final out = StringBuffer();
  var i = 0;
  while (i < args.length) {
    final c = args[i];
    if (c == "'" || c == '"') {
      final end = stringEnd(args, i);
      out.write(' ' * (end - i));
      i = end;
      continue;
    }
    if (c == '(' || c == '[' || c == '{') {
      final end = _blockEnd(args, i);
      out.write(' ' * (end - i));
      i = end;
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// Splits top-level arguments on commas (`a, b(c, d), e` → 3 parts).
List<String> splitArguments(String args) {
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  var i = 0;
  while (i < args.length) {
    final c = args[i];
    if (c == "'" || c == '"') {
      i = stringEnd(args, i);
      continue;
    }
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') depth--;
    if (c == ',' && depth == 0) {
      parts.add(args.substring(start, i).trim());
      start = i + 1;
    }
    i++;
  }
  final last = args.substring(start).trim();
  if (last.isNotEmpty) parts.add(last);
  return parts;
}

/// Calls of [pattern] (a regex ending right before `(`) with their argument
/// text: `(offset, args)`.
Iterable<({int offset, String args})> callsOf(String code, RegExp pattern) sync* {
  for (final match in pattern.allMatches(code)) {
    var open = match.end;
    while (open < code.length && code[open] == ' ') {
      open++;
    }
    if (open >= code.length || code[open] != '(') continue;
    yield (offset: match.start, args: argumentsAt(code, open));
  }
}

/// Formats violations for a failure message.
String report(List<Violation> violations) => '\n${violations.join('\n')}\n';
