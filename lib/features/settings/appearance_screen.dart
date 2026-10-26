import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/settings/app_settings.dart';
import '../../core/design_system/app_tokens.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/settings_tiles.dart';

/// Appearance is intentionally a single, live-previewed surface: theme, accent,
/// type, language and tactile effects are all changed without a save button.
class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  late double _fontScale;
  late double _blurIntensity;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final settings = ref.read(settingsControllerProvider);
    _fontScale = settings.fontScale;
    _blurIntensity = settings.blurIntensity;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    return AppPage(
      title: l10n.appearance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.changesSavedAutomatically,
            style: context.texts.bodySmall?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          _PreviewCard(settings: settings, fontScale: _fontScale),
          const SizedBox(height: AppSpacing.x5),
          SettingsGroup(
            title: l10n.theme,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x2,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.themeSystem),
                      icon: const Icon(Icons.brightness_auto_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.themeLight),
                      icon: const Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.themeDark),
                      icon: const Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) =>
                      _save(settings.copyWith(themeMode: selection.first)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.accentColor,
            padding: const EdgeInsets.all(AppSpacing.x4),
            children: [
              Wrap(
                spacing: AppSpacing.x3,
                runSpacing: AppSpacing.x3,
                children: [
                  for (final accent in AppAccents.all)
                    _AccentSwatch(
                      accent: accent,
                      label: _accentLabel(l10n, accent.id),
                      selected: settings.accentId == accent.id,
                      onTap: () =>
                          _save(settings.copyWith(accentId: accent.id)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.typography,
            children: [
              SettingsValueTile(
                title: l10n.fontFamily,
                value: _fontLabel(l10n, settings.font),
                leading: const Icon(Icons.text_fields_rounded),
                onTap: () => _pickFont(settings),
              ),
              SettingsValueTile(
                title: l10n.language,
                value: settings.effectiveLanguageCode == 'my'
                    ? l10n.languageMyanmar
                    : l10n.languageEnglish,
                leading: const Icon(Icons.translate_rounded),
                onTap: () => _pickLanguage(settings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.fontSize,
            description: l10n.fontSizePreview,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x3,
                  vertical: AppSpacing.x1,
                ),
                child: Row(
                  children: [
                    Text('A', style: context.texts.bodySmall),
                    Expanded(
                      child: Slider(
                        value: _fontScale,
                        min: 0.85,
                        max: 1.3,
                        divisions: 9,
                        label: '${(_fontScale * 100).round()}%',
                        onChanged: (value) =>
                            setState(() => _fontScale = value),
                        onChangeEnd: (value) => _save(
                          ref
                              .read(settingsControllerProvider)
                              .copyWith(fontScale: value),
                        ),
                      ),
                    ),
                    Text(
                      'A',
                      style: context.texts.titleLarge?.copyWith(fontSize: 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.effects,
            children: [
              SettingsSwitchTile(
                title: l10n.blurEffects,
                subtitle: l10n.blurEffectsHelper,
                leading: const Icon(Icons.blur_on_rounded),
                value: settings.blurEnabled,
                onChanged: (value) =>
                    _save(settings.copyWith(blurEnabled: value)),
              ),
              if (settings.blurEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x3,
                    vertical: AppSpacing.x1,
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.blurIntensity,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _blurIntensity.clamp(0, 30),
                          min: 0,
                          max: 30,
                          divisions: 10,
                          label: _blurIntensity.round().toString(),
                          onChanged: (value) =>
                              setState(() => _blurIntensity = value),
                          onChangeEnd: (value) => _save(
                            ref
                                .read(settingsControllerProvider)
                                .copyWith(blurIntensity: value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.haptics,
            children: [
              SettingsValueTile(
                title: l10n.vibrationIntensity,
                value: _vibrationLabel(l10n, settings.vibration),
                leading: const Icon(Icons.vibration_rounded),
                onTap: () => _pickVibration(settings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(AppSettings next) async {
    try {
      await ref.read(settingsControllerProvider.notifier).save(next);
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _pickFont(AppSettings settings) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<AppFontOption>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x2,
                  AppSpacing.x5,
                  AppSpacing.x3,
                ),
                child: Text(
                  l10n.fontFamily,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: AppSpacing.x4),
                  children: [
                    for (final font in AppFonts.all)
                      ListTile(
                        onTap: () => Navigator.of(sheetContext).pop(font),
                        leading: Icon(
                          settings.fontFamilyId == font.id
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: settings.fontFamilyId == font.id
                              ? Theme.of(sheetContext).colorScheme.primary
                              : Theme.of(sheetContext)
                                    .colorScheme
                                    .onSurfaceVariant,
                        ),
                        title: Text(
                          _fontLabel(l10n, font),
                          style: TextStyle(
                            fontFamily: font.family,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          l10n.fontSizePreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: font.family,
                            fontFamilyFallback: const [
                              AppFonts.myanmarFallback,
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      await _save(settings.copyWith(fontFamilyId: selected.id));
    }
  }

  Future<void> _pickLanguage(AppSettings settings) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x2,
                AppSpacing.x5,
                AppSpacing.x3,
              ),
              child: Text(
                l10n.language,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(l10n.languageEnglish),
              trailing: settings.effectiveLanguageCode == 'en'
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop('en'),
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(l10n.languageMyanmar),
              trailing: settings.effectiveLanguageCode == 'my'
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop('my'),
            ),
            const SizedBox(height: AppSpacing.x4),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      await _save(settings.copyWith(languageCode: selected));
    }
  }

  Future<void> _pickVibration(AppSettings settings) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<VibrationIntensity>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x2,
                AppSpacing.x5,
                AppSpacing.x3,
              ),
              child: Text(
                l10n.vibrationIntensity,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final value in VibrationIntensity.values)
              ListTile(
                leading: Icon(
                  value == VibrationIntensity.off
                      ? Icons.do_not_disturb_on_outlined
                      : Icons.vibration_rounded,
                ),
                title: Text(_vibrationLabel(l10n, value)),
                trailing: settings.vibration == value
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
            const SizedBox(height: AppSpacing.x4),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      await _save(settings.copyWith(vibration: selected));
    }
  }

  String _fontLabel(AppLocalizations l10n, AppFontOption font) =>
      font.isDefault ? l10n.fontSystem : font.label;

  String _vibrationLabel(AppLocalizations l10n, VibrationIntensity value) {
    return switch (value) {
      VibrationIntensity.off => l10n.vibrationOff,
      VibrationIntensity.light => l10n.vibrationLight,
      VibrationIntensity.medium => l10n.vibrationMedium,
      VibrationIntensity.strong => l10n.vibrationStrong,
    };
  }

  String _accentLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'teal' => l10n.accentTeal,
      'rose' => l10n.accentRose,
      'amber' => l10n.accentAmber,
      'violet' => l10n.accentViolet,
      'green' => l10n.accentGreen,
      'blue' => l10n.accentBlue,
      _ => l10n.accentIndigo,
    };
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.settings, required this.fontScale});

  final AppSettings settings;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final font = settings.font;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: context.scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.scheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  Icons.terminal_rounded,
                  size: AppIconSizes.sm,
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  l10n.appName,
                  style: context.texts.titleSmall?.copyWith(
                    fontFamily: font.family,
                    fontSize:
                        (context.texts.titleSmall?.fontSize ?? 14) * fontScale,
                  ),
                ),
              ),
              Icon(
                Icons.bookmark_border_rounded,
                size: AppIconSizes.sm,
                color: context.scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            l10n.fontSizePreview,
            style: context.texts.bodyMedium?.copyWith(
              fontFamily: font.family,
              fontFamilyFallback: const [AppFonts.myanmarFallback],
              fontSize: (context.texts.bodyMedium?.fontSize ?? 14) * fontScale,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              FilledButton.tonal(onPressed: () {}, child: Text(l10n.copy)),
              const SizedBox(width: AppSpacing.x2),
              OutlinedButton(onPressed: () {}, child: Text(l10n.run)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppDurations.short,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.seed,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? context.scheme.onSurface
                    : context.scheme.outlineVariant.withValues(alpha: 0.4),
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}
