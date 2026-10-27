import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/providers.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/data/services/haptics_service.dart';
import 'package:termux_command_library/shared/widgets/haptic_slider.dart';
import 'package:termux_command_library/shared/widgets/settings_tiles.dart';

class _FakeSettingsController extends SettingsController {
  @override
  AppSettings build() => AppSettings.defaults('test-guest');

  @override
  Future<void> save(AppSettings next) async {
    state = next;
  }
}

class _RecordingHaptics extends HapticsService {
  final List<HapticCue> cues = <HapticCue>[];

  @override
  Future<void> trigger(
    VibrationIntensity intensity, {
    HapticCue cue = HapticCue.tap,
  }) async {
    cues.add(cue);
  }
}

void main() {
  late _RecordingHaptics haptics;
  late ProviderContainer container;

  setUp(() {
    haptics = _RecordingHaptics();
    container = ProviderContainer(
      overrides: [
        hapticsServiceProvider.overrideWithValue(haptics),
        settingsControllerProvider.overrideWith(_FakeSettingsController.new),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  testWidgets('switch row toggles once and plays one cue', (tester) async {
    var value = false;
    final changes = <bool>[];
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SettingsSwitchTile(
          title: 'Frosted glass',
          value: value,
          onChanged: (next) {
            changes.add(next);
            setState(() => value = next);
          },
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(changes, [true]);
    expect(value, isTrue);

    await tester.tap(find.text('Frosted glass'));
    await tester.pump();
    expect(changes, [true, false]);
    expect(value, isFalse);
    expect(haptics.cues, [HapticCue.toggle, HapticCue.toggle]);
  });

  testWidgets('discrete slider ticks once per division change', (tester) async {
    var value = 0.0;
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => HapticSlider(
          value: value,
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: (next) => setState(() => value = next),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart!(0);
    // Several drag events inside the same division must produce one tick.
    slider.onChanged!(0.04);
    slider.onChanged!(0.12);
    slider.onChanged!(0.18);
    slider.onChanged!(0.22);
    slider.onChanged!(0.29);
    slider.onChangeEnd!(0.29);

    expect(haptics.cues, [
      HapticCue.selection,
      HapticCue.selection,
      HapticCue.selection,
    ]);
  });

  testWidgets('a new drag resumes ticking from its starting division', (
    tester,
  ) async {
    await pump(
      tester,
      HapticSlider(value: 0, divisions: 10, onChanged: (_) {}),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart!(0);
    slider.onChanged!(0.2);
    slider.onChangeEnd!(0.2);
    slider.onChangeStart!(0.2);
    slider.onChanged!(0.5);
    slider.onChangeEnd!(0.5);

    expect(haptics.cues, [HapticCue.selection, HapticCue.selection]);
  });
}
