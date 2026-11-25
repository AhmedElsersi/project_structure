// Form factor from the window's SHORTEST SIDE + responsive context helpers.
//
// Your convention (approved): phone < 600, tablet 600–839, large tablet ≥ 840,
// measured on `MediaQuery.sizeOf(context).shortestSide` — the *window* size, so
// Split View, multi-window and foldables (folded = phone, unfolded = tablet)
// are classified correctly and re-evaluated on every change. Never cache it.
//
// Source: chinaparts-customer lib/core/utilities/responsive/responsive.dart
//         (single helper, context.responsive<T>() cascade, never cached).
// Merged: corsa-customer lib/core/extensions/context_extensions.dart (Material 3
//         600/840 classes, portrait lock decided by shortestSide); lexa
//         breakpoints.dart (gutter + max content width per class).
// See docs/CONVENTIONS.md#responsive.
import 'package:flutter/widgets.dart';

enum FormFactor {
  phone,
  tablet,
  largeTablet;

  static FormFactor fromShortestSide(double shortestSide) {
    if (shortestSide >= Breakpoints.largeTablet) return FormFactor.largeTablet;
    if (shortestSide >= Breakpoints.tablet) return FormFactor.tablet;
    return FormFactor.phone;
  }

  static FormFactor of(Size size) => fromShortestSide(size.shortestSide);

  bool get isPhone => this == FormFactor.phone;
  bool get isTabletOrLarger => this != FormFactor.phone;
}

/// The only breakpoint numbers in the app.
abstract final class Breakpoints {
  static const double tablet = 600;
  static const double largeTablet = 840;
}

extension ResponsiveContext on BuildContext {
  /// Rebuilds only when the window size changes.
  Size get windowSize => MediaQuery.sizeOf(this);

  FormFactor get formFactor => FormFactor.of(windowSize);
  bool get isPhone => formFactor == FormFactor.phone;
  bool get isTablet => formFactor == FormFactor.tablet;
  bool get isLargeTablet => formFactor == FormFactor.largeTablet;
  bool get isTabletOrLarger => formFactor.isTabletOrLarger;
  bool get isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Picks a value per form factor; missing values fall back to the next
  /// smaller one (largeTablet → tablet → phone).
  T responsive<T>({required T phone, T? tablet, T? largeTablet}) => switch (formFactor) {
    FormFactor.phone => phone,
    FormFactor.tablet => tablet ?? phone,
    FormFactor.largeTablet => largeTablet ?? tablet ?? phone,
  };

  /// Horizontal page padding.
  double get pageGutter => responsive<double>(phone: 16, tablet: 24, largeTablet: 32);

  /// Max width of single-column content (forms, details, lists).
  double get maxContentWidth => responsive<double>(phone: double.infinity, tablet: 720, largeTablet: 840);
}

/// Grid column count from the AVAILABLE width (use inside LayoutBuilder), so a
/// grid adapts to panes, rails and split screens, not just the device.
int columnsForWidth(double width, {double minTileWidth = 160, int maxColumns = 6}) {
  if (width.isInfinite || width <= 0) return 1;
  return (width / minTileWidth).floor().clamp(1, maxColumns);
}
