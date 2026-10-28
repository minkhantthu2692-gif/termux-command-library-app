import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/app_exception.dart';

/// The minimum Google identity data needed to create a Firebase credential.
/// The ID token is sensitive and is never logged or persisted by the app.
class GoogleIdentity {
  const GoogleIdentity({required this.idToken, this.email, this.displayName});

  final String idToken;
  final String? email;
  final String? displayName;
}

/// Abstraction over the native Google account picker so the Firebase gateway
/// stays testable and the rest of the app never imports `google_sign_in`.
abstract interface class GoogleIdentityClient {
  /// Opens the native account picker and returns a fresh Google ID token.
  Future<GoogleIdentity> authenticate();

  /// Clears the native Google session. Called on a best-effort basis.
  Future<void> signOut();
}

/// Native Google sign-in backed by Android Credential Manager.
///
/// This deliberately avoids Firebase's hosted `/__/auth/handler` redirect for
/// Google. The hosted page keeps its OAuth state in browser session storage,
/// which Chrome (and other browsers) can partition or clear, producing the
/// "missing initial state" error before the app receives a result.
class GoogleSignInIdentityClient implements GoogleIdentityClient {
  GoogleSignInIdentityClient({String? serverClientId})
    : _serverClientId = serverClientId ?? _configuredServerClientId;

  /// Optional override for builds without `google-services.json` (for example
  /// an iOS build). Android resolves the web OAuth client from the bundled
  /// Firebase configuration when this is empty.
  static const _configuredServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  final String? _serverClientId;

  /// `GoogleSignIn.initialize` must run exactly once. The future is cached so
  /// concurrent sign-in taps cannot initialise the plugin twice.
  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    return _initialization ??= _initializeOnce();
  }

  Future<void> _initializeOnce() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _emptyToNull(_serverClientId),
      );
    } catch (_) {
      // A failed initialisation should be retryable once the configuration is
      // fixed, so do not cache the failed future.
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<GoogleIdentity> authenticate() async {
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppException(
          AppErrorCode.authProviderUnavailable,
          message: 'Google returned no ID token.',
        );
      }
      return GoogleIdentity(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
      );
    } on AppException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw mapGoogleSignInError(error);
    } catch (error) {
      throw AppException(AppErrorCode.unknown, cause: error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Signing out of Google is best effort. A failure here must not block
      // Firebase sign-out or local data cleanup.
    }
  }

  static String? _emptyToNull(String? value) =>
      value == null || value.isEmpty ? null : value;
}

/// Maps the native Google plugin's failure modes to stable application codes.
/// Kept top-level so it can be unit tested without a platform channel.
AppException mapGoogleSignInError(GoogleSignInException error) {
  return switch (error.code) {
    GoogleSignInExceptionCode.canceled ||
    GoogleSignInExceptionCode.interrupted => const AppException(
      AppErrorCode.authCancelled,
    ),
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError ||
    GoogleSignInExceptionCode.uiUnavailable => const AppException(
      AppErrorCode.authProviderUnavailable,
    ),
    GoogleSignInExceptionCode.userMismatch => const AppException(
      AppErrorCode.authRequired,
    ),
    GoogleSignInExceptionCode.unknownError => const AppException(
      AppErrorCode.unknown,
    ),
  };
}
