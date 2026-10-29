import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/app/providers.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/app/theme/app_theme.dart';
import 'package:termux_command_library/features/termux/termux_guide_screen.dart';

import 'support/fake_termux_service.dart';

void main() {
  Future<void> pumpGuide(WidgetTester tester, FakeTermuxService service) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [termuxServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(
            AppSettings.defaults('test-guest'),
            Brightness.light,
          ),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TermuxGuideScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows both parts of the Termux:API setup', (tester) async {
    await pumpGuide(tester, FakeTermuxService());

    expect(
      find.text('Install Termux:API for built-in commands (optional).'),
      findsOneWidget,
    );
    expect(find.text('pkg install termux-api'), findsOneWidget);
    expect(find.text('Open Termux:API settings'), findsOneWidget);
    expect(
      find.textContaining('Status reflects installed apps and Android'),
      findsOneWidget,
    );
  });

  testWidgets('shows the display-over-apps step and grants it', (tester) async {
    final service = FakeTermuxService(overlay: false);
    await pumpGuide(tester, service);

    expect(
      find.text('Allow Termux to open sessions from the background.'),
      findsOneWidget,
    );
    expect(find.text('Open Termux display settings'), findsOneWidget);

    final button = find.text('Open Termux display settings');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();

    expect(service.overlaySettingsOpened, 1);
  });

  testWidgets('shows the display permission as granted', (tester) async {
    await pumpGuide(tester, FakeTermuxService());

    expect(
      find.widgetWithText(FilledButton, 'Permission granted'),
      findsNWidgets(2),
    );
  });

  testWidgets('opens the Termux:API app info page when installed', (
    tester,
  ) async {
    final service = FakeTermuxService();
    await pumpGuide(tester, service);

    final button = find.text('Open Termux:API settings');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();

    expect(service.apiSettingsOpened, 1);
  });

  testWidgets('disables the API settings action when the APK is missing', (
    tester,
  ) async {
    await pumpGuide(tester, FakeTermuxService(apiInstalled: false));

    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Open Termux:API settings'),
    );
    expect(button.onPressed, isNull);
  });
}
