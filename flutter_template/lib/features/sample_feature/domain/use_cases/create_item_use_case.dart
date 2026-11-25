// Creates an item after cleaning the input and enforcing a domain rule.
//
// Source: corsa-customer create_feature.dart (`--use-cases`: use cases only
//         where a flow needs one; no UI side effects in a use case).
// Merged: markspulse lib/domain use cases (rules live in pure Dart, tested
//         without widgets; typed Failure out).
// See docs/ARCHITECTURE.md#use-cases.
//
// Use cases are OPTIONAL. Add one only when there is a business rule to
// enforce or several repositories / services to orchestrate. A cubit that
// just loads or saves data talks to the repository directly (see
// ItemsListCubit / ItemDetailsCubit).
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/generated/locale_keys.g.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/formatters.dart';
import '../entities/create_item_input.dart';
import '../entities/item.dart';
import '../repositories/items_repository.dart';

class CreateItemUseCase {
  CreateItemUseCase(this._repository);

  final ItemsRepository _repository;

  /// Shortest accepted title (user-perceived characters).
  static const int minTitleLength = 3;

  /// Trims [input], rejects a title shorter than [minTitleLength] with a
  /// field error (no request is sent), then creates the item.
  Future<Result<Item>> call(CreateItemInput input) async {
    final clean = input.trimmed();
    // `runes` counts code points, so Arabic letters count as one each.
    if (clean.title.runes.length < minTitleLength) {
      return Err(
        ValidationFailure(
          code: 'title_too_short',
          fieldErrors: {
            'title': [
              LocaleKeys.items_title_too_short.tr(namedArgs: {'min': AppFormat.number(minTitleLength)}),
            ],
          },
        ),
      );
    }
    return _repository.create(clean);
  }
}
