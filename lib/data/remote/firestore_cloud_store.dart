import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/command_post.dart';
import '../models/user_profile.dart';
import 'cloud_gateways.dart';
import 'firebase_errors.dart';

/// Firestore implementation of the cloud contract. It is the only file in the
/// data layer that understands Firestore document shapes.
class FirestoreCloudStore implements CloudStore {
  FirestoreCloudStore(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _commands =>
      _firestore.collection(AppConstants.commandsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  @override
  Stream<CloudCommandEvent> watchLatestCommands({int limit = 250}) {
    return _commands
        .where('status', isEqualTo: CommandStatus.published.name)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final upserts = <CommandPost>[];
          final removedIds = <String>[];
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.removed) {
              removedIds.add(change.doc.id);
              continue;
            }
            final post = _commandFromDoc(change.doc);
            if (post != null) upserts.add(post);
          }
          return CloudCommandEvent(upserts: upserts, removedIds: removedIds);
        })
        .handleError((Object error) {
          throw mapFirebaseError(error);
        });
  }

  @override
  Stream<CloudProfile?> watchProfile(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return _profileFromData(uid, snapshot.data() ?? const {});
        })
        .handleError((Object error) {
          throw mapFirebaseError(error);
        });
  }

  @override
  Future<CloudProfile?> fetchProfile(String uid) async {
    try {
      final snapshot = await _users
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (!snapshot.exists) return null;
      return _profileFromData(uid, snapshot.data() ?? const {});
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<CloudCommandPage> fetchCommandsPage({
    int limit = AppConstants.syncPageSize,
    Object? cursor,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _commands
          .where('status', isEqualTo: CommandStatus.published.name)
          .orderBy('updatedAt', descending: true)
          .limit(limit.clamp(1, AppConstants.maxPageSize));
      if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
        query = query.startAfterDocument(cursor);
      }
      final snapshot = await query.get();
      final commands = <CommandPost>[];
      for (final doc in snapshot.docs) {
        final post = _commandFromDoc(doc);
        if (post != null) commands.add(post);
      }
      return CloudCommandPage(
        commands: commands,
        hasMore: snapshot.docs.length >= limit,
        cursor: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      );
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<List<CommandPost>> fetchAuthoredCommands(String uid) async {
    try {
      final snapshot = await _commands
          .where('authorUid', isEqualTo: uid)
          .limit(200)
          .get();
      final posts = <CommandPost>[];
      for (final doc in snapshot.docs) {
        final post = _commandFromDoc(doc);
        if (post != null) posts.add(post);
      }
      posts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return posts;
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> saveCommand(CommandPost command) async {
    try {
      await _commands
          .doc(command.id)
          .set(_commandToMap(command), SetOptions(merge: false));
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> deleteCommand(String commandId) async {
    try {
      await _commands.doc(commandId).delete();
    } on FirebaseException catch (error) {
      // A pending local creation may never have reached the server. Treat an
      // already-missing document as a successful delete.
      if (error.code == 'not-found') return;
      throw mapFirebaseError(error);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> saveProfile({
    required String uid,
    String? nickname,
    String? email,
    String? avatarId,
    Set<String>? favoriteIds,
    List<String>? pinnedIds,
    bool createIfMissing = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'uid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (nickname != null) data['nickname'] = nickname;
      if (email != null) data['email'] = email;
      if (avatarId != null) data['avatarId'] = AppAvatars.normalize(avatarId);
      if (favoriteIds != null) {
        data['favoriteIds'] = favoriteIds.toList(growable: false);
      }
      if (pinnedIds != null) {
        data['pinnedIds'] = pinnedIds.toList(growable: false);
      }
      if (createIfMissing) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await _users.doc(uid).set(data, SetOptions(merge: true));
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> deleteProfile(String uid) async {
    try {
      await _users.doc(uid).delete();
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _commandToMap(CommandPost command) => {
    'name': command.name,
    'description': command.description,
    'categoryId': command.categoryId,
    'tags': command.tags,
    'metadata': command.metadata,
    'steps': command.steps.map((step) => step.toJson()).toList(),
    'authorUid': command.authorUid,
    'authorNickname': command.authorNickname,
    'createdAt': Timestamp.fromDate(command.createdAt.toUtc()),
    'updatedAt': Timestamp.fromDate(command.updatedAt.toUtc()),
    'version': command.version,
    'status': command.status.name,
  };

  CommandPost? _commandFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final rawSteps = data['steps'];
    final steps = <CommandStep>[];
    if (rawSteps is List) {
      for (final raw in rawSteps) {
        if (raw is Map) {
          steps.add(
            CommandStep.fromJson(
              Map<String, dynamic>.from(raw),
              fallbackOrder: steps.length,
            ),
          );
        }
      }
    }
    final now = DateTime.now().toUtc();
    final tagsRaw = data['tags'];
    final metadataRaw = data['metadata'];
    return CommandPost(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      description: (data['description'] as String?) ?? '',
      categoryId: (data['categoryId'] as String?) ?? '',
      tags: tagsRaw is List
          ? tagsRaw.whereType<String>().toList(growable: false)
          : const [],
      metadata: metadataRaw is Map
          ? metadataRaw.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
      steps: CommandStep.sorted(steps),
      authorUid: (data['authorUid'] as String?) ?? '',
      authorNickname: (data['authorNickname'] as String?) ?? '',
      createdAt: _readDate(data['createdAt']) ?? now,
      updatedAt: _readDate(data['updatedAt']) ?? now,
      version: (data['version'] as num?)?.toInt() ?? 1,
      status: CommandStatus.parse(data['status'] as String?),
      isSeed: (data['authorUid'] as String?) == AppConstants.seedAuthorUid,
    );
  }

  CloudProfile _profileFromData(String uid, Map<String, dynamic> data) {
    final favoritesRaw = data['favoriteIds'];
    final pinsRaw = data['pinnedIds'];
    return CloudProfile(
      uid: uid,
      nickname: (data['nickname'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      avatarId: AppAvatars.normalize(data['avatarId'] as String?),
      favoriteIds: favoritesRaw is List
          ? favoritesRaw.whereType<String>().toSet()
          : const {},
      pinnedIds: pinsRaw is List
          ? pinsRaw.whereType<String>().toList(growable: false)
          : const [],
      createdAt: _readDate(data['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _readDate(data['updatedAt']) ?? DateTime.now().toUtc(),
    );
  }

  DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}
