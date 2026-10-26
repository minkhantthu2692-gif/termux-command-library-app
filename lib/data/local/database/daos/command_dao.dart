import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/utils/stream_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../models/command_post.dart';
import '../../../models/command_query.dart';
import '../../../models/user_profile.dart';
import '../app_database.dart';
import '../tables.dart';

part 'command_dao.g.dart';

@DriftAccessor(tables: [Commands, CommandSteps, Favorites, Pins])
class CommandDao extends DatabaseAccessor<AppDatabase> with _$CommandDaoMixin {
  CommandDao(super.db);

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Saves an edit made on this device. The row is marked pending until the
  /// remote write (or local-only acknowledgement) completes.
  Future<void> saveLocalPost(CommandPost post, {required bool pendingSync}) =>
      _writePost(post, isPendingSync: pendingSync);

  /// Inserts/updates a remote document without overwriting a local edit that
  /// has not yet been synchronized. Returns whether the row was applied.
  Future<bool> applyRemotePost(CommandPost post) async {
    final existing = await _getRow(post.id);
    if (existing != null) {
      if (existing.isPendingSync) return false;
      if (post.version < existing.version) return false;
      if (post.version == existing.version &&
          !post.updatedAt.isAfter(existing.updatedAt)) {
        return false;
      }
    }
    await _writePost(post, isPendingSync: false, isSeed: existing?.isSeed);
    return true;
  }

  Future<void> upsertSeedPost(CommandPost post) =>
      _writePost(post, isPendingSync: false, isSeed: true);

  Future<void> markSynced(CommandPost remotePost) async {
    final existing = await _getRow(remotePost.id);
    if (existing?.isPendingSync ?? false) {
      // The user edited again while the write was in flight; keep the newer
      // local state and its pending flag.
      return;
    }
    await _writePost(
      remotePost.copyWith(isPendingSync: false),
      isPendingSync: false,
      isSeed: existing?.isSeed,
    );
  }

