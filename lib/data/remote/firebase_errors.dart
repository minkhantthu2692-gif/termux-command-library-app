import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../core/errors/app_exception.dart';

/// Converts SDK-specific failures into stable application error codes. Raw SDK
/// messages can contain request details, so they are not surfaced in the UI.
AppException mapFirebaseAuthError(Object error) {
  // Repository/gateway code sometimes raises a stable AppException directly
  // (for example when Firebase returns no user). Preserve it instead of
  // flattening it to `unknown`.
  if (error is AppException) return error;
  if (error is FirebaseAuthException) {
    final code = switch (error.code) {
      'invalid-email' => AppErrorCode.validation,
      'wrong-password' ||
      'invalid-credential' ||
      'user-not-found' ||
      'invalid-login-credentials' => AppErrorCode.authInvalidCredentials,
      'email-already-in-use' ||
      'credential-already-in-use' ||
      'account-exists-with-different-credential' => AppErrorCode.authEmailInUse,
      'weak-password' => AppErrorCode.authWeakPassword,
      'too-many-requests' => AppErrorCode.authTooManyRequests,
      'requires-recent-login' => AppErrorCode.authRecentLoginRequired,
      'user-disabled' || 'user-token-expired' => AppErrorCode.authRequired,
      'cancelled' ||
      'canceled' ||
      'web-context-cancelled' ||
      'popup-closed-by-user' ||
      'user-cancelled' => AppErrorCode.authCancelled,
      'network-request-failed' => AppErrorCode.network,
      'operation-not-allowed' ||
      'admin-restricted-operation' => AppErrorCode.authProviderUnavailable,
      'user-mismatch' || 'provider-already-linked' => AppErrorCode.conflict,
      _ => AppErrorCode.unknown,
    };
    return AppException(code, retryable: code == AppErrorCode.network);
  }
  if (error is FirebaseException) return mapFirebaseError(error);
  return const AppException(AppErrorCode.unknown);
}

/// Provider sign-in variant of [mapFirebaseAuthError].
///
/// Firebase reports an email that is already attached to another sign-in
/// method as `account-exists-with-different-credential` (or
/// `credential-already-in-use` while linking). Those are account-model
/// conflicts, not failed attempts, so retrying the provider cannot help. The UI
/// can use the distinct code to tell the user to sign in with the existing
/// method instead.
AppException mapProviderAuthError(Object error) {
  if (error is FirebaseAuthException &&
      (error.code == 'account-exists-with-different-credential' ||
          error.code == 'credential-already-in-use')) {
    return const AppException(AppErrorCode.authProviderAccountExists);
  }
  return mapFirebaseAuthError(error);
}

AppException mapFirebaseError(Object error) {
  if (error is FirebaseException) {
    final code = switch (error.code) {
      'permission-denied' => AppErrorCode.permissionDenied,
      'unauthenticated' => AppErrorCode.authRequired,
      'unavailable' || 'network-request-failed' => AppErrorCode.network,
      'deadline-exceeded' => AppErrorCode.timeout,
      'not-found' => AppErrorCode.notFound,
      'already-exists' => AppErrorCode.conflict,
      'failed-precondition' ||
      'aborted' ||
      'resource-exhausted' => AppErrorCode.conflict,
      'cancelled' => AppErrorCode.unknown,
      _ => AppErrorCode.unknown,
    };
    return AppException(
      code,
      retryable: code == AppErrorCode.network || code == AppErrorCode.timeout,
    );
  }
  return const AppException(AppErrorCode.unknown);
}

AppException mapPlatformError(Object error) {
  if (error is PlatformException) {
    return switch (error.code) {
      'termux_missing' => const AppException(AppErrorCode.termuxMissing),
      'permission_missing' => const AppException(
        AppErrorCode.termuxPermissionMissing,
      ),
      'invalid_command' => const AppException(AppErrorCode.validation),
      'termux_error' => const AppException(AppErrorCode.termuxError),
      _ => const AppException(AppErrorCode.unknown),
    };
  }
  return const AppException(AppErrorCode.unknown);
}
