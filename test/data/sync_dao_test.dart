import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/local/database/daos/sync_dao.dart';

void main() {
  late AppDatabase db;
  const uid = 'user-1';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('pending operation queue', () {
    test('collapses repeated toggles into one latest operation', () async {
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.favoritesSync,
        payload: const {'favorite': true},
      );
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.favoritesSync,
        payload: const {'favorite': false},
      );

      expect(await db.syncDao.pendingCount(uid), 1);
      final operations = await db.syncDao.readPending(uid);
      expect(operations, hasLength(1));
      expect(operations.single.payload, {'favorite': false});
      expect(operations.single.attempts, 0);
    });

    test('enqueueIfAbsent never replaces an existing payload', () async {
      expect(
        await db.syncDao.enqueueIfAbsent(
          uid: uid,
          type: PendingOperationType.commandUpsert,
          entityId: 'guide-1',
          payload: const {'name': 'First'},
        ),
        isTrue,
      );
      expect(
        await db.syncDao.enqueueIfAbsent(
          uid: uid,
          type: PendingOperationType.commandUpsert,
          entityId: 'guide-1',
          payload: const {'name': 'Second'},
        ),
        isFalse,
      );

      final operation = (await db.syncDao.readPending(uid)).single;
      expect(operation.payload['name'], 'First');
    });

    test('keeps operations separate by uid, type and entity', () async {
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.commandUpsert,
        entityId: 'a',
      );
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.commandUpsert,
        entityId: 'b',
      );
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.commandDelete,
        entityId: 'a',
      );
      await db.syncDao.enqueue(
        uid: 'user-2',
        type: PendingOperationType.commandUpsert,
        entityId: 'a',
      );

      expect(await db.syncDao.pendingCount(uid), 3);
      expect(await db.syncDao.pendingCount('user-2'), 1);
      expect(
        await db.syncDao.hasOperations(uid, {
          PendingOperationType.commandDelete,
        }),
        isTrue,
      );
      expect(
        await db.syncDao.hasOperations(uid, {PendingOperationType.profileSync}),
        isFalse,
      );
      expect(await db.syncDao.hasOperations(uid, const {}), isFalse);
    });

    test('reads in insertion order with a limit', () async {
      for (final id in ['a', 'b', 'c']) {
        await db.syncDao.enqueue(
          uid: uid,
          type: PendingOperationType.commandUpsert,
          entityId: id,
        );
      }

      final limited = await db.syncDao.readPending(uid, limit: 2);
      expect(limited.map((operation) => operation.entityId), ['a', 'b']);
    });

    test('failures increment attempts and truncate error text', () async {
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.profileSync,
      );
      final operation = (await db.syncDao.readPending(uid)).single;

      await db.syncDao.markFailed(operation.id, 'x' * 500);
      final failed = await db.syncDao.readOperation(operation.id);
      expect(failed!.attempts, 1);
      expect(failed.lastError, hasLength(300));

      await db.syncDao.markFailed(operation.id, 'second');
      expect((await db.syncDao.readOperation(operation.id))!.attempts, 2);
    });

    test('successful operations are removed from the queue', () async {
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.profileSync,
      );
      final operation = (await db.syncDao.readPending(uid)).single;

      await db.syncDao.markSucceeded(operation.id);
      expect(await db.syncDao.pendingCount(uid), 0);
      expect(await db.syncDao.readOperation(operation.id), isNull);
    });

    test('acknowledges a write only when its payload is unchanged', () async {
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.commandUpsert,
        entityId: 'guide-1',
        payload: const {'name': 'First'},
      );
      final operation = (await db.syncDao.readPending(uid)).single;

      expect(
        await db.syncDao.markSucceededIfUnchanged(
          operation.id,
          operation.payloadJson,
        ),
        isTrue,
      );
      expect(await db.syncDao.pendingCount(uid), 0);
    });

    test('keeps a payload replaced while its write was in flight', () async {
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.commandUpsert,
        entityId: 'guide-1',
        payload: const {'name': 'First'},
      );
      final operation = (await db.syncDao.readPending(uid)).single;

      // The user saved again after the first payload was read but before the
      // network write completed. The row keeps its id but carries a new payload.
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.commandUpsert,
        entityId: 'guide-1',
        payload: const {'name': 'Second'},
      );

      expect(
        await db.syncDao.markSucceededIfUnchanged(
          operation.id,
          operation.payloadJson,
        ),
        isFalse,
      );
      final remaining = (await db.syncDao.readPending(uid)).single;
      expect(remaining.payload['name'], 'Second');
    });

    test('clearing a user queue leaves other users untouched', () async {
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.favoritesSync,
      );
      await db.syncDao.enqueue(
        uid: 'user-2',
        type: PendingOperationType.favoritesSync,
      );

      await db.syncDao.clearForUser(uid);
      expect(await db.syncDao.pendingCount(uid), 0);
      expect(await db.syncDao.pendingCount('user-2'), 1);
    });

    test('watches pending count changes', () async {
      final counts = <int>[];
      final subscription = db.syncDao.watchPendingCount(uid).listen(counts.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await db.syncDao.enqueue(
        uid: uid,
        type: PendingOperationType.favoritesSync,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await subscription.cancel();

      expect(counts.first, 0);
      expect(counts.last, 1);
    });
  });

  group('sync bookkeeping state', () {
    test('writes, replaces, reads and deletes values', () async {
      expect(await db.syncDao.readState('seedVersion'), isNull);
      await db.syncDao.writeState('seedVersion', '3');
      expect(await db.syncDao.readState('seedVersion'), '3');
      await db.syncDao.writeState('seedVersion', '4');
      expect(await db.syncDao.readState('seedVersion'), '4');
      await db.syncDao.deleteState('seedVersion');
      expect(await db.syncDao.readState('seedVersion'), isNull);
    });
  });
}
