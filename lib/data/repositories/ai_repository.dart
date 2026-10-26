import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../local/database/daos/ai_dao.dart';
import '../models/ai_models.dart';
import '../models/command_post.dart';
import '../services/ai/ai_prompts.dart';
import '../services/ai/ai_provider.dart';
import '../services/secure_key_store.dart';
import 'settings_repository.dart';

/// High-level AI orchestration: key handling, model discovery, caching and
/// local history. It never logs prompts, keys or responses.
class AiRepository {
  AiRepository({
    required AiProvider provider,
    required ApiKeyStore keyStore,
    required AiDao dao,
    required SettingsRepository settingsRepository,
  }) : _provider = provider,
       _keyStore = keyStore,
       _dao = dao,
       _settingsRepository = settingsRepository {
    unawaited(_dao.cleanExpiredCache().catchError((_) => 0));
  }

  final AiProvider _provider;
  final ApiKeyStore _keyStore;
  final AiDao _dao;
  final SettingsRepository _settingsRepository;

  String get providerId => _provider.providerId;
  String get promptVersion => AiPromptBuilder.promptVersion;

  Stream<List<AiModelInfo>> watchModels() =>
      _dao.watchModels(_provider.providerId);

  Stream<List<AiConversation>> watchConversations({String search = ''}) =>
      _dao.watchConversations(search: search);

  Stream<AiConversation?> watchConversation(String id) =>
      _dao.watchConversation(id);

  Stream<List<AiStoredMessage>> watchMessages(String conversationId) =>
      _dao.watchMessages(conversationId);

  Future<List<AiStoredMessage>> readMessages(String conversationId) =>
      _dao.readMessages(conversationId);

  Future<bool> hasApiKey() => _keyStore.hasKey(providerId);

  Future<String?> readApiKey() => _keyStore.readKey(providerId);

