import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/local/database/daos/sync_dao.dart';
import 'package:termux_command_library/data/models/auth_models.dart';
import 'package:termux_command_library/data/models/command_post.dart';
import 'package:termux_command_library/data/remote/cloud_gateways.dart';
import 'package:termux_command_library/data/repositories/auth_repository.dart';
import 'package:termux_command_library/data/repositories/command_repository.dart';
import 'package:termux_command_library/data/services/sync_coordinator.dart';

import '../support/test_helpers.dart';

const _memberSession = AuthSession(
  uid: 'user-1',
  email: 'member@example.com',
  displayName: 'Member',
  isAnonymous: false,
  isAdmin: false,
  isLocalOnly: false,
);

void main() {
  late AppDatabase db;
  late _FakeAuthGateway gateway;
  late _FakeCloudStore cloud;
  late SyncCoordinator coordinator;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    gateway = _FakeAuthGateway();
    cloud = _FakeCloudStore();
    coordinator = SyncCoordinator(
      commandDao: db.commandDao,
      preferenceDao: db.preferenceDao,
      profileDao: db.profileDao,
      syncDao: db.syncDao,
      authRepository: AuthRepository(
        gateway: gateway,
        cloud: cloud,
        profileDao: db.profileDao,
        preferenceDao: db.preferenceDao,
        commandDao: db.commandDao,
        syncDao: db.syncDao,
        localGuestUid: 'local-guest',
      ),
      cloud: cloud,
    );
    coordinator.start();
    await pumpEventQueue();
  });

  tearDown(() async {
    await coordinator.dispose();
    await db.close();
  });

  test('stays attached after switching from guest to a member', () async {
    gateway.emit(_memberSession);
    await pumpEventQueue(times: 20);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Attaching must not race with the previous detach. A null attachment made
    // refresh report "Firebase is not configured" even though it was.
    await coordinator.refresh();
    expect(coordinator.currentStatus.isRemote, isTrue);
  });

  test('syncs an upload queued right after sign-in', () async {
    gateway.emit(_memberSession);
    await pumpEventQueue(times: 20);

    final repository = CommandRepository(
      commandDao: db.commandDao,
      preferenceDao: db.preferenceDao,
      syncDao: db.syncDao,
      cloudConfigured: true,
    );
    final draft = buildCommand(id: 'queued-upload');
    await repository.savePost(
      session: _memberSession,
      post: draft,
      publish: true,
      authorNickname: 'Member',
    );

    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (cloud.savedCommandIds.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    expect(cloud.savedCommandIds, contains(draft.id));
    expect(await db.syncDao.pendingCount(_memberSession.uid), 0);
    expect((await db.commandDao.getCommand(draft.id))?.isPendingSync, isFalse);
  });

  test('sends a newer payload queued during an in-flight write', () async {
    gateway.emit(_memberSession);
    await pumpEventQueue(times: 20);

    final first = buildCommand(id: 'superseded', name: 'First version');
    final second = buildCommand(
      id: 'superseded',
      name: 'Second version',
      version: 2,
    );
    await db.commandDao.saveLocalPost(first, pendingSync: true);
    await db.syncDao.enqueue(
      uid: _memberSession.uid,
      type: PendingOperationType.commandUpsert,
      entityId: first.id,
      payload: first.toJson(),
    );

    cloud.onSaveCommand = (command) async {
      if (command.name != first.name) return;
      // The user saves again after the first payload was read.
      await db.commandDao.saveLocalPost(second, pendingSync: true);
      await db.syncDao.enqueue(
        uid: _memberSession.uid,
        type: PendingOperationType.commandUpsert,
        entityId: second.id,
        payload: second.toJson(),
      );
    };

    await _waitFor(() => cloud.savedCommandNames.contains(second.name));
    await _waitFor(
      () async => await db.syncDao.pendingCount(_memberSession.uid) == 0,
    );

    // The acknowledged payload must not delete its replacement, and the newer
    // payload must still be written instead of staying "pending" forever.
    expect(cloud.savedCommandNames, [first.name, second.name]);
    final stored = await db.commandDao.getCommand(first.id);
    expect(stored!.name, second.name);
    expect(stored.isPendingSync, isFalse);
  });
}

Future<void> _waitFor(FutureOr<bool> Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  fail('Condition was not met before the timeout.');
}

class _FakeAuthGateway implements AuthGateway {
  final _sessions = StreamController<AuthSession?>.broadcast();

  void emit(AuthSession session) => _sessions.add(session);

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> watchSessions() => _sessions.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used');
}

class _FakeCloudStore implements CloudStore {
  final List<String> savedCommandIds = [];
  final List<String> savedCommandNames = [];
  Future<void> Function(CommandPost command)? onSaveCommand;

  @override
  Stream<CloudCommandEvent> watchLatestCommands({int limit = 250}) =>
      const Stream.empty();

  @override
  Stream<CloudProfile?> watchProfile(String uid) =>
      Stream<CloudProfile?>.value(null);

  @override
  Future<CloudProfile?> fetchProfile(String uid) async => null;

  @override
  Future<CloudCommandPage> fetchCommandsPage({
    int limit = 20,
    Object? cursor,
  }) async => const CloudCommandPage(commands: [], hasMore: false);

  @override
  Future<List<CommandPost>> fetchAuthoredCommands(String uid) async => const [];

  @override
  Future<void> saveCommand(CommandPost command) async {
    savedCommandIds.add(command.id);
    savedCommandNames.add(command.name);
    await onSaveCommand?.call(command);
  }

  @override
  Future<void> deleteCommand(String commandId) async {}

  @override
  Future<void> saveProfile({
    required String uid,
    String? nickname,
    String? email,
    String? avatarId,
    Set<String>? favoriteIds,
    List<String>? pinnedIds,
    bool createIfMissing = false,
  }) async {}

  @override
  Future<void> deleteProfile(String uid) async {}
}
