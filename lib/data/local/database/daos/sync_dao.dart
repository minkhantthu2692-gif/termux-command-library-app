import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'sync_dao.g.dart';

/// Queue operation types. Payloads are JSON so the queue survives schema
/// changes and can be inspected in tests.
abstract final class PendingOperationType {
  static const favoritesSync = 'favorites.sync';
  static const pinsSync = 'pins.sync';
  static const profileSync = 'profile.sync';
  static const commandUpsert = 'command.upsert';
  static const commandDelete = 'command.delete';
}

class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.uid,
    required this.type,
    required this.entityId,
    required this.createdAt,
    this.payload = const {},
    this.payloadJson = '',
    this.attempts = 0,
    this.lastError,
  });

  final int id;
  final String uid;
  final String type;
  final String entityId;
  final Map<String, dynamic> payload;

  /// Original encoded payload, used to avoid deleting an operation that was
  /// replaced by a newer edit while its write was in flight.
  final String payloadJson;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
}

@DriftAccessor(tables: [PendingOperations, SyncState])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  /// Adds an operation to the durable queue. The unique key `(uid, type,
  /// entityId)` collapses repeats: toggling a favorite twenty times leaves a
  /// single operation carrying the latest requested state.
  Future<void> enqueue({
    required String uid,
    required String type,
    String entityId = '',
    Map<String, dynamic> payload = const {},
  }) async {
    await transaction(
      () => _replaceOperation(
        uid: uid,
        type: type,
        entityId: entityId,
        payload: payload,
      ),
    );
  }

  /// Inserts or replaces the single queued operation for `(uid, type,
  /// entityId)`. Must run inside a transaction.
  Future<void> _replaceOperation({
    required String uid,
    required String type,
    required String entityId,
    Map<String, dynamic> payload = const {},
  }) async {
    final companion = PendingOperationsCompanion(
      uid: Value(uid),
      type: Value(type),
      entityId: Value(entityId),
      payloadJson: Value(jsonEncode(payload)),
      createdAt: Value(DateTime.now().toUtc()),
      attempts: const Value(0),
      lastError: const Value(null),
    );
    // insertOnConflictUpdate targets the primary key only, so it cannot use
    // the (uid, type, entityId) unique index. Look the row up explicitly and
    // update it, keeping a single queued operation per entity.
    final existing =
        await (select(pendingOperations)..where(
              (table) =>
                  table.uid.equals(uid) &
                  table.type.equals(type) &
                  table.entityId.equals(entityId),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await into(pendingOperations).insert(companion);
    } else {
      await (update(
        pendingOperations,
      )..where((table) => table.id.equals(existing.id))).write(companion);
    }
  }

  /// Queues a guide deletion and drops any pending upsert for the same guide in
  /// one transaction. The delete is the final intent; keeping an older upsert
  /// could publish the guide again after the user removed it.
  Future<void> enqueueCommandDelete({
    required String uid,
    required String commandId,
  }) async {
    await transaction(() async {
      await (delete(pendingOperations)..where(
            (table) =>
                table.uid.equals(uid) &
                table.type.equals(PendingOperationType.commandUpsert) &
                table.entityId.equals(commandId),
          ))
          .go();
      await _replaceOperation(
        uid: uid,
        type: PendingOperationType.commandDelete,
        entityId: commandId,
      );
    });
  }

  /// Adds an operation only when no operation of the same `(uid, type,
  /// entityId)` exists. Repair code uses this so it cannot replace a newer
  /// payload that was queued while the queue was being inspected.
  Future<bool> enqueueIfAbsent({
    required String uid,
    required String type,
    String entityId = '',
    Map<String, dynamic> payload = const {},
    String? blockedByType,
  }) async {
    return transaction(() async {
      if (blockedByType != null) {
        final blocked =
            await (select(pendingOperations)..where(
                  (table) =>
                      table.uid.equals(uid) &
                      table.type.equals(blockedByType) &
                      table.entityId.equals(entityId),
                ))
                .getSingleOrNull();
        if (blocked != null) return false;
      }
      final existing =
          await (select(pendingOperations)..where(
                (table) =>
                    table.uid.equals(uid) &
                    table.type.equals(type) &
                    table.entityId.equals(entityId),
              ))
              .getSingleOrNull();
      if (existing != null) return false;
      await into(pendingOperations).insert(
        PendingOperationsCompanion(
          uid: Value(uid),
          type: Value(type),
          entityId: Value(entityId),
          payloadJson: Value(jsonEncode(payload)),
          createdAt: Value(DateTime.now().toUtc()),
          attempts: const Value(0),
          lastError: const Value(null),
        ),
      );
      return true;
    });
  }

  Stream<int> watchPendingCount(String uid) {
    return customSelect(
      'SELECT COUNT(*) AS count FROM pending_operations WHERE uid = ?',
      variables: [Variable.withString(uid)],
      readsFrom: {pendingOperations},
    ).watchSingle().map((row) {
      final value = row.data['count'];
      return value is int ? value : 0;
    });
  }

  Future<int> pendingCount(String uid) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS count FROM pending_operations WHERE uid = ?',
      variables: [Variable.withString(uid)],
      readsFrom: {pendingOperations},
    ).getSingle();
    final value = row.data['count'];
    return value is int ? value : 0;
  }

  Future<List<PendingOperation>> readPending(
    String uid, {
    int limit = 25,
  }) async {
    final rows =
        await (select(pendingOperations)
              ..where((table) => table.uid.equals(uid))
              ..orderBy([(table) => OrderingTerm.asc(table.id)])
              ..limit(limit))
            .get();
    return rows.map(_mapOperation).toList(growable: false);
  }

  Future<PendingOperation?> readOperation(int id) async {
    final row = await (select(
      pendingOperations,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapOperation(row);
  }

  Future<bool> hasOperations(String uid, Set<String> types) async {
    if (types.isEmpty) return false;
    final placeholders = List.filled(types.length, '?').join(', ');
    final row = await customSelect(
      'SELECT COUNT(*) AS count FROM pending_operations '
      'WHERE uid = ? AND type IN ($placeholders)',
      variables: [Variable.withString(uid), ...types.map(Variable.withString)],
      readsFrom: {pendingOperations},
    ).getSingle();
    final value = row.data['count'];
    return value is int && value > 0;
  }

  /// IDs of guides whose deletion is still queued for [uid]. Realtime listeners
  /// use this so a stale Firestore snapshot cannot re-insert a guide that the
  /// user already deleted while the delete is still uploading.
  Future<Set<String>> pendingDeleteIds(String uid) async {
    final rows =
        await (select(pendingOperations)..where(
              (table) =>
                  table.uid.equals(uid) &
                  table.type.equals(PendingOperationType.commandDelete),
            ))
            .get();
    return rows.map((row) => row.entityId).where((id) => id.isNotEmpty).toSet();
  }

  Future<void> markSucceeded(int id) async {
    await (delete(
      pendingOperations,
    )..where((table) => table.id.equals(id))).go();
  }

  /// Removes the operation only when it still carries the payload that was
  /// sent. If a newer edit replaced that payload during the write, the row
  /// stays queued so the newer change is not silently lost.
  Future<bool> markSucceededIfUnchanged(int id, String payloadJson) async {
    final removed =
        await (delete(pendingOperations)..where(
              (table) =>
                  table.id.equals(id) & table.payloadJson.equals(payloadJson),
            ))
            .go();
    return removed > 0;
  }

  Future<void> markFailed(int id, String error) async {
    final clipped = error.length > 300 ? error.substring(0, 300) : error;
    await customUpdate(
      'UPDATE pending_operations '
      'SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      variables: [Variable.withString(clipped), Variable.withInt(id)],
      updates: {pendingOperations},
    );
  }

  Future<void> removeForEntity(String uid, String type, String entityId) async {
    await (delete(pendingOperations)..where(
          (table) =>
              table.uid.equals(uid) &
              table.type.equals(type) &
              table.entityId.equals(entityId),
        ))
        .go();
  }

  Future<void> clearForUser(String uid) async {
    await (delete(
      pendingOperations,
    )..where((table) => table.uid.equals(uid))).go();
  }

  // ---------------------------------------------------------------------------
  // Small key/value state shared by seeding, sync bookkeeping and migration.
  // ---------------------------------------------------------------------------

  Future<String?> readState(String key) async {
    final row = await (select(
      syncState,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeState(String key, String value) async {
    await into(
      syncState,
    ).insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: value));
  }

  Future<void> deleteState(String key) =>
      (delete(syncState)..where((table) => table.key.equals(key))).go();

  PendingOperation _mapOperation(PendingOperationRow row) {
    var payload = <String, dynamic>{};
    try {
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is Map) {
        payload = Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      // A corrupt payload can never be replayed safely. Leaving it as an empty
      // map means the processor will drop the operation with a logged error
      // instead of deleting local user data.
    }
    return PendingOperation(
      id: row.id,
      uid: row.uid,
      type: row.type,
      entityId: row.entityId,
      payload: payload,
      payloadJson: row.payloadJson,
      createdAt: row.createdAt.toUtc(),
      attempts: row.attempts,
      lastError: row.lastError,
    );
  }
}
