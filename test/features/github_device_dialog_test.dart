import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/app/localization/generated/app_localizations.dart';
import 'package:termux_command_library/core/errors/app_exception.dart';
import 'package:termux_command_library/data/models/auth_models.dart';
import 'package:termux_command_library/features/authentication/widgets/github_device_dialog.dart';

void main() {
  const session = AuthSession(
    uid: 'github-1',
    email: 'octocat@example.com',
    displayName: 'Octocat',
    isAnonymous: false,
    isAdmin: false,
    isLocalOnly: false,
  );

  Future<Future<AuthSession?>> showDialogUnderTest(
    WidgetTester tester, {
    required Future<GithubDeviceSignIn> Function() start,
    Future<void> Function(String code)? onCopy,
    Future<bool> Function(Uri uri)? onOpen,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    final result = showDialog<AuthSession>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GithubDeviceDialog(
        start: start,
        onCopyCode: onCopy ?? (_) async {},
        onOpenUri: onOpen ?? (_) async => true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    return result;
  }

  testWidgets('shows the code, opens GitHub, copies and returns the session', (
    tester,
  ) async {
    final challenge = _FakeChallenge();
    final copied = <String>[];
    final opened = <Uri>[];
    final result = await showDialogUnderTest(
      tester,
      start: () async => challenge.signIn,
      onCopy: (code) async => copied.add(code),
      onOpen: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    expect(find.text('Connect GitHub'), findsOneWidget);
    expect(find.text('ABCD-1234'), findsOneWidget);
    expect(
      find.text('Waiting for you to authorize on GitHub…'),
      findsOneWidget,
    );
    expect(opened, [Uri.parse('https://github.com/login/device')]);

    await tester.tap(find.byTooltip('Copy code'));
    await tester.pump();
    expect(copied, ['ABCD-1234']);
    expect(find.byTooltip('Code copied'), findsOneWidget);

    challenge.result.complete(session);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(await result, session);
    expect(find.text('Connect GitHub'), findsNothing);
  });

  testWidgets('cancel stops polling and returns null', (tester) async {
    final challenge = _FakeChallenge();
    final result = await showDialogUnderTest(
      tester,
      start: () async => challenge.signIn,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(challenge.cancelled, isTrue);
    expect(await result, isNull);
    expect(find.text('Connect GitHub'), findsNothing);
  });

  testWidgets('shows a disabled-flow error and can request a new code', (
    tester,
  ) async {
    final first = _FakeChallenge();
    final second = _FakeChallenge();
    var starts = 0;
    final result = await showDialogUnderTest(
      tester,
      start: () async {
        starts++;
        return starts == 1 ? first.signIn : second.signIn;
      },
    );

    first.result.completeError(
      const AppException(AppErrorCode.authDeviceFlowDisabled),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Try again'), findsOneWidget);
    expect(
      find.text(
        'GitHub sign-in is not available. The app owner must enable Device Flow in the GitHub OAuth app.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(starts, 2);
    expect(find.text('ABCD-1234'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(await result, isNull);
  });

  testWidgets('shows a start failure and retries', (tester) async {
    final challenge = _FakeChallenge();
    var starts = 0;
    final result = await showDialogUnderTest(
      tester,
      start: () async {
        starts++;
        if (starts == 1) {
          throw const AppException(AppErrorCode.network);
        }
        return challenge.signIn;
      },
    );

    expect(
      find.text('No connection. Check your network and try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(starts, 2);
    expect(find.text('ABCD-1234'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(await result, isNull);
  });

  testWidgets('explains when the browser could not be opened', (tester) async {
    final challenge = _FakeChallenge();
    await showDialogUnderTest(
      tester,
      start: () async => challenge.signIn,
      onOpen: (_) async => false,
    );
    await tester.pump();

    expect(
      find.text(
        'Could not open the browser. Visit github.com/login/device manually.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders localized Myanmar copy', (tester) async {
    final challenge = _FakeChallenge();
    await showDialogUnderTest(
      tester,
      start: () async => challenge.signIn,
      locale: const Locale('my'),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(GithubDeviceDialog)),
    );

    expect(find.text(l10n.githubDeviceTitle), findsOneWidget);
    expect(find.text(l10n.githubDeviceInstructions), findsOneWidget);
    expect(find.text(l10n.githubDeviceWaiting), findsOneWidget);
  });
}

class _FakeChallenge {
  final result = Completer<AuthSession>();
  bool cancelled = false;

  late final GithubDeviceSignIn signIn = GithubDeviceSignIn(
    userCode: 'ABCD-1234',
    verificationUri: Uri.parse('https://github.com/login/device'),
    expiresAt: DateTime.utc(2026, 10, 28, 12, 15),
    result: result.future,
    cancel: () => cancelled = true,
  );
}
