import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/app/settings/app_settings.dart';
import 'package:termux_command_library/app/theme/app_theme.dart';
import 'package:termux_command_library/features/authentication/widgets/auth_scaffold.dart';
import 'package:termux_command_library/shared/widgets/app_logo.dart';

void main() {
  testWidgets('authentication screens render without a logo banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          AppSettings.defaults('local-guest'),
          Brightness.light,
        ),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AuthScaffold(
          title: 'Sign in',
          subtitle: 'Pick up where you left off.',
          child: Text('form'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppLogo), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('form'), findsOneWidget);
  });
}
