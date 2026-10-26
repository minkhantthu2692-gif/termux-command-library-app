import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';

/// Translucent surface used sparingly for the bottom navigation and a few
/// floating elements. It respects the user's blur preference and falls back to
/// an opaque card when blur is disabled (or on low-end devices).
class GlassSurface extends ConsumerWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.extraLarge,
    this.padding,
    this.margin,
    this.border,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final palette = context.appColors;
    final blurred = settings.blurEnabled && settings.blurIntensity > 0;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: palette.glassTint,
        borderRadius: borderRadius,
        border: border ?? Border.all(color: palette.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: blurred
              ? ImageFilter.blur(
                  sigmaX: settings.blurIntensity,
                  sigmaY: settings.blurIntensity,
                )
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}
