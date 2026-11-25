// Tests for lib/core/pagination/page.dart. Source: new
import 'package:app_template/core/pagination/page.dart';
import 'package:flutter_test/flutter_test.dart';

int _id(Map<String, dynamic> json) => json['id'] as int;

List<Map<String, dynamic>> _items(List<int> ids) => [
  for (final id in ids) <String, dynamic>{'id': id},
];

void main() {
  group('Page.fromJson', () {
    test('nested meta with last_page', () {
      final page = Page.fromJson(<String, dynamic>{
        'data': _items([1, 2]),
        'meta': {'current_page': 1, 'last_page': 3, 'total': 25},
      }, _id);
      expect(page.items, [1, 2]);
      expect(page.page, 1);
      expect(page.hasMore, isTrue);
      expect(page.total, 25);
    });

    test('nested meta on the last page → hasMore false', () {
      final page = Page.fromJson(<String, dynamic>{
        'data': _items([9]),
        'meta': {'current_page': 3, 'last_page': 3},
      }, _id);
      expect(page.page, 3);
      expect(page.hasMore, isFalse);
      expect(page.total, isNull);
    });

    test('flat (Laravel-style) keys at the root', () {
      final page = Page.fromJson(<String, dynamic>{
        'data': _items([1]),
        'current_page': 2,
        'last_page': 2,
        'total': 11,
      }, _id);
      expect(page.page, 2);
      expect(page.hasMore, isFalse);
      expect(page.total, 11);
    });

    test('explicit has_more wins over last_page (nested and flat)', () {
      expect(
        Page.fromJson(<String, dynamic>{
          'items': _items([1]),
          'meta': {'page': 2, 'last_page': 9, 'has_more': false},
        }, _id).hasMore,
        isFalse,
      );
      final flat = Page.fromJson(<String, dynamic>{
        'items': _items([1]),
        'page': 4,
        'has_more': true,
      }, _id);
      expect(flat.items, [1]);
      expect(flat.page, 4);
      expect(flat.hasMore, isTrue);
    });

    test('total_pages is an alias of last_page', () {
      final page = Page.fromJson(<String, dynamic>{
        'data': _items([1]),
        'meta': {'current_page': 1, 'total_pages': 2},
      }, _id);
      expect(page.hasMore, isTrue);
    });

    test('numeric strings and doubles are accepted', () {
      final page = Page.fromJson(<String, dynamic>{
        'data': _items([1]),
        'meta': {'current_page': '2', 'last_page': 5.0, 'total': '40'},
      }, _id);
      expect(page.page, 2);
      expect(page.hasMore, isTrue);
      expect(page.total, 40);
    });

    test('without paging info: page 1, hasMore while items keep coming', () {
      final some = Page.fromJson(<String, dynamic>{
        'data': _items([1]),
      }, _id);
      expect(some.page, 1);
      expect(some.hasMore, isTrue);
      final none = Page.fromJson(<String, dynamic>{'data': <dynamic>[]}, _id);
      expect(none.hasMore, isFalse);
    });

    test('non-map items are skipped; bad bodies yield an empty page', () {
      final page = Page.fromJson(<String, dynamic>{
        'data': [
          {'id': 1},
          'junk',
          null,
          {'id': 2},
        ],
        'meta': {'current_page': 1, 'last_page': 1},
      }, _id);
      expect(page.items, [1, 2]);
      for (final bad in <Object?>[
        null,
        'oops',
        42,
        <dynamic>[],
        <String, dynamic>{'data': 'not a list'},
      ]) {
        final empty = Page.fromJson(bad, _id);
        expect(empty.items, isEmpty, reason: '$bad');
        expect(empty.hasMore, isFalse, reason: '$bad');
      }
    });
  });

  test('Page.empty', () {
    final page = Page.empty<int>();
    expect(page.items, isEmpty);
    expect(page.page, 1);
    expect(page.hasMore, isFalse);
    expect(page.total, 0);
  });
}
