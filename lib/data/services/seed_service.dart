import 'dart:async';
import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../local/database/daos/command_dao.dart';
import '../local/database/daos/sync_dao.dart';
import '../models/command_post.dart';

/// Installs the curated offline catalogue into SQLite. Firestore is never
/// required for this content, so a fresh install always has something useful.
class SeedService {
  SeedService({
    required CommandDao commandDao,
    required SyncDao syncDao,
    required Future<String> Function() loadAsset,
  }) : _commandDao = commandDao,
       _syncDao = syncDao,
       _loadAsset = loadAsset;

  final CommandDao _commandDao;
  final SyncDao _syncDao;
  final Future<String> Function() _loadAsset;

  static const _stateKey = 'seedVersion';

  /// Returns true when a new seed version was installed.
  Future<bool> ensureSeeded() async {
    final stored = await _syncDao.readState(_stateKey);
    if (int.tryParse(stored ?? '') == AppConstants.currentSeedVersion) {
      return false;
    }
    String raw;
    try {
      raw = await _loadAsset();
    } catch (error) {
      throw AppException(AppErrorCode.database, cause: error);
    }
    final commands = _parseSeed(raw);
    for (final command in commands) {
      await _commandDao.upsertSeedPost(command);
    }
    await _syncDao.writeState(
      _stateKey,
      AppConstants.currentSeedVersion.toString(),
    );
    return true;
  }

  List<CommandPost> _parseSeed(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Seed data must be a list.');
      }
      final commands = <CommandPost>[];
      for (final entry in decoded) {
        if (entry is Map) {
          try {
            commands.add(
              CommandPost.fromJson(Map<String, dynamic>.from(entry)),
            );
          } on FormatException {
            // Skip a malformed guide rather than blocking the entire starter
            // library. The catalogue is validated by tests.
          }
        }
      }
      return commands;
    } on FormatException catch (error) {
      throw AppException(AppErrorCode.database, cause: error);
    }
  }
}
