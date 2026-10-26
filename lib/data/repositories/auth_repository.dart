import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../local/database/daos/command_dao.dart';
import '../local/database/daos/preference_dao.dart';
import '../local/database/daos/profile_dao.dart';
import '../local/database/daos/sync_dao.dart';
import '../models/auth_models.dart';
import '../models/user_profile.dart';
import '../remote/cloud_gateways.dart';

/// Coordinates the Firebase identity with the on-device guest identity and
/// local profile cache. Feature UI talks to this repository, not to Firebase.
class AuthRepository {
  AuthRepository({
    required AuthGateway? gateway,
    required CloudStore? cloud,
    required ProfileDao profileDao,
    required PreferenceDao preferenceDao,
    required CommandDao commandDao,
    required SyncDao syncDao,
    required String localGuestUid,
  }) : _gateway = gateway,
       _cloud = cloud,
       _profileDao = profileDao,
       _preferenceDao = preferenceDao,
       _commandDao = commandDao,
       _syncDao = syncDao,
       _localGuestUid = localGuestUid;

  final AuthGateway? _gateway;
  final CloudStore? _cloud;
  final ProfileDao _profileDao;
  final PreferenceDao _preferenceDao;
  final CommandDao _commandDao;
  final SyncDao _syncDao;
  final String _localGuestUid;

  bool get isCloudConfigured => _gateway != null;

  AuthSession get localGuestSession => AuthSession(
    uid: _localGuestUid,
    isAnonymous: true,
    isAdmin: false,
    isLocalOnly: true,
  );

  Stream<AuthSession> watchSessions() async* {
    AuthSession? last;
    Future<AuthSession> ensure(AuthSession session) async {
      await _ensureProfile(session);
      return session;
    }

    void emit(AuthSession session) {
      last = session;
    }

    final current = _gateway?.currentSession;
    if (current != null) {
      final guest = current;
      emit(guest);
      yield guest;
    } else {
      final guest = await ensure(localGuestSession);
      emit(guest);
      yield guest;
    }

    final gateway = _gateway;
    if (gateway == null) return;

    await for (final remote in gateway.watchSessions()) {
      final next = remote ?? await ensure(localGuestSession);
      if (next != last) {
        last = next;
        yield next;
      }
    }
  }

  Future<void> _ensureProfile(AuthSession session) async {
    try {
      final existing = await _profileDao.getProfile(session.uid);
      if (existing != null) return;
      if (session.isLocalOnly) {
        await _profileDao.ensureProfile(
          uid: session.uid,
          nickname: '',
          isLocalOnly: true,
        );
        return;
      }
      final email = session.email ?? '';
      final prefix = email.contains('@') ? email.split('@').first : '';
      await _profileDao.ensureProfile(
        uid: session.uid,
        nickname: session.isAnonymous ? '' : prefix,
        email: email,
        isLocalOnly: false,
      );
    } catch (error) {
      debugPrint('Local profile bootstrap failed: $error');
    }
  }

