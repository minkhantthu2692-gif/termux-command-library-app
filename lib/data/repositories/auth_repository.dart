import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../local/database/daos/command_dao.dart';
import '../local/database/daos/preference_dao.dart';
import '../local/database/daos/profile_dao.dart';
import '../local/database/daos/sync_dao.dart';
import '../models/auth_models.dart';
import '../models/user_profile.dart';
import '../remote/cloud_gateways.dart';
import '../remote/github_device_client.dart';

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
    GithubDeviceClient? githubDeviceClient,
  }) : _gateway = gateway,
       _cloud = cloud,
       _profileDao = profileDao,
       _preferenceDao = preferenceDao,
       _commandDao = commandDao,
       _syncDao = syncDao,
       _localGuestUid = localGuestUid,
       _githubDeviceClient = githubDeviceClient;

  final AuthGateway? _gateway;
  final CloudStore? _cloud;
  final ProfileDao _profileDao;
  final PreferenceDao _preferenceDao;
  final CommandDao _commandDao;
  final SyncDao _syncDao;
  final String _localGuestUid;
  final GithubDeviceClient? _githubDeviceClient;

  /// Active `watchSessions()` listeners. A forced claim refresh must push the
  /// new role into those streams even though Firebase Auth does not emit an
  /// `authStateChanges` event for a token refresh.
  final List<void Function(AuthSession)> _sessionObservers = [];

  bool get isCloudConfigured => _gateway != null;

  AuthSession get localGuestSession => AuthSession(
    uid: _localGuestUid,
    isAnonymous: true,
    isAdmin: false,
    isLocalOnly: true,
  );

  Stream<AuthSession> watchSessions() {
    final controller = StreamController<AuthSession>();
    StreamSubscription<AuthSession?>? remoteSubscription;
    AuthSession? last;
    var cancelled = false;

    void emit(AuthSession session) {
      if (cancelled || controller.isClosed || session == last) return;
      last = session;
      controller.add(session);
    }

    // Exposes this listener to refreshIdentityClaims() so a forced claim
    // refresh can update the UI and the sync coordinator without a restart.
    void publish(AuthSession session) => emit(session);

    controller.onListen = () async {
      _sessionObservers.add(publish);
      final current = _gateway?.currentSession;
      final initial = current ?? localGuestSession;
      await _ensureProfile(initial);
      emit(initial);
      if (cancelled || controller.isClosed) return;

      final gateway = _gateway;
      if (gateway == null) {
        _sessionObservers.remove(publish);
        await controller.close();
        return;
      }

      // Keep an explicit subscription instead of `await for` inside an
      // `async*` generator: cancelling such a generator while it awaits a
      // broadcast stream never completes, which left the sync coordinator
      // attached after disposal.
      remoteSubscription = gateway.watchSessions().listen(
        (remote) {
          if (remote != null) {
            emit(remote);
            return;
          }
          unawaited(
            _ensureProfile(localGuestSession)
                .then((_) => emit(localGuestSession)),
          );
        },
        onError: (Object error, StackTrace stack) {
          if (!cancelled && !controller.isClosed) {
            controller.addError(error, stack);
          }
        },
        onDone: () {
          _sessionObservers.remove(publish);
          if (!cancelled && !controller.isClosed) {
            unawaited(controller.close());
          }
        },
      );
    };

    controller.onCancel = () async {
      cancelled = true;
      _sessionObservers.remove(publish);
      await remoteSubscription?.cancel();
      remoteSubscription = null;
    };

    return controller.stream;
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
      await _profileDao.ensureProfile(
        uid: session.uid,
        nickname: session.isAnonymous ? '' : _profileNickname(session),
        email: email,
        isLocalOnly: false,
      );
    } catch (error) {
      debugPrint('Local profile bootstrap failed: $error');
    }
  }

  /// Prefers the provider-supplied display name and falls back to the local
  /// part of the email. Long names are clipped to the profile field limit; the
  /// user can always change the nickname later.
  String _profileNickname(AuthSession session) {
    final displayName = session.displayName?.trim() ?? '';
    final candidate = displayName.isNotEmpty
        ? displayName
        : (session.email ?? '').split('@').first;
    if (candidate.length <= AppConstants.maxNicknameLength) return candidate;
    return candidate.substring(0, AppConstants.maxNicknameLength);
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

  /// Completes a Google or GitHub sign-in that already happened in the browser
  /// flow, then makes sure the local profile and its pending sync exist.
  ///
  /// [linkAnonymous] is used by the account-upgrade screen so an anonymous
  /// Firebase UID keeps its favorites, pins and authored guides.
  Future<AuthSession> signInWithProvider(
    AuthProviderKind provider, {
    bool linkAnonymous = false,
  }) async {
    final gateway = _requireGateway();
    try {
      final session = await gateway.signInWithProvider(
        provider,
        linkAnonymous: linkAnonymous,
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

  /// Starts GitHub's OAuth device flow and returns the challenge the UI shows.
  ///
  /// The device code stays inside the client; only the short user code and the
  /// verification URL reach the UI. [GithubDeviceSignIn.result] completes after
  /// GitHub authorizes the app and Firebase accepts the token, and
  /// [GithubDeviceSignIn.cancel] stops polling.
  Future<GithubDeviceSignIn> startGithubDeviceSignIn({
    bool linkAnonymous = false,
  }) {
    return _startGithubDeviceFlow(linkAnonymous: linkAnonymous);
  }

  /// Starts the device flow to connect GitHub to the signed-in registered
  /// account. The Firebase UID is preserved, so favorites, pins and authored
  /// guides stay attached.
  Future<GithubDeviceSignIn> startGithubAccountLink() async {
    final session = _gateway?.currentSession;
    if (session == null || !session.isRegistered) {
      throw const AppException(AppErrorCode.authRequired);
    }
    return _startGithubDeviceFlow(linkExisting: true);
  }

  Future<GithubDeviceSignIn> _startGithubDeviceFlow({
    bool linkAnonymous = false,
    bool linkExisting = false,
  }) async {
    final gateway = _requireGateway();
    final client = _githubDeviceClient;
    if (client == null) {
      throw const AppException(AppErrorCode.authProviderUnavailable);
    }
    try {
      final authorization = await client.start();
      final result = _completeGithubDeviceSignIn(
        authorization,
        gateway,
        linkAnonymous: linkAnonymous,
        linkExisting: linkExisting,
      );
      // A dialog that is dismissed while the first request is in flight may
      // never await the result. Attach an error handler now so a late failure
      // is not reported as an unhandled asynchronous error.
      result.ignore();
      return GithubDeviceSignIn(
        userCode: authorization.userCode,
        verificationUri: authorization.verificationUri,
        expiresAt: authorization.expiresAt,
        result: result,
        cancel: authorization.cancel,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  Future<AuthSession> _completeGithubDeviceSignIn(
    GithubDeviceAuthorization authorization,
    AuthGateway gateway, {
    bool linkAnonymous = false,
    bool linkExisting = false,
  }) async {
    try {
      final token = await authorization.waitForToken();
      final session = linkExisting
          ? await gateway.linkGithubAccessToken(token.accessToken)
          : await gateway.signInWithGithubAccessToken(
              token.accessToken,
              linkAnonymous: linkAnonymous,
            );
      await _ensureProfile(session);
      if (linkExisting) {
        // Firebase does not emit authStateChanges when a provider is linked to
        // the current user, so publish the updated provider list explicitly.
        for (final observer in List.of(_sessionObservers)) {
          observer(session);
        }
      } else {
        await _syncDao.enqueue(
          uid: session.uid,
          type: PendingOperationType.profileSync,
        );
      }
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

  /// Re-reads the Firebase profile and forces a fresh ID token, so a custom
  /// claim granted by an operator becomes active without restarting the app.
  /// The refreshed session is published to every active session listener.
  Future<AuthSession> refreshIdentityClaims() async {
    final gateway = _gateway;
    if (gateway == null) {
      throw const AppException(AppErrorCode.firebaseNotConfigured);
    }
    try {
      final session = await gateway.refreshSession();
      for (final observer in List.of(_sessionObservers)) {
        observer(session);
      }
      return session;
    } catch (error) {
      throw error is AppException
          ? error
          : AppException(AppErrorCode.unknown, cause: error);
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
