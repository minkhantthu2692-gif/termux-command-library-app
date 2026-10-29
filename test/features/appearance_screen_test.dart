import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/app/providers.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/app/theme/app_theme.dart';
import 'package:termux_command_library/app/theme/dynamic_color_scope.dart';
import 'package:termux_command_library/core/design_system/app_tokens.dart';
import 'package:termux_command_library/data/services/haptics_service.dart';
import 'package:termux_command_library/features/settings/appearance_screen.dart';

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
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        hapticsServiceProvider.overrideWithValue(_SilentHaptics()),
        settingsControllerProvider.overrideWith(_FakeSettingsController.new),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool dynamicColorSupported = false,
  }) async {
    final settings = container.read(settingsControllerProvider);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: DynamicColorScope(
          isSupported: dynamicColorSupported,
          child: MaterialApp(
            theme: AppTheme.build(settings, Brightness.light),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppearanceScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders every accent swatch on a phone-width screen', (
    tester,
  ) async {
    await pumpScreen(tester);

    for (final accent in AppAccents.all) {
      final label = _labels[accent.id]!;
      expect(find.byTooltip(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a new accent updates the saved setting', (
    tester,
  ) async {
    await pumpScreen(tester);

    final coral = find.byTooltip('Coral');
    await tester.ensureVisible(coral);
    await tester.tap(coral);
    await tester.pumpAndSettle();

    expect(container.read(settingsControllerProvider).accentId, 'coral');
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides wallpaper colors on devices without support', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Wallpaper colors'), findsNothing);
  });

  testWidgets('wallpaper colors can be enabled and a palette tap disables it', (
    tester,
  ) async {
    await pumpScreen(tester, dynamicColorSupported: true);

    await tester.tap(find.text('Wallpaper colors'));
    await tester.pumpAndSettle();
    expect(container.read(settingsControllerProvider).useDynamicColor, isTrue);

    final teal = find.byTooltip('Teal');
    await tester.ensureVisible(teal);
    await tester.tap(teal);
    await tester.pumpAndSettle();

    final settings = container.read(settingsControllerProvider);
    expect(settings.useDynamicColor, isFalse);
    expect(settings.accentId, 'teal');
    expect(tester.takeException(), isNull);
  });
}

const _labels = <String, String>{
  'indigo': 'Indigo',
  'blue': 'Blue',
  'cyan': 'Cyan',
  'teal': 'Teal',
  'green': 'Green',
  'lime': 'Lime',
  'amber': 'Amber',
  'coral': 'Coral',
  'rose': 'Rose',
  'fuchsia': 'Fuchsia',
  'violet': 'Violet',
  'slate': 'Slate',
};
