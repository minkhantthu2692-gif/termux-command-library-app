import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/command_post.dart';
import '../../data/services/ai/ai_prompts.dart';
import '../../shared/utils/error_messages.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_note.dart';

/// Contextual AI actions for a command draft. It only reads the current form
/// values; nothing is sent until the user selects an action.
Future<void> showAiAssistSheet(
  BuildContext context,
  WidgetRef ref, {
  required CommandPost draft,
  ValueChanged<String>? onApplyDescription,
}) async {
  final l10n = AppLocalizations.of(context);
  final settings = ref.read(settingsControllerProvider);
  final hasKey = await ref.read(aiRepositoryProvider).hasApiKey();
  if (!settings.aiEnabled) {
    if (!context.mounted) return;
    await _showSetupMessage(
      context,
      title: l10n.aiDisabledTitle,
      body: l10n.aiDisabledBody,
    );
    return;
  }
  if (!hasKey || settings.aiModelId.trim().isEmpty) {
    if (!context.mounted) return;
    await _showSetupMessage(
      context,
      title: l10n.aiNoProviderConfigured,
      body: l10n.aiSetupGuideBody,
    );
    return;
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) =>
        _AiAssistSheet(draft: draft, onApplyDescription: onApplyDescription),
  );
}

Future<void> _showSetupMessage(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final l10n = AppLocalizations.of(context);
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.openAiSettings),
        ),
      ],
    ),
  );
  if (openSettings == true && context.mounted) {
    context.push('/settings/ai');
  }
}

class _IntentOption {
  const _IntentOption(this.intent, this.label, this.icon);

  final AiAssistIntent intent;
  final String label;
  final IconData icon;
}

class _AiAssistSheet extends ConsumerStatefulWidget {
  const _AiAssistSheet({required this.draft, this.onApplyDescription});

  final CommandPost draft;
  final ValueChanged<String>? onApplyDescription;

  @override
  ConsumerState<_AiAssistSheet> createState() => _AiAssistSheetState();
}

class _AiAssistSheetState extends ConsumerState<_AiAssistSheet> {
  AiAssistIntent? _running;
  String? _result;
  String? _error;

  List<_IntentOption> get _options {
    final l10n = AppLocalizations.of(context);
    return [
      _IntentOption(
        AiAssistIntent.suggestTitle,
        l10n.generateTitle,
        Icons.title_rounded,
      ),
      _IntentOption(
        AiAssistIntent.rewriteDescription,
        l10n.rewriteDescription,
        Icons.auto_fix_high_rounded,
      ),
      _IntentOption(
        AiAssistIntent.reviewCommand,
        l10n.reviewCommand,
        Icons.fact_check_outlined,
      ),
      _IntentOption(
        AiAssistIntent.explainCommand,
        l10n.explainCommand,
        Icons.menu_book_outlined,
      ),
      _IntentOption(
        AiAssistIntent.translateToMyanmar,
        l10n.translateToMyanmar,
        Icons.translate_rounded,
      ),
      _IntentOption(
        AiAssistIntent.translateToEnglish,
        l10n.translateToEnglish,
        Icons.language_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final running = _running != null;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.64,
      minChildSize: 0.36,
      maxChildSize: 0.94,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                0,
                AppSpacing.x5,
                AppSpacing.x5,
              ),
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.scheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.medium,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: context.scheme.primary,
                        size: AppIconSizes.md,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.aiAssistTitle,
                            style: context.texts.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.aiContext,
                            style: context.texts.bodySmall?.copyWith(
                              color: context.scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
                AppNote(
                  message: l10n.aiPrivacyNote,
                  icon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: AppSpacing.x4),
                if (!running && _result == null) ...[
                  Text(l10n.suggestions, style: context.texts.titleSmall),
                  const SizedBox(height: AppSpacing.x2),
                  for (final option in _options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                      child: _IntentButton(
                        option: option,
                        onTap: () => _run(option.intent),
                      ),
                    ),
                ] else if (running)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.x12,
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          l10n.thinking,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _intentLabel(
                            _running ?? AiAssistIntent.reviewCommand,
                          ),
                          style: context.texts.titleSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.copy,
                        onPressed: () =>
                            copyWithFeedback(context, ref, _result ?? ''),
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    decoration: BoxDecoration(
                      color: context.appColors.cardMuted,
                      borderRadius: AppRadius.medium,
                    ),
                    child: MarkdownBody(
                      data: _result ?? '',
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(
                        Theme.of(context),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.x3),
                    AppNote(message: l10n.aiError, tone: AppNoteTone.danger),
                  ],
                  const SizedBox(height: AppSpacing.x4),
                  if (widget.onApplyDescription != null &&
                      _running == AiAssistIntent.rewriteDescription)
                    FilledButton.icon(
                      onPressed: () {
                        widget.onApplyDescription?.call(_result!.trim());
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n.aiAssistApplied),
                    ),
                  if (widget.onApplyDescription != null &&
                      _running == AiAssistIntent.rewriteDescription)
                    const SizedBox(height: AppSpacing.x2),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _result = null;
                      _error = null;
                      _running = null;
                    }),
                    child: Text(l10n.tryAgain),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _intentLabel(AiAssistIntent intent) {
    final l10n = AppLocalizations.of(context);
    return switch (intent) {
      AiAssistIntent.suggestTitle => l10n.generateTitle,
      AiAssistIntent.rewriteDescription => l10n.rewriteDescription,
      AiAssistIntent.reviewCommand => l10n.reviewCommand,
      AiAssistIntent.explainCommand => l10n.explainCommand,
      AiAssistIntent.translateToMyanmar => l10n.translateToMyanmar,
      AiAssistIntent.translateToEnglish => l10n.translateToEnglish,
    };
  }

  Future<void> _run(AiAssistIntent intent) async {
    setState(() {
      _running = intent;
      _result = null;
      _error = null;
    });
    try {
      final answer = await ref
          .read(aiRepositoryProvider)
          .completeAssist(intent: intent, command: widget.draft);
      if (!mounted) return;
      setState(() {
        _result = answer;
        _running = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = localizeError(AppLocalizations.of(context), error);
        _result = null;
        _running = null;
      });
    }
  }
}

class _IntentButton extends StatelessWidget {
  const _IntentButton({required this.option, required this.onTap});

  final _IntentOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(
          color: context.scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x3,
          ),
          child: Row(
            children: [
              Icon(
                option.icon,
                size: AppIconSizes.sm,
                color: context.scheme.primary,
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(option.label, style: context.texts.bodyMedium),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppIconSizes.sm,
                color: context.scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
