// Tests for lib/features/sample_feature/data/models/item_model.dart and the
// ItemStatus fallback.
//
// Source: new.
import 'package:app_template/features/sample_feature/data/models/item_model.dart';
import 'package:app_template/features/sample_feature/domain/entities/create_item_input.dart';
import 'package:app_template/features/sample_feature/domain/entities/item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a complete row into the entity', () {
    final item = ItemModel.fromJson({
      'id': '7',
      'title': 'Sample item 07',
      'description': 'Text',
      'status': 'active',
      'image_url': 'https://picsum.photos/seed/7/400/300',
      'created_at': '2026-10-30T09:00:00Z',
    }).toEntity();

    expect(item.id, '7');
    expect(item.title, 'Sample item 07');
    expect(item.description, 'Text');
    expect(item.status, ItemStatus.active);
    expect(item.imageUrl, 'https://picsum.photos/seed/7/400/300');
    expect(item.createdAt, DateTime.utc(2026, 10, 30, 9).toLocal());
  });

  test('is tolerant: numeric id, epoch seconds, missing optional fields', () {
    final item = ItemModel.fromJson({'id': 12, 'created_at': 1793350800}).toEntity();
    expect(item.id, '12');
    expect(item.title, '');
    expect(item.description, '');
    expect(item.imageUrl, isNull);
    expect(item.status, ItemStatus.unknown);
    expect(item.createdAt, DateTime.fromMillisecondsSinceEpoch(1793350800 * 1000));
  });

  test('a missing date falls back to the epoch instead of dropping the item', () {
    expect(ItemModel.fromJson({'id': '1'}).toEntity().createdAt, DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('unknown or oddly cased statuses map safely', () {
    expect(ItemStatus.fromValue('ARCHIVED'), ItemStatus.archived);
    expect(ItemStatus.fromValue(' draft '), ItemStatus.draft);
    expect(ItemStatus.fromValue('pending_review'), ItemStatus.unknown);
    expect(ItemStatus.fromValue('unknown'), ItemStatus.unknown);
    expect(ItemStatus.fromValue(null), ItemStatus.unknown);
    expect(ItemStatus.selectable, isNot(contains(ItemStatus.unknown)));
  });

  test('a row without an id is rejected (tryParse → null)', () {
    expect(() => ItemModel.fromJson({'title': 'x'}), throwsFormatException);
    expect(ItemModel.tryParse({'id': ' ', 'title': 'x'}), isNull);
    expect(ItemModel.tryParse({'id': 'a'}), isNotNull);
  });

  test('fromResponse unwraps {data: ...} and accepts a bare object', () {
    expect(
      ItemModel.fromResponse({
        'data': {'id': '1', 'title': 'A'},
      }).title,
      'A',
    );
    expect(ItemModel.fromResponse({'id': '2', 'title': 'B'}).id, '2');
  });

  test('createBody sends the wire status value', () {
    expect(ItemModel.createBody(const CreateItemInput(title: 'T', description: 'D', status: ItemStatus.archived)), {
      'title': 'T',
      'description': 'D',
      'status': 'archived',
    });
  });
}
