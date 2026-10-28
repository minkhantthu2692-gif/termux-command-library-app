import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:termux_command_library/core/errors/app_exception.dart';
import 'package:termux_command_library/data/remote/google_identity_client.dart';

AppErrorCode mapCode(GoogleSignInExceptionCode code) =>
    mapGoogleSignInError(GoogleSignInException(code: code)).code;

void main() {
  test('dismissing the account picker is treated as a cancellation', () {
    for (final code in [
      GoogleSignInExceptionCode.canceled,
      GoogleSignInExceptionCode.interrupted,
    ]) {
      expect(mapCode(code), AppErrorCode.authCancelled, reason: code.name);
    }
  });

  test('configuration failures report an unavailable provider', () {
    for (final code in [
      GoogleSignInExceptionCode.clientConfigurationError,
      GoogleSignInExceptionCode.providerConfigurationError,
      GoogleSignInExceptionCode.uiUnavailable,
    ]) {
      expect(
        mapCode(code),
        AppErrorCode.authProviderUnavailable,
        reason: code.name,
      );
    }
  });

  test('a stale Google session asks the user to sign in again', () {
    expect(
      mapCode(GoogleSignInExceptionCode.userMismatch),
      AppErrorCode.authRequired,
    );
  });

  test('unexpected plugin failures stay generic', () {
    final error = mapGoogleSignInError(
      const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError),
    );
    expect(error.code, AppErrorCode.unknown);
    expect(error.retryable, isFalse);
  });
}
