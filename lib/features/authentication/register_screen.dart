import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/providers.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/services/haptics_service.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/utils/ui_actions.dart';
import '../../../shared/widgets/avatar_bubble.dart';
import 'auth_flow.dart';
import 'widgets/auth_provider_buttons.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/github_device_dialog.dart';

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
  AuthProviderKind? _provider;
  String? _error;

  bool get _busy => _loading || _provider != null;

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
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.haveAccount,
            style: context.texts.bodyMedium?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => context.pop(),
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
                      onPressed: _busy ? null : _chooseAvatar,
                      child: Text(l10n.chooseAvatar),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              TextFormField(
                controller: _nicknameController,
                enabled: !_busy,
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
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  hintText: l10n.emailHint,
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
                enabled: !_busy,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                    onPressed: () {
                      unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
                      setState(() => _obscure = !_obscure);
                    },
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
                enabled: !_busy,
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
                    onPressed: () {
                      unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
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
                onPressed: _busy || !cloudConfigured ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(linking ? l10n.upgradeAccount : l10n.createAccount),
              ),
              if (cloudConfigured) ...[
                const SizedBox(height: AppSpacing.x6),
                AuthProviderButtons(
                  enabled: !_busy,
                  busyProvider: _provider,
                  onSelected: _continueWithProvider,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseAvatar() async {
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    final selected = await showAvatarPicker(context, selectedId: _avatarId);
    if (selected != null && mounted) {
      unawaited(triggerHaptic(ref, cue: HapticCue.selection));
      setState(() => _avatarId = selected);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
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
      unawaited(triggerHaptic(ref, cue: HapticCue.success));
      await finishAuthFlow(context, ref, session, next: widget.next);
    } on AppException catch (error) {
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.error));
      setState(
        () => _error = localizeError(AppLocalizations.of(context), error),
      );
    } catch (error) {
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.error));
      setState(
        () => _error = localizeError(AppLocalizations.of(context), error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Signs in with Google or GitHub. On the account-upgrade screen the provider
  /// is linked to the anonymous UID so the collection survives, and any avatar
  /// or nickname already chosen in the form is applied to the profile.
  Future<void> _continueWithProvider(AuthProviderKind provider) async {
    if (provider == AuthProviderKind.github) {
      return _continueWithGithub();
    }
    if (_busy) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    final linking = _linkingAnonymous;
    setState(() {
      _provider = provider;
      _error = null;
    });
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signInWithProvider(provider, linkAnonymous: linking);
      if (linking) await _applyChosenProfile(session);
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.success));
      await finishAuthFlow(context, ref, session, next: widget.next);
    } on AppException catch (error) {
      // Closing the browser or cancelling the account picker is not a failure
      // the user needs to read about.
      if (!mounted) return;
      if (error.code != AppErrorCode.authCancelled) {
        unawaited(triggerHaptic(ref, cue: HapticCue.error));
        setState(
          () => _error = localizeError(AppLocalizations.of(context), error),
        );
      }
    } catch (error) {
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.error));
      setState(
        () => _error = localizeError(AppLocalizations.of(context), error),
      );
    } finally {
      if (mounted) setState(() => _provider = null);
    }
  }

  /// GitHub uses the device flow, so no Custom Tab state can be lost. On the
  /// upgrade screen the provider is linked to the anonymous UID.
  Future<void> _continueWithGithub() async {
    if (_busy) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    final linking = _linkingAnonymous;
    setState(() {
      _provider = AuthProviderKind.github;
      _error = null;
    });
    try {
      final session = await showGithubDeviceSignInDialog(
        context,
        ref,
        linkAnonymous: linking,
      );
      if (session == null) return;
      if (linking) await _applyChosenProfile(session);
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.success));
      await finishAuthFlow(context, ref, session, next: widget.next);
    } on AppException catch (error) {
      if (!mounted) return;
      if (error.code != AppErrorCode.authCancelled) {
        unawaited(triggerHaptic(ref, cue: HapticCue.error));
        setState(
          () => _error = localizeError(AppLocalizations.of(context), error),
        );
      }
    } catch (error) {
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.error));
      setState(
        () => _error = localizeError(AppLocalizations.of(context), error),
      );
    } finally {
      if (mounted) setState(() => _provider = null);
    }
  }

  /// Best-effort profile update after a successful link. The account is already
  /// linked at this point, so a local failure must not block navigation.
  Future<void> _applyChosenProfile(AuthSession session) async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty || Validators.nicknameError(nickname) != null) {
      return;
    }
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            session: session,
            nickname: nickname,
            avatarId: _avatarId,
          );
    } catch (error) {
      debugPrint('Could not apply the chosen profile after linking: $error');
    }
  }
}
