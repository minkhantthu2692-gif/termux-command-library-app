import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user_profile.dart';
import '../../shared/utils/error_messages.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/avatar_bubble.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  late String _avatarId;
  late String _email;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final profile = ref.read(profileProvider).value;
    final session = ref.read(currentSessionProvider);
    _nickname.text = profile?.effectiveNickname ?? '';
    _avatarId = profile?.avatarId ?? AppAvatars.defaultId;
    _email = profile?.email ?? session.email ?? '';
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(currentSessionProvider);
    return AppPage(
      title: l10n.editProfile,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  AvatarBubble(avatarId: _avatarId, size: 92, showBorder: true),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            final selected = await showAvatarPicker(
                              context,
                              selectedId: _avatarId,
                            );
                            if (selected != null && mounted) {
                              setState(() => _avatarId = selected);
                            }
                          },
                    child: Text(l10n.chooseAvatar),
                  ),
                  Text(
                    l10n.builtInAvatars,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            TextFormField(
              controller: _nickname,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.nickname,
                hintText: l10n.nicknameHint,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              validator: (value) =>
                  localizeValidation(l10n, Validators.nicknameError(value)),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.x4),
            TextFormField(
              initialValue: _email.isEmpty
                  ? l10n.emailOptionalForGuest
                  : _email,
              readOnly: true,
              enabled: false,
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Text(
              session.isLocalOnly ? l10n.localProfileBody : l10n.syncProfile,
              style: context.texts.bodySmall?.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            session: ref.read(currentSessionProvider),
            nickname: _nickname.text,
            avatarId: _avatarId,
          );
      if (!mounted) return;
      context.showSnack(AppLocalizations.of(context).profileUpdated);
      context.pop();
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
