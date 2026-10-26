import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/models/ai_models.dart';

import '../support/test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AI conversations', () {
    setUp(() async {
      await db.aiDao.saveConversation(
        buildAiConversation(
          id: 'conv-1',
          title: 'Termux setup',
          updatedAt: DateTime.utc(2026, 10, 2),
        ),
      );
      await db.aiDao.saveConversation(
        buildAiConversation(
          id: 'conv-2',
          title: 'Python help',
          updatedAt: DateTime.utc(2026, 10, 1),
        ),
      );
      await db.aiDao.saveMessage(
        buildAiMessage(
          id: 'm-1',
          conversationId: 'conv-1',
          role: AiMessageRole.user,
          content: 'How do I install packages?',
          createdAt: DateTime.utc(2026, 10, 2, 8),
          attachmentName: 'notes.sh',
          usage: const AiUsage(promptTokens: 12, totalTokens: 12),
        ),
      );
      await db.aiDao.saveMessage(
        buildAiMessage(
          id: 'm-2',
          conversationId: 'conv-1',
          role: AiMessageRole.assistant,
          content: 'Use pkg install.',
          createdAt: DateTime.utc(2026, 10, 2, 8, 1),
          usage: const AiUsage(
            promptTokens: 12,
            completionTokens: 4,
            totalTokens: 16,
          ),
        ),
      );
      await db.aiDao.saveMessage(
        buildAiMessage(
          id: 'm-3',
          conversationId: 'conv-2',
          role: AiMessageRole.user,
          content: 'Unrelated question',
          createdAt: DateTime.utc(2026, 10, 1, 9),
        ),
      );
    });

    test('lists conversations by most recently updated', () async {
      final conversations = await db.aiDao.watchConversations().first;
      expect(conversations.map((conversation) => conversation.id), [
        'conv-1',
        'conv-2',
      ]);
      expect(conversations.first.messageCount, 2);
      expect(conversations.last.messageCount, 1);
    });

    test('search covers titles and message content', () async {
      final byTitle = await db.aiDao.watchConversations(search: 'termux').first;
      expect(byTitle.single.id, 'conv-1');

      final byContent = await db.aiDao
          .watchConversations(search: 'packages')
          .first;
      expect(byContent.single.id, 'conv-1');

      expect(
        await db.aiDao.watchConversations(search: 'nothing').first,
        isEmpty,
      );
    });

    test('messages retain order, attachments and usage metadata', () async {
      final messages = await db.aiDao.watchMessages('conv-1').first;
      expect(messages.map((message) => message.id), ['m-1', 'm-2']);
      expect(messages.first.attachmentName, 'notes.sh');
      expect(messages.first.usage.promptTokens, 12);
      expect(messages.last.usage.totalTokens, 16);
      expect(messages.last.role, AiMessageRole.assistant);
      expect(await db.aiDao.readMessages('conv-2'), hasLength(1));
    });

    test('conversation metadata can be updated', () async {
      await db.aiDao.touchConversation(
        'conv-2',
        title: 'Renamed',
        modelId: 'other-model',
        updatedAt: DateTime.utc(2026, 11, 1),
      );

      final conversation = await db.aiDao.watchConversation('conv-2').first;
      expect(conversation!.title, 'Renamed');
      expect(conversation.modelId, 'other-model');
      final list = await db.aiDao.watchConversations().first;
      expect(list.first.id, 'conv-2');
    });

    test('deleting a conversation removes its messages only', () async {
      await db.aiDao.deleteConversation('conv-1');

      expect(await db.aiDao.watchConversation('conv-1').first, isNull);
      expect(await db.aiDao.watchMessages('conv-1').first, isEmpty);
      expect(await db.aiDao.watchMessages('conv-2').first, hasLength(1));
    });

    test('clearing history removes every conversation and message', () async {
      await db.aiDao.clearConversations();
      expect(await db.aiDao.watchConversations().first, isEmpty);
      expect(await db.aiDao.readMessages('conv-1'), isEmpty);
      expect(await db.aiDao.readMessages('conv-2'), isEmpty);
    });
  });

  group('AI response cache', () {
    test('returns only unexpired entries', () async {
      final now = DateTime.now().toUtc();
      await db.aiDao.writeCache(
        key: 'valid',
        providerId: 'groq',
        modelId: 'model-a',
        promptVersion: 'v1',
        responseText: 'Cached answer',
        usage: const AiUsage(totalTokens: 7),
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 1)),
      );
      await db.aiDao.writeCache(
        key: 'expired',
        providerId: 'groq',
        modelId: 'model-a',
        promptVersion: 'v1',
        responseText: 'Old answer',
        usage: const AiUsage(),
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.subtract(const Duration(hours: 1)),
      );

      final cached = await db.aiDao.readCache('valid');
      expect(cached!.text, 'Cached answer');
      expect(cached.usage.totalTokens, 7);
      expect(cached.modelId, 'model-a');
      expect(await db.aiDao.readCache('expired'), isNull);
    });

    test('cleans expired entries and can clear the whole cache', () async {
      final now = DateTime.now().toUtc();
      await db.aiDao.writeCache(
        key: 'valid',
        providerId: 'groq',
        modelId: 'model-a',
        promptVersion: 'v1',
        responseText: 'Keep',
        usage: const AiUsage(),
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 1)),
      );
      await db.aiDao.writeCache(
        key: 'expired',
        providerId: 'groq',
        modelId: 'model-a',
        promptVersion: 'v1',
        responseText: 'Drop',
        usage: const AiUsage(),
        createdAt: now,
        expiresAt: now.subtract(const Duration(seconds: 1)),
      );

      expect(await db.aiDao.cleanExpiredCache(), 1);
      expect(await db.aiDao.readCache('valid'), isNotNull);
      expect(await db.aiDao.readCache('expired'), isNull);

      await db.aiDao.clearCache();
      expect(await db.aiDao.readCache('valid'), isNull);
    });
  });

  group('AI models', () {
    test(
      'replaceModels retires absent models while caching new metadata',
      () async {
        await db.aiDao.replaceModels('groq', [
          const AiModelInfo(
            providerId: 'groq',
            id: 'model-a',
            displayName: 'Alpha',
            contextWindow: 8192,
          ),
          const AiModelInfo(
            providerId: 'groq',
            id: 'model-b',
            displayName: 'Beta',
            ownedBy: 'Groq',
          ),
        ]);

        expect((await db.aiDao.readModels('groq')).map((model) => model.id), [
          'model-a',
          'model-b',
        ]);

        await db.aiDao.replaceModels('groq', [
          const AiModelInfo(
            providerId: 'groq',
            id: 'model-b',
            displayName: 'Beta',
            ownedBy: 'Groq',
          ),
          const AiModelInfo(
            providerId: 'groq',
            id: 'model-c',
            displayName: 'Gamma',
            active: false,
          ),
        ]);

        final active = await db.aiDao.readModels('groq');
        expect(active.map((model) => model.id), ['model-b']);
        final all = await db.aiDao.readModels('groq', activeOnly: false);
        expect(all.map((model) => model.id), ['model-a', 'model-b', 'model-c']);
        expect((await db.aiDao.readModel('groq', 'model-a'))!.active, isFalse);
        expect(
          (await db.aiDao.readModel('groq', 'model-a'))!.contextWindow,
          8192,
        );
        expect(await db.aiDao.readModel('groq', 'missing'), isNull);
      },
    );

    test('providers do not share model lists', () async {
      await db.aiDao.replaceModels('groq', [
        const AiModelInfo(
          providerId: 'groq',
          id: 'groq-model',
          displayName: 'Groq model',
        ),
      ]);
      await db.aiDao.replaceModels('other', [
        const AiModelInfo(
          providerId: 'other',
          id: 'other-model',
          displayName: 'Other model',
        ),
      ]);

      expect((await db.aiDao.readModels('groq')).single.id, 'groq-model');
      expect((await db.aiDao.readModels('other')).single.id, 'other-model');

      await db.aiDao.clearModels('groq');
      expect(await db.aiDao.readModels('groq'), isEmpty);
      expect(await db.aiDao.readModels('other'), hasLength(1));
    });
  });
}
