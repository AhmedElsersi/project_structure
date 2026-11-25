// One item in the list (row with a thumbnail) or the grid (card with the image
// on top). RTL-safe: only start/end paddings and directional rows.
//
// Source: corsa-customer lib/core/utilities/widgets/shared/widgets/app_image.dart
//         usage in list tiles (cached thumbnail decoded at display size).
// Merged: chinaparts-customer CLAUDE.md rule "fixed-height rails grow with the
//         text scale" → [ItemTile.cardExtent] sizes grid cells from the
//         current text scaler instead of a fixed number.
// See docs/WIDGETS.md#lists.
import 'package:flutter/material.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/display/app_card.dart';
import '../../../../shared/widgets/media/app_network_image.dart';
import '../../domain/entities/item.dart';
import 'item_status_chip.dart';

/// How an [ItemTile] is laid out.
enum ItemTileLayout {
  /// Thumbnail at the start, text at the end (lists, phones).
  row,

  /// Image on top, text below; needs a bounded height (grid cells with
  /// [ItemTile.cardExtent]).
  card,
}

class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, this.onTap, this.layout = ItemTileLayout.row});

  final Item item;
  final VoidCallback? onTap;
  final ItemTileLayout layout;

  /// Shared with the details screen so the image flies between them.
  static String heroTag(String id) => 'item-image-$id';

  static const double thumbnailSize = 72;

  /// The card image never gets smaller than this.
  static const double cardImageMinHeight = 120;

  /// Grid cell height for [ItemTileLayout.card] at the CURRENT text scale, so
  /// cells grow with the user's font size instead of overflowing.
  static double cardExtent(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle? style) => scaler.scale(style?.fontSize ?? 14) * (style?.height ?? 1.5);
    final textBlock =
        line(text.titleMedium) +
        AppSpacing.xs +
        line(text.bodySmall) * 2 +
        AppSpacing.sm +
        line(text.labelMedium) +
        AppSpacing.xs * 2;
    // Padding around the text + a little slack for borders and rounding.
    return cardImageMinHeight + textBlock + AppSpacing.md * 2 + AppSpacing.sm;
  }

  @override
  Widget build(BuildContext context) => switch (layout) {
    ItemTileLayout.row => _row(context),
    ItemTileLayout.card => _card(context),
  };

  Widget _row(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppNetworkImage(
          url: item.imageUrl,
          width: thumbnailSize,
          height: thumbnailSize,
          borderRadius: AppRadii.smAll,
          heroTag: heroTag(item.id),
        ),
        AppSpacing.gapMd,
        Expanded(child: _texts(context, titleLines: 2)),
      ],
    ),
  );

  Widget _card(BuildContext context) => AppCard(
    onTap: onTap,
    padding: EdgeInsetsDirectional.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Takes whatever the text leaves, at least cardImageMinHeight.
        Expanded(
          child: AppNetworkImage(url: item.imageUrl, heroTag: heroTag(item.id)),
        ),
        Padding(padding: const EdgeInsetsDirectional.all(AppSpacing.md), child: _texts(context, titleLines: 1)),
      ],
    ),
  );

  Widget _texts(BuildContext context, {required int titleLines}) {
    final text = context.textTheme;
    final muted = context.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.title, style: text.titleMedium, maxLines: titleLines, overflow: TextOverflow.ellipsis),
        if (item.description.isNotEmpty) ...[
          AppSpacing.gapXs,
          Text(
            item.description,
            style: text.bodySmall?.copyWith(color: muted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        AppSpacing.gapSm,
        Row(
          children: [
            Flexible(child: ItemStatusChip(status: item.status)),
            AppSpacing.gapSm,
            Flexible(
              child: Text(
                AppFormat.date(item.createdAt, locale: context.languageCode),
                style: text.labelSmall?.copyWith(color: muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
