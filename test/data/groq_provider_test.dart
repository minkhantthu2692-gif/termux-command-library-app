import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:termux_command_library/core/errors/app_exception.dart';
import 'package:termux_command_library/data/models/ai_models.dart';
import 'package:termux_command_library/data/services/ai/groq_ai_provider.dart';

Matcher _errorCode(AppErrorCode code) =>
    throwsA(isA<AppException>().having((error) => error.code, 'code', code));

String _sse(List<Object> events) {
  final buffer = StringBuffer();
  for (final event in events) {
    buffer.writeln('data: ${event is String ? event : jsonEncode(event)}');
    buffer.writeln();
  }
  return buffer.toString();
}

void main() {
  group('Groq validation and model discovery', () {
    test('sends the key in the Authorization header and accepts 200', () async {
      late http.Request captured;
      final provider = GroqAiProvider(
        client: MockClient((request) async {
          captured = request;
          return http.Response('{"data":[]}', 200);
        }),
      );
      addTearDown(provider.close);

      await provider.validateApiKey('gsk_test_key');

      expect(captured.url.toString(), 'https://api.groq.com/openai/v1/models');
      expect(captured.headers['Authorization'], 'Bearer gsk_test_key');
    });

    test('maps authentication, rate-limit and server failures', () async {
      Future<void> expectFailure(int status, AppErrorCode code) async {
        final provider = GroqAiProvider(
          client: MockClient(
            (request) async => http.Response('{"error":"failed"}', status),
          ),
        );
        addTearDown(provider.close);
        await expectLater(provider.validateApiKey('key'), _errorCode(code));
      }

      await expectFailure(401, AppErrorCode.aiInvalidKey);
      await expectFailure(403, AppErrorCode.aiInvalidKey);
      await expectFailure(429, AppErrorCode.aiRateLimited);
      await expectFailure(500, AppErrorCode.aiProviderUnavailable);
    });

    test('parses, filters and sorts model metadata', () async {
      final provider = GroqAiProvider(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'zeta',
                  'name': 'Zeta model',
                  'owned_by': 'Groq',
                  'context_window': 8192,
                },
                {'id': 'alpha', 'owned_by': 'Groq', 'context_length': 4096},
                {'id': '', 'name': 'Missing id'},
                {'id': 'disabled', 'name': 'Disabled', 'active': false},
              ],
            }),
            200,
          ),
        ),
      );
      addTearDown(provider.close);

      final models = await provider.fetchModels('key');

      expect(models.map((model) => model.id), ['alpha', 'disabled', 'zeta']);
      expect(models.first.displayName, 'alpha');
      expect(models.first.contextWindow, 4096);
      expect(models.last.displayName, 'Zeta model');
      expect(models.last.contextWindow, 8192);
      expect(models.first.providerId, 'groq');
      expect(models[1].active, isFalse);
    });

    test('rejects malformed model payloads', () async {
      final provider = GroqAiProvider(
        client: MockClient(
          (request) async => http.Response('{"not_data":true}', 200),
        ),
      );
      addTearDown(provider.close);

      await expectLater(
        provider.fetchModels('key'),
        _errorCode(AppErrorCode.aiProviderUnavailable),
      );
    });
  });

  group('Groq streaming', () {
    test('parses SSE deltas, usage and finish reason', () async {
      late http.Request captured;
      final provider = GroqAiProvider(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            _sse([
              {
                'choices': [
                  {
                    'delta': {'content': 'Hello'},
                  },
                ],
              },
              {
                'choices': [
                  {
                    'delta': {'content': ' world'},
                  },
                ],
                'usage': {
                  'prompt_tokens': 1,
                  'completion_tokens': 2,
                  'total_tokens': 3,
                },
              },
              {
                'choices': [
                  {'delta': <String, dynamic>{}, 'finish_reason': 'stop'},
                ],
                'usage': {
                  'prompt_tokens': 1,
                  'completion_tokens': 2,
                  'total_tokens': 3,
                },
              },
              '[DONE]',
            ]),
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }),
      );
      addTearDown(provider.close);

      final deltas = await provider
          .streamChat(
            apiKey: 'key',
            modelId: 'selected-from-api',
            messages: const [
              AiPromptMessage(role: AiMessageRole.user, content: 'Hi'),
            ],
          )
          .toList();

      expect(deltas.map((delta) => delta.text).join(), 'Hello world');
      expect(deltas.last.done, isTrue);
      expect(deltas.last.usage!.totalTokens, 3);
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'selected-from-api');
      expect(body['stream'], isTrue);
      expect(body['messages'], hasLength(1));
      expect(captured.headers['Authorization'], 'Bearer key');
    });

    test('streams done after content when no finish reason is sent', () async {
      final provider = GroqAiProvider(
        client: MockClient(
          (request) async => http.Response(
            _sse([
              {
                'choices': [
                  {
                    'delta': {'content': 'ok'},
                  },
                ],
              },
              '[DONE]',
            ]),
            200,
          ),
        ),
      );
      addTearDown(provider.close);

      final deltas = await provider
          .streamChat(
            apiKey: 'key',
            modelId: 'model',
            messages: const [
              AiPromptMessage(role: AiMessageRole.user, content: 'Hi'),
            ],
          )
          .toList();

      expect(deltas.first.text, 'ok');
      expect(deltas.last.done, isTrue);
    });

    test('maps HTTP and in-stream errors', () async {
      final unauthorized = GroqAiProvider(
        client: MockClient(
          (request) async => http.Response('{"error":"bad key"}', 401),
        ),
      );
      addTearDown(unauthorized.close);
      await expectLater(
        unauthorized
            .streamChat(
              apiKey: 'key',
              modelId: 'model',
              messages: const [
                AiPromptMessage(role: AiMessageRole.user, content: 'Hi'),
              ],
            )
            .toList(),
        _errorCode(AppErrorCode.aiInvalidKey),
      );

      final rateLimited = GroqAiProvider(
        client: MockClient(
          (request) async => http.Response(
            _sse([
              {
                'error': {'code': 'rate_limit_exceeded'},
              },
            ]),
            200,
          ),
        ),
      );
      addTearDown(rateLimited.close);
      await expectLater(
        rateLimited
            .streamChat(
              apiKey: 'key',
              modelId: 'model',
              messages: const [
                AiPromptMessage(role: AiMessageRole.user, content: 'Hi'),
              ],
            )
            .toList(),
        _errorCode(AppErrorCode.aiRateLimited),
      );
    });

    test('empty streamed output is reported, never shown as success', () async {
      final provider = GroqAiProvider(
        client: MockClient(
          (request) async => http.Response(_sse(['[DONE]']), 200),
        ),
      );
      addTearDown(provider.close);

      await expectLater(
        provider
            .streamChat(
              apiKey: 'key',
              modelId: 'model',
              messages: const [
                AiPromptMessage(role: AiMessageRole.user, content: 'Hi'),
              ],
            )
            .toList(),
        _errorCode(AppErrorCode.aiEmptyResponse),
      );
    });
  });
}
