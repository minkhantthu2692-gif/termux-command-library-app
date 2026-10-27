import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/providers.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/haptics_service.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/utils/ui_actions.dart';
import 'widgets/auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cloudConfigured = ref.watch(
      appDependenciesProvider.select((deps) => deps.cloudConfigured),
    );
    return AuthScaffold(
      title: l10n.resetPassword,
      subtitle: l10n.resetPasswordBody,
      footer: Center(
        child: TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, size: AppIconSizes.sm),
          label: Text(l10n.backToSignIn),
        ),
      ),
      child: _sent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  decoration: BoxDecoration(
                    color: context.appColors.success.withValues(alpha: 0.1),
                    borderRadius: AppRadius.medium,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.mark_email_read_outlined,
                        color: context.appColors.success,
                        size: AppIconSizes.md,
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: Text(
                          l10n.resetEmailSent,
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.appColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Form(
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
                  TextFormField(
                    controller: _emailController,
                    enabled: !_loading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      hintText: l10n.emailHint,
                      helperText: l10n.emailHelper,
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) =>
                        localizeValidation(l10n, Validators.emailError(value)),
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
                        : Text(l10n.sendResetLink),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_emailController.text);
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.success));
      setState(() => _sent = true);
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
