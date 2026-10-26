enum AiMessageRole {
  system,
  user,
  assistant;

  static AiMessageRole parse(String value) => AiMessageRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => AiMessageRole.user,
  );
}

class AiAttachment {
  const AiAttachment({
    required this.name,
    required this.content,
    required this.sizeBytes,
  });

  final String name;
  final String content;
  final int sizeBytes;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

class AiPromptMessage {
  const AiPromptMessage({required this.role, required this.content});

  final AiMessageRole role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role.name, 'content': content};
}

class AiUsage {
  const AiUsage({
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  factory AiUsage.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiUsage();
    return AiUsage(
      promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'prompt_tokens': promptTokens,
    'completion_tokens': completionTokens,
    'total_tokens': totalTokens,
  };
}

class AiModelInfo {
  const AiModelInfo({
    required this.providerId,
    required this.id,
    required this.displayName,
    this.contextWindow,
    this.ownedBy = '',
    this.active = true,
  });

  final String providerId;
  final String id;
  final String displayName;
  final int? contextWindow;
  final String ownedBy;
  final bool active;
}

class AiStreamDelta {
  const AiStreamDelta({
    this.text = '',
    this.usage,
    this.done = false,
    this.cached = false,
  });

  final String text;
  final AiUsage? usage;
  final bool done;

  /// True when the entire answer came from the local request cache.
  final bool cached;
}

class AiResponse {
  const AiResponse({
    required this.text,
    this.usage = const AiUsage(),
    this.modelId = '',
  });

  final String text;
  final AiUsage usage;
  final String modelId;
}

class AiConversation {
  const AiConversation({
    required this.id,
    required this.title,
    required this.providerId,
    required this.modelId,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  final String id;
  final String title;
  final String providerId;
  final String modelId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
}

class AiStoredMessage {
  const AiStoredMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.attachmentName = '',
    this.usage = const AiUsage(),
  });

  final String id;
  final String conversationId;
  final AiMessageRole role;
  final String content;
  final String attachmentName;
  final AiUsage usage;
  final DateTime createdAt;
}
