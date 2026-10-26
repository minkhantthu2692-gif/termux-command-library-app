import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/ai_models.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/utils/markdown_styles.dart';
import '../../shared/utils/url_actions.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/status_pill.dart';

/// A single chat turn. Assistant answers render Markdown, while user text is
/// kept literal so shell snippets are never reinterpreted as formatting.
class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.role,
    required this.text,
    this.attachmentName = '',
    this.usage = const AiUsage(),
    this.createdAt,
    this.streaming = false,
    this.cached = false,
    this.onCopy,
  });

  final AiMessageRole role;
  final String text;
  final String attachmentName;
  final AiUsage usage;
  final DateTime? createdAt;
  final bool streaming;
  final bool cached;
  final VoidCallback? onCopy;

  bool get _isUser => role == AiMessageRole.user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    final label = _isUser ? l10n.you : l10n.aiReply;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 660),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      decoration: BoxDecoration(
        color: _isUser
            ? scheme.primary.withValues(alpha: 0.11)
            : context.appColors.card,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.lg),
          topRight: const Radius.circular(AppRadius.lg),
          bottomLeft: Radius.circular(_isUser ? AppRadius.lg : AppRadius.xs),
          bottomRight: Radius.circular(_isUser ? AppRadius.xs : AppRadius.lg),
        ),
        border: Border.all(
          color: _isUser
              ? scheme.primary.withValues(alpha: 0.2)
              : scheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.texts.labelMedium?.copyWith(
                    color: _isUser ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (cached)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.x1),
                  child: StatusPill(
                    label: l10n.cacheHit,
                    icon: Icons.bolt_rounded,
                    tone: StatusPillTone.neutral,
                  ),
                ),
              if (!_isUser && !streaming && text.trim().isNotEmpty)
                IconButton(
                  tooltip: l10n.copyResponse,
                  visualDensity: VisualDensity.compact,
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: AppIconSizes.sm),
                ),
              if (createdAt != null && !streaming)
                Text(
                  MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay.fromDateTime(createdAt!.toLocal()),
                    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                      context,
                    ),
                  ),
                  style: context.texts.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          if (attachmentName.trim().isNotEmpty) ...[
            _AttachmentLabel(name: attachmentName, isUser: _isUser),
            const SizedBox(height: AppSpacing.x2),
          ],
          if (streaming && text.isEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.x2),
                Text(
                  l10n.thinking,
                  style: context.texts.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          else if (_isUser)
            SelectableText(
              text,
              style: context.texts.bodyMedium?.copyWith(
                color: scheme.onSurface,
                height: 1.55,
              ),
            )
          else
            MarkdownBody(
              data: text,
              selectable: true,
              onTapLink: (_, href, _) {
                if (href != null && href.isNotEmpty) {
                  openExternalUrl(context, href);
                }
              },
              styleSheet: appMarkdownStyle(context),
            ),
          if (streaming && text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x1),
            Text(
              '\u258d',
              style: context.texts.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (!_isUser && !streaming && usage.totalTokens > 0) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              l10n.tokensUsed(AppFormatters.tokens(usage.totalTokens)),
              style: context.texts.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: _isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!_isUser) ...[
            const AppLogo(size: 30),
            const SizedBox(width: AppSpacing.x2),
          ],
          Flexible(child: bubble),
          if (_isUser) ...[
            const SizedBox(width: AppSpacing.x2),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: AppIconSizes.sm,
                color: scheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentLabel extends StatelessWidget {
  const _AttachmentLabel({required this.name, required this.isUser});

  final String name;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final foreground = isUser ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: AppRadius.small,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: AppIconSizes.xs,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.x1),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
