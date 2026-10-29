import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/core/constants/app_constants.dart';
import 'package:termux_command_library/core/design_system/app_tokens.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/repositories/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = SettingsRepository(db.settingsDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('initialisation', () {
    test('creates a stable local guest identity and safe defaults', () async {
      final settings = await repository.initialize();

      expect(settings.localGuestUid, startsWith(AppConstants.localUidPrefix));
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.accentId, 'indigo');
      expect(settings.useDynamicColor, isFalse);
      expect(settings.fontFamilyId, AppFonts.inter.id);
      expect(settings.languageCode, 'en');
      expect(settings.aiEnabled, isFalse);
      expect(settings.aiProviderId, AppConstants.groqProviderId);
      expect(settings.onboardingCompleted, isFalse);

      final again = await repository.initialize();
      expect(again.localGuestUid, settings.localGuestUid);
    });

    test('replaces a malformed guest identity', () async {
      await db.settingsDao.put('localGuestUid', 'not-a-local-uid');
      final settings = await repository.initialize();
      expect(settings.localGuestUid, startsWith(AppConstants.localUidPrefix));
      expect(settings.localGuestUid, isNot('not-a-local-uid'));
    });
  });

  group('persistence', () {
    test('round trips every user-facing setting', () async {
      final base = await repository.initialize();
      final custom = base.copyWith(
        themeMode: ThemeMode.dark,
        accentId: 'teal',
        useDynamicColor: true,
        blurEnabled: false,
        blurIntensity: 5.5,
        vibration: VibrationIntensity.strong,
        fontScale: 1.25,
        fontFamilyId: AppFonts.lora.id,
        languageCode: 'my',
        aiEnabled: true,
        aiModelId: 'dynamic-model',
        aiCacheHours: 12,
        onboardingCompleted: true,
      );

      await repository.save(custom);
      final restored = await repository.read();

      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.accentId, 'teal');
      expect(restored.useDynamicColor, isTrue);
      expect(restored.blurEnabled, isFalse);
      expect(restored.blurIntensity, 5.5);
      expect(restored.vibration, VibrationIntensity.strong);
      expect(restored.fontScale, 1.25);
      expect(restored.fontFamilyId, AppFonts.lora.id);
      expect(restored.languageCode, 'my');
      expect(restored.aiEnabled, isTrue);
      expect(restored.aiModelId, 'dynamic-model');
      expect(restored.aiCacheHours, 12);
      expect(restored.onboardingCompleted, isTrue);
      expect(restored.localGuestUid, base.localGuestUid);
    });

    test('persists every supported accent id', () async {
      final base = await repository.initialize();
      for (final accent in AppAccents.all) {
        await repository.save(base.copyWith(accentId: accent.id));
        expect((await repository.read()).accentId, accent.id);
      }
    });

    test('wallpaper colors keep the selected accent as a fallback', () async {
      final base = await repository.initialize();
      await repository.save(
        base.copyWith(accentId: 'coral', useDynamicColor: true),
      );

      var restored = await repository.read();
      expect(restored.useDynamicColor, isTrue);
      expect(restored.accentId, 'coral');

      await repository.save(restored.copyWith(useDynamicColor: false));
      restored = await repository.read();
      expect(restored.useDynamicColor, isFalse);
      expect(restored.accentId, 'coral');
    });

    test('clamps values written through save', () async {
      final base = await repository.initialize();
      await repository.save(
        base.copyWith(
          blurIntensity: 99,
          fontScale: 3,
          aiCacheHours: 999,
          accentId: 'not-a-color',
          fontFamilyId: 'not-a-font',
          languageCode: 'fr',
        ),
      );

      final restored = await repository.read();
      expect(restored.blurIntensity, 30);
      expect(restored.fontScale, 1.5);
      expect(restored.aiCacheHours, 168);
      expect(restored.accentId, 'indigo');
      expect(restored.fontFamilyId, AppFonts.inter.id);
      expect(restored.languageCode, 'en');
    });

    test('streams a new snapshot after saving', () async {
      final base = await repository.initialize();
      final values = <AppSettings>[];
      final subscription = repository.watch().listen(values.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repository.save(base.copyWith(themeMode: ThemeMode.light));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await subscription.cancel();

      expect(values, isNotEmpty);
      expect(values.last.themeMode, ThemeMode.light);
    });
  });

  group('defensive parsing', () {
    test('invalid raw values fall back without throwing', () async {
      await db.settingsDao.putAll({
        'localGuestUid': 'local-guest-test',
        'themeMode': 'sepia',
        'accentId': 'neon',
        'useDynamicColor': 'perhaps',
        'blurEnabled': 'perhaps',
        'blurIntensity': '-4',
        'vibration': 'earthquake',
        'fontScale': '0.1',
        'fontFamilyId': 'unknown',
        'languageCode': 'de',
        'aiEnabled': 'nope',
        'aiModelId': '',
        'aiCacheHours': '-3',
        'onboardingCompleted': 'yes',
      });

      final settings = await repository.read();
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.accentId, 'indigo');
      expect(settings.useDynamicColor, isFalse);
      expect(settings.blurEnabled, isFalse);
      expect(settings.blurIntensity, 0);
      expect(settings.vibration, VibrationIntensity.medium);
      expect(settings.fontScale, 0.8);
      expect(settings.fontFamilyId, AppFonts.inter.id);
      expect(settings.languageCode, 'en');
      expect(settings.aiEnabled, isFalse);
      expect(settings.aiCacheHours, 0);
      expect(settings.onboardingCompleted, isFalse);
    });

    test(
      'AI provider selection is always normalised to Groq for now',
      () async {
        await db.settingsDao.putAll({
          'localGuestUid': 'local-guest-test',
          'aiProvider': 'another-provider',
        });
        expect((await repository.read()).aiProviderId, 'groq');
      },
    );
  });
}
