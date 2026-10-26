import 'package:flutter/material.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../core/design_system/app_tokens.dart';

/// Simple branded mark used on the welcome, about and AI screens. It is drawn
/// with Material shapes so no raster assets are required.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44, this.showShadow = false});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.appColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.2)!,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.28),
                  blurRadius: size * 0.45,
                  offset: Offset(0, size * 0.16),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.terminal_rounded,
            color: scheme.onPrimary,
            size: size * 0.54,
          ),
          Positioned(
            right: size * 0.16,
            bottom: size * 0.14,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: palette.star,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary, width: size * 0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.size = 40, this.showTagline = false});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: size),
        const SizedBox(width: AppSpacing.x3),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Termux Library',
                style: texts.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showTagline)
                Text(
                  l10n.appTagline,
                  style: texts.bodySmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
