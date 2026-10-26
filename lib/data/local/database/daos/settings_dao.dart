import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsEntries])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<Map<String, String>> watchEntries() {
    return select(appSettingsEntries)
        .watch()
        .map((rows) => {for (final row in rows) row.key: row.value});
  }

  Future<Map<String, String>> readAll() async {
    final rows = await select(appSettingsEntries).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<String?> read(String key) async {
    final row = await (select(
      appSettingsEntries,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> put(String key, String value) async {
    await into(appSettingsEntries).insertOnConflictUpdate(
      AppSettingsEntriesCompanion.insert(key: key, value: value),
    );
  }

  Future<void> putAll(Map<String, String> values) async {
    await batch((batch) {
      batch.insertAll(
        appSettingsEntries,
        values.entries.map(
          (entry) => AppSettingsEntriesCompanion.insert(
            key: entry.key,
            value: entry.value,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> remove(String key) => (delete(
    appSettingsEntries,
  )..where((table) => table.key.equals(key))).go();

  Future<void> clear() => delete(appSettingsEntries).go();
}
