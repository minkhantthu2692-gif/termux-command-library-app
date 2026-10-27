import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../local/database/daos/command_dao.dart';
import '../local/database/daos/preference_dao.dart';
import '../local/database/daos/profile_dao.dart';
import '../local/database/daos/sync_dao.dart';
import '../models/auth_models.dart';
import '../models/command_post.dart';
import '../models/user_profile.dart';
import '../remote/cloud_gateways.dart';
import '../repositories/auth_repository.dart';

/// Owns the realtime Firestore listeners and the durable pending-operation
/// queue. SQLite remains the source of truth for every screen.
class SyncCoordinator {
  SyncCoordinator({
    required CommandDao commandDao,
    required PreferenceDao preferenceDao,
    required ProfileDao profileDao,
    required SyncDao syncDao,
    required AuthRepository authRepository,
    required CloudStore? cloud,
  }) : _commandDao = commandDao,
       _preferenceDao = preferenceDao,
       _profileDao = profileDao,
       _syncDao = syncDao,
       _authRepository = authRepository,
       _cloud = cloud;

  final CommandDao _commandDao;
  final PreferenceDao _preferenceDao;
  final ProfileDao _profileDao;
  final SyncDao _syncDao;
  final AuthRepository _authRepository;
  final CloudStore? _cloud;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.localOnly;
  SyncStatus get currentStatus => _status;
  Stream<SyncStatus> get statusStream => _statusController.stream;

  StreamSubscription<AuthSession>? _sessionSub;
  StreamSubscription<CloudCommandEvent>? _commandsSub;
  StreamSubscription<CloudProfile?>? _profileSub;
  StreamSubscription<int>? _pendingSub;
  Timer? _processTimer;
  Timer? _retryTimer;
  AuthSession? _session;
  String? _attachedUid;

  /// Guards overlapping session changes. A stale switch must never attach
  /// after a newer one, and detaching must finish before the next attach.
  int _sessionGeneration = 0;
  bool _started = false;
  bool _disposed = false;
  bool _processing = false;
  bool _refreshing = false;
  bool _profileBootstrapStarted = false;
  int _pendingCount = 0;
  DateTime? _lastSyncedAt;

