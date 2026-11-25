// Tests for lib/core/responsive/display_features.dart. Source: new
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app_template/core/responsive/display_features.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _contextWith(WidgetTester tester, List<DisplayFeature> features) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: const Size(840, 900), displayFeatures: features),
      child: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

DisplayFeature _fold(Rect bounds, DisplayFeatureState state) =>
    DisplayFeature(bounds: bounds, type: DisplayFeatureType.fold, state: state);

const _verticalFoldLine = Rect.fromLTWH(420, 0, 0, 900);
const _horizontalFoldLine = Rect.fromLTWH(0, 450, 840, 0);

void main() {
  testWidgets('no display features → no hinge, not tabletop', (tester) async {
    final c = await _contextWith(tester, const []);
    expect(c.separatingHinge, isNull);
    expect(c.isTabletop, isFalse);
  });

  testWidgets('half-opened vertical fold → vertical, non-occluding hinge (book posture)', (tester) async {
    final c = await _contextWith(tester, [_fold(_verticalFoldLine, DisplayFeatureState.postureHalfOpened)]);
    final hinge = c.separatingHinge;
    expect(hinge, isNotNull);
    expect(hinge!.isVertical, isTrue);
    expect(hinge.isOccluding, isFalse);
    expect(hinge.bounds, _verticalFoldLine);
    expect(c.isTabletop, isFalse);
  });

  testWidgets('half-opened horizontal fold → tabletop', (tester) async {
    final c = await _contextWith(tester, [_fold(_horizontalFoldLine, DisplayFeatureState.postureHalfOpened)]);
    expect(c.separatingHinge!.isVertical, isFalse);
    expect(c.isTabletop, isTrue);
  });

  testWidgets('a fold that is flat (fully open) does not separate the window', (tester) async {
    final c = await _contextWith(tester, [
      _fold(_verticalFoldLine, DisplayFeatureState.postureFlat),
      _fold(_horizontalFoldLine, DisplayFeatureState.unknown),
    ]);
    expect(c.separatingHinge, isNull);
    expect(c.isTabletop, isFalse);
  });

  testWidgets('a physical hinge always separates and occludes pixels', (tester) async {
    const bounds = Rect.fromLTWH(403, 0, 34, 900);
    final c = await _contextWith(tester, [
      const DisplayFeature(bounds: bounds, type: DisplayFeatureType.hinge, state: DisplayFeatureState.unknown),
    ]);
    final hinge = c.separatingHinge!;
    expect(hinge.isVertical, isTrue);
    expect(hinge.isOccluding, isTrue);
    expect(hinge.bounds, bounds);
  });

  testWidgets('camera cutouts are ignored; the first separating feature wins', (tester) async {
    final c = await _contextWith(tester, [
      const DisplayFeature(
        bounds: Rect.fromLTWH(10, 0, 40, 40),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
      _fold(_horizontalFoldLine, DisplayFeatureState.postureHalfOpened),
      _fold(_verticalFoldLine, DisplayFeatureState.postureHalfOpened),
    ]);
    expect(c.isTabletop, isTrue);
  });
}
