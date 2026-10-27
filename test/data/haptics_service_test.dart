import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/data/services/haptics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.termuxlibrary/haptics');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('patternFor', () {
    test('off produces no pattern for any cue', () {
      for (final cue in HapticCue.values) {
        final pattern = HapticsService.patternFor(VibrationIntensity.off, cue);
        expect(pattern.isEmpty, isTrue, reason: 'cue=$cue');
        expect(pattern.timings, isEmpty);
        expect(pattern.amplitudes, isEmpty);
      }
    });

    test('higher intensity increases both duration and amplitude', () {
      final light = HapticsService.patternFor(
        VibrationIntensity.light,
        HapticCue.selection,
      );
      final medium = HapticsService.patternFor(
        VibrationIntensity.medium,
        HapticCue.selection,
      );
      final strong = HapticsService.patternFor(
        VibrationIntensity.strong,
        HapticCue.selection,
      );

      expect(light.timings[1], lessThan(medium.timings[1]));
      expect(medium.timings[1], lessThan(strong.timings[1]));
      expect(light.amplitudes[1], lessThan(medium.amplitudes[1]));
      expect(medium.amplitudes[1], lessThan(strong.amplitudes[1]));
      expect(strong.amplitudes[1], 255);
      expect(light.timings[1], greaterThanOrEqualTo(4));
    });

    test('timings and amplitudes stay aligned with silent gaps', () {
      for (final intensity in VibrationIntensity.values) {
        for (final cue in HapticCue.values) {
          final pattern = HapticsService.patternFor(intensity, cue);
          if (intensity == VibrationIntensity.off) {
            expect(pattern.isEmpty, isTrue, reason: 'cue=$cue');
            continue;
          }
          expect(
            pattern.amplitudes.length,
            pattern.timings.length,
            reason: 'intensity=$intensity cue=$cue',
          );
          expect(pattern.timings.first, 0, reason: 'cue=$cue');
          for (var index = 0; index < pattern.timings.length; index++) {
            if (index.isEven) {
              expect(
                pattern.amplitudes[index],
                0,
                reason: 'off segment should be silent: cue=$cue index=$index',
              );
            } else {
              expect(
                pattern.amplitudes[index],
                greaterThan(0),
                reason: 'on segment should be audible: cue=$cue index=$index',
              );
            }
          }
        }
      }
    });

    test('semantic cues have distinct rhythms', () {
      final selection = HapticsService.patternFor(
        VibrationIntensity.medium,
        HapticCue.selection,
      );
      final success = HapticsService.patternFor(
        VibrationIntensity.medium,
        HapticCue.success,
      );
      final warning = HapticsService.patternFor(
        VibrationIntensity.medium,
        HapticCue.warning,
      );
      final error = HapticsService.patternFor(
        VibrationIntensity.medium,
        HapticCue.error,
      );

      expect(selection.timings.length, 2);
      expect(success.timings.length, 4);
      expect(warning.timings.length, 4);
      expect(error.timings.length, 6);
      expect(success.timings, isNot(equals(warning.timings)));
      expect(warning.timings, isNot(equals(error.timings)));
    });
  });

  group('trigger', () {
    const service = HapticsService();

    test('sends the generated waveform over the native channel', () async {
      MethodCall? captured;
      messenger.setMockMethodCallHandler(channel, (call) async {
        captured = call;
        return null;
      });

      await service.trigger(VibrationIntensity.medium, cue: HapticCue.success);

      expect(captured?.method, 'perform');
      final arguments = captured!.arguments as Map<Object?, Object?>;
      final expected = HapticsService.patternFor(
        VibrationIntensity.medium,
        HapticCue.success,
      );
      expect(arguments['timings'], expected.timings);
      expect(arguments['amplitudes'], expected.amplitudes);
    });

    test('off never reaches the native channel', () async {
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls++;
        return null;
      });

      await service.trigger(VibrationIntensity.off, cue: HapticCue.error);

      expect(calls, 0);
    });

    test('missing native support falls back without throwing', () async {
      await expectLater(
        service.trigger(VibrationIntensity.strong, cue: HapticCue.error),
        completes,
      );
    });
  });
}
