import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../models/ai_models.dart';
import 'ai_provider.dart';

/// Groq implementation of the OpenAI-compatible chat completions API. Model
/// identifiers are always fetched from the API; none are hard-coded here.
class GroqAiProvider implements AiProvider {
  GroqAiProvider({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://api.groq.com/openai/v1';
  static const _timeout = Duration(seconds: 45);

  final http.Client _client;

  @override
  String get providerId => AppConstants.groqProviderId;

  @override
  Future<void> validateApiKey(String apiKey) async {
    final response = await _guardRequest(
      () => _client
          .get(
            Uri.parse('$_baseUrl/models'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout),
    );
    if (response.statusCode != 200) {
      throw _mapStatus(response.statusCode, response.body);
    }
  }

  @override
  Future<List<AiModelInfo>> fetchModels(String apiKey) async {
    final response = await _guardRequest(
      () => _client
          .get(
            Uri.parse('$_baseUrl/models'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout),
    );
    if (response.statusCode != 200) {
      throw _mapStatus(response.statusCode, response.body);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['data'] is! List) {
        throw const AppException(AppErrorCode.aiProviderUnavailable);
      }
      final models = <AiModelInfo>[];
      for (final raw in decoded['data'] as List) {
        if (raw is! Map) continue;
        final id = raw['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final contextRaw =
            raw['context_window'] ??
            raw['context_length'] ??
            raw['max_context'];
        models.add(
          AiModelInfo(
            providerId: providerId,
            id: id,
            displayName: (raw['name']?.toString().trim().isNotEmpty ?? false)
                ? raw['name'].toString()
                : id,
            ownedBy: raw['owned_by']?.toString() ?? '',
            contextWindow: contextRaw is num ? contextRaw.toInt() : null,
            active: raw['active'] != false,
          ),
        );
      }
      models.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return models;
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.aiProviderUnavailable, cause: error);
    }
  }

  @override
  Stream<AiStreamDelta> streamChat({
    required String apiKey,
    required String modelId,
    required List<AiPromptMessage> messages,
    double temperature = 0.35,
    int maxTokens = 2048,
  }) async* {
    final request =
        http.Request('POST', Uri.parse('$_baseUrl/chat/completions'))
          ..headers.addAll({
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          })
          ..body = jsonEncode({
            'model': modelId,
            'messages': messages.map((message) => message.toJson()).toList(),
            'temperature': temperature,
            'max_tokens': maxTokens,
            'stream': true,
          });

    http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(_timeout);
    } on TimeoutException {
      throw const AppException(AppErrorCode.timeout, retryable: true);
    } on http.ClientException catch (error) {
      throw AppException(AppErrorCode.network, cause: error, retryable: true);
    } catch (error) {
      throw AppException(AppErrorCode.network, cause: error, retryable: true);
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw _mapStatus(response.statusCode, body);
    }

    AiUsage? usage;
    var sawContent = false;
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    try {
      await for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith(':')) continue;
        if (!trimmed.startsWith('data:')) continue;
        final data = trimmed.substring(5).trim();
        if (data == '[DONE]') break;
        Map<String, dynamic> json;
        try {
          final decoded = jsonDecode(data);
          if (decoded is! Map) continue;
          json = Map<String, dynamic>.from(decoded);
        } on FormatException {
          continue;
        }
        final error = json['error'];
        if (error is Map) {
          final code = error['code']?.toString() ?? '';
          throw _mapApiErrorCode(code);
        }
        final usageRaw = json['usage'];
        if (usageRaw is Map) {
          usage = AiUsage.fromJson(Map<String, dynamic>.from(usageRaw));
        }
        final choices = json['choices'];
        if (choices is! List || choices.isEmpty) continue;
        final choice = choices.first;
        if (choice is! Map) continue;
        final delta = choice['delta'];
        if (delta is Map) {
          final content = delta['content'];
          if (content is String && content.isNotEmpty) {
            sawContent = true;
            yield AiStreamDelta(text: content, usage: usage);
          }
        }
        final finishReason = choice['finish_reason'];
        if (finishReason != null && finishReason.toString().isNotEmpty) {
          yield AiStreamDelta(usage: usage, done: true);
          return;
        }
      }
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(AppErrorCode.timeout, retryable: true);
    } on http.ClientException catch (error) {
      throw AppException(AppErrorCode.network, cause: error, retryable: true);
    } catch (error) {
      throw AppException(AppErrorCode.aiProviderUnavailable, cause: error);
    }

    if (!sawContent) {
      throw const AppException(AppErrorCode.aiEmptyResponse);
    }
    yield AiStreamDelta(usage: usage, done: true);
  }

  Future<http.Response> _guardRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on TimeoutException {
      throw const AppException(AppErrorCode.timeout, retryable: true);
    } on http.ClientException catch (error) {
      throw AppException(AppErrorCode.network, cause: error, retryable: true);
    } catch (error) {
      throw AppException(AppErrorCode.network, cause: error, retryable: true);
    }
  }

  AppException _mapStatus(int status, String body) {
    final lower = body.toLowerCase();
    if (status == 401 || status == 403) {
      return const AppException(AppErrorCode.aiInvalidKey);
    }
    if (status == 429) {
      return const AppException(AppErrorCode.aiRateLimited, retryable: true);
    }
    if (status == 404) {
      return const AppException(AppErrorCode.aiModelUnavailable);
    }
    if (status == 413 ||
        lower.contains('too large') ||
        lower.contains('context_length_exceeded') ||
        lower.contains('maximum context')) {
      return const AppException(AppErrorCode.aiRequestTooLarge);
    }
    if (lower.contains('model_not_found') ||
        lower.contains('does not exist') && lower.contains('model')) {
      return const AppException(AppErrorCode.aiModelUnavailable);
    }
    if (status >= 500) {
      return const AppException(
        AppErrorCode.aiProviderUnavailable,
        retryable: true,
      );
    }
    return const AppException(AppErrorCode.aiProviderUnavailable);
  }

  AppException _mapApiErrorCode(String code) {
    final normalized = code.toLowerCase();
    if (normalized.contains('auth') || normalized.contains('key')) {
      return const AppException(AppErrorCode.aiInvalidKey);
    }
    if (normalized.contains('rate')) {
      return const AppException(AppErrorCode.aiRateLimited, retryable: true);
    }
    if (normalized.contains('model')) {
      return const AppException(AppErrorCode.aiModelUnavailable);
    }
    if (normalized.contains('context') || normalized.contains('length')) {
      return const AppException(AppErrorCode.aiRequestTooLarge);
    }
    return const AppException(AppErrorCode.aiProviderUnavailable);
  }

  void close() => _client.close();
}
