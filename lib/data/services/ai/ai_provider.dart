import '../../models/ai_models.dart';

/// Provider-neutral AI contract. Chat UI depends on this interface, never on
/// Groq-specific request/response shapes.
abstract interface class AiProvider {
  String get providerId;

  Future<void> validateApiKey(String apiKey);

  Future<List<AiModelInfo>> fetchModels(String apiKey);

  Stream<AiStreamDelta> streamChat({
    required String apiKey,
    required String modelId,
    required List<AiPromptMessage> messages,
    double temperature = 0.35,
    int maxTokens = 2048,
  });
}
