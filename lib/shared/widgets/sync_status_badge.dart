import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/auth_models.dart';
import '../utils/app_formatters.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({
    super.key,
    this.compact = false,
    this.showTime = true,
    this.iconSize = 14,
  });

  final bool compact;
  final bool showTime;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider).value ?? SyncStatus.localOnly;
    final cloud = ref.watch(appDependenciesProvider).cloudConfigured;
    final scheme = context.scheme;
    final palette = context.appColors;

    final (IconData icon, Color color, String label) = !cloud
        ? (Icons.cloud_off_rounded, scheme.onSurfaceVariant, l10n.localOnly)
        : status.phase == SyncPhase.error
        ? (Icons.cloud_off_rounded, scheme.error, l10n.syncError)
        : status.phase == SyncPhase.syncing
        ? (Icons.sync_rounded, scheme.primary, l10n.syncingNow)
        : status.pendingOperations > 0
        ? (
            Icons.cloud_upload_outlined,
            palette.warning,
            l10n.syncPending(status.pendingOperations),
          )
        : (
            Icons.cloud_done_outlined,
            palette.success,
            status.lastSyncedAt != null && showTime
                ? l10n.lastSynced(
                    AppFormatters.relativeTime(
                      context,
                      l10n,
                      status.lastSyncedAt!,
                    ),
                  )
                : l10n.syncComplete,
          );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        if (!compact) ...[
          const SizedBox(width: AppSpacing.x1 + 2),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );

    if (compact) {
      return Tooltip(message: label, child: content);
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x1 + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: content,
    );
  }
}
