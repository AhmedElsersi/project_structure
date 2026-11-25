// Tests for lib/core/utils/json_x.dart (tolerant JSON readers). Source: new
import 'package:app_template/core/utils/json_x.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = <String, dynamic>{
    'id': 7,
    'name': 'Item',
    'blank': '   ',
    'price': '12.5',
    'count': '3',
    'countDouble': 4.9,
    'flag1': 1,
    'flag0': 0,
    'flagStr': 'true',
    'flagOne': '1',
    'flagYes': 'YES',
    'flagWeird': 'maybe',
    'iso': '2026-11-05T10:00:00Z',
    'epochSec': 1700000000,
    'epochMs': '1700000000000',
    'nested': {'a': 1},
    'nestedLoose': <Object, Object>{1: 'x'},
    'items': [
      {'id': 1},
      'junk',
      {'id': 'bad'},
      {'id': 3},
      null,
    ],
    'tags': [1, 'a', null, ' ', <String, dynamic>{}],
    'nullValue': null,
  };

  test('string / stringOrNull', () {
    expect(json.string('name'), 'Item');
    expect(json.string('id'), '7');
    expect(json.string('missing', 'fallback'), 'fallback');
    expect(json.stringOrNull('blank'), isNull);
    expect(json.stringOrNull('nested'), isNull);
    expect(json.stringOrNull('nullValue'), isNull);
  });

  test('intOr / doubleOr from numbers and numeric strings', () {
    expect(json.intOr('id'), 7);
    expect(json.intOr('count'), 3);
    expect(json.intOr('countDouble'), 4);
    expect(json.intOr('price'), 12, reason: '"12.5" truncates');
    expect(json.intOr('name', -1), -1);
    expect(json.intOrNull('flagStr'), isNull);
    expect(json.doubleOr('price'), 12.5);
    expect(json.doubleOr('id'), 7.0);
    expect(json.doubleOr('missing', 1.5), 1.5);
    expect(json.doubleOrNull('flag1'), 1.0);
  });

  test('boolOr accepts true/false, 1/0, "true", "1", "yes"', () {
    expect(json.boolOr('flag1'), isTrue);
    expect(json.boolOr('flag0', true), isFalse);
    expect(json.boolOr('flagStr'), isTrue);
    expect(json.boolOr('flagOne'), isTrue);
    expect(json.boolOr('flagYes'), isTrue);
    expect(json.boolOr('flagWeird', true), isTrue, reason: 'unknown → fallback');
    expect(json.boolOrNull('missing'), isNull);
  });

  test('dateTime from ISO strings and epoch seconds / milliseconds', () {
    expect(json.dateTime('iso')!.toUtc(), DateTime.utc(2026, 11, 5, 10));
    expect(json.dateTime('epochSec')!.toUtc(), DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
    expect(json.dateTime('epochMs')!.toUtc(), DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
    expect(json.dateTime('name'), isNull);
    expect(json.dateTime('missing'), isNull);
  });

  test('mapOrNull converts loosely typed maps', () {
    expect(json.mapOrNull('nested'), {'a': 1});
    expect(json.mapOrNull('nestedLoose'), {'1': 'x'});
    expect(json.mapOrNull('name'), isNull);
  });

  test('listOf skips non-objects and items whose mapper throws', () {
    final ids = json.listOf('items', (m) => m['id'] as int);
    expect(ids, [1, 3]);
    expect(json.listOf('missing', (m) => m), isEmpty);
    expect(json.listOf('name', (m) => m), isEmpty);
  });

  test('stringList keeps non-blank scalars', () {
    expect(json.stringList('tags'), ['1', 'a']);
    expect(json.stringList('missing'), isEmpty);
  });

  test('asJsonMap', () {
    expect(asJsonMap({'a': 1}), {'a': 1});
    expect(asJsonMap('x'), isNull);
    expect(asJsonMap(null), isNull);
  });
}
