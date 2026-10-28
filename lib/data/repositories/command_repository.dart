import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../local/database/daos/command_dao.dart';
import '../local/database/daos/preference_dao.dart';
import '../local/database/daos/sync_dao.dart';
import '../models/auth_models.dart';
import '../models/command_category.dart';
import '../models/command_post.dart';
import '../models/command_query.dart';
import '../models/user_profile.dart';

/// Local-first command library operations. Every mutation lands in SQLite
/// first; cloud writes are queued durably and never block the UI.
class CommandRepository {
  CommandRepository({
    required CommandDao commandDao,
    required PreferenceDao preferenceDao,
    required SyncDao syncDao,
    required bool cloudConfigured,
  }) : _commandDao = commandDao,
       _preferenceDao = preferenceDao,
       _syncDao = syncDao,
       _cloudConfigured = cloudConfigured;

  final CommandDao _commandDao;
  final PreferenceDao _preferenceDao;
  final SyncDao _syncDao;
  final bool _cloudConfigured;

  Stream<List<CommandSummary>> watchCommands(
    CommandListQuery query,
    String uid,
  ) => _commandDao.watchCommands(query, uid);

  Stream<CommandPost?> watchCommand(String id) => _commandDao.watchCommand(id);

  Stream<List<CommandSummary>> watchPinned(String uid) =>
      _commandDao.watchPinnedCommands(uid);

  Stream<LibraryStats> watchStats(String uid) => _commandDao.watchStats(uid);

  Stream<List<CategoryCount>> watchCategoryCounts() =>
      _commandDao.watchCategoryCounts();

  Future<CommandPost?> getCommand(String id) => _commandDao.getCommand(id);

  Future<int> countCommands() => _commandDao.countCommands();

  // ---------------------------------------------------------------------------
  // Favorites and pins
  // ---------------------------------------------------------------------------

  Future<void> setFavorite({
    required AuthSession session,
    required String commandId,
    required bool favorite,
  }) async {
    if (favorite) {
      final count = await _preferenceDao.countFavorites(session.uid);
      if (count >= AppConstants.maxFavoriteIds) {
        throw const AppException(AppErrorCode.limitReached);
      }
    }
    await _preferenceDao.setFavorite(
      session.uid,
      commandId,
      favorite: favorite,
    );
    await _queuePreferenceSync(session, favorites: true);
  }

  Future<void> setPinned({
    required AuthSession session,
    required String commandId,
    required bool pinned,
  }) async {
    if (pinned) {
      final prefs = await _preferenceDao.getPreferences(session.uid);
      if (prefs.pinnedIds.length >= AppConstants.maxPinnedIds) {
        throw const AppException(AppErrorCode.limitReached);
      }
    }
    await _preferenceDao.setPinned(session.uid, commandId, pinned: pinned);
    await _queuePreferenceSync(session, pins: true);
  }

  Future<void> reorderPins({
    required AuthSession session,
    required List<String> orderedIds,
  }) async {
    if (orderedIds.length > AppConstants.maxPinnedIds) {
      throw const AppException(AppErrorCode.limitReached);
    }
    await _preferenceDao.reorderPins(session.uid, orderedIds);
    await _queuePreferenceSync(session, pins: true);
  }

