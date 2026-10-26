import 'package:drift/drift.dart';

/// Cached public commands. SQLite is the display/search source of truth; the
/// Firestore listener writes into this table and the UI watches local streams.
@DataClassName('CommandRow')
class Commands extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get categoryId => text()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  TextColumn get authorUid => text()();
  TextColumn get authorNickname => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('published'))();
  IntColumn get stepCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSeed => boolean().withDefault(const Constant(false))();
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();
  TextColumn get searchBlob => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CommandStepRow')
class CommandSteps extends Table {
  TextColumn get id => text()();
  TextColumn get commandId =>
      text().references(Commands, #id, onDelete: KeyAction.cascade)();
  IntColumn get stepOrder => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get command => text()();
  TextColumn get runMode => text().withDefault(const Constant('foreground'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Favorites are namespaced by UID so different users on the same device never
/// see each other's preferences. No user-specific fields live on commands.
@DataClassName('FavoriteRow')
class Favorites extends Table {
  TextColumn get uid => text()();
  TextColumn get commandId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uid, commandId};
}

/// Pins preserve user-defined ordering through [position].
@DataClassName('PinRow')
class Pins extends Table {
  TextColumn get uid => text()();
  TextColumn get commandId => text()();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uid, commandId};
}

@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get uid => text()();
  TextColumn get nickname => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get avatarId => text().withDefault(const Constant('orbit'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isLocalOnly => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

@DataClassName('AppSettingsEntryRow')
class AppSettingsEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Durable queue for offline mutations. Operations are collapsed by type and
/// entity so a user can toggle a favorite repeatedly without growing the queue.
@DataClassName('PendingOperationRow')
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text()();
  TextColumn get type => text()();
  TextColumn get entityId => text().withDefault(const Constant(''))();
  TextColumn get payloadJson => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {uid, type, entityId},
  ];
}

@DataClassName('SyncStateRow')
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('AiConversationRow')
class AiConversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get providerId => text()();
  TextColumn get modelId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AiMessageRow')
class AiMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(AiConversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get attachmentName => text().withDefault(const Constant(''))();
  TextColumn get usageJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cache key includes provider, model, prompt version, prompt and request
/// parameters. Responses are never shared across different withcontexts.
@DataClassName('AiCacheEntryRow')
class AiCacheEntries extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get providerId => text()();
  TextColumn get modelId => text()();
  TextColumn get promptVersion => text()();
  TextColumn get responseText => text()();
  TextColumn get usageJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

@DataClassName('AiModelRow')
class AiModels extends Table {
  TextColumn get providerId => text()();
  TextColumn get modelId => text()();
  TextColumn get displayName => text()();
  TextColumn get ownedBy => text().withDefault(const Constant(''))();
  IntColumn get contextWindow => integer().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastFetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {providerId, modelId};
}
