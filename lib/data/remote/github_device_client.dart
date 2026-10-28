import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';

/// Public OAuth client ID of the GitHub app that is also registered in the
/// Firebase console. A client ID is not a secret; the matching client secret
/// stays in Firebase and never enters the app. Override the ID with
/// `--dart-define=GITHUB_CLIENT_ID=...` for a different environment.
const defaultGithubClientId = String.fromEnvironment(
  'GITHUB_CLIENT_ID',
  defaultValue: 'Ov23lif4ood2wdgA1fae',
);

const _deviceCodeEndpoint = 'https://github.com/login/device/code';
const _accessTokenEndpoint = 'https://github.com/login/oauth/access_token';
const _requestedScopes = 'read:user user:email';
const _requestTimeout = Duration(seconds: 20);

/// A GitHub OAuth access token. It is handed straight to Firebase Auth and is
/// never logged, cached or persisted by the app.
class GithubAccessToken {
  const GithubAccessToken({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.scope,
  });

  final String accessToken;
  final String tokenType;
  final String? scope;

  /// Deliberately omits the token so accidental logging cannot leak it.
  @override
  String toString() => 'GithubAccessToken(scope: $scope)';
}

/// Abstraction over GitHub's OAuth device flow. The rest of the app depends on
/// this interface, which keeps HTTP details out of repositories and UI and
/// makes the flow testable without a network.
abstract interface class GithubDeviceClient {
  /// Requests a one-time user code from GitHub. The returned authorization is
  /// already ready to poll.
  Future<GithubDeviceAuthorization> start();
}

/// A pending GitHub device authorization.
///
/// [userCode] is safe to show and copy. The device code that identifies the
/// request stays inside the client implementation.
class GithubDeviceAuthorization {
  GithubDeviceAuthorization({
    required this.userCode,
    required this.verificationUri,
    required this.expiresAt,
    required Future<GithubAccessToken> Function() poll,
    required void Function() cancel,
  }) : _poll = poll,
       _cancel = cancel;

  final String userCode;
  final Uri verificationUri;
  final DateTime expiresAt;

  final Future<GithubAccessToken> Function() _poll;
  final void Function() _cancel;
  Future<GithubAccessToken>? _pending;

  /// Waits until the user authorizes the app. Repeated calls share one poll
  /// loop, so a rebuild cannot create duplicate token requests.
  Future<GithubAccessToken> waitForToken() => _pending ??= _poll();

  /// Stops polling and releases the HTTP connection. Safe to call repeatedly
  /// and after the flow has already completed.
  void cancel() => _cancel();
}

