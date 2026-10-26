import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/section_header.dart';

/// Changes the password of a registered Firebase account. Firebase requires a
/// recent sign-in, so the current password is verified first.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _nextFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    _nextFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(currentSessionProvider);
    if (session.isLocalOnly || session.isAnonymous) {
      return AppMessageScaffold(
        title: l10n.securitySettings,
        child: EmptyState(
          icon: Icons.lock_person_outlined,
          title: l10n.localProfile,
          body: l10n.localProfileBody,
          actionLabel: l10n.upgradeAccount,
          onAction: () => context.push('/auth/register'),
        ),
      );
    }

    final strength = Validators.passwordStrength(_next.text);
    return AppPage(
      title: l10n.updatePassword,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNote(
              title: l10n.securitySettings,
              message: l10n.reauthenticateNeeded,
              tone: AppNoteTone.info,
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: AppSpacing.x5),
            TextFormField(
              controller: _current,
              enabled: !_saving,
              obscureText: _obscureCurrent,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: l10n.currentPassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscureCurrent
                      ? l10n.showPassword
                      : l10n.hidePassword,
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? l10n.passwordRequired : null,
              onFieldSubmitted: (_) => _nextFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.x4),
            TextFormField(
              controller: _next,
              focusNode: _nextFocus,
              enabled: !_saving,
              obscureText: _obscureNext,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                helperText: l10n.passwordHelper,
                suffixIcon: IconButton(
                  tooltip: _obscureNext ? l10n.showPassword : l10n.hidePassword,
                  onPressed: () => setState(() => _obscureNext = !_obscureNext),
                  icon: Icon(
                    _obscureNext
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
                if (value == _current.text) return l10n.nameMustBeDifferent;
                return null;
              },
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
            ),
            if (_next.text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x2),
              _StrengthMeter(strength: strength),
            ],
            const SizedBox(height: AppSpacing.x4),
            TextFormField(
              controller: _confirm,
              focusNode: _confirmFocus,
              enabled: !_saving,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                prefixIcon: const Icon(Icons.check_circle_outline_rounded),
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
                if (!Validators.passwordsMatch(_next.text, value)) {
                  return l10n.passwordsMismatch;
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
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
            const SizedBox(height: AppSpacing.x3),
            Text(
              l10n.syncSecretsNote,
              textAlign: TextAlign.center,
              style: context.texts.labelSmall?.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
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
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      context.showSnack(AppLocalizations.of(context).passwordChanged);
      context.pop();
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color, value) = switch (strength) {
      PasswordStrength.tooShort => (
        l10n.passwordTooShort,
        context.scheme.error,
        0.18,
      ),
      PasswordStrength.weak => (
        l10n.passwordWeak,
        context.appColors.riskHigh,
        0.36,
      ),
      PasswordStrength.medium => (
        l10n.passwordMedium,
        context.appColors.warning,
        0.68,
      ),
      PasswordStrength.strong => (
        l10n.passwordStrong,
        context.appColors.success,
        1.0,
      ),
    };
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              color: color,
              backgroundColor: context.appColors.cardMuted,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        Text(
          label,
          style: context.texts.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
