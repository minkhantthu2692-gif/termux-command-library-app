import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/app/providers.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/app/theme/app_theme.dart';
import 'package:termux_command_library/data/services/clipboard_service.dart';
import 'package:termux_command_library/data/services/haptics_service.dart';
import 'package:termux_command_library/features/termux/termux_guide_screen.dart';

import 'support/fake_termux_service.dart';

class _FakeSettingsController extends SettingsController {
  @override
  AppSettings build() => AppSettings.defaults('test-guest');

  @override
  Future<void> save(AppSettings next) async {
    state = next;
  }
}

class _NoopHaptics extends HapticsService {
  @override
  Future<void> trigger(
    VibrationIntensity intensity, {
    HapticCue cue = HapticCue.tap,
  }) async {}
}

class _RecordingClipboard extends ClipboardService {
  final List<String> copied = <String>[];

  @override
  Future<void> copy(String text) async => copied.add(text);
}

void main() {
  Future<void> pumpGuide(
    WidgetTester tester,
    FakeTermuxService service, {
    ClipboardService? clipboard,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        termuxServiceProvider.overrideWithValue(service),
        settingsControllerProvider.overrideWith(_FakeSettingsController.new),
        hapticsServiceProvider.overrideWithValue(_NoopHaptics()),
        if (clipboard != null)
          clipboardServiceProvider.overrideWithValue(clipboard),
      ],
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

  testWidgets('copies setup commands and omits the old footer notes', (
    tester,
  ) async {
    const externalAppsCommand =
        'mkdir -p ~/.termux\n'
        'echo "allow-external-apps=true" >> ~/.termux/termux.properties\n'
        'termux-reload-settings';
    final clipboard = _RecordingClipboard();
    await pumpGuide(tester, FakeTermuxService(), clipboard: clipboard);

    // Both command boxes are selectable and expose a copy button.
    expect(find.byTooltip('Copy command'), findsNWidgets(2));
    expect(find.byType(SelectableText), findsNWidgets(2));

    final copy = find.byTooltip('Copy command').first;
    await tester.ensureVisible(copy);
    await tester.pumpAndSettle();
    await tester.tap(copy);
    await tester.pumpAndSettle();

    expect(clipboard.copied, [externalAppsCommand]);
    expect(find.text('Copied to clipboard'), findsOneWidget);

    // The old bottom card and secure-storage footer are gone.
    expect(find.text('No command was sent.'), findsNothing);
    expect(find.textContaining('API keys are never synced'), findsNothing);
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