  static const _lastSyncedKey = 'lastSyncedAt';
  static const _maxAutomaticAttempts = 8;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(_loadLastSynced());
    _sessionSub = _authRepository.watchSessions().listen(
      _onSession,
      onError: (Object error, StackTrace stack) {
        _setError(
          error is AppException
              ? error
              : const AppException(AppErrorCode.unknown),
        );
      },
    );
  }

  Future<void> _loadLastSynced() async {
    final raw = await _syncDao.readState(_lastSyncedKey);
    if (raw == null) return;
    _lastSyncedAt = DateTime.tryParse(raw)?.toUtc();
    _emit(
      _status.copyWith(
        lastSyncedAt: _lastSyncedAt,
        clearError: true,
        phase: _status.phase,
      ),
    );
  }

  void _onSession(AuthSession session) {
    if (_disposed) return;
    final sameUid = _session?.uid == session.uid;
    final sameMode = _session?.isLocalOnly == session.isLocalOnly;
    _session = session;
    if (sameUid && sameMode && (_attachedUid != null || session.isLocalOnly)) {
      return;
    }

    // Serialize the switch. Previously `_detach()` was fired without awaiting
    // and could resume after `_attach()`, cancelling the fresh listeners and
    // nulling `_attachedUid` — leaving uploads queued forever.
    final generation = ++_sessionGeneration;
    unawaited(_switchSession(session, generation));
  }

  Future<void> _switchSession(AuthSession session, int generation) async {
    await _detach();
    if (_disposed || generation != _sessionGeneration) return;

    if (session.isLocalOnly || _cloud == null) {
      _attachedUid = null;
      _setStatus(
        SyncStatus.localOnly.copyWith(
          pendingOperations: 0,
          lastSyncedAt: _lastSyncedAt,
        ),
      );
      return;
    }
    _attach(session);
  }

  Future<void> _attach(AuthSession session) async {
    final cloud = _cloud;
    if (cloud == null) return;
    _attachedUid = session.uid;
    _pendingCount = 0;
    _setStatus(
      SyncStatus(
        phase: SyncPhase.idle,
        pendingOperations: 0,
        lastSyncedAt: _lastSyncedAt,
      ),
    );

    _pendingSub = _syncDao.watchPendingCount(session.uid).listen((count) {
      _pendingCount = count;
      _emit(_status.copyWith(pendingOperations: count));
      if (count > 0) _scheduleProcessing();
    });

    _commandsSub = cloud
        .watchLatestCommands(limit: 250)
        .listen(_applyCommandEvent, onError: _onListenerError);
    _profileSub = cloud
        .watchProfile(session.uid)
        .listen(
          (profile) => unawaited(_applyProfile(session, profile)),
          onError: _onListenerError,
        );

    unawaited(_bootstrapCloudProfile(session));
    unawaited(_repairPendingCommands(session.uid));
    unawaited(_refreshQuietly());
  }

  /// Attach-time refresh runs in the background. `refresh()` reports failures
  /// through the status stream and rethrows so interactive callers can show a
  /// snackbar; an unhandled asynchronous error at attach time would crash the
  /// zone instead. The badge still shows the actionable error.
  Future<void> _refreshQuietly() async {
    try {
      await refresh(showBusy: false);
    } on AppException {
      // Already published to the status stream by refresh().
    }
  }

  /// Re-queues local guides marked pending that have no queue entry. Older
  /// builds could delete a queue row without clearing the flag, which left the
  /// badge stuck forever. The upsert is idempotent, so repairing a row that was
  /// already uploaded simply acknowledges it again.
  Future<void> _repairPendingCommands(String uid) async {
    try {
      final ids = await _commandDao.getPendingCommandIdsForAuthor(uid);
      for (final id in ids) {
        if (_disposed || _attachedUid != uid) return;
        final post = await _commandDao.getCommand(id);
        if (post == null || post.authorUid != uid || !post.isPendingSync) {
          continue;
        }
        await _syncDao.enqueueIfAbsent(
          uid: uid,
          type: PendingOperationType.commandUpsert,
          entityId: id,
          payload: post.toJson(),
        );
      }
    } catch (_) {
      // Best-effort repair. The normal sync path and its visible errors still
      // run, and the next refresh retries this reconciliation.
    }
  }

  Future<void> _detach() async {
    _processTimer?.cancel();
    _retryTimer?.cancel();
    // Capture and clear the references before awaiting so a listener created
    // by the next attach can never be cancelled by this detach.
    final commandsSub = _commandsSub;
    final profileSub = _profileSub;
    final pendingSub = _pendingSub;
    _commandsSub = null;
    _profileSub = null;
    _pendingSub = null;
    _attachedUid = null;
    _profileBootstrapStarted = false;
    _processTimer = null;
    _retryTimer = null;
    await commandsSub?.cancel();
    await profileSub?.cancel();
    await pendingSub?.cancel();
  }

  Future<void> _applyCommandEvent(CloudCommandEvent event) async {
    try {
      for (final post in event.upserts) {
        await _commandDao.applyRemotePost(post);
      }
      for (final id in event.removedIds) {
        await _commandDao.deleteRemoteCommand(id);
      }
    } catch (error) {
      _setError(
        error is AppException
            ? error
            : const AppException(AppErrorCode.database),
      );
    }
  }

  Future<void> _applyProfile(AuthSession session, CloudProfile? profile) async {
    if (_disposed || _attachedUid != session.uid) return;
    if (profile == null) {
      await _bootstrapCloudProfile(session);
      return;
    }
    try {
      final favoritePending = await _syncDao.hasOperations(session.uid, {
        PendingOperationType.favoritesSync,
      });
      final pinPending = await _syncDao.hasOperations(session.uid, {
        PendingOperationType.pinsSync,
      });
      final profilePending = await _syncDao.hasOperations(session.uid, {
        PendingOperationType.profileSync,
      });

      if (!profilePending) {
        final existing = await _profileDao.getProfile(session.uid);
        if (existing == null ||
            existing.nickname != profile.nickname ||
            existing.avatarId != profile.avatarId ||
            existing.email != profile.email ||
            existing.isLocalOnly) {
          await _profileDao.upsertProfile(
            UserProfile(
              uid: session.uid,
              nickname: profile.nickname,
              email: profile.email,
              avatarId: profile.avatarId,
              createdAt: existing?.createdAt ?? profile.createdAt,
              updatedAt: profile.updatedAt,
              isLocalOnly: false,
            ),
          );
        }
      }

      if (!favoritePending && !pinPending) {
        // Remote collection is the source of truth when no local toggle is
        // waiting. Local rows for other users are namespaced separately.
        await _preferenceDao.replaceAll(
          session.uid,
          favoriteIds: profile.favoriteIds
              .take(AppConstants.maxFavoriteIds)
              .toSet(),
          pinnedIds: profile.pinnedIds
              .take(AppConstants.maxPinnedIds)
              .toList(growable: false),
        );
      }
    } catch (error) {
      _setError(
        error is AppException
            ? error
            : const AppException(AppErrorCode.database),
      );
    }
  }

  Future<void> _bootstrapCloudProfile(AuthSession session) async {
    final cloud = _cloud;
    if (cloud == null || _profileBootstrapStarted) return;
    _profileBootstrapStarted = true;
    try {
      final remote = await cloud.fetchProfile(session.uid);
      if (remote != null) {
        await _applyProfile(session, remote);
        return;
      }
      final local = await _profileDao.ensureProfile(
        uid: session.uid,
        nickname: session.isAnonymous
            ? ''
            : (session.email?.split('@').first ?? ''),
        email: session.email ?? '',
        isLocalOnly: false,
      );
      final prefs = await _preferenceDao.getPreferences(session.uid);
      await cloud.saveProfile(
        uid: session.uid,
        nickname: local.nickname,
        email: local.email,
        avatarId: local.avatarId,
        favoriteIds: prefs.favoriteIds,
        pinnedIds: prefs.pinnedIds,
        createIfMissing: true,
      );
    } catch (error) {
      _profileBootstrapStarted = false;
      _setError(
        error is AppException
            ? error
            : const AppException(AppErrorCode.network),
      );
      _scheduleRetry(const Duration(seconds: 20));
    }
  }

  void _onListenerError(Object error, StackTrace stack) {
    _setError(
      error is AppException ? error : const AppException(AppErrorCode.network),
    );
    _scheduleRetry(const Duration(seconds: 20));
  }

  void _scheduleProcessing() {
    if (_disposed || _attachedUid == null || _processing) return;
    _processTimer?.cancel();
    _processTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_processPending());
    });
  }

  void _scheduleRetry(Duration delay) {
    if (_disposed || _attachedUid == null) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      final session = _session;
      if (session == null || session.isLocalOnly) return;
      unawaited(_bootstrapCloudProfile(session));
      unawaited(_processPending());
    });
  }

  Future<AppException?> _processPending({bool force = false}) async {
    final uid = _attachedUid;
    final cloud = _cloud;
    if (uid == null || cloud == null || _processing || _disposed) return null;
    _processing = true;
    var failedRetryable = false;
    var superseded = false;
    AppException? failure;
    try {
      final operations = await _syncDao.readPending(uid);
      if (operations.isEmpty) return null;
      if (!force &&
          operations.every((op) => op.attempts >= _maxAutomaticAttempts)) {
        final error = const AppException(
          AppErrorCode.network,
          message: 'Retry limit reached',
        );
        _setError(error);
        return error;
      }
      _emit(_status.copyWith(phase: SyncPhase.syncing));
      for (final operation in operations) {
        if (_disposed || _attachedUid != uid) return failure;
        if (!force && operation.attempts >= _maxAutomaticAttempts) continue;
        try {
          await _executeOperation(uid, operation);
          // Only acknowledge the payload that was actually written. A newer
          // edit may have replaced the queued payload while this write was in
          // flight; deleting the row unconditionally would lose that edit.
          final acknowledged = await _syncDao.markSucceededIfUnchanged(
            operation.id,
            operation.payloadJson,
          );
          if (!acknowledged) {
            superseded = true;
            break;
          }
        } on AppException catch (error) {
          await _syncDao.markFailed(operation.id, error.code.name);
          failure = error;
          if (error.retryable) {
            failedRetryable = true;
            break;
          }
          _setError(error);
        } catch (error) {
          await _syncDao.markFailed(operation.id, 'unknown');
          failure = const AppException(AppErrorCode.unknown);
          failedRetryable = true;
          break;
        }
      }
      if (failedRetryable) {
        _scheduleRetry(const Duration(seconds: 8));
      } else if (failure == null && !superseded) {
        await _syncDao.writeState(
          _lastSyncedKey,
          DateTime.now().toUtc().toIso8601String(),
        );
        _lastSyncedAt = DateTime.now().toUtc();
      }
      _emit(
        _status.copyWith(
          phase: failure == null ? SyncPhase.idle : SyncPhase.error,
          pendingOperations: await _syncDao.pendingCount(uid),
          lastSyncedAt: _lastSyncedAt,
          clearError: failure == null,
        ),
      );
      return failure;
    } catch (error) {
      final mapped = error is AppException
          ? error
          : const AppException(AppErrorCode.database);
      _setError(mapped);
      return mapped;
    } finally {
      _processing = false;
      // The replacement payload was queued while `_processing` was true, so
      // schedule the follow-up after releasing the guard.
      if (superseded && !_disposed && _attachedUid == uid) {
        _scheduleProcessing();
      }
    }
  }

  Future<void> _executeOperation(String uid, PendingOperation operation) async {
    final cloud = _cloud!;
    switch (operation.type) {
      case PendingOperationType.favoritesSync:
        final prefs = await _preferenceDao.getPreferences(uid);
        if (prefs.favoriteIds.length > AppConstants.maxFavoriteIds) {
          throw const AppException(AppErrorCode.limitReached);
        }
        await cloud.saveProfile(uid: uid, favoriteIds: prefs.favoriteIds);
      case PendingOperationType.pinsSync:
        final prefs = await _preferenceDao.getPreferences(uid);
        if (prefs.pinnedIds.length > AppConstants.maxPinnedIds) {
          throw const AppException(AppErrorCode.limitReached);
        }
        await cloud.saveProfile(uid: uid, pinnedIds: prefs.pinnedIds);
      case PendingOperationType.profileSync:
        final profile = await _profileDao.getProfile(uid);
        if (profile == null) return;
        await cloud.saveProfile(
          uid: uid,
          nickname: profile.nickname,
          email: profile.email,
          avatarId: profile.avatarId,
          createIfMissing: true,
        );
      case PendingOperationType.commandUpsert:
        final post = _parseCommandPayload(operation.payload, uid);
        await cloud.saveCommand(post);
        await _commandDao.markSynced(post);
      case PendingOperationType.commandDelete:
        if (operation.entityId.isEmpty) {
          throw const AppException(AppErrorCode.validation);
        }
        await cloud.deleteCommand(operation.entityId);
      default:
        throw const AppException(AppErrorCode.unknown);
    }
  }

  CommandPost _parseCommandPayload(
    Map<String, dynamic> payload,
    String expectedUid,
  ) {
    if (payload.isEmpty) {
      throw const AppException(AppErrorCode.validation);
    }
    try {
      final command = CommandPost.fromJson(payload);
      if (command.authorUid != expectedUid ||
          command.authorUid == AppConstants.seedAuthorUid) {
        throw const AppException(AppErrorCode.permissionDenied);
      }
      return command.copyWith(isSeed: false);
    } on FormatException {
      throw const AppException(AppErrorCode.validation);
    }
  }

  /// Pulls pages for cache hydration and retries pending operations. Local data
  /// is never cleared first; a failed refresh simply leaves the cache intact.
  Future<void> refresh({bool showBusy = true}) async {
    final uid = _attachedUid;
    final cloud = _cloud;
    if (cloud == null) {
      throw const AppException(AppErrorCode.firebaseNotConfigured);
    }
    if (uid == null) {
      // Cloud is available but no registered session is attached yet. Saying
      // "Firebase is not configured" here was misleading and hid the real
      // state from the user.
      throw const AppException(AppErrorCode.authRequired);
    }
    if (_refreshing) return;
    _refreshing = true;
    if (showBusy) {
      _emit(_status.copyWith(phase: SyncPhase.syncing, clearError: true));
    }
    try {
      Object? cursor;
      for (var page = 0; page < AppConstants.syncMaxPagesPerRefresh; page++) {
        final result = await cloud.fetchCommandsPage(
          limit: AppConstants.syncPageSize,
          cursor: cursor,
        );
        for (final post in result.commands) {
          await _commandDao.applyRemotePost(post);
        }
        cursor = result.cursor;
        if (!result.hasMore || cursor == null) break;
      }
      final authored = await cloud.fetchAuthoredCommands(uid);
      for (final post in authored) {
        await _commandDao.applyRemotePost(post);
      }
      if (!_profileBootstrapStarted) {
        final session = _session;
        if (session != null) await _bootstrapCloudProfile(session);
      }
      await _repairPendingCommands(uid);
      final pendingFailure = await _processPending(force: true);
      // A refresh that cannot upload queued work must not claim success. The
      // error is also what makes the retry actionable for the user.
      if (pendingFailure != null) throw pendingFailure;
      final now = DateTime.now().toUtc();
      _lastSyncedAt = now;
      await _syncDao.writeState(_lastSyncedKey, now.toIso8601String());
      _emit(
        _status.copyWith(
          phase: SyncPhase.idle,
          lastSyncedAt: now,
          pendingOperations: await _syncDao.pendingCount(uid),
          clearError: true,
        ),
      );
    } catch (error) {
      _setError(
        error is AppException
            ? error
            : const AppException(AppErrorCode.network),
      );
      rethrow;
    } finally {
      _refreshing = false;
    }
  }

  void _setError(AppException error) {
    _emit(
      _status.copyWith(
        phase: SyncPhase.error,
        error: error,
        pendingOperations: _pendingCount,
      ),
    );
  }

  void _setStatus(SyncStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  void _emit(SyncStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  Future<void> dispose() async {
    _disposed = true;
    await _detach();
    await _sessionSub?.cancel();
    _sessionSub = null;
    await _statusController.close();
  }
}
