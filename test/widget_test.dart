import 'package:drift/native.dart';
import 'package:dynamic_color_testing/dynamic_color_testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/app.dart';
import 'package:termux_command_library/app/bootstrap.dart';
import 'package:termux_command_library/app/providers.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/remote/firebase_bootstrap.dart';
import 'package:termux_command_library/data/repositories/settings_repository.dart';
import 'package:termux_command_library/shared/widgets/glass_surface.dart';

import 'support/test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    DynamicColorTestingUtils.setMockDynamicColors();
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<AppDependencies> buildDependencies({
    required bool onboardingCompleted,
  }) async {
    final repository = SettingsRepository(db.settingsDao);
    final base = await repository.initialize();
    await repository.save(
      base.copyWith(onboardingCompleted: onboardingCompleted),
    );
    return AppDependencies(
      database: db,
      initialSettings: await repository.read(),
      firebase: FirebaseRuntime.disabled,
      authGateway: null,
      cloudStore: null,
    );
  }

  Widget buildApp(AppDependencies dependencies, FakeApiKeyStore keyStore) {
    return ProviderScope(
      overrides: [
        appDependenciesProvider.overrideWithValue(dependencies),
        apiKeyStoreProvider.overrideWithValue(keyStore),
      ],
      child: const TermuxCommandLibraryApp(),
    );
  }

  Future<void> disposeApp(WidgetTester tester) async {
    // Unmount the ProviderScope while the fake async zone is still active so
    // Drift's stream-cleanup timers run before the database is closed.
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Closing inside runAsync avoids awaiting drift's cleanup timers from the
    // fake async zone, which would deadlock the test.
    await tester.runAsync(db.close);
  }

  testWidgets('new installs start at welcome and can continue as a guest', (
    tester,
  ) async {
    final dependencies = await buildDependencies(onboardingCompleted: false);
    await tester.pumpWidget(buildApp(dependencies, FakeApiKeyStore()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to your command library'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('Quick actions'), findsNothing);

    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Search commands, tags or tools'), findsOneWidget);

    final persisted = await SettingsRepository(db.settingsDao).read();
    expect(persisted.onboardingCompleted, isTrue);

    await disposeApp(tester);
  });

  testWidgets('completed onboarding opens the four-tab shell', (tester) async {
    final dependencies = await buildDependencies(onboardingCompleted: true);
    await tester.pumpWidget(buildApp(dependencies, FakeApiKeyStore()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Community library'), findsOneWidget);
    expect(find.text('Search commands, tags or tools'), findsWidgets);

    await tester.tap(find.text('Assistant'));
    await tester.pumpAndSettle();
    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('quick actions pair up on phones and stack at large text', (
    tester,
  ) async {
    final dependencies = await buildDependencies(onboardingCompleted: true);
    await tester.pumpWidget(buildApp(dependencies, FakeApiKeyStore()));
    await tester.pumpAndSettle();

    expect(find.text('Explore commands'), findsOneWidget);
    expect(find.text('Contribute knowledge'), findsOneWidget);
    expect(find.text('Get help with AI'), findsOneWidget);
    expect(find.text('Set up your environment'), findsOneWidget);

    final browse = find.byKey(const ValueKey('quick-action-browse'));
    final share = find.byKey(const ValueKey('quick-action-share'));

    // Two half-width cards share a row at the default text size.
    expect(tester.getTopLeft(browse).dy, tester.getTopLeft(share).dy);
    expect(tester.getSize(browse).width, lessThan(400));

    // Larger text falls back to full-width rows so the label block keeps
    // enough room, especially for Myanmar.
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    expect(tester.getSize(browse).width, greaterThan(500));
    expect(
      tester.getTopLeft(share).dy,
      greaterThan(tester.getTopLeft(browse).dy),
    );

    await disposeApp(tester);
  });

  testWidgets('the navigation bar follows the blur setting', (tester) async {
    final dependencies = await buildDependencies(onboardingCompleted: true);
    await tester.pumpWidget(buildApp(dependencies, FakeApiKeyStore()));
    await tester.pumpAndSettle();

    // The bar is a GlassSurface laid over the scrolling body, not a plain
    // tinted DecoratedBox, so blur is visible when enabled.
    expect(
      find.ancestor(
        of: find.byType(NavigationBar),
        matching: find.byType(GlassSurface),
      ),
      findsOneWidget,
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.extendBody, isTrue);
    expect(find.byType(BackdropFilter), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TermuxCommandLibraryApp)),
    );
    final settings = container.read(settingsControllerProvider);
    await container
        .read(settingsControllerProvider.notifier)
        .save(settings.copyWith(blurEnabled: false));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);

    await container
        .read(settingsControllerProvider.notifier)
        .save(settings.copyWith(blurEnabled: true, blurIntensity: 24));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('back returns through the tab history instead of closing', (
    tester,
  ) async {
    final dependencies = await buildDependencies(onboardingCompleted: true);
    await tester.pumpWidget(buildApp(dependencies, FakeApiKeyStore()));
    await tester.pumpAndSettle();

    // Home -> Library -> back.
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Community library'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Quick actions'), findsOneWidget);

    // Home -> Library -> Assistant, then back twice.
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assistant'));
    await tester.pumpAndSettle();
    expect(find.text('AI Assistant'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Community library'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Quick actions'), findsOneWidget);

    // A Quick Action destination is also part of the back history. Target the
    // tile by key so the identically labelled empty-state action further down
    // the page is not selected by mistake.
    final quickBrowse = find.byKey(const ValueKey('quick-action-browse'));
    expect(quickBrowse, findsOneWidget);
    await tester.tap(quickBrowse);
    await tester.pumpAndSettle();
    expect(find.text('Community library'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Quick actions'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('theme and locale settings propagate to the running app', (
    tester,
  ) async {
    final dependencies = await buildDependencies(onboardingCompleted: true);
    final keyStore = FakeApiKeyStore();
    await tester.pumpWidget(buildApp(dependencies, keyStore));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TermuxCommandLibraryApp)),
    );
    final settings = container.read(settingsControllerProvider);
    await container
        .read(settingsControllerProvider.notifier)
        .save(settings.copyWith(themeMode: ThemeMode.dark, languageCode: 'my'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Localizations.localeOf(context).languageCode, 'my');
    expect(find.text('အမြန်လုပ်ဆောင်ချက်များ'), findsOneWidget);
    expect(find.text('Quick actions'), findsNothing);

    await disposeApp(tester);
  });
}
