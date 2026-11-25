// Full-screen image gallery: swipe between images, pinch and double-tap zoom,
// page counter and a close button.
//
// Source: tebbr lib/core/utilities/widgets/shared/screens/image_viewer.dart
//         (PageView of InteractiveViewers, one TransformationController per
//         page, double-tap zooms toward the tapped point / resets, paging
//         locked while zoomed, chrome hidden while zoomed, hero on the first
//         image, full-resolution decode).
// Merged: baytna lib/core/widgets/image_gallery_viewer.dart (dark backdrop, page
//         counter, round close button) — colours taken from the app's dark
//         theme instead of literal black/white; counter text localized (new).
// See docs/WIDGETS.md#media.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import 'app_network_image.dart';

/// Full-screen viewer for one or more image URLs.
///
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute<void>(
///   fullscreenDialog: true,
///   builder: (_) => ImageViewerScreen(urls: product.images, initialIndex: i, heroTag: 'img-$i'),
/// ));
/// ```
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.urls, this.initialIndex = 0, this.heroTag});

  final List<String> urls;
  final int initialIndex;

  /// Hero tag of the image at [initialIndex] (match the thumbnail's tag).
  final Object? heroTag;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> with SingleTickerProviderStateMixin {
  static const double _maxScale = 6;
  static const double _doubleTapScale = 2.5;

  late final PageController _pages;
  late int _index;
  final Map<int, TransformationController> _transforms = {};
  late final AnimationController _zoomAnimation;
  Animation<Matrix4>? _zoomTween;
  Offset? _doubleTapPosition;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    assert(widget.urls.isNotEmpty, 'ImageViewerScreen needs at least one URL');
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pages = PageController(initialPage: _index);
    _zoomAnimation = AnimationController(vsync: this, duration: AppMotion.medium)
      ..addListener(() {
        final tween = _zoomTween;
        if (tween != null) _transformFor(_index).value = tween.value;
      });
  }

  @override
  void dispose() {
    _pages.dispose();
    _zoomAnimation.dispose();
    for (final controller in _transforms.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _transformFor(int index) => _transforms.putIfAbsent(index, () {
    final controller = TransformationController();
    controller.addListener(() {
      if (index != _index) return;
      final zoomed = controller.value.getMaxScaleOnAxis() > 1.05;
      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
    });
    return controller;
  });

  void _onDoubleTap() {
    final controller = _transformFor(_index);
    final Matrix4 target;
    if (controller.value.getMaxScaleOnAxis() > 1.05) {
      target = Matrix4.identity();
    } else {
      final point = _doubleTapPosition ?? Offset.zero;
      const s = _doubleTapScale;
      // Scale around the tapped point.
      target = Matrix4.diagonal3Values(s, s, 1)..setTranslationRaw(-point.dx * (s - 1), -point.dy * (s - 1), 0);
    }
    _zoomTween = Matrix4Tween(
      begin: controller.value,
      end: target,
    ).animate(CurvedAnimation(parent: _zoomAnimation, curve: AppMotion.standard));
    _zoomAnimation.duration = AppMotion.of(context, AppMotion.medium);
    _zoomAnimation.forward(from: 0);
  }

  void _onPageChanged(int index) {
    _transformFor(_index).value = Matrix4.identity();
    setState(() {
      _index = index;
      _zoomed = false;
    });
  }

  Widget _page(int index) {
    final image = AppNetworkImage(url: widget.urls[index], fit: BoxFit.contain, fullResolution: true);
    final tag = widget.heroTag;
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformFor(index),
        maxScale: _maxScale,
        child: Center(
          child: tag != null && index == widget.initialIndex ? Hero(tag: tag, child: image) : image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A dark surface whatever the app theme (photos read best on dark).
    final theme = AppTheme.adaptTo(AppTheme.dark(), context.formFactor);
    final scheme = theme.colorScheme;
    final chromeDuration = AppMotion.of(context, AppMotion.fast);
    final multiple = widget.urls.length > 1;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: widget.urls.length,
              physics: _zoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _page(index),
            ),
            SafeArea(
              child: AnimatedOpacity(
                opacity: _zoomed ? 0 : 1,
                duration: chromeDuration,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      if (multiple)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            child: Text(
                              LocaleKeys.widgets_image_counter.tr(
                                namedArgs: {'current': '${_index + 1}', 'total': '${widget.urls.length}'},
                              ),
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),
                      const Spacer(),
                      IconButton.filledTonal(
                        tooltip: LocaleKeys.common_close.tr(),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
