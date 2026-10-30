import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/data/models/user_profile.dart';
import 'package:termux_command_library/shared/widgets/avatar_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every built-in avatar has a bundled SVG and a backdrop', () async {
    final assets = <String>{};
    for (final id in AppAvatars.all) {
      final asset = avatarAsset(id);
      expect(asset, endsWith('/$id.svg'));
      expect(assets.add(asset), isTrue, reason: 'duplicate asset for $id');

      final data = await rootBundle.loadString(asset);
      expect(data, contains('<svg'), reason: '$asset must be an SVG');
      expect(avatarBackground(id), isA<Color>());
    }
  });

  test('unknown ids fall back to the default illustration', () {
    expect(avatarAsset('not-an-avatar'), avatarAsset(AppAvatars.defaultId));
    expect(
      avatarBackground('not-an-avatar'),
      avatarBackground(AppAvatars.defaultId),
    );
  });

  testWidgets('renders the illustration for every avatar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final id in AppAvatars.all)
                AvatarBubble(key: ValueKey(id), avatarId: id, size: 92),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final id in AppAvatars.all) {
      final bubble = find.byKey(ValueKey(id));
      expect(bubble, findsOneWidget);
      expect(
        find.descendant(of: bubble, matching: find.byType(SvgPicture)),
        findsOneWidget,
      );
    }
  });

  testWidgets('the picker returns the tapped avatar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showAvatarPicker(
                  context,
                  selectedId: AppAvatars.defaultId,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AvatarBubble).at(1));
    await tester.pumpAndSettle();

    expect(selected, AppAvatars.all[1]);
  });
}
