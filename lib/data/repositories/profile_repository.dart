import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../local/database/daos/preference_dao.dart';
import '../local/database/daos/profile_dao.dart';
import '../local/database/daos/sync_dao.dart';
import '../models/auth_models.dart';
import '../models/user_profile.dart';
import 'auth_repository.dart';

class ProfileRepository {
  ProfileRepository({
    required ProfileDao profileDao,
    required PreferenceDao preferenceDao,
    required SyncDao syncDao,
    required AuthRepository authRepository,
  }) : _profileDao = profileDao,
       _preferenceDao = preferenceDao,
       _syncDao = syncDao,
       _authRepository = authRepository;

  final ProfileDao _profileDao;
  final PreferenceDao _preferenceDao;
  final SyncDao _syncDao;
  final AuthRepository _authRepository;

  Stream<UserProfile?> watchProfile(String uid) =>
      _profileDao.watchProfile(uid);

  Future<UserProfile?> getProfile(String uid) => _profileDao.getProfile(uid);

  Future<void> ensureProfile(AuthSession session) async {
    await _profileDao.ensureProfile(
      uid: session.uid,
      nickname: session.isAnonymous
          ? ''
          : (session.email?.split('@').first ?? ''),
      email: session.email ?? '',
      isLocalOnly: session.isLocalOnly,
    );
  }

  Future<UserProfile> updateProfile({
    required AuthSession session,
    required String nickname,
    required String avatarId,
    bool enqueueCloudSync = true,
  }) async {
    final cleanNickname = nickname.trim();
    final error = Validators.nicknameError(cleanNickname);
    if (error != null) {
      throw const AppException(AppErrorCode.validation);
    }
    final existing = await _profileDao.ensureProfile(
      uid: session.uid,
      email: session.email ?? '',
      isLocalOnly: session.isLocalOnly,
    );
    final updated = existing.copyWith(
      nickname: cleanNickname,
      avatarId: AppAvatars.normalize(avatarId),
      email: session.email ?? existing.email,
      updatedAt: DateTime.now().toUtc(),
      isLocalOnly: session.isLocalOnly,
    );
    await _profileDao.upsertProfile(updated);
    if (enqueueCloudSync && !session.isLocalOnly) {
      await _syncDao.enqueue(
        uid: session.uid,
        type: PendingOperationType.profileSync,
      );
      await _authRepository.updateDisplayName(cleanNickname);
    }
    return updated;
  }

  /// Explicitly imports the guest collection into a freshly signed-in account.
  /// Guest rows are removed afterwards so another account on the same device
  /// cannot inherit them. The caller confirms this in the UI.
  Future<bool> hasGuestPreferences(String guestUid) async {
    final prefs = await _preferenceDao.getPreferences(guestUid);
    return prefs.favoriteIds.isNotEmpty || prefs.pinnedIds.isNotEmpty;
  }

  Future<int> importGuestPreferences({
    required String guestUid,
    required String targetUid,
    bool syncToCloud = true,
  }) async {
    if (guestUid == targetUid) return 0;
    final guest = await _preferenceDao.getPreferences(guestUid);
    if (guest.favoriteIds.isEmpty && guest.pinnedIds.isEmpty) return 0;
    final target = await _preferenceDao.getPreferences(targetUid);
    final favorites = {
      ...target.favoriteIds,
      ...guest.favoriteIds,
    }.take(AppConstants.maxFavoriteIds).toSet();
    final pins = <String>[];
    for (final id in [...target.pinnedIds, ...guest.pinnedIds]) {
      if (pins.length >= AppConstants.maxPinnedIds) break;
      if (pins.contains(id)) continue;
      pins.add(id);
    }
    await _preferenceDao.replaceAll(
      targetUid,
      favoriteIds: favorites,
      pinnedIds: pins,
    );
    await _preferenceDao.clearForUser(guestUid);
    if (syncToCloud) {
      await _syncDao.enqueue(
        uid: targetUid,
        type: PendingOperationType.favoritesSync,
      );
      await _syncDao.enqueue(
        uid: targetUid,
        type: PendingOperationType.pinsSync,
      );
    }
    return guest.favoriteIds.length + guest.pinnedIds.length;
  }

  Future<void> clearLocalAccountData({
    required String uid,
    required bool localOnly,
  }) async {
    await _preferenceDao.clearForUser(uid);
    await _syncDao.clearForUser(uid);
    await _profileDao.deleteProfile(uid);
    if (localOnly) {
      await _profileDao.ensureProfile(
        uid: uid,
        nickname: '',
        isLocalOnly: true,
      );
    }
  }
}
