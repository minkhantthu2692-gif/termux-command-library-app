import 'package:flutter/material.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../../core/design_system/app_tokens.dart';

/// Displays a command exactly as stored. Text is selectable and softly wraps so
/// multi-line shell snippets, quoting and whitespace remain visible without
/// transforming the content.
class CommandCodeBlock extends StatelessWidget {
  const CommandCodeBlock({
    super.key,
    required this.command,
    this.onCopy,
    this.onRun,
    this.label,
    this.dense = false,
    this.showLineNumbers = false,
  });

  final String command;
  final VoidCallback? onCopy;
  final VoidCallback? onRun;
  final String? label;
  final bool dense;
  final bool showLineNumbers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.appColors;
    final scheme = context.scheme;
    final style = context.monoStyle.copyWith(
      fontSize: dense ? 13 : 13.5,
      color: scheme.onSurface,
    );
    final lines = command.split('\n');
    return Container(
      decoration: BoxDecoration(
        color: palette.codeBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(color: palette.codeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.x3,
              dense ? AppSpacing.x1 : AppSpacing.x2,
              AppSpacing.x1,
              dense ? AppSpacing.x1 : AppSpacing.x2,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal_rounded,
                  size: AppIconSizes.xs,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    label ?? l10n.commandsTab,
                    style: context.texts.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    tooltip: l10n.copyCommand,
                    visualDensity: VisualDensity.compact,
                    iconSize: AppIconSizes.sm,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded),
                  ),
                if (onRun != null)
                  IconButton(
                    tooltip: l10n.runViaTermux,
                    visualDensity: VisualDensity.compact,
                    iconSize: AppIconSizes.sm,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    onPressed: onRun,
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
              ],
            ),
          ),
          Divider(color: palette.codeBorder, height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(dense ? AppSpacing.x3 : AppSpacing.x4),
            child: showLineNumbers && lines.length > 1
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        List.generate(
                          lines.length,
                          (index) => '${index + 1}',
                        ).join('\n'),
                        style: style.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Text(command, style: style),
                    ],
                  )
                : SelectableText(
                    command,
                    style: style,
                    // Preserve every line break and space; the user may be
                    // copying a script rather than a single command.
                  ),
          ),
        ],
      ),
    );
  }
}
