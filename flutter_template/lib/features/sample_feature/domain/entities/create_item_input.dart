// What the "create item" form submits (pure Dart value object).
//
// Source: new (pattern example: forms build an input object, the use case
//         cleans and validates it, the repository sends it).
import 'package:equatable/equatable.dart';

import 'item.dart';

class CreateItemInput extends Equatable {
  const CreateItemInput({required this.title, this.description = '', this.status = ItemStatus.draft});

  final String title;
  final String description;
  final ItemStatus status;

  /// The same input with surrounding whitespace removed.
  CreateItemInput trimmed() => CreateItemInput(title: title.trim(), description: description.trim(), status: status);

  @override
  List<Object?> get props => [title, description, status];
}
