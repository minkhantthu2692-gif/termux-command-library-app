import 'package:flutter/material.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/user_profile.dart';

IconData avatarIcon(String id) => switch (id) {
  'sprout' => Icons.eco_rounded,
  'wave' => Icons.waves_rounded,
  'sun' => Icons.wb_sunny_rounded,
  'moon' => Icons.dark_mode_rounded,
  'spark' => Icons.auto_awesome_rounded,
  'leaf' => Icons.spa_rounded,
  'pixel' => Icons.grid_view_rounded,
  _ => Icons.blur_on_rounded,
};

int avatarColorIndex(String id) {
  final index = AppAvatars.all.indexOf(id);
  return index < 0 ? 0 : index;
}

class AvatarBubble extends StatelessWidget {
  const AvatarBubble({
    super.key,
    required this.avatarId,
    this.size = AppSizes.avatar,
    this.borderColor,
    this.showBorder = false,
  });

  final String avatarId;
  final double size;
  final Color? borderColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final color =
        palette.avatarPalette[avatarColorIndex(AppAvatars.normalize(avatarId)) %
            palette.avatarPalette.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.18)!],
        ),
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? Theme.of(context).colorScheme.surface,
                width: size > 60 ? 4 : 2.5,
              )
            : null,
        boxShadow: size >= 64
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Icon(
        avatarIcon(AppAvatars.normalize(avatarId)),
        size: size * 0.46,
        color: Colors.white.withValues(alpha: 0.96),
      ),
    );
  }
}

/// Modal grid for choosing one of the built-in avatars. Profile images are
/// intentionally local; no Firebase Storage upload is involved.
Future<String?> showAvatarPicker(
  BuildContext context, {
  required String selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _AvatarPickerSheet(selectedId: selectedId),
  );
}

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({required this.selectedId});

  final String selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x5,
          0,
          AppSpacing.x5,
          AppSpacing.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectAvatar, style: context.texts.titleLarge),
            const SizedBox(height: AppSpacing.x2),
            Text(
              l10n.builtInAvatars,
              style: context.texts.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.x3,
              crossAxisSpacing: AppSpacing.x3,
              children: [
                for (final id in AppAvatars.all)
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    onTap: () => Navigator.of(context).pop(id),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: id == selectedId
                              ? scheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: AvatarBubble(avatarId: id, size: 58),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
