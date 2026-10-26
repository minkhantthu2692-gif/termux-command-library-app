import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/design_system/app_tokens.dart';
import '../../shared/widgets/app_logo.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _finishing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final cloudConfigured = ref.watch(
      appDependenciesProvider.select((deps) => deps.cloudConfigured),
    );
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x3,
            AppSpacing.x5,
            AppSpacing.x8,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 940),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final content = _Content(
                    l10n: l10n,
                    cloudConfigured: cloudConfigured,
                    finishing: _finishing,
                    onGuest: _continueAsGuest,
                    onSignIn: () => context.push('/auth/sign-in'),
                    onCreate: () => context.push('/auth/register'),
                    onDocs: () => context.push('/docs'),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const AppWordmark(size: 40),
                          const Spacer(),
                          IconButton(
                            tooltip: l10n.language,
                            onPressed: _toggleLanguage,
                            icon: const Icon(Icons.translate_rounded),
                          ),
                          TextButton(
                            onPressed: _toggleLanguage,
                            child: Text(
                              settings.effectiveLanguageCode == 'my'
                                  ? l10n.languageEnglish
                                  : l10n.languageMyanmar,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: wide ? AppSpacing.x10 : AppSpacing.x6),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(flex: 11, child: _HeroPanel()),
                            const SizedBox(width: AppSpacing.x10),
                            Expanded(flex: 10, child: content),
                          ],
                        )
                      else ...[
                        const _HeroPanel(),
                        const SizedBox(height: AppSpacing.x7),
                        content,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLanguage() async {
    final settings = ref.read(settingsControllerProvider);
    final next = settings.effectiveLanguageCode == 'my' ? 'en' : 'my';
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .save(settings.copyWith(languageCode: next));
    } catch (_) {
      // A preferences write failure should not block onboarding.
    }
  }

  Future<void> _continueAsGuest() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .setOnboardingCompleted(true);
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.l10n,
    required this.cloudConfigured,
    required this.finishing,
    required this.onGuest,
    required this.onSignIn,
    required this.onCreate,
    required this.onDocs,
  });

  final AppLocalizations l10n;
  final bool cloudConfigured;
  final bool finishing;
  final VoidCallback onGuest;
  final VoidCallback onSignIn;
  final VoidCallback onCreate;
  final VoidCallback onDocs;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    final scheme = context.scheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.welcomeGreeting,
          style: texts.displaySmall?.copyWith(fontSize: 36, height: 1.13),
        ),
        const SizedBox(height: AppSpacing.x3),
        Text(
          l10n.welcomeBody,
          style: texts.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.x6),
        _FeatureRow(
          icon: Icons.offline_bolt_rounded,
          title: l10n.welcomeFeatureOffline,
          body: l10n.welcomeFeatureOfflineBody,
          color: const Color(0xFF2D7D5B),
        ),
        const SizedBox(height: AppSpacing.x3),
        _FeatureRow(
          icon: Icons.terminal_rounded,
          title: l10n.welcomeFeatureTermux,
          body: l10n.welcomeFeatureTermuxBody,
          color: const Color(0xFF2B6CA3),
        ),
        const SizedBox(height: AppSpacing.x3),
        _FeatureRow(
          icon: Icons.auto_awesome_rounded,
          title: l10n.welcomeFeatureAi,
          body: l10n.welcomeFeatureAiBody,
          color: const Color(0xFF7651C9),
        ),
        if (!cloudConfigured) ...[
          const SizedBox(height: AppSpacing.x4),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x3),
            decoration: BoxDecoration(
              color: context.appColors.cardMuted,
              borderRadius: AppRadius.medium,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: AppIconSizes.sm,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.cloudUnavailableTitle,
                        style: texts.labelMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.cloudUnavailableBody,
                        style: texts.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      TextButton(
                        onPressed: onDocs,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 34),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(l10n.firebaseSetupDocs),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x6),
        FilledButton(
          onPressed: finishing ? null : onGuest,
          child: finishing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.continueAsGuest),
        ),
        if (cloudConfigured) ...[
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSignIn,
                  child: Text(l10n.signIn),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCreate,
                  child: Text(l10n.createAccount),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.x4),
        Text(
          l10n.guestDataNote,
          textAlign: TextAlign.center,
          style: texts.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: AppIconSizes.md, color: color),
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.texts.titleSmall),
              const SizedBox(height: 2),
              Text(
                body,
                style: context.texts.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A calm, product-style visual: a soft gradient field with a terminal window
/// and a few floating status chips. Drawn entirely with widgets so the app has
/// no decorative image payload.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final palette = context.appColors;
    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 460),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.16),
              scheme.secondary.withValues(alpha: 0.06),
              palette.cardMuted,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.09)),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -40,
              top: -30,
              child: _Orb(
                size: 190,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              left: -30,
              bottom: 10,
              child: _Orb(
                size: 140,
                color: scheme.tertiary.withValues(alpha: 0.08),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x6),
                child: _TerminalMockup(),
              ),
            ),
            Positioned(
              left: AppSpacing.x5,
              top: AppSpacing.x5,
              child: _FloatingChip(
                icon: Icons.offline_bolt_rounded,
                label: 'Offline first',
                color: palette.success,
              ),
            ),
            Positioned(
              right: AppSpacing.x4,
              bottom: AppSpacing.x5,
              child: _FloatingChip(
                icon: Icons.verified_rounded,
                label: 'Curated',
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final palette = context.appColors;
    final mono = context.monoStyle.copyWith(
      fontSize: 11.5,
      height: 1.65,
      color: scheme.onSurface.withValues(alpha: 0.86),
    );
    return Transform.rotate(
      angle: -0.035,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: palette.card.withValues(alpha: 0.94),
          borderRadius: AppRadius.large,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3,
                vertical: AppSpacing.x2,
              ),
              decoration: BoxDecoration(
                color: palette.cardMuted,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  for (final color in const [
                    Color(0xFFE88983),
                    Color(0xFFE6BE67),
                    Color(0xFF7CC49A),
                  ]) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const SizedBox(width: AppSpacing.x2),
                  Text(
                    'termux ~',
                    style: context.texts.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.more_horiz_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$ pkg update && pkg upgrade -y', style: mono),
                  const SizedBox(height: 2),
                  Text(
                    '\$ pkg install python git openssh',
                    style: mono.copyWith(color: scheme.primary),
                  ),
                  const SizedBox(height: 2),
                  Text('\$ python -m venv ~/project/.venv', style: mono),
                  const SizedBox(height: 2),
                  Text(
                    '\$ git clone <your-repository>',
                    style: mono.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.x2,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: palette.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'ready',
                          style: context.texts.labelSmall?.copyWith(
                            color: palette.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '4 steps',
                        style: context.texts.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x1 + 2,
      ),
      decoration: BoxDecoration(
        color: context.appColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
