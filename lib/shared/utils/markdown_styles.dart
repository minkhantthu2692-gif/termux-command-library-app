import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../app/theme/app_theme.dart';
import '../../core/design_system/app_tokens.dart';

/// Shared Markdown presentation for assistant answers and bundled docs. Keeping
/// it in one place means code blocks, links and spacing stay consistent.
MarkdownStyleSheet appMarkdownStyle(BuildContext context) {
  final theme = Theme.of(context);
  final base = MarkdownStyleSheet.fromTheme(theme);
  final scheme = theme.colorScheme;
  final codeBackground = context.appColors.cardMuted;
  return base.copyWith(
    p: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
    h1: theme.textTheme.titleLarge?.copyWith(height: 1.3),
    h2: theme.textTheme.titleMedium?.copyWith(height: 1.3),
    h3: theme.textTheme.titleSmall?.copyWith(height: 1.3),
    strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
    a: theme.textTheme.bodyMedium?.copyWith(
      color: scheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary,
    ),
    code: context.monoStyle.copyWith(
      backgroundColor: codeBackground,
      color: scheme.onSurface,
      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * 0.9,
    ),
    codeblockDecoration: BoxDecoration(
      color: context.appColors.codeBackground,
      borderRadius: AppRadius.medium,
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
    ),
    codeblockPadding: const EdgeInsets.all(AppSpacing.x3),
    blockquoteDecoration: BoxDecoration(
      color: scheme.primary.withValues(alpha: 0.06),
      borderRadius: AppRadius.small,
      border: Border(left: BorderSide(color: scheme.primary, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.all(AppSpacing.x3),
    listBullet: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),
    tableHead: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
    tableBody: theme.textTheme.bodySmall,
    tableBorder: TableBorder.all(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
      width: 1,
    ),
  );
}
