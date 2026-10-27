import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/models/auth_models.dart';
import 'package:termux_command_library/data/remote/cloud_gateways.dart';
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
