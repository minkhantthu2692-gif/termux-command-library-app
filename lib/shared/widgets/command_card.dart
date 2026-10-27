import 'package:flutter/material.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/command_post.dart';
import '../../data/models/user_profile.dart';
import '../utils/category_visual.dart';
import 'avatar_bubble.dart';
import 'status_pill.dart';

/// Primary list representation of a guide. The card is intentionally flat: the
/// outline and typography carry the hierarchy, not nested surfaces or shadows.
class CommandCard extends StatelessWidget {
  const CommandCard({
    super.key,
    required this.command,
    required this.onTap,
    this.preferences,
    this.onFavorite,
    this.onPin,
    this.compact = false,
    this.showAuthor = false,
  });

  final CommandSummary command;
  final VoidCallback onTap;
  final UserPreferences? preferences;
  final VoidCallback? onFavorite;
  final VoidCallback? onPin;
  final bool compact;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    final texts = context.texts;
    final visual = CategoryVisual.of(command.categoryId);
    final isFavorite = preferences?.isFavorite(command.id) ?? false;
    final isPinned = preferences?.isPinned(command.id) ?? false;
    final categoryTitle = command.category == null
        ? command.categoryId
        : categoryLabel(l10n, command.categoryId);

    return Semantics(
      button: true,
      label: '${command.name}. $categoryTitle',
      child: Material(
        color: context.appColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.x4,
              compact ? AppSpacing.x3 : AppSpacing.x4,
              onFavorite != null || onPin != null
                  ? AppSpacing.x1
                  : AppSpacing.x4,
              compact ? AppSpacing.x3 : AppSpacing.x4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 34 : 40,
                      height: compact ? 34 : 40,
                      decoration: BoxDecoration(
                        color: visual.color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        visual.icon,
                        size: compact ? AppIconSizes.sm : AppIconSizes.md,
                        color: visual.color,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            command.name,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (compact ? texts.titleSmall : texts.titleMedium)
                                    ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.x1),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  categoryTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: texts.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(width: AppSpacing.x2),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: scheme.outline,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.x2),
                                Text(
                                  l10n.stepCount(command.stepCount),
                                  style: texts.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onFavorite != null)
                      _QuickAction(
                        icon: isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isFavorite
                            ? context.appColors.star
                            : scheme.onSurfaceVariant,
                        tooltip: isFavorite
                            ? l10n.removeFromFavorites
                            : l10n.addToFavorites,
                        onPressed: onFavorite!,
                      ),
                    if (onPin != null)
                      _QuickAction(
                        icon: isPinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        color: isPinned
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        tooltip: isPinned ? l10n.unpinCommand : l10n.pinCommand,
                        onPressed: onPin!,
                      ),
                  ],
                ),
                if (!compact && command.description.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    command.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: texts.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x3),
                Wrap(
                  spacing: AppSpacing.x1,
                  runSpacing: AppSpacing.x1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CommandStatusPills(
                      status: command.status,
                      isSeed: command.isSeed,
                      isPendingSync: command.isPendingSync,
                    ),
                    if (command.tags.isNotEmpty)
                      for (final tag in command.tags.take(compact ? 1 : 2))
                        StatusPill(
                          label: '#$tag',
                          tone: StatusPillTone.neutral,
                        ),
                  ],
                ),
                if (showAuthor) ...[
                  const SizedBox(height: AppSpacing.x3),
                  Row(
                    children: [
                      AvatarBubble(avatarId: AppAvatars.defaultId, size: 20),
                      const SizedBox(width: AppSpacing.x2),
                      Expanded(
                        child: Text(
                          command.isSeed
                              ? l10n.curatedBy
                              : l10n.byAuthor(
                                  command.authorNickname.trim().isEmpty
                                      ? l10n.member
                                      : command.authorNickname,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: texts.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: AppIconSizes.sm),
      color: color,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }
}
