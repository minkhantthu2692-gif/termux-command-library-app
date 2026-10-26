import 'package:flutter/material.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/ai_models.dart';
import '../../shared/utils/app_formatters.dart';

/// Reusable row for a locally stored AI conversation. The same row is used on
/// the assistant landing screen and in AI history, with an optional delete
/// action supplied by history.
class AiConversationTile extends StatelessWidget {
  const AiConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.trailing,
    this.showModel = false,
  });

  final AiConversation conversation;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = conversation.title.trim().isEmpty
        ? l10n.newChat
        : conversation.title;
    final time = AppFormatters.relativeTime(
      context,
      l10n,
      conversation.updatedAt,
    );
    final subtitle = showModel && conversation.modelId.trim().isNotEmpty
        ? '${conversation.modelId}  \u00b7  $time'
        : time;
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.medium,
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.scheme.primary.withValues(alpha: 0.09),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  Icons.forum_outlined,
                  size: AppIconSizes.sm,
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelSmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppIconSizes.md,
                    color: context.scheme.onSurfaceVariant,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
