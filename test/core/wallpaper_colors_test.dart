import 'package:dynamic_color_testing/dynamic_color_testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/theme/wallpaper_colors.dart';

void main() {
  testWidgets('maps the platform palette to light and dark schemes', (
    tester,
  ) async {
    DynamicColorTestingUtils.setMockDynamicColors(
      corePalette: SampleCorePalettes.green,
    );

    ColorScheme? light;
    ColorScheme? dark;
    await tester.pumpWidget(
      WallpaperColorBuilder(
        builder: (lightScheme, darkScheme) {
          light = lightScheme;
          dark = darkScheme;
          return const SizedBox.shrink();
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(light, isNotNull);
    expect(dark, isNotNull);
    expect(light!.brightness, Brightness.light);
    expect(dark!.brightness, Brightness.dark);

    // Android's exact tonal values are preserved rather than regenerated from
    // a seed, so the app matches the system palette.
    // ignore: deprecated_member_use
    expect(light!.primary, Color(SampleCorePalettes.green.primary.get(40)));
    // ignore: deprecated_member_use
    expect(dark!.primary, Color(SampleCorePalettes.green.primary.get(80)));
  });

  testWidgets('reports no palette when the platform does not provide one', (
    tester,
  ) async {
    DynamicColorTestingUtils.setMockDynamicColors();

    ColorScheme? light;
    ColorScheme? dark;
    await tester.pumpWidget(
      WallpaperColorBuilder(
        builder: (lightScheme, darkScheme) {
          light = lightScheme;
          dark = darkScheme;
          return const SizedBox.shrink();
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(light, isNull);
    expect(dark, isNull);
    expect(tester.takeException(), isNull);
  });
}
