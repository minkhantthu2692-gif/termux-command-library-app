import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design_system/app_tokens.dart';

/// Translucent surface used sparingly for the bottom navigation and the bottom
/// action bars. It respects the user's blur preference.
///
/// Blur only produces a visible effect when content is painted behind the
/// surface. Callers must therefore place the surface over a scrolling body
/// (for example with `Scaffold.extendBody`) rather than in a layout slot that
/// reserves its own space. When blur is disabled, or the intensity is zero,
/// the surface falls back to an opaque card so text underneath cannot reduce
/// readability.
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

  /// Upper bound mirrors the settings repository, which clamps the persisted
  /// value to the same range.
  static const double maxBlurSigma = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final palette = context.appColors;
    final sigma = settings.blurEnabled
        ? settings.blurIntensity.clamp(0.0, maxBlurSigma)
        : 0.0;
    final blurred = sigma > 0;

    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        // The opaque fallback makes the enable/disable toggle unambiguous and
        // keeps labels readable when no blur layer is present.
        color: blurred ? palette.glassTint : palette.card,
        borderRadius: borderRadius,
        border: border ?? Border.all(color: palette.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: blurred
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: content,
              )
            : content,
      ),
    );
  }
}
