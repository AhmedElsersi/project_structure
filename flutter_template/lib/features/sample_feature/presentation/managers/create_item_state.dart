// State of the "create item" form: submitting, failure (field or general),
// created item.
//
// Source: chinaparts-seller lib/core/base_architecture/presentation/managers/
//         base_single_class_state_bloc/base_single_class_state.dart
//         ({status, failure, success} idea, specialised for a form: field
//         errors come from the Failure).
// Fixes: the house-style `failure ?? this.failure` copyWith that could never
//        clear a failure — every transition builds a fresh state.
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/item.dart';

class CreateItemState extends Equatable {
  const CreateItemState({this.isSubmitting = false, this.failure, this.created});

  /// A request is in flight (button busy, fields locked).
  final bool isSubmitting;

  /// Last submit's failure (cleared by the next submit).
  final Failure? failure;

  /// Set once the backend accepted the item.
  final Item? created;

  /// Server or domain message for [field] (e.g. `title`), shown under it.
  String? fieldError(String field) => switch (failure) {
    final ValidationFailure validation => validation.fieldError(field),
    _ => null,
  };

  /// A failure that no field can show (network, server, validation without
  /// field errors) — shown in a snackbar.
  Failure? get generalFailure => switch (failure) {
    final ValidationFailure validation when validation.hasFieldErrors => null,
    final other => other,
  };

  @override
  List<Object?> get props => [isSubmitting, failure, created];
}
