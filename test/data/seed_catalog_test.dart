import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/constants/app_constants.dart';
import 'package:termux_command_library/data/models/command_category.dart';
import 'package:termux_command_library/data/models/command_post.dart';

void main() {
  late List<dynamic> raw;
  late List<CommandPost> seeded;

  setUpAll(() {
    final file = File('assets/data/seed_commands.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Run tests from the project root.',
    );
    raw = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    seeded = raw
        .whereType<Map>()
        .map((entry) => CommandPost.fromJson(Map<String, dynamic>.from(entry)))
        .toList(growable: false);
  });

  test('starter catalogue is non-empty and completely parseable', () {
    expect(seeded, hasLength(52));
    expect(seeded, hasLength(raw.length));
  });

  test('every guide has a unique id and belongs to a known category', () {
    final ids = seeded.map((post) => post.id).toList();
    expect(ids.toSet(), hasLength(ids.length));

    for (final post in seeded) {
      expect(
        CommandCategories.isValid(post.categoryId),
        isTrue,
        reason: '${post.id} has category ${post.categoryId}',
      );
      expect(post.name.trim(), isNotEmpty);
      expect(post.description.trim(), isNotEmpty);
      expect(post.steps, isNotEmpty);
    }
  });

  test('all ten categories are represented', () {
    final categories = seeded.map((post) => post.categoryId).toSet();
    expect(categories, CommandCategories.ids);
  });

  test('starter guides are published, attributed and marked as seeds', () {
    for (final post in seeded) {
      expect(post.status, CommandStatus.published);
      expect(post.isSeed, isTrue);
      expect(post.authorUid, AppConstants.seedAuthorUid);
      expect(post.authorNickname, AppConstants.seedAuthorName);
      expect(post.version, greaterThanOrEqualTo(1));
    }
  });

  test('step ids are unique across the entire catalogue', () {
    final stepIds = <String>[];
    for (final post in seeded) {
      for (final step in post.steps) {
        stepIds.add(step.id);
        expect(step.title.trim(), isNotEmpty);
        expect(step.command.trim(), isNotEmpty);
      }
    }
    expect(stepIds.toSet(), hasLength(stepIds.length));
  });

  test('commands are stored exactly as authored, including shell syntax', () {
    for (var index = 0; index < raw.length; index++) {
      final entry = raw[index] as Map;
      final post = seeded[index];
      final rawSteps = (entry['steps'] as List?) ?? const [];
      expect(post.steps, hasLength(rawSteps.length));
      for (var stepIndex = 0; stepIndex < rawSteps.length; stepIndex++) {
        final rawStep = rawSteps[stepIndex] as Map;
        expect(post.steps[stepIndex].command, rawStep['command']);
      }
    }
  });

  test('guide ids are URL-safe route segments', () {
    for (final post in seeded) {
      expect(RegExp(r'^[a-z0-9-]+$').hasMatch(post.id), isTrue);
    }
  });
}
