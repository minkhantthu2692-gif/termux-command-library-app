/// A small set of stable error codes shared by repositories, services and UI.
/// UI code maps these codes to localized, actionable messages instead of
/// displaying raw exception text.
enum AppErrorCode {
  network,
  timeout,
  authRequired,
  authInvalidCredentials,
  authEmailInUse,
  authWeakPassword,
  authTooManyRequests,
  authRecentLoginRequired,
  authCancelled,
  authProviderUnavailable,
  authDeviceCodeExpired,
  authDeviceFlowDisabled,
  authAccountDeleted,
  permissionDenied,
  firebaseUnavailable,
  firebaseNotConfigured,
  validation,
  notFound,
  database,
  conflict,
  limitReached,
  aiDisabled,
  aiKeyMissing,
  aiInvalidKey,
  aiRateLimited,
  aiProviderUnavailable,
  aiModelUnavailable,
  aiRequestTooLarge,
  aiEmptyResponse,
  aiCancelled,
  attachmentTooLarge,
  attachmentUnsupported,
  attachmentReadFailed,
  termuxMissing,
  termuxPermissionMissing,
  termuxExternalAppsDisabled,
  termuxError,
  unsupported,
  unknown,
}

/// Exception type used at repository/service boundaries. It never contains
/// API keys or request headers.
class AppException implements Exception {
  const AppException(
    this.code, {
    this.message,
    this.cause,
    this.retryable = false,
  });

  final AppErrorCode code;
  final String? message;
  final Object? cause;
  final bool retryable;

  bool get isAuthError =>
      code == AppErrorCode.authRequired ||
      code == AppErrorCode.authInvalidCredentials ||
      code == AppErrorCode.authEmailInUse ||
      code == AppErrorCode.authWeakPassword ||
      code == AppErrorCode.authTooManyRequests ||
      code == AppErrorCode.authRecentLoginRequired ||
      code == AppErrorCode.authProviderUnavailable;

  AppException copyWith({AppErrorCode? code, String? message, Object? cause}) =>
      AppException(
        code ?? this.code,
        message: message ?? this.message,
        cause: cause ?? this.cause,
        retryable: retryable,
      );

  @override
  String toString() {
    final detail = message == null || message!.isEmpty ? '' : ': $message';
    return 'AppException(${code.name}$detail)';
  }
}
