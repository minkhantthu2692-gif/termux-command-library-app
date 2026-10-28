import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/errors/app_exception.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/models/auth_models.dart';
import 'package:termux_command_library/data/remote/cloud_gateways.dart';
import 'package:termux_command_library/data/remote/github_device_client.dart';
import 'package:termux_command_library/data/repositories/auth_repository.dart';

void main() {
  late AppDatabase db;
  late _RefreshAuthGateway gateway;
  late AuthRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = _RefreshAuthGateway();
    repository = AuthRepository(
      gateway: gateway,
      cloud: null,
      profileDao: db.profileDao,
      preferenceDao: db.preferenceDao,
      commandDao: db.commandDao,
      syncDao: db.syncDao,
      localGuestUid: 'local-guest',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('a forced claim refresh publishes the new admin session', () async {
    final sessions = <AuthSession>[];
    final subscription = repository.watchSessions().listen(sessions.add);
    await pumpEventQueue();

    expect(sessions, isNotEmpty);
    expect(sessions.last.isAdmin, isFalse);

    gateway.refreshed = const AuthSession(
      uid: 'admin-1',
      email: 'admin@example.com',
      displayName: 'Admin',
      isAnonymous: false,
      isAdmin: true,
      isLocalOnly: false,
    );
    final refreshed = await repository.refreshIdentityClaims();
    await pumpEventQueue();

    expect(gateway.refreshCalls, 1);
    expect(refreshed.isAdmin, isTrue);
    // The stream must publish the claim update: Firebase Auth does not emit an
    // authStateChanges event for a token refresh.
    expect(sessions.last.isAdmin, isTrue);
    expect(sessions.last.uid, 'admin-1');

    await subscription.cancel();
  });

  test('a forced claim refresh requires cloud authentication', () async {
    final localRepository = AuthRepository(
      gateway: null,
      cloud: null,
      profileDao: db.profileDao,
      preferenceDao: db.preferenceDao,
      commandDao: db.commandDao,
      syncDao: db.syncDao,
      localGuestUid: 'local-guest',
    );

    await expectLater(
      localRepository.refreshIdentityClaims(),
      throwsA(isA<Exception>()),
    );
  });

  group('GitHub device flow', () {
    late _GithubAuthGateway githubGateway;
    late _FakeGithubDeviceClient client;
    late Completer<GithubAccessToken> tokenCompleter;
    late bool cancelled;
    late AuthRepository githubRepository;

    setUp(() {
      githubGateway = _GithubAuthGateway();
      tokenCompleter = Completer<GithubAccessToken>();
      cancelled = false;
      client = _FakeGithubDeviceClient(
        GithubDeviceAuthorization(
          userCode: 'ABCD-1234',
          verificationUri: Uri.parse('https://github.com/login/device'),
          expiresAt: DateTime.utc(2026, 10, 28, 12, 15),
          poll: () => tokenCompleter.future,
          cancel: () => cancelled = true,
        ),
      );
      githubRepository = AuthRepository(
        gateway: githubGateway,
        cloud: null,
        profileDao: db.profileDao,
        preferenceDao: db.preferenceDao,
        commandDao: db.commandDao,
        syncDao: db.syncDao,
        localGuestUid: 'local-guest',
        githubDeviceClient: client,
      );
    });

    test('exchanges the token and queues a profile sync', () async {
      final signIn = await githubRepository.startGithubDeviceSignIn();

      expect(client.starts, 1);
      expect(signIn.userCode, 'ABCD-1234');
      expect(
        signIn.verificationUri.toString(),
        'https://github.com/login/device',
      );

      tokenCompleter.complete(
        const GithubAccessToken(accessToken: 'gho_test_token'),
      );
      final session = await signIn.result;

      expect(githubGateway.receivedToken, 'gho_test_token');
      expect(githubGateway.linkedAnonymous, isFalse);
      expect(session.uid, 'github-1');
      expect(await db.profileDao.getProfile('github-1'), isNotNull);
      expect(await db.syncDao.pendingCount('github-1'), 1);
    });

    test('forwards the link-anonymous flag to the gateway', () async {
      final signIn = await githubRepository.startGithubDeviceSignIn(
        linkAnonymous: true,
      );

      tokenCompleter.complete(
        const GithubAccessToken(accessToken: 'gho_test_token'),
      );
      await signIn.result;

      expect(githubGateway.linkedAnonymous, isTrue);
    });

    test('cancel stops the pending authorization', () async {
      final signIn = await githubRepository.startGithubDeviceSignIn();

      signIn.cancel();
      expect(cancelled, isTrue);

      tokenCompleter.completeError(
        const AppException(AppErrorCode.authCancelled),
      );
      await expectLater(
        signIn.result,
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.authCancelled,
          ),
        ),
      );
    });

    test('requires a configured device client', () async {
      final withoutClient = AuthRepository(
        gateway: githubGateway,
        cloud: null,
        profileDao: db.profileDao,
        preferenceDao: db.preferenceDao,
        commandDao: db.commandDao,
        syncDao: db.syncDao,
        localGuestUid: 'local-guest',
      );

      await expectLater(
        withoutClient.startGithubDeviceSignIn(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.authProviderUnavailable,
          ),
        ),
      );
    });

    test('propagates a Firebase credential failure', () async {
      githubGateway.error = const AppException(AppErrorCode.authEmailInUse);
      final signIn = await githubRepository.startGithubDeviceSignIn();

      tokenCompleter.complete(
        const GithubAccessToken(accessToken: 'gho_test_token'),
      );

      await expectLater(
        signIn.result,
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.authEmailInUse,
          ),
        ),
      );
      expect(await db.profileDao.getProfile('github-1'), isNull);
    });
  });

  group('GitHub account linking', () {
    const registered = AuthSession(
      uid: 'user-1',
      email: 'user@example.com',
      displayName: 'User',
      isAnonymous: false,
      isAdmin: false,
      isLocalOnly: false,
      linkedProviders: {AuthProviderIds.password},
    );

    late _GithubAuthGateway githubGateway;
    late _FakeGithubDeviceClient client;
    late Completer<GithubAccessToken> tokenCompleter;
    late AuthRepository githubRepository;

    setUp(() {
      githubGateway = _GithubAuthGateway()..session = registered;
      tokenCompleter = Completer<GithubAccessToken>();
      client = _FakeGithubDeviceClient(
        GithubDeviceAuthorization(
          userCode: 'ABCD-1234',
          verificationUri: Uri.parse('https://github.com/login/device'),
          expiresAt: DateTime.utc(2026, 10, 28, 12, 15),
          poll: () => tokenCompleter.future,
          cancel: () {},
        ),
      );
      githubRepository = AuthRepository(
        gateway: githubGateway,
        cloud: null,
        profileDao: db.profileDao,
        preferenceDao: db.preferenceDao,
        commandDao: db.commandDao,
        syncDao: db.syncDao,
        localGuestUid: 'local-guest',
        githubDeviceClient: client,
      );
    });

    tearDown(() async {
      await githubGateway.close();
    });

    test('requires a signed-in registered session', () async {
      githubGateway.session = null;
      await expectLater(
        githubRepository.startGithubAccountLink(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.authRequired,
          ),
        ),
      );

      githubGateway.session = const AuthSession(
        uid: 'anon-1',
        isAnonymous: true,
        isAdmin: false,
        isLocalOnly: false,
      );
      await expectLater(
        githubRepository.startGithubAccountLink(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.authRequired,
          ),
        ),
      );
      expect(client.starts, 0);
    });

    test('keeps the UID and publishes the linked provider', () async {
      final sessions = <AuthSession>[];
      final subscription = githubRepository.watchSessions().listen(
        sessions.add,
      );
      await pumpEventQueue();

      final link = await githubRepository.startGithubAccountLink();
      expect(client.starts, 1);
      expect(link.userCode, 'ABCD-1234');

      tokenCompleter.complete(
        const GithubAccessToken(accessToken: 'gho_test_token'),
      );
      final session = await link.result;
      await pumpEventQueue();

      expect(githubGateway.linkCalls, 1);
      expect(githubGateway.receivedLinkToken, 'gho_test_token');
      expect(session.uid, registered.uid);
      expect(session.isRegistered, isTrue);
      expect(session.hasGithub, isTrue);
      // Firebase does not emit authStateChanges for provider linking, so the
      // repository must publish the updated session itself.
      expect(sessions.last.hasGithub, isTrue);
      expect(await db.profileDao.getProfile(registered.uid), isNotNull);
      // Linking changes no profile data, so it must not queue another sync.
      expect(await db.syncDao.pendingCount(registered.uid), 0);

      await subscription.cancel();
    });

    test('propagates a provider linked to another account', () async {
      githubGateway.linkError = const AppException(
        AppErrorCode.authProviderLinkedElsewhere,
      );
      final link = await githubRepository.startGithubAccountLink();

      tokenCompleter.complete(
        const GithubAccessToken(accessToken: 'gho_test_token'),
      );

      await expectLater(
        link.result,
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.authProviderLinkedElsewhere,
          ),
        ),
      );
      expect(await db.syncDao.pendingCount(registered.uid), 0);
    });
  });
}

