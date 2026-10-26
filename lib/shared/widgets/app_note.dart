import 'package:flutter/material.dart';

import '../../core/design_system/app_tokens.dart';

enum AppNoteTone { neutral, info, warning, danger, success }

/// Compact inline explanation used for setup guidance, safety warnings and
/// local-only states. It never hides information behind a tooltip.
class AppNote extends StatelessWidget {
  const AppNote({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.tone = AppNoteTone.neutral,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.all(AppSpacing.x3),
  });

  final String message;
  final String? title;
  final IconData? icon;
  final AppNoteTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final palette = context.appColors;
    final (
      Color foreground,
      Color background,
      IconData defaultIcon,
    ) = switch (tone) {
      AppNoteTone.info => (
        scheme.primary,
        scheme.primary.withValues(alpha: 0.08),
        Icons.info_outline_rounded,
      ),
      AppNoteTone.warning => (
        palette.warning,
        palette.warning.withValues(alpha: 0.09),
        Icons.warning_amber_rounded,
      ),
      AppNoteTone.danger => (
        scheme.error,
        scheme.error.withValues(alpha: 0.08),
        Icons.error_outline_rounded,
      ),
      AppNoteTone.success => (
        palette.success,
        palette.success.withValues(alpha: 0.09),
        Icons.check_circle_outline_rounded,
      ),
      AppNoteTone.neutral => (
        scheme.onSurfaceVariant,
        palette.cardMuted,
        Icons.lightbulb_outline_rounded,
      ),
    };
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.medium,
        border: Border.all(color: foreground.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: AppIconSizes.sm, color: foreground),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: context.texts.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: context.texts.bodySmall?.copyWith(
                    color: tone == AppNoteTone.neutral
                        ? scheme.onSurfaceVariant
                        : foreground,
                    height: 1.5,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.x1),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: foreground,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 34),
                      alignment: Alignment.centerLeft,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
