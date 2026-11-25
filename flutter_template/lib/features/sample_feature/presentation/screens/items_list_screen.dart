// Items list: search, infinite scroll, pull to refresh, list on narrow widths
// and a grid when the width fits two or more 280 px tiles, FAB → create.
//
// Source: corsa-customer lib/core/utilities/widgets/shared/screens/paginated_list_view.dart
//         usage (PaginatedListView over a paginated cubit, inline load-more
//         errors) and lib/core/utilities/widgets/app_search_field.dart (search
//         on top of the list).
// Merged: chinaparts-customer CLAUDE.md (grids add columns from the available
//         width, never a cached device flag); corsa-customer
//         lib/core/utilities/widgets/base_fetching_widget.dart (a failed
//         refresh keeps the data on screen; the error is shown beside it).
// See docs/ARCHITECTURE.md#pagination.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/generated/locale_keys.g.dart';
import '../../../../core/pagination/paginated_cubit.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/inputs/app_search_field.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../../../shared/widgets/lists/paginated_list_view.dart';
import '../../../../shared/widgets/states/empty_view.dart';
import '../../domain/entities/item.dart';
import '../../items_routes.dart';
import '../managers/items_list_cubit.dart';
import '../widgets/item_tile.dart';

/// Expects an [ItemsListCubit] above it (created in `ItemsRoutes`).
class ItemsListScreen extends StatelessWidget {
  const ItemsListScreen({super.key});

  /// Narrowest grid tile; fewer than two fit → plain list.
  static const double minTileWidth = 280;

  /// Opens the create form; the created item is added on top of the list
  /// without a reload.
  static Future<void> openCreate(BuildContext context) async {
    final cubit = context.read<ItemsListCubit>();
    final created = await context.push<Item>(ItemsRoutes.create);
    if (created != null) cubit.upsertLocal(created);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ItemsListCubit>();
    final gutter = context.pageGutter;

    return BlocListener<ItemsListCubit, PaginatedState<Item>>(
      // A failed refresh keeps the items on screen: tell the user with a
      // snackbar (a failed FIRST load shows the full-screen error instead).
      listenWhen: (previous, current) =>
          current.failure != null && current.failure != previous.failure && current.items.isNotEmpty,
      listener: (context, state) => AppSnackBar.error(state.failure!, context: context),
      child: AppScaffold(
        title: LocaleKeys.items_title.tr(),
        showBackButton: false,
        // The list scrolls edge to edge; PaginatedListView pads the items.
        constrainWidth: false,
        padding: EdgeInsetsDirectional.zero,
        floatingActionButton: FloatingActionButton(
          tooltip: LocaleKeys.items_add.tr(),
          onPressed: () => openCreate(context),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(gutter, AppSpacing.sm, gutter, AppSpacing.xs),
              child: AppSearchField(
                hint: LocaleKeys.items_search_hint.tr(),
                // The cubit debounces (ItemsListCubit.searchDelay).
                debounce: Duration.zero,
                onChanged: cubit.search,
                onSubmitted: cubit.search,
              ),
            ),
            Expanded(
              child: BlocBuilder<ItemsListCubit, PaginatedState<Item>>(
                builder: (context, state) => LayoutBuilder(
                  builder: (context, constraints) {
                    final grid = columnsForWidth(constraints.maxWidth - gutter * 2, minTileWidth: minTileWidth) > 1;
                    return PaginatedListView<Item>(
                      state: state,
                      onLoadMore: cubit.loadNextPage,
                      onRefresh: cubit.refresh,
                      onRetry: cubit.loadFirstPage,
                      gridColumns: grid ? (width) => columnsForWidth(width, minTileWidth: minTileWidth) : null,
                      gridItemExtent: grid ? ItemTile.cardExtent(context) : null,
                      empty: _empty(context, cubit),
                      itemBuilder: (context, item, _) => ItemTile(
                        item: item,
                        layout: grid ? ItemTileLayout.card : ItemTileLayout.row,
                        onTap: () => context.push(ItemsRoutes.details(item.id)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, ItemsListCubit cubit) {
    if (cubit.query.isNotEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: LocaleKeys.items_no_results_title.tr(),
        message: LocaleKeys.items_no_results_message.tr(),
      );
    }
    return EmptyView(
      title: LocaleKeys.items_empty_title.tr(),
      message: LocaleKeys.items_empty_message.tr(),
      actionLabel: LocaleKeys.items_add.tr(),
      onAction: () => openCreate(context),
    );
  }
}
