// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_dao.dart';

// ignore_for_file: type=lint
mixin _$AiDaoMixin on DatabaseAccessor<AppDatabase> {
  $AiConversationsTable get aiConversations => attachedDatabase.aiConversations;
  $AiMessagesTable get aiMessages => attachedDatabase.aiMessages;
  $AiCacheEntriesTable get aiCacheEntries => attachedDatabase.aiCacheEntries;
  $AiModelsTable get aiModels => attachedDatabase.aiModels;
  AiDaoManager get managers => AiDaoManager(this);
}

class AiDaoManager {
  final _$AiDaoMixin _db;
  AiDaoManager(this._db);
  $$AiConversationsTableTableManager get aiConversations =>
      $$AiConversationsTableTableManager(
        _db.attachedDatabase,
        _db.aiConversations,
      );
  $$AiMessagesTableTableManager get aiMessages =>
      $$AiMessagesTableTableManager(_db.attachedDatabase, _db.aiMessages);
  $$AiCacheEntriesTableTableManager get aiCacheEntries =>
      $$AiCacheEntriesTableTableManager(
        _db.attachedDatabase,
        _db.aiCacheEntries,
      );
  $$AiModelsTableTableManager get aiModels =>
      $$AiModelsTableTableManager(_db.attachedDatabase, _db.aiModels);
}