  Future<void> _queuePreferenceSync(
    AuthSession session, {
    bool favorites = false,
    bool pins = false,
  }) async {
    if (session.isLocalOnly || !_cloudConfigured) return;
    if (favorites) {
      await _syncDao.enqueue(
        uid: session.uid,
        type: PendingOperationType.favoritesSync,
      );
    }
    if (pins) {
      await _syncDao.enqueue(
        uid: session.uid,
        type: PendingOperationType.pinsSync,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Authoring
  // ---------------------------------------------------------------------------

  /// Creates or updates a guide. Returns the saved local model with its new
  /// version/timestamp. [publish] controls whether the guide is visible.
  Future<CommandPost> savePost({
    required AuthSession session,
    required CommandPost post,
    required bool publish,
    String authorNickname = '',
  }) async {
    if (!_cloudConfigured) {
      throw const AppException(AppErrorCode.firebaseNotConfigured);
    }
    if (!session.canPublish) {
      throw const AppException(AppErrorCode.authRequired);
    }
    if (!CommandCategories.isValid(post.categoryId)) {
      throw const AppException(AppErrorCode.validation);
    }

    final existing = await _commandDao.getCommand(post.id);
    if (existing != null) {
      if (existing.isSeed) {
        throw const AppException(AppErrorCode.permissionDenied);
      }
      if (existing.authorUid != session.uid && !session.isAdmin) {
        throw const AppException(AppErrorCode.permissionDenied);
      }
    }

    if (publish) {
      _validateForPublish(post);
    } else if (post.name.trim().isEmpty) {
      throw const AppException(AppErrorCode.validation);
    }

    final now = DateTime.now().toUtc();
    final steps = <CommandStep>[];
    for (var index = 0; index < post.steps.length; index++) {
      final step = post.steps[index];
      steps.add(step.copyWith(order: index));
    }
    if (steps.length > AppConstants.maxSteps) {
      throw const AppException(AppErrorCode.limitReached);
    }

    final normalizedTags = Validators.normalizeTags(post.tags);
    final metadata = Map<String, String>.from(post.metadata);
    if (metadata.length > AppConstants.maxMetadataEntries ||
        metadata.values.any(
          (value) => value.length > AppConstants.maxMetadataValueLength,
        )) {
      throw const AppException(AppErrorCode.limitReached);
    }

    final editingOtherAuthor =
        existing != null && existing.authorUid != session.uid;
    final saved = CommandPost(
      id: post.id,
      name: post.name.trim(),
      description: post.description.trim(),
      categoryId: post.categoryId,
      tags: normalizedTags,
      metadata: metadata,
      steps: steps,
      authorUid: existing?.authorUid ?? session.uid,
      // An admin editing a community guide preserves the original author's
      // attribution. Taking the admin's nickname here made the guide look as if
      // it had been re-authored.
      authorNickname: editingOtherAuthor
          ? existing.authorNickname
          : authorNickname.trim().isNotEmpty
          ? authorNickname.trim()
          : (existing?.authorNickname ?? ''),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      version: existing == null
          ? 1
          : math.max(existing.version + 1, post.version + 1),
      status: publish ? CommandStatus.published : CommandStatus.draft,
      isSeed: false,
      isPendingSync: !session.isLocalOnly,
    );

    await _commandDao.saveLocalPost(saved, pendingSync: !session.isLocalOnly);
    if (!session.isLocalOnly) {
      // A guide loaded from the cache without a pending write is known to have
      // a remote copy. A brand-new guide, or one whose first upload never
      // completed, has none. The gateway falls back to the other write if this
      // hint is stale, so it is only an optimization, never an authorization
      // decision.
      final remoteExists = existing != null && !existing.isPendingSync;
      await _syncDao.enqueue(
        uid: session.uid,
        type: PendingOperationType.commandUpsert,
        entityId: saved.id,
        payload: {...saved.toJson(), 'remoteExists': remoteExists},
      );
    }
    return saved;
  }

  void _validateForPublish(CommandPost post) {
    if (Validators.nameError(post.name) != null ||
        Validators.descriptionError(post.description) != null ||
        post.steps.isEmpty) {
      throw const AppException(AppErrorCode.validation);
    }
    if (post.steps.length > AppConstants.maxSteps) {
      throw const AppException(AppErrorCode.limitReached);
    }
    for (final step in post.steps) {
      final title = step.title.trim();
      if (title.isEmpty ||
          title.length > AppConstants.maxStepTitleLength ||
          Validators.commandError(step.command) != null ||
          step.description.length > AppConstants.maxStepDescriptionLength) {
        throw const AppException(AppErrorCode.validation);
      }
    }
  }

  Future<void> deletePost({
    required AuthSession session,
    required String commandId,
  }) async {
    final existing = await _commandDao.getCommand(commandId);
    if (existing == null) return;
    if (existing.isSeed) {
      throw const AppException(AppErrorCode.permissionDenied);
    }
    if (existing.authorUid != session.uid && !session.isAdmin) {
      throw const AppException(AppErrorCode.permissionDenied);
    }
    if (!session.isLocalOnly && _cloudConfigured) {
      // Persist the delete intent before removing the row. If the process dies
      // in between, the queued operation still removes the cloud document and
      // the tombstone hides any stale remote snapshot. This also drops a
      // pending creation: the delete is the user's final intent and succeeds
      // even when the document never reached Firestore.
      await _syncDao.enqueueCommandDelete(
        uid: session.uid,
        commandId: commandId,
      );
    }
    await _commandDao.deleteLocalCommand(commandId);
    final removedPreferences = await _preferenceDao.removeCommandForUser(
      session.uid,
      commandId,
    );
    if (removedPreferences) {
      await _queuePreferenceSync(session, favorites: true, pins: true);
    }
  }

  /// Deletes a guide only on this device. Used by "clear cache"; cloud content
  /// reappears on the next refresh.
  Future<int> clearRemoteCache(String uid) => _commandDao.clearRemoteCache(uid);
}
