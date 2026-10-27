import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/app/theme/app_theme.dart';

void main() {
  group('AppTheme font scaling', () {
    test('builds for every supported scale without throwing', () {
      final settings = AppSettings.defaults('local-guest');
      for (final scale in <double>[0.85, 1.0, 1.15, 1.3, 1.5, double.nan]) {
        expect(
          () => AppTheme.build(
            settings.copyWith(fontScale: scale),
            Brightness.light,
          ),
          returnsNormally,
          reason: 'scale $scale must not assert',
        );
      }
    });

    test('every Material text style has an explicit size', () {
      final theme = AppTheme.build(
        AppSettings.defaults('local-guest').copyWith(fontScale: 1.3),
        Brightness.light,
      );
      final styles = <String, TextStyle?>{
        'displayLarge': theme.textTheme.displayLarge,
        'displayMedium': theme.textTheme.displayMedium,
        'displaySmall': theme.textTheme.displaySmall,
        'headlineLarge': theme.textTheme.headlineLarge,
        'headlineMedium': theme.textTheme.headlineMedium,
        'headlineSmall': theme.textTheme.headlineSmall,
        'titleLarge': theme.textTheme.titleLarge,
        'titleMedium': theme.textTheme.titleMedium,
        'titleSmall': theme.textTheme.titleSmall,
        'bodyLarge': theme.textTheme.bodyLarge,
        'bodyMedium': theme.textTheme.bodyMedium,
        'bodySmall': theme.textTheme.bodySmall,
        'labelLarge': theme.textTheme.labelLarge,
        'labelMedium': theme.textTheme.labelMedium,
        'labelSmall': theme.textTheme.labelSmall,
      };
      for (final entry in styles.entries) {
        expect(
          entry.value?.fontSize,
          isNotNull,
          reason: '${entry.key} must declare a fontSize',
        );
      }
    });

    test('scales the body and label sizes by the preference', () {
      final settings = AppSettings.defaults('local-guest');
      final normal = AppTheme.build(settings, Brightness.light).textTheme;
      final large = AppTheme.build(
        settings.copyWith(fontScale: 1.3),
        Brightness.light,
      ).textTheme;

      expect(normal.bodyMedium?.fontSize, 14);
      expect(large.bodyMedium?.fontSize, closeTo(14 * 1.3, 0.001));
      expect(large.labelSmall?.fontSize, closeTo(11 * 1.3, 0.001));
      expect(large.headlineSmall?.fontSize, closeTo(21 * 1.3, 0.001));
    });

    test('clamps out-of-range preferences instead of overshooting', () {
      final settings = AppSettings.defaults('local-guest');
      final theme = AppTheme.build(
        settings.copyWith(fontScale: 5),
        Brightness.light,
      ).textTheme;
      expect(theme.bodyMedium?.fontSize, closeTo(14 * 1.35, 0.001));
    });
  });

  testWidgets('a non-default font scale can render text', (tester) async {
    final theme = AppTheme.build(
      AppSettings.defaults('local-guest').copyWith(fontScale: 1.3),
      Brightness.light,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: Text('Termux Command Library')),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Termux Command Library'), findsOneWidget);
  });
}
