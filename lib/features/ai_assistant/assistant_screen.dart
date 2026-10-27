import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/ai_models.dart';
import '../../data/services/haptics_service.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/section_header.dart';
import 'ai_conversation_tile.dart';
import 'ai_setup_card.dart';

/// Assistant tab. It is a calm entry point rather than a second settings screen:
/// availability, suggested prompts and recent local conversations are visible
/// in one scroll, and the actual conversation opens on its own route.
class AssistantScreen extends ConsumerWidget {
  const AssistantScreen({super.key});

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
    final ready = availability == AiAvailability.ready;
    AiModelInfo? selectedModel;
    for (final model in models) {
      if (model.id == settings.aiModelId) selectedModel = model;
    }
    final recent = ref.watch(aiConversationsProvider(''));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x4,
              AppSpacing.x5,
              AppSpacing.x12,
            ),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.aiAssistant,
                        style: context.texts.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.chatHistory,
                      onPressed: () {
                        unawaited(triggerHaptic(ref, cue: HapticCue.selection));
                        context.push('/ai/history');
                      },
                      icon: const Icon(Icons.history_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x3),
                if (ready)
                  _AssistantHero(
                    modelName: selectedModel?.displayName ?? settings.aiModelId,
                    onNewChat: () {
                      unawaited(triggerHaptic(ref, cue: HapticCue.selection));
                      context.push('/assistant/chat');
                    },
                  )
                else
                  const AiSetupCard(),
                const SizedBox(height: AppSpacing.x5),
                if (ready) ...[
                  SectionHeader(
                    title: l10n.suggestions,
                    subtitle: l10n.aiAssistantSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _SuggestionGrid(
                    onSelected: (prompt) {
                      unawaited(triggerHaptic(ref, cue: HapticCue.selection));
                      final location = Uri(
                        path: '/assistant/chat',
                        queryParameters: {'prompt': prompt},
                      ).toString();
                      context.push(location);
                    },
                  ),
                  const SizedBox(height: AppSpacing.x6),
                ],
                SectionHeader(
                  title: l10n.recentConversations,
                  actionLabel: l10n.seeAll,
                  onAction: () {
                    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
                    context.push('/ai/history');
                  },
                ),
                const SizedBox(height: AppSpacing.x3),
                recent.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.x5),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  ),
                  error: (_, _) => EmptyState(
                    icon: Icons.forum_outlined,
                    title: l10n.somethingWentWrong,
                    body: l10n.errorDatabase,
                    compact: true,
                  ),
                  data: (conversations) {
                    if (conversations.isEmpty) {
                      return EmptyState(
                        icon: Icons.forum_outlined,
                        title: l10n.noConversations,
                        body: l10n.noConversationsBody,
                        actionLabel: ready ? l10n.newChat : null,
                        onAction: ready
                            ? () {
                                unawaited(
                                  triggerHaptic(ref, cue: HapticCue.selection),
                                );
                                context.push('/assistant/chat');
                              }
                            : null,
                        compact: true,
                      );
                    }
                    return _ConversationList(
                      conversations: conversations
                          .take(4)
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.x5),
                AppNote(
                  title: l10n.localOnly,
                  message: l10n.aiPrivacyNote,
                  icon: Icons.lock_outline_rounded,
                  tone: AppNoteTone.neutral,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AssistantHero extends StatelessWidget {
  const _AssistantHero({required this.modelName, required this.onNewChat});

  final String modelName;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(size: 46, showShadow: true),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.aiWelcomeTitle, style: context.texts.titleLarge),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      l10n.aiWelcomeBody,
                      style: context.texts.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Row(
            children: [
              Expanded(
                child: _ModelPill(
                  label: modelName.isEmpty ? l10n.aiModel : modelName,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              FilledButton.icon(
                onPressed: onNewChat,
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                label: Text(l10n.newChat),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionGrid extends StatelessWidget {
  const _SuggestionGrid({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <(IconData, String)>[
      (Icons.menu_book_outlined, l10n.suggestionExplain),
      (Icons.build_circle_outlined, l10n.suggestionFix),
      (Icons.terminal_rounded, l10n.suggestionScript),
      (Icons.translate_rounded, l10n.suggestionTranslate),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 560;
        final width = twoColumns
            ? (constraints.maxWidth - AppSpacing.x2) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _SuggestionCard(
                  icon: item.$1,
                  label: item.$2,
                  onTap: () => onSelected(item.$2),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.card,
      borderRadius: AppRadius.medium,
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x3),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: context.scheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: AppIconSizes.sm, color: context.scheme.primary),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppIconSizes.sm,
                color: context.scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationList extends ConsumerWidget {
  const _ConversationList({required this.conversations});

  final List<AiConversation> conversations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x2),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: context.scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < conversations.length; index++) ...[
            AiConversationTile(
              conversation: conversations[index],
              onTap: () {
                unawaited(triggerHaptic(ref, cue: HapticCue.selection));
                context.push(
                  '/assistant/chat?conversation=${Uri.encodeComponent(conversations[index].id)}',
                );
              },
            ),
            if (index < conversations.length - 1)
              const SizedBox(height: AppSpacing.x1),
          ],
        ],
      ),
    );
  }
}

class _ModelPill extends StatelessWidget {
  const _ModelPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: context.scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.memory_rounded,
            size: AppIconSizes.xs,
            color: context.scheme.primary,
          ),
          const SizedBox(width: AppSpacing.x1),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall?.copyWith(
                color: context.scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
