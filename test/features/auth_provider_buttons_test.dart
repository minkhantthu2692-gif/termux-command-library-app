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
    Duration slowHintDelay = const Duration(seconds: 45),
    Locale locale = const Locale('en'),
  }) async {
    final taps = <AuthProviderKind>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AuthProviderButtons(
                enabled: enabled,
                busyProvider: busy,
                slowHintDelay: slowHintDelay,
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

  Finder googleButton() => find.byKey(const ValueKey('auth_provider_google'));
  Finder githubButton() => find.byKey(const ValueKey('auth_provider_github'));

  testWidgets('shows compact icon buttons and reports the selection', (
    tester,
  ) async {
    final taps = await pumpButtons(tester);
    expect(googleButton(), findsOneWidget);
    expect(githubButton(), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    expect(find.byTooltip('Continue with Google'), findsOneWidget);
    expect(find.byTooltip('Continue with GitHub'), findsOneWidget);

    await tester.tap(googleButton());
    await tester.tap(githubButton());
    expect(taps, [AuthProviderKind.google, AuthProviderKind.github]);
  });

  testWidgets('shows progress on the active provider and disables both', (
    tester,
  ) async {
    final taps = await pumpButtons(tester, busy: AuthProviderKind.google);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The inactive provider keeps its icon but must not accept taps.
    expect(find.byTooltip('Continue with GitHub'), findsOneWidget);

    await tester.tap(githubButton());
    await tester.tap(googleButton());
    await tester.pump();
    expect(taps, isEmpty);
  });

  testWidgets('disables both providers when the screen is busy', (
    tester,
  ) async {
    final taps = await pumpButtons(tester, enabled: false);
    final buttons = tester
        .widgetList<OutlinedButton>(find.byType(OutlinedButton))
        .toList();
    expect(buttons, hasLength(2));
    expect(buttons.every((button) => button.onPressed == null), isTrue);

    await tester.tap(githubButton());
    expect(taps, isEmpty);
  });

  testWidgets('renders localized Myanmar tooltips and divider', (tester) async {
    await pumpButtons(tester, locale: const Locale('my'));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AuthProviderButtons)),
    );
    expect(find.text(l10n.orContinueWith), findsOneWidget);
    expect(find.byTooltip(l10n.continueWithGoogle), findsOneWidget);
    expect(find.byTooltip(l10n.continueWithGithub), findsOneWidget);
  });

  testWidgets('suggests recovery when the provider flow is slow', (
    tester,
  ) async {
    await pumpButtons(
      tester,
      busy: AuthProviderKind.google,
      slowHintDelay: const Duration(seconds: 1),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AuthProviderButtons)),
    );
    expect(find.text(l10n.providerSignInSlow), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text(l10n.providerSignInSlow), findsOneWidget);
  });

  testWidgets('hides the slow hint once the provider flow settles', (
    tester,
  ) async {
    await pumpButtons(
      tester,
      busy: AuthProviderKind.github,
      slowHintDelay: const Duration(seconds: 1),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AuthProviderButtons)),
    );
    expect(find.text(l10n.providerSignInSlow), findsOneWidget);

    await pumpButtons(tester);
    expect(find.text(l10n.providerSignInSlow), findsNothing);
  });
}
