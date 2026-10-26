import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/providers.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/auth_models.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/avatar_bubble.dart';
import 'auth_flow.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.next});

  final String? next;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  String _avatarId = 'orbit';
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _linkingAnonymous {
    final session = ref.watch(currentSessionProvider);
    final cloudConfigured = ref.read(appDependenciesProvider).cloudConfigured;
    return cloudConfigured && !session.isLocalOnly && session.isAnonymous;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cloudConfigured = ref.watch(
      appDependenciesProvider.select((deps) => deps.cloudConfigured),
    );
    final linking = _linkingAnonymous;
    final strength = Validators.passwordStrength(_passwordController.text);
    return AuthScaffold(
      title: linking ? l10n.upgradeAccount : l10n.createAccount,
      subtitle: linking ? l10n.upgradeAccountBody : l10n.createAccountSubtitle,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.haveAccount,
            style: context.texts.bodySmall?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: _loading ? null : () => context.pop(),
            child: Text(l10n.signIn),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!cloudConfigured)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x4),
                  child: AuthErrorBanner(
                    message:
                        '${l10n.cloudUnavailableTitle}\n${l10n.cloudUnavailableBody}',
                  ),
                ),
              if (linking)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x4),
                  child: AuthErrorBanner(message: l10n.anonymousExplanation),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x4),
                  child: AuthErrorBanner(message: _error!),
                ),
              Center(
                child: Column(
                  children: [
                    AvatarBubble(
                      avatarId: _avatarId,
                      size: 82,
                      showBorder: true,
                    ),
                    TextButton(
                      onPressed: _loading ? null : _chooseAvatar,
                      child: Text(l10n.chooseAvatar),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              TextFormField(
                controller: _nicknameController,
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.nickname,
                  hintText: l10n.nicknameHint,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (value) =>
                    localizeValidation(l10n, Validators.nicknameError(value)),
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.x4),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  hintText: l10n.emailHint,
                  helperText: l10n.emailHelper,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) =>
                    localizeValidation(l10n, Validators.emailError(value)),
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.x4),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !_loading,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.password,
                  helperText: l10n.passwordHelper,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.passwordRequired;
                  }
                  if (value.length < 8) return l10n.passwordTooShort;
                  return null;
                },
                onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.x2),
                PasswordStrengthMeter(
                  score: switch (strength) {
                    PasswordStrength.tooShort => 0,
                    PasswordStrength.weak => 1,
                    PasswordStrength.medium => 2,
                    PasswordStrength.strong => 3,
                  },
                  label: switch (strength) {
                    PasswordStrength.tooShort => l10n.passwordTooShort,
                    PasswordStrength.weak => l10n.passwordWeak,
                    PasswordStrength.medium => l10n.passwordMedium,
                    PasswordStrength.strong => l10n.passwordStrong,
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.x4),
              TextFormField(
                controller: _confirmController,
                focusNode: _confirmFocus,
                enabled: !_loading,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: l10n.confirmPassword,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirm
                        ? l10n.showPassword
                        : l10n.hidePassword,
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.passwordRequired;
                  }
                  if (!Validators.passwordsMatch(
                    _passwordController.text,
                    value,
                  )) {
                    return l10n.passwordsMismatch;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.x5),
              FilledButton(
                onPressed: _loading || !cloudConfigured ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(linking ? l10n.upgradeAccount : l10n.createAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseAvatar() async {
    final selected = await showAvatarPicker(context, selectedId: _avatarId);
    if (selected != null && mounted) {
      setState(() => _avatarId = selected);
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final AuthSession session;
      if (_linkingAnonymous) {
        final linked = await authRepository.linkAnonymousAccount(
          email: _emailController.text,
          password: _passwordController.text,
        );
        await ref
            .read(profileRepositoryProvider)
            .updateProfile(
              session: linked,
              nickname: _nicknameController.text,
              avatarId: _avatarId,
            );
        session = linked;
      } else {
        session = await authRepository.register(
          nickname: _nicknameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          avatarId: _avatarId,
        );
      }
      if (!mounted) return;
      await finishAuthFlow(context, ref, session, next: widget.next);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = localizeError(AppLocalizations.of(context), error),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = localizeError(AppLocalizations.of(context), error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
