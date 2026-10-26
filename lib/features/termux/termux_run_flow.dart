import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/command_risk.dart';
import '../../data/models/command_post.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/utils/url_actions.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/command_code_block.dart';
import '../../shared/widgets/risk_labels.dart';

/// One command as presented to the Termux confirmation sheet.
class TermuxRunItem {
  const TermuxRunItem({
    required this.title,
    required this.command,
    this.runMode = CommandRunMode.foreground,
  });

  final String title;
  final String command;
  final CommandRunMode runMode;
}

/// The only supported way for the app to hand a command to Termux.
///
/// The flow is deliberately explicit:
/// 1. detect Termux and the RUN_COMMAND permission,
/// 2. show every command and the risk warnings,
/// 3. require a confirmation (and an acknowledgement for risky commands),
/// 4. report that the commands were *sent*, never that they succeeded.
Future<bool> showTermuxRunFlow(
  BuildContext context,
  WidgetRef ref, {
  required String label,
  required List<TermuxRunItem> items,
  bool? backgroundOverride,
}) async {
  if (items.isEmpty) return false;
  final l10n = AppLocalizations.of(context);
  final service = ref.read(termuxServiceProvider);

  if (!service.isSupported) {
    if (!context.mounted) return false;
    await _showMessage(
      context,
      title: l10n.termuxMissingTitle,
      message: l10n.errorUnsupported,
    );
    return false;
  }

  try {
    if (!await service.isTermuxInstalled()) {
      if (!context.mounted) return false;
      await _showInstallDialog(context);
      return false;
    }
    var granted = await service.hasRunCommandPermission();
    if (!granted) {
      if (!context.mounted) return false;
      granted = await showConfirmDialog(
        context,
        title: l10n.termuxPermissionTitle,
        message: l10n.termuxPermissionBody,
        confirmLabel: l10n.grantPermission,
        cancelLabel: l10n.cancel,
      );
      if (!granted) return false;
      granted = await service.requestRunCommandPermission();
      if (!granted) {
        if (!context.mounted) return false;
        await _showMessage(
          context,
          title: l10n.termuxPermissionTitle,
          message: l10n.termuxPermissionBody,
          actionLabel: l10n.openTermux,
          onAction: service.openTermuxAppInfo,
        );
        return false;
      }
    }

    if (!context.mounted) return false;
    final risk = CommandRiskAnalyzer.analyze(items.map((item) => item.command));
    final defaultBackground =
        backgroundOverride ??
        items.every((item) => item.runMode == CommandRunMode.background);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _RunConfirmSheet(
        label: label,
        items: items,
        risk: risk,
        defaultBackground: defaultBackground,
      ),
    );
    if (confirmed == null) return false;

    final sent = await service.runCommands(
      items.map((item) => item.command).toList(growable: false),
      background: confirmed,
      label: label,
    );
    if (!context.mounted) return false;
    if (sent > 0) {
      context.showSnack(l10n.commandSentToTermux);
      return true;
    }
    return false;
  } on AppException catch (error) {
    if (!context.mounted) return false;
    if (error.code == AppErrorCode.termuxExternalAppsDisabled) {
      await showExternalAppsDialog(context);
    } else if (error.code == AppErrorCode.termuxMissing) {
      await _showInstallDialog(context);
    } else if (error.code == AppErrorCode.termuxPermissionMissing) {
      await _showMessage(
        context,
        title: l10n.termuxPermissionTitle,
        message: l10n.termuxPermissionBody,
        actionLabel: l10n.openTermux,
        onAction: service.openTermuxAppInfo,
      );
    } else {
      context.showErrorSnack(error);
    }
    return false;
  } catch (error) {
    if (context.mounted) context.showErrorSnack(error);
    return false;
  }
}

Future<void> _showInstallDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final getTermux = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.termuxMissingTitle),
      content: Text(l10n.termuxMissingBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.close),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.getTermux),
        ),
      ],
    ),
  );
  if (getTermux == true && context.mounted) {
    await openExternalUrl(context, _termuxReleasesUrl);
  }
}

