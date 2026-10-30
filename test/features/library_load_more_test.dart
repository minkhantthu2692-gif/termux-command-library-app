import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/bootstrap.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/app/providers.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/app/theme/app_theme.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/models/auth_models.dart';
import 'package:termux_command_library/data/models/command_post.dart';
import 'package:termux_command_library/data/models/user_profile.dart';
import 'package:termux_command_library/data/remote/firebase_bootstrap.dart';
import 'package:termux_command_library/features/command_library/library_screen.dart';

import '../support/test_helpers.dart';

void main() {
  testWidgets('load more keeps the current scroll position', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());

    // Drift schedules zero-duration timers when its streams are cancelled.
    // Unmount and drain them inside the test body so the binding's timer check
    // does not see them as leaks.
    Future<void> disposeApp() async {
      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(db.close);
    }

    try {
      for (var i = 0; i < 25; i++) {
        await db.commandDao.saveLocalPost(
          buildCommand(
            id: 'command-$i',
            name: 'Command $i',
            updatedAt: DateTime.utc(2026, 10, 1).add(Duration(minutes: i)),
          ),
          pendingSync: false,
        );
      }

      final settings = AppSettings.defaults('test-guest');
      final dependencies = AppDependencies(
        database: db,
        initialSettings: settings,
        firebase: FirebaseRuntime.disabled,
        authGateway: null,
        cloudStore: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDependenciesProvider.overrideWithValue(dependencies),
            currentSessionProvider.overrideWithValue(
              const AuthSession(
                uid: 'test-guest',
                isAnonymous: true,
                isAdmin: false,
                isLocalOnly: true,
              ),
            ),
            preferencesProvider.overrideWith(
              (ref) => Stream.value(const UserPreferences()),
            ),
            pinnedCommandsProvider.overrideWith(
              (ref) => Stream.value(const <CommandSummary>[]),
            ),
            syncStatusProvider.overrideWith(
              (ref) => Stream.value(SyncStatus.localOnly),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.build(settings, Brightness.light),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: LibraryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Load more'),
        300,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Load more'), findsOneWidget);

      final position = tester.state<ScrollableState>(scrollable).position;
      final offsetBefore = position.pixels;
      expect(offsetBefore, greaterThan(0));

      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();

      // The viewport must stay where the button was; the new rows are
      // appended below it instead of replacing the list and resetting to the
      // top.
      expect(position.pixels, closeTo(offsetBefore, 1));

      await tester.scrollUntilVisible(
        find.text('You have reached the end.'),
        300,
        scrollable: scrollable,
      );
      expect(find.text('You have reached the end.'), findsOneWidget);
    } finally {
      await disposeApp();
    }
  });
}
