// JSON shape of an item and its mapping to the domain entity.
//
// Source: corsa-customer lib/core/utilities/converters/json_helpers.dart usage
//         in models (tolerant readers: numbers as strings, missing keys).
// Merged: markspulse lib/domain/common/parse.dart idea (a malformed row is
//         skipped, never fails the whole list — see [ItemModel.tryParse]).
// See docs/SERVICES.md#json-helpers.
import '../../../../core/utils/json_x.dart';
import '../../domain/entities/create_item_input.dart';
import '../../domain/entities/item.dart';

class ItemModel {
  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
  });

  /// Reads `{id, title, description, status, image_url, created_at}`.
  /// `id` may be a number or a string; everything else is optional.
  /// Throws [FormatException] when there is no id (the row is unusable).
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    final id = json.stringOrNull('id');
    if (id == null) throw const FormatException('Item without an id');
    return ItemModel(
      id: id,
      title: json.string('title'),
      description: json.string('description'),
      status: json.stringOrNull('status'),
      imageUrl: json.stringOrNull('image_url'),
      createdAt: json.dateTime('created_at'),
    );
  }

  /// [ItemModel.fromJson], or null for a malformed row.
  static ItemModel? tryParse(Map<String, dynamic> json) {
    try {
      return ItemModel.fromJson(json);
    } on Object {
      return null;
    }
  }

  /// Unwraps `{data: {...}}` envelopes, then parses.
  static ItemModel fromResponse(Object? json) {
    final body = asJsonMap(json) ?? const <String, dynamic>{};
    return ItemModel.fromJson(body.mapOrNull('data') ?? body);
  }

  /// Request body for `POST /items`.
  static Map<String, dynamic> createBody(CreateItemInput input) => {
    'title': input.title,
    'description': input.description,
    'status': input.status.value,
  };

  final String id;
  final String title;
  final String description;

  /// Raw backend value; unknown values map to [ItemStatus.unknown].
  final String? status;
  final String? imageUrl;
  final DateTime? createdAt;

  /// A missing date never hides the item: it falls back to the epoch.
  Item toEntity() => Item(
    id: id,
    title: title,
    description: description,
    status: ItemStatus.fromValue(status),
    imageUrl: imageUrl,
    createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