Future<void> _showMessage(
  BuildContext context, {
  required String title,
  required String message,
  String? actionLabel,
  Future<void> Function()? onAction,
}) async {
  final l10n = AppLocalizations.of(context);
  final action = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.close),
        ),
        if (actionLabel != null && onAction != null)
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
      ],
    ),
  );
  if (action == true && onAction != null) await onAction();
}

/// Also used by the Termux guide to explain the required Termux setting.
Future<void> showExternalAppsDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final openGuide = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.termuxExternalAppsTitle),
      content: Text(l10n.termuxExternalAppsBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.close),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.termuxGuide),
        ),
      ],
    ),
  );
  if (openGuide == true && context.mounted) {
    context.push('/termux-guide');
  }
}

const _termuxReleasesUrl = 'https://github.com/termux/termux-app/releases';

class _RunConfirmSheet extends StatefulWidget {
  const _RunConfirmSheet({
    required this.label,
    required this.items,
    required this.risk,
    required this.defaultBackground,
  });

  final String label;
  final List<TermuxRunItem> items;
  final CommandRisk risk;
  final bool defaultBackground;

  @override
  State<_RunConfirmSheet> createState() => _RunConfirmSheetState();
}

class _RunConfirmSheetState extends State<_RunConfirmSheet> {
  late bool _background = widget.defaultBackground;
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.appColors;
    final requiresAcknowledgement = widget.risk.hasWarnings;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.42,
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
                AppSpacing.x4,
              ),
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.scheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.medium,
                      ),
                      child: Icon(
                        Icons.terminal_rounded,
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
                            l10n.runConfirmationTitle,
                            style: context.texts.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                Text(
                  l10n.runConfirmationBody,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                if (widget.risk.hasWarnings) ...[
                  const SizedBox(height: AppSpacing.x4),
                  AppNote(
                    title: widget.risk.isHigh
                        ? l10n.riskWarningTitle
                        : l10n.riskMedium,
                    message: [
                      l10n.riskWarningBody,
                      for (final reason in widget.risk.reasons)
                        '• ${riskReasonLabel(l10n, reason)}',
                    ].join('\n'),
                    tone: widget.risk.isHigh
                        ? AppNoteTone.danger
                        : AppNoteTone.warning,
                  ),
                ],
                const SizedBox(height: AppSpacing.x4),
                Text(l10n.steps, style: context.texts.titleSmall),
                const SizedBox(height: AppSpacing.x2),
                for (var index = 0; index < widget.items.length; index++) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                    child: CommandCodeBlock(
                      command: widget.items[index].command,
                      label:
                          '${l10n.stepNumber(index + 1)} · ${widget.items[index].title}',
                      dense: true,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x2),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x3),
                  decoration: BoxDecoration(
                    color: palette.cardMuted,
                    borderRadius: AppRadius.medium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.termuxExternalAppsTitle,
                        style: context.texts.labelMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.termuxExternalAppsBody,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.runBackground),
                  subtitle: Text(l10n.runBackgroundHelper),
                  value: _background,
                  onChanged: (value) => setState(() => _background = value),
                ),
                if (requiresAcknowledgement) ...[
                  const SizedBox(height: AppSpacing.x1),
                  CheckboxListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _acknowledged,
                    onChanged: (value) =>
                        setState(() => _acknowledged = value ?? false),
                    title: Text(l10n.riskAcknowledge),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x3,
              AppSpacing.x5,
              AppSpacing.x4,
            ),
            decoration: BoxDecoration(
              color: palette.card,
              border: Border(
                top: BorderSide(
                  color: context.scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.commandNotRun,
                    textAlign: TextAlign.center,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: requiresAcknowledgement && !_acknowledged
                              ? null
                              : () => Navigator.of(context).pop(_background),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l10n.confirmRun),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
