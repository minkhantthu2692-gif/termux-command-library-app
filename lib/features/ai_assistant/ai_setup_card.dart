import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/settings/app_settings.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/ai_models.dart';
import '../../data/services/haptics_service.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/section_header.dart';

enum AiAvailability { loading, disabled, missingKey, missingModel, ready }

AiAvailability resolveAiAvailability({
  required AppSettings settings,
  required AsyncValue<bool> keyAsync,
  required List<AiModelInfo> models,
}) {
  if (keyAsync.isLoading) return AiAvailability.loading;
  if (!settings.aiEnabled) return AiAvailability.disabled;
  if (!(keyAsync.value ?? false)) return AiAvailability.missingKey;
  final selected = settings.aiModelId.trim();
  if (selected.isEmpty || !models.any((model) => model.id == selected)) {
    return AiAvailability.missingModel;
  }
  return AiAvailability.ready;
}

/// Explains exactly which setup step is missing and links to the AI settings
/// screen. It never asks for a key in the assistant itself.
class AiSetupCard extends ConsumerWidget {
  const AiSetupCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final keyAsync = ref.watch(aiKeyPresentProvider);
    final models = ref.watch(aiModelsProvider).value ?? const <AiModelInfo>[];
    final availability = resolveAiAvailability(
      settings: settings,
      keyAsync: keyAsync,
      models: models,
    );

    final (
      String title,
      String message,
      IconData icon,
    ) = switch (availability) {
      AiAvailability.loading => (
        l10n.loading,
        l10n.aiSetupGuideBody,
        Icons.hourglass_empty_rounded,
      ),
      AiAvailability.disabled => (
        l10n.aiDisabledTitle,
        l10n.aiDisabledBody,
        Icons.auto_awesome_outlined,
      ),
      AiAvailability.missingKey => (
        l10n.aiNoProviderConfigured,
        l10n.aiSetupGuideBody,
        Icons.key_off_outlined,
      ),
      AiAvailability.missingModel => (
        l10n.noAiModelSelected,
        l10n.refreshModelsFirst,
        Icons.memory_rounded,
      ),
      AiAvailability.ready => (
        l10n.aiAssistant,
        l10n.aiAssistantSubtitle,
        Icons.auto_awesome_rounded,
      ),
    };

    // Loading has no destination yet; every other state opens the existing AI
    // settings route, so the whole card acts as the affordance.
    final canOpenSettings = availability != AiAvailability.loading;
    return Material(
      color: context.appColors.card,
      borderRadius: AppRadius.large,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: canOpenSettings
            ? () {
                unawaited(triggerHaptic(ref, cue: HapticCue.selection));
                context.push('/settings/ai');
              }
            : null,
        child: Container(
          padding: EdgeInsets.all(compact ? AppSpacing.x3 : AppSpacing.x5),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(
              color: context.scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 36 : 46,
                height: compact ? 36 : 46,
                decoration: BoxDecoration(
                  color: context.scheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(
                  icon,
                  size: compact ? AppIconSizes.sm : AppIconSizes.lg,
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.texts.titleSmall),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      message,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (canOpenSettings) ...[
                const SizedBox(width: AppSpacing.x3),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIconSizes.md,
                  color: context.scheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A lightweight inline notice used above the composer when the assistant is
/// not ready. It reuses the same availability logic as [AiSetupCard].
class AiComposerNotice extends ConsumerWidget {
  const AiComposerNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final keyAsync = ref.watch(aiKeyPresentProvider);
    final models = ref.watch(aiModelsProvider).value ?? const <AiModelInfo>[];
    final availability = resolveAiAvailability(
      settings: settings,
      keyAsync: keyAsync,
      models: models,
    );
    if (availability == AiAvailability.ready ||
        availability == AiAvailability.loading) {
      return const SizedBox.shrink();
    }
    final message = switch (availability) {
      AiAvailability.disabled => l10n.aiDisabledBody,
      AiAvailability.missingKey => l10n.aiNoProviderConfigured,
      AiAvailability.missingModel => l10n.noAiModelSelected,
      _ => '',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: Material(
        color: context.scheme.primary.withValues(alpha: 0.07),
        borderRadius: AppRadius.medium,
        child: InkWell(
          borderRadius: AppRadius.medium,
          onTap: () {
            unawaited(triggerHaptic(ref, cue: HapticCue.selection));
            context.push('/settings/ai');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x3,
              vertical: AppSpacing.x2,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: AppIconSizes.sm,
                  color: context.scheme.primary,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    message,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Text(
                  l10n.openAiSettings,
                  style: context.texts.labelSmall?.copyWith(
                    color: context.scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIconSizes.sm,
                  color: context.scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact empty state for the assistant tab that still offers a next action.
class AiAvailabilityBanner extends StatelessWidget {
  const AiAvailabilityBanner({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: context.scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.scheme.primary, size: AppIconSizes.lg),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.titleSmall),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  body,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.x2),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 34),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading/empty/error body reused by AI history.
class AiEmptyState extends StatelessWidget {
  const AiEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.forum_outlined,
      title: title,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
      compact: true,
    );
  }
}
