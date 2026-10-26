import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/data/models/command_post.dart';

import '../support/test_helpers.dart';

void main() {
  group('CommandStep', () {
    test('sorts by order and keeps command text byte-for-byte', () {
      const command =
          '  printf "%s\\n" "hello world"  \n'
          '\techo \$HOME\n'
          'if [ -f "a b" ]; then\n'
          '  cat "a b"\n'
          'fi\n';
      final steps = CommandStep.sorted([
        buildStep(id: 'second', order: 2, command: 'echo second'),
        buildStep(id: 'first', order: 1, command: command),
      ]);

      expect(steps.map((step) => step.id), ['first', 'second']);
      expect(steps.first.command, command);
      expect(steps.first.command.contains('  printf'), isTrue);
      expect(steps.first.command.endsWith('\n'), isTrue);
    });

    test('copyWith changes metadata without altering the command', () {
      const original = 'git commit -m "fix: don\'t trim" && echo done';
      final step = buildStep(id: 's1', command: original);
      final copied = step.copyWith(title: 'Commit', order: 3);

      expect(copied.command, original);
      expect(copied.title, 'Commit');
      expect(copied.order, 3);
      expect(step.title, 'Step');
    });

    test('JSON round trip preserves run mode and raw command', () {
      const command = 'line one\nline two\\nliteral\n';
      final step = buildStep(
        id: 'step-1',
        order: 4,
        title: 'Run',
        description: 'Note',
        command: command,
        runMode: CommandRunMode.background,
      );

      final restored = CommandStep.fromJson(
        jsonDecode(jsonEncode(step.toJson())) as Map<String, dynamic>,
      );

      expect(restored.id, step.id);
      expect(restored.order, 4);
      expect(restored.command, command);
      expect(restored.runMode, CommandRunMode.background);
    });

    test('missing fields fall back safely', () {
      final step = CommandStep.fromJson(const {}, fallbackOrder: 5);
      expect(step.id, 'step-5');
      expect(step.order, 5);
      expect(step.command, isEmpty);
      expect(step.runMode, CommandRunMode.foreground);
    });
  });

  group('CommandPost', () {
    test('sorting is applied when constructing copies', () {
      final post = buildCommand(
        id: 'multi',
        steps: [
          buildStep(id: 'b', order: 2, command: 'echo b'),
          buildStep(id: 'a', order: 1, command: 'echo a'),
        ],
      );
      expect(post.steps.map((step) => step.id), ['b', 'a']);

      final sorted = post.copyWith(steps: post.steps);
      expect(sorted.steps.map((step) => step.id), ['a', 'b']);
      expect(sorted.allCommands, 'echo a\n\necho b');
      expect(sorted.stepCount, 2);
    });

    test('searchable text includes commands, tags and metadata', () {
      final post = buildCommand(
        id: 'search',
        name: 'Remote Sync',
        description: 'Copy files with rsync',
        tags: ['backup', 'ssh'],
        metadata: {'difficulty': 'Advanced'},
        steps: [
          buildStep(
            id: 'one',
            title: 'Transfer',
            description: 'Uses a key',
            command: 'rsync -avz ~/docs phone:/sdcard/docs',
          ),
        ],
      );

      expect(post.searchableText, contains('remote sync'));
      expect(post.searchableText, contains('copy files with rsync'));
      expect(post.searchableText, contains('backup ssh'));
      expect(post.searchableText, contains('difficulty advanced'));
      expect(post.searchableText, contains('rsync -avz'));
    });

    test('Firestore JSON shape and round trip preserve fields', () {
      final post = buildCommand(
        id: 'json-command',
        tags: const ['one', 'two'],
        metadata: const {'difficulty': 'Beginner'},
        steps: [
          buildStep(id: 's1', order: 0, command: 'echo one'),
          buildStep(id: 's2', order: 1, command: 'echo two'),
        ],
      );

      final json = post.toJson();
      expect(json['authorUid'], 'user-1');
      expect(json['categoryId'], 'package_management');
      expect((json['steps'] as List).length, 2);
      expect(json.containsKey('isSeed'), isFalse);

      final restored = CommandPost.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(restored.id, post.id);
      expect(restored.name, post.name);
      expect(restored.tags, post.tags);
      expect(restored.metadata, post.metadata);
      expect(restored.steps.map((step) => step.command), [
        'echo one',
        'echo two',
      ]);
      expect(restored.isSeed, isTrue);
      expect(restored.status, CommandStatus.published);
    });

    test('seed JSON normalises tags and tolerates missing optional data', () {
      final post = CommandPost.fromJson({
        'id': 'seed-only',
        'name': 'Seed',
        'steps': [
          {'command': 'echo seed'},
        ],
        'tags': ['  Keep  ', 'keep', 'second  tag'],
      });

      expect(post.tags, ['Keep', 'second tag']);
      expect(post.categoryId, 'package_management');
      expect(post.authorUid, 'termux-library');
      expect(post.isSeed, isTrue);
      expect(post.steps.single.order, 0);
      expect(post.steps.single.command, 'echo seed');
    });

    test('status and run mode parsing are forward compatible', () {
      expect(CommandStatus.parse('draft'), CommandStatus.draft);
      expect(CommandStatus.parse('archived'), CommandStatus.archived);
      expect(CommandStatus.parse('future-value'), CommandStatus.published);
      expect(CommandRunMode.parse('background'), CommandRunMode.background);
      expect(CommandRunMode.parse(null), CommandRunMode.foreground);
    });
  });
}
