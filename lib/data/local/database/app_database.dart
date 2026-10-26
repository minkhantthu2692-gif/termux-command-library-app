import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/ai_dao.dart';
import 'daos/command_dao.dart';
import 'daos/preference_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/sync_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Commands,
    CommandSteps,
    Favorites,
    Pins,
    Profiles,
    AppSettingsEntries,
    PendingOperations,
    SyncState,
    AiConversations,
    AiMessages,
    AiCacheEntries,
    AiModels,
  ],
  daos: [CommandDao, PreferenceDao, ProfileDao, SettingsDao, SyncDao, AiDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'termux_command_library',
              native: const DriftNativeOptions(shareAcrossIsolates: true),
            ),
      );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createIndexes();
    },
    onUpgrade: (migrator, from, to) async {
      // Keep migrations explicit when the schema grows. Never drop user data
      // here; add additive migrations or carefully copy data into new tables.
      // Example:
      // if (from < 2) { await migrator.addColumn(...); await _backfill...(); }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated) {
        await _createIndexes();
      }
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_commands_updated '
      'ON commands(updated_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_commands_category '
      'ON commands(category_id, updated_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_commands_author '
      'ON commands(author_uid, updated_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_steps_command '
      'ON command_steps(command_id, step_order)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_favorites_uid '
      'ON favorites(uid)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pins_uid_position '
      'ON pins(uid, position)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pending_uid '
      'ON pending_operations(uid, id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation '
      'ON ai_messages(conversation_id, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ai_cache_expiry '
      'ON ai_cache_entries(expires_at)',
    );
  }
}
