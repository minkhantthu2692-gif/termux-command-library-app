import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/settings/app_settings.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/auth_models.dart';
import '../../shared/utils/error_messages.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/settings_tiles.dart';
import '../../shared/widgets/sync_status_badge.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _refreshing = false;
  bool _clearing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final session = ref.watch(currentSessionProvider);
    final profile = ref.watch(profileProvider).value;
    final cloudConfigured = ref.watch(
      appDependenciesProvider.select((deps) => deps.cloudConfigured),
    );
    final keyAsync = ref.watch(aiKeyPresentProvider);
    final hasKey = keyAsync.value ?? false;
    final models = ref.watch(aiModelsProvider).value ?? const <AiModelInfo>[];
    AiModelInfo? selectedModel;
    for (final model in models) {
      if (model.id == settings.aiModelId) selectedModel = model;
    }
    final cachedCount = ref.watch(cachedCommandCountProvider);

    return AppPage(
      title: l10n.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AccountSummary(
            session: session,
            nickname: profile?.effectiveNickname ?? '',
            email: profile?.email ?? session.email ?? '',
            onTap: () => context.push('/settings/account'),
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.appearance,
            children: [
              SettingsValueTile(
                title: l10n.theme,
                value: _themeLabel(l10n, settings.themeMode),
                leading: const Icon(Icons.contrast_rounded),
                onTap: () => context.push('/settings/appearance'),
              ),
              SettingsValueTile(
                title: l10n.accentColor,
                value: _accentLabel(l10n, settings.accentId),
                leading: const Icon(Icons.palette_outlined),
                onTap: () => context.push('/settings/appearance'),
              ),
              SettingsValueTile(
                title: l10n.fontFamily,
                value: settings.font.isDefault
                    ? l10n.fontSystem
                    : settings.font.label,
                leading: const Icon(Icons.text_fields_rounded),
                onTap: () => context.push('/settings/appearance'),
              ),
              SettingsValueTile(
                title: l10n.language,
                value: settings.effectiveLanguageCode == 'my'
                    ? l10n.languageMyanmar
                    : l10n.languageEnglish,
                leading: const Icon(Icons.translate_rounded),
                onTap: () => context.push('/settings/appearance'),
              ),
              SettingsSwitchTile(
                title: l10n.blurEffects,
                subtitle: l10n.blurEffectsHelper,
                leading: const Icon(Icons.blur_on_rounded),
                value: settings.blurEnabled,
                onChanged: (value) =>
                    _save(settings.copyWith(blurEnabled: value)),
              ),
              SettingsValueTile(
                title: l10n.vibrationIntensity,
                value: _vibrationLabel(l10n, settings.vibration),
                leading: const Icon(Icons.vibration_rounded),
                onTap: () => context.push('/settings/appearance'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.aiAssistant,
            description: l10n.aiAssistantSubtitle,
            children: [
              SettingsSwitchTile(
                title: l10n.aiEnabled,
                subtitle: l10n.aiEnabledHelper,
                leading: const Icon(Icons.auto_awesome_rounded),
                value: settings.aiEnabled,
                onChanged: (value) =>
                    _toggleAi(value, hasKey: hasKey, models: models),
              ),
              SettingsValueTile(
                title: l10n.aiSettings,
                value:
                    selectedModel?.displayName ??
                    (hasKey ? l10n.noAiModelSelected : l10n.keyMissing),
                subtitle: hasKey ? l10n.aiProviderGroq : l10n.aiSetupGuideBody,
                leading: const Icon(Icons.key_outlined),
                onTap: () => context.push('/settings/ai'),
              ),
              SettingsTile(
                leading: const Icon(Icons.history_rounded),
                title: l10n.chatHistory,
                subtitle: l10n.aiHistory,
                onTap: () => context.push('/ai/history'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.dataAndStorage,
            description: l10n.localDatabaseBody,
            children: [
              SettingsTile(
                title: l10n.localDatabase,
                subtitle: cachedCount.when(
                  data: (count) => l10n.commandsCached(count),
                  loading: () => l10n.loading,
                  error: (_, _) => l10n.databaseHealthy,
                ),
                leading: const Icon(Icons.storage_rounded),
                trailing: const SyncStatusBadge(compact: true, showTime: false),
              ),
              if (cloudConfigured)
                SettingsTile(
                  leading: _refreshing
                      ? const SizedBox(
                          width: AppIconSizes.sm,
                          height: AppIconSizes.sm,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  title: _refreshing ? l10n.refreshing : l10n.refreshLibrary,
                  subtitle: l10n.refreshLibrary,
                  enabled: !_refreshing,
                  onTap: _refreshLibrary,
                ),
              SettingsTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: l10n.clearCache,
                subtitle: l10n.clearCacheBody,
                enabled: !_clearing,
                onTap: _clearCache,
              ),
              SettingsTile(
                leading: const Icon(Icons.key_outlined),
                title: l10n.aiSettings,
                subtitle: l10n.cachePolicyNote,
                onTap: () => context.push('/settings/ai'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.about,
            children: [
              SettingsTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: l10n.account,
                subtitle: l10n.accountAndSync,
                onTap: () => context.push('/settings/account'),
              ),
              SettingsTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: l10n.documentation,
                subtitle: l10n.firebaseSetupDocs,
                onTap: () => context.push('/docs'),
              ),
              SettingsTile(
                leading: const Icon(Icons.terminal_rounded),
                title: l10n.termuxGuide,
                subtitle: l10n.termuxGuideIntro,
                onTap: () => context.push('/termux-guide'),
              ),
              SettingsTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: l10n.privacy,
                subtitle: l10n.privacyBody,
                onTap: () => _showPrivacy(l10n),
              ),
              SettingsTile(
                leading: const Icon(Icons.description_outlined),
                title: l10n.licenses,
                subtitle: l10n.openSource,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appName,
                  applicationVersion: '1.0.0',
                  applicationLegalese: l10n.appTagline,
                ),
              ),
              SettingsTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: l10n.version,
                trailing: Text(
                  '1.0.0',
                  style: context.texts.labelSmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (!cloudConfigured) ...[
            const SizedBox(height: AppSpacing.x4),
            AppNote(
              title: l10n.localOnly,
              message: l10n.cloudUnavailableBody,
              tone: AppNoteTone.neutral,
              actionLabel: l10n.openDocs,
              onAction: () => context.push('/docs'),
            ),
          ],
          const SizedBox(height: AppSpacing.x4),
          Text(
            l10n.appDescription,
            textAlign: TextAlign.center,
            style: context.texts.labelSmall?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
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

  Future<void> _toggleAi(
    bool value, {
    required bool hasKey,
    required List<AiModelInfo> models,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (value && !hasKey) {
      context.showSnack(l10n.keyMissing);
      return;
    }
    if (value && models.isEmpty) {
      context.showSnack(l10n.refreshModelsFirst);
      return;
    }
    await _save(
      ref.read(settingsControllerProvider).copyWith(aiEnabled: value),
    );
  }

  Future<void> _refreshLibrary() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await ref.read(syncCoordinatorProvider).refresh();
      if (mounted) {
        context.showSnack(AppLocalizations.of(context).refreshed);
      }
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        context.showSnack(
          '${l10n.refreshFailed}\n${localizeError(l10n, error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.clearCache,
      message: l10n.clearCacheBody,
      confirmLabel: l10n.clear,
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _clearing = true);
    try {
      final uid = ref.read(currentUidProvider);
      await ref.read(commandRepositoryProvider).clearRemoteCache(uid);
      ref.invalidate(cachedCommandCountProvider);
      if (mounted) context.showSnack(l10n.cacheCleared);
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _showPrivacy(AppLocalizations l10n) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.privacy),
        content: SingleChildScrollView(
          child: Text(
            '${l10n.privacyBody}\n\n${l10n.syncSecretsNote}\n\n${l10n.cachePolicyNote}',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
    ThemeMode.system => l10n.themeSystem,
  };

  String _accentLabel(AppLocalizations l10n, String id) => switch (id) {
    'teal' => l10n.accentTeal,
    'rose' => l10n.accentRose,
    'amber' => l10n.accentAmber,
    'violet' => l10n.accentViolet,
    'green' => l10n.accentGreen,
    'blue' => l10n.accentBlue,
    _ => l10n.accentIndigo,
  };

  String _vibrationLabel(AppLocalizations l10n, VibrationIntensity value) =>
      switch (value) {
        VibrationIntensity.off => l10n.vibrationOff,
        VibrationIntensity.light => l10n.vibrationLight,
        VibrationIntensity.medium => l10n.vibrationMedium,
        VibrationIntensity.strong => l10n.vibrationStrong,
      };
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({
    required this.session,
    required this.nickname,
    required this.email,
    required this.onTap,
  });

  final AuthSession session;
  final String nickname;
  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = nickname.trim();
    final role = session.isAdmin
        ? l10n.admin
        : session.isRegistered
        ? l10n.member
        : l10n.guest;
    return Material(
      color: context.appColors.card,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(
              color: context.scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.scheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(
                  Icons.account_circle_outlined,
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? l10n.guest : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall,
                    ),
                    Text(
                      email.trim().isEmpty ? role : l10n.signedInAs(email),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppIconSizes.md,
                color: context.scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