class _RefreshAuthGateway implements AuthGateway {
  final _sessions = StreamController<AuthSession?>.broadcast();

  int refreshCalls = 0;
  AuthSession? refreshed;

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> watchSessions() => _sessions.stream;

  @override
  Future<AuthSession> refreshSession() async {
    refreshCalls++;
    return refreshed!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used');
}

class _GithubAuthGateway implements AuthGateway {
  final _sessions = StreamController<AuthSession?>.broadcast();

  AuthSession? session;
  String? receivedToken;
  bool? linkedAnonymous;
  AppException? error;
  String? receivedLinkToken;
  int linkCalls = 0;
  AppException? linkError;

  Future<void> close() => _sessions.close();

  @override
  AuthSession? get currentSession => session;

  @override
  Stream<AuthSession?> watchSessions() => _sessions.stream;

  @override
  Future<AuthSession> signInWithGithubAccessToken(
    String accessToken, {
    bool linkAnonymous = false,
  }) async {
    receivedToken = accessToken;
    linkedAnonymous = linkAnonymous;
    final failure = error;
    if (failure != null) throw failure;
    return const AuthSession(
      uid: 'github-1',
      email: 'octocat@example.com',
      displayName: 'Octocat',
      isAnonymous: false,
      isAdmin: false,
      isLocalOnly: false,
    );
  }

  @override
  Future<AuthSession> linkGithubAccessToken(String accessToken) async {
    linkCalls++;
    receivedLinkToken = accessToken;
    final failure = linkError;
    if (failure != null) throw failure;
    final current = session;
    if (current == null) throw const AppException(AppErrorCode.authRequired);
    return current.copyWith(
      linkedProviders: {...current.linkedProviders, AuthProviderIds.github},
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used');
}

class _FakeGithubDeviceClient implements GithubDeviceClient {
  _FakeGithubDeviceClient(this.authorization);

  final GithubDeviceAuthorization authorization;
  int starts = 0;

  @override
  Future<GithubDeviceAuthorization> start() async {
    starts++;
    return authorization;
  }
}