  Future<AuthSession> signInAnonymously() async {
    final gateway = _requireGateway();
    try {
      final session = await gateway.signInAnonymously();
      await _profileDao.ensureProfile(
        uid: session.uid,
        nickname: '',
        email: '',
        isLocalOnly: false,
      );
      await _syncDao.enqueue(
        uid: session.uid,
        type: PendingOperationType.profileSync,
      );
      return session;
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  Future<AuthSession> register({
    required String nickname,
    required String email,
    required String password,
    required String avatarId,
  }) async {
    final gateway = _requireGateway();
    final cleanNickname = nickname.trim();
    if (Validators.nicknameError(cleanNickname) != null) {
      throw const AppException(AppErrorCode.validation);
    }
    final normalizedEmail = Validators.normalizeEmail(email);
    if (!Validators.isValidEmail(normalizedEmail)) {
      throw const AppException(AppErrorCode.validation);
    }
    if (password.length < 8) {
      throw const AppException(AppErrorCode.authWeakPassword);
    }
    try {
      final session = await gateway.register(
        email: normalizedEmail,
        password: password,
      );
      try {
        await gateway.updateDisplayName(cleanNickname);
      } catch (_) {
        // The local profile remains the source for the UI; display-name sync
        // can be retried later without blocking account creation.
      }
      await _profileDao.upsertProfile(
        UserProfile(
          uid: session.uid,
          nickname: cleanNickname,
          email: normalizedEmail,
          avatarId: AppAvatars.normalize(avatarId),
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          isLocalOnly: false,
        ),
      );
      await _syncDao.enqueue(
        uid: session.uid,
        type: PendingOperationType.profileSync,
      );
      return session;
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final gateway = _requireGateway();
    final normalizedEmail = Validators.normalizeEmail(email);
    if (!Validators.isValidEmail(normalizedEmail)) {
      throw const AppException(AppErrorCode.validation);
    }
    try {
      final session = await gateway.signIn(
        email: normalizedEmail,
        password: password,
      );
      await _ensureProfile(session);
      await _syncDao.enqueue(
        uid: session.uid,
        type: PendingOperationType.profileSync,
      );
      return session;
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  /// Converts the current anonymous Firebase account into a registered one
  /// without changing its UID, so all local and cloud favorites/pins/posts stay.
  Future<AuthSession> linkAnonymousAccount({
    required String email,
    required String password,
  }) async {
    final gateway = _requireGateway();
    final normalizedEmail = Validators.normalizeEmail(email);
    if (!Validators.isValidEmail(normalizedEmail)) {
      throw const AppException(AppErrorCode.validation);
    }
    if (password.length < 8) {
      throw const AppException(AppErrorCode.authWeakPassword);
    }
    try {
      final session = await gateway.linkAnonymousAccount(
        email: normalizedEmail,
        password: password,
      );
      await _profileDao.ensureProfile(
        uid: session.uid,
        email: normalizedEmail,
        isLocalOnly: false,
      );
      await _syncDao.enqueue(
        uid: session.uid,
        type: PendingOperationType.profileSync,
      );
      return session;
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final gateway = _requireGateway();
    final normalizedEmail = Validators.normalizeEmail(email);
    if (!Validators.isValidEmail(normalizedEmail)) {
      throw const AppException(AppErrorCode.validation);
    }
    try {
      await gateway.sendPasswordReset(normalizedEmail);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final gateway = _requireGateway();
    if (newPassword.length < 8) {
      throw const AppException(AppErrorCode.authWeakPassword);
    }
    try {
      await gateway.reauthenticateWithPassword(currentPassword);
      await gateway.updatePassword(newPassword);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  Future<void> sendEmailVerification() async {
    final gateway = _requireGateway();
    try {
      await gateway.sendEmailVerification();
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  Future<void> signOut() async {
    final gateway = _requireGateway();
    try {
      await gateway.signOut();
      await _ensureProfile(localGuestSession);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  /// Deletes the cloud account, its authored guides and synced profile, then
  /// clears that user's local rows. Public cached content is preserved.
  Future<void> deleteAccount({String? password}) async {
    final gateway = _requireGateway();
    final session = gateway.currentSession;
    if (session == null) throw const AppException(AppErrorCode.authRequired);
    try {
      if (!session.isAnonymous) {
        final value = password ?? '';
        if (value.isEmpty) {
          throw const AppException(AppErrorCode.authRecentLoginRequired);
        }
        await gateway.reauthenticateWithPassword(value);
      }

      final cloud = _cloud;
      if (cloud != null) {
        final authored = await cloud.fetchAuthoredCommands(session.uid);
        for (final command in authored) {
          await cloud.deleteCommand(command.id);
        }
        await cloud.deleteProfile(session.uid);
      }

      await gateway.deleteAccount();
      await _commandDao.deleteLocalCommandsByAuthor(session.uid);
      await _preferenceDao.clearForUser(session.uid);
      await _syncDao.clearForUser(session.uid);
      await _profileDao.deleteProfile(session.uid);
      await _ensureProfile(localGuestSession);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  /// Used by account settings after a successful profile sync.
  Future<void> refreshIdentityClaims() async {
    final gateway = _gateway;
    if (gateway == null) return;
    try {
      await gateway.reload();
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  AuthGateway _requireGateway() {
    final gateway = _gateway;
    if (gateway == null) {
      throw const AppException(AppErrorCode.firebaseNotConfigured);
    }
    return gateway;
  }

  Future<void> updateDisplayName(String nickname) async {
    final gateway = _gateway;
    if (gateway == null) return;
    try {
      await gateway.updateDisplayName(nickname);
    } catch (error) {
      debugPrint('Could not update the Firebase display name: $error');
    }
  }

  String get guestUid => _localGuestUid;

  /// Stable guest profile creation for first launch without a session stream.
  Future<void> ensureGuestProfile() async {
    await _profileDao.ensureProfile(
      uid: _localGuestUid,
      nickname: '',
      isLocalOnly: true,
    );
  }
}
