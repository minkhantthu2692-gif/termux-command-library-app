import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../data/models/auth_models.dart';

/// Google and GitHub entry points shared by the sign-in and registration
/// screens. They are deliberately compact, icon-only secondary actions placed
/// below the email/password form, so the primary form remains the focus.
class AuthProviderButtons extends StatefulWidget {
  const AuthProviderButtons({
    super.key,
    required this.enabled,
    required this.busyProvider,
    required this.onSelected,
    this.slowHintDelay = const Duration(seconds: 45),
  });

  /// False while the screen is busy or cloud authentication is unavailable.
  final bool enabled;

  /// The provider currently waiting on the browser flow, if any.
  final AuthProviderKind? busyProvider;

  final ValueChanged<AuthProviderKind> onSelected;

  /// How long to wait before suggesting recovery steps. Exposed so widget
  /// tests do not have to wait for the production delay.
  @visibleForTesting
  final Duration slowHintDelay;

  @override
  State<AuthProviderButtons> createState() => _AuthProviderButtonsState();
}

class _AuthProviderButtonsState extends State<AuthProviderButtons> {
  Timer? _slowHintTimer;
  bool _showSlowHint = false;

  @override
  void initState() {
    super.initState();
    _syncSlowHintTimer();
  }

  @override
  void didUpdateWidget(covariant AuthProviderButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busyProvider != oldWidget.busyProvider ||
        widget.slowHintDelay != oldWidget.slowHintDelay) {
      _syncSlowHintTimer();
    }
  }

  @override
  void dispose() {
    _slowHintTimer?.cancel();
    super.dispose();
  }

  void _syncSlowHintTimer() {
    _slowHintTimer?.cancel();
    _slowHintTimer = null;
    _showSlowHint = false;
    if (widget.busyProvider == null) return;

    _slowHintTimer = Timer(widget.slowHintDelay, () {
      if (!mounted || widget.busyProvider == null) return;
      setState(() => _showSlowHint = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = widget.busyProvider != null;
    final enabled = widget.enabled && !busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Flexible(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
                child: Text(
                  l10n.orContinueWith,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.texts.labelSmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProviderIconButton(
              key: const ValueKey('auth_provider_google'),
              provider: AuthProviderKind.google,
              label: l10n.continueWithGoogle,
              icon: const _GoogleMark(),
              enabled: enabled,
              busy: widget.busyProvider == AuthProviderKind.google,
              onSelected: widget.onSelected,
            ),
            const SizedBox(width: AppSpacing.x3),
            _ProviderIconButton(
              key: const ValueKey('auth_provider_github'),
              provider: AuthProviderKind.github,
              label: l10n.continueWithGithub,
              icon: const _GithubMark(),
              enabled: enabled,
              busy: widget.busyProvider == AuthProviderKind.github,
              onSelected: widget.onSelected,
            ),
          ],
        ),
        if (_showSlowHint) ...[
          const SizedBox(height: AppSpacing.x3),
          Text(
            l10n.providerSignInSlow,
            textAlign: TextAlign.center,
            style: context.texts.labelSmall?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProviderIconButton extends StatelessWidget {
  const _ProviderIconButton({
    super.key,
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
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: SizedBox(
          width: AppSizes.minTapTarget,
          height: AppSizes.minTapTarget,
          child: OutlinedButton(
            onPressed: enabled ? () => onSelected(provider) : null,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(AppSizes.minTapTarget),
              maximumSize: const Size.square(AppSizes.minTapTarget),
              shape: const CircleBorder(),
            ),
            child: busy
                ? const SizedBox(
                    width: AppIconSizes.sm,
                    height: AppIconSizes.sm,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : icon,
          ),
        ),
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
