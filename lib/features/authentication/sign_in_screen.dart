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
import 'auth_flow.dart';
import 'widgets/auth_provider_buttons.dart';
import 'widgets/auth_scaffold.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.next});

  final String? next;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  AuthProviderKind? _provider;
  String? _error;

  bool get _busy => _loading || _provider != null;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cloudConfigured = ref.watch(
      appDependenciesProvider.select((deps) => deps.cloudConfigured),
    );
    return AuthScaffold(
      title: l10n.signIn,
      subtitle: l10n.signInSubtitle,
      footer: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.noAccount,
                style: context.texts.bodySmall?.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => context.push(
                        '/auth/register${widget.next == null ? '' : '?next=${Uri.encodeComponent(widget.next!)}'}',
                      ),
                child: Text(l10n.createAccount),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l10n.guestModeBanner,
            textAlign: TextAlign.center,
            style: context.texts.labelSmall?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
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
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x4),
                  child: AuthErrorBanner(message: _error!),
                ),
              if (cloudConfigured)
                AuthProviderButtons(
                  enabled: !_busy,
                  busyProvider: _provider,
                  onSelected: _signInWithProvider,
                ),
              TextFormField(
                controller: _emailController,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.emailOrUsername,
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
                enabled: !_busy,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
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
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => context.push(
                          '/auth/reset${_emailController.text.trim().isEmpty ? '' : '?email=${Uri.encodeComponent(_emailController.text.trim())}'}',
                        ),
                  child: Text(l10n.forgotPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              FilledButton(
                onPressed: _busy || !cloudConfigured ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.signIn),
              ),
              if (cloudConfigured) ...[
                const SizedBox(height: AppSpacing.x3),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _continueAnonymously,
                  icon: const Icon(Icons.person_outline_rounded),
                  label: Text(l10n.continueAnonymously),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  l10n.anonymousExplanation,
                  textAlign: TextAlign.center,
                  style: context.texts.labelSmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    setState(() => _loading = true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
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

  Future<void> _signInWithProvider(AuthProviderKind provider) async {
    if (_busy) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    setState(() {
      _provider = provider;
      _error = null;
    });
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signInWithProvider(provider);
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

  Future<void> _continueAnonymously() async {
    if (_busy) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AuthSession session = await ref
          .read(authRepositoryProvider)
          .signInAnonymously();
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
}
