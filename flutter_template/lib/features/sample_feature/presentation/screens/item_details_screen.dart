// Item details: image + info stacked on phones, two panes on tablets and
// unfolded foldables (split exactly at the hinge).
//
// Source: corsa-customer lib/core/utilities/widgets/base_fetching_widget.dart
//         usage (loading / error with retry / data kept while refreshing) via
//         the template's DataStateBuilder.
// Merged: baytna lib/core/utils/formatters.dart (dates via AppFormat, never
//         DateTime.toString()); new (approved decision C2: hinge-aware
//         AdaptiveTwoPane on tablets and foldables, one column on phones).
// See docs/WIDGETS.md#layout.
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../core/localization/generated/locale_keys.g.dart';
import '../../../../core/presentation/data_state.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/display_features.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../../../shared/widgets/layout/two_pane.dart';
import '../../../../shared/widgets/media/app_network_image.dart';
import '../../../../shared/widgets/states/data_state_builder.dart';
import '../../domain/entities/item.dart';
import '../managers/item_details_cubit.dart';
import '../widgets/item_status_chip.dart';
import '../widgets/item_tile.dart';

/// Expects an [ItemDetailsCubit] for [id] above it (created in `ItemsRoutes`).
class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key, required this.id});

  /// The item id from the route path.
  final String id;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ItemDetailsCubit>();
    return BlocConsumer<ItemDetailsCubit, DataState<Item>>(
      // Data on screen + a failed reload → snackbar, the data stays.
      listenWhen: (previous, current) => current.isFailure && current.hasData && previous.failure != current.failure,
      listener: (context, state) => AppSnackBar.error(state.failure!, context: context),
      builder: (context, state) => AppScaffold(
        title: state.data?.title ?? LocaleKeys.items_details_title.tr(),
        busy: state.isRefreshing,
        // The panes handle their own width and padding.
        constrainWidth: false,
        padding: EdgeInsetsDirectional.zero,
        body: DataStateBuilder<Item>(
          state: state,
          onRetry: cubit.load,
          builder: (context, item) => _ItemDetailsBody(item: item, onRefresh: cubit.load),
        ),
      ),
    );
  }
}

class _ItemDetailsBody extends StatelessWidget {
  const _ItemDetailsBody({required this.item, required this.onRefresh});

  final Item item;
  final Future<void> Function() onRefresh;

  /// Narrowest pane and the image pane's share of the width.
  static const double _minPaneWidth = 260;
  static const double _primaryFraction = 0.4;

  /// Stacked layout: the image takes at most this share of the height.
  static const double _maxStackedImageShare = 0.6;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final gutter = context.pageGutter;
      final padding = EdgeInsetsDirectional.all(gutter);
      final image = _ItemImage(item: item);
      final info = _ItemInfo(item: item);

      // AdaptiveTwoPane shows only `primary` when two panes don't fit, but
      // the details need the image AND the info: stack them in one scroll
      // view on phones (and folded foldables) or a narrow pane, using the
      // same width rule as AdaptiveTwoPane.
      final width = constraints.maxWidth;
      final fitsTwoPanes =
          !context.isPhone && width - math.max(width * _primaryFraction, _minPaneWidth) >= _minPaneWidth;
      if (!fitsTwoPanes && context.separatingHinge == null) {
        // In landscape the image would fill the screen: cap it so the info
        // starts on the first screen.
        final cappedImage = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight * _maxStackedImageShare),
            child: image,
          ),
        );
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(padding: padding, children: [cappedImage, AppSpacing.gapLg, info]),
        );
      }
      // Tablets / unfolded foldables: image pane at the start, info at the
      // end, split exactly at the hinge when there is one.
      return AdaptiveTwoPane(
        minPaneWidth: _minPaneWidth,
        primaryFraction: _primaryFraction,
        primary: SingleChildScrollView(padding: padding, child: image),
        secondary: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(padding: padding, children: [info]),
        ),
      );
    },
  );
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 4 / 3,
    child: AppNetworkImage(
      url: item.imageUrl,
      borderRadius: AppRadii.lgAll,
      heroTag: ItemTile.heroTag(item.id),
      semanticLabel: LocaleKeys.items_image_of.tr(namedArgs: {'title': item.title}),
    ),
  );
}

class _ItemInfo extends StatelessWidget {
  const _ItemInfo({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final muted = context.colorScheme.onSurfaceVariant;
    final description = item.description;

    Widget label(String value) => Text(value, style: text.labelLarge?.copyWith(color: muted));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(item.title, style: text.headlineSmall),
        AppSpacing.gapLg,
        label(LocaleKeys.items_field_status.tr()),
        AppSpacing.gapXs,
        ItemStatusChip(status: item.status),
        AppSpacing.gapLg,
        label(LocaleKeys.items_field_created.tr()),
        AppSpacing.gapXs,
        Text(AppFormat.dateTime(item.createdAt, locale: context.languageCode), style: text.bodyLarge),
        AppSpacing.gapLg,
        label(LocaleKeys.items_field_description.tr()),
        AppSpacing.gapXs,
        Text(
          description.isEmpty ? LocaleKeys.items_no_description.tr() : description,
          style: description.isEmpty ? text.bodyLarge?.copyWith(color: muted) : text.bodyLarge,
        ),
      ],
    );
  }
}
