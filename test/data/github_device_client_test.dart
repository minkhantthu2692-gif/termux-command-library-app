import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:termux_command_library/core/errors/app_exception.dart';
import 'package:termux_command_library/data/remote/github_device_client.dart';

void main() {
  const deviceResponse = <String, Object?>{
    'device_code': 'device-secret',
    'user_code': 'ABCD-1234',
    'verification_uri': 'https://github.com/login/device',
    'expires_in': 900,
    'interval': 5,
  };

  http.Response jsonResponse(
    Map<String, Object?> body, {
    int statusCode = 200,
  }) {
    return http.Response(
      jsonEncode(body),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }

  Matcher throwsAppError(AppErrorCode code) =>
      throwsA(isA<AppException>().having((error) => error.code, 'code', code));

  HttpGithubDeviceClient buildClient(
    Future<http.Response> Function(http.Request request) handler, {
    List<Duration>? delays,
    DateTime Function()? clock,
  }) {
    return HttpGithubDeviceClient(
      clientFactory: () => MockClient(handler),
      delay: (duration) async => delays?.add(duration),
      clock: clock ?? () => DateTime.utc(2026, 10, 28, 12),
    );
  }

  group('start', () {
    test('requests a user code with the public client id and scopes', () async {
      final requests = <http.Request>[];
      final client = buildClient((request) async {
        requests.add(request);
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        return jsonResponse({
          'access_token': 'gho_test_token',
          'token_type': 'bearer',
          'scope': 'read:user,user:email',
        });
      });

      final authorization = await client.start();

      expect(authorization.userCode, 'ABCD-1234');
      expect(
        authorization.verificationUri.toString(),
        'https://github.com/login/device',
      );
      expect(requests, hasLength(1));
      expect(
        requests.single.url.toString(),
        'https://github.com/login/device/code',
      );
      expect(requests.single.headers['Accept'], 'application/json');
      expect(requests.single.bodyFields['client_id'], defaultGithubClientId);
      expect(requests.single.bodyFields['scope'], 'read:user user:email');
    });

    test('maps device_flow_disabled to a stable error', () async {
      final client = buildClient(
        (_) async => jsonResponse({
          'error': 'device_flow_disabled',
          'error_description': 'Device Flow must be explicitly enabled',
        }, statusCode: 400),
      );

      await expectLater(
        client.start(),
        throwsAppError(AppErrorCode.authDeviceFlowDisabled),
      );
    });

    test('rejects a malformed authorization response', () async {
      final client = buildClient(
        (_) async => jsonResponse({'device_code': 'only-a-device-code'}),
      );

      await expectLater(
        client.start(),
        throwsAppError(AppErrorCode.authProviderUnavailable),
      );
    });

    test('rejects a non-HTTPS verification URI', () async {
      final client = buildClient(
        (_) async => jsonResponse({
          ...deviceResponse,
          'verification_uri': 'http://github.com/login/device',
        }),
      );

      await expectLater(
        client.start(),
        throwsAppError(AppErrorCode.authProviderUnavailable),
      );
    });

    test('maps a server failure to a retryable network error', () async {
      final client = buildClient(
        (_) async => http.Response('unavailable', 503),
      );

      await expectLater(
        client.start(),
        throwsA(
          isA<AppException>()
              .having((error) => error.code, 'code', AppErrorCode.network)
              .having((error) => error.retryable, 'retryable', isTrue),
        ),
      );
    });
  });

  group('polling', () {
    test('returns the access token without exposing it in toString', () async {
      final requests = <http.Request>[];
      final client = buildClient((request) async {
        requests.add(request);
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        return jsonResponse({
          'access_token': 'gho_test_token',
          'token_type': 'bearer',
          'scope': 'read:user,user:email',
        });
      });

      final authorization = await client.start();
      final token = await authorization.waitForToken();

      expect(token.accessToken, 'gho_test_token');
      expect(token.tokenType, 'bearer');
      expect(token.scope, 'read:user,user:email');
      expect(token.toString(), isNot(contains('gho_test_token')));
      expect(requests, hasLength(2));
      expect(
        requests.last.url.toString(),
        'https://github.com/login/oauth/access_token',
      );
      expect(requests.last.bodyFields['client_id'], defaultGithubClientId);
      expect(requests.last.bodyFields['device_code'], 'device-secret');
      expect(
        requests.last.bodyFields['grant_type'],
        'urn:ietf:params:oauth:grant-type:device_code',
      );
    });

    test('waits through authorization_pending responses', () async {
      final delays = <Duration>[];
      var polls = 0;
      final client = buildClient((request) async {
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        polls++;
        if (polls < 3) {
          return jsonResponse({'error': 'authorization_pending'});
        }
        return jsonResponse({'access_token': 'gho_test_token'});
      }, delays: delays);

      final authorization = await client.start();
      final token = await authorization.waitForToken();

      expect(token.accessToken, 'gho_test_token');
      expect(polls, 3);
      expect(delays, [
        const Duration(seconds: 5),
        const Duration(seconds: 5),
        const Duration(seconds: 5),
      ]);
    });

    test('backs off when GitHub returns slow_down', () async {
      final delays = <Duration>[];
      var polls = 0;
      final client = buildClient((request) async {
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        polls++;
        if (polls == 1) {
          return jsonResponse({'error': 'authorization_pending'});
        }
        if (polls == 2) {
          return jsonResponse({'error': 'slow_down'});
        }
        return jsonResponse({'access_token': 'gho_test_token'});
      }, delays: delays);

      final authorization = await client.start();
      await authorization.waitForToken();

      expect(delays, [
        const Duration(seconds: 5),
        const Duration(seconds: 5),
        const Duration(seconds: 10),
      ]);
    });

    test('shares one poll loop between waitForToken callers', () async {
      var polls = 0;
      final client = buildClient((request) async {
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        polls++;
        return jsonResponse({'access_token': 'gho_test_token'});
      });

      final authorization = await client.start();
      final first = authorization.waitForToken();
      final second = authorization.waitForToken();

      expect(identical(first, second), isTrue);
      await first;
      expect(polls, 1);
    });

    test('maps access_denied to cancellation', () async {
      final client = buildClient((request) async {
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        return jsonResponse({'error': 'access_denied'});
      });

      final authorization = await client.start();

      await expectLater(
        authorization.waitForToken(),
        throwsAppError(AppErrorCode.authCancelled),
      );
    });

    test('maps expired_token to an expired code error', () async {
      final client = buildClient((request) async {
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        return jsonResponse({'error': 'expired_token'});
      });

      final authorization = await client.start();

      await expectLater(
        authorization.waitForToken(),
        throwsAppError(AppErrorCode.authDeviceCodeExpired),
      );
    });

    test('stops when the challenge expires locally', () async {
      var now = DateTime.utc(2026, 10, 28, 12);
      final client = buildClient((request) async {
        if (request.url.path == '/login/device/code') {
          return jsonResponse({...deviceResponse, 'expires_in': 2});
        }
        now = now.add(const Duration(seconds: 5));
        return jsonResponse({'error': 'authorization_pending'});
      }, clock: () => now);

      final authorization = await client.start();

      await expectLater(
        authorization.waitForToken(),
        throwsAppError(AppErrorCode.authDeviceCodeExpired),
      );
    });

    test('gives up after three consecutive network failures', () async {
      var polls = 0;
      final client = buildClient((request) async {
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        polls++;
        throw http.ClientException('offline');
      });

      final authorization = await client.start();

      await expectLater(
        authorization.waitForToken(),
        throwsAppError(AppErrorCode.network),
      );
      expect(polls, 3);
    });

    test('cancel stops a pending poll', () async {
      final client = buildClient((request) async {
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        return jsonResponse({'error': 'authorization_pending'});
      });

      final authorization = await client.start();
      authorization.cancel();

      await expectLater(
        authorization.waitForToken(),
        throwsAppError(AppErrorCode.authCancelled),
      );
    });

    test('rejects a token response without an access token', () async {
      final client = buildClient((request) async {
        if (request.url.path == '/login/device/code') {
          return jsonResponse(deviceResponse);
        }
        return jsonResponse({'token_type': 'bearer'});
      });

      final authorization = await client.start();

      await expectLater(
        authorization.waitForToken(),
        throwsAppError(AppErrorCode.authProviderUnavailable),
      );
    });
  });
}
