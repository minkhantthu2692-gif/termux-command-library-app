import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';
import '../../core/utils/command_risk.dart';
import '../../data/models/command_post.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/haptics_service.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/utils/category_visual.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/avatar_bubble.dart';
import '../../shared/widgets/command_code_block.dart';
import '../../shared/widgets/risk_labels.dart';
import '../../shared/widgets/status_pill.dart';
import '../termux/termux_run_flow.dart';

class CommandDetailsScreen extends ConsumerWidget {
  const CommandDetailsScreen({super.key, required this.commandId});

  final String commandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(commandProvider(commandId));
    return async.when(
      loading: () => AppMessageScaffold(
        title: l10n.commandDetails,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => AppMessageScaffold(
        title: l10n.commandDetails,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x6),
            child: Text(l10n.errorDatabase, textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (command) {
        if (command == null) {
          return AppMessageScaffold(
            title: l10n.commandDetails,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: AppIconSizes.xl,
                      color: context.scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      l10n.guideNotAvailable,
                      style: context.texts.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      l10n.deletedGuide,
                      textAlign: TextAlign.center,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _DetailsView(command: command);
      },
    );
  }
}

enum _DetailAction { copyAll, runAll, askAi, edit, delete }

class _DetailsView extends ConsumerWidget {
  const _DetailsView({required this.command});

  final CommandPost command;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(currentSessionProvider);
    final preferences =
        ref.watch(preferencesProvider).value ?? const UserPreferences();
    final isFavorite = preferences.isFavorite(command.id);
    final isPinned = preferences.isPinned(command.id);
    final canEdit =
        !command.isSeed &&
        (session.isAdmin || session.uid == command.authorUid);
    final risk = CommandRiskAnalyzer.analyze(
      command.steps.map((step) => step.command),
    );
    final visual = CategoryVisual.of(command.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commandDetails),
        actions: [
          IconButton(
            tooltip: isFavorite
                ? l10n.removeFromFavorites
                : l10n.addToFavorites,
            onPressed: () => _toggleFavorite(context, ref, isFavorite),
            icon: Icon(
              isFavorite
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isFavorite ? context.appColors.star : null,
            ),
          ),
          IconButton(
            tooltip: isPinned ? l10n.unpinCommand : l10n.pinCommand,
            onPressed: () => _togglePin(context, ref, isPinned),
            icon: Icon(
              isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            ),
          ),
          PopupMenuButton<_DetailAction>(
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onSelected: (action) => _onAction(context, ref, action, canEdit),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _DetailAction.copyAll,
                child: _MenuRow(
                  icon: Icons.copy_all_rounded,
                  label: l10n.copyAllCommands,
                ),
              ),
              PopupMenuItem(
                value: _DetailAction.runAll,
                child: _MenuRow(
                  icon: Icons.play_circle_outline_rounded,
                  label: l10n.runAllCommands,
                ),
              ),
              PopupMenuItem(
                value: _DetailAction.askAi,
                child: _MenuRow(
                  icon: Icons.auto_awesome_rounded,
                  label: l10n.askAboutCommand,
                ),
              ),
              if (canEdit) ...[
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _DetailAction.edit,
                  child: _MenuRow(icon: Icons.edit_outlined, label: l10n.edit),
                ),
                PopupMenuItem(
                  value: _DetailAction.delete,
                  child: _MenuRow(
                    icon: Icons.delete_outline_rounded,
                    label: l10n.delete,
                    color: context.scheme.error,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x2,
                AppSpacing.x5,
                AppSpacing.x12,
              ),
              sliver: SliverList.list(
                children: [
                  _Header(command: command, visual: visual),
                  const SizedBox(height: AppSpacing.x4),
                  if (command.status == CommandStatus.draft) ...[
                    AppNote(
                      title: l10n.draftBadge,
                      message: l10n.draftSavedLocally,
                      icon: Icons.edit_note_rounded,
                      tone: AppNoteTone.warning,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                  ],
                  if (risk.hasWarnings) ...[
                    AppNote(
                      title: risk.isHigh
                          ? l10n.riskWarningTitle
                          : l10n.riskMedium,
                      message: [
                        l10n.riskWarningBody,
                        for (final reason in risk.reasons)
                          '• ${riskReasonLabel(l10n, reason)}',
                      ].join('\n'),
                      tone: risk.isHigh
                          ? AppNoteTone.danger
                          : AppNoteTone.warning,
                    ),
                    const SizedBox(height: AppSpacing.x4),
                  ],
                  _OverviewCard(command: command),
                  const SizedBox(height: AppSpacing.x6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.stepsTitle,
                          style: context.texts.titleMedium,
                        ),
                      ),
                      Text(
                        l10n.stepCount(command.steps.length),
                        style: context.texts.labelSmall?.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  if (command.steps.isEmpty)
                    AppNote(message: l10n.noSteps, icon: Icons.list_alt_rounded)
                  else
                    for (final step in command.steps) ...[
                      _StepCard(
                        step: step,
                        onCopy: () => copyWithFeedback(
                          context,
                          ref,
                          step.command,
                          message: l10n.stepCommandCopied,
                        ),
                        onRun: () => showTermuxRunFlow(
                          context,
                          ref,
                          label: '${command.name} · ${step.title}',
                          items: [
                            TermuxRunItem(
                              title: step.title,
                              command: step.command,
                              runMode: step.runMode,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3),
                    ],
                  if (command.metadata.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x3),
                    _MetadataCard(metadata: command.metadata),
                  ],
                  const SizedBox(height: AppSpacing.x5),
                  OutlinedButton.icon(
                    onPressed: () {
                      unawaited(triggerHaptic(ref, cue: HapticCue.selection));
                      context.push(
                        '/assistant/chat?command=${Uri.encodeComponent(command.id)}',
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(l10n.explainWithAi),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: command.steps.isEmpty
          ? null
          : _BottomActions(
              onCopy: () => copyWithFeedback(
                context,
                ref,
                command.allCommands,
                message: l10n.allCommandsCopied,
              ),
              onRun: () => _runAll(context, ref),
            ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    bool current,
  ) async {
    final l10n = AppLocalizations.of(context);
    unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
    try {
      await ref
          .read(commandRepositoryProvider)
          .setFavorite(
            session: ref.read(currentSessionProvider),
            commandId: command.id,
            favorite: !current,
          );
      if (context.mounted) {
        context.showSnack(
          !current ? l10n.favoritedSnack : l10n.unfavoritedSnack,
        );
      }
    } catch (error) {
      if (context.mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _togglePin(
    BuildContext context,
    WidgetRef ref,
    bool current,
  ) async {
    final l10n = AppLocalizations.of(context);
    unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
    try {
      await ref
          .read(commandRepositoryProvider)
          .setPinned(
            session: ref.read(currentSessionProvider),
            commandId: command.id,
            pinned: !current,
          );
      if (context.mounted) {
        context.showSnack(!current ? l10n.pinnedSnack : l10n.unpinnedSnack);
      }
    } catch (error) {
      if (context.mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _runAll(BuildContext context, WidgetRef ref) {
    return showTermuxRunFlow(
      context,
      ref,
      label: command.name,
      items: [
        for (final step in command.steps)
          TermuxRunItem(
            title: step.title,
            command: step.command,
            runMode: step.runMode,
          ),
      ],
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _DetailAction action,
    bool canEdit,
  ) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _DetailAction.copyAll:
        await copyWithFeedback(
          context,
          ref,
          command.allCommands,
          message: l10n.allCommandsCopied,
        );
      case _DetailAction.runAll:
        await _runAll(context, ref);
      case _DetailAction.askAi:
        unawaited(triggerHaptic(ref, cue: HapticCue.selection));
        context.push(
          '/assistant/chat?command=${Uri.encodeComponent(command.id)}',
        );
      case _DetailAction.edit:
        if (canEdit) {
          unawaited(triggerHaptic(ref, cue: HapticCue.selection));
          context.push('/command/${command.id}/edit');
        }
      case _DetailAction.delete:
        if (!canEdit) return;
        final confirmed = await showConfirmDialog(
          context,
          title: l10n.deleteCommandTitle,
          message: l10n.deleteCommandBody,
          confirmLabel: l10n.delete,
          destructive: true,
        );
        if (!confirmed || !context.mounted) return;
        try {
          await ref
              .read(commandRepositoryProvider)
              .deletePost(
                session: ref.read(currentSessionProvider),
                commandId: command.id,
              );
          if (context.mounted) {
            unawaited(triggerHaptic(ref, cue: HapticCue.success));
            context.showSnack(l10n.commandDeleted);
            context.pop();
          }
        } catch (error) {
          if (context.mounted) context.showErrorSnack(error);
        }
    }
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppIconSizes.sm, color: color),
        const SizedBox(width: AppSpacing.x2),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.command, required this.visual});

  final CommandPost command;
  final CategoryVisual visual;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                visual.icon,
                color: visual.color,
                size: AppIconSizes.md,
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Text(
                categoryLabel(l10n, command.categoryId),
                style: context.texts.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            CommandStatusPills(
              status: command.status,
              isSeed: command.isSeed,
              isPendingSync: command.isPendingSync,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(command.name, style: context.texts.headlineSmall),
        if (command.description.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x3),
          Text(
            command.description,
            style: context.texts.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x4),
        Row(
          children: [
            AvatarBubble(avatarId: AppAvatars.defaultId, size: 30),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.isSeed
                        ? l10n.curatedBy
                        : l10n.byAuthor(
                            command.authorNickname.trim().isEmpty
                                ? l10n.member
                                : command.authorNickname,
                          ),
                    style: context.texts.labelMedium,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    l10n.updatedTime(
                      AppFormatters.relativeTime(
                        context,
                        l10n,
                        command.updatedAt,
                      ),
                    ),
                    style: context.texts.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.command});

  final CommandPost command;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    final items = <(IconData, String, String)>[
      (Icons.layers_outlined, l10n.steps, l10n.stepCount(command.stepCount)),
      (Icons.verified_outlined, l10n.version, '${command.version}'),
      (
        Icons.calendar_today_outlined,
        l10n.updatedTime(''),
        AppFormatters.shortDate(context, command.updatedAt),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (command.tags.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.x1,
              runSpacing: AppSpacing.x1,
              children: [
                for (final tag in command.tags) StatusPill(label: '#$tag'),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
          ],
          for (var index = 0; index < items.length; index++) ...[
            Row(
              children: [
                Icon(
                  items[index].$1,
                  size: AppIconSizes.sm,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    items[index].$2.trim(),
                    style: context.texts.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(items[index].$3, style: context.texts.labelMedium),
              ],
            ),
            if (index < items.length - 1) ...[
              const SizedBox(height: AppSpacing.x2),
              Divider(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
                height: 1,
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
          ],
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.onCopy,
    required this.onRun,
  });

  final CommandStep step;
  final VoidCallback onCopy;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${step.order + 1}',
                  style: context.texts.labelSmall?.copyWith(
                    color: context.scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(step.title, style: context.texts.titleSmall),
              ),
              StatusPill(
                label: step.runMode == CommandRunMode.background
                    ? l10n.runModeBackground
                    : l10n.runModeForeground,
                tone: step.runMode == CommandRunMode.background
                    ? StatusPillTone.neutral
                    : StatusPillTone.primary,
              ),
            ],
          ),
          if (step.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              step.description,
              style: context.texts.bodySmall?.copyWith(
                color: context.scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x3),
          CommandCodeBlock(
            command: step.command,
            label: l10n.stepNumber(step.order + 1),
            onCopy: onCopy,
            onRun: onRun,
          ),
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.metadata});

  final Map<String, String> metadata;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: context.appColors.cardMuted,
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.metadata, style: context.texts.titleSmall),
          const SizedBox(height: AppSpacing.x2),
          for (final entry in metadata.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      entry.key,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(entry.value, style: context.texts.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onCopy, required this.onRun});

  final VoidCallback onCopy;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x5,
          AppSpacing.x3,
          AppSpacing.x5,
          AppSpacing.x3,
        ),
        decoration: BoxDecoration(
          color: context.appColors.glassTint,
          border: Border(
            top: BorderSide(
              color: context.scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_all_rounded),
                label: Text(l10n.copyAllCommands),
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: FilledButton.icon(
                onPressed: onRun,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.runAllCommands),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
