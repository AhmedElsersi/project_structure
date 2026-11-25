// ImageViewerScreen (counter, close, double-tap zoom), AppNetworkImage
// fallback, showImageSourceSheet result, AppScaffold busy bar + bottom action.
//
// Source: new (tests for lib/shared/widgets/media/* and layout/app_scaffold.dart).
// Images use empty URLs so no network / cache plugin is touched.
import 'package:app_template/shared/widgets/layout/app_scaffold.dart';
import 'package:app_template/shared/widgets/media/app_network_image.dart';
import 'package:app_template/shared/widgets/media/image_source_sheet.dart';
import 'package:app_template/shared/widgets/media/image_viewer_screen.dart';
import 'package:flutter/gestures.dart' show kDoubleTapMinTime;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('AppNetworkImage without a URL shows the fallback', (tester) async {
    await pumpApp(tester, const Center(child: AppNetworkImage(url: null, width: 100, height: 80)));
    expect(find.byType(ImageFallback), findsOneWidget);
    expect(tester.getSize(find.byType(AppNetworkImage)), const Size(100, 80));
  });

  testWidgets('ImageViewerScreen: counter, double-tap zoom, close', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ImageViewerScreen(urls: ['', ''], initialIndex: 1))),
          child: const Text('open'),
        ),
      ),
      locale: const Locale('en'),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);

    final viewer = find.byType(InteractiveViewer).hitTestable();
    await tester.tap(viewer);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(viewer);
    await tester.pumpAndSettle();
    final scale = tester.widget<InteractiveViewer>(viewer).transformationController!.value.getMaxScaleOnAxis();
    expect(scale, greaterThan(2));

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewerScreen), findsNothing);
  });

  testWidgets('showImageSourceSheet returns the tapped source', (tester) async {
    ImageSource? source;
    await pumpApp(
      tester,
      Builder(
        builder: (context) =>
            TextButton(onPressed: () async => source = await showImageSourceSheet(context), child: const Text('open')),
      ),
      locale: const Locale('en'),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Add a photo'), findsOneWidget);

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(source, ImageSource.camera);
  });

  testWidgets('AppScaffold: busy bar under the app bar, bottom action pinned', (tester) async {
    await pumpApp(
      tester,
      AppScaffold(
        title: 'Edit',
        busy: true,
        bottomAction: FilledButton(onPressed: () {}, child: const Text('Save')),
        body: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('body')]),
      ),
      wrapInScaffold: false,
      settle: false,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.getBottomLeft(find.byType(FilledButton)).dy, greaterThan(852 - 80));
    // Body starts at the page gutter on the start (right) side in Arabic.
    expect(tester.getTopRight(find.text('body')).dx, 393 - 16);
  });
}
