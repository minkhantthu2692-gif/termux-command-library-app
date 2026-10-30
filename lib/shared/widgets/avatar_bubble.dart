import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/user_profile.dart';

/// Illustration asset for a persisted avatar id. Ids are stored in profiles and
/// Firestore, so the artwork is mapped by id instead of renaming the records.
String avatarAsset(String id) =>
    'assets/avatars/${AppAvatars.normalize(id)}.svg';

/// Solid backdrop of each illustration. Kept in sync with the first `<rect>` in
/// the matching SVG so the bubble never flashes an unrelated color while the
/// asset decodes, and so a missing asset still leaves a tidy circle.
const _avatarBackgrounds = <String, Color>{
  'orbit': Color(0xFFAEBDF2),
  'sprout': Color(0xFFBFD8B8),
  'wave': Color(0xFFA9D3E6),
  'sun': Color(0xFFF3C99B),
  'moon': Color(0xFFC9BCE8),
  'spark': Color(0xFFF2C0B2),
  'leaf': Color(0xFFA8D8C8),
  'pixel': Color(0xFFF0D992),
  'person': Color(0xFFC9D0DC),
};

Color avatarBackground(String id) =>
    _avatarBackgrounds[AppAvatars.normalize(id)] ??
    _avatarBackgrounds[AppAvatars.defaultId]!;

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
    final id = AppAvatars.normalize(avatarId);
    final background = avatarBackground(id);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
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
                  color: background.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      // The border insets the child, so the illustration never paints over it.
      child: ClipOval(
        child: SvgPicture.asset(
          avatarAsset(id),
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
        ),
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
