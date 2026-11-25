// Foldable support: find the hinge/fold so two-pane layouts never put content
// under it.
//
// Source: new (approved decision: responsive on foldables). Built on Flutter's
//         `MediaQuery.displayFeaturesOf` (Android Jetpack WindowManager data).
//         Dialogs and bottom sheets already avoid the hinge automatically via
//         DisplayFeatureSubScreen; this helper is for your own layouts.
// See docs/CONVENTIONS.md#foldables.
import 'dart:ui' show DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// A separating fold/hinge in local coordinates.
class Hinge {
  const Hinge(this.bounds, {required this.isVertical, required this.isOccluding});

  /// Area of the hinge (zero-width for a fold).
  final Rect bounds;

  /// True when the hinge splits the window into left/right panes.
  final bool isVertical;

  /// True for a physical hinge that hides pixels (e.g. dual-screen devices).
  final bool isOccluding;
}

extension FoldableContext on BuildContext {
  /// The hinge that currently separates the window, or null (phones, tablets,
  /// a foldable held flat-closed, or a fold that is fully open and flat).
  Hinge? get separatingHinge {
    for (final feature in MediaQuery.displayFeaturesOf(this)) {
      final isHinge = feature.type == DisplayFeatureType.hinge;
      final isHalfOpenedFold =
          feature.type == DisplayFeatureType.fold && feature.state == DisplayFeatureState.postureHalfOpened;
      if (!isHinge && !isHalfOpenedFold) continue;
      final b = feature.bounds;
      return Hinge(b, isVertical: b.height >= b.width, isOccluding: isHinge && b.width > 0 && b.height > 0);
    }
    return null;
  }

  /// Tabletop posture: horizontal half-opened fold (show content top, controls bottom).
  bool get isTabletop {
    final hinge = separatingHinge;
    return hinge != null && !hinge.isVertical;
  }
}
