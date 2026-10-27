import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/app_tokens.dart';
import '../../data/services/haptics_service.dart';
import '../utils/ui_actions.dart';

/// A headed group of settings rows. Rows sit in one surface instead of nesting
/// a card per item, which keeps the settings screens calm and scannable.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    this.title,
    this.description,
    required this.children,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
  });

  final String? title;
  final String? description;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x2,
              AppSpacing.x2,
              AppSpacing.x2,
              AppSpacing.x2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title!, style: context.texts.titleSmall),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: context.appColors.card,
            borderRadius: AppRadius.large,
            border: Border.all(
              color: context.scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  const SizedBox(height: AppSpacing.x1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsTile extends ConsumerWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
    this.hapticCue = HapticCue.selection,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  /// Cue played before [onTap]. Set to null when a parent, such as a switch
  /// row, already provides a more specific cue and must avoid a double pulse.
  final HapticCue? hapticCue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.scheme;
    final foreground = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : destructive
        ? scheme.error
        : scheme.onSurface;
    final tap = onTap;
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.medium,
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: !enabled || tap == null
            ? null
            : () {
                final cue = hapticCue;
                if (cue != null) {
                  unawaited(triggerHaptic(ref, cue: cue));
                }
                tap();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2 + 2,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: !enabled
                        ? scheme.onSurface.withValues(alpha: 0.32)
                        : destructive
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                    size: AppIconSizes.md,
                  ),
                  child: leading!,
                ),
                const SizedBox(width: AppSpacing.x3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.texts.bodyLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.texts.bodySmall?.copyWith(
                          color: !enabled
                              ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.x2),
                  child: trailing!,
                )
              else if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIconSizes.md,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends ConsumerWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    required this.onChanged,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final change = onChanged;
    void toggle(bool next) {
      unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
      change?.call(next);
    }

    return SettingsTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      enabled: change != null,
      trailing: Switch(
        value: value ?? false,
        onChanged: change == null ? null : toggle,
      ),
      onTap: change == null ? null : () => toggle(!(value ?? false)),
      // The switch and its row already share one toggle cue above.
      hapticCue: null,
    );
  }
}

class SettingsValueTile extends StatelessWidget {
  const SettingsValueTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.leading,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      onTap: onTap,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.texts.bodySmall?.copyWith(
            color: context.scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
