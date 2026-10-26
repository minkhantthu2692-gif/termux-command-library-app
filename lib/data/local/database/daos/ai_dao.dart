import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../models/ai_models.dart';
import '../app_database.dart';
import '../tables.dart';

part 'ai_dao.g.dart';

@DriftAccessor(tables: [AiConversations, AiMessages, AiCacheEntries, AiModels])
class AiDao extends DatabaseAccessor<AppDatabase> with _$AiDaoMixin {
  AiDao(super.db);

  // ---------------------------------------------------------------------------
  // Conversations and messages
  // ---------------------------------------------------------------------------

  Stream<List<AiConversation>> watchConversations({String search = ''}) {
    final trimmed = search.trim();
    final where = trimmed.isEmpty
        ? ''
        : '''
          WHERE c.title LIKE ? OR EXISTS (
            SELECT 1 FROM ai_messages m
            WHERE m.conversation_id = c.id AND m.content LIKE ?
          )
        ''';
    final variables = trimmed.isEmpty
        ? <Variable<Object>>[]
        : [
            Variable.withString('%$trimmed%'),
            Variable.withString('%$trimmed%'),
          ];
    return customSelect(
      '''
      SELECT c.*,
        (SELECT COUNT(*) FROM ai_messages m
          WHERE m.conversation_id = c.id) AS message_count
      FROM ai_conversations c
      $where
      ORDER BY c.updated_at DESC, c.id ASC
      ''',
      variables: variables,
      readsFrom: {aiConversations, aiMessages},
    ).watch().map((rows) => rows.map(_mapConversation).toList(growable: false));
  }

  Stream<AiConversation?> watchConversation(String id) {
    return customSelect(
      '''
      SELECT c.*,
        (SELECT COUNT(*) FROM ai_messages m
          WHERE m.conversation_id = c.id) AS message_count
      FROM ai_conversations c
      WHERE c.id = ?
      ''',
      variables: [Variable.withString(id)],
      readsFrom: {aiConversations, aiMessages},
    ).watchSingleOrNull().map(
      (row) => row == null ? null : _mapConversation(row),
    );
  }

  Stream<List<AiStoredMessage>> watchMessages(String conversationId) {
    // Drift stores DateTime values with second precision. Two messages sent in
    // the same second would otherwise be ordered by their random UUID, which can
    // put an assistant reply before the user question. rowid preserves insertion
    // order and is stable for the lifetime of the local conversation.
    return customSelect(
      'SELECT * FROM ai_messages WHERE conversation_id = ? '
      'ORDER BY created_at ASC, rowid ASC',
      variables: [Variable.withString(conversationId)],
      readsFrom: {aiMessages},
    ).watch().map(
      (rows) =>
          rows.map((row) => _mapMessageData(row.data)).toList(growable: false),
    );
  }

  /// One-shot read used to build the exact provider prompt after a user message
  /// is saved. The UI keeps watching [watchMessages] for rendering.
  Future<List<AiStoredMessage>> readMessages(String conversationId) async {
    final rows = await customSelect(
      'SELECT * FROM ai_messages WHERE conversation_id = ? '
      'ORDER BY created_at ASC, rowid ASC',
      variables: [Variable.withString(conversationId)],
      readsFrom: {aiMessages},
    ).get();
    return rows.map((row) => _mapMessageData(row.data)).toList(growable: false);
  }

  Future<void> saveConversation(AiConversation conversation) async {
    await into(aiConversations).insertOnConflictUpdate(
      AiConversationsCompanion(
        id: Value(conversation.id),
        title: Value(conversation.title),
        providerId: Value(conversation.providerId),
        modelId: Value(conversation.modelId),
        createdAt: Value(conversation.createdAt.toUtc()),
        updatedAt: Value(conversation.updatedAt.toUtc()),
      ),
    );
  }

  Future<void> touchConversation(
    String id, {
    String? title,
    String? modelId,
    DateTime? updatedAt,
  }) async {
    await (update(
      aiConversations,
    )..where((table) => table.id.equals(id))).write(
      AiConversationsCompanion(
        title: title == null ? const Value.absent() : Value(title),
        modelId: modelId == null ? const Value.absent() : Value(modelId),
        updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
      ),
    );
  }

  Future<void> saveMessage(AiStoredMessage message) async {
    await into(aiMessages).insertOnConflictUpdate(
      AiMessagesCompanion(
        id: Value(message.id),
        conversationId: Value(message.conversationId),
        role: Value(message.role.name),
        content: Value(message.content),
        attachmentName: Value(message.attachmentName),
        usageJson: Value(jsonEncode(message.usage.toJson())),
        createdAt: Value(message.createdAt.toUtc()),
      ),
    );
  }

