import 'package:drift/drift.dart';

import '../../../../core/utils/stream_utils.dart';
import '../../../models/user_profile.dart';
import '../app_database.dart';
import '../tables.dart';

part 'preference_dao.g.dart';

/// Owns per-user favorite and pin rows. Rows are namespaced by UID so two
/// accounts on the same device never share personal state.
@DriftAccessor(tables: [Favorites, Pins])
class PreferenceDao extends DatabaseAccessor<AppDatabase>
    with _$PreferenceDaoMixin {
  PreferenceDao(super.db);

  Stream<UserPreferences> watchPreferences(String uid) {
    final favoritesStream =
        (select(favorites)..where((table) => table.uid.equals(uid)))
            .watch()
            .map((rows) => rows.map((row) => row.commandId).toSet());
    final pinsStream =
        (select(pins)
              ..where((table) => table.uid.equals(uid))
              ..orderBy([
                (table) => OrderingTerm.asc(table.position),
                (table) => OrderingTerm.asc(table.createdAt),
              ]))
            .watch()
            .map(
              (rows) =>
                  rows.map((row) => row.commandId).toList(growable: false),
            );
    return combineLatest2(
      favoritesStream,
      pinsStream,
      (favoriteIds, pinnedIds) =>
          UserPreferences(favoriteIds: favoriteIds, pinnedIds: pinnedIds),
    );
  }

  Future<UserPreferences> getPreferences(String uid) async {
    final favoriteRows = await (select(
      favorites,
    )..where((table) => table.uid.equals(uid))).get();
    final pinRows =
        await (select(pins)
              ..where((table) => table.uid.equals(uid))
              ..orderBy([
                (table) => OrderingTerm.asc(table.position),
                (table) => OrderingTerm.asc(table.createdAt),
              ]))
            .get();
    return UserPreferences(
      favoriteIds: favoriteRows.map((row) => row.commandId).toSet(),
      pinnedIds: pinRows.map((row) => row.commandId).toList(growable: false),
    );
  }

  Future<void> setFavorite(
    String uid,
    String commandId, {
    required bool favorite,
  }) async {
    if (favorite) {
      await into(favorites).insertOnConflictUpdate(
        FavoritesCompanion.insert(
          uid: uid,
          commandId: commandId,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    } else {
      await (delete(favorites)..where(
            (table) =>
                table.uid.equals(uid) & table.commandId.equals(commandId),
          ))
          .go();
    }
  }

  Future<void> setPinned(
    String uid,
    String commandId, {
    required bool pinned,
  }) async {
    await transaction(() async {
      if (pinned) {
        final existing =
            await (select(pins)..where(
                  (table) =>
                      table.uid.equals(uid) & table.commandId.equals(commandId),
                ))
                .getSingleOrNull();
        if (existing == null) {
          final maxRow = await customSelect(
            'SELECT COALESCE(MAX(position), -1) AS max_position '
            'FROM pins WHERE uid = ?',
            variables: [Variable.withString(uid)],
            readsFrom: {pins},
          ).getSingle();
          final rawMax = maxRow.data['max_position'];
          final nextPosition = rawMax is int ? rawMax + 1 : 0;
          await into(pins).insert(
            PinsCompanion.insert(
              uid: uid,
              commandId: commandId,
              position: nextPosition,
              createdAt: DateTime.now().toUtc(),
            ),
          );
        }
      } else {
        await (delete(pins)..where(
              (table) =>
                  table.uid.equals(uid) & table.commandId.equals(commandId),
            ))
            .go();
        await _normalizePinPositions(uid);
      }
    });
  }

  Future<void> reorderPins(String uid, List<String> orderedCommandIds) async {
    await transaction(() async {
      final rows = await (select(
        pins,
      )..where((table) => table.uid.equals(uid))).get();
      final byId = {for (final row in rows) row.commandId: row};
      final seen = <String>{};
      var position = 0;
      for (final id in orderedCommandIds) {
        if (!seen.add(id)) continue;
        final row = byId.remove(id);
        if (row == null) continue;
        await (update(pins)..where(
              (table) => table.uid.equals(uid) & table.commandId.equals(id),
            ))
            .write(PinsCompanion(position: Value(position)));
        position++;
      }
      // Preserve any rows the caller did not include at the end rather than
      // silently dropping them.
      for (final row in byId.values) {
        await (update(pins)..where(
              (table) =>
                  table.uid.equals(uid) & table.commandId.equals(row.commandId),
            ))
            .write(PinsCompanion(position: Value(position)));
        position++;
      }
    });
  }

  Future<void> _normalizePinPositions(String uid) async {
    final rows =
        await (select(pins)
              ..where((table) => table.uid.equals(uid))
              ..orderBy([(table) => OrderingTerm.asc(table.position)]))
            .get();
    for (var index = 0; index < rows.length; index++) {
      if (rows[index].position == index) continue;
      await (update(pins)..where(
            (table) =>
                table.uid.equals(uid) &
                table.commandId.equals(rows[index].commandId),
          ))
          .write(PinsCompanion(position: Value(index)));
    }
  }

  /// Replaces local state with a remote snapshot. Timestamps are preserved when
  /// the row already exists. All writes are atomic so watchers never observe a
  /// partially applied profile.
  Future<void> replaceAll(
    String uid, {
    required Set<String> favoriteIds,
    required List<String> pinnedIds,
  }) async {
    await transaction(() async {
      final now = DateTime.now().toUtc();

      final favoriteRows = await (select(
        favorites,
      )..where((table) => table.uid.equals(uid))).get();
      final existingFavorites = {
        for (final row in favoriteRows) row.commandId: row.createdAt,
      };
      if (!_sameSet(existingFavorites.keys.toSet(), favoriteIds)) {
        await (delete(favorites)..where((table) => table.uid.equals(uid))).go();
        if (favoriteIds.isNotEmpty) {
          await batch((batch) {
            batch.insertAll(
              favorites,
              favoriteIds.map(
                (id) => FavoritesCompanion.insert(
                  uid: uid,
                  commandId: id,
                  createdAt: existingFavorites[id] ?? now,
                ),
              ),
            );
          });
        }
      }

      final pinRows = await (select(
        pins,
      )..where((table) => table.uid.equals(uid))).get();
      final existingPins = {for (final row in pinRows) row.commandId: row};
      final samePins =
          pinRows.length == pinnedIds.length &&
          List.generate(
            pinnedIds.length,
            (index) =>
                existingPins[pinnedIds[index]] != null &&
                existingPins[pinnedIds[index]]!.position == index,
          ).every((value) => value);
      if (!samePins) {
        await (delete(pins)..where((table) => table.uid.equals(uid))).go();
        if (pinnedIds.isNotEmpty) {
          await batch((batch) {
            for (var index = 0; index < pinnedIds.length; index++) {
              final id = pinnedIds[index];
              batch.insert(
                pins,
                PinsCompanion.insert(
                  uid: uid,
                  commandId: id,
                  position: index,
                  createdAt: existingPins[id]?.createdAt ?? now,
                ),
              );
            }
          });
        }
      }
    });
  }

  bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> clearForUser(String uid) async {
    await transaction(() async {
      await (delete(favorites)..where((table) => table.uid.equals(uid))).go();
      await (delete(pins)..where((table) => table.uid.equals(uid))).go();
    });
  }

  /// Removes references to a deleted command for one user. Other users' local
  /// caches are untouched.
  Future<bool> removeCommandForUser(String uid, String commandId) async {
    var removed = false;
    await transaction(() async {
      final favorite =
          await (delete(favorites)..where(
                (table) =>
                    table.uid.equals(uid) & table.commandId.equals(commandId),
              ))
              .go();
      final pin =
          await (delete(pins)..where(
                (table) =>
                    table.uid.equals(uid) & table.commandId.equals(commandId),
              ))
              .go();
      removed = favorite > 0 || pin > 0;
      if (pin > 0) await _normalizePinPositions(uid);
    });
    return removed;
  }

  Future<int> countFavorites(String uid) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS count FROM favorites WHERE uid = ?',
      variables: [Variable.withString(uid)],
      readsFrom: {favorites},
    ).getSingle();
    final value = row.data['count'];
    return value is int ? value : 0;
  }
}
