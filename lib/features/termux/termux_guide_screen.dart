import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/services/termux_service.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/utils/url_actions.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/command_code_block.dart';
import '../../shared/widgets/status_pill.dart';
import 'termux_run_flow.dart';

class TermuxGuideScreen extends ConsumerStatefulWidget {
  const TermuxGuideScreen({super.key});

  @override
  ConsumerState<TermuxGuideScreen> createState() => _TermuxGuideScreenState();
}

class _TermuxGuideScreenState extends ConsumerState<TermuxGuideScreen> {
  bool _checking = true;
  bool _installed = false;
  bool _apiInstalled = false;
  bool _permission = false;

  TermuxService get _service => ref.read(termuxServiceProvider);

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final service = _service;
    if (!service.isSupported) {
      if (mounted) setState(() => _checking = false);
      return;
    }
    try {
      final results = await Future.wait([
        service.isTermuxInstalled(),
        service.isTermuxApiInstalled(),
        service.hasRunCommandPermission(),
      ]);
      if (!mounted) return;
      setState(() {
        _installed = results[0];
        _apiInstalled = results[1];
        _permission = results[2];
        _checking = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n.termuxGuide,
      actions: [
        IconButton(
          tooltip: l10n.refresh,
          onPressed: _check,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.termuxGuideIntro,
            style: context.texts.bodyMedium?.copyWith(
              color: context.scheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          _StatusCard(
            installed: _installed,
            apiInstalled: _apiInstalled,
            permission: _permission,
            checking: _checking,
          ),
          const SizedBox(height: AppSpacing.x6),
          _GuideStep(
            number: 1,
            title: l10n.termuxStepInstall,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpacing.x2,
                  runSpacing: AppSpacing.x2,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => openExternalUrl(
                        context,
                        AppConstants.termuxReleasesUrl,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(l10n.getTermux),
                    ),
                    OutlinedButton.icon(
                      onPressed: _installed
                          ? () async {
                              try {
                                await _service.openTermux();
                              } catch (error) {
                                if (context.mounted) {
                                  context.showErrorSnack(error);
                                }
                              }
                            }
                          : null,
                      icon: const Icon(Icons.terminal_rounded),
                      label: Text(l10n.openTermux),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  l10n.officialReleases,
                  style: context.texts.labelSmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          _GuideStep(
            number: 2,
            title: l10n.termuxStepPermission,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.termuxPermissionBody,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: _permission
                        ? null
                        : () async {
                            try {
                              final granted = await _service
                                  .requestRunCommandPermission();
                              if (!context.mounted) return;
                              context.showSnack(
                                granted ? l10n.keyWorks : l10n.noPermission,
                              );
                              await _check();
                            } catch (error) {
                              if (context.mounted) {
                                context.showErrorSnack(error);
                              }
                            }
                          },
                    icon: Icon(
                      _permission
                          ? Icons.check_circle_outline_rounded
                          : Icons.shield_outlined,
                    ),
                    label: Text(
                      _permission ? l10n.noPermission : l10n.grantPermission,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          _GuideStep(
            number: 3,
            title: l10n.termuxStepExternal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.termuxExternalAppsBody,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                const CommandCodeBlock(
                  command:
                      'mkdir -p ~/.termux\n'
                      'echo "allow-external-apps=true" >> ~/.termux/termux.properties\n'
                      'termux-reload-settings',
                  label: '~/.termux/termux.properties',
                  showLineNumbers: true,
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  l10n.termuxStepReload,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          _GuideStep(
            number: 4,
            title: l10n.termuxTestTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.termuxTestBody,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => showTermuxRunFlow(
                      context,
                      ref,
                      label: l10n.termuxTestTitle,
                      items: const [
                        TermuxRunItem(
                          title: 'Termux test',
                          command:
                              'echo "Termux Command Library connection OK"',
                        ),
                      ],
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.termuxTestButton),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          AppNote(
            title: l10n.termuxApiNote,
            message: l10n.termuxApiNote,
            icon: Icons.extension_outlined,
            actionLabel: l10n.officialReleases,
            onAction: () =>
                openExternalUrl(context, AppConstants.termuxApiReleasesUrl),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppNote(
            title: l10n.commandNotRun,
            message: l10n.runConfirmationBody,
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            l10n.syncSecretsNote,
            style: context.texts.labelSmall?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.installed,
    required this.apiInstalled,
    required this.permission,
    required this.checking,
  });

  final bool installed;
  final bool apiInstalled;
  final bool permission;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: context.scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: checking
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                StatusPill(
                  label: 'Termux',
                  icon: installed
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  tone: installed
                      ? StatusPillTone.success
                      : StatusPillTone.danger,
                  dense: false,
                ),
                StatusPill(
                  label: 'Termux:API',
                  icon: apiInstalled
                      ? Icons.check_circle_outline_rounded
                      : Icons.remove_circle_outline_rounded,
                  tone: apiInstalled
                      ? StatusPillTone.success
                      : StatusPillTone.neutral,
                  dense: false,
                ),
                StatusPill(
                  label: l10n.termuxPermissionTitle,
                  icon: permission
                      ? Icons.check_circle_outline_rounded
                      : Icons.shield_outlined,
                  tone: permission
                      ? StatusPillTone.success
                      : StatusPillTone.warning,
                  dense: false,
                ),
              ],
            ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: context.scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '$number',
                  style: context.texts.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(child: Text(title, style: context.texts.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          child,
        ],
      ),
    );
  }
}
