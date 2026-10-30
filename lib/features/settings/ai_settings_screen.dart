import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/ai_models.dart';
import '../../data/services/haptics_service.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/utils/url_actions.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/settings_tiles.dart';
import '../../shared/widgets/status_pill.dart';

/// BYOK setup for the Groq-backed assistant. The key is written only to secure
/// storage, never displayed again after saving, and never sent to Firebase.
class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  bool _fetching = false;
  bool _testPassed = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final keyAsync = ref.watch(aiKeyPresentProvider);
    final hasKey = keyAsync.value ?? false;
    final models = ref.watch(aiModelsProvider).value ?? const <AiModelInfo>[];
    AiModelInfo? selected;
    for (final model in models) {
      if (model.id == settings.aiModelId) selected = model;
    }

    return AppPage(
      title: l10n.aiSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNote(
            title: l10n.aiAssistant,
            message: l10n.aiPrivacyNote,
            tone: AppNoteTone.info,
            icon: Icons.privacy_tip_outlined,
          ),
          const SizedBox(height: AppSpacing.x5),
          SettingsGroup(
            title: l10n.aiProvider,
            children: [
              SettingsTile(
                leading: const Icon(Icons.bolt_rounded),
                title: l10n.aiProviderGroq,
                subtitle: l10n.groq,
                trailing: const StatusPill(
                  label: 'BYOK',
                  icon: Icons.key_rounded,
                  tone: StatusPillTone.primary,
                ),
              ),
              SettingsSwitchTile(
                title: l10n.aiEnabled,
                subtitle: l10n.aiEnabledHelper,
                leading: const Icon(Icons.auto_awesome_rounded),
                value: settings.aiEnabled,
                onChanged: (value) => _setEnabled(value, hasKey: hasKey),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.apiKey,
            description: l10n.apiKeyHelper,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x2,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasKey
                              ? Icons.verified_user_outlined
                              : Icons.key_off_outlined,
                          size: AppIconSizes.sm,
                          color: hasKey
                              ? context.appColors.success
                              : context.scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        Expanded(
                          child: Text(
                            hasKey ? l10n.keyStored : l10n.keyMissing,
                            style: context.texts.bodySmall?.copyWith(
                              color: hasKey
                                  ? context.appColors.success
                                  : context.scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          // New users need Groq's sign-up/sign-in before keys;
                          // returning users go straight to key management.
                          onPressed: () => openExternalUrl(
                            context,
                            hasKey
                                ? AppConstants.groqKeysUrl
                                : AppConstants.groqConsoleUrl,
                          ),
                          child: Text(l10n.getApiKey),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    TextField(
                      controller: _keyController,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      onChanged: (_) {
                        if (_testPassed) setState(() => _testPassed = false);
                      },
                      decoration: InputDecoration(
                        labelText: l10n.apiKey,
                        hintText: 'gsk_...',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? l10n.showPassword
                              : l10n.hidePassword,
                          onPressed: () {
                            unawaited(
                              triggerHaptic(ref, cue: HapticCue.toggle),
                            );
                            setState(() => _obscure = !_obscure);
                          },
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Wrap(
                      spacing: AppSpacing.x2,
                      runSpacing: AppSpacing.x1,
                      children: [
                        FilledButton.tonal(
                          onPressed: _testing ? null : _testKey,
                          child: _testing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.testKey),
                        ),
                        FilledButton(
                          onPressed: _saveKey,
                          child: Text(l10n.saveKey),
                        ),
                        if (hasKey)
                          TextButton(
                            onPressed: _removeKey,
                            child: Text(l10n.delete),
                          ),
                      ],
                    ),
                    if (_testPassed) ...[
                      const SizedBox(height: AppSpacing.x2),
                      AppNote(
                        message: l10n.keyWorks,
                        tone: AppNoteTone.success,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.aiModel,
            description: l10n.refreshModelsFirst,
            children: [
              SettingsValueTile(
                title: l10n.selectedModel,
                value:
                    selected?.displayName ??
                    (settings.aiModelId.isEmpty
                        ? l10n.noAiModelSelected
                        : settings.aiModelId),
                subtitle: selected?.contextWindow == null
                    ? null
                    : l10n.modelContext(
                        AppFormatters.tokens(selected!.contextWindow!),
                      ),
                leading: const Icon(Icons.memory_rounded),
                onTap: models.isEmpty ? null : () => _pickModel(models),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x1,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                child: OutlinedButton.icon(
                  onPressed: _fetching ? null : () => _fetchModels(),
                  icon: _fetching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(l10n.fetchModels),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.cacheDuration,
            description: l10n.cacheDurationHelper,
            children: [
              SettingsValueTile(
                title: l10n.cacheDuration,
                value: settings.aiCacheHours == 0
                    ? l10n.cacheOff
                    : l10n.cacheHours(settings.aiCacheHours),
                leading: const Icon(Icons.saved_search_rounded),
                onTap: () => _pickCacheDuration(settings.aiCacheHours),
              ),
              SettingsTile(
                title: l10n.clearAiCache,
                leading: const Icon(Icons.cleaning_services_outlined),
                onTap: _clearCache,
              ),
              SettingsTile(
                title: l10n.clearHistory,
                leading: const Icon(Icons.history_rounded),
                onTap: _clearHistory,
              ),
              SettingsTile(
                title: l10n.chatHistory,
                leading: const Icon(Icons.forum_outlined),
                onTap: () => context.push('/ai/history'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveKey() async {
    final l10n = AppLocalizations.of(context);
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      context.showSnack(l10n.keyMissing);
      return;
    }
    try {
      await ref.read(aiRepositoryProvider).saveApiKey(key);
      _keyController.clear();
      ref.invalidate(aiKeyPresentProvider);
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.keySaved);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _testKey() async {
    if (_testing) return;
    setState(() {
      _testing = true;
      _testPassed = false;
    });
    try {
      final key = _keyController.text.trim();
      await ref
          .read(aiRepositoryProvider)
          .validateKey(key.isEmpty ? null : key);
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        setState(() => _testPassed = true);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _fetchModels() async {
    if (_fetching) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _fetching = true);
    try {
      final typedKey = _keyController.text.trim();
      final repo = ref.read(aiRepositoryProvider);
      if (typedKey.isNotEmpty) {
        await repo.saveApiKey(typedKey);
        _keyController.clear();
        ref.invalidate(aiKeyPresentProvider);
      }
      await repo.fetchModels();
      ref.invalidate(aiModelsProvider);
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.modelsFetched);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _removeKey() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.apiKey,
      message: l10n.apiKeyHelper,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      final repo = ref.read(aiRepositoryProvider);
      await repo.clearApiKey();
      await repo.clearCache();
      final settings = ref.read(settingsControllerProvider);
      if (settings.aiEnabled) {
        await ref
            .read(settingsControllerProvider.notifier)
            .save(settings.copyWith(aiEnabled: false));
      }
      ref.invalidate(aiKeyPresentProvider);
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.apiKeyRemoved);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _setEnabled(bool value, {required bool hasKey}) async {
    final l10n = AppLocalizations.of(context);
    if (value && !hasKey) {
      context.showSnack(l10n.keyMissing);
      return;
    }
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .save(
            ref.read(settingsControllerProvider).copyWith(aiEnabled: value),
          );
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _pickModel(List<AiModelInfo> models) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(settingsControllerProvider).aiModelId;
    final selected = await showModalBottomSheet<AiModelInfo>(
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
                  l10n.selectModel,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: AppSpacing.x4),
                  children: [
                    for (final model in models)
                      ListTile(
                        onTap: () => Navigator.of(sheetContext).pop(model),
                        leading: Icon(
                          model.id == current
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: model.id == current
                              ? Theme.of(sheetContext).colorScheme.primary
                              : Theme.of(sheetContext)
                                    .colorScheme
                                    .onSurfaceVariant,
                        ),
                        title: Text(model.displayName),
                        subtitle: Text(
                          model.contextWindow == null
                              ? model.id
                              : '${model.id}  ·  ${l10n.modelContext(AppFormatters.tokens(model.contextWindow!))}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    if (selected == null || !mounted) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
    try {
      await ref.read(aiRepositoryProvider).selectModel(selected.id);
      if (mounted) context.showSnack(l10n.modelSelected(selected.displayName));
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _pickCacheDuration(int current) async {
    final l10n = AppLocalizations.of(context);
    final options = <int>[0, 6, 24, 72, 168];
    final selected = await showModalBottomSheet<int>(
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
                l10n.cacheDuration,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final hours in options)
              ListTile(
                leading: Icon(
                  hours == current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: Text(
                  hours == 0 ? l10n.cacheOff : l10n.cacheHours(hours),
                ),
                onTap: () => Navigator.of(sheetContext).pop(hours),
              ),
            const SizedBox(height: AppSpacing.x4),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .save(
            ref
                .read(settingsControllerProvider)
                .copyWith(aiCacheHours: selected),
          );
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(aiRepositoryProvider).clearCache();
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.aiCacheCleared);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _clearHistory() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.clearHistory,
      message: l10n.clearHistoryBody,
      confirmLabel: l10n.clearAll,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(aiRepositoryProvider).clearHistory();
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.aiHistoryCleared);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    }
  }
}
