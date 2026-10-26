import 'package:flutter/material.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/command_post.dart';

enum StatusPillTone { neutral, primary, warning, success, danger }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = StatusPillTone.neutral,
    this.dense = true,
  });

  final String label;
  final IconData? icon;
  final StatusPillTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final palette = context.appColors;
    final (background, foreground) = switch (tone) {
      StatusPillTone.primary => (
        scheme.primary.withValues(alpha: 0.11),
        scheme.primary,
      ),
      StatusPillTone.warning => (
        palette.warning.withValues(alpha: 0.13),
        palette.warning,
      ),
      StatusPillTone.success => (
        palette.success.withValues(alpha: 0.12),
        palette.success,
      ),
      StatusPillTone.danger => (
        scheme.error.withValues(alpha: 0.11),
        scheme.error,
      ),
      StatusPillTone.neutral => (palette.cardMuted, scheme.onSurfaceVariant),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.x2 : AppSpacing.x3,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.5, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: dense ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class CommandStatusPills extends StatelessWidget {
  const CommandStatusPills({
    super.key,
    required this.status,
    this.isSeed = false,
    this.isPendingSync = false,
  });

  final CommandStatus status;
  final bool isSeed;
  final bool isPendingSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.x1,
      runSpacing: AppSpacing.x1,
      children: [
        if (status == CommandStatus.draft)
          StatusPill(
            label: l10n.draftBadge,
            icon: Icons.edit_note_rounded,
            tone: StatusPillTone.warning,
          ),
        if (isSeed)
          StatusPill(
            label: l10n.seedBadge,
            icon: Icons.verified_rounded,
            tone: StatusPillTone.success,
          ),
        if (isPendingSync)
          StatusPill(
            label: l10n.pendingSyncBadge,
            icon: Icons.sync_rounded,
            tone: StatusPillTone.primary,
          ),
      ],
    );
  }
}
