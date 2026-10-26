import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/user_profile.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/avatar_bubble.dart';
import '../../shared/widgets/settings_tiles.dart';
import '../../shared/widgets/status_pill.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(currentSessionProvider);
    final profile = ref.watch(profileProvider).value;
    final stats = ref.watch(libraryStatsProvider).value ?? const LibraryStats();
    final preferences =
        ref.watch(preferencesProvider).value ?? const UserPreferences();
    final cloudConfigured = ref.watch(
      appDependenciesProvider.select((deps) => deps.cloudConfigured),
    );
    final name = profile?.effectiveNickname ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        if (cloudConfigured) {
          try {
            await ref.read(syncCoordinatorProvider).refresh();
          } catch (error) {
            if (context.mounted) context.showErrorSnack(error);
          }
        }
      },
      child: CustomScrollView(
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
                          l10n.profile,
                          style: context.texts.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.settings,
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _ProfileHeader(
                    name: name.isEmpty ? l10n.guest : name,
                    email: profile?.email ?? session.email ?? '',
                    avatarId: profile?.avatarId ?? AppAvatars.defaultId,
                    role: _roleLabel(l10n, session),
                    memberSince: profile == null
                        ? null
                        : AppFormatters.monthYear(context, profile.createdAt),
                    isAdmin: session.isAdmin,
                    isAnonymous: session.isAnonymous,
                    isLocalOnly: session.isLocalOnly,
                    onEdit: () => context.push('/profile/edit'),
                  ),
                  if (cloudConfigured && session.isAnonymous) ...[
                    const SizedBox(height: AppSpacing.x4),
                    AppNote(
                      title: l10n.anonymousAccount,
                      message: l10n.anonymousExplanation,
                      tone: AppNoteTone.info,
                      actionLabel: l10n.upgradeAccount,
                      onAction: () => context.push('/auth/register'),
                    ),
                  ] else if (!cloudConfigured) ...[
                    const SizedBox(height: AppSpacing.x4),
                    AppNote(
                      title: l10n.localOnly,
                      message: l10n.cloudUnavailableBody,
                      tone: AppNoteTone.neutral,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x5),
                  _StatsRow(
                    stats: stats,
                    onMine: () => context.go('/library?tab=mine'),
                    onFavorites: () => context.go('/library?tab=favorites'),
                    onPins: () => context.go('/library?tab=pinned'),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  SettingsGroup(
                    title: l10n.myCollection,
                    children: [
                      SettingsTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: l10n.myGuides,
                        subtitle: l10n.myPostsCount,
                        onTap: () => context.go('/library?tab=mine'),
                        trailing: _CountBadge(value: stats.mine),
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.bookmark_outline_rounded),
                        title: l10n.favorites,
                        subtitle: l10n.emptyFavoritesBody,
                        onTap: () => context.go('/library?tab=favorites'),
                        trailing: _CountBadge(value: stats.favorites),
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.push_pin_outlined),
                        title: l10n.pinned,
                        subtitle: l10n.pinnedCommands,
                        onTap: () => context.go('/library?tab=pinned'),
                        trailing: _CountBadge(value: stats.pins),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  SettingsGroup(
                    title: l10n.accountAndSync,
                    children: [
                      SettingsTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: l10n.editProfile,
                        onTap: () => context.push('/profile/edit'),
                      ),
                      if (session.isRegistered)
                        SettingsTile(
                          leading: const Icon(Icons.lock_outline_rounded),
                          title: l10n.securitySettings,
                          subtitle: l10n.updatePassword,
                          onTap: () => context.push('/profile/password'),
                        ),
                      if (session.isAnonymous)
                        SettingsTile(
                          leading: const Icon(Icons.person_add_alt_rounded),
                          title: l10n.upgradeAccount,
                          subtitle: l10n.upgradeAccountBody,
                          onTap: () => context.push('/auth/register'),
                        ),
                      SettingsTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: l10n.settings,
                        subtitle: l10n.settingsSubtitle,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  SettingsGroup(
                    title: l10n.aiAssistant,
                    children: [
                      SettingsTile(
                        leading: const Icon(Icons.auto_awesome_rounded),
                        title: l10n.aiAssistant,
                        subtitle: l10n.aiAssistantSubtitle,
                        onTap: () => context.go('/assistant'),
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.history_rounded),
                        title: l10n.chatHistory,
                        subtitle: l10n.aiHistory,
                        onTap: () => context.push('/ai/history'),
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.key_outlined),
                        title: l10n.aiSettings,
                        subtitle: l10n.aiProviderGroq,
                        onTap: () => context.push('/settings/ai'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  SettingsGroup(
                    title: l10n.about,
                    children: [
                      SettingsTile(
                        leading: const Icon(Icons.terminal_rounded),
                        title: l10n.termuxGuide,
                        onTap: () => context.push('/termux-guide'),
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.help_outline_rounded),
                        title: l10n.documentation,
                        subtitle: l10n.firebaseSetupDocs,
                        onTap: () => context.push('/docs'),
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
                  const SizedBox(height: AppSpacing.x5),
                  if (!cloudConfigured)
                    Text(
                      l10n.localProfileBody,
                      textAlign: TextAlign.center,
                      style: context.texts.labelSmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.x4),
                  if (preferences.pinnedIds.isNotEmpty)
                    Text(
                      l10n.pinnedCommands,
                      textAlign: TextAlign.center,
                      style: context.texts.labelSmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(AppLocalizations l10n, AuthSession session) {
    if (session.isAdmin) return l10n.admin;
    if (session.isRegistered) return l10n.member;
    return l10n.guest;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.avatarId,
    required this.role,
    required this.memberSince,
    required this.isAdmin,
    required this.isAnonymous,
    required this.isLocalOnly,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String avatarId;
  final String role;
  final String? memberSince;
  final bool isAdmin;
  final bool isAnonymous;
  final bool isLocalOnly;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarBubble(avatarId: avatarId, size: 68, showBorder: true),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleLarge,
                    ),
                    if (email.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.x2),
                    Wrap(
                      spacing: AppSpacing.x1,
                      runSpacing: AppSpacing.x1,
                      children: [
                        StatusPill(
                          label: role,
                          icon: isAdmin
                              ? Icons.shield_rounded
                              : isAnonymous
                              ? Icons.person_outline_rounded
                              : Icons.verified_user_outlined,
                          tone: isAdmin
                              ? StatusPillTone.warning
                              : StatusPillTone.primary,
                        ),
                        if (isLocalOnly)
                          StatusPill(
                            label: l10n.localOnly,
                            icon: Icons.smartphone_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.editProfile,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          if (memberSince != null) ...[
            const SizedBox(height: AppSpacing.x3),
            Text(
              l10n.memberSince(memberSince!),
              style: context.texts.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: context.appColors.cardMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        AppFormatters.compactCount(value),
        style: context.texts.labelSmall?.copyWith(
          color: context.scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.stats,
    required this.onMine,
    required this.onFavorites,
    required this.onPins,
  });

  final LibraryStats stats;
  final VoidCallback onMine;
  final VoidCallback onFavorites;
  final VoidCallback onPins;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = [
      (l10n.myPosts, stats.mine, Icons.description_outlined, onMine),
      (
        l10n.favorites,
        stats.favorites,
        Icons.bookmark_border_rounded,
        onFavorites,
      ),
      (l10n.pinned, stats.pins, Icons.push_pin_outlined, onPins),
    ];
    return Row(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          Expanded(
            child: Material(
              color: context.appColors.cardMuted,
              borderRadius: AppRadius.medium,
              child: InkWell(
                borderRadius: AppRadius.medium,
                onTap: entries[index].$4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x2,
                    vertical: AppSpacing.x3,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        entries[index].$3,
                        size: AppIconSizes.sm,
                        color: context.scheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        AppFormatters.compactCount(entries[index].$2),
                        style: context.texts.titleMedium,
                      ),
                      Text(
                        entries[index].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.labelSmall?.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (index < entries.length - 1) const SizedBox(width: AppSpacing.x2),
        ],
      ],
    );
  }
}