  /// Saves a key without validating it. The setup screen tests it separately so
  /// the user can fix a typo before the key is used.
  Future<void> saveApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _keyStore.deleteKey(providerId);
      return;
    }
    await _keyStore.saveKey(providerId, trimmed);
  }

  Future<void> clearApiKey() => _keyStore.deleteKey(providerId);

  Future<void> validateKey([String? key]) async {
    final apiKey = (key?.trim().isNotEmpty ?? false)
        ? key!.trim()
        : await _keyStore.readKey(providerId);
    if (apiKey == null || apiKey.isEmpty) {
      throw const AppException(AppErrorCode.aiKeyMissing);
    }
    try {
      await _provider.validateApiKey(apiKey);
    } catch (error) {
      throw _mapAiError(error);
    }
  }

  /// Fetches live model metadata and stores it locally. The currently selected
  /// model is kept only if it is still returned by the provider.
  Future<List<AiModelInfo>> fetchModels() async {
    final key = await _keyStore.readKey(providerId);
    if (key == null || key.isEmpty) {
      throw const AppException(AppErrorCode.aiKeyMissing);
    }
    try {
      final models = await _provider.fetchModels(key);
      if (models.isEmpty) {
        throw const AppException(AppErrorCode.aiModelUnavailable);
      }
      await _dao.replaceModels(providerId, models);
      final settings = await _settingsRepository.read();
      final activeIds = models
          .where((model) => model.active)
          .map((model) => model.id)
          .toSet();
      if (!activeIds.contains(settings.aiModelId)) {
        await _settingsRepository.save(
          settings.copyWith(aiModelId: models.first.id),
        );
      }
      return models;
    } catch (error) {
      throw _mapAiError(error);
    }
  }

  Future<void> selectModel(String modelId) async {
    final settings = await _settingsRepository.read();
    await _settingsRepository.save(settings.copyWith(aiModelId: modelId));
  }

  Future<AiModelInfo?> selectedModel() async {
    final settings = await _settingsRepository.read();
    if (settings.aiModelId.trim().isEmpty) return null;
    return _dao.readModel(providerId, settings.aiModelId);
  }

  /// Streams a chat answer. The same provider/model/prompt/parameters tuple is
  /// cached, keyed by a SHA-256 digest so long prompts never become SQLite keys.
  Stream<AiStreamDelta> streamChat({
    required List<AiPromptMessage> messages,
    String? commandContext,
    String? modelId,
    bool useCache = true,
  }) {
    final built = AiPromptBuilder.buildChat(
      history: messages,
      commandContext: commandContext,
    );
    return _streamCompletion(
      messages: built,
      modelId: modelId,
      useCache: useCache,
    );
  }

  Future<String> completeAssist({
    required AiAssistIntent intent,
    required CommandPost command,
  }) async {
    final messages = AiPromptBuilder.buildAssist(
      intent: intent,
      name: command.name,
      description: command.description,
      steps: command.steps,
    );
    final buffer = StringBuffer();
    await for (final delta in _streamCompletion(
      messages: messages,
      useCache: true,
    )) {
      buffer.write(delta.text);
    }
    final answer = buffer.toString().trim();
    if (answer.isEmpty) {
      throw const AppException(AppErrorCode.aiEmptyResponse);
    }
    return answer;
  }

  Stream<AiStreamDelta> _streamCompletion({
    required List<AiPromptMessage> messages,
    String? modelId,
    required bool useCache,
  }) async* {
    final settings = await _settingsRepository.read();
    if (!settings.aiEnabled) {
      throw const AppException(AppErrorCode.aiDisabled);
    }
    final apiKey = await _keyStore.readKey(providerId);
    if (apiKey == null || apiKey.isEmpty) {
      throw const AppException(AppErrorCode.aiKeyMissing);
    }
    final selectedModel = (modelId == null || modelId.trim().isEmpty)
        ? settings.aiModelId
        : modelId.trim();
    if (selectedModel.isEmpty) {
      throw const AppException(AppErrorCode.aiModelUnavailable);
    }
    final model = await _dao.readModel(providerId, selectedModel);
    if (model == null || !model.active) {
      throw const AppException(AppErrorCode.aiModelUnavailable);
    }

    if (messages.length > AppConstants.aiMaxHistoryMessages + 2 ||
        messages.any(
          (message) =>
              message.content.length > AppConstants.aiMaxMessageCharacters,
        )) {
      throw const AppException(AppErrorCode.aiRequestTooLarge);
    }

    final cacheKey = _cacheKey(
      modelId: selectedModel,
      messages: messages,
      temperature: 0.35,
      maxTokens: 3072,
    );
    final cacheEnabled = settings.aiCacheHours > 0 && useCache;
    if (cacheEnabled) {
      final cached = await _dao.readCache(cacheKey);
      if (cached != null) {
        yield AiStreamDelta(
          text: cached.text,
          usage: cached.usage,
          done: true,
          cached: true,
        );
        return;
      }
    }

    final buffer = StringBuffer();
    AiUsage usage = const AiUsage();
    try {
      await for (final delta in _provider.streamChat(
        apiKey: apiKey,
        modelId: selectedModel,
        messages: messages,
        temperature: 0.35,
        maxTokens: 3072,
      )) {
        if (delta.text.isNotEmpty) buffer.write(delta.text);
        if (delta.usage != null) usage = delta.usage!;
        if (delta.done) {
          if (cacheEnabled && buffer.isNotEmpty) {
            await _writeCache(
              cacheKey: cacheKey,
              modelId: selectedModel,
              text: buffer.toString(),
              usage: usage,
              hours: settings.aiCacheHours,
            );
          }
          yield AiStreamDelta(usage: usage, done: true);
          return;
        }
        yield delta;
      }
    } on AppException {
      rethrow;
    } catch (error) {
      throw _mapAiError(error);
    }
  }

  String _cacheKey({
    required String modelId,
    required List<AiPromptMessage> messages,
    required double temperature,
    required int maxTokens,
  }) {
    final canonical = jsonEncode({
      'provider': providerId,
      'model': modelId,
      'promptVersion': promptVersion,
      'messages': messages
          .map(
            (message) => {
              'role': message.role.name,
              'content': message.content,
            },
          )
          .toList(),
      'temperature': temperature,
      'maxTokens': maxTokens,
    });
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  Future<void> _writeCache({
    required String cacheKey,
    required String modelId,
    required String text,
    required AiUsage usage,
    required int hours,
  }) async {
    final now = DateTime.now().toUtc();
    await _dao.writeCache(
      key: cacheKey,
      providerId: providerId,
      modelId: modelId,
      promptVersion: promptVersion,
      responseText: text,
      usage: usage,
      createdAt: now,
      expiresAt: now.add(Duration(hours: hours.clamp(1, 168))),
    );
  }

  Future<void> clearCache() => _dao.clearCache();

  Future<void> clearHistory() => _dao.clearConversations();

  Future<void> deleteConversation(String id) => _dao.deleteConversation(id);

  Future<AiConversation> createConversation({
    required String title,
    required String modelId,
  }) async {
    final now = DateTime.now().toUtc();
    final conversation = AiConversation(
      id: const Uuid().v4(),
      title: title.trim().isEmpty ? 'New chat' : _clipTitle(title),
      providerId: providerId,
      modelId: modelId,
      createdAt: now,
      updatedAt: now,
    );
    await _dao.saveConversation(conversation);
    return conversation;
  }

  Future<AiStoredMessage> appendUserMessage({
    required String conversationId,
    required String content,
    String attachmentName = '',
  }) async {
    final now = DateTime.now().toUtc();
    final message = AiStoredMessage(
      id: const Uuid().v4(),
      conversationId: conversationId,
      role: AiMessageRole.user,
      content: content,
      attachmentName: attachmentName,
      createdAt: now,
    );
    await _dao.saveMessage(message);
    await _dao.touchConversation(conversationId, updatedAt: now);
    return message;
  }

  Future<AiStoredMessage> appendAssistantMessage({
    required String conversationId,
    required String content,
    required AiUsage usage,
  }) async {
    final now = DateTime.now().toUtc();
    final message = AiStoredMessage(
      id: const Uuid().v4(),
      conversationId: conversationId,
      role: AiMessageRole.assistant,
      content: content,
      usage: usage,
      createdAt: now,
    );
    await _dao.saveMessage(message);
    await _dao.touchConversation(conversationId, updatedAt: now);
    return message;
  }

  Future<void> updateConversationTitle(String conversationId, String title) =>
      _dao.touchConversation(conversationId, title: _clipTitle(title));

  Future<void> updateConversationModel(String conversationId, String modelId) =>
      _dao.touchConversation(conversationId, modelId: modelId);

  String _clipTitle(String title) {
    final singleLine = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return singleLine.length <= 80
        ? singleLine
        : '${singleLine.substring(0, 77)}…';
  }

  AppException _mapAiError(Object error) {
    if (error is AppException) return error;
    return const AppException(AppErrorCode.aiProviderUnavailable);
  }
}
