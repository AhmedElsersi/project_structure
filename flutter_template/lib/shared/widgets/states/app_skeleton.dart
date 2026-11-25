// Skeleton loading placeholders (skeletonizer) in theme colours.
//
// Source: corsa-customer lib/core/utilities/widgets/skeletons/app_skeletons.dart
//         (AppSkeleton wrapper over Skeletonizer; skeletons with the real
//         card's size so nothing jumps; SkeletonList for first loads).
// Merged: chinaparts-seller idea of skeletonizing the REAL item widget over a
//         mock model (pass `itemBuilder`); reduced motion → no shimmer (new).
// See docs/WIDGETS.md#states.
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_spacing.dart';

/// Turns [child] into a shimmering skeleton while [enabled] (text becomes
/// bars, images and icons become boxes). Taps are ignored while enabled.
///
/// Best used over the real widget built with placeholder data, so the
/// skeleton has exactly the loaded layout.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final PaintingEffect effect = MediaQuery.disableAnimationsOf(context)
        ? SolidColorEffect(color: scheme.surfaceContainerHighest)
        : ShimmerEffect(baseColor: scheme.surfaceContainerHighest, highlightColor: scheme.surfaceContainerLow);
    return Skeletonizer(enabled: enabled, effect: effect, child: child);
  }
}

/// A non-scrolling list of skeleton rows for a first load.
///
/// Pass [itemBuilder] to skeletonize your real item widget (with mock data);
/// otherwise a generic avatar + two-line row is used.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 6, this.itemBuilder, this.padding});

  final int itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: ListView.separated(
      padding: padding ?? const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => AppSpacing.gapSm,
      itemBuilder: itemBuilder ?? (_, _) => const _SkeletonRow(),
    ),
  );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Row(
        children: [
          const Bone.circle(size: AppSizes.minTouch),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 3, style: Theme.of(context).textTheme.titleMedium),
                AppSpacing.gapXs,
                Bone.text(words: 5, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