/// GitHub device flow over HTTPS.
///
/// This replaces Firebase's hosted browser OAuth handler for GitHub. That
/// handler stores its state in browser session storage, which some Android
/// browsers (Opera, Firefox variants) clear during the Custom Tab redirect,
/// producing "missing initial state". The device flow has no browser storage
/// dependency, needs no client secret in the app, and works with any browser.
class HttpGithubDeviceClient implements GithubDeviceClient {
  HttpGithubDeviceClient({
    http.Client Function()? clientFactory,
    String clientId = defaultGithubClientId,
    Future<void> Function(Duration)? delay,
    DateTime Function()? clock,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _clientId = clientId,
       _delay = delay ?? Future<void>.delayed,
       _clock = clock ?? DateTime.now;

  final http.Client Function() _clientFactory;
  final String _clientId;
  final Future<void> Function(Duration) _delay;
  final DateTime Function() _clock;

  @override
  Future<GithubDeviceAuthorization> start() async {
    final client = _clientFactory();
    var closed = false;
    void close() {
      if (closed) return;
      closed = true;
      client.close();
    }

    try {
      final response = await client
          .post(
            Uri.parse(_deviceCodeEndpoint),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'client_id': _clientId, 'scope': _requestedScopes},
          )
          .timeout(_requestTimeout);

      final body = _decodeBody(response);
      final oauthError = _stringOrNull(body['error']);
      if (oauthError != null) throw _mapOAuthError(oauthError);

      final deviceCode = _stringOrNull(body['device_code']);
      final userCode = _stringOrNull(body['user_code']);
      final verificationUri = Uri.tryParse(
        _stringOrNull(body['verification_uri']) ?? '',
      );
      if (deviceCode == null ||
          userCode == null ||
          verificationUri == null ||
          !verificationUri.isScheme('https')) {
        throw const AppException(
          AppErrorCode.authProviderUnavailable,
          message: 'GitHub returned an invalid device authorization response.',
        );
      }

      final expiresIn = _intOrNull(body['expires_in']) ?? 900;
      final intervalSeconds = (_intOrNull(body['interval']) ?? 5).clamp(1, 60);
      final expiresAt = _clock().add(Duration(seconds: expiresIn));
      final cancellation = _Cancellation();

      return GithubDeviceAuthorization(
        userCode: userCode,
        verificationUri: verificationUri,
        expiresAt: expiresAt,
        poll: () => _pollForToken(
          client: client,
          deviceCode: deviceCode,
          interval: Duration(seconds: intervalSeconds),
          expiresAt: expiresAt,
          cancellation: cancellation,
        ),
        cancel: () {
          cancellation.cancel();
          close();
        },
      );
    } on AppException {
      close();
      rethrow;
    } on TimeoutException {
      close();
      throw const AppException(AppErrorCode.timeout, retryable: true);
    } catch (error) {
      close();
      throw AppException(AppErrorCode.network, cause: error, retryable: true);
    }
  }

  Future<GithubAccessToken> _pollForToken({
    required http.Client client,
    required String deviceCode,
    required Duration interval,
    required DateTime expiresAt,
    required _Cancellation cancellation,
  }) async {
    var wait = interval;
    var consecutiveNetworkFailures = 0;
    try {
      while (true) {
        if (cancellation.isCancelled) {
          throw const AppException(AppErrorCode.authCancelled);
        }
        if (!_clock().isBefore(expiresAt)) {
          throw const AppException(AppErrorCode.authDeviceCodeExpired);
        }

        await _waitOrCancel(wait, cancellation);

        if (cancellation.isCancelled) {
          throw const AppException(AppErrorCode.authCancelled);
        }
        if (!_clock().isBefore(expiresAt)) {
          throw const AppException(AppErrorCode.authDeviceCodeExpired);
        }

        final http.Response response;
        try {
          response = await client
              .post(
                Uri.parse(_accessTokenEndpoint),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: {
                  'client_id': _clientId,
                  'device_code': deviceCode,
                  'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
                },
              )
              .timeout(_requestTimeout);
          consecutiveNetworkFailures = 0;
        } catch (error) {
          // A single dropped request should not discard a code the user is
          // still entering. Give up after three consecutive failures.
          consecutiveNetworkFailures++;
          if (consecutiveNetworkFailures >= 3) {
            throw AppException(
              AppErrorCode.network,
              cause: error,
              retryable: true,
            );
          }
          continue;
        }

        final body = _decodeBody(response);
        final oauthError = _stringOrNull(body['error']);
        if (oauthError == null) {
          final accessToken = _stringOrNull(body['access_token']);
          if (accessToken == null) {
            throw const AppException(
              AppErrorCode.authProviderUnavailable,
              message: 'GitHub returned no access token.',
            );
          }
          return GithubAccessToken(
            accessToken: accessToken,
            tokenType: _stringOrNull(body['token_type']) ?? 'bearer',
            scope: _stringOrNull(body['scope']),
          );
        }

        switch (oauthError) {
          case 'authorization_pending':
            continue;
          case 'slow_down':
            wait += const Duration(seconds: 5);
            continue;
          case 'expired_token':
            throw const AppException(AppErrorCode.authDeviceCodeExpired);
          case 'access_denied':
            throw const AppException(AppErrorCode.authCancelled);
          case 'device_flow_disabled':
            throw const AppException(AppErrorCode.authDeviceFlowDisabled);
          default:
            throw const AppException(AppErrorCode.authProviderUnavailable);
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> _waitOrCancel(Duration duration, _Cancellation cancellation) {
    if (cancellation.isCancelled) return Future<void>.value();
    return Future.any<void>([_delay(duration), cancellation.whenCancelled]);
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      // Fall through to the status-based error below.
    }
    if (body == null) {
      if (response.statusCode >= 500) {
        throw const AppException(AppErrorCode.network, retryable: true);
      }
      throw const AppException(AppErrorCode.authProviderUnavailable);
    }
    return body;
  }

  static AppException _mapOAuthError(String error) {
    return switch (error) {
      'device_flow_disabled' => const AppException(
        AppErrorCode.authDeviceFlowDisabled,
      ),
      'slow_down' || 'authorization_pending' => const AppException(
        AppErrorCode.authProviderUnavailable,
      ),
      _ => const AppException(AppErrorCode.authProviderUnavailable),
    };
  }

  static String? _stringOrNull(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static int? _intOrNull(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Completes when [cancel] is called, letting a pending poll delay finish
/// immediately instead of waiting for the full interval.
class _Cancellation {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}
