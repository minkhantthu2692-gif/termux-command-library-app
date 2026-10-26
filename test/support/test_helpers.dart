import 'package:termux_command_library/data/models/ai_models.dart';
import 'package:termux_command_library/data/models/command_post.dart';
import 'package:termux_command_library/data/services/secure_key_store.dart';

CommandStep buildStep({
  required String id,
  String title = 'Step',
  String command = 'echo hello',
  int order = 0,
  String description = '',
  CommandRunMode runMode = CommandRunMode.foreground,
}) {
  return CommandStep(
    id: id,
    order: order,
    title: title,
    description: description,
    command: command,
    runMode: runMode,
  );
}

CommandPost buildCommand({
  required String id,
  String name = 'Test command',
  String description = 'A useful test guide.',
  String categoryId = 'package_management',
  List<String> tags = const ['test'],
  Map<String, String> metadata = const {},
  List<CommandStep>? steps,
  String authorUid = 'user-1',
  String authorNickname = 'Tester',
  DateTime? createdAt,
  DateTime? updatedAt,
  int version = 1,
  CommandStatus status = CommandStatus.published,
  bool isSeed = false,
  bool isPendingSync = false,
}) {
  final created = createdAt ?? DateTime.utc(2026, 10, 1, 8);
  return CommandPost(
    id: id,
    name: name,
    description: description,
    categoryId: categoryId,
    tags: tags,
    metadata: metadata,
    steps: steps ?? [buildStep(id: '$id-step-1', command: 'echo $id')],
    authorUid: authorUid,
    authorNickname: authorNickname,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    version: version,
    status: status,
    isSeed: isSeed,
    isPendingSync: isPendingSync,
  );
}

AiStoredMessage buildAiMessage({
  required String id,
  required String conversationId,
  required AiMessageRole role,
  required String content,
  required DateTime createdAt,
  String attachmentName = '',
  AiUsage usage = const AiUsage(),
}) {
  return AiStoredMessage(
    id: id,
    conversationId: conversationId,
    role: role,
    content: content,
    createdAt: createdAt,
    attachmentName: attachmentName,
    usage: usage,
  );
}

AiConversation buildAiConversation({
  required String id,
  String title = 'Test chat',
  String providerId = 'groq',
  String modelId = 'test-model',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 10, 1, 8);
  return AiConversation(
    id: id,
    title: title,
    providerId: providerId,
    modelId: modelId,
    createdAt: created,
    updatedAt: updatedAt ?? created,
  );
}

class FakeApiKeyStore implements ApiKeyStore {
  FakeApiKeyStore([this.key]);

  String? key;

  @override
  Future<void> deleteKey(String providerId) async {
    key = null;
  }

  @override
  Future<bool> hasKey(String providerId) async => key != null;

  @override
  Future<String?> readKey(String providerId) async => key;

  @override
  Future<void> saveKey(String providerId, String key) async {
    final trimmed = key.trim();
    this.key = trimmed.isEmpty ? null : trimmed;
  }
}
