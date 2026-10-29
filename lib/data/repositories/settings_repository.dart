import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/settings/app_settings.dart';
import '../../core/constants/app_constants.dart';
import '../local/database/daos/settings_dao.dart';

/// Local-only preferences. Sensitive AI credentials never enter this table.
class SettingsRepository {
  SettingsRepository(this._dao);

  final SettingsDao _dao;
  static const _keyTheme = 'themeMode';
  static const _keyAccent = 'accentId';
  static const _keyDynamicColor = 'useDynamicColor';
  static const _keyBlur = 'blurEnabled';
  static const _keyBlurIntensity = 'blurIntensity';
  static const _keyVibration = 'vibration';
  static const _keyFontScale = 'fontScale';
  static const _keyFontFamily = 'fontFamilyId';
  static const _keyLanguage = 'languageCode';
  static const _keyAiEnabled = 'aiEnabled';
  static const _keyAiProvider = 'aiProviderId';
  static const _keyAiModel = 'aiModelId';
  static const _keyAiCacheHours = 'aiCacheHours';
  static const _keyOnboarding = 'onboardingCompleted';
  static const _keyGuestUid = 'localGuestUid';

  static const _validAccents = {
    'indigo',
    'blue',
    'cyan',
    'teal',
    'green',
    'lime',
    'amber',
    'coral',
    'rose',
    'fuchsia',
    'violet',
    'slate',
  };

  /// Ensures a stable on-device guest identity exists before any provider is
  /// built. The guest UID namespaces local favorites and pins, but is never sent
  /// to the cloud as an identity.
  Future<AppSettings> initialize() async {
    final entries = await _dao.readAll();
    final existingUid = entries[_keyGuestUid];
    if (existingUid == null ||
        existingUid.isEmpty ||
        !existingUid.startsWith(AppConstants.localUidPrefix)) {
      final uid = '${AppConstants.localUidPrefix}${const Uuid().v4()}';
      await _dao.put(_keyGuestUid, uid);
      entries[_keyGuestUid] = uid;
    }
    return _fromMap(entries);
  }

  Stream<AppSettings> watch() => _dao.watchEntries().map(_fromMap);

  Future<AppSettings> read() async => _fromMap(await _dao.readAll());

  Future<void> save(AppSettings settings) async {
    await _dao.putAll({
      _keyTheme: settings.themeMode.name,
      _keyAccent: _validAccents.contains(settings.accentId)
          ? settings.accentId
          : AppSettings.defaults(settings.localGuestUid).accentId,
      _keyDynamicColor: settings.useDynamicColor.toString(),
      _keyBlur: settings.blurEnabled.toString(),
      _keyBlurIntensity: settings.blurIntensity.clamp(0, 30).toString(),
      _keyVibration: settings.vibration.name,
      _keyFontScale: settings.fontScale.clamp(0.8, 1.5).toString(),
      _keyFontFamily:
          AppFonts.all.any((font) => font.id == settings.fontFamilyId)
          ? settings.fontFamilyId
          : AppFonts.inter.id,
      _keyLanguage: settings.languageCode == 'my' ? 'my' : 'en',
      _keyAiEnabled: settings.aiEnabled.toString(),
      _keyAiProvider: settings.aiProviderId,
      _keyAiModel: settings.aiModelId,
      _keyAiCacheHours: settings.aiCacheHours.clamp(0, 168).toString(),
      _keyOnboarding: settings.onboardingCompleted.toString(),
      _keyGuestUid: settings.localGuestUid,
    });
  }

  AppSettings _fromMap(Map<String, String> map) {
    final guestUid = map[_keyGuestUid] ?? '';
    final defaults = AppSettings.defaults(guestUid);
    return AppSettings(
      themeMode: _parseTheme(map[_keyTheme]),
      accentId: _validAccents.contains(map[_keyAccent])
          ? map[_keyAccent]!
          : defaults.accentId,
      useDynamicColor: _parseBool(map[_keyDynamicColor], fallback: false),
      blurEnabled: _parseBool(map[_keyBlur], fallback: true),
      blurIntensity: _parseDouble(map[_keyBlurIntensity], 12).clamp(0, 30),
      vibration: _parseVibration(map[_keyVibration]),
      fontScale: _parseDouble(map[_keyFontScale], 1).clamp(0.8, 1.5),
      fontFamilyId: AppFonts.byId(map[_keyFontFamily]).id,
      languageCode: map[_keyLanguage] == 'my' ? 'my' : 'en',
      aiEnabled: _parseBool(map[_keyAiEnabled], fallback: false),
      aiProviderId: AppConstants.groqProviderId,
      aiModelId: map[_keyAiModel] ?? '',
      aiCacheHours: _parseInt(
        map[_keyAiCacheHours],
        AppConstants.aiDefaultCacheHours,
      ).clamp(0, 168),
      onboardingCompleted: _parseBool(map[_keyOnboarding], fallback: false),
      localGuestUid: guestUid,
    );
  }

  ThemeMode _parseTheme(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  VibrationIntensity _parseVibration(String? raw) {
    for (final value in VibrationIntensity.values) {
      if (value.name == raw) return value;
    }
    return VibrationIntensity.medium;
  }

  bool _parseBool(String? raw, {required bool fallback}) {
    if (raw == null) return fallback;
    return raw == 'true';
  }

  double _parseDouble(String? raw, double fallback) =>
      double.tryParse(raw ?? '') ?? fallback;

  int _parseInt(String? raw, int fallback) =>
      int.tryParse(raw ?? '') ?? fallback;
}
