import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Resolves the Android wallpaper palette and rebuilds when it changes.
///
/// `dynamic_color`'s builder widget exposes `material_ui` color schemes, which
/// are not interchangeable with Flutter's [ColorScheme]. This widget talks to
/// the same platform channel but maps the raw Android tonal palettes onto
/// Flutter roles so the rest of the app only ever sees Flutter types.
class WallpaperColorBuilder extends StatefulWidget {
  const WallpaperColorBuilder({super.key, required this.builder});

  /// Receives null schemes until the platform answers, or when wallpaper colors
  /// are unavailable (pre-Android 12 and non-Android platforms).
  final Widget Function(ColorScheme? light, ColorScheme? dark) builder;

  @override
  State<WallpaperColorBuilder> createState() => _WallpaperColorBuilderState();
}

class _WallpaperColorBuilderState extends State<WallpaperColorBuilder>
    with WidgetsBindingObserver {
  ColorScheme? _light;
  ColorScheme? _dark;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may change their wallpaper while the app is in the background.
    // Re-reading on resume keeps the theme in sync without a cold start.
    if (state == AppLifecycleState.resumed) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      // dynamic_color 2.x still exposes the legacy CorePalette type. The
      // replacement DynamicScheme API is not available through the plugin yet.
      // ignore: deprecated_member_use
      final palette = await DynamicColorPlugin.getCorePalette();
      if (!mounted) return;
      if (palette == null) {
        if (_resolved) return;
        setState(() => _resolved = true);
        return;
      }
      setState(() {
        _resolved = true;
        _light = wallpaperScheme(palette, Brightness.light);
        _dark = wallpaperScheme(palette, Brightness.dark);
      });
    } on PlatformException {
      // A missing or failing platform implementation must never break startup.
      if (!mounted) return;
      setState(() => _resolved = true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_light, _dark);
}

/// Maps an Android core palette onto the Flutter roles the app consumes.
///
/// Surfaces, outlines and error colors are replaced by the design system in
/// [AppTheme], so only the accent roles need to come from the wallpaper.
// ignore: deprecated_member_use
ColorScheme wallpaperScheme(CorePalette palette, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: _tone(palette.primary, dark ? 80 : 40),
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  return base.copyWith(
    primary: _tone(palette.primary, dark ? 80 : 40),
    onPrimary: _tone(palette.primary, dark ? 20 : 100),
    primaryContainer: _tone(palette.primary, dark ? 30 : 90),
    onPrimaryContainer: _tone(palette.primary, dark ? 90 : 10),
    secondary: _tone(palette.secondary, dark ? 80 : 40),
    onSecondary: _tone(palette.secondary, dark ? 20 : 100),
    secondaryContainer: _tone(palette.secondary, dark ? 30 : 90),
    onSecondaryContainer: _tone(palette.secondary, dark ? 90 : 10),
    tertiary: _tone(palette.tertiary, dark ? 80 : 40),
    onTertiary: _tone(palette.tertiary, dark ? 20 : 100),
    tertiaryContainer: _tone(palette.tertiary, dark ? 30 : 90),
    onTertiaryContainer: _tone(palette.tertiary, dark ? 90 : 10),
  );
}

Color _tone(TonalPalette palette, int tone) => Color(palette.get(tone));
