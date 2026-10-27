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

  test('an existing provider account is reported as already in use', () {
    expect(mapCode('credential-already-in-use'), AppErrorCode.authEmailInUse);
    expect(
      mapCode('account-exists-with-different-credential'),
      AppErrorCode.authEmailInUse,
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
