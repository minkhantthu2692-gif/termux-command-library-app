import 'package:flutter/material.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../data/models/auth_models.dart';

/// Google and GitHub entry points shared by the sign-in and registration
/// screens. The email form stays directly below the divider, so an external
/// provider that is not configured yet never blocks the primary flow.
class AuthProviderButtons extends StatelessWidget {
  const AuthProviderButtons({
    super.key,
    required this.enabled,
    required this.busyProvider,
    required this.onSelected,
  });

  /// False while the screen is busy or cloud authentication is unavailable.
  final bool enabled;

  /// The provider currently waiting on the browser flow, if any.
  final AuthProviderKind? busyProvider;

  final ValueChanged<AuthProviderKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = busyProvider != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProviderButton(
          provider: AuthProviderKind.google,
          label: l10n.continueWithGoogle,
          icon: const _GoogleMark(),
          enabled: enabled && !busy,
          busy: busyProvider == AuthProviderKind.google,
          onSelected: onSelected,
        ),
        const SizedBox(height: AppSpacing.x3),
        _ProviderButton(
          provider: AuthProviderKind.github,
          label: l10n.continueWithGithub,
          icon: const _GithubMark(),
          enabled: enabled && !busy,
          busy: busyProvider == AuthProviderKind.github,
          onSelected: onSelected,
        ),
        const SizedBox(height: AppSpacing.x5),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
              child: Text(
                l10n.orContinueWithEmail,
                style: context.texts.labelSmall?.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.x5),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.busy,
    required this.onSelected,
  });

  final AuthProviderKind provider;
  final String label;
  final Widget icon;
  final bool enabled;
  final bool busy;
  final ValueChanged<AuthProviderKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? () => onSelected(provider) : null,
      child: busy
          ? const SizedBox(
              width: AppIconSizes.sm,
              height: AppIconSizes.sm,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: AppSpacing.x3),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/google_g.png',
      width: AppIconSizes.md,
      height: AppIconSizes.md,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
  }
}

class _GithubMark extends StatelessWidget {
  const _GithubMark();

  @override
  Widget build(BuildContext context) {
    // The bundled mark is a black alpha mask, so it is tinted to stay legible
    // in both light and dark themes.
    return ColorFiltered(
      colorFilter: ColorFilter.mode(context.scheme.onSurface, BlendMode.srcIn),
      child: Image.asset(
        'assets/brand/github_mark.png',
        width: AppIconSizes.md,
        height: AppIconSizes.md,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}
