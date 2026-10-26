import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/errors/app_exception.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/models/ai_models.dart';
import 'package:termux_command_library/data/repositories/ai_repository.dart';
import 'package:termux_command_library/data/repositories/settings_repository.dart';
import 'package:termux_command_library/data/services/ai/ai_provider.dart';
import 'package:termux_command_library/data/services/ai/ai_prompts.dart';

import '../support/test_helpers.dart';

class _FakeAiProvider implements AiProvider {
  List<AiModelInfo> models = const [];
  int validateCalls = 0;
  int fetchCalls = 0;
  int streamCalls = 0;
  Object? validateFailure;
  List<AiPromptMessage> lastMessages = const [];

  @override
  String get providerId => 'groq';

  @override
  Future<void> validateApiKey(String apiKey) async {
    validateCalls++;
    final failure = validateFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<List<AiModelInfo>> fetchModels(String apiKey) async {
    fetchCalls++;
    return models;
  }

  @override
  Stream<AiStreamDelta> streamChat({
    required String apiKey,
    required String modelId,
    required List<AiPromptMessage> messages,
    double temperature = 0.35,
    int maxTokens = 2048,
  }) async* {
    streamCalls++;
    lastMessages = messages;
    yield const AiStreamDelta(text: 'Hello ');
    yield const AiStreamDelta(
      text: 'world',
      usage: AiUsage(promptTokens: 5, completionTokens: 2, totalTokens: 7),
    );
    yield const AiStreamDelta(
      usage: AiUsage(promptTokens: 5, completionTokens: 2, totalTokens: 7),
      done: true,
    );
  }
}

void main() {
  late AppDatabase db;
  late SettingsRepository settingsRepository;
  late _FakeAiProvider provider;
  late FakeApiKeyStore keyStore;
  late AiRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settingsRepository = SettingsRepository(db.settingsDao);
    final base = await settingsRepository.initialize();
    await settingsRepository.save(
      base.copyWith(aiEnabled: true, aiModelId: 'test-model', aiCacheHours: 24),
    );
    await db.aiDao.replaceModels('groq', [
      const AiModelInfo(
        providerId: 'groq',
        id: 'test-model',
        displayName: 'Test model',
      ),
    ]);
    provider = _FakeAiProvider();
    keyStore = FakeApiKeyStore('secret-key');
    repository = AiRepository(
      provider: provider,
      keyStore: keyStore,
      dao: db.aiDao,
      settingsRepository: settingsRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('API keys', () {
    test('save, read and clear use the secure key store abstraction', () async {
      expect(await repository.hasApiKey(), isTrue);
      await repository.saveApiKey('  second-key  ');
      expect(await repository.readApiKey(), 'second-key');

      await repository.saveApiKey('   ');
      expect(await repository.hasApiKey(), isFalse);
      expect(await repository.readApiKey(), isNull);
    });

    test('validation requires a key and maps provider failures', () async {
      await keyStore.deleteKey('groq');
      await expectLater(
        repository.validateKey(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.aiKeyMissing,
          ),
        ),
      );

      provider.validateFailure = const AppException(AppErrorCode.aiInvalidKey);
      await expectLater(
        repository.validateKey('bad-key'),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.aiInvalidKey,
          ),
        ),
      );
      expect(provider.validateCalls, 1);
    });
  });

  group('models', () {
    test('fetches dynamic models and selects a valid fallback', () async {
      await settingsRepository.save(
        (await settingsRepository.read()).copyWith(aiModelId: 'not-returned'),
      );
      provider.models = [
        const AiModelInfo(
          providerId: 'groq',
          id: 'dynamic-model',
          displayName: 'Dynamic',
          contextWindow: 32000,
        ),
      ];

      final models = await repository.fetchModels();

      expect(models.single.id, 'dynamic-model');
      expect(provider.fetchCalls, 1);
      expect((await settingsRepository.read()).aiModelId, 'dynamic-model');
      expect((await repository.selectedModel())!.contextWindow, 32000);
      expect((await repository.watchModels().first).single.id, 'dynamic-model');
    });

    test('rejects an empty model list', () async {
      provider.models = const [];
      await expectLater(
        repository.fetchModels(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.aiModelUnavailable,
          ),
        ),
      );
    });

    test('selectModel persists the user choice', () async {
      await repository.selectModel('test-model');
      expect((await settingsRepository.read()).aiModelId, 'test-model');
    });
  });

  group('streaming and caching', () {
    test(
      'streams a response and reuses the cache for an identical request',
      () async {
        const messages = [
          AiPromptMessage(role: AiMessageRole.user, content: 'Hello there'),
        ];
        final first = await repository.streamChat(messages: messages).toList();
        expect(first.map((delta) => delta.text).join(), 'Hello world');
        expect(first.last.done, isTrue);
        expect(first.last.cached, isFalse);
        expect(first.last.usage!.totalTokens, 7);
        expect(provider.streamCalls, 1);
        expect(provider.lastMessages.first.role, AiMessageRole.system);
        expect(provider.lastMessages.last.content, 'Hello there');

        final second = await repository.streamChat(messages: messages).toList();
        expect(second.single.text, 'Hello world');
        expect(second.single.cached, isTrue);
        expect(second.single.done, isTrue);
        expect(provider.streamCalls, 1);
      },
    );

    test(
      'different prompts and command contexts do not share a cache entry',
      () async {
        const messages = [
          AiPromptMessage(role: AiMessageRole.user, content: 'Explain pkg'),
        ];
        await repository.streamChat(messages: messages).toList();
        await repository
            .streamChat(
              messages: const [
                AiPromptMessage(
                  role: AiMessageRole.user,
                  content: 'Explain pkg',
                ),
              ],
              commandContext: 'Title: pkg update',
            )
            .toList();
        await repository
            .streamChat(
              messages: const [
                AiPromptMessage(
                  role: AiMessageRole.user,
                  content: 'Explain apt',
                ),
              ],
            )
            .toList();

        expect(provider.streamCalls, 3);
      },
    );

    test('cache is disabled when the configured duration is zero', () async {
      await settingsRepository.save(
        (await settingsRepository.read()).copyWith(aiCacheHours: 0),
      );
      const messages = [
        AiPromptMessage(role: AiMessageRole.user, content: 'No cache here'),
      ];

      await repository.streamChat(messages: messages).toList();
      await repository.streamChat(messages: messages).toList();

      expect(provider.streamCalls, 2);
    });

    test('useCache false bypasses an existing entry', () async {
      const messages = [
        AiPromptMessage(role: AiMessageRole.user, content: 'Bypass cache'),
      ];
      await repository.streamChat(messages: messages).toList();
      await repository.streamChat(messages: messages, useCache: false).toList();

      expect(provider.streamCalls, 2);
    });

    test('disabled AI, missing key and missing model fail clearly', () async {
      await settingsRepository.save(
        (await settingsRepository.read()).copyWith(aiEnabled: false),
      );
      const messages = [
        AiPromptMessage(role: AiMessageRole.user, content: 'Hello'),
      ];
      await expectLater(
        repository.streamChat(messages: messages).toList(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.aiDisabled,
          ),
        ),
      );

      await settingsRepository.save(
        (await settingsRepository.read()).copyWith(aiEnabled: true),
      );
      await keyStore.deleteKey('groq');
      await expectLater(
        repository.streamChat(messages: messages).toList(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.aiKeyMissing,
          ),
        ),
      );

      keyStore.key = 'secret-key';
      await settingsRepository.save(
        (await settingsRepository.read()).copyWith(aiModelId: 'missing-model'),
      );
      await expectLater(
        repository.streamChat(messages: messages).toList(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.aiModelUnavailable,
          ),
        ),
      );
      expect(provider.streamCalls, 0);
    });

    test(
      'rejects oversized conversation input before calling the provider',
      () async {
        final messages = [
          AiPromptMessage(role: AiMessageRole.user, content: 'x' * 48001),
        ];
        await expectLater(
          repository.streamChat(messages: messages).toList(),
          throwsA(
            isA<AppException>().having(
              (error) => error.code,
              'code',
              AppErrorCode.aiRequestTooLarge,
            ),
          ),
        );
        expect(provider.streamCalls, 0);
      },
    );

    test('assist requests include the guide and return the answer', () async {
      final command = buildCommand(
        id: 'guided',
        name: 'Guided task',
        description: 'Runs two steps',
        steps: [
          buildStep(id: 'one', order: 0, command: 'echo one'),
          buildStep(id: 'two', order: 1, command: 'echo two'),
        ],
      );

      final answer = await repository.completeAssist(
        intent: AiAssistIntent.suggestTitle,
        command: command,
      );

      expect(answer, 'Hello world');
      final userMessage = provider.lastMessages.last.content;
      expect(userMessage, contains('TITLE:'));
      expect(userMessage, contains('Guided task'));
      expect(userMessage, contains('echo one'));
      expect(userMessage, contains('echo two'));
    });

    test('clearCache removes cached answers', () async {
      const messages = [
        AiPromptMessage(role: AiMessageRole.user, content: 'Cache me'),
      ];
      await repository.streamChat(messages: messages).toList();
      await repository.clearCache();
      await repository.streamChat(messages: messages).toList();
      expect(provider.streamCalls, 2);
    });
  });

  group('local history', () {
    test('creates, updates, reads and deletes conversations', () async {
      final conversation = await repository.createConversation(
        title: '   ',
        modelId: 'test-model',
      );
      expect(conversation.title, 'New chat');
      expect(conversation.providerId, 'groq');

      await repository.updateConversationTitle(
        conversation.id,
        'A very long title ' * 10,
      );
      final renamed = await repository.watchConversation(conversation.id).first;
      expect(renamed!.title.length, lessThanOrEqualTo(80));
      expect(renamed.title.endsWith('…'), isTrue);

      await repository.appendUserMessage(
        conversationId: conversation.id,
        content: 'Use pkg install',
        attachmentName: 'notes.sh',
      );
      await repository.appendAssistantMessage(
        conversationId: conversation.id,
        content: 'Run it with confirmation.',
        usage: const AiUsage(totalTokens: 10),
      );

      final messages = await repository.watchMessages(conversation.id).first;
      expect(messages, hasLength(2));
      expect(messages.first.attachmentName, 'notes.sh');
      expect(messages.last.usage.totalTokens, 10);

      final search = await repository.watchConversations(search: 'pkg').first;
      expect(search.single.id, conversation.id);

      await repository.deleteConversation(conversation.id);
      expect(await repository.watchConversation(conversation.id).first, isNull);
    });

    test(
      'clearHistory removes conversations but leaves cached responses',
      () async {
        const messages = [
          AiPromptMessage(role: AiMessageRole.user, content: 'Keep cache'),
        ];
        await repository.streamChat(messages: messages).toList();
        final conversation = await repository.createConversation(
          title: 'Temporary',
          modelId: 'test-model',
        );

        await repository.clearHistory();
        expect(await repository.watchConversations().first, isEmpty);
        expect(
          await repository.watchConversation(conversation.id).first,
          isNull,
        );

        await repository.streamChat(messages: messages).toList();
        expect(provider.streamCalls, 1);
      },
    );
  });
}
