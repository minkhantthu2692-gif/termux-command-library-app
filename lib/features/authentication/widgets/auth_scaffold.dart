import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';

/// Shared frame for authentication screens. It keeps forms centered, scrollable
/// with the keyboard open, and visually consistent without nesting cards. The
/// compact back button is the only chrome above the title, which keeps the
/// focus on the form instead of a decorative banner. An optional footer is
/// pinned to the bottom of the screen and hidden while the keyboard is open so
/// it never competes with the form for space.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final texts = context.texts;
    // The pinned footer would otherwise sit directly above the keyboard and
    // squeeze the form on short screens. It reappears as soon as typing ends.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (showBack)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.x2,
                    top: AppSpacing.x2,
                  ),
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x6,
                  AppSpacing.x2,
                  AppSpacing.x6,
                  AppSpacing.x6,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(title, style: texts.headlineMedium),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          subtitle,
                          style: texts.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x6),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (footer != null && !keyboardOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x6,
                  AppSpacing.x2,
                  AppSpacing.x6,
                  AppSpacing.x3,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: footer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: AppRadius.medium,
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: AppIconSizes.sm,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.label,
    required this.score,
  });

  /// Localized strength label. [score] is 0..3.
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final color = switch (score) {
      <= 0 => scheme.error,
      1 => context.appColors.warning,
      2 => context.appColors.warning,
      _ => context.appColors.success,
    };
    return Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: index < score
                    ? color
                    : scheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          if (index < 2) const SizedBox(width: AppSpacing.x1),
        ],
        const SizedBox(width: AppSpacing.x2),
        Text(label, style: context.texts.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}
