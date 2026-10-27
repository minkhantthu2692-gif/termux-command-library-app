import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/models/command_post.dart';
import 'package:termux_command_library/data/models/command_query.dart';
import 'package:termux_command_library/data/models/user_profile.dart';

import '../support/test_helpers.dart';

void main() {
  late AppDatabase db;
  const uid = 'user-1';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('CommandDao writes and reads', () {
    test(
      'round trips multi-step commands without changing whitespace',
      () async {
        const script =
            'if [ -d "\$HOME/project" ]; then\n'
            '  cd "\$HOME/project"\n'
            '  git status --short\n'
            'fi\n';
        final post = buildCommand(
          id: 'multiline',
          steps: [
            buildStep(id: 's2', order: 1, title: 'Second', command: 'echo two'),
            buildStep(
              id: 's1',
              order: 0,
              title: 'First',
              description: 'Runs a script',
              command: script,
              runMode: CommandRunMode.background,
            ),
          ],
        );

        await db.commandDao.saveLocalPost(post, pendingSync: false);
        final loaded = await db.commandDao.getCommand(post.id);

        expect(loaded, isNotNull);
        expect(loaded!.steps.map((step) => step.id), ['s1', 's2']);
        expect(loaded.steps.first.command, script);
        expect(loaded.steps.first.runMode, CommandRunMode.background);
        expect(loaded.steps.last.order, 1);
        expect(loaded.stepCount, 2);
      },
    );

    test('saving an edit replaces the complete step set', () async {
      final original = buildCommand(
        id: 'edit-me',
        steps: [
          buildStep(id: 'old-1', order: 0, command: 'echo old'),
          buildStep(id: 'old-2', order: 1, command: 'echo removed'),
        ],
      );
      await db.commandDao.saveLocalPost(original, pendingSync: false);

      final edited = original.copyWith(
        name: 'Edited',
        steps: [buildStep(id: 'new-1', order: 0, command: 'echo new')],
        isPendingSync: true,
      );
      await db.commandDao.saveLocalPost(edited, pendingSync: true);

      final loaded = await db.commandDao.getCommand(original.id);
      expect(loaded!.name, 'Edited');
      expect(loaded.steps, hasLength(1));
      expect(loaded.steps.single.command, 'echo new');
      expect(loaded.isPendingSync, isTrue);
    });

    test('counts, ids and watched details are available', () async {
      await db.commandDao.saveLocalPost(
        buildCommand(id: 'a'),
        pendingSync: false,
      );
      await db.commandDao.saveLocalPost(
        buildCommand(id: 'b'),
        pendingSync: false,
      );

      expect(await db.commandDao.countCommands(), 2);
      expect(await db.commandDao.getAllCommandIds(), containsAll(['a', 'b']));

      final watched = await db.commandDao.watchCommand('a').first;
      expect(watched?.id, 'a');
    });
  });

  group('CommandDao querying', () {
    setUp(() async {
      final base = DateTime.utc(2026, 10, 1, 8);
      await db.commandDao.saveLocalPost(
        buildCommand(
          id: 'git-basics',
          name: 'Git basics',
          description: 'Version control essentials',
          categoryId: 'git_version_control',
          tags: const ['git', 'version'],
          createdAt: base,
          updatedAt: base,
        ),
        pendingSync: false,
      );
      await db.commandDao.saveLocalPost(
        buildCommand(
          id: 'python-setup',
          name: 'Python setup',
          description: 'Set up Python and pip',
          categoryId: 'programming_development',
          tags: const ['python'],
          createdAt: base.add(const Duration(days: 1)),
          updatedAt: base.add(const Duration(days: 1)),
          steps: [
            buildStep(id: 'py-1', order: 0, command: 'pkg install python'),
            buildStep(id: 'py-2', order: 1, command: 'python --version'),
            buildStep(id: 'py-3', order: 2, command: 'pip --version'),
          ],
        ),
        pendingSync: false,
      );
      await db.commandDao.saveLocalPost(
        buildCommand(
          id: 'file-cleanup',
          name: 'File cleanup',
          description: 'Delete temporary files safely',
          categoryId: 'file_storage',
          tags: const ['files'],
          createdAt: base.add(const Duration(days: 2)),
          updatedAt: base.add(const Duration(days: 2)),
          steps: [
            buildStep(id: 'file-1', order: 0, command: 'du -sh ~'),
            buildStep(id: 'file-2', order: 1, command: 'rm -rf ~/tmp/cache'),
          ],
        ),
        pendingSync: false,
      );
      await db.commandDao.saveLocalPost(
        buildCommand(
          id: 'my-draft',
          name: 'My private draft',
          description: 'Work in progress',
          categoryId: 'shell_scripting',
          createdAt: base.add(const Duration(days: 3)),
          updatedAt: base.add(const Duration(days: 3)),
          status: CommandStatus.draft,
        ),
        pendingSync: false,
      );
      await db.commandDao.saveLocalPost(
        buildCommand(
          id: 'archived-post',
          name: 'Archived',
          description: 'Old guide',
          authorUid: 'user-2',
          status: CommandStatus.archived,
        ),
        pendingSync: false,
      );
    });

    Future<List<CommandSummary>> read(CommandListQuery query) =>
        db.commandDao.watchCommands(query, uid).first;

    test('public browsing excludes drafts and archived guides', () async {
      final results = await read(const CommandListQuery(limit: 20));
      expect(results.map((command) => command.id), [
        'file-cleanup',
        'python-setup',
        'git-basics',
      ]);
    });

    test('includeDrafts shows only the caller own drafts', () async {
      final results = await read(
        const CommandListQuery(limit: 20, includeDrafts: true),
      );
      expect(results.map((command) => command.id), contains('my-draft'));
      expect(
        results.map((command) => command.id),
        isNot(contains('archived-post')),
      );

      final otherUser = await db.commandDao
          .watchCommands(
            const CommandListQuery(limit: 20, includeDrafts: true),
            'user-2',
          )
          .first;
      expect(
        otherUser.map((command) => command.id),
        isNot(contains('my-draft')),
      );
    });

    test('search covers name, description, tags and category', () async {
      expect(
        (await read(const CommandListQuery(search: 'python'))).single.id,
        'python-setup',
      );
      expect(
        (await read(const CommandListQuery(search: 'version control')))
            .single
            .id,
        'git-basics',
      );
      expect(
        (await read(const CommandListQuery(search: 'FILES'))).single.id,
        'file-cleanup',
      );
      expect(
        (await read(const CommandListQuery(search: 'programming_development')))
            .single
            .id,
        'python-setup',
      );
      expect(
        await read(const CommandListQuery(search: 'no-such-guide')),
        isEmpty,
      );
    });

    test('literal LIKE wildcards are escaped', () async {
      await db.commandDao.saveLocalPost(
        buildCommand(
          id: 'percent-guide',
          name: 'Battery at 100%',
          description: 'Check percentage',
        ),
        pendingSync: false,
      );

      final all = await read(const CommandListQuery(search: '%'));
      expect(all.map((command) => command.id), isNot(contains('git-basics')));
      expect(all.map((command) => command.id), contains('percent-guide'));
    });

    test('category and author filters compose', () async {
      final files = await read(
        const CommandListQuery(categoryId: 'file_storage'),
      );
      expect(files.single.id, 'file-cleanup');

      final mine = await read(
        const CommandListQuery(authorUid: 'user-1', includeDrafts: true),
      );
      expect(
        mine.map((command) => command.id),
        containsAll(['git-basics', 'python-setup', 'file-cleanup', 'my-draft']),
      );
      expect(
        mine.map((command) => command.id),
        isNot(contains('archived-post')),
      );
    });

    test('sorting supports recency, creation, name and step count', () async {
      final newest = await read(
        const CommandListQuery(sort: CommandSort.newest),
      );
      expect(newest.map((command) => command.id), [
        'file-cleanup',
        'python-setup',
        'git-basics',
      ]);

      final byName = await read(
        const CommandListQuery(sort: CommandSort.nameAscending),
      );
      expect(byName.map((command) => command.name), [
        'File cleanup',
        'Git basics',
        'Python setup',
      ]);

      final mostSteps = await read(
        const CommandListQuery(sort: CommandSort.mostSteps),
      );
      expect(mostSteps.first.id, 'python-setup');
      expect(mostSteps.map((command) => command.stepCount), [3, 2, 1]);
    });

    test('pagination is stable and ordered', () async {
      final firstPage = await read(const CommandListQuery(limit: 2));
      final secondPage = await read(
        const CommandListQuery(limit: 2, offset: 2),
      );
      expect(firstPage, hasLength(2));
      expect(secondPage, hasLength(1));
      expect([...firstPage, ...secondPage].map((command) => command.id), [
        'file-cleanup',
        'python-setup',
        'git-basics',
      ]);
    });

    test('favorites and pins filter local results', () async {
      await db.preferenceDao.setFavorite(uid, 'git-basics', favorite: true);
      await db.preferenceDao.setFavorite(uid, 'python-setup', favorite: true);
      await db.preferenceDao.setPinned(uid, 'python-setup', pinned: true);

      final favorites = await read(const CommandListQuery(favoritesOnly: true));
      expect(favorites.map((command) => command.id), [
        'python-setup',
        'git-basics',
      ]);

      final pinned = await read(const CommandListQuery(pinnedOnly: true));
      expect(pinned.single.id, 'python-setup');
    });

    test('pinned commands preserve user order', () async {
      await db.preferenceDao.setPinned(uid, 'git-basics', pinned: true);
      await db.preferenceDao.setPinned(uid, 'file-cleanup', pinned: true);
      await db.preferenceDao.setPinned(uid, 'python-setup', pinned: true);
      await db.preferenceDao.reorderPins(uid, [
        'python-setup',
        'git-basics',
        'file-cleanup',
      ]);

      final pinned = await db.commandDao.watchPinnedCommands(uid).first;
      expect(pinned.map((command) => command.id), [
        'python-setup',
        'git-basics',
        'file-cleanup',
      ]);
    });

    test('stats and category counts reflect published local data', () async {
      await db.preferenceDao.setFavorite(uid, 'git-basics', favorite: true);
      await db.preferenceDao.setFavorite(uid, 'python-setup', favorite: true);
      await db.preferenceDao.setPinned(uid, 'git-basics', pinned: true);

      final stats = await db.commandDao.watchStats(uid).first;
      expect(
        stats,
        const LibraryStats(total: 3, mine: 4, favorites: 2, pins: 1),
      );

      final counts = await db.commandDao.watchCategoryCounts().first;
      expect(
        {for (final count in counts) count.categoryId: count.count},
        {
          'git_version_control': 1,
          'programming_development': 1,
          'file_storage': 1,
        },
      );
    });
  });

  group('CommandDao synchronization rules', () {
    test('remote upserts never overwrite a pending local edit', () async {
      final local = buildCommand(
        id: 'pending',
        name: 'Local edit',
        isPendingSync: true,
        version: 2,
      );
      await db.commandDao.saveLocalPost(local, pendingSync: true);

      final applied = await db.commandDao.applyRemotePost(
        buildCommand(id: 'pending', name: 'Remote edit', version: 3),
      );

      expect(applied, isFalse);
      final loaded = await db.commandDao.getCommand('pending');
      expect(loaded!.name, 'Local edit');
      expect(loaded.isPendingSync, isTrue);
      expect(loaded.version, 2);
    });

    test(
      'remote upserts reject older versions and accept newer ones',
      () async {
        await db.commandDao.saveLocalPost(
          buildCommand(id: 'versioned', name: 'Version 3', version: 3),
          pendingSync: false,
        );

        final older = await db.commandDao.applyRemotePost(
          buildCommand(id: 'versioned', name: 'Version 2', version: 2),
        );
        expect(older, isFalse);

        final newer = await db.commandDao.applyRemotePost(
          buildCommand(
            id: 'versioned',
            name: 'Version 4',
            version: 4,
            updatedAt: DateTime.utc(2026, 12, 1),
          ),
        );
        expect(newer, isTrue);
        expect(
          (await db.commandDao.getCommand('versioned'))!.name,
          'Version 4',
        );
      },
    );

    test('equal versions use updatedAt as a tie breaker', () async {
      final original = DateTime.utc(2026, 10, 1);
      await db.commandDao.saveLocalPost(
        buildCommand(id: 'tie', name: 'Older', updatedAt: original),
        pendingSync: false,
      );

      final stale = await db.commandDao.applyRemotePost(
        buildCommand(
          id: 'tie',
          name: 'Stale remote',
          updatedAt: original.subtract(const Duration(minutes: 1)),
        ),
      );
      expect(stale, isFalse);

      final fresh = await db.commandDao.applyRemotePost(
        buildCommand(
          id: 'tie',
          name: 'Fresh remote',
          updatedAt: original.add(const Duration(minutes: 1)),
        ),
      );
      expect(fresh, isTrue);
      expect((await db.commandDao.getCommand('tie'))!.name, 'Fresh remote');
    });

    test('markSynced does not clear a newer pending local edit', () async {
      await db.commandDao.saveLocalPost(
        buildCommand(
          id: 'inflight',
          name: 'Newer local',
          version: 2,
          updatedAt: DateTime.utc(2026, 10, 1, 9),
          isPendingSync: true,
        ),
        pendingSync: true,
      );

      await db.commandDao.markSynced(
        buildCommand(id: 'inflight', name: 'Remote response'),
      );

      final loaded = await db.commandDao.getCommand('inflight');
      expect(loaded!.name, 'Newer local');
      expect(loaded.isPendingSync, isTrue);
    });

    test('markSynced clears the flag for an acknowledged write', () async {
      await db.commandDao.saveLocalPost(
        buildCommand(id: 'ack', name: 'Local', isPendingSync: true),
        pendingSync: true,
      );

      await db.commandDao.markSynced(
        buildCommand(id: 'ack', name: 'Server copy'),
      );

      final loaded = await db.commandDao.getCommand('ack');
      expect(loaded!.name, 'Server copy');
      expect(loaded.isPendingSync, isFalse);
    });

    test('remote deletion preserves seeds and pending edits', () async {
      await db.commandDao.upsertSeedPost(
        buildCommand(id: 'seed', isSeed: true, authorUid: 'termux-library'),
      );
      await db.commandDao.saveLocalPost(
        buildCommand(id: 'pending', isPendingSync: true),
        pendingSync: true,
      );
      await db.commandDao.saveLocalPost(
        buildCommand(id: 'ordinary'),
        pendingSync: false,
      );

      expect(await db.commandDao.deleteRemoteCommand('seed'), isFalse);
      expect(await db.commandDao.deleteRemoteCommand('pending'), isFalse);
      expect(await db.commandDao.deleteRemoteCommand('ordinary'), isTrue);
      expect(await db.commandDao.getCommand('seed'), isNotNull);
      expect(await db.commandDao.getCommand('pending'), isNotNull);
      expect(await db.commandDao.getCommand('ordinary'), isNull);
    });

    test(
      'clearRemoteCache preserves seeds, own posts, favorites and pending',
      () async {
        await db.commandDao.upsertSeedPost(
          buildCommand(id: 'seed', isSeed: true, authorUid: 'termux-library'),
        );
        await db.commandDao.saveLocalPost(
          buildCommand(id: 'mine', authorUid: uid),
          pendingSync: false,
        );
        await db.commandDao.saveLocalPost(
          buildCommand(id: 'favorite', authorUid: 'user-2'),
          pendingSync: false,
        );
        await db.commandDao.saveLocalPost(
          buildCommand(id: 'pending', authorUid: 'user-2', isPendingSync: true),
          pendingSync: true,
        );
        await db.commandDao.saveLocalPost(
          buildCommand(id: 'cached', authorUid: 'user-2'),
          pendingSync: false,
        );
        await db.preferenceDao.setFavorite(uid, 'favorite', favorite: true);

        final removed = await db.commandDao.clearRemoteCache(uid);

        expect(removed, 1);
        final remaining = await db.commandDao.getAllCommandIds();
        expect(remaining, containsAll(['seed', 'mine', 'favorite', 'pending']));
        expect(remaining, isNot(contains('cached')));
      },
    );

    test(
      'account deletion clears only the author own non-seed posts',
      () async {
        await db.commandDao.upsertSeedPost(
          buildCommand(id: 'seed', isSeed: true, authorUid: 'termux-library'),
        );
        await db.commandDao.saveLocalPost(
          buildCommand(id: 'mine', authorUid: uid),
          pendingSync: false,
        );
        await db.commandDao.saveLocalPost(
          buildCommand(id: 'other', authorUid: 'user-2'),
          pendingSync: false,
        );

        expect(await db.commandDao.deleteLocalCommandsByAuthor(uid), 1);
        final remaining = await db.commandDao.getAllCommandIds();
        expect(remaining, containsAll(['seed', 'other']));
        expect(remaining, isNot(contains('mine')));
      },
    );
  });
}
