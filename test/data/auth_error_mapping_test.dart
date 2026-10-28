import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/errors/app_exception.dart';
import 'package:termux_command_library/data/remote/firebase_errors.dart';

/// The base constructor is protected for SDK use; a small subclass lets the
/// tests exercise the mapping without a live Firebase project.
class _TestAuthException extends FirebaseAuthException {
  _TestAuthException(String code) : super(code: code);
}

void main() {
  AppErrorCode mapCode(String code) =>
      mapFirebaseAuthError(_TestAuthException(code)).code;

  AppErrorCode mapProviderCode(String code) =>
      mapProviderAuthError(_TestAuthException(code)).code;

  test('provider cancellations are not treated as failures', () {
    for (final code in [
      'cancelled',
      'canceled',
      'web-context-cancelled',
      'popup-closed-by-user',
      'user-cancelled',
    ]) {
      expect(mapCode(code), AppErrorCode.authCancelled, reason: code);
    }
  });

  test('disabled sign-in methods report a provider configuration problem', () {
    expect(
      mapCode('operation-not-allowed'),
      AppErrorCode.authProviderUnavailable,
    );
    expect(
      mapCode('admin-restricted-operation'),
      AppErrorCode.authProviderUnavailable,
    );
  });

  test(
    'an existing email is reported as already in use for password flows',
    () {
      expect(mapCode('credential-already-in-use'), AppErrorCode.authEmailInUse);
      expect(
        mapCode('account-exists-with-different-credential'),
        AppErrorCode.authEmailInUse,
      );
    },
  );

  test('provider email collisions are non-retryable account conflicts', () {
    for (final code in [
      'account-exists-with-different-credential',
      'credential-already-in-use',
    ]) {
      final error = mapProviderAuthError(_TestAuthException(code));
      expect(error.code, AppErrorCode.authProviderAccountExists, reason: code);
      expect(error.retryable, isFalse, reason: code);
    }
  });

  test('provider mapping leaves unrelated failures unchanged', () {
    expect(mapProviderCode('network-request-failed'), AppErrorCode.network);
    expect(mapProviderCode('cancelled'), AppErrorCode.authCancelled);
    expect(
      mapProviderCode('operation-not-allowed'),
      AppErrorCode.authProviderUnavailable,
    );
  });

  test('network failures stay retryable', () {
    final error = mapFirebaseAuthError(
      _TestAuthException('network-request-failed'),
    );
    expect(error.code, AppErrorCode.network);
    expect(error.retryable, isTrue);
  });

  test('an application error is preserved through the mapping', () {
    const original = AppException(AppErrorCode.authRequired);
    expect(mapFirebaseAuthError(original), same(original));
  });
}
