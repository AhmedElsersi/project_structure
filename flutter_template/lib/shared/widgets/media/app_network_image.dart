// Every remote image goes through here: cached, decoded at display size, with
// a skeleton placeholder and a quiet broken-image fallback.
//
// Source: corsa-customer lib/core/utilities/widgets/shared/widgets/app_image.dart
//         (cached_network_image, memCacheWidth = logical width × device pixel
//         ratio from LayoutBuilder, skeleton placeholder, fallback, radius,
//         hero tag, semantics).
// Merged: baytna lib/core/widgets/remote_image.dart (a missing / broken URL is a
//         normal state: neutral surface + broken-image icon, never an error);
//         tebbr image viewer `fullResolution` (skip the decode cap when the
//         image can be zoomed).
// See docs/WIDGETS.md#media.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/theme/app_motion.dart';
import '../states/app_skeleton.dart';

/// A cached network image.
///
/// It is decoded at `width × devicePixelRatio` (from [width] or the layout
/// constraints) to keep memory low; set [fullResolution] for zoomable
/// viewers. A null / empty [url] or a load error shows [fallback] (default:
/// a broken-image icon on a neutral surface).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.semanticLabel,
    this.onTap,
    this.placeholder,
    this.fallback,
    this.fullResolution = false,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;

  /// Wraps the image in a [Hero] (e.g. list → image viewer).
  final Object? heroTag;

  /// Already-translated description; null = decorative.
  final String? semanticLabel;
  final VoidCallback? onTap;

  /// Shown while loading; defaults to a skeleton box.
  final Widget? placeholder;

  /// Shown when [url] is missing or fails to load.
  final Widget? fallback;

  /// Decode at the source resolution (zoomable viewers).
  final bool fullResolution;

  @override
  Widget build(BuildContext context) {
    final src = url?.trim();
    Widget child = LayoutBuilder(
      builder: (context, constraints) {
        if (src == null || src.isEmpty) return fallback ?? const ImageFallback();
        final logicalWidth = width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : null);
        final cacheWidth = logicalWidth == null || fullResolution
            ? null
            : (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();
        return CachedNetworkImage(
          imageUrl: src,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: cacheWidth != null && cacheWidth > 0 ? cacheWidth : null,
          fadeInDuration: AppMotion.of(context, AppMotion.medium),
          placeholder: (_, _) => placeholder ?? const _ImagePlaceholder(),
          errorWidget: (_, _, _) => fallback ?? const ImageFallback(),
        );
      },
    );

    child = SizedBox(width: width, height: height, child: child);
    final radius = borderRadius;
    if (radius != null) child = ClipRRect(borderRadius: radius, child: child);
    final tag = heroTag;
    if (tag != null) child = Hero(tag: tag, child: child);
    child = Semantics(
      image: semanticLabel != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: child,
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

/// The neutral "image unavailable" box used by [AppNetworkImage].
class ImageFallback extends StatelessWidget {
  const ImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: scheme.onSurfaceVariant,
          semanticLabel: LocaleKeys.widgets_image_unavailable.tr(),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  // A size-less bone fills tight constraints and collapses in loose ones.
  Widget build(BuildContext context) => const AppSkeleton(child: Bone());
}
