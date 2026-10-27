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
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/section_header.dart';
import 'ai_conversation_tile.dart';

/// Local-only AI history. Search runs against SQLite and never calls a remote
/// provider, so history stays usable offline.
class AiHistoryScreen extends ConsumerStatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  ConsumerState<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends ConsumerState<AiHistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  bool _clearing = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final conversations = ref.watch(aiConversationsProvider(_search));
    final hasConversations = conversations.value?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiHistory),
        actions: [
          if (hasConversations)
            IconButton(
              tooltip: l10n.clearHistory,
              onPressed: _clearing ? null : _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x2,
                AppSpacing.x5,
                AppSpacing.x3,
              ),
              child: AppSearchField(
                controller: _searchController,
                hintText: l10n.searchHistory,
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: conversations.when(
                loading: () => const LoadingState(),
                error: (_, _) => ErrorStateView(
                  message: l10n.errorDatabase,
                  onRetry: () =>
                      ref.invalidate(aiConversationsProvider(_search)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.forum_outlined,
                      title: _search.trim().isEmpty
                          ? l10n.noConversations
                          : l10n.searchHistory,
                      body: l10n.noConversationsBody,
                      actionLabel: _search.trim().isEmpty
                          ? l10n.newChat
                          : l10n.clear,
                      onAction: _search.trim().isEmpty
                          ? () {
                              unawaited(
                                triggerHaptic(ref, cue: HapticCue.selection),
                              );
                              context.push('/assistant/chat');
                            }
                          : () {
                              unawaited(
                                triggerHaptic(ref, cue: HapticCue.selection),
                              );
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x5,
                      AppSpacing.x1,
                      AppSpacing.x5,
                      AppSpacing.x8,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.x2),
                    itemBuilder: (context, index) {
                      final conversation = items[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: context.appColors.card,
                          borderRadius: AppRadius.large,
                          border: Border.all(
                            color: context.scheme.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: AiConversationTile(
                          conversation: conversation,
                          showModel: true,
                          onTap: () {
                            unawaited(
                              triggerHaptic(ref, cue: HapticCue.selection),
                            );
                            context.push(
                              '/assistant/chat?conversation=${Uri.encodeComponent(conversation.id)}',
                            );
                          },
                          trailing: IconButton(
                            tooltip: l10n.deleteConversation,
                            onPressed: () => _deleteConversation(conversation),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.localSearchDebounce, () {
      if (!mounted) return;
      setState(() => _search = value.trim());
    });
  }

  Future<void> _deleteConversation(AiConversation conversation) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteConversation,
      message: l10n.deleteConversationBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(aiRepositoryProvider).deleteConversation(conversation.id);
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.conversationDeleted);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.clearHistory,
      message: l10n.clearHistoryBody,
      confirmLabel: l10n.clearAll,
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _clearing = true);
    try {
      await ref.read(aiRepositoryProvider).clearHistory();
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.aiHistoryCleared);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }
}
