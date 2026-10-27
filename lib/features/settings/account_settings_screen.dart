import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/haptics_service.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/avatar_bubble.dart';
import '../../shared/widgets/settings_tiles.dart';
import '../../shared/widgets/status_pill.dart';

/// Account management intentionally separates local cache clearing, local guest
/// removal, sign out, and permanent cloud-account deletion.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(currentSessionProvider);
    final profile = ref.watch(profileProvider).value;
    final cloudConfigured = ref.watch(
      appDependenciesProvider.select((deps) => deps.cloudConfigured),
    );

    return AppPage(
      title: l10n.account,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AccountHeader(
            session: session,
            nickname: profile?.effectiveNickname ?? '',
            email: profile?.email ?? session.email ?? '',
            avatarId: profile?.displayAvatarId ?? AppAvatars.localOnlyId,
          ),
          const SizedBox(height: AppSpacing.x4),
          if (!cloudConfigured)
            AppNote(
              title: l10n.localOnly,
              message: l10n.cloudUnavailableBody,
              tone: AppNoteTone.warning,
            )
          else if (session.isAnonymous)
            AppNote(
              title: l10n.anonymousAccount,
              message: l10n.anonymousExplanation,
              tone: AppNoteTone.info,
              actionLabel: l10n.upgradeAccount,
              onAction: () => context.push('/auth/register'),
            ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.securitySettings,
            children: [
              SettingsValueTile(
                title: l10n.email,
                value: (profile?.email ?? session.email ?? '').trim().isEmpty
                    ? l10n.emailOptionalForGuest
                    : (profile?.email ?? session.email!),
                leading: const Icon(Icons.alternate_email_rounded),
              ),
              if (session.isRegistered)
                SettingsTile(
                  leading: const Icon(Icons.lock_reset_rounded),
                  title: l10n.updatePassword,
                  subtitle: l10n.reauthenticateNeeded,
                  onTap: () => context.push('/profile/password'),
                ),
              if (cloudConfigured && !session.isLocalOnly)
                SettingsTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: l10n.refreshRole,
                  subtitle: l10n.refreshRoleBody,
                  onTap: _busy ? null : _refreshRole,
                ),
              if (session.isAnonymous && cloudConfigured)
                SettingsTile(
                  leading: const Icon(Icons.person_add_alt_rounded),
                  title: l10n.upgradeAccount,
                  subtitle: l10n.upgradeAccountBody,
                  onTap: () => context.push('/auth/register'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.dataAndStorage,
            children: [
              SettingsTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: l10n.clearLocalData,
                subtitle: l10n.clearLocalDataBodySafe,
                onTap: _busy ? null : _clearLocalData,
              ),
              if (session.isLocalOnly)
                SettingsTile(
                  leading: const Icon(Icons.person_remove_outlined),
                  title: l10n.deleteLocalProfile,
                  subtitle: l10n.deleteProfileBody,
                  destructive: true,
                  onTap: _busy ? null : _removeLocalProfile,
                ),
              SettingsTile(
                leading: const Icon(Icons.history_rounded),
                title: l10n.clearHistory,
                subtitle: l10n.clearHistoryBody,
                onTap: _busy ? null : _clearAiHistory,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          SettingsGroup(
            title: l10n.account,
            children: [
              if (!session.isLocalOnly)
                SettingsTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: l10n.signOut,
                  subtitle: l10n.syncOnSignIn,
                  onTap: _busy ? null : _signOut,
                ),
              if (cloudConfigured && !session.isLocalOnly)
                SettingsTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: l10n.deleteAccount,
                  subtitle: l10n.deleteAccountBody,
                  destructive: true,
                  onTap: _busy ? null : _deleteAccount,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          AppNote(
            message: l10n.syncSecretsNote,
            tone: AppNoteTone.neutral,
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            l10n.guestDataNote,
            textAlign: TextAlign.center,
            style: context.texts.labelSmall?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshRole() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).refreshIdentityClaims();
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.roleRefreshed);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearLocalData() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.clearLocalDataTitle,
      message: l10n.clearLocalDataBodySafe,
      confirmLabel: l10n.clearAll,
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      final session = ref.read(currentSessionProvider);
      await ref.read(commandRepositoryProvider).clearRemoteCache(session.uid);
      final ai = ref.read(aiRepositoryProvider);
      await ai.clearHistory();
      await ai.clearCache();
      ref.invalidate(cachedCommandCountProvider);
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.clearDataSuccess);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeLocalProfile() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteProfileTitle,
      message: l10n.deleteProfileBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      final session = ref.read(currentSessionProvider);
      await ref
          .read(profileRepositoryProvider)
          .clearLocalAccountData(uid: session.uid, localOnly: true);
      ref.invalidate(cachedCommandCountProvider);
      if (mounted) {
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.clearDataSuccess);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearAiHistory() async {
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

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.signOutTitle,
      message: l10n.signOutBody,
      confirmLabel: l10n.signOut,
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.success));
      context.showSnack(l10n.signedOutLocally);
      context.go('/home');
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final session = ref.read(currentSessionProvider);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteAccountTitle,
      message: l10n.deleteAccountBody,
      confirmLabel: l10n.deleteAccountConfirm,
      destructive: true,
    );
    if (!confirmed) return;

    String? password;
    if (!session.isAnonymous) {
      password = await _askForPassword();
      if (password == null) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount(password: password);
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.success));
      context.showSnack(l10n.accountDeleted);
      context.go('/home');
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askForPassword() {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reauthenticateNeeded),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.currentPassword,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(controller.text);
              }
            },
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.session,
    required this.nickname,
    required this.email,
    required this.avatarId,
  });

  final AuthSession session;
  final String nickname;
  final String email;
  final String avatarId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = session.isAdmin
        ? l10n.admin
        : session.isRegistered
        ? l10n.member
        : l10n.guest;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: context.scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          AvatarBubble(avatarId: avatarId, size: 58, showBorder: true),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname.trim().isEmpty ? l10n.guest : nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleMedium,
                ),
                if (email.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.signedInAs(email),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
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
                      icon: session.isAdmin
                          ? Icons.shield_rounded
                          : Icons.person_outline_rounded,
                      tone: session.isAdmin
                          ? StatusPillTone.warning
                          : StatusPillTone.primary,
                    ),
                    if (session.isLocalOnly)
                      StatusPill(
                        label: l10n.localOnly,
                        icon: Icons.smartphone_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