  Future<void> deleteConversation(String id) async {
    await transaction(() async {
      await (delete(
        aiMessages,
      )..where((table) => table.conversationId.equals(id))).go();
      await (delete(
        aiConversations,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<void> clearConversations() async {
    await transaction(() async {
      await delete(aiMessages).go();
      await delete(aiConversations).go();
    });
  }

  // ---------------------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------------------

  Future<AiResponse?> readCache(String key) async {
    final now = DateTime.now().toUtc();
    final row =
        await (select(aiCacheEntries)..where(
              (table) =>
                  table.cacheKey.equals(key) &
                  table.expiresAt.isBiggerThanValue(now),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    AiUsage usage = const AiUsage();
    try {
      final decoded = jsonDecode(row.usageJson);
      if (decoded is Map) {
        usage = AiUsage.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on FormatException {
      // Usage metadata is informational; a corrupt value is not fatal.
    }
    return AiResponse(
      text: row.responseText,
      usage: usage,
      modelId: row.modelId,
    );
  }

  Future<void> writeCache({
    required String key,
    required String providerId,
    required String modelId,
    required String promptVersion,
    required String responseText,
    required AiUsage usage,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) async {
    await into(aiCacheEntries).insertOnConflictUpdate(
      AiCacheEntriesCompanion(
        cacheKey: Value(key),
        providerId: Value(providerId),
        modelId: Value(modelId),
        promptVersion: Value(promptVersion),
        responseText: Value(responseText),
        usageJson: Value(jsonEncode(usage.toJson())),
        createdAt: Value(createdAt.toUtc()),
        expiresAt: Value(expiresAt.toUtc()),
      ),
    );
  }

  Future<void> clearCache() => delete(aiCacheEntries).go();

  Future<int> cleanExpiredCache() async {
    return (delete(aiCacheEntries)..where(
          (table) =>
              table.expiresAt.isSmallerOrEqualValue(DateTime.now().toUtc()),
        ))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Models
  // ---------------------------------------------------------------------------

  Stream<List<AiModelInfo>> watchModels(
    String providerId, {
    bool activeOnly = true,
  }) {
    return customSelect(
      'SELECT * FROM ai_models WHERE provider_id = ?'
      '${activeOnly ? ' AND active = 1' : ''}'
      ' ORDER BY display_name COLLATE NOCASE ASC',
      variables: [Variable.withString(providerId)],
      readsFrom: {aiModels},
    ).watch().map((rows) => rows.map(_mapModel).toList(growable: false));
  }

  Future<List<AiModelInfo>> readModels(
    String providerId, {
    bool activeOnly = true,
  }) async {
    final rows = await customSelect(
      'SELECT * FROM ai_models WHERE provider_id = ?'
      '${activeOnly ? ' AND active = 1' : ''}'
      ' ORDER BY display_name COLLATE NOCASE ASC',
      variables: [Variable.withString(providerId)],
      readsFrom: {aiModels},
    ).get();
    return rows.map(_mapModel).toList(growable: false);
  }

  Future<AiModelInfo?> readModel(String providerId, String modelId) async {
    final row = await customSelect(
      'SELECT * FROM ai_models WHERE provider_id = ? AND model_id = ?',
      variables: [
        Variable.withString(providerId),
        Variable.withString(modelId),
      ],
      readsFrom: {aiModels},
    ).getSingleOrNull();
    return row == null ? null : _mapModel(row);
  }

  Future<void> replaceModels(
    String providerId,
    List<AiModelInfo> models,
  ) async {
    await transaction(() async {
      final now = DateTime.now().toUtc();
      await (update(aiModels)
            ..where((table) => table.providerId.equals(providerId)))
          .write(const AiModelsCompanion(active: Value(false)));
      for (final model in models) {
        await into(aiModels).insertOnConflictUpdate(
          AiModelsCompanion(
            providerId: Value(providerId),
            modelId: Value(model.id),
            displayName: Value(model.displayName),
            ownedBy: Value(model.ownedBy),
            contextWindow: Value(model.contextWindow),
            active: Value(model.active),
            lastFetchedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<void> clearModels(String providerId) => (delete(
    aiModels,
  )..where((table) => table.providerId.equals(providerId))).go();

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  AiConversation _mapConversation(QueryRow row) {
    final data = row.data;
    return AiConversation(
      id: data['id'] as String,
      title: (data['title'] as String?) ?? '',
      providerId: (data['provider_id'] as String?) ?? '',
      modelId: (data['model_id'] as String?) ?? '',
      createdAt: _readDate(data['created_at']),
      updatedAt: _readDate(data['updated_at']),
      messageCount: _asInt(data['message_count']),
    );
  }

  AiStoredMessage _mapMessageData(Map<String, dynamic> data) {
    AiUsage usage = const AiUsage();
    try {
      final decoded = jsonDecode((data['usage_json'] as String?) ?? '{}');
      if (decoded is Map) {
        usage = AiUsage.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on FormatException {
      // Usage metadata is optional.
    }
    return AiStoredMessage(
      id: (data['id'] as String?) ?? '',
      conversationId: (data['conversation_id'] as String?) ?? '',
      role: AiMessageRole.parse((data['role'] as String?) ?? 'user'),
      content: (data['content'] as String?) ?? '',
      attachmentName: (data['attachment_name'] as String?) ?? '',
      usage: usage,
      createdAt: _readDate(data['created_at']),
    );
  }

  AiModelInfo _mapModel(QueryRow row) {
    final data = row.data;
    final context = data['context_window'];
    return AiModelInfo(
      providerId: (data['provider_id'] as String?) ?? '',
      id: (data['model_id'] as String?) ?? '',
      displayName: (data['display_name'] as String?) ?? '',
      ownedBy: (data['owned_by'] as String?) ?? '',
      contextWindow: context is int ? context : null,
      active: data['active'] == true || data['active'] == 1,
    );
  }

  DateTime _readDate(Object? value) {
    if (value is DateTime) return value.toUtc();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  int _asInt(Object? value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : 0;
}