  Future<void> _writePost(
    CommandPost post, {
    required bool isPendingSync,
    bool? isSeed,
  }) async {
    await transaction(() async {
      await into(commands).insertOnConflictUpdate(
        CommandsCompanion(
          id: Value(post.id),
          name: Value(post.name),
          description: Value(post.description),
          categoryId: Value(post.categoryId),
          tagsJson: Value(jsonEncode(post.tags)),
          metadataJson: Value(jsonEncode(post.metadata)),
          authorUid: Value(post.authorUid),
          authorNickname: Value(post.authorNickname),
          createdAt: Value(post.createdAt.toUtc()),
          updatedAt: Value(post.updatedAt.toUtc()),
          version: Value(post.version),
          status: Value(post.status.name),
          stepCount: Value(post.steps.length),
          isSeed: Value(isSeed ?? post.isSeed),
          isPendingSync: Value(isPendingSync),
          searchBlob: Value(post.searchableText),
        ),
      );

      await (delete(
        commandSteps,
      )..where((t) => t.commandId.equals(post.id))).go();

      if (post.steps.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(
            commandSteps,
            post.steps.map(
              (step) => CommandStepsCompanion(
                id: Value(step.id),
                commandId: Value(post.id),
                stepOrder: Value(step.order),
                title: Value(step.title),
                description: Value(step.description),
                command: Value(step.command),
                runMode: Value(step.runMode.name),
              ),
            ),
          );
        });
      }
    });
  }

  Future<bool> deleteLocalCommand(String id) async {
    final count = await (delete(commands)..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  /// Removes every locally cached guide authored by [uid]. Used when an account
  /// is deleted; community cache and guest content are untouched.
  Future<int> deleteLocalCommandsByAuthor(String uid) async {
    return (delete(
      commands,
    )..where((t) => t.authorUid.equals(uid) & t.isSeed.equals(false))).go();
  }

  /// Applies a deletion that arrived from Firestore. Locally pending edits and
  /// seeded offline content are preserved.
  Future<bool> deleteRemoteCommand(String id) async {
    final existing = await _getRow(id);
    if (existing == null) return false;
    if (existing.isPendingSync || existing.isSeed) return false;
    final count = await (delete(commands)..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  Future<CommandPost?> getCommand(String id) async {
    final row = await _getRow(id);
    if (row == null) return null;
    final stepRows =
        await (select(commandSteps)
              ..where((t) => t.commandId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.stepOrder)]))
            .get();
    return _mapPost(row, stepRows);
  }

  Future<CommandRow?> _getRow(String id) =>
      (select(commands)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Removes cached remote commands while keeping seeds, the user's own posts,
  /// favorites, pins and pending operations. Used by "Clear cache" only.
  Future<int> clearRemoteCache(String uid) async {
    return customUpdate(
      '''
      DELETE FROM commands
      WHERE is_seed = 0
        AND is_pending_sync = 0
        AND author_uid != ?
        AND status = 'published'
        AND id NOT IN (SELECT command_id FROM favorites WHERE uid = ?)
        AND id NOT IN (SELECT command_id FROM pins WHERE uid = ?)
      ''',
      variables: [
        Variable.withString(uid),
        Variable.withString(uid),
        Variable.withString(uid),
      ],
      updates: {commands},
    );
  }

  // ---------------------------------------------------------------------------
  // Reads / streams
  // ---------------------------------------------------------------------------

  Stream<CommandPost?> watchCommand(String id) {
    final commandRows = (select(
      commands,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
    final stepRows =
        (select(commandSteps)
              ..where((t) => t.commandId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.stepOrder)]))
            .watch();
    return combineLatest2(commandRows, stepRows, (row, steps) {
      if (row == null) return null;
      return _mapPost(row, steps);
    });
  }

  Stream<List<CommandSummary>> watchCommands(
    CommandListQuery query,
    String uid,
  ) {
    final conditions = <String>[];
    final variables = <Variable<Object>>[];

    if (query.includeDrafts) {
      conditions.add(
        "(c.status = 'published' OR (c.author_uid = ? AND c.status = 'draft'))",
      );
      variables.add(Variable.withString(uid));
    } else {
      conditions.add("c.status = 'published'");
    }

    final search = query.search.trim();
    if (search.isNotEmpty) {
      conditions.add("c.search_blob LIKE ? ESCAPE '\\'");
      variables.add(
        Variable.withString('%${Validators.escapeLike(search.toLowerCase())}%'),
      );
    }

    if (query.categoryId != null) {
      conditions.add('c.category_id = ?');
      variables.add(Variable.withString(query.categoryId!));
    }

    if (query.authorUid != null) {
      conditions.add('c.author_uid = ?');
      variables.add(Variable.withString(query.authorUid!));
    }

    if (query.favoritesOnly) {
      conditions.add(
        'EXISTS (SELECT 1 FROM favorites f '
        'WHERE f.uid = ? AND f.command_id = c.id)',
      );
      variables.add(Variable.withString(uid));
    }

    if (query.pinnedOnly) {
      conditions.add(
        'EXISTS (SELECT 1 FROM pins p '
        'WHERE p.uid = ? AND p.command_id = c.id)',
      );
      variables.add(Variable.withString(uid));
    }

    final orderBy = switch (query.sort) {
      CommandSort.recentlyUpdated => 'c.updated_at DESC, c.id ASC',
      CommandSort.newest => 'c.created_at DESC, c.id ASC',
      CommandSort.nameAscending => 'c.name COLLATE NOCASE ASC, c.id ASC',
      CommandSort.mostSteps =>
        'c.step_count DESC, c.name COLLATE NOCASE ASC, c.id ASC',
    };

    final sql =
        '''
      SELECT c.*
      FROM commands c
      WHERE ${conditions.join(' AND ')}
      ORDER BY $orderBy
      LIMIT ? OFFSET ?
      ''';

    variables
      ..add(Variable.withInt(query.limit.clamp(1, 100)))
      ..add(Variable.withInt(query.offset < 0 ? 0 : query.offset));

    return customSelect(
      sql,
      variables: variables,
      readsFrom: {commands, favorites, pins},
    ).watch().map(_mapSummaryRows);
  }

  Stream<List<CommandSummary>> watchPinnedCommands(String uid) {
    return customSelect(
      '''
      SELECT c.*
      FROM commands c
      INNER JOIN pins p ON p.command_id = c.id
      WHERE p.uid = ? AND c.status = 'published'
      ORDER BY p.position ASC, p.created_at ASC
      ''',
      variables: [Variable.withString(uid)],
      readsFrom: {commands, pins},
    ).watch().map(_mapSummaryRows);
  }

  Stream<LibraryStats> watchStats(String uid) {
    return customSelect(
      '''
      SELECT
        (SELECT COUNT(*) FROM commands WHERE status = 'published') AS total,
        (SELECT COUNT(*) FROM commands
          WHERE author_uid = ? AND status != 'archived') AS mine,
        (SELECT COUNT(*) FROM favorites f
          INNER JOIN commands c ON c.id = f.command_id
          WHERE f.uid = ? AND c.status = 'published') AS favorites,
        (SELECT COUNT(*) FROM pins p
          INNER JOIN commands c ON c.id = p.command_id
          WHERE p.uid = ? AND c.status = 'published') AS pins
      ''',
      variables: [
        Variable.withString(uid),
        Variable.withString(uid),
        Variable.withString(uid),
      ],
      readsFrom: {commands, favorites, pins},
    ).watchSingle().map((row) {
      final data = row.data;
      return LibraryStats(
        total: _asInt(data['total']),
        mine: _asInt(data['mine']),
        favorites: _asInt(data['favorites']),
        pins: _asInt(data['pins']),
      );
    });
  }

  Stream<List<CategoryCount>> watchCategoryCounts() {
    return customSelect(
      '''
      SELECT category_id, COUNT(*) AS count
      FROM commands
      WHERE status = 'published'
      GROUP BY category_id
      ORDER BY count DESC
      ''',
      readsFrom: {commands},
    ).watch().map(
      (rows) => rows
          .map(
            (row) => CategoryCount(
              categoryId: (row.data['category_id'] as String?) ?? '',
              count: _asInt(row.data['count']),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<int> countCommands() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS count FROM commands',
      readsFrom: {commands},
    ).getSingle();
    return _asInt(row.data['count']);
  }

  Future<List<String>> getAllCommandIds() async {
    final rows = await customSelect(
      'SELECT id FROM commands',
      readsFrom: {commands},
    ).get();
    return rows.map((row) => row.data['id'] as String).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  List<CommandSummary> _mapSummaryRows(List<QueryRow> rows) =>
      rows.map((row) => _mapSummary(row.data)).toList(growable: false);

  CommandSummary _mapSummary(Map<String, dynamic> data) {
    return CommandSummary(
      id: data['id'] as String,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      categoryId: (data['category_id'] as String?) ?? '',
      tags: _decodeTags(data['tags_json']),
      metadata: _decodeMetadata(data['metadata_json']),
      authorUid: (data['author_uid'] as String?) ?? '',
      authorNickname: (data['author_nickname'] as String?) ?? '',
      createdAt: _readDate(data['created_at']),
      updatedAt: _readDate(data['updated_at']),
      version: _asInt(data['version'], fallback: 1),
      status: CommandStatus.parse(data['status'] as String?),
      stepCount: _asInt(data['step_count']),
      isSeed: _asBool(data['is_seed']),
      isPendingSync: _asBool(data['is_pending_sync']),
    );
  }

  CommandPost _mapPost(CommandRow row, List<CommandStepRow> stepRows) {
    return CommandPost(
      id: row.id,
      name: row.name,
      description: row.description,
      categoryId: row.categoryId,
      tags: _decodeTags(row.tagsJson),
      metadata: _decodeMetadata(row.metadataJson),
      steps: CommandStep.sorted(
        stepRows.map(
          (step) => CommandStep(
            id: step.id,
            order: step.stepOrder,
            title: step.title,
            description: step.description,
            command: step.command,
            runMode: CommandRunMode.parse(step.runMode),
          ),
        ),
      ),
      authorUid: row.authorUid,
      authorNickname: row.authorNickname,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      version: row.version,
      status: CommandStatus.parse(row.status),
      isSeed: row.isSeed,
      isPendingSync: row.isPendingSync,
    );
  }

  List<String> _decodeTags(Object? raw) {
    try {
      final decoded = jsonDecode(raw as String? ?? '[]');
      if (decoded is List) {
        return decoded.whereType<String>().toList(growable: false);
      }
    } on FormatException {
      // Corrupt cache metadata must not crash the library; drop tags only.
    }
    return const [];
  }

  Map<String, String> _decodeMetadata(Object? raw) {
    try {
      final decoded = jsonDecode(raw as String? ?? '{}');
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } on FormatException {
      // Ignore corrupt metadata.
    }
    return const {};
  }

  DateTime _readDate(Object? value) {
    if (value is DateTime) return value.toUtc();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ?? _epoch;
    }
    return _epoch;
  }

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  int _asInt(Object? value, {int fallback = 0}) =>
      value is int ? value : (value is num ? value.toInt() : fallback);

  bool _asBool(Object? value) => value == true || value == 1;
}
