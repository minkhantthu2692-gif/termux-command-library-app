import 'package:drift/drift.dart';

import '../../../models/user_profile.dart';
import '../app_database.dart';
import '../tables.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  Stream<UserProfile?> watchProfile(String uid) {
    return (select(profiles)..where((table) => table.uid.equals(uid)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _map(row));
  }

  Future<UserProfile?> getProfile(String uid) async {
    final row = await (select(
      profiles,
    )..where((table) => table.uid.equals(uid))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await into(profiles).insertOnConflictUpdate(
      ProfilesCompanion(
        uid: Value(profile.uid),
        nickname: Value(profile.nickname),
        email: Value(profile.email),
        avatarId: Value(AppAvatars.normalize(profile.avatarId)),
        createdAt: Value(profile.createdAt.toUtc()),
        updatedAt: Value(profile.updatedAt.toUtc()),
        isLocalOnly: Value(profile.isLocalOnly),
      ),
    );
  }

  /// Inserts a default profile only when one does not already exist. This is
  /// safe to call on every sign-in and never overwrites remote data.
  Future<UserProfile> ensureProfile({
    required String uid,
    String nickname = '',
    String email = '',
    String avatarId = AppAvatars.defaultId,
    bool isLocalOnly = false,
  }) async {
    final existing = await getProfile(uid);
    if (existing != null) return existing;
    final now = DateTime.now().toUtc();
    final profile = UserProfile(
      uid: uid,
      nickname: nickname,
      email: email,
      avatarId: AppAvatars.normalize(avatarId),
      createdAt: now,
      updatedAt: now,
      isLocalOnly: isLocalOnly,
    );
    await upsertProfile(profile);
    return profile;
  }

  Future<void> deleteProfile(String uid) =>
      (delete(profiles)..where((table) => table.uid.equals(uid))).go();

  UserProfile _map(ProfileRow row) => UserProfile(
    uid: row.uid,
    nickname: row.nickname,
    email: row.email,
    avatarId: AppAvatars.normalize(row.avatarId),
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    isLocalOnly: row.isLocalOnly,
  );
}
