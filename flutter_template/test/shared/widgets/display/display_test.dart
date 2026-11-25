// StatusChip palette colours, AppAvatar initials, NavTile / SectionHeader RTL
// start alignment and mirrored chevron.
//
// Source: new (tests for lib/shared/widgets/display/* and lists/nav_tile.dart).
import 'package:app_template/core/theme/app_palette.dart';
import 'package:app_template/shared/widgets/display/app_avatar.dart';
import 'package:app_template/shared/widgets/display/status_chip.dart';
import 'package:app_template/shared/widgets/layout/section_header.dart';
import 'package:app_template/shared/widgets/lists/nav_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('StatusChip paints the palette tone pair', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: StatusChip(label: 'Paid', tone: StatusTone.success),
      ),
    );
    final palette = tester.element(find.byType(StatusChip)).palette;

    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(StatusChip), matching: find.byType(DecoratedBox)).first,
    );
    expect((box.decoration as BoxDecoration).color, palette.success.container);
    expect(tester.widget<Text>(find.text('Paid')).style?.color, palette.success.onContainer);
  });

  testWidgets('StatusChip follows the dark palette', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: StatusChip(label: 'Late', tone: StatusTone.danger, icon: Icons.schedule),
      ),
      themeMode: ThemeMode.dark,
    );
    final palette = tester.element(find.byType(StatusChip)).palette;
    expect(Theme.of(tester.element(find.byType(StatusChip))).brightness, Brightness.dark);
    expect(tester.widget<Icon>(find.byIcon(Icons.schedule)).color, palette.danger.onContainer);
  });

  group('AppAvatar.initialsOf', () {
    test('two words, any script, honorifics skipped', () {
      expect(AppAvatar.initialsOf('Sara Ali Hassan'), 'SA');
      expect(AppAvatar.initialsOf('  mona  '), 'M');
      expect(AppAvatar.initialsOf('أحمد صالح'), 'أص');
      expect(AppAvatar.initialsOf('أ. أحمد صالح'), 'أص');
      expect(AppAvatar.initialsOf('Dr. John Smith'), 'JS');
      expect(AppAvatar.initialsOf(null), '?');
      expect(AppAvatar.initialsOf('   '), '?');
    });

    test('grapheme-safe (emoji and combining marks stay whole)', () {
      expect(AppAvatar.initialsOf('👩‍💻 Dev'), '👩‍💻D');
    });
  });

  testWidgets('AppAvatar without a photo shows initials', (tester) async {
    await pumpApp(tester, const Center(child: AppAvatar(name: 'Omar Khaled', size: 56)));
    expect(find.text('OK'), findsOneWidget);
    expect(tester.getSize(find.byType(AppAvatar)), const Size(56, 56));
  });

  testWidgets('RTL (Arabic): NavTile and SectionHeader start on the right', (tester) async {
    await pumpApp(
      tester,
      Column(
        children: [
          SectionHeader(title: 'الحساب', actionLabel: 'الكل', onAction: () {}),
          NavTile(title: 'الملف الشخصي', icon: Icons.person_outline, onTap: () {}),
        ],
      ),
    );
    expect(Directionality.of(tester.element(find.byType(NavTile))), TextDirection.rtl);

    // Leading icon on the right edge, chevron on the left.
    final icon = tester.getCenter(find.byIcon(Icons.person_outline));
    final chevron = tester.getCenter(find.byIcon(Icons.chevron_right));
    expect(icon.dx, greaterThan(chevron.dx));
    expect(icon.dx, greaterThan(393 / 2));

    // Text starts at the right: the title's right edge sits near the end of the row.
    final title = tester.getRect(find.text('الحساب'));
    final action = tester.getRect(find.text('الكل'));
    expect(title.left, greaterThan(action.right));

    // Material mirrors chevron_right in RTL (matchTextDirection).
    expect(Icons.chevron_right.matchTextDirection, isTrue);
  });
}
