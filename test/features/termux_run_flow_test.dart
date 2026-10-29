import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/app/providers.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/app/theme/app_theme.dart';
import 'package:termux_command_library/data/services/haptics_service.dart';
import 'package:termux_command_library/features/termux/termux_run_flow.dart';

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

class _RunHost extends ConsumerWidget {
  const _RunHost({required this.command});

  final String command;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showTermuxRunFlow(
            context,
            ref,
            label: 'Test',
            items: [TermuxRunItem(title: 'Test step', command: command)],
          ),
          child: const Text('Run'),
        ),
      ),
    );
  }
}

void main() {
  Future<void> pumpHost(
    WidgetTester tester,
    FakeTermuxService service,
    String command,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        termuxServiceProvider.overrideWithValue(service),
        settingsControllerProvider.overrideWith(_FakeSettingsController.new),
        hapticsServiceProvider.overrideWithValue(_NoopHaptics()),
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
          home: _RunHost(command: command),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('stops before running termux-* when the APK is missing', (
    tester,
  ) async {
    final service = FakeTermuxService(apiInstalled: false);
    await pumpHost(tester, service, 'termux-toast "hello"');

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    expect(find.text('Termux:API is required'), findsOneWidget);
    expect(find.text('Send command'), findsNothing);
    expect(service.sent, isEmpty);
  });

  testWidgets('warns about the package when the APK is installed', (
    tester,
  ) async {
    final service = FakeTermuxService();
    await pumpHost(tester, service, 'termux-toast "hello"');

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    expect(find.text('Send command'), findsOneWidget);
    expect(find.text('Termux:API commands'), findsOneWidget);
    expect(
      find.textContaining('termux-api package are both installed'),
      findsOneWidget,
    );
    expect(find.text('Enable external commands in Termux'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.sent, isEmpty);
  });

  testWidgets('does not show the Termux:API note for other commands', (
    tester,
  ) async {
    final service = FakeTermuxService();
    await pumpHost(tester, service, 'echo hello');

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    expect(find.text('Send command'), findsOneWidget);
    expect(find.text('Termux:API commands'), findsNothing);
  });

  testWidgets('stops a foreground run when Termux cannot draw overlays', (
    tester,
  ) async {
    final service = FakeTermuxService(overlay: false);
    await pumpHost(tester, service, 'echo hello');

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send command'));
    await tester.pumpAndSettle();

    expect(find.text('Termux needs display permission'), findsOneWidget);
    expect(service.sent, isEmpty);

    await tester.tap(find.text('Open Termux display settings'));
    await tester.pumpAndSettle();
    expect(service.overlaySettingsOpened, 1);
    expect(service.sent, isEmpty);
  });

  testWidgets('still allows a background run without the overlay permission', (
    tester,
  ) async {
    final service = FakeTermuxService(overlay: false);
    await pumpHost(tester, service, 'echo hello');

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run in the background'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send command'));
    await tester.pumpAndSettle();

    expect(service.sent, ['echo hello']);
    expect(service.sentInBackground, [true]);
    expect(service.sentKeepOpen, [false]);
  });

  testWidgets('keeps the terminal open by default', (tester) async {
    final service = FakeTermuxService();
    await pumpHost(tester, service, 'echo hello');

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    expect(find.text('Keep terminal open'), findsOneWidget);
    await tester.tap(find.text('Send command'));
    await tester.pumpAndSettle();

    expect(service.sentKeepOpen, [true]);
  });

  testWidgets('can turn the keep-open option off', (tester) async {
    final service = FakeTermuxService();
    await pumpHost(tester, service, 'echo hello');

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep terminal open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send command'));
    await tester.pumpAndSettle();

    expect(service.sentKeepOpen, [false]);
  });

  testWidgets('hides keep-open for background runs', (tester) async {
    final service = FakeTermuxService();
    await pumpHost(tester, service, 'echo hello');

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run in the background'));
    await tester.pumpAndSettle();

    expect(find.text('Keep terminal open'), findsNothing);

    await tester.tap(find.text('Send command'));
    await tester.pumpAndSettle();
    expect(service.sentInBackground, [true]);
    expect(service.sentKeepOpen, [false]);
  });
}
