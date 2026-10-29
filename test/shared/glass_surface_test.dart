import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/providers.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/app/theme/app_theme.dart';
import 'package:termux_command_library/core/design_system/app_tokens.dart';
import 'package:termux_command_library/shared/widgets/glass_surface.dart';

/// Bypasses the repository-backed settings controller so the widget can be
/// tested with an exact [AppSettings] value.
class _TestSettingsController extends SettingsController {
  _TestSettingsController(this.initial);

  final AppSettings initial;

  @override
  AppSettings build() => initial;
}

void main() {
  final defaults = AppSettings.defaults('test-guest');

  Future<void> pumpSurface(WidgetTester tester, AppSettings settings) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith(
            () => _TestSettingsController(settings),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(settings, Brightness.light),
          home: const Scaffold(
            body: Center(
              child: GlassSurface(child: SizedBox(width: 240, height: 64)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(GlassSurface),
        matching: find.byType(Container),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('enabled blur paints a backdrop filter at the chosen sigma', (
    tester,
  ) async {
    await pumpSurface(
      tester,
      defaults.copyWith(blurEnabled: true, blurIntensity: 18),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(filter.filter.toString(), contains('18.0'));
    expect(decorationOf(tester).color, AppColors.light.glassTint);
  });

  testWidgets('disabling blur removes the filter and uses an opaque card', (
    tester,
  ) async {
    await pumpSurface(
      tester,
      defaults.copyWith(blurEnabled: false, blurIntensity: 18),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(decorationOf(tester).color, AppColors.light.card);
    expect(decorationOf(tester).color!.a, 1);
  });

  testWidgets('a zero intensity falls back to the opaque card', (tester) async {
    await pumpSurface(
      tester,
      defaults.copyWith(blurEnabled: true, blurIntensity: 0),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(decorationOf(tester).color, AppColors.light.card);
  });

  testWidgets('sigma is clamped to the supported maximum', (tester) async {
    await pumpSurface(
      tester,
      defaults.copyWith(blurEnabled: true, blurIntensity: 99),
    );

    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(
      filter.filter.toString(),
      contains(GlassSurface.maxBlurSigma.toStringAsFixed(1)),
    );
  });
}
