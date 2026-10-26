import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';

import '../support/test_helpers.dart';

void main() {
  late AppDatabase db;
  const uid = 'user-1';
  const otherUid = 'user-2';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('favorites', () {
    test('are idempotent and namespaced by uid', () async {
      await db.preferenceDao.setFavorite(uid, 'guide-a', favorite: true);
      await db.preferenceDao.setFavorite(uid, 'guide-a', favorite: true);
      await db.preferenceDao.setFavorite(otherUid, 'guide-b', favorite: true);

      final first = await db.preferenceDao.getPreferences(uid);
      final second = await db.preferenceDao.getPreferences(otherUid);
      expect(first.favoriteIds, {'guide-a'});
      expect(second.favoriteIds, {'guide-b'});
      expect(await db.preferenceDao.countFavorites(uid), 1);

      await db.preferenceDao.setFavorite(uid, 'guide-a', favorite: false);
      expect((await db.preferenceDao.getPreferences(uid)).favoriteIds, isEmpty);
      expect((await db.preferenceDao.getPreferences(otherUid)).favoriteIds, {
        'guide-b',
      });
    });

    test('stream reflects changes', () async {
      final emissions = <List<String>>[];
      final subscription = db.preferenceDao
          .watchPreferences(uid)
          .listen((preferences) => emissions.add(preferences.pinnedIds));
      await Future<void>.delayed(Duration.zero);
      await db.preferenceDao.setPinned(uid, 'a', pinned: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await db.preferenceDao.setPinned(uid, 'b', pinned: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await subscription.cancel();

      expect(emissions.last, ['a', 'b']);
    });
  });

  group('pins', () {
    test('append in user order and reorder without dropping rows', () async {
      await db.preferenceDao.setPinned(uid, 'a', pinned: true);
      await db.preferenceDao.setPinned(uid, 'b', pinned: true);
      await db.preferenceDao.setPinned(uid, 'c', pinned: true);
      expect((await db.preferenceDao.getPreferences(uid)).pinnedIds, [
        'a',
        'b',
        'c',
      ]);

      await db.preferenceDao.reorderPins(uid, ['c', 'a']);
      expect((await db.preferenceDao.getPreferences(uid)).pinnedIds, [
        'c',
        'a',
        'b',
      ]);

      await db.preferenceDao.reorderPins(uid, ['unknown']);
      expect((await db.preferenceDao.getPreferences(uid)).pinnedIds, [
        'c',
        'a',
        'b',
      ]);
    });

    test('pinning twice does not duplicate a row', () async {
      await db.preferenceDao.setPinned(uid, 'a', pinned: true);
      await db.preferenceDao.setPinned(uid, 'a', pinned: true);
      expect((await db.preferenceDao.getPreferences(uid)).pinnedIds, ['a']);
    });

    test('unpinning renormalises the remaining order', () async {
      await db.preferenceDao.setPinned(uid, 'a', pinned: true);
      await db.preferenceDao.setPinned(uid, 'b', pinned: true);
      await db.preferenceDao.setPinned(uid, 'c', pinned: true);

      await db.preferenceDao.setPinned(uid, 'b', pinned: false);
      expect((await db.preferenceDao.getPreferences(uid)).pinnedIds, [
        'a',
        'c',
      ]);

      await db.preferenceDao.setPinned(uid, 'a', pinned: false);
      expect((await db.preferenceDao.getPreferences(uid)).pinnedIds, ['c']);
    });

    test('users have independent pin lists', () async {
      await db.preferenceDao.setPinned(uid, 'a', pinned: true);
      await db.preferenceDao.setPinned(otherUid, 'x', pinned: true);
      expect((await db.preferenceDao.getPreferences(uid)).pinnedIds, ['a']);
      expect((await db.preferenceDao.getPreferences(otherUid)).pinnedIds, [
        'x',
      ]);
    });
  });

  group('remote preference snapshots', () {
    test('replaceAll applies favorites and ordered pins atomically', () async {
      await db.preferenceDao.setFavorite(uid, 'old', favorite: true);
      await db.preferenceDao.setPinned(uid, 'old-pin', pinned: true);

      await db.preferenceDao.replaceAll(
        uid,
        favoriteIds: {'a', 'b'},
        pinnedIds: ['c', 'b', 'a'],
      );

      final preferences = await db.preferenceDao.getPreferences(uid);
      expect(preferences.favoriteIds, {'a', 'b'});
      expect(preferences.pinnedIds, ['c', 'b', 'a']);
    });

    test('replaceAll can clear both collections', () async {
      await db.preferenceDao.replaceAll(
        uid,
        favoriteIds: const {},
        pinnedIds: const [],
      );
      final preferences = await db.preferenceDao.getPreferences(uid);
      expect(preferences.favoriteIds, isEmpty);
      expect(preferences.pinnedIds, isEmpty);
    });

    test('clearForUser only affects one account', () async {
      await db.preferenceDao.setFavorite(uid, 'a', favorite: true);
      await db.preferenceDao.setPinned(uid, 'a', pinned: true);
      await db.preferenceDao.setFavorite(otherUid, 'b', favorite: true);

      await db.preferenceDao.clearForUser(uid);
      expect(await db.preferenceDao.countFavorites(uid), 0);
      expect((await db.preferenceDao.getPreferences(otherUid)).favoriteIds, {
        'b',
      });
    });

    test('removeCommandForUser removes both records for that user', () async {
      await db.preferenceDao.setFavorite(uid, 'guide', favorite: true);
      await db.preferenceDao.setPinned(uid, 'guide', pinned: true);

      expect(await db.preferenceDao.removeCommandForUser(uid, 'guide'), isTrue);
      final preferences = await db.preferenceDao.getPreferences(uid);
      expect(preferences.favoriteIds, isEmpty);
      expect(preferences.pinnedIds, isEmpty);
      expect(
        await db.preferenceDao.removeCommandForUser(uid, 'missing'),
        isFalse,
      );
    });
  });

  test(
    'favorites and pins survive closing and reopening the database',
    () async {
      final directory = Directory.systemTemp.createTempSync('tcl_prefs_');
      final file = File(
        '${directory.path}${Platform.pathSeparator}library.sqlite',
      );
      AppDatabase? first;
      AppDatabase? second;
      try {
        first = AppDatabase(NativeDatabase(file));
        await first.commandDao.saveLocalPost(
          buildCommand(id: 'persisted'),
          pendingSync: false,
        );
        await first.preferenceDao.setFavorite(uid, 'persisted', favorite: true);
        await first.preferenceDao.setPinned(uid, 'persisted', pinned: true);
        await first.preferenceDao.setPinned(uid, 'second', pinned: true);
        await first.preferenceDao.reorderPins(uid, ['second', 'persisted']);
        await first.close();
        first = null;

        second = AppDatabase(NativeDatabase(file));
        final preferences = await second.preferenceDao.getPreferences(uid);
        expect(preferences.favoriteIds, {'persisted'});
        expect(preferences.pinnedIds, ['second', 'persisted']);
        expect(await second.commandDao.getCommand('persisted'), isNotNull);
        await second.close();
        second = null;
      } finally {
        await first?.close();
        await second?.close();
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      }
    },
  );
}
