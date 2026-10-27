import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/data/models/auth_models.dart';
import 'package:termux_command_library/features/authentication/widgets/auth_provider_buttons.dart';

void main() {
  Future<List<AuthProviderKind>> pumpButtons(
    WidgetTester tester, {
    bool enabled = true,
    AuthProviderKind? busy,
  }) async {
    final taps = <AuthProviderKind>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AuthProviderButtons(
                enabled: enabled,
                busyProvider: busy,
                onSelected: taps.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return taps;
  }

  testWidgets('shows both providers and reports the selection', (tester) async {
    final taps = await pumpButtons(tester);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with GitHub'), findsOneWidget);
    expect(find.text('or continue with email'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with GitHub'));
    expect(taps, [AuthProviderKind.google, AuthProviderKind.github]);
  });

  testWidgets('shows progress and disables the other provider while busy', (
    tester,
  ) async {
    final taps = await pumpButtons(tester, busy: AuthProviderKind.google);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);

    await tester.tap(find.text('Continue with GitHub'));
    await tester.pump();
    expect(taps, isEmpty);
  });

  testWidgets('renders localized Myanmar labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('my'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AuthProviderButtons(
            enabled: true,
            busyProvider: null,
            onSelected: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AuthProviderButtons)),
    );
    expect(find.text(l10n.continueWithGoogle), findsOneWidget);
    expect(find.text(l10n.continueWithGithub), findsOneWidget);
  });
}

void _noop(AuthProviderKind provider) {}
