// Item entity + status enum of the sample feature (pure Dart, no Flutter).
//
// Source: new (pattern example for the template's clean-architecture layers).
// Merged: corsa-customer lib/core/enums/app_enums.dart (enums with an
//         `unknown` fallback: a new backend value never crashes an old build).
// See docs/ARCHITECTURE.md#features.
import 'package:equatable/equatable.dart';

/// Lifecycle of an [Item]. [unknown] absorbs values this build doesn't know.
enum ItemStatus {
  draft('draft'),
  active('active'),
  archived('archived'),
  unknown('unknown');

  const ItemStatus(this.value);

  /// Wire value sent to / received from the backend.
  final String value;

  /// Statuses a user can pick (never [unknown]).
  static const List<ItemStatus> selectable = [draft, active, archived];

  /// Parses a backend value (case-insensitive); anything else is [unknown].
  static ItemStatus fromValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final status in values) {
      if (status != unknown && status.value == normalized) return status;
    }
    return unknown;
  }
}

/// One item as the app understands it (independent of the JSON shape).
class Item extends Equatable {
  const Item({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.description = '',
    this.imageUrl,
  });

  final String id;
  final String title;

  /// Empty when the item has no description.
  final String description;
  final ItemStatus status;
  final String? imageUrl;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, title, description, status, imageUrl, createdAt];
}
