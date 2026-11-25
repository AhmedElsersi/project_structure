// UI mapping of ItemStatus (label key + tone) and its chip.
//
// Source: lexa-control lib/core/ui/widgets/status_pill.dart idea (status →
//         semantic tone, never a raw colour) via the template's StatusChip.
// See docs/WIDGETS.md#display.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/generated/locale_keys.g.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../shared/widgets/display/status_chip.dart';
import '../../domain/entities/item.dart';

/// Presentation of [ItemStatus]; the domain enum stays free of UI concerns.
extension ItemStatusUi on ItemStatus {
  String get labelKey => switch (this) {
    ItemStatus.draft => LocaleKeys.items_status_draft,
    ItemStatus.active => LocaleKeys.items_status_active,
    ItemStatus.archived => LocaleKeys.items_status_archived,
    ItemStatus.unknown => LocaleKeys.items_status_unknown,
  };

  StatusTone get tone => switch (this) {
    ItemStatus.draft => StatusTone.info,
    ItemStatus.active => StatusTone.success,
    ItemStatus.archived => StatusTone.warning,
    ItemStatus.unknown => StatusTone.neutral,
  };
}

/// The status pill of an item.
class ItemStatusChip extends StatelessWidget {
  const ItemStatusChip({super.key, required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) => StatusChip(label: status.labelKey.tr(), tone: status.tone);
}
