import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/providers.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/models/command_category.dart';
import '../../../data/models/command_post.dart';
import '../../../data/models/command_query.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/haptics_service.dart';
import '../../../shared/utils/app_formatters.dart';
import '../../../shared/utils/category_visual.dart';
import '../../../shared/utils/ui_actions.dart';
import '../../../shared/widgets/avatar_bubble.dart';
import '../../../shared/widgets/command_card.dart';
import '../../../shared/widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final session = ref.watch(currentSessionProvider);
    final profile = ref.watch(profileProvider).value;
    final preferences =
        ref.watch(preferencesProvider).value ?? const UserPreferences();
    final stats = ref.watch(libraryStatsProvider).value ?? const LibraryStats();
    final pinned = ref.watch(pinnedCommandsProvider).value ?? const [];
    final categories =
        ref.watch(categoryCountsProvider).value ?? const <CategoryCount>[];
    final recent = ref.watch(
      commandsProvider(
        const CommandListQuery(limit: 5, sort: CommandSort.recentlyUpdated),
      ),
    );
    final cloudConfigured = ref.watch(
      appDependenciesProvider.select((deps) => deps.cloudConfigured),
    );
    final syncStatus = ref.watch(syncStatusProvider).value;
    final name = profile?.effectiveNickname.trim() ?? '';
    // The shell extends the body behind the frosted navigation bar, so reserve
    // its height at the end of the scroll extent.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: () => _refresh(context, ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x4,
                AppSpacing.x5,
                AppSpacing.x6 + bottomInset,
              ),
              sliver: SliverList.list(
                children: [
                  _Header(
                    name: name.isEmpty ? l10n.guest : name,
                    avatarId:
                        profile?.displayAvatarId ?? AppAvatars.localOnlyId,
                    onProfile: () => context.go('/profile'),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  _SearchTrigger(
                    hint: l10n.searchCommands,
                    onTap: () => context.go('/library?focus=1'),
                  ),
                  if (!cloudConfigured) ...[
                    const SizedBox(height: AppSpacing.x3),
                    _LocalOnlyNote(
                      title: l10n.localOnly,
                      body: l10n.cloudUnavailableBody,
                      onTap: () => context.push('/docs'),
                    ),
                  ] else if (session.isAnonymous) ...[
                    const SizedBox(height: AppSpacing.x3),
                    _GuestNote(onSignIn: () => context.push('/auth/sign-in')),
                  ],
                  if (syncStatus?.phase == SyncPhase.error) ...[
                    const SizedBox(height: AppSpacing.x3),
                    _SyncErrorNote(onRetry: () => _refresh(context, ref)),
                  ],
                  const SizedBox(height: AppSpacing.x6),
                  SectionHeader(
                    title: l10n.quickActions,
                    actionLabel: l10n.seeAll,
                    onAction: () => context.go('/library'),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _QuickActions(
                    onBrowse: () => context.go('/library'),
                    onShare: () => _openUpload(context, ref),
                    onAi: () => context.go('/assistant'),
                    onTermux: () => context.push('/termux-guide'),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  _StatsStrip(
                    stats: stats,
                    onCommands: () => context.go('/library'),
                    onFavorites: () => context.go('/library?tab=favorites'),
                    onPins: () => context.go('/library?tab=pinned'),
                    onMine: () {
                      if (session.canPublish) {
                        context.go('/library?tab=mine');
                      } else {
                        context.push(
                          '/auth/sign-in?next=%2Flibrary%3Ftab%3Dmine',
                        );
                      }
                    },
                  ),
                  if (pinned.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x6),
                    SectionHeader(
                      title: l10n.pinnedCommands,
                      actionLabel: l10n.seeAll,
                      onAction: () => context.go('/library?tab=pinned'),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pinned.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.x3),
                        itemBuilder: (context, index) {
                          final command = pinned[index];
                          return _PinnedCard(
                            command: command,
                            onTap: () => context.push('/command/${command.id}'),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x6),
                  SectionHeader(
                    title: l10n.exploreCategories,
                    actionLabel: l10n.allCategories,
                    onAction: () => context.go('/library'),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _CategoryStrip(
                    counts: categories,
                    onSelected: (id) => context.go(
                      '/library?category=${Uri.encodeComponent(id)}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  SectionHeader(
                    title: l10n.recentCommands,
                    actionLabel: l10n.seeAll,
                    onAction: () => context.go('/library'),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  ...recent.when(
                    data: (commands) {
                      if (commands.isEmpty) {
                        return [
                          EmptyState(
                            icon: Icons.menu_book_outlined,
                            title: l10n.noCommandsTitle,
                            body: l10n.noCommandsBody,
                            actionLabel: l10n.browseLibrary,
                            onAction: () => context.go('/library'),
                            compact: true,
                          ),
                        ];
                      }
                      return [
                        for (
                          var index = 0;
                          index < commands.length;
                          index++
                        ) ...[
                          CommandCard(
                            command: commands[index],
                            preferences: preferences,
                            onTap: () =>
                                context.push('/command/${commands[index].id}'),
                            onFavorite: () => _toggleFavorite(
                              context,
                              ref,
                              session,
                              preferences,
                              commands[index],
                            ),
                            onPin: () => _togglePin(
                              context,
                              ref,
                              session,
                              preferences,
                              commands[index],
                            ),
                          ),
                          if (index < commands.length - 1)
                            const SizedBox(height: AppSpacing.x2 + 2),
                        ],
                      ];
                    },
                    loading: () => [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.x6),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ],
                    error: (error, _) => [
                      ErrorStateView(
                        message: l10n.errorDatabase,
                        onRetry: () => ref.invalidate(
                          commandsProvider(
                            const CommandListQuery(
                              limit: 5,
                              sort: CommandSort.recentlyUpdated,
                            ),
                          ),
                        ),
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  Text(
                    l10n.seedDisclaimer,
                    textAlign: TextAlign.center,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                  if (settings.effectiveLanguageCode == 'my')
                    const SizedBox(height: AppSpacing.x2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final deps = ref.read(appDependenciesProvider);
    if (!deps.cloudConfigured) {
      context.showSnack(l10n.localOnly);
      return;
    }
    try {
      await ref.read(syncCoordinatorProvider).refresh();
      unawaited(triggerHaptic(ref, cue: HapticCue.success));
      if (context.mounted) context.showSnack(l10n.refreshed);
    } catch (error) {
      if (context.mounted) context.showErrorSnack(error);
    }
  }

  void _openUpload(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.read(currentSessionProvider);
    final cloudConfigured = ref.read(appDependenciesProvider).cloudConfigured;
    if (!cloudConfigured) {
      context.showSnack(l10n.cloudUnavailableBody);
      return;
    }
    if (!session.canPublish) {
      context.push('/auth/sign-in?next=%2Fupload');
      return;
    }
    context.push('/upload');
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    AuthSession session,
    UserPreferences preferences,
    CommandSummary command,
  ) async {
    final l10n = AppLocalizations.of(context);
    final next = !preferences.isFavorite(command.id);
    unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
    try {
      await ref
          .read(commandRepositoryProvider)
          .setFavorite(session: session, commandId: command.id, favorite: next);
      if (context.mounted) {
        context.showSnack(next ? l10n.favoritedSnack : l10n.unfavoritedSnack);
      }
    } catch (error) {
      if (context.mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _togglePin(
    BuildContext context,
    WidgetRef ref,
    AuthSession session,
    UserPreferences preferences,
    CommandSummary command,
  ) async {
    final l10n = AppLocalizations.of(context);
    final next = !preferences.isPinned(command.id);
    unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
    try {
      await ref
          .read(commandRepositoryProvider)
          .setPinned(session: session, commandId: command.id, pinned: next);
      if (context.mounted) {
        context.showSnack(next ? l10n.pinnedSnack : l10n.unpinnedSnack);
      }
    } catch (error) {
      if (context.mounted) context.showErrorSnack(error);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.avatarId,
    required this.onProfile,
  });

  final String name;
  final String avatarId;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeGreeting(name),
                style: context.texts.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                l10n.homeSubtitle,
                style: context.texts.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onProfile,
          child: AvatarBubble(avatarId: avatarId, size: 42),
        ),
      ],
    );
  }
}

class _SearchTrigger extends StatelessWidget {
  const _SearchTrigger({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Material(
      color: context.appColors.cardMuted,
      borderRadius: AppRadius.medium,
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x3 + 2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: AppIconSizes.md,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  hint,
                  style: context.texts.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.tune_rounded,
                size: AppIconSizes.sm,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalOnlyNote extends StatelessWidget {
  const _LocalOnlyNote({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    return InkWell(
      borderRadius: AppRadius.medium,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x3),
        decoration: BoxDecoration(
          color: palette.cardMuted,
          borderRadius: AppRadius.medium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: AppIconSizes.sm,
              color: context.scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    maxLines: 3,
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
    );
  }
}

class _GuestNote extends StatelessWidget {
  const _GuestNote({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x2,
        AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: AppRadius.medium,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: AppIconSizes.sm,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              l10n.guestSignInHint,
              style: context.texts.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: onSignIn,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
            ),
            child: Text(l10n.signIn),
          ),
        ],
      ),
    );
  }
}

class _SyncErrorNote extends StatelessWidget {
  const _SyncErrorNote({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.32),
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: AppIconSizes.sm,
            color: scheme.error,
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              l10n.syncError,
              style: context.texts.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(minimumSize: const Size(0, 34)),
            child: Text(l10n.errorBannerRetry),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBrowse,
    required this.onShare,
    required this.onAi,
    required this.onTermux,
  });

  final VoidCallback onBrowse;
  final VoidCallback onShare;
  final VoidCallback onAi;
  final VoidCallback onTermux;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 360;
        final width = twoColumns
            ? (constraints.maxWidth - AppSpacing.x3) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.x3,
          runSpacing: AppSpacing.x3,
          children: [
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.menu_book_rounded,
                label: l10n.browseLibrary,
                color: const Color(0xFF4F5BD5),
                onTap: onBrowse,
              ),
            ),
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.add_circle_outline_rounded,
                label: l10n.shareGuide,
                color: const Color(0xFF0E8576),
                onTap: onShare,
              ),
            ),
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.auto_awesome_rounded,
                label: l10n.aiAssistant,
                color: const Color(0xFF7651C9),
                onTap: onAi,
              ),
            ),
            SizedBox(
              width: width,
              child: _ActionTile(
                icon: Icons.terminal_rounded,
                label: l10n.termuxGuide,
                color: const Color(0xFFB27815),
                onTap: onTermux,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends ConsumerWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: context.appColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(
          color: context.scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: () {
          unawaited(triggerHaptic(ref, cue: HapticCue.tap));
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x3,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: AppIconSizes.sm, color: color),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.stats,
    required this.onCommands,
    required this.onFavorites,
    required this.onPins,
    required this.onMine,
  });

  final LibraryStats stats;
  final VoidCallback onCommands;
  final VoidCallback onFavorites;
  final VoidCallback onPins;
  final VoidCallback onMine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (l10n.totalCommands, stats.total, Icons.terminal_rounded, onCommands),
      (
        l10n.favoritesCount,
        stats.favorites,
        Icons.bookmark_rounded,
        onFavorites,
      ),
      (l10n.pinsCount, stats.pins, Icons.push_pin_rounded, onPins),
      (l10n.myPostsCount, stats.mine, Icons.description_outlined, onMine),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.x2 * 3) / 4;
        return Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              SizedBox(
                width: itemWidth,
                child: _StatTile(
                  label: items[index].$1,
                  value: items[index].$2,
                  icon: items[index].$3,
                  onTap: items[index].$4,
                ),
              ),
              if (index < items.length - 1)
                const SizedBox(width: AppSpacing.x2),
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Material(
      color: context.appColors.cardMuted,
      borderRadius: AppRadius.medium,
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x3,
          ),
          child: Column(
            children: [
              Icon(icon, size: AppIconSizes.sm, color: scheme.primary),
              const SizedBox(height: AppSpacing.x2),
              Text(
                AppFormatters.compactCount(value),
                style: context.texts.headlineSmall?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.command, required this.onTap});

  final CommandSummary command;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = CategoryVisual.of(command.categoryId);
    return SizedBox(
      width: 250,
      child: Material(
        color: context.appColors.card,
        borderRadius: AppRadius.medium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(
            color: context.scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.medium,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    visual.icon,
                    size: AppIconSizes.sm,
                    color: visual.color,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        command.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.stepCount(command.stepCount),
                        style: context.texts.labelSmall?.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.counts, required this.onSelected});

  final List<CategoryCount> counts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final available = counts.where((c) => c.count > 0).toList();
    final items = available.isEmpty
        ? [for (final category in CommandCategories.all) (category.id, 0)]
        : [for (final count in available) (count.categoryId, count.count)];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x2),
        itemBuilder: (context, index) {
          final (id, count) = items[index];
          final visual = CategoryVisual.of(id);
          return ActionChip(
            avatar: Icon(
              visual.icon,
              size: AppIconSizes.sm,
              color: visual.color,
            ),
            label: Text(
              count > 0
                  ? '${categoryLabel(l10n, id)} · $count'
                  : categoryLabel(l10n, id),
            ),
            onPressed: () => onSelected(id),
            side: BorderSide(
              color: context.scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            backgroundColor: context.appColors.card,
          );
        },
      ),
    );
  }
}
