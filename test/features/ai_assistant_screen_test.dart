import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/app/providers.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/app/theme/app_theme.dart';
import 'package:termux_command_library/data/models/ai_models.dart';
import 'package:termux_command_library/data/services/haptics_service.dart';
import 'package:termux_command_library/features/ai_assistant/assistant_screen.dart';

class _FakeSettingsController extends SettingsController {
  @override
  AppSettings build() => AppSettings.defaults('test-guest');

  @override
  Future<void> save(AppSettings next) async {
    state = next;
  }
}

class _SilentHaptics extends HapticsService {
  @override
  Future<void> trigger(
    VibrationIntensity intensity, {
    HapticCue cue = HapticCue.tap,
  }) async {}
}

void main() {
  testWidgets('AI-off card opens settings and omits removed elements', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final settings = AppSettings.defaults('test-guest');
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: AssistantScreen()),
        ),
        GoRoute(
          path: '/settings/ai',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('AI settings destination')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith(_FakeSettingsController.new),
          hapticsServiceProvider.overrideWithValue(_SilentHaptics()),
          aiKeyPresentProvider.overrideWith((ref) async => false),
          aiModelsProvider.overrideWith(
            (ref) => Stream.value(const <AiModelInfo>[]),
          ),
          aiConversationsProvider.overrideWith(
            (ref, search) => Stream.value(const <AiConversation>[]),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.build(settings, Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI is off'), findsOneWidget);
    expect(find.text('Enable assistant'), findsNothing);
    expect(find.text('Local only'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.text('AI is off'));
    await tester.pumpAndSettle();

    expect(find.text('AI settings destination'), findsOneWidget);
  });
}
