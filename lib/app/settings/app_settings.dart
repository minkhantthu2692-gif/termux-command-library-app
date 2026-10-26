import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class AppFontOption {
  const AppFontOption({
    required this.id,
    required this.family,
    required this.label,
    this.isDefault = false,
  });

  final String id;

  /// Null means the platform's system font.
  final String? family;
  final String label;
  final bool isDefault;
}

abstract final class AppFonts {
  static const system = AppFontOption(
    id: 'system',
    family: null,
    label: 'System default',
    isDefault: true,
  );
  static const inter = AppFontOption(
    id: 'inter',
    family: 'Inter',
    label: 'Inter',
  );
  static const openSans = AppFontOption(
    id: 'open_sans',
    family: 'OpenSans',
    label: 'Open Sans',
  );
  static const lato = AppFontOption(id: 'lato', family: 'Lato', label: 'Lato');
  static const montserrat = AppFontOption(
    id: 'montserrat',
    family: 'Montserrat',
    label: 'Montserrat',
  );
  static const nunitoSans = AppFontOption(
    id: 'nunito_sans',
    family: 'NunitoSans',
    label: 'Nunito Sans',
  );
  static const sourceSans3 = AppFontOption(
    id: 'source_sans_3',
    family: 'SourceSans3',
    label: 'Source Sans 3',
  );
  static const lora = AppFontOption(id: 'lora', family: 'Lora', label: 'Lora');
  static const robotoSlab = AppFontOption(
    id: 'roboto_slab',
    family: 'RobotoSlab',
    label: 'Roboto Slab',
  );
  static const jetBrainsMono = AppFontOption(
    id: 'jetbrains_mono',
    family: 'JetBrainsMono',
    label: 'JetBrains Mono',
  );

  static const all = <AppFontOption>[
    system,
    inter,
    openSans,
    lato,
    montserrat,
    nunitoSans,
    sourceSans3,
    lora,
    robotoSlab,
    jetBrainsMono,
  ];

  static AppFontOption byId(String? id) =>
      all.firstWhere((font) => font.id == id, orElse: () => inter);

  static const commandMonoFamily = 'JetBrainsMono';
  static const myanmarFallback = 'NotoSansMyanmar';
}

enum VibrationIntensity {
  off,
  light,
  medium,
  strong;

  String get labelKey => switch (this) {
    VibrationIntensity.off => 'vibrationOff',
    VibrationIntensity.light => 'vibrationLight',
    VibrationIntensity.medium => 'vibrationMedium',
    VibrationIntensity.strong => 'vibrationStrong',
  };
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.accentId,
    required this.blurEnabled,
    required this.blurIntensity,
    required this.vibration,
    required this.fontScale,
    required this.fontFamilyId,
    required this.languageCode,
    required this.aiEnabled,
    required this.aiProviderId,
    required this.aiModelId,
    required this.aiCacheHours,
    required this.onboardingCompleted,
    required this.localGuestUid,
  });

  final ThemeMode themeMode;
  final String accentId;
  final bool blurEnabled;

  /// Backdrop blur sigma. 0 disables the effect even if enabled.
  final double blurIntensity;
  final VibrationIntensity vibration;

  /// App-level text multiplier. Kept within a readable range in the UI.
  final double fontScale;
  final String fontFamilyId;
  final String languageCode;
  final bool aiEnabled;
  final String aiProviderId;
  final String aiModelId;
  final int aiCacheHours;
  final bool onboardingCompleted;

  /// Stable on-device identity used to scope guest favorites and pins.
  final String localGuestUid;

  String get effectiveLanguageCode => languageCode == 'my' ? 'my' : 'en';

  AppFontOption get font => AppFonts.byId(fontFamilyId);

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? accentId,
    bool? blurEnabled,
    double? blurIntensity,
    VibrationIntensity? vibration,
    double? fontScale,
    String? fontFamilyId,
    String? languageCode,
    bool? aiEnabled,
    String? aiProviderId,
    String? aiModelId,
    int? aiCacheHours,
    bool? onboardingCompleted,
    String? localGuestUid,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    accentId: accentId ?? this.accentId,
    blurEnabled: blurEnabled ?? this.blurEnabled,
    blurIntensity: blurIntensity ?? this.blurIntensity,
    vibration: vibration ?? this.vibration,
    fontScale: fontScale ?? this.fontScale,
    fontFamilyId: fontFamilyId ?? this.fontFamilyId,
    languageCode: languageCode ?? this.languageCode,
    aiEnabled: aiEnabled ?? this.aiEnabled,
    aiProviderId: aiProviderId ?? this.aiProviderId,
    aiModelId: aiModelId ?? this.aiModelId,
    aiCacheHours: aiCacheHours ?? this.aiCacheHours,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    localGuestUid: localGuestUid ?? this.localGuestUid,
  );

  static AppSettings defaults(String localGuestUid) => AppSettings(
    themeMode: ThemeMode.system,
    accentId: 'indigo',
    blurEnabled: true,
    blurIntensity: 12,
    vibration: VibrationIntensity.medium,
    fontScale: 1,
    fontFamilyId: AppFonts.inter.id,
    languageCode: 'en',
    aiEnabled: false,
    aiProviderId: AppConstants.groqProviderId,
    aiModelId: '',
    aiCacheHours: AppConstants.aiDefaultCacheHours,
    onboardingCompleted: false,
    localGuestUid: localGuestUid,
  );
}
